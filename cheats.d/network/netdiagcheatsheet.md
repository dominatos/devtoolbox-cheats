Title: 🛰️ Network Diagnostics — mtr/traceroute/iperf3/ping
Group: Network
Icon: 🛰️
Order: 11

# Network Diagnostics — ping / traceroute / mtr / iperf3

A collection of essential network diagnostic tools for connectivity testing, path tracing, and bandwidth measurement. `ping` tests basic reachability, `traceroute` maps the path packets take, `mtr` combines both with continuous monitoring, and `iperf3` measures actual throughput between two endpoints.

📚 **Official Docs / Официальная документация:** [mtr(8)](https://www.bitwizard.nl/mtr/) · [iperf3](https://iperf.fr/)

## Table of Contents
- [ping — Basic Connectivity](#-ping--basic-connectivity)
- [traceroute — Path Tracing](#-traceroute--path-tracing)
- [mtr — Combined Trace](#-mtr--combined-trace)
- [iperf3 — Bandwidth Testing](#-iperf3--bandwidth-testing)
- [netcat — Network Swiss Army](#-netcat--network-swiss-army)  
- [ss — Socket Statistics](#-ss--socket-statistics)
- [Troubleshooting Workflows](#-troubleshooting-workflows--рабочие-процессы)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

## 🏓 ping — Basic Connectivity

### Basic Usage / Базовое использование
```bash
ping <HOST>                                   # Ping host / Пинговать хост
ping 8.8.8.8                                  # Ping Google DNS / Пинговать Google DNS
ping google.com                               # Ping by hostname / Пинговать по имени хоста
ping -c 5 <HOST>                              # Send 5 packets / Отправить 5 пакетов
ping -c 10 -i 0.5 <HOST>                      # 10 packets, 0.5s interval / 10 пакетов, интервал 0.5с
```

### Advanced Options / Продвинутые опции
```bash
ping -4 <HOST>                                # Force IPv4 / Принудительно IPv4
ping -6 <HOST>                                # Force IPv6 / Принудительно IPv6
ping -s 1000 <HOST>                           # Packet size 1000 bytes / Размер пакета 1000 байт
ping -f <HOST>                                # Flood ping (root) / Флуд пинг (root)
ping -W 2 <HOST>                              # Timeout 2 seconds / Таймаут 2 секунды
ping -q -c 10 <HOST>                          # Quiet (summary only) / Тихий (только итог)
```

### Continuous & Timestamps / Непрерывный и временные метки
```bash
ping <HOST> | ts                              # Add timestamps / Добавить временные метки
ping <HOST> | while read line; do echo "$(date): $line"; done  # Manual timestamps / Ручные временные метки
```

---

## 🗺️ traceroute — Path Tracing

### Basic Usage / Базовое использование
```bash
traceroute <HOST>                             # Trace route / Трассировать маршрут
traceroute 8.8.8.8                            # Trace to Google DNS / Трассировка к Google DNS
traceroute -n <HOST>                          # No DNS resolution / Без DNS разрешения
traceroute -m 20 <HOST>                       # Max 20 hops / Максимум 20 переходов
traceroute -q 3 <HOST>                        # 3 queries per hop / 3 запроса на переход
```

### Protocol Options / Опции протокола
```bash
traceroute -I <HOST>                          # ICMP Echo / ICMP Echo
traceroute -T <HOST>                          # TCP SYN / TCP SYN
traceroute -U <HOST>                          # UDP (default) / UDP (по умолчанию)
traceroute -T -p 80 <HOST>                    # TCP to port 80 / TCP на порт 80
```

### IPv6 / IPv6
```bash
traceroute6 <HOST>                            # IPv6 traceroute / IPv6 трассировка
traceroute -6 <HOST>                          # Alternative / Альтернатива
```

---

## 🎯 mtr — Combined Trace

### Basic Usage / Базовое использование
```bash
mtr <HOST>                                    # Interactive MTR / Интерактивный MTR
mtr -n <HOST>                                 # No DNS / Без DNS
mtr -4 <HOST>                                 # IPv4 only / Только IPv4
mtr -6 <HOST>                                 # IPv6 only / Только IPv6
```

### Report Mode / Режим отчёта
```bash
mtr -r <HOST>                                 # Report mode / Режим отчёта
mtr -rw <HOST>                                # Wide report / Широкий отчёт
mtr -rwc 100 <HOST>                           # 100 cycles report / Отчёт 100 циклов
mtr -r -c 50 <HOST>                           # 50 cycles / 50 циклов
```

### Advanced Options / Продвинутые опции
```bash
mtr -b <HOST>                                 # Show both host and IP / Показать и хост и IP
mtr -z <HOST>                                 # Show AS numbers / Показать номера AS
mtr -o "LSDR ABWV" <HOST>                     # Custom column order / Пользовательский порядок колонок
mtr -i 0.5 <HOST>                             # 0.5s interval / Интервал 0.5с
```

### Protocol Selection / Выбор протокола
```bash
mtr -u <HOST>                                 # UDP mode / Режим UDP
mtr -T <HOST>                                 # TCP mode / Режим TCP
mtr -T -P 443 <HOST>                          # TCP port 443 / TCP порт 443
```

### Output Formats / Форматы вывода
```bash
mtr --json <HOST>                             # JSON output / Вывод JSON
mtr --csv <HOST>                              # CSV output / Вывод CSV
mtr --xml <HOST>                              # XML output / Вывод XML
```

---

## 📊 iperf3 — Bandwidth Testing

### Installation / Установка
```bash
sudo apt install iperf3                       # Debian/Ubuntu
sudo dnf install iperf3                       # RHEL/Fedora
```

### Server Mode / Режим сервера
```bash
iperf3 -s                                     # Start server / Запустить сервер
iperf3 -s -p 5201                             # Server on port 5201 / Сервер на порту 5201
iperf3 -s -D                                  # Daemon mode / Режим демона
iperf3 -s -1                                  # Single client mode / Режим одного клиента
```

### Client Mode / Режим клиента
```bash
iperf3 -c <SERVER_IP>                         # Test to server / Тест к серверу
iperf3 -c <SERVER_IP> -t 30                   # 30 second test / 30 секунд тест
iperf3 -c <SERVER_IP> -P 10                   # 10 parallel streams / 10 параллельных потоков
iperf3 -c <SERVER_IP> -n 1G                   # Transfer 1GB / Передать 1GB
```

### Reverse & Bidirectional / Обратное и двунаправленное
```bash
iperf3 -c <SERVER_IP> -R                      # Reverse (download) / Обратное (скачивание)
iperf3 -c <SERVER_IP> --bidir                 # Bidirectional / Двунаправленное
```

### UDP Testing / UDP тестирование
```bash
iperf3 -c <SERVER_IP> -u                      # UDP mode / Режим UDP
iperf3 -c <SERVER_IP> -u -b 100M              # UDP 100Mbps / UDP 100Мбит/с
iperf3 -c <SERVER_IP> -u -b 0                 # UDP unlimited / UDP без ограничений
```

### Output & Reports / Вывод и отчёты
```bash
iperf3 -c <SERVER_IP> -i 1                    # 1s interval reports / Отчёты каждую секунду
iperf3 -c <SERVER_IP> -J                      # JSON output / Вывод JSON
iperf3 -c <SERVER_IP> --logfile test.log      # Log to file / Логировать в файл
```

---

## 🔌 netcat — Network Swiss Army

### Port Scanning / Сканирование портов
```bash
nc -zv <HOST> 80                              # Test port 80 / Проверить порт 80
nc -zv <HOST> 20-100                          # Scan ports 20-100 / Сканировать порты 20-100
nc -zv -w 1 <HOST> 22                         # 1s timeout / Таймаут 1с
```

### Listen Mode / Режим прослушивания
```bash
nc -l 8080                                    # Listen on port 8080 / Слушать порт 8080
nc -l -p 9999                                 # Listen on port 9999 / Слушать порт 9999
nc -l 8080 > received.file                    # Receive file / Получить файл
```

### Connect & Transfer / Подключение и передача
```bash
nc <HOST> 80                                  # Connect to port 80 / Подключиться к порту 80
nc <HOST> 9999 < file.txt                     # Send file / Отправить файл
cat file.txt | nc <HOST> 9999                 # Alternative / Альтернатива
```

### Chat / Чат
```bash
nc -l 8080                                    # Server / Сервер
nc <HOST> 8080                                # Client / Клиент
```

### Test Port / Проверить порт
```bash
echo "test" | nc -w 1 <HOST> 80               # Test with timeout / Проверить с таймаутом
```

---

## 📡 ss — Socket Statistics

### Basic Usage / Базовое использование
```bash
ss                                            # Show all sockets / Показать все сокеты
ss -t                                         # TCP sockets / TCP сокеты
ss -u                                         # UDP sockets / UDP сокеты
ss -l                                         # Listening sockets / Слушающие сокеты
ss -a                                         # All sockets / Все сокеты
```

### Common Combinations / Распространённые комбинации
```bash
ss -tunap                                     # TCP+UDP, numeric, all, processes / TCP+UDP, числовые, все, процессы
ss -tulpn                                     # TCP+UDP, listening, processes, numeric / TCP+UDP, слушающие, процессы, числовые
ss -s                                         # Summary statistics / Сводная статистика
```

### Filter by State / Фильтр по состоянию
```bash
ss state established                          # Established connections / Установленные соединения
ss state listening                            # Listening sockets / Слушающие сокеты
ss state time-wait                            # Time-wait sockets / Сокеты в состоянии time-wait
```

### Filter by Port / Фильтр по порту
```bash
ss -tunap | grep :80                          # Port 80 connections / Соединения порта 80
ss sport = :22                                # Source port 22 / Исходный порт 22
ss dport = :443                               # Destination port 443 / Порт назначения 443
```

### Show Processes / Показать процессы
```bash
ss -tp                                        # Show process info / Показать информацию о процессах
ss -tlnp                                      # Listening with processes / Слушающие с процессами
```

---

## 🛠️ Troubleshooting Workflows / Рабочие процессы

### Check Network Connectivity / Проверка сетевого подключения
```bash
# 1. Basic connectivity / Базовое подключение
ping -c 4 8.8.8.8

# 2. DNS resolution / DNS разрешение
ping -c 4 google.com

# 3. Trace route / Трассировка маршрута
mtr -rw google.com

# 4. Check firewall / Проверить фаервол
sudo ufw status
```

### Diagnose Slow Connection / Диагностика медленного соединения
```bash
# 1. MTR report / Отчёт MTR
mtr -rwc 100 <HOST>

# 2. Check for packet loss / Проверить потерю пакетов
ping -c 100 <HOST> | grep loss

# 3. Test bandwidth / Тест пропускной способности
iperf3 -c <SERVER_IP> -R

# 4. Check local network / Проверить локальную сеть
ping -c 10 <GATEWAY>
```

### Test Port Connectivity / Проверка подключения к порту
```bash
# 1. Quick port check / Быстрая проверка порта
nc -zv <HOST> <PORT>

# 2. Check if port is listening / Проверить слушает ли порт
ss -tunlp | grep :<PORT>

# 3. Test with telnet / Проверить с telnet
telnet <HOST> <PORT>

# 4. Check firewall rules / Проверить правила фаервола
sudo iptables -L -n | grep <PORT>
```

### Find Network Bottleneck / Найти сетевое узкое место
```bash
# 1. Trace with MTR / Трассировка с MTR
mtr -rwc 200 <HOST>

# 2. Test multiple paths / Проверить несколько путей
mtr -rwc 50 <HOST1>
mtr -rwc 50 <HOST2>

# 3. Bandwidth test / Тест пропускной способности
iperf3 -c <SERVER_IP> -P 10

# 4. Check interface stats / Проверить статистику интерфейса
ip -s link show eth0
```

---

## 🌟 Real-World Examples / Примеры из практики

### Monitor Connection Quality / Мониторинг качества соединения
```bash
# Continuous MTR with timestamps / Непрерывный MTR с временными метками
while true; do
  echo "=== $(date) ==="
  mtr -rwc 10 <HOST>
  sleep 60
done | tee connection-monitor.log
```

### Bandwidth Benchmark / Бенчмарк пропускной способности
```bash
# Server side / Серверная сторона
iperf3 -s

# Client side tests / Тесты клиентской стороны
echo "Upload test:"
iperf3 -c <SERVER_IP> -t 30

echo "Download test:"
iperf3 -c <SERVER_IP> -t 30 -R

echo "Bidirectional test:"
iperf3 -c <SERVER_IP> -t 30 --bidir
```

### Network Path Analysis / Анализ сетевого пути
```bash
# Compare paths to multiple hosts / Сравнить пути к нескольким хостам
for host in google.com cloudflare.com aws.com; do
  echo "=== $host ==="
  mtr -rwc 10 $host
  echo
done > network-paths.txt
```

### Port Connectivity Matrix / Матрица подключений портов
```bash
# Check multiple ports / Проверить несколько портов
for port in 22 80 443 3306 5432; do
  echo -n "Port $port: "
  nc -zv -w 1 <HOST> $port 2>&1 | grep -q succeeded && echo "OPEN" || echo "CLOSED"
done
```

### Automated Connectivity Check / Автоматическая проверка подключения
```bash
# Monitor connectivity and alert / Мониторить подключение и оповещать
ping -c 1 <HOST> > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Host <HOST> is DOWN at $(date)" | tee -a downtime.log
  # Send alert / Отправить оповещение
  echo "Host <HOST> is DOWN" | mail -s "Alert" <EMAIL>
fi
```

### Performance Baseline / Базовая производительность
```bash
# Establish baseline / Установить базовую линию
echo "Latency baseline:"
ping -c 100 <HOST> | tail -1

echo "Bandwidth baseline:"
iperf3 -c <SERVER_IP> -t 60 -J > baseline.json

echo "Path baseline:"
mtr -rwc 200 <HOST> > path-baseline.txt
```

### Multi-Server Latency / Задержка к нескольким серверам
```bash
# Check latency to multiple servers / Проверить задержку к нескольким серверам
for server in server1 server2 server3; do
  echo "$server:"
  ping -c 10 $server | grep rtt
done
```

### Network Troubleshooting Script / Скрипт устранения сетевых неполадок
```bash
#!/bin/bash
HOST=$1

echo "=== Network Diagnostic for $HOST ==="
echo
echo "1. Ping test:"
ping -c 5 $HOST

echo
echo "2. Traceroute:"
traceroute -n $HOST

echo
echo "3. MTR Report:"
mtr -rwc 20 $HOST

echo
echo "4. DNS Resolution:"
dig +short $HOST

echo
echo "5. Port 80 test:"
nc -zv -w 2 $HOST 80

echo
echo "6. Port 443 test:"
nc -zv -w 2 $HOST 443
```

## 💡 Best Practices / Лучшие практики
# Use mtr instead of ping+traceroute / Используйте mtr вместо ping+traceroute
# Always use -n to avoid DNS delays / Всегда используйте -n для избежания задержек DNS
# Run iperf3 tests bidirectionally / Запускайте iperf3 тесты в обоих направлениях
# Use -c for count-limited ping / Используйте -c для ping с ограничением счётчика
# Log long-term connectivity tests / Логируйте долгосрочные тесты подключения

## 🔧 Default Ports / Порты по умолчанию
```bash
# iperf3: 5201
# netcat: user-specified / задаётся пользователем
```

## 📋 Common Use Cases / Распространённые случаи использования
```bash
# ping: Basic connectivity / Базовое подключение
# traceroute: Path discovery / Обнаружение пути
# mtr: Continuous monitoring / Непрерывный мониторинг
# iperf3: Bandwidth testing / Тест пропускной способности
# netcat: Port testing / Тест портов
# ss: Active connections / Активные соединения
```

## 🔍 Alternative Tools / Альтернативные инструменты
```bash
# fping: Parallel ping / Параллельный ping
# hping3: Advanced packet crafting / Продвинутое создание пакетов
# nmap: Port scanning / Сканирование портов
# iftop: Real-time bandwidth / Пропускная способность в реальном времени
# nethogs: Per-process bandwidth / Пропускная способность по процессам
```
