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

if [[ $# -eq 0 && -t 0 ]]; then
    printf '%s\n' '1) Test alert' '2) Test list dialog' 'q) Quit'
    read -r -p 'Select test: ' test_choice
    case "$test_choice" in
        1) set -- runAlert ;;
        2) set -- runDialog ;;
        *) exit 0 ;;
    esac
fi

if [[ "${1:-}" == runAlert ]]; then
    if osascript -e 'display alert "DevToolbox dialog test" message "Basic macOS GUI access works."'; then
        echo "Alert completed successfully."
        exit 0
    fi
    echo "ERROR: basic macOS alert failed." >&2
    exit 1
fi

if [[ "${1:-}" != runDialog ]]; then
    echo "DevToolbox Dialog Test"
    echo "---"
    echo "Open native macOS list dialog | bash='$script_path' param1=runDialog terminal=false"
    echo "Open native macOS alert      | bash='$script_path' param1=runAlert terminal=false"
    exit 0
fi

dialog_error=""
if ! selection="$(osascript - "DevToolbox Category" "Cheatsheets" \
    "📚 apache" "📦 awk" "🔐 openssl" "🌐 curl" "🛠️ systemctl" \
    "📝 sed" "☁️ aws" "🗃️ mysql" 2>&1 <<'APPLESCRIPT'
on run argv
    set dialog_title to item 1 of argv
    set prompt_text to item 2 of argv
    set choices to items 3 thru -1 of argv
    set selected_item to choose from list choices with prompt prompt_text with title dialog_title
    if selected_item is false then return "CANCELLED"
    return item 1 of selected_item
end run
APPLESCRIPT
)"; then
    dialog_error="$selection"
    echo "ERROR: native macOS list dialog failed:" >&2
    printf '%s\n' "$dialog_error" >&2
    exit 1
fi

if [[ "$selection" == "CANCELLED" ]]; then
    echo "Dialog opened successfully; selection cancelled."
    exit 0
fi

printf 'Dialog opened successfully; selected: %s\n' "$selection"
