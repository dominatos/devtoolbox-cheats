# 📝 Changelog

### v1.1.1 (2026-03-04)

**Documentation Updates:**
- ✅ Simplified manual `.desktop` creation instructions for all Desktop Environments (Cosmic, Budgie, Deepin, etc.)
- ✅ Updated panel commands for XFCE, MATE, Cinnamon, LXQt to point to the universal executable `devtoolbox-cheats-menu`
- ✅ Updated Tiling WM configurations (i3, sway, bspwm, hyprland) to use the new `devtoolbox-cheats-menu` binary

---

### v1.1 (2026-03-04)

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

### v1.0 Beta (2026-02-23)

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
