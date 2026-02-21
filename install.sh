#!/bin/bash
set -e

echo "📦 Installing Noto Color Emoji font..."
if command -v apt &>/dev/null; then
    echo "  → Detected apt (Debian/Ubuntu)"
    sudo apt install -y fonts-noto-color-emoji
elif command -v dnf &>/dev/null; then
    echo "  → Detected dnf (RHEL/Rocky/AlmaLinux)"
    sudo dnf install -y google-noto-emoji-color-fonts
elif command -v pacman &>/dev/null; then
    echo "  → Detected pacman (Arch)"
    sudo pacman -S --noconfirm noto-fonts-emoji
else
    echo "  ⚠️  No supported package manager found (apt/dnf/pacman). Skipping emoji font install."
fi

echo "🔍 Detecting Plasma version..."

if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "✅ Detected Plasma 6"
    echo "📂 Using kde-widget-plasma6..."
    cd kde-widget-plasma6 && ./install.sh
elif command -v kpackagetool5 >/dev/null 2>&1; then
    echo "✅ Detected Plasma 5"
    echo "📂 Using kde-widget-plasma5..."
    cd kde-widget-plasma5 && ./install.sh
else
    echo "❌ Error: Could not detect Plasma version (kpackagetool not found)."
    exit 1
fi
