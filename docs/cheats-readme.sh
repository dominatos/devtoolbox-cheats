#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cheats_dir="${CHEATS_DIR:-$REPO_ROOT/cheats.d}"
readme="${README_FILE:-$REPO_ROOT/README.md}"

if [[ ! -d "$cheats_dir" ]]; then
    echo "Error: Directory not found - $cheats_dir" >&2
    exit 1
fi

if [[ ! -f "$readme" ]]; then
    echo "Error: File not found - $readme" >&2
    exit 1
fi

missing=0

while IFS= read -r cheat; do
    rel_path="${cheat#"$cheats_dir"/}"
    if ! grep -qF "$rel_path" "$readme"; then
        echo "Missing in README: $rel_path"
        missing=$((missing+1))
    fi
done < <(find "$cheats_dir" -type f -name '*.md')

if [[ $missing -eq 0 ]]; then
    echo "All cheatsheets are referenced in README.md"
else
    echo "$missing cheatsheets missing"
fi