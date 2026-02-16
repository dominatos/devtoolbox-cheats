Title: 🟢 Zypper — OpenSUSE
Group: Package Managers
Icon: 🟢
Order: 4

## Table of Contents
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Comparison: Update vs Dup](#-comparison-update-vs-dup)
- [Security](#-security--безопасность)

---

# 🟢 Zypper Cheatsheet (OpenSUSE/SLES)

Zypper is the command-line interface for ZYpp, the package management library for OpenSUSE and SUSE Linux Enterprise. / Zypper — это интерфейс командной строки для ZYpp, библиотеки управления пакетами для OpenSUSE и SLES.

---

## ⚙️ Configuration / Конфигурация

### Main Configuration Files / Основные файлы конфигурации
`/etc/zypp/zypp.conf`
`/etc/zypp/repos.d/*.repo`

### Repository Management / Управление репозиториями
```bash
sudo zypper repos (lr)                        # List repositories / Список репозиториев
sudo zypper addrepo <URL> <ALIAS>             # Add repository / Добавить репозиторий
sudo zypper removerepo <ALIAS>                # Remove repository / Удалить репозиторий
sudo zypper modifyrepo --enable <ALIAS>       # Enable repository / Включить репозиторий
sudo zypper modifyrepo --disable <ALIAS>      # Disable repository / Отключить репозиторий
sudo zypper refresh (ref)                     # Refresh metadata / Обновить метаданные
```

---

## 🛠 Core Management / Основное управление

### Update & Dist-Upgrade / Обновление
```bash
sudo zypper update (up)                       # Update installed packages / Обновить установленные пакеты
sudo zypper dist-upgrade (dup)                # Full distribution upgrade / Полное обновление дистрибутива
sudo zypper patch                             # Install needed patches / Установить необходимые патчи
sudo zypper list-patches (lp)                 # List needed patches / Список необходимых патчей
```

### Install & Remove / Установка и удаление
```bash
sudo zypper install <PACKAGE> (in)            # Install package / Установить пакет
sudo zypper install <PKG1> <PKG2>             # Install multiple / Установить несколько
sudo zypper remove <PACKAGE> (rm)             # Remove package / Удалить пакет
sudo zypper remove --clean-deps <PACKAGE>     # Remove with dependencies / Удалить с зависимостями
sudo zypper verify (ve)                       # Verify dependencies / Проверить зависимости
```

### Search & Info / Поиск и информация
```bash
zypper search <KEYWORD> (se)                  # Search packages / Поиск пакетов
zypper info <PACKAGE> (if)                    # Show package details / Показать детали пакета
zypper search --installed-only                # List installed packages / Список установленных пакетов
zypper search --provides <FILE>               # Find package owning file / Найти пакет, владеющий файлом
```

### Patterns / Шаблоны
Patterns are groups of packages (e.g., "Lamp Server", "KDE Desktop"). / Шаблоны — это группы пакетов.

```bash
zypper patterns                               # List available patterns / Список доступных шаблонов
sudo zypper install -t pattern <PATTERN>      # Install pattern / Установить шаблон
```

---

## 🔧 Sysadmin Operations / Операции системного администратора

### Clean & Locks / Очистка и блокировки
```bash
sudo zypper clean (cc)                        # Clean local caches / Очистить локальные кэши
sudo zypper addlock <PACKAGE> (al)            # Lock package (prevent changes) / Заблокировать пакет
sudo zypper removelock <PACKAGE> (rl)         # Remove lock / Снять блокировку
sudo zypper locks (ll)                        # List active locks / Список активных блокировок
```

### Logs / Логи
- **History Log:** `/var/log/zypp/history` - High-level history.
- **Zypper Log:** `/var/log/zypper.log` - Detailed debugging log.

```bash
tail -f /var/log/zypp/history                 # Monitor package history / Мониторинг истории пакетов
```

### Services (Snapper Integration) / Снапшоты (Интеграция Snapper)
OpenSUSE automatically creates Btrfs snapshots before updates. / OpenSUSE автоматически создает снапшоты Btrfs перед обновлениями.

```bash
sudo snapper list                             # List snapshots / Список снапшотов
sudo snapper status <ID>..<ID>                # Compare snapshots / Сравнить снапшоты
sudo snapper rollback <ID>                    # Rollback system / Откатить систему
```

---

## 🚨 Troubleshooting / Устранение неполадок

### Repository Issues / Проблемы с репозиториями
If refresh fails or GPG checks fail:
```bash
sudo zypper clean --all
sudo zypper refresh --force                   # Force refresh / Принудительное обновление
```

### Dependency Hell / Проблемы с зависимостями
Zypper is interactive. If there is a conflict, it asks for a solution number. / Zypper интерактивен. Если есть конфликт, он просит выбрать номер решения.
1. Deinstall conflicting item / Удалить конфликтующий элемент
2. Keep obsolete item / Оставить устаревший элемент
3. Breaking dependency / Нарушить зависимость (Not recommended / Не рекомендуется)

### Check System Integrity / Проверка целостности системы
```bash
sudo zypper verify                            # Check for broken dependencies / Проверка сломанных зависимостей
sudo rpm -Va                                  # Verify all installed files / Проверка всех установленных файлов
```

---

## 📊 Comparison: Update vs Dup

| Feature | `update` (up) | `dist-upgrade` (dup) |
| :--- | :--- | :--- |
| **Scope** | Minor updates / Мелкие обновления | Major upgrades / Крупные обновления |
| **Vendor Change** | No (Sticky vendor) | Yes (Allow vendor change) |
| **Use Case** | Stability (Leap) | Tumbleweed Rolling |

---

## 🔒 Security / Безопасность

### Security Patches / Патчи безопасности
Zypper separates "patches" from "updates". / Zypper разделяет "патчи" и "обновления".

```bash
sudo zypper list-updates -t patch             # List security patches / Список патчей безопасности
sudo zypper patch --category security         # Install only security patches / Установить только патчи безопасности
```
