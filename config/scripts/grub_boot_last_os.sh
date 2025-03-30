#!/bin/bash

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Use sudo." >&2
    exit 1
fi

# Remove existing entries if they exist
sed -i '/^GRUB_DEFAULT=.*/d' /etc/default/grub
sed -i '/^GRUB_SAVEDEFAULT=.*/d' /etc/default/grub

# Add new settings
echo "GRUB_DEFAULT=saved" >> /etc/default/grub
echo "GRUB_SAVEDEFAULT=true" >> /etc/default/grub

# Update GRUB configuration
update-grub

echo "GRUB configuration updated successfully. Previous configuration backed up to /etc/default/grub.bak"
