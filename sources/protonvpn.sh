#!/bin/bash
set -eo pipefail

# Configuration
DEB_URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"
DEB_FILE="protonvpn-stable-release_1.0.8_all.deb"
EXPECTED_CHECKSUM="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180  protonvpn-stable-release_1.0.8_all.deb"

# Cleanup downloaded file on exit
trap 'rm -f "$DEB_FILE"' EXIT

# Check if ProtonVPN is already installed
if dpkg -s proton-vpn-gnome-desktop &> /dev/null; then
    echo "ProtonVPN is already installed. Skipping installation."
    exit 0
fi

# Download package if missing
if [ ! -f "$DEB_FILE" ]; then
    echo "Downloading ProtonVPN repository package..."
    if ! wget -q "$DEB_URL"; then
        echo "Failed to download package from $DEB_URL" >&2
        exit 1
    fi
fi

# Verify checksum
echo "Verifying package checksum..."
if ! echo "$EXPECTED_CHECKSUM" | sha256sum --check - --status; then
    echo "Checksum verification failed! File may be corrupted." >&2
    exit 1
fi

# Install repository only if missing
if ! grep -q "repo.protonvpn.com" /etc/apt/sources.list.d/*; then
    echo "Installing ProtonVPN repository..."
    sudo dpkg -i "./$DEB_FILE" >/dev/null 2>&1 || {
        sudo apt-get install -f -y
    }
fi
