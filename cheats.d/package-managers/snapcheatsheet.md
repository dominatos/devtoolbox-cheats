Title: 📦 Snap — Universal Packages
Group: Package Managers
Icon: 📦
Order: 5

## Table of Contents
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Comparison: Confinement Modes](#-comparison-confinement-modes)
- [Security](#-security--безопасность)

---

# 📦 Snap Cheatsheet (Universal Packages)

Snap is a software deployment and package management system developed by Canonical. Snaps are self-contained applications with all their dependencies. / Snap — это система развертывания ПО и управления пакетами, разработанная Canonical. Snap-пакеты — это автономные приложения со всеми зависимостями.

---

## ⚙️ Configuration / Конфигурация

### Main Configuration / Основная конфигурация
Snap is primarily configured via system settings or command line arguments, rather than text files. / Snap в основном настраивается через системные настройки или аргументы командной строки, а не через текстовые файлы.

`/var/snap/` (User data and configs / Данные пользователя и конфиги)
`/snap/` (Mount points for read-only squashfs images / Точки монтирования для read-only образов squashfs)

### Proxy Configuration / Настройка прокси
```bash
sudo snap set system proxy.http="http://<HOST>:<PORT>"
sudo snap set system proxy.https="http://<HOST>:<PORT>"
```

---

## 🛠 Core Management / Основное управление

### Install / Установка
```bash
sudo snap install <PACKAGE>                   # Install snap / Установить snap
sudo snap install <PACKAGE> --classic         # Install with classic confinement / Установить с классической изоляцией
sudo snap install <PACKAGE> --edge            # Install from edge channel / Установить из канала edge
sudo snap install <PACKAGE> --beta            # Install from beta channel / Установить из канала beta
sudo snap install <PACKAGE> --candidate       # Install from candidate channel / Установить из канала candidate
```

### Search & List / Поиск и список
```bash
snap find <KEYWORD>                           # Search for snaps / Поиск снапов
snap list                                     # List installed snaps / Список установленных снапов
snap info <PACKAGE>                           # Show snap details / Показать детали снапа
snap download <PACKAGE>                       # Download snap file / Скачать файл снапа
```

### Update & Refresh / Обновление
Snap updates automatically. Manual control: / Snap обновляется автоматически. Ручное управление:

```bash
sudo snap refresh                             # Update all snaps / Обновить все снапы
sudo snap refresh <PACKAGE>                   # Update specific snap / Обновить конкретный снап
sudo snap revert <PACKAGE>                    # Revert to previous version / Вернуться к предыдущей версии
sudo snap switch --channel=<CHANNEL> <PACKAGE> # Switch channel / Переключить канал (stable, candidate, beta, edge)
```

### Remove / Удаление
```bash
sudo snap remove <PACKAGE>                    # Remove snap / Удалить snap
sudo snap remove <PACKAGE> --purge            # Remove without saving snapshot / Удалить без сохранения снимка данных
```

---

## 🔧 Sysadmin Operations / Операции системного администратора

### Services & Logs / Сервисы и логи
Snaps can register systemd services. / Snap-пакеты могут регистрировать сервисы systemd.

```bash
snap services                                 # List services / Список сервисов
sudo snap start <SERVICE>                     # Start service / Запустить сервис
sudo snap stop <SERVICE>                      # Stop service / Остановить сервис
sudo snap restart <SERVICE>                   # Restart service / Перезапустить сервис
snap logs <SERVICE>                           # Show service logs / Показать логи сервиса
snap logs -f <SERVICE>                        # Follow service logs / Следить за логами сервиса
```

### Connections & Permissions / Соединения и права
Manage permissions (interfaces) for isolated apps. / Управление правами (интерфейсами) для изолированных приложений.

```bash
snap connections <PACKAGE>                    # List interfaces / Список интерфейсов
sudo snap connect <PACKAGE>:<PLUG> <SLOT>     # Connect interface manually / Подключить интерфейс вручную
sudo snap disconnect <PACKAGE>:<PLUG>         # Disconnect interface / Отключить интерфейс
```

### Snapshots (Backups) / Снимки (Резервные копии)
Automatic snapshots on remove. Manual management: / Автоматические снимки при удалении. Ручное управление:

```bash
snap saved                                    # List saved snapshots / Список сохраненных снимков
sudo snap save <PACKAGE>                      # Create snapshot / Создать снимок
sudo snap restore <ID>                        # Restore snapshot / Восстановить снимок
sudo snap forget <ID>                         # Delete snapshot / Удалить снимок
```

---

## 🚨 Troubleshooting / Устранение неполадок

### Debugging / Отладка
```bash
snap debug confinement                        # Print confinement mode / Показать режим изоляции
snap debug connectivity                       # Check connectivity / Проверить соединение
snap run --shell <PACKAGE>                    # Run shell inside snap environment / Запустить оболочку внутри окружения snap
```

### Disk Space / Дисковое пространство
Snap keeps old versions. To free space: / Snap хранит старые версии. Чтобы освободить место:

```bash
sudo snap set system refresh.retain=2         # Keep only 2 versions / Хранить только 2 версии
# Manually remove disabled snaps / Вручную удалить отключенные снапы
snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do sudo snap remove "$snapname" --revision="$revision"; done
```

---

## 📊 Comparison: Confinement Modes

| Mode | Description (EN) | Description (RU) |
| :--- | :--- | :--- |
| **Strict** | Strongly isolated, no access to system files (Typical). | Сильно изолирован, нет доступа к системным файлам (Типично). |
| **Classic** | Full access to system (like apt/dnf). Required by IDEs, compilers. | Полный доступ к системе (как apt/dnf). Требуется для IDE, компиляторов. |
| **Devmode** | Strict but with full access logging (For developers). | Строгий, но с логированием полного доступа (Для разработчиков). |

---

## 🔒 Security / Безопасность

### Sandbox / Песочница
Snaps run in a sandbox using AppArmor, Seccomp, and cgroups. / Snap-пакеты запускаются в песочнице, используя AppArmor, Seccomp и cgroups.

Check current mode:
```bash
snap list <PACKAGE>                           # Check notes column / Проверить колонку заметок
```
