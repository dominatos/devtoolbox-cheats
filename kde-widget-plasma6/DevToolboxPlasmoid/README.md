# DevToolbox Cheats Plasmoid

A native KDE Plasma widget for managing, searching, and viewing Markdown cheatsheets.
Adapted from the [DevToolbox Cheats](https://github.com/dominatos/devtoolbox-cheats) bash script.

## Features
- **Library View**: Browse cheatsheets by category.
- **Search**: Real-time filtering by title or filename.
- **Copy**: One-click copy to clipboard (Wayland & X11 support).
- **Export**: Generate a single Markdown/PDF file from all cheats.
- **Native UI**: Integrates with Plasma theme (dark/light support).

## Installation

### Automatic (Recommended)
Run the install script:
```bash
./install-widget.sh
```

### Manual
For Plasma 6:
```bash
kpackagetool6 --type Plasma/Applet --install DevToolboxPlasmoid
```

For Plasma 5:
```bash
kpackagetool5 --type Plasma/Applet --install DevToolboxPlasmoid
```

## Configuration
1. Right-click the widget -> **Configure DevToolbox Cheats...**
2. Set the path to your cheats directory (default: `~/.config/argos/cheats.d`)
3. Set your preferred editor (default: `code`)

## dependencies
- `pandoc` (optional, for PDF export)
- `wl-copy` or `xclip` (for clipboard)
- `zenity` (not strictly needed for widget, but useful for fallback)
