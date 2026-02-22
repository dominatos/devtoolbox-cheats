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

# Force-remove directories regardless
rm -rf "$INSTALL_DIR" 2>/dev/null || true
rm -rf "$HOME/.local/share/kpackage/generic/$PKG_ID" 2>/dev/null || true

# --- 3. Clear QML cache (critical — Plasma caches old QML!) ---
echo "→ Clearing QML cache..."
rm -rf "$HOME/.cache/plasmashell/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/plasma-plasmashell/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/qt6/qmlcache" 2>/dev/null || true
rm -rf "$HOME/.cache/qmlcache" 2>/dev/null || true
find "$HOME/.cache" -name "*.qmlc" -path "*devtoolbox*" -delete 2>/dev/null || true
find "$HOME/.cache" -name "*.jsc" -path "*devtoolbox*" -delete 2>/dev/null || true

# --- 4. Install widget ---
echo "→ Installing widget..."
if command -v kpackagetool6 >/dev/null 2>&1; then
    if ! kpackagetool6 --type Plasma/Applet --install "$PKG_DIR" 2>&1; then
        echo "  kpackagetool6 --install failed, trying --upgrade..."
        kpackagetool6 --type Plasma/Applet --upgrade "$PKG_DIR" 2>&1 || true
    fi
else
    # Manual install fallback: just copy files
    echo "  ⚠️  kpackagetool6 not found — doing manual copy install"
    mkdir -p "$INSTALL_DIR"
    cp -r "$PKG_DIR"/* "$INSTALL_DIR/"
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
        mkdir -p "$INSTALL_DIR"
        cp -r "$PKG_DIR"/* "$INSTALL_DIR/"
        echo "✅ Manual install done: $INSTALL_DIR"
    fi
fi

# --- 5. Deploy cheatsheets ---
echo ""
echo "→ Deploying cheatsheets..."
if [ -d "$SCRIPT_DIR/../cheats.d" ]; then
    mkdir -p "$HOME/cheats.d"
    cp -r "$SCRIPT_DIR/../cheats.d"/* "$HOME/cheats.d/"
    CHEAT_COUNT=$(find "$HOME/cheats.d" -name "*.md" | wc -l)
    echo "✅ Deployed $CHEAT_COUNT cheatsheets to ~/cheats.d"
else
    echo "⚠️  cheats.d source not found at $SCRIPT_DIR/../cheats.d — skipping"
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
echo "🔄 Plasma Shell needs to restart for the widget to appear."
echo ""
echo "Choose restart method:"
echo "  1. Restart manually (safest - recommended for VMs)"
echo "  2. Automatic restart (tries systemctl then kquitapp6)"
echo ""
read -p "Enter choice [1-2]: " RESTART_CHOICE

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
echo ""
