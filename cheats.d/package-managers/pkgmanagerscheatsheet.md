Title: 📦 Package Managers — APT/DNF/Pacman/Snap/Flatpak
Group: Package Managers
Icon: 📦
Order: 0

## Table of Contents
- [Description](#description)
- [APT — Debian/Ubuntu](#-apt--debianubuntu)
- [DNF — RHEL/Fedora](#-dnf--rhelfedora)
- [Pacman — Arch Linux](#-pacman--arch-linux)
- [Zypper — OpenSUSE](#-zypper--opensuse)
- [Snap — Universal Packages](#-snap--universal-packages)
- [Flatpak — Application Sandboxes](#-flatpak--application-sandboxes)
- [AppImage — Portable Apps](#-appimage--portable-apps)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Cross-Reference Comparison](#-cross-reference-comparison--сравнение-менеджеров-пакетов)
- [Best Practices](#-best-practices--лучшие-практики)
- [Configuration Files](#-configuration-files--файлы-конфигурации)
- [Documentation Links](#-documentation-links)

---

## Description

This cheatsheet is a **consolidated quick-reference** for all major Linux package managers. It provides the most common commands for each manager side-by-side, making it easy to switch between distributions. / Эта шпаргалка — **консолидированная справка** по всем основным менеджерам пакетов Linux. Она предоставляет наиболее частые команды для каждого менеджера бок о бок, облегчая переключение между дистрибутивами.

For detailed cheatsheets on each package manager, see dedicated files in this directory. / Для подробных шпаргалок по каждому менеджеру смотрите отдельные файлы в этой директории.

> [!TIP]
> **When to use what:** Use your distro's native package manager (APT, DNF, Pacman, Zypper) for system packages. Use Flatpak/Snap for sandboxed desktop apps. Use AppImage for portable single-file applications. / Используйте нативный менеджер дистрибутива для системных пакетов, Flatpak/Snap — для изолированных десктопных приложений, AppImage — для портативных приложений.

---

# 📦 APT — Debian/Ubuntu

### Update & Upgrade / Обновление
```bash
sudo apt update                               # Update package lists / Обновить списки пакетов
sudo apt upgrade                              # Upgrade packages / Обновить пакеты
sudo apt full-upgrade                         # Full upgrade (remove conflicting) / Полное обновление
sudo apt dist-upgrade                         # Distribution upgrade / Обновление дистрибутива
sudo apt update && sudo apt upgrade -y        # Update and upgrade / Обновить и обновить пакеты
```

### Install & Remove / Установка и удаление
```bash
sudo apt install <PACKAGE>                    # Install package / Установить пакет
sudo apt install <PKG1> <PKG2> <PKG3>         # Install multiple / Установить несколько
sudo apt remove <PACKAGE>                     # Remove package / Удалить пакет
sudo apt purge <PACKAGE>                      # Remove with configs / Удалить с конфигами
sudo apt autoremove                           # Remove unused dependencies / Удалить неиспользуемые зависимости
sudo apt autoremove --purge                   # Remove unused with configs / Удалить неиспользуемые с конфигами
```

### Search & Info / Поиск и информация
```bash
apt search <KEYWORD>                          # Search packages / Поиск пакетов
apt show <PACKAGE>                            # Show package details / Показать детали пакета
apt list --installed                          # List installed packages / Список установленных пакетов
apt list --upgradable                         # List upgradable packages / Список обновляемых пакетов
apt-cache policy <PACKAGE>                    # Show available versions / Показать доступные версии
```

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo apt clean                                # Clear downloaded packages / Очистить скачанные пакеты
sudo apt autoclean                            # Clear old packages / Очистить старые пакеты
sudo apt autoremove                           # Remove orphaned packages / Удалить осиротевшие пакеты
```

### Hold & Unhold / Удержание
```bash
sudo apt-mark hold <PACKAGE>                  # Prevent upgrade / Предотвратить обновление
sudo apt-mark unhold <PACKAGE>                # Allow upgrade / Разрешить обновление
apt-mark showhold                             # Show held packages / Показать удерживаемые пакеты
```

### Repositories / Репозитории
```bash
sudo add-apt-repository ppa:<USER>/<REPO>     # Add PPA / Добавить PPA
sudo add-apt-repository --remove ppa:<USER>/<REPO>  # Remove PPA / Удалить PPA
sudo apt edit-sources                         # Edit sources / Редактировать источники
```

---

# 🔴 DNF — RHEL/Fedora

### Update & Upgrade / Обновление
```bash
sudo dnf update                               # Update packages / Обновить пакеты
sudo dnf upgrade                              # Upgrade packages / Обновить пакеты
sudo dnf check-update                         # Check for updates / Проверить обновления
sudo dnf update <PACKAGE>                     # Update specific package / Обновить конкретный пакет
```

### Install & Remove / Установка и удаление
```bash
sudo dnf install <PACKAGE>                    # Install package / Установить пакет
sudo dnf install <PKG1> <PKG2>                # Install multiple / Установить несколько
sudo dnf remove <PACKAGE>                     # Remove package / Удалить пакет
sudo dnf autoremove                           # Remove unused dependencies / Удалить неиспользуемые зависимости
```

### Search & Info / Поиск и информация
```bash
dnf search <KEYWORD>                          # Search packages / Поиск пакетов
dnf info <PACKAGE>                            # Show package info / Показать информацию о пакете
dnf list installed                            # List installed packages / Список установленных пакетов
dnf list available                            # List available packages / Список доступных пакетов
dnf history                                   # Show transaction history / Показать историю транзакций
```

### Groups / Группы
```bash
dnf group list                                # List package groups / Список групп пакетов
sudo dnf group install "Development Tools"    # Install package group / Установить группу пакетов
sudo dnf group remove "Development Tools"     # Remove package group / Удалить группу пакетов
```

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo dnf clean all                            # Clean cache / Очистить кэш
sudo dnf autoremove                           # Remove orphaned packages / Удалить осиротевшие пакеты
sudo dnf makecache                            # Rebuild cache / Перестроить кэш
```

### Modules / Модули
```bash
dnf module list                               # List modules / Список модулей
sudo dnf module enable <PACKAGE>:<STREAM>     # Enable module stream / Включить поток модуля
sudo dnf module install <PACKAGE>:<STREAM>    # Install module / Установить модуль
```

---

# 🔵 Pacman — Arch Linux

### Update & Upgrade / Обновление
```bash
sudo pacman -Syu                              # Sync and upgrade / Синхронизировать и обновить
sudo pacman -Sy                               # Sync package database / Синхронизировать базу пакетов
sudo pacman -Su                               # Upgrade packages / Обновить пакеты
sudo pacman -Syyu                             # Force refresh and upgrade / Принудительное обновление
```

### Install & Remove / Установка и удаление
```bash
sudo pacman -S <PACKAGE>                      # Install package / Установить пакет
sudo pacman -S <PKG1> <PKG2>                  # Install multiple / Установить несколько
sudo pacman -R <PACKAGE>                      # Remove package / Удалить пакет
sudo pacman -Rs <PACKAGE>                     # Remove with unused deps / Удалить с неиспользуемыми зависимостями
sudo pacman -Rns <PACKAGE>                    # Remove with deps and configs / Удалить с зависимостями и конфигами
```

### Search & Info / Поиск и информация
```bash
pacman -Ss <KEYWORD>                          # Search packages / Поиск пакетов
pacman -Si <PACKAGE>                          # Show package info / Показать информацию о пакете
pacman -Q                                     # List installed packages / Список установленных пакетов
pacman -Qe                                    # List explicitly installed / Список явно установленных
pacman -Qdt                                   # List orphaned packages / Список осиротевших пакетов
```

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo pacman -Sc                               # Clean package cache / Очистить кэш пакетов
sudo pacman -Scc                              # Clean all cache / Очистить весь кэш
sudo pacman -Rns $(pacman -Qdtq)              # Remove orphans / Удалить осиротевшие
```

### AUR Helper (yay) / Помощник AUR (yay)
```bash
yay -Syu                                      # Update all (AUR + official) / Обновить всё (AUR + официальные)
yay -S <AUR_PACKAGE>                          # Install from AUR / Установить из AUR
yay -Rns <PACKAGE>                            # Remove package / Удалить пакет
```

---

# 🟢 Zypper — OpenSUSE

### Update & Upgrade / Обновление
```bash
sudo zypper refresh                           # Refresh repositories / Обновить репозитории
sudo zypper update                            # Update packages / Обновить пакеты
sudo zypper dup                               # Distribution upgrade / Обновление дистрибутива
sudo zypper patch                             # Install security patches / Установить патчи безопасности
```

### Install & Remove / Установка и удаление
```bash
sudo zypper install <PACKAGE>                 # Install package / Установить пакет
sudo zypper in <PACKAGE>                      # Short form / Короткая форма
sudo zypper remove <PACKAGE>                  # Remove package / Удалить пакет
sudo zypper rm <PACKAGE>                      # Short form / Короткая форма
```

### Search & Info / Поиск и информация
```bash
zypper search <KEYWORD>                       # Search packages / Поиск пакетов
zypper se <KEYWORD>                           # Short form / Короткая форма
zypper info <PACKAGE>                         # Show package info / Показать информацию о пакете
zypper if <PACKAGE>                           # Short form / Короткая форма
```

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo zypper clean                             # Clean cache / Очистить кэш
sudo zypper verify                            # Verify dependencies / Проверить зависимости
```

---

# 📦 Snap — Universal Packages

### Installation / Установка
```bash
sudo snap install <PACKAGE>                   # Install snap / Установить snap
sudo snap install <PACKAGE> --classic         # Classic confinement / Классическая изоляция
sudo snap install <PACKAGE> --edge            # Install edge channel / Установить edge канал
sudo snap install <PACKAGE> --beta            # Install beta channel / Установить beta канал
```

### List & Info / Список и информация
```bash
snap list                                     # List installed snaps / Список установленных snaps
snap find <KEYWORD>                           # Search snaps / Поиск snaps
snap info <PACKAGE>                           # Show snap info / Показать информацию о snap
```

### Update & Refresh / Обновление
```bash
sudo snap refresh                             # Update all snaps / Обновить все snaps
sudo snap refresh <PACKAGE>                   # Update specific snap / Обновить конкретный snap
sudo snap revert <PACKAGE>                    # Revert to previous version / Вернуться к предыдущей версии
```

### Remove / Удаление
```bash
sudo snap remove <PACKAGE>                    # Remove snap / Удалить snap
sudo snap remove <PACKAGE> --purge            # Remove with data / Удалить с данными
```

### Channels / Каналы
```bash
sudo snap switch <PACKAGE> --channel=stable   # Switch channel / Сменить канал
snap changes                                  # Show recent changes / Показать последние изменения
```

### Services / Сервисы
```bash
snap services                                 # List snap services / Список сервисов snap
sudo snap start <SERVICE>                     # Start service / Запустить сервис
sudo snap stop <SERVICE>                      # Stop service / Остановить сервис
sudo snap restart <SERVICE>                   # Restart service / Перезапустить сервис
```

---

# 📦 Flatpak — Application Sandboxes

### Installation / Установка
```bash
flatpak install flathub <APP_ID>              # Install from Flathub / Установить из Flathub
flatpak install flathub org.gimp.GIMP         # Example: GIMP / Пример: GIMP
flatpak install --user <APP_ID>               # Install for user / Установить для пользователя
```

### List & Search / Список и поиск
```bash
flatpak list                                  # List installed apps / Список установленных приложений
flatpak search <KEYWORD>                      # Search apps / Поиск приложений
flatpak info <APP_ID>                         # Show app info / Показать информацию о приложении
```

### Update / Обновление
```bash
flatpak update                                # Update all apps / Обновить все приложения
flatpak update <APP_ID>                       # Update specific app / Обновить конкретное приложение
```

### Run & Uninstall / Запуск и удаление
```bash
flatpak run <APP_ID>                          # Run application / Запустить приложение
flatpak uninstall <APP_ID>                    # Uninstall app / Удалить приложение
flatpak uninstall --unused                    # Remove unused runtimes / Удалить неиспользуемые runtimes
```

### Remotes / Удалённые репозитории
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo  # Add Flathub / Добавить Flathub
flatpak remote-list                           # List remotes / Список удалённых репозиториев
flatpak remote-delete <REMOTE>                # Remove remote / Удалить удалённый репозиторий
```

---

# 📦 AppImage — Portable Apps

### Usage / Использование
```bash
chmod +x <FILE>.AppImage                      # Make executable / Сделать исполняемым
./<FILE>.AppImage                             # Run AppImage / Запустить AppImage
./<FILE>.AppImage --appimage-extract          # Extract AppImage / Распаковать AppImage
./<FILE>.AppImage --appimage-help             # Show help / Показать помощь
```

### Integration / Интеграция
```bash
# AppImageLauncher for system integration / AppImageLauncher для системной интеграции
sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo apt update
sudo apt install appimagelauncher
```

---

# 🌟 Real-World Examples / Примеры из практики

### Full System Update / Полное обновление системы
```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# RHEL/Fedora
sudo dnf update -y && sudo dnf autoremove -y

# Arch
sudo pacman -Syu --noconfirm

# OpenSUSE
sudo zypper refresh && sudo zypper update -y
```

### Install Development Tools / Установка инструментов разработки
```bash
# Debian/Ubuntu
sudo apt install build-essential git vim curl wget

# RHEL/Fedora
sudo dnf groupinstall "Development Tools"
sudo dnf install git vim curl wget

# Arch
sudo pacman -S base-devel git vim curl wget

# OpenSUSE
sudo zypper install -t pattern devel_basis
sudo zypper install git vim curl wget
```

### Clean System / Очистка системы
```bash
# Debian/Ubuntu
sudo apt autoremove --purge -y
sudo apt autoclean
sudo apt clean

# RHEL/Fedora
sudo dnf autoremove -y
sudo dnf clean all

# Arch
sudo pacman -Scc --noconfirm
sudo pacman -Rns $(pacman -Qdtq)

# OpenSUSE
sudo zypper clean
```

### Automated Updates / Автоматические обновления
```bash
# Debian/Ubuntu with unattended-upgrades / Debian/Ubuntu с unattended-upgrades
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# RHEL/Fedora with dnf-automatic / RHEL/Fedora с dnf-automatic
sudo dnf install dnf-automatic
sudo systemctl enable --now dnf-automatic.timer
```

### Rollback Package / Откат пакета
```bash
# DNF history / История DNF
sudo dnf history
sudo dnf history undo <ID>

# APT downgrade / Понижение версии APT
sudo apt install <PACKAGE>=<VERSION>
```

### Multi-Package Manager / Несколько менеджеров пакетов
```bash
# Install Docker on Ubuntu / Установить Docker на Ubuntu
# 1. APT for system packages / APT для системных пакетов
sudo apt update && sudo apt install docker.io

# 2. Snap for isolated apps / Snap для изолированных приложений
sudo snap install spotify

# 3. Flatpak for desktop apps / Flatpak для приложений рабочего стола
flatpak install flathub org.videolan.VLC
```

---

## 📊 Cross-Reference Comparison / Сравнение менеджеров пакетов

### Equivalent Commands / Эквивалентные команды

| Operation / Операция | APT (Debian/Ubuntu) | DNF (RHEL/Fedora) | Pacman (Arch) | Zypper (SUSE) |
| :--- | :--- | :--- | :--- | :--- |
| **Update lists** | `apt update` | `dnf check-update` | `pacman -Sy` | `zypper refresh` |
| **Upgrade all** | `apt upgrade` | `dnf upgrade` | `pacman -Syu` | `zypper update` |
| **Install** | `apt install` | `dnf install` | `pacman -S` | `zypper install` |
| **Remove** | `apt remove` | `dnf remove` | `pacman -R` | `zypper remove` |
| **Remove+deps** | `apt autoremove` | `dnf autoremove` | `pacman -Rs` | `zypper rm --clean-deps` |
| **Purge (configs)** | `apt purge` | — | `pacman -Rns` | — |
| **Search** | `apt search` | `dnf search` | `pacman -Ss` | `zypper search` |
| **Info** | `apt show` | `dnf info` | `pacman -Si` | `zypper info` |
| **List installed** | `apt list --installed` | `dnf list installed` | `pacman -Q` | `zypper se -i` |
| **Clean cache** | `apt clean` | `dnf clean all` | `pacman -Sc` | `zypper clean` |
| **File owner** | `dpkg -S <FILE>` | `dnf provides <FILE>` | `pacman -Qo <FILE>` | `zypper se --provides <FILE>` |

### Universal Package Managers Comparison / Сравнение универсальных менеджеров

| Feature | Snap | Flatpak | AppImage |
| :--- | :--- | :--- | :--- |
| **Developer** | Canonical | freedesktop.org | Community |
| **Backend** | Centralized (Snap Store) | Decentralized (multiple remotes) | None (standalone files) |
| **Sandboxing** | AppArmor + Seccomp + cgroups | Bubblewrap (bwrap) | None (by default) |
| **Auto-updates** | Yes (automatic) | No (manual `flatpak update`) | No (manual download) |
| **Server apps** | Yes | No (desktop focus) | No |
| **Root required** | Yes (install) | Yes (system) / No (user) | No |
| **Format** | SquashFS | OSTree (OCI-compatible) | Single binary + FUSE |

---

## 💡 Best Practices / Лучшие практики

> [!IMPORTANT]
> Following these practices keeps your system secure and clean. / Следование этим практикам поддерживает вашу систему в безопасности и чистоте.

1. **Always update before installing** / Всегда обновляйте перед установкой — ensures you get the latest version and dependencies.
2. **Use `autoremove` regularly** / Регулярно используйте `autoremove` — frees disk space and removes orphan packages.
3. **Hold critical packages** / Удерживайте критические пакеты — prevents accidental upgrades of production software.
4. **Keep system updated for security** / Обновляйте систему для безопасности — unpatched systems are vulnerable.
5. **Use official repositories** / Используйте официальные репозитории — third-party repos can introduce instability.
6. **Check package info before installing** / Проверяйте информацию о пакете перед установкой — verify dependencies and size.

---

## 🔧 Configuration Files / Файлы конфигурации

| Package Manager | Main Config | Repositories |
| :--- | :--- | :--- |
| **APT** | `/etc/apt/apt.conf` | `/etc/apt/sources.list`, `/etc/apt/sources.list.d/` |
| **DNF** | `/etc/dnf/dnf.conf` | `/etc/yum.repos.d/` |
| **Pacman** | `/etc/pacman.conf` | `/etc/pacman.d/mirrorlist` |
| **Zypper** | `/etc/zypp/zypp.conf` | `/etc/zypp/repos.d/` |
| **Snap** | CLI-based | Snap Store (centralized) |
| **Flatpak** | CLI-based | Remotes (e.g., Flathub) |

---

## 📚 Documentation Links

- **APT:** https://manpages.debian.org/apt — https://wiki.debian.org/Apt
- **DNF:** https://dnf.readthedocs.io/ — https://docs.fedoraproject.org/en-US/quick-docs/dnf/
- **Pacman:** https://wiki.archlinux.org/title/Pacman — https://man.archlinux.org/man/pacman.8
- **Zypper:** https://en.opensuse.org/SDB:Zypper_manual — https://doc.opensuse.org/documentation/leap/reference/html/book-reference/cha-sw-cl.html
- **Snap:** https://snapcraft.io/docs — https://ubuntu.com/core/docs/snaps-in-ubuntu-core
- **Flatpak:** https://docs.flatpak.org/ — https://flathub.org/
- **AppImage:** https://appimage.org/ — https://docs.appimage.org/
