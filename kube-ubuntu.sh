#!/bin/bash

# Install docker from Docker-ce repository
echo "[TASK 1] Install docker container engine"
sudo apt-get update -y
swapoff -a
sudo apt-get install -y docker.io
#Start and enable docker 
echo "[TASK 2] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Add yum repo file for Kubernetes
echo "[TASK 3] Add apt repo file for kubernetes"

sudo apt-get update -y && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update

# Install Kubernetes
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
sudo apt-get install -y kubelet kubeadm kubectl

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd >/dev/null 2>&1
systemctl start sshd >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

#######################################
# To be executed only on master nodes #
#######################################


if [[ $(hostname) =~ .*master.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 9] Initialize Kubernetes Cluster"
  kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=Swap,FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification >> /root/kubeinit.log 2>&1
  
  echo 'Environment="cgroup-driver=systemd/cgroup-driver=cgroupfs"' >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
 
 # Copy Kube admin config
  echo "[TASK 10] Copy kube admin config to root user .kube directory"
  mkdir /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  # Deploy calico network
  echo "[TASK 11] Deploy calico network"
  kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml > /dev/null 2>&1

  # Generate Cluster join command
  echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command) 
  echo "$joinCommand --ignore-preflight-errors=Swap,FileContent--proc-sys-net-bridge-bridge-nf-call-iptables,SystemVerification" > /joincluster.sh

fi


#######################################
# To be executed only on worker nodes #
#######################################

if [[ $(hostname) =~ .*worker.* ]]
then

  # Join worker nodes to the Kubernetes cluster
  echo "[TASK 9] Join node to Kubernetes Cluster"
  sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.lxd:/joincluster.sh /joincluster.sh 2>/tmp/joincluster.log
  bash /joincluster.sh >> /tmp/joincluster.log 2>&1

fi
