#!/bin/bash
# Force-uninstall DevToolbox Cheats Widget (Plasma 6)

echo "🗑️  Force-uninstalling DevToolbox Cheats Widget..."

PKG="com.dominatos.devtoolboxcheats"

# --- 1. Try kpackagetool6 removal ---
if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "→ Removing via kpackagetool6..."
    kpackagetool6 --type Plasma/Applet --remove "$PKG" 2>&1 || true
else
    echo "⚠️  kpackagetool6 not found, doing manual cleanup only."
fi

# --- 2. Force-remove installed package directories ---
echo "→ Force-removing installed package directories..."
INSTALL_DIRS=(
    "$HOME/.local/share/plasma/plasmoids/$PKG"
    "$HOME/.local/share/kpackage/generic/$PKG"
    "$HOME/.local/share/kservices5/$PKG.desktop"
    "$HOME/.local/share/kservices6/$PKG.desktop"
    "$HOME/.local/share/plasma5/plasmoids/$PKG"
)
for d in "${INSTALL_DIRS[@]}"; do
    if [ -e "$d" ]; then
        rm -rf "$d"
        echo "   ✅ Removed: $d"
    fi
done

# --- 3. Clear QML cache to prevent stale code from running ---
echo "→ Clearing QML cache..."
QML_CACHE_DIRS=(
    "$HOME/.cache/plasmashell/qmlcache"
    "$HOME/.cache/plasma-plasmashell/qmlcache"
    "$HOME/.cache/qt6/qmlcache"
    "$HOME/.cache/qmlcache"
)
for d in "${QML_CACHE_DIRS[@]}"; do
    if [ -d "$d" ]; then
        rm -rf "$d"
        echo "   ✅ Cleared: $d"
    fi
done
# Also nuke any qmlc files related to our widget
find "$HOME/.cache" -name "*.qmlc" -path "*devtoolbox*" -delete 2>/dev/null || true
find "$HOME/.cache" -name "*.jsc" -path "*devtoolbox*" -delete 2>/dev/null || true

echo ""
echo "✅ Widget uninstalled and caches cleared."
echo ""
echo "To also remove data files, run:"
echo "  rm -rf ~/cheats.d ~/.cache/devtoolbox-cheats.json ~/.cache/devtoolbox-cheats-debug.log"
echo ""
echo "Restart Plasma to apply:"
echo "  systemctl --user restart plasma-plasmashell.service"
