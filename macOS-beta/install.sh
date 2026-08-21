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

# ============= Check Homebrew =============
log_info "Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew is required but not installed."
    echo "  Install Homebrew:"
    echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
log_info "Homebrew found: $(brew --version | head -n1)"

# ============= Install Dependencies =============
log_info "Installing dependencies via Homebrew..."
echo ""

# Required dependencies
DEPS=(
    "fzf"              # Fuzzy finder
    "bat"              # Syntax highlighting (optional, for fzf preview)
    "coreutils"        # GNU coreutils (grealpath, etc.)
    "jq"               # JSON processor
    "pandoc"           # Document converter (optional, for PDF export)
)

for dep in "${DEPS[@]}"; do
    if brew list "$dep" >/dev/null 2>&1; then
        log_info "  ${C_DIM}$dep${C_RESET} — already installed"
    else
        log_info "  Installing ${C_CYAN}$dep${C_RESET}..."
        brew install "$dep" || log_warn "Failed to install $dep (may be optional)"
    fi
done

# Optional: Noto Color Emoji font
echo ""
log_info "Checking for emoji font..."
if fc-list 2>/dev/null | grep -qi "noto.*emoji"; then
    log_info "  Noto Color Emoji font found"
else
    log_info "  Installing Noto Color Emoji font..."
    brew install --cask font-noto-color-emoji || log_warn "Failed to install emoji font (optional)"
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
DEVTOOLBOX_XBAR_DIR="$XBAR_PLUGINS_DIR/devtoolbox-cheats"

# Create xbar plugins directory if it doesn't exist
mkdir -p "$XBAR_PLUGINS_DIR"

# Create symlink to macOS scripts
if [[ -L "$DEVTOOLBOX_XBAR_DIR" ]]; then
    rm -f "$DEVTOOLBOX_XBAR_DIR"
fi

ln -sf "$SCRIPT_DIR" "$DEVTOOLBOX_XBAR_DIR"
log_info "  xbar plugin link → ${C_CYAN}$DEVTOOLBOX_XBAR_DIR${C_RESET}"

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

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
