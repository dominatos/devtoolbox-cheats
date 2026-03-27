Title: 🔍 Diagnostics — strace/perf/tcpdump/lsof
Group: Diagnostics
Icon: 🔍
Order: 1

# Diagnostics — strace / perf / tcpdump / lsof / ltrace

A collection of essential Linux diagnostic and tracing tools for low-level system analysis. **strace** traces system calls between user-space programs and the kernel. **perf** provides hardware/software performance counters and CPU profiling with minimal overhead. **tcpdump** captures and analyzes network packets at the wire level. **lsof** lists open files and network connections for any process. **ltrace** traces dynamic library calls. Together they form the core toolkit for debugging performance bottlenecks, network issues, and application misbehavior on any Linux system.

All tools are actively maintained and part of most Linux distributions. There are no direct replacements, though higher-level tools (e.g., `bpftrace`, Wireshark, `sysdig`) build upon similar kernel subsystems.

📚 **Official Docs / Официальная документация:**
[strace(1)](https://man7.org/linux/man-pages/man1/strace.1.html) · [perf](https://perf.wiki.kernel.org/) · [tcpdump(1)](https://www.tcpdump.org/manpages/tcpdump.1.html) · [lsof(8)](https://man7.org/linux/man-pages/man8/lsof.8.html) · [ltrace(1)](https://man7.org/linux/man-pages/man1/ltrace.1.html)

## Table of Contents
- [strace — System Call Tracing](#strace--system-call-tracing)
- [perf — Performance Analysis](#perf--performance-analysis)
- [tcpdump — Network Packet Capture](#tcpdump--network-packet-capture)
- [lsof — List Open Files](#lsof--list-open-files)
- [ltrace — Library Call Tracing](#ltrace--library-call-tracing)
- [Tool Comparison](#tool-comparison)
- [Common strace Filters](#common-strace-filters)
- [Troubleshooting Workflows](#troubleshooting-workflows)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)

---

## strace — System Call Tracing

### Description / Описание

`strace` intercepts and records every system call a process makes, plus signals it receives. It works via the `ptrace()` mechanism, which means **significant overhead** (2–100× slowdown). Use it for debugging, not profiling.

### Installation / Установка
```bash
sudo apt install strace                       # Debian/Ubuntu
sudo dnf install strace                       # RHEL/Fedora
sudo pacman -S strace                         # Arch
```

### Basic Usage / Базовое использование
```bash
strace <COMMAND>                              # Trace command / Трассировать команду
strace ls -la                                 # Trace ls command / Трассировать команду ls
strace -p <PID>                               # Attach to running process / Подключиться к процессу
strace -p <PID> -f                            # Follow child processes / Следовать за дочерними процессами
```

### Output Options / Опции вывода
```bash
strace -o trace.txt <COMMAND>                 # Save to file / Сохранить в файл
strace -o trace.txt -f -tt -T -s 200 -p <PID> # Detailed trace / Детальная трассировка
# -f: follow forks / следовать за fork
# -tt: timestamps with microseconds / временные метки с микросекундами
# -T: show time spent in calls / показать время вызовов
# -s 200: string size limit / лимит размера строки
```

### Filter by Syscall / Фильтр по системным вызовам
```bash
strace -e trace=open,read,write <COMMAND>     # Trace specific calls / Трассировать конкретные вызовы
strace -e trace=network -p <PID>              # Network syscalls / Сетевые системные вызовы
strace -e trace=file -p <PID>                 # File operations / Файловые операции
strace -e trace=process -p <PID>              # Process operations / Операции процессов
strace -e trace=signal -p <PID>               # Signal handling / Обработка сигналов
strace -e trace=ipc -p <PID>                  # IPC operations / IPC операции
```

### Statistics / Статистика
```bash
strace -c <COMMAND>                           # Summary statistics / Сводная статистика
strace -c -p <PID>                            # Count syscalls / Подсчитать системные вызовы
strace -c -S time <COMMAND>                   # Sort by time / Сортировать по времени
strace -c -S calls <COMMAND>                  # Sort by call count / Сортировать по числу вызовов
```

**Sample output / Пример вывода:**
```
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 45.22    0.001245          12       103           read
 30.11    0.000829           8       100           write
 15.67    0.000431          21        20         5 open
  9.00    0.000248           6        40           close
------ ----------- ----------- --------- --------- ----------------
100.00    0.002753                   263         5 total
```

### Advanced / Продвинутое использование
```bash
strace -e trace=open,openat -e signal=none <COMMAND>  # Open calls, no signals / Вызовы open, без сигналов
strace -y -p <PID>                            # Show file descriptor paths / Показать пути дескрипторов
strace -k -p <PID>                            # Show stack traces / Показать stack traces
strace -r <COMMAND>                           # Relative timestamps / Относительные метки времени
```

> [!WARNING]
> `strace` attaches via `ptrace()` which **pauses and resumes** the target on every syscall. Do NOT use on hot production processes without understanding the impact (2–100× slowdown).
> / `strace` подключается через `ptrace()`, что **приостанавливает и возобновляет** процесс на каждом системном вызове. НЕ используйте на нагруженных продакшен-процессах без понимания последствий (замедление в 2–100 раз).

---

## perf — Performance Analysis

### Description / Описание

`perf` is the official Linux kernel profiling tool. It uses hardware performance counters and kernel tracepoints with **minimal overhead** (1–5%), making it safe for production use. It supports CPU sampling (flame graphs), cache/branch analysis, and per-function breakdowns.

### Installation / Установка
```bash
sudo apt install linux-tools-common linux-tools-$(uname -r)  # Debian/Ubuntu
sudo dnf install perf                         # RHEL/Fedora
sudo pacman -S perf                           # Arch
```

> [!NOTE]
> The kernel version of `linux-tools` must match your running kernel. After a kernel update, reinstall `linux-tools-$(uname -r)`.
> / Версия `linux-tools` должна соответствовать версии работающего ядра. После обновления ядра переустановите `linux-tools-$(uname -r)`.

### Top CPU Consumers / Топ потребителей CPU
```bash
sudo perf top                                 # Live CPU hot spots / «Горячие точки» CPU
sudo perf top -p <PID>                        # Top for specific process / Top для конкретного процесса
sudo perf top -g                              # Call graph / Граф вызовов
```

### Record and Report / Запись и отчёт
```bash
sudo perf record -g -- <COMMAND>              # Record with call graph / Записать с графом вызовов
sudo perf record -g -p <PID>                  # Record process / Записать процесс
sudo perf record -g -a -- sleep 10            # Record all CPUs for 10s / Записать все CPU 10с
sudo perf report                              # View report / Просмотр отчёта
sudo perf report --stdio                      # Text report / Текстовый отчёт
```

### CPU Profiling / Профилирование CPU
```bash
sudo perf stat <COMMAND>                      # Performance statistics / Статистика производительности
sudo perf stat -p <PID>                       # Stats for process / Статистика для процесса
sudo perf stat -a -- sleep 5                  # System-wide for 5s / Для всей системы 5с
sudo perf stat -e cpu-cycles,instructions <COMMAND>  # Specific events / Конкретные события
```

### Flame Graphs / Flame-графы
```bash
# Step 1: Record CPU samples / Шаг 1: Записать семплы CPU
sudo perf record -F 99 -a -g -- sleep 30      # Record for 30s at 99 Hz / Записать 30с на частоте 99 Гц

# Step 2: Export to readable script / Шаг 2: Экспортировать в читаемый скрипт
sudo perf script > out.perf                   # Export data / Экспортировать данные

# Step 3: Generate flame graph / Шаг 3: Генерировать flame граф
# Requires https://github.com/brendangregg/FlameGraph
stackcollapse-perf.pl out.perf | flamegraph.pl > perf.svg
```

> [!TIP]
> `-F 99` samples at 99 Hz (not 100) to avoid lockstep aliasing with kernel timers. This is a Brendan Gregg best practice.
> / `-F 99` сэмплирует на частоте 99 Гц (а не 100), чтобы избежать резонанса с таймерами ядра. Это лучшая практика от Brendan Gregg.

### List Available Events / Список доступных событий
```bash
perf list                                     # List all events / Список всех событий
perf list cache                               # Cache events / События кэша
perf list hw                                  # Hardware events / Аппаратные события
perf list sw                                  # Software events / Программные события
```

---

## tcpdump — Network Packet Capture

### Description / Описание

`tcpdump` captures network packets directly from interfaces using the `libpcap` library. It can display packet headers, payloads (ASCII/Hex), and filter by BPF (Berkeley Packet Filter) expressions. Output files (`.pcap`) are compatible with Wireshark/tshark.

### Installation / Установка
```bash
sudo apt install tcpdump                      # Debian/Ubuntu
sudo dnf install tcpdump                      # RHEL/Fedora
sudo pacman -S tcpdump                        # Arch
```

### Default Ports / Стандартные порты
```bash
# Common ports used in tcpdump filters:
# 22   — SSH
# 53   — DNS
# 80   — HTTP
# 443  — HTTPS
# 3306 — MySQL
# 5432 — PostgreSQL
# 6379 — Redis
# 8080 — HTTP alt / management
```

### Basic Capture / Базовый захват
```bash
sudo tcpdump                                  # Capture all interfaces / Захват всех интерфейсов
sudo tcpdump -i eth0                          # Capture specific interface / Захват конкретного интерфейса
sudo tcpdump -i any                           # Capture all interfaces / Захват всех интерфейсов
sudo tcpdump -n                               # No DNS resolution / Без DNS разрешения
sudo tcpdump -nn                              # No DNS/port resolution / Без DNS/портов
```

### Protocol Filters / Фильтры протоколов
```bash
sudo tcpdump tcp                              # TCP packets only / Только TCP пакеты
sudo tcpdump udp                              # UDP packets only / Только UDP пакеты
sudo tcpdump icmp                             # ICMP packets only / Только ICMP пакеты
sudo tcpdump arp                              # ARP packets only / Только ARP пакеты
```

### Port Filters / Фильтры портов
```bash
sudo tcpdump port 80                          # HTTP traffic / HTTP трафик
sudo tcpdump port 443                         # HTTPS traffic / HTTPS трафик
sudo tcpdump tcp port 22                      # SSH traffic / SSH трафик
sudo tcpdump 'tcp port 80 or tcp port 443'    # HTTP or HTTPS / HTTP или HTTPS
sudo tcpdump portrange 8000-9000              # Port range / Диапазон портов
```

### Host Filters / Фильтры хостов
```bash
sudo tcpdump host <IP>                        # Specific host / Конкретный хост
sudo tcpdump src <IP>                         # Source IP / IP источника
sudo tcpdump dst <IP>                         # Destination IP / IP назначения
sudo tcpdump net 192.168.1.0/24               # Network / Сеть
```

### Output Options / Опции вывода
```bash
sudo tcpdump -w capture.pcap                  # Write to file / Записать в файл
sudo tcpdump -r capture.pcap                  # Read from file / Читать из файла
sudo tcpdump -A                               # ASCII output / ASCII вывод
sudo tcpdump -X                               # Hex and ASCII / Hex и ASCII
sudo tcpdump -s 0                             # Capture full packets / Захват полных пакетов
sudo tcpdump -s0 -A -i any host <IP>          # Full packets ASCII / Полные пакеты ASCII
```

### Advanced Filters / Продвинутые фильтры
```bash
sudo tcpdump -n -i eth0 tcp port 443          # HTTPS on eth0 / HTTPS на eth0
sudo tcpdump -A -s0 -i any host <IP>          # Full packets host filter / Полные пакеты фильтр хоста
sudo tcpdump 'tcp[tcpflags] & (tcp-syn) != 0' # SYN packets / SYN пакеты
sudo tcpdump 'tcp[tcpflags] & (tcp-rst) != 0' # RST packets / RST пакеты
sudo tcpdump -c 100                           # Capture 100 packets / Захватить 100 пакетов
sudo tcpdump -nn -vv -c 50 port 53            # DNS queries verbose / DNS запросы подробно
```

### Combine Filters / Комбинирование фильтров
```bash
sudo tcpdump 'host <IP> and port 80'          # Host and port / Хост и порт
sudo tcpdump 'src <IP> and dst port 443'      # Source IP and dest port / IP источника и порт назначения
sudo tcpdump 'tcp and not port 22'            # TCP except SSH / TCP кроме SSH
sudo tcpdump '(tcp port 80 or tcp port 443) and host <IP>'  # HTTP/HTTPS to host / HTTP/HTTPS к хосту
```

> [!TIP]
> Use `-w` to save captures for later analysis in Wireshark, and `-c` to limit capture count to avoid filling disk in high-traffic environments.
> / Используйте `-w` для сохранения захвата для последующего анализа в Wireshark и `-c` для ограничения количества, чтобы не заполнять диск при большом трафике.

---

## lsof — List Open Files

### Description / Описание

`lsof` (List Open Files) reports all open files in the system — regular files, directories, sockets, pipes, and devices. In Linux "everything is a file," so `lsof` is invaluable for debugging file locks, hung mount points, and network connections.

### Installation / Установка
```bash
sudo apt install lsof                         # Debian/Ubuntu
sudo dnf install lsof                         # RHEL/Fedora
sudo pacman -S lsof                           # Arch
```

### Basic Usage / Базовое использование
```bash
lsof                                          # List all open files / Список всех открытых файлов
lsof -u <USER>                                # Files opened by user / Файлы открытые пользователем
lsof -p <PID>                                 # Files opened by process / Файлы открытые процессом
lsof <FILE>                                   # Processes using file / Процессы использующие файл
```

### Network Connections / Сетевые соединения
```bash
lsof -i                                       # All network connections / Все сетевые соединения
lsof -i :80                                   # Port 80 connections / Соединения порта 80
lsof -i tcp                                   # TCP connections / TCP соединения
lsof -i udp                                   # UDP connections / UDP соединения
lsof -i tcp:22                                # SSH connections / SSH соединения
lsof -i @<IP>                                 # Connections to IP / Соединения к IP
```

### Process Information / Информация о процессах
```bash
lsof -c nginx                                 # Files by command / Файлы по команде
lsof -t -c nginx                              # PIDs only / Только PID
lsof -a -u <USER> -i                          # User network files / Сетевые файлы пользователя
lsof -a -p <PID> -i                           # Process network files / Сетевые файлы процесса
```

### Filesystem / Файловая система
```bash
lsof +D /path/to/dir                          # All files in directory / Все файлы в директории
lsof +d /path/to/dir                          # Files in directory (no recurse) / Файлы в директории (без рекурсии)
lsof /mnt                                     # What's using mount / Что использует монтирование
```

> [!TIP]
> `lsof +D` recursively scans the directory tree — on large filesystems this can be very slow. Use `lsof +d` (lowercase, non-recursive) when possible.
> / `lsof +D` рекурсивно сканирует дерево каталогов — на больших ФС это может быть очень медленно. По возможности используйте `lsof +d` (без рекурсии).

### Common Patterns / Распространённые шаблоны
```bash
lsof -i :80 | grep LISTEN                     # Who's listening on 80 / Кто слушает порт 80
lsof -nP -iTCP -sTCP:LISTEN                   # All listening TCP / Все слушающие TCP
lsof -nP -i4TCP -sTCP:ESTABLISHED             # Established IPv4 TCP / Установленные IPv4 TCP
lsof -u ^root                                 # Not root / Не root
lsof -i -u <USER>                             # User network activity / Сетевая активность пользователя
```

---

## ltrace — Library Call Tracing

### Description / Описание

`ltrace` traces calls to shared library functions (e.g., `malloc`, `free`, `printf`) as well as signals received. It uses the same `ptrace()` mechanism as `strace`, so performance impact is similarly **HIGH**. Useful for analyzing memory allocation patterns and debugging library-level issues.

### Installation / Установка
```bash
sudo apt install ltrace                       # Debian/Ubuntu
sudo dnf install ltrace                       # RHEL/Fedora
sudo pacman -S ltrace                         # Arch
```

### Basic Usage / Базовое использование
```bash
ltrace <COMMAND>                              # Trace library calls / Трассировать библиотечные вызовы
ltrace -p <PID>                               # Attach to process / Подключиться к процессу
ltrace -c <COMMAND>                           # Count calls / Подсчитать вызовы
ltrace -o trace.txt <COMMAND>                 # Save to file / Сохранить в файл
ltrace -e malloc,free <COMMAND>               # Trace specific calls / Трассировать конкретные вызовы
ltrace -f <COMMAND>                           # Follow forks / Следовать за fork
```

> [!NOTE]
> `ltrace` may not work on modern binaries compiled with `-z now` (full RELRO). In such cases, consider using `LD_PRELOAD` wrappers or `bpftrace` uprobe-based tracing.
> / `ltrace` может не работать с бинарниками, скомпилированными с `-z now` (полный RELRO). В таких случаях используйте `LD_PRELOAD`-обёртки или трассировку через `bpftrace` uprobe.

---

## Tool Comparison

### Performance Impact / Влияние на производительность

> [!WARNING]
> Tracing tools have significant performance impact on the traced process. Use with care in production.
> / Инструменты трассировки значительно влияют на производительность процесса. Используйте осторожно в продакшене.

| Tool | Mechanism (EN / RU) | Impact | Overhead | Production-Safe |
|------|---------------------|--------|----------|-----------------|
| **strace** | ptrace / каждый syscall | 🔴 HIGH / Высокое | 2–100× slowdown | ⚠️ No |
| **perf** | HW counters, sampling / аппаратные счётчики | 🟢 LOW / Низкое | 1–5% | ✅ Yes |
| **tcpdump** | libpcap / kernel filter | 🟡 MEDIUM / Среднее | Depends on traffic / Зависит от трафика | ⚠️ Careful |
| **lsof** | `/proc` scan / сканирование /proc | 🟢 MINIMAL / Минимальное | Point-in-time snapshot / Снимок | ✅ Yes |
| **ltrace** | ptrace / каждый lib call | 🔴 HIGH / Высокое | 2–100× slowdown | ⚠️ No |

### Layer Comparison / Сравнение уровней

| Layer / Уровень | Tool / Инструмент | What it shows (EN / RU) |
|-----------------|-------------------|-------------------------|
| **Kernel syscalls** | `strace` | System call parameters and results / Параметры и результаты системных вызовов |
| **CPU/HW events** | `perf` | Instruction counts, cache misses, branches / Инструкции, промахи кэша, ветвления |
| **Network packets** | `tcpdump` | Raw packet headers and payloads / Заголовки и данные сетевых пакетов |
| **File descriptors** | `lsof` | Open files, sockets, pipes per process / Открытые файлы, сокеты, каналы |
| **Library calls** | `ltrace` | Dynamic library function calls / Вызовы функций динамических библиотек |

---

## Common strace Filters

| Filter | Description (EN / RU) |
|--------|----------------------|
| `-e trace=network` | Socket operations / Операции сокетов |
| `-e trace=file` | File operations (open, stat, chmod) / Файловые операции |
| `-e trace=process` | Fork/exec/wait/clone / Fork/exec/wait/clone |
| `-e trace=signal` | Signal handling (kill, sigaction) / Обработка сигналов |
| `-e trace=ipc` | IPC (SHM, semaphores, msg queues) / IPC (разделяемая память, семафоры, очереди сообщений) |
| `-e trace=memory` | Memory mapping (mmap, mprotect, brk) / Отображение памяти |
| `-e trace=desc` | File descriptor ops (read, write, close) / Операции с дескрипторами |

---

## Troubleshooting Workflows

### Runbook: Debug High CPU / Отладка высокой нагрузки CPU

1. Identify the offending process / Найти проблемный процесс:
```bash
top                                           # Find top CPU consumer / Найти потребителя CPU
htop                                          # Interactive view / Интерактивный просмотр
```

2. Profile CPU usage with perf / Профилировать CPU с perf:
```bash
sudo perf top -p <PID>                        # Live CPU hot functions / Горячие функции CPU
sudo perf record -g -p <PID> -- sleep 30      # Record call graph for 30s / Записать граф вызовов 30с
sudo perf report                              # View report / Просмотр отчёта
```

3. Trace syscalls if perf points to kernel time / Трассировать сисколы если perf показывает kernel time:
```bash
strace -c -p <PID>                            # Summary: which calls are slow / Сводка: какие вызовы медленные
strace -p <PID> -f -e trace=all               # Full trace / Полная трассировка
```

### Runbook: Debug Network Issues / Отладка сетевых проблем

1. Check connections / Проверить соединения:
```bash
lsof -i                                       # All open sockets / Все открытые сокеты
ss -tunap                                     # Socket statistics / Статистика сокетов
```

2. Capture packets / Захватить пакеты:
```bash
sudo tcpdump -i any -nn port <PORT>           # Capture traffic on port / Захват трафика на порту
sudo tcpdump -i any -A host <IP>              # ASCII payload from host / ASCII данные от хоста
```

3. Trace network syscalls / Трассировать сетевые системные вызовы:
```bash
strace -e trace=network -p <PID> -f           # Network syscalls / Сетевые системные вызовы
```

### Runbook: Debug File Access / Отладка доступа к файлам

1. Find open files / Найти открытые файлы:
```bash
lsof -p <PID>                                 # All files by process / Все файлы процесса
lsof /path/to/file                            # Who's using this file / Кто использует файл
```

2. Trace file operations / Трассировать файловые операции:
```bash
strace -e trace=file -p <PID>                 # File syscalls / Файловые системные вызовы
strace -e trace=open,read,write -p <PID>      # Open/read/write calls / Вызовы open/read/write
```

3. Find what's locking / Найти что блокирует:
```bash
lsof +D /path/to/dir                          # Files in directory tree / Файлы в дереве каталогов
fuser -v /path/to/file                        # Process using file / Процесс использующий файл
```

### Runbook: Unmountable Filesystem / Невозможно отмонтировать ФС

1. Find who holds the mount / Найти кто блокирует монтирование:
```bash
lsof +D /mnt/data                             # All files open under mount / Все файлы под точкой монтирования
fuser -vm /mnt/data                           # Processes using mount / Процессы использующие монтирование
```

> [!CAUTION]
> Using `fuser -k /mnt/data` will **kill all processes** accessing files on the mount. Verify the process list first!
> / Использование `fuser -k /mnt/data` **убьёт все процессы**, обращающиеся к файлам на точке монтирования. Сначала проверьте список процессов!

2. Kill and unmount / Завершить и отмонтировать:
```bash
fuser -k /mnt/data                            # Kill all processes / Завершить все процессы
umount /mnt/data                              # Unmount / Отмонтировать
```

---

## Real-World Examples

### Debug Slow Application / Отладка медленного приложения
```bash
# Trace duration of syscalls / Трассировать длительность системных вызовов
sudo strace -c -p <PID>
sudo strace -T -tt -p <PID> | grep -v '<0.000'

# Profile CPU / Профилировать CPU
sudo perf record -g -p <PID> -- sleep 30
sudo perf report --stdio | head -50
```

### Find Network Bottleneck / Найти сетевое узкое место
```bash
# Capture HTTP traffic / Захватить HTTP трафик
sudo tcpdump -i any -s0 -A 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' | grep -i "GET\|POST\|HTTP"

# Find slow DNS / Найти медленный DNS
sudo tcpdump -i any -nn port 53

# Monitor connections / Мониторить соединения
watch -n 1 'lsof -i :80 | wc -l'
```

### Debug Container / Отладка контейнера
```bash
# Find container PID / Найти PID контейнера
docker inspect -f '{{.State.Pid}}' <CONTAINER>

# Trace container / Трассировать контейнер
sudo strace -p <CONTAINER_PID> -f

# Network trace / Сетевая трассировка
sudo nsenter -t <CONTAINER_PID> -n tcpdump -i any
```

### Find Memory Leaks / Найти утечки памяти
```bash
# Trace memory allocations / Трассировать выделение памяти
ltrace -e malloc,free,realloc -p <PID>
ltrace -c -e malloc,free -p <PID>

# Track with valgrind / Отслеживать с valgrind
valgrind --leak-check=full <COMMAND>
```

### Debug SSL/TLS / Отладка SSL/TLS
```bash
# Capture TLS traffic / Захватить TLS трафик
sudo tcpdump -i any -nn -s0 -X 'tcp port 443'

# Trace SSL calls / Трассировать SSL вызовы
ltrace -e SSL_* -p <PID>

# Check TLS handshake timing / Проверить время TLS хендшейка
sudo tcpdump -nn -i any 'tcp port 443 and (tcp[tcpflags] & (tcp-syn) != 0)'
```

### Find Deleted But Still Open Files / Найти удалённые но открытые файлы
```bash
# Find deleted files still held open / Найти удалённые файлы
lsof | grep '(deleted)'

# Find specific process holding deleted files / Найти процесс с удалёнными файлами
lsof -p <PID> | grep '(deleted)'

# Recover space by restarting service / Освободить пространство перезапуском
systemctl restart <SERVICE_NAME>              # Restart service / Перезапустить сервис
```

> [!TIP]
> Deleted files still consume disk space until the file descriptor is closed. This is a common cause of "disk full but `du` shows free space."
> / Удалённые файлы продолжают занимать место до закрытия дескриптора. Это частая причина «диск полон, но `du` показывает свободное место».

---

## Best Practices

### General Tracing Rules / Общие правила трассировки
```bash
# 1. Always start with -c for quick overview / Начинайте с -c для быстрого обзора
strace -c -p <PID>                            # before full trace / перед полной трассировкой

# 2. Use perf for CPU profiling, NOT strace / Используйте perf для CPU, НЕ strace
sudo perf top -p <PID>                        # minimal overhead / минимальная нагрузка

# 3. Filter strace to reduce noise / Фильтруйте strace
strace -e trace=network -p <PID>              # only what you need / только то что нужно

# 4. Use -nn with tcpdump to avoid DNS delays / Используйте -nn с tcpdump
sudo tcpdump -nn -i any port <PORT>           # no DNS resolution / без DNS разрешения

# 5. Use lsof for quick connection overview / lsof для быстрого обзора
lsof -nP -iTCP -sTCP:LISTEN                   # all listeners / все слушатели

# 6. Always attach with -p to running process / Подключайтесь к процессу через -p
strace -p <PID> -f                            # not by running cmd / не запуском команды

# 7. Limit tcpdump capture count or size / Ограничивайте захват tcpdump
sudo tcpdump -c 1000 -W 5 -C 100 -w out.pcap # rotate 5 files × 100MB / ротация 5 файлов × 100МБ
```

### Decision: Which Tool to Use / Какой инструмент использовать
```bash
# App is slow but CPU is fine    → strace -c / Приложение медленное но CPU ОК → strace -c
# CPU is pegged at 100%          → perf top -p / CPU загружен на 100% → perf top -p
# Network timeouts               → tcpdump / Таймауты сети → tcpdump
# "Port already in use"          → lsof -i :<PORT> / «Порт уже используется» → lsof -i :<PORT>
# Memory leak suspected          → ltrace -e malloc,free / Подозрение на утечку → ltrace -e malloc,free
# Can't unmount filesystem       → lsof +D /mount/point / Невозможно отмонтировать → lsof +D /mount/point
```

---

## Documentation Links

- **strace:** https://strace.io/ | https://man7.org/linux/man-pages/man1/strace.1.html
- **perf:** https://perf.wiki.kernel.org/ | https://www.brendangregg.com/perf.html
- **tcpdump:** https://www.tcpdump.org/ | https://www.tcpdump.org/manpages/tcpdump.1.html
- **lsof:** https://github.com/lsof-org/lsof | https://man7.org/linux/man-pages/man8/lsof.8.html
- **ltrace:** https://man7.org/linux/man-pages/man1/ltrace.1.html
- **FlameGraph:** https://github.com/brendangregg/FlameGraph
- **Brendan Gregg's Perf Examples:** https://www.brendangregg.com/perf.html
