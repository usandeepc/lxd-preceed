#!/bin/bash

# Install docker from Docker-ce repository
echo "[TASK 1] Install docker container engine"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
#yum install -y -q docker-ce-18.06.0.ce-3.el7 >/dev/null 2>&1
yum install -y -q docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
#Install on all nodes for nfs-dynamic provisoning
yum install -y -q nfs-utils >/dev/null 2>&1

# Enable docker service
echo "[TASK 2] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker >/dev/null 2>&1
#Prerequisites for kubeadm
cat >>/etc/sysctl.d/k8s.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

# Add yum repo file for Kubernetes
echo "[TASK 3] Add yum repo file for kubernetes"
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Install Kubernetes
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubelet kubeadm kubectl --disableexcludes=kubernetes>/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 5] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet >/dev/null 2>&1

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd >/dev/null 2>&1
systemctl start sshd >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 8] Install additional packages"
yum install -y -q which net-tools sudo sshpass >/dev/null 2>&1


#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 9] Initialize Kubernetes Cluster"
  kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all >> /root/kubeinit.log 2>&1
  sleep 60
  # Copy Kube admin config
  echo "[TASK 10] Copy kube admin config to root user .kube directory"
  mkdir /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  # Deploy flannel network
  echo "[TASK 11] Deploy flannel network"
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > /dev/null 2>&1

  # Generate Cluster join command
  echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null)
  sleep 60 
  echo "$joinCommand --ignore-preflight-errors=all" > /joincluster.sh

fi

#######################################
# To be executed only on worker nodes #
#######################################

if [[ $(hostname) =~ .*worker.* ]]
then

  # Join worker nodes to the Kubernetes cluster
  echo "[TASK 9] Join node to Kubernetes Cluster"
  sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.lxd:/joincluster.sh /joincluster.sh 2>/tmp/joincluster.log
  sleep 10
  bash /joincluster.sh >> /tmp/joincluster.log 2>&1
  sleep 10

fi
