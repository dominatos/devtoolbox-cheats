Title: 📦 APT — Debian/Ubuntu
Group: Package Managers
Icon: 📦
Order: 1

## Table of Contents
- [Description](#description)
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Comparison: Upgrade vs Dist-Upgrade](#-comparison-upgrade-vs-dist-upgrade)
- [Security](#-security--безопасность)
- [Documentation Links](#-documentation-links)

---

# 📦 APT Cheatsheet (Debian/Ubuntu)

## Description

**APT (Advanced Package Tool)** is the standard package management system for Debian, Ubuntu, and all their derivatives (Linux Mint, Pop!_OS, etc.). It is a front-end to the lower-level `dpkg` tool and handles dependency resolution, repository management, and package downloading automatically. / **APT** — стандартная система управления пакетами для Debian, Ubuntu и их производных. Это фронтенд для низкоуровневого инструмента `dpkg`, автоматически обрабатывающий зависимости, репозитории и загрузку пакетов.

**Status:** Actively maintained and the primary package manager for the largest family of Linux distributions. The `apt` command (introduced in Debian 8/Ubuntu 14.04) is the modern replacement for the older `apt-get` and `apt-cache` commands. / **Статус:** Активно поддерживается и является основным менеджером пакетов для крупнейшего семейства дистрибутивов Linux.

**Default Ports:** N/A (local tool)  
**Package Format:** `.deb`

---

## ⚙️ Configuration / Конфигурация

### Main Configuration Files / Основные файлы конфигурации
`/etc/apt/sources.list`
`/etc/apt/sources.list.d/*.list`
`/etc/apt/apt.conf`
`/etc/apt/apt.conf.d/`

### Add Repository / Добавить репозиторий
```bash
sudo add-apt-repository ppa:<USER>/<REPO>         # Add PPA / Добавить PPA
sudo add-apt-repository --remove ppa:<USER>/<REPO> # Remove PPA / Удалить PPA
sudo apt edit-sources                             # Edit sources manually / Редактировать источники вручную
```

### Proxy Configuration / Настройка прокси
`/etc/apt/apt.conf.d/proxy.conf`
```bash
Acquire::http::Proxy "http://<USER>:<PASSWORD>@<HOST>:<PORT>/";
Acquire::https::Proxy "http://<USER>:<PASSWORD>@<HOST>:<PORT>/";
```

---

## 🛠 Core Management / Основное управление

### Update & Upgrade / Обновление
```bash
sudo apt update                               # Update package lists / Обновить списки пакетов
sudo apt upgrade                              # Upgrade packages / Обновить пакеты
sudo apt full-upgrade                         # Full upgrade (handles conflicts) / Полное обновление (обрабатывает конфликты)
sudo apt dist-upgrade                         # Distribution upgrade / Обновление дистрибутива
sudo apt update && sudo apt upgrade -y        # Update and upgrade / Обновить списки и пакеты
```

### Install & Remove / Установка и удаление
```bash
sudo apt install <PACKAGE>                    # Install package / Установить пакет
sudo apt install <PKG1> <PKG2> <PKG3>         # Install multiple / Установить несколько
sudo apt install <PACKAGE>=<VERSION>          # Install specific version / Установить конкретную версию
sudo apt reinstall <PACKAGE>                  # Reinstall package / Переустановить пакет
sudo apt remove <PACKAGE>                     # Remove package (keep config) / Удалить пакет (сохранить конфиг)
sudo apt purge <PACKAGE>                      # Remove with configs / Удалить вместе с конфигами
sudo apt autoremove                           # Remove unused dependencies / Удалить неиспользуемые зависимости
sudo apt autoremove --purge                   # Remove unused with configs / Удалить неиспользуемые с конфигами
```

### Search & Info / Поиск и информация
```bash
apt search <KEYWORD>                          # Search packages / Поиск пакетов
apt show <PACKAGE>                            # Show package details / Показать детали пакета
apt list --installed                          # List installed packages / Список установленных пакетов
apt list --upgradable                         # List upgradable packages / Список обновляемых пакетов
apt list --all-versions                       # List all versions / Список всех версий
apt-cache policy <PACKAGE>                    # Show installed/available versions / Показать установленные/доступные версии
apt-cache depends <PACKAGE>                   # Show dependencies / Показать зависимости
apt-cache rdepends <PACKAGE>                  # Show reverse dependencies / Показать обратные зависимости
dpkg -L <PACKAGE>                             # List files in package / Список файлов в пакете
dpkg -S <PATH/TO/FILE>                        # Find owner of file / Найти владельца файла
```

---

## 🔧 Sysadmin Operations / Операции системного администратора

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo apt clean                                # Clear local repository of retrieved package files / Очистить локальный репозиторий скачанных файлов
sudo apt autoclean                            # Clear old versions of downloaded packages / Очистить старые версии скачанных пакетов
```

### Hold & Unhold / Удержание пакетов
Prevent a package from being automatically upgraded. / Предотвратить автоматическое обновление пакета.

```bash
sudo apt-mark hold <PACKAGE>                  # Prevent upgrade / Запретить обновление
sudo apt-mark unhold <PACKAGE>                # Allow upgrade / Разрешить обновление
apt-mark showhold                             # Show held packages / Показать удерживаемые пакеты
```

### Logs / Логи
- **History Log:** `/var/log/apt/history.log` - Record of installed/removed/upgraded packages.
- **Term Log:** `/var/log/apt/term.log` - Terminal output of apt commands.

```bash
tail -f /var/log/apt/history.log              # Monitor package changes / Мониторинг изменений пакетов
grep "install " /var/log/apt/history.log      # Search installed packages / Поиск установленных пакетов
```

### Unattended Upgrades / Автоматические обновления
`/etc/apt/apt.conf.d/50unattended-upgrades`

Enable automatic updates for security patches. / Включить автоматические обновления для патчей безопасности.

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
# Check log / Проверка лога
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

---

## 🚨 Troubleshooting / Устранение неполадок

### Lock File Issues / Проблемы с файлами блокировки
> [!WARNING]
> Only remove lock files if you are certain no other apt/dpkg process is running. / Удаляйте файлы блокировки только если уверены, что процесс apt/dpkg не запущен.

If you get "Could not get lock /var/lib/dpkg/lock":
```bash
sudo lsof /var/lib/dpkg/lock                  # Check who holds the lock / Проверить, кто держит блокировку
sudo kill -9 <PID>                            # Kill the process / Убить процесс
# OR if no process is running / ИЛИ если процесс не запущен
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a                      # Fix interrupted installations / Исправить прерванные установки
```

### Merge List Errors / Ошибки списков пакетов
If you get "Problem with MergeList" or "Hash Sum Mismatch":
```bash
sudo rm -rf /var/lib/apt/lists/*
sudo apt clean
sudo apt update
```

### Fix Broken Installs / Исправление сломанных установок
```bash
sudo apt --fix-broken install                 # Fix missing dependencies / Исправить отсутствующие зависимости
```

---

## 📊 Comparison: Upgrade vs Dist-Upgrade

| Feature | `apt upgrade` | `apt dist-upgrade` |
| :--- | :--- | :--- |
| **New Packages** | No | Yes (if needed) |
| **Remove Packages** | No | Yes (to resolve conflicts) |
| **Kernel Updates** | Usually no | Yes |
| **Use Case** | Routine updates (Safe) / Регулярные обновления (Безопасно) | Major system updates / Крупные обновления системы |

---

## 🔒 Security / Безопасность

### Key Management / Управление ключами
Files in `/etc/apt/trusted.gpg.d/` or `/usr/share/keyrings/`.

```bash
apt-key list                                  # List keys (deprecated) / Список ключей (устарело)
# Modern way to add key / Современный способ добавить ключ:
curl -fsSL https://<URL>/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/<REPO>-archive-keyring.gpg
```

---

## 📚 Documentation Links

- **APT Man Page:** https://manpages.debian.org/apt
- **Debian Wiki — Apt:** https://wiki.debian.org/Apt
- **Ubuntu APT Guide:** https://ubuntu.com/server/docs/package-management
- **dpkg Man Page:** https://man7.org/linux/man-pages/man1/dpkg.1.html
- **Debian Repository Format:** https://wiki.debian.org/DebianRepository/Format
