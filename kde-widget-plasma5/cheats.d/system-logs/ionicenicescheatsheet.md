Title: 📜 ionice & nice — Priority Control
Group: System & Logs
Icon: 📜
Order: 98

# ionice & nice Sysadmin Cheatsheet

> **Context:** CPU and I/O priority control for processes. / Управление приоритетами CPU и I/O для процессов.
> **Role:** Sysadmin / DevOps
> **Tools:** nice, renice, ionice

---

## 📚 Table of Contents / Содержание

1. [nice — CPU Priority](#nice--cpu-priority--приоритет-cpu)
2. [renice — Change Priority](#renice--change-priority--изменение-приоритета)
3. [ionice — I/O Priority](#ionice--io-priority--приоритет-io)
4. [Combined Usage](#combined-usage--комбинированное-использование)
5. [Best Practices](#best-practices--лучшие-практики)

---

## 1. nice — CPU Priority / Приоритет CPU

### Basic Usage / Базовое использование
nice запускает процесс с изменённым приоритетом CPU (niceness).
nice starts a process with modified CPU priority (niceness).

```bash
nice <COMMAND>                            # Default +10 niceness / По умолчанию +10
nice -n 10 <COMMAND>                      # Run with niceness 10 / Запустить с niceness 10
nice -n 19 <COMMAND>                      # Lowest priority / Минимальный приоритет
sudo nice -n -20 <COMMAND>                # Highest priority (root) / Максимальный приоритет (root)
```

### Niceness Values / Значения niceness
```text
-20 = Highest priority / Максимальный приоритет (только root)
  0 = Default / По умолчанию
+19 = Lowest priority / Минимальный приоритет

Negative values = Higher priority / Отрицательные = выше приоритет
Positive values = Lower priority / Положительные = ниже приоритет
```

### Examples / Примеры
```bash
nice -n 19 tar czf backup.tgz /data       # Low priority backup / Бэкап с низким приоритетом
nice -n 10 find / -type f > list.txt      # Background search / Фоновый поиск
sudo nice -n -5 nginx                     # Higher priority nginx / Nginx с высоким приоритетом
```

---

## 2. renice — Change Priority / Изменение приоритета

### By PID / По PID
```bash
renice -n 10 -p <PID>                     # Set niceness 10 / Установить niceness 10
sudo renice -n -5 -p <PID>                # Higher priority (root) / Повысить приоритет (root)
renice -n 19 -p <PID>                     # Lowest priority / Минимальный приоритет
```

### By User / По пользователю
```bash
renice -n 10 -u <USER>                    # All user processes / Все процессы пользователя
sudo renice -n -5 -u root                 # All root processes / Все процессы root
```

### By Process Group / По группе процессов
```bash
renice -n 10 -g <PGID>                    # All in group / Все в группе
```

### Check Current Priority / Проверить текущий приоритет
```bash
ps -l -p <PID>                            # NI column shows niceness / Столбец NI показывает niceness
top                                       # NI column in top / Столбец NI в top
```

---

## 3. ionice — I/O Priority / Приоритет I/O

### Basic Usage / Базовое использование
ionice управляет приоритетом ввода-вывода (диск).
ionice controls I/O (disk) priority.

```bash
ionice <COMMAND>                          # Show/set I/O priority / Показать/установить приоритет I/O
ionice -p <PID>                           # Show priority of PID / Показать приоритет PID
ionice -c <CLASS> -n <LEVEL> <COMMAND>    # Set class and level / Установить класс и уровень
```

### I/O Classes (-c) / Классы I/O
```text
Class 1 = realtime   — Highest, root only, can starve system / Максимальный, только root, может повесить систему
Class 2 = best-effort — Default, adjustable via -n / По умолчанию, настраивается через -n
Class 3 = idle       — Only when disk is idle / Только когда диск свободен
```

### I/O Levels (-n) / Уровни I/O
```text
0 = Highest priority (for class 2) / Максимальный приоритет (для класса 2)
7 = Lowest priority (for class 2) / Минимальный приоритет (для класса 2)
```

### Examples / Примеры
```bash
ionice -c3 rsync -a /mnt/data /backup     # Idle class backup / Бэкап в классе idle
ionice -c2 -n7 find / -type f > list.txt  # Low priority search / Поиск с низким приоритетом
ionice -c2 -n0 dd if=/dev/zero of=/dev/sda  # High priority dd / dd с высоким приоритетом
ionice -p 1234                            # Show priority of PID / Показать приоритет PID
```

### For Running Processes / Для запущенных процессов
```bash
ionice -c3 -p <PID>                       # Set PID to idle class / Установить PID в класс idle
ionice -c2 -n7 -p <PID>                   # Set PID to low priority / Установить PID в низкий приоритет
```

---

## 4. Combined Usage / Комбинированное использование

### Low CPU + Low I/O / Низкий CPU + низкий I/O
```bash
ionice -c3 nice -n19 tar czf /backup.tgz /data
# Minimal CPU and disk impact / Минимальное влияние на CPU и диск

ionice -c3 nice -n19 rsync -a /source /dest
# Background rsync / Фоновый rsync

ionice -c2 -n7 nice -n10 find / -type f -mtime +30 > old_files.txt
# Low priority file search / Поиск файлов с низким приоритетом
```

### High Priority (Admin) / Высокий приоритет (Админ)
```bash
sudo ionice -c1 -n0 nice -n-10 <CRITICAL_COMMAND>
# Maximum priority (use with caution) / Максимальный приоритет (осторожно!)
```

### Verification / Проверка
```bash
# Check both CPU and I/O priority / Проверить приоритеты CPU и I/O
ps -o pid,ni,comm -p <PID>                # CPU niceness / CPU niceness
ionice -p <PID>                           # I/O priority / Приоритет I/O
```

---

## 5. Best Practices / Лучшие практики

### Recommended Priorities / Рекомендуемые приоритеты
```text
Backup jobs:      ionice -c3 nice -n19     # Lowest / Минимальный
Log rotation:     ionice -c2 -n7 nice -n10 # Low / Низкий
Normal tasks:     (default)                # Standard / Стандартный
Database:         ionice -c2 -n0 nice -n-5 # Higher / Повышенный
Critical apps:    ionice -c1 nice -n-10    # Highest / Максимальный
```

### Use Cases / Варианты использования
```bash
# Backup scripts / Скрипты бэкапа
ionice -c3 nice -n19 /usr/local/bin/backup.sh

# Cron jobs / Задачи cron
# Add to crontab: 0 3 * * * ionice -c3 nice -n19 /path/to/script.sh

# Database dumps / Дампы БД
ionice -c2 -n7 nice -n10 pg_dump mydb > backup.sql
ionice -c2 -n7 nice -n10 mysqldump --all-databases > backup.sql
```

### Notes / Примечания
```text
- ionice works with block devices (HDD, SSD, NVMe) / работает с блочными устройствами
- Uses I/O scheduler (cfq, bfq, mq-deadline) / использует I/O scheduler
- Combine with nice for both CPU and I/O control / комбинируйте с nice для контроля CPU и I/O
- Ideal for: rsync, find, tar, dd, gzip, bzip2 / идеально для: rsync, find, tar, dd, gzip, bzip2
- Root required for negative niceness / root нужен для отрицательного niceness
- Root required for realtime I/O class / root нужен для realtime класса I/O
```

---

# 💡 Quick Reference / Быстрый справочник
# nice -n19 cmd           — Lowest CPU priority / Минимальный приоритет CPU
# ionice -c3 cmd          — Idle I/O class / Класс I/O idle
# ionice -c3 nice -n19 cmd — Both low / Оба низкие
# renice -n10 -p PID      — Change running process / Изменить запущенный процесс

# 📋 Priority Levels Summary / Сводка уровней приоритета
# CPU (nice):  -20 (high) → 0 (default) → +19 (low)
# I/O (ionice): Class 1 (realtime) → Class 2 (best-effort) → Class 3 (idle)
