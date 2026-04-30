Title: 🕵️ Process Diagnostics — Process State/Resources/Network
Group: Diagnostics
Icon: 🕵️
Order: 2

# Process Diagnostics — ps / top / htop / proc / iotop

A comprehensive guide to Linux process inspection using standard OS utilities. These tools let you discover running processes, examine their state (CPU, RAM, I/O, threads, file descriptors), monitor network activity per process, and diagnose resource consumption issues. All commands rely on the `/proc` filesystem — a virtual interface to kernel data structures — making them lightweight and always available.

These tools (`ps`, `top`, `htop`, `pgrep`, `/proc`) are part of the `procps` package and ship with every Linux distribution. Modern alternatives like `btop`, `glances`, and `atop` offer richer UIs but rely on the same kernel interfaces.

📚 **Official Docs / Официальная документация:**
[ps(1)](https://man7.org/linux/man-pages/man1/ps.1.html) · [top(1)](https://man7.org/linux/man-pages/man1/top.1.html) · [htop(1)](https://man7.org/linux/man-pages/man1/htop.1.html) · [proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) · [pgrep(1)](https://man7.org/linux/man-pages/man1/pgrep.1.html) · [iotop(8)](https://man7.org/linux/man-pages/man8/iotop.8.html)

## Table of Contents
- [Process Discovery & Identification](#process-discovery--identification)
- [Process State & Activity](#process-state--activity)
- [Resource Consumption (CPU, RAM, I/O)](#resource-consumption-cpu-ram-io)
- [Network & Ports Monitoring](#network--ports-monitoring)
- [Thread Analysis](#thread-analysis)
- [File Handles & Descriptors](#file-handles--descriptors)
- [System Integration & Logging](#system-integration--logging)
- [Case Study: MySQL Monitoring](#case-study-mysql-monitoring)
- [Advanced Tracing & Debugging](#advanced-tracing--debugging)
- [Comparison Tables & Senior Tips](#comparison-tables--senior-tips)

---

## Process Discovery & Identification

### Search and List Processes / Поиск и перечисление процессов

```bash
ps aux | grep <PROCESS_NAME>                    # List processes by name / Список процессов по имени
pgrep -fl <PROCESS_NAME>                        # Find PID and full command line / Найти PID и полную строку команды
pidof <PROCESS_NAME>                             # Get PID only / Получить только PID
pstree -p <PID>                                 # Show process tree with PIDs / Показать дерево процессов с PID
```

### Useful ps Format Strings / Полезные форматы ps
```bash
ps -eo pid,ppid,user,%cpu,%mem,vsz,rss,stat,start,time,comm --sort=-%cpu | head -20  # Top CPU consumers / Топ потребители CPU
ps -eo pid,ppid,user,%cpu,%mem,vsz,rss,stat,start,time,comm --sort=-%mem | head -20  # Top RAM consumers / Топ потребители RAM
ps -eo pid,ppid,user,stat,wchan:20,cmd -p <PID>  # Process state with wait channel / Состояние с каналом ожидания
```

> [!TIP]
> Use `pgrep` instead of `ps aux | grep` — it avoids the common pitfall of grep matching itself and supports regex natively.
> / Используйте `pgrep` вместо `ps aux | grep` — это позволяет избежать частой ошибки, когда grep находит самого себя, и поддерживает regex.

---

## Process State & Activity

### Monitor Process State / Мониторинг состояния процесса

```bash
ps -o pid,state,wchan,cmd -p <PID>               # View process state and wait channel / Просмотр состояния и канала ожидания
cat /proc/<PID>/status | grep State             # Detailed state from procfs / Подробное состояние из procfs
cat /proc/<PID>/wchan                           # Current wait channel (kernel function) / Текущий канал ожидания (функция ядра)
cat /proc/<PID>/stack                           # Kernel call stack (if D/S state) / Стек вызовов ядра (если в состоянии D/S)
```

> [!NOTE]
> **Process State Codes / Коды состояний процессов:**
> - `R` (Running): Active on CPU / Активен на CPU.
> - `S` (Sleeping): Waiting for event (interruptible) / Ожидает события (прерываемый).
> - `D` (Uninterruptible Sleep): Waiting for I/O (cannot be killed) / Ожидает I/O (непрерываемый, нельзя убить).
> - `Z` (Zombie): Finished but not reaped by parent / Завершен, но не удален из таблицы родителем.
> - `T` (Stopped): Suspended by signal (SIGSTOP/SIGTSTP) / Приостановлен сигналом.
> - `t` (Traced): Stopped by debugger (ptrace) / Остановлен отладчиком.
> - `X` (Dead): Should never be seen / Не должен быть виден.

### Execution Context / Контекст выполнения
```bash
readlink /proc/<PID>/exe                        # Path to executable / Путь к исполняемому файлу
cat /proc/<PID>/cmdline | xargs -0              # Full launch command / Полная команда запуска
cat /proc/<PID>/environ | xargs -0 -n 1         # Environment variables / Переменные окружения
cat /proc/<PID>/limits                          # Resource limits (ulimit) / Лимиты ресурсов (ulimit)
```

> [!TIP]
> Reading `/proc/<PID>/environ` requires the same UID as the target process (or root). It reveals environment variables at process start time — they may have been modified since.
> / Чтение `/proc/<PID>/environ` требует того же UID, что и у процесса (или root). Показывает переменные окружения на момент запуска — они могли измениться позже.

---

## Resource Consumption (CPU, RAM, I/O)

### Detailed CPU and RAM Usage / Детальное использование CPU и RAM

```bash
top -p <PID>                                    # Monitor specific PID / Мониторинг конкретного PID
htop -p <PID>                                   # Interactive monitor for PID / Интерактивный монитор для PID
grep VmRSS /proc/<PID>/status                    # Resident memory size (RAM) / Объем резидентной памяти (ОЗУ)
pmap -x <PID> | tail -n 1                       # Detailed memory map summary / Итоговая сводка карты памяти
```

### Interactive Filters (Heavy Hitters) / Интерактивные фильтры

| Tool / Инструмент | Key / Клавиша | Action (EN / RU) |
| :--- | :--- | :--- |
| **top** | `P` | Sort by CPU usage / Сортировать по CPU |
| **top** | `M` | Sort by Memory usage / Сортировать по памяти |
| **top** | `1` | Toggle per-CPU view / Переключить вид по ядрам |
| **top** | `c` | Toggle full command line / Показать полную командную строку |
| **top** | `k` | Kill a process (enter PID) / Убить процесс (ввести PID) |
| **htop** | `F6` | Open sort menu / Открыть меню сортировки |
| **htop** | `F4` | Filter by name / Фильтр по имени |
| **htop** | `F5` | Toggle tree view / Вид дерева процессов |
| **htop** | `H` | Toggle threads visibility / Вкл/выкл отображение потоков |
| **htop** | `t` | Toggle tree view (alternate) / Вид дерева (альтернативный) |

### I/O Usage / Использование ввода-вывода
```bash
iotop -p <PID>                                  # Live I/O monitoring / Мониторинг I/O в реальном времени
iotop -oP                                       # Only show processes doing I/O / Только процессы с I/O
cat /proc/<PID>/io                              # I/O statistics counters / Счетчики статистики I/O
```

**Sample `/proc/<PID>/io` output / Пример вывода:**
```
rchar: 1234567890       # Bytes read from storage / Байт прочитано
wchar: 987654321        # Bytes written to storage / Байт записано
syscr: 45678            # Read syscalls count / Количество системных вызовов чтения
syscw: 23456            # Write syscalls count / Количество системных вызовов записи
read_bytes: 1048576     # Actual bytes read from disk / Реально прочитано с диска
write_bytes: 524288     # Actual bytes written to disk / Реально записано на диск
```

### Installation / Установка
```bash
sudo apt install htop iotop                     # Debian/Ubuntu
sudo dnf install htop iotop                     # RHEL/Fedora
sudo pacman -S htop iotop                       # Arch
```

---

## Network & Ports Monitoring

### Listeners and Connections / Слушатели и соединения

```bash
ss -tunap | grep <PID>                          # Current sockets by PID / Текущие сокеты по PID
netstat -plntu | grep <PID>                     # Listening ports (classic) / Прослушиваемые порты (классика)
lsof -i -nP -p <PID>                            # Network files opened by process / Сетевые файлы, открытые процессом
```

> [!NOTE]
> `ss` is the modern replacement for `netstat` and is faster on systems with thousands of connections. `netstat` is part of `net-tools` which is deprecated but still widely available.
> / `ss` — современная замена `netstat`, работает быстрее при тысячах соединений. `netstat` входит в `net-tools`, который считается устаревшим, но всё ещё доступен.

### Process-Targeted Bandwidth / Пропускная способность процесса
```bash
nethogs                                         # Monitor traffic per process / Мониторинг трафика по процессам
iftop -P -i <INTERFACE> -f "port <PORT>"        # Traffic on specific port / Трафик на конкретном порту
# Press 'P' in iftop to show ports / Нажмите 'P' в iftop для отображения портов
```

### Deep Packet Analysis / Глубокий анализ пакетов
```bash
tcpdump -i <INTERFACE> port <PORT> -n           # Capture port traffic / Захват трафика порта
tcpdump -i <INTERFACE> port <PORT> -A           # Show payload in ASCII / Показать содержимое в ASCII
tcpdump -i <INTERFACE> -w capture.pcap          # Save to file for Wireshark / Сохранить в файл для Wireshark
```

### Comparison: ss vs netstat / Сравнение: ss vs netstat

| Feature / Функция | `ss` | `netstat` |
| :--- | :--- | :--- |
| **Speed** / Скорость | Fast (direct kernel access) / Быстрый | Slower (reads /proc) / Медленнее |
| **Status** / Статус | Active, maintained / Активный | Deprecated / Устаревший |
| **Package** / Пакет | `iproute2` (default) | `net-tools` (install separately) |
| **Filter syntax** | Built-in state filters / Встроенная фильтрация | Requires grep / Требуется grep |
| **TCP state** | `ss -t state established` | `netstat -nt \| grep ESTABLISHED` |

---

## Thread Analysis

### Thread Count and Details / Количество и детали потоков

```bash
ps -o nlwp,pid,cmd -p <PID>                     # Show thread count (NLWP) / Показать количество потоков
ps -eLf | grep <PID>                            # List every thread separately / Список каждого потока отдельно
ls /proc/<PID>/task | wc -l                      # Count threads via procfs / Подсчет потоков через procfs
top -H -p <PID>                                 # Monitor individual threads / Мониторинг отдельных потоков
```

### Thread State Inspection / Инспекция состояния потоков
```bash
# Check state of each thread / Проверить состояние каждого потока
for tid in /proc/<PID>/task/*/; do
  echo "TID: $(basename $tid) State: $(cat ${tid}status | grep State)"
done
```

---

## File Handles & Descriptors

### Open Files Tracking / Отслеживание открытых файлов

```bash
lsof -p <PID>                                   # List all open files / Список всех открытых файлов
ls -l /proc/<PID>/fd                            # File descriptors count/paths / Пути и количество дескрипторов
ls /proc/<PID>/fd | wc -l                       # Count open file descriptors / Количество открытых дескрипторов
fuser -v <PATH_TO_FILE>                         # Find process using a file / Найти процесс, использующий файл
```

### File Descriptor Limits / Лимиты файловых дескрипторов
```bash
# Check current limits for process / Проверить текущие лимиты процесса
cat /proc/<PID>/limits | grep "Max open files"  # Per-process limit / Лимит процесса

# System-wide limits / Системные лимиты
cat /proc/sys/fs/file-nr                        # allocated / unused / max / выделено / не использовано / максимум
sysctl fs.file-max                              # System max open files / Системный максимум
```

> [!WARNING]
> If a process approaches its `Max open files` limit, it will start failing with `EMFILE: Too many open files`. Check with `ls /proc/<PID>/fd | wc -l` vs `cat /proc/<PID>/limits | grep "Max open files"`.
> / Если процесс приближается к лимиту `Max open files`, начнётся ошибка `EMFILE: Too many open files`. Проверьте: `ls /proc/<PID>/fd | wc -l` против `cat /proc/<PID>/limits | grep "Max open files"`.

---

## System Integration & Logging

### Service Control & Logs / Управление сервисом и логи

```bash
systemctl status <SERVICE_NAME>                 # Check systemd status / Проверить статус systemd
systemctl restart <SERVICE_NAME>                # Restart service / Перезапустить сервис
systemctl stop <SERVICE_NAME>                   # Stop service / Остановить сервис
journalctl -u <SERVICE_NAME> -f                 # Follow service logs / Следить за логами сервиса
journalctl -u <SERVICE_NAME> --since "1 hour ago" # Logs for last hour / Логи за последний час
journalctl -u <SERVICE_NAME> -p err             # Only error messages / Только ошибки
```

### Common Log Locations / Типичные пути логов
```bash
# /var/log/syslog          — Main system log / Основной системный лог (Debian/Ubuntu)
# /var/log/messages        — Main system log / Основной системный лог (RHEL/CentOS)
# /var/log/kern.log        — Kernel messages / Сообщения ядра
# /var/log/dmesg           — Boot/hardware messages / Сообщения загрузки/оборудования
# /var/log/auth.log        — Authentication log / Лог аутентификации
```

---

## Case Study: MySQL Monitoring

### Targeting MySQL Specifically / Специфический мониторинг MySQL

```bash
# 1. Identify MySQL process / Найти процесс MySQL
pgrep -u mysql -fa

# 2. Check MySQL threads / Проверить потоки MySQL
ps -o nlwp,pid,cmd -p $(pgrep -u mysql -x mysqld)

# 3. Monitor MySQL memory / Мониторинг памяти MySQL
grep VmRSS /proc/$(pgrep -u mysql -x mysqld)/status

# 4. MySQL network activity / Сетевая активность MySQL
ss -tunap | grep mysqld
iftop -P -i <INTERFACE> -f "port 3306"          # Default MySQL port / Стандартный порт MySQL

# 5. Internal MySQL Diagnostics / Внутренняя диагностика MySQL
# Run inside mysql client / Выполнять внутри mysql-клиента
mysql -u <USER> -p -e "SHOW PROCESSLIST;"       # List active threads / Список активных потоков
mysql -u <USER> -p -e "SHOW ENGINE INNODB STATUS\G" # Detailed InnoDB state / Детальное состояние InnoDB
```

> [!TIP]
> MySQL uses a **One-Process-Many-Threads** model. Resource visibility in `top`/`htop` often combines all threads into the main process. Use `top -H` or MySQL's Performance Schema for granular internal thread info.
> / MySQL использует модель **Один-Процесс-Много-Потоков**. В `top`/`htop` ресурсы всех потоков объединяются в основной процесс. Используйте `top -H` или Performance Schema MySQL для детализации.

### MySQL Key Metrics to Watch / Ключевые метрики MySQL

| Metric / Метрика | How to Check / Как проверить | When to Alert / Когда тревога |
| :--- | :--- | :--- |
| **Threads running** | `SHOW STATUS LIKE 'Threads_running'` | > CPU cores × 2 |
| **Slow queries** | `SHOW STATUS LIKE 'Slow_queries'` | Growing fast / Быстро растёт |
| **Open files** | `ls /proc/$(pgrep mysqld)/fd \| wc -l` | Near `open_files_limit` |
| **RSS memory** | `grep VmRSS /proc/$(pgrep mysqld)/status` | Near `innodb_buffer_pool_size` |
| **Connections** | `SHOW STATUS LIKE 'Threads_connected'` | Near `max_connections` |

---

## Advanced Tracing & Debugging

### Low-Level Activity / Низкоуровневая активность

```bash
strace -p <PID> -f -e trace=network,file        # Trace syscalls / Трассировка системных вызовов
perf top -p <PID>                               # CPU profiling / Профилирование CPU
gdb -p <PID>                                    # Attach debugger (EXPERT ONLY) / Подключить отладчик (ТОЛЬКО ЭКСПЕРТЫ)
```

> [!WARNING]
> Attaching `strace` or `gdb` to a high-load production process can cause significant performance degradation or temporarily "freeze" the app. Always test on staging first.
> / Подключение `strace` или `gdb` к высоконагруженному процессу может вызвать серьезное замедление или временную «заморозку» приложения. Сначала тестируйте на staging.

> [!CAUTION]
> `gdb -p` will **STOP the target process** until you type `continue`. On a database or web server, this means instant downtime for all clients.
> / `gdb -p` **ОСТАНОВИТ целевой процесс** до команды `continue`. Для базы данных или веб-сервера это означает мгновенный простой для всех клиентов.

### bpftrace (Modern Alternative) / bpftrace (Современная альтернатива)
```bash
# Count syscalls per process / Подсчёт системных вызовов по процессам
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens for specific PID / Трассировать открытие файлов для PID
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /pid == <PID>/ { printf("%s\n", str(args->filename)); }'
```

> [!NOTE]
> `bpftrace` uses eBPF (extended Berkeley Packet Filter) and has **much lower overhead** than `strace`. Requires kernel 4.9+ with CONFIG_BPF enabled.
> / `bpftrace` использует eBPF и имеет **значительно меньшую нагрузку**, чем `strace`. Требуется ядро 4.9+ с CONFIG_BPF.

---

## Comparison Tables & Senior Tips

### Comparison: Process Memory Metrics / Сравнение: Метрики памяти процессов

| Metric / Метрика | Name (EN / RU) | Description (EN / RU) | Use Case / Когда смотреть |
| :--- | :--- | :--- | :--- |
| **VIRT** | Virtual Image / Виртуальная | Total address space (shared + mapped + reserved) / Весь адресный объем | General limits / Общие лимиты |
| **RSS** | Resident Set / Резидентная | Non-swapped physical RAM actually in use / Физическая ОЗУ без swap | Actual usage / Реальное потребление |
| **SHR** | Shared Memory / Разделяемая | Memory shared with other processes (libs) / Память, общая с другими (библиотеки) | Library impact / Влияние библиотек |
| **SWAP** | Swap Size / Своп | Memory moved to disk / Выгруженная на диск память | Memory pressure / Дефицит памяти |
| **PSS** | Proportional Set / Пропорциональная | RSS divided by number of sharers / RSS делённая на число пользователей | True cost per process / Реальная стоимость |

> [!IMPORTANT]
> **VIRT ≠ real memory usage.** A process can reserve 10 GB of virtual memory but only use 100 MB of RAM (RSS). Never alarm on high VIRT alone.
> / **VIRT ≠ реальное потребление.** Процесс может зарезервировать 10 ГБ виртуальной памяти, но использовать лишь 100 МБ ОЗУ (RSS). Никогда не паникуйте из-за высокого VIRT.

### Comparison: Process Monitoring Tools / Сравнение: Инструменты мониторинга

| Tool / Инструмент | Type / Тип | Strengths (EN / RU) | Install |
| :--- | :--- | :--- | :--- |
| **top** | Built-in | Everywhere, lightweight / Везде, легковесный | Pre-installed |
| **htop** | Interactive | Color, tree, mouse, filtering / Цвет, дерево, мышь, фильтр | `apt install htop` |
| **atop** | Historical | Records to file, I/O, disk / Запись в файл, I/O, диски | `apt install atop` |
| **btop** | Modern TUI | Beautiful, Rust-based, themes / Красивый, на Rust, темы | `apt install btop` |
| **glances** | Web/API | REST API, export, plugins / REST API, экспорт, плагины | `pip install glances` |
| **nmon** | Performance | CSV export for analysis / CSV экспорт для анализа | `apt install nmon` |

### Senior Tips / Советы для опытных

#### Soft vs Hard Limits / Мягкие и жёсткие лимиты
```bash
ulimit -Sn                                     # Soft open files limit / Мягкий лимит файлов
ulimit -Hn                                     # Hard open files limit / Жёсткий лимит файлов
# Soft limits can be raised by the process up to Hard limit
# Hard limits can only be raised by root
# Мягкие лимиты могут быть подняты процессом до жёсткого лимита
# Жёсткие лимиты может поднять только root
```

#### Zombie Processes / Зомби-процессы
```bash
# Find zombie processes / Найти зомби-процессы
ps aux | awk '$8 == "Z" {print}'

# Find parent of zombie / Найти родителя зомби
ps -o ppid= -p <ZOMBIE_PID>

# A zombie doesn't consume CPU/RAM but takes a process table slot
# Cleaning requires parent to wait() or killing the parent
# Зомби не потребляет CPU/RAM, но занимает слот в таблице процессов
# Очистка требует вызова wait() от родителя или убийства родителя
```

> [!WARNING]
> Do NOT blindly kill parent processes of zombies — the parent may be a critical service. First identify the parent with `ps -o ppid= -p <ZOMBIE_PID>` and check what it is.
> / НЕ убивайте бездумно родительские процессы зомби — родитель может быть критически важным сервисом. Сначала определите родителя и проверьте, что это за процесс.

#### D-State (Uninterruptible Sleep) / Состояние D (непрерываемый сон)
```bash
# Find processes in D-state / Найти процессы в состоянии D
ps aux | awk '$8 ~ /D/ {print}'

# Check what they're waiting for / Проверить чего они ждут
cat /proc/<PID>/wchan                           # Wait channel / Канал ожидания
cat /proc/<PID>/stack                           # Kernel stack / Стек ядра

# D-state usually means wait for hardware I/O (disk/NFS)
# The process CANNOT be killed by SIGKILL until I/O returns
# Состояние D обычно означает ожидание I/O (диск/NFS)
# Процесс НЕЛЬЗЯ убить сигналом SIGKILL до завершения I/O
```

> [!CAUTION]
> Processes stuck in D-state for extended periods often indicate hardware failure (dying disk, NFS server down, iSCSI timeout). Investigate the underlying storage layer, not the process itself.
> / Процессы, надолго застрявшие в состоянии D, часто указывают на отказ оборудования (умирающий диск, NFS сервер недоступен, iSCSI таймаут). Расследуйте уровень хранения, а не сам процесс.

#### Quick Diagnostic One-Liners / Быстрые диагностические команды
```bash
# Top 10 CPU consuming processes / Топ-10 потребителей CPU
ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -11

# Top 10 RAM consuming processes / Топ-10 потребителей RAM
ps -eo pid,%cpu,%mem,rss,comm --sort=-rss | head -11

# Count all processes by user / Количество процессов по пользователям
ps -eo user --no-headers | sort | uniq -c | sort -rn

# Find processes with most open files / Процессы с наибольшим числом открытых файлов
for pid in /proc/[0-9]*/fd; do echo "$(ls $pid 2>/dev/null | wc -l) $pid"; done | sort -rn | head -10
```

---

## Documentation Links

- **procps (ps, top, pgrep, sysctl):** https://gitlab.com/procps-ng/procps
- **htop:** https://htop.dev/ | https://github.com/htop-dev/htop
- **iotop:** https://man7.org/linux/man-pages/man8/iotop.8.html
- **btop (modern alternative):** https://github.com/aristocratos/btop
- **glances (web-based):** https://nicolargo.github.io/glances/
- **atop (historical):** https://www.atoptool.nl/
- **bpftrace (eBPF tracing):** https://github.com/bpftrace/bpftrace
- **Brendan Gregg — Linux Performance:** https://www.brendangregg.com/linuxperf.html
