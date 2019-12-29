curl -L https://istio.io/downloadIstio | sh 
sudo mv istio-1.4.2/bin/istioctl /usr/bin/
istioctl version
istioctl verify-install
