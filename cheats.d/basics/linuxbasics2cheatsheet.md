Title: 📗 Linux Basics 2 — Next Steps
Group: Basics
Icon: 📗
Order: 2

# 📗 Linux Basics 2 — Next Steps

## 📚 Table of Contents / Содержание

1. [Permissions & Owners](#permissions-owners-права-и-владельцы)
2. [Users & Groups](#users-groups-пользователи-и-группы)
3. [Processes](#processes-процессы)
4. [Network Basics](#network-basics-сеть-база)
5. [Archives](#archives-архивы)
6. [Disk & Memory](#disk-memory-диск-и-память)
7. [System Information](#system-information-информация-о-системе)
8. [Helpful Shortcuts](#helpful-shortcuts-полезные-сокращения)

---

## Permissions & Owners / Права и Владельцы

### Permission Basics / Основы прав

```bash
ls -l                                          # Long list / Длинный список
chmod +x script.sh                             # Make executable / Сделать исполняемым
chmod 644 file                                 # rw-r--r-- / Права rw-r--r--
chmod 755 dir                                  # rwxr-xr-x / Папка исполнимая
chmod u+r,g-w,o-x file                         # Symbolic perms / Символьные права
chmod -R 755 /path/dir                         # Recursive perms / Рекурсивно применить
```

### Ownership / Владение

```bash
sudo chown <USER> file                         # Change owner / Сменить владельца
sudo chown -R <USER>:<GROUP> dir               # Chown + group (rec) / Владельца+группу рекурсивно
chgrp developers file                          # Change group / Сменить группу
```

### Permission Reference / Справка по правам

| Numeric | Symbolic | Description / Описание |
|---------|----------|------------------------|
| `644` | `rw-r--r--` | Files: owner can read/write / Файлы: владелец r/w |
| `755` | `rwxr-xr-x` | Directories & scripts / Папки и скрипты |
| `600` | `rw-------` | Private files / Приватные файлы |
| `700` | `rwx------` | Private directories / Приватные папки |

---

## Users & Groups / Пользователи и Группы

```bash
whoami                                         # Current user / Текущий пользователь
id                                             # UID/GID / UID/GID
groups                                         # User groups / Группы пользователя
sudo usermod -aG docker $USER                  # Add to group / Добавить в группу
newgrp docker                                  # Apply new group / Применить группу без релогина
```

### User Management / Управление пользователями

```bash
sudo useradd -m <USER>                         # Create user with home dir / Создать пользователя
sudo passwd <USER>                             # Set password / Установить пароль
sudo userdel -r <USER>                         # Delete user and home / Удалить пользователя и home
sudo usermod -aG <GROUP> <USER>                # Add user to group / Добавить в группу
```

---

## Processes / Процессы

```bash
ps aux | grep nginx                            # Search process / Найти процесс
pgrep -a ssh                                   # PIDs by name / PIDы по имени
top                                            # Live monitor / Мониторинг (q выход)
htop                                           # Fancy top / Улучшенный top
kill -TERM 1234                                # Graceful kill / Корректно завершить
kill -9 1234                                   # ⚠️ Force kill / ⚠️ Жёстко убить
killall nginx                                  # Kill by name / Завершить по имени
nice -n 10 long_task &                         # Lower priority / Пониженный приоритет
sudo renice -n 10 -p 1234                      # Change priority / Изменить приоритет
```

> [!WARNING]
> `kill -9` (SIGKILL) should be used as last resort. It doesn't allow the process to clean up.
> `kill -9` (SIGKILL) использовать в крайнем случае. Не даёт процессу завершиться корректно.

---

## Network Basics / Сеть (База)

```bash
ip a                                           # IP addresses / IP-адреса
ip r                                           # Routes / Маршруты
ping -c 4 8.8.8.8                              # Ping 4 packets / 4 пакета
curl -I https://example.com                    # HTTP HEAD / Заголовки HTTP(S)
ss -tulpn | grep ':22'                         # Who listens 22 / Кто слушает порт 22
```

---

## Archives / Архивы

```bash
tar -xzvf file.tar.gz                          # Extract tar.gz / Распаковать .tar.gz
tar -czvf archive.tar.gz dir/                  # Create tar.gz / Упаковать каталог
zip -r archive.zip dir/                        # Zip recursively / Создать zip
unzip archive.zip -d out/                      # Unzip to out/ / Распаковать в out/
gzip -k file && gunzip file.gz                 # Gzip/ungzip / Сжать/распаковать
```

### Common Archive Formats / Распространённые форматы

| Format | Compress / Сжатие | Extract / Распаковка |
|--------|-------------------|----------------------|
| `.tar.gz` | `tar -czvf archive.tar.gz dir/` | `tar -xzvf archive.tar.gz` |
| `.tar.bz2` | `tar -cjvf archive.tar.bz2 dir/` | `tar -xjvf archive.tar.bz2` |
| `.zip` | `zip -r archive.zip dir/` | `unzip archive.zip` |
| `.7z` | `7z a archive.7z dir/` | `7z x archive.7z` |

---

## Disk & Memory / Диск и Память

```bash
df -h                                          # Filesystems usage / Использование ФС
du -sh * | sort -h                             # Sizes sorted / Размеры объектов
free -h                                        # RAM & swap / Память и swap
lsblk                                          # Block devices / Блочные устройства
mount | column -t                              # Mounted filesystems / Смонтированные ФС
findmnt                                        # Tree of mounts / Дерево монтирования
```

---

## System Information / Информация о Системе

```bash
uname -a                                       # Kernel info / Информация о ядре
hostname                                       # Machine name / Имя машины
hostnamectl                                    # Detailed hostname info / Подробная информация
uptime                                         # System uptime / Время работы
w                                              # Who is logged in / Кто в системе
last                                           # Login history / История входов
dmesg | tail                                   # Kernel messages / Сообщения ядра
lscpu                                          # CPU info / Информация о CPU
lsmem                                          # Memory info / Информация о памяти
lsusb                                          # USB devices / USB устройства
lspci                                          # PCI devices / PCI устройства
```

---

## Helpful Shortcuts / Полезные Сокращения

| Shortcut | Action / Действие |
|----------|-------------------|
| `Ctrl+C` | Stop current command / Остановить команду |
| `Ctrl+Z` | Suspend to background / Приостановить в фон |
| `Ctrl+D` | Exit shell / Выйти из оболочки |
| `Ctrl+L` | Clear screen / Очистить экран |
| `Ctrl+A` | Go to line start / В начало строки |
| `Ctrl+E` | Go to line end / В конец строки |
| `Ctrl+U` | Delete from cursor to start / Удалить от курсора до начала |
| `Ctrl+K` | Delete from cursor to end / Удалить от курсора до конца |
| `Ctrl+W` | Delete word before cursor / Удалить слово перед курсором |
| `Ctrl+R` | Search history / Поиск по истории |
| `TAB` | Autocomplete / Автодополнение |
| `!!` | Last command / Последняя команда |
| `!$` | Last argument / Последний аргумент |

---
