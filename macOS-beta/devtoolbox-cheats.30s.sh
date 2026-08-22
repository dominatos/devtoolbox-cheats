#!/bin/bash
# devtoolbox-cheats.30s.sh — macOS-native xbar/Argos cheatsheet menu
# Standalone script: ZERO dependencies on the Linux version.
# All functions use macOS-native APIs only (osascript, pbcopy, shasum, etc.)
#
# Requires: Bash 4+ (macOS ships with 3.2 which lacks mapfile, declare -A)
# This script auto-detects and re-executes with Homebrew Bash if needed.

# --- Auto-detect Bash 4+ and re-exec if needed ---
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    for bash_path in /opt/local/bin/bash /opt/homebrew/bin/bash /usr/local/bin/bash; do
        if [[ -x "$bash_path" ]]; then
            exec "$bash_path" "$0" "$@"
        fi
    done
    echo "ERROR: Bash 4+ required. Install with: brew install bash" >&2
    exit 1
fi

set -Eeuo pipefail
trap ' exit 0' ERR

VERSION="v1.5.5"

# ============= Config =============
CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
if [[ -L "$CHEATS_DIR" ]]; then
    CHEATS_DIR="$(cd "$(dirname "$CHEATS_DIR")" && pwd)/$(basename "$CHEATS_DIR")"
fi

CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats-combined.idx}"
CHEATS_REBUILD="${CHEATS_REBUILD:-}"

DEVTOOLBOX_LAYOUT_CONF="${HOME}/.config/devtoolbox-cheats/layout.conf"
DEVTOOLBOX_TOC_FORMAT_CONF="${HOME}/.config/devtoolbox-cheats/toc_format.conf"

ARGOS_RUNTIME_DIR="${HOME}/.cache/devtoolbox-cheats/run"
ARGOS_CAT_STATE="${ARGOS_RUNTIME_DIR}/argos-cat-combined.state"
ARGOS_CAT_TTL="${ARGOS_CAT_TTL:-60}"
ARGOS_CAT_CACHE_DIR="${HOME}/.cache/devtoolbox-cheats-argos-combined"
_ARGOS_TMP_CACHE=""

# === Group Icons (Section Headers) ===
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

# ============= Resolve Script Path (follow symlinks) =============
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_PATH="$(cd "$(dirname "$SOURCE")" && pwd)/$(basename "$SOURCE")"

export PATH="/opt/local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# ============= Clipboard =============
CLIPBOARD_COPY="pbcopy"
copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY"; }

# ============= macOS Abstraction Layer =============

open_url() {
    open "$1"
}

notify() {
    local title="$1" msg="$2"
    osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
}

input_dialog() {
    local title="$1" prompt="$2"
    osascript -e "set theText to text returned of (display dialog \"$prompt\" default answer \"\" with title \"$title\")" -e 'return theText' 2>/dev/null || true
}

info_dialog() {
    local title="$1" msg="$2"
    osascript -e "display dialog \"$msg\" with title \"$title\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null || true
}

text_dialog() {
    local title="$1" body="$2"
    osascript -e "display dialog \"$body\" with title \"$title\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null || true
}

# list_dialog: prefer fzf, fallback to osascript choose from list
list_dialog() {
    local title="$1" col="$2"
    shift 2

    local fzf_cmd=""
    for p in /opt/local/bin/fzf /opt/homebrew/bin/fzf /usr/local/bin/fzf; do
        if [[ -x "$p" ]]; then
            fzf_cmd="$p"
            break
        fi
    done
    if [[ -z "$fzf_cmd" ]] && command -v fzf >/dev/null 2>&1; then
        fzf_cmd="fzf"
    fi

    if [[ -n "$fzf_cmd" ]]; then
        if [[ $# -gt 0 ]]; then
            printf '%s\n' "$@" | "$fzf_cmd" --prompt="$title > " --height=40% --reverse
        else
            "$fzf_cmd" --prompt="$title > " --height=40% --reverse
        fi
    else
        # Native macOS list dialog. Pass values through argv instead of interpolating
        # them into AppleScript source, because titles may contain quotes or symbols.
        if [[ $# -gt 0 ]]; then
            osascript - "$title" "$col" "$@" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    set dialog_title to item 1 of argv
    set prompt_text to item 2 of argv
    set choices to items 3 thru -1 of argv
    set selected_item to choose from list choices with prompt prompt_text with title dialog_title
    if selected_item is not false then return item 1 of selected_item
end run
APPLESCRIPT
        fi
    fi
}

# ============= Screen / Windows =============
_SCREEN_DIMS_CACHED=""

get_screen_dims() {
    if [[ -n "$_SCREEN_DIMS_CACHED" ]]; then
        echo "$_SCREEN_DIMS_CACHED"
        return
    fi
    local dims
    dims="$(system_profiler SPDisplaysDataType 2>/dev/null | awk '/Resolution/{print $2"x"$4; exit}')"
    _SCREEN_DIMS_CACHED="${dims:-1366x768}"
    echo "$_SCREEN_DIMS_CACHED"
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
    [[ $max_groups -lt 5 ]] && max_groups=5
    echo "$max_groups"
}

popup() {
    text_dialog "Dev Toolbox: $1" "$2"
}

run_in_terminal() {
    local cmd="$1" title="${2:-Dev Toolbox}"
    osascript <<APPLESCRIPT 2>/dev/null || true
tell application "Terminal"
    activate
    do script "$cmd"
    set custom title of front window to "$title"
end tell
APPLESCRIPT
}

is_argos() {
    [[ -n "${ARGOS_VERSION:-}" || "$0" == *".sh" ]]
}

# ============= Utilities =============

strip_leading_icon_if_same() {
    local title="$1" icon="$2"
    [[ -z "$icon" ]] && { printf '%s' "$title"; return; }
    if [[ "$title" == "$icon "* ]]; then
        printf '%s' "${title#"$icon "}"
    else
        printf '%s' "$title"
    fi
}

compose_label() {
    local title="$1" icon="$2"
    if [[ -n "$icon" ]]; then
        local t; t="$(strip_leading_icon_if_same "$title" "$icon")"
        printf '%s %s' "$icon" "$t"
    else
        printf '%s' "$title"
    fi
}

# ============= Base64 helpers =============
_B64ENC_FLAG=""

b64enc() {
    base64 ${_B64ENC_FLAG} | tr -d '\n'
}

b64dec() {
    base64 -D
}

# ============= Index cheats =============

meta_val() {
    local f="$1" key="$2"
    sed '1s/^\xEF\xBB\xBF//' "$f" | head -n 80 \
        | tr -d '\r' \
        | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
        | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//' \
        | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'/\1/"
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

        title="${title%$'\r'}"; group="${group%$'\r'}"; icon="${icon%$'\r'}"; order="${order%$'\r'}"

        printf "%s\t%s\t%s\t%s\t%s\n" "$f" "$title" "$group" "$icon" "$order" >> "$CHEATS_CACHE"
    done < <(find -L "$CHEATS_DIR" -type f -name '*.md' | sort -f)
}

_CACHE_CHECKED=0

ensure_cache() {
    (( _CACHE_CHECKED )) && return

    if [[ -n "${CHEATS_REBUILD:-}" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi
    if [[ ! -s "$CHEATS_CACHE" ]]; then index_cheats; _CACHE_CHECKED=1; return; fi

    local latest_src mtime_cache
    latest_src="$(find -L "$CHEATS_DIR" -type f -name '*.md' -exec stat -f '%m' {} + 2>/dev/null | sort -nr | head -n1 || true)"
    [[ -z "$latest_src" ]] && { index_cheats; _CACHE_CHECKED=1; return; }

    mtime_cache="$(stat -f '%m' "$CHEATS_CACHE" 2>/dev/null || echo 0)"
    local latest_int="${latest_src%.*}"

    if (( latest_int > mtime_cache )); then index_cheats; fi
    _CACHE_CHECKED=1
}

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

get_layout() {
    if [[ -n "${DEVTOOLBOX_LAYOUT:-}" ]]; then
        echo "$DEVTOOLBOX_LAYOUT"
        return
    fi
    if [[ -s "$DEVTOOLBOX_LAYOUT_CONF" ]]; then
        local val
        val="$(tr -d '[:space:]' < "$DEVTOOLBOX_LAYOUT_CONF")"
        case "$val" in
            standard|zenity|drilldown) echo "$val"; return ;;
        esac
    fi
    echo "standard"
}

setLayout() {
    local layout="${1:-standard}"
    case "$layout" in
        standard|zenity|drilldown) ;;
        *) layout="standard" ;;
    esac
    mkdir -p "$(dirname "$DEVTOOLBOX_LAYOUT_CONF")"
    printf '%s\n' "$layout" > "$DEVTOOLBOX_LAYOUT_CONF"
    rm -f "$ARGOS_CAT_STATE" 2>/dev/null || true
}

get_toc_format() {
    if [[ -n "${DEVTOOLBOX_TOC_FORMAT:-}" ]]; then
        case "$DEVTOOLBOX_TOC_FORMAT" in
            obsidian|github) echo "$DEVTOOLBOX_TOC_FORMAT"; return ;;
        esac
    fi
    if [[ -s "$DEVTOOLBOX_TOC_FORMAT_CONF" ]]; then
        local val
        val="$(tr -d '[:space:]' < "$DEVTOOLBOX_TOC_FORMAT_CONF")"
        case "$val" in
            obsidian|github) echo "$val"; return ;;
        esac
    fi
    echo "obsidian"
}

setTocFormat() {
    local format="${1:-obsidian}"
    case "$format" in
        obsidian|github) ;;
        *) format="obsidian" ;;
    esac
    mkdir -p "$(dirname "$DEVTOOLBOX_TOC_FORMAT_CONF")"
    printf '%s\n' "$format" > "$DEVTOOLBOX_TOC_FORMAT_CONF"
}

applyTocFormat() {
    local format
    format="$(get_toc_format)"

    if ! command -v python3 &>/dev/null; then
        notify "DevToolbox Cheats" "python3 not found — cannot apply TOC formatting"
        return 1
    fi

    local py_script=""
    local script_dir
    script_dir="$(dirname "$SCRIPT_PATH")"
    for candidate in \
        "${HOME}/.local/share/devtoolbox-cheats/tools/manage-tocs.py" \
        "${script_dir}/tools/manage-tocs.py" \
        "${HOME}/devtoolbox-cheats/tools/manage-tocs.py"; do
        if [[ -f "$candidate" ]]; then
            py_script="$candidate"
            break
        fi
    done

    if [[ -n "$py_script" ]]; then
        if python3 "$py_script" --style "$format" --dir "$CHEATS_DIR"; then
            notify "DevToolbox Cheats" "TOC Formatting applied: $format"
        else
            notify "DevToolbox Cheats" "Failed to apply TOC formatting"
            return 1
        fi
    else
        notify "DevToolbox Cheats" "manage-tocs.py not found. Run: cheats-updater update"
        return 1
    fi
}

# ============= Drill-down state helpers =============

argos_set_category() {
    mkdir -p "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
    chmod 0700 "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
    local tmp_state
    tmp_state="$(mktemp "${ARGOS_CAT_STATE}.XXXXXX")"
    printf '%s' "$1" > "$tmp_state"
    chmod 600 "$tmp_state" 2>/dev/null || true
    mv -f "$tmp_state" "$ARGOS_CAT_STATE"
}

argos_clear_category() {
    rm -f "$ARGOS_CAT_STATE"
}

argos_get_category() {
    [[ -f "$ARGOS_CAT_STATE" ]] || { printf ''; return; }
    local mtime now age
    mtime="$(stat -f '%m' "$ARGOS_CAT_STATE" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    age=$(( now - mtime ))
    if (( age > ARGOS_CAT_TTL )); then
        rm -f "$ARGOS_CAT_STATE"
        printf ''
        return
    fi
    cat "$ARGOS_CAT_STATE"
}

argos_category_lines() {
    local grp="$1"
    local hash_sum cat_cache line
    hash_sum="$(printf '%s' "$grp" | shasum -a 256 | awk '{print $1}')"
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

# ============= Actions ============

showCheat() {
    local enc="${2:-}" file="" title="" icon_meta="" body=""

    [[ -z "$enc" ]] && { notify "Dev Toolbox" "No payload (param2)"; return 0; }
    file="$(printf '%s' "$enc" | b64dec 2>/dev/null || true)"

    if [[ -z "$file" || ! -f "$file" ]]; then
        rm -f "$CHEATS_CACHE" 2>/dev/null || true
        ensure_cache
        local base found safe_base
        base="$(basename -- "$file")"
        safe_base="$(printf '%s' "$base" | sed 's/[][*?\\]/\\&/g')"
        found="$(find "$CHEATS_DIR" -type f -name "$safe_base" 2>/dev/null | head -n1 || true)"
        [[ -n "$found" ]] && file="$found"
        [[ ! -f "$file" ]] && { notify "Dev Toolbox" "File not found: $file"; return 0; }
    fi

    title="$(meta_val "$file" 'Title' | tr -d '\r' || true)"
    icon_meta="$(meta_val "$file" 'Icon' | tr -d '\r' || true)"
    [[ -z "$title" ]] && title="$(basename "$file" .md)"

    body="$(strip_front_matter < "$file")"

    local _copy_rc=0
    if [[ -n "$CLIPBOARD_COPY" ]]; then
        copy <<< "$body" || _copy_rc=$?
    fi
    if [[ $_copy_rc -eq 0 && -n "$CLIPBOARD_COPY" ]]; then
        notify "✅ Dev Toolbox" "$title (copied to clipboard)"
    elif [[ -n "$CLIPBOARD_COPY" ]]; then
        notify "⚠️ Dev Toolbox" "$title (clipboard failed — displayed only)"
    else
        notify "✅ Dev Toolbox" "$title (displayed — no clipboard backend)"
    fi

    argos_clear_category

    local popup_title="$title"
    [[ -n "$icon_meta" ]] && popup_title="$(compose_label "$title" "$icon_meta")"

    local CHEAT_VIEWERS="${CHEAT_VIEWERS:-code textedit default}"
    for viewer in $CHEAT_VIEWERS; do
        case "$viewer" in
            code)
                if command -v code >/dev/null 2>&1; then
                    code --reuse-window "$file" 2>/dev/null
                    return 0
                fi
                ;;
            textedit)
                open -a TextEdit "$file" 2>/dev/null && return 0
                ;;
            default)
                open "$file" 2>/dev/null && return 0
                ;;
            cat)
                command -v cat >/dev/null 2>&1 && cat "$file" && return 0
                ;;
            less)
                command -v less >/dev/null 2>&1 && less "$file" && return 0
                ;;
            terminal)
                local escaped_file
                escaped_file="$(printf '%q' "$file")"
                run_in_terminal "cat $escaped_file" "$popup_title" && return 0
                ;;
            *)
                if command -v "$viewer" >/dev/null 2>&1; then
                    "$viewer" "$file" && return 0
                fi
                ;;
        esac
    done
}

searchCheatsFS() {
    ensure_cache
    local q; q=$(input_dialog "🔎 Search cheats" "Type to filter...") || exit 0
    [[ -z "$q" ]] && exit 0

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

    local file
    file="$(printf "%s\n" "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"
    showCheat _ "$(printf '%s' "$file" | b64enc)"
}

browseAllCheatsFS() {
    ensure_cache

    local groups_list
    groups_list=$(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sort -u | while read -r g; do
        [[ -z "$g" ]] && continue
        icon="${GROUP_ICON[$g]:-🧩}"
        echo "$icon $g"
    done)

    [[ -z "$groups_list" ]] && { info_dialog "Browse" "No categories found"; exit 0; }

    local sel_group_str
    sel_group_str=$(echo "$groups_list" | list_dialog "📚 Categories" "Select a Group") || exit 0
    [[ -z "$sel_group_str" ]] && exit 0

    local group_name="${sel_group_str#* }"

    browseDeep_Cheats "$group_name"
}

browseDeep_Cheats() {
    local target_group="$1"

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

    local sel
    sel="$(printf "%s\n" "$list" | cut -f1 | list_dialog "📂 $target_group" "Cheatsheets")" || exit 0
    [[ -z "$sel" ]] && exit 0

    local file
    file="$(printf '%s\n' "$list" | awk -F'\t' -v s="$sel" '$1==s{print $2; exit}')"

    if [[ -n "$file" ]]; then
        showCheat _ "$(printf '%s' "$file" | b64enc)"
    fi
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

fzfSearch() {
    ensure_cache
    local fzf_cmd=""
    for p in /opt/local/bin/fzf /opt/homebrew/bin/fzf /usr/local/bin/fzf; do
        if [[ -x "$p" ]]; then
            fzf_cmd="$p"
            break
        fi
    done
    if [[ -z "$fzf_cmd" ]] && command -v fzf >/dev/null 2>&1; then
        fzf_cmd="fzf"
    fi

    if [[ -z "$fzf_cmd" ]]; then
        echo "Error: 'fzf' is not installed. Please install it to use this feature."
        read -r -p "Press enter to exit..."
        return
    fi

    local selected
    selected=$(grep -rnH --include="*.md" "." "$CHEATS_DIR" 2>/dev/null | \
               "$fzf_cmd" --delimiter : \
                   --preview 'if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --highlight-line {2} {1}; else cat {1}; fi' \
                   --preview-window=right:60% \
                   --header 'Start typing to search commands... Enter to open.' \
                   --bind 'enter:accept') || return 0

    [[ -z "$selected" ]] && return

    local file line
    file=$(echo "$selected" | cut -d: -f1)
    line=$(echo "$selected" | cut -d: -f2)

    if [[ -n "$file" && -n "$line" ]]; then
        if command -v code >/dev/null 2>&1; then
            code -g "$file:$line"
        else
            local editor="${EDITOR:-nano}"
            "$editor" "+$line" "$file"
        fi
    fi
}

showSettings() {
    local layout; layout="$(get_layout)"
    local toc_fmt; toc_fmt="$(get_toc_format)"
    local msg
    printf -v msg '%b' "Version: $VERSION\nPlatform: macOS\n\nConfiguration:\nDEVTOOLBOX_DE=$DEVTOOLBOX_DE\nCHEATS_DIR=$CHEATS_DIR\nCHEATS_CACHE=$CHEATS_CACHE\nLayout: $layout (standard|zenity|drilldown)\nLayout config: $DEVTOOLBOX_LAYOUT_CONF\nTOC Format: $toc_fmt (obsidian|github)"
    info_dialog "Dev Toolbox Settings" "$msg"
}

settingsTocFormat() {
    local current; current="$(get_toc_format)"
    local obs_label="Obsidian (Exact text, %20)"
    local gh_label="GitHub (Lowercase slugs)"
    local choice
    choice=$(list_dialog "📝 TOC Format  [current: ${current}]" "Style" \
        "$obs_label" \
        "$gh_label") || return 0

    local new_fmt
    case "$choice" in
        "$obs_label") new_fmt="obsidian" ;;
        "$gh_label")  new_fmt="github" ;;
        *) return 0 ;;
    esac

    setTocFormat "$new_fmt"
    applyTocFormat
}

# ============= Compact menu dialog ============
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
        "🌐 Online Version") open_url "https://cheats.alteron.net/" &>/dev/null ;;
        "🐙 GitHub Repository") open_url "https://github.com/dominatos/devtoolbox-cheats/" &>/dev/null ;;
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

# ============= Standalone Menu =============
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
        "🌐 Online Version") open_url "https://cheats.alteron.net/" &>/dev/null ;;
        "🐙 GitHub Repository") open_url "https://github.com/dominatos/devtoolbox-cheats/" &>/dev/null ;;
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

# ============= Argos/xbar Layout Renderers =============

_render_small_screen_header() {
    local layout="$1"
    _render_functions_submenu "$layout"
    echo "📚 Browse all cheats    | bash='$SCRIPT_PATH' param1=browseAllCheatsFS terminal=false"
    echo "---"
}

_render_functions_submenu() {
    local layout="$1"
    local check_std="" check_zen="" check_dd=""
    case "$layout" in
        zenity)    check_zen="✅ " ;;
        drilldown) check_dd="✅ "  ;;
        *)         check_std="✅ " ;;
    esac

    echo "🛠 DevToolbox Functions"
    echo "-- 🌐 Online Version       | bash='$SCRIPT_PATH' param1=openUrl param2='https://cheats.alteron.net/' terminal=false"
    echo "-- ⚙️ Open compact menu    | bash='$SCRIPT_PATH' param1=compactMenu terminal=false"
    echo "-- 🔎 Search cheats        | bash='$SCRIPT_PATH' param1=searchCheatsFS terminal=false"
    echo "-- 🚀 FZF Search Commands  | bash='$SCRIPT_PATH' param1=fzfSearch terminal=true"
    echo "-- 📥 Export all (MD/PDF)  | bash='$SCRIPT_PATH' param1=exportAllCheatsFS terminal=false"
    echo "-- 🐙 GitHub Repository  | bash='$SCRIPT_PATH' param1=openUrl param2='https://github.com/dominatos/devtoolbox-cheats/' terminal=false"
    echo "-- ⚙️ Settings             | bash='$SCRIPT_PATH' param1=showSettings terminal=false"
    echo "-- Layout Options"
    echo "-- -- ${check_std}Standard (inline submenus)    | bash='$SCRIPT_PATH' param1=setLayout param2=standard terminal=false refresh=true"
    echo "-- -- ${check_zen}Zenity (dialog cheat list)     | bash='$SCRIPT_PATH' param1=setLayout param2=zenity terminal=false refresh=true"
    echo "-- -- ${check_dd}Drill-down (category→cheats)   | bash='$SCRIPT_PATH' param1=setLayout param2=drilldown terminal=false refresh=true"

    local toc_fmt
    toc_fmt="$(get_toc_format)"
    local check_obs="" check_gh=""
    [[ "$toc_fmt" == "obsidian" ]] && check_obs="✅ "
    [[ "$toc_fmt" == "github" ]] && check_gh="✅ "

    echo "-- TOC Formatting"
    echo "-- -- ${check_obs}Obsidian (Exact, %20) | bash='$SCRIPT_PATH' param1=setTocFormat param2=obsidian terminal=false refresh=true"
    echo "-- -- ${check_gh}GitHub (Slugs)        | bash='$SCRIPT_PATH' param1=setTocFormat param2=github terminal=false refresh=true"
    echo "---"
}

render_argos_standard() {
    local layout="$1"
    echo "🗒️ Cheatsheets"
    echo "---"

    if is_small_screen; then
        _render_small_screen_header "$layout"
    else
        _render_functions_submenu "$layout"
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
}

render_argos_zenity() {
    local layout="$1"
    echo "🗒️ Cheatsheets"
    echo "---"

    if is_small_screen; then
        _render_small_screen_header "$layout"
    else
        _render_functions_submenu "$layout"
        mapfile -t groups < <(cut -f3 "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
        for g in "${groups[@]}"; do
            [[ -z "$g" ]] && continue
            gi="${GROUP_ICON[$g]:-🧩}"
            enc_g="$(printf '%s' "$g" | b64enc)"
            echo "$gi $g | bash='$SCRIPT_PATH' param1=browseDeep_Cheats param2='$enc_g' terminal=false"
        done
    fi
}

render_argos_drilldown() {
    local layout="$1"

    local _drill_cat
    _drill_cat="$(argos_get_category)"

    if [[ -n "$_drill_cat" ]]; then
        local _drill_gi="${GROUP_ICON[$_drill_cat]:-🧩}"
        echo "$_drill_gi $_drill_cat"
        echo "---"
        echo "◀ All categories | bash='$SCRIPT_PATH' param1=clearCategory terminal=false refresh=true"
        echo "---"
        argos_category_lines "$_drill_cat"

    else
        echo "🗒️ Cheatsheets"
        echo "---"

        if is_small_screen; then
            _render_small_screen_header "$layout"
        else
            _render_functions_submenu "$layout"
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

# ============= xbar param dispatch ============
case "${1:-}" in
    showCheat)
        argos_clear_category
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
    menu)                standaloneMenu ; exit 0 ;;
    browseDeep_Cheats)
        _grp="$(printf '%s' "${2:-}" | b64dec 2>/dev/null || true)"
        ensure_cache
        browseDeep_Cheats "$_grp"
        exit 0
        ;;
    setLayout)
        setLayout "${2:-}"
        exit 0
        ;;
    setTocFormat)
        setTocFormat "${2:-}"
        applyTocFormat
        exit 0
        ;;
    applyTocFormat)
        applyTocFormat
        exit 0
        ;;
    setCategory)
        _grp="$(printf '%s' "${2:-}" | b64dec 2>/dev/null || true)"
        argos_set_category "$_grp"
        exit 0
        ;;
    clearCategory)
        argos_clear_category
        exit 0
        ;;
    openUrl)
        open_url "${2:-}"
        exit 0
        ;;
esac

# ============= Main: render Argos/xbar menu =============
# When invoked with no action params, render the menu output for xbar.
ensure_cache

_active_layout="$(get_layout)"

case "$_active_layout" in
    zenity)    render_argos_zenity    "$_active_layout" ;;
    drilldown) render_argos_drilldown "$_active_layout" ;;
    *)         render_argos_standard  "$_active_layout" ;;
esac

# coded by Sviatoslav https://github.com/dominatos
echo "---"
