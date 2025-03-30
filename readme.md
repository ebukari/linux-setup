# Ubuntu (and Derivatives) Setup Script

## Steps
 - Update package list
 - Remove unnecessary packages marked for removal
 - Install packages needed for setup
 - Setup PPAs
 - Upgrade
 - Install programs & software
    - Install the ones with custom installers first
    - Add the PPAs for the one that require PPAs
    - Update package list to pull from new PPAs
    - Install all remaining packages
 - Copy dotfiles
 - Make settings

**Packages to remove**
>  - LibreOffice*
>  - Transmission-gtk

**Initial packages to install**
> - nala
> - git
> - build-essential
> - gcc
> - apt-transport-https
> - curl
> - wget
> - aria2c
> - homebrew
> - yq, jq
> - 7zip-full
> - 7zip-rar

## Software

**Multimedia**
 - Vlc
 - Audacious
 - Clementine

**Developer**
 - Golang
 - Rust
 - Python
 - Zeal (Documentation browser)
 - Zed
 - Sublime Text
 - VsCodium
 - Shellcheck

**Internet**
 - qBittorrent
 - Jackett
 - ProtonVPN
 - Mailspring
 - Tor browser
 - Zapzap (Whatsapp)

**Browsers**
 - Brave
 - Mozilla
 - Vivaldi
 - Edge
 - Zen
 - Tor browser

**Utility**
 - Starship (Shell prompt customiser)
 - Flameshot
 - tldr
 - lsd
 - fzf
 - Grub customiser
 - GNU stow
 - qemu
 - guake
 - Bitwarden

**Office & Productivity**
 - Obsidian
 - Calibre
 - Foliate
 - PDF Arranger

## Settings
 - Disable touchscreen
 - Enable firewall
 - Update system
 - Allow ssh through firewall
 - Set timezone to UTC
 - Configure git
 ```
 git config --global init.defaultBranch master
 ```
 - Set wallpaper
 - Setup dotfiles

## Sources
 - [Preslav Mihaylov Blog Post](https://pmihaylov.com/automate-os-setup/) and [script](https://github.com/presmihaylov/default-setups/blob/master/ubuntu/install.sh)
 - Sayed Ibrahim's [Windows setup script](https://github.com/sayedihashimi/sayed-tools/blob/master/machine-setup.ps1)
