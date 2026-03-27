Title: 📦 APT — Debian/Ubuntu
Group: Package Managers
Icon: 📦
Order: 1

## Table of Contents
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Revert / Downgrade Upgraded Package](#-revert--downgrade-upgraded-package--откат--понижение-версии-пакета)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Comparison: Upgrade vs Dist-Upgrade](#-comparison-upgrade-vs-dist-upgrade)
- [Security](#-security--безопасность)

---

# 📦 APT Cheatsheet (Debian/Ubuntu)

Advanced Package Tool (APT) is the package manager for Debian, Ubuntu, and their derivatives. / Advanced Package Tool (APT) — это менеджер пакетов для Debian, Ubuntu и их производных.

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

## ⏪ Revert / Downgrade Upgraded Package / Откат / Понижение версии пакета

Sometimes an upgrade introduces regressions or breaks compatibility. APT allows you to install a specific older version of a package to roll back. / Иногда обновление вызывает регрессии или нарушает совместимость. APT позволяет установить конкретную старую версию пакета для отката.

> [!WARNING]
> Downgrading packages is **not officially supported** by Debian/Ubuntu and may break dependencies. Always test on a staging system first. / Понижение версии пакетов **официально не поддерживается** Debian/Ubuntu и может нарушить зависимости. Всегда тестируйте сначала на стенде.

### Step 1: Check Available Versions / Шаг 1: Проверить доступные версии

```bash
apt-cache policy <PACKAGE>                    # Show all available versions / Показать все доступные версии
apt list --all-versions <PACKAGE>             # Alternative: list all versions / Альтернатива: список всех версий
apt-cache madison <PACKAGE>                   # Show versions from all repos / Показать версии из всех репозиториев
```

Sample output / Пример вывода:
```
nginx:
  Installed: 1.24.0-2
  Candidate: 1.24.0-2
  Version table:
 *** 1.24.0-2 500
        500 http://deb.debian.org/debian bookworm/main amd64 Packages
        100 /var/lib/dpkg/status
     1.22.1-9 500
        500 http://deb.debian.org/debian bullseye/main amd64 Packages
```

### Step 2: Check APT History Log / Шаг 2: Проверить историю APT

Find what was upgraded and when. / Узнать, что и когда было обновлено.

`/var/log/apt/history.log`

```bash
# Show recent upgrades / Показать последние обновления
grep -A 2 "Upgrade:" /var/log/apt/history.log | tail -20

# Search specific package upgrade history / Поиск истории обновления конкретного пакета
grep "<PACKAGE>" /var/log/apt/history.log

# For rotated (compressed) logs / Для ротированных (сжатых) логов
zgrep "<PACKAGE>" /var/log/apt/history.log.*.gz
```

### Step 3: Downgrade to a Specific Version / Шаг 3: Откатить на конкретную версию

```bash
sudo apt install <PACKAGE>=<OLD_VERSION>       # Install exact older version / Установить конкретную старую версию

# Example / Пример:
sudo apt install nginx=1.22.1-9

# Downgrade with dependencies / Откатить с зависимостями
sudo apt install <PACKAGE>=<OLD_VERSION> <DEP1>=<OLD_VERSION> <DEP2>=<OLD_VERSION>
```

> [!TIP]
> If apt refuses due to dependency conflicts, you can try `--allow-downgrades`: / Если apt отказывает из-за конфликтов зависимостей, можно попробовать `--allow-downgrades`:
> ```bash
> sudo apt install --allow-downgrades <PACKAGE>=<OLD_VERSION>
> ```

### Step 4: Pin Package to Prevent Re-Upgrade / Шаг 4: Закрепить пакет для предотвращения повторного обновления

After downgrading, hold the package so it won't be upgraded again automatically. / После отката закрепите пакет, чтобы он не обновился автоматически.

```bash
sudo apt-mark hold <PACKAGE>                   # Hold package at current version / Удержать пакет на текущей версии
apt-mark showhold                              # Verify hold is set / Проверить, что удержание установлено

# When ready to allow upgrades again / Когда будете готовы снова разрешить обновления
sudo apt-mark unhold <PACKAGE>                 # Release hold / Снять удержание
```

**Alternative: APT Pinning (Persistent)** / **Альтернатива: APT Pinning (Постоянное закрепление)**

`/etc/apt/preferences.d/<PACKAGE>`

```bash
# Create a pin file to force a specific version / Создать файл закрепления для принудительной установки версии
cat <<EOF | sudo tee /etc/apt/preferences.d/<PACKAGE>
Package: <PACKAGE>
Pin: version <OLD_VERSION>
Pin-Priority: 1001
EOF
```

> [!IMPORTANT]
> A Pin-Priority of **1001** forces the version even over newer ones. Use **990** to prefer the version without forcing. Remove the pin file when no longer needed. / Приоритет **1001** принудительно устанавливает версию даже при наличии более новой. Используйте **990** для предпочтения версии без принуждения. Удалите файл закрепления, когда он больше не нужен.

### Step 5: Verify the Downgrade / Шаг 5: Проверить откат

```bash
apt-cache policy <PACKAGE>                     # Confirm installed version / Подтвердить установленную версию
dpkg -l <PACKAGE>                              # Check installed version via dpkg / Проверить версию через dpkg
sudo systemctl restart <SERVICE>               # Restart the service if applicable / Перезапустить сервис, если применимо
sudo systemctl status <SERVICE>                # Verify service is running / Проверить, что сервис работает
```

### Production Runbook: Package Downgrade / Продакшен-рунбук: Откат пакета

> [!CAUTION]
> In production, always coordinate with your team and have a rollback plan before modifying packages. / На продакшене всегда координируйте с командой и имейте план отката перед изменением пакетов.

1. **Identify the problem** — confirm the issue is caused by the package upgrade. / **Определить проблему** — подтвердить, что проблема вызвана обновлением пакета.
2. **Check history** — find the previous working version in `/var/log/apt/history.log`. / **Проверить историю** — найти предыдущую рабочую версию.
3. **Verify availability** — run `apt-cache policy <PACKAGE>` to ensure the old version is still in the repos. / **Проверить доступность** — убедиться, что старая версия ещё доступна в репозиториях.
4. **Take a snapshot/backup** — snapshot the VM or back up configs before proceeding. / **Сделать снапшот/бэкап** — снапшот ВМ или бэкап конфигов перед началом.
5. **Downgrade** — `sudo apt install <PACKAGE>=<OLD_VERSION>`. / **Откатить** — выполнить команду отката.
6. **Hold the package** — `sudo apt-mark hold <PACKAGE>`. / **Закрепить пакет** — заблокировать обновление.
7. **Restart and verify** — restart affected services and confirm the issue is resolved. / **Перезапустить и проверить** — перезапустить затронутые сервисы и подтвердить решение проблемы.
8. **Document** — record the incident and the downgrade in your changelog. / **Задокументировать** — записать инцидент и откат в журнал изменений.

### Comparison: Downgrade Methods / Сравнение: Методы отката

| Method / Метод | Scope / Область | Persistence / Постоянство | Risk / Риск | Use Case / Применение |
| :--- | :--- | :--- | :--- | :--- |
| `apt install <PKG>=<VER>` | Single action / Разовое действие | Until next upgrade / До следующего обновления | Low / Низкий | Quick rollback / Быстрый откат |
| `apt install` + `apt-mark hold` | Single action + lock / Разовое + блокировка | Until manually unhold / До ручного снятия | Low / Низкий | Stable rollback / Стабильный откат |
| APT Pinning (`preferences.d`) | Persistent rule / Постоянное правило | Until pin file removed / До удаления файла | Medium / Средний | Long-term version lock / Долгосрочная фиксация версии |
| Reinstall from `.deb` file | Manual / Ручной | Until next upgrade / До следующего обновления | High / Высокий | Version not in repos / Версия отсутствует в репозиториях |

### Reinstall from a Cached or Downloaded .deb / Установка из кеша или скачанного .deb

If the old version is no longer in the repositories, you may install from a cached `.deb` or download one manually. / Если старая версия больше недоступна в репозиториях, можно установить из кешированного `.deb` или скачать вручную.

```bash
# Check APT cache for old .deb files / Проверить кеш APT на наличие старых .deb файлов
ls /var/cache/apt/archives/<PACKAGE>*

# Install directly from .deb / Установить напрямую из .deb
sudo dpkg -i /var/cache/apt/archives/<PACKAGE>_<OLD_VERSION>_amd64.deb
sudo apt --fix-broken install                  # Fix any dependency issues / Исправить проблемы с зависимостями

# Download a specific version without installing / Скачать конкретную версию без установки
apt download <PACKAGE>=<OLD_VERSION>
```

> [!TIP]
> By default, `apt clean` removes cached `.deb` files. If you anticipate needing rollbacks, consider keeping the cache or archiving important `.deb` files separately. / По умолчанию `apt clean` удаляет кешированные `.deb` файлы. Если предполагаете необходимость отката, сохраняйте кеш или архивируйте важные `.deb` файлы отдельно.

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
