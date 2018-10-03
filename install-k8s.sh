# from https://kubernetes.io/docs/setup/independent/install-kubeadm/

# Add Kubernetes project repo
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install kubelet
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Disable SELinux for now. Hopefully can enable it in the future
sudo setenforce 0

sudo systemctl enable kubelet
sudo systemctl start kubelet

# Configure iptables to listen on bridge interface
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system