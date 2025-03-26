#!/bin/bash

# Example usage:
# install_nerd_fonts FiraCode Hack JetBrainsMono UbuntuMono

install_nerd_fonts() {
    set -euo pipefail
    local -a fonts=("$@")
    local repo="ryanoasis/nerd-fonts"
    local fonts_dir="${HOME}/.local/share/fonts"
    local version tmp_dir

    # Validate input
    if [[ ${#fonts[@]} -eq 0 ]]; then
        echo "Error: No fonts specified" >&2
        return 1
    fi

    # Check dependencies
    local dependencies=("curl" "jq" "wget" "unzip")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is required but not installed" >&2
            return 1
        fi
    done

    # Create temporary directory
    tmp_dir=$(mktemp -d -t nerd-fonts-XXXXXX) || {
        echo "Error: Failed to create temporary directory" >&2
        return 1
    }
    trap 'rm -rf "$tmp_dir"' EXIT

    # Get latest release version
    version=$(curl -sfL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name') || {
        echo "Error: Failed to fetch latest version" >&2
        return 1
    }
    [[ -z "$version" ]] && {
        echo "Error: Empty version received" >&2
        return 1
    }

    # Create fonts directory
    mkdir -p "$fonts_dir" || {
        echo "Error: Failed to create fonts directory: $fonts_dir" >&2
        return 1
    }

    # Download and install fonts
    for font in "${fonts[@]}"; do
        local zip_file="${font}.zip"
        local download_url="https://github.com/${repo}/releases/download/${version}/${zip_file}"
        local tmp_file="${tmp_dir}/${zip_file}"

        echo "→ Downloading ${font} (${version})..."
        if ! curl -sfL "$download_url" -o "$tmp_file" --retry 3; then
            echo "  Error: Failed to download ${font}" >&2
            continue
        fi

        echo "  Installing ${font}..."
        if ! unzip -q "$tmp_file" -d "$fonts_dir"; then
            echo "  Error: Failed to unzip ${font}" >&2
            continue
        fi
    done

    # Clean Windows-compatible fonts
    echo "→ Cleaning Windows-compatible fonts..."
    find "$fonts_dir" -name '*Windows Compatible*' -delete 2>/dev/null || true

    # Update font cache
    echo "→ Updating font cache..."
    fc-cache -fvr "$fonts_dir" > /dev/null 2>&1

    echo "✅ Nerd Fonts installation complete!"
}
