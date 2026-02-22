# 📒 DevToolbox Cheats — Universal Linux Cheatsheet Manager

**Cross-Desktop cheatsheet manager** for Linux with native support for GNOME, KDE, XFCE, and more. Access your Markdown command references instantly from your panel or menu.

![Version](https://img.shields.io/badge/version-1.0_beta-blue)
![GNOME](https://img.shields.io/badge/GNOME-Argos-informational)
![KDE](https://img.shields.io/badge/KDE-Plasma_5%2F6-informational)
![Universal](https://img.shields.io/badge/DE-Universal-green)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

### 🌍 Universal Desktop Support
- **GNOME** - Native Argos panel menu with dropdown
- **KDE Plasma 5/6** - Native widget with full UI
- **XFCE / MATE / Cinnamon** - Dialog-based menus (zenity/yad)
- **Tiling WMs** - Terminal-based with FZF (i3, sway, bspwm)
- **Auto-Detection** - Detects your DE and adapts automatically

### 🚀 Performance
- **Instant Loading** - Smart caching loads 100+ cheats in <100ms
- **Fast Category Toggle** - Optimized for instant expand/collapse (KDE widget)
- **Auto Cache Invalidation** - Rebuilds only when files change

### 🎯 Core Features
- **Category Organization** - Group cheats by topic with emoji icons
- **Live Search** - Filter cheats as you type
- **Copy to Clipboard** - One-click copy (wl-clipboard/xclip)
- **Open in Editor** - Launch any editor (auto-detected or custom)
- **Export** - Save individual or all cheats to Markdown/PDF
- **FZF Integration** - Powerful fuzzy search in terminal with syntax highlighting

### 🎨 Smart Features (KDE Widget)
- **Editor Auto-Detection** - Scans for 16+ popular editors
- **Editor Dropdown** - Quick selection with ✓ marks for installed
- **Auto-Fallback** - Uses first available editor if preferred missing
- **Custom Icons** - Emoji or system icons per category/cheat
- **Safe Install** - No crashes, works in VMs

---

## 📦 Installation

### Choose Your Desktop Environment

<details>
<summary><b>🟠 GNOME (Argos Extension)</b></summary>

#### 1. Install Argos Extension
From [extensions.gnome.org](https://extensions.gnome.org/extension/1176/argos/) or [GitHub](https://github.com/p-e-w/argos)

#### 2. Install Dependencies
```bash
# Debian/Ubuntu
sudo apt install zenity xclip fzf bat pandoc

# Fedora
sudo dnf install zenity xclip fzf bat pandoc

# Arch
sudo pacman -S zenity xclip fzf bat pandoc
```

#### 3. Clone and Link
```bash
git clone -b beta https://github.com/dominatos/devtoolbox-cheats.git ~/.config/argos/devtoolbox-cheats
cd ~/.config/argos
ln -s devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh .
ln -s devtoolbox-cheats/cheats.d .
```

#### 4. Restart Argos
Disable and re-enable the Argos extension, or press `Alt+F2` → `r` → `Enter`

**Result:** 🗒️ icon appears in your top panel with dropdown menu

</details>

<details>
<summary><b>🔵 KDE Plasma 5/6 (Native Widget)</b></summary>

#### Quick Install

```bash
# Clone repository
git clone -b beta https://github.com/dominatos/devtoolbox-cheats.git
cd devtoolbox-cheats

# Install for Plasma 6 (recommended)
cd kde-widget-plasma6
./install.sh

# OR Install for Plasma 5
cd kde-widget-plasma5
./install.sh
```

The installer will:
1. ✅ Install widget to `~/.local/share/plasma/plasmoids/`
2. ✅ Clear QML cache (ensures config shows correctly)
3. ✅ Deploy 133 example cheatsheets to `~/cheats.d`
4. ✅ Install dependencies (fzf, bat, wl-clipboard, fonts)
5. ✅ Prompt for safe Plasma Shell restart

#### After Install

1. **Add to Panel:**
   - Right-click panel → Add Widgets
   - Search "DevToolbox Cheats"
   - Drag to panel or desktop

2. **Configure:**
   - Right-click widget → Configure
   - **Editor Dropdown** - Select from auto-detected editors (marked with ✓)
   - **Cheats Directory** - Default: `~/cheats.d`
   - **Cache File** - Default: `~/.cache/devtoolbox-cheats.json`

3. **Usage:**
   - Click widget to open
   - Click categories to expand
   - Click cheat to open in editor
   - Use buttons: Copy, Open, Export, FZF Search

</details>

<details>
<summary><b>🟢 XFCE / MATE / Cinnamon</b></summary>

#### 1. Install Dependencies
```bash
# Debian/Ubuntu
sudo apt install zenity xclip fzf bat pandoc

# Fedora
sudo dnf install zenity xclip fzf bat pandoc

# For Wayland sessions, use wl-clipboard instead of xclip
```

#### 2. Clone Repository
```bash
git clone -b beta https://github.com/dominatos/devtoolbox-cheats.git
cd devtoolbox-cheats
```

#### 3. Run Manually or Add to Panel

**Run manually:**
```bash
./devtoolbox-cheats-beta.30s.sh menu
```

**Add to panel (XFCE example):**
1. Install Genmon plugin: `sudo apt install xfce4-genmon-plugin`
2. Add "Generic Monitor" to panel
3. Configure:
   - **Label:** 🗒️ (or leave empty for icon)
   - **Command (on click):** `~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu`
   - **Period:** 30 seconds

</details>

<details>
<summary><b>⚫ Tiling WMs (i3, sway, bspwm)</b></summary>

#### 1. Install Dependencies
```bash
# Debian/Ubuntu
sudo apt install fzf bat xclip pandoc zenity

# For Wayland (sway, hyprland)
sudo apt install fzf bat wl-clipboard pandoc

# Arch
sudo pacman -S fzf bat xclip pandoc zenity
```

#### 2. Clone Repository
```bash
git clone -b beta https://github.com/dominatos/devtoolbox-cheats.git
cd devtoolbox-cheats
```

#### 3. Add Keybinding

**i3 config example:**
```bash
bindsym $mod+c exec --no-startup-id ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
```

**sway config example:**
```bash
bindsym $mod+c exec ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
```

**Result:** Opens dialog menu (if zenity installed) or FZF terminal search

</details>

---

## 📋 Requirements

### Core (All Platforms)
- Bash 4.0+
- `find`, `grep`, `sed`, `awk`

### Desktop-Specific

| Desktop | Required | Optional |
|---------|----------|----------|
| **GNOME** | Argos extension | `zenity`, `xclip`, `fzf`, `bat` |
| **KDE Plasma** | `kdialog`, `wl-clipboard` | `fzf`, `bat`, `noto-fonts-emoji` |
| **XFCE/MATE** | `zenity`, `xclip` | `fzf`, `bat` |
| **Wayland** | `wl-clipboard` | `zenity`, `fzf`, `bat` |
| **X11** | `xclip` | `zenity`, `fzf`, `bat` |
| **Terminal** | `fzf` | `bat` (syntax highlighting) |

### Supported Editors (Auto-Detected)
- **VS Code** (`code`), **VS Codium** (`codium`)
- **Kate** (`kate`), **KWrite** (`kwrite`)
- **Geany** (`geany`), **Gedit** (`gedit`)
- **Sublime Text** (`subl`), **Atom** (`atom`)
- **Vim** (`vim`), **Neovim** (`nvim`)
- **Emacs** (`emacs`), **Nano** (`nano`)
- **Mousepad** (`mousepad`), **Pluma** (`pluma`)
- **XED** (`xed`), **Notepadqq** (`notepadqq`)
- **Custom** - Any command

---

## 📚 Creating Cheatsheets

### File Structure

Cheatsheets are Markdown files in `~/cheats.d/` with metadata in the first 80 lines:

```markdown
Title: Docker Basics
Group: Containers
Icon: 🐳
Order: 1

# Docker Commands

## Containers

```bash
# List running containers
docker ps

# Stop container
docker stop <container_id>
```

## Images

```bash
# List images
docker images

# Pull image
docker pull nginx
```
```

### Metadata Fields

- **Title:** (Required) Display name
- **Group:** (Required) Category name
- **Icon:** (Optional) Emoji (🐳) or system icon name (`docker`)
- **Order:** (Optional) Sort order within group (1-999)

### Icon Options

**Emoji:**
```markdown
Icon: 🐳
Icon: 🔒
Icon: 🌐
```

**System Icons:**
```markdown
Icon: docker
Icon: database-server
Icon: network-server
```

### Example Structure

```
~/cheats.d/
├── docker-basics.md          (Group: Containers, Icon: 🐳)
├── kubernetes-commands.md    (Group: Containers, Icon: ☸️)
├── mysql-queries.md          (Group: Databases, Icon: 🗄️)
├── mongodb-basics.md         (Group: Databases, Icon: 🍃)
├── nginx-config.md           (Group: Network, Icon: 🌐)
└── ssl-certificates.md       (Group: Security, Icon: 🔒)
```

**Result in Menu:**
- **🐳 Containers** → Docker Basics, Kubernetes Commands
- **🗄️ Databases** → MySQL Queries, MongoDB Basics
- **🌐 Network** → Nginx Config
- **🔒 Security** → SSL Certificates

---

## 🎯 Usage

### GNOME (Argos)

1. **Click 🗒️ icon** in top panel
2. Dropdown menu appears with:
   - 🔎 Search cheats
   - 🚀 FZF Search Commands
   - 📥 Export all (MD/PDF)
   - **Categories** (expandable)
3. Click cheat name to copy & view
4. Content copied to clipboard automatically

### KDE Widget

1. **Click widget** in panel
2. Full window opens with:
   - Search field at top
   - Category list with counts
   - Action buttons: Copy, Open, Export, FZF
3. **Browse:** Click category to expand
4. **Search:** Type in search field
5. **Copy:** Click cheat → copied to clipboard
6. **Open:** Click cheat name → opens in editor
7. **Export:** Button to save all as Markdown
8. **FZF:** Opens terminal fuzzy search

### Other DEs (Dialog Menu)

1. **Launch script** (panel button, keybinding, or manually)
2. Dialog appears with options:
   - 🔎 Search cheats
   - 🚀 FZF Search Commands
   - 📚 Browse all cheats
   - 📥 Export all (MD/PDF)
3. **Search:** Type query → select from results
4. **Browse:** Select category → select cheat
5. **FZF:** Opens terminal with fuzzy search

### Terminal / FZF Search

```bash
# Direct FZF search
./devtoolbox-cheats-beta.30s.sh fzfSearch

# Or from menu → FZF Search Commands
```

- Start typing to filter
- Preview shows file with syntax highlighting (bat)
- Press `Enter` to open in editor at exact line
- `Esc` to cancel

---

## ⚙️ Configuration

### Environment Variables

```bash
# Override cheats directory (default: ~/cheats.d)
export CHEATS_DIR=~/my-cheats

# Override cache file
export CHEATS_CACHE=~/.cache/my-cheats.cache

# Force cache rebuild on every run (for debugging)
export CHEATS_REBUILD=1

# Force specific desktop environment
export DEVTOOLBOX_DE=kde     # kde, gnome, xfce, terminal

# Set preferred viewers (space-separated, tried in order)
export CHEAT_VIEWERS="code zenity"
```

### KDE Widget Settings

Right-click widget → Configure:

- **Cheats Directory** - Where your `.md` files are stored
- **Cache File** - JSON cache for fast loading
- **Preferred Editor** - Dropdown with auto-detected editors (✓ mark)
- **Auto-Rebuild Cache** - Force rebuild on widget load

### Custom Integration

**Add to i3/sway config:**
```bash
bindsym $mod+c exec ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
```

**Add to polybar:**
```ini
[module/devtoolbox]
type = custom/script
exec = echo "🗒️"
click-left = ~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu
```

**Add to waybar:**
```json
"custom/devtoolbox": {
  "format": "🗒️ {}",
  "on-click": "~/devtoolbox-cheats/devtoolbox-cheats-beta.30s.sh menu"
}
```

---

## 🔧 Troubleshooting

### GNOME: Icon Not Showing

**Cause:** Argos not detecting script

**Solution:**
```bash
# Check script name matches pattern
ls ~/.config/argos/*.sh

# Should be: something.30s.sh (30 seconds refresh)

# Restart Argos: disable/enable extension
```

### KDE: Widget Not Showing

**Cause:** QML cache not cleared

**Solution:**
```bash
# Clear QML cache
rm -rf ~/.cache/plasmashell/qmlcache
rm -rf ~/.cache/plasma-plasmashell/qmlcache
rm -rf ~/.cache/qt6/qmlcache

# Restart Plasma Shell
systemctl --user restart plasma-plasmashell.service
```

### KDE: Config Page Not Showing

**Solution:** Reinstall with cache clearing
```bash
cd kde-widget-plasma6
./install.sh
# Choose option 2 for automatic restart
```

### KDE: Editor Not Found

**Behavior:** Widget auto-falls back to first available editor

**Fix:** Right-click → Configure → Select different editor from dropdown

### Any DE: Copy Not Working

**Cause:** Missing clipboard tool

**Solution:**
```bash
# For Wayland
sudo apt install wl-clipboard

# For X11
sudo apt install xclip
```

### Dialog Menu Not Showing

**Cause:** Missing dialog tool

**Solution:**
```bash
# Install zenity (universal)
sudo apt install zenity

# Or kdialog (KDE)
sudo apt install kdialog

# Or yad (advanced dialogs)
sudo apt install yad
```

### FZF Search Not Working

**Cause:** Missing fzf or terminal

**Solution:**
```bash
# Install fzf and bat
sudo apt install fzf bat

# Ensure terminal is installed
sudo apt install konsole  # KDE
sudo apt install gnome-terminal  # GNOME
sudo apt install xfce4-terminal  # XFCE
```

---

## 🚀 Performance

### Benchmark Results

**Test System:** 133 cheatsheets, 15 categories

| Operation | Time | Platform |
|-----------|------|----------|
| **First Load** | ~1-2s | All (builds cache) |
| **Cached Load** | <100ms | KDE Widget / Script |
| **Category Toggle** | <10ms | KDE Widget (optimized) |
| **Search Filter** | <50ms | KDE Widget |
| **FZF Search** | Instant | Terminal (fzf) |
| **Copy to Clipboard** | <200ms | All |

### Cache System

- **Format:** TSV index with metadata
- **Location:** `~/.cache/devtoolbox-cheats-beta.idx` (script) or `.json` (widget)
- **Invalidation:** Auto-detects file changes via mtime
- **Rebuild:** Only when needed or forced

---

## 🛠 Development

### Project Structure

```
devtoolbox-cheats/
├── devtoolbox-cheats-beta.30s.sh    # Universal script (GNOME/KDE/XFCE)
├── kde-widget-plasma6/               # Plasma 6 widget
│   ├── install.sh
│   ├── uninstall.sh
│   └── DevToolboxPlasmoid/
│       ├── contents/ui/
│       │   ├── FullRepresentation.qml    # Main UI
│       │   └── configGeneral.qml         # Config page
│       └── contents/code/
│           ├── indexer.sh                 # Cache builder
│           └── fzf-search.sh              # FZF helper
├── kde-widget-plasma5/               # Plasma 5 widget (same structure)
├── cheats.d/                         # Example cheatsheets (133 files)
└── README.md
```

### Testing

**Test Universal Script:**
```bash
# Force specific DE
DEVTOOLBOX_DE=kde ./devtoolbox-cheats-beta.30s.sh menu
DEVTOOLBOX_DE=gnome ./devtoolbox-cheats-beta.30s.sh
DEVTOOLBOX_DE=terminal ./devtoolbox-cheats-beta.30s.sh menu

# Test FZF search
./devtoolbox-cheats-beta.30s.sh fzfSearch
```

**Test KDE Widget:**
```bash
cd kde-widget-plasma6
./install.sh

# View logs
journalctl --user -f | grep DevToolbox
```

### Contributing

Pull requests welcome! Please:
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing`
3. Test on your DE
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing`
6. Open Pull Request to `beta` branch

---

## 📝 Changelog

### v1.0 Beta (2026-02-22)

**Universal Support:**
- ✅ GNOME Argos integration
- ✅ KDE Plasma 5 & 6 native widgets
- ✅ XFCE/MATE/Cinnamon dialog menus
- ✅ Tiling WM support (i3, sway, bspwm)
- ✅ Auto-detection with smart fallbacks

**Performance:**
- ✅ Smart caching: <100ms load time
- ✅ Category toggle optimization: <10ms (KDE widget)
- ✅ Auto cache invalidation on file changes

**KDE Widget Features:**
- ✅ Editor auto-detection (16+ editors)
- ✅ Editor dropdown with ✓ marks
- ✅ Auto-fallback when editor missing
- ✅ Safe install/uninstall (no crashes in VMs)

**Universal Script Features:**
- ✅ Cross-DE dialog abstraction layer
- ✅ Terminal detection (15+ terminals)
- ✅ FZF search with syntax highlighting
- ✅ Copy/Open/Export functions
- ✅ PDF export with pandoc

---

## 📄 License

MIT License - See LICENSE file

---

## 🙏 Credits

- **Developer:** Sviatoslav Fedorenko ([@dominatos](https://github.com/dominatos))
- **Inspired by:** DevHints, tldr, cheat.sh, Argos
- **Icons:** Noto Color Emoji

---

## 🔗 Links

- **Repository:** https://github.com/dominatos/devtoolbox-cheats
- **Issues:** https://github.com/dominatos/devtoolbox-cheats/issues
- **Beta Branch:** https://github.com/dominatos/devtoolbox-cheats/tree/beta
- **Argos Extension:** https://github.com/p-e-w/argos

---

## ⭐ Support

If you find this useful:
- ⭐ Star the repository
- 🐛 Report bugs via Issues
- 💡 Suggest features
- 🍴 Fork and contribute

---

**Made with ❤️ for the Linux community**
