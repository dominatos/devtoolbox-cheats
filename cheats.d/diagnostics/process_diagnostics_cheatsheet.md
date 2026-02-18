Title: 🕵️ Process Diagnostics — Process State/Resources/Network
Group: Diagnostics
Icon: 🕵️
Order: 2

## Table of Contents
- [Process Discovery & Identification](#process-discovery--identification)
- [Process State & Activity](#process-state--activity)
- [Resource Consumption (CPU, RAM, I/O)](#resource-consumption-cpu-ram-io)
- [Network & Ports Monitoring](#network--ports-monitoring)
- [Thread Analysis](#thread-analysis)
- [File Handles & Descriptors](#file-handles--descriptors)
- [System Integration & Logging](#system-integration--logging)
- [Topic: MySQL Monitoring (Case Study)](#topic-mysql-monitoring-case-study)
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

## Process State & Activity
### Monitor Process State / Мониторинг состояния процесса

```bash
ps -o pid,state,wchan,cmd -p <PID>               # View process state and wait channel / Просмотр состояния и канала ожидания
cat /proc/<PID>/status | grep State             # Detailed state from procfs / Подробное состояние из procfs
cat /proc/<PID>/wchan                           # Current wait channel (kernel function) / Текущий канал ожидания (функция ядра)
cat /proc/<PID>/stack                           # Kernel call stack (if D/S state) / Стек вызовов ядра (если в состоянии D/S)
```

> [!NOTE]
> **State Codes / Коды состояний:**
> - `R` (Running): Active on CPU / Активен на CPU.
> - `S` (Sleeping): Waiting for event / Ожидает события (прерываемый).
> - `D` (Uninterruptible Sleep): Waiting for I/O / Ожидает I/O (непрерываемый).
> - `Z` (Zombie): Finished but not reaped / Завершен, но не удален из таблицы.
> - `T` (Stopped): Suspended by signal / Приостановлен сигналом.

### Execution Context / Контекст выполнения
```bash
readlink /proc/<PID>/exe                        # Path to executable / Путь к исполняемому файлу
cat /proc/<PID>/cmdline | xargs -0              # Full launch command / Полная команда запуска
cat /proc/<PID>/environ | xargs -0 -n 1         # Environment variables / Переменные окружения
cat /proc/<PID>/limits                          # Resource limits (ulimit) / Лимиты ресурсов (ulimit)
```

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
| **htop** | `F6` | Open sort menu / Открыть меню сортировки |
| **htop** | `F4` | Filter by name / Фильтр по имени |
| **htop** | `H` | Toggle threads visibility / Вкл/выкл отображение потоков |

### I/O Usage / Использование ввода-вывода
```bash
iotop -p <PID>                                  # Live I/O monitoring / Мониторинг I/O в реальном времени
cat /proc/<PID>/io                              # I/O statistics counters / Счетчики статистики I/O
```

## Network & Ports Monitoring
### Listeners and Connections / Слушатели и соединения

```bash
ss -tunap | grep <PID>                          # Current sockets by PID / Текущие сокеты по PID
netstat -plntu | grep <PID>                     # Listening ports (classic) / Прослушиваемые порты (классика)
lsof -i -nP -p <PID>                            # Network files opened by process / Сетевые файлы, открытые процессом
```

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

## Thread Analysis
### Thread Count and Details / Количество и детали потоков

```bash
ps -o nlwp,pid,cmd -p <PID>                     # Show thread count (NLWP) / Показать количество потоков
ps -eLf | grep <PID>                            # List every thread separately / Список каждого потока отдельно
ls /proc/<PID>/task | wc -l                      # Count threads via procfs / Подсчет потоков через procfs
top -H -p <PID>                                 # Monitor individual threads / Мониторинг отдельных потоков
```

## File Handles & Descriptors
### Open Files Tracking / Отслеживание открытых файлов

```bash
lsof -p <PID>                                   # List all open files / Список всех открытых файлов
ls -l /proc/<PID>/fd                            # File descriptors count/paths / Пути и количество дескрипторов
fuser -v <PATH_TO_FILE>                         # Find process using a file / Найти процесс, использующий файл
```

## System Integration & Logging
### Service Control & Logs / Управление сервисом и логи

```bash
systemctl status <SERVICE_NAME>                 # Check systemd status / Проверить статус systemd
journalctl -u <SERVICE_NAME> -f                 # Follow service logs / Следить за логами сервиса
journalctl -u <SERVICE_NAME> --since "1 hour ago" # Logs for last hour / Логи за последний час
```



## Topic: MySQL Monitoring (Case Study)
### Targeting MySQL specifically / Специфический мониторинг MySQL

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
> MySQL uses a **One-Process-Many-Threads** model. Resource visibility often combines all threads into the main process. Use `top -H` or Performance Schema inside MySQL for granular internal thread info.

## Advanced Tracing & Debugging
### Low-Level Activity / Низкоуровневая активность

```bash
strace -p <PID> -f -e trace=network,file        # Trace syscalls / Трассировка системных вызовов
perf top -p <PID>                               # CPU profiling / Профилирование CPU
gdb -p <PID>                                    # Attach debugger (EXPERT ONLY) / Подключить отладчик (ТОЛЬКО ЭКСПЕРТЫ)
```

> [!WARNING]
> Attaching `strace` or `gdb` to a high-load production process can cause significant performance degradation or temporarily "freeze" the app.
> / Подключение `strace` или `gdb` к высоконагруженному процессу может вызвать серьезное замедление или временную «заморозку» приложения.

## Comparison Tables & Senior Tips
### Comparison: Process Memory Metrics / Сравнение: Метрики памяти процессов

| Metric / Метрика | Name (EN/RU) | Description (EN / RU) | Use Case / Когда смотреть |
| :--- | :--- | :--- | :--- |
| **VIRT** | Virtual Image / Виртуальная | Total address space shared + mapped / Весь адресный объем | General limits / Общие лимиты |
| **RSS** | Resident Set / Резидентная | Non-swapped physical RAM / Физическая ОЗУ без swap | Actual usage / Реальное потребление |
| **SHR** | Shared Memory / Разделяемая | Memory shared with other processes / Память, общая с другими | Library impact / Влияние библиотек |
| **SWAP** | Swap Size / Своп | Memory moved to disk / Выгруженная на диск память | Memory pressure / Дефицит памяти |

### Senior Tips
- **Soft vs Hard Limits:** Soft limits (`ulimit -Sn`) can be changed by the user; Hard limits (`ulimit -Hn`) are the absolute ceiling set by root.
- **Zombie Processes:** A zombie process doesn't consume CPU/RAM but takes a slot in the process table. Cleaning them requires the parent to `wait()` or killing the parent.
- **D-State (Uninterruptible):** Usually means wait for Hardware I/O (Disk/NFS). The process cannot be killed by `SIGKILL` until I/O returns.
