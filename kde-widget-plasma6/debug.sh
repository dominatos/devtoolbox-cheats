#!/bin/bash
# Debug script for DevToolbox Cheats Plasma 6 Widget
# Run this BEFORE restarting plasmashell to capture logs
#
# Usage:
#   1. Run:    bash debug.sh
#   2. In another terminal, restart plasma:
#        systemctl --user restart plasma-plasmashell.service
#   3. Try adding/clicking the widget
#   4. Press Ctrl+C to stop logging
#   5. Check the output for [DevToolbox] lines and QML errors

set -e

LOG_FILE="$(dirname "$0")/debug-plasma6.log"

echo "=========================================="
echo " DevToolbox Plasma 6 Widget Debug Logger"
echo "=========================================="
echo ""
echo "Logging to: $LOG_FILE"
echo ""
echo "Step 1: Reinstall widget (if needed)..."

# Try to remove and reinstall
if command -v kpackagetool6 >/dev/null 2>&1; then
    echo "  → Using kpackagetool6"
    kpackagetool6 --type Plasma/Applet --remove com.dominatos.devtoolboxcheats 2>/dev/null || true
    kpackagetool6 --type Plasma/Applet --install "$(dirname "$0")/DevToolboxPlasmoid" 2>&1 || \
    kpackagetool6 --type Plasma/Applet --upgrade "$(dirname "$0")/DevToolboxPlasmoid" 2>&1
    echo "  ✅ Widget installed/upgraded"
else
    echo "  ❌ kpackagetool6 not found! Are you on Plasma 6?"
    exit 1
fi

echo ""
echo "Step 2: Restarting plasmashell and capturing logs..."
echo "  (Widget logs will contain [DevToolbox] prefix)"
echo "  Press Ctrl+C to stop."
echo ""

# Restart plasmashell and capture ALL output
# QT_LOGGING_RULES enables QML debug output
export QT_LOGGING_RULES="*.debug=true;qt.*.debug=false"

# Kill and restart plasmashell, capturing output
systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
sleep 1

echo "--- Debug session started at $(date) ---" > "$LOG_FILE"

# Start plasmashell with debug output, filter for relevant messages
QT_LOGGING_RULES="*.debug=true;qt.*.debug=false" \
  plasmashell 2>&1 | tee -a "$LOG_FILE" | grep --line-buffered -iE "DevToolbox|devtoolboxcheats|Error|Warning|qml|Cannot" || true

echo ""
echo "--- Debug session ended at $(date) ---" >> "$LOG_FILE"
echo "Full log saved to: $LOG_FILE"
