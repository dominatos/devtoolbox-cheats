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

# ─── Argos / GNOME detection ─────────────────────────────────────────────────
# Argos is detected if the ~/.config/argos directory exists OR the argos
# gnome-shell extension is loaded.
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

# ─── Desktop Environment detection ───────────────────────────────────────────
# Returns a normalised lowercase DE name:
#   gnome | kde | xfce | mate | cinnamon | lxqt | lxde |
#   budgie | pantheon | deepin | cosmic | tiling | unknown
detect_de() {
    local de
    de="${XDG_CURRENT_DESKTOP:-}"
    de="${de,,}"   # lowercase

    # Strip composited names like "ubuntu:GNOME" → check substrings
    case "$de" in
        *gnome*)    echo "gnome";    return ;;
        *kde*)      echo "kde";      return ;;
        *plasma*)   echo "kde";      return ;;
        *xfce*)     echo "xfce";     return ;;
        *mate*)     echo "mate";     return ;;
        *cinnamon*) echo "cinnamon"; return ;;
        *lxqt*)     echo "lxqt";     return ;;
        *lxde*)     echo "lxde";     return ;;
        *budgie*)   echo "budgie";   return ;;
        *pantheon*) echo "pantheon"; return ;;
        *deepin*)   echo "deepin";   return ;;
        *cosmic*)   echo "cosmic";   return ;;
    esac

    # Fallback: DESKTOP_SESSION
    local ds
    ds="${DESKTOP_SESSION:-}"
    ds="${ds,,}"
    case "$ds" in
        *gnome*)    echo "gnome";    return ;;
        *plasma*)   echo "kde";      return ;;
        *xfce*)     echo "xfce";     return ;;
        *mate*)     echo "mate";     return ;;
        *cinnamon*) echo "cinnamon"; return ;;
        *lxqt*)     echo "lxqt";     return ;;
        *lxde*)     echo "lxde";     return ;;
        *budgie*)   echo "budgie";   return ;;
    esac

    # Fallback: check running processes
    if pgrep -x "xfce4-session" &>/dev/null;  then echo "xfce";     return; fi
    if pgrep -x "mate-session" &>/dev/null;   then echo "mate";     return; fi
    if pgrep -x "cinnamon" &>/dev/null;       then echo "cinnamon"; return; fi
    if pgrep -x "lxqt-session" &>/dev/null;  then echo "lxqt";     return; fi
    if pgrep -x "lxsession" &>/dev/null;     then echo "lxde";     return; fi
    if pgrep -x "budgie-daemon" &>/dev/null; then echo "budgie";   return; fi
    if pgrep -x "io.elementary.wingpanel" &>/dev/null; then echo "pantheon"; return; fi
    if pgrep -x "dde-desktop" &>/dev/null;   then echo "deepin";   return; fi
    if pgrep -x "cosmic-session" &>/dev/null; then echo "cosmic";  return; fi
    # Tiling / standalone WMs
    for wm in i3 sway bspwm openbox fluxbox awesome dwm herbstluftwm river wayfire; do
        if pgrep -x "$wm" &>/dev/null; then echo "tiling"; return; fi
    done

    echo "unknown"
}

# ─── Per-DE widget installation guide ────────────────────────────────────────
print_de_instructions() {
    local de="$1"
    local script_path="$SCRIPT_DIR/devtoolbox-cheats.30s.sh"
    local icon_path="$SCRIPT_DIR/docs/img/icons8-test-cheating-48.png"

    echo ""
    echo "──────────────────────────────────────────────────────────"
    echo "  📋 How to add DevToolbox Cheats to your panel / launcher"
    echo "──────────────────────────────────────────────────────────"
    echo "  Script path : $script_path"
    echo "  Icon path   : $icon_path"
    echo ""

    case "$de" in
        xfce)
            echo "  🟢 XFCE — Genmon plugin"
            echo "  1. Install plugin:  sudo apt install xfce4-genmon-plugin"
            echo "  2. Right-click panel → Add New Items → 'Generic Monitor'"
            echo "  3. Right-click the monitor → Properties:"
            echo "       Command : $script_path menu"
            echo "       Period  : 30"
            ;;
        mate)
            echo "  🟢 MATE — Custom Application Launcher"
            echo "  1. Right-click panel → 'Add to Panel…'"
            echo "  2. Select 'Custom Application Launcher' → Add"
            echo "  3. Set:"
            echo "       Type    : Application"
            echo "       Name    : DevToolbox Cheats"
            echo "       Command : bash -c '$script_path menu'"
            echo "       Icon    : $icon_path"
            ;;
        cinnamon)
            echo "  🟢 Cinnamon — Menu launcher"
            echo "  1. Right-click Menu applet → Configure → 'Open the menu editor'"
            echo "  2. Select a category → 'New Item'"
            echo "  3. Set:"
            echo "       Name    : DevToolbox Cheats"
            echo "       Command : bash -c '$script_path menu'"
            echo "       Icon    : $icon_path"
            echo "  4. Save, then find 'DevToolbox Cheats' in the menu,"
            echo "     right-click it → 'Add to panel'."
            ;;
        lxqt)
            echo "  🟣 LXQt — Custom command widget"
            echo "  1. Right-click panel → 'Manage Widgets' → 'Add Widgets'"
            echo "  2. Select 'Custom command' → Add"
            echo "  3. Right-click the widget → Configure:"
            echo "       Command       : $script_path menu"
            echo "       Click command : $script_path menu"
            echo "       Icon          : $icon_path"
            ;;
        lxde)
            echo "  🟣 LXDE — Application Launch Bar"
            echo "  1. Right-click panel → 'Add / Remove Panel Items'"
            echo "  2. Select 'Application Launch Bar' → Add → Preferences"
            echo "  3. Click '+' and set:"
            echo "       Command : bash -c '$script_path menu'"
            echo "  Or create a desktop shortcut:"
            cat <<EOF
     cat > ~/Desktop/DevToolbox-Cheats.desktop <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DevToolbox Cheats
Comment=Quick access to command cheatsheets
Exec=bash -c '$script_path menu'
Icon=$icon_path
Terminal=false
Categories=Utility;
DESK
     chmod +x ~/Desktop/DevToolbox-Cheats.desktop
EOF
            ;;
        budgie)
            echo "  🟡 Budgie — Application launcher"
            echo "  1. Create a .desktop entry:"
            echo "     mkdir -p ~/.local/share/applications"
            cat <<EOF
     cat > ~/.local/share/applications/devtoolbox-cheats.desktop <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DevToolbox Cheats
Comment=Quick access to command cheatsheets
Exec=bash -c '$script_path menu'
Icon=$icon_path
Terminal=false
Categories=Utility;Development;
DESK
     chmod +x ~/.local/share/applications/devtoolbox-cheats.desktop
EOF
            echo "  2. Open Budgie Menu, search 'DevToolbox', drag to Favorites or panel."
            ;;
        pantheon)
            echo "  🔷 Pantheon (elementary OS) — Application launcher"
            echo "  1. Create a .desktop entry:"
            cat <<EOF
     mkdir -p ~/.local/share/applications
     cat > ~/.local/share/applications/devtoolbox-cheats.desktop <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DevToolbox Cheats
Comment=Quick access to command cheatsheets
Exec=bash -c '$script_path menu'
Icon=$icon_path
Terminal=false
Categories=Utility;Development;
Keywords=cheat;cheatsheet;command;reference;
DESK
     chmod +x ~/.local/share/applications/devtoolbox-cheats.desktop
EOF
            echo "  2. Press Super to open Applications, search 'DevToolbox Cheats',"
            echo "     right-click → 'Add to Dock'."
            ;;
        deepin)
            echo "  🔵 Deepin — Application launcher"
            echo "  1. Create a .desktop entry:"
            cat <<EOF
     mkdir -p ~/.local/share/applications
     cat > ~/.local/share/applications/devtoolbox-cheats.desktop <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DevToolbox Cheats
Comment=Quick access to command cheatsheets
Exec=bash -c '$script_path menu'
Icon=$icon_path
Terminal=false
Categories=Utility;Development;
DESK
     chmod +x ~/.local/share/applications/devtoolbox-cheats.desktop
EOF
            echo "  2. Open Launcher, find 'DevToolbox Cheats',"
            echo "     right-click → 'Send to Desktop' or 'Pin to Dock'."
            ;;
        cosmic)
            echo "  🚀 Cosmic (Pop!_OS) — Launcher"
            echo "  1. Create a .desktop entry:"
            cat <<EOF
     mkdir -p ~/.local/share/applications
     cat > ~/.local/share/applications/devtoolbox-cheats.desktop <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=DevToolbox Cheats
Comment=Quick access to command cheatsheets
Exec=bash -c '$script_path menu'
Icon=$icon_path
Terminal=false
Categories=Utility;Development;
DESK
     chmod +x ~/.local/share/applications/devtoolbox-cheats.desktop
EOF
            echo "  2. Press Super+/ to open Cosmic Launcher, search 'DevToolbox Cheats',"
            echo "     right-click → 'Pin to Dock'."
            echo "  Or add a keyboard shortcut:"
            echo "     Settings → Keyboard → Custom Shortcuts → '+'"
            echo "       Name    : DevToolbox Cheats"
            echo "       Command : bash -c '$script_path menu'"
            ;;
        tiling)
            echo "  ⚫ Tiling WM — keybinding"
            echo ""
            echo "  Add one of the following to your WM config:"
            echo ""
            echo "  i3   (~/.config/i3/config):"
            echo "    bindsym \$mod+c exec --no-startup-id $script_path menu"
            echo ""
            echo "  sway (~/.config/sway/config):"
            echo "    bindsym \$mod+c exec $script_path menu"
            echo ""
            echo "  bspwm/sxhkd (~/.config/sxhkd/sxhkdrc):"
            echo "    super + c"
            echo "        $script_path menu"
            echo ""
            echo "  hyprland (~/.config/hypr/hyprland.conf):"
            echo "    bind = SUPER, C, exec, $script_path menu"
            echo ""
            echo "  awesome (~/.config/awesome/rc.lua):"
            echo "    awful.key({ modkey }, 'c',"
            echo "        function () awful.spawn.with_shell('$script_path menu') end,"
            echo "        {description = 'open devtoolbox cheats', group = 'launcher'})"
            ;;
        gnome)
            # GNOME without Argos
            echo "  🟠 GNOME — Argos extension not detected."
            echo "  Install Argos from https://extensions.gnome.org/extension/1176/argos/"
            echo "  or https://github.com/p-e-w/argos, then re-run this installer."
            echo ""
            echo "  Alternatively, add a keyboard shortcut:"
            echo "    Settings → Keyboard → Custom Shortcuts → '+'"
            echo "      Name    : DevToolbox Cheats"
            echo "      Command : bash -c '$script_path menu'"
            ;;
        *)
            echo "  ℹ️  Unknown desktop environment."
            echo "  You can run the script directly from any DE using:"
            echo "    bash -c '$script_path menu'"
            echo ""
            echo "  To add it to a panel or launcher, point the launcher command to:"
            echo "    $script_path menu"
            ;;
    esac

    echo ""
    echo "  📖 Full instructions: https://github.com/dominatos/devtoolbox-cheats#installation"
    echo "──────────────────────────────────────────────────────────"
}

# ─── DE routing ──────────────────────────────────────────────────────────────
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
    echo "ℹ️  KDE Plasma not detected."

    DETECTED_DE="$(detect_de)"
    echo "🖥️  Detected desktop environment: $DETECTED_DE"

    print_de_instructions "$DETECTED_DE"

    echo ""
    echo "   Supported natively: KDE Plasma 5/6 (kpackagetool), GNOME + Argos (~/.config/argos)"
    echo "   For all other DEs, follow the instructions above to add the script as a panel launcher."
    exit 1
fi
