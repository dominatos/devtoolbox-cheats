#!/usr/bin/env bash
# devtoolbox-cheats-combined.30s.sh
# coded by Sviatoslav https://github.com/dominatos
#
# Combined Argos cheatsheet script — all 3 layout modes in one file.
# Switch layouts from the Argos menu (🛠 DevToolbox Functions → 🔄 Layout)
# without editing any code.
#
# Layouts:
#   standard   — categories expand inline as Argos submenus (default)
#   zenity     — clicking a category opens a Zenity/dialog cheat list
#   drilldown  — clicking a category re-renders the Argos menu to show
#                only that category's cheats; ◀ Back returns to categories
#
# Layout preference is persisted in:
#   ~/.config/devtoolbox-cheats/layout.conf
# Override with env var: DEVTOOLBOX_LAYOUT=standard|zenity|drilldown

set -Eeuo pipefail
trap '  exit 0' ERR

VERSION="v1.4.28"

# ============= Config =============🖧
# Directory containing markdown cheatsheets.
# Defaults to $HOME/cheats.d if CHEATS_DIR is not set.
CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"

# Resolve symlink to ensure find works reliably
# If CHEATS_DIR is a symbolic link, we resolve it to its absolute path.
# This ensures that the 'find' command correctly traverses the directory structure.
if [[ -L "$CHEATS_DIR" ]] && command -v realpath >/dev/null 2>&1; then
  CHEATS_DIR="$(realpath "$CHEATS_DIR")"
fi

# Cache file to store indexed cheatsheet metadata.
# This speeds up menu generation by avoiding re-reading all files every time.
CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats-combined.idx}"
CHEATS_REBUILD="" # Set to any non-empty value (e.g. CHEATS_REBUILD=1) to force a cache rebuild

# === Layout config ===
# Persistent layout preference file (XDG-compliant).
DEVTOOLBOX_LAYOUT_CONF="${HOME}/.config/devtoolbox-cheats/layout.conf"

# === Argos drill-down navigation state (used by drilldown layout only) ===
# Stores the currently selected category for the Argos inline drill-down menu.
# Uses a private runtime directory so stale state never persists across sessions safely.
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  ARGOS_RUNTIME_DIR="${XDG_RUNTIME_DIR}/devtoolbox-cheats"
else
  ARGOS_RUNTIME_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/devtoolbox-cheats/run"
fi
ARGOS_CAT_STATE="${ARGOS_RUNTIME_DIR}/argos-cat-combined.state"
# TTL in seconds: state auto-expires so reopening the widget resets to the category list.
# Default 60s = at most 2 Argos refresh cycles (script refreshes every 30s).
ARGOS_CAT_TTL="${ARGOS_CAT_TTL:-60}"
# Per-category Argos output cache directory (drilldown layout only).
# Each category's cheat list is cached as a text file and reused until CHEATS_CACHE changes.
ARGOS_CAT_CACHE_DIR="${HOME}/.cache/devtoolbox-cheats-argos-combined"

# === Group Icons (Section Headers) ===
# Maps category names (Group metadata) to emoji icons for the menu display.
declare -A GROUP_ICON=(
  ["Basics"]="📚"
  ["Network"]="📡"
  ["Storage & FS"]="💿"
  ["Backups & S3"]="🗄️"
  ["Files & Archives"]="📦"
  ["Text & Parsing"]="📝"
  ["Kubernetes & Containers"]="☸️"
  ["System & Logs"]="🛠"
  ["Web Servers"]="🌐"
  ["Databases"]="🗃️"
  ["Package Managers"]="📦"
  ["Security & Crypto"]="🔐"
  ["Dev & Tools"]="🧬"
  ["Misc"]="🧩"
  ["Diagnostics"]="🔎"
  ["Monitoring"]="📈"
  ["Cloud"]="☁️"
  ["Infrastructure Management"]="🔧"
  ["Identity Management"]="🪪"
)


CHEAT_VIEWERS="${CHEAT_VIEWERS:-code codium antigravity windsurf subl kate kwrite geany gedit mousepad pluma xed notepadqq zenity}"
export PATH="/usr/local/bin:/usr/bin:$PATH"
SCRIPT_PATH="$(realpath -s "$0")"

# ============= Clipboard =============
# Detect available clipboard utility (Wayland's wl-copy or X11's xclip).
if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
  CLIPBOARD_COPY="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  CLIPBOARD_COPY="xclip -selection clipboard"
else
  CLIPBOARD_COPY=""
fi

# Helper function to copy text to clipboard safely.
copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY" || true; }

# ============= Cross-DE Abstraction Layer =============
# Provides DE-agnostic functions for notifications, dialogs, and terminals.
# Поддержка разных окружений рабочего стола (GNOME, KDE, XFCE, etc.)

# --- Configuration / Конфигурация ---
# Override DE detection (gnome, kde, xfce, cinnamon, mate, lxqt, terminal)
# Переопределение определения DE
DEVTOOLBOX_DE="${DEVTOOLBOX_DE:-auto}"

# Cache files for DE detection and fallback warnings
# Файлы кэша для определения DE и предупреждений
DE_CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/devtoolbox-de.cache"
DE_WARNING_FLAG="${XDG_RUNTIME_DIR:-/tmp}/devtoolbox-de-warning.flag"

# --- DE Detection (Cached) / Определение DE (с кэшированием) ---
detect_de() {
  # Return configured DE if not auto / Вернуть настроенный DE если не auto
  if [[ "$DEVTOOLBOX_DE" != "auto" ]]; then
    echo "$DEVTOOLBOX_DE"
    return
  fi

  # Return cached value if exists / Вернуть кэшированное значение
  if [[ -f "$DE_CACHE_FILE" ]]; then
    cat "$DE_CACHE_FILE"
    return
  fi

  local detected="terminal"

  # Check XDG_CURRENT_DESKTOP first / Сначала проверить XDG_CURRENT_DESKTOP
  case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*|*Unity*|*Pantheon*) detected="gnome" ;;
    *KDE*|*Plasma*)             detected="kde" ;;
    *XFCE*)                     detected="xfce" ;;
    *Cinnamon*)                 detected="cinnamon" ;;
    *MATE*)                     detected="mate" ;;
    *LXQt*)                     detected="lxqt" ;;
    *LXDE*)                     detected="lxde" ;;
    *)
      # Fallback: check running processes / Фоллбэк: проверить процессы
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

  # Cache the result / Закэшировать результат
  echo "$detected" > "$DE_CACHE_FILE"
  echo "$detected"
}

# --- Dialog Tool Detection / Определение инструмента диалогов ---
# Returns: kdialog, zenity, yad, or empty
detect_dialog_tool() {
  local de="$(detect_de)"
  
  case "$de" in
    kde)
      # KDE: prefer kdialog, fallback to zenity with warning
      # KDE: предпочитать kdialog, фоллбэк на zenity с предупреждением
      if command -v kdialog >/dev/null 2>&1; then
        echo "kdialog"
      elif command -v zenity >/dev/null 2>&1; then
        # One-time warning per boot / Одноразовое предупреждение за сессию
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
      # All other DEs: prefer zenity, then yad, then kdialog
      # Остальные DE: zenity → yad → kdialog
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

# --- Notification Wrapper / Обёртка уведомлений ---
notify() {
  local title="$1" msg="$2"
  local de="$(detect_de)"
  
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

# --- Input Dialog / Диалог ввода ---
input_dialog() {
  local title="$1" prompt="$2"
  local tool="$(detect_dialog_tool)"
  
  case "$tool" in
    kdialog) kdialog --inputbox "$prompt" --title "$title" 2>/dev/null ;;
    yad)     yad --entry --title="$title" --text="${prompt//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --entry --title="$title" --text="${prompt//&/&amp;}" 2>/dev/null ;;
    *)       read -rp "$prompt: " reply; echo "$reply" ;;
  esac
}

# --- Info Dialog / Информационный диалог ---
info_dialog() {
  local title="$1" msg="$2"
  local tool="$(detect_dialog_tool)"
  
  case "$tool" in
    kdialog) kdialog --msgbox "$msg" --title "$title" 2>/dev/null ;;
    yad)     yad --info --title="$title" --text="${msg//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --info --title="$title" --text="${msg//&/&amp;}" 2>/dev/null ;;
    *)       echo -e "=== $title ===\n$msg"; read -rp "Press Enter to continue..." ;;
  esac
}

# --- List Selection Dialog / Диалог выбора из списка ---
# Usage: list_dialog "title" "column" item1 item2 ...
# or pipe items: echo -e "item1\nitem2" | list_dialog "title" "column"
list_dialog() {
  local title="$1" col="$2"
  shift 2
  local tool="$(detect_dialog_tool)"
  local w h
  read -r w h < <(calc_window_size)
  
  case "$tool" in
    kdialog)
      # kdialog --menu needs: tag1 item1 tag2 item2
      # Build menu items from input
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
        local escaped_items=()
        for item in "$@"; do escaped_items+=("${item//&/&amp;}"); done
        printf '%s\n' "${escaped_items[@]}" | zenity --list --title="$title" --column="$col" --width="$w" --height="$h" 2>/dev/null | sed 's/&amp;/\&/g'
      else
        sed 's/&/\&amp;/g' | zenity --list --title="$title" --column="$col" --width="$w" --height="$h" 2>/dev/null | sed 's/&amp;/\&/g'
      fi
      ;;
    *)
      # Terminal fallback with fzf or select
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

# --- Text Display Dialog / Показать текст ---
text_dialog() {
  local title="$1" body="$2"
  local tool="$(detect_dialog_tool)"
  local w h
  read -r w h < <(calc_window_size)
  
  case "$tool" in
    kdialog) printf '%s' "$body" | kdialog --textbox /dev/stdin "$w" "$h" --title "$title" 2>/dev/null ;;
    yad)     printf '%s' "$body" | yad --text-info --title="$title" --width="$w" --height="$h" --center 2>/dev/null ;;
    zenity)  printf '%s' "$body" | zenity --text-info --title="$title" --width="$w" --height="$h" --no-wrap 2>/dev/null ;;
    *)       echo -e "=== $title ===\n$body" | less ;;
  esac
}

# --- Default Terminal Detection / Терминал по умолчанию ---
# Returns the preferred terminal emulator for the current DE
# Extended list for compatibility / Расширенный список для совместимости
default_terminal() {
  local de="$(detect_de)"
  
  # Check DE-specific terminals first / Сначала проверить терминалы DE
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
      for t in xfce4-terminal; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    cinnamon) 
      for t in gnome-terminal tilix; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    mate)     
      for t in mate-terminal; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    lxqt)     
      for t in qterminal lxterminal; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
    lxde)     
      for t in lxterminal; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
      done
      ;;
  esac
  
  # Fallback: try popular terminals / Фоллбэк: популярные терминалы
  for t in gnome-terminal konsole xfce4-terminal mate-terminal tilix terminator \
           alacritty kitty wezterm foot st urxvt rxvt-unicode xterm; do
    command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
  done
  
  # Last resort / Крайний случай
  echo "xterm"
}

# --- Run Command in Terminal / Запустить команду в терминале ---
run_in_terminal() {
  local cmd="$1" title="${2:-Dev Toolbox}"
  local term="$(default_terminal)"
  local escaped_cmd
  escaped_cmd=$(printf '%q' "$cmd")
  
  case "$term" in
    gnome-terminal) gnome-terminal --title="$title" -- bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    kgx)            kgx -- bash -c "eval $escaped_cmd; read -rp 'Press Enter...'" ;;
    konsole)        konsole --hold -e bash -c "eval $escaped_cmd" ;;
    yakuake)        konsole --hold -e bash -c "eval $escaped_cmd" ;;  # Fallback to konsole
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

# --- Check if Running in Argos / Проверка запуска в Argos ---
is_argos() {
  [[ "$(detect_de)" == "gnome" ]] && [[ -n "${ARGOS_VERSION:-}" || "$0" == *".sh" ]]
}

# === Utilities to avoid duplicating emojis ===
# Removes the icon from the title if the title already starts with it.
# Args: <title> <icon>
strip_leading_icon_if_same() {
  local title="$1" icon="$2"
  [[ -z "$icon" ]] && { printf '%s' "$title"; return; }
  
  # If title starts with "<icon> ", remove it to avoid double icons like "📈 📈 Title"
  if [[ "$title" == "$icon "* ]]; then
    printf '%s' "${title#"$icon "}"
  else
    printf '%s' "$title"
  fi
}

# Composes the display label for the menu item.
# Args: <title> <icon>
compose_label() {
  local title="$1" icon="$2"
  if [[ -n "$icon" ]]; then
    local t; t="$(strip_leading_icon_if_same "$title" "$icon")"
    printf '%s %s' "$icon" "$t"
  else
    printf '%s' "$title"
  fi
}

# ============= Screen / Windows ============
# Cache for screen dimensions — queried once per process invocation.
_SCREEN_DIMS_CACHED=""

# Detects screen dimensions to calculate appropriate window sizes for dialogs.
get_screen_dims() {
  # Return cached value if already detected this run
  if [[ -n "$_SCREEN_DIMS_CACHED" ]]; then
    echo "$_SCREEN_DIMS_CACHED"
    return
  fi
  local dims
  # Try xdpyinfo first (X11)
  dims="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
  # Fallback to xrandr (X11/Wayland with XWayland)
  [[ -z "$dims" ]] && dims="$(xrandr --current 2>/dev/null | awk '/\*/{print $1; exit}')"
  # Default fallback if detection fails
  _SCREEN_DIMS_CACHED="${dims:-1366x768}"
  echo "$_SCREEN_DIMS_CACHED"
}

# Calculates window size (80% width, 70% height) for Zenity dialogs.
calc_window_size() {
  local dims w h win_w win_h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  win_w=$(( w * 80 / 100 ))
  win_h=$(( h * 70 / 100 ))
  # Enforce minimum dimensions
  [[ $win_w -lt 600 ]] && win_w=600
  [[ $win_h -lt 400 ]] && win_h=400
  echo "$win_w" "$win_h"
}

# Checks if the screen is considered "small" (laptop resolution).
# Used to switch to specific menu layouts.
is_small_screen() {
  local dims w h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  (( w <= 1368 || h <= 768 ))
}

# Calculates the maximum number of top-level category groups that can safely
# fit in an Argos dropdown without submenus being clipped off-screen.
#
# Strategy:
#   usable_height = screen_height - panel_height (30px GNOME top bar)
#   max_total_items = usable_height / item_height (28px conservative estimate)
#   overhead = fixed utility lines + separators + footer (10 items)
#   max_groups = (max_total_items - overhead) * 60 / 100
#              (60% factor reserves screen real estate for submenu rendering)
#
# Examples:
#   1080p → (1050/28 - 10) * 60/100 ≈ 16  (19 groups > 16 → collapse)
#   1440p → (1410/28 - 10) * 60/100 ≈ 24  (19 groups < 24 → expand)
#   768p  → handled by is_small_screen() before this is reached
calc_max_argos_groups() {
  local dims w h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  local panel_height=30
  local item_height=28
  local overhead=10
  local usable=$(( h - panel_height ))
  local max_total=$(( usable / item_height ))
  local max_groups=$(( (max_total - overhead) * 60 / 100 ))
  # Always allow at least 5 groups to avoid degenerate collapse on odd resolutions
  [[ $max_groups -lt 5 ]] && max_groups=5
  echo "$max_groups"
}

# Displays a text popup using DE-aware dialog.
# Now uses text_dialog() abstraction for cross-DE support.
popup() {
  text_dialog "Dev Toolbox: $1" "$2"
}

# ============= Base64 helpers (Argos params safe) ============
# Detect base64 flag support once at startup (GNU coreutils uses -w0; macOS/BSD do not).
# Storing the result avoids spawning 'base64 --help | grep' on every b64enc() call.
if base64 --help 2>/dev/null | grep -q -- '-w'; then
  _B64ENC_FLAG="-w0"
else
  _B64ENC_FLAG=""
fi

# Encodes string to base64, removing newlines for safe passing as arguments.
b64enc() {
  base64 ${_B64ENC_FLAG} | tr -d '\n'
}

# Decodes base64 string.
b64dec() {
  # GNU coreutils: -d, macOS: -D
  if base64 -d </dev/null 2>/dev/null; then
    base64 -d
  else
    base64 -D
  fi
}

# ============= Index cheats (read MD front-matter) ============
# Cache format (TSV): FILE<TAB>TITLE<TAB>GROUP<TAB>ICON<TAB>ORDER

# Extracts metadata value from the top of the markdown file.
# Args: <file> <KeyRegexCaseInsensitive>
meta_val() {
  local f="$1" key="$2"
  # Read first 80 lines, remove BOM, handle CRLF, look for Key: Value
  sed '1s/^\xEF\xBB\xBF//' "$f" | head -n 80 \
    | tr -d '\r' \
    | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
    | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
}

# Indexes all cheatsheets and builds the cache file.
index_cheats() {
  mkdir -p "$(dirname "$CHEATS_CACHE")"
  : > "$CHEATS_CACHE" # Truncate/create cache file
  [[ -d "$CHEATS_DIR" ]] || return 0

  # Find all .md files, following symlinks (-L), and process them
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    local title group icon order
    # Extract metadata, with defaults
    title="$(meta_val "$f" 'Title')";  [[ -z "$title" ]] && title="$(basename "$f" .md)"
    group="$(meta_val "$f" 'Group')";  [[ -z "$group" ]] && group="Misc"
    icon="$(meta_val "$f" 'Icon')";    [[ -z "$icon"  ]] && icon=""
    order="$(meta_val "$f" 'Order')";  [[ -z "$order" ]] && order="9999"
    
    # Strip carriage returns just in case (e.g. files created on Windows)
    title="${title%$'\r'}"; group="${group%$'\r'}"; icon="${icon%$'\r'}"; order="${order%$'\r'}"
    
    # Append to cache
    printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$title" "$group" "$icon" "$order" >> "$CHEATS_CACHE"
  done < <(find -L "$CHEATS_DIR" -type f -name '*.md' | sort -f)
}


# Per-process guard: avoids redundant mtime scans when ensure_cache() is called
# from multiple functions within the same shell invocation.
_CACHE_CHECKED=0

# Ensures the cache exists and is up-to-date.
ensure_cache() {
  # Skip all checks if already verified in this process invocation
  (( _CACHE_CHECKED )) && return

  # If forced rebuild, or cache empty, index immediately
  if [[ -n "${CHEATS_REBUILD:-}" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi
  if [[ ! -s "$CHEATS_CACHE" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi
  
  # Check if any cheatsheet file is newer than the cache file
  local latest_src mtime_cache
  latest_src="$(find -L "$CHEATS_DIR" -type f -name '*.md' -printf '%T@\n' 2>/dev/null | sort -nr | head -n1 || true)"
  [[ -z "$latest_src" ]] && { index_cheats; _CACHE_CHECKED=1; return; }
  
  mtime_cache="$(stat -c '%Y' "$CHEATS_CACHE" 2>/dev/null || echo 0)"
  local latest_int="${latest_src%.*}"
  
  # If source file is newer, rebuild index
  if (( latest_int > mtime_cache )); then index_cheats; fi
  _CACHE_CHECKED=1
}

# Removes the YAML front-matter (Title, Group, etc.) from the display
# so the user sees only the clean content.
strip_front_matter() {
  sed -n -E '
    1,80{
      /^[[:space:]]*[Tt][Ii][Tt][Ll][Ee][[:space:]]*:/d
      /^[[:space:]]*[Gg][Rr][Oo][Uu][Pp][[:space:]]*:/d
      /^[[:space:]]*[Ii][Cc][Oo][Nn][[:space:]]*:/d
      /^[[:space:]]*[Oo][Rr][Dd][Ee][Rr][[:space:]]*:/d
    }
    p
  ' | tr -d '\r'
}

# ============= Layout Config =============

# Reads the persisted layout choice.
# Priority: env var DEVTOOLBOX_LAYOUT > config file > default (standard)
get_layout() {
  # Env var override takes highest priority
  if [[ -n "${DEVTOOLBOX_LAYOUT:-}" ]]; then
    echo "$DEVTOOLBOX_LAYOUT"
    return
  fi
  # Read from config file if it exists and is non-empty
  if [[ -s "$DEVTOOLBOX_LAYOUT_CONF" ]]; then
    local val
    val="$(cat "$DEVTOOLBOX_LAYOUT_CONF" | tr -d '[:space:]')"
    case "$val" in
      standard|zenity|drilldown) echo "$val"; return ;;
    esac
  fi
  # Default
  echo "standard"
}

# Persists the chosen layout to the config file.
# Called via Argos param dispatch: param1=setLayout param2=<layout>
setLayout() {
  local layout="${1:-standard}"
  # Validate input — only known values accepted
  case "$layout" in
    standard|zenity|drilldown) ;;
    *) layout="standard" ;;
  esac
  mkdir -p "$(dirname "$DEVTOOLBOX_LAYOUT_CONF")"
  printf '%s\n' "$layout" > "$DEVTOOLBOX_LAYOUT_CONF"
  # Also clear any active drill-down state so the next render starts clean
  rm -f "$ARGOS_CAT_STATE" 2>/dev/null || true
}

# ============= Drill-down state helpers (drilldown layout only) ============

# Write current category to state file.
argos_set_category() {
  mkdir -m 0700 -p "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
  local tmp_state
  tmp_state="$(mktemp "${ARGOS_CAT_STATE}.XXXXXX")"
  printf '%s' "$1" > "$tmp_state"
  chmod 600 "$tmp_state" 2>/dev/null || true
  mv -f "$tmp_state" "$ARGOS_CAT_STATE"
}

# Delete state file — returns to category list on next render.
argos_clear_category() {
  rm -f "$ARGOS_CAT_STATE"
}

# Read current category from state file, respecting ARGOS_CAT_TTL.
# Prints the category name if the state is still valid; empty string if expired or missing.
# Auto-deletes the state file when TTL is exceeded.
argos_get_category() {
  [[ -f "$ARGOS_CAT_STATE" ]] || { printf ''; return; }
  local mtime now age
  mtime="$(stat -c '%Y' "$ARGOS_CAT_STATE" 2>/dev/null || echo 0)"
  now="$(date +%s)"
  age=$(( now - mtime ))
  if (( age > ARGOS_CAT_TTL )); then
    rm -f "$ARGOS_CAT_STATE"
    printf ''
    return
  fi
  cat "$ARGOS_CAT_STATE"
}

# Returns pre-rendered Argos menu lines for a category's cheatsheets.
# On first call (or after CHEATS_CACHE update) generates the lines and writes
# them to a per-category cache file. Subsequent calls read the cache directly.
# Cache is invalidated automatically when CHEATS_CACHE is newer than the cache file.
# Each cheat line includes refresh=true so Argos re-renders after click.
argos_category_lines() {
  local grp="$1"
  local hash_sum cat_cache line
  hash_sum="$(printf '%s' "$grp" | sha256sum | awk '{print $1}')"
  cat_cache="${ARGOS_CAT_CACHE_DIR}/cat_${hash_sum}.lines"

  mkdir -p "$ARGOS_CAT_CACHE_DIR"

  # Serve from cache if it exists and is newer than the main cheatsheet index
  if [[ -f "$cat_cache" && "$cat_cache" -nt "$CHEATS_CACHE" ]]; then
    cat "$cat_cache"
    return
  fi

  # Generate, write to temporary cache, and output simultaneously
  local tmp_cache
  tmp_cache="$(mktemp "${cat_cache}.XXXXXX")"
  trap "rm -f '$tmp_cache' 2>/dev/null" EXIT

  while IFS=$'\t' read -r file title group icon order; do
    label="$(compose_label "$title" "$icon")"
    enc="$(printf '%s' "$file" | b64enc)"
    # refresh=true: Argos re-renders after click; showCheat dispatch clears state file
    line="$label | bash='$SCRIPT_PATH' param1=showCheat param2='$enc' terminal=false refresh=true"
    printf '%s\n' "$line" >> "$tmp_cache"
    printf '%s\n' "$line"
  done < <(awk -F'\t' -v gg="$grp" '$3==gg{printf "%s\t%s\t%s\t%s\t%05d\n",$1,$2,$3,$4,$5}' "$CHEATS_CACHE" \
           | sort -t$'\t' -k5,5n -k2,2f)

  chmod 644 "$tmp_cache" 2>/dev/null || true
  mv -f "$tmp_cache" "$cat_cache"
}

# ============= Actions ============

# Action: Show the cheatsheet content.
# Param2: Base64 encoded file path.
showCheat() {
  local enc="${2:-}" file="" title="" icon_meta="" body=""

  [[ -z "$enc" ]] && { notify "Dev Toolbox" "No payload (param2)"; return 0; }
  file="$(printf '%s' "$enc" | b64dec 2>/dev/null || true)"
  
  # Verify file existence. If missing, try to rebuild cache and find by basename.
  if [[ -z "$file" || ! -f "$file" ]]; then
    rm -f "$CHEATS_CACHE" 2>/dev/null || true
    ensure_cache
    local base found safe_base
    base="$(basename -- "$file")"
    # Escape glob metacharacters so find -name treats the pattern literally
    safe_base="$(printf '%s' "$base" | sed 's/[][*?\\]/\\&/g')"
    found="$(find "$CHEATS_DIR" -type f -name "$safe_base" 2>/dev/null | head -n1 || true)"
    [[ -n "$found" ]] && file="$found"
    [[ ! -f "$file" ]] && { notify "Dev Toolbox" "File not found: $file"; return 0; }
  fi

  # Extract metadata for display
  title="$(meta_val "$file" 'Title' | tr -d '\r' || true)"
  icon_meta="$(meta_val "$file" 'Icon' | tr -d '\r' || true)"
  [[ -z "$title" ]] && title="$(basename "$file" .md)"
  
  # Get content without metadata headers
  body="$(strip_front_matter < "$file")"

  # Copy to clipboard
  if [[ -n "$CLIPBOARD_COPY" ]]; then
    copy <<< "$body"
    notify "✅ Dev Toolbox" "$title (copied to clipboard)"
  else
    notify "✅ Dev Toolbox" "$title (displayed — no clipboard backend)"
  fi

  # Clear drill-down state so next Argos render returns to category list
  argos_clear_category

  # Compose popup title
  local popup_title="$title"
  [[ -n "$icon_meta" ]] && popup_title="$(compose_label "$title" "$icon_meta")"

  # Try to open with preferred viewer
  for viewer in $CHEAT_VIEWERS; do
    case "$viewer" in
      code)
        # Reuse VS Code window if available
        command -v code >/dev/null 2>&1 && code --reuse-window "$file" &>/dev/null && return 0
        ;;
      cat)
        command -v cat >/dev/null 2>&1 && cat "$file" && return 0
        ;;
      less)
        command -v less >/dev/null 2>&1 && less "$file" && return 0
        ;;
      zenity)
        command -v zenity >/dev/null 2>&1 && popup "$popup_title" "$body" && return 0
        ;;
      terminal)
        # Open in default terminal, display file / Открыть в терминале по умолчанию
        local escaped_file
        printf -v escaped_file '%q' "$file"
        run_in_terminal "cat $escaped_file" "$popup_title" && return 0
        ;;
      *)
        # Custom commands, if any
        if command -v "$viewer" >/dev/null 2>&1; then
          "$viewer" "$file" && return 0
        fi
        ;;
    esac
  done
}


# Action: Interactive search using dialog
searchCheatsFS() {
  ensure_cache
  local q; q=$(input_dialog "🔎 Search cheats" "Type to filter...") || exit 0
  [[ -z "$q" ]] && exit 0

  # Search in cache. Format: "Label<TAB>FILE"
  local list
  list="$(while IFS=$'\t' read -r file title group icon order; do
            label="$(compose_label "$title" "$icon")"
            printf "%s\t%s\n" "$label" "$file"
          done < "$CHEATS_CACHE" \
          | grep -i -F -- "$q" || true)"
  [[ -z "$list" ]] && { info_dialog "Search" "No matches found"; exit 0; }

  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | list_dialog "🔎 Select" "Cheats")" || exit 0
  [[ -z "$sel" ]] && exit 0

  # Find file path corresponding to selection
  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  showCheat _ "$(printf '%s' "$file" | b64enc)"
}

# Action: Browse cheatsheets (Hierarchical: Groups -> Cheats)
browseAllCheatsFS() {
  ensure_cache
  
  # 1. Get unique groups with icons / Получить список групп с иконками
  local groups_list
  groups_list=$(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sort -u | while read -r g; do
    [[ -z "$g" ]] && continue
    icon="${GROUP_ICON[$g]:-🧩}"
    echo "$icon $g"
  done)
  
  [[ -z "$groups_list" ]] && { info_dialog "Browse" "No categories found"; exit 0; }

  # 2. Show Category Dialog / Показать диалог категорий
  local sel_group_str
  sel_group_str=$(echo "$groups_list" | list_dialog "📚 Categories" "Select a Group") || exit 0
  [[ -z "$sel_group_str" ]] && exit 0
  
  # 3. Extract group name (remove icon) / Извлечь имя группы
  # "📚 Basics" -> "Basics"
  local group_name="${sel_group_str#* }"
  
  # 4. Browse cheats in this group / Просмотр читов в этой группе
  browseDeep_Cheats "$group_name"
}

# Helper: Browse cheats within a specific group
browseDeep_Cheats() {
  local target_group="$1"
  
  # Filter cheats for this group / Фильтр читов для этой группы
  local list
  list="$(
    awk -F'\t' -v g="$target_group" '$3==g {print $0}' "$CHEATS_CACHE" \
    | sort -t$'\t' -k5,5n -k2,2f \
    | while IFS=$'\t' read -r file title group icon order; do
        label="$(compose_label "$title" "$icon")"
        printf "%s\t%s\n" "$label" "$file"
      done
  )"
  
  [[ -z "$list" ]] && { info_dialog "Browse" "No cheats found in $target_group"; exit 0; }

  # Show Cheatsheet List / Показать список читшитов
  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | list_dialog "📂 $target_group" "Cheatsheets")" || exit 0
  [[ -z "$sel" ]] && exit 0

  # Find file and show / Найти файл и показать
  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  
  if [[ -n "$file" ]]; then
    showCheat _ "$(printf '%s' "$file" | b64enc)"
  fi
}


# Action: Export all cheatsheets to a single Markdown (and PDF if pandoc is present)
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
    # Sort by Group then Order, then print styled content
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


# Action: FZF Search for commands (Run in terminal)
fzfSearch() {
  ensure_cache
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: 'fzf' is not installed. Please install it to use this feature."
    read -r -p "Press enter to exit..."
    return
  fi

  local selected
  # Search all md files recursively.
  # Output format: file:line:content
  # fzf preview uses 'bat' if available, else 'cat'
  selected=$(grep -rnH --include="*.md" "." "$CHEATS_DIR" 2>/dev/null | \
             fzf --delimiter : \
                 --preview 'if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --highlight-line {2} {1}; else cat {1}; fi' \
                 --preview-window=right:60% \
                 --header 'Start typing to search commands... Enter to open.' \
                 --bind 'enter:accept') || return 0

  [[ -z "$selected" ]] && return

  local file line
  file=$(echo "$selected" | cut -d: -f1)
  line=$(echo "$selected" | cut -d: -f2)

  if [[ -n "$file" && -n "$line" ]]; then
     # Try to open in VS Code at specific line
     if command -v code >/dev/null 2>&1; then
       code -g "$file:$line"
     else
       # Fallback: EDITOR or nano
       local editor="${EDITOR:-nano}"
       "$editor" "+$line" "$file"
     fi
  fi
}

# Action: Show Settings info dialog
showSettings() {
  local layout; layout="$(get_layout)"
  local msg
  printf -v msg '%b' "Version: $VERSION\nDetected DE: $(detect_de)\nDialog tool: $(detect_dialog_tool)\nTerminal: $(default_terminal)\n\nConfiguration:\nDEVTOOLBOX_DE=$DEVTOOLBOX_DE (set to override DE)\nCHEATS_DIR=$CHEATS_DIR\nCHEATS_CACHE=$CHEATS_CACHE\nLayout: $layout (standard|zenity|drilldown)\nLayout config: $DEVTOOLBOX_LAYOUT_CONF"
  info_dialog "Dev Toolbox Settings" "$msg"
}

# ============= Compact menu dialog ============
# Dialog for when screen space is limited or requested directly
compactMenu() {
  ensure_cache

  # Build dynamic category list from cache
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
    "── Categories ──" \
    "${cat_items[@]}") || exit 0
  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "🚀 FZF Search Commands")
        # Launch FZF in terminal / Запустить FZF в терминале
        run_in_terminal "$SCRIPT_PATH fzfSearch" "FZF Search"
        ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
    "🌐 Online Version") xdg-open "https://cheats.alteron.net/" &>/dev/null ;;
    "🐙 GitHub Repository") xdg-open "https://github.com/dominatos/devtoolbox-cheats/" &>/dev/null ;;
    "⚙️ Settings")
        showSettings
        compactMenu
        ;;
    "── Categories ──") compactMenu ;;  # Divider — no-op, re-show menu
    *)
        # Category selected — extract group name (remove leading icon + space)
        local group_name="${choice#* }"
        browseDeep_Cheats "$group_name"
        ;;
  esac
}

# ============= Standalone Menu (Non-Argos) / Меню вне Argos =============
# For non-GNOME DEs or direct terminal invocation
standaloneMenu() {
  ensure_cache

  # Build dynamic category list from cache
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
    "── Categories ──" \
    "${cat_items[@]}") || exit 0

  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "🚀 FZF Search Commands")
        # Launch FZF in terminal / Запустить FZF в терминале
        if [[ -t 0 ]]; then
          fzfSearch
        else
          run_in_terminal "$SCRIPT_PATH fzfSearch" "FZF Search"
        fi
        ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
    "🌐 Online Version") xdg-open "https://cheats.alteron.net/" &>/dev/null ;;
    "🐙 GitHub Repository") xdg-open "https://github.com/dominatos/devtoolbox-cheats/" &>/dev/null ;;
    "⚙️ Settings")
        showSettings
        standaloneMenu
        ;;
    "── Categories ──") standaloneMenu ;;  # Divider — no-op, re-show menu
    *)
        # Category selected — extract group name (remove leading icon + space)
        local group_name="${choice#* }"
        browseDeep_Cheats "$group_name"
        ;;
  esac
}

# ============= Argos Layout Renderers =============

# --- Shared: small-screen header (same for all 3 layouts) ---
_render_small_screen_header() {
  local layout="$1"
  _render_functions_submenu "$layout"
  echo "📚 Browse all cheats    | bash='$SCRIPT_PATH' param1=browseAllCheatsFS terminal=false"
  echo "---"
}

# --- Shared: DevToolbox Functions submenu with layout switcher ---
_render_functions_submenu() {
  local layout="$1"
  local check_std="" check_zen="" check_dd=""
  case "$layout" in
    zenity)    check_zen="✅ " ;;
    drilldown) check_dd="✅ "  ;;
    *)         check_std="✅ " ;;
  esac

  echo "🛠 DevToolbox Functions"
  echo "-- 🌐 Online Version       | bash='xdg-open' param1='https://cheats.alteron.net/' terminal=false"
  echo "-- ⚙️ Open compact menu    | bash='$SCRIPT_PATH' param1=compactMenu terminal=false"
  echo "-- ⚙️ Settings             | bash='$SCRIPT_PATH' param1=showSettings terminal=false"
  echo "-- 🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
  echo "-- 🚀 FZF Search Commands  | bash='$SCRIPT_PATH' param1=fzfSearch terminal=true"
  echo "-- 📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"
  echo "-- 🐙 GitHub Repository   | bash='xdg-open' param1='https://github.com/dominatos/devtoolbox-cheats/' terminal=false"
  echo "-- 🐙 Edit this script   | bash='code' param1='$SCRIPT_PATH' terminal=false"
  echo "-- 🐙 Go to Argos folder | bash='doublecmd' param1='$HOME/.config/argos/' terminal=false"
  echo "-- ---"
  echo "-- 🔄 Layout"
  echo "-- -- ${check_std}Standard (inline submenus)    | bash='$SCRIPT_PATH' param1=setLayout param2=standard terminal=false refresh=true"
  echo "-- -- ${check_zen}Zenity (dialog cheat list)     | bash='$SCRIPT_PATH' param1=setLayout param2=zenity terminal=false refresh=true"
  echo "-- -- ${check_dd}Drill-down (category→cheats)   | bash='$SCRIPT_PATH' param1=setLayout param2=drilldown terminal=false refresh=true"
  echo "---"
}

# --- Layout 1: Standard — categories expand inline as Argos submenus ---
render_argos_standard() {
  local layout="$1"
  echo "🗒️ Cheatsheets"
  echo "---"

  if is_small_screen; then
    _render_small_screen_header "$layout"
  else
    _render_functions_submenu "$layout"
    # Groups — each is a top-level submenu; cheats listed as sub-items inline
    mapfile -t groups < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
    for g in "${groups[@]}"; do
      [[ -z "$g" ]] && continue
      gi="${GROUP_ICON[$g]:-🧩}"
      echo "$gi $g"
      # Read matching cheats for this group
      while IFS=$'\t' read -r file title group icon order; do
        [[ "$group" != "$g" ]] && continue
        label="$(compose_label "$title" "$icon")"
        enc="$(printf '%s' "$file" | b64enc)"
        echo "-- $label | bash='$SCRIPT_PATH' param1=showCheat param2='$enc' terminal=false"
      done < <(awk -F'\t' -v gg="$g" '$3==gg{printf "%s\t%s\t%s\t%s\t%05d\n",$1,$2,$3,$4,$5}' "$CHEATS_CACHE" \
               | sort -t$'\t' -k5,5n -k2,2f \
               | awk -F'\t' '{printf "%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,$5}')
    done
  fi
}

# --- Layout 2: Zenity — clicking a category opens a Zenity/dialog cheat list ---
render_argos_zenity() {
  local layout="$1"
  echo "🗒️ Cheatsheets"
  echo "---"

  if is_small_screen; then
    _render_small_screen_header "$layout"
  else
    _render_functions_submenu "$layout"
    # Categories at root — each category opens Zenity cheat list via browseDeep_Cheats
    mapfile -t groups < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
    for g in "${groups[@]}"; do
      [[ -z "$g" ]] && continue
      gi="${GROUP_ICON[$g]:-🧩}"
      enc_g="$(printf '%s' "$g" | b64enc)"
      echo "$gi $g | bash='$SCRIPT_PATH' param1=browseDeep_Cheats param2='$enc_g' terminal=false"
    done
  fi
}

# --- Layout 3: Drill-down — stateful per-category rendering ---
render_argos_drilldown() {
  local layout="$1"

  # Check drill-down state (TTL-aware: auto-expires after ARGOS_CAT_TTL seconds)
  local _drill_cat
  _drill_cat="$(argos_get_category)"

  if [[ -n "$_drill_cat" ]]; then
    # ===== DRILL-DOWN MODE =====
    # A category was selected. Show its cheats inline as top-level items.
    # Panel icon changes to the selected category name so the user knows where they are.
    local _drill_gi="${GROUP_ICON[$_drill_cat]:-🧩}"
    echo "$_drill_gi $_drill_cat"
    echo "---"
    # Back button — clears state, next render returns to category list
    echo "◀ All categories | bash='$SCRIPT_PATH' param1=clearCategory terminal=false refresh=true"
    echo "---"
    # Render all cheats for this category via cache (generated once, reused on refresh)
    argos_category_lines "$_drill_cat"

  else
    # ===== NORMAL MODE =====
    echo "🗒️ Cheatsheets"
    echo "---"

    if is_small_screen; then
      _render_small_screen_header "$layout"
    else
      _render_functions_submenu "$layout"

      # All categories shown directly at top level.
      # Each category is a clickable item that triggers drill-down (setCategory).
      mapfile -t groups < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
      for g in "${groups[@]}"; do
        [[ -z "$g" ]] && continue
        gi="${GROUP_ICON[$g]:-🧩}"
        enc_g="$(printf '%s' "$g" | b64enc)"
        echo "$gi $g | bash='$SCRIPT_PATH' param1=setCategory param2='$enc_g' terminal=false refresh=true"
      done
    fi
  fi
}

# ============= Argos param dispatch ============
# Handles arguments passed when clicking on menu items
case "${1:-}" in
  showCheat)
    argos_clear_category  # Reset drill-down state so next open shows category list
    showCheat "$@"
    exit 0
    ;;
  searchCheatsFS)      searchCheatsFS ; exit 0 ;;
  fzfSearch)           fzfSearch ; exit 0 ;;
  browseAllCheatsFS)   browseAllCheatsFS ; exit 0 ;;
  exportAllCheatsFS)   exportAllCheatsFS ; exit 0 ;;
  showSettings)        showSettings ; exit 0 ;;
  compactMenu)         compactMenu ; exit 0 ;;
  standaloneMenu)      standaloneMenu ; exit 0 ;;
  menu)                standaloneMenu ; exit 0 ;;  # Alias for easy invocation
  browseDeep_Cheats)
    # param2 = base64-encoded group name (handles spaces and special chars safely)
    _grp="$(printf '%s' "${2:-}" | b64dec 2>/dev/null || true)"
    ensure_cache
    browseDeep_Cheats "$_grp"
    exit 0
    ;;
  setLayout)
    # param2 = layout name (standard|zenity|drilldown)
    setLayout "${2:-}"
    exit 0
    ;;
  setCategory)
    # Drill-down: write selected category to state file.
    # param2 = base64-encoded group name.
    _grp="$(printf '%s' "${2:-}" | b64dec 2>/dev/null || true)"
    argos_set_category "$_grp"
    exit 0
    ;;
  clearCategory)
    # Drill-down: clear state file so next render returns to category list.
    argos_clear_category
    exit 0
    ;;
esac

# ============= DE Detection for Menu Rendering =============
# For GNOME: output Argos format
# For other DEs: launch standalone dialog menu
CURRENT_DE="$(detect_de)"
if [[ "$CURRENT_DE" != "gnome" ]]; then
  # Non-GNOME: launch standalone dialog menu / Не-GNOME: запустить диалоговое меню
  standaloneMenu
  exit 0
fi

# ============= MENU RENDER (Argos stdout) =============
ensure_cache

_active_layout="$(get_layout)"

case "$_active_layout" in
  zenity)    render_argos_zenity    "$_active_layout" ;;
  drilldown) render_argos_drilldown "$_active_layout" ;;
  *)         render_argos_standard  "$_active_layout" ;;
esac

# coded by Sviatoslav https://github.com/dominatos
echo "---"
