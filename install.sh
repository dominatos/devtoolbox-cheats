#!/bin/bash
set -e

echo "📦 Installing dependencies..."
# Dependencies used by argos script + KDE widget:
#   fzf        – fuzzy finder (search feature)
#   bat        – syntax-highlighted preview in fzf (optional, falls back to cat)
#   zenity     – GUI dialogs (argos standalone mode)
#   wl-clipboard – Wayland clipboard (wl-copy / wl-paste)
#   xclip      – X11 clipboard fallback
#   libnotify  – notify-send desktop notifications
#   fontconfig – fc-cache for font rebuilding
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Argos / GNOME detection ────────────────────────────────────────────────
# Argos is detected if the ~/.config/argos directory exists OR the argos
# gnome-shell extension is loaded (pgrep looks for the extension helper).
install_argos() {
    local argos_dir="$HOME/.config/argos"
    local script_src="$SCRIPT_DIR/devtoolbox-cheats.30s.sh"
    local cheats_src="$SCRIPT_DIR/cheats.d"

    echo "🐚 Installing Argos variant..."
    mkdir -p "$argos_dir"

    if [ -f "$script_src" ]; then
        cp "$script_src" "$argos_dir/"
        chmod +x "$argos_dir/devtoolbox-cheats.30s.sh"
        echo "  ✅ Script installed → $argos_dir/devtoolbox-cheats.30s.sh"
    else
        echo "  ⚠️  Script not found: $script_src"
    fi

    if [ -d "$cheats_src" ]; then
        mkdir -p "$HOME/cheats.d"
        cp -r "$cheats_src/." "$HOME/cheats.d/"
        echo "  ✅ Cheats deployed → ~/cheats.d"
    else
        echo "  ⚠️  cheats.d not found: $cheats_src"
    fi

    echo "  ℹ️  Restart Argos (or toggle the extension) to reload the menu."
}

is_argos_present() {
    # Argos config dir already exists
    [ -d "$HOME/.config/argos" ] && return 0
    # Argos extension is listed as enabled
    if command -v gnome-extensions &>/dev/null; then
        gnome-extensions list --enabled 2>/dev/null | grep -qi argos && return 0
    fi
    return 1
}

# ─── DE routing ─────────────────────────────────────────────────────────────
INSTALLED=0

if is_argos_present; then
    echo "✅ Detected GNOME + Argos"
    install_argos
    INSTALLED=1
fi

echo ""
echo "🔍 Detecting KDE Plasma version..."

if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "✅ Detected Plasma 6"
    echo "📂 Using kde-widget-plasma6..."
    cd "$SCRIPT_DIR/kde-widget-plasma6" && ./install.sh
    INSTALLED=1
elif command -v kpackagetool5 >/dev/null 2>&1; then
    echo "✅ Detected Plasma 5"
    echo "📂 Using kde-widget-plasma5..."
    cd "$SCRIPT_DIR/kde-widget-plasma5" && ./install.sh
    INSTALLED=1
fi

if [ "$INSTALLED" -eq 0 ]; then
    echo ""
    echo "❌ Could not detect a supported environment."
    echo "   Supported: KDE Plasma 5/6 (kpackagetool), GNOME + Argos (~/.config/argos)"
    exit 1
fi
