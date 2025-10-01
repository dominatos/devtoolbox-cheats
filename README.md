# 📒 DevToolbox Cheats — Argos Menu for Markdown Cheatsheets

## Overview
**DevToolbox Cheats** is an [Argos](https://github.com/p-e-w/argos) extension script that creates a dynamic panel menu with your personal **Markdown cheatsheets**.  
It allows you to:

- 📚 Browse cheats by categories (groups)  
- 🔎 Search cheats interactively  
- 📥 Export all cheats into a single Markdown (and PDF if `pandoc` is installed)  
- ⚡ Copy cheats instantly to clipboard  
- 🖥️ View cheats in a resizable popup window  

Everything is managed through a single Bash script and a folder of `.md` files.

---

## Features
- **Categories (Groups):** Cheatsheets are organized by front-matter metadata  
- **Clipboard Integration:** Copies cheat body automatically (supports Wayland and X11)  
- **Export:** Generate one big “mega cheatsheet” in Markdown, optionally PDF  
- **Smart Cache:** Re-indexes only when cheatsheets change  
- **Compact Mode:** Quick menu with just search/browse/export  

---

## Installation
### Requirements
- Linux with **GNOME/Argos extension**  
- `bash`, `coreutils`, `grep`, `sed`, `awk`, `find`, `stat`  
- `zenity` (for dialogs)  
- `xclip` or `wl-clipboard` (for clipboard copy)  
- `pandoc` (optional, for PDF export)

### Quick setup
```bash
mkdir -p ~/.config/argos ~/.config/argos/cheats.d

# Download the script
curl -fsSL -o ~/.config/argos/devtoolbox-cheats.30s.sh \
  https://raw.githubusercontent.com/<your-user>/devtoolbox-cheats/main/devtoolbox-cheats.30s.sh

chmod +x ~/.config/argos/devtoolbox-cheats.30s.sh
```

Reload GNOME shell (`Alt+F2 → r → Enter`) or restart Argos — you should see **🗒️ Cheatsheet** in your panel.

---

## Usage
- **Panel Menu**
  - 🔎 Search cheats
  - 📚 Browse cheats by group
  - 📥 Export all cheats
- **Compact menu** (for small screens) → one dialog with all three actions  
- **Shortcuts in menu**: Open cheats folder, LAB folder, edit script in VS Code

---

## Cheatsheet Format
Each cheatsheet is a simple Markdown file (`.md`) with optional **front-matter keys** in the first 80 lines.

### Example file: `cheats.d/rsync.md`
```markdown
Title: rsync basics
Group: Basics
Icon: 🔄
Order: 10

rsync -avh /src/ /dst/  
Copies files in archive mode with human-readable sizes.

rsync -avz -e "ssh -p 2222" user@host:/data/ /backup/  
Transfer over SSH with compression and custom port.
```

- **Title** → Displayed name in menu  
- **Group** → Category (must match one of the defined groups; defaults to `Misc`)  
- **Icon** → Optional emoji shown before the title  
- **Order** → Sorting within group (lowest first)

---

## Creating New Categories
Categories are defined in the script with an associated emoji.  
To add one, edit `devtoolbox-cheats.30s.sh`:

```bash
declare -A GROUP_ICON=(
  ["Basics"]="📚"
  ["Network"]="📡"
  ["Databases"]="🗃️"
  ["Security"]="🔐"
  ["Misc"]="🧩"
  ["My Custom Group"]="✨"   # ← Add your custom category here
)
```

Then in your Markdown file front-matter:
```markdown
Title: Docker CLI
Group: My Custom Group
Icon: 🐳
Order: 5

docker ps -a  
List all containers including stopped ones.
```

---

## Export Cheats
Click **📥 Export all (MD/PDF)** in the menu, and it will generate:
- `~/DevToolbox-Cheatsheet_<timestamp>.md`  
- `~/DevToolbox-Cheatsheet_<timestamp>.pdf` (if `pandoc` is available)

---

## Configuration
You can override defaults via environment variables:
- `CHEATS_DIR` → path to `.md` cheats (default `~/.config/argos/cheats.d`)  
- `CHEATS_CACHE` → index file (default `~/.cache/devtoolbox-cheats.idx`)  
- `CHEATS_REBUILD=1` → force rebuild cache on every run  
- `EXPORT_MODE=1` → make `showCheat` print Markdown to stdout instead of showing popup  

---

## Example Screenshots

![Main menu](docs/img/menu.png)
![Sub menu](docs/img/cat.png)
![One item](docs/img/item.png)

---

## Roadmap
- ✅ Initial release with categories, search, export  
- 🔄 Optional fallback to `yad` if `zenity` missing  
- 🔄 HTML/EPUB export with `pandoc`  
- 🔄 Automatic installer script  

## Included categories

The repository already ships with a structured set of categories (groups):

- 📚 **Basics**
- 📡 **Network**
- 💿 **Storage & FS**
- 🗄️ **Backups & S3**
- 📦 **Files & Archives**
- 📝 **Text & Parsing**
- ☸️ **Kubernetes & Containers**
- 🛠 **System & Logs**
- 🌐 **Web Servers**
- 🗃️ **Databases**
- 📦 **Package Managers**
- 🔐 **Security & Crypto**
- 🧬 **Dev & Tools**
- 🧩 **Misc**


## Included cheats (selected)

This repository already includes ready-to-use cheatsheets for popular tools:

**Basics & Files**
- `rsync`, `cp/mv/ln`, `tar`, `zip/unzip`, `find`, `grep`, `sed`, `awk`

**Network**
- `ssh/scp/sftp`, `curl/httpie`, `iptables/nft`, `ss/iptables`

**Text & Parsing**
- `jq`, `awk`, `sed`, `ripgrep`

**Kubernetes & Containers**
- `kubectl`, `helm`, `docker` / `podman`, `containerd`, `k9s`

**System & Logs**
- `systemctl`, `journalctl`, `top/htop/btop`, `dmesg`

**Web Servers**
- `nginx`, `apache2`

**Databases**
- `mysql/mariadb`, `postgresql`, `mongodb`, `redis`

**Backups & S3**
- `rclone`, `aws s3 / awscli`, `restic`, `borg`

**Security & Crypto**
- `openssl`, `gpg`, `ssh-keygen`

> Each cheat lives as a Markdown file under `cheats.d/` with front-matter (`Title`, `Group`, `Icon`, `Order`).

---

## License
MIT License — feel free to fork, adapt, and share. Contributions welcome!
