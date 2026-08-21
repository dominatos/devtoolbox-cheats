#!/opt/homebrew/bin/bash
# macOS-beta/devtools.1m.sh — macOS wrapper for tools menu
# Thin wrapper that overrides Linux-incompatible functions,
# then sources the original Linux script for shared core logic.
#
# Requires: Homebrew Bash 5+ (/opt/homebrew/bin/bash)

set -Eeuo pipefail

# ============= Source Platform Abstraction =============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/compat.sh"

# ============= Resolve Script Path =============
LINUX_SCRIPT_PATH="${SCRIPT_DIR}/../devtools.1m.sh"

# ============= Override: Clipboard Detection =============
# Lines 28-39 in original
if [[ "$PLATFORM" == "macos" ]]; then
  if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
    CLIPBOARD_COPY="pbcopy"
    CLIPBOARD_PASTE="pbpaste"
    CLIPBOARD_MODE="macOS"
  else
    echo "❌ Requires pbcopy/pbpaste"
    exit 1
  fi
fi

# ============= Override: popup() =============
# Line 43 in original — uses zenity
popup() {
  local title="$1" body="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_text_dialog "$title" "$body"
  else
    echo -e "$body" | zenity --text-info --title="Dev Toolbox: $title" --width=800 --height=500 --filename=/dev/stdin --no-wrap --ok-label="Close" 2>/dev/null
  fi
}

# ============= Override: show() =============
# Line 44 in original — uses notify-send
show() {
  local result
  result="$(cat)"
  copy <<<"$result"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_notify "✅ Dev Toolbox" "$1"
  else
    notify-send "✅ Dev Toolbox" "$1"
  fi
  popup "$1" "$result"
}

# ============= Override: jsonEscape() =============
# Line 49 in original — uses xargs -0
jsonEscape() {
  if [[ "$PLATFORM" == "macos" ]]; then
    # macOS: use sed instead of xargs -0
    paste | jq -R . | jq -s . | jq -r '.[]' | show "Escaped JSON"
  else
    paste | xargs -0 printf "%s" | jq @json | show "Escaped JSON"
  fi
}

# ============= Override: unixToLocal() =============
# Line 61 in original — uses date -d
unixToLocal() {
  local ts
  ts="$(paste)"
  if [[ "$PLATFORM" == "macos" ]]; then
    date -r "$ts" +%Y-%m-%dT%H:%M:%S | show "Local Timestamp"
  else
    date -d "@$ts" +%Y-%m-%dT%H:%M:%S | show "Local Timestamp"
  fi
}

# ============= Override: unixToUTC() =============
# Line 62 in original — uses date -d
unixToUTC() {
  local ts
  ts="$(paste)"
  if [[ "$PLATFORM" == "macos" ]]; then
    date -u -r "$ts" +%Y-%m-%dT%H:%M:%SZ | show "UTC Timestamp"
  else
    date -u -d "@$ts" +%Y-%m-%dT%H:%M:%SZ | show "UTC Timestamp"
  fi
}

# ============= Override: hashMD5() =============
# Line 76 in original — uses md5sum
hashMD5() {
  if [[ "$PLATFORM" == "macos" ]]; then
    paste | md5 -q | show "MD5 Hash"
  else
    paste | md5sum | awk '{print $1}' | show "MD5 Hash"
  fi
}

# ============= Override: hashSHA256() =============
# Line 77 in original — uses sha256sum
hashSHA256() {
  if [[ "$PLATFORM" == "macos" ]]; then
    paste | shasum -a 256 | awk '{print $1}' | show "SHA256 Hash"
  else
    paste | sha256sum | awk '{print $1}' | show "SHA256 Hash"
  fi
}

# ============= Override: getIP() =============
# Line 86 in original — uses hostname -I
getIP() {
  if [[ "$PLATFORM" == "macos" ]]; then
    ipconfig getifaddr en0 2>/dev/null | show "IP Address" || echo "N/A" | show "IP Address"
  else
    hostname -I | awk '{print $1}' | show "IP Address"
  fi
}

# ============= Override: getMAC() =============
# Line 87 in original — uses ip link show
getMAC() {
  if [[ "$PLATFORM" == "macos" ]]; then
    ifconfig en0 2>/dev/null | awk '/ether/{print $2}' | head -n1 | show "MAC Address" || echo "N/A" | show "MAC Address"
  else
    ip link show | awk '/ether/{print $2}' | head -n1 | show "MAC Address"
  fi
}

# ============= Source Linux Script =============
# This loads all the remaining functions and menu output
source "$LINUX_SCRIPT_PATH"
