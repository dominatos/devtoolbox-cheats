Title: 💽 du/df/lsof/ps — Commands
Group: System & Logs
Icon: 💽
Order: 10

# Disk & Process Commands Cheatsheet

> **Context:** Essential disk usage and process monitoring commands. / Основные команды для мониторинга дисков и процессов.
> **Role:** Sysadmin / DevOps
> **Tools:** du, df, lsof, ps, top, htop

---

## 📚 Table of Contents / Содержание

1. [Disk Usage (du)](#disk-usage-du--использование-диска)
2. [Filesystem Info (df)](#filesystem-info-df--информация-о-фс)
3. [Open Files (lsof)](#open-files-lsof--открытые-файлы)
4. [Process Info (ps)](#process-info-ps--информация-о-процессах)
5. [Real-time Monitoring](#real-time-monitoring--мониторинг-в-реальном-времени)
6. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Disk Usage (du) / Использование диска

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

---

## 2. Filesystem Info (df) / Информация о ФС

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

---

## 3. Open Files (lsof) / Открытые файлы

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

## 4. Process Info (ps) / Информация о процессах

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

## 5. Real-time Monitoring / Мониторинг в реальном времени

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
```

### Other Tools / Другие инструменты
```bash
watch -n 1 'df -h'                        # Watch disk usage / Наблюдать за дисками
iotop                                     # I/O usage / Использование I/O
vmstat 1                                  # Virtual memory stats / Статистика памяти
```

---

## 6. Troubleshooting / Устранение неполадок

### Disk Full / Диск заполнен
```bash
# Find large directories / Найти большие директории
du -sh /var/* | sort -rh | head -10

# Find large files / Найти большие файлы
find / -xdev -type f -size +100M -exec ls -lh {} \;

# Check for deleted but open / Проверить удалённые но открытые
lsof +L1 | awk '{print $7, $9}' | sort -rn | head
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

# 💡 Best Practices / Лучшие практики
# Use htop for interactive monitoring / Используйте htop для интерактивного мониторинга
# Combine ps with grep for filtering / Комбинируйте ps с grep для фильтрации
# Check lsof +L1 when disk full / Проверяйте lsof +L1 при заполненном диске
# Use du -x to stay on one filesystem / Используйте du -x для одной ФС

# 📋 Quick Reference / Быстрый справочник
# du -sh *        — Directory sizes / Размеры папок
# df -hT          — Filesystem space / Пространство ФС
# lsof -i :PORT   — What's on port / Что на порту
# ps aux --sort   — Sorted processes / Сортированные процессы
