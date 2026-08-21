#!/usr/bin/env bash
# macOS-beta/compat.sh — Platform abstraction layer for macOS
# Provides macOS-compatible versions of commands used by Linux scripts.
# Source this file before sourcing the Linux script.

# Prevent double-sourcing
[[ -n "${_COMPAT_SH_LOADED:-}" ]] && return
_COMPATAT_SH_LOADED=1

# ============= Platform Detection =============
detect_platform() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    *)       echo "linux" ;;
  esac
}

PLATFORM="$(detect_platform)"

# ============= Clipboard =============
# macOS: pbcopy/pbpaste
# Linux: wl-copy/wl-paste or xclip (set by caller)
compat_clipboard_copy() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v pbcopy >/dev/null 2>&1; then
      CLIPBOARD_COPY="pbcopy"
    else
      CLIPBOARD_COPY=""
    fi
  fi
  # On Linux, CLIPBOARD_COPY is set by the Linux script
}

compat_clipboard_paste() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v pbpaste >/dev/null 2>&1; then
      CLIPBOARD_PASTE="pbpaste"
    else
      CLIPBOARD_PASTE=""
    fi
  fi
  # On Linux, CLIPBOARD_PASTE is set by the Linux script
}

# ============= Notifications =============
# macOS: osascript
# Linux: notify-send
compat_notify() {
  local title="$1" msg="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
    fi
  else
    notify-send "$title" "$msg" 2>/dev/null || true
  fi
}

# ============= Dialogs =============
# macOS: osascript or fzf
# Linux: zenity/yad/kdialog

compat_input_dialog() {
  local title="$1" prompt="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "text returned of (display dialog \"$prompt\" default answer \"\" with title \"$title\")" 2>/dev/null
    elif command -v fzf >/dev/null 2>&1; then
      echo "" | fzf --prompt="$prompt > "
    else
      read -rp "$prompt: " reply; echo "$reply"
    fi
  else
    # Linux: use the caller's detect_dialog_tool
    return 1
  fi
}

compat_info_dialog() {
  local title="$1" msg="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display dialog \"$msg\" with title \"$title\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null || true
    else
      echo "=== $title ==="
      echo "$msg"
      read -rp "Press Enter to continue..."
    fi
  else
    return 1
  fi
}

compat_list_dialog() {
  local title="$1" col="$2"
  shift 2
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v fzf >/dev/null 2>&1; then
      if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@" | fzf --prompt="$title > "
      else
        fzf --prompt="$title > "
      fi
    else
      # Fallback: use osascript with choose from list
      if [[ $# -gt 0 ]]; then
        local items
        items=$(printf '"%s", ' "$@" | sed 's/, $//')
        osascript -e "choose from list {${items}} with prompt \"$title\"" 2>/dev/null
      fi
    fi
  else
    return 1
  fi
}

compat_text_dialog() {
  local title="$1" body="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display dialog \"$body\" with title \"$title\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null || true
    else
      echo "=== $title ==="
      echo "$body"
      read -rp "Press Enter to continue..."
    fi
  else
    return 1
  fi
}

# ============= Open URL / File =============
# macOS: open
# Linux: xdg-open
compat_open_url() {
  local url="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    open "$url" 2>/dev/null || true
  else
    xdg-open "$url" 2>/dev/null || true
  fi
}

# ============= File Metadata =============
# macOS: stat -f '%m' (BSD stat)
# Linux: stat -c '%Y' (GNU stat)
compat_file_mtime() {
  local file="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    stat -f '%m' "$file" 2>/dev/null || echo 0
  else
    stat -c '%Y' "$file" 2>/dev/null || echo 0
  fi
}

# ============= Find with mtime =============
# macOS: find -exec stat -f '%m' {} + | sort -nr | head -1
# Linux: find -printf '%T@\n' | sort -nr | head -1
compat_find_latest_mtime() {
  local dir="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    find -L "$dir" -type f -name '*.md' -exec stat -f '%m' {} + 2>/dev/null | sort -nr | head -n1 || true
  else
    find -L "$dir" -type f -name '*.md' -printf '%T@\n' 2>/dev/null | sort -nr | head -n1 || true
  fi
}

# ============= Hashing =============
# macOS: md5 -q, shasum -a 256
# Linux: md5sum, sha256sum
compat_hash_md5() {
  if [[ "$PLATFORM" == "macos" ]]; then
    md5 -q 2>/dev/null || md5sum 2>/dev/null | awk '{print $1}'
  else
    md5sum 2>/dev/null | awk '{print $1}'
  fi
}

compat_hash_sha256() {
  if [[ "$PLATFORM" == "macos" ]]; then
    shasum -a 256 2>/dev/null | awk '{print $1}'
  else
    sha256sum 2>/dev/null | awk '{print $1}'
  fi
}

# ============= realpath =============
# macOS: may not have realpath, use python fallback or grealpath
compat_realpath() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
  elif command -v grealpath >/dev/null 2>&1; then
    grealpath "$path"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import os; print(os.path.realpath('$path'))"
  else
    # Last resort: use cd && pwd
    (cd "$(dirname "$path")" && echo "$(pwd)/$(basename "$path")")
  fi
}

# ============= sed -i =============
# macOS: BSD sed requires -i '' (empty string backup extension)
# Linux: GNU sed uses -i without backup extension
compat_sed_inplace() {
  if [[ "$PLATFORM" == "macos" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ============= Screen Dimensions =============
# macOS: system_profiler SPDisplaysDataType or default
# Linux: xdpyinfo/xrandr
compat_get_screen_dims() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v system_profiler >/dev/null 2>&1; then
      local dims
      dims=$(system_profiler SPDisplaysDataType 2>/dev/null | \
             awk '/Resolution/{print $2 "x" $4; exit}')
      if [[ -n "$dims" ]]; then
        echo "$dims"
        return
      fi
    fi
    echo "1920x1080"
  else
    # Linux: caller handles xdpyinfo/xrandr
    return 1
  fi
}

# ============= Terminal Detection =============
compat_default_terminal() {
  if [[ "$PLATFORM" == "macos" ]]; then
    # Check for iTerm2 first, then Terminal.app
    if [[ -d "/Applications/iTerm.app" ]]; then
      echo "iTerm"
    else
      echo "Terminal"
    fi
  else
    return 1
  fi
}

compat_run_in_terminal() {
  local cmd="$1" title="${2:-Dev Toolbox}"
  if [[ "$PLATFORM" == "macos" ]]; then
    local term
    term=$(compat_default_terminal)
    case "$term" in
      iTerm)
        osascript -e "tell application \"iTerm\"
          activate
          set newWindow to (create window with default profile)
          tell current session of newWindow
            write text \"$cmd\"
          end tell
        end tell" 2>/dev/null || true
        ;;
      *)
        osascript -e "tell application \"Terminal\"
          activate
          do script \"$cmd\"
        end tell" 2>/dev/null || true
        ;;
    esac
  else
    return 1
  fi
}

# ============= Network =============
compat_get_ip() {
  if [[ "$PLATFORM" == "macos" ]]; then
    ipconfig getifaddr en0 2>/dev/null || echo "N/A"
  else
    hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A"
  fi
}

compat_get_mac() {
  if [[ "$PLATFORM" == "macos" ]]; then
    ifconfig en0 2>/dev/null | awk '/ether/{print $2}' || echo "N/A"
  else
    ip link show 2>/dev/null | awk '/ether/{print $2}' | head -n1 || echo "N/A"
  fi
}

# ============= Date/Time =============
# macOS: date -r <unix_timestamp> (BSD date)
# Linux: date -d "@<unix_timestamp>" (GNU date)
compat_unix_to_local() {
  local ts="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    date -r "$ts" +%Y-%m-%dT%H:%M:%S 2>/dev/null
  else
    date -d "@$ts" +%Y-%m-%dT%H:%M:%S 2>/dev/null
  fi
}

compat_unix_to_utc() {
  local ts="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    date -u -r "$ts" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null
  else
    date -u -d "@$ts" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null
  fi
}

# ============= Lowercase =============
# macOS: tr '[:upper:]' '[:lower:]' (bash 3.2 doesn't support ${var,,})
# Linux: ${var,,} (bash 4+)
compat_lowercase() {
  local str="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    echo "$str" | tr '[:upper:]' '[:lower:]'
  else
    echo "${str,,}"
  fi
}

# ============= Mapfile Alternative =============
# macOS bash 3.2 doesn't have mapfile; use while loop
compat_mapfile() {
  local -n arr_ref=$1
  shift
  if [[ "$PLATFORM" == "macos" ]]; then
    arr_ref=()
    while IFS= read -r line; do
      arr_ref+=("$line")
    done < <("$@")
  else
    mapfile -t arr_ref < <("$@")
  fi
}

# ============= Base64 =============
# macOS: base64 without -w flag (doesn't support it)
# Linux: base64 -w0 (GNU coreutils)
compat_b64enc() {
  if [[ "$PLATFORM" == "macos" ]]; then
    base64 | tr -d '\n'
  else
    if base64 --help 2>/dev/null | grep -q -- '-w'; then
      base64 -w0 | tr -d '\n'
    else
      base64 | tr -d '\n'
    fi
  fi
}

compat_b64dec() {
  if [[ "$PLATFORM" == "macos" ]]; then
    # macOS base64 uses -D for decode
    base64 -D 2>/dev/null || base64 -d 2>/dev/null
  else
    base64 -d 2>/dev/null
  fi
}

# ============= Initialize =============
# Auto-initialize clipboard on source
compat_clipboard_copy
compat_clipboard_paste
