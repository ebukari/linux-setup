#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/PROJECTS/dotfiles"
REPO_URL="https://github.com/ebukari/dotfiles.git"

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function confirm() {
    local prompt="$1"
    while true; do
        read -rp "$prompt [y/N] " answer
        case "$answer" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}
mkdir -p ~/PROJECTS

# Clone repo if missing
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo -e "${YELLOW}Dotfiles not found at $DOTFILES_DIR${NC}"
    if confirm "Clone repository from $REPO_URL?"; then
        git clone "$REPO_URL" "$DOTFILES_DIR"
    else
        echo -e "${RED}Aborting: Dotfiles repository required${NC}"
        exit 1
    fi
fi

cd "$DOTFILES_DIR"

# First run: Simulation mode
echo -e "\n${YELLOW}Simulating changes...${NC}"
stow -nRv --target='$USER' --override='.*' */ || {
    echo -e "${RED}Simulation failed - check for errors above${NC}"
    exit 1
}

# Get confirmation
if ! confirm "${GREEN}Would you like to apply these changes?${NC}"; then
    echo -e "${RED}Aborting - no changes made${NC}"
    exit 0
fi

# Second run: Actual execution
echo -e "\n${YELLOW}Applying changes...${NC}"
stow -Rv --target='$USER' --override='.*' */ && \
    echo -e "${GREEN}Successfully linked dotfiles!${NC}"
