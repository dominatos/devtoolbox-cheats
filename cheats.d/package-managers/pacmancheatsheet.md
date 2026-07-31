---
Title: 🟢 Pacman — Arch Linux
Group: Package Managers
Icon: 🟢
Order: 3
tags:
  - package-managers
  - sysadmin
  - linux
---

## Table of Contents
- [Description](#Description)
- [Configuration](#️%20Configuration)
- [Core Management](#Core%20Management)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Troubleshooting](#Troubleshooting)
- [Security & Verification](#Security%20&%20Verification)
- [Documentation Links](#Documentation%20Links)

---

# 🟢 Pacman Cheatsheet (Arch Linux)

## Description

**Pacman** is the package manager for Arch Linux and its derivatives (Manjaro, EndeavourOS, Garuda Linux). It uses simple compressed tar archives (`.pkg.tar.zst`) for packages and maintains a text-based package database. Designed for the rolling release model, pacman keeps the entire system up to date with a single command. / **Pacman** — менеджер пакетов для Arch Linux и его производных. Использует сжатые tar-архивы и текстовую базу данных пакетов.

**Status:** Actively maintained. Pacman is the core tool of the Arch ecosystem and is tightly integrated with the AUR (Arch User Repository) via helpers like `yay` and `paru`. / **Статус:** Активно поддерживается. Ядро экосистемы Arch, интегрирован с AUR.

**Default Ports:** N/A (local tool)
**Package Format:** `.pkg.tar.zst`

---

## ⚙️ Configuration

### Main Configuration Files
`/etc/pacman.conf`
`/etc/pacman.d/mirrorlist`

### Mirrorlist Management
Generate mirrorlist using `reflector`. / Генерация списка зеркал с помощью `reflector`.

```bash
sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
```

### Parallel Downloads
To speed up downloads, enable parallel downloads in `/etc/pacman.conf`. / Чтобы ускорить загрузку, включите параллельные загрузки в `/etc/pacman.conf`.

```ini
PowerPill = /usr/bin/powerpill
ParallelDownloads = 5
```

---

## 🛠 Core Management

### Sync & Upgrade
> [!WARNING]
> Never run `pacman -Sy` (sync only) without upgrading (`-u`). Partial upgrades are unsupported and can break your system. / Никогда не запускайте `pacman -Sy` без обновления (`-u`). Частичные обновления не поддерживаются и могут сломать систему.

```bash
sudo pacman -Syu                              # Synchronize repos and update system / Синхронизировать репозитории и обновить систему
sudo pacman -Syyu                             # Force refresh repos and update / Принудительно обновить репозитории и систему
sudo pacman -Sy                               # Sync repositories (DO NOT USE before install) / Синхронизировать репозитории
sudo pacman -Su                               # Upgrade packages (without sync) / Обновить пакеты (без синхронизации)
```

### Install & Remove
```bash
sudo pacman -S <PACKAGE>                      # Install package / Установить пакет
sudo pacman -S <PKG1> <PKG2>                  # Install multiple / Установить несколько
sudo pacman -S <GROUP_NAME>                   # Install package group / Установить группу пакетов
sudo pacman -U <PATH_TO_PKG.tar.zst>          # Install local package / Установить локальный пакет
sudo pacman -R <PACKAGE>                      # Remove package / Удалить пакет
sudo pacman -Rs <PACKAGE>                     # Remove with unused dependencies (Best practice) / Удалить с неиспользуемыми зависимостями
sudo pacman -Rns <PACKAGE>                    # Remove with deps and configs (Cleanest) / Удалить с зависимостями и конфигами
```

### Search & Query
```bash
pacman -Ss <KEYWORD>                          # Search in repositories / Поиск в репозиториях
pacman -Si <PACKAGE>                          # Info about package in repo / Инфо о пакете в репозитории
pacman -Qs <KEYWORD>                          # Search installed packages / Поиск установленных пакетов
pacman -Qi <PACKAGE>                          # Info about installed package / Инфо об установленном пакете
pacman -Qo <FILE_PATH>                        # Find package owning file / Найти пакет, владеющий файлом
pacman -Qdt                                   # List orphans (deps no longer needed) / Список сирот
pacman -Qe                                    # List explicitly installed packages / Список явно установленных пакетов
pacman -Qkk <PACKAGE>                         # Verify package files / Проверить файлы пакета
```

---

## 🔧 Sysadmin Operations

### Clean & Maintenance
Manage disk space used by pacman cache. / Управление дисковым пространством, используемым кэшем pacman.

```bash
sudo pacman -Sc                               # Remove old packages from cache / Удалить старые пакеты из кэша
sudo pacman -Scc                              # Remove all packages from cache (Aggressive) / Удалить все пакеты из кэша
sudo paccache -r                              # Keep only last 3 versions (requires pacman-contrib) / Оставить только 3 последние версии
sudo pacman -Rns $(pacman -Qdtq)              # Remove all orphans / Удалить всех сирот
```

### AUR Helpers (Yay/Paru)
AUR (Arch User Repository) contains community packages. / AUR содержит пакеты сообщества.

```bash
yay -Syu                                      # Update system including AUR / Обновить систему, включая AUR
yay -S <AUR_PACKAGE>                          # Install from AUR / Установить из AUR
yay -Rns <PACKAGE>                            # Remove package / Удалить пакет
yay -Yc                                       # Clean unused AUR dependencies / Очистить неиспользуемые зависимости AUR
```

### Logs
- **Pacman Log:** `/var/log/pacman.log` - History of pacman actions.

```bash
grep "upgraded" /var/log/pacman.log | tail      # Show recently upgraded packages / Показать недавно обновленные пакеты
grep "installed" /var/log/pacman.log | tail     # Show recently installed packages / Показать недавно установленные пакеты
```

---

## 🚨 Troubleshooting

### Lock File
If pacman is interrupted:
```bash
sudo rm /var/lib/pacman/db.lck                # Remove lock file / Удалить файл блокировки
```

### Keyring Issues
If you get "signature from ... is unknown trust":
```bash
sudo pacman -Sy archlinux-keyring             # Update keyring first / Сначала обновить связку ключей
sudo pacman-key --init                        # Initialize keyring / Инициализировать связку ключей
sudo pacman-key --populate archlinux          # Populate keys / Заполнить ключи
sudo pacman-key --refresh-keys                # Refresh keys / Обновить ключи
```

### File Conflicts
If "exists in filesystem":
```bash
sudo pacman -S --overwrite='*' <PACKAGE>      # Force overwrite files / Принудительно перезаписать файлы
```

---

## 🔒 Security & Verification
Check for modified configuration files (`.pacnew`). / Проверка измененных конфигурационных файлов.

```bash
sudo pacdiff                                  # Manage pacnew files / Управление файлами pacnew
```

---

## 📚 Documentation Links

- **Arch Wiki — Pacman:** https://wiki.archlinux.org/title/Pacman
- **Pacman Man Page:** https://man.archlinux.org/man/pacman.8
- **Arch Wiki — AUR:** https://wiki.archlinux.org/title/Arch_User_Repository
- **Pacman Tips & Tricks:** https://wiki.archlinux.org/title/Pacman/Tips_and_tricks
- **Pacman Rosetta (cross-distro):** https://wiki.archlinux.org/title/Pacman/Rosetta
