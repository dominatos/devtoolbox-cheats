#!/bin/bash
# macOS-beta/devtoolbox-cheats.30s.sh — macOS wrapper for main script
# Thin wrapper that overrides Linux-incompatible functions,
# then sources the original Linux script for shared core logic.
#
# Requires: Bash 4+ (macOS ships with 3.2 which lacks mapfile, declare -A)
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

set -Eeuo pipefail
trap ' exit 0' ERR

# ============= Source Platform Abstraction =============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/compat.sh"

# ============= Resolve Script Path =============
# The Linux script expects SCRIPT_PATH to point to itself
# but we need it to point to this wrapper for xbar compatibility
MACOS_SCRIPT_PATH="${SCRIPT_DIR}/devtoolbox-cheats.30s.sh"
LINUX_SCRIPT_PATH="${SCRIPT_DIR}/../devtoolbox-cheats.30s.sh"

# ============= Override: Clipboard Detection =============
# Lines 94-101 in original
if [[ "$PLATFORM" == "macos" ]]; then
  if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
    CLIPBOARD_COPY="pbcopy"
  else
    CLIPBOARD_COPY=""
  fi
fi

# ============= Override: DE Detection =============
# Lines 121-161 in original — return "xbar" on macOS
detect_de() {
  # Return configured DE if not auto
  if [[ "$DEVTOOLBOX_DE" != "auto" ]]; then
    echo "$DEVTOOLBOX_DE"
    return
  fi

  # Return cached value if exists
  if [[ -f "$DE_CACHE_FILE" ]]; then
    cat "$DE_CACHE_FILE"
    return
  fi

  local detected="terminal"

  if [[ "$PLATFORM" == "macos" ]]; then
    detected="xbar"
  else
    # Linux DE detection (from original)
    case "${XDG_CURRENT_DESKTOP:-}" in
      *GNOME*|*Unity*|*Pantheon*) detected="gnome" ;;
      *KDE*|*Plasma*)             detected="kde" ;;
      *XFCE*)                     detected="xfce" ;;
      *Cinnamon*)                 detected="cinnamon" ;;
      *MATE*)                     detected="mate" ;;
      *LXQt*)                     detected="lxqt" ;;
      *LXDE*)                     detected="lxde" ;;
      *)
        if pgrep -x gnome-shell >/dev/null 2>&1; then detected="gnome"
        elif pgrep -x plasmashell >/dev/null 2>&1; then detected="kde"
        elif pgrep -x xfce4-panel >/dev/null 2>&1; then detected="xfce"
        elif pgrep -x cinnamon >/dev/null 2>&1; then detected="cinnamon"
        elif pgrep -x mate-panel >/dev/null 2>&1; then detected="mate"
        elif pgrep -x lxqt-panel >/dev/null 2>&1; then detected="lxqt"
        elif pgrep -x lxpanel >/dev/null 2>&1; then detected="lxde"
        fi
        ;;
    esac
  fi

  # Cache the result
  echo "$detected" > "$DE_CACHE_FILE"
  echo "$detected"
}

# ============= Override: Dialog Tool Detection =============
# Lines 165-198 in original — return "osascript" on macOS
detect_dialog_tool() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      echo "osascript"
    elif command -v fzf >/dev/null 2>&1; then
      echo "fzf"
    fi
    return
  fi

  # Linux: original logic
  local de
  de="$(detect_de)"
  
  case "$de" in
    kde)
      if command -v kdialog >/dev/null 2>&1; then
        echo "kdialog"
      elif command -v zenity >/dev/null 2>&1; then
        if [[ ! -f "$DE_WARNING_FLAG" ]]; then
          notify-send "Dev Toolbox" "KDE detected but kdialog not found. Using zenity as fallback.\nInstall kdialog for better experience: sudo apt install kdialog" 2>/dev/null || true
          touch "$DE_WARNING_FLAG"
        fi
        echo "zenity"
      elif command -v yad >/dev/null 2>&1; then
        echo "yad"
      fi
      ;;
    *)
      if command -v zenity >/dev/null 2>&1; then
        echo "zenity"
      elif command -v yad >/dev/null 2>&1; then
        echo "yad"
      elif command -v kdialog >/dev/null 2>&1; then
        echo "kdialog"
      fi
      ;;
  esac
}

# ============= Override: notify() =============
# Lines 201-218 in original
notify() {
  local title="$1" msg="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_notify "$title" "$msg"
    return
  fi

  # Linux: original logic
  local de
  de="$(detect_de)"
  case "$de" in
    kde)
      if command -v kdialog >/dev/null 2>&1; then
        kdialog --passivepopup "$msg" 5 --title "$title" 2>/dev/null || true
      else
        notify-send "$title" "$msg" 2>/dev/null || true
      fi
      ;;
    *)
      notify-send "$title" "$msg" 2>/dev/null || true
      ;;
  esac
}

# ============= Override: input_dialog() =============
# Lines 221-232 in original
input_dialog() {
  local title="$1" prompt="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_input_dialog "$title" "$prompt"
    return
  fi

  # Linux: original logic
  local tool
  tool="$(detect_dialog_tool)"
  case "$tool" in
    kdialog) kdialog --inputbox "$prompt" --title "$title" 2>/dev/null ;;
    yad)     yad --entry --title="$title" --text="${prompt//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --entry --title="$title" --text="${prompt//&/&amp;}" 2>/dev/null ;;
    *)       read -rp "$prompt: " reply; echo "$reply" ;;
  esac
}

# ============= Override: info_dialog() =============
# Lines 235-246 in original
info_dialog() {
  local title="$1" msg="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_info_dialog "$title" "$msg"
    return
  fi

  # Linux: original logic
  local tool
  tool="$(detect_dialog_tool)"
  case "$tool" in
    kdialog) kdialog --msgbox "$msg" --title "$title" 2>/dev/null ;;
    yad)     yad --info --title="$title" --text="${msg//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --info --title="$title" --text="${msg//&/&amp;}" 2>/dev/null ;;
    *)       echo -e "=== $title ===\n$msg"; read -rp "Press Enter to continue..." ;;
  esac
}

# ============= Override: list_dialog() =============
# Lines 251-301 in original
list_dialog() {
  local title="$1" col="$2"
  shift 2
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_list_dialog "$title" "$col" "$@"
    return
  fi

  # Linux: original logic
  local tool
  tool="$(detect_dialog_tool)"
  local w h
  read -r w h < <(calc_window_size)
  
  case "$tool" in
    kdialog)
      local items=()
      if [[ $# -gt 0 ]]; then
        for item in "$@"; do items+=("$item" "$item"); done
      else
        while IFS= read -r item; do items+=("$item" "$item"); done
      fi
      kdialog --menu "$title" "${items[@]}" --title "$title" 2>/dev/null
      ;;
    yad)
      if [[ $# -gt 0 ]]; then
        local escaped_items=()
        for item in "$@"; do escaped_items+=("${item//&/&amp;}"); done
        printf '%s\n' "${escaped_items[@]}" | yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1 | sed 's/&amp;/\&/g'
      else
        sed 's/&/\&amp;/g' | yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1 | sed 's/&amp;/\&/g'
      fi
      ;;
    zenity)
      if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@" | zenity --list --title="$title" --column="$col" --width="$w" --height="$h" 2>/dev/null
      else
        zenity --list --title="$title" --column="$col" --width="$w" --height="$h" 2>/dev/null
      fi
      ;;
    *)
      if command -v fzf >/dev/null 2>&1; then
        if [[ $# -gt 0 ]]; then
          printf '%s\n' "$@" | fzf --prompt="$title > "
        else
          fzf --prompt="$title > "
        fi
      else
        echo "=== $title ===" >&2
        select item in "$@"; do echo "$item"; break; done
      fi
      ;;
  esac
}

# ============= Override: text_dialog() =============
# Lines 304-317 in original
text_dialog() {
  local title="$1" body="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_text_dialog "$title" "$body"
    return
  fi

  # Linux: original logic
  local tool
  tool="$(detect_dialog_tool)"
  local w h
  read -r w h < <(calc_window_size)
  
  case "$tool" in
    kdialog) printf '%s' "$body" | kdialog --textbox /dev/stdin "$w" "$h" --title "$title" 2>/dev/null ;;
    yad)     printf '%s' "$body" | yad --text-info --title="$title" --width="$w" --height="$h" --center 2>/dev/null ;;
    zenity)  printf '%s' "$body" | zenity --text-info --title="$title" --width="$w" --height="$h" --no-wrap 2>/dev/null ;;
    *)       echo -e "=== $title ===\n$body" | less ;;
  esac
}

# ============= Override: default_terminal() =============
# Lines 322-367 in original
default_terminal() {
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_default_terminal
    return
  fi

  # Linux: original logic
  local de
  de="$(detect_de)"
  case "$de" in
    gnome)    
      for t in gnome-terminal kgx tilix terminator; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    kde)      
      for t in konsole yakuake; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    xfce)     
      command -v xfce4-terminal >/dev/null 2>&1 && { echo "xfce4-terminal"; return; }
      ;;
    cinnamon) 
      for t in gnome-terminal tilix; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    mate)     
      command -v mate-terminal >/dev/null 2>&1 && { echo "mate-terminal"; return; }
      ;;
    lxqt)     
      for t in qterminal lxterminal; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    lxde)     
      command -v lxterminal >/dev/null 2>&1 && { echo "lxterminal"; return; }
      ;;
  esac
  
  for t in gnome-terminal konsole xfce4-terminal mate-terminal tilix terminator \
           alacritty kitty wezterm foot st urxvt rxvt-unicode xterm; do
    command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
  done
  
  echo "xterm"
}

# ============= Override: run_in_terminal() =============
# Lines 370-396 in original
run_in_terminal() {
  local cmd="$1" title="${2:-Dev Toolbox}"
  if [[ "$PLATFORM" == "macos" ]]; then
    compat_run_in_terminal "$cmd" "$title"
    return
  fi

  # Linux: original logic
  local term
  term="$(default_terminal)"
  local escaped_cmd
  escaped_cmd=$(printf '%q' "$cmd")
  
  case "$term" in
    gnome-terminal) gnome-terminal --title="$title" -- bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    kgx)            kgx -- bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    konsole)        konsole --hold -e bash -c "eval $escaped_cmd" ;;
    yakuake)        konsole --hold -e bash -c "eval $escaped_cmd" ;;
    xfce4-terminal) xfce4-terminal --hold --title="$title" -e "bash -c \"eval $escaped_cmd\"" ;;
    mate-terminal)  mate-terminal --title="$title" -e "bash -c \"eval $escaped_cmd; read -rp 'Press Enter...'\"" ;;
    tilix)          tilix -e "bash -c \"eval $escaped_cmd; read -rp 'Press Enter...'\"" ;;
    terminator)     terminator -e "bash -c \"eval $escaped_cmd; read -rp 'Press Enter...'\"" ;;
    qterminal)      qterminal -e "bash -c \"eval $escaped_cmd; read -rp 'Press Enter...'\"" ;;
    lxterminal)     lxterminal --title="$title" -e "bash -c \"eval $escaped_cmd; read -rp 'Press Enter...'\"" ;;
    alacritty)      alacritty --hold -e bash -c "eval $escaped_cmd" ;;
    kitty)          kitty --hold bash -c "eval $escaped_cmd" ;;
    wezterm)        wezterm start -- bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    foot)           foot bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    st)             st -e bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    urxvt|rxvt-unicode) urxvt -hold -e bash -c "eval $escaped_cmd" ;;
    *)              xterm -hold -e bash -c "eval $escaped_cmd" ;;
  esac
}

# ============= Override: get_screen_dims() =============
# Lines 435-449 in original
get_screen_dims() {
  if [[ -n "$_SCREEN_DIMS_CACHED" ]]; then
    echo "$_SCREEN_DIMS_CACHED"
    return
  fi

  if [[ "$PLATFORM" == "macos" ]]; then
    _SCREEN_DIMS_CACHED="$(compat_get_screen_dims)"
    echo "$_SCREEN_DIMS_CACHED"
    return
  fi

  # Linux: original logic
  local dims
  dims="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
  [[ -z "$dims" ]] && dims="$(xrandr --current 2>/dev/null | awk '/\*/{print $1; exit}')"
  _SCREEN_DIMS_CACHED="${dims:-1366x768}"
  echo "$_SCREEN_DIMS_CACHED"
}

# ============= Override: index_cheats() =============
# Lines 549-570 in original — replace find -printf with compat function
index_cheats() {
  mkdir -p "$(dirname "$CHEATS_CACHE")"
  : > "$CHEATS_CACHE"
  [[ -d "$CHEATS_DIR" ]] || return 0

  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    local title group icon order
    title="$(meta_val "$f" 'Title')";  [[ -z "$title" ]] && title="$(basename "$f" .md)"
    group="$(meta_val "$f" 'Group')";  [[ -z "$group" ]] && group="Misc"
    icon="$(meta_val "$f" 'Icon')";    [[ -z "$icon"  ]] && icon=""
    order="$(meta_val "$f" 'Order')";  [[ -z "$order" ]] && order="9999"
    
    title="${title%$'\r'}"; group="${group%$'\r'}"; icon="${icon%$'\r'}"; order="${order%$'\r'}"
    
    printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$title" "$group" "$icon" "$order" >> "$CHEATS_CACHE"
  done < <(find -L "$CHEATS_DIR" -type f -name '*.md' | sort -f)
}

# ============= Override: ensure_cache() =============
# Lines 578-597 in original — replace find -printf and stat -c
ensure_cache() {
  (( _CACHE_CHECKED )) && return

  if [[ -n "${CHEATS_REBUILD:-}" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi
  if [[ ! -s "$CHEATS_CACHE" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi
  
  local latest_src mtime_cache
  latest_src="$(compat_find_latest_mtime "$CHEATS_DIR")"
  [[ -z "$latest_src" ]] && { index_cheats; _CACHE_CHECKED=1; return; }
  
  mtime_cache="$(compat_file_mtime "$CHEATS_CACHE")"
  local latest_int="${latest_src%.*}"
  
  if (( latest_int > mtime_cache )); then index_cheats; fi
  _CACHE_CHECKED=1
}

# ============= Override: argos_get_category() =============
# Lines 738-750 in original — replace stat -c
argos_get_category() {
  [[ -f "$ARGOS_CAT_STATE" ]] || { printf ''; return; }
  local mtime now age
  mtime="$(compat_file_mtime "$ARGOS_CAT_STATE")"
  now="$(date +%s)"
  age=$(( now - mtime ))
  if (( age > ARGOS_CAT_TTL )); then
    rm -f "$ARGOS_CAT_STATE"
    printf ''
    return
  fi
  cat "$ARGOS_CAT_STATE"
}

# ============= Override: argos_category_lines() =============
# Lines 757-791 in original — replace sha256sum
argos_category_lines() {
  local grp="$1"
  local hash_sum cat_cache line
  hash_sum="$(printf '%s' "$grp" | compat_hash_sha256)"
  cat_cache="${ARGOS_CAT_CACHE_DIR}/cat_${hash_sum}.lines"

  mkdir -p "$ARGOS_CAT_CACHE_DIR"

  if [[ -f "$cat_cache" && "$cat_cache" -nt "$CHEATS_CACHE" ]]; then
    cat "$cat_cache"
    return
  fi

  local tmp_cache
  tmp_cache="$(mktemp "${cat_cache}.XXXXXX")"
  _ARGOS_TMP_CACHE="$tmp_cache"
  trap '[[ -n "$_ARGOS_TMP_CACHE" ]] && rm -f "$_ARGOS_TMP_CACHE" 2>/dev/null; true' EXIT

  while IFS=$'\t' read -r file title group icon order; do
    label="$(compose_label "$title" "$icon")"
    enc="$(printf '%s' "$file" | b64enc)"
    line="$label | bash='$SCRIPT_PATH' param1=showCheat param2='$enc' terminal=false refresh=true"
    printf '%s\n' "$line" >> "$tmp_cache"
    printf '%s\n' "$line"
  done < <(awk -F'\t' -v gg="$grp" '$3==gg{printf "%s\t%s\t%s\t%s\t%05d\n",$1,$2,$3,$4,$5}' "$CHEATS_CACHE" \
           | sort -t$'\t' -k5,5n -k2,2f)

  chmod 644 "$tmp_cache" 2>/dev/null || true
  if mv -f "$tmp_cache" "$cat_cache"; then
    _ARGOS_TMP_CACHE=""
  fi
}

# ============= Override: exportAllCheatsFS() =============
# Lines 965-994 in original — replace xdg-open
exportAllCheatsFS() {
  ensure_cache
  local ts out_md out_pdf
  ts="$(date +%Y-%m-%d_%H-%M)"
  out_md="$HOME/DevToolbox-Cheatsheet_${ts}.md"
  out_pdf="$HOME/DevToolbox-Cheatsheet_${ts}.pdf"

  {
    echo "# Dev Toolbox — Mega Cheatsheet"
    echo ""
    echo "_Generated on $(date)_"
    echo ""
    while IFS=$'\t' read -r file title group icon order; do
        [[ -z "$file" || ! -f "$file" ]] && continue
        echo "## $(compose_label "$title" "$icon")"
        echo ""
        strip_front_matter < "$file"
        echo ""
      done < <(sort -t$'\t' -k3,3f -k5,5n "$CHEATS_CACHE")
  } > "$out_md"

  local extra=""
  if command -v pandoc >/dev/null 2>&1; then
    if pandoc "$out_md" -o "$out_pdf" 2>/dev/null; then
      extra="\nPDF: $out_pdf"
    fi
  fi
  info_dialog "📥 Export complete" "Saved:\n$out_md${extra}"
}

# ============= Override: xdg-open calls in menu =============
# These are hardcoded in the menu rendering sections
# We override the compactMenu and standaloneMenu to use compat_open_url

# Override compactMenu to use compat_open_url
compactMenu() {
  ensure_cache

  local cat_items=()
  while IFS= read -r g; do
    [[ -z "$g" ]] && continue
    local gi="${GROUP_ICON[$g]:-🧩}"
    cat_items+=("$gi $g")
  done < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)

  local choice
  choice=$(list_dialog "Dev Toolbox (Compact)" "Action" \
    "🔎 Search cheats" \
    "🚀 FZF Search Commands" \
    "📚 Browse all cheats" \
    "📥 Export all (MD/PDF)" \
    "🌐 Online Version" \
    "🐙 GitHub Repository" \
    "⚙️ Settings" \
    "📝 TOC Format" \
    "── Categories ──" \
    "${cat_items[@]}") || exit 0
  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "🚀 FZF Search Commands")
        run_in_terminal "$SCRIPT_PATH fzfSearch" "FZF Search"
        ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
    "🌐 Online Version") compat_open_url "https://cheats.alteron.net/" ;;
    "🐙 GitHub Repository") compat_open_url "https://github.com/dominatos/devtoolbox-cheats/" ;;
    "⚙️ Settings")
        showSettings
        compactMenu
        ;;
    "📝 TOC Format")
        settingsTocFormat
        compactMenu
        ;;
    "── Categories ──") compactMenu ;;
    *)
        local group_name="${choice#* }"
        browseDeep_Cheats "$group_name"
        ;;
  esac
}

# Override standaloneMenu to use compat_open_url
standaloneMenu() {
  ensure_cache

  local cat_items=()
  while IFS= read -r g; do
    [[ -z "$g" ]] && continue
    local gi="${GROUP_ICON[$g]:-🧩}"
    cat_items+=("$gi $g")
  done < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)

  local choice
  choice=$(list_dialog "🗒️ Dev Toolbox" "Action" \
    "🔎 Search cheats" \
    "🚀 FZF Search Commands" \
    "📚 Browse all cheats" \
    "📥 Export all (MD/PDF)" \
    "🌐 Online Version" \
    "🐙 GitHub Repository" \
    "⚙️ Settings" \
    "📝 TOC Format" \
    "── Categories ──" \
    "${cat_items[@]}") || exit 0

  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "🚀 FZF Search Commands")
        if [[ -t 0 ]]; then
          fzfSearch
        else
          run_in_terminal "$SCRIPT_PATH fzfSearch" "FZF Search"
        fi
        ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
    "🌐 Online Version") compat_open_url "https://cheats.alteron.net/" ;;
    "🐙 GitHub Repository") compat_open_url "https://github.com/dominatos/devtoolbox-cheats/" ;;
    "⚙️ Settings")
        showSettings
        standaloneMenu
        ;;
    "📝 TOC Format")
        settingsTocFormat
        standaloneMenu
        ;;
    "── Categories ──") standaloneMenu ;;
    *)
        local group_name="${choice#* }"
        browseDeep_Cheats "$group_name"
        ;;
  esac
}

# ============= Source Linux Script =============
# This loads all the remaining functions and logic
source "$LINUX_SCRIPT_PATH"

# ============= Override SCRIPT_PATH for xbar =============
# The Linux script sets SCRIPT_PATH to itself, but xbar needs it to point to this wrapper
SCRIPT_PATH="$MACOS_SCRIPT_PATH"
