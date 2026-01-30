#!/usr/bin/env bash
set -Eeuo pipefail
trap '  exit 0' ERR

# ============= Config =============🖧
CHEATS_DIR="${CHEATS_DIR:-$HOME/.config/argos/cheats.d}"
CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats.idx}"
CHEATS_REBUILD=1 # set to 1 to force rebuild cache
# === Групповые иконки (заголовки разделов) ===
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
  
)


CHEAT_VIEWERS="${CHEAT_VIEWERS:-code zenity}"
CHEAT_VIEWERS="code antigravity windsurf zenity"
export PATH="/usr/local/bin:/usr/bin:$PATH"
SCRIPT_PATH="$(realpath -s "$0")"

# ============= Clipboard =============
if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
  CLIPBOARD_COPY="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  CLIPBOARD_COPY="xclip -selection clipboard"
else
  CLIPBOARD_COPY=""
fi
copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY" || true; }
# === Утилиты, чтобы не дублировать эмодзи ===
strip_leading_icon_if_same() { # args: <title> <icon>
  local title="$1" icon="$2"
  [[ -z "$icon" ]] && { printf '%s' "$title"; return; }
  # если title начинается с "<icon> " — убираем его
  if [[ "$title" == "$icon "* ]]; then
    printf '%s' "${title#"$icon "}"
  else
    printf '%s' "$title"
  fi
}

compose_label() { # args: <title> <icon>
  local title="$1" icon="$2"
  if [[ -n "$icon" ]]; then
    local t; t="$(strip_leading_icon_if_same "$title" "$icon")"
    printf '%s %s' "$icon" "$t"
  else
    printf '%s' "$title"
  fi
}
# ============= Screen / Windows ============
get_screen_dims() {
  local dims
  dims="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
  [[ -z "$dims" ]] && dims="$(xrandr --current 2>/dev/null | awk '/\*/{print $1; exit}')"
  echo "${dims:-1366x768}"
}
calc_window_size() {
  local dims w h win_w win_h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  win_w=$(( w * 80 / 100 ))
  win_h=$(( h * 70 / 100 ))
  [[ $win_w -lt 600 ]] && win_w=600
  [[ $win_h -lt 400 ]] && win_h=400
  echo "$win_w" "$win_h"
}
is_small_screen() {
  local dims w h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  (( w <= 1368 || h <= 768 ))
}

popup() {
  local w h
  read -r w h < <(calc_window_size)
  printf "%s" "$2" | zenity --text-info \
    --title="Dev Toolbox: $1" \
    --width="$w" --height="$h" \
    --filename=/dev/stdin --no-wrap \
    --ok-label="Close" 2>/dev/null
}

# ============= Base64 helpers (Argos params safe) ============
b64enc() {
  if base64 --help 2>/dev/null | grep -q -- '-w'; then
    base64 -w0 | tr -d '\n'
  else
    base64 | tr -d '\n'
  fi
}
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
meta_val() { # meta_val <file> <KeyRegexCaseInsensitive>
  local f="$1" key="$2"
  sed '1s/^\xEF\xBB\xBF//' "$f" | head -n 80 \
    | tr -d '\r' \
    | grep -i -m1 "^[[:space:]]*$key[[:space:]]*:" \
    | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
}
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
    # срежем CR на всякий случай
    title="${title%$'\r'}"; group="${group%$'\r'}"; icon="${icon%$'\r'}"; order="${order%$'\r'}"
    printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$title" "$group" "$icon" "$order" >> "$CHEATS_CACHE"
  done < <(find "$CHEATS_DIR" -type f -name '*.md' | sort -f)
}


ensure_cache() {
  if [[ -n "${CHEATS_REBUILD:-}" ]]; then index_cheats; return; fi
  if [[ ! -s "$CHEATS_CACHE" ]]; then index_cheats; return; fi
  local latest_src mtime_cache
  latest_src="$(find "$CHEATS_DIR" -type f -name '*.md' -printf '%T@\n' 2>/dev/null | sort -nr | head -n1 || true)"
  [[ -z "$latest_src" ]] && return
  mtime_cache="$(stat -c '%Y' "$CHEATS_CACHE" 2>/dev/null || echo 0)"
  local latest_int="${latest_src%.*}"
  if (( latest_int > mtime_cache )); then index_cheats; fi
}

# --- ЗАМЕНА strip_front_matter() ---
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
showCheat() {
  local enc="${2:-}" file="" title="" icon_meta="" body=""

  [[ -z "$enc" ]] && { notify-send "Dev Toolbox" "No payload (param2)"; return 0; }
  file="$(printf '%s' "$enc" | b64dec 2>/dev/null || true)"
  if [[ -z "$file" || ! -f "$file" ]]; then
    rm -f "$CHEATS_CACHE" 2>/dev/null || true
    ensure_cache
    local base found
    base="$(basename -- "$file")"
    found="$(find "$CHEATS_DIR" -type f -name "$base" 2>/dev/null | head -n1 || true)"
    [[ -n "$found" ]] && file="$found"
    [[ ! -f "$file" ]] && { notify-send "Dev Toolbox" "File not found:\n$file"; return 0; }
  fi

  title="$(meta_val "$file" 'Title' | tr -d '\r' || true)"
  icon_meta="$(meta_val "$file" 'Icon' | tr -d '\r' || true)"
  [[ -z "$title" ]] && title="$(basename "$file" .md)"
  body="$(strip_front_matter < "$file")"

  # Copy to clipboard
  copy <<<"$body"
  notify-send "✅ Dev Toolbox" "$title (copied / скопировано)" || true

  # Compose popup title
  local popup_title="$title"
  [[ -n "$icon_meta" ]] && popup_title="$(compose_label "$title" "$icon_meta")"

  # Viewer loop
  for viewer in $CHEAT_VIEWERS; do
    case "$viewer" in
      code)
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
      xterm)
        command -v xterm >/dev/null 2>&1 && xterm -hold -e "cat '$file'; read" && return 0
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



searchCheatsFS() {
  ensure_cache
  local q; q=$(zenity --entry --title="🔎 Search cheats" --text="Type to filter / Введите для поиска" 2>/dev/null) || exit 0
  [[ -z "$q" ]] && exit 0

  # Список: "Label<TAB>FILE"
  local list
  list="$(while IFS=$'\t' read -r file title group icon order; do
            label="$(compose_label "$title" "$icon")"
            printf "%s\t%s\n" "$label" "$file"
          done < "$CHEATS_CACHE" \
          | grep -i -F -- "$q" || true)"
  [[ -z "$list" ]] && { zenity --info --text="No matches / Нет совпадений" 2>/dev/null; exit 0; }

  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | \
        zenity --list --title="🔎 Select" --column="Cheats" \
               --height="$(calc_window_size | awk '{print $2}')" 2>/dev/null)" || exit 0
  [[ -z "$sel" ]] && exit 0

  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  showCheat _ "$(printf '%s' "$file" | b64enc)"
}

browseAllCheatsFS() {
  ensure_cache
  local list
list="$(
  while IFS=$'\t' read -r file title group icon order; do
    label="$(compose_label "$title" "$icon")"
    printf "%s  —  %s\t%s\t%05d\n" "$group" "$label" "$file" "$order"
  done < "$CHEATS_CACHE" | sort -t$'\t' -k3,3n -k1,1f
)"
  [[ -z "$list" ]] && { zenity --info --text="No cheats found / Шпаргалки не найдены" 2>/dev/null; exit 0; }

  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | \
        zenity --list --title="📚 All cheats" --column="Group — Title" \
               --height="$(calc_window_size | awk '{print $2}')" 2>/dev/null)" || exit 0
  [[ -z "$sel" ]] && exit 0

  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  showCheat _ "$(printf '%s' "$file" | b64enc)"
}


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
    # group+order sort
    awk -F'\t' '{printf "%s\t%05d\t%s\t%s\t%s\n",$3,$5,$4,$2,$1}' "$CHEATS_CACHE" \
    | sort -t$'\t' -k1,1f -k2,2n \
    | while IFS=$'\t' read -r group ord icon title file; do
        echo "## $(compose_label "$title" "$icon")"
        echo ""
        strip_front_matter < "$file"
        echo ""
      done
  } > "$out_md"

  local extra=""
  if command -v pandoc >/dev/null 2>&1; then
    if pandoc "$out_md" -o "$out_pdf" 2>/dev/null; then
      extra="\nPDF: $out_pdf"
    fi
  fi
  zenity --info --title="📥 Export complete" --text="Saved:\n<b>$out_md</b>${extra}" 2>/dev/null
}


# ============= Compact menu dialog ============
compactMenu() {
  local choice
  choice=$(
    zenity --list --title="Dev Toolbox (Compact)" \
           --text="Выберите действие" \
           --column="Action" \
           "🔎 Search cheats" \
           "📚 Browse all cheats" \
           "📥 Export all (MD/PDF)" \
           --height="$(calc_window_size | awk '{print $2}')" 2>/dev/null
  ) || exit 0
  case "$choice" in
    "🔎 Search cheats") searchCheatsFS ;;
    "📚 Browse all cheats") browseAllCheatsFS ;;
    "📥 Export all (MD/PDF)") exportAllCheatsFS ;;
  esac
}

# ============= Argos param dispatch ============
case "${1:-}" in
  showCheat)           showCheat "$@" ; exit 0 ;;
  searchCheatsFS)      searchCheatsFS ; exit 0 ;;
  browseAllCheatsFS)   browseAllCheatsFS ; exit 0 ;;
  exportAllCheatsFS)   exportAllCheatsFS ; exit 0 ;;
  compactMenu)         compactMenu ; exit 0 ;;
esac

# ============= MENU RENDER (Argos stdout) =============
echo "🗒️ Cheatsheet"
echo "---"

ensure_cache

if is_small_screen; then
  echo "🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
  echo "📚 Browse all cheats    | bash='$SCRIPT_PATH' param1=browseAllCheatsFS terminal=false"
  echo "📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"
  echo "---"
  echo "⚙️ Open compact menu    | bash='$SCRIPT_PATH' param1=compactMenu terminal=false"
  echo "---"
else
  # Quick actions (always useful)
  echo "🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
  echo "📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"

  echo "---"

  # Группы
  # Список уникальных групп:
  mapfile -t groups < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
for g in "${groups[@]}"; do
  [[ -z "$g" ]] && continue
  gi="${GROUP_ICON[$g]:-🧩}"
  echo "$gi $g"

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


echo "---"
