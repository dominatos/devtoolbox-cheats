Title: 📡 SS — Socket Statistics
Group: Network
Icon: 📡
Order: 2

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Filtering](#-filtering--фильтрация)
- [Statistics](#-statistics--статистика)
- [Advanced Usage](#-advanced-usage--продвинутое-использование)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Basic Commands / Базовые команды

### Show All Sockets / Показать все сокеты
```bash
ss                                            # Show all sockets / Показать все сокеты
ss -a                                         # Show all (listening + non-listening) / Показать все
ss -l                                         # Show only listening / Показать только слушающие
ss -t                                         # Show TCP sockets / Показать TCP сокеты
ss -u                                         # Show UDP sockets / Показать UDP сокеты
ss -x                                         # Show Unix sockets / Показать Unix сокеты
```

### Common Combinations / Распространённые комбинации
```bash
ss -tunlp                                     # TCP+UDP, numeric, listening, processes / TCP+UDP, числовые, слушающие, процессы
ss -tunap                                     # TCP+UDP, numeric, all, processes / TCP+UDP, числовые, все, процессы
ss -tulpn                                     # Same as above (order doesn't matter) / То же (порядок не важен)
```

### Options / Опции
```bash
ss -n                                         # Don't resolve service names / Не разрешать имена сервисов
ss -p                                         # Show process using socket / Показать процесс использующий сокет
ss -r                                         # Resolve IP addresses / Разрешать IP адреса
ss -e                                         # Show extended info / Показать расширенную информацию
ss -m                                         # Show socket memory usage / Показать использование памяти сокетами
```

---

# 🔍 Filtering / Фильтрация

### By State / По состоянию
```bash
ss state established                          # Established connections / Установленные соединения
ss state listening                            # Listening sockets / Слушающие сокеты
ss state time-wait                            # Time-wait sockets / Сокеты в состоянии time-wait
ss state syn-sent                             # SYN-sent connections / Соединения SYN-sent
ss state fin-wait-1                           # FIN-wait-1 connections / Соединения FIN-wait-1
```

### Multiple States / Несколько состояний
```bash
ss state established state syn-recv           # Multiple states / Несколько состояний
ss 'state established or state syn-recv'      # Alternative syntax / Альтернативный синтаксис
```

### By Port / По порту
```bash
ss sport = :22                                # Source port 22 / Исходный порт 22
ss dport = :80                                # Destination port 80 / Порт назначения 80
ss sport = :1024-65535                        # Source port range / Диапазон исходных портов
ss dport gt :1024                             # Destination port > 1024 / Порт назначения > 1024
ss dport lt :1024                             # Destination port < 1024 / Порт назначения < 1024
```

### By Address / По адресу
```bash
ss src <IP>                                   # Source IP / Исходный IP
ss dst <IP>                                   # Destination IP / IP назначения
ss src 192.168.1.0/24                         # Source subnet / Исходная подсеть
```

### Complex Filters / Сложные фильтры
```bash
ss 'sport = :22 and state established'        # SSH established / SSH установленные
ss 'dport = :80 or dport = :443'              # HTTP or HTTPS / HTTP или HTTPS
ss '( dport = :http or dport = :https ) and state established'  # Complex / Сложный
```

---

# 📊 Statistics / Статистика

### Summary / Сводка
```bash
ss -s                                         # Socket summary / Сводка сокетов
ss -s | head -10                              # Top 10 lines / Первые 10 строк
```

### Memory / Память
```bash
ss -m                                         # Show socket memory / Показать память сокетов
ss -tm                                        # TCP with memory info / TCP с информацией о памяти
```

### Timer / Таймер
```bash
ss -o                                         # Show timer info / Показать информацию о таймере
ss -to                                        # TCP with timers / TCP с таймерами
```

---

# 🔬 Advanced Usage / Продвинутое использование

### Show Process Info / Показать информацию о процессах
```bash
sudo ss -tlnp                                 # Listening TCP with processes / Слушающие TCP с процессами
sudo ss -plnt | grep ':80'                    # Process on port 80 / Процесс на порту 80
sudo ss -plnt | awk '$4 ~ /:22$/'             # SSH processes / SSH процессы
```

### Extended Information / Расширенная информация
```bash
ss -e                                         # Extended socket info / Расширенная информация о сокетах
ss -te                                        # TCP extended / TCP расширенное
ss -tem                                       # TCP extended + memory / TCP расширенное + память
```

### Unix Sockets / Unix сокеты
```bash
ss -x                                         # Unix domain sockets / Unix доменные сокеты
ss -xa                                        # All Unix sockets / Все Unix сокеты
ss -xl                                        # Listening Unix sockets / Слушающие Unix сокеты
```

---

# 🌟 Real-World Examples / Примеры из практики

### Find Which Process Uses Port / Найти какой процесс использует порт
```bash
sudo ss -tlnp | grep ':80'                    # Find process on port 80 / Найти процесс на порту 80
sudo ss -tunlp | grep ':3306'                 # Find MySQL process / Найти процесс MySQL
sudo ss -plnt | awk '$4 ~ /:443$/'            # Find HTTPS process / Найти процесс HTTPS
```

### Count Connections / Подсчитать соединения
```bash
ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c  # Count by state / Подсчитать по состоянию
ss state established | wc -l                  # Count established / Подсчитать установленные
ss sport = :80 state established | wc -l      # Count HTTP connections / Подсчитать HTTP соединения
```

### Find Top Connections / Найти топ соединений
```bash
# Top 10 IPs by connection count / Топ 10 IP по количеству соединений
ss -tan | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10

# Top ports / Топ портов
ss -tan | awk 'NR>1 {print $4}' | cut -d: -f2 | sort | uniq -c | sort -nr | head -10
```

### Monitor Connections / Мониторить соединения
```bash
# Watch established connections / Смотреть установленные соединения
watch -n 1 'ss -tan | grep ESTAB | wc -l'

# Monitor specific port / Мониторить конкретный порт
watch -n 1 'sudo ss -tlnp | grep :80'
```

### Check Listening Services / Проверить слушающие сервисы
```bash
# All listening ports / Все слушающие порты
sudo ss -tunlp

# Only TCP / Только TCP
sudo ss -tlnp

# Only UDP / Только UDP
sudo ss -ulnp

# Sort by port / Сортировать по порту
sudo ss -tlnp | sort -k 5
```

### Detect TIME_WAIT Issues / Обнаружить проблемы TIME_WAIT
```bash
# Count TIME_WAIT connections / Подсчитать TIME_WAIT соединения
ss -tan | grep TIME-WAIT | wc -l

# Show TIME_WAIT details / Показать детали TIME_WAIT
ss state time-wait
```

### Find Zombie Connections / Найти зомби-соединения
```bash
# Find half-open connections / Найти полуоткрытые соединения
ss state syn-recv
ss state fin-wait-1
ss state fin-wait-2
```

### Check Specific Service / Проверить конкретный сервис
```bash
# SSH connections / SSH соединения
sudo ss -tp state established '( dport = :22 or sport = :22 )'

# MySQL connections / MySQL соединения
sudo ss -tp '( dport = :3306 or sport = :3306 )'

# Docker connections / Docker соединения
sudo ss -tlnp | grep docker
```

### Compare with netstat / Сравнить с netstat
```bash
# netstat equivalent / эквивалент netstat
ss -tan                                       # netstat -tan
ss -ltn                                       # netstat -ltn
sudo ss -tulpn                                # sudo netstat -tulpn
```

### Export Connection Data / Экспортировать данные соединений
```bash
# Export to CSV / Экспортировать в CSV
ss -tan | awk 'NR>1 {print $1","$2","$3","$4","$5}' > connections.csv

# Export with timestamp / Экспортировать с временной меткой
echo "$(date),$(ss -tan | grep ESTAB | wc -l)" >> connections-log.csv
```

### Security Audit / Аудит безопасности
```bash
# Find unexpected listening ports / Найти неожиданные слушающие порты
sudo ss -tunlp | grep -v '127.0.0.1\|::1'

# Find non-local listeners / Найти не-локальные слушатели
sudo ss -tunlp | grep -v 'users:'
```

## 💡 Best Practices / Лучшие практики

- Use `-n` for faster output (no DNS resolution) / Используйте `-n` для быстрого вывода (без DNS разрешения)
- Use `sudo` for process info (`-p` option) / Используйте `sudo` для информации о процессах (опция `-p`)
- `ss` is faster than `netstat` / `ss` быстрее чем `netstat`
- Use filters for large servers / Используйте фильтры для больших серверов
- Watch for TIME_WAIT buildup / Следите за накоплением TIME_WAIT
- Check listening services regularly / Регулярно проверяйте слушающие сервисы

## 🔧 Common Options / Распространённые опции

| Option | Description (EN / RU) |
|--------|----------------------|
| `-t` / `-u` | TCP / UDP sockets / сокеты |
| `-l` / `-a` | Listening / All sockets / Слушающие / Все сокеты |
| `-n` | Numeric (no name resolution) / Числовой (без разрешения имён) |
| `-p` | Show processes / Показать процессы |
| `-e` | Extended info / Расширенная информация |
| `-m` | Memory info / Информация о памяти |
| `-o` | Timer info / Информация о таймере |

## 📋 Socket States / Состояния сокетов

| State | Description (EN / RU) |
|-------|----------------------|
| `ESTABLISHED` | Active connection / Активное соединение |
| `LISTEN` | Listening for connections / Слушает соединения |
| `TIME-WAIT` | Waiting after close / Ожидание после закрытия |
| `SYN-SENT` | Connection attempt / Попытка соединения |
| `SYN-RECV` | Connection being established / Соединение устанавливается |
| `FIN-WAIT-1` | Connection closing / Соединение закрывается |
| `FIN-WAIT-2` | Connection almost closed / Соединение почти закрыто |
| `CLOSE-WAIT` | Waiting for close / Ожидание закрытия |
| `CLOSING` | Closing connection / Закрытие соединения |
| `LAST-ACK` | Waiting for ACK / Ожидание ACK |

## ⚠️ Important Notes / Важные примечания

- `ss` replaces `netstat` / `ss` заменяет `netstat`
- Requires `iproute2` package / Требует пакет `iproute2`
- Some options require root / Некоторые опции требуют root
- Filters use double quotes / Фильтры используют двойные кавычки
