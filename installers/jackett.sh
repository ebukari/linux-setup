#!/bin/bash

JACKETT_DIR="/opt/Jackett"
SERVICE_FILE="/etc/systemd/system/jackett.service"
ACTUAL_USER=${SUDO_USER:-$(whoami)}

# Check if service is active
if systemctl is-active --quiet jackett.service; then
    echo "Jackett service already running"
    exit 0
fi

# Create directory if needed
sudo mkdir -p /opt
cd /opt || exit

# Download only if newer version exists
f=Jackett.Binaries.LinuxAMDx64.tar.gz
sudo wget -Nc https://github.com/Jackett/Jackett/releases/latest/download/"$f"

# Verify file integrity
if ! tar -tzf "$f" >/dev/null 2>&1; then
    echo "Invalid download file, removing..."
    sudo rm -f "$f"
    exit 1
fi

# Extract and install
sudo tar -xzf "$f"
sudo rm -f "$f"
cd Jackett* || exit

# Set permissions
sudo chown "${ACTUAL_USER}:$(id -gn ${ACTUAL_USER})" -R "$JACKETT_DIR"

# Install service if not exists
if [ ! -f "$SERVICE_FILE" ]; then
    sudo ./install_service_systemd.sh
    sudo systemctl daemon-reload
fi

# Start service
sudo systemctl enable --now jackett.service
systemctl status jackett.service
