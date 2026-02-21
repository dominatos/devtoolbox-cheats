#!/bin/bash
set -e

echo "📦 Installing DevToolbox Cheats Widget..."

PKG="DevToolboxPlasmoid"

if command -v kpackagetool6 >/dev/null 2>&1; then
    TOOL="kpackagetool6"
    echo "Detected Plasma 6"
else
    echo "❌ Error: kpackagetool6 not found. Are you running KDE Plasma 6?"
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
    $TOOL --type Plasma/Applet --remove com.dominatos.devtoolboxcheats || true
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
echo "You can now add 'DevToolbox Cheats' to your panel or desktop."
echo "You may need to logout/login or restart Plasma to see the new widget."
echo "  Restart Plasma:  systemctl --user restart plasma-plasmashell.service"
