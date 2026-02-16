# 📒 DevToolbox Cheats (Beta) — Universal Linux Cheatsheet Menu

**Cross-DE Beta Version** with support for GNOME, KDE, XFCE, MATE, Cinnamon, and generic Window Managers (i3, sway, etc.)

---

## 🚀 Features (Beta)
- **Universal Menu:** Native Argos menu on GNOME, Dialog menu on other DEs.
- **Cross-DE Support:** Auto-detects your desktop environment.
  - **GNOME:** Integration via [Argos](https://github.com/p-e-w/argos).
  - **KDE Plasma:** Native dialogs via `kdialog` or [Kargos](https://github.com/lipido/kargos).
  - **XFCE / MATE / Cinnamon:** Dialogs via `zenity` or `yad`.
  - **Terminal / WM:** Interactive menu via `fzf` in your preferred terminal.
- **Terminal Detection:** Supports 15+ terminals (Konsole, GNOME Terminal, Alacritty, Kitty, etc.).
- **Smart Fallbacks:** Gracefully degrades from rich GUI -> basic GUI -> terminal interactions.
- **All Original Features:** Search, FZF deep search, PDF export, caching, and clipboard support.

---

## 💻 Supported Environments

| Environment | Menu Type | Interaction | Dependencies |
|-------------|-----------|-------------|--------------|
| **GNOME** | Database (Argos) | Native Panel | `argos` extension |
| **KDE Plasma** | Dialog (Standalone) | kdialog | `kdialog` |
| **XFCE / MATE** | Dialog (Standalone) | zenity | `zenity` |
| **Cinnamon** | Dialog (Standalone) | zenity | `zenity` |
| **I3 / Sway / WM** | Terminal (Standalone) | fzf | `fzf` + `xterm/alacritty/...` |

---

## 📦 Installation

### 1. Requirements (Common)
All users need these base utilities:
```bash
# Debian/Ubuntu
sudo apt install git bash coreutils grep sed awk findutils git

# Fedora/RHEL
sudo dnf install git bash coreutils grep sed gawk findutils git

# Arch Linux
sudo pacman -S git bash coreutils grep sed gawk findutils git
```

### 2. Desktop-Specific Setup

#### 🟠 GNOME (Argos)
1. Install **Argos** extension from [extensions.gnome.org](https://extensions.gnome.org/extension/1176/argos/) or from [github](https://github.com/p-e-w/argos)
2. Install dependencies:
   ```bash
   sudo apt install zenity xclip fzf python3-pip pandoc
   ```
3. Clone and link:
   ```bash
   git clone https://github.com/dominatos/devtoolbox-cheats ~/.config/argos/devtoolbox-cheats
   cd ~/.config/argos
   ln -s devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh .
   ln -s devtoolbox-cheats/cheats.d .
   ```

#### 🔵 KDE Plasma
1. Install dependencies:
   ```bash
   # Debian/Ubuntu
   sudo apt install kdialog wl-clipboard fzf pandoc
   
   # Fedora
   sudo dnf install kdialog wl-clipboard fzf pandoc
   
   # Arch
   sudo pacman -S kdialog wl-clipboard fzf pandoc
   ```
2. Clone repository:
   ```bash
   git clone https://github.com/dominatos/devtoolbox-cheats ~/devtoolbox-cheats
   ```
3. **Usage:** Add a "Command" widget to your panel or run directly:
   ```bash
   ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
   ```

#### 🟢 XFCE / MATE / Cinnamon / LXQt
1. Install dependencies:
   ```bash
   # Debian/Ubuntu
   sudo apt install zenity xclip fzf pandoc
   # (For Wayland sessions, replace xclip with wl-clipboard)
   ```
2. Clone and run:
   ```bash
   git clone https://github.com/dominatos/devtoolbox-cheats ~/devtoolbox-cheats
   ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
   ```
3. **Tip:** Create a `.desktop` launcher in `~/.local/share/applications/` to add it to your start menu.

#### ⚫ Tiling WMs (i3, sway, hyprland)
1. Install dependencies:
   ```bash
   # Dependencies
   sudo apt install fzf xclip pandoc
   # (Use wl-clipboard for Hyprland/Sway)
   ```
2. Run via terminal or keybinding:
   ```bash
   # i3 config example
   bindsym $mod+c exec --no-startup-id ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
   ```

---

## 🧩 System Tray & Panel Integration

You can add this script to your panel to get an "Argos-like" dropdown experience on other Desktop Environments.



### 🔷 KDE Plasma

**Option A: Native Plasmoid (Recommended)**
This repository includes a native KDE Widget (Plasmoid) for the best experience.
1. Install dependencies:
   ```bash
   # Debian/Ubuntu
   sudo apt install kde-plasma-desktop wl-clipboard
   ```
2. Install the widget:
   ```bash
   cd kde-widget
   ./install.sh
   ```
3. Add **"DevToolbox Cheats"** widget to your panel/desktop.
4. Configure it (Right Click -> Configure) to point to your cheats directory (default: `~/devtoolbox-cheats/cheats.d`) and cache file.

**Option B: Kargos**
Kargos is a KDE port of Argos. It natively supports this script format.
1. Install Kargos: [https://github.com/lipido/kargos](https://github.com/lipido/kargos)
   (Available in AUR as `plasma5-applet-kargos-git` or via KDE Store)
2. Add "Kargos" widget to your panel.
3. In settings, set **Command** to:
   ```bash
   ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh
   ```

**Option C: Command Widget**
1. Add "Command Output" widget.
2. Set command to run the menu on click:
   ```bash
   ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
   ```

### 🐭 XFCE

**Option A: Genmon Plugin**
1. Install Genmon:
   ```bash
   sudo apt install xfce4-genmon-plugin
   ```
2. Add "Generic Monitor" to your panel.
3. Configure it:
   - **Command:** `echo "🗒️"` (or path to icon)
   - **On Click:** `~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu`
   - **Period:** 30s

### 🟢 Universal (Yad / System Tray)
If you just want a tray icon that opens the menu:

1. Install `yad`:
   ```bash
   sudo apt install yad
   ```
2. Run this command on startup:
   ```bash
   yad --notification \
       --text="DevToolbox Cheats" \
       --image="gtk-edit" \
       --command="~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu"
   ```

---

## 🕹️ Usage Modes

### Auto-Detection
The script automatically detects your environment.
```bash
./devtoolbox-cheats-beta.30s.sh
```
- In **GNOME + Argos**: Outputs formatted text for the panel.
- In **Others**: Launches the standalone graphical menu.

### Force Standalone Menu
Force the dialog menu to appear regardless of the environment:
```bash
./devtoolbox-cheats-beta.30s.sh menu
```

### Configuration
Override detection or paths via environment variables:
```bash
export DEVTOOLBOX_DE=kde    # Force KDE mode (uses kdialog)
export DEVTOOLBOX_DE=gnome  # Force GNOME/Argos output
export CHEATS_DIR=~/my-cheats
```

---

## 🛠 Troubleshooting
- **No menu appears?** Run in terminal to see errors.
- **"File not found"?** Ensure `cheats.d` is linked or configured correctly.
- **KDE but no kdialog?** The script will warn you and fall back to `zenity`.
- **FZF search not working?** Ensure a compatible terminal is installed (`konsole`, `gnome-terminal`, `alacritty`, etc.).
