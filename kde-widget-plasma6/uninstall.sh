#!/bin/bash
set -e

echo "🗑️ Uninstalling DevToolbox Cheats Widget..."

PKG="com.dominatos.devtoolboxcheats"

if command -v kpackagetool6 >/dev/null 2>&1; then
    TOOL="kpackagetool6"
    echo "Detected Plasma 6"
else
    echo "❌ Error: kpackagetool6 not found. Are you running KDE Plasma 6?"
    exit 1
fi

echo "Removing widget..."
if $TOOL --type Plasma/Applet --list | grep -q "$PKG"; then
    $TOOL --type Plasma/Applet --remove "$PKG"
    echo "✅ Widget removed successfully."
else
    echo "ℹ️ Widget not found in Plasma. It might already be uninstalled."
fi

# Cleanup options
echo ""
read -p "❓ Do you want to remove the cheats directory (~/cheats.d)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/cheats.d"
    echo "✅ Removed ~/cheats.d"
fi

read -p "❓ Do you want to remove the cache file (~/.cache/devtoolbox-cheats.json)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$HOME/.cache/devtoolbox-cheats.json"
    echo "✅ Removed ~/.cache/devtoolbox-cheats.json"
fi

echo "✅ Uninstallation complete!"

read -p "❓ Do you want to restart Plasma now to immediately apply changes? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Restarting Plasma..."
    systemctl --user restart plasma-plasmashell.service
else
    echo "You may need to restart Plasma to see the changes:"
    echo "  systemctl --user restart plasma-plasmashell.service"
fi
