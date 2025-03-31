#!/bin/bash

ACTUAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# Check if starship is installed
if command -v starship &>/dev/null; then
    echo "Starship already installed"
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Add to bashrc if not present
if ! grep -q "starship init bash" ~/.bashrc; then
    echo 'eval "$(starship init bash)"' >>"$USER_HOME/.bashrc"
else
    echo "starship init added to bashrc already"
fi

# Create config if missing
if [ ! -f "$USER_HOME/.config/starship.toml" ]; then
    mkdir -p "$USER_HOME/.config"
    starship preset pastel-powerline -o "$USER_HOME/.config/starship.toml"
else
    echo "starship config exists"
fi
