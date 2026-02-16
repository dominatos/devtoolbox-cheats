#!/bin/bash
set -e

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
