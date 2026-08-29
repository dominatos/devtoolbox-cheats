#!/bin/bash
# Force-install DevToolbox Cheats Widget (Plasma 6)

echo "📦 Installing DevToolbox Cheats Widget..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/DevToolboxPlasmoid"
PKG_ID="com.dominatos.devtoolboxcheats"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PKG_ID"

if [ ! -d "$PKG_DIR" ]; then
    echo "❌ Error: $PKG_DIR not found!"
    exit 1
fi

# --- 1. Clean up deprecated metadata.desktop ---
[ -f "$PKG_DIR/metadata.desktop" ] && rm -f "$PKG_DIR/metadata.desktop"

# --- 2. Force-remove any existing installation ---
echo "→ Removing previous installation..."

# Try kpackagetool6 first
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --remove "$PKG_ID" 2>/dev/null || true
fi

# Force-remove directories regardless (clean slate)
rm -rf "$INSTALL_DIR" 2>/dev/null || true
rm -rf "$HOME/.local/share/kpackage/generic/$PKG_ID" 2>/dev/null || true

# --- 3. Clear QML cache (CRITICAL!) ---
echo "→ Clearing QML cache..."
echo "  This ensures config page shows correctly!"

# Clear all QML caches
rm -rf "$HOME/.cache/plasmashell/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/plasma-plasmashell/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/qt6/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/qmlcache" 2>/dev/null || true

# Clear KCM (configuration module) caches
rm -rf "$HOME/.cache/kcmshell6" 2>/dev/null || true
rm -rf "$HOME/.cache/plasma_theme" 2>/dev/null || true

# Remove any cached QML files for this specific widget
find "$HOME/.cache" -type f \( -name "*.qmlc" -o -name "*.jsc" \) -path "*devtoolbox*" -delete 2>/dev/null || true
find "$HOME/.cache" -type f \( -name "*.qmlc" -o -name "*.jsc" \) -path "*dominatos*" -delete 2>/dev/null || true

echo "  ✅ QML cache cleared"

# --- Helper: transactional copy install ---
# stage_install SRC DEST — copies SRC into a temp dir, validates, then replaces DEST.
# Preserves DEST on failure. Exits 1 on any error.
stage_install() {
    local src="$1" dest="$2"
    local tmp="${dest}.staging.$$"
    local backup="${dest}.backup.$$"

    # Stage into temp sibling
    if ! rm -rf "$tmp" 2>/dev/null; then
        echo "❌ Failed to clean staging dir: $tmp" >&2; exit 1
    fi
    if ! mkdir -p "$tmp"; then
        echo "❌ Failed to create staging dir: $tmp" >&2; exit 1
    fi
    if ! cp -a "$src"/. "$tmp/"; then
        echo "❌ Failed to stage files from $src" >&2
        rm -rf "$tmp" 2>/dev/null || true
        exit 1
    fi

    # Backup existing destination (if any)
    if [ -d "$dest" ]; then
        if ! mv "$dest" "$backup"; then
            echo "❌ Failed to backup existing: $dest" >&2
            rm -rf "$tmp" 2>/dev/null || true
            exit 1
        fi
    fi

    # Replace destination with staged files
    if ! mv "$tmp" "$dest"; then
        echo "❌ Failed to install: $dest" >&2
        rm -rf "$tmp" 2>/dev/null || true
        # Restore backup if we moved the original
        if [ -d "$backup" ]; then
            if ! mv "$backup" "$dest"; then
                echo "❌ Recovery also failed — backup at: $backup" >&2
            fi
        fi
        exit 1
    fi

    # Cleanup backup on success
    rm -rf "$backup" 2>/dev/null || true
}

# --- 4. Install widget ---
echo "→ Installing widget..."
if command -v kpackagetool6 >/dev/null 2>&1; then
    if ! kpackagetool6 --type Plasma/Applet --install "$PKG_DIR" 2>&1; then
        echo "  kpackagetool6 --install failed, trying --upgrade..."
        kpackagetool6 --type Plasma/Applet --upgrade "$PKG_DIR" 2>&1 || true
    fi
else
    # Manual install fallback: transactional copy
    echo "  ⚠️  kpackagetool6 not found — doing manual copy install"
    stage_install "$PKG_DIR" "$INSTALL_DIR"
fi

# Verify installation
if [ -d "$INSTALL_DIR" ]; then
    echo "✅ Widget installed to: $INSTALL_DIR"
else
    # If kpackagetool worked but installed elsewhere, check
    if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "$PKG_ID"; then
        echo "✅ Widget installed (via kpackagetool6)"
    else
        echo "⚠️  Installation may have failed. Doing manual copy..."
        stage_install "$PKG_DIR" "$INSTALL_DIR"
        echo "✅ Manual install done: $INSTALL_DIR"
    fi
fi

# --- 5. Deploy cheatsheets ---
echo ""
if [ "${SKIP_CHEATS_DEPLOY:-0}" != "1" ]; then
    echo "→ Deploying cheatsheets..."
    if [ -d "$SCRIPT_DIR/../cheats.d" ]; then
        mkdir -p "$HOME/cheats.d"
        cp -r "$SCRIPT_DIR/../cheats.d"/* "$HOME/cheats.d/"
        CHEAT_COUNT=$(find "$HOME/cheats.d" -name "*.md" | wc -l)
        echo "✅ Deployed $CHEAT_COUNT cheatsheets to ~/cheats.d"
    else
        echo "⚠️  cheats.d source not found at $SCRIPT_DIR/../cheats.d — skipping"
    fi
else
    echo "→ Skipping cheatsheets deployment (already deployed)"
fi

# --- 6. Install dependencies (optional, non-fatal) ---
echo ""
echo "→ Checking dependencies..."
MISSING=""
for cmd in fzf bat zenity wl-copy notify-send fc-cache; do
    command -v "$cmd" >/dev/null 2>&1 || MISSING="$MISSING $cmd"
done

if [ -n "$MISSING" ]; then
    echo "  Missing:$MISSING"
    if command -v apt >/dev/null 2>&1; then
        echo "  → Installing via apt..."
        sudo apt install -y fonts-noto-color-emoji fzf bat zenity wl-clipboard xclip libnotify-bin fontconfig 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        echo "  → Installing via dnf..."
        sudo dnf install -y google-noto-emoji-color-fonts fzf bat zenity wl-clipboard xclip libnotify fontconfig 2>&1 || true
    elif command -v pacman >/dev/null 2>&1; then
        echo "  → Installing via pacman..."
        sudo pacman -S --noconfirm noto-fonts-emoji fzf bat zenity wl-clipboard xclip libnotify fontconfig 2>&1 || true
    else
        echo "  ⚠️  Install manually:$MISSING"
    fi
    fc-cache -f 2>/dev/null || true
else
    echo "  ✅ All dependencies present"
fi

# --- 7. Restart Plasma Shell (SAFE METHOD) ---
echo ""
echo "============================================"
echo "✅ Installation complete!"
echo "============================================"
echo ""

if ! pgrep -x plasmashell >/dev/null 2>&1; then
    echo "ℹ️  Plasma Shell is not currently running."
    echo "   The widget will be available the next time you log into KDE Plasma."
    echo ""
    echo "When you run Plasma:"
    echo "  1. Right-click panel → Add Widgets"
    echo "  2. Search 'DevToolbox Cheats'"
    echo "  3. Add to panel or desktop"
    echo "  4. Right-click widget → Configure"
    echo ""
    exit 0
fi

echo "🔄 Plasma Shell needs to restart for changes to take effect."
echo "   (This ensures config page shows correctly!)"
echo ""
echo "Choose restart method:"
echo "  1. Restart manually (safest - recommended for VMs)"
echo "  2. Automatic restart (tries systemctl then kquitapp6)"
echo ""
if [[ -r /dev/tty ]]; then
    read -rp "Enter choice [1-2]: " RESTART_CHOICE < /dev/tty || RESTART_CHOICE=""
else
    RESTART_CHOICE=""
fi

case "$RESTART_CHOICE" in
    1)
        echo ""
        echo "Manual restart commands (choose one):"
        echo ""
        echo "Option A (systemctl):"
        echo "  systemctl --user restart plasma-plasmashell.service"
        echo ""
        echo "Option B (kquitapp6):"
        echo "  kquitapp6 plasmashell && sleep 2 && plasmashell &"
        echo ""
        echo "After restart:"
        echo "  1. Right-click panel → Add Widgets"
        echo "  2. Search 'DevToolbox Cheats'"
        echo "  3. Add to panel or desktop"
        echo "  4. Right-click widget → Configure to see editor dropdown!"
        ;;
    2)
        echo ""
        echo "→ Attempting automatic restart..."
        if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
            echo "Using systemctl..."
            systemctl --user restart plasma-plasmashell.service &
            echo "✅ Plasma Shell restart initiated"
            echo "   Desktop will reload in a few seconds..."
        else
            if command -v kquitapp6 >/dev/null 2>&1; then
                echo "Using kquitapp6 (systemctl not available)..."
                (kquitapp6 plasmashell && sleep 2 && plasmashell) >/dev/null 2>&1 &
                echo "✅ Plasma Shell restart initiated"
                echo "   Desktop will reload in a few seconds..."
            else
                echo "❌ Cannot restart automatically"
                echo "Please restart manually:"
                echo "  systemctl --user restart plasma-plasmashell.service"
            fi
        fi
        ;;
    *)
        echo ""
        echo "Invalid choice. To restart manually:"
        echo "  systemctl --user restart plasma-plasmashell.service"
        ;;
esac

echo ""
echo "After Plasma Shell restarts:"
echo "  1. Right-click panel → Add Widgets"
echo "  2. Search 'DevToolbox Cheats'"
echo "  3. Add to panel or desktop"
echo "  4. Right-click widget → Configure"
echo "     - You'll see editor dropdown with auto-detected editors!"
echo "     - Widget auto-falls back if configured editor is missing"
echo ""
