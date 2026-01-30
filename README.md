# 📒 DevToolbox Cheats — Argos Menu for Markdown Cheatsheets
[![stars](https://img.shields.io/github/stars/dominatos/devtoolbox-cheats)](https://github.com/dominatos/devtoolbox-cheats)

## Overview
**DevToolbox Cheats** is an [Argos](https://github.com/p-e-w/argos) extension script that creates a dynamic panel menu with your personal **Markdown cheatsheets**.  
It allows you to:

- 📚 Browse cheats by categories (groups)  
- 🔎 Search cheats interactively  
- 📥 Export all cheats into a single Markdown (and PDF if `pandoc` is installed)  
- ⚡ Copy cheats instantly to clipboard (Wayland/X11 compatible)  
- 🖥️ View cheats in Visual Code or a resizable popup window 
- 🖼️ Compact mode for small screens  

Everything is managed through a single Bash script and a folder of `.md` files.

---

## Example Screenshots

![Main menu](docs/img/menu.png)
![Sub menu](docs/img/cat.png)
![One item](docs/img/item.png)

---

## Features
- **Categories (Groups):** Cheatsheets are organized by front-matter metadata (`Title`, `Group`, `Icon`, `Order`)  
- **Clipboard Integration:** Copies cheat body automatically, supports Wayland (`wl-copy`) and X11 (`xclip`)  
- **Export:** Generate one big “mega cheatsheet” in Markdown, optionally PDF if `pandoc` is installed  
- **Smart Cache:** Re-indexes only when cheatsheets change; `CHEATS_REBUILD=1` forces rebuild  
- **Compact Mode:** Quick menu with all main actions in one dialog  
- **Popup Viewer:** Resizable popup for Zenity dialogs; falls back to `cat`, `less`, `xterm`, or custom viewers  
- **Base64-safe Parameters:** Works with Argos menu parameters safely

---

## Installation
### Requirements
- Linux with **GNOME/Argos extension**  
- `bash`, `coreutils`, `grep`, `sed`, `awk`, `find`, `stat`  
- `visual code` `zenity` (for view and dialogs)  
- `xclip` or `wl-clipboard` (clipboard support)  
- `pandoc` (optional, for PDF export)

### Quick Setup
```bash
mkdir -p ~/.config/argos ~/.config/argos/cheats.d

# Download the script
curl -fsSL -o ~/.config/argos/devtoolbox-cheats.30s.sh   https://raw.githubusercontent.com/dominatos/devtoolbox-cheats/refs/heads/main/devtoolbox-cheats.30s.sh

chmod +x ~/.config/argos/devtoolbox-cheats.30s.sh
```

Reload GNOME shell (`Alt+F2 → r → Enter`) or restart Argos — you should see **🗒️ Cheatsheet** in your panel.

---

## Usage
- **Panel Menu**
  - 🔎 Search cheats
  - 📚 Browse all cheats by group
  - 📥 Export all cheats (Markdown / PDF)
- **Compact menu** → combines search, browse, and export in one dialog (useful for small screens)  
- **Shortcuts** in menu:
  - Open cheats folder (`~/.config/argos/cheats.d/`)  
  - Open LAB folder (`~/Documents/LAB/`)  
  - Edit script in VS Code

---

## Cheatsheet Format
Each cheatsheet is a simple Markdown file (`.md`) with optional **front-matter keys** in the first 80 lines.

### Example file: `cheats.d/network/rsync.md`
```markdown
Title: rsync basics
Group: Network
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
To add one, edit `devtoolbox-cheats.sh`:

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
Environment variables:

- `CHEATS_DIR` → path to `.md` cheats (default `~/.config/argos/cheats.d`)  
- `CHEATS_CACHE` → index file (default `~/.cache/devtoolbox-cheats.idx`)  
- `CHEATS_REBUILD=1` → force cache rebuild every run  
- `EXPORT_MODE=1` → print Markdown to stdout instead of showing popup  

---

## Roadmap
- ✅ Improved indexing & caching  
- ✅ Compact menu for small screens  
- 🔄 Optional fallback to `yad` if `zenity` is missing  
- 🔄 HTML/EPUB export via `pandoc`  
- 🔄 Automatic installer script  

---

## Included categories

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
- 🔎 **Diagnostics**


## Included cheats (selected)

This repository already includes ready-to-use cheatsheets for popular tools:

### Backups 0 S3
- [🗄️ rclone — Remotes/S3](cheats.d/backups-s3/rclonecheatsheet.md)
- [🗄️ restic — Backups](cheats.d/backups-s3/resticcheatsheet.md)

### Basics
- [📗 Linux Basics 2 — Next Steps](cheats.d/basics/linuxbasics2cheatsheet.md)
- [📚 Linux Basics — Cheatsheet](cheats.d/basics/linuxbasicscheatsheet.md)

### Databases
- [🍃 MongoDB — Cheatsheet](cheats.d/databases/mongodbcheatsheet.md)
- [🗃️ MySQL/MariaDB](cheats.d/databases/mysqlcheatsheet.md)
- [🔎 OpenSearch — Cheatsheet](cheats.d/databases/opensearchcheatsheet.md)
- [🗃️ PostgreSQL — psql/pg_dump](cheats.d/databases/postgrescheatsheet.md)
- [🗃️ SQLite](cheats.d/databases/sqlitecheatsheet.md)

### Dev 0 Tools
- [🛠️ Build — Make/CMake](cheats.d/dev-tools/buildtoolscheatsheet.md)
- [🧬 Git — Advanced](cheats.d/dev-tools/gitadvancedcheatsheet.md)
- [🧬 Git — Basics](cheats.d/dev-tools/gitcheatsheet.md)
- [🟢 Node — nvm/npm/yarn](cheats.d/dev-tools/nodetoolscheatsheet.md)
- [🐍 Python — venv/pip/pipx](cheats.d/dev-tools/pythontoolscheatsheet.md)
- [🧷 tmux — Commands](cheats.d/dev-tools/tmuxcheatsheet.md)

### Diagnostics
- [🔍 strace / perf / tcpdump — Commands](cheats.d/diagnostics/diagcheatsheet.md)

### Files 0 Archives
- [🔁 diff / patch — Commands](cheats.d/files-archives/diffpatchcheatsheet.md)
- [📦 TAR — Commands](cheats.d/files-archives/tarcheatsheet.md)
- [📦 TAR (zstd) — Commands](cheats.d/files-archives/tarzstdcheatsheet.md)
- [📦 ZIP / 7z / ZSTD — Commands](cheats.d/files-archives/zip7zzstdcheatsheet.md)

### Kubernetes 0 Containers
- [🐳 Docker — Commands](cheats.d/kubernetes-containers/dockercheatsheet.md)
- [⛏ Helm — Commands](cheats.d/kubernetes-containers/helmcheatsheet.md)
- [⛏ Helm — template/lint](cheats.d/kubernetes-containers/helmtemplatelintcheatsheet.md)
- [🎛 k9s — Hotkeys](cheats.d/kubernetes-containers/k9scheatsheet.md)
- [☸️ KUBECTL — Commands](cheats.d/kubernetes-containers/kubectlcheatsheet.md)
- [☸️ KUBECTL — JSONPath](cheats.d/kubernetes-containers/kubectljsonpathcheatsheet.md)
- [☸️ Kustomize — kustomization.yaml](cheats.d/kubernetes-containers/kubectlkustomizecheatsheet.md)
- [🫙 Podman / nerdctl — Commands](cheats.d/kubernetes-containers/podmannerdctlcheatsheet.md)

### Network
- [🔁 autossh — Resilient tunnels](cheats.d/network/autosshcheatsheet.md)
- [🌐 CURL — Commands](cheats.d/network/curlcheatsheet.md)
- [🧭 DNS — dig/nslookup](cheats.d/network/dnscheatsheet.md)
- [🚓 Fail2Ban — Commands](cheats.d/network/fail2bancheatsheet.md)
- [🔥 firewalld — Commands](cheats.d/network/firewalldcheatsheet.md)
- [🌐 ip — Commands](cheats.d/network/ipcheatsheet.md)
- [🔥 iptables — Commands](cheats.d/network/iptablescheatsheet.md)
- [🔁 iptables → nftables — Mapping](cheats.d/network/iptablesnfttranslatecheatsheet.md)
- [🔌 nc / nmap — Commands](cheats.d/network/ncnmapcheatsheet.md)
- [🛰️ Network diag — mtr/traceroute/iperf3](cheats.d/network/netdiagcheatsheet.md)
- [🕸 nftables — Commands](cheats.d/network/nftcheatsheet.md)
- [🚚 RSYNC — Commands](cheats.d/network/rsynccheatsheet.md)
- [🔐 SCP — Commands](cheats.d/network/scpcheatsheet.md)
- [🔑 SSH — Commands 0 Config](cheats.d/network/sshcheatsheet.md)
- [📡 SS — Socket Stats](cheats.d/network/sscheatsheet.md)
- [🧱 UFW — Commands](cheats.d/network/ufwcheatsheet.md)
- [🔐 WireGuard — Quickstart](cheats.d/network/wireguardcheatsheet.md)
- [🔑 🔑 SSH / VPN / Port Forwarding](cheats.d/network/ssh_vpn_tunnel_cheatsheet.md)
- [🖧 🖧 resolvectl](cheats.d/network/resolvectlcheatsheet.md)


### Package Managers
- [📦 Package Managers](cheats.d/package-managers/pkgmanagerscheatsheet.md)

### Security 0 Crypto
- [CrowdSec Cheatsheet](cheats.d/security-crypto/crowdseccheatsheet.md)
- [🔐 gpg / age](cheats.d/security-crypto/gpgagecheatsheet.md)
- [🔐 OpenSSL — Commands](cheats.d/security-crypto/opensslcheatsheet.md)
- [🔐 OpenSSL — CSR with SAN](cheats.d/security-crypto/opensslsancsrcheatsheet.md)
- [🔐 pass — Password Store](cheats.d/security-crypto/passcheatsheet.md)

### Storage 0 FS
- [💿 Grow Disk (Cloud EXT4/XFS)](cheats.d/storage-fs/diskgrowcheatsheet.md)
- [💿 LVM — Basics](cheats.d/storage-fs/lvmcheatsheet.md)
- [💿 Partition 0 Mount](cheats.d/storage-fs/partitionmountcheatsheet.md)
- [💿 SMART 0 mdadm RAID](cheats.d/storage-fs/smartraidcheatsheet.md)
- [💿 ACL Cheat Sheet for Linux](cheats.d/storage-fs/aclcheatsheet.md)

### System 0 Logs
- [⏰ cron / at — Commands](cheats.d/system-logs/cronatcheatsheet.md)
- [📅 date / TZ — Commands](cheats.d/system-logs/datetzcheatsheet.md)
- [💽 du/df/lsof/ps — Commands](cheats.d/system-logs/diskproccheatsheet.md)
- [📜 journalctl — Basics](cheats.d/system-logs/journalctlbasicscheatsheet.md)
- [📜 journalctl — Commands](cheats.d/system-logs/journalctlcheatsheet.md)
- [🌀 logrotate — Basics](cheats.d/system-logs/logrotatecheatsheet.md)
- [🛡️ SELinux / AppArmor — Basic diag](cheats.d/system-logs/selinuxapparmorcheatsheet.md)
- [🛠 systemctl — Commands](cheats.d/system-logs/systemctlcheatsheet.md)
- [🕰️ systemd timers — Basics](cheats.d/system-logs/systemdtimerscheatsheet.md)
- [🧩 systemd unit — template](cheats.d/system-logs/systemdunittemplate.md)
- [📜 📜 Ionice nice](cheats.d/system-logs/ionicenicescheatsheet.md)
- [📜 📜 Kernel-panic RHEL](cheats.d/system-logs/kernelpanicscheatsheet.md)

### Text 0 Parsing
- [🦾 AWK — Commands](cheats.d/text-parsing/awkcheatsheet.md)
- [🌀 Bash — Loops](cheats.d/text-parsing/loopscheatsheet.md)
- [🔪 cut/sort/uniq — Commands](cheats.d/text-parsing/cutsortuniqcheatsheet.md)
- [🗃 FIND — Commands](cheats.d/text-parsing/findcheatsheet.md)
- [⚡ fzf — Fuzzy Finder](cheats.d/text-parsing/fzfcheatsheet.md)
- [🔎 GREP — Commands](cheats.d/text-parsing/grepcheatsheet.md)
- [🧩 JQ — Commands](cheats.d/text-parsing/jqcheatsheet.md)
- [⚡ ripgrep / fd / bat](cheats.d/text-parsing/modernclicheatsheet.md)
- [✂️ SED — Commands](cheats.d/text-parsing/sedcheatsheet.md)
- [Tree — Cheatsheet](cheats.d/text-parsing/treecheatsheet.md)
- [🔤 tr/head/tail/watch — Commands](cheats.d/text-parsing/trheadtailwatchcheatsheet.md)
- [✍️ vim](cheats.d/text-parsing/vimquickstartcheatsheet.md)
- [🧪 yq — YAML processor](cheats.d/text-parsing/yqcheatsheet.md)

### Web Servers
- [🪶 Apache HTTPD — Cheatsheet](cheats.d/web-servers/apachecheatsheet.md)
- [🌐 Nginx — Cheatsheet](cheats.d/web-servers/nginxcheatsheet.md)
- [🐱 Tomcat — Cheatsheet](cheats.d/web-servers/tomcatcheatsheet.md)
- [🌀 🌀 HAProxy — Cheatsheet](cheats.d/web-servers/haproxycheatsheet.md)
---

> Each cheat lives as a Markdown file under `cheats.d/` with front-matter (`Title`, `Group`, `Icon`, `Order`).

---

## License
MIT License — feel free to fork, adapt, and share. Contributions welcome!
