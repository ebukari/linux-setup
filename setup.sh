#!/bin/bash
set -eo pipefail

# Configuration
CONFIG_FILE="config.yaml"
LOG_FILE="install.log"
TMP_DIR="/tmp/ubuntu_setup"
WHITE='\033[1;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Initialize directories
mkdir -p "$TMP_DIR"

# Load configuration
if ! [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Config file $CONFIG_FILE not found!${NC}"
    exit 1
fi

# Check for yq
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is required but not installed. Run setup.sh first.${NC}"
    exit 1
fi

# ---------------------- Helper Functions ----------------------
log() {
    echo -e "${WHITE}[$(date +'%T')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

install_package() {
    local name="$1"
    local package="$2"
    log "Installing $name..."
    if sudo apt install -y "$package" >> "$LOG_FILE" 2>&1; then
        success "$name installed successfully"
    else
        error "Failed to install $name"
        return 1
    fi
}

# ---------------------- Installation Handlers ----------------------
handle_apt() {
    local entry="$1"
    local name=$(echo "$entry" | yq e '.name' -)
    local package=$(echo "$entry" | yq e '.package' -)
    local source=$(echo "$entry" | yq e '.source' -)
    local source_script=$(echo "$entry" | yq e '.source_script' -)

    # Handle source script
    if [ "$source_script" != "null" ]; then
        log "Running source script for $name"
        if ! bash "$source_script" >> "$LOG_FILE" 2>&1; then
            error "Source script failed for $name"
            return 1
        fi
    fi

    # Handle PPA
    if [ "$source" != "null" ]; then
        log "Adding repository: $source"
        if ! sudo add-apt-repository -y "$source" >> "$LOG_FILE" 2>&1; then
            error "Failed to add repository $source"
            return 1
        fi
    fi

    # Update after adding repositories
    if [ "$source" != "null" ] || [ "$source_script" != "null" ]; then
        sudo apt update >> "$LOG_FILE" 2>&1
    fi

    install_package "$name" "$package"
}

handle_flatpak() {
    local entry="$1"
    local name=$(echo "$entry" | yq e '.name' -)
    local package=$(echo "$entry" | yq e '.package' -)

    log "Installing Flatpak: $name"
    if flatpak install -y "$package" >> "$LOG_FILE" 2>&1; then
        success "$name installed successfully"
    else
        error "Failed to install $name"
        return 1
    fi
}

handle_command() {
    local entry="$1"
    local name=$(echo "$entry" | yq e '.name' -)
    local cmd=$(echo "$entry" | yq e '.package' -)

    log "Executing command: $name"
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        success "$name completed successfully"
    else
        error "Command failed: $name"
        return 1
    fi
}

handle_custom() {
    local entry="$1"
    local name=$(echo "$entry" | yq e '.name' -)
    local script=$(echo "$entry" | yq e '.script' -)

    log "Running custom script: $name"
    if bash "$script" >> "$LOG_FILE" 2>&1; then
        success "$name installed successfully"
    else
        error "Custom script failed: $name"
        return 1
    fi
}

handle_settings() {
    local type="$1"
    local entry="$2"
    local name=$(echo "$entry" | yq e '.name' -)

    case "$type" in
        "command")
            local cmd=$(echo "$entry" | yq e '.command' -)
            log "Applying setting: $name"
            if eval "$cmd" >> "$LOG_FILE" 2>&1; then
                success "Setting applied: $name"
            else
                error "Failed to apply setting: $name"
            fi
            ;;
        "script")
            local script=$(echo "$entry" | yq e '.script' -)
            log "Running settings script: $name"
            if bash "$script" >> "$LOG_FILE" 2>&1; then
                success "Settings script completed: $name"
            else
                error "Settings script failed: $name"
            fi
            ;;
    esac
}

# ---------------------- Main Logic ----------------------
main() {
    # Parse arguments
    local INTERACTIVE=true
    while getopts ":y" opt; do
        case $opt in
            y) INTERACTIVE=false;;
        esac
    done

    # Step 1: Update package list
    log "Updating package lists..."
    sudo apt update >> "$LOG_FILE" 2>&1
    success "Package lists updated"

    # Step 2: Remove unnecessary packages
    log "Cleaning up packages..."
    sudo apt autoremove -y >> "$LOG_FILE" 2>&1
    success "Package cleanup completed"

    # Step 3: Install setup dependencies
    log "Installing setup dependencies..."
    sudo apt install -y software-properties-common >> "$LOG_FILE" 2>&1

    # Installation selection
    if [ "$INTERACTIVE" = true ]; then
        # TODO: Implement interactive selection using whiptail
        echo "Interactive selection not implemented yet, installing all packages"
    fi

    # Process installations
    declare -a sections=("apt" "flatpak" "commands" "custom")
    for section in "${sections[@]}"; do
        count=$(yq e ".$section | length" "$CONFIG_FILE")
        for ((i=0; i<$count; i++)); do
            entry=$(yq e ".$section[$i]" "$CONFIG_FILE")
            case "$section" in
                "apt") handle_apt "$entry";;
                "flatpak") handle_flatpak "$entry";;
                "commands") handle_command "$entry";;
                "custom") handle_custom "$entry";;
            esac
        done
    done

    # Step 6: Upgrade
    log "Performing system upgrade..."
    sudo apt full-upgrade -y >> "$LOG_FILE" 2>&1
    success "System upgraded"

    # Step 7-8: Handle settings
    count=$(yq e ".settings.commands | length" "$CONFIG_FILE")
    for ((i=0; i<$count; i++)); do
        entry=$(yq e ".settings.commands[$i]" "$CONFIG_FILE")
        handle_settings "command" "$entry"
    done

    count=$(yq e ".settings.scripts | length" "$CONFIG_FILE")
    for ((i=0; i<$count; i++)); do
        entry=$(yq e ".settings.scripts[$i]" "$CONFIG_FILE")
        handle_settings "script" "$entry"
    done

    success "All operations completed!"
}

# Execute main function
main "$@"
