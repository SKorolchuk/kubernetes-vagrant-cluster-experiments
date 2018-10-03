# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab