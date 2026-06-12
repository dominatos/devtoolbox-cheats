#!/bin/bash
set -e

echo "📦 Installing DevToolbox Cheats Widget..."

PKG="DevToolboxPlasmoid"

if command -v kpackagetool5 >/dev/null 2>&1; then
    TOOL="kpackagetool5"
    echo "Detected Plasma 5"
else
    echo "❌ Error: kpackagetool5 not found. Are you running KDE Plasma 5?"
    exit 1
fi

# Clean up deprecated metadata.desktop to avoid warnings/errors
if [ -f "$PKG/metadata.desktop" ]; then
    echo "🧹 Removing deprecated metadata.desktop..."
    rm "$PKG/metadata.desktop"
fi

# Upgrade logic (clean removal before install)
if $TOOL --type Plasma/Applet --list | grep -q "com.dominatos.devtoolboxcheats"; then
    echo "🔄 Found existing widget, removing before re-installation..."
    $TOOL --type Plasma/Applet --remove com.dominatos.devtoolboxcheats
fi
$TOOL --type Plasma/Applet --install "$PKG"


echo ""
echo "📂 Deploying cheatsheets into ~/cheats.d..."
if [ -d "../cheats.d" ]; then
    mkdir -p "$HOME/cheats.d"
    cp -r ../cheats.d/* "$HOME/cheats.d/"
    echo "✅ Cheatsheets deployed to $HOME/cheats.d"
else
    echo "⚠️ Warning: cheats.d source not found (looked in ../cheats.d). Skipping deployment."
fi

echo ""
echo "📦 Installing dependencies..."
# fzf, bat, zenity, wl-clipboard, xclip, libnotify, fontconfig
if command -v apt &>/dev/null; then
    echo "  → Detected apt (Debian/Ubuntu)"
    sudo apt install -y \
        fonts-noto-color-emoji \
        fzf bat \
        zenity \
        wl-clipboard xclip \
        libnotify-bin \
        fontconfig
elif command -v dnf &>/dev/null; then
    echo "  → Detected dnf (RHEL/Rocky/AlmaLinux)"
    sudo dnf install -y \
        google-noto-emoji-color-fonts \
        fzf bat \
        zenity \
        wl-clipboard xclip \
        libnotify \
        fontconfig
elif command -v pacman &>/dev/null; then
    echo "  → Detected pacman (Arch)"
    sudo pacman -S --noconfirm \
        noto-fonts-emoji \
        fzf bat \
        zenity \
        wl-clipboard xclip \
        libnotify \
        fontconfig
else
    echo "  ⚠️  No supported package manager found (apt/dnf/pacman)."
    echo "     Please install manually: fzf bat zenity wl-clipboard xclip libnotify fontconfig"
fi

echo ""
echo "🔤 Refreshing font cache..."
fc-cache -f -v

echo ""
echo "✅ Installation complete!"
echo "============================================"
echo ""
echo "🔄 Plasma Shell needs to restart for changes to take effect."
echo "   (This ensures config page shows correctly!)"
echo ""
echo "Choose restart method:"
echo "  1. Restart manually (safest - recommended for VMs)"
echo "  2. Automatic restart (tries systemctl then kquitapp5)"
echo ""
read -rp "Enter choice [1-2]: " RESTART_CHOICE

case "$RESTART_CHOICE" in
    1)
        echo ""
        echo "Manual restart commands (choose one):"
        echo ""
        echo "Option A (systemctl):"
        echo "  systemctl --user restart plasma-plasmashell.service"
        echo ""
        echo "Option B (kquitapp5):"
        echo "  kquitapp5 plasmashell && sleep 2 && plasmashell &"
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
            if command -v kquitapp5 >/dev/null 2>&1; then
                echo "Using kquitapp5 (systemctl not available)..."
                (kquitapp5 plasmashell && sleep 2 && plasmashell) >/dev/null 2>&1 &
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
