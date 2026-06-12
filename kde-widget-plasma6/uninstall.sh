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

# --- 4. Restart Plasma Shell (SAFE METHOD) ---
echo "🔄 Plasma Shell needs to restart to complete removal."
echo ""
echo "Choose restart method:"
echo "  1. Restart manually (safest - recommended for VMs)"
echo "  2. Automatic restart (tries systemctl then kquitapp6)"
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
        echo "Option B (kquitapp6):"
        echo "  kquitapp6 plasmashell && sleep 2 && plasmashell &"
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
echo "To also remove data files, run:"
echo "  rm -rf ~/cheats.d ~/.cache/devtoolbox-cheats*"
echo ""
