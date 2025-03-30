#!/usr/bin/env bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)"
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_PATH")"

EXTENSIONS_FILE="${SCRIPT_PARENT_DIR}/codium_extensions.txt"

# Check if the extensions file exists
if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "Error: Extensions file $EXTENSIONS_FILE not found!"
    exit 1
fi

# Check if code command is available
if ! command -v codium &> /dev/null; then
    echo "Error: VSCodium OSS 'code' command is not in PATH."
    exit 1
fi

# Read file line by line, skipping empty lines and comments
while IFS= read -r extension; do
    # Remove leading/trailing whitespace and skip empty lines
    extension=$(echo "$extension" | xargs)

    if [[ -n "$extension" ]]; then
        echo "Installing: $extension"
        codium --install-extension "$extension"
    fi
done < <(grep -v '^[[:space:]]*$' "$EXTENSIONS_FILE")

echo "Extension installation complete!"
