#!/bin/bash

# Check if already installed
if dpkg -s vivaldi-stable &> /dev/null; then
    echo "Vivaldi already installed"
    exit 0
fi

# Get download URL
url=$(curl -s https://vivaldi.com/download/ | grep -oP 'href="\K[^"]*amd64\.deb' | head -n 1)
[[ $url == //* ]] && url="https:$url"

# Download package
wget "$url" -O vivaldi.deb

# Install with checks
sudo dpkg -i vivaldi.deb || true
sudo apt install -f -y
rm vivaldi.deb
