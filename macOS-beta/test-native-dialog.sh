#!/usr/bin/env bash
# Minimal macOS native dialog smoke test.

set -u

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: run this test on macOS." >&2
    exit 1
fi

if ! command -v osascript >/dev/null 2>&1; then
    echo "ERROR: osascript is required." >&2
    exit 1
fi

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

if [[ "${1:-}" != runDialog ]]; then
    echo "DevToolbox Dialog Test"
    echo "---"
    echo "Open native macOS list dialog | bash='$script_path' param1=runDialog terminal=false"
    exit 0
fi

selection="$(osascript - <<'APPLESCRIPT'
on run
    set selected_item to choose from list {"Search cheats", "Browse all cheats", "Settings"} with prompt "Choose an action" with title "DevToolbox Dialog Test"
    if selected_item is false then return "CANCELLED"
    return item 1 of selected_item
end run
APPLESCRIPT
)"

if [[ "$selection" == "CANCELLED" ]]; then
    echo "Dialog opened successfully; selection cancelled."
    exit 0
fi

printf 'Dialog opened successfully; selected: %s\n' "$selection"
