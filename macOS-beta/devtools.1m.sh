#!/bin/bash
# macOS-beta/devtools.1m.sh — macOS wrapper for tools menu
# Sets macOS-compatible variables, then sources Linux script for shared logic.

# --- Auto-detect Bash 4+ and re-exec if needed ---
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    for bash_path in /usr/local/bin/bash /opt/homebrew/bin/bash /opt/local/bin/bash; do
        if [[ -x "$bash_path" ]]; then exec "$bash_path" "$0" "$@"; fi
    done
    echo "ERROR: Bash 4+ required. Install with: brew install bash" >&2
    exit 1
fi

set -euo pipefail

# ============= Source Platform Abstraction =============
# Resolve symlink to get actual script directory
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
source "${SCRIPT_DIR}/compat.sh"

# ============= Provide realpath for Linux script =============
realpath() {
  local path="$1"
  [[ "$path" == "-s" ]] && path="$2"
  if [[ -e "$path" ]]; then
    (cd "$(dirname "$path")" && echo "$(pwd)/$(basename "$path")")
  else
    echo "$path"
  fi
}

# ============= Resolve Script Path =============
LINUX_SCRIPT_PATH="${SCRIPT_DIR}/../devtools.1m.sh"

# ============= Set macOS clipboard (before sourcing Linux script) =============
if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
  CLIPBOARD_COPY="pbcopy"
  CLIPBOARD_PASTE="pbpaste"
  CLIPBOARD_MODE="macOS"
else
  echo "❌ Requires pbcopy/pbpaste"
  exit 1
fi

# ============= Source Linux Script =============
# Linux script will see CLIPBOARD_COPY is set and skip its own detection
source "$LINUX_SCRIPT_PATH"

# ============= Override SCRIPT_PATH for xbar =============
SCRIPT_PATH="${SCRIPT_DIR}/devtools.1m.sh"
