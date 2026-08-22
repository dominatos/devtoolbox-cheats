#!/usr/bin/env bash
# macOS-beta/uninstall.sh — Uninstall DevToolbox Cheats from macOS
set -euo pipefail

# ============= Colors =============
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_CYAN=$'\033[0;36m' C_BOLD=$'\033[1m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_CYAN="" C_BOLD=""
fi

log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_remove() { echo -e "${C_RED}[REMOVE]${C_RESET} $*"; }

# ============= Header =============
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     DevToolbox Cheats — macOS Uninstaller                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============= Confirmation =============
read -rp "Remove DevToolbox Cheats and all installed files? [y/N]: " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ============= Unload LaunchAgent =============
PLIST_NAME="com.devtoolbox-cheats.updater"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

if [[ -f "$PLIST_PATH" ]]; then
    log_remove "Unloading LaunchAgent..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    log_remove "  Removed $PLIST_PATH"
fi

# ============= Remove xbar Plugin =============
XBAR_PLUGIN="$HOME/Library/Application Support/xbar/plugins/devtoolbox-cheats"
if [[ -e "$XBAR_PLUGIN" ]]; then
    log_remove "Removing xbar plugin..."
    rm -f "$XBAR_PLUGIN"
    log_remove "  Removed $XBAR_PLUGIN"
fi

# ============= Remove Cheats-Updater =============
LOCAL_BIN="$HOME/.local/bin"
UPDATER="$LOCAL_BIN/cheats-updater"
if [[ -f "$UPDATER" ]]; then
    log_remove "Removing cheats-updater..."
    rm -f "$UPDATER"
    log_remove "  Removed $UPDATER"
fi

# ============= Remove Deployed Cheatsheets =============
CHEATS_DIR="$HOME/cheats.d"
if [[ -d "$CHEATS_DIR" ]]; then
    log_remove "Removing cheatsheets..."
    rm -rf "$CHEATS_DIR"
    log_remove "  Removed $CHEATS_DIR"
fi

# ============= Remove Deployed Tools =============
TOOLS_DIR="$HOME/.local/share/devtoolbox-cheats"
if [[ -d "$TOOLS_DIR" ]]; then
    log_remove "Removing tools..."
    rm -rf "$TOOLS_DIR"
    log_remove "  Removed $TOOLS_DIR"
fi

# ============= Remove Cache =============
CACHE_DIR="$HOME/.cache/devtoolbox-cheats-combined"
CACHE_DIR2="$HOME/.cache/devtoolbox-cheats-argos-combined"
CACHE_IDX="$HOME/.cache/devtoolbox-cheats-combined.idx"
if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "$CACHE_DIR"
    log_remove "  Removed $CACHE_DIR"
fi
if [[ -d "$CACHE_DIR2" ]]; then
    rm -rf "$CACHE_DIR2"
    log_remove "  Removed $CACHE_DIR2"
fi
if [[ -f "$CACHE_IDX" ]]; then
    rm -f "$CACHE_IDX"
    log_remove "  Removed $CACHE_IDX"
fi

# ============= Remove Config =============
CONFIG_DIR="$HOME/.config/devtoolbox-cheats"
if [[ -d "$CONFIG_DIR" ]]; then
    log_remove "Removing config..."
    rm -rf "$CONFIG_DIR"
    log_remove "  Removed $CONFIG_DIR"
fi

# ============= Remove PATH from Shell RC =============
log_info "Checking shell RC files for PATH entry..."
LOCAL_BIN_LINE='export PATH="$HOME/.local/bin:$PATH"'
DEVTOOLBOX_COMMENT="# DevToolbox Cheats"

for rc in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [[ -f "$rc" ]] && grep -q "DevToolbox Cheats" "$rc" 2>/dev/null; then
        # Remove the comment line and the PATH line after it
        sed -i '' '/# DevToolbox Cheats/d' "$rc"
        sed -i '' '/\$HOME\/.local\/bin/d' "$rc"
        log_remove "  Cleaned $rc"
    fi
done

# ============= Remove LaunchAgent Logs =============
rm -f "/tmp/${PLIST_NAME}.out.log" "/tmp/${PLIST_NAME}.err.log" 2>/dev/null || true

# ============= Summary =============
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Uninstall Complete                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  ${C_BOLD}Removed:${C_RESET}"
echo "    • Cheatsheets  → ~/cheats.d/"
echo "    • xbar plugin  → ~/Library/Application Support/xbar/plugins/devtoolbox-cheats"
echo "    • Updater      → ~/.local/bin/cheats-updater"
echo "    • Auto-update  → LaunchAgent unloaded"
echo "    • Config       → ~/.config/devtoolbox-cheats/"
echo "    • Cache        → ~/.cache/devtoolbox-cheats*"
echo ""
echo "  ${C_BOLD}Note:${C_RESET} Package manager packages (jq, fzf, pandoc, etc.) were NOT removed."
echo "        Uninstall them manually if no longer needed."
echo ""
