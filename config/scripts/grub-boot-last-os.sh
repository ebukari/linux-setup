#!/bin/bash

# Script to increase GRUB menu font size using DejaVu Sans Mono
# This script automates the process of downloading, converting, and configuring
# a larger font for the GRUB boot menu, and adjusts the GRUB resolution for
# optimal display

# Exit on any error
set -e

# Function to display steps
print_step() {
  echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

# Function to display success messages
print_success() {
  echo -e "\033[1;32m==> $1\033[0m"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (with sudo)"
  exit 1
fi

# Set default font size and resolution
FONT_SIZE=24
RESOLUTION="1920x1080"  # Default to 1920x1080 as specified

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--size)
      FONT_SIZE="$2"
      shift 2
      ;;
    -r|--resolution)
      RESOLUTION="$2"
      shift 2
      ;;
    *)
      # If no flag is provided, assume it's the font size (for backward compatibility)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        FONT_SIZE="$1"
      fi
      shift
      ;;
  esac
done

print_step "Starting GRUB configuration (font size: $FONT_SIZE, resolution: $RESOLUTION)"

# Create temporary working directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
print_success "Created temporary directory: $TEMP_DIR"

# Step 1: Check if DejaVu Sans Mono is already available
if [ -f /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf ]; then
  print_success "DejaVu Sans Mono font already installed on system"
  FONT_PATH="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
elif [ -f /usr/share/fonts/TTF/DejaVuSansMono.ttf ]; then
  print_success "DejaVu Sans Mono font already installed on system"
  FONT_PATH="/usr/share/fonts/TTF/DejaVuSansMono.ttf"
else
  # Download the font
  print_step "Downloading DejaVu Sans Mono font"
  wget -q https://dejavu-fonts.github.io/Files/dejavu-fonts-ttf-2.37.tar.bz2
  
  # Extract the archive
  print_step "Extracting font archive"
  tar -xf dejavu-fonts-ttf-2.37.tar.bz2
  
  FONT_PATH="$TEMP_DIR/dejavu-fonts-ttf-2.37/ttf/DejaVuSansMono.ttf"
  print_success "Font extracted to $FONT_PATH"
fi

# Step 2: Convert font to GRUB format
print_step "Converting font to GRUB-compatible PF2 format"
grub-mkfont -s "$FONT_SIZE" -o /boot/grub/dejavu-sans-mono.pf2 "$FONT_PATH"
print_success "Font converted and saved to /boot/grub/dejavu-sans-mono.pf2"

# Step 3: Backup current GRUB configuration with numbered backups
print_step "Creating backup of current GRUB configuration"

# Check if a backup already exists
if [ -f "/etc/default/grub.bak" ]; then
  # Find the highest backup number
  HIGHEST_NUM=0
  for backup in /etc/default/grub[0-9]*.bak; do
    if [ -f "$backup" ]; then
      # Extract the number from the filename
      NUM=$(echo "$backup" | grep -o '[0-9]\+' | head -1)
      if [ -n "$NUM" ] && [ "$NUM" -gt "$HIGHEST_NUM" ]; then
        HIGHEST_NUM=$NUM
      fi
    fi
  done
  
  # Increment the backup number
  NEXT_NUM=$((HIGHEST_NUM + 1))
  BACKUP_FILE="/etc/default/grub${NEXT_NUM}.bak"
else
  BACKUP_FILE="/etc/default/grub.bak"
fi

# Create the backup
cp /etc/default/grub "$BACKUP_FILE"
print_success "Backup created at $BACKUP_FILE"

# Step 4: Update GRUB configuration to use the new font and set resolution
print_step "Updating GRUB configuration"

# Update font configuration
if grep -q "^GRUB_FONT=" /etc/default/grub; then
  # Replace existing GRUB_FONT line
  sed -i 's|^GRUB_FONT=.*|GRUB_FONT=/boot/grub/dejavu-sans-mono.pf2|' /etc/default/grub
else
  # Add GRUB_FONT line
  echo "GRUB_FONT=/boot/grub/dejavu-sans-mono.pf2" >> /etc/default/grub
fi

# Update resolution configuration
if grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
  # Replace existing uncommented GRUB_GFXMODE line
  sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=$RESOLUTION|" /etc/default/grub
elif grep -q "^#GRUB_GFXMODE=" /etc/default/grub; then
  # Uncomment the GRUB_GFXMODE line and set the resolution
  sed -i "s|^#GRUB_GFXMODE=.*|GRUB_GFXMODE=$RESOLUTION|" /etc/default/grub
else
  # Add GRUB_GFXMODE line
  echo "GRUB_GFXMODE=$RESOLUTION" >> /etc/default/grub
fi

print_success "GRUB configuration updated with new font and resolution ($RESOLUTION)"

# Step 5: Update GRUB configuration file
print_step "Generating updated GRUB configuration"

# Check if system uses EFI
if [ -d /boot/efi ]; then
  # EFI system - try to determine the distribution
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRO_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    
    if [ -d "/boot/efi/EFI/$DISTRO_ID" ]; then
      print_success "Detected EFI system with distribution: $DISTRO_ID"
      grub-mkconfig -o "/boot/efi/EFI/$DISTRO_ID/grub.cfg"
    else
      print_success "EFI system detected, using default configuration path"
      grub-mkconfig -o /boot/grub/grub.cfg
    fi
  else
    print_success "EFI system detected, using default configuration path"
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
else
  # Non-EFI system
  print_success "Non-EFI system detected, using default configuration path"
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"
print_success "Temporary files cleaned up"

echo -e "\n\033[1;32m===============================================\033[0m"
echo -e "\033[1;32mGRUB configuration successfully updated:\033[0m"
echo -e "\033[1;32m - Font: DejaVu Sans Mono (size $FONT_SIZE)\033[0m"
echo -e "\033[1;32m - Resolution: $RESOLUTION\033[0m"
echo -e "\033[1;32mThe changes will take effect after rebooting your system\033[0m"
echo -e "\033[1;32mIf you need to revert, restore from $BACKUP_FILE\033[0m"
echo -e "\033[1;32m===============================================\033[0m"
