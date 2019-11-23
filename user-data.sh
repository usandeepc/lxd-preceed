sudo apt-get install lxd
sudo gpasswd -a ubuntu lxd
wget -O preseed.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/lxd-preceed.yaml
cat preseed.yaml | lxd init --preseed
lxc list
lxc profile create k8s
wget -O lxc-profile-k8s.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/lxc-profile-k8s.yaml
cat lxc-profile-k8s.yaml | lxc profile edit k8s
lxc launch images:centos/7 kmaster --profile k8s
lxc launch images:centos/7 kworker1 --profile k8s
lxc launch images:centos/7 kworker2 --profile k8s
wget -O bootstrap-kube.sh https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/bootstrap-kube.sh
sleep 60
cat bootstrap-kube.sh | lxc exec kmaster bash
cat bootstrap-kube.sh | lxc exec kworker1 bash
cat bootstrap-kube.sh | lxc exec kworker2 bash
mkdir /home/ubuntu/.kube/
lxc file pull kmaster/root/.kube/config ~/.kube/config
sudo snap install kubectl --classic
#sudo apt-get install ipvsadm
curl -L https://git.io/get_helm.sh | bash
wget -O helm.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/helm.yaml
wget -O metallb.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/metallb.yaml
kubectl apply -f helm.yaml
helm init --service-account=tiller --history-max 300
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml

#Configure Metallb (ConfigMap)
#sudo ipvsadm -a -t 172.31.43.77:80 -r 10.36.211.220 -m

helm install stable/nginx-ingress --name nginx-ingress --set controller.publishService.enabled=true --namespace nginx-ingress
helm repo add codecentric https://codecentric.github.io/helm-charts

#IPVS proxy to Metallb -- eg 
#sudo ipvsadm -A -t 172.31.43.77:80 -s rr
#sudo ipvsadm -a -t 172.31.43.77:80 -r 10.36.211.220 -m
