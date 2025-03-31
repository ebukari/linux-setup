#!/bin/bash

set -e

ACTUAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv*) ARCH="armv6l" ;;
esac

# Check existing Go installation
if command -v go &> /dev/null; then
    INSTALLED_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+(\.[0-9]+)?')
    echo "Go $INSTALLED_VERSION already installed"
    exit 0
fi

# Get latest version
LATEST=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-'${ARCH}'\.tar\.gz' | head -n 1 | grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?')

if [ -z "$LATEST" ]; then
    echo "Could not find latest Go version"
    exit 1
fi

# Package details
FILENAME="go$LATEST.$OS-$ARCH.tar.gz"
URL="https://dl.google.com/go/$FILENAME"

# Download and install
echo "Downloading Go $LATEST..."
curl -LO $URL

echo "Installing to /usr/local..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf $FILENAME

# Update PATH if not already exists
SHELL_PROFILE="$USER_HOME/.bashrc"
[[ "$SHELL" == *zsh* ]] && SHELL_PROFILE="$USER_HOME/.zshrc"

if ! grep -q "/usr/local/go/bin" "$SHELL_PROFILE"; then
    echo "Updating $SHELL_PROFILE..."
    echo -e "\n# Go Lang Path" >> "$SHELL_PROFILE"
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$SHELL_PROFILE"
fi

# Cleanup
echo "Cleaning up"
rm -f $FILENAME

# Verify installation
if source "$SHELL_PROFILE"; then
   echo "Refreshed bash profile"
else
    echo "Some errors while loading bash profile"
fi

echo -e "\nInstalled version:"
su - "$ACTUAL_USER" -c "go version"

# Install tools if not present
declare -A tools=(
    [gotests]="github.com/cweill/gotests/gotests@latest"
    [gomodifytags]="github.com/fatih/gomodifytags@latest"
    [impl]="github.com/josharian/impl@latest"
    [goplay]="github.com/haya14busa/goplay/cmd/goplay@latest"
    [dlv]="github.com/go-delve/delve/cmd/dlv@latest"
    [staticcheck]="honnef.co/go/tools/cmd/staticcheck@latest"
    [gosh]="mvdan.cc/sh/v3/cmd/gosh@latest"
)

for cmd in "${!tools[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Installing $cmd..."
        go install "${tools[$cmd]}"
    fi
done
