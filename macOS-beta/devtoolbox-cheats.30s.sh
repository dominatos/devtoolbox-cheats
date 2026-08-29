#!/usr/bin/env bash
# <xbar.title>DevToolbox Cheats</xbar.title>
# <xbar.version>v1.5.6</xbar.version>
# <xbar.author>Sviatoslav</xbar.author>
# <xbar.author.github>dominatos</xbar.author.github>
# <xbar.abouturl>https://github.com/dominatos/devtoolbox-cheats</xbar.abouturl>

# devtoolbox-cheats.30s.sh — macOS-native SwiftBar cheatsheet menu
# Standalone script: ZERO dependencies on the Linux version.
# All functions use macOS-native APIs only (osascript, pbcopy, shasum, etc.)
#
# Requires: Bash 4+ (macOS ships with 3.2 which lacks mapfile, declare -A)
# This script auto-detects and re-executes with Homebrew Bash if needed.

# --- Auto-detect Bash 4+ and re-exec if needed ---
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    # Loop protection: the flag is only meaningful while still on Bash < 4.
    # A successful re-exec inherits it but exits this branch immediately.
    if [[ -n "${_DEVTOOLBOX_BASH_REEXEC:-}" ]]; then
        echo "ERROR: Bash 4+ required but re-exec already attempted." >&2
        echo "Install a modern Bash first: brew install bash" >&2
        exit 1
    fi
    # Verify each candidate really provides Bash 4+ before exec'ing into it.
    for bash_path in /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash; do
        # shellcheck disable=SC2016  # must stay single-quoted: evaluated by the candidate bash
        if [[ -x "$bash_path" ]] && "$bash_path" -c '[[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]' 2>/dev/null; then
            export _DEVTOOLBOX_BASH_REEXEC=1
            # Ensure the re-exec uses an absolute path in case xbar invoked us with a relative path
            _script_path="$0"
            [[ "$_script_path" != /* ]] && _script_path="$PWD/$_script_path"
            exec "$bash_path" "$_script_path" "$@"
        fi
    done
    echo "ERROR: Bash 4+ required." >&2
    echo "  Install with Homebrew: brew install bash" >&2
    echo "  Or with MacPorts:      sudo port install bash" >&2
    exit 1
fi

set -Eeuo pipefail

VERSION="v1.5.6"

# ============= Config =============
CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
# xbar's <xbar.var> metadata can pass the default through UNEXPANDED
# (literal '$HOME/cheats.d'), which silently yields an empty cheatsheet
# index. Expand it and fall back to the standard location.
# shellcheck disable=SC2016  # $HOME is a literal pattern, not a shell expansion
case "$CHEATS_DIR" in
    *'$HOME'*) CHEATS_DIR="${CHEATS_DIR//\$HOME/$HOME}" ;;
esac
if [[ ! -d "$CHEATS_DIR" && -d "$HOME/cheats.d" ]]; then
    CHEATS_DIR="$HOME/cheats.d"
fi
if [[ -L "$CHEATS_DIR" ]]; then
    # Resolve the directory symlink itself (not just its parent).
    resolved_dir="$(cd -P "$CHEATS_DIR" 2>/dev/null && pwd)" || resolved_dir=""
    if [[ -n "$resolved_dir" ]]; then
        CHEATS_DIR="$resolved_dir"
    else
        echo "WARNING: CHEATS_DIR symlink cannot be resolved, using as-is: $CHEATS_DIR" >&2
    fi
fi

CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats-combined.idx}"
CHEATS_REBUILD="${CHEATS_REBUILD:-}"

DEVTOOLBOX_LAYOUT_CONF="${HOME}/.config/devtoolbox-cheats/layout.conf"
DEVTOOLBOX_TOC_FORMAT_CONF="${HOME}/.config/devtoolbox-cheats/toc_format.conf"
DEVTOOLBOX_VIEWER_CONF="${HOME}/.config/devtoolbox-cheats/viewer.conf"

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
# copy copies input to the configured clipboard command when clipboard support is enabled.
copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY"; }

# open_url opens the specified URL using the macOS default application.

open_url() {
    open "$1"
}

# notify displays a macOS notification with the specified title and message.
notify() {
    local title="$1" msg="$2"
    osascript - "$title" "$msg" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT
}

# input_dialog displays a macOS text-input dialog and outputs the entered text.
input_dialog() {
    local title="$1" prompt="$2"
    osascript - "$title" "$prompt" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    set theText to text returned of (display dialog (item 2 of argv) default answer "" with title (item 1 of argv))
    return theText
end run
APPLESCRIPT
}

# info_dialog displays a macOS dialog with the specified title and message.
info_dialog() {
    local title="$1" msg="$2"
    osascript - "$title" "$msg" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    display dialog (item 2 of argv) with title (item 1 of argv) buttons {"OK"} default button "OK"
end run
APPLESCRIPT
}

# text_dialog displays a macOS dialog containing the specified title and message.
text_dialog() {
    local title="$1" body="$2"
    osascript - "$title" "$body" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    display dialog (item 2 of argv) with title (item 1 of argv) buttons {"OK"} default button "OK"
end run
APPLESCRIPT
}

# list_dialog displays a native macOS choice dialog and echoes the selected item.
list_dialog() {
    local title="$1" col="$2"
    shift 2

    if [[ "$(uname -s)" == "Darwin" && $# -eq 0 && ! -t 0 ]]; then
        local stdin_item
        while IFS= read -r stdin_item; do
            [[ -n "$stdin_item" ]] && set -- "$@" "$stdin_item"
        done
    fi

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
}

# ============= Screen / Windows =============
_SCREEN_DIMS_CACHED=""
# Detected dimensions are persisted with a long TTL: system_profiler is slow
# and xbar re-invokes this script constantly.
SCREEN_DIMS_TTL="${SCREEN_DIMS_TTL:-86400}"

# get_screen_dims determines the current screen dimensions from a valid cached value or system information, defaulting to 1366x768.
get_screen_dims() {
    if [[ -n "$_SCREEN_DIMS_CACHED" ]]; then
        echo "$_SCREEN_DIMS_CACHED"
        return
    fi

    mkdir -p "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
    local cache_file="${ARGOS_RUNTIME_DIR}/screen-dims"
    local cached_line="" cached_ts="" cached_dims="" now
    if [[ -r "$cache_file" ]]; then
        cached_line="$(cat "$cache_file" 2>/dev/null || true)"
        cached_ts="${cached_line%% *}"
        cached_dims="${cached_line#* }"
        if [[ "$cached_ts" =~ ^[0-9]+$ && "$cached_ts" != "$cached_line" && -n "$cached_dims" ]]; then
            now="$(date +%s)"
            if (( now - cached_ts < SCREEN_DIMS_TTL )); then
                _SCREEN_DIMS_CACHED="$cached_dims"
                echo "$_SCREEN_DIMS_CACHED"
                return
            fi
        fi
    fi

    local dims
    dims="$(system_profiler SPDisplaysDataType 2>/dev/null | awk '/Resolution/{print $2"x"$4; exit}')" || true
    _SCREEN_DIMS_CACHED="${dims:-1366x768}"
    printf '%s %s\n' "$(date +%s)" "$_SCREEN_DIMS_CACHED" > "$cache_file" 2>/dev/null || true
    echo "$_SCREEN_DIMS_CACHED"
}

# calc_window_size calculates window dimensions from the screen size, using 80% of the width and 70% of the height with minimum dimensions of 600 by 400 pixels.
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

# is_small_screen determines whether the display dimensions are at or below the compact-screen thresholds.
is_small_screen() {
    local dims w h
    dims="$(get_screen_dims)"
    w="${dims%x*}"; h="${dims#*x}"
    (( w <= 1368 || h <= 768 ))
}

# calc_max_argos_groups estimates the maximum number of groups that fit in the Argos menu based on the screen height.
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

# popup displays a titled text dialog with the provided message.
popup() {
    text_dialog "Dev Toolbox: $1" "$2"
}

# run_in_terminal <script_path> <action> [title]
# Opens Terminal running "<script_path> <action>". Both parts are passed
# through AppleScript `quoted form of`, so spaces or special characters in
# run_in_terminal opens a script with an action in a new macOS Terminal window and sets the window title.
run_in_terminal() {
    local script_path="$1" action="$2" title="${3:-Dev Toolbox}"
    osascript - "$script_path" "$action" "$title" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    tell application "Terminal"
        activate
        do script (quoted form of (item 1 of argv)) & " " & quoted form of (item 2 of argv)
        set custom title of front window to (item 3 of argv)
    end tell
end run
APPLESCRIPT
}

# run_in_terminal_cmd <command> [title]
# Variant for arbitrary shell commands; the command text is passed through
# run_in_terminal_cmd opens Terminal, executes a command, and sets the front window title.
run_in_terminal_cmd() {
    local cmd="$1" title="${2:-Dev Toolbox}"
    local rc=0
    osascript - "$cmd" "$title" <<'APPLESCRIPT' || rc=$?
on run argv
    tell application "Terminal"
        activate
        do script (item 1 of argv)
        set custom title of front window to (item 2 of argv)
    end tell
end run
APPLESCRIPT
    return $rc
}

# strip_leading_icon_if_same removes a matching leading icon and following space from a title.

strip_leading_icon_if_same() {
    local title="$1" icon="$2"
    [[ -z "$icon" ]] && { printf '%s' "$title"; return; }
    if [[ "$title" == "$icon "* ]]; then
        printf '%s' "${title#"$icon "}"
    else
        printf '%s' "$title"
    fi
}

# compose_label combines an optional icon with a title, avoiding duplicate leading icons.
compose_label() {
    local title="$1" icon="$2"
    if [[ -n "$icon" ]]; then
        local t; t="$(strip_leading_icon_if_same "$title" "$icon")"
        printf '%s %s' "$icon" "$t"
    else
        printf '%s' "$title"
    fi
}

# b64enc encodes standard input as a single-line Base64 string.
b64enc() {
    base64 | tr -d '\n'
}

# b64dec decodes Base64-encoded input and writes the result to standard output.
b64dec() {
    base64 -D
}

# meta_val extracts the first matching metadata value for a key from the first 80 lines of a Markdown file.

meta_val() {
    local f="$1" key="$2"
    # perl strips the UTF-8 BOM (BSD sed cannot match the byte sequence);
    # `|| true` keeps a missing key from tripping set -e.
    perl -pe 's/^\xEF\xBB\xBF//' "$f" 2>/dev/null \
        | head -n 80 \
        | tr -d '\r' \
        | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
        | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//' \
        | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'/\1/" \
        || true
}

# index_cheats indexes Markdown cheatsheets into the cache with their file paths, metadata, and default values.
# Shared AWK program for both the primary and fallback branches.
# shellcheck disable=SC2016  # awk program uses single quotes intentionally
_INDEX_AWK='
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    function unquote(s,   dq, sq, n) {
        dq = sprintf("%c", 34); sq = sprintf("%c", 39); n = length(s)
        if (n >= 2 && substr(s,1,1) == dq && substr(s,n,1) == dq)
            return substr(s, 2, n - 2)
        if (n >= 2 && substr(s,1,1) == sq && substr(s,n,1) == sq)
            return substr(s, 2, n - 2)
        return s
    }
    function field(line,   v) {
        v = substr(line, index(line, ":") + 1)
        v = unquote(trim(v))
        sub(/\r$/, "", v)
        return v
    }
    function emit(   n, parts, base) {
        n = split(fn, parts, "/")
        base = parts[n]
        sub(/\.md$/, "", base)
        if (title == "") title = base
        if (group == "") group = "Misc"
        if (order == "") order = "9999"
        printf "%s\t%s\t%s\t%s\t%s\n", fn, title, group, icon, order
    }
    FNR == 1 {
        if (fn != "") emit()
        fn = FILENAME
        title = ""; group = ""; icon = ""; order = ""
        checked = 0
        # Strip UTF-8 BOM (octal EF BB BF) from the very first line.
        if (substr($0, 1, 1) == "\357") $0 = substr($0, 4)
    }
    FNR <= 80 && checked < 4 {
        line = $0
        sub(/\r$/, "", line)
        if (title == "" && line ~ /^[[:space:]]*[Tt][Ii][Tt][Ll][Ee][[:space:]]*:/) { title = field(line); checked++ }
        else if (group == "" && line ~ /^[[:space:]]*[Gg][Rr][Oo][Uu][Pp][[:space:]]*:/) { group = field(line); checked++ }
        else if (icon == "" && line ~ /^[[:space:]]*[Ii][Cc][Oo][Nn][[:space:]]*:/) { icon = field(line); checked++ }
        else if (order == "" && line ~ /^[[:space:]]*[Oo][Rr][Dd][Ee][Rr][[:space:]]*:/) { order = field(line); checked++ }
    }
    END { if (fn != "") emit() }
'

# index_cheats rebuilds the cheatsheet index cache from Markdown files in `$CHEATS_DIR`, preserving the existing cache if indexing fails.
index_cheats() {
    mkdir -p "$(dirname "$CHEATS_CACHE")"
    local tmp_cache
    tmp_cache="$(mktemp "${CHEATS_CACHE}.XXXXXX")"
    [[ -d "$CHEATS_DIR" ]] || { mv -f "$tmp_cache" "$CHEATS_CACHE"; return 0; }

    # Single awk pass over every cheatsheet (BSD-awk compatible: no gensub,
    # no gawk-only extensions). This replaced a per-file, per-field pipeline
    # that spawned thousands of subprocesses and could not finish inside
    # xbar's refresh window, leaving an empty cache behind.
    # NUL-delimited pipeline preserves filenames with spaces or special chars.
    local _idx_rc=0
    if find -L "$CHEATS_DIR" -type f -name '*.md' -print0 2>/dev/null | sort -zf > /dev/null 2>&1; then
        find -L "$CHEATS_DIR" -type f -name '*.md' -print0 | sort -zf | xargs -0 awk "$_INDEX_AWK" > "$tmp_cache" || _idx_rc=$?
    else
        # Fallback: BSD sort may lack -z; use find -exec which passes
        # filenames safely without shell splitting. Filenames are rendered
        # sorted at display time anyway.
        find -L "$CHEATS_DIR" -type f -name '*.md' -exec awk "$_INDEX_AWK" {} + > "$tmp_cache" 2>/dev/null || _idx_rc=$?
    fi

    # Replace the cache on a successful rebuild (even if empty — no files is a
    # valid result).  Preserve the old cache only when indexing itself failed.
    if (( _idx_rc == 0 )); then
        chmod 0600 "$tmp_cache" 2>/dev/null || true
        mv -f "$tmp_cache" "$CHEATS_CACHE"
    else
        rm -f "$tmp_cache"
    fi
}

_CACHE_CHECKED=0

# ensure_cache ensures the cheatsheet index cache exists and is refreshed when requested, missing, or older than the source Markdown files.
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

# strip_front_matter removes recognized metadata fields from the first 80 lines of input and outputs the remaining content without carriage returns.
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

# get_layout returns the configured menu layout, defaulting to standard.

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

# setLayout validates and saves the selected menu layout, then clears the active category state.
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

# get_toc_format reads and outputs the configured table-of-contents format, defaulting to obsidian.
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

CHEAT_VIEWERS_DEFAULT="default code codium cursor windsurf zed subl warp antigravity obsidian joplin macdown typora bear iawriter ulysses textmate textedit"

# get_cheat_viewer outputs the configured cheatsheet viewer list, using the default list when no configuration is available.
get_cheat_viewer() {
    if [[ -n "${CHEAT_VIEWERS:-}" ]]; then
        echo "$CHEAT_VIEWERS"; return
    fi
    if [[ -s "$DEVTOOLBOX_VIEWER_CONF" ]]; then
        local val
        val="$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' < "$DEVTOOLBOX_VIEWER_CONF")"
        [[ -n "$val" ]] && { echo "$val"; return; }
    fi
    echo "$CHEAT_VIEWERS_DEFAULT"
}

# setCheatViewer saves the selected viewer list to the viewer configuration file.
setCheatViewer() {
    local viewer="${1:-}"
    [[ -z "$viewer" ]] && viewer="$CHEAT_VIEWERS_DEFAULT"
    mkdir -p "$(dirname "$DEVTOOLBOX_VIEWER_CONF")"
    printf '%s\n' "$viewer" > "$DEVTOOLBOX_VIEWER_CONF"
}

# All known macOS viewers with display names (order = preference).
# For GUI apps, the id is the .app bundle name (without .app).
declare -a VIEWER_LIST=(
    "default:System Default (open)"
    "code:VS Code"
    "codium:VSCodium"
    "cursor:Cursor"
    "windsurf:Windsurf"
    "zed:Zed"
    "subl:Sublime Text"
    "warp:Warp"
    "antigravity:Antigravity IDE"
    "obsidian:Obsidian"
    "joplin:Joplin"
    "macdown:MacDown"
    "typora:Typora"
    "bear:Bear"
    "iawriter:iA Writer"
    "ulysses:Ulysses"
    "textmate:TextMate"
    "textedit:TextEdit"
    "nano:Nano"
    "vim:Vim"
    "nvim:Neovim"
    "helix:Helix"
    "emacs:Emacs"
    "less:Less (pager)"
    "cat:Cat (terminal)"
)

# detect_installed_viewers checks which viewers are available on macOS.
# For CLI tools: checks command -v. For GUI apps: checks /Applications/ and ~/Applications/.
# detect_installed_viewers lists configured viewers with their installation status as pipe-delimited records. Each record contains the viewer ID, display name, and `1` if installed or `0` otherwise.
detect_installed_viewers() {
    local id name installed
    for entry in "${VIEWER_LIST[@]}"; do
        id="${entry%%:*}"
        name="${entry#*:}"
        installed=0
        case "$id" in
            default)
                # open is always available on macOS
                command -v open >/dev/null 2>&1 && installed=1
                ;;
            cat|less|nano|vim|nvim|emacs)
                command -v "$id" >/dev/null 2>&1 && installed=1
                ;;
            *)
                # Check CLI first
                if command -v "$id" >/dev/null 2>&1; then
                    installed=1
                else
                    # Map viewer IDs to their actual macOS .app bundle names
                    local app_bundle
                    case "$id" in
                        code)       app_bundle="Visual Studio Code.app" ;;
                        codium)     app_bundle="VSCodium.app" ;;
                        subl)       app_bundle="Sublime Text.app" ;;
                        iawriter)   app_bundle="iA Writer.app" ;;
                        textedit)   app_bundle="TextEdit.app" ;;
                        *)          app_bundle="${id}.app" ;;
                    esac
                    if [[ -d "/Applications/${app_bundle}" ]] || [[ -d "${HOME}/Applications/${app_bundle}" ]]; then
                        installed=1
                    fi
                fi
                ;;
        esac
        printf '%s|%s|%d\n' "$id" "$name" "$installed"
    done
}

# setTocFormat saves the selected table-of-contents format, defaulting to Obsidian for unsupported values.
setTocFormat() {
    local format="${1:-obsidian}"
    case "$format" in
        obsidian|github) ;;
        *) format="obsidian" ;;
    esac
    mkdir -p "$(dirname "$DEVTOOLBOX_TOC_FORMAT_CONF")"
    printf '%s\n' "$format" > "$DEVTOOLBOX_TOC_FORMAT_CONF"
}

# applyTocFormat applies the configured table-of-contents format to the cheatsheets.
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

# argos_set_category stores the selected category in the Argos drill-down state file.

argos_set_category() {
    mkdir -p "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
    chmod 0700 "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
    local tmp_state
    tmp_state="$(mktemp "${ARGOS_CAT_STATE}.XXXXXX")"
    printf '%s' "$1" > "$tmp_state"
    chmod 600 "$tmp_state" 2>/dev/null || true
    mv -f "$tmp_state" "$ARGOS_CAT_STATE" 2>/dev/null || true
}

# argos_clear_category removes the stored Argos category selection.
argos_clear_category() {
    rm -f "$ARGOS_CAT_STATE"
}

# argos_get_category returns the selected category when its state is present and within the configured TTL.
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

# argos_category_lines renders cached menu entries for a cheatsheet category and emits actions that open each selected cheatsheet.
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

    while IFS=$'\t' read -r file title group icon _order; do
        local label enc line
        label="$(compose_label "$title" "$icon")"
        enc="$(printf '%s' "$file" | b64enc)"
        line="$label | bash='$SCRIPT_PATH' param1=showCheat param2='$enc' terminal=false refresh=true"
        printf '%s\n' "$line" >> "$tmp_cache"
        printf '%s\n' "$line"
    done < <(awk -F'\t' -v gg="$grp" '$3==gg{printf "%s\t%s\t%s\t%s\t%05d\n",$1,$2,$3,$4,$5}' "$CHEATS_CACHE" \
             | LC_ALL=C sort -t$'\t' -k5,5n -k2,2f)

    chmod 0600 "$tmp_cache" 2>/dev/null || true
    if mv -f "$tmp_cache" "$cat_cache"; then
        _ARGOS_TMP_CACHE=""
    fi
}

# showCheat decodes a cheatsheet path, displays its content, copies it to the clipboard when configured, and opens it with the preferred available viewer.

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

    local CHEAT_VIEWERS
    CHEAT_VIEWERS="$(get_cheat_viewer)"
    for viewer in $CHEAT_VIEWERS; do
        case "$viewer" in
            default)
                # System default: open on macOS
                open "$file" 2>/dev/null && return 0
                ;;
            code)
                if command -v code >/dev/null 2>&1; then
                    if code --reuse-window "$file" 2>/dev/null; then
                        return 0
                    fi
                fi
                open -b com.microsoft.VSCode "$file" 2>/dev/null && return 0
                open -a "Visual Studio Code" "$file" 2>/dev/null && return 0
                ;;
            codium)
                if command -v codium >/dev/null 2>&1; then
                    codium --reuse-window "$file" 2>/dev/null && return 0
                fi
                open -b com.vscodium "$file" 2>/dev/null && return 0
                open -a "VSCodium" "$file" 2>/dev/null && return 0
                ;;
            cursor)
                if command -v cursor >/dev/null 2>&1; then
                    cursor --reuse-window "$file" 2>/dev/null && return 0
                fi
                open -a "Cursor" "$file" 2>/dev/null && return 0
                ;;
            windsurf)
                if command -v windsurf >/dev/null 2>&1; then
                    windsurf --reuse-window "$file" 2>/dev/null && return 0
                fi
                open -a "Windsurf" "$file" 2>/dev/null && return 0
                ;;
            zed)
                if command -v zed >/dev/null 2>&1; then
                    zed "$file" 2>/dev/null && return 0
                fi
                open -b dev.zed.Zed "$file" 2>/dev/null && return 0
                open -a "Zed" "$file" 2>/dev/null && return 0
                ;;
            subl)
                if command -v subl >/dev/null 2>&1; then
                    subl "$file" 2>/dev/null && return 0
                fi
                open -b com.sublimetext.4 "$file" 2>/dev/null && return 0
                open -b com.sublimetext.3 "$file" 2>/dev/null && return 0
                open -a "Sublime Text" "$file" 2>/dev/null && return 0
                ;;
            warp)
                if command -v warp >/dev/null 2>&1; then
                    warp "$file" 2>/dev/null && return 0
                fi
                open -a "Warp" "$file" 2>/dev/null && return 0
                ;;
            antigravity)
                if command -v antigravity >/dev/null 2>&1; then
                    antigravity "$file" 2>/dev/null && return 0
                fi
                open -a "Antigravity IDE" "$file" 2>/dev/null && return 0
                ;;
            obsidian)
                open -b md.obsidian "$file" 2>/dev/null && return 0
                open -a "Obsidian" "$file" 2>/dev/null && return 0
                ;;
            joplin)
                open -b net.cozic.joplin-desktop "$file" 2>/dev/null && return 0
                open -a "Joplin" "$file" 2>/dev/null && return 0
                ;;
            macdown)
                open -b com.uranusjr.macdown "$file" 2>/dev/null && return 0
                open -a "MacDown" "$file" 2>/dev/null && return 0
                ;;
            typora)
                open -b io.typora "$file" 2>/dev/null && return 0
                open -a "Typora" "$file" 2>/dev/null && return 0
                ;;
            bear)
                open -b net.shinyfrog.bear "$file" 2>/dev/null && return 0
                open -a "Bear" "$file" 2>/dev/null && return 0
                ;;
            iawriter)
                open -b pro.writer.mac "$file" 2>/dev/null && return 0
                open -a "iA Writer" "$file" 2>/dev/null && return 0
                ;;
            ulysses)
                open -b com.ulyssesapp.mac "$file" 2>/dev/null && return 0
                open -a "Ulysses" "$file" 2>/dev/null && return 0
                ;;
            textmate)
                if command -v mate >/dev/null 2>&1; then
                    mate "$file" 2>/dev/null && return 0
                fi
                open -b com.macromates.TextMate "$file" 2>/dev/null && return 0
                open -a "TextMate" "$file" 2>/dev/null && return 0
                ;;
            textedit)
                open -a TextEdit "$file" 2>/dev/null && return 0
                ;;
            cat|less|nano|vim|nvim|helix|emacs)
                # Terminal-based viewers: open in Terminal.app
                local escaped_file
                escaped_file="$(printf '%q' "$file")"
                run_in_terminal_cmd "$viewer $escaped_file" "$popup_title" && return 0
                ;;
            terminal)
                local escaped_file
                escaped_file="$(printf '%q' "$file")"
                run_in_terminal_cmd "cat $escaped_file" "$popup_title" && return 0
                ;;
            *)
                if command -v "$viewer" >/dev/null 2>&1; then
                    "$viewer" "$file" && return 0
                fi
                ;;
        esac
    done

    # Fallback: open in terminal if no viewer succeeded
    local escaped_file
    escaped_file="$(printf '%q' "$file")"
    run_in_terminal_cmd "cat $escaped_file" "$popup_title" 2>/dev/null || true
}

# searchCheatsFS searches indexed cheatsheets by title and opens the selected match.
searchCheatsFS() {
    ensure_cache
    local q; q=$(input_dialog "🔎 Search cheats" "Type to filter...") || exit 0
    [[ -z "$q" ]] && exit 0

    local list
    list="$(while IFS=$'\t' read -r file title group icon _order; do
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

# browseAllCheatsFS displays available cheatsheet categories and opens the selected category.
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

# browseDeep_Cheats displays the cheatsheets in a group, prompts for a selection, and opens the selected cheatsheet.
browseDeep_Cheats() {
    local target_group="$1"

    local list
    list="$(
        awk -F'\t' -v g="$target_group" '$3==g {print $0}' "$CHEATS_CACHE" \
        | LC_ALL=C sort -t$'\t' -k5,5n -k2,2f \
        | while IFS=$'\t' read -r file title group icon _order; do
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

# exportAllCheatsFS exports all indexed cheatsheets to a combined Markdown file and optionally converts it to PDF.
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
        while IFS=$'\t' read -r file title group icon _order; do
            [[ -z "$file" || ! -f "$file" ]] && continue
            echo "## $(compose_label "$title" "$icon")"
            echo ""
            strip_front_matter < "$file"
            echo ""
        done < <(LC_ALL=C sort -t$'\t' -k3,3f -k5,5n "$CHEATS_CACHE")
    } > "$out_md"

    local extra=""
    if command -v pandoc >/dev/null 2>&1; then
        if pandoc "$out_md" -o "$out_pdf" 2>/dev/null; then
            extra="\nPDF: $out_pdf"
        fi
    fi
    local msg
    printf -v msg '%b' "Saved:\n$out_md${extra}"
    info_dialog "📥 Export complete" "$msg"
}

# fzfSearch interactively searches Markdown cheatsheets and opens the selected match in an editor.
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

# showSettings displays the current Dev Toolbox version, platform, paths, layout, and TOC format configuration.
showSettings() {
    local layout; layout="$(get_layout)"
    local toc_fmt; toc_fmt="$(get_toc_format)"
    local viewer; viewer="$(get_cheat_viewer)"
    local detected_de="${DEVTOOLBOX_DE:-auto}"
    local msg
    printf -v msg '%b' "Version: $VERSION\nPlatform: macOS\n\nConfiguration:\nDEVTOOLBOX_DE=$detected_de\nCHEATS_DIR=$CHEATS_DIR\nCHEATS_CACHE=$CHEATS_CACHE\nLayout: $layout (standard|zenity|drilldown)\nLayout config: $DEVTOOLBOX_LAYOUT_CONF\nTOC Format: $toc_fmt (obsidian|github)\nViewer: $viewer"
    info_dialog "Dev Toolbox Settings" "$msg"
}

# settingsTocFormat lets the user select a table-of-contents format and applies the selection.
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

# settingsViewer lets the user select and save a preferred Markdown viewer, including a custom viewer command.
settingsViewer() {
    local current; current="$(get_cheat_viewer)"

    # Build list with installed status
    local items=()
    local ids=()
    while IFS='|' read -r id name installed; do
        ids+=("$id")
        if [[ "$installed" -eq 1 ]]; then
            items+=("✅ $name ($id)")
        else
            items+=("❌ $name ($id) — not installed")
        fi
    done < <(detect_installed_viewers)

    items+=("── Custom ──")
    items+=("✏️ Custom viewer...")

    local choice
    choice=$(list_dialog "👁️ Viewer  [current: ${current%% *}]$( [[ "$current" == *"default"* ]] && echo ' (system default)' || echo " ($current)" )" "Select preferred viewer" \
        "${items[@]}") || return 0

    case "$choice" in
        "✏️ Custom viewer...")
            local input
            input=$(input_dialog "Custom viewer" "Space-separated app names, e.g.: code cursor default") || return 0
            [[ -z "$input" ]] && return 0
            setCheatViewer "$input"
            ;;
        "── Custom ──")
            return 0
            ;;
        *)
            # Extract id from "✅ Name (id)" or "❌ Name (id) — not installed"
            local selected_id
            selected_id="$(printf '%s' "$choice" | sed 's/.*(\(.*\)).*/\1/')"
            [[ -n "$selected_id" ]] && setCheatViewer "$selected_id"
            ;;
    esac

    # Refresh runtime variable so the new choice takes effect immediately
    CHEAT_VIEWERS="$(get_cheat_viewer)"
}

# compactMenu displays a native macOS menu for searching, browsing, exporting, configuring, and selecting cheatsheet categories.
compactMenu() {
    ensure_cache

    local cat_items=()
    while IFS= read -r g; do
        [[ -z "$g" ]] && continue
        local gi="${GROUP_ICON[$g]:-🧩}"
        cat_items+=("$gi $g")
    done < <(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)

    local -a dialog_args=(
        "🔎 Search cheats"
        "🚀 FZF Search Commands"
        "📚 Browse all cheats"
        "📥 Export all (MD/PDF)"
        "🌐 Online Version"
        "🐙 GitHub Repository"
        "⚙️ Settings"
        "📝 TOC Format"
        "👁️ Viewer"
        "── Categories ──"
    )
    # Bash < 4.4 trips set -u when expanding an empty array; only append
    # category entries when they exist.
    if (( ${#cat_items[@]} > 0 )); then
        dialog_args+=("${cat_items[@]}")
    fi

    local choice
    choice=$(list_dialog "Dev Toolbox (Compact)" "Action" \
        "${dialog_args[@]}") || exit 0
    case "$choice" in
        "🔎 Search cheats") searchCheatsFS ;;
        "🚀 FZF Search Commands")
            run_in_terminal "$SCRIPT_PATH" fzfSearch "FZF Search"
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
        "👁️ Viewer")
            settingsViewer
            compactMenu
            ;;
        "── Categories ──") compactMenu ;;
        *)
            local group_name="${choice#* }"
            browseDeep_Cheats "$group_name"
            ;;
    esac
}

# standaloneMenu displays the standalone Dev Toolbox menu and dispatches the selected action.
standaloneMenu() {
    ensure_cache

    local cat_items=()
    while IFS= read -r g; do
        [[ -z "$g" ]] && continue
        local gi="${GROUP_ICON[$g]:-🧩}"
        cat_items+=("$gi $g")
    done < <(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)

    local -a dialog_args=(
        "🔎 Search cheats"
        "🚀 FZF Search Commands"
        "📚 Browse all cheats"
        "📥 Export all (MD/PDF)"
        "🌐 Online Version"
        "🐙 GitHub Repository"
        "⚙️ Settings"
        "📝 TOC Format"
        "👁️ Viewer"
        "── Categories ──"
    )
    # Bash < 4.4 trips set -u when expanding an empty array.
    if (( ${#cat_items[@]} > 0 )); then
        dialog_args+=("${cat_items[@]}")
    fi

    local choice
    choice=$(list_dialog "🗒️ Dev Toolbox" "Action" \
        "${dialog_args[@]}") || exit 0

    case "$choice" in
        "🔎 Search cheats") searchCheatsFS ;;
        "🚀 FZF Search Commands")
            if [[ -t 0 ]]; then
                fzfSearch
            else
                run_in_terminal "$SCRIPT_PATH" fzfSearch "FZF Search"
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
        "👁️ Viewer")
            settingsViewer
            standaloneMenu
            ;;
        "── Categories ──") standaloneMenu ;;
        *)
            local group_name="${choice#* }"
            browseDeep_Cheats "$group_name"
            ;;
    esac
}

# _render_small_screen_header renders the compact Argos/xbar menu header with common actions and a link to browse all cheats.

_render_small_screen_header() {
    local layout="$1"
    _render_functions_submenu "$layout"
    echo "📚 Browse all cheats    | bash='$SCRIPT_PATH' param1=browseAllCheatsFS terminal=false"
    echo "---"
}

# _render_functions_submenu renders DevToolbox actions, layout options, TOC formats, and viewer settings for the selected layout.
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

    local viewer
    viewer="$(get_cheat_viewer)"
    echo "-- Viewer (${viewer%% *})"
    echo "-- -- ⚙️ Change viewer...   | bash='$SCRIPT_PATH' param1=settingsViewer terminal=false refresh=true"
    echo "---"
}

# render_argos_standard renders the standard cheatsheet menu with grouped entries on larger screens and a compact header on smaller screens.
render_argos_standard() {
    local layout="$1"
    echo "🗒️ Cheats"
    echo "---"

    if is_small_screen; then
        _render_small_screen_header "$layout"
    else
        _render_functions_submenu "$layout"
        mapfile -t groups < <(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
        # Bash < 4.4 trips set -u when expanding an empty array.
        if (( ${#groups[@]} > 0 )); then
            for g in "${groups[@]}"; do
                [[ -z "$g" ]] && continue
                gi="${GROUP_ICON[$g]:-🧩}"
                echo "$gi $g"
                while IFS=$'\t' read -r file title group icon _order; do
                    [[ "$group" != "$g" ]] && continue
                    label="$(compose_label "$title" "$icon")"
                    enc="$(printf '%s' "$file" | b64enc)"
                    echo "-- $label | bash='$SCRIPT_PATH' param1=showCheat param2='$enc' terminal=false"
                done < <(awk -F'\t' -v gg="$g" '$3==gg{printf "%s\t%s\t%s\t%s\t%05d\n",$1,$2,$3,$4,$5}' "$CHEATS_CACHE" \
                         | LC_ALL=C sort -t$'\t' -k5,5n -k2,2f \
                         | awk -F'\t' '{printf "%s\t%s\t%s\t%s\t%s\n",$1,$2,$3,$4,$5}')
            done
        fi
    fi
}

# render_argos_zenity renders the Zenity-style Argos menu with actions and cheatsheet groups.
render_argos_zenity() {
    local layout="$1"
    echo "🗒️ Cheats"
    echo "---"

    if is_small_screen; then
        _render_small_screen_header "$layout"
    else
        _render_functions_submenu "$layout"
        mapfile -t groups < <(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
        # Bash < 4.4 trips set -u when expanding an empty array.
        if (( ${#groups[@]} > 0 )); then
            for g in "${groups[@]}"; do
                [[ -z "$g" ]] && continue
                gi="${GROUP_ICON[$g]:-🧩}"
                enc_g="$(printf '%s' "$g" | b64enc)"
                echo "$gi $g | bash='$SCRIPT_PATH' param1=browseDeep_Cheats param2='$enc_g' terminal=false"
            done
        fi
    fi
}

# render_argos_drilldown renders the Argos drill-down menu for the selected category or lists available categories.
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
        echo "🗒️ Cheats"
        echo "---"

        if is_small_screen; then
            _render_small_screen_header "$layout"
        else
            _render_functions_submenu "$layout"
            mapfile -t groups < <(awk -F'\t' '{print $3}' "$CHEATS_CACHE" | sed '/^$/d' | sort -fu)
            # Bash < 4.4 trips set -u when expanding an empty array.
            if (( ${#groups[@]} > 0 )); then
                for g in "${groups[@]}"; do
                    [[ -z "$g" ]] && continue
                    gi="${GROUP_ICON[$g]:-🧩}"
                    enc_g="$(printf '%s' "$g" | b64enc)"
                    echo "$gi $g | bash='$SCRIPT_PATH' param1=setCategory param2='$enc_g' terminal=false refresh=true"
                done
            fi
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
    setCheatViewer)
        setCheatViewer "${2:-}"
        exit 0
        ;;
    settingsViewer)
        settingsViewer
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
