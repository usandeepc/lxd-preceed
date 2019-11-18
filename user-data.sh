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
wget -O bootstrap-kube.sh https://raw.githubusercontent.com/usandeepc/lxd-preceed/master/bootstrap-kube.sh
cat bootstrap-kube.sh | lxc exec kmaster bash
cat bootstrap-kube.sh | lxc exec kworker1 bash
history | cut -c 8-
