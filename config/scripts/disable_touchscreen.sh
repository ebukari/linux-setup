#!/bin/bash

# Path to the libinput configuration file
CONFIG_FILE="/usr/share/X11/xorg.conf.d/40-libinput.conf"

# Check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Create a backup of the original file
sudo cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
echo "Created backup: $CONFIG_FILE.backup"

# Add configuration to disable touchscreen
cat << EOF | sudo tee -a "$CONFIG_FILE"

# Disable touchscreen
Section "InputClass"
        Identifier "Disable touchscreen"
        MatchIsTouchscreen "on"
        Option "Ignore" "on"
EndSection
EOF

echo "Touchscreen disabled in X11 configuration."
echo "You'll need to restart your X session (log out and log back in) or restart your computer for changes to take effect."
