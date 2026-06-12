# Changelog

## v1.4.35 (2026-06-12)

**Bug fixes:**
- 🐛 Fix: Resolved an issue where `fzf` would return 0 results because the internal `grep` pattern was accidentally removed during a previous code cleanup. The `.` pattern has been safely restored across all widgets and scripts to accurately feed files into `fzf`.

## v1.4.34 (2026-06-12)

**Bug fixes:**
- 🐛 Fix: Replaced standard `XMLHttpRequest.timeout` (which is often silently ignored by QML) with a dynamic `Timer`-based timeout to reliably enforce the 10-second limit during the version check (Plasma 5 & Plasma 6).
- 🐛 Fix: Ensured `globalCheatsModel` is cleared in Plasma 5 when the indexer encounters an error so that stale cache data isn't displayed alongside error messages.
- 🐛 Fix: Removed redundant single-quotes around `notify-send` variables in `FullRepresentation.qml` to prevent shell argument breaking when editor paths contain spaces.

## v1.4.33 (2026-06-12)

**Bug fixes:**
- 🐛 Fix: Resolved an issue where rapidly triggering `refreshCheats()` could cause stdout buffering interleaving by switching to per-command buffer mapping in `main.qml` (Plasma 5 & Plasma 6).
- 🐛 Fix: Removed an unintended leading dot (`.`) in the `fzfSearch()` internal `grep` command to prevent recursive searching of the current working directory.

## v1.4.32 (2026-06-12)

**New Features:**
- ✨ Feature: Added automatic GitHub version check for both Plasma 5 and Plasma 6 widgets. On startup, the widget performs a single asynchronous HTTP request to fetch `version.txt` from the main branch. If a newer version is available, an "⬆️ v..." update button appears in the widget header — clicking it opens the GitHub Releases page. The check can be disabled via a new "Automatically check for updates on startup" toggle in Settings.

## v1.4.31 (2026-06-12)

**Bug fixes:**
- ✅ Fix: Added proper error and exit code logging to the editor auto-detection background task in Plasma 6 to improve debuggability when fallback editors fail to detect.

## v1.4.30 (2026-06-12)

**Security:**
- 🔒 Fix: Escaped user-controlled configuration values (`cheatsDir`, `cacheFile`) in the Plasma 6 widget's indexer command to prevent shell injection. Previously these values were interpolated with only double-quote wrapping, which does not prevent `$()` or backtick expansion. Now uses single-quote escaping via shared `escapeShell()` / `bashSafePath()` utilities added to `cheats.js`.

## v1.4.29 (2026-06-12)

**Bug fixes:**
- ✅ Fix: Fixed a silent UI crash in the Plasma 6 widget that caused the "No cheatsheets found" empty state to persistently show even when cheats were successfully indexed in the background. The crash was caused by using `cheatsModel.slice()` to copy the model array. In Qt 6 QML, JavaScript arrays passed across component boundaries (from `main.qml` to `FullRepresentation.qml`) are implicitly converted to `QVariantList`, which does not support the `.slice()` method. Replaced it with a safe manual copy loop.

## v1.4.28 (2026-06-12)

**Bug fixes:**
- ✅ Fix: Removed the incorrectly applied `plasmaShield()` escaping from the Plasma 6 widget. The `plasmaShield()` function backslash-escapes every special character (including `/`, `.`, `-`), which was completely destroying file paths (e.g., `/home/user/cheats.d` → `\/home\/user\/cheats\.d`) and silently preventing the indexer from ever finding any cheatsheets. The `Plasma5Support.DataSource` executable engine does not strip characters and does not need this escaping.
- ✅ Fix: Removed orphaned dead code block in Plasma 5 `cheats.js`.
- ✅ Fix: Deleted accidentally committed `test_home.qml` scratch file.
- ✅ Fix: Moved `$EDITOR` resolution inside the terminal `bash -c` session in Plasma 5 `fzfSearch()` so that the variable is correctly exported into the `konsole`/`xterm` child process.

## v1.4.27 (2026-06-12)

**Bug fixes & Adjustments:**
- ✅ Fix: Fixed a critical bug in the Plasma 6 widget (`main.qml`) where the asynchronous data source would prematurely disconnect if the indexer script printed any `stderr` progress messages before exiting. The widget now properly waits for the bash script to finish (`exitCode !== undefined`) before evaluating the output, fixing the "No cheatsheets found" error.

## v1.4.26 (2026-06-12)

**Features & Refactoring:**
- ✨ Feature: Overhauled editor launch logic for both Plasma 5 and Plasma 6 widgets. If your configured editor isn't installed, the widget will display a warning notification and securely fall back through a massive, dynamically exported list of 23 popular GUI and CLI editors (`vscodium`, `zed`, `kate`, `nvim`, `hx`, etc.) to ensure cheatsheets always open successfully.
- ♻️ Refactor: Simplified FZF search `getFzfSearchCommand` to inherit the resolved `$EDITOR` directly from the QML logic rather than duplicating fallback behaviors, natively supporting smart `+line` jumping for CLI tools and `-g` for GUI tools.

## v1.4.25 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Fix: Improved shell escaping via a new `bashSafePath` helper to properly allow bash to expand `$HOME/` and `~/` paths while strictly escaping the rest of the string. This fixes an issue where the `fzfSearch` and Export features were failing when configured to point inside the user's home directory.
- ✅ Fix: Updated Plasma 5's `copyCheat` function to use the standard centralized `escapeShell` helper instead of a manual string replace.
- 🛠️ Internal: Updated `tofix-helper.py fetch` to automatically detect CodeRabbit AI rate limits. If a limit is hit, the script displays a live countdown timer and automatically triggers the next review via the GitHub CLI once the cooldown expires.

## v1.4.24 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Fix: Improved category search filtering in Plasma 5 to automatically expand categories that contain matches, making search results immediately visible.
- ✅ Security: Ensured the `copyCheat` and `exportCheat` functions in both widgets use strict shell escaping for all cheat paths, removing the final possible vector for shell injection.

## v1.4.23 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Security: Fixed shell injection vulnerabilities in Plasma 5/6 widgets by aggressively escaping user-supplied strings (`configuredEditor`, `detectedEditor`, `cheatPath`) before composing shell execution strings.
- ✅ Fix: Improved indexer error handling so it correctly treats commands with `exit 0` as success even if they emit warnings to `stderr`.

## v1.4.22 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Refactor: Consolidated the editor fallback logic into a single shared helper used by both `openCheat()` and `fzfSearch()`, ensuring consistent behavior.
- ✅ Fix: Ensured FZF Search aborts correctly if the fallback notification fails to send, preventing it from executing a terminal with an empty editor variable.

## v1.4.21 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Fix: Improved FZF Search editor validation. It now verifies the editor exists via `command -v` before launching, properly handles missing editors, and removes the hardcoded `"code"` fallback if no editor is found.

## v1.4.20 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Fix: Added proper `try-catch` blocks around `Cheats.parseIndexOutput()` in `main.qml` to prevent UI lockups if cheat parsing fails.
- ✅ Fix: Corrected editor fallback logic in `fzfSearch()` to properly respect the user's explicit preferred editor over the auto-detected editor.

## v1.4.19 (2026-06-11)

**Performance:**
- ✅ Categories now expand and collapse **instantly** (negligible delay). We implemented a QML signal-based update that prevents the `ListView` from unnecessarily destroying and rebuilding all 150+ cheat delegates whenever a single category is clicked.

## v1.4.18 (2026-06-11)

**Bug fixes & Adjustments:**
- ✅ Fix: Preserved QML property bindings by updating global state (`plasmoid.rootItem`) instead of writing to bound local properties in Plasma 5/6 widgets.
- ✅ Fix: Repaired a syntax issue with the filter function in Plasma 5 `FullRepresentation.qml`.
- ✅ Fix: Updated import paths to correctly resolve relative locations (`../code/`) in `main.qml`.
- ✅ Fix: Ensure the persistent cache is explicitly cleared if the indexer returns empty data, preventing stale entries from displaying.

## v1.4.17 (2026-06-11)

**Performance — KDE Widget Caching & Instant Loading:**
- ✅ Massive performance improvement for both Plasma 5 and Plasma 6 widgets. The widget now features **virtually instantaneous popup loading**.
- ✅ Moved data loading and index caching out of the ephemeral popup (`FullRepresentation.qml`) and into the persistent background root (`main.qml`).
- ✅ The widget now fully loads and parses your cheatsheets into RAM when the Plasma shell starts. The "Loading cheats..." spinner no longer appears on initial popup open because data is preloaded, eliminating the need to spawn `/bin/bash` subprocesses and D-Bus transfers every single time you click the widget icon.
- ✅ The "Refresh" button remains available if you add new `.md` files and want to manually trigger a re-index. The `globalIsLoading` flag is set during `refreshCheats()`, so the spinner will correctly appear when a manual refresh is requested.

## v1.4.16 (2026-06-10)

**Bug fixes & Adjustments:**
- ✅ Fix: KDE Plasma 5 and 6 widget config menus (`configGeneral.qml`) now dynamically pull the version string directly from `metadata.json` (`plasmoid.metadata.version`), avoiding the need for sed-based script updates and ensuring a single source of truth.
- ✅ Fix: Removed duplicate `v` prefix from the `generate-tldr.sh` output when displaying the `--version` or help menu.

---

## v1.4.15 (2026-06-10)

**Bug fixes & Adjustments:**
- ✅ Fix: FZF search in KDE 5 and older fzf versions. The `--preview-window 'right:60%'` option was passed with an invalid trailing space due to a KDE 5 Javascript escaping bug, and older `fzf` versions rejected the syntax entirely. Replaced across the entire codebase with the universal `--preview-window=right:60%` syntax.

---

## v1.4.14 (2026-06-10)

**Bug fixes & Layout adjustments:**
- ✅ Fix: Zenity and Yad dialogs now correctly display categories and cheatsheets containing ampersands (`&`). Previously, GTK's Pango markup parser would fail on unescaped ampersands, causing items like "Backups & S3" to disappear or create duplicated ghost rows.
- ✅ Fix: Added `VERSION` variable tracking to all scripts and KDE widgets, which is now displayed in the Settings menu.

---

## v1.4.13 (2026-06-10)

**Bug fixes & Layout adjustments:**
- ✅ Fix: On small screens (≤1368×768), the drilldown layout now correctly hides inline categories and only shows the "Browse all cheats" dialog entry point, making it consistent with the standard and zenity layouts.
- ✅ Fix: Changed Argos menu item syntax to use `param1` for passing script paths to `code` and `doublecmd`, preventing breakage when paths contain spaces.
- ✅ Fix: Escaped glob metacharacters (`[`, `]`, `*`, `?`) when searching for cheatsheets by filename, ensuring files containing brackets or wildcards are matched correctly.
- ✅ Fix: Notification "copied to clipboard" now conditionally triggers only if `CLIPBOARD_COPY` is set, with a fallback neutral message when missing.
- ✅ Fix: `ensure_cache` now correctly rebuilds (clears) the cache instead of leaving it stale when all markdown files have been deleted.
- ✅ Fix: `showSettings` now properly expands `\n` characters using `printf '%b'` so that the dialog doesn't display literal backslash-n sequences.
- ✅ Fix: Category cache files are now written atomically using a temporary file and `mv`, preventing partial or corrupted cache files if generation is interrupted.
- ✅ Fix: Category cache filenames are now generated using a collision-free `sha256sum` hash of the category name rather than a lossy alphanumeric normalization, preventing cache collisions between categories like `A+B` and `A/B`.
- ✅ Security: `ARGOS_CAT_STATE` now uses a private per-user directory instead of falling back to `/tmp`, and state files are written atomically using a temporary file to prevent symlink attacks and clobbered files.

---

## v1.4.12 (2026-06-09)

**Development & Alignment:**
- ✅ Synchronized the Argos menu structure in `devtoolbox-cheats.30s-separate-menu-DEV.sh` with the production script: added the `🛠 DevToolbox Functions` submenu, fixed panel button text to "🗒️ Cheatsheets", and removed collapsed/expanded logic so categories are always flat while preserving the drill-down `setCategory` action.

---

## v1.4.11 (2026-06-09)

**Development & Installation:**
- ✅ Created `install-dev.sh`: an interactive Argos script installer allowing users to select between the standard, zenity-list, and drill-down DEV variants, including an option to install all three simultaneously under distinct filenames.
- ✅ Synchronized the Argos menu structure in `devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh` with the production script: added the `🛠 DevToolbox Functions` submenu, fixed panel button text, and removed collapsed/expanded logic so categories are always flat and open the zenity dialog directly.

---

## v1.4.10 (2026-06-08)

**Development & Testing:**
- ✅ Isolate cache files for the DEV script (`devtoolbox-cheats.30s-separate-menu-DEV.sh`). The DEV script now writes to `~/.cache/devtoolbox-cheats-dev.idx` and `~/.cache/devtoolbox-cheats-argos-dev/` to ensure it never interferes with or pollutes the production script's cache.

---

## v1.4.9 (2026-06-08)

**Performance — Cache Fixes (DEV script + production script):**
- ✅ Fix critical bug: `CHEATS_REBUILD=0` was treated as truthy by `[[ -n ... ]]`, causing a full re-index of all 158 cheatsheets on **every** script invocation. Changed to `CHEATS_REBUILD=""` so the cache is correctly used. Fixed in both `devtoolbox-cheats.30s-separate-menu-DEV.sh` and `devtoolbox-cheats.30s.sh`.
- ✅ Add `_CACHE_CHECKED` per-process guard in `ensure_cache()` (DEV script): eliminates redundant `find` mtime scans when multiple action functions call `ensure_cache()` in the same shell invocation (e.g. `standaloneMenu` → `browseAllCheatsFS`).
- ✅ Cache `get_screen_dims()` result in `_SCREEN_DIMS_CACHED` (DEV script): `xdpyinfo`/`xrandr` is now queried at most once per run instead of on every `list_dialog()` and `text_dialog()` call.
- ✅ Cache `base64` flag detection at startup in `_B64ENC_FLAG` (DEV script): eliminates `base64 --help | grep` subprocess pair spawned on every `b64enc()` call (was called once per cheatsheet in Argos render loop, 158×/run).
- ✅ Remove redundant identity `awk` passthrough in `argos_category_lines()` and Argos expanded-mode render loop (DEV script): the second `awk` was reading and re-printing the same TSV unchanged.

---

## v1.4.8 (2026-06-08)

**Codebase & Documentation Alignment:**
- ✅ `README.md`: Updated 'Usage' instructions to accurately reflect the new GNOME Argos `🛠 DevToolbox Functions` submenu introduced in v1.4.4.
- ✅ `README.md`: Updated the 'Other DEs (Dialog Menu)' section to document the inline categories and new buttons added in v1.4.5.
- ✅ Fix: The `CHEAT_VIEWERS` environment variable couldn't be overridden by the user because its value was hardcoded inside the script. This bug is now fixed, and it properly respects custom overrides while defaulting to a much larger list of popular editors: `"code codium antigravity windsurf subl kate kwrite geany gedit mousepad pluma xed notepadqq zenity"`.

---

## v1.4.7 (2026-06-08)

**Installation:**
- ✅ `install.sh`: The GNOME Argos installer now also deploys `devtools.1m.sh` to provide an additional tools menu panel
- ✅ Documentation: Added a note about the new DevTools menu to the Argos section in `README.md`

---

## v1.4.6 (2026-06-08)

**Bug fixes:**
- ✅ Fix: Argos `⚙️ Settings` entry in `🛠 DevToolbox Functions` submenu now shows the Settings info dialog correctly — previously it opened the full `standaloneMenu()` instead
- ✅ Add dedicated `showSettings()` function + `showSettings` dispatch action so the info dialog can be triggered directly from Argos without launching the full navigation menu
- ✅ Fix: `CHEATS_REBUILD=1` → `0` — the debug flag was left hardcoded, causing a full cheatsheet re-index on **every** script invocation; menus are now fast (cache is rebuilt only when `.md` files change)
- ✅ Fix: Argos small-screen layout accidentally nested 'Edit this script' and 'Go to Argos folder' as a submenu under 'Open compact menu'. Removed `--` prefix to render them as top-level items.

---

## v1.4.5 (2026-06-08)

**Dialog menus — Inline Category Listing:**
- ✅ `standaloneMenu()`: categories are now listed inline directly after functional buttons — no extra click needed to browse cheatsheets
- ✅ `compactMenu()`: same inline category listing added
- ✅ Both menus: added `"── Categories ──"` label divider between functional buttons and category list
- ✅ `compactMenu()`: added `⚙️ Settings` button (previously only in `standaloneMenu()`)
- ✅ Argos `🛠 DevToolbox Functions` submenu: added `⚙️ Settings` entry (launches `standaloneMenu`)
- ✅ Clicking a category calls `browseDeep_Cheats()` directly — reduces navigation from 3 clicks to 2
- ✅ `"── Categories ──"` divider is a no-op (re-shows the menu if clicked)
- ✅ `browseAllCheatsFS()` function and `📚 Browse all cheats` menu item are preserved unchanged
- ✅ No impact on GNOME Argos menu layout, KDE widget, or DE detection logic

---

## v1.4.4 (2026-06-08)

**GNOME Argos — Functions Submenu:**
- ✅ Normal-screen layout: moved all 6 functional buttons (Compact Menu, Search, FZF Search, Export, Online Version, GitHub) into a collapsible `🛠 Functions` submenu
- ✅ Functions submenu appears before cheatsheet category groups — reclaims top-level Argos dropdown space for categories
- ✅ Small-screen layout is unchanged (existing behavior preserved)
- ✅ No impact on KDE, XFCE, dialog-based, or terminal DE paths

---

## v1.4.3 (2026-06-06)

**GNOME Argos — Auto-Adaptive Menu Layout:**
- ✅ Fix: categories with submenus were invisible on 1080p screens — GNOME Shell clipped submenus when the dropdown exceeded screen height
- ✅ Add `calc_max_argos_groups()` function — dynamically calculates the safe maximum number of top-level category groups based on screen resolution
- ✅ Collapsed mode: when group count exceeds the screen-safe threshold (e.g. 19 groups on 1080p), all categories are nested under **📂 Browse by Category** with `----` third-level submenu items — ensuring submenus always have room to render
- ✅ Expanded mode: original behavior preserved when screen is large enough (e.g. ≥1440p with current group count)
- ✅ Formula: `(screen_height − 30px) / 28px × 60%` — the 60% factor reserves vertical space for submenu rendering
- ✅ No new external dependencies — reuses existing `get_screen_dims()`
- ✅ No impact on KDE, XFCE, dialog-based, or terminal DE paths

---

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

## v1.0-beta (2026-02-23)

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
