#!/usr/bin/env bash
# macOS-beta/install.sh — macOS installer for DevToolbox Cheats
# Installs DevToolbox Cheats on macOS with xbar integration.
set -euo pipefail

VERSION="v1.5.5"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============= Colors =============
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_BLUE=$'\033[0;34m' C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD="" C_DIM=""
fi

log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*"; }

# ============= Header =============
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
    read -rp "  Which package manager to use? [1/2]: " choice
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
    log_error "No package manager found (Homebrew or MacPorts required)."
    echo ""
    echo "  Install Homebrew:"
    echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "  Or install MacPorts:"
    echo "    https://www.macports.org/install.php"
    exit 1
fi

log_info "Selected package manager: ${C_CYAN}$PKG_MGR${C_RESET}"

# ============= Package Install Helper =============
# Maps package names between brew and port
install_pkg() {
    local pkg="$1"
    local brew_name="${2:-$pkg}"
    local port_name="${3:-$pkg}"

    if [[ "$PKG_MGR" == "brew" ]]; then
        if brew list "$brew_name" >/dev/null 2>&1; then
            log_info "  ${C_DIM}$brew_name${C_RESET} — already installed"
        else
            log_info "  Installing ${C_CYAN}$brew_name${C_RESET} via Homebrew..."
            brew install "$brew_name" || log_warn "Failed to install $brew_name"
        fi
    elif [[ "$PKG_MGR" == "port" ]]; then
        if port installed "$port_name" 2>/dev/null | grep -q "installed"; then
            log_info "  ${C_DIM}$port_name${C_RESET} — already installed"
        else
            log_info "  Installing ${C_CYAN}$port_name${C_RESET} via MacPorts..."
            sudo port install "$port_name" || log_warn "Failed to install $port_name"
        fi
    fi
}

# ============= Install Dependencies =============
log_info "Installing dependencies via $PKG_MGR..."
echo ""

# Required dependencies
# Format: "generic_name brew_name port_name"
# If brew_name and port_name are same as generic, can omit them
install_pkg "fzf"
install_pkg "jq"
install_pkg "pandoc"

# bat: different names in brew vs port
if [[ "$PKG_MGR" == "brew" ]]; then
    install_pkg "bat" "bat" "bat"
elif [[ "$PKG_MGR" == "port" ]]; then
    # MacPorts uses 'bat' as well
    install_pkg "bat" "bat" "bat"
fi

# coreutils: GNU coreutils (grealpath, etc.)
if [[ "$PKG_MGR" == "brew" ]]; then
    install_pkg "coreutils" "coreutils" "coreutils"
elif [[ "$PKG_MGR" == "port" ]]; then
    install_pkg "coreutils" "coreutils" "coreutils"
fi

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

# ============= Setup xbar Plugin =============
log_info ""
log_info "Setting up xbar plugin..."

XBAR_PLUGINS_DIR="$HOME/Library/Application Support/xbar/plugins"

# Create xbar plugins directory if it doesn't exist
mkdir -p "$XBAR_PLUGINS_DIR"

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Create individual symlinks for each script (xbar requires this)
# Only link cheats wrapper — devtools.1m.sh is not yet working
for script in "$SCRIPT_DIR"/devtoolbox-cheats.30s.sh "$SCRIPT_DIR"/compat.sh; do
    script_name="$(basename "$script")"
    xbar_link="$XBAR_PLUGINS_DIR/$script_name"
    if [[ -L "$xbar_link" ]]; then
        rm -f "$xbar_link"
    fi
    ln -sf "$script" "$xbar_link"
done
log_info "  xbar plugin links → ${C_CYAN}$XBAR_PLUGINS_DIR/${C_RESET}"

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
        if ! grep -q "$LOCAL_BIN" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# DevToolbox Cheats" >> "$SHELL_RC"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
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

UPDATER_SRC="$ROOT_DIR/cheats-updater.sh"
UPDATER_DEST="$LOCAL_BIN/cheats-updater"

mkdir -p "$LOCAL_BIN"

if [[ -f "$UPDATER_SRC" ]]; then
    cp "$UPDATER_SRC" "$UPDATER_DEST"
    chmod +x "$UPDATER_DEST"
    log_info "  cheats-updater installed → ${C_CYAN}$UPDATER_DEST${C_RESET}"
else
    log_warn "  cheats-updater.sh not found: $UPDATER_SRC"
fi

# ============= Setup Launchd Timer (Optional) =============
log_info ""
log_info "Setting up launchd auto-updater..."

PLIST_NAME="com.devtoolbox-cheats.updater"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
SCRIPT_PATH="$LOCAL_BIN/cheats-updater"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

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
    <string>/tmp/${PLIST_NAME}.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/${PLIST_NAME}.err.log</string>
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
echo "    • xbar plugin  → $XBAR_PLUGINS_DIR/devtoolbox-cheats/"
echo "    • Updater      → $LOCAL_BIN/cheats-updater"
echo "    • Auto-update   → Daily at 10:00 AM (launchd)"
echo ""
echo "  ${C_BOLD}Next steps:${C_RESET}"
echo "    1. Install xbar from https://xbarapp.com"
echo "    2. xbar will automatically detect the plugin"
echo "    3. Or run directly: $SCRIPT_DIR/devtoolbox-cheats.30s.sh"
echo ""
echo "  ${C_BOLD}Manual commands:${C_RESET}"
echo "    • Browse cheats:   $SCRIPT_DIR/devtoolbox-cheats.30s.sh menu"
echo "    • Update cheats:   $LOCAL_BIN/cheats-updater update"
echo "    • Check updates:   $LOCAL_BIN/cheats-updater check"
echo ""
