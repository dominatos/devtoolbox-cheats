# DevToolbox Cheats — macOS Troubleshooting & Debug Guide

A comprehensive reference for diagnosing and fixing issues with the macOS port of DevToolbox Cheats.

---

## Quick Diagnostics

Before reading through specific sections, run the diagnostic script to get a full system report:

```bash
bash macOS-beta/debug.sh
```

Save the output for reference:

```bash
bash macOS-beta/debug.sh > /tmp/devtoolbox-debug.txt
```

Use `--compact` for a shorter output:

```bash
bash macOS-beta/debug.sh --compact
```

The sections below explain what each check means and how to fix failures.

---

## Table of Contents

1. [Prerequisites & System Requirements](#1-prerequisites--system-requirements)
2. [Installation Troubleshooting](#2-installation-troubleshooting)
3. [SwiftBar & xbar Integration Troubleshooting](#3-swiftbar--xbar-integration-troubleshooting)
4. [Runtime Troubleshooting (devtoolbox-cheats.30s.sh)](#4-runtime-troubleshooting-devtoolbox-cheats30ssh)
5. [Tools Menu Troubleshooting (devtools.1m.sh)](#5-tools-menu-troubleshooting-devtools1msh)
6. [Cheats-Updater Troubleshooting](#6-cheats-updater-troubleshooting)
7. [TLDR Generator Troubleshooting](#7-tldr-generator-troubleshooting)
8. [LaunchAgent (Auto-Update) Troubleshooting](#8-launchagent-auto-update-troubleshooting)
9. [Clipboard Troubleshooting](#9-clipboard-troubleshooting)
10. [Uninstall Issues](#10-uninstall-issues)
11. [Platform-Specific Notes](#11-platform-specific-notes)
12. [Environment Variables Reference](#12-environment-variables-reference)
13. [File Paths Reference](#13-file-paths-reference)
14. [Manual Debugging Procedures](#14-manual-debugging-procedures)

---

## 1. Prerequisites & System Requirements

### What You Need

| Requirement | Version | Purpose |
|-------------|---------|---------|
| macOS | 10.15+ (Catalina or later recommended) | Platform |
| Bash | 4.0+ | Script runtime (macOS ships with 3.2) |
| Package manager | Homebrew **or** MacPorts | Dependency installation |
| git | Any | Required by cheats-updater (Xcode CLT) |
| SwiftBar / xbar | Latest | Menu bar integration |

### Diagnostic Check

Run the diagnostic script to verify prerequisites:

```bash
bash macOS-beta/debug.sh
```

Look for these sections in the output:
- **macOS System** — confirms you're on macOS, shows version
- **Shell Environment** — shows all bash versions installed
- **Package Managers** — shows Homebrew/MacPorts status
- **Required Tools** — bash, python3, git availability

---

## 2. Installation Troubleshooting

### 2.1 No Package Manager Found

**Symptom:**
```
[ERROR] No package manager found (Homebrew or MacPorts required).
```

**Cause:** Neither Homebrew nor MacPorts is installed, or their `bin` directories are not in `PATH`.

**Fix:**

Install Homebrew (recommended):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Or install MacPorts: https://www.macports.org/install.php

If already installed but not found, check the diagnostic output under **Package Managers** and **PATH** sections. Common fix:

```bash
# Homebrew on Apple Silicon
export PATH="/opt/homebrew/bin:$PATH"

# Homebrew on Intel
export PATH="/usr/local/bin:$PATH"

# MacPorts
export PATH="/opt/local/bin:$PATH"
```

You can also set `DEVTOOLBOX_PKG_MGR_PATH` before running the installer:
```bash
DEVTOOLBOX_PKG_MGR_PATH=/opt/homebrew/bin bash macOS-beta/install.sh
```

### 2.2 git Not Installed

**Symptom:**
```
[ERROR] git is required (cheats-updater uses it) but was not found.
[ERROR] Install the Xcode Command Line Tools with:
[ERROR]   xcode-select --install
```

**Cause:** git ships with Xcode Command Line Tools, not the base macOS install.

**Fix:**
```bash
xcode-select --install
```

This opens a GUI installer. After installation, verify:
```bash
git --version
```

### 2.3 Bash Version Errors

**Symptom:**
```
ERROR: Bash 4+ required.
  Install with Homebrew: brew install bash
  Or with MacPorts:      sudo port install bash
```

Or the script appears to loop/restart repeatedly.

**Cause:** macOS ships with Bash 3.2 which lacks `mapfile`, `declare -A`, and other features the scripts require. The scripts attempt to auto-detect and re-exec with Homebrew/MacPorts Bash, but this fails when:
- Homebrew/MacPorts Bash is not installed
- The re-exec candidate paths don't contain Bash 4+
- Bash is installed but not executable

**Fix:**

Install Bash 4+:
```bash
# Homebrew
brew install bash

# MacPorts
sudo port install bash
```

Verify the install:
```bash
/opt/homebrew/bin/bash --version   # Apple Silicon Homebrew
/usr/local/bin/bash --version     # Intel Homebrew
/opt/local/bin/bash --version     # MacPorts
```
At least one of the above should report Bash version 4 or newer.

If Bash 4+ is installed but the scripts still fail, check that these paths are accessible:
```bash
ls -la /opt/homebrew/bin/bash    # Apple Silicon Homebrew
ls -la /usr/local/bin/bash       # Intel Homebrew
ls -la /opt/local/bin/bash       # MacPorts
```

**Re-exec loop:** If the script prints "Bash 4+ required but re-exec already attempted" it means the candidate Bash found was still <4. The diagnostic script shows all bash versions found — check the **Shell Environment** section.

### 2.4 python3 Not Found

**Symptom:**
```
[ERROR] Required dependency 'python3' could not be installed. Aborting installation.
```

**Cause:** python3 is not installed and the package manager could not install it.

**Fix:**

macOS ships `/usr/bin/python3` with Xcode Command Line Tools. Install them first:
```bash
xcode-select --install
```

If you need a newer python3 via Homebrew:
```bash
brew install python3
```

Or via MacPorts:
```bash
sudo port install python312
sudo port select --set python3 python312
```

Verify python3:
```bash
command -v python3
```

The diagnostic script's **Required Tools** section shows which `python3` is found and its location.

### 2.5 Installer Fails on System Commands

**Symptom:**
```
[ERROR] Required system command missing: find
```

**Cause:** Core system utilities are missing. This is extremely rare on macOS and may indicate a corrupted system or unusual PATH.

**Fix:**

`find`, `cp`, `cmp`, `sed`, `sort` are part of the base macOS system. If PATH is the issue:
```bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
```

### 2.6 Permission Errors (MacPorts)

**Symptom:**
```
Password: [sudo prompts and fails]
```

**Cause:** MacPorts requires `sudo` for `port install`.

**Fix:**

Ensure your user is in the `admin` group and you can use `sudo`. Alternatively, use Homebrew which does not require `sudo`.

### 2.7 Cheatsheet Deployment Fails

**Symptom:**
```
[WARN] cheats.d not found: /path/to/repo/cheats.d
```

**Cause:** The installer could not find the bundled `cheats.d/` directory relative to the script location.

**Fix:**

Run the installer from within the cloned repository:
```bash
cd devtoolbox-cheats
./macOS-beta/install.sh
```

### 2.8 Plugin Refuses to Overwrite

**Symptom:**
```
[ERROR] Refusing to overwrite unknown file: ~/Library/Application Support/SwiftBar/Plugins/devtoolbox-cheats.30s.sh
[ERROR] Remove or rename it, then re-run the installer.
```

**Cause:** A file exists at the target location that the installer doesn't recognize as belonging to DevToolbox.

**Fix:**
```bash
# For SwiftBar:
rm ~/Library/Application\ Support/SwiftBar/Plugins/devtoolbox-cheats.30s.sh
rm ~/Library/Application\ Support/SwiftBar/Plugins/devtools.1m.sh

# For xbar (legacy):
rm ~/Library/Application\ Support/xbar/plugins/devtoolbox-cheats.30s.sh
rm ~/Library/Application\ Support/xbar/plugins/devtools.1m.sh
```

Then re-run the installer.

---

## 3. SwiftBar & xbar Integration Troubleshooting

### 3.1 Plugin Not Appearing in Menu Bar

**Symptom:** The menu bar app (SwiftBar/xbar) is running but the DevToolbox icon does not appear.

**Checks:**

1. Is SwiftBar running?
   ```bash
   pgrep -x SwiftBar
   ```
   *(For xbar: `pgrep -x xbar`)*

2. Are the plugin symlinks in the correct directory?
   ```bash
   ls -la ~/Library/Application\ Support/SwiftBar/Plugins/devtoolbox-*
   ```

3. Are the scripts executable?
   ```bash
   chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/devtoolbox-cheats.30s.sh
   chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/devtools.1m.sh
   ```

4. If you used symlinks (`DEVTOOLBOX_USE_SYMLINKS=true`), are they broken?
   ```bash
   readlink ~/Library/Application\ Support/SwiftBar/Plugins/devtoolbox-cheats.30s.sh
   ```

*(Repeat steps 2-4 for `~/Library/Application\ Support/xbar/plugins/` if using xbar)*

**Fix:** Re-run the installer or manually copy the files:
```bash
cp "$(pwd)/macOS-beta/devtoolbox-cheats.30s.sh" \
    ~/Library/Application\ Support/SwiftBar/Plugins/
cp "$(pwd)/macOS-beta/devtools.1m.sh" \
    ~/Library/Application\ Support/SwiftBar/Plugins/
```

Then restart your menu bar app.

### 3.2 Plugin Shows Empty Menu / No Categories

**Symptom:** Clicking the DevToolbox icon shows a menu with no cheatsheets.

**Cause:** The cheatsheet directory is empty or the cache is stale.

**Fix:**

1. Verify cheatsheets exist:
   ```bash
   find ~/cheats.d -name '*.md' | head -5
   ```

2. Check cache:
   ```bash
   wc -l ~/.cache/devtoolbox-cheats-combined.idx
   ```
   If 0 lines or file doesn't exist, force a rebuild:
   ```bash
   CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh
   ```

3. Check that cheatsheets have valid front-matter:
   ```bash
   head -5 ~/cheats.d/basics/ls.md
   ```
   Should show `Title:`, `Group:`, etc.

### 3.3 Menu Refresh Not Working

**Symptom:** Menu shows stale data after adding/modifying cheatsheets.

**Fix:**

1. The plugin filename controls refresh: `devtoolbox-cheats.30s.sh` means it refreshes every 30 seconds. Do not rename.

2. Force cache rebuild:
   ```bash
   CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh
   ```

3. Check cache mtime vs cheatsheet mtime:
   ```bash
   stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' ~/.cache/devtoolbox-cheats-combined.idx
   stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' ~/cheats.d/basics/ls.md
   ```

### 3.4 Menu App Shows Error / Crash

**Diagnostic:**

Run the script manually to see errors:
```bash
bash macOS-beta/devtoolbox-cheats.30s.sh 2>&1
```

If you see "Bash 4+ required", the re-exec mechanism is failing. See [Section 2.3](#23-bash-version-errors).

---

## 4. Runtime Troubleshooting (devtoolbox-cheats.30s.sh)

### 4.1 Bash Re-exec Loop

**Symptom:** Script prints "ERROR: Bash 4+ required but re-exec already attempted" and exits.

**Diagnostic:** The diagnostic script shows all bash versions:
```bash
bash macOS-beta/debug.sh | grep -A20 "Shell Environment"
```

**Fix:** Ensure at least one of these paths has Bash 4+:
- `/opt/homebrew/bin/bash` (Apple Silicon Homebrew)
- `/usr/local/bin/bash` (Intel Homebrew)
- `/opt/local/bin/bash` (MacPorts)

```bash
# Verify each candidate
/opt/homebrew/bin/bash --version 2>/dev/null | head -1
/usr/local/bin/bash --version 2>/dev/null | head -1
/opt/local/bin/bash --version 2>/dev/null | head -1
```

If none work, install Bash via Homebrew:
```bash
brew install bash
```

### 4.2 Front-matter Parsing Issues

**Symptom:** Cheatsheets show wrong titles, wrong groups, or missing icons.

**Cause:** The front-matter parser reads the first 80 lines looking for `Title:`, `Group:`, `Icon:`, `Order:` keys.

**Diagnostic:** Check a specific file's front-matter:
```bash
head -10 ~/cheats.d/basics/ls.md
```

**Fix:** Ensure front-matter is in the first 80 lines and follows the format:
```markdown
Title: ls command
Group: Basics
Icon: 📚
Order: 1
```

### 4.3 osascript Permission Dialogs (TCC)

**Symptom:** Script pauses and macOS shows a dialog like:
> "SwiftBar would like to send you notifications"
> "Terminal would like to access data from other apps"

**Cause:** macOS Big Sur (11) and later enforce TCC (Transparency, Consent, and Control).

**Fix:**

1. Open **System Settings** > **Privacy & Security**
2. Check two sections:
   - **Notifications**: allow SwiftBar/xbar or Terminal
   - **Automation**: allow SwiftBar/xbar or Terminal to control System Events
3. If permissions are denied, dialogs and notifications will silently fail but the menu will still work

### 4.4 Screen Dimension Detection Fails

**Symptom:** Window sizes are wrong (shows 1366x768 default).

**Diagnostic:**
```bash
system_profiler SPDisplaysDataType 2>/dev/null | grep Resolution
```

If empty, your display may not be recognized. The script defaults to 1366x768 and adapts gracefully.

### 4.5 CHEATS_DIR Symlink Not Resolving

**Symptom:** Cheatsheets not found even though `~/cheats.d` exists.

**Fix:**
```bash
ls -la ~/cheats.d
# If broken symlink:
rm ~/cheats.d
ln -s /actual/path/to/cheats ~/cheats.d
```

---

## 5. Tools Menu Troubleshooting (devtools.1m.sh)

### 5.1 "Missing required tools: pbcopy pbpaste"

**Cause:** `pbcopy` and `pbpaste` are macOS system utilities. If missing, the system may be corrupted.

**Diagnostic:**
```bash
ls -la /usr/bin/pbcopy /usr/bin/pbpaste
```

### 5.2 JSON Tools Not Working

**Cause:** `jq` is not installed.

**Fix:**
```bash
brew install jq
```

### 5.3 URL Decode Not Working

**Cause:** Uses `python3` for URL decoding.

**Fix:** Install python3 (see [Section 2.4](#24-python3-not-found)).

### 5.4 Markdown to HTML Conversion Fails

**Cause:** `pandoc` is not installed.

**Fix:**
```bash
brew install pandoc
```

### 5.5 IP Address / MAC Address Empty

**Cause:** Network interface detection uses `ipconfig getifaddr` and `ifconfig`. The active interface may not be `en0`-`en3`.

**Diagnostic:**
```bash
ifconfig | grep "flags=" | grep -v "lo0"
```

### 5.6 Port Check Fails

**Cause:** The clipboard content is not in `host:port` format.

**Fix:** Copy a value like `example.com:443` to the clipboard first, then run the port check tool.

---

## 6. Cheats-Updater Troubleshooting

### 6.1 git Clone Fails

**Symptom:**
```
[ERROR] Failed to clone repository
```

**Diagnostic:**
```bash
git ls-remote --heads https://github.com/dominatos/devtoolbox-cheats.git
curl -sI https://github.com | head -5
```

**Fix:**
- Ensure you have internet access
- Check if a proxy is needed: `git config --global http.proxy`
- Verify git is installed: `git --version`

### 6.2 Backup Location

Backups are stored at:
```
~/.local/share/devtoolbox-cheats/backups/YYYY-MM-DD-HHMMSS/
```

**Restore:**
```bash
ls ~/.local/share/devtoolbox-cheats/backups/
cp -r ~/.local/share/devtoolbox-cheats/backups/2024-01-15-103000/. ~/cheats.d/
```

### 6.3 TOC Formatting Failures

**Cause:** `manage-tocs.py` not found or `python3` not installed.

**Diagnostic:**
```bash
ls ~/.local/share/devtoolbox-cheats/tools/manage-tocs.py
python3 --version
```

**Fix:** Re-run the installer:
```bash
./macOS-beta/install.sh
```

---

## 7. TLDR Generator Troubleshooting

### 7.1 "Source directory not found"

**Symptom:**
```
[ERROR] Source directory not found: ~/cheats.d
```

**Fix:**
```bash
mkdir -p ~/cheats.d
cp -r /path/to/repo/cheats.d/* ~/cheats.d/
```

### 7.2 "Invalid platform directory"

**Cause:** The `--platform` argument contains path separators or is `.`/`..`.

**Fix:**
```bash
bash macOS-beta/generate-tldr.sh --platform common
```

---

## 8. LaunchAgent (Auto-Update) Troubleshooting

### 8.1 LaunchAgent Not Loading

**Symptom:** Auto-updates don't happen daily at 10:00 AM.

**Diagnostic:**
```bash
ls -la ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
launchctl list | grep devtoolbox-cheats
plutil -lint ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
```

**Fix:**
```bash
launchctl unload ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
```

### 8.2 Updater Logs

Logs are stored at:
```
~/Library/Logs/devtoolbox-cheats/com.devtoolbox-cheats.updater.out.log
~/Library/Logs/devtoolbox-cheats/com.devtoolbox-cheats.updater.err.log
```

Check for errors:
```bash
cat ~/Library/Logs/devtoolbox-cheats/com.devtoolbox-cheats.updater.err.log
```

### 8.3 Manual Trigger

```bash
~/.local/bin/cheats-updater update
```

Or via launchd:
```bash
launchctl start com.devtoolbox-cheats.updater
```

### 8.4 Change Schedule

Edit the plist and change the `Hour` value, then reload:
```bash
open -e ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
# Change <integer>10</integer> to desired hour
launchctl unload ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
launchctl load ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
```

---

## 9. Clipboard Troubleshooting

### 9.1 pbcopy/pbpaste Not Working

**Test:**
```bash
echo "test" | pbcopy
pbpaste
# Should output: test
```

**Common causes:**
- Running in a non-interactive session (SSH, cron)
- macOS security restrictions

**Fix:**
```bash
killall pbcopy 2>/dev/null; true
```

If running via SSH, clipboard may not work — this is expected.

### 9.2 Copy Works But Paste Doesn't

Try pasting in a different application (e.g., TextEdit). If it works there, the issue is with the destination app.

---

## 10. Uninstall Issues

### 10.1 LaunchAgent Not Unloading

**Fix:**
```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist
```

### 10.2 PATH Entry Left in Shell RC

```bash
grep -n "DevToolbox Cheats" ~/.zshrc
# Edit the file and remove the marker comment + PATH line
```

Or restore from the backup:
```bash
ls ~/.zshrc.devtoolbox-uninstall-backup
```

---

## 11. Platform-Specific Notes

### 11.1 macOS Big Sur (11) and Later — TCC Permissions

Starting with macOS 11, apps must request permission for:
- **Notifications** — required for `osascript -e 'display notification ...'`
- **Automation** — required for `osascript` to control other apps
- **Accessibility** — may be needed for some dialog interactions

Grant permissions in **System Settings > Privacy & Security**.

### 11.2 Apple Silicon (M1/M2/M3) vs Intel

Homebrew installs to different prefixes:
- Apple Silicon: `/opt/homebrew/`
- Intel: `/usr/local/`

### 11.3 System Integrity Protection (SIP)

SIP prevents modifying system directories. DevToolbox installs to user-space (`~/.local/`, `~/Library/`), so SIP does not interfere.

### 11.4 Gatekeeper

Gatekeeper may block unsigned scripts. Fix:
```bash
xattr -d com.apple.quarantine macOS-beta/devtoolbox-cheats.30s.sh
```

### 11.5 Path Randomization

macOS may randomize the path of scripts launched from Finder, SwiftBar, or xbar. The scripts resolve symlinks to find their real location.

---

## 12. Environment Variables Reference

| Variable | Default | Used By | Description |
|----------|---------|---------|-------------|
| `CHEATS_DIR` | `~/cheats.d` | All scripts | Cheatsheet directory |
| `CHEATS_CACHE` | `~/.cache/devtoolbox-cheats-combined.idx` | Main script | Cache index file |
| `CHEATS_REBUILD` | (empty) | Main script | Force cache rebuild |
| `DEVTOOLBOX_DE` | auto | Main script | Override DE detection |
| `DEVTOOLBOX_LAYOUT` | from config | Main script | Override layout (standard/zenity/drilldown) |
| `DEVTOOLBOX_TOC_FORMAT` | from config | Main script | Override TOC format (obsidian/github) |
| `DEVTOOLBOX_PKG_MGR_PATH` | (empty) | Installer | Override package manager PATH prefix |
| `DEVTOOLBOX_MAC_HOST` | `macos` | deploy-to-macos-vm.sh | SSH host for macOS VM |
| `DEVTOOLBOX_MAC_DIR` | `devtool` | deploy-to-macos-vm.sh | Remote directory on VM |
| `SCREEN_DIMS_TTL` | `86400` | Main script | Screen dimension cache TTL (seconds) |
| `ARGOS_CAT_TTL` | `60` | Main script | Drill-down category state TTL (seconds) |
| `CHEAT_VIEWERS` | `code textedit default` | Main script | Ordered list of viewers |
| `SOURCE_DIR` | `~/cheats.d` | generate-tldr.sh | TLDR source directory |
| `OUTPUT_DIR` | `~/cheats.d-gen/tldr` | generate-tldr.sh | TLDR staging output |
| `TLDR_CACHE_DIR` | `~/.cache/tldr/pages` | generate-tldr.sh | TLDR cache pages |
| `TLDR_PLATFORM_DIR` | `common` | generate-tldr.sh | TLDR platform directory |
| `EDITOR` | `nano` | Main script | Fallback editor |

**Usage examples:**
```bash
# Force cache rebuild
CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh

# Use custom cheats directory
CHEATS_DIR=/my/custom/cheats bash macOS-beta/devtoolbox-cheats.30s.sh menu

# Override layout
DEVTOOLBOX_LAYOUT=drilldown bash macOS-beta/devtoolbox-cheats.30s.sh
```

---

## 13. File Paths Reference

| Path | Type | Used By | Description |
|------|------|---------|-------------|
| `~/cheats.d/` | Directory | All | Cheatsheet markdown files |
| `~/.cache/devtoolbox-cheats-combined.idx` | File | Main script | Cache index (tab-separated) |
| `~/.cache/devtoolbox-cheats/run/` | Directory | Main script | Runtime state directory |
| `~/.cache/devtoolbox-cheats/run/argos-cat-combined.state` | File | Main script | Drill-down category state |
| `~/.cache/devtoolbox-cheats/run/screen-dims` | File | Main script | Cached screen dimensions |
| `~/.cache/devtoolbox-cheats-argos-combined/` | Directory | Main script | Per-category menu cache |
| `~/Library/Application Support/SwiftBar/Plugins/` | Directory | Installer | SwiftBar plugin files |
| `~/Library/Application Support/xbar/plugins/` | Directory | Installer | xbar plugin files |
| `~/.local/bin/cheats-updater` | File | CLI | Updater command |
| `~/.local/bin/generate-tldr` | File | CLI | TLDR generator command |
| `~/.local/share/devtoolbox-cheats/` | Directory | Installer | Deployed tools directory |
| `~/.local/share/devtoolbox-cheats/tools/manage-tocs.py` | File | Updater, Main | TOC formatter |
| `~/.local/share/devtoolbox-cheats/backups/` | Directory | Updater | Update backups |
| `~/.config/devtoolbox-cheats/` | Directory | Main script | User configuration |
| `~/.config/devtoolbox-cheats/layout.conf` | File | Main script | Layout setting |
| `~/.config/devtoolbox-cheats/toc_format.conf` | File | Main script | TOC format setting |
| `~/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist` | File | launchd | Auto-update agent |
| `~/Library/Logs/devtoolbox-cheats/` | Directory | launchd | Updater logs |
| `/tmp/devtoolbox-cheats-XXXXXX` | Directory | Updater | Temporary clone directory |

---

## 14. Manual Debugging Procedures

### 14.1 Full Diagnostic Report

```bash
bash macOS-beta/debug.sh
```

### 14.2 Run Script with Debug Output

```bash
# See all output from the main script
bash macOS-beta/devtoolbox-cheats.30s.sh 2>&1

# Run a specific action
bash macOS-beta/devtoolbox-cheats.30s.sh showSettings
```

### 14.3 Force Cache Rebuild

```bash
# Delete cache and rebuild
rm -f ~/.cache/devtoolbox-cheats-combined.idx
CHEATS_REBUILD=1 bash macOS-beta/devtoolbox-cheats.30s.sh

# Or just touch a cheatsheet to trigger mtime-based rebuild
touch ~/cheats.d/basics/ls.md
```

### 14.4 Test Native macOS Dialogs

```bash
bash macOS-beta/test-native-dialog.sh
```

### 14.5 Test Individual Tools Menu Actions

```bash
echo '{"key":"value"}' | pbcopy && bash macOS-beta/devtools.1m.sh jsonFormat
echo 'hello world' | pbcopy && bash macOS-beta/devtools.1m.sh base64Encode
echo 'https://example.com' | pbcopy && bash macOS-beta/devtools.1m.sh urlEncode
date +%s | pbcopy && bash macOS-beta/devtools.1m.sh unixToLocal
```

### 14.6 Test Cheatsheet Front-matter Parsing

```bash
perl -pe 's/^\xEF\xBB\xBF//' ~/cheats.d/basics/ls.md 2>/dev/null \
    | head -n 80 \
    | tr -d '\r' \
    | grep -i "^[[:space:]]*Title[[:space:]]*:" \
    | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
```

### 14.7 Check Cache Contents

```bash
cat ~/.cache/devtoolbox-cheats-combined.idx
wc -l ~/.cache/devtoolbox-cheats-combined.idx
stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' ~/.cache/devtoolbox-cheats-combined.idx
```

### 14.8 Verify SwiftBar / xbar Plugin Detection

```bash
for link in ~/Library/Application\ Support/SwiftBar/Plugins/devtoolbox-*.sh ~/Library/Application\ Support/xbar/plugins/devtoolbox-*.sh; do
    if [[ -L "$link" ]]; then
        target="$(readlink "$link")"
        if [[ -f "$link" ]]; then
            echo "OK: $link -> $target"
        else
            echo "BROKEN: $link -> $target"
        fi
    elif [[ -f "$link" ]]; then
        echo "OK: $link (regular file)"
    fi
done
```

### 14.9 Manual Updater Test

```bash
~/.local/bin/cheats-updater check
~/.local/bin/cheats-updater update
```

### 14.10 Collect Debug Info for Bug Reports

When filing an issue, include:

```bash
# Full diagnostic
bash macOS-beta/debug.sh > /tmp/devtoolbox-debug.txt 2>&1

# Script error output
bash macOS-beta/devtoolbox-cheats.30s.sh 2>&1 | tee /tmp/devtoolbox-stderr.txt

# macOS version
sw_vers > /tmp/devtoolbox-macos-version.txt

# Include all three files in the issue
```

---

## Diagnostic Script Reference

The `debug.sh` script checks all of the following:

| Section | What It Checks |
|---------|----------------|
| macOS System | `uname`, `sw_vers`, architecture, kernel, uptime |
| Shell Environment | All bash versions in known paths, active shell |
| Package Managers | Homebrew/MacPorts presence and version |
| Required Tools | bash, python3, git, find, cp, cmp, sed, sort, perl |
| Optional Tools | fzf, jq, bat, pandoc, grealpath/realpath |
| macOS Tools | osascript, pbcopy, pbpaste, open, shasum, md5, uuidgen, openssl |
| Network Tools | curl, nc, ifconfig, ipconfig |
| Editors | code, nano, vim, TextEdit.app |
| SwiftBar / xbar | App installed, running status, plugin directory, symlink integrity |
| DevToolbox Paths | Cheats dir, cache, runtime dir, argos cache, CLI tools, tools dir, config |
| Environment Variables | All 17 recognized env vars with defaults |
| LaunchAgent | Plist exists, syntax valid, loaded status, log files |
| PATH | All directories checked for existence, common prefix detection |
| Fonts | Noto Color Emoji font presence |
| Clipboard | pbcopy/pbpaste round-trip test |
| osascript | Basic AppleScript execution test |
| Disk Space | Available disk space on `/` |
