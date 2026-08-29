#!/usr/bin/env bash
# macOS-beta/uninstall.sh — Uninstall DevToolbox Cheats from macOS
set -euo pipefail

# ============= Host check =============
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This uninstaller is for macOS only. No cleanup performed." >&2
    exit 1
fi

# ============= Colors =============
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_BOLD=$'\033[1m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BOLD=""
fi

# log_info prints an informational message with a green status prefix.
log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET} $*"; }
# log_warn prints a warning message with warning-level formatting.
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
# log_remove prints a colored removal-status message with the provided arguments.
log_remove() { echo -e "${C_RED}[REMOVE]${C_RESET} $*"; }

# ============= Header =============
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     DevToolbox Cheats — macOS Uninstaller                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============= Confirmation =============
# EOF / closed stdin counts as "no" and exits cleanly.
confirm=""
printf "Remove DevToolbox Cheats and all installed files? [y/N]: "
read -r confirm || confirm=""
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

# ============= Remove Plugins =============
PLUGIN_DIRS=()
PLUGIN_DIRS+=("$HOME/Library/Application Support/xbar/plugins")

SB_DEFAULT="$HOME/Library/Application Support/SwiftBar/Plugins"
SB_DIR="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)"
if [[ -z "$SB_DIR" ]]; then
    SB_DIR="$SB_DEFAULT"
fi
PLUGIN_DIRS+=("$SB_DIR")
# Also clean the default location in case plugins were copied there as a fallback.
if [[ "$SB_DIR" != "$SB_DEFAULT" ]]; then
    PLUGIN_DIRS+=("$SB_DEFAULT")
fi

# is_devtoolbox_link identifies DevToolbox plugin links and files eligible for removal.
is_devtoolbox_link() {
    local link="$1" target resolved
    if [[ -L "$link" ]]; then
        target="$(readlink "$link" 2>/dev/null)" || return 1
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
    if [[ -d "$PDIR" ]]; then
        for script in \
            devtoolbox-cheats.30s.sh \
            devtools.1m.sh \
            compat.sh \
            cheats-updater.sh \
            generate-tldr.sh \
            bump-version.sh \
            devtoolbox-cheats; do
            target_path="$PDIR/$script"
            if [[ -e "$target_path" || -L "$target_path" ]]; then
                if is_devtoolbox_link "$target_path"; then
                    rm -f "$target_path"
                    log_remove "  Removed $target_path"
                fi
            fi
        done
    fi
done

# ============= Remove Cheats-Updater and TLDR Generator =============
LOCAL_BIN="$HOME/.local/bin"
for cli in cheats-updater generate-tldr; do
    tool="$LOCAL_BIN/$cli"
    if [[ -f "$tool" ]]; then
        log_remove "Removing $cli..."
        rm -f "$tool"
        log_remove "  Removed $tool"
    fi
done

# ============= Remove Deployed Cheatsheets =============
CHEATS_DIR="$HOME/cheats.d"
if [[ -d "$CHEATS_DIR" ]]; then
    echo ""
    printf "Do you also want to remove all cheatsheets in ~/cheats.d (including custom ones)? [y/N]: "
    read -r confirm_cheats 2>/dev/null || confirm_cheats=""
    if [[ "$confirm_cheats" == [yY] ]]; then
        log_remove "Removing cheatsheets..."
        rm -rf "$CHEATS_DIR"
        log_remove "  Removed $CHEATS_DIR"
    else
        log_info "Keeping cheatsheets in $CHEATS_DIR"
    fi
fi

# ============= Remove Deployed Tools =============
TOOLS_DIR="$HOME/.local/share/devtoolbox-cheats"
if [[ -d "$TOOLS_DIR" ]]; then
    # Updater backups are the only recovery copies of user cheatsheets —
    # never remove them without explicit confirmation.
    backups_dir="$TOOLS_DIR/backups"
    if [[ -d "$backups_dir" ]] && [[ "$(ls -A "$backups_dir" 2>/dev/null)" ]]; then
        # EOF / no stdin counts as "no" so cleanup can continue under set -e.
        confirm_backups=""
        printf "Updater backups exist in %s. Remove them too? [y/N]: " "$backups_dir"
        read -r confirm_backups 2>/dev/null || confirm_backups=""
        if [[ "$confirm_backups" == [yY] ]]; then
            log_remove "Removing tools and backups..."
            rm -rf "$TOOLS_DIR"
            log_remove "  Removed $TOOLS_DIR (including backups)"
        else
            log_info "Keeping backups in $backups_dir"
            # Remove everything except backups.
            find "$TOOLS_DIR" -mindepth 1 -maxdepth 1 ! -name 'backups' -exec rm -rf {} +
            log_remove "  Removed $TOOLS_DIR contents (backups preserved)"
        fi
    else
        log_remove "Removing tools..."
        rm -rf "$TOOLS_DIR"
        log_remove "  Removed $TOOLS_DIR"
    fi
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

for rc in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [[ -f "$rc" ]] && grep -q "DevToolbox Cheats" "$rc" 2>/dev/null; then
        # Back up before modifying.
        cp -p "$rc" "${rc}.devtoolbox-uninstall-backup"
        # Remove only the marker comment and its immediately following
        # PATH line; unrelated entries stay intact.
        awk '
            /# DevToolbox Cheats/ { skip_path_line = 1; next }
            skip_path_line && /\.local\/bin/ { skip_path_line = 0; next }
            { skip_path_line = 0; print }
        ' "$rc" > "${rc}.tmp" && mv "${rc}.tmp" "$rc"
        log_remove "  Cleaned $rc (backup: ${rc}.devtoolbox-uninstall-backup)"
    fi
done

# ============= Remove LaunchAgent Logs =============
LOG_DIR="$HOME/Library/Logs/devtoolbox-cheats"
if [[ -d "$LOG_DIR" ]]; then
    rm -rf "$LOG_DIR"
    log_remove "  Removed $LOG_DIR"
fi
# Legacy /tmp logs from older installers.
rm -f "/tmp/${PLIST_NAME}.out.log" "/tmp/${PLIST_NAME}.err.log" 2>/dev/null || true

# ============= Summary =============
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Uninstall Complete                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  ${C_BOLD}Removed:${C_RESET}"
echo "    • Cheatsheets  → ~/cheats.d/ (if confirmed)"
echo "    • xbar plugins → ~/Library/Application Support/xbar/plugins/ (devtoolbox-cheats.30s.sh, devtools.1m.sh)"
echo "    • Updater      → ~/.local/bin/cheats-updater"
echo "    • TLDR gen     → ~/.local/bin/generate-tldr"
echo "    • Auto-update  → LaunchAgent unloaded"
echo "    • Config       → ~/.config/devtoolbox-cheats/"
echo "    • Cache        → ~/.cache/devtoolbox-cheats*"
echo ""
echo "  ${C_BOLD}Note:${C_RESET} Package manager packages (jq, fzf, pandoc, etc.) were NOT removed."
echo "        Uninstall them manually if no longer needed."
echo ""
