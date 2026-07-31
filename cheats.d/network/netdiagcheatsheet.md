---
Title: 🛰️ Network Diagnostics — mtr/traceroute/iperf3/ping
Group: Network
Icon: 🛰️
Order: 11
tags:
  - network
  - sysadmin
  - linux
---

# Network Diagnostics — ping / traceroute / mtr / iperf3

A collection of essential network diagnostic tools for connectivity testing, path tracing, and bandwidth measurement. `ping` tests basic reachability, `traceroute` maps the path packets take, `mtr` combines both with continuous monitoring, and `iperf3` measures actual throughput between two endpoints.

📚 **Official Docs / Официальная документация:** [mtr(8)](https://www.bitwizard.nl/mtr/) · [iperf3](https://iperf.fr/)

## Table of Contents

- [🏓 ping — Basic Connectivity](#🏓%20ping%20—%20Basic%20Connectivity)
- [🗺️ traceroute — Path Tracing](#🗺️%20traceroute%20—%20Path%20Tracing)
- [🎯 mtr — Combined Trace](#🎯%20mtr%20—%20Combined%20Trace)
- [📊 iperf3 — Bandwidth Testing](#📊%20iperf3%20—%20Bandwidth%20Testing)
- [🔌 netcat — Network Swiss Army](#🔌%20netcat%20—%20Network%20Swiss%20Army)
- [📡 ss — Socket Statistics](#📡%20ss%20—%20Socket%20Statistics)
- [🛠️ Troubleshooting Workflows](#🛠️%20Troubleshooting%20Workflows)
- [🌟 Real-World Examples](#🌟%20Real-World%20Examples)
- [💡 Best Practices](#💡%20Best%20Practices)
- [🔧 Default Ports](#🔧%20Default%20Ports)
- [📋 Common Use Cases](#📋%20Common%20Use%20Cases)
- [🔍 Alternative Tools](#🔍%20Alternative%20Tools)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

## 🏓 ping — Basic Connectivity

### Basic Usage
```bash
ping <HOST>                                   # Ping host / Пинговать хост
ping 8.8.8.8                                  # Ping Google DNS / Пинговать Google DNS
ping google.com                               # Ping by hostname / Пинговать по имени хоста
ping -c 5 <HOST>                              # Send 5 packets / Отправить 5 пакетов
ping -c 10 -i 0.5 <HOST>                      # 10 packets, 0.5s interval / 10 пакетов, интервал 0.5с
```

### Advanced Options
```bash
ping -4 <HOST>                                # Force IPv4 / Принудительно IPv4
ping -6 <HOST>                                # Force IPv6 / Принудительно IPv6
ping -s 1000 <HOST>                           # Packet size 1000 bytes / Размер пакета 1000 байт
ping -f <HOST>                                # Flood ping (root) / Флуд пинг (root)
ping -W 2 <HOST>                              # Timeout 2 seconds / Таймаут 2 секунды
ping -q -c 10 <HOST>                          # Quiet (summary only) / Тихий (только итог)
```

### Continuous & Timestamps
```bash
ping <HOST> | ts                              # Add timestamps / Добавить временные метки
ping <HOST> | while read line; do echo "$(date): $line"; done  # Manual timestamps / Ручные временные метки
```

---

## 🗺️ traceroute — Path Tracing

### Basic Usage
```bash
traceroute <HOST>                             # Trace route / Трассировать маршрут
traceroute 8.8.8.8                            # Trace to Google DNS / Трассировка к Google DNS
traceroute -n <HOST>                          # No DNS resolution / Без DNS разрешения
traceroute -m 20 <HOST>                       # Max 20 hops / Максимум 20 переходов
traceroute -q 3 <HOST>                        # 3 queries per hop / 3 запроса на переход
```

### Protocol Options
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

### Basic Usage
```bash
mtr <HOST>                                    # Interactive MTR / Интерактивный MTR
mtr -n <HOST>                                 # No DNS / Без DNS
mtr -4 <HOST>                                 # IPv4 only / Только IPv4
mtr -6 <HOST>                                 # IPv6 only / Только IPv6
```

### Report Mode
```bash
mtr -r <HOST>                                 # Report mode / Режим отчёта
mtr -rw <HOST>                                # Wide report / Широкий отчёт
mtr -rwc 100 <HOST>                           # 100 cycles report / Отчёт 100 циклов
mtr -r -c 50 <HOST>                           # 50 cycles / 50 циклов
```

### Advanced Options
```bash
mtr -b <HOST>                                 # Show both host and IP / Показать и хост и IP
mtr -z <HOST>                                 # Show AS numbers / Показать номера AS
mtr -o "LSDR ABWV" <HOST>                     # Custom column order / Пользовательский порядок колонок
mtr -i 0.5 <HOST>                             # 0.5s interval / Интервал 0.5с
```

### Protocol Selection
```bash
mtr -u <HOST>                                 # UDP mode / Режим UDP
mtr -T <HOST>                                 # TCP mode / Режим TCP
mtr -T -P 443 <HOST>                          # TCP port 443 / TCP порт 443
```

### Output Formats
```bash
mtr --json <HOST>                             # JSON output / Вывод JSON
mtr --csv <HOST>                              # CSV output / Вывод CSV
mtr --xml <HOST>                              # XML output / Вывод XML
```

---

## 📊 iperf3 — Bandwidth Testing

### Installation
```bash
sudo apt install iperf3                       # Debian/Ubuntu
sudo dnf install iperf3                       # RHEL/Fedora
```

### Server Mode
```bash
iperf3 -s                                     # Start server / Запустить сервер
iperf3 -s -p 5201                             # Server on port 5201 / Сервер на порту 5201
iperf3 -s -D                                  # Daemon mode / Режим демона
iperf3 -s -1                                  # Single client mode / Режим одного клиента
```

### Client Mode
```bash
iperf3 -c <SERVER_IP>                         # Test to server / Тест к серверу
iperf3 -c <SERVER_IP> -t 30                   # 30 second test / 30 секунд тест
iperf3 -c <SERVER_IP> -P 10                   # 10 parallel streams / 10 параллельных потоков
iperf3 -c <SERVER_IP> -n 1G                   # Transfer 1GB / Передать 1GB
```

### Reverse & Bidirectional
```bash
iperf3 -c <SERVER_IP> -R                      # Reverse (download) / Обратное (скачивание)
iperf3 -c <SERVER_IP> --bidir                 # Bidirectional / Двунаправленное
```

### UDP Testing / UDP
```bash
iperf3 -c <SERVER_IP> -u                      # UDP mode / Режим UDP
iperf3 -c <SERVER_IP> -u -b 100M              # UDP 100Mbps / UDP 100Мбит/с
iperf3 -c <SERVER_IP> -u -b 0                 # UDP unlimited / UDP без ограничений
```

### Output & Reports
```bash
iperf3 -c <SERVER_IP> -i 1                    # 1s interval reports / Отчёты каждую секунду
iperf3 -c <SERVER_IP> -J                      # JSON output / Вывод JSON
iperf3 -c <SERVER_IP> --logfile test.log      # Log to file / Логировать в файл
```

---

## 🔌 netcat — Network Swiss Army

### Port Scanning
```bash
nc -zv <HOST> 80                              # Test port 80 / Проверить порт 80
nc -zv <HOST> 20-100                          # Scan ports 20-100 / Сканировать порты 20-100
nc -zv -w 1 <HOST> 22                         # 1s timeout / Таймаут 1с
```

### Listen Mode
```bash
nc -l 8080                                    # Listen on port 8080 / Слушать порт 8080
nc -l -p 9999                                 # Listen on port 9999 / Слушать порт 9999
nc -l 8080 > received.file                    # Receive file / Получить файл
```

### Connect & Transfer
```bash
nc <HOST> 80                                  # Connect to port 80 / Подключиться к порту 80
nc <HOST> 9999 < file.txt                     # Send file / Отправить файл
cat file.txt | nc <HOST> 9999                 # Alternative / Альтернатива
```

### Chat
```bash
nc -l 8080                                    # Server / Сервер
nc <HOST> 8080                                # Client / Клиент
```

### Test Port
```bash
echo "test" | nc -w 1 <HOST> 80               # Test with timeout / Проверить с таймаутом
```

---

## 📡 ss — Socket Statistics

### Basic Usage
```bash
ss                                            # Show all sockets / Показать все сокеты
ss -t                                         # TCP sockets / TCP сокеты
ss -u                                         # UDP sockets / UDP сокеты
ss -l                                         # Listening sockets / Слушающие сокеты
ss -a                                         # All sockets / Все сокеты
```

### Common Combinations
```bash
ss -tunap                                     # TCP+UDP, numeric, all, processes / TCP+UDP, числовые, все, процессы
ss -tulpn                                     # TCP+UDP, listening, processes, numeric / TCP+UDP, слушающие, процессы, числовые
ss -s                                         # Summary statistics / Сводная статистика
```

### Filter by State
```bash
ss state established                          # Established connections / Установленные соединения
ss state listening                            # Listening sockets / Слушающие сокеты
ss state time-wait                            # Time-wait sockets / Сокеты в состоянии time-wait
```

### Filter by Port
```bash
ss -tunap | grep :80                          # Port 80 connections / Соединения порта 80
ss sport = :22                                # Source port 22 / Исходный порт 22
ss dport = :443                               # Destination port 443 / Порт назначения 443
```

### Show Processes
```bash
ss -tp                                        # Show process info / Показать информацию о процессах
ss -tlnp                                      # Listening with processes / Слушающие с процессами
```

---

## 🛠️ Troubleshooting Workflows

### Check Network Connectivity
```bash
# 1. Basic connectivity
ping -c 4 8.8.8.8

# 2. DNS resolution / DNS
ping -c 4 google.com

# 3. Trace route
mtr -rw google.com

# 4. Check firewall
sudo ufw status
```

### Diagnose Slow Connection
```bash
# 1. MTR report
mtr -rwc 100 <HOST>

# 2. Check for packet loss
ping -c 100 <HOST> | grep loss

# 3. Test bandwidth
iperf3 -c <SERVER_IP> -R

# 4. Check local network
ping -c 10 <GATEWAY>
```

### Test Port Connectivity
```bash
# 1. Quick port check
nc -zv <HOST> <PORT>

# 2. Check if port is listening
ss -tunlp | grep :<PORT>

# 3. Test with telnet
telnet <HOST> <PORT>

# 4. Check firewall rules
sudo iptables -L -n | grep <PORT>
```

### Find Network Bottleneck
```bash
# 1. Trace with MTR
mtr -rwc 200 <HOST>

# 2. Test multiple paths
mtr -rwc 50 <HOST1>
mtr -rwc 50 <HOST2>

# 3. Bandwidth test
iperf3 -c <SERVER_IP> -P 10

# 4. Check interface stats
ip -s link show eth0
```

---

## 🌟 Real-World Examples

### Monitor Connection Quality
```bash
# Continuous MTR with timestamps
while true; do
  echo "=== $(date) ==="
  mtr -rwc 10 <HOST>
  sleep 60
done | tee connection-monitor.log
```

### Bandwidth Benchmark
```bash
# Server side
iperf3 -s

# Client side tests
echo "Upload test:"
iperf3 -c <SERVER_IP> -t 30

echo "Download test:"
iperf3 -c <SERVER_IP> -t 30 -R

echo "Bidirectional test:"
iperf3 -c <SERVER_IP> -t 30 --bidir
```

### Network Path Analysis
```bash
# Compare paths to multiple hosts
for host in google.com cloudflare.com aws.com; do
  echo "=== $host ==="
  mtr -rwc 10 $host
  echo
done > network-paths.txt
```

### Port Connectivity Matrix
```bash
# Check multiple ports
for port in 22 80 443 3306 5432; do
  echo -n "Port $port: "
  nc -zv -w 1 <HOST> $port 2>&1 | grep -q succeeded && echo "OPEN" || echo "CLOSED"
done
```

### Automated Connectivity Check
```bash
# Monitor connectivity and alert
ping -c 1 <HOST> > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Host <HOST> is DOWN at $(date)" | tee -a downtime.log
  # Send alert / Отправить оповещение
  echo "Host <HOST> is DOWN" | mail -s "Alert" <EMAIL>
fi
```

### Performance Baseline
```bash
# Establish baseline
echo "Latency baseline:"
ping -c 100 <HOST> | tail -1

echo "Bandwidth baseline:"
iperf3 -c <SERVER_IP> -t 60 -J > baseline.json

echo "Path baseline:"
mtr -rwc 200 <HOST> > path-baseline.txt
```

### Multi-Server Latency
```bash
# Check latency to multiple servers
for server in server1 server2 server3; do
  echo "$server:"
  ping -c 10 $server | grep rtt
done
```

### Network Troubleshooting Script
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

## 💡 Best Practices
# Use mtr instead of ping+traceroute
# Always use -n to avoid DNS delays
# Run iperf3 tests bidirectionally
# Use -c for count-limited ping
# Log long-term connectivity tests

## 🔧 Default Ports
```bash
# iperf3: 5201
# netcat: user-specified
```

## 📋 Common Use Cases
```bash
# ping: Basic connectivity
# traceroute: Path discovery
# mtr: Continuous monitoring
# iperf3: Bandwidth testing
# netcat: Port testing
# ss: Active connections
```

## 🔍 Alternative Tools
```bash
# fping: Parallel ping
# hping3: Advanced packet crafting
# nmap: Port scanning
# iftop: Real-time bandwidth
# nethogs: Per-process bandwidth
```

## 📚 Documentation Links

- [mtr Man Page](https://man7.org/linux/man-pages/man8/mtr.8.html)
- [traceroute Man Page](https://man7.org/linux/man-pages/man1/traceroute.1.html)
