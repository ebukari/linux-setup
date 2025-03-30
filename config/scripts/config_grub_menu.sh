#!/bin/bash

# Default values
FONT_SIZE="${1:-24}"
RESOLUTION="${2:-1920x1080}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi

# Install dependencies if needed
if ! command -v grub-mkfont &> /dev/null; then
    echo "Installing required packages (grub2-common)..."
    apt update && apt install -y grub2-common
fi

# Generate the font in the correct size
echo "Generating GRUB font with size $FONT_SIZE..."
grub-mkfont -s "$FONT_SIZE" -o /boot/grub/fonts/DejaVuSansMono.pf2 /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf

# Update GRUB config with the new font and resolution
echo "Updating GRUB configuration with resolution $RESOLUTION..."
sed -i "/^GRUB_GFXMODE=/d" /etc/default/grub
sed -i '/^GRUB_FONT=.*/d' /etc/default/grub
echo "GRUB_GFXMODE=$RESOLUTION" | tee -a /etc/default/grub
echo "GRUB_FONT=/boot/grub/fonts/DejaVuSansMono.pf2" | tee -a /etc/default/grub

# Update GRUB
echo "Applying changes..."
# grub-mkconfig -o /boot/grub/grub.cfg
# grub-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg
update-grub

echo "Done! Reboot to see the changes."
