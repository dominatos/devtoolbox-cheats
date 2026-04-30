#!/bin/bash
# Debug script for DevToolbox Cheats Plasma 6 Widget

echo "===================================="
echo "DevToolbox Cheats Widget Debug Tool"
echo "===================================="
echo ""

# Enable QML debug logging
echo "→ Enabling QML debug logging..."
mkdir -p ~/.config/QtProject
cat > ~/.config/QtProject/qtlogging.ini <<EOF
[Rules]
qml.debug=true
EOF
echo "✅ QML debugging enabled"
echo ""

# Check if cheats directory exists
echo "→ Checking cheats directory..."
CHEATS_DIR="$HOME/cheats.d"
if [ -d "$CHEATS_DIR" ]; then
    CHEAT_COUNT=$(find "$CHEATS_DIR" -name "*.md" 2>/dev/null | wc -l)
    echo "✅ Found $CHEATS_DIR with $CHEAT_COUNT .md files"
    
    if [ $CHEAT_COUNT -eq 0 ]; then
        echo "⚠️  WARNING: No .md files found in $CHEATS_DIR"
        echo "   You need to install cheatsheets first!"
    else
        echo "   Sample files:"
        find "$CHEATS_DIR" -name "*.md" | head -3
    fi
else
    echo "❌ ERROR: $CHEATS_DIR does not exist!"
    echo "   Run the install script to deploy cheatsheets:"
    echo "   cd kde-widget-plasma6 && ./install.sh"
    exit 1
fi
echo ""

# Check if widget is installed
echo "→ Checking widget installation..."
WIDGET_ID="com.dominatos.devtoolboxcheats"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"

if [ -d "$INSTALL_DIR" ]; then
    echo "✅ Widget installed at: $INSTALL_DIR"
    
    # Check if indexer.sh exists and is executable
    INDEXER="$INSTALL_DIR/contents/code/indexer.sh"
    if [ -f "$INDEXER" ]; then
        echo "✅ Indexer script found: $INDEXER"
        if [ -x "$INDEXER" ]; then
            echo "✅ Indexer is executable"
        else
            echo "⚠️  Making indexer executable..."
            chmod +x "$INDEXER"
            echo "✅ Indexer permissions fixed"
        fi
    else
        echo "❌ ERROR: Indexer script not found at $INDEXER"
        exit 1
    fi
else
    echo "❌ ERROR: Widget not installed at $INSTALL_DIR"
    echo "   Run the install script:"
    echo "   cd kde-widget-plasma6 && ./install.sh"
    exit 1
fi
echo ""

# Test the indexer script directly
echo "→ Testing indexer script directly..."
DEBUG_LOG="/tmp/devtoolbox-debug-test.log"
echo "Running: bash \"$INDEXER\" \"$CHEATS_DIR\" \"$DEBUG_LOG\""
OUTPUT=$(bash "$INDEXER" "$CHEATS_DIR" "$DEBUG_LOG" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    LINE_COUNT=$(echo "$OUTPUT" | wc -l)
    PIPE_COUNT=$(echo "$OUTPUT" | grep -c '|')
    
    echo "✅ Indexer ran successfully"
    echo "   Exit code: $EXIT_CODE"
    echo "   Output lines: $LINE_COUNT"
    echo "   Lines with pipes: $PIPE_COUNT"
    
    if [ $PIPE_COUNT -gt 0 ]; then
        echo "   Sample output (first 3 lines):"
        echo "$OUTPUT" | head -3 | sed 's/^/   /'
    else
        echo "⚠️  WARNING: No pipe characters found in output!"
        echo "   This means the indexer is not finding/parsing cheats correctly"
        echo "   Full output:"
        echo "$OUTPUT" | sed 's/^/   /'
    fi
    
    if [ -f "$DEBUG_LOG" ]; then
        echo ""
        echo "   Debug log contents:"
        head -10 "$DEBUG_LOG" | sed 's/^/   /'
    fi
else
    echo "❌ ERROR: Indexer failed with exit code $EXIT_CODE"
    echo "   Output:"
    echo "$OUTPUT" | sed 's/^/   /'
    exit 1
fi
echo ""

# Check widget in plasmoidviewer
echo "→ Testing widget with plasmoidviewer..."
echo "   This will open the widget in a test window."
echo "   Watch the terminal output for [DevToolbox] log messages."
echo ""
echo "   Press Ctrl+C when done testing."
echo ""

if command -v plasmoidviewer >/dev/null 2>&1; then
    echo "Starting plasmoidviewer..."
    QT_LOGGING_RULES="qml.debug=true" plasmoidviewer -a "$WIDGET_ID" 2>&1 | grep -E "\[DevToolbox\]|ERROR|Warning" --color=always
else
    echo "⚠️  plasmoidviewer not found. Skipping interactive test."
    echo "   Install it with: sudo apt install plasma-sdk (or equivalent)"
    echo ""
    echo "   To test in the actual panel, restart plasmashell:"
    echo "   systemctl --user restart plasma-plasmashell.service"
    echo ""
    echo "   Then check logs with:"
    echo "   journalctl --user -f | grep -E '\[DevToolbox\]|devtoolbox'"
fi

echo ""
echo "===================================="
echo "Debug complete!"
echo "===================================="
