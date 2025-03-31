#!/bin/bash
set -eo pipefail

# Configuration
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)"
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_PATH")"
LOG_FILE="${SCRIPT_PARENT_DIR}/install.log"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


FONT_DIR="${HOME}/.local/share/fonts"
SUDO_USER=$(logname)
if [[ -z "$SUDO_USER" ]]; then
    SUDO_USER=$(who am i | awk '{print $1}')
fi

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
    echo -e "${BLUE}ⓘ $(date '+%Y-%m-%d %H:%M:%S') - $* ${NC}"
}

success() {
    echo -e "${GREEN}✓ $(date '+%Y-%m-%d %H:%M:%S') $1${NC}"
}

error() {
    echo -e "${RED}✗ $(date '+%Y-%m-%d %H:%M:%S') $1${NC}"
}

run_scripts_in_dir() {
    local dir="$1"
    log "Running scripts in directory: ${dir}"

    # Get sorted list of executable scripts
    local scripts=()
    while IFS= read -r -d $'\0' script; do
        scripts+=("$script")
    done < <(find "${dir}" -maxdepth 1 -name '*.sh' -executable -print0 | sort -Vz)

    # Handle case where no scripts found
    if [[ ${#scripts[@]} -eq 0 ]]; then
        log "No executable scripts found in ${dir}"
        return 0
    fi

    # Execute each script
    for script in "${scripts[@]}"; do
        log "Running $(basename "${script}")"
        if ! bash "${script}"; then
            error "Failed to run script: ${script}"
            exit 1
        fi
        success "Completed: ${script}"
    done
}

validate_ppa() {
    local ppa="$1"
     ls /etc/apt/sources.list.d/*"${ppa/\//-}"*.list &>/dev/null || return 0
}

check_command() {
    local cmd="$1"
    local user="${2:-}"

    if [[ -n "$user" ]]; then
        su - "$user" -c "type -P \"$cmd\"" &>/dev/null
    else
        type -P "$cmd" &>/dev/null
    fi
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi


# Update package lists
log "Updating package lists..."
if apt update; then
    success "Package lists updated"
else
    error "Package list update encountered errors. Continuing..."
fi

# Remove packages
log "Removing packages..."
for pkg_pattern in "${PURGED_PKGS[@]}"; do
    apt purge -y "${pkg_pattern}"
done
success "Finished removing packages"

log "Cleaning up after purging packages..."
apt autoremove -y

# Installing setup dependencies
log "Installing setup dependencies..."
apt install -y \
    software-properties-common \
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

log "Configuring nala.."
if [[ ! -f /etc/apt/sources.list.d/nala-sources.list ]]; then
    nala fetch --auto
else
    log "Nala mirrors already configured"
fi
su - "$SUDO_USER" -c "nala --install-completion bash"
success "Configured nala"

# Adding PPAs
log "Adding PPAs"
for ppa in "${PPA_S[@]}"; do
    if validate_ppa "$ppa"; then
        log "Adding ${ppa}"
        apt add-repository -y "ppa:$ppa"
        success "Added ${ppa}"
    fi
done

log "Updating packages list after adding PPA's"
if nala update; then
    success "Package lists updated"
else
    error "Package list update encountered errors. Continuing..."
fi
success "Added PPAs"

# Setting up other PPAs/sources with scripts
log "Adding other sources with scripts..."
run_scripts_in_dir "${SCRIPT_PARENT_DIR}/sources"
success "Added other PPAs with scripts"

if nala update; then
    success "Package lists updated"
else
    error "Package list update encountered errors. Continuing..."
fi


# Upgrading system
log "Upgrading system..."
nala upgrade -y
success "Upgraded system"

# Installing packages
log "Installing apt packages"
nala install -y \
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
run_scripts_in_dir "${SCRIPT_PARENT_DIR}/installers"
success "Installed packages using scripts"

log "Installing packages that can be done with a command"
# Calibre
if ! check_command calibre; then
    log "Installing Calibre"
    wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin
    success "Installed Calibre"
else
    log "Calibre already installed"
fi

# Rust
if ! check_command rustup "$SUDO_USER"; then
    log "Installing Rustup"
    su - "$SUDO_USER" -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh'
    success "Installed Rustup"
else
    log "Rustup already installed"
fi

success "Installed packages with command"

log "Cleaning up packages..."
nala clean

log "Installing packages with flatpak..."
su - "$SUDO_USER" -c 'flatpak install -y \
    app.zen_browser.zen \
    com.bitwarden.desktop \
    com.rtosta.zapzap \
    io.github.prateekmedia.appimagepool \
    it.mijorus.gearlever'

success "Installed flatpak packages"

log "Setting up dotfiles..."
bash "${SCRIPT_PARENT_DIR}/config/scripts/dotfiles.sh"

log "Copying fonts to fonts folder"
if [[ -d "${SCRIPT_PARENT_DIR}/config/assets/font" ]]; then
    mkdir -p "$FONT_DIR"
    log "Copying fonts (no-clobber)"
    su - "$SUDO_USER" -c "cp -nv \"${SCRIPT_PARENT_DIR}/config/assets/font/\"* \"$FONT_DIR/\""
    su - "$SUDO_USER" -c "fc-cache -fvr \"$FONT_DIR\""
else
    error "Font directory not found"
fi

log "Settings..."
ufw enable
ufw allow ssh
timedatectl set-timezone UTC
bash "${SCRIPT_PARENT_DIR}/config/scripts/disable_touchscreen.sh"

log "Backing up grub before changes..."
if [[ -f /etc/default/grub.bak ]]; then
    log "Existing grub backup found"
else
    cp -v /etc/default/grub /etc/default/grub.bak
fi

# Only run config scripts if grub needs updating
log "Configuring grub..."
current_hash=$(md5sum /etc/default/grub)
bash "${SCRIPT_PARENT_DIR}/config/scripts/config_grub_menu.sh" 24 1920x1080
bash "${SCRIPT_PARENT_DIR}/config/scripts/grub_boot_last_os.sh"
new_hash=$(md5sum /etc/default/grub)

if [[ "$current_hash" != "$new_hash" ]]; then
    log "Updating grub configuration"
    update-grub
else
    log "Grub configuration unchanged"
fi
