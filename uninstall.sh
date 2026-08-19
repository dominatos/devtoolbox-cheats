#!/bin/bash
set -euo pipefail

VERSION="v1.5.4"

print_header() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║     DevToolbox Cheats — Uninstaller                         ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "($VERSION)"
  echo ""
}
print_header

removed=0

remove_file() {
  local f="$1"
  if [[ -f "$f" || -L "$f" ]]; then
    if rm -f "$f" 2>/dev/null; then
      echo "  ✓ $f"
      ((removed++)) || true
    else
      echo "  ✗ failed to remove: $f"
    fi
  fi
}

remove_dir() {
  local d="$1"
  if [[ -d "$d" ]]; then
    if rm -rf "$d" 2>/dev/null; then
      echo "  ✓ $d/"
      ((removed++)) || true
    else
      echo "  ✗ failed to remove: $d/"
    fi
  fi
}

# --- Systemd timer ---
echo "⏱️  Stopping systemd timer..."
systemctl --user stop devtoolbox-cheats-updater.timer 2>/dev/null || true
systemctl --user disable devtoolbox-cheats-updater.timer 2>/dev/null || true
remove_file "$HOME/.config/systemd/user/devtoolbox-cheats-updater.service"
remove_file "$HOME/.config/systemd/user/devtoolbox-cheats-updater.timer"

# --- Binaries ---
echo "📦 Removing scripts..."
remove_file "$HOME/.local/bin/devtoolbox-cheats-menu"
remove_file "$HOME/.local/bin/cheats-updater"

# --- Desktop integration ---
echo "🖥️  Removing desktop entries..."
remove_file "$HOME/.local/share/applications/devtoolbox-cheats.desktop"
remove_file "$HOME/.local/share/icons/devtoolbox-cheats.png"

# --- Argos / GNOME extension ---
echo "🐚 Removing Argos scripts..."
remove_file "$HOME/.config/argos/devtoolbox-cheats.30s.sh"
remove_file "$HOME/.config/argos/devtools.1m.sh"

# --- KDE widget ---
echo "🔧 Removing KDE widget..."
if command -v kpackagetool6 &>/dev/null; then
  kpackagetool6 -t Plasma/Applet -r com.dominatos.devtoolboxcheats 2>/dev/null || true
elif command -v kpackagetool5 &>/dev/null; then
  kpackagetool5 --type Plasma/Applet -r com.dominatos.devtoolboxcheats 2>/dev/null || true
fi
remove_dir "$HOME/.local/share/plasma/plasmoids/com.dominatos.devtoolboxcheats"

# --- Data and config directories ---
echo "📂 Removing data directories..."
remove_dir "$HOME/.local/share/devtoolbox-cheats"
remove_dir "$HOME/.config/devtoolbox-cheats"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ Uninstalled $removed item(s)"
echo "  ℹ️  ~/cheats.d/ was NOT removed (your cheat sheets are safe)"
echo "═══════════════════════════════════════════════════════════════"
