# 🗒️ DevToolbox Cheats — KDE Plasma Widget for Markdown Cheatsheets

**Fast, searchable cheatsheet manager** as a native KDE Plasma widget. Organize your command-line references, code snippets, and quick guides in Markdown files with instant access from your panel.

![Version](https://img.shields.io/badge/version-1.0-blue)
![Plasma 5](https://img.shields.io/badge/Plasma-5-informational)
![Plasma 6](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

### 🚀 Performance
- **Instant Loading** - Smart caching loads 100+ cheats in <100ms
- **Fast Category Toggle** - Optimized for instant expand/collapse
- **Auto Cache Invalidation** - Rebuilds only when files change

### 🎯 Core Features
- **Native KDE Widget** - Full Plasma 5 & 6 support
- **Category Organization** - Group cheats by topic with emoji icons
- **Live Search** - Filter cheats as you type
- **Copy to Clipboard** - One-click copy (wl-clipboard/xclip support)
- **Open in Editor** - Launch any editor with auto-detection
- **Export** - Save individual or all cheats to Markdown
- **FZF Integration** - Powerful fuzzy search in terminal

### 🎨 Smart Features
- **Editor Auto-Detection** - Scans for 16+ popular editors
- **Editor Dropdown** - Quick selection with ✓ marks for installed
- **Auto-Fallback** - Uses first available editor if preferred missing
- **Custom Icons** - Emoji or system icons per category/cheat
- **Safe Install** - No crashes, works in VMs

---

## 📦 Installation

### Quick Install

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
1. ✅ Install the widget to `~/.local/share/plasma/plasmoids/`
2. ✅ Clear QML cache (ensures config shows correctly)
3. ✅ Deploy 133 example cheatsheets to `~/cheats.d`
4. ✅ Install dependencies (fzf, bat, wl-clipboard, fonts)
5. ✅ Prompt for safe Plasma Shell restart

### After Install

1. **Add to Panel:**
   - Right-click panel → Add Widgets
   - Search "DevToolbox Cheats"
   - Drag to panel or desktop

2. **Configure:**
   - Right-click widget → Configure
   - **Editor Dropdown** - Select from auto-detected editors (marked with ✓)
   - **Cheats Directory** - Default: `~/cheats.d`
   - **Cache File** - Default: `~/.cache/devtoolbox-cheats.json`
   - **Auto-Rebuild Cache** - Enable to rebuild cache on startup

3. **Start Using:**
   - Click widget to open
   - Click categories to expand
   - Search with top field
   - Click cheat to open in editor
   - Use buttons: Copy, Open, Export

---

## 📋 Requirements

### Core (Required)
- KDE Plasma 5.20+ or Plasma 6.0+
- Bash 4.0+

### Recommended
- **Clipboard:** `wl-clipboard` (Wayland) or `xclip` (X11)
- **FZF Search:** `fzf`, `bat`
- **Notifications:** `libnotify` (notify-send)
- **Fonts:** `noto-fonts-emoji` (for emoji icons)

### Supported Editors
Auto-detected:
- **VS Code** (`code`), **VS Codium** (`codium`)
- **Kate** (`kate`), **KWrite** (`kwrite`)
- **Geany** (`geany`), **Gedit** (`gedit`)
- **Sublime Text** (`subl`), **Atom** (`atom`)
- **Vim** (`vim`), **Neovim** (`nvim`)
- **Emacs** (`emacs`), **Nano** (`nano`)
- **Mousepad** (`mousepad`), **Pluma** (`pluma`)
- **XED** (`xed`), **Notepadqq** (`notepadqq`)
- **Custom** - Type any command

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

### Example Categories

```
~/cheats.d/
├── docker-basics.md          (Group: Containers, Icon: 🐳)
├── kubernetes-commands.md    (Group: Containers, Icon: ☸️)
├── mysql-queries.md          (Group: Databases, Icon: 🗄️)
├── mongodb-basics.md         (Group: Databases, Icon: 🍃)
├── nginx-config.md           (Group: Network, Icon: 🌐)
└── ssl-certificates.md       (Group: Security, Icon: 🔒)
```

Result:
- **🐳 Containers (2)** - Docker Basics, Kubernetes Commands
- **🗄️ Databases (2)** - MySQL Queries, MongoDB Basics
- **🌐 Network (1)** - Nginx Config
- **🔒 Security (1)** - SSL Certificates

---

## ⚙️ Configuration

### Widget Settings

Right-click widget → Configure:

**Cheats Directory**
- Default: `~/cheats.d`
- Where your Markdown files are stored

**Cache File**
- Default: `~/.cache/devtoolbox-cheats.json`
- Enables instant loading (<100ms)

**Preferred Editor**
- Dropdown shows auto-detected editors with ✓
- Falls back to first available if not found
- Custom option for any command

**Auto-Rebuild Cache**
- Off by default (cache auto-invalidates on file changes)
- Enable to force rebuild on widget load

### Advanced Configuration

Edit `~/.config/plasma-org.kde.plasma.desktop-appletsrc` or use widget config UI.

---

## 🎯 Usage

### Basic Operations

1. **Browse Cheats**
   - Click widget in panel
   - Categories show count: "🐳 Containers (8)"
   - Click category to expand/collapse

2. **Search**
   - Type in search field at top
   - Filters by title and filename
   - Categories auto-expand with results

3. **Copy to Clipboard**
   - Hover over cheat → Click copy button
   - Strips metadata (Title, Group, Icon, Order)
   - Status shows: "✅ Copied to clipboard!"

4. **Open in Editor**
   - Click cheat name
   - Opens with configured editor
   - Falls back to any available editor

5. **Export**
   - **Export All** - Saves all cheats to `~/DevToolbox-Cheatsheet_<date>.md`
   - **Export Single** - Hover → Export button → `~/DevToolbox-<name>_<date>.md`

6. **FZF Search**
   - Click FZF button
   - Opens terminal with fuzzy search
   - Preview with syntax highlighting (bat)
   - Select to open in editor

### Keyboard Shortcuts

No default shortcuts. Add custom shortcut in System Settings:
- System Settings → Shortcuts → Custom Shortcuts
- Add script: `qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu`

---

## 🔧 Troubleshooting

### Widget Not Showing After Install

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

### Config Page Not Showing

**Cause:** KCM cache not cleared

**Solution:**
```bash
# Reinstall with fresh cache clear
cd kde-widget-plasma6
./install.sh
# Choose option 2 for automatic restart
```

### Editor Not Found Error

**Cause:** Configured editor uninstalled

**Solution:**
- Widget auto-falls back to first available editor
- Notification shows: "Editor 'code' not found. Using 'kate' instead."
- Or reconfigure: Right-click → Configure → Select different editor

### Copy Not Working

**Cause:** Missing clipboard tool

**Solution:**
```bash
# For Wayland
sudo apt install wl-clipboard

# For X11
sudo apt install xclip
```

### FZF Search Not Opening

**Cause:** Missing fzf or terminal

**Solution:**
```bash
# Install fzf
sudo apt install fzf bat

# Ensure terminal installed (konsole, xterm, etc.)
sudo apt install konsole
```

### Slow Loading

**Cause:** Cache not being used

**Solution:**
1. Check cache file exists: `ls -lh ~/.cache/devtoolbox-cheats.json`
2. If missing, click "Refresh" button to rebuild
3. Check permissions: `chmod 644 ~/.cache/devtoolbox-cheats.json`

### Categories Won't Toggle

**Cause:** Old version before optimization

**Solution:**
```bash
cd ~/devtoolbox-cheats
git pull origin beta
cd kde-widget-plasma6
./install.sh
```

---

## 🚀 Performance

### Benchmark Results

**Test System:** 133 cheatsheets, 15 categories

| Operation | Time | Notes |
|-----------|------|-------|
| **First Load** | ~1-2s | Builds cache |
| **Cached Load** | <100ms | Reads from cache |
| **Category Toggle** | <10ms | Optimized in-place |
| **Search Filter** | <50ms | Filters 133 items |
| **Copy to Clipboard** | <200ms | Strips metadata |

### Optimization Features

1. **Smart Caching**
   - JSON cache with modification time check
   - Auto-invalidates on file changes
   - Single-pass metadata extraction

2. **Toggle Optimization**
   - In-place property modification
   - No array recreation (was 200-500ms)
   - Simple reassignment for QML update

3. **Lazy Loading**
   - Categories collapsed by default
   - Cheats loaded only in expanded categories

---

## 🛠 Development

### Project Structure

```
devtoolbox-cheats/
├── kde-widget-plasma6/          # Plasma 6 widget
│   ├── install.sh              # Safe installer
│   ├── uninstall.sh            # Safe uninstaller
│   └── DevToolboxPlasmoid/
│       ├── contents/
│       │   ├── ui/
│       │   │   ├── FullRepresentation.qml    # Main UI
│       │   │   └── configGeneral.qml         # Config page
│       │   └── code/
│       │       ├── indexer.sh                # Cache builder
│       │       ├── fzf-search.sh             # FZF helper
│       │       ├── cheats.js                 # Utilities
│       │       └── utils.js                  # Date helpers
│       ├── metadata.json         # Widget metadata
│       └── config/
│           └── main.xml          # Config schema
├── kde-widget-plasma5/          # Plasma 5 widget (same structure)
├── cheats.d/                    # Example cheatsheets (133 files)
└── README.md                    # This file
```

### Building from Source

```bash
# Clone
git clone -b beta https://github.com/dominatos/devtoolbox-cheats.git
cd devtoolbox-cheats

# Test widget (no install)
kpackagetool6 --type Plasma/Applet --show kde-widget-plasma6/DevToolboxPlasmoid

# Install for development
cd kde-widget-plasma6
./install.sh

# View logs
journalctl --user -f | grep DevToolbox
```

### Contributing

Pull requests welcome! Please:
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing`
5. Open Pull Request to `beta` branch

---

## 📝 Changelog

### v1.0 (2026-02-22) - Beta Branch

**Performance:**
- ✅ Smart caching: <100ms load time
- ✅ Category toggle optimization: <10ms (was 200-500ms)
- ✅ Auto cache invalidation on file changes

**Features:**
- ✅ Editor auto-detection (16+ editors)
- ✅ Editor dropdown in config with ✓ marks
- ✅ Auto-fallback when editor missing
- ✅ FZF search with helper script
- ✅ Copy/Open/Export functions fixed
- ✅ Safe install/uninstall (no crashes in VMs)

**Fixes:**
- ✅ Fixed quote escaping in all commands
- ✅ Fixed config page not showing (QML cache)
- ✅ Fixed category toggle not working
- ✅ Fixed FZF search errors
- ✅ Fixed dangerous plasmashell restart method

---

## 📄 License

MIT License - See LICENSE file

---

## 🙏 Credits

- **Developer:** Sviatoslav Fedorenko ([@dominatos](https://github.com/dominatos))
- **Inspired by:** DevHints, tldr, cheat.sh
- **Icons:** Noto Color Emoji

---

## 🔗 Links

- **Repository:** https://github.com/dominatos/devtoolbox-cheats
- **Issues:** https://github.com/dominatos/devtoolbox-cheats/issues
- **Beta Branch:** https://github.com/dominatos/devtoolbox-cheats/tree/beta

---

## ⭐ Support

If you find this useful:
- ⭐ Star the repository
- 🐛 Report bugs via Issues
- 💡 Suggest features
- 🍴 Fork and contribute

---

**Made with ❤️ for the KDE community**
