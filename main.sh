#!/bin/bash
set -eo pipefail

# Configuration
LOG_FILE="install.log"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)"
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_PATH")"
FONT_DIR="${HOME}/.local/share/fonts"

PURGED_PKGS=(
    "libreoffice-*"
    "transmission*"
)
PPA_S=(
    # "zeal-developers/ppa"
    # "appimagelauncher-team/stable"
    "qbittorrent-team/qbittorrent-stable"
    "danielrichter2007/grub-customizer"
)

exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    if [ "$#" -gt 0 ]; then
        # Execute command and tee to log file
        echo "${BLUE} ▶ $(date '+%Y-%m-%d %H:%M:%S') - Running: $* ${NC}" | tee -a "$LOG_FILE"
        "$@" 2>&1 | tee -a "$LOG_FILE"
    else
        # Log plain text (e.g., for status messages)
        echo "${BLUE} $(date '+%Y-%m-%d %H:%M:%S') - $* ${NC}" | tee -a "$LOG_FILE"
    fi
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi


# Update package lists
log "Updating pacakge lists..."
sudo apt update
success "Package lists updated"

# Remove packages
log "Removing packages..."
for pkg in "${PURGED_PKGS[@]}"; do
    log "Removing ${pkg}"
    sudo apt purge -y "$pkg"
    success "Removed ${pkg}"
done
success "Finished removing packages"

# Installing setup dependencies
log "Installing setup dependencies..."
sudo apt install -y \
    apt-transport-https \
    aria2 \
    build-essential \
    curl \
    gcc \
    git \
    jq \
    nala \
    p7zip-full 7zip-rar \
    wget \
    yq \

success "Installed setup dependencies"

# Adding PPAs
log "Adding PPAs"
for ppa in "${PPA_S[@]}"; do
    log "Adding ${ppa}"
    sudo apt add-repository -y "ppa:$ppa"
    success "Added ${ppa}"
done
success "Added PPAs"

# Configuring nala
log "Configuring nala..."
sudo nala --install-completion bash
sudo nala fetch --auto
success "Configured nala"

# Setting up other PPAs/sources with scripts
log "Adding other sources with scripts..."
bash ./sources/brave_browser.sh;
bash ./sources/sublime_text.sh;
bash ./sources/vscodium.sh;
bash ./sources/protonvpn.sh;
success "Added other PPAs with scripts"

# Upgrading system
log "Upgrading system..."
sudo nala upgrade -y
success "Upgraded system"

# Installing packages
log "Installing apt packages"
sudo nala install -y \
    audacious \
    brave-browser \
    cht.sh \
    clementine \
    codium \
    duf \
    duff \
    firefox \
    flameshot \
    foliate \
    fzf \
    grub-customizer \
    guake \
    lsd \
    pdfarranger \
    proton-vpn-gnome-desktop \
    python3-dev \
    python3-pip \
    qbittorrent \
    shellcheck \
    stow \
    sublime-text \
    tldr \
    torbrowser-launcher \
    vlc \
    zeal \

success "Installed packages with apt"

log "Installing packages with scripts..."
bash installers/golang.sh
bash installers/vivaldi.sh
bash installers/starship.sh
bash installers/jackett.sh
bash installers/qemu.sh
bash installers/nf_dl.sh
success "Installed packages using scripts"

log "Installing packages that can be done with a command"
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
success "Installed packages with command"

log "Installing packages with flatpak..."
flatpak install -y \
    app.zen_browser.zen \
    com.bitwarden.desktop \
    com.rtosta.zapzap \
    io.github.prateekmedia.appimagepool \
    it.mijorus.gearlever \

success "Installed flatpak packages"

log "Setting up dotfiles..."
bash config/scripts/dotfiles.sh

log "Copying fonts to fonts folder"
cp -r "${SCRIPT_PARENT_DIR}/config/assets/font/." "$FONT_DIR"
fc-cache -fvr "$FONT_DIR" > /dev/null 2>&1


log "Settings..."
sudo ufw enable
sudo ufw allow ssh
sudo timedatectl set-timezone UTC
sudo bash disable_touchscreen.sh

log "Backing up grub..."
sudo cp /etc/default/grub /etc/default/grub.bak

log "Configuring grub..."
sudo bash ./config/scripts/config_grub_menu.sh 24 1920x1080
sudo bash ./config/scripts/grub_boot_last_os.sh
