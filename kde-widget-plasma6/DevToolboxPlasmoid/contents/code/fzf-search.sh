#!/bin/bash
# FZF search helper for DevToolbox Cheats
# Usage: fzf-search.sh <cheats_dir> <editor>

CHEATS_DIR="${1:-$HOME/cheats.d}"
EDITOR="${2:-code}"

# Check if fzf is installed
if ! command -v fzf >/dev/null 2>&1; then
    echo "ERROR: fzf not installed. Install via apt/dnf/pacman."
    read -rp "Press enter to exit..."
    exit 1
fi

# Search all markdown files with fzf
selected=$(grep -rnH --include='*.md' . "$CHEATS_DIR" 2>/dev/null | \
    fzf --delimiter : \
        --preview 'if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --highlight-line {2} {1}; else cat {1}; fi' \
        --preview-window 'right:60%' \
        --header 'Type to search all cheats... Enter to open.' \
        --bind 'enter:accept') || exit 0

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Extract file and line number
file=$(echo "$selected" | cut -d: -f1)
line=$(echo "$selected" | cut -d: -f2)

# Open in editor
if command -v "$EDITOR" >/dev/null 2>&1; then
    "$EDITOR" -g "$file:$line"
else
    ${EDITOR:-nano} +"$line" "$file"
fi
