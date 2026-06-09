#!/usr/bin/env bash
# install-dev.sh — Interactive Argos script installer for devtoolbox-cheats
# Asks the user which Argos variant to install, with a 30s timeout that
# auto-selects the default (standard) variant if no input is given.
# coded by Sviatoslav https://github.com/dominatos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOS_DIR="$HOME/.config/argos"
TIMEOUT=30

# ─── Variant definitions ──────────────────────────────────────────────────────
# Each entry: SRC_FILE | ARGOS_DEST_NAME | LABEL | DESCRIPTION
# ARGOS_DEST_NAME must follow Argos convention: <name>.<interval>.sh
VARIANTS=(
  "devtoolbox-cheats.30s.sh|devtoolbox-cheats.30s.sh|1) Standard (default)|Categories expand inline in the Argos panel menu with all cheats listed as sub-items. Fastest to browse, no extra windows."
  "devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh|devtoolbox-cheats-zenity.30s.sh|2) Zenity cheat list (DEV)|Categories shown at root level. Clicking a category opens a Zenity dialog window listing that category's cheats. Useful on small screens or when you prefer a separate window."
  "devtoolbox-cheats.30s-separate-menu-DEV.sh|devtoolbox-cheats-drilldown.30s.sh|3) Separate drill-down menu (DEV)|Drill-down navigation with per-category Argos output cache. Clicking a category re-renders the Argos menu to show only that category's cheats inline. State expires after 60s."
)

DEFAULT_VARIANT=0   # index into VARIANTS array (0-based)

# ─── Helpers ─────────────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║        DevToolbox Cheats — Argos Script Installer           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

print_variants() {
  local i=0
  for entry in "${VARIANTS[@]}"; do
    local _src _dest label desc
    IFS='|' read -r _src _dest label desc <<< "$entry"
    if [[ $i -eq $DEFAULT_VARIANT ]]; then
      echo "  ★ ${label}  ← DEFAULT"
    else
      echo "    ${label}"
    fi
    echo "      ${desc}"
    echo ""
    (( i++ )) || true
  done
  echo "    4) Install all 3 (try & compare)"
  echo "      All three variants are installed under distinct filenames."
  echo "      Each appears as a separate icon in the Argos panel."
  echo "      Remove whichever you don't want afterwards (instructions shown after install)."
  echo ""
}

# Read a single character with a countdown timer.
# Prints the countdown on the same line; clears it when done.
# Returns the raw character in $REPLY, or empty string on timeout.
read_with_timeout() {
  local prompt="$1" timeout="$2"
  local remaining="$timeout" key=""

  tput sc 2>/dev/null || true

  while (( remaining > 0 )); do
    printf "\r  %s (auto-selects default in %2ds): " "$prompt" "$remaining"
    if IFS= read -r -s -n1 -t1 key 2>/dev/null; then
      printf "\r%-72s\r" " "
      REPLY="$key"
      return 0
    fi
    (( remaining-- )) || true
  done

  printf "\r%-72s\r" " "
  REPLY=""
  return 0
}

# Install a single variant to a specific destination name.
# Args: <src_file> <dest_name>
install_one() {
  local src_file="$1" dest_name="$2"
  local src_path="$SCRIPT_DIR/${src_file}"
  local dest_path="$ARGOS_DIR/${dest_name}"

  if [[ ! -f "$src_path" ]]; then
    echo "  ✖  Source not found: $src_path"
    echo "     Make sure you are running this from the devtoolbox-cheats directory."
    return 1
  fi

  mkdir -p "$ARGOS_DIR"
  cp "$src_path" "$dest_path"
  chmod +x "$dest_path"
  echo "  ✅ $dest_name"
}

# Install a single chosen variant (options 1-3).
install_single() {
  local src_file="$1" dest_name="$2" label="$3"
  echo ""
  echo "🐚 Installing: ${label}"
  install_one "$src_file" "$dest_name"
  echo "  ℹ️  Restart Argos (or toggle the extension) to reload the menu."
  echo ""
  echo "  Source file : $SCRIPT_DIR/${src_file}"
  echo "  Installed   : $ARGOS_DIR/${dest_name}"
}

# Install all 3 variants with their distinct Argos filenames.
install_all() {
  echo ""
  echo "🐚 Installing all 3 variants..."
  echo ""

  for entry in "${VARIANTS[@]}"; do
    local src dest _label _desc
    IFS='|' read -r src dest _label _desc <<< "$entry"
    install_one "$src" "$dest"
  done

  echo ""
  echo "  ℹ️  Restart Argos (or toggle the extension) to see all three icons."
  echo ""
  echo "──────────────────────────────────────────────────────────────────"
  echo "  📂 All scripts installed into: $ARGOS_DIR/"
  echo ""
  echo "  Files installed:"
  for entry in "${VARIANTS[@]}"; do
    local _src dest label _desc
    IFS='|' read -r _src dest label _desc <<< "$entry"
    printf "    %-42s  %s\n" "$dest" "$label"
  done
  echo ""
  echo "  🗑  To remove a variant you don't want:"
  echo ""
  echo "    Standard (default):"
  echo "      rm ~/.config/argos/devtoolbox-cheats.30s.sh"
  echo ""
  echo "    Zenity cheat list (DEV):"
  echo "      rm ~/.config/argos/devtoolbox-cheats-zenity.30s.sh"
  echo ""
  echo "    Separate drill-down menu (DEV):"
  echo "      rm ~/.config/argos/devtoolbox-cheats-drilldown.30s.sh"
  echo ""
  echo "  After removing a file, Argos removes its icon automatically"
  echo "  (no restart needed — it just disappears on the next 30s refresh)."
  echo "──────────────────────────────────────────────────────────────────"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

print_header

echo "  Choose which Argos variant to install into ~/.config/argos/:"
echo ""

print_variants

# Wait for user input with countdown
read_with_timeout "Enter choice [1/2/3/4]" "$TIMEOUT"
choice="$REPLY"

# Dispatch
case "$choice" in
  "1") selected=0 ;;
  "2") selected=1 ;;
  "3") selected=2 ;;
  "4")
    install_all
    echo "  Done. 🎉"
    echo ""
    exit 0
    ;;
  "")
    echo "  ⏱  Timeout — installing default."
    selected=$DEFAULT_VARIANT
    ;;
  *)
    echo "  ⚠️  Unrecognised input '${choice}' — installing default."
    selected=$DEFAULT_VARIANT
    ;;
esac

# Single variant install
IFS='|' read -r sel_file sel_dest sel_label _sel_desc <<< "${VARIANTS[$selected]}"

echo "  → Selected: ${sel_label}"

install_single "$sel_file" "$sel_dest" "$sel_label"

echo "  Done. 🎉"
echo ""
