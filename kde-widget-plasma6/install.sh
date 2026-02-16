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
echo "✅ Installation complete!"
echo "You can now add 'DevToolbox Cheats' to your panel or desktop."
echo "You may need to logout/login or restart Plasma to see the new widget."
echo "  Restart Plasma:  systemctl --user restart plasma-plasmashell.service"
