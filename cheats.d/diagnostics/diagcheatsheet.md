Title: 🔍 Diagnostics — strace/perf/tcpdump/lsof
Group: Diagnostics
Icon: 🔍
Order: 1

## Table of Contents
- [strace — System Call Tracing](#-strace--system-call-tracing)
- [perf — Performance Analysis](#-perf--performance-analysis)
- [tcpdump — Network Packet Capture](#-tcpdump--network-packet-capture)
- [lsof — List Open Files](#-lsof--list-open-files)
- [ltrace — Library Call Tracing](#-ltrace--library-call-tracing)
- [Troubleshooting Workflows](#-troubleshooting-workflows--рабочие-процессы)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔎 strace — System Call Tracing

### Basic Usage / Базовое использование
strace <COMMAND>                              # Trace command / Трассировать команду
strace ls -la                                 # Trace ls command / Трассировать команду ls
strace -p <PID>                               # Attach to running process / Подключиться к процессу
strace -p <PID> -f                            # Follow child processes / Следовать за дочерними процессами

### Output Options / Опции вывода
strace -o trace.txt <COMMAND>                 # Save to file / Сохранить в файл
strace -o trace.txt -f -tt -T -s 200 -p <PID> # Detailed trace / Детальная трассировка
# -f: follow forks / следовать за fork
# -tt: timestamps with microseconds / временные метки с микросекундами
# -T: show time spent in calls / показать время вызовов
# -s 200: string size limit / лимит размера строки

### Filter by Syscall / Фильтр по сисколам
strace -e trace=open,read,write <COMMAND>     # Trace specific calls / Трассировать конкретные вызовы
strace -e trace=network -p <PID>              # Network syscalls / Сетевые сисколы
strace -e trace=file -p <PID>                 # File operations / Файловые операции
strace -e trace=process -p <PID>              # Process operations / Операции процессов
strace -e trace=signal -p <PID>               # Signal handling / Обработка сигналов
strace -e trace=ipc -p <PID>                  # IPC operations / IPC операции

### Statistics / Статистика
strace -c <COMMAND>                           # Summary statistics / Сводная статистика
strace -c -p <PID>                            # Count syscalls / Подсчитать сисколы
strace -c -S time <COMMAND>                   # Sort by time / Сортировать по времени
strace -c -S calls <COMMAND>                  # Sort by call count / Сортировать по числу вызовов

### Advanced / Продвинутое
strace -e trace=open,openat -e signal=none <COMMAND>  # Open calls, no signals / Вызовы open, без сигналов
strace -y -p <PID>                            # Show file descriptor paths / Показать пути дескрипторов
strace -k -p <PID>                            # Show stack traces / Показать stack traces
strace -r <COMMAND>                           # Relative timestamps / Относительные метки времени

---

# 📊 perf — Performance Analysis

### Installation / Установка
sudo apt install linux-tools-common linux-tools-$(uname -r)  # Debian/Ubuntu
sudo dnf install perf                         # RHEL/Fedora

### Top CPU Consumers / Топ потребителей CPU
sudo perf top                                 # Live CPU hot spots / «Горячие точки» CPU
sudo perf top -p <PID>                        # Top for specific process / Top для конкретного процесса
sudo perf top -g                              # Call graph / Граф вызовов

### Record and Report / Запись и отчёт
sudo perf record -g -- <COMMAND>              # Record with call graph / Записать с графом вызовов
sudo perf record -g -p <PID>                  # Record process / Записать процесс
sudo perf record -g -a -- sleep 10            # Record all CPUs for 10s / Записать все CPU 10с
sudo perf report                              # View report / Просмотр отчёта
sudo perf report --stdio                      # Text report / Текстовый отчёт

### CPU Profiling / Профилирование CPU
sudo perf stat <COMMAND>                      # Performance statistics / Статистика производительности
sudo perf stat -p <PID>                       # Stats for process / Статистика для процесса
sudo perf stat -a -- sleep 5                  # System-wide for 5s / Для всей системы 5с
sudo perf stat -e cpu-cycles,instructions <COMMAND>  # Specific events / Конкретные события

### Flame Graphs / Flame графы
sudo perf record -F 99 -a -g -- sleep 30      # Record for 30s / Записать 30с
sudo perf script > out.perf                   # Export data / Экспортировать данные
# Generate flame graph with flamegraph.pl / Генерировать flame граф с flamegraph.pl
stackcollapse-perf.pl out.perf | flamegraph.pl > perf.svg

### List Available Events / Список доступных событий
perf list                                     # List all events / Список всех событий
perf list cache                               # Cache events / События кэша
perf list hw                                  # Hardware events / Аппаратные события
perf list sw                                  # Software events / Программные события

---

# 📡 tcpdump — Network Packet Capture

### Basic Capture / Базовый захват
sudo tcpdump                                  # Capture all interfaces / Захват всех интерфейсов
sudo tcpdump -i eth0                          # Capture specific interface / Захват конкретного интерфейса
sudo tcpdump -i any                           # Capture all interfaces / Захват всех интерфейсов
sudo tcpdump -n                               # No DNS resolution / Без DNS разрешения
sudo tcpdump -nn                              # No DNS/port resolution / Без DNS/портов

### Protocol Filters / Фильтры протоколов
sudo tcpdump tcp                              # TCP packets only / Только TCP пакеты
sudo tcpdump udp                              # UDP packets only / Только UDP пакеты
sudo tcpdump icmp                             # ICMP packets only / Только ICMP пакеты
sudo tcpdump arp                              # ARP packets only / Только ARP пакеты

### Port Filters / Фильтры портов
sudo tcpdump port 80                          # HTTP traffic / HTTP трафик
sudo tcpdump port 443                         # HTTPS traffic / HTTPS трафик
sudo tcpdump tcp port 22                      # SSH traffic / SSH трафик
sudo tcpdump 'tcp port 80 or tcp port 443'    # HTTP or HTTPS / HTTP или HTTPS
sudo tcpdump portrange 8000-9000              # Port range / Диапазон портов

### Host Filters / Фильтры хостов
sudo tcpdump host <IP>                        # Specific host / Конкретный хост
sudo tcpdump src <IP>                         # Source IP / IP источника
sudo tcpdump dst <IP>                         # Destination IP / IP назначения
sudo tcpdump net 192.168.1.0/24               # Network / Сеть

### Output Options / Опции вывода
sudo tcpdump -w capture.pcap                  # Write to file / Записать в файл
sudo tcpdump -r capture.pcap                  # Read from file / Читать из файла
sudo tcpdump -A                               # ASCII output / ASCII вывод
sudo tcpdump -X                               # Hex and ASCII / Hex и ASCII
sudo tcpdump -s 0                             # Capture full packets / Захват полных пакетов
sudo tcpdump -s0 -A -i any host <IP>          # Full packets ASCII / Полные пакеты ASCII

### Advanced Filters / Продвинутые фильтры
sudo tcpdump -n -i eth0 tcp port 443          # HTTPS on eth0 / HTTPS на eth0
sudo tcpdump -A -s0 -i any host 10.0.0.5      # Full packets host filter / Полные пакеты фильтр хоста
sudo tcpdump 'tcp[tcpflags] & (tcp-syn) != 0' # SYN packets / SYN пакеты
sudo tcpdump 'tcp[tcpflags] & (tcp-rst) != 0' # RST packets / RST пакеты
sudo tcpdump -c 100                           # Capture 100 packets / Захватить 100 пакетов
sudo tcpdump -nn -vv -c 50 port 53            # DNS queries verbose / DNS запросы подробно

### Combine Filters / Комбинирование фильтров
sudo tcpdump 'host <IP> and port 80'          # Host and port / Хост и порт
sudo tcpdump 'src <IP> and dst port 443'      # Source IP and dest port / IP источника и порт назначения
sudo tcpdump 'tcp and not port 22'            # TCP except SSH / TCP кроме SSH
sudo tcpdump '(tcp port 80 or tcp port 443) and host <IP>'  # HTTP/HTTPS to host / HTTP/HTTPS к хосту

---

# 📂 lsof — List Open Files

### Basic Usage / Базовое использование
lsof                                          # List all open files / Список всех открытых файлов
lsof -u <USER>                                # Files opened by user / Файлы открытые пользователем
lsof -p <PID>                                 # Files opened by process / Файлы открытые процессом
lsof <FILE>                                   # Processes using file / Процессы использующие файл

### Network Connections / Сетевые соединения
lsof -i                                       # All network connections / Все сетевые соединения
lsof -i :80                                   # Port 80 connections / Соединения порта 80
lsof -i tcp                                   # TCP connections / TCP соединения
lsof -i udp                                   # UDP connections / UDP соединения
lsof -i tcp:22                                # SSH connections / SSH соединения
lsof -i @<IP>                                 # Connections to IP / Соединения к IP

### Process Information / Информация о процессах
lsof -c nginx                                 # Files by command / Файлы по команде
lsof -t -c nginx                              # PIDs only / Только PID
lsof -a -u <USER> -i                          # User network files / Сетевые файлы пользователя
lsof -a -p <PID> -i                           # Process network files / Сетевые файлы процесса

### Filesystem / Файловая система
lsof +D /path/to/dir                          # All files in directory / Все файлы в директории
lsof +d /path/to/dir                          # Files in directory (no recurse) / Файлы в директории (без рекурсии)
lsof /mnt                                     # What's using mount / Что использует монтирование

### Common Patterns / Распространённые шаблоны
lsof -i :80 | grep LISTEN                     # Who's listening on 80 / Кто слушает порт 80
lsof -nP -iTCP -sTCP:LISTEN                   # All listening TCP / Все слушающие TCP
lsof -nP -i4TCP -sTCP:ESTABLISHED             # Established IPv4 TCP / Установленные IPv4 TCP
lsof -u ^root                                 # Not root / Не root
lsof -i -u <USER>                             # User network activity / Сетевая активность пользователя

---

# 🔬 ltrace — Library Call Tracing

ltrace <COMMAND>                              # Trace library calls / Трассировать библиотечные вызовы
ltrace -p <PID>                               # Attach to process / Подключиться к процессу
ltrace -c <COMMAND>                           # Count calls / Подсчитать вызовы
ltrace -o trace.txt <COMMAND>                 # Save to file / Сохранить в файл
ltrace -e malloc,free <COMMAND>               # Trace specific calls / Трассировать конкретные вызовы
ltrace -f <COMMAND>                           # Follow forks / Следовать за fork

---

# 🛠️ Troubleshooting Workflows / Рабочие процессы

### Debug High CPU / Отладка высокой нагрузки CPU
```bash
# 1. Find process / Найти процесс
top
htop

# 2. Profile with perf / Профилировать с perf
sudo perf top -p <PID>
sudo perf record -g -p <PID> -- sleep 30
sudo perf report

# 3. Trace syscalls / Трассировать сисколы
strace -c -p <PID>
strace -p <PID> -f -e trace=all
```

### Debug Network Issues / Отладка сетевых проблем
```bash
# 1. Check connections / Проверить соединения
lsof -i
ss -tunap

# 2. Capture packets / Захватить пакеты
sudo tcpdump -i any -nn port <PORT>
sudo tcpdump -i any -A host <IP>

# 3. Trace network syscalls / Трассировать сетевые сисколы
strace -e trace=network -p <PID> -f
```

### Debug File Access / Отладка доступа к файлам
```bash
# 1. Find open files / Найти открытые файлы
lsof -p <PID>
lsof /path/to/file

# 2. Trace file operations / Трассировать файловые операции
strace -e trace=file -p <PID>
strace -e trace=open,read,write -p <PID>

# 3. Find what's locking / Найти что блокирует
lsof +D /path/to/dir
```

---

# 🌟 Real-World Examples / Примеры из практики

### Debug Slow Application / Отладка медленного приложения
```bash
# Trace duration of syscalls / Трассировать длительность сисколов
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
```

# 💡 Best Practices / Лучшие практики
# Use -c for quick syscall overview / Используйте -c для быстрого обзора сисколов
# Filter strace output to reduce noise / Фильтруйте вывод strace для уменьшения шума
# Use perf for CPU profiling, not strace / Используйте perf для профилирования CPU, не strace
# tcpdump -nn to avoid DNS delays / tcpdump -nn для избежания задержек DNS
# lsof for quick connection overview / lsof для быстрого обзора соединений
# Always use -p to attach to running process / Всегда используйте -p для подключения к процессу

# 🔧 Performance Impact / Влияние на производительность
# strace: HIGH (2-100x slowdown) / Высокое (замедление в 2-100 раз)
# perf: LOW (1-5% overhead) / Низкое (нагрузка 1-5%)
# tcpdump: MEDIUM (depends on traffic) / Среднее (зависит от трафика)
# lsof: MINIMAL / Минимальное
# ltrace: HIGH (similar to strace) / Высокое (похоже на strace)

# 📋 Common strace Filters / Распространённые фильтры strace
# -e trace=network — Socket operations / Операции сокетов
# -e trace=file — File operations / Файловые операции
# -e trace=process — Fork/exec/wait / Fork/exec/wait
# -e trace=signal — Signal handling / Обработка сигналов
# -e trace=ipc — IPC (SHM, semaphores, msg queues) / IPC (разделяемая память, семафоры, очереди сообщений)
