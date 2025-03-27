sudo apt install qemu-kvm virt-manager virtinst libvirt-clients bridge-utils libvirt-daemon-system -y
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG kvm $(whoami)
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd
# sudo systemctl status libvirtd
sudo apt install qemu-guest-agent
