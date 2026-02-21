#!/usr/bin/env bash
# coded by Sviatoslav https://github.com/dominatos
set -Eeuo pipefail
trap '  exit 0' ERR

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
CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats-beta.idx}"
CHEATS_REBUILD=1 # Set to 1 to force a cache rebuild on every run (useful for debugging)

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
)


CHEAT_VIEWERS="${CHEAT_VIEWERS:-code zenity}"
CHEAT_VIEWERS="code antigravity windsurf zenity"
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
    yad)     yad --entry --title="$title" --text="$prompt" --center 2>/dev/null ;;
    zenity)  zenity --entry --title="$title" --text="$prompt" 2>/dev/null ;;
    *)       read -rp "$prompt: " reply; echo "$reply" ;;
  esac
}

# --- Info Dialog / Информационный диалог ---
info_dialog() {
  local title="$1" msg="$2"
  local tool="$(detect_dialog_tool)"
  
  case "$tool" in
    kdialog) kdialog --msgbox "$msg" --title "$title" 2>/dev/null ;;
    yad)     yad --info --title="$title" --text="$msg" --center 2>/dev/null ;;
    zenity)  zenity --info --title="$title" --text="$msg" 2>/dev/null ;;
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
        printf '%s\n' "$@" | yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1
      else
        yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1
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
  
  case "$term" in
    gnome-terminal) gnome-terminal --title="$title" -- bash -c "$cmd; read -rp 'Press Enter...'" ;;
    kgx)            kgx -- bash -c "$cmd; read -rp 'Press Enter...'" ;;
    konsole)        konsole --hold -e bash -c "$cmd" ;;
    yakuake)        konsole --hold -e bash -c "$cmd" ;;  # Fallback to konsole
    xfce4-terminal) xfce4-terminal --hold --title="$title" -e "bash -c \"$cmd\"" ;;
    mate-terminal)  mate-terminal --title="$title" -e "bash -c \"$cmd; read -rp 'Press Enter...'\"" ;;
    tilix)          tilix -e "bash -c \"$cmd; read -rp 'Press Enter...'\"" ;;
    terminator)     terminator -e "bash -c \"$cmd; read -rp 'Press Enter...'\"" ;;
    qterminal)      qterminal -e "bash -c \"$cmd; read -rp 'Press Enter...'\"" ;;
    lxterminal)     lxterminal --title="$title" -e "bash -c \"$cmd; read -rp 'Press Enter...'\"" ;;
    alacritty)      alacritty --hold -e bash -c "$cmd" ;;
    kitty)          kitty --hold bash -c "$cmd" ;;
    wezterm)        wezterm start -- bash -c "$cmd; read -rp 'Press Enter...'" ;;
    foot)           foot bash -c "$cmd; read -rp 'Press Enter...'" ;;
    st)             st -e bash -c "$cmd; read -rp 'Press Enter...'" ;;
    urxvt|rxvt-unicode) urxvt -hold -e bash -c "$cmd" ;;
    *)              xterm -hold -e bash -c "$cmd" ;;
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
# Detects screen dimensions to calculate appropriate window sizes for dialogs.
get_screen_dims() {
  local dims
  # Try xdpyinfo first (X11)
  dims="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
  # Fallback to xrandr (X11/Wayland with XWayland)
  [[ -z "$dims" ]] && dims="$(xrandr --current 2>/dev/null | awk '/\*/{print $1; exit}')"
  # Default fallback if detection fails
  echo "${dims:-1366x768}"
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

# Displays a text popup using DE-aware dialog.
# Now uses text_dialog() abstraction for cross-DE support.
popup() {
  text_dialog "Dev Toolbox: $1" "$2"
}

# ============= Base64 helpers (Argos params safe) ============
# Encodes string to base64, removing newlines for safe passing as arguments.
b64enc() {
  if base64 --help 2>/dev/null | grep -q -- '-w'; then
    base64 -w0 | tr -d '\n' # GNU coreutils
  else
    base64 | tr -d '\n'     # macOS / BSD
  fi
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
    | grep -i -m1 "^[[:space:]]*$key[[:space:]]*:" \
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


# Ensures the cache exists and is up-to-date.
ensure_cache() {
  # If forced rebuild, or cache empty, index immediately
  if [[ -n "${CHEATS_REBUILD:-}" ]]; then index_cheats; return; fi
  if [[ ! -s "$CHEATS_CACHE" ]]; then index_cheats; return; fi
  
  # Check if any cheatsheet file is newer than the cache file
  local latest_src mtime_cache
  latest_src="$(find -L "$CHEATS_DIR" -type f -name '*.md' -printf '%T@\n' 2>/dev/null | sort -nr | head -n1 || true)"
  [[ -z "$latest_src" ]] && return
  
  mtime_cache="$(stat -c '%Y' "$CHEATS_CACHE" 2>/dev/null || echo 0)"
  local latest_int="${latest_src%.*}"
  
  # If source file is newer, rebuild index
  if (( latest_int > mtime_cache )); then index_cheats; fi
}

# --- Replacement for strip_front_matter() ---
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
    local base found
    base="$(basename -- "$file")"
    found="$(find "$CHEATS_DIR" -type f -name "$base" 2>/dev/null | head -n1 || true)"
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
  copy <<<"$body"
  notify "✅ Dev Toolbox" "$title (copied to clipboard)"

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
        run_in_terminal "cat '$file'" "$popup_title" && return 0
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


# Action: Interactive search using Zenity
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

# Action: Browse all cheatsheets in a large list
# Action: Browse cheatsheets (Hierarchical: Groups -> Cheats)
browseAllCheatsFS() {
  ensure_cache
  
  # 1. Get unique groups with icons / Получить список групп с иконками
  local groups_list
  # awk faster than cut+loop / awk быстрее чем cut+loop
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
                 --preview-window 'right:60%' \
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

# ============= Compact menu dialog ============
# Dialog for when screen space is limited or requested directly
compactMenu() {
  local choice
  choice=$(list_dialog "Dev Toolbox (Compact)" "Action" \
    "🔎 Search cheats" \
    "🚀 FZF Search Commands" \
    "📚 Browse all cheats" \
    "📥 Export all (MD/PDF)") || exit 0
  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "🚀 FZF Search Commands")
        # Launch FZF in terminal / Запустить FZF в терминале
        run_in_terminal "$SCRIPT_PATH fzfSearch" "FZF Search"
        ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
  esac
}

# ============= Standalone Menu (Non-Argos) / Меню вне Argos =============
# For non-GNOME DEs or direct terminal invocation
standaloneMenu() {
  ensure_cache
  local choice
  choice=$(list_dialog "🗒️ Dev Toolbox" "Action" \
    "🔎 Search cheats" \
    "🚀 FZF Search Commands" \
    "📚 Browse all cheats" \
    "📥 Export all (MD/PDF)" \
    "⚙️ Settings") || exit 0
  
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
    "⚙️ Settings") 
        info_dialog "Dev Toolbox Settings" \
          "Detected DE: $(detect_de)\nDialog tool: $(detect_dialog_tool)\nTerminal: $(default_terminal)\n\nConfiguration:\nDEVTOOLBOX_DE=$DEVTOOLBOX_DE (set to override DE)\nCHEATS_DIR=$CHEATS_DIR\nCHEATS_CACHE=$CHEATS_CACHE"
        standaloneMenu
        ;;
  esac
}

# ============= Argos param dispatch ============
# Handles arguments passed when clicking on menu items
case "${1:-}" in
  showCheat)           showCheat "$@" ; exit 0 ;;
  searchCheatsFS)      searchCheatsFS ; exit 0 ;;
  fzfSearch)           fzfSearch ; exit 0 ;;
  browseAllCheatsFS)   browseAllCheatsFS ; exit 0 ;;
  exportAllCheatsFS)   exportAllCheatsFS ; exit 0 ;;
  compactMenu)         compactMenu ; exit 0 ;;
  standaloneMenu)      standaloneMenu ; exit 0 ;;
  menu)                standaloneMenu ; exit 0 ;;  # Alias for easy invocation
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
echo "🗒️ Cheatsheet"
echo "---"

ensure_cache

if is_small_screen; then
  echo "🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
  echo "🚀 FZF Search Commands  | bash='$SCRIPT_PATH' param1=fzfSearch terminal=true"
  echo "📚 Browse all cheats    | bash='$SCRIPT_PATH' param1=browseAllCheatsFS terminal=false"
  echo "📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"
  echo "---"
  echo "⚙️ Open compact menu    | bash='$SCRIPT_PATH' param1=compactMenu terminal=false"
  echo "---"
else
  # Quick actions (always useful)
  echo "🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
  echo "🚀 FZF Search Commands  | bash='$SCRIPT_PATH' param1=fzfSearch terminal=true"
  echo "📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"

  echo "---"

  # Groups
  # Get list of unique groups from cache
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

echo "---"
echo " Go to Argos folder | bash='doublecmd $HOME/.config/argos/' terminal=false"

echo " Edit this script | bash='code $SCRIPT_PATH' terminal=false"

# coded by Sviatoslav https://github.com/dominatos
echo "---"
