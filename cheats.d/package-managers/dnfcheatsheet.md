Title: 📦 DNF — RHEL/Fedora
Group: Package Managers
Icon: 📦
Order: 2

## Table of Contents
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Comparison: DNF vs YUM](#-comparison-dnf-vs-yum)
- [Security](#-security--безопасность)

---

# 📦 DNF Cheatsheet (RHEL/Fedora/CentOS)

Dandified YUM (DNF) is the next-generation version of the Yellowdog Updater, Modified (yum), a package manager for .rpm-based distributions. / Dandified YUM (DNF) — это следующее поколение Yellowdog Updater, Modified (yum), менеджера пакетов для дистрибутивов на базе .rpm.

---

## ⚙️ Configuration / Конфигурация

### Main Configuration Files / Основные файлы конфигурации
`/etc/dnf/dnf.conf`
`/etc/yum.repos.d/*.repo`

### Add Repository / Добавить репозиторий
```bash
sudo dnf config-manager --add-repo <URL>      # Add repository / Добавить репозиторий
sudo dnf config-manager --set-enabled <REPO_ID> # Enable repository / Включить репозиторий
sudo dnf config-manager --set-disabled <REPO_ID> # Disable repository / Отключить репозиторий
```

### Proxy Configuration / Настройка прокси
`/etc/dnf/dnf.conf`
```ini
proxy=http://<HOST>:<PORT>
proxy_username=<USER>
proxy_password=<PASSWORD>
```

---

## 🛠 Core Management / Основное управление

### Update & Upgrade / Обновление
```bash
sudo dnf check-update                         # Check for updates / Проверить наличие обновлений
sudo dnf upgrade                              # Upgrade packages / Обновить пакеты
sudo dnf upgrade <PACKAGE>                    # Update specific package / Обновить конкретный пакет
sudo dnf upgrade --refresh                    # Force metadata refresh / Принудительное обновление метаданных
```

### Install & Remove / Установка и удаление
```bash
sudo dnf install <PACKAGE>                    # Install package / Установить пакет
sudo dnf install <PKG1> <PKG2>                # Install multiple / Установить несколько
sudo dnf install <URL_TO_RPM>                 # Install from URL / Установить по URL
sudo dnf localinstall <PATH_TO_RPM>           # Install local RPM / Установить локальный RPM
sudo dnf reinstall <PACKAGE>                  # Reinstall package / Переустановить пакет
sudo dnf remove <PACKAGE>                     # Remove package / Удалить пакет
sudo dnf autoremove                           # Remove unused dependencies / Удалить неиспользуемые зависимости
```

### Search & Info / Поиск и информация
```bash
dnf search <KEYWORD>                          # Search packages / Поиск пакетов
dnf info <PACKAGE>                            # Show package details / Показать детали пакета
dnf list installed                            # List installed packages / Список установленных пакетов
dnf list available                            # List available packages / Список доступных пакетов
dnf repoquery --list <PACKAGE>                # List files in package / Список файлов в пакете
dnf provides <FILE_PATH>                      # Find package owning file / Найти пакет, владеющий файлом
```

### Groups / Группы
Install collections of software (e.g., "Server with GUI", "Development Tools"). / Установка коллекций ПО.

```bash
dnf group list                                # List groups / Список групп
dnf group summary                             # Show group summary / Показать сводку по группам
sudo dnf group install "<GROUP_NAME>"         # Install group / Установить группу
sudo dnf group remove "<GROUP_NAME>"          # Remove group / Удалить группу
```

---

## 🔧 Sysadmin Operations / Операции системного администратора

### Clean & Maintenance / Очистка и обслуживание
```bash
sudo dnf clean all                            # Remove cached data / Удалить кэшированные данные
sudo dnf clean dbcache                        # Clean metadata / Очистить метаданные
sudo dnf makecache                            # Update metadata cache / Обновить кэш метаданных
```

### History & Undo / История и откат
> [!IMPORTANT]
> DNF keeps a history of transactions, allowing you to undo or redo changes. / DNF хранит историю транзакций, позволяя отменять или повторять изменения.

```bash
sudo dnf history                              # Show transaction history / Показать историю транзакций
sudo dnf history info <ID>                    # Show details of transaction <ID> / Показать детали транзакции <ID>
sudo dnf history undo <ID>                    # Undo transaction <ID> / Отменить транзакцию <ID>
sudo dnf history rollback <ID>                # Rollback to before transaction <ID> / Откатить до транзакции <ID>
```

### Modules / Модули
Manage versions of applications (streams). / Управление версиями приложений (потоками).

```bash
dnf module list                               # List modules / Список модулей
dnf module list <PACKAGE>                     # List specific module / Показать конкретный модуль
sudo dnf module enable <PACKAGE>:<STREAM>     # Enable stream / Включить поток
sudo dnf module install <PACKAGE>:<STREAM>    # Install stream / Установить поток
sudo dnf module reset <PACKAGE>               # Reset module stream / Сбросить поток модуля
```

### Logs / Логи
- **DNF Log:** `/var/log/dnf.log` - Main log file.
- **RPM Log:** `/var/log/dnf.rpm.log` - RPM transaction log.

```bash
tail -f /var/log/dnf.log                      # Monitor DNF activity / Мониторинг активности DNF
```

---

## 🚨 Troubleshooting / Устранение неполадок

### Metadata Issues / Проблемы с метаданными
If you encounter synchronization errors:
```bash
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo dnf makecache
```

### RPM Database Recovery / Восстановление базы RPM
> [!CAUTION]
> Rebuilding the RPM database carries risks. Backup `/var/lib/rpm` first. / Перестройка базы RPM несет риски. Сделайте копию `/var/lib/rpm`.

```bash
sudo rpm --rebuilddb                          # Rebuild database / Перестроить базу данных
```

### Broken Dependencies / Сломанные зависимости
```bash
sudo dnf distro-sync                          # Synchronize packages to latest versions / Синхронизировать пакеты до последних версий
sudo package-cleanup --problems               # List dependency problems / Список проблем с зависимостями
sudo package-cleanup --orphans                # List orphan packages / Список пакетов-сирот
```

---

## 📊 Comparison: DNF vs YUM

| Feature | `dnf` | `yum` (Legacy) |
| :--- | :--- | :--- |
| **Performance** | Faster dependency resolution (C/C++) | Slower (Python) |
| **Memory Usage** | Optimized / Оптимизировано | High / Высокое |
| **API** | Stable, documented API | Undocumented |
| **Command Syntax** | Mostly compatible | Original |

---

## 🔒 Security / Безопасность

### GPG Keys / GPG Ключи
Manage keys used to verify packages. / Управление ключами для проверки пакетов.

```bash
rpm -qa gpg-pubkey*                           # List installed keys / Список установленных ключей
sudo rpm --import <KEY_FILE>                  # Import key / Импортировать ключ
```
