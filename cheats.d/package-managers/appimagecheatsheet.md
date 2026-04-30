Title: 📦 AppImage — Portable Apps
Group: Package Managers
Icon: 📦
Order: 7

## Table of Contents
- [Description](#description)
- [Core Management](#-core-management--основное-управление)
- [Advanced Operations](#-advanced-operations--продвинутые-операции)
- [Comparison: AppImage vs Others](#-comparison-appimage-vs-others)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Documentation Links](#-documentation-links)

---

# 📦 AppImage Cheatsheet (Portable Apps)

## Description

**AppImage** is a format for distributing portable software on Linux without needing superuser permissions to install. Each AppImage is a single self-contained file that bundles the application and all its dependencies. Just download, make executable, and run — no installation, no root access required. / **AppImage** — формат для распространения портативного ПО на Linux без необходимости прав суперпользователя. Каждый AppImage — один самодостаточный файл.

**Status:** Actively maintained but less popular than Flatpak/Snap for new projects. AppImage has no centralized store or automatic updates (though AppImageUpdate exists). It remains useful for distributing portable tools, one-off applications, and software that needs to run across many distro versions without modification. **Alternatives:** Flatpak (sandboxed desktop apps), Snap (universal packages with auto-updates). / **Статус:** Активно поддерживается, но менее популярен чем Flatpak/Snap. **Альтернативы:** Flatpak, Snap.

---

## 🛠 Core Management / Основное управление

### Execution / Запуск
AppImages are single files that just need to be made executable. / AppImages — это одиночные файлы, которые нужно просто сделать исполняемыми.

```bash
chmod +x <FILE>.AppImage                      # Make executable / Сделать исполняемым
./<FILE>.AppImage                             # Run / Запустить
```

### Installation (Integration) / Установка (Интеграция)
Since AppImages are not installed, "installation" means integrating them into the system menu. / Поскольку AppImages не устанавливаются, "установка" означает интеграцию их в системное меню.

**Tools:**
- **AppImageLauncher**: Monitors your Applications directory and integrates AppImages automatically. / Мониторит вашу директорию приложений и автоматически интегрирует AppImages.

#### Install AppImageLauncher (Ubuntu/Debian) / Установка AppImageLauncher
```bash
sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo apt update
sudo apt install appimagelauncher
```

#### Manual Desktop Entry Example / Пример ручной записи Desktop Entry
File path: `~/.local/share/applications/<APP>.desktop`

```ini
[Desktop Entry]
Name=<APP_NAME>
Exec=/path/to/<FILE>.AppImage
Icon=/path/to/icon.png
Type=Application
Categories=Utility;
```

---

## 🔧 Advanced Operations / Продвинутые операции

### Extract Contents / Извлечение содержимого
If you need to inspect the contents or modify the AppImage. / Если нужно проверить содержимое или изменить AppImage.

```bash
./<FILE>.AppImage --appimage-extract          # Extract to squashfs-root/ / Извлечь в squashfs-root/
```

### Update / Обновление
AppImageUpdate lets you update AppImages using binary delta updates (only downloads changes). / AppImageUpdate позволяет обновлять AppImages используя бинарные дельта-обновления (скачивает только изменения).

```bash
# Requires AppImageUpdate tool / Требуется инструмент AppImageUpdate
./AppImageUpdate-x86_64.AppImage <FILE>.AppImage
```

### Portable Home / Портативная домашняя директория
Create a directory with the same name as the AppImage plus `.home` to store configuration alongside the app. / Создайте директорию с тем же именем, что и AppImage плюс `.home`, чтобы хранить конфигурацию рядом с приложением.

```bash
mkdir <FILE>.AppImage.home                    # Create portable home / Создать портативную домашнюю директорию
# The app will now store config/data here instead of ~/.config / Приложение теперь будет хранить конфиг/данные здесь, а не в ~/.config
```

---

## 📊 Comparison: AppImage vs Others

| Feature | AppImage | Flatpak/Snap |
| :--- | :--- | :--- |
| **Installation** | Not required (Portable) | Required |
| **Dependencies** | Bundled inside file | Bundled in runtime/snap |
| **Root Access** | No | Yes (for install) |
| **Sandboxing** | No (by default) | Yes (Strong) |
| **Updates** | Download new file (or AppImageUpdate) | Repository based (Automatic) |

---

## 🚨 Troubleshooting / Устранение неполадок

### FUSE Errors / Ошибки FUSE
AppImages rely on FUSE (Filesystem in Userspace). If you get `dlopen(): error loading libfuse.so.2`: / AppImages полагаются на FUSE. Если вы получаете ошибку `libfuse.so.2`:

```bash
# Ubuntu 22.04+ (Restores FUSE 2 support) / Восстанавливает поддержку FUSE 2
sudo apt install libfuse2
```

### Sandboxing (Firejail) / Изоляция (Firejail)
Since AppImages are not sandboxed, use Firejail for security. / Поскольку AppImages не изолированы, используйте Firejail для безопасности.

```bash
firejail ./<FILE>.AppImage                    # Run in sandbox / Запустить в песочнице
```

---

## 📚 Documentation Links

- **AppImage Official:** https://appimage.org/
- **AppImage Documentation:** https://docs.appimage.org/
- **AppImageHub (Directory):** https://www.appimagehub.com/
- **AppImageLauncher:** https://github.com/TheAssassin/AppImageLauncher
- **AppImageUpdate:** https://github.com/AppImage/AppImageUpdate
