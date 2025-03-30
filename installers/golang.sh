#!/bin/bash

# Install Latest Go Lang
# Works for Linux/macOS (amd64/arm64)

set -e  # Exit on error

# Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv*) ARCH="armv6l" ;;
esac

# Get latest version
LATEST=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-'${ARCH}'\.tar\.gz' | head -n 1 | grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?')

if [ -z "$LATEST" ]; then
    echo "Could not find latest Go version"
    exit 1
fi

# Package details
FILENAME="go$LATEST.$OS-$ARCH.tar.gz"
URL="https://dl.google.com/go/$FILENAME"

# Download and verify checksum
echo "Downloading Go $LATEST..."
curl -LO $URL
curl -LO https://dl.google.com/go/go$LATEST.sha256

# Verify checksum
sha256sum -c go$LATEST.sha256 2>/dev/null | grep OK || {
    echo "Checksum verification failed!"
    exit 1
}

# Install Go
echo "Installing to /usr/local..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf $FILENAME

# Update PATH
SHELL_PROFILE="$HOME/.bashrc"
[[ "$SHELL" == *zsh* ]] && SHELL_PROFILE="$HOME/.zshrc"

echo "Updating $SHELL_PROFILE..."
echo -e "\n# Go Lang Path" >> $SHELL_PROFILE
echo 'export PATH=$PATH:/usr/local/go/bin' >> $SHELL_PROFILE
# echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $SHELL_PROFILE

# Cleanup
rm go$LATEST.sha256 $FILENAME

# Verify installation
source $SHELL_PROFILE
echo -e "\nInstalled version:"
go version
echo "Run 'source $SHELL_PROFILE' or restart your terminal"

echo "Installing go tools"
go install github.com/cweill/gotests/gotests@latest
go install github.com/fatih/gomodifytags@latest
go install github.com/josharian/impl@latest
go install github.com/haya14busa/goplay/cmd/goplay@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
# For bash development
go install mvdan.cc/sh/v3/cmd/gosh@latest
