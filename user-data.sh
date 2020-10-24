#!/bin/bash
#Install and configure Lxd
#Required Ubuntu:20.04
sudo snap install lxd
lxc launch images:centos/7 kmaster --vm -c limits.memory=2GB
lxc launch images:centos/7 kworker1 --vm -c limits.memory=2GB
#lxc launch images:centos/7 kworker2 --vm -c limits.memory=2GB
#lxc launch images:centos/7 kworker3 --vm -c limits.memory=2GB
wget -O bootstrap-kube.sh https://raw.githubusercontent.com/usandeepc/lxd-preceed/lxd-virtualmachine/bootstrap-kube.sh
#Delay is required to initialize lxd-agent on vms
sleep 150
lxc exec kmaster -- hostnamectl set-hostname kmaster
lxc exec kworker1 -- hostnamectl set-hostname kworker1
#lxc exec kworker2 -- hostnamectl set-hostname kworker2
#lxc exec kworker3 -- hostnamectl set-hostname kworker3
cat bootstrap-kube.sh | lxc exec kmaster bash
cat bootstrap-kube.sh | lxc exec kworker1 bash
#cat bootstrap-kube.sh | lxc exec kworker2 bash
#cat bootstrap-kube.sh | lxc exec kworker3 bash

#Adding KubeConfig
mkdir ~/.kube/
lxc file pull kmaster/root/.kube/config ~/.kube/config

#kubectl install and enable bash auto-completeion feature for kubectl
sudo snap install kubectl --classic
sudo kubectl completion bash > kubectl && sudo mv kubectl /etc/bash_completion.d/
sudo /bin/bash /etc/bash_completion.d/kubectl


#Helm 3 install 
wget https://get.helm.sh/helm-v3.3.4-linux-amd64.tar.gz && tar -xvzf helm-v3.3.4-linux-amd64.tar.gz && sudo mv linux-amd64/helm /usr/bin/
helm repo add stable https://kubernetes-charts.storage.googleapis.com &&  helm repo update

#Metallb install
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"


#Configure Metallb (ConfigMap)
wget -O metallb.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/metallb.yaml
#kubectl apply -f metallb.yaml

#Helm 2 Install
#curl -L https://git.io/get_helm.sh | bash
#wget -O helm.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/helm.yaml
#kubectl apply -f helm.yaml
#helm init --service-account=tiller --history-max 300

#Install ipvsadm
sudo apt-get install ipvsadm -y
sleep 20

#Install nginx-ingress 
#kubectl create ns nginx-ingress
#helm install nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true --namespace nginx-ingress

#Configure ipvsadm
#export $PVT_IP=xx.xxx.xx.x
#sudo ipvsadm -A -t $PVT_IP:443 -s rr
#sudo ipvsadm -a -t $PVT_IP:443 -r 10.235.228.240 -m
#sudo ipvsadm -A -t $PVT_IP:80 -s rr
#sudo ipvsadm -a -t $PVT_IP:80 -r 10.235.228.240 -m
#curl https://ipinfo.io/ip

#Keycloak
#helm repo add codecentric https://codecentric.github.io/helm-charts


#Cert-Manager
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.0.3 --set installCRDs=true
