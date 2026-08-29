# DevToolbox Cheats — macOS Port

A macOS port of DevToolbox Cheats using [SwiftBar](https://swiftbar.app/) for menu bar integration (recommended for macOS 12+). xbar is supported as a legacy option for older macOS via `DEVTOOLBOX_APP_TARGET=1`.

## Prerequisites

**Required:** Bash 4+ (runtime), python3 (TOC tooling, URL decoding), git
(cheats-updater; ships with the Xcode Command Line Tools — `xcode-select --install`).
Standard macOS tools (`find`, `cp`, `cmp`, `sed`, `sort`, `osascript`,
`pbcopy`/`pbpaste`) are used as-is.

**Optional** (the app degrades gracefully without them):

| Tool | Purpose | Install |
|------|---------|---------|
| **fzf** | Interactive fuzzy finder (FZF Search) | `brew install fzf` or `sudo port install fzf` |
| **jq** | JSON/JWT utilities in the Tools menu | `brew install jq` or `sudo port install jq` |
| **bat** | Syntax-highlighted previews | `brew install bat` or `sudo port install bat` |
| **pandoc** | Markdown → HTML/PDF export | `brew install pandoc` or `sudo port install pandoc` |
| **coreutils** | `grealpath` convenience | `brew install coreutils` or `sudo port install coreutils` |

The installer prints a Required/Optional plan before installing and never
aborts because an optional package failed.

**Package Manager Install:**
- Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- MacPorts: https://www.macports.org/install.php

## Quick Install

From the repository root:

```bash
./macOS-beta/install.sh
```

This will:
1. Detect Homebrew or MacPorts and install dependencies
2. Deploy cheatsheets to `~/cheats.d/`
3. Set up menu bar plugins for SwiftBar (`devtoolbox-cheats.30s.sh`, `devtools.1m.sh`)
4. Install the `cheats-updater` and `generate-tldr` CLI commands to `~/.local/bin`
5. Configure daily auto-updates via launchd

## Manual Install

### 1. Install Dependencies

**Homebrew:**
```bash
brew install bash fzf bat coreutils jq pandoc
brew install --cask swiftbar
brew install --cask font-noto-color-emoji
```

**MacPorts:**
```bash
sudo port install bash fzf bat coreutils jq pandoc python312
sudo port select --set python3 python312
```

### 2. Deploy Cheatsheets

```bash
mkdir -p ~/cheats.d
cp -r cheats.d/* ~/cheats.d/
```

### 3. Setup Menu Bar Plugin

```bash
# SwiftBar (recommended):
mkdir -p ~/Library/Application\ Support/SwiftBar/Plugins
cp "$(pwd)/macOS-beta/devtoolbox-cheats.30s.sh" ~/Library/Application\ Support/SwiftBar/Plugins/
cp "$(pwd)/macOS-beta/devtools.1m.sh" ~/Library/Application\ Support/SwiftBar/Plugins/

# xbar (legacy, macOS < 12 only):
mkdir -p ~/Library/Application\ Support/xbar/plugins
cp "$(pwd)/macOS-beta/devtoolbox-cheats.30s.sh" ~/Library/Application\ Support/xbar/plugins/
cp "$(pwd)/macOS-beta/devtools.1m.sh" ~/Library/Application\ Support/xbar/plugins/
```

### 4. Make Scripts Executable

```bash
chmod +x macOS-beta/*.sh
```

## Usage

### Via SwiftBar (Menu Bar)

After installation, SwiftBar will automatically detect the plugin. Click the DevToolbox icon in your menu bar to access cheatsheets.

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

The macOS port is **fully standalone**: every runtime script contains its own
platform logic and never sources Linux runtime scripts or a compatibility shim.
The legacy `compat.sh` bridge has been removed.

```
macOS-beta/
├── devtoolbox-cheats.30s.sh     # Complete menu bar implementation (SwiftBar/xbar)
├── devtools.1m.sh               # Complete macOS tools menu
├── cheats-updater.sh            # Complete macOS updater
├── generate-tldr.sh             # Complete macOS TLDR generator
├── install.sh                   # macOS installer (Homebrew/MacPorts)
├── uninstall.sh                 # macOS uninstaller
├── deploy-to-macos-vm.sh        # Dev helper: sync repo to macOS test VM via SSH
├── test-native-dialog.sh        # Native macOS dialog smoke test
├── debug.sh                       # Universal debug info collector (macOS + Linux SSH)
├── troubleshoot.md              # Comprehensive troubleshooting & debug guide
└── README.md                    # This file
```

## Platform Mapping

macOS-native equivalents used by the standalone scripts:

| Function | Linux | macOS |
|----------|-------|-------|
| Clipboard | `wl-copy`/`xclip` | `pbcopy`/`pbpaste` |
| Notifications | `notify-send` | `osascript` |
| Dialogs | `zenity`/`yad`/`kdialog` | `osascript`/`fzf` |
| Open URL | `xdg-open` | `open` |
| File mtime | `stat -c '%Y'` | `stat -f '%m'` |
| Hashing | `md5sum`/`sha256sum` | `md5 -q`/`shasum -a 256` |
| Timestamps | GNU `date -d @N` | BSD `date -r N` |
| realpath | `realpath` | `grealpath`/python fallback |
| Screen dims | `xdpyinfo`/`xrandr` | `system_profiler` |
| Terminal | Various Linux terminals | Terminal.app/iTerm |

## Known Limitations

1. **Bash 4+ Required**: macOS ships with Bash 3.2 which lacks `mapfile` and `declare -A`. The scripts auto-detect and re-execute with Homebrew/MacPorts Bash.

2. **SwiftBar vs Argos**: The macOS version uses SwiftBar (or xbar on macOS < 12) instead of Argos. The menu format is compatible but some Argos-specific features (like drill-down navigation) may work differently.

3. **Dialog Differences**: `osascript` dialogs are simpler than `zenity`/`yad`. Some advanced dialog features may not be available.

4. **Clipboard**: Wayland/X11 clipboard detection is skipped on macOS; `pbcopy`/`pbpaste` are used directly.

5. **DE Detection**: On macOS, `detect_de()` returns `"xbar"` instead of a Linux desktop environment.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHEATS_DIR` | `~/cheats.d` | Cheatsheet directory |
| `CHEATS_CACHE` | `~/.cache/devtoolbox-cheats-combined.idx` | Cache file |
| `CHEATS_REBUILD` | (empty) | Set to force cache rebuild |
| `CHEAT_VIEWERS` | `code codium cursor windsurf zed subl warp antigravity obsidian joplin macdown typora bear iawriter ulysses textmate textedit default` | Ordered list of preferred Markdown viewers |
| `DEVTOOLBOX_DE` | `auto` | Override DE detection (use `xbar` or `swiftbar` on macOS) |
| `DEVTOOLBOX_APP_TARGET` | `2` (SwiftBar) | Menu bar app: `1`=xbar, `2`=SwiftBar, `3`=both (installer only) |
| `DEVTOOLBOX_LAYOUT` | (from config) | Override layout (standard/zenity/drilldown) |

## Differences from Linux Version

| Feature | Linux | macOS |
|---------|-------|-------|
| Menu bar | Argos (GNOME) | SwiftBar (recommended) / xbar (legacy) |
| DE detection | Auto-detect GNOME/KDE/etc. | Returns "xbar" |
| Dialogs | zenity/yad/kdialog | osascript/fzf |
| Clipboard | wl-copy/xclip | pbcopy/pbpaste |
| Notifications | notify-send | osascript |
| Auto-update | systemd timer | launchd |
| Package manager | apt/dnf/pacman | Homebrew / MacPorts |

## Troubleshooting

### Plugin missing from the menu bar (esp. after `git pull`)

SwiftBar and xbar **silently skip plugins without the execute bit**. A `git pull` or
archive extraction can strip modes. Fix:

```bash
chmod +x ~/devtoolbox-cheats/macOS-beta/*.sh
# then Refresh all
```

The installer also restores these bits automatically and reports each repair.

To watch how SwiftBar launches your plugins:

```bash
log stream --debug --predicate 'processImagePath contains "SwiftBar"'
```

And run a plugin manually exactly like it runs in the menu bar:

```bash
/bin/bash "$HOME/Library/Application Support/SwiftBar/Plugins/devtoolbox-cheats.30s.sh"; echo "exit=$?"
```

A quick troubleshooting guide is also available at [troubleshoot.md](troubleshoot.md).

### Quick Diagnostics

Run the diagnostic script to collect all system info for debugging:

```bash
bash macOS-beta/debug.sh
```

Save the output for bug reports:
```bash
bash macOS-beta/debug.sh > /tmp/devtoolbox-debug.txt
```

### Common Issues

| Issue | Quick Fix |
|-------|-----------|
| "No package manager found" | Install [Homebrew](https://brew.sh) or [MacPorts](https://www.macports.org) |
| "git is required" | `xcode-select --install` |
| "Bash 4+ required" | `brew install bash` |
| Plugin not showing | Check files in `~/Library/Application Support/SwiftBar/Plugins/` (or xbar plugins folder) |
| osascript permission prompts | Grant in System Settings > Privacy & Security |
| Empty menu / no cheatsheets | `CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh` |

See [troubleshoot.md](troubleshoot.md) for the full guide covering all failure modes.

## Deploy to a macOS Test VM

For development, the working tree can be deployed to a macOS test VM over SSH
without committing anything:

```bash
bash macOS-beta/deploy-to-macos-vm.sh
```

This syncs the repository to `~/Downloads/devtool` on the VM (`ssh macos`,
passwordless key auth required), runs `./install.sh` there, quits xbar, and
relaunches it after 30 seconds. Override defaults with
`--host`, `--remote-dir`, `--delay`, `--no-install`, or `--no-restart`.

## Support

For issues specific to the macOS port, please open an issue with the `macos` label.
