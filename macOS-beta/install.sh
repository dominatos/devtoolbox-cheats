#!/usr/bin/env bash
# macOS-beta/install.sh — macOS installer for DevToolbox Cheats
# Installs DevToolbox Cheats on macOS with SwiftBar integration.
# xbar is supported internally via DEVTOOLBOX_APP_TARGET=1
set -euo pipefail

VERSION="v1.5.6"
# Works when invoked as `bash install.sh`, `./install.sh`, `zsh install.sh`,
# or via stdin piping (where BASH_SOURCE is unset and only $0 remains).
SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Standalone / curl execution detection ────────────────────────────────────
# If the script is run via `curl ... | bash` or downloaded independently,
# it won't have the adjacent repository files (e.g. cheats.d/).
# Clone the repo and re-execute from the clone rather than failing.
# Always clone on stdin piping (BASH_SOURCE empty) — SCRIPT_DIR resolves to
# the caller's working directory which may contain unrelated files.
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    echo "📦 Standalone execution detected (e.g. curl | bash)"

    if ! command -v git >/dev/null 2>&1; then
        echo "❌ git is required for remote installation. Please install git."
        exit 1
    fi

    REPO_URL="https://github.com/dominatos/devtoolbox-cheats.git"
    CLONE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-cheats-XXXXXX")"

    echo "🚀 Cloning repository to $CLONE_DIR..."
    if ! git clone --depth 1 -b macos-beta "$REPO_URL" "$CLONE_DIR"; then
        echo "❌ Failed to clone repository."
        rm -rf "$CLONE_DIR"
        exit 1
    fi

    echo "🔄 Starting installer from cloned repository..."
    cd "$CLONE_DIR/macOS-beta"

    bash ./install.sh
    EXIT_CODE=$?

    echo "🧹 Cleaning up temporary clone..."
    cd /
    rm -rf "$CLONE_DIR"
    exit $EXIT_CODE
fi

# Homebrew and MacPorts may be installed outside the non-interactive PATH.
# DEVTOOLBOX_PKG_MGR_PATH overrides this for tests/hermetic environments;
# when set it must not create a leading empty PATH component.
if [[ -n "${DEVTOOLBOX_PKG_MGR_PATH:-}" ]]; then
    # Strip one trailing slash for tidy paths, but never reduce "/" itself
    # to an empty (leading-colon) PATH entry.
    pkg_mgr_path="${DEVTOOLBOX_PKG_MGR_PATH%/}"
    [[ -z "$pkg_mgr_path" ]] && pkg_mgr_path="/"
    export PATH="${pkg_mgr_path}:$PATH"
else
    export PATH="/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:$PATH"
fi

# ============= Colors =============
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_BLUE=$'\033[0;34m' C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD="" C_DIM=""
fi

# log_info prints an informational message with a colored `[INFO]` prefix.
log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET} $*"; }
# log_warn prints a warning message with colored output.
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
# log_error prints an error message with error-level formatting.
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*"; }

# ============= Install log capture =============
# Everything the installer prints is mirrored into a temp log. On exit the
# user is asked once whether to keep it under macOS-beta/debug-output/.
INSTALL_LOG_TMP="$(mktemp "${TMPDIR:-/tmp}/devtoolbox-install-log.XXXXXX")"
exec > >(tee "$INSTALL_LOG_TMP") 2>&1

# save_install_log_prompt prompts to save the installation log, removes the temporary log, and preserves the current exit status.
save_install_log_prompt() {
    local rc=$?
    local dest_dir="$SCRIPT_DIR/debug-output"
    local answer=""
    [[ -n "${INSTALL_LOG_PROMPTED:-}" ]] && return 0
    INSTALL_LOG_PROMPTED=1
    echo ""
    # EOF / closed stdin counts as "no".
    printf "Save install log? [y/N]: "
    if ! read -r answer < /dev/tty 2>/dev/null; then
        read -r answer 2>/dev/null || answer=""
    fi
    if [[ "$answer" == [yY] ]]; then
        local dest_file="$dest_dir/install-$(date +%Y%m%d-%H%M%S).log"
        if mkdir -p "$dest_dir" && cp "$INSTALL_LOG_TMP" "$dest_file"; then
            log_info "Install log saved → $dest_file"
        else
            log_warn "Could not write $dest_dir — install log discarded."
        fi
    fi
    rm -f "$INSTALL_LOG_TMP" 2>/dev/null || true
    return $rc
}
trap save_install_log_prompt EXIT

# ============= Header =============
# print_header prints the DevToolbox Cheats installer header and version.
print_header() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     DevToolbox Cheats — macOS Installer                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo "($VERSION)"
    echo ""
}
print_header

# ============= Check macOS =============
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This installer is for macOS only."
    log_info "Use the root install.sh for Linux."
    exit 1
fi

# ============= Pre-flight: system commands =============
for sys_cmd in find cp cmp sed sort; do
    if ! command -v "$sys_cmd" >/dev/null 2>&1; then
        log_error "Required system command missing: $sys_cmd"
        exit 1
    fi
done

if command -v git >/dev/null 2>&1; then
    log_info "  ${C_DIM}git${C_RESET} — provided by $(command -v git)"
else
    log_error "git is required (cheats-updater uses it) but was not found."
    log_error "Install the Xcode Command Line Tools with:"
    log_error "  xcode-select --install"
    exit 1
fi

# ============= Package Manager Detection =============
PKG_MGR=""
HAS_BREW=false
HAS_PORT=false

# Check what's available
if command -v brew >/dev/null 2>&1; then
    HAS_BREW=true
fi
if command -v port >/dev/null 2>&1; then
    HAS_PORT=true
fi

# Ask user which to use
if [[ "$HAS_BREW" == true && "$HAS_PORT" == true ]]; then
    # Both available — ask user
    echo ""
    echo "  ${C_BOLD}Multiple package managers detected:${C_RESET}"
    echo "    1) Homebrew ($(brew --version 2>/dev/null | head -n1))"
    echo "    2) MacPorts ($(port version 2>/dev/null | head -n1))"
    echo ""
    # EOF / unavailable stdin must not abort via set -e; default to Homebrew.
    printf "  Which package manager to use? [1/2]: "
    if ! read -r choice < /dev/tty 2>/dev/null; then
        if ! read -r choice 2>/dev/null; then
            log_warn "No interactive input available — defaulting to Homebrew."
            choice=""
        fi
    fi
    case "$choice" in
        2) PKG_MGR="port" ;;
        *) PKG_MGR="brew" ;;
    esac
elif [[ "$HAS_BREW" == true ]]; then
    PKG_MGR="brew"
    log_info "Using Homebrew: $(brew --version | head -n1)"
elif [[ "$HAS_PORT" == true ]]; then
    PKG_MGR="port"
    log_info "Using MacPorts: $(port version | head -n1)"
else
    echo ""
    log_error "No package manager found (Homebrew or MacPorts required)."
    printf "  Would you like to install Homebrew now? [y/N]: "
    if ! read -r choice < /dev/tty 2>/dev/null; then
        if ! read -r choice 2>/dev/null; then
            choice=""
        fi
    fi
    if [[ "$choice" == [yY]* ]]; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Export PATH for the rest of the script
        if [[ "$(uname -m)" == "arm64" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        else
            export PATH="/usr/local/bin:$PATH"
        fi
        
        if command -v brew >/dev/null 2>&1; then
            PKG_MGR="brew"
            log_info "Homebrew installed successfully: $(brew --version | head -n1)"
        else
            log_error "Homebrew installation failed. brew command not found."
            exit 1
        fi
    else
        echo ""
        echo "  Install Homebrew manually:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "  Or install MacPorts:"
        echo "    https://www.macports.org/install.php"
        exit 1
    fi
fi

log_info "Selected package manager: ${C_CYAN}$PKG_MGR${C_RESET}"

# ============= Package Install Helper =============
# install_pkg verifies or installs a package through the selected package manager, warning on optional package failures and returning failure for required package failures.
install_pkg() {
    # Args: pkg [brew_name] [port_name] [optional]
    # Required dependencies return failure on install error; optional ones
    # (4th arg = "optional") only warn.
    local pkg="$1"
    local brew_name="${2:-$pkg}"
    local port_name="${3:-$pkg}"
    local optional="${4:-}"

    if [[ "$PKG_MGR" == "brew" ]]; then
        if brew list "$brew_name" >/dev/null 2>&1; then
            log_info "  ${C_DIM}$brew_name${C_RESET} — already installed"
        else
            log_info "  Installing ${C_CYAN}$brew_name${C_RESET} via Homebrew..."
            if ! brew install "$brew_name"; then
                log_warn "Failed to install $brew_name"
                [[ "$optional" == "optional" ]] || return 1
            fi
        fi
    elif [[ "$PKG_MGR" == "port" ]]; then
        # Match the actual port line ("  jq @1.7.1_0 (active)"); the command
        # also prints "...are installed." when the port is MISSING, so a bare
        # grep for "installed" gives false positives.
        if port installed "$port_name" 2>/dev/null | grep -Eq "[[:space:]]+${port_name}@|^[[:space:]]+${port_name}[[:space:]]+@"; then
            log_info "  ${C_DIM}$port_name${C_RESET} — already installed"
        else
            log_info "  Installing ${C_CYAN}$port_name${C_RESET} via MacPorts..."
            if ! sudo port install "$port_name"; then
                log_warn "Failed to install $port_name"
                [[ "$optional" == "optional" ]] || return 1
            fi
        fi
    fi
    return 0
}

# require_pkg installs a required dependency and aborts the installation if it cannot be installed.
require_pkg() {
    if ! install_pkg "$@"; then
        log_error "Required dependency '$1' could not be installed. Aborting installation."
        exit 1
    fi
}

# ============= Install Dependencies =============
log_info "Installing dependencies via $PKG_MGR..."
echo ""

# Required dependencies
# Format: "generic_name brew_name port_name"
# If brew_name and port_name are same as generic, can omit them
# ============= Dependency model =============
# Required:  bash 4+ (runtime), python3 (TOC tooling, URL decoding)
# Optional:  fzf (fuzzy search), jq (JSON/JWT tools), bat (previews),
#            pandoc (Markdown → HTML/PDF), coreutils (grealpath nicety)
echo ""
log_info "Dependency plan:"
echo "  ${C_BOLD}Required:${C_RESET}"
echo "    • bash 4+   — script runtime"
echo "    • python3   — TOC tooling, URL decoding"
echo "  ${C_BOLD}Optional:${C_RESET} (app degrades gracefully without them)"
echo "    • fzf       — interactive fuzzy finder"
echo "    • jq        — JSON/JWT utilities"
echo "    • bat       — syntax-highlighted previews"
echo "    • pandoc    — Markdown → HTML/PDF"
echo "    • coreutils — grealpath convenience"
echo ""

# --- Required ---
require_pkg "bash"

# Verify the resolved bash satisfies the runtime requirement.
# Probe PATH plus known package-manager directories so that a Homebrew/MacPorts
# bash is preferred over the (often older) system bash.
RESOLVED_BASH=""
# shellcheck disable=SC2016  # intentionally single-quoted for subshell
for bash_path in "$(command -v bash 2>/dev/null || true)" \
                 /opt/homebrew/bin/bash /opt/local/bin/bash \
                 /usr/local/bin/bash; do
    if [[ -n "$bash_path" && -x "$bash_path" ]] && \
       "$bash_path" -c '[[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]' 2>/dev/null; then
        RESOLVED_BASH="$bash_path"
        break
    fi
done
if [[ -z "$RESOLVED_BASH" ]]; then
    log_error "Bash 4+ not found. The system bash is too old."
    log_error "Ensure Homebrew/MacPorts bash is installed and precedes /bin in PATH."
    exit 1
fi

# python3: probe PATH plus known absolute locations; package managers use
# different prefixes and xbar/launchd environments may have a minimal PATH.
PYTHON3_FOUND=""
for py in "$(command -v python3 2>/dev/null || true)" \
          /usr/bin/python3 /usr/local/bin/python3 \
          /opt/homebrew/bin/python3 /opt/local/bin/python3; do
    if [[ -n "$py" && -x "$py" ]]; then PYTHON3_FOUND="$py"; break; fi
done
if [[ -n "$PYTHON3_FOUND" ]]; then
    log_info "  ${C_DIM}python3${C_RESET} — provided by $PYTHON3_FOUND"
elif [[ "$PKG_MGR" == "port" ]]; then
    log_info "  Installing ${C_CYAN}python3${C_RESET} via MacPorts..."
    if ! sudo port install python312; then
        log_error "Failed to install python312 via MacPorts."
        log_error "Install manually: sudo port install python312"
        exit 1
    fi
    # Verify the MacPorts python3 is callable after installation.
    PYTHON3_MPORT="/opt/local/bin/python3"
    if [[ ! -x "$PYTHON3_MPORT" ]]; then
        log_error "MacPorts python3 not found at $PYTHON3_MPORT after install."
        log_error "Ensure MacPorts /opt/local/bin is in your PATH."
        exit 1
    fi
    log_info "  ${C_DIM}python3${C_RESET} — provided by $PYTHON3_MPORT (MacPorts)"
else
    require_pkg "python3"
fi

# --- Optional (warn-only) ---
install_pkg "fzf" "fzf" "fzf" optional
install_pkg "jq" "jq" "jq" optional
install_pkg "bat" "bat" "bat" optional
install_pkg "pandoc" "pandoc" "pandoc" optional
install_pkg "coreutils" "coreutils" "coreutils" optional

# Optional: Noto Color Emoji font
echo ""
log_info "Checking for emoji font..."
if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi "noto.*emoji"; then
    log_info "  Noto Color Emoji font found"
elif [[ "$PKG_MGR" == "brew" ]]; then
    log_info "  Installing Noto Color Emoji font..."
    brew install --cask font-noto-color-emoji || log_warn "Failed to install emoji font (optional)"
else
    log_info "  Skipping emoji font (install manually via Homebrew cask if needed)"
fi

# ============= Deploy Cheatsheets =============
log_info ""
log_info "Deploying cheatsheets..."

CHEATS_SRC="$ROOT_DIR/cheats.d"
CHEATS_DEST="$HOME/cheats.d"

if [[ -d "$CHEATS_SRC" ]]; then
    # Back up an existing ~/cheats.d before overwriting (same convention as
    # cheats-updater.sh) so a re-run never silently replaces user content.
    if [[ -d "$CHEATS_DEST" ]]; then
        backup_dir="${HOME}/.local/share/devtoolbox-cheats/backups/$(date +%Y-%m-%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp -rp "$CHEATS_DEST/." "$backup_dir/"
        log_info "  Existing cheats backed up → ${C_DIM}$backup_dir${C_RESET}"
    fi
    mkdir -p "$CHEATS_DEST"
    cp -r "$CHEATS_SRC/." "$CHEATS_DEST/"
    log_info "  Cheats deployed → ${C_CYAN}$CHEATS_DEST${C_RESET}"
else
    log_warn "  cheats.d not found: $CHEATS_SRC"
fi

# ============= Deploy Tools =============
log_info ""
log_info "Deploying tools..."

TOOLS_SRC="$ROOT_DIR/tools"
TOOLS_DEST="$HOME/.local/share/devtoolbox-cheats/tools"

if [[ -d "$TOOLS_SRC" ]]; then
    mkdir -p "$TOOLS_DEST"
    cp -r "$TOOLS_SRC/." "$TOOLS_DEST/"
    chmod +x "$TOOLS_DEST"/*.py 2>/dev/null || true
    log_info "  Tools deployed → ${C_CYAN}$TOOLS_DEST${C_RESET}"
else
    log_warn "  tools/ not found: $TOOLS_SRC"
fi

# ============= Setup Plugins =============
log_info ""
log_info "Setting up Menu Bar Plugins..."

# Default: SwiftBar (recommended for macOS 12+).
# xbar is still supported via DEVTOOLBOX_APP_TARGET=1 (or =3 for both).
APP_CHOICE="2"
if [[ -n "${DEVTOOLBOX_APP_TARGET:-}" ]]; then
    APP_CHOICE="$DEVTOOLBOX_APP_TARGET"
else
    # Detect macOS version: SwiftBar requires macOS 12+.
    # On older macOS, recommend xbar instead.
    MACOS_MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1 || true)"
    if [[ -n "$MACOS_MAJOR" ]] && (( MACOS_MAJOR < 12 )); then
        log_warn "macOS ${MACOS_MAJOR} detected. SwiftBar requires macOS 12+."
        log_info "Defaulting to xbar for this macOS version."
        APP_CHOICE="1"
    fi
fi

if [[ "$APP_CHOICE" == "2" || "$APP_CHOICE" == "3" ]]; then
    if [[ ! -d "/Applications/SwiftBar.app" && ! -d "$HOME/Applications/SwiftBar.app" ]]; then
        echo ""
        log_warn "SwiftBar is not installed."
        if [[ "$PKG_MGR" == "brew" ]]; then
            printf "  Would you like to install SwiftBar via Homebrew? [y/N]: "
            if ! read -r choice < /dev/tty 2>/dev/null; then
                if ! read -r choice 2>/dev/null; then
                    choice=""
                fi
            fi
            if [[ "$choice" == [yY]* ]]; then
                log_info "Installing SwiftBar..."
                if brew install --cask swiftbar; then
                    log_info "SwiftBar installed successfully."
                else
                    log_warn "Failed to install SwiftBar. You may need to install it manually."
                fi
            else
                log_info "Skipping SwiftBar installation."
            fi
        else
            log_warn "Please install SwiftBar manually from https://swiftbar.app"
        fi
        echo ""
    fi
fi

PLUGIN_DIRS=()

if [[ "$APP_CHOICE" == "1" || "$APP_CHOICE" == "3" ]]; then
    PLUGIN_DIRS+=("$HOME/Library/Application Support/xbar/plugins")
fi

if [[ "$APP_CHOICE" == "2" || "$APP_CHOICE" == "3" ]]; then
    SB_DEFAULT="$HOME/Library/Application Support/SwiftBar/Plugins"
    SB_DIR="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)"
    if [[ -z "$SB_DIR" ]]; then
        SB_DIR="$SB_DEFAULT"
        log_info "SwiftBar plugin directory not explicitly set. Using default: $SB_DIR"
    fi
    PLUGIN_DIRS+=("$SB_DIR")
    # Also copy to the default location so plugins work even if the custom
    # directory is on a different volume or gets reset.
    if [[ "$SB_DIR" != "$SB_DEFAULT" ]]; then
        PLUGIN_DIRS+=("$SB_DEFAULT")
    fi
fi

# Make scripts executable in source
for plugin_file in "$SCRIPT_DIR/devtoolbox-cheats.30s.sh" "$SCRIPT_DIR/devtools.1m.sh" \
                   "$SCRIPT_DIR/cheats-updater.sh" "$SCRIPT_DIR/generate-tldr.sh"; do
    if [[ -f "$plugin_file" && ! -x "$plugin_file" ]]; then
        chmod +x "$plugin_file"
        log_info "  Restored execute bit: $(basename "$plugin_file")"
    fi
done

# is_devtoolbox_link identifies whether a path is a recognized DevToolbox plugin file or symbolic link.
is_devtoolbox_link() {
    local link="$1" target resolved
    if [[ -L "$link" ]]; then
        target="$(readlink "$link" 2>/dev/null)" || return 1
        # Accept only if the resolved target is an exact source-file match
        # or lives under our known source directory.
        case "$target" in
            "$SCRIPT_DIR/devtoolbox-cheats.30s.sh"|\
            "$SCRIPT_DIR/devtools.1m.sh") return 0 ;;
        esac
        resolved="$(cd "$(dirname "$link")" 2>/dev/null && cd "$(dirname "$target")" 2>/dev/null && pwd)" || return 1
        [[ "$resolved" == "$SCRIPT_DIR" ]] && return 0
    elif [[ -f "$link" ]]; then
        grep -q "DevToolbox Cheats" "$link" 2>/dev/null && return 0
        grep -q "Dev Toolbox" "$link" 2>/dev/null && return 0
    fi
    return 1
}

for PDIR in "${PLUGIN_DIRS[@]}"; do
    mkdir -p "$PDIR"
    
    for script_name in \
        devtools.1m.sh \
        devtoolbox-cheats.30s.sh; do
        target_path="$PDIR/$script_name"
        if [[ -e "$target_path" || -L "$target_path" ]]; then
            if is_devtoolbox_link "$target_path"; then
                rm -f "$target_path"
                log_info "  Removed old plugin file/link: $script_name from $PDIR"
            else
                log_error "Refusing to overwrite unknown file: $target_path"
                log_error "Remove or rename it, then re-run the installer."
                exit 1
            fi
        fi
    done

    # Install the current plugins
    for plugin_name in devtoolbox-cheats.30s.sh devtools.1m.sh; do
        target_path="$PDIR/$plugin_name"
        if [[ "${DEVTOOLBOX_USE_SYMLINKS:-false}" == "true" ]]; then
            ln -sf "$SCRIPT_DIR/$plugin_name" "$target_path"
            log_info "  Symlinked $plugin_name → ${C_CYAN}$PDIR/${C_RESET}"
        else
            cp -f "$SCRIPT_DIR/$plugin_name" "$target_path"
            chmod +x "$target_path"
            log_info "  Copied $plugin_name → ${C_CYAN}$PDIR/${C_RESET}"
        fi
    done
done

# ============= Setup PATH =============
log_info ""
log_info "Setting up PATH..."

LOCAL_BIN="$HOME/.local/bin"
if [[ ! "$PATH" == *"$LOCAL_BIN"* ]]; then
    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        SHELL_RC="$HOME/.bash_profile"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        # Match the literal marker the installer writes (comment or unexpanded
        # "$HOME/.local/bin"), not the expanded path — otherwise reruns would
        # append duplicate blocks when only the literal form is present.
        # shellcheck disable=SC2016  # literal '$HOME' is intentional
        if ! grep -q "DevToolbox Cheats" "$SHELL_RC" 2>/dev/null \
           && ! grep -qF '$HOME/.local/bin' "$SHELL_RC" 2>/dev/null; then
            {
                echo ""
                echo "# DevToolbox Cheats"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
            } >> "$SHELL_RC"
            log_info "  Added $LOCAL_BIN to ${C_CYAN}$SHELL_RC${C_RESET}"
        else
            log_info "  $LOCAL_BIN already in ${C_CYAN}$SHELL_RC${C_RESET}"
        fi
    else
        log_warn "  No shell RC file found. Add $LOCAL_BIN to your PATH manually."
    fi
else
    log_info "  $LOCAL_BIN already in PATH"
fi

# ============= Setup Cheats-Updater =============
log_info ""
log_info "Setting up cheats-updater..."

UPDATER_SRC="$SCRIPT_DIR/cheats-updater.sh"
UPDATER_DEST="$LOCAL_BIN/cheats-updater"

mkdir -p "$LOCAL_BIN"

if [[ -f "$UPDATER_SRC" ]]; then
    cp "$UPDATER_SRC" "$UPDATER_DEST"
    chmod +x "$UPDATER_DEST"
    log_info "  cheats-updater installed → ${C_CYAN}$UPDATER_DEST${C_RESET}"
else
    log_warn "  cheats-updater.sh not found: $UPDATER_SRC"
fi

# ============= Setup TLDR Generator (CLI) =============
log_info ""
log_info "Setting up generate-tldr..."

TLDR_SRC="$SCRIPT_DIR/generate-tldr.sh"
TLDR_DEST="$LOCAL_BIN/generate-tldr"

if [[ -f "$TLDR_SRC" ]]; then
    cp "$TLDR_SRC" "$TLDR_DEST"
    chmod +x "$TLDR_DEST"
    log_info "  generate-tldr installed → ${C_CYAN}$TLDR_DEST${C_RESET}"
else
    log_warn "  generate-tldr.sh not found: $TLDR_SRC"
fi

# ============= Setup Launchd Timer (Optional) =============
log_info ""
log_info "Setting up launchd auto-updater..."

PLIST_NAME="com.devtoolbox-cheats.updater"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
SCRIPT_PATH="$LOCAL_BIN/cheats-updater"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Application-owned log directory (predictable /tmp paths are insecure).
LOG_DIR="$HOME/Library/Logs/devtoolbox-cheats"
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Create launchd plist for daily auto-updates
cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${SCRIPT_PATH}</string>
        <string>update</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/${PLIST_NAME}.out.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/${PLIST_NAME}.err.log</string>
</dict>
</plist>
PLIST

log_info "  LaunchAgent created → ${C_CYAN}$PLIST_PATH${C_RESET}"

# Load the LaunchAgent
if launchctl list | grep -q "$PLIST_NAME" 2>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi
launchctl load "$PLIST_PATH" 2>/dev/null || log_warn "  Failed to load LaunchAgent (may need manual activation)"

log_info "  Auto-updater scheduled daily at 10:00 AM"

# ============= Summary =============
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Installation Complete                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  ${C_BOLD}Installed components:${C_RESET}"
    echo "    • Cheatsheets  → ~/cheats.d/"
    if [[ "$APP_CHOICE" == "1" || "$APP_CHOICE" == "3" ]]; then
        echo "    • xbar plugins → $HOME/Library/Application Support/xbar/plugins/"
    fi
    if [[ "$APP_CHOICE" == "2" || "$APP_CHOICE" == "3" ]]; then
        echo "    • SwiftBar plg → $SB_DIR/"
        if [[ "$SB_DIR" != "$SB_DEFAULT" ]]; then
            echo "    •               → $SB_DEFAULT/ (fallback)"
        fi
    fi
    echo "    • Updater      → $LOCAL_BIN/cheats-updater"
    echo "    • TLDR gen     → $LOCAL_BIN/generate-tldr"
    echo "    • Auto-update   → Daily at 10:00 AM (launchd)"
echo ""
echo "  ${C_BOLD}Next steps:${C_RESET}"
if [[ "$APP_CHOICE" == "1" || "$APP_CHOICE" == "3" ]]; then
    echo "    1. Install xbar from https://xbarapp.com"
    echo "    2. xbar will automatically detect the plugin"
fi
if [[ "$APP_CHOICE" == "2" || "$APP_CHOICE" == "3" ]]; then
    echo "    1. Install SwiftBar from https://swiftbar.app"
    echo "    2. SwiftBar will automatically detect the plugin"
fi
_plugin_path="${SB_DIR:-$HOME/Library/Application Support/xbar/plugins}/devtoolbox-cheats.30s.sh"
echo "    3. Or run directly: $_plugin_path"
echo ""
echo "  ${C_BOLD}Manual commands:${C_RESET}"
echo "    • Browse cheats:   $_plugin_path menu"
echo "    • Update cheats:   $LOCAL_BIN/cheats-updater update"
echo "    • Check updates:   $LOCAL_BIN/cheats-updater check"
echo "    • Generate TLDR:   $LOCAL_BIN/generate-tldr"
echo ""
if [[ "$APP_CHOICE" == "2" ]]; then
    echo "  ${C_DIM}Note: xbar is available via DEVTOOLBOX_APP_TARGET=1${C_RESET}"
fi
echo ""
