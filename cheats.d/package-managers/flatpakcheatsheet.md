Title: 📦 Flatpak — Application Sandboxes
Group: Package Managers
Icon: 📦
Order: 6

## Table of Contents
- [Description](#description)
- [Configuration](#-configuration--конфигурация)
- [Core Management](#-core-management--основное-управление)
- [Sysadmin Operations](#-sysadmin-operations--операции-системного-администратора)
- [Comparison: Flatpak vs Snap](#-comparison-flatpak-vs-snap)
- [Security](#-security--безопасность)
- [Documentation Links](#-documentation-links)

---

# 📦 Flatpak Cheatsheet (Application Sandboxes)

## Description

**Flatpak** is a framework for distributing desktop applications across various Linux distributions. Developed under the **freedesktop.org** umbrella, it provides a sandbox environment using Bubblewrap (bwrap) for isolation, allowing applications to run independently from the host system. Unlike Snap, Flatpak supports decentralized repositories (multiple remotes). / **Flatpak** — фреймворк для распространения десктопных приложений на Linux. Предоставляет песочницу для изоляции приложений и поддерживает децентрализованные репозитории.

**Status:** Actively maintained and widely adopted. Flatpak is the **preferred desktop application format** for Fedora, Linux Mint, elementary OS, and many other distributions. **Flathub** is the main repository with thousands of applications. Flatpak is **desktop-focused** and does not support server/CLI applications (unlike Snap). / **Статус:** Активно поддерживается. Предпочтительный формат для Fedora, Linux Mint и др.

---

## ⚙️ Configuration / Конфигурация

### Remotes (Repositories) / Удалённые репозитории (Remotes)
Manage where Flatpak downloads applications from (e.g., Flathub). / Управление источниками загрузки приложений (например, Flathub).

```bash
flatpak remotes                               # List configured remotes / Список настроенных репозиториев
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-delete <REMOTE>                # Remove remote / Удалить репозиторий
flatpak remote-modify <REMOTE> --enable       # Enable remote / Включить репозиторий
```

### Locations / Расположение
- **System Installation:** `/var/lib/flatpak/`
- **User Installation:** `~/.local/share/flatpak/`

---

## 🛠 Core Management / Основное управление

### Install / Установка
```bash
flatpak install flathub <APP_ID>              # Install from specific remote / Установить из конкретного репозитория
flatpak install <App_ID>                      # Search and install / Найти и установить
flatpak install --user <APP_ID>               # Install for current user only / Установить только для текущего пользователя
```

### Run / Запуск
```bash
flatpak run <APP_ID>                          # Launch application / Запустить приложение
flatpak run --command=bash <APP_ID>           # Run shell inside container / Запустить оболочку внутри контейнера
```

### Update / Обновление
```bash
flatpak update                                # Update all installed apps and runtimes / Обновить все установленные приложения и runtimes
flatpak update <APP_ID>                       # Update specific app / Обновить конкретное приложение
```

### List & Search / Список и поиск
```bash
flatpak list                                  # List installed apps / Список установленных приложений
flatpak list --app                            # List only apps (hide runtimes) / Список только приложений
flatpak search <KEYWORD>                      # Search for apps / Поиск приложений
flatpak info <APP_ID>                         # Show detailed info / Показать детальную информацию
```

### Remove / Удаление
```bash
flatpak uninstall <APP_ID>                    # Remove application / Удалить приложение
flatpak uninstall --unused                    # Remove unused runtimes (Important!) / Удалить неиспользуемые runtimes (Важно!)
flatpak uninstall --delete-data <APP_ID>      # Remove app and its data / Удалить приложение и его данные
```

---

## 🔧 Sysadmin Operations / Операции системного администратора

### Permissions (Overrides) / Права (Переопределения)
Manage sandbox permissions (filesystem, network, device access). / Управление правами песочницы (файловая система, сеть, доступ к устройствам).

```bash
flatpak override --show <APP_ID>              # Show current permissions / Показать текущие права
sudo flatpak override <APP_ID> --filesystem=home # Allow access to home folder / Разрешить доступ к домашней папке
sudo flatpak override <APP_ID> --socket=wayland # Allow access to Wayland / Разрешить доступ к Wayland
sudo flatpak override --reset <APP_ID>        # Reset permissions to default / Сбросить права к значениям по умолчанию
```

### Troubleshooting / Устранение неполадок
Repair installation errors. / Исправление ошибок установки.

```bash
flatpak repair                                # Deduplicate and repair installation / Дедупликация и исправление установки
flatpak repair --user                         # Repair user installation / Исправление установки пользователя
```

### Processes / Процессы
```bash
flatpak ps                                    # List running flatpak instances / Список запущенных экземпляров flatpak
flatpak kill <APP_ID>                         # Kill running instance / Убить запущенный экземпляр
```

---

## 📊 Comparison: Flatpak vs Snap

| Feature | Flatpak | Snap |
| :--- | :--- | :--- |
| **Backend** | Decentralized (Multiple remotes possible) | Centralized (Canonical Snap Store) |
| **Server Apps** | No (Focused on Desktop/GUI) | Yes (Strong server support) |
| **Format** | OCI-compatible images (OSTree) | SquashFS images |
| **Sandboxing** | Bubblewrap (bwp) | AppArmor + Cgroups |

---

## 🔒 Security / Безопасность

### Isolation / Изоляция
Flatpaks are sandboxed by default. They cannot see host processes or files unless explicitly allowed. / Flatpaks изолированы по умолчанию. Они не видят процессы хоста или файлы, если это явно не разрешено.

### Verification / Проверка
Check commit checksums. / Проверка контрольных сумм коммитов.

```bash
flatpak info --show-commit <APP_ID>           # Show commit hash / Показать хэш коммита
```

---

## 📚 Documentation Links

- **Flatpak Documentation:** https://docs.flatpak.org/
- **Flathub (App Store):** https://flathub.org/
- **Flatpak GitHub:** https://github.com/flatpak/flatpak
- **Flatpak Permissions:** https://docs.flatpak.org/en/latest/sandbox-permissions.html
- **Flatpak Builder:** https://docs.flatpak.org/en/latest/flatpak-builder.html
