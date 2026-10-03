---
Title: 📦 APT — Debian/Ubuntu
Group: Package Managers
Icon: 📦
Order: 1
tags:
  - package-managers
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 📦 APT Cheatsheet (Debian/Ubuntu)

## Description

**APT (Advanced Package Tool)** is the standard package management system for Debian, Ubuntu, and all their derivatives (Linux Mint, Pop!_OS, etc.). It is a high-level front-end to the lower-level `dpkg` tool and handles dependency resolution, repository management, and package downloading automatically. / **APT** — стандартная система управления пакетами для Debian, Ubuntu и их производных. Это фронтенд для низкоуровневого инструмента `dpkg`, автоматически обрабатывающий зависимости, репозитории и загрузку пакетов.

**Common use cases / Типовые сценарии:**
- Interactive install/upgrade of system packages on Debian/Ubuntu / Интерактивная установка и обновление системных пакетов.
- Managing third-party repositories (vendor, PPA, local mirror) / Управление сторонними репозиториями.
- Automating patching via `unattended-upgrades` / Автоматизация патчинга через unattended-upgrades.
- Controlling upgrade policy (hold, pin, security pocket) / Контроль политики обновлений.

**Status:** Actively maintained and the primary package manager for the largest family of Linux distributions. The `apt` command (introduced in Debian 8 / Ubuntu 14.04) is the modern human-facing replacement for the older `apt-get` and `apt-cache` commands. It is **not** legacy — in scripts prefer `apt-get`/`apt-cache`, whose CLI is kept stable across releases. / **Статус:** Активно поддерживается; `apt` — современный интерфейс для человека. В скриптах предпочтительнее `apt-get`/`apt-cache` (стабильный CLI).

**Alternatives / Альтернативы:**

| Tool | Role | Use in production? | Notes / Примечания |
| :--- | :--- | :--- | :--- |
| `apt` | Interactive CLI / Интерактивный CLI | Yes | Human-friendly defaults / Удобен человеку |
| `apt-get`, `apt-cache` | Stable scripting CLI / Стабильный CLI | Yes (automation) | Preferred for Ansible/CI / Предпочтителен для автоматизации |
| `dpkg` | Low-level unpack/configure / Низкоуровневый | Yes (rarely) | No dependency resolution / Без разрешения зависимостей |
| `aptitude` | TUI resolver / TUI-оболочка | Optional | Better interactive conflict resolution / Лучше разрешает конфликты |
| `snap` / `flatpak` / `dnf` / `pacman` | Other package ecosystems / Другие экосистемы | Yes (scoped) | See dedicated cheatsheets / См. отдельные шпаргалки |

**Default Ports:** N/A (local tool)
**Package Format:** `.deb`
**Stack:** APT (deps, repos) → dpkg (unpack, configure) / Стек: APT (зависимости, репозитории) → dpkg (распаковка, настройка)

Cross-reference: [Package Managers](pkgmanagerscheatsheet.md), [snap](snapcheatsheet.md), [logrotate](../system-logs/logrotatecheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md), [journalctl](../system-logs/journalctlcheatsheet.md).

---

## Configuration

### Main Configuration Files / Основные файлы конфигурации

`/etc/apt/sources.list`

`/etc/apt/sources.list.d/*.list`

`/etc/apt/sources.list.d/*.sources`

`/etc/apt/apt.conf`

`/etc/apt/apt.conf.d/`

`/etc/apt/preferences`

`/etc/apt/preferences.d/`

`/etc/apt/keyrings/`

`/etc/apt/auth.conf` / `/etc/apt/auth.conf.d/`

> [!TIP]
> One-line style uses `.list` extension; modern deb822 style uses `.sources`. Ubuntu 24.04 (noble)+ ships deb822 by default (`/etc/apt/sources.list.d/ubuntu.sources`). / Одинаковый формат — `.list`; современный deb822 — `.sources`. Ubuntu 24.04+ использует deb822 по умолчанию.

### One-Line Source Format / Формат источников (однострочный)

`/etc/apt/sources.list.d/custom.list`

```bash
# Suite examples: noble, bookworm, stable, <SUITE>
deb [signed-by=/etc/apt/keyrings/vendor.gpg] https://<HOST>/<PATH> <SUITE> main contrib non-free non-free-firmware
deb-src [signed-by=/etc/apt/keyrings/vendor.gpg] https://<HOST>/<PATH> <SUITE> main
```

### Deb822 Source Format / Формат deb822

`/etc/apt/sources.list.d/ubuntu.sources`

```bash
Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: noble noble-updates
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Enabled: yes
```

`/etc/apt/sources.list.d/vendor.sources`

```bash
Types: deb
URIs: https://<HOST>
Suites: <SUITE>
Components: main
Signed-By: /etc/apt/keyrings/vendor.gpg
```

> [!CAUTION]
> Never use `trusted=yes` or `Allow-Insecure: yes` on internet repositories. That disables apt-secure checks. / Никогда не используйте `trusted=yes` / `Allow-Insecure` на интернет-репозиториях — это отключает проверки apt-secure.

### Add Repository / Добавление репозитория

```bash
sudo apt install software-properties-common    # Provides add-apt-repository / Установить пакет с add-apt-repository
sudo add-apt-repository ppa:<USER>/<REPO>     # Add PPA / Добавить PPA
sudo add-apt-repository --remove ppa:<USER>/<REPO>  # Remove PPA / Удалить PPA
sudo apt edit-sources                         # Edit sources manually / Редактировать источники вручную
sudo apt update                               # Refresh lists after source change / Обновить списки после смены источников
```

### Third-Party Keys (Modern Way) / Ключи сторонних репозиториев

Keyring locations / Локации ключей:
- `/etc/apt/keyrings/` — system-operator-managed keys / ключи администратора
- `/usr/share/keyrings/` — keys shipped in packages / ключи из пакетов

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://<URL>/key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/<REPO>-archive-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/<REPO>-archive-keyring.gpg  # Readable for _apt / Читаем для пользователя _apt
apt-key list                                # DEPRECATED — do not use in production / УСТАРЕЛО — не использовать в production
```

### Proxy Configuration / Конфигурация прокси

`/etc/apt/apt.conf.d/proxy.conf`

```bash
Acquire::http::Proxy "http://<USER>:<PASSWORD>@<HOST>:<PORT>/";
Acquire::https::Proxy "http://<USER>:<PASSWORD>@<HOST>:<PORT>/";
```

`/etc/apt/auth.conf.d/proxy.conf`

```bash
machine <HOST>
login <USER>
password <PASSWORD>
```

### APT Configuration Snippets / Сниппеты конфигурации APT

`/etc/apt/apt.conf.d/90default-release`

```bash
APT::Default-Release "bookworm";   # Target release / Целевой релиз
```

`/etc/apt/apt.conf.d/00common-options`

```bash
APT::Install-Recommends "false";   # Do not install recommends by default / Не ставить recommends по умолчанию
APT::Install-Suggests "false";
Acquire::Languages "en";           # Limit translations / Ограничить языки
DPkg::Pre-Install-Pkgs { "/usr/bin/apt-listchanges --apt || true"; };
```

> [!TIP]
> `--no-install-recommends` keeps servers leaner (fewer surprise packages). Prefer explicit package lists on production hosts. / `--no-install-recommends` делает серверы компактнее; на production перечисляйте пакеты явно.

### Check Effective Config / Проверка конфигурации

```bash
apt-config dump | less                       # Dump effective APT config / Дамп конфигурации APT
apt-config dump | grep -i proxy              # Find proxy settings / Найти настройки прокси
apt-cache policy                             # Default priorities for installed packages / Приоритеты установленных пакетов
```

---

## Core Management

### Update and Upgrade / Обновление списков и пакетов

```bash
sudo apt update                              # Update package lists / Обновить списки пакетов
sudo apt upgrade                             # Upgrade packages (never remove) / Обновить пакеты (без удаления)
sudo apt full-upgrade                        # Full upgrade (handles conflicts) / Полное обновление (обрабатывает конфликты)
sudo apt dist-upgrade                        # Alias of full-upgrade / Синоним full-upgrade
sudo apt update && sudo apt upgrade -y       # Update lists and upgrade / Обновить списки и пакеты
sudo apt upgrade --with-new-pkgs             # Allow installing new packages during upgrade / Разрешить новые пакеты при обновлении
sudo apt-get upgrade -s                      # Script-stable dry-run / Симуляция для скриптов
```

> [!TIP]
> Production habit: always dry-run (`-s` / `--simulate`) before a maintenance window. / Привычка production: всегда симуляция перед окном обслуживания.

### Install and Remove / Установка и удаление

```bash
sudo apt install <PACKAGE>                   # Install package / Установить пакет
sudo apt install <PKG1> <PKG2> <PKG3>        # Install multiple / Установить несколько
sudo apt install <PACKAGE>=<VERSION>         # Install specific version / Установить конкретную версию
sudo apt install <PACKAGE>/<SUITE>           # Install from specific suite (e.g. /bookworm-backports) / Установить из suite
sudo apt install <PACKAGE>+                  # Force install target / Принудительно установить
sudo apt install --no-install-recommends <PACKAGE>  # Skip recommends / Без recommends
sudo apt install ./<PACKAGE>.deb             # Install local .deb / Установить локальный .deb
sudo apt reinstall <PACKAGE>                 # Reinstall package / Переустановить пакет
sudo apt remove <PACKAGE>                    # Remove package (keep config) / Удалить пакет (сохранить конфиг)
sudo apt remove <PACKAGE>-                   # Force remove target / Принудительно удалить
sudo apt purge <PACKAGE>                     # Remove with configs / Удалить вместе с конфигами
sudo apt autoremove                          # Remove unused dependencies / Удалить неиспользуемые зависимости
sudo apt autoremove --purge                  # Remove unused with configs / Удалить неиспользуемые с конфигами
sudo apt-get install -s <PACKAGE>            # Simulate install for automation / Симуляция установки для автоматизации
sudo apt satisfy "foo, bar (>= 1.0)"         # Satisfy dependency strings / Выполнить строку зависимостей
```

> [!WARNING]
> `remove` keeps modified config; `purge` deletes it. Check diffs before `purge`. / `remove` сохраняет конфиги; `purge` удаляет их. Проверьте изменения перед purge.

### Search and Info / Поиск и информация

```bash
apt search <KEYWORD>                         # Search packages / Поиск пакетов
apt show <PACKAGE>                           # Show package details / Показать детали пакета
apt changelog <PACKAGE>                      # Show package changelog (from repo) / Показать changelog пакета
apt list --installed                         # List installed packages / Список установленных пакетов
apt list --upgradable                        # List upgradable packages / Список обновляемых пакетов
apt list --all-versions                      # List all versions / Список всех версий
apt-cache policy <PACKAGE>                   # Show installed/available versions / Показать установленные/доступные версии
apt-cache madison <PACKAGE>                  # List available versions per repository / Список версий по репозиториям
apt-cache depends <PACKAGE>                  # Show dependencies / Показать зависимости
apt-cache rdepends <PACKAGE>                 # Show reverse dependencies / Показать обратные зависимости
apt-cache stats                              # Cache statistics / Статистика кэша
dpkg -L <PACKAGE>                            # List files in package / Список файлов в пакете
dpkg -S <PATH/TO/FILE>                       # Find owner of file / Найти владельца файла
dpkg -l <PACKAGE>                            # List package status / Статус пакета
dpkg -s <PACKAGE>                            # Show dpkg-level package info / Информация на уровне dpkg
apt-file search <PATH/TO/FILE>               # Which package provides a file (install apt-file first) / Какой пакет содержит файл
```

Sample output / Пример вывода (`apt list --upgradable`):

```text
Listing... Done
nginx/noble-updates,now 1.24.0-2ubuntu7 amd64 [upgradable from: 1.24.0-2ubuntu6]
openssl/noble-updates,now 3.0.13-0ubuntu3.12 amd64 [upgradable from: 3.0.13-0ubuntu3.10]
```

### Package Marking (Auto / Manual) / Метки пакетов (auto / manual)

Packages installed as dependencies are marked **auto** and may be removed by `autoremove`. Explicitly installed packages are **manual**. / Пакеты, поставленные как зависимости, — **auto**; явно установленные — **manual**.

```bash
sudo apt-mark auto <PACKAGE>                 # Mark as auto / Пометить как auto
sudo apt-mark manual <PACKAGE>               # Mark as manual (protect from autoremove) / Пометить manual (защита от autoremove)
apt-mark showauto                             # List auto packages / Список auto-пакетов
apt-mark showmanual                           # List manual packages / Список manual-пакетов
apt-mark showhold                             # List held packages / Список удерживаемых пакетов
```

State file / Файл состояния: `/var/lib/apt/extended_states`

---

## Sysadmin Operations

### Hold and Unhold / Удержание пакетов

Prevent a package from being automatically upgraded. / Предотвратить автоматическое обновление пакета.

```bash
sudo apt-mark hold <PACKAGE>                 # Prevent upgrade / Запретить обновление
sudo apt-mark unhold <PACKAGE>               # Allow upgrade / Разрешить обновление
apt-mark showhold                            # Show held packages / Показать удерживаемые пакеты
```

> [!TIP]
> Use **hold** for temporary freezes (app incompatibility). Use **pin** for policy (source/version). See [Comparison Tables](#comparison-tables). / Hold — временная заморозка; pin — политика источника/версии.

### Pinning (apt preferences) / Pinning (apt preferences)

`/etc/apt/preferences` and `/etc/apt/preferences.d/*.pref` control which versions APT selects. / Файлы preferences управляют выбором версий APT.

`/etc/apt/preferences.d/99default-release`

```bash
Package: *
Pin: release a=bookworm
Pin-Priority: 990
Package: *
Pin: release o=Debian
Pin-Priority: -10
```

`/etc/apt/preferences.d/99pin-local`

```bash
Package: *
Pin: origin "apt.internal.example"
Pin-Priority: 999
```

`/etc/apt/preferences.d/99pin-package`

```bash
Package: nginx
Pin: version 1.24.*
Pin-Priority: 1001
```

Priority rules / Правила приоритета:

| Priority (P) | Effect / Эффект |
| :--- | :--- |
| P >= 1000 | Install even if downgrade / Установка даже с даунгрейдом |
| 990 <= P < 1000 | Prefer target release over installed / Целевой релиз предпочтительнее |
| 500 <= P < 990 | Default candidate range / Обычный диапазон кандидата |
| 100 <= P < 500 | Only if no better version / Только если лучше версии нет |
| 0 < P < 100 | Only if not installed / Только если не установлен |
| P < 0 | Prevent install / Запрет установки |
| P = 0 | Undefined — do not use / Неопределённо — не использовать |

Default assignment (no preferences file) / Назначение по умолчанию:
- Installed package: priority 100 / Установленный: 100
- Available from normal repo: 500 / Доступный из обычного репо: 500
- Target release (APT::Default-Release): 990 / Целевой релиз: 990
- `apt-mark hold` behaves like pinning that package at installed version / hold работает как pinning на установленную версию

### Clean and Maintenance / Очистка и обслуживание

```bash
sudo apt clean                               # Clear local repository of retrieved package files / Очистить кэш скачанных .deb
sudo apt autoclean                           # Clear only old superseded package files / Очистить только старые версии
sudo apt autoremove                          # Remove orphaned dependencies / Удалить осиротевшие зависимости
sudo apt autoremove --purge                  # Remove orphans with configs / Удалить сироты с конфигами
sudo apt update                              # Re-fetch package lists / Повторно получить списки пакетов
```

| Command | Clears what? | When to use / Когда использовать |
| :--- | :--- | :--- |
| `apt clean` | Entire package cache `/var/cache/apt/archives/` / Весь кэш | Disk pressure; after large upgrades / Давление на диск |
| `apt autoclean` | Only outdated superseded .deb files / Только старые версии | Regular maintenance / Регулярное обслуживание |
| `apt autoremove` | Auto-marked unused packages / Auto-пакеты без зависимостей | Periodic hygiene / Периодическая чистка |

### Logs and Paths / Логи и пути

| Path | Content / Содержимое |
| :--- | :--- |
| `/var/log/apt/history.log` | apt action history (Start-Date, Commandline) / История apt-команд |
| `/var/log/apt/term.log` | Terminal output of apt / Терминальный вывод apt |
| `/var/log/dpkg.log` | dpkg install/upgrade/remove events / События dpkg |
| `/var/lib/apt/lists/` | Cached package indexes / Кэш индексов пакетов |
| `/var/cache/apt/archives/` | Downloaded .deb files / Скачанные .deb |
| `/var/lib/dpkg/status` | Installed package database / БД установленных пакетов |
| `/var/lib/apt/extended_states` | Auto/manual markers / Метки auto/manual |
| `/var/log/unattended-upgrades/` | Unattended-upgrades logs / Логи автообновлений |

```bash
tail -f /var/log/apt/history.log             # Monitor package changes / Мониторинг изменений пакетов
grep "install " /var/log/apt/history.log     # Search installed packages / Поиск установленных пакетов
grep "upgrade " /var/log/apt/history.log     # Search upgrades / Поиск обновлений
grep "purge " /var/log/apt/history.log       # Search purges / Поиск удалений с конфигами
zgrep -h "^Start-Date" /var/log/apt/history.log*  # All apt action start times / Время всех действий apt
```

### Logrotate for APT Logs / Logrotate для логов APT

`/etc/logrotate.d/apt`

```bash
/var/log/apt/*.log
/var/log/dpkg.log
{
        rotate 7
        daily
        compress
        delaycompress
        missingok
        notifempty
        create 0644 root root
}
```

`/etc/logrotate.d/unattended-upgrades`

```bash
/var/log/unattended-upgrades/*.log
{
        rotate 7
        daily
        compress
        delaycompress
        missingok
        notifempty
        create 0640 root adm
}
```

```bash
sudo logrotate -d /etc/logrotate.d/apt      # Dry-run logrotate / Тест logrotate
```

Cross-reference: [logrotate](../system-logs/logrotatecheatsheet.md)

### Unattended Upgrades / Автоматические обновления

Enable automatic security patches. / Включить автоматические обновления для патчей безопасности.

`/etc/apt/apt.conf.d/50unattended-upgrades`

```bash
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
        "${distro_id}ESMApps:${distro_codename}-apps-security";
};
Unattended-Upgrade::Package-Blacklist {
        // "package-name";   // Pin or block / Удержать или заблокировать
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
```

`/etc/apt/apt.conf.d/20auto-upgrades`

```bash
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
```

```bash
sudo apt install unattended-upgrades          # Install unattended-upgrades / Установить unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades  # Interactive enable / Интерактивная настройка
sudo unattended-upgrade -d                    # Dry-run (safe test) / Тестовый запуск
unattended-upgrade --dry-run -v               # Verbose dry-run / Подробная симуляция
cat /var/log/unattended-upgrades/unattended-upgrades.log  # Check log / Проверить лог
```

> [!TIP]
> Keep `Automatic-Reboot "false"` on production unless you have a reboot policy and monitoring. / На production оставляйте `Automatic-Reboot "false"`, если нет политики перезагрузки.

### needrestart (Service Restart After Upgrade) / Перезапуск сервисов

On Ubuntu/Debian, upgraded daemons may keep old binaries until restart. / После обновления демоны могут работать со старым бинарным файлом до перезапуска.

`/etc/needrestart/needrestart.conf`

```bash
$nrconf{enable} = 1;
$nrconf{override_rc} = [ qr('^docker$') => 0 ];   # Example: skip docker / Пример: не перезапускать docker
```

```bash
sudo apt install needrestart                 # Install needrestart / Установить needrestart
sudo needrestart -b                          # Check what needs restart / Проверить, что нужно перезапустить
sudo needrestart -r a                         # Ask before restarting / Спрашивать перед перезапуском
```

Cross-reference: [systemctl](../system-logs/systemctlcheatsheet.md)

### Target Release (Default-Release) / Целевой релиз

```bash
sudo apt install -t bookworm-backports <PACKAGE>   # Install from specific release / Установить из конкретного релиза
APT::Default-Release "bookworm";                     # Persistent default / Постоянный целевой релиз
apt-cache policy <PACKAGE>                           # Verify selected version / Проверить выбранную версию
```

### Source Packages / Пакеты исходного кода

```bash
sudo apt install build-essential dpkg-dev            # Build tools / Сборочные инструменты
sudo apt-get source <PACKAGE>                        # Download source / Загрузить исходники
sudo apt-get build-dep <PACKAGE>                     # Install build deps / Установить зависимости сборки
sudo apt install <PACKAGE>-dbg <PACKAGE>-dbgsym      # Debug symbols / Отладочные символы
```

### Apt-Cacher (Local Cache Proxy) / Локальный кэш-прокси

```bash
sudo apt install apt-cacher-ng                        # Install caching proxy / Установить кэширующий прокси
```

`/etc/apt/apt.conf.d/01proxy`

```bash
Acquire::http::Proxy "http://<HOST>:3142/";
```

> [!TIP]
> Useful on LANs with many hosts to cut bandwidth and speed up updates. / Полезно в LAN для экономии канала и ускорения обновлений.

### Snapshots (Debian / Ubuntu 24.04+) / Снимки репозиториев

`/etc/apt/sources.list.d/snapshot.sources`

```bash
Types: deb
URIs: http://snapshot.debian.org/archive/debian/20250101T000000Z/
Suites: bookworm
Components: main
Snapshot: 20250101T000000Z
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

```bash
sudo apt-get update -o Acquire::Retries=3
```

> [!WARNING]
> Snapshot pins the archive to a past state — good for reproducibility, bad if you expect security updates. Prefer live security pockets on production. / Снимок фиксирует архив в прошлом — для безопасности нужны живые `-security` репозитории.

---

## Security

### Key Management / Управление ключами

Files in `/etc/apt/keyrings/` (operator) or `/usr/share/keyrings/` (packaged). / Файлы ключей в `/etc/apt/keyrings/` или `/usr/share/keyrings/`.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://<URL>/key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/<REPO>-archive-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/<REPO>-archive-keyring.gpg
apt-key list                                # DEPRECATED / УСТАРЕЛО — не использовать
sudo apt-key adv --keyserver <HOST> --recv-keys <FINGERPRINT>   # DEPRECATED / УСТАРЕЛО
gpg --show-keys /etc/apt/keyrings/<REPO>-archive-keyring.gpg   # Inspect key / Проверить ключ
```

### apt-secure / Проверка подписей

APT verifies `InRelease` / `Release` + `Release.gpg` signatures. / APT проверяет подписи `InRelease` / `Release` + `Release.gpg`.

| Check | Meaning | Risk if disabled / Риск |
| :--- | :--- | :--- |
| Signature valid | Repo signed by trusted key / Подпись валидна | Supply-chain risk / Риск цепочки поставок |
| Valid-Until | Repo data not expired / Данные не устарели | Stale mirror errors / Ошибки устаревших зеркал |
| Check-Date | Machine clock sane / Часы корректны | Bad timestamps break validation / Некорректное время ломает проверки |

```bash
apt-get check                                # Verify dependency integrity / Проверить целостность зависимостей
dpkg --audit                                 # Report half-configured packages / Половинно настроенные пакеты
```

> [!WARNING]
> `trusted=yes`, `Allow-Insecure: yes`, `Allow-Weak: yes`, `Allow-Downgrade-To-Insecure: yes` weaken apt-secure. Use only for fully local, trusted media. / Эти опции ослабляют apt-secure — только для локальных доверенных медиа.

### Security Pockets / Security-репозитории

```bash
sudo apt update && sudo apt list --upgradable   # Check updates incl. security / Проверить обновления
apt-cache policy <PACKAGE> | grep -i security  # Inspect security origin / Происхождение security-пакета
grep "security" /etc/apt/sources.list /etc/apt/sources.list.d/*  # Confirm security sources / Проверить security-источники
```

Typical suites / Типовые suite:
- Ubuntu: `noble-security`, `jammy-security`
- Debian: `bookworm-security`, `trixie-security`

### Local Repository (Optional) / Локальный репозиторий

```bash
sudo apt install reprepro                    # Build local .deb repo / Собрать локальный .deb-репозиторий
```

`/etc/apt/sources.list.d/local.list`

```bash
deb [trusted=yes] file:/var/local/repo <SUITE> main
```

> [!CAUTION]
> `[trusted=yes]` is acceptable **only** for a repository you fully control on a trusted path. / `[trusted=yes]` допустим **только** для полностью доверенного локального репозитория.

---

## Backup and Restore

### What to Back Up / Что резервировать

| Path | Why / Зачем |
| :--- | :--- |
| `/etc/apt/` | sources, preferences, apt.conf.d / источники, pinning, конфиги |
| `/etc/apt/keyrings/` | Third-party keys / ключи сторонних репозиториев |
| `/var/lib/dpkg/status` | Package database / БД пакетов |
| `/var/lib/apt/extended_states` | Auto/manual markers / Метки auto/manual |
| `/var/cache/apt/archives/*.deb` | Installed package payloads / Установленные пакеты |

```bash
sudo tar -czf /root/apt-backup-$(date +%F).tgz \
  /etc/apt \
  /var/lib/dpkg/status \
  /var/lib/apt/extended_states \
  /var/cache/apt/archives/*.deb
```

### apt-clone / Клонирование состояния APT

```bash
sudo apt install apt-clone                   # Install apt-clone / Установить apt-clone
sudo apt-clone clone /root/apt-clone-$(date +%F).tgz
sudo apt-clone restore /root/apt-clone-<FILE>.tgz
```

> [!CAUTION]
> `apt-clone restore` reinstalls package state from the clone — it can remove/replace packages added after the snapshot. / `restore` откатывает состояние пакетов к моменту снимка.

### Rollback Runbook (Downgrade) / Откат (даунгрейд)

1. Identify the bad package and current version / Определите проблемный пакет и текущую версию
   - `apt list --upgradable`
   - `grep "upgrade " /var/log/apt/history.log`

2. Check available versions / Проверьте доступные версии
   - `apt-cache madison <PACKAGE>`
   - `apt-cache policy <PACKAGE>`

3. Pin the good version in preferences / Зафиксируйте версию в preferences

   `/etc/apt/preferences.d/rollback-<PACKAGE>`

   ```bash
   Package: <PACKAGE>
   Pin: version <GOOD_VERSION>
   Pin-Priority: 1001
   ```

4. Allow downgrade explicitly / Явно разрешите даунгрейд

   ```bash
   sudo apt-get install --allow-downgrades <PACKAGE>=<GOOD_VERSION>
   ```

5. Verify and restart affected services / Проверьте и перезапустите сервисы

   ```bash
   dpkg -l <PACKAGE> && sudo systemctl restart <SERVICE>
   ```

6. Remove the pin after validation / После проверки удалите pin

   ```bash
   sudo rm /etc/apt/preferences.d/rollback-<PACKAGE>
   ```

> [!CAUTION]
> Downgrades can leave broken dependencies. Prefer package-level hold + test in staging; only use pin-Priority >= 1000 when you must. / Даунгрейды ломают зависимости — сначала staging и hold.

### Emergency Package Install from Archives / Аварийная установка из архивов

```bash
sudo dpkg -i /var/cache/apt/archives/<PACKAGE>_<VERSION>_amd64.deb
sudo apt-get -f install                      # Repair dependency chain / Исправить цепочку зависимостей
```

---

## Troubleshooting

### Lock File Issues / Файлы блокировки

> [!WARNING]
> Only remove lock files if you are certain no other apt/dpkg process is running. / Удаляйте файлы блокировки только если уверены, что процесс apt/dpkg не запущен.

If you get "Could not get lock /var/lib/dpkg/lock":

```bash
sudo lsof /var/lib/dpkg/lock                # Check who holds the lock / Проверить, кто держит блокировку
sudo fuser -v /var/lib/dpkg/lock-frontend  # Also check frontend lock / Также проверить lock-frontend
sudo kill -9 <PID>                          # Kill the process / Убить процесс
# OR if no process is running / ИЛИ если процесс не запущен
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a                    # Fix interrupted installations / Исправить прерванные установки
```

### Merge List / Hash Sum Errors / Ошибки MergeList / Hash Sum

If you get "Problem with MergeList" or "Hash Sum Mismatch":

```bash
sudo rm -rf /var/lib/apt/lists/*
sudo apt clean
sudo apt update
```

> [!TIP]
> Increase retries for flaky mirrors: `sudo apt-get update -o Acquire::Retries=3`. / Увеличьте число попыток для нестабильных зеркал.

### 404 Not Found (Stale Suite) / Ошибка 404

```bash
apt-cache policy | head -40                  # List configured suites / Показать suite
grep -R "Suites:\|^deb " /etc/apt/sources.list /etc/apt/sources.list.d/  # Review sources / Проверить источники
sudo apt update                              # Retry after fix / Повторить после правки
```

### Invalid Signature / Неверная подпись

```bash
gpg --show-keys /etc/apt/keyrings/<REPO>-archive-keyring.gpg
apt-get update 2>&1 | grep -i -E "key|signature|signed"
```

- Expired key → fetch new key / Истёкший ключ → обновить ключ
- Wrong `Signed-By` path → fix deb822/one-line entry / Неверный путь — исправить источник
- Missing key → add keyring to `/etc/apt/keyrings/` and reference it / Нет ключа — добавить ключ и сослаться на него

### Expired Valid-Until / Устаревшие данные репозитория

```bash
apt-get update 2>&1 | grep -i valid
```

- Mirror not updated → switch mirror / Зеркало не обновляется → сменить зеркало
- Historical archive → set `Check-Valid-Until: no` on that source only / Архив → отключить проверку только для этого источника

### Fix Broken Installs / Исправление сломанных установок

```bash
sudo apt --fix-broken install                # Fix missing dependencies / Исправить отсутствующие зависимости
sudo dpkg --configure -a                     # Finish interrupted configuration / Завершить прерванную настройку
sudo apt-get check                           # Check for broken packages / Проверить целостность
sudo dpkg --audit                            # Report half-configured / Показать половинно настроенные
apt-get -s install <PACKAGE>                 # Simulate resolution / Симулировать разрешение
```

### Debug and Diagnostics / Отладка

```bash
apt -o Debug::pkgProblemResolver=yes install <PACKAGE>  # Dependency resolver debug / Отладка разрешателя зависимостей
apt-get -o Debug::Acquire::http=true update             # Acquire HTTP debug / Отладка загрузки
sudo apt -s upgrade                           # Full upgrade simulation / Полная симуляция обновления
aptitude why <PACKAGE>                        # Why is package installed (aptitude) / Почему пакет установлен
```

### dpkg Status Codes / Коды состояния dpkg

| Code | Meaning / Значение |
| :--- | :--- |
| `ii` | Installed correctly / Корректно установлен |
| `rc` | Removed, config remains / Удалён, конфиг остался |
| `iU` | Unpacked, not configured / Распакован, не настроен |
| `iF` | Half-configured / Полунастроен |
| `H` | Held / Удерживается |

```bash
dpkg -l | grep ^..H | awk '{print $2}'       # List held packages / Список удерживаемых пакетов
dpkg -l | grep ^iF                           # List half-configured / Список полунастроенных
sudo dpkg --configure -a                     # Repair half-configured / Исправить полунастроенные
```

---

## Comparison Tables

### apt vs apt-get vs apt-cache vs dpkg

| Tool | Purpose | Stability | Best for / Лучше для |
| :--- | :--- | :--- | :--- |
| `apt` | Interactive high-level CLI / Интерактивный | Output may change / Вывод может меняться | Humans on servers/desktops / Люди |
| `apt-get` | Stable high-level CLI / Стабильный CLI | Stable contract / Стабильный контракт | Scripts, Ansible, CI / Скрипты, автоматизация |
| `apt-cache` | Query metadata / Запрос метаданных | Stable contract / Стабильный контракт | policy, depends, madison / policy, зависимости |
| `dpkg` | Unpack + configure only / Только распаковка и настройка | Low-level / Низкоуровневый | Emergency repair, no-deps install / Аварийный ремонт |

**Why it matters / Почему это важно:** Debian man page (apt(8)) states `apt` may change behavior between versions for interactive convenience; automation should use `apt-get`/`apt-cache`. / Меню apt(8) допускает изменения поведения apt между версиями — в автоматизации используйте apt-get/apt-cache.

### upgrade vs full-upgrade vs dist-upgrade

| Feature | `apt upgrade` | `apt full-upgrade` / `apt dist-upgrade` |
| :--- | :--- | :--- |
| **New Packages** | Only if required by deps / Только если нужны для зависимостей | Yes / Да |
| **Remove Packages** | Never / Никогда | Yes, to resolve conflicts / Да, чтобы разрешить конфликты |
| **Kernel Updates** | Sometimes skipped / Иногда пропускает | Usually installed / Обычно ставит |
| **When conflict arises** | Package is skipped / Пакет пропускается | Package may be removed / Пакет может быть удалён |
| **Use Case** | Routine updates (safe) / Регулярные обновления | Major upgrades / Крупные обновления |

> [!TIP]
> `dist-upgrade` is a historical alias of `full-upgrade`. Prefer `full-upgrade` in new runbooks. / `dist-upgrade` — исторический синоним `full-upgrade`. В новых runbook пишите `full-upgrade`.

### Hold vs Pin

| Aspect | `apt-mark hold` | APT preferences (pin) |
| :--- | :--- | :--- |
| **Scope** | Single package / Один пакет | Package glob, origin, release, version / Пакет/репо/релиз/версия |
| **Mechanism** | Blocks upgrade in apt-get/apt / Блокирует обновление | Priority override via preferences / Приоритет через preferences |
| **Downgrade** | Not automatically allowed / Даунгрейд не разрешён | P >= 1000 can allow downgrades / P >= 1000 может разрешить |
| **Best for** | Temporary freeze / Временная заморозка | Distro policy, backports, local mirror / Политика дистрибутива |
| **Check** | `apt-mark showhold` | `apt-cache policy <PACKAGE>` |
| **Remove** | `apt-mark unhold <PACKAGE>` | Delete pin file / Удалить файл pin |

### clean vs autoclean vs autoremove

| Command | Removes | Safe on production? / Безопасно? |
| :--- | :--- | :--- |
| `apt clean` | All cached .deb in `/var/cache/apt/archives/` / Все кэшированные .deb | Yes, but slower next installs / Да, но следующие установки медленнее |
| `apt autoclean` | Only superseded .deb files / Только вытесненные версии | Yes / Да |
| `apt autoremove` | Auto-marked unused packages / Auto-пакеты без зависимости | Check list first / Сначала просмотреть список |
| `apt autoremove --purge` | Orphans + their configs / Сироты + их конфиги | Review / Перед удали проверьте |

---

## Production Runbooks

### Routine Upgrade Window / Штатное окно обновления

1. Announce maintenance window; confirm backups and snapshot available. / Объявите окно обслуживания; убедитесь, что есть бэкап и snapshot.
2. Dry-run and review plan / Симуляция и план  
   `sudo apt-get upgrade -s | less`
3. Check holds and phased updates / Проверьте hold и phased updates  
   `apt-mark showhold` · `apt-cache policy <PACKAGE>`
4. Update lists and upgrade / Обновите списки и пакеты  
   `sudo apt update && sudo apt upgrade -y`
5. Restart affected services / Перезапустите затронутые сервисы  
   `sudo needrestart -b` · `sudo systemctl restart <SERVICE>`
6. Health-check application and monitoring / Проверьте приложение и мониторинг
7. Review logs / Проверьте логи  
   `grep "Start-Date" -A2 /var/log/apt/history.log | tail -40`

### Security Patch Window / Окно security-патчей

1. Confirm security pocket in sources / Подтвердите security-репозиторий в источниках  
   `grep -R "security" /etc/apt/sources.list /etc/apt/sources.list.d/`
2. List security-related upgrades / Список security-обновлений  
   `apt list --upgradable`
3. Hold risky application packages if needed / При необходимости зафиксируйте рискованные пакеты  
   `sudo apt-mark hold <PACKAGE>`
4. Dry-run then apply / Симуляция и применение  
   `sudo apt-get full-upgrade -s` → `sudo apt update && sudo apt full-upgrade -y`
5. Restart daemons with new binaries / Перезапустите демоны с новыми бинарниками  
   `sudo needrestart -r a`
6. Validate services, then unhold packages / Проверьте сервисы, затем снимите hold  
   `sudo apt-mark unhold <PACKAGE>`
7. Document actions from history log / Зафиксируйте действия по history log

### Repository Change / Изменение репозитория

1. Backup `/etc/apt` and current keyrings / Бэкап `/etc/apt` и ключей
2. Add key to `/etc/apt/keyrings/` (never `apt-key add`) / Добавьте ключ в `/etc/apt/keyrings/`
3. Add `.list` or `.sources` entry with `Signed-By` / Добавьте источник с `Signed-By`
4. `sudo apt update` — fix 404/signature errors before proceeding / Обновите списки и исправьте ошибки
5. `apt-cache policy <PACKAGE>` — verify selected origin/version / Проверьте происхождение и версию
6. Install/upgrade a sample package / Установите тестовый пакет
7. Keep logrotate configs unchanged unless log paths changed / Не меняйте logrotate, если пути к логам не менялись

---

## Documentation Links

- **APT Man Page (apt):** https://manpages.debian.org/bookworm/apt/apt.8.en.html
- **apt-get Man Page:** https://manpages.debian.org/bookworm/apt/apt-get.8.en.html
- **apt-cache Man Page:** https://manpages.debian.org/bookworm/apt/apt-cache.8.en.html
- **apt_preferences (Pinning):** https://manpages.debian.org/bookworm/apt/apt_preferences.5.en.html
- **sources.list (one-line + deb822):** https://manpages.ubuntu.com/manpages/noble/man5/sources.list.5.html
- **apt.conf:** https://manpages.debian.org/bookworm/apt/apt.conf.5.en.html
- **apt_auth.conf:** https://manpages.ubuntu.com/manpages/noble/man5/apt_auth.conf.5.html
- **apt-secure:** https://manpages.ubuntu.com/manpages/noble/man8/apt-secure.8.html
- **unattended-upgrades:** https://manpages.ubuntu.com/manpages/noble/man8/unattended-upgrades.8.html
- **needrestart:** https://manpages.ubuntu.com/manpages/noble/man8/needrestart.8.html
- **dpkg:** https://man7.org/linux/man-pages/man1/dpkg.1.html
- **Debian Wiki — Apt:** https://wiki.debian.org/Apt
- **Ubuntu Server Docs — Package Management:** https://ubuntu.com/server/docs/package-management
- **Debian Repository Format:** https://wiki.debian.org/DebianRepository/Format
- **APT User's Guide:** https://wiki.debian.org/AptUserGuide (local: `/usr/share/doc/apt-doc/`)
