Title: 📚 Linux Basics — Cheatsheet
Group: Basics
Icon: 📚
Order: 1

# 📚 Linux Basics — Cheatsheet

## 📚 Table of Contents / Содержание

1. [Navigation](#navigation--навигация)
2. [Files & Directories](#files--directories--файлы-и-папки)
3. [View & Edit](#view--edit--просмотр-и-редактирование)
4. [Nano Editor](#nano-editor--редактор-nano)
5. [Privileges](#privileges--права-и-привилегии)
6. [Package Management (APT)](#package-management-apt--управление-пакетами-apt)
7. [Process Management](#process-management--управление-процессами)
8. [System Information](#system-information--информация-о-системе)
9. [Network Basics](#network-basics--основы-сети)
10. [Helpful Tips](#helpful-tips--полезные-советы)

---

## Navigation / Навигация

```bash
pwd                                           # Show current directory / Показать текущую директорию
ls -la                                        # List detailed incl. hidden / Подробный список (включая скрытые)
cd /path/to/dir                               # Change directory / Перейти в папку
cd ..                                         # Up one level / Вверх на уровень
cd -                                          # Previous directory / В предыдущую папку
cd ~                                          # Home directory / Домашняя директория
cd /                                          # Filesystem root / Корень ФС
```

---

## Files & Directories / Файлы и Папки

```bash
mkdir newdir                                  # Create directory / Создать папку
mkdir -p a/b/c                                # Create nested dirs / Вложенные папки
touch file.txt                                # New empty/update mtime / Пустой файл/обновить время
cp file.txt backup.txt                        # Copy file / Копировать файл
cp -r dir/ dir_copy/                          # Recursive copy dir / Рекурсивно копировать каталог
cp -i file.txt backup.txt                     # Copy with prompt / Копировать с подтверждением
mv old.txt new.txt                            # Rename/move / Переименовать/переместить
mv file.txt /some/path/                       # Move to dir / Переместить в папку
mv -i file.txt /some/path/                    # Move with prompt / Перемещать с подтверждением
rm file.txt                                   # Delete file / Удалить файл
rm -i file.txt                                # Delete with prompt / Удалить с подтверждением
rm -r dir/                                    # Remove dir recursively / Рекурсивно удалить каталог
rm -rf dir/                                   # ⚠️ Force remove / ⚠️ Силовое удаление
rmdir emptydir                                # Remove empty dir / Удалить пустую папку
```

> [!CAUTION]
> `rm -rf` is extremely dangerous! Always double-check the path before executing.
> `rm -rf` крайне опасен! Всегда проверяйте путь перед выполнением.

---

## View & Edit / Просмотр и Редактирование

```bash
cat file.txt                                  # Print file / Вывести файл
less file.txt                                 # Pager (q exit, / search) / Просмотрщик (q выход, / поиск)
head -n 20 file.txt                           # First 20 lines / Первые 20 строк
tail -n 50 file.txt                           # Last 50 lines / Последние 50 строк
tail -f /var/log/syslog                       # Follow log / «Хвост» лога
```

---

## Nano Editor / Редактор Nano

```bash
nano file.txt                                 # Open in nano / Открыть в nano
```

| Shortcut | Action / Действие |
|----------|-------------------|
| `Ctrl+O` | Save / Сохранить |
| `Ctrl+X` | Exit / Выход |
| `Ctrl+W` | Search / Поиск |
| `Ctrl+K` | Cut line / Вырезать строку |
| `Ctrl+U` | Paste / Вставить |
| `Ctrl+\` | Replace / Замена |

---

## Privileges / Права и Привилегии

```bash
whoami                                        # Current user / Текущий пользователь
sudo command                                  # Run as root / Выполнить от root
sudo -i                                       # Root shell (root env) / Оболочка root (окружение root)
sudo -s                                       # Root shell (user env) / Оболочка root (ваше окружение)
su -                                          # Switch to root / Переключиться на root
```

---

## Package Management (APT) / Управление Пакетами (APT)

> [!NOTE]
> APT is the package manager for Debian/Ubuntu based distributions.
> APT — менеджер пакетов для Debian/Ubuntu дистрибутивов.

```bash
sudo apt update                               # Update package lists / Обновить списки пакетов
sudo apt upgrade                              # Upgrade packages / Установить обновления
sudo apt install htop                         # Install package / Установить пакет
sudo apt remove htop                          # Remove keep conf / Удалить (с конфигами)
sudo apt purge htop                           # Remove + purge conf / Удалить + конфиги
sudo apt autoremove                           # Remove unused deps / Удалить неисп. зависимости
apt search nginx                              # Search package / Поиск пакета
apt show nginx                                # Package info / Информация о пакете
do-release-upgrade                            # Upgrade to next Ubuntu release / Обновить до след. версии Ubuntu
```

### Debconf & GRUB Disk Configuration / Debconf и настройка диска GRUB

```bash
# Show GRUB install device configuration / Показать конфигурацию установки GRUB
debconf-show grub-pc | grep install_devices

# Change GRUB install device (e.g. /dev/sda→sdb) / Изменить диск установки GRUB
echo "grub-pc grub-pc/install_devices multiselect /dev/sdb" | debconf-set-selections

# Verify change / Проверить изменение
debconf-show grub-pc | grep install_devices
```

> [!WARNING]
> Wrong GRUB install device = unbootable system after kernel update. Always verify with `debconf-show grub-pc` after disk changes. / Неверный диск GRUB = незагружаемая система после обновления ядра.

### Ubuntu Minimal / Cloud Images / Ubuntu Minimal / Облачные образы

```bash
# Restore man pages and docs on minimal/cloud installs / Восстановить man-страницы на облачных образах
unminimize
```

---

## Process Management / Управление Процессами

```bash
ps aux                                        # All processes / Все процессы
ps aux | grep nginx                           # Search process / Найти процесс
top                                           # Live monitor (q exit) / Мониторинг (q — выход)
htop                                          # Enhanced top / Улучшенный top
pgrep -a nginx                                # Find PID by name / Найти PID по имени
kill 1234                                     # Kill process / Убить процесс
kill -9 1234                                  # Force kill / Принудительное завершение
killall nginx                                 # Kill by name / Убить по имени
pkill nginx                                   # Pattern kill / Убить по шаблону
jobs                                          # Background jobs / Фоновые задачи
fg                                            # Foreground job / На передний план
bg                                            # Background job / В фон
command &                                     # Run in background / Запустить в фоне
nohup command &                               # Run detached / Запустить независимо
```

---

## System Information / Информация о Системе

```bash
uname -a                                      # System info / Информация о системе
hostname                                      # Machine name / Имя машины
uptime                                        # System uptime / Время работы системы
whoami                                        # Current user / Текущий пользователь
id                                            # User ID info / Информация о UID/GID
w                                             # Who is logged in / Кто в системе
last                                          # Login history / История входов
free -h                                       # RAM usage / Использование памяти
df -h                                         # Disk usage / Использование дисков
du -sh *                                      # Dir sizes / Размеры папок
lsb_release -a                                # Distro info / Информация о дистрибутиве
cat /etc/os-release                           # OS info / Информация об ОС
lscpu                                         # CPU info / Информация о CPU
```

---

## Network Basics / Основы Сети

```bash
ip a                                          # IP addresses / IP-адреса
ip r                                          # Routes / Маршруты
ping -c 4 8.8.8.8                             # Ping 4 packets / Пинг 4 пакета
curl https://example.com                      # HTTP request / HTTP запрос
wget https://example.com/file                 # Download file / Скачать файл
ss -tulpn                                     # Listening ports / Прослушиваемые порты
netstat -tulpn                                # Network stats / Сетевая статистика
hostname -I                                   # Local IP / Локальный IP
```

---

## Helpful Tips / Полезные Советы

```bash
man ls                                        # Manual (q exit) / Руководство (q — выход)
ls --help                                     # Help options / Короткая справка
history                                       # Shell history / История команд
!123                                          # Run command #123 / Выполнить команду #123
sudo !!                                       # Repeat prev with sudo / Повторить прошлую с sudo
alias ll='ls -lah'                            # Create alias / Создать псевдоним
which command                                 # Command location / Расположение команды
type command                                  # Command type / Тип команды
echo $PATH                                    # PATH variable / Переменная PATH
export VAR=value                              # Set env variable / Установить переменную окружения
```

### Keyboard Shortcuts / Клавиатурные сокращения

| Shortcut | Action / Действие |
|----------|-------------------|
| `TAB` | Completion helps with paths and names / Дополняет пути и имена |
| `Ctrl+C` | Stops running command / Останавливает команду |
| `Ctrl+Z` | Suspends to background / Приостанавливает в фон |
| `Ctrl+R` | Search command history / Поиск по истории |
| `Ctrl+L` | Clear screen / Очистить экран |

---
