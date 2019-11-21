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
#sudo ipvsadm -A -t `dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`:80 -s rr
#sudo ipvsadm -a -t `dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`:80 -r `lxc exec kworker1 -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1` -m
#sudo ipvsadm -a -t `dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`:80 -r `lxc exec kworker2 -- ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1` -m
curl -L https://git.io/get_helm.sh | bash
wget -O helm.yaml https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/helm.yaml
kubectl apply -f helm.yaml
helm init --service-account=tiller --history-max 300
