#!/bin/bash
# macOS-beta/generate-tldr.sh — macOS wrapper for TLDR page generator
# Thin wrapper that overrides Linux-incompatible functions,
# then sources the original Linux script for shared core logic.
#
# Requires: Bash 4+ (macOS ships with 3.2)
# This script auto-detects and re-executes with Homebrew Bash if needed.

# --- Auto-detect Bash 4+ and re-exec if needed ---
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    for bash_path in /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash; do
        if [[ -x "$bash_path" ]]; then
            exec "$bash_path" "$0" "$@"
        fi
    done
    echo "ERROR: Bash 4+ required. Install with: brew install bash" >&2
    exit 1
fi

set -euo pipefail

# ============= Source Platform Abstraction =============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/compat.sh"

# ============= Resolve Script Path =============
LINUX_SCRIPT_PATH="${SCRIPT_DIR}/../generate-tldr.sh"

# ============= Override: meta_val() =============
# Line 63-69 in original — replace sed BOM stripping for BSD sed
meta_val() {
    local file="$1" key="$2"
    if [[ "$PLATFORM" == "macos" ]]; then
        # macOS: use perl for BOM stripping (BSD sed behaves differently)
        perl -pe 's/^\xEF\xBB\xBF//' "$file" | head -n 80 \
            | tr -d '\r' \
            | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
            | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
    else
        sed '1s/^\xEF\xBB\xBF//' "$file" | head -n 80 \
            | tr -d '\r' \
            | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
            | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
    fi
}

# ============= Override: page_name_from_source() =============
# Line 76-86 in original — replace ${name,,} for bash 3.2 compatibility
page_name_from_source() {
    local src="$1"
    local name
    name="$(basename "$src" .md)"
    name="${name%cheatsheet}"
    name="${name%_cheatsheet}"
    name="${name%-cheatsheet}"
    name="${name%_}"
    name="${name%-}"
    if [[ "$PLATFORM" == "macos" ]]; then
        # macOS: use tr for lowercase (bash 3.2 doesn't support ${var,,})
        echo "$name" | tr '[:upper:]' '[:lower:]'
    else
        echo "${name,,}"
    fi
}

# ============= Override: main() =============
# Line 532-565 in original — replace mapfile for bash 3.2 compatibility
main() {
    parse_args "$@"
    validate_paths

    local source_files=()
    if [[ "$PLATFORM" == "macos" ]]; then
        # macOS: use while loop instead of mapfile
        while IFS= read -r file; do
            source_files+=("$file")
        done < <(find -L "$SOURCE_DIR" -type f -name '*.md' | sort -f)
    else
        mapfile -t source_files < <(find -L "$SOURCE_DIR" -type f -name '*.md' | sort -f)
    fi
    files_scanned="${#source_files[@]}"

    local staging_platform_dir
    staging_platform_dir="$OUTPUT_DIR/pages/$PLATFORM_DIR"

    if (( CHECK_ONLY == 0 && DRY_RUN == 0 )); then
        rm -rf "$staging_platform_dir"
        mkdir -p "$staging_platform_dir"
    fi

    local src page_name staging_dest cache_dest
    for src in "${source_files[@]}"; do
        page_name="$(page_name_from_source "$src")"
        staging_dest="$(staging_page_path "$page_name")"
        cache_dest="$(cache_page_path "$page_name")"

        if (( CHECK_ONLY )); then
            check_output_file "$src" "$page_name" "$staging_dest" "$cache_dest"
        else
            write_output_file "$src" "$page_name" "$staging_dest" "$cache_dest"
        fi
    done

    print_summary

    if (( CHECK_ONLY )) && (( stale_files > 0 )); then
        exit 1
    fi
}

# ============= Source Linux Script =============
# This loads all the remaining functions and logic
source "$LINUX_SCRIPT_PATH"
