#!/bin/bash

# Example usage:
# url=$(get_gh_asset_url "owner/repo" "substring1,substring2" "zip")
# if [ $? -eq 0 ]; then
#     wget "$url"
# else
#     echo "Failed to find asset"
# fi

get_gh_asset_url() {
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        echo "Usage: get_github_asset_url <owner/repo> <comma-separated substrings> [extension]" >&2
        return 1
    fi

    local REPO="$1"
    local SUBSTRINGS="$2"
    local EXTENSION="${3:-}"
    local REGEX_PATTERN
    local API_URL RESPONSE ASSET_URLS URL FILENAME

    # Build regex pattern from substrings
    IFS=',' read -ra PARTS <<<"$SUBSTRINGS"
    REGEX_PATTERN="$(printf '(?=.*%s)' "${PARTS[@]}")"
    [[ -n "$EXTENSION" ]] && REGEX_PATTERN+=".*\\.${EXTENSION}$" || REGEX_PATTERN+=".*"

    # Get latest release data
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    RESPONSE=$(curl -s "$API_URL") || return 1

    # Extract asset URLs
    ASSET_URLS=$(echo "$RESPONSE" | jq -r '.assets[] | .browser_download_url' 2>/dev/null)

    # Find first matching asset
    for URL in $ASSET_URLS; do
        FILENAME=$(basename "$URL")
        if [[ "$FILENAME" =~ $REGEX_PATTERN ]]; then
            echo "$URL"
            return 0
        fi
    done

    # Error message if no match found
    echo "No matching asset found with:" >&2
    echo "  Substrings: ${SUBSTRINGS//,/ }" >&2
    [[ -n "$EXTENSION" ]] && echo "  Extension: .$EXTENSION" >&2
    return 1
}
