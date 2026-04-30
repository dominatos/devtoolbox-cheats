#!/bin/bash
# DevToolbox Fast Indexer with Caching
# Usage: ./indexer.sh <cheatsDir> [debugLog] [cacheFile]

CHEATS_DIR="$1"
DEBUG_LOG="${2:-/tmp/devtoolbox-debug.log}"
CACHE_FILE="${3:-$HOME/.cache/devtoolbox-cheats-index.cache}"

if [ -z "$CHEATS_DIR" ]; then
    echo "ERROR: cheatsDir not provided" >&2
    exit 1
fi

# Ensure UTF-8
export LC_ALL=C.UTF-8

echo "Search Dir: $CHEATS_DIR" > "$DEBUG_LOG"
echo "Cache File: $CACHE_FILE" >> "$DEBUG_LOG"

if [ ! -d "$CHEATS_DIR" ]; then
    echo "Directory not found: $CHEATS_DIR" >> "$DEBUG_LOG"
    exit 1
fi

# Create cache directory if needed
mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null

# Function to check if cache is valid
# Cache is valid if it exists and is newer than all .md files
check_cache_valid() {
    [ -f "$CACHE_FILE" ] || return 1
    
    # Find newest .md file
    local newest_md=$(find -L "$CHEATS_DIR" -type f -name '*.md' -printf '%T@\n' 2>/dev/null | sort -nr | head -1)
    [ -z "$newest_md" ] && return 1
    
    # Get cache timestamp
    local cache_time=$(stat -c '%Y' "$CACHE_FILE" 2>/dev/null || echo "0")
    
    # Cache is valid if newer than newest md file
    local newest_md_int=${newest_md%.*}  # Remove decimal part
    [ "$cache_time" -gt "$newest_md_int" ]
}

# If cache is valid, use it
if check_cache_valid; then
    echo "Using cache (valid)" >> "$DEBUG_LOG"
    cat "$CACHE_FILE"
    exit 0
fi

echo "Rebuilding cache (stale or missing)" >> "$DEBUG_LOG"

# Build new index
temp_output=$(mktemp)

find -L "$CHEATS_DIR" -type f -name '*.md' 2>/dev/null | while read -r f; do
    # Fast metadata extraction using single sed pass
    metadata=$(head -80 "$f" | sed -n '
        /^[Tt][Ii][Tt][Ll][Ee]:[[:space:]]*/{
            s///
            s/[[:space:]]*$//
            s/\r//g
            h
        }
        /^[Gg][Rr][Oo][Uu][Pp]:[[:space:]]*/{
            s///
            s/[[:space:]]*$//
            s/\r//g
            H
        }
        /^[Ii][Cc][Oo][Nn]:[[:space:]]*/{
            s///
            s/[[:space:]]*$//
            s/\r//g
            H
        }
        /^[Oo][Rr][Dd][Ee][Rr]:[[:space:]]*/{
            s///
            s/[[:space:]]*$//
            s/\r//g
            H
        }
        ${
            x
            s/\n/|/g
            p
        }
    ')
    
    # Parse metadata (format: title|group|icon|order)
    IFS='|' read -r title group icon order <<< "$metadata"
    
    # Set defaults
    [ -z "$title" ] && title=$(basename "$f" .md)
    [ -z "$group" ] && group="Misc"
    [ -z "$order" ] && order=9999
    
    # Output format: path|title|group|icon|order
    echo "$f|$title|$group|$icon|$order"
done | tee "$temp_output" "$DEBUG_LOG"

# Save to cache
mv "$temp_output" "$CACHE_FILE" 2>/dev/null || cp "$temp_output" "$CACHE_FILE"
rm -f "$temp_output"

echo "Cache saved" >> "$DEBUG_LOG"
