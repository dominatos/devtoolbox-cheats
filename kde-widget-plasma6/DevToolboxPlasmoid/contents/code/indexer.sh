#!/bin/bash
# DevToolbox Indexer Helper
# Usage: ./indexer.sh <cheatsDir> [debugLog]

CHEATS_DIR="$1"
DEBUG_LOG="${2:-/tmp/devtoolbox-debug.log}"

if [ -z "$CHEATS_DIR" ]; then
    echo "ERROR: cheatsDir not provided" >&2
    exit 1
fi

# Ensure UTF-8
export LC_ALL=C.UTF-8

echo "Search Dir: $CHEATS_DIR" > "$DEBUG_LOG"

if [ ! -d "$CHEATS_DIR" ]; then
    echo "Directory not found: $CHEATS_DIR" >> "$DEBUG_LOG"
    exit 1
fi

find -L "$CHEATS_DIR" -type f -name '*.md' | while read -r f; do
    title=$(grep -i -m1 '^Title:' "$f" | sed -E 's/^[Tt][Ii][Tt][Ll][Ee]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')
    group=$(grep -i -m1 '^Group:' "$f" | sed -E 's/^[Gg][Rr][Oo][Uu][Pp]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')
    icon=$(grep -i -m1 '^Icon:' "$f" | sed -E 's/^[Ii][Cc][Oo][Nn]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')
    order=$(grep -i -m1 '^Order:' "$f" | sed -E 's/^[Oo][Rr][Dd][Ee][Rr]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')
    
    [ -z "$title" ] && title=$(basename "$f" .md)
    [ -z "$group" ] && group="Misc"
    [ -z "$order" ] && order=9999
    
    res="$f|$title|$group|$icon|$order"
    echo "$res"
    echo "$res" >> "$DEBUG_LOG"
done
