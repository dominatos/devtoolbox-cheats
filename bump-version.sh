#!/usr/bin/env bash
# beta/tools/bump-version.sh — Automated script for syncing version across files
# It reads the version from the root version.txt and updates VERSION="..." in beta scripts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
VERSION_FILE="$ROOT_DIR/version.txt"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Error: version.txt not found at $VERSION_FILE"
    exit 1
fi

RAW_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
V_VERSION="v${RAW_VERSION}"
echo "Syncing version: $RAW_VERSION"

# Escape versions for sed
escaped_v_version=$(printf '%s\n' "$V_VERSION" | sed -e 's/[\/&]/\\&/g')
escaped_raw_version=$(printf '%s\n' "$RAW_VERSION" | sed -e 's/[\/&]/\\&/g')

# 1. Update Bash Scripts
echo "Updating shell scripts..."
find "$ROOT_DIR" -maxdepth 1 -name "*.sh" -type f | while read -r file; do
    if grep -qE "^(readonly )?VERSION=" "$file"; then
        echo "  -> $(basename "$file")"
        sed -i -E "s/^(readonly )?VERSION=\".*\"/\1VERSION=\"$escaped_v_version\"/" "$file"
    fi
done

# 2. Update KDE Widgets metadata.json
echo "Updating KDE metadata.json files..."
for metadata in "$ROOT_DIR"/kde-widget-plasma*/DevToolboxPlasmoid/metadata.json; do
    if [[ -f "$metadata" ]]; then
        echo "  -> $(echo "$metadata" | sed "s|$ROOT_DIR/||")"
        sed -i -E "s/\"Version\":[[:space:]]*\".*\"/\"Version\": \"$escaped_raw_version\"/" "$metadata"
    fi
done

# 3. Update KDE configGeneral.qml
echo "Updating KDE configGeneral.qml files..."
for config in "$ROOT_DIR"/kde-widget-plasma*/DevToolboxPlasmoid/contents/ui/configGeneral.qml; do
    if [[ -f "$config" ]]; then
        echo "  -> $(echo "$config" | sed "s|$ROOT_DIR/||")"
        sed -i -E "s/DevToolbox Cheats Version:[[:space:]]*v.*/DevToolbox Cheats Version: $escaped_v_version\"/" "$config"
    fi
done

echo "Done! 🎉"
