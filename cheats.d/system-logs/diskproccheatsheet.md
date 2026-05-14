Title: 💽 du/df/lsof/ps — Commands
Group: System & Logs
Icon: 💽
Order: 10

# du/df/lsof/ps — Disk & Process Commands

**du, df, lsof, ps** are foundational Linux command-line utilities for monitoring disk usage, filesystem space, open files, and process information. These are among the most frequently used tools in daily sysadmin work.

**Tool overview / Обзор инструментов:**
- **du** (disk usage) — estimates file and directory sizes
- **df** (disk free) — reports filesystem disk space usage
- **lsof** (list open files) — lists files opened by processes (files, sockets, pipes)
- **ps** (process status) — displays information about active processes
- **top/htop** — interactive real-time process monitors

These are part of GNU coreutils (`du`, `df`), the `lsof` package, and `procps-ng` (`ps`, `top`), pre-installed on virtually all Linux distributions.

📚 **Official Docs / Официальная документация:**
[du(1)](https://man7.org/linux/man-pages/man1/du.1.html) · [df(1)](https://man7.org/linux/man-pages/man1/df.1.html) · [lsof(8)](https://man7.org/linux/man-pages/man8/lsof.8.html) · [ps(1)](https://man7.org/linux/man-pages/man1/ps.1.html) · [top(1)](https://man7.org/linux/man-pages/man1/top.1.html)

## Table of Contents
- [Disk Usage (du)](#disk-usage-du)
- [Filesystem Info (df)](#filesystem-info-df)
- [Open Files (lsof)](#open-files-lsof)
- [Process Info (ps)](#process-info-ps)
- [Real-time Monitoring](#real-time-monitoring)
- [Troubleshooting](#troubleshooting)

---

## Disk Usage (du)

### Basic Usage / Базовое использование

```bash
du -sh *                                  # Size of each item / Размер каждого элемента
du -sh * | sort -h                        # Sorted by size / Сортировка по размеру
du -sh /var/log                           # Specific directory / Конкретная директория
du -h --max-depth=1                       # One level deep / На один уровень
```

### Advanced / Продвинутое

```bash
du -ah /var | sort -rh | head -20         # Top 20 largest / Топ 20 крупнейших
du -sh --exclude='*.log' /var             # Exclude pattern / Исключить шаблон
du -c /home/*                             # Total for multiple dirs / Итого для нескольких папок
du -x /                                   # Same filesystem only / Только одна ФС
```

### Sample Output / Пример вывода

```text
4.0K    file.txt
12M     logs/
256M    database/
1.2G    backups/
```

> [!TIP]
> Use `du -x` to stay on one filesystem — prevents counting NFS/tmpfs mounts. Use `ncdu` for an interactive TUI alternative.
> Используйте `du -x` чтобы оставаться на одной ФС. Используйте `ncdu` для интерактивного TUI.

---

## Filesystem Info (df)

### Basic Usage / Базовое использование

```bash
df -h                                     # Human-readable / Читаемый формат
df -hT                                    # With filesystem type / С типом ФС
df -i                                     # Inode usage / Использование inodes
df -h /                                   # Specific mount / Конкретная точка
```

### Advanced / Продвинутое

```bash
df -h --output=source,size,used,avail,pcent,target  # Custom columns / Выборочные столбцы
df -t ext4                                # Only ext4 / Только ext4
df -x tmpfs -x devtmpfs                   # Exclude virtual FS / Исключить виртуальные ФС
```

### Sample Output / Пример вывода

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   25G   23G  53% /
/dev/sdb1       100G   80G   15G  85% /data
```

> [!WARNING]
> `df` can show 100% used even when files were deleted — if a process still holds the file handle open, the space won't be reclaimed. Use `lsof +L1` to find these.
> `df` может показать 100% даже после удаления файлов — если процесс держит дескриптор. Используйте `lsof +L1`.

---

## Open Files (lsof)

### By Port / По порту

```bash
lsof -i :80                               # Port 80 / Порт 80
lsof -i :5432                             # PostgreSQL port / Порт PostgreSQL
lsof -i :22                               # SSH connections / SSH соединения
lsof -i tcp:8080                          # TCP port 8080 / TCP порт 8080
```

### By Process / По процессу

```bash
lsof -p <PID>                             # Files by PID / Файлы по PID
lsof -c nginx                             # Files by command / Файлы по команде
lsof -u <USER>                            # Files by user / Файлы по пользователю
```

### Special Cases / Особые случаи

```bash
lsof +L1                                  # Deleted but open files / Удалённые но открытые
lsof +D /var/log                          # All files in dir / Все файлы в директории
lsof /path/to/file                        # Who uses this file / Кто использует файл
```

### Network / Сеть

```bash
lsof -i                                   # All network connections / Все сетевые соединения
lsof -iTCP -sTCP:LISTEN                   # Listening TCP / Слушающие TCP
lsof -i @<IP>                             # Connections to IP / Соединения к IP
```

---

## Process Info (ps)

### Basic Usage / Базовое использование

```bash
ps aux                                    # All processes / Все процессы
ps aux | grep nginx                       # Filter by name / Фильтр по имени
ps -ef                                    # Full format / Полный формат
ps -u <USER>                              # By user / По пользователю
```

### Resource Sorting / Сортировка по ресурсам

```bash
ps aux --sort=-%mem | head                # Top memory consumers / Топ по памяти
ps aux --sort=-%cpu | head                # Top CPU consumers / Топ по CPU
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head  # Custom columns / Выборочные столбцы
```

### Process Tree / Дерево процессов

```bash
ps auxf                                   # Process tree / Дерево процессов
ps -ejH                                   # Hierarchical view / Иерархический вид
pstree -p                                 # Visual tree with PIDs / Дерево с PID
```

### Find Specific / Поиск конкретных

```bash
pgrep -a nginx                            # PIDs with command / PID с командой
pgrep -u root                             # PIDs by user / PID по пользователю
pidof nginx                               # PID of process / PID процесса
```

---

## Real-time Monitoring

### top / htop

```bash
top                                       # Live process monitor / Монитор процессов
htop                                      # Enhanced top / Улучшенный top
top -p <PID>                              # Monitor specific PID / Мониторить конкретный PID
top -u <USER>                             # Filter by user / Фильтр по пользователю
```

### top Shortcuts / Горячие клавиши top

```text
M — Sort by memory / Сортировка по памяти
P — Sort by CPU / Сортировка по CPU
k — Kill process / Убить процесс
q — Quit / Выход
1 — Toggle per-CPU stats / Показать по каждому CPU
c — Toggle full command / Показать полную команду
```

### Other Tools / Другие инструменты

```bash
watch -n 1 'df -h'                        # Watch disk usage / Наблюдать за дисками
iotop                                     # I/O usage / Использование I/O
vmstat 1                                  # Virtual memory stats / Статистика памяти
dstat                                     # Combined CPU/disk/net stats / Комбинированная статистика
```

---

## Troubleshooting

### Disk Full / Диск заполнен

```bash
# Find large directories / Найти большие директории
du -sh /var/* | sort -rh | head -10

# Find large files / Найти большие файлы
find / -xdev -type f -size +100M -exec ls -lh {} \;

# Check for deleted but open / Проверить удалённые но открытые
lsof +L1 | awk '{print $7, $9}' | sort -rn | head

# Inode exhaustion / Исчерпание inodes
df -i
find / -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -20
```

### High CPU / Высокая нагрузка CPU

```bash
# Find top CPU processes / Топ процессов по CPU
ps aux --sort=-%cpu | head -10

# Real-time monitoring / Мониторинг в реальном времени
top -bn1 | head -20
```

### Memory Issues / Проблемы с памятью

```bash
# Memory overview / Обзор памяти
free -h

# Top memory processes / Топ процессов по памяти
ps aux --sort=-%mem | head -10

# Detailed memory info / Подробная информация о памяти
cat /proc/meminfo
```

### Process Using Resource / Процесс использующий ресурс

```bash
# What's using this file / Что использует этот файл
fuser -v /path/to/file

# What's holding this port / Что занимает этот порт
ss -tlnp | grep :8080
lsof -i :8080
```

---

## 💡 Best Practices / Лучшие практики

- Use `htop` for interactive monitoring. / Используйте `htop` для интерактивного мониторинга.
- Combine `ps` with `grep` for filtering. / Комбинируйте `ps` с `grep` для фильтрации.
- Check `lsof +L1` when disk is full (deleted but open files). / Проверяйте `lsof +L1` при заполненном диске.
- Use `du -x` to stay on one filesystem. / Используйте `du -x` для одной ФС.
- Check `df -i` for inode exhaustion (many small files). / Проверяйте `df -i` для исчерпания inodes.

---

## Documentation Links

- **du(1):** https://man7.org/linux/man-pages/man1/du.1.html
- **df(1):** https://man7.org/linux/man-pages/man1/df.1.html
- **lsof(8):** https://man7.org/linux/man-pages/man8/lsof.8.html
- **ps(1):** https://man7.org/linux/man-pages/man1/ps.1.html
- **top(1):** https://man7.org/linux/man-pages/man1/top.1.html
- **fuser(1):** https://man7.org/linux/man-pages/man1/fuser.1.html
- **ArchWiki — Core Utilities:** https://wiki.archlinux.org/title/Core_utilities
