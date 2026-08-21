# DevToolbox Cheats — macOS Port

A macOS port of DevToolbox Cheats using [xbar](https://github.com/matryer/xbar) for menu bar integration.

## Prerequisites

| Requirement | Purpose | Install |
|-------------|---------|---------|
| **Homebrew** | Package manager | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| **Bash 5** | Script runtime (macOS ships with 3.2) | `brew install bash` |
| **xbar** | Menu bar app | `brew install --cask xbar` |
| **fzf** | Fuzzy finder (optional) | `brew install fzf` |
| **bat** | Syntax highlighting (optional) | `brew install bat` |
| **pandoc** | PDF export (optional) | `brew install pandoc` |

## Quick Install

```bash
./install.sh
```

This will:
1. Install dependencies via Homebrew
2. Deploy cheatsheets to `~/cheats.d/`
3. Set up xbar plugin symlink
4. Configure daily auto-updates via launchd

## Manual Install

### 1. Install Dependencies

```bash
brew install fzf bat coreutils jq pandoc
brew install --cask font-noto-color-emoji
```

### 2. Deploy Cheatsheets

```bash
mkdir -p ~/cheats.d
cp -r cheats.d/* ~/cheats.d/
```

### 3. Setup xbar Plugin

```bash
# Create xbar plugins directory
mkdir -p ~/Library/Application\ Support/xbar/plugins

# Symlink macOS scripts
ln -sf "$(pwd)/macOS-beta" ~/Library/Application\ Support/xbar/plugins/devtoolbox-cheats
```

### 4. Make Scripts Executable

```bash
chmod +x macOS-beta/*.sh
```

## Usage

### Via xbar (Menu Bar)

After installation, xbar will automatically detect the plugin. Click the DevToolbox icon in your menu bar to access cheatsheets.

### Direct Execution

```bash
# Open standalone menu
./macOS-beta/devtoolbox-cheats.30s.sh menu

# Browse all cheats
./macOS-beta/devtoolbox-cheats.30s.sh browseAllCheatsFS

# Search cheats
./macOS-beta/devtoolbox-cheats.30s.sh searchCheatsFS

# Export all cheats to Markdown/PDF
./macOS-beta/devtoolbox-cheats.30s.sh exportAllCheatsFS
```

### Tools Menu

```bash
./macOS-beta/devtools.1m.sh
```

### Cheatsheet Updater

```bash
# Check for updates
./macOS-beta/cheats-updater.sh check

# Update cheatsheets
./macOS-beta/cheats-updater.sh update
```

### TLDR Generator

```bash
./macOS-beta/generate-tldr.sh
```

## Architecture

The macOS port uses a **thin wrapper** pattern:

```
macOS-beta/
├── compat.sh                    # Platform abstraction layer
├── devtoolbox-cheats.30s.sh     # Main script wrapper
├── devtools.1m.sh               # Tools menu wrapper
├── install.sh                   # macOS installer
├── cheats-updater.sh            # Updater wrapper
├── generate-tldr.sh             # TLDR generator wrapper
└── README.md                    # This file
```

Each wrapper:
1. Sources `compat.sh` for platform detection
2. Overrides Linux-incompatible functions
3. Sources the corresponding Linux script for shared core logic

This avoids duplicating ~2,800 lines of core logic.

## Platform Abstraction

The `compat.sh` file provides macOS-compatible versions of:

| Function | Linux | macOS |
|----------|-------|-------|
| Clipboard | `wl-copy`/`xclip` | `pbcopy`/`pbpaste` |
| Notifications | `notify-send` | `osascript` |
| Dialogs | `zenity`/`yad`/`kdialog` | `osascript`/`fzf` |
| Open URL | `xdg-open` | `open` |
| File mtime | `stat -c '%Y'` | `stat -f '%m'` |
| Hashing | `md5sum`/`sha256sum` | `md5 -q`/`shasum -a 256` |
| realpath | `realpath` | `grealpath`/python fallback |
| Screen dims | `xdpyinfo`/`xrandr` | `system_profiler` |
| Terminal | Various Linux terminals | Terminal.app/iTerm |

## Known Limitations

1. **Bash 4+ Required**: macOS ships with Bash 3.2 which lacks `mapfile` and `declare -A`. The wrappers require Homebrew Bash 5+.

2. **xbar vs Argos**: The macOS version uses xbar instead of Argos. The menu format is compatible but some Argos-specific features (like drill-down navigation) may work differently.

3. **Dialog Differences**: `osascript` dialogs are simpler than `zenity`/`yad`. Some advanced dialog features may not be available.

4. **Clipboard**: Wayland/X11 clipboard detection is skipped on macOS; `pbcopy`/`pbpaste` are used directly.

5. **DE Detection**: On macOS, `detect_de()` returns `"xbar"` instead of a Linux desktop environment.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHEATS_DIR` | `~/cheats.d` | Cheatsheet directory |
| `CHEATS_CACHE` | `~/.cache/devtoolbox-cheats-combined.idx` | Cache file |
| `CHEATS_REBUILD` | (empty) | Set to force cache rebuild |
| `DEVTOOLBOX_DE` | `auto` | Override DE detection (use `xbar` on macOS) |
| `DEVTOOLBOX_LAYOUT` | (from config) | Override layout (standard/zenity/drilldown) |

## Differences from Linux Version

| Feature | Linux | macOS |
|---------|-------|-------|
| Menu bar | Argos (GNOME) | xbar |
| DE detection | Auto-detect GNOME/KDE/etc. | Returns "xbar" |
| Dialogs | zenity/yad/kdialog | osascript/fzf |
| Clipboard | wl-copy/xclip | pbcopy/pbpaste |
| Notifications | notify-send | osascript |
| Systemd timer | launchd | launchd |
| Package manager | apt/dnf/pacman | Homebrew |

## Troubleshooting

### Scripts not executing

```bash
chmod +x macOS-beta/*.sh
```

### xbar not showing plugin

1. Ensure xbar is running
2. Check plugin directory: `~/Library/Application Support/xbar/plugins/`
3. Restart xbar

### Bash version errors

```bash
# Check current bash version
bash --version

# Should be 5.x or higher
# If not, install via Homebrew:
brew install bash
```

### Cheatsheet updates not working

```bash
# Manual update
./macOS-beta/cheats-updater.sh update

# Check for errors
./macOS-beta/cheats-updater.sh check
```

## Support

For issues specific to the macOS port, please open an issue with the `macos` label.
