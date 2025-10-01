#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Dev Toolbox — Argos cheats menu (fully commented, EN-only UI)
# -----------------------------------------------------------------------------
# This script renders an Argos (GNOME panel) menu that exposes a searchable
# library of Markdown cheats. It also provides dialogs to browse and export
# cheats, and a compact UI. All UI strings are in English. The code is heavily
# commented for maintainability.
# -----------------------------------------------------------------------------

# ============= Config =========================================================
# Root directory with cheat Markdown files. You can override via env.
CHEATS_DIR="${CHEATS_DIR:-$HOME/.config/argos/cheats.d}"
# Cache file (TSV) storing an index for faster filtering and sorting.
CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats.idx}"
# If non-empty, always rebuild cache on each render; set to empty to enable
# smart incremental rebuilds.
CHEATS_REBUILD=1

# Group header icons used in the Argos submenu tree. Keys must match the
# "Group" front‑matter of your Markdown cheats (case-insensitive match is
# handled elsewhere).
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
)

# Ensure common paths are present (Argos runs in a slimmed shell env sometimes).
export PATH="/usr/local/bin:/usr/bin:$PATH"
# Absolute path to this script, used when Argos triggers actions.
SCRIPT_PATH="$(realpath -s "$0")"

# ============= Clipboard helpers =============================================
# Pick a Wayland or X11 clipboard tool if available. If neither is present,
# copying silently becomes a no-op.
if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
  CLIPBOARD_COPY="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  CLIPBOARD_COPY="xclip -selection clipboard"
else
  CLIPBOARD_COPY=""
fi
# Copy stdin to clipboard if a tool is configured.
copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY" || true; }

# ============= Label composition =============================================
# If title already starts with the same icon, avoid duplicating it.
strip_leading_icon_if_same() { # args: <title> <icon>
  local title="$1" icon="$2"
  [[ -z "$icon" ]] && { printf '%s' "$title"; return; }
  if [[ "$title" == "$icon "* ]]; then
    printf '%s' "${title#"$icon "}"
  else
    printf '%s' "$title"
  fi
}

# Compose a display label as "<icon> <title>", deduplicating if needed.
compose_label() { # args: <title> <icon>
  local title="$1" icon="$2"
  if [[ -n "$icon" ]]; then
    local t; t="$(strip_leading_icon_if_same "$title" "$icon")"
    printf '%s %s' "$icon" "$t"
  else
    printf '%s' "$title"
  fi
}

# ============= Screen / windows sizing =======================================
# Try xdpyinfo first (works on X11), fallback to xrandr, then default.
get_screen_dims() {
  local dims
  dims="$(xdpyinfo 2>/dev/null | awk '/dimensions:/{print $2; exit}')"
  [[ -z "$dims" ]] && dims="$(xrandr --current 2>/dev/null | awk '/\*/{print $1; exit}')"
  echo "${dims:-1366x768}"
}

# Calculate a reasonable dialog size (80% width, 70% height), with minimums.
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

# Small screen heuristic used to switch the Argos menu layout.
is_small_screen() {
  local dims w h
  dims="$(get_screen_dims)"
  w="${dims%x*}"; h="${dims#*x}"
  (( w <= 1368 || h <= 768 ))
}

# Show a read-only text viewer with zenity.
popup() {
  local w h
  read -r w h < <(calc_window_size)
  printf "%s" "$2" | zenity --text-info \
    --title="Dev Toolbox: $1" \
    --width="$w" --height="$h" \
    --filename=/dev/stdin --no-wrap \
    --ok-label="Close" 2>/dev/null
}

# ============= Base64 helpers (safe for Argos params) =========================
# Encode stdin as a single line base64 (GNU base64 uses -w0; BSD has no -w).
b64enc() {
  if base64 --help 2>/dev/null | grep -q -- '-w'; then
    base64 -w0 | tr -d '\n'
  else
    base64 | tr -d '\n'
  fi
}

# Decode base64 from stdin; support both GNU (-d) and macOS/BSD (-D).
b64dec() {
  if base64 -d </dev/null 2>/dev/null; then
    base64 -d
  else
    base64 -D
  fi
}

# ============= Index cheats (front‑matter parsing) ============================
# Extract a front‑matter key value (case-insensitive) from the first ~80 lines.
# Usage: meta_val <file> <KeyRegexCaseInsensitive>
meta_val() {
  local f="$1" key="$2"
  sed '1s/^\xEF\xBB\xBF//' "$f" | head -n 80 \
    | tr -d '\r' \
    | grep -i -m1 "^[[:space:]]*$key[[:space:]]*:" \
    | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
}

# Build the TSV cache: FILE<TAB>TITLE<TAB>GROUP<TAB>ICON<TAB>ORDER
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
    # Extra safety for CRLF leftovers.
    title="${title%$'\r'}"; group="${group%$'\r'}"; icon="${icon%$'\r'}"; order="${order%$'\r'}"
    printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$title" "$group" "$icon" "$order" >> "$CHEATS_CACHE"
  done < <(find "$CHEATS_DIR" -type f -name '*.md' | sort -f)
}

# Ensure cache exists and is fresh. If CHEATS_REBUILD is set, rebuild always.
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

# Remove small front‑matter keys from the cheat body before display/export.
# We intentionally only strip the specific keys that this launcher manages
# (Title, Group, Icon, Order) while preserving the rest of the content.
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

# ============= Actions ========================================================
# Open and display a single cheat. When not exporting, it also copies the body
# to the clipboard and shows a zenity viewer window.
showCheat() {
  local enc="${2:-}"
  local file; file="$(printf '%s' "$enc" | b64dec)"
  [[ -f "$file" ]] || { notify-send "Dev Toolbox" "File not found: $file"; exit 0; }

  local title
  title="$(meta_val "$file" 'Title')" || title="$(basename "$file" .md)"

  local body
  body="$(strip_front_matter < "$file")"

  if [[ -n "${EXPORT_MODE:-}" ]]; then
    printf "## %s\n\n%s\n\n" "$title" "$body"
    exit 0
  fi

  copy <<<"$body"
  notify-send "✅ Dev Toolbox" "$title (copied)" || true
  popup "$title" "$body"
}

# Search cheats using zenity prompts (case-insensitive substring search).
searchCheatsFS() {
  ensure_cache
  local q; q=$(zenity --entry --title="🔎 Search cheats" --text="Type to filter" 2>/dev/null) || exit 0
  [[ -z "$q" ]] && exit 0

  # Build a temporary list of "Label<TAB>FILE" for the dialog.
  local list label
  list="$(while IFS=$'\t' read -r file title group icon order; do
            label="$(compose_label "$title" "$icon")"
            printf "%s\t%s\n" "$label" "$file"
          done < "$CHEATS_CACHE" \
          | grep -i -F -- "$q" || true)"
  [[ -z "$list" ]] && { zenity --info --text="No matches" 2>/dev/null; exit 0; }

  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | \
        zenity --list --title="🔎 Select a cheat" --column="Cheats" \
               --height="$(calc_window_size | awk '{print $2}')" 2>/dev/null)" || exit 0
  [[ -z "$sel" ]] && exit 0

  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  showCheat _ "$(printf '%s' "$file" | b64enc)"
}

# Browse all cheats grouped, sorted by group (A..Z) and order (numeric).
browseAllCheatsFS() {
  ensure_cache
  local list label
  list="$(
    while IFS=$'\t' read -r file title group icon order; do
      label="$(compose_label "$title" "$icon")"
      printf "%s  —  %s\t%s\t%05d\n" "$group" "$label" "$file" "$order"
    done < "$CHEATS_CACHE" | sort -t$'\t' -k3,3n -k1,1f
  )"
  [[ -z "$list" ]] && { zenity --info --text="No cheats found" 2>/dev/null; exit 0; }

  local sel
  sel="$(printf "%s\n" "$list" | cut -f1 | \
        zenity --list --title="📚 All cheats" --column="Group — Title" \
               --height="$(calc_window_size | awk '{print $2}')" 2>/dev/null)" || exit 0
  [[ -z "$sel" ]] && exit 0

  local file
  file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
  showCheat _ "$(printf '%s' "$file" | b64enc)"
}

# Export all cheats into a single Markdown file; if pandoc is available, also
# export a PDF next to it. Show a completion dialog with paths.
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
    # Re-shape TSV to: GROUP\tORDER\tICON\tTITLE\tFILE, sort, then render.
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

# ============= Compact menu dialog ===========================================
# Minimal entry point that exposes the three core actions in a single list.
compactMenu() {
  local choice
  choice=$(
    zenity --list --title="Dev Toolbox (Compact)" \
           --text="Choose an action" \
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

# ============= Argos param dispatch ==========================================
# Argos calls the same script with parameters for actions; we dispatch here.
case "${1:-}" in
  showCheat)           showCheat "$@" ; exit 0 ;;
  searchCheatsFS)      searchCheatsFS ; exit 0 ;;
  browseAllCheatsFS)   browseAllCheatsFS ; exit 0 ;;
  exportAllCheatsFS)   exportAllCheatsFS ; exit 0 ;;
  compactMenu)         compactMenu ; exit 0 ;;
esac

# ============= MENU RENDER (Argos stdout) ====================================
# Everything printed below is rendered by Argos as a panel menu.
echo "🗒️ Cheatsheet"
echo "---"

ensure_cache

if is_small_screen; then
  # Compact layout for small screens.
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

  # Build a grouped tree: one submenu per Group, entries sorted by Order then Title.
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
echo "Open Argos folder | bash='doublecmd $HOME/.config/argos/' terminal=false"
echo "Open LAB folder   | bash='doublecmd $HOME/Documents/LAB/' terminal=false"
echo "Edit this script  | bash='code $SCRIPT_PATH' terminal=false"

echo "---"
