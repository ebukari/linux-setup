#!/bin/bash

ACTUAL_USER=${SUDO_USER:-$(whoami)}

# Check if packages are installed
declare -a packages=(
    qemu-kvm virt-manager virtinst libvirt-clients
    bridge-utils libvirt-daemon-system qemu-guest-agent
)

for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        sudo apt install -y "$pkg"
    fi
done

# Add user to groups if not member
for group in libvirt kvm; do
    if ! groups "$ACTUAL_USER" | grep -q "\b$group\b"; then
        sudo usermod -aG "$group" $ACTUAL_USER
    fi
done

# Handle service state
if ! systemctl is-active --quiet libvirtd; then
    sudo systemctl enable --now libvirtd
    sudo systemctl start libvirtd
fi
