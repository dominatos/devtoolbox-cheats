# Changelog

## v1.4.2 (2026-05-31)

**Security / Stability:**
- ✅ Fix predictable `/tmp` path in `cheats-updater.sh` — replaced with `mktemp -d` (prevents race conditions)
- ✅ Add `cmp` to dependency check in `cheats-updater.sh` to fail fast when missing

**Windows Installer (`install-devtoolbox.ps1`):**
- ✅ Default to deploying `cheats.ahk` (script mode) instead of compiled EXE — avoids Windows Defender false positives
- ✅ Add optional `-CompileExe` flag for users who prefer a compiled executable
- ✅ Add AutoHotkey v1 version check — aborts with a clear message if only v2 is installed
- ✅ Auto-download latest AutoHotkey v1 installer from GitHub releases; bundled EXE used as offline fallback
- ✅ Abort installer if run as Administrator (prevents wrong-profile installation)
- ✅ Fix duplicate tray icon bug — only one startup entry registered

**Documentation:**
- ✅ Fix Windows install guide to not instruct users to run as Administrator
- ✅ Update `README-windows.md` to reflect AHK-first default and `-CompileExe` option
- ✅ Fix broken mojibake characters in README.md cheatsheet list
- ✅ Update systemd/updater docs to match actual deployed unit and binary path
- ✅ Add missing `# Changelog` heading to `CHANGELOG.md`
- ✅ Fix manual Windows install guide to include the compile step
- ✅ Fix `.gitignore` entry for `Windows-beta/cheats.exe`

**Code Quality:**
- ✅ Fix all ShellCheck warnings in `cheats-updater.sh` (SC2155, SC2295)
- ✅ Fix AHK menu collision bug — `MENU_MAP` now keyed by position index, not label

---

## v1.4.1 (2026-04-13)

**Features:**
- ✅ Add online and GitHub repository links to shell script and Plasma widgets
- ✅ Configure CodeRabbit AI review settings

**Documentation:**
- ✅ Fix Windows Setup Guide links in README.md
- ✅ Update installer command in README to include execution policy bypass

---

## v1.4.0 (2026-03-27)

**Windows Support (BETA):**
- ✅ Introduced native Windows Tray Application using AutoHotkey with PowerShell installer.
- ✅ Native Search GUI for Windows with real-time filtering by Title and Group.
- ✅ Global hotkey `Ctrl+Shift+S` to trigger search on Windows.
- ✅ Custom tray icon support and enhanced tray menu items with emojis.
- ✅ Dual-file startup strategy for improved reliability against antivirus false positives.

**New Cheatsheets & Categories:**
- ✅ **New Categories:** Added **Identity Management** and **Infrastructure Management**.
- ✅ **Databases/HA:** Added ProxySQL, MySQL Galera, Percona XtraDB Cluster, Pacemaker HA.
- ✅ **Security/Identity:** Added Keycloak, adcli, SSH Honeypot & CrowdSec.
- ✅ **Enterprise:** Added comprehensive Commvault v11 (Simpana) backup strategies.
- ✅ **Infrastructure/Web:** Added WildFly, Meld, plus 11 additional cheatsheets across monitoring, security, and cloud.
- ✅ **Updates:** Refined APT, HAProxy, and Nginx cheatsheets.

**Documentation:**
- ✅ Added Windows native tray app screenshots and setup instructions.
- ✅ Updated repository README to reflect Windows support.

## v1.3.2 (2026-03-24)

**New Cheatsheets:**
- ✅ Added WildFly application server cheatsheet.
- ✅ Added MySQL Galera Cluster cheatsheet.
- ✅ Added Percona XtraDB Cluster cheatsheet.
- ✅ Added Meld (merge & diff) cheatsheet.
- ✅ Added Pacemaker HA cheatsheet.
- ✅ Added ProxySQL cheatsheet.

**Documentation:**
- ✅ Updated HAProxy cheatsheet with corrections and new content.
- ✅ Updated APT cheatsheet content.

---

## v1.3.1 (2026-03-20)

**New Cheatsheets:**
- ✅ Added Keycloak identity management cheatsheet.
- ✅ Added Commvault v11 (Simpana) enterprise backup strategies cheatsheet.

**Windows (BETA) — Tray App Improvements:**
- ✅ Implemented native Search GUI with global hotkey `Ctrl+Shift+S` and real-time filtering.
- ✅ Automated user profile path detection — no manual path editing required.
- ✅ Custom tray icon support: place `icon.ico` in `cheats.d` to override.
- ✅ Enhanced tray menu items with emoji group icons.
- ✅ Professional Gear icon in tray (replaces default "H").
- ✅ Dual-file startup strategy (`cheats.exe` + `cheats.ahk`) for antivirus resilience.
- ✅ UTF-8 BOM encoding enforced on script save to prevent garbled characters.
- ✅ Removed obsolete installation script and icon browser utility.

---

## v1.3.0 (2026-03-18)

**Windows Support (BETA — Initial Release):**
- ✅ Introduced native Windows tray application via AutoHotkey (`cheats.ahk`).
- ✅ Automated PowerShell installer (`install-devtoolbox.ps1`).
- ✅ Auto-discovery of cheatsheets from `%USERPROFILE%\cheats.d`.
- ✅ Auto-start on login via Windows Startup folder.
- ✅ Documented ExecutionPolicy bypass and Administrator warning.

---

## v1.2.0 (2026-03-10)

**New Cheatsheets & Categories:**
- ✅ Added **Identity Management** category with adcli cheatsheet.
- ✅ Added **Infrastructure Management** category with 11 new cheatsheets across monitoring, security, and cloud.
- ✅ Added SSH Honeypot & CrowdSec security cheatsheet.

**Documentation:**
- ✅ Updated Nginx cheatsheet.
- ✅ Updated README with new categories and cheatsheet links.

---

## v1.1.1 (2026-03-04)

**Documentation Updates:**
- ✅ Simplified manual `.desktop` creation instructions for all Desktop Environments (Cosmic, Budgie, Deepin, etc.)
- ✅ Updated panel commands for XFCE, MATE, Cinnamon, LXQt to point to the universal executable `devtoolbox-cheats-menu`
- ✅ Updated Tiling WM configurations (i3, sway, bspwm, hyprland) to use the new `devtoolbox-cheats-menu` binary

---

## v1.1 (2026-03-04)

**Universal Installer:**
- ✅ Unified `install.sh` — single installer for all 12+ desktop environments
- ✅ Auto-detection for GNOME, KDE, XFCE, MATE, Cinnamon, LXQt, LXDE, Budgie, Pantheon, Deepin, Cosmic, Tiling WMs
- ✅ Per-DE panel integration instructions printed after install
- ✅ Universal `cheats.d` deployment to `~/cheats.d` for all DEs

**Auto-Updater:**
- ✅ New `cheats-updater.sh` — check, list, and update cheatsheets from upstream
- ✅ Smart diff — only overwrites changed files; custom cheatsheets never touched
- ✅ Automatic backups before every update
- ✅ systemd daily timer for automatic updates
- ✅ Installed to `~/.local/bin/` (PATH-accessible)

**Cheatsheet Library:**
- ✅ 130+ cheatsheets organized in 17 categories
- ✅ Refactored and standardized formatting across all cheatsheets
- ✅ Proper fenced code blocks, consistent headers, improved readability

---

## v1.0 Beta (2026-02-23)

**Universal Support:**
- ✅ GNOME Argos integration
- ✅ KDE Plasma 5 & 6 native widgets
- ✅ XFCE/MATE/Cinnamon dialog menus
- ✅ LXQt/LXDE lightweight support
- ✅ Budgie/Pantheon/Deepin modern DEs
- ✅ Cosmic (Pop!_OS 2025) support
- ✅ Tiling WM support (i3, sway, bspwm, hyprland, awesome, dwm)
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
- ✅ Wayland clipboard support (wl-clipboard)
