#!/usr/bin/env bash
# macOS-beta/debug-sysinfo.sh — Diagnostic system info collector for DevToolbox Cheats
# Gathers all paths, tools, env vars, and state relevant to debugging.
# Read-only: never modifies any files or system state.
#
# Usage:
#   bash macOS-beta/debug-sysinfo.sh            # full report to stdout
#   bash macOS-beta/debug-sysinfo.sh > report.txt  # save to file
#   bash macOS-beta/debug-sysinfo.sh --compact   # essential checks only

set -u

# ============= PATH Augmentation =============
# SSH sessions and cron have minimal PATH. Add common macOS tool dirs.
__mac_paths=(
    /opt/homebrew/bin   # Homebrew Apple Silicon
    /usr/local/bin      # Homebrew Intel / general
    /opt/local/bin      # MacPorts
    "$HOME/.local/bin"  # DevToolbox CLI tools
    /usr/local/opt/coreutils/libexec/gnubin  # GNU coreutils
)
for __p in "${__mac_paths[@]}"; do
    [[ -d "$__p" && ":$PATH:" != *":$__p:"* ]] && PATH="$__p:$PATH"
done
unset __p __mac_paths

# ============= Config =============
COMPACT=0
if [[ "${1:-}" == "--compact" ]]; then
    COMPACT=1
fi

# ============= Colors =============
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_BLUE=$'\033[0;34m' C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD="" C_DIM=""
fi

# _ok prints an `[OK]` status message.
_ok()   { printf "  ${C_GREEN}[OK]${C_RESET}   %s\n" "$*"; }
# _warn reports a warning message with warning formatting.
_warn() { printf "  ${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"; }
# _fail reports a failed diagnostic check.
_fail() { printf "  ${C_RED}[FAIL]${C_RESET}  %s\n" "$*"; }
# _info prints an informational message with an `[INFO]` status label.
_info() { printf "  ${C_BLUE}[INFO]${C_RESET} %s\n" "$*"; }
# _section prints a bold section heading surrounded by a blank line.
_section() { echo ""; printf "${C_BOLD}=== %s ===${C_RESET}\n" "$*"; }
# _subsection prints a cyan subsection heading with the provided text.
_subsection() { printf "  ${C_CYAN}--- %s ---${C_RESET}\n" "$*"; }

# check_cmd reports whether a command is available and displays its version or path.
check_cmd() {
    local cmd="$1" label="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        local ver=""
        case "$cmd" in
            bash)     ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            python3)  ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            git)      ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            fzf)      ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            jq)       ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            bat)      ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            pandoc)   ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            brew)     ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            port)     ver="$($cmd version 2>/dev/null | head -n1)" ;;
            curl)     ver="$($cmd --version 2>/dev/null | head -n1)" ;;
            openssl)  ver="$($cmd version 2>/dev/null | head -n1)" ;;
            *)        ver="found at $(command -v "$cmd")" ;;
        esac
        _ok "$label: $ver"
        return 0
    else
        _fail "$label: not found"
        return 1
    fi
}

# check_env reports the value of an environment variable, or its unset state and optional default.
check_env() {
    local var="$1" default="${2:-}"
    local val="${!var:-}"
    if [[ -n "$val" ]]; then
        _info "$var=$val"
    elif [[ -n "$default" ]]; then
        _info "$var=(unset, default: $default)"
    else
        _info "$var=(unset)"
    fi
}

# ============= Report Start =============
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     DevToolbox Cheats — macOS Debug System Info             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
printf "Generated: %s\n" "$(date)"
printf "Hostname:  %s\n" "$(hostname -f 2>/dev/null || hostname)"
printf "User:      %s\n" "$(whoami)"

# ============= 1. macOS System =============
_section "macOS System"

if [[ "$(uname -s)" == "Darwin" ]]; then
    _ok "Running on macOS"
else
    _fail "NOT running on macOS (uname -s=$(uname -s))"
fi

if command -v sw_vers >/dev/null 2>&1; then
    _info "Product:    $(sw_vers -productName 2>/dev/null)"
    _info "Version:    $(sw_vers -productVersion 2>/dev/null)"
    _info "Build:      $(sw_vers -buildVersion 2>/dev/null)"
else
    _warn "sw_vers not found"
fi

_info "Architecture: $(uname -m)"
_info "Kernel:       $(uname -r)"
_info "Uptime:       $(uptime 2>/dev/null | sed 's/.*up //' | sed 's/,.*//' || echo '?')"

# ============= 2. Shell Environment =============
_section "Shell Environment"

_info "Default shell: ${SHELL:-?}"
_info "Current shell: $(ps -p $$ -o comm= 2>/dev/null || echo '?')"

_subsection "Bash Versions"
for bash_path in /bin/bash /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash; do
    if [[ -x "$bash_path" ]]; then
        local_ver="$("$bash_path" --version 2>/dev/null | head -n1)"
        _ok "$bash_path: $local_ver"
    fi
done

active_bash="$(command -v bash 2>/dev/null || echo '?')"
active_ver_num=""
if [[ "$active_bash" != "?" ]]; then
    # shellcheck disable=SC2016  # intentionally single-quoted for subshell
    active_ver_num="$("$active_bash" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null)"
fi
active_ver="$("$active_bash" --version 2>/dev/null | head -n1)"
_info "Active bash: $active_bash ($active_ver)"

if [[ "${active_ver_num:-0}" -ge 4 ]]; then
    _ok "Detected bash satisfies >=4 requirement"
else
    _fail "Detected bash is <4 (install bash 4+ via brew/port)"
fi

# ============= 3. Package Managers =============
_section "Package Managers"

has_pkg_mgr=0
if command -v brew >/dev/null 2>&1; then
    _ok "Homebrew: $(brew --version 2>/dev/null | head -n1)"
    _info "  Prefix: $(brew --prefix 2>/dev/null)"
    _info "  Cellar: $(brew --cellar 2>/dev/null)"
    has_pkg_mgr=1
else
    _warn "Homebrew: not found"
fi

if command -v port >/dev/null 2>&1; then
    _ok "MacPorts: $(port version 2>/dev/null | head -n1)"
    _info "  Prefix: /opt/local"
    has_pkg_mgr=1
else
    _warn "MacPorts: not found"
fi

if [[ "$has_pkg_mgr" -eq 0 ]]; then
    _fail "No package manager found (Homebrew or MacPorts required)"
fi

# ============= 4. Required Tools =============
_section "Required Tools"

check_cmd bash "Bash"
check_cmd python3 "python3"
check_cmd git "git"

_subsection "System Commands (install.sh pre-flight)"
for sys_cmd in find cp cmp sed sort perl; do
    check_cmd "$sys_cmd"
done

# ============= 5. Optional Tools =============
_section "Optional Tools"

check_cmd fzf "fzf (fuzzy finder)" || true
check_cmd jq "jq (JSON processor)" || true
check_cmd bat "bat (syntax highlighting)" || true
check_cmd pandoc "pandoc (Markdown converter)" || true

if command -v grealpath >/dev/null 2>&1; then
    _ok "grealpath (coreutils): $(command -v grealpath)"
elif command -v realpath >/dev/null 2>&1; then
    _ok "realpath: $(command -v realpath)"
else
    _warn "No realpath/grealpath found (python3 fallback will be used)"
fi

# ============= 6. macOS-Specific Tools =============
_section "macOS-Specific Tools"

check_cmd osascript "osascript (AppleScript)"
check_cmd pbcopy "pbcopy (clipboard write)"
check_cmd pbpaste "pbpaste (clipboard read)"
check_cmd open "open (URL/file opener)"
check_cmd shasum "shasum (hashing)"
check_cmd md5 "md5 (hashing)"
check_cmd uuidgen "uuidgen (UUID generator)"
check_cmd openssl "openssl"

_subsection "Network Tools"
check_cmd curl "curl" || true
check_cmd nc "nc (netcat)" || true

if command -v ifconfig >/dev/null 2>&1; then
    _ok "ifconfig: $(command -v ifconfig)"
else
    _warn "ifconfig: not found"
fi

if command -v ipconfig >/dev/null 2>&1; then
    _ok "ipconfig: $(command -v ipconfig)"
else
    _warn "ipconfig: not found (needed for getIP)"
fi

_subsection "Editors"
check_cmd code "VS Code (code)" || true
check_cmd nano "nano" || true
check_cmd vim "vim" || true
if [[ -d "/Applications/TextEdit.app" ]]; then
    _ok "TextEdit.app: /Applications/TextEdit.app"
else
    _warn "TextEdit.app: not found"
fi

# ============= 7. xbar =============
_section "xbar"

XBAR_PLUGINS_DIR="$HOME/Library/Application Support/xbar/plugins"

if [[ -d "/Applications/xbar.app" ]]; then
    _ok "xbar.app installed: /Applications/xbar.app"
elif [[ -d "$HOME/Applications/xbar.app" ]]; then
    _ok "xbar.app installed: ~/Applications/xbar.app"
else
    _fail "xbar.app not found in /Applications or ~/Applications"
fi

if pgrep -x xbar >/dev/null 2>&1; then
    _ok "xbar is running (PID: $(pgrep -x xbar | head -n1))"
else
    _warn "xbar is NOT running"
fi

if [[ -d "$XBAR_PLUGINS_DIR" ]]; then
    _ok "xbar plugins dir: $XBAR_PLUGINS_DIR"
    local_count=$(find "$XBAR_PLUGINS_DIR" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
    link_count=$(find "$XBAR_PLUGINS_DIR" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
    _info "  Files: $local_count .sh files, $link_count symlinks"

    for plugin in devtoolbox-cheats.30s.sh devtools.1m.sh; do
        p="$XBAR_PLUGINS_DIR/$plugin"
        if [[ -L "$p" ]]; then
            target="$(readlink "$p" 2>/dev/null || echo '?')"
            if [[ -f "$p" ]]; then
                _ok "  $plugin -> $target"
            else
                _fail "  $plugin -> $target (BROKEN — target missing)"
            fi
        elif [[ -f "$p" ]]; then
            _warn "  $plugin: regular file (expected symlink)"
        else
            _fail "  $plugin: missing"
        fi
    done
else
    _fail "xbar plugins dir: $XBAR_PLUGINS_DIR (not found)"
fi

# ============= 8. DevToolbox Paths =============
_section "DevToolbox Paths"

CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
if [[ -d "$CHEATS_DIR" ]]; then
    cheat_count=$(find "$CHEATS_DIR" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    _ok "Cheats dir: $CHEATS_DIR ($cheat_count .md files)"
    if [[ "$cheat_count" -eq 0 ]]; then
        _warn "  No cheatsheets found — menu will be empty"
    fi
else
    _fail "Cheats dir: $CHEATS_DIR (not found)"
fi

CHEATS_CACHE="${CHEATS_CACHE:-$HOME/.cache/devtoolbox-cheats-combined.idx}"
if [[ -f "$CHEATS_CACHE" ]]; then
    cache_size=$(wc -c < "$CHEATS_CACHE" 2>/dev/null | tr -d ' ')
    cache_mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$CHEATS_CACHE" 2>/dev/null || echo '?')
    cache_lines=$(wc -l < "$CHEATS_CACHE" 2>/dev/null | tr -d ' ')
    _ok "Cache index: $CHEATS_CACHE ($cache_lines entries, $cache_size bytes, modified $cache_mtime)"
    if [[ "$cache_lines" -eq 0 ]]; then
        _warn "  Cache is empty — will rebuild on next run"
    fi
else
    _warn "Cache index: $CHEATS_CACHE (not found, will be created on first run)"
fi

RUNTIME_DIR="$HOME/.cache/devtoolbox-cheats/run"
if [[ -d "$RUNTIME_DIR" ]]; then
    _ok "Runtime dir: $RUNTIME_DIR"
    STATE_FILE="$RUNTIME_DIR/argos-cat-combined.state"
    if [[ -f "$STATE_FILE" ]]; then
        state_age=$(($(date +%s) - $(stat -f '%m' "$STATE_FILE" 2>/dev/null || echo 0)))
        _info "  Category state: active (age: ${state_age}s, TTL: 60s)"
    else
        _info "  Category state: none (main menu)"
    fi
    DIMS_FILE="$RUNTIME_DIR/screen-dims"
    if [[ -f "$DIMS_FILE" ]]; then
        dims_content=$(cat "$DIMS_FILE" 2>/dev/null | head -n1)
        _info "  Screen dims cache: $dims_content"
    else
        _info "  Screen dims cache: not cached"
    fi
else
    _info "Runtime dir: $RUNTIME_DIR (not found, will be created)"
fi

ARGOS_CACHE_DIR="$HOME/.cache/devtoolbox-cheats-argos-combined"
if [[ -d "$ARGOS_CACHE_DIR" ]]; then
    argos_files=$(find "$ARGOS_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    _ok "Argos cache: $ARGOS_CACHE_DIR ($argos_files files)"
else
    _info "Argos cache: $ARGOS_CACHE_DIR (not found, will be created)"
fi

LOCAL_BIN="$HOME/.local/bin"
_subsection "CLI Tools ($LOCAL_BIN)"
for cli in cheats-updater generate-tldr; do
    p="$LOCAL_BIN/$cli"
    if [[ -x "$p" ]]; then
        _ok "$cli: $p"
    elif [[ -f "$p" ]]; then
        _warn "$cli: $p (exists but not executable)"
    else
        _fail "$cli: $p (not found)"
    fi
done

TOOLS_DIR="$HOME/.local/share/devtoolbox-cheats"
if [[ -d "$TOOLS_DIR" ]]; then
    _ok "Tools dir: $TOOLS_DIR"
    if [[ -f "$TOOLS_DIR/tools/manage-tocs.py" ]]; then
        _ok "  manage-tocs.py: found"
    else
        _warn "  manage-tocs.py: not found (TOC formatting unavailable)"
    fi
    BACKUP_DIR="$TOOLS_DIR/backups"
    if [[ -d "$BACKUP_DIR" ]]; then
        backup_count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        _info "  Backups: $backup_count backup(s)"
    fi
else
    _warn "Tools dir: $TOOLS_DIR (not found)"
fi

CONFIG_DIR="$HOME/.config/devtoolbox-cheats"
_subsection "Configuration ($CONFIG_DIR)"
if [[ -d "$CONFIG_DIR" ]]; then
    _ok "Config dir: $CONFIG_DIR"
    layout_file="$CONFIG_DIR/layout.conf"
    if [[ -s "$layout_file" ]]; then
        layout_val=$(tr -d '[:space:]' < "$layout_file")
        _info "  Layout: $layout_val"
    else
        _info "  Layout: default (standard)"
    fi
    toc_file="$CONFIG_DIR/toc_format.conf"
    if [[ -s "$toc_file" ]]; then
        toc_val=$(tr -d '[:space:]' < "$toc_file")
        _info "  TOC format: $toc_val"
    else
        _info "  TOC format: default (obsidian)"
    fi
else
    _warn "Config dir: $CONFIG_DIR (not found, will use defaults)"
fi

# ============= 9. Environment Variables =============
_section "Environment Variables"

check_env "CHEATS_DIR" "$HOME/cheats.d"
check_env "CHEATS_CACHE" "$HOME/.cache/devtoolbox-cheats-combined.idx"
check_env "CHEATS_REBUILD"
check_env "DEVTOOLBOX_DE"
check_env "DEVTOOLBOX_LAYOUT"
check_env "DEVTOOLBOX_TOC_FORMAT"
check_env "DEVTOOLBOX_PKG_MGR_PATH"
check_env "DEVTOOLBOX_MAC_HOST" "macos"
check_env "DEVTOOLBOX_MAC_DIR" "devtool"
check_env "SCREEN_DIMS_TTL" "86400"
check_env "ARGOS_CAT_TTL" "60"
check_env "CHEAT_VIEWERS" "code textedit default"
check_env "SOURCE_DIR" "$HOME/cheats.d"
check_env "OUTPUT_DIR" "$HOME/cheats.d-gen/tldr"
check_env "TLDR_CACHE_DIR" "$HOME/.cache/tldr/pages"
check_env "TLDR_PLATFORM_DIR" "common"
check_env "EDITOR" "nano"

# ============= 10. LaunchAgent =============
_section "LaunchAgent (Auto-Updater)"

PLIST_NAME="com.devtoolbox-cheats.updater"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

if [[ -f "$PLIST_PATH" ]]; then
    _ok "Plist exists: $PLIST_PATH"
    if command -v plutil >/dev/null 2>&1; then
        if plutil -lint "$PLIST_PATH" >/dev/null 2>&1; then
            _ok "  Plist syntax: valid"
        else
            _fail "  Plist syntax: INVALID"
        fi
    fi
    if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
        _ok "  LaunchAgent: loaded"
    else
        _warn "  LaunchAgent: NOT loaded"
    fi
else
    _warn "Plist: $PLIST_PATH (not found)"
fi

LOG_DIR="$HOME/Library/Logs/devtoolbox-cheats"
if [[ -d "$LOG_DIR" ]]; then
    log_count=$(find "$LOG_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    _ok "Updater logs: $LOG_DIR ($log_count files)"
    err_log="$LOG_DIR/${PLIST_NAME}.err.log"
    if [[ -s "$err_log" ]]; then
        _warn "  Last error log (last 5 lines):"
        tail -n5 "$err_log" 2>/dev/null | sed 's/^/    /'
    fi
else
    _info "Updater logs: $LOG_DIR (not found)"
fi

# ============= 11. PATH =============
_section "PATH"

_info "Current PATH:"
while IFS= read -r p; do
    if [[ -d "$p" ]]; then
        _ok "  $p"
    else
        _fail "  $p (missing)"
    fi
done < <(echo "$PATH" | tr ':' '\n')

for candidate in /opt/homebrew/bin /opt/local/bin /usr/local/bin "$HOME/.local/bin"; do
    if [[ -d "$candidate" ]]; then
        case ":$PATH:" in
            *":$candidate:"*) _info "$candidate: in PATH" ;;
            *)                _warn "$candidate: EXISTS but NOT in PATH" ;;
        esac
    else
        _info "$candidate: directory does not exist"
    fi
done

if [[ "$(uname -m)" == "arm64" ]] && [[ -d /opt/homebrew ]]; then
    _info "Apple Silicon Homebrew detected at /opt/homebrew"
fi

# ============= 12. Fonts =============
_section "Fonts"

if command -v fc-list >/dev/null 2>&1; then
    if fc-list 2>/dev/null | grep -qi "noto.*emoji"; then
        _ok "Noto Color Emoji font: installed"
    else
        _warn "Noto Color Emoji font: not found (emoji may not render)"
    fi
else
    _info "fc-list not found — cannot check fonts"
fi

# ============= 13. Clipboard Test =============
_section "Clipboard Test"

if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
    test_str="devtoolbox-debug-$$"
    if printf '%s' "$test_str" | pbcopy 2>/dev/null; then
        pasted="$(pbpaste 2>/dev/null)"
        if [[ "$pasted" == "$test_str" ]]; then
            _ok "Clipboard read/write: working"
        else
            _warn "Clipboard: wrote but read back differs (got: '$pasted')"
        fi
    else
        _fail "Clipboard: pbcopy failed"
    fi
else
    _fail "Clipboard: pbcopy/pbpaste not available"
fi

# ============= 14. osascript Test =============
_section "osascript Test"

if command -v osascript >/dev/null 2>&1; then
    if osascript -e 'return "ok"' 2>/dev/null | grep -q "ok"; then
        _ok "osascript: basic execution works"
    else
        _warn "osascript: returned unexpected result"
    fi
else
    _fail "osascript: not found"
fi

# ============= 15. Disk Space =============
_section "Disk Space"

if command -v df >/dev/null 2>&1; then
    df -h / 2>/dev/null | tail -n1 | while IFS= read -r line; do
        _info "  $line"
    done
fi

# ============= 16. Summary =============
_section "Summary"

{
    echo "Run complete. Review [FAIL] and [WARN] items above."
    echo ""
    echo "Quick actions:"
    echo "  Rebuild cache:    CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh"
    echo "  Manual update:    $HOME/.local/bin/cheats-updater update"
    echo "  Test dialogs:     bash macOS-beta/test-native-dialog.sh"
    echo "  Browse cheats:    bash macOS-beta/devtoolbox-cheats.30s.sh menu"
    echo "  Check for update: $HOME/.local/bin/cheats-updater check"
}
