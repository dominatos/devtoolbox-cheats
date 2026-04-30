Title:  Redis
Group: Databases
Icon: 🗃️
Order: 99

---

> **Redis** (Remote Dictionary Server) is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. It supports strings, hashes, lists, sets, sorted sets, bitmaps, HyperLogLogs, streams, and geospatial indexes.
>
> **Common use cases / Типичные сценарии:** Session caching, full-page caching, rate limiting, real-time leaderboards, message queues, pub/sub messaging, real-time analytics.
>
> **Status / Статус:** Redis is actively developed (current stable: 7.x). In 2024, Redis changed its license from BSD to dual RSALv2/SSPLv1 (source-available). This led to the **Valkey** fork (Linux Foundation) — a fully open-source alternative. Other alternatives: **KeyDB** (multithreaded), **Dragonfly** (modern C++ reimplementation), **Memcached** (simple caching only).
>
> **Default port / Порт по умолчанию:** `6379/tcp`

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Core Management](#core-management)
3. [Sysadmin Operations](#sysadmin-operations)
4. [Security](#security)
5. [Persistence](#persistence)
6. [Monitoring & Performance](#monitoring--performance)
7. [Data Structures](#data-structures)
8. [Caching Patterns](#caching-patterns)
9. [Troubleshooting & Tools](#troubleshooting--tools)
10. [Backup & Restore](#backup--restore)
11. [Logrotate Configuration](#logrotate-configuration)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y redis-server                        # Install Redis / Установка Redis

# RHEL/AlmaLinux/Rocky
sudo dnf install -y redis                                                  # Install Redis / Установка Redis

# From source / Из исходников
wget https://download.redis.io/redis-stable.tar.gz
tar -xzf redis-stable.tar.gz && cd redis-stable
make && sudo make install                                                  # Compile and install / Компиляция и установка
```

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `6379` | Redis server (TCP) / Сервер Redis |
| `16379` | Redis Cluster bus (TCP) / Шина кластера Redis |
| `26379` | Redis Sentinel (TCP) / Sentinel для HA |

### Configuration Files / Файлы конфигурации

| OS / ОС | Config Path / Путь конфигурации |
|---------|-------------------------------|
| Ubuntu/Debian | `/etc/redis/redis.conf` |
| RHEL-based | `/etc/redis.conf` or `/etc/redis/redis.conf` |

### Production Configuration / Конфигурация для продакшена

`/etc/redis/redis.conf`

```bash
# === NETWORK / СЕТЬ ===
bind 127.0.0.1                  # Listen only locally / Слушать только локально
protected-mode yes               # Extra safety / Доп. защита
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# === AUTH / АВТОРИЗАЦИЯ ===
requirepass <PASSWORD>            # Mandatory in prod / Обязательно в проде

# === MEMORY / ПАМЯТЬ ===
maxmemory 2gb                    # Hard RAM limit / Жёсткий лимит RAM
maxmemory-policy allkeys-lru     # Cache eviction policy / Политика вытеснения
maxmemory-samples 5

# === PERSISTENCE / СОХРАНЕНИЕ ===
save 900 1
save 300 10
save 60 10000

appendonly yes                   # Enable AOF / Включить AOF
appendfsync everysec             # Balance safety/perf / Баланс надёжности
no-appendfsync-on-rewrite yes

# === PERFORMANCE / ПРОИЗВОДИТЕЛЬНОСТЬ ===
lazyfree-lazy-eviction yes       # Async key deletion / Асинхронное удаление
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes

# === LIMITS / ЛИМИТЫ ===
maxclients 10000                 # Connection limit / Лимит подключений

# === LOGGING / ЛОГИ ===
loglevel notice
logfile /var/log/redis/redis-server.log

# === SAFETY / БЕЗОПАСНОСТЬ ===
stop-writes-on-bgsave-error yes
```

> [!IMPORTANT]
> `maxmemory` is mandatory in production. Redis without memory limit will consume all available RAM and trigger OOM killer.
> `maxmemory` обязателен в продакшене. Redis без лимита памяти потребит всю RAM и будет убит OOM killer.

---

## Core Management

### Connection / Подключение

```bash
redis-cli                                                                  # Connect locally / Локальное подключение
redis-cli -h <HOST> -p 6379                                               # Connect remotely / Удалённое подключение
redis-cli -a <PASSWORD>                                                    # Connect with auth / С авторизацией
redis-cli -h <HOST> -p 6379 -a <PASSWORD> --tls                           # Connect with TLS / С TLS
```

### General Commands / Основные команды

```bash
PING                                                                       # Health check / Проверка доступности
INFO                                                                       # Full server info / Полная информация
INFO memory                                                                # Memory stats / Статистика памяти
INFO stats                                                                 # Runtime stats / Статистика выполнения
INFO persistence                                                           # RDB/AOF state / Состояние RDB/AOF
INFO replication                                                           # Master/replica status / Статус репликации
INFO clients                                                               # Connected clients / Подключённые клиенты
INFO server                                                                # Server version and uptime / Версия и аптайм
```

### Memory Management / Управление памятью

```bash
MEMORY STATS                                                               # Memory internals / Внутренняя статистика памяти
MEMORY USAGE <KEY>                                                         # Per-key memory usage / Потребление памяти ключом
redis-cli --bigkeys                                                        # Find large keys / Найти большие ключи
redis-cli --memkeys                                                        # Find memory-heavy keys / Ключи с большим потреблением
```

### TTL & Expiration / TTL и истечение срока

```bash
TTL <KEY>                                                                  # Seconds to expire / Секунд до истечения
PTTL <KEY>                                                                 # Milliseconds to expire / Миллисекунд до истечения
EXPIRE <KEY> 300                                                           # Set TTL (5 min) / Установить TTL (5 мин)
PERSIST <KEY>                                                              # Remove TTL / Убрать TTL
```

### Client Management / Управление клиентами

```bash
CLIENT LIST                                                                # Active connections / Активные соединения
CLIENT KILL IP:PORT                                                        # Kill specific client / Убить клиента
CLIENT GETNAME                                                             # Get client name / Имя клиента
CLIENT SETNAME <NAME>                                                      # Set client name / Установить имя клиента
```

### Dangerous Commands / Опасные команды

> [!CAUTION]
> These commands can cause significant performance impact or data loss in production.
> Эти команды могут вызвать значительное падение производительности или потерю данных.

```bash
FLUSHALL                                                                   # Delete ALL data from ALL databases / Удалить ВСЕ данные
FLUSHDB                                                                    # Delete ALL data from current DB / Удалить данные текущей БД
KEYS *                                                                     # List all keys (BLOCKS Redis!) / Список ключей (БЛОКИРУЕТ!)
MONITOR                                                                    # Stream all commands (debug only) / Поток всех команд (отладка)
DEBUG SLEEP <SECONDS>                                                      # Pause server / Остановить сервер
```

> [!TIP]
> Use `SCAN 0 COUNT 100` instead of `KEYS *` in production to iterate keys without blocking.
> Используйте `SCAN 0 COUNT 100` вместо `KEYS *` в продакшене для итерации без блокировки.

---

## Sysadmin Operations

### Service Control / Управление сервисом

```bash
sudo systemctl start redis-server                                          # Start service / Запустить сервис
sudo systemctl stop redis-server                                           # Stop service / Остановить сервис
sudo systemctl restart redis-server                                        # Restart service / Перезапустить сервис
sudo systemctl status redis-server                                         # Service status / Статус сервиса
sudo systemctl enable redis-server                                         # Enable on boot / Включить автозапуск

# RHEL-based may use 'redis' instead of 'redis-server'
sudo systemctl start redis                                                 # RHEL: Start Redis / Запустить Redis
```

### Log Locations / Расположение логов

| Type / Тип | Path / Путь |
|------------|-------------|
| Server Log / Лог сервера | `/var/log/redis/redis-server.log` |
| Data Directory / Данные | `/var/lib/redis/` |
| PID File / Файл PID | `/var/run/redis/redis-server.pid` |
| Unix Socket / Сокет | `/var/run/redis/redis.sock` (if configured) |

```bash
sudo tail -f /var/log/redis/redis-server.log                               # Follow Redis log / Следить за логом
sudo journalctl -u redis-server -f                                         # Systemd logs / Логи systemd
```

### Network & Firewall / Сеть и файрвол

```bash
# Default port: 6379 / Порт по умолчанию: 6379

# UFW / UFW
sudo ufw allow 6379/tcp                                                    # Allow Redis / Разрешить Redis

# firewalld / firewalld
sudo firewall-cmd --permanent --add-port=6379/tcp && sudo firewall-cmd --reload  # Allow Redis / Разрешить Redis
```

> [!WARNING]
> **NEVER** expose Redis to the public internet. Redis has no access control by default (even `requirepass` uses a weak auth model). Always bind to `127.0.0.1` or use a VPN/firewall.
> **НИКОГДА** не выставляйте Redis в интернет. У Redis нет контроля доступа по умолчанию.

### System Tuning / Системная настройка

```bash
# /etc/sysctl.d/99-redis.conf
vm.overcommit_memory = 1                                                   # Required for background saves / Необходимо для фоновых сохранений
net.core.somaxconn = 65535                                                 # Increase backlog / Увеличить backlog

# Apply / Применить
sudo sysctl --system
```

```bash
# Increase file descriptors for Redis service / Увеличить лимит file descriptors
# /etc/systemd/system/redis-server.service.d/override.conf
[Service]
LimitNOFILE=100000
```

---

## Security

### Authentication / Аутентификация

```bash
# Set password in config / Установить пароль в конфиге
requirepass <PASSWORD>

# Set password at runtime (lost on restart) / Установить пароль на лету
CONFIG SET requirepass <PASSWORD>

# Authenticate / Авторизация
AUTH <PASSWORD>
```

### ACL (Access Control Lists) — Redis 6+ / Списки контроля доступа

```bash
# Create user with limited permissions / Создать пользователя с ограниченными правами
ACL SETUSER <USER> on ><PASSWORD> ~cached:* +get +set +del                 # R/W on cached:* keys only

# List users / Список пользователей
ACL LIST

# Check current user / Текущий пользователь
ACL WHOAMI

# Save ACL to config / Сохранить ACL
ACL SAVE
```

### Disable Dangerous Commands / Отключить опасные команды

`/etc/redis/redis.conf`

```bash
rename-command FLUSHALL ""                                                 # Disable FLUSHALL / Отключить FLUSHALL
rename-command FLUSHDB ""                                                  # Disable FLUSHDB / Отключить FLUSHDB
rename-command DEBUG ""                                                    # Disable DEBUG / Отключить DEBUG
rename-command KEYS ""                                                     # Disable KEYS / Отключить KEYS
```

---

## Persistence

### Persistence Methods Comparison / Сравнение методов персистентности

| Method / Метод | Description (EN) | Описание (RU) | Use Case / Применение |
|---------------|------------------|---------------|----------------------|
| **RDB** (Snapshot) | Full DB snapshot every N seconds | Снимок базы каждые N секунд | Fast restarts, acceptable data loss / Быстрый старт, допустима потеря |
| **AOF** (Append Only File) | Append commands to log file | Лог всех команд | Minimal data loss, slower / Минимальные потери, медленнее |
| **RDB + AOF** | Both methods combined | Оба метода вместе | **Recommended for production** / Рекомендуется |
| **None** | RAM only, lost on crash | Только RAM, теряется при падении | Pure cache scenarios / Только кэш |

### RDB Configuration / Настройка RDB

```bash
# Trigger RDB save periodically / Периодическое сохранение RDB
save 900 1                                                                 # Save if 1 key changed in 900s / Сохранять если 1 ключ изменён за 900с
save 300 10                                                                # Save if 10 keys changed in 300s
save 60 10000                                                              # Save if 10000 keys changed in 60s

# Manual RDB save / Ручное сохранение
BGSAVE                                                                     # Background save / Фоновое сохранение
SAVE                                                                       # Blocking save (NOT for production) / Блокирующее (НЕ для прода)
```

### AOF Configuration / Настройка AOF

```bash
appendonly yes                                                             # Enable AOF / Включить AOF
appendfsync everysec                                                       # Sync every second / Синхронизация каждую секунду
# Options: always (safest, slowest), everysec (recommended), no (OS decides)
```

### AOF Rewrite / Перезапись AOF

```bash
# Manual AOF rewrite / Ручная перезапись AOF
BGREWRITEAOF

# Auto-rewrite configuration / Автоматическая перезапись
auto-aof-rewrite-percentage 100                                            # Rewrite when AOF grows 100% / Перезаписать при росте на 100%
auto-aof-rewrite-min-size 64mb                                             # Minimum size for rewrite / Минимальный размер для перезаписи
```

---

## Monitoring & Performance

### Key Metrics / Ключевые метрики

```bash
redis-cli -a <PASSWORD> INFO memory                                        # Memory usage / Использование памяти
redis-cli -a <PASSWORD> INFO stats                                         # Operations stats / Статистика операций
redis-cli -a <PASSWORD> INFO clients                                       # Client connections / Подключения клиентов
redis-cli -a <PASSWORD> INFO keyspace                                      # Keys per database / Ключи по базам
```

### Performance Commands / Команды производительности

```bash
SLOWLOG GET 10                                                             # Last 10 slow commands / Последние 10 медленных команд
SLOWLOG LEN                                                                # Slowlog size / Количество записей в slowlog
SLOWLOG RESET                                                              # Clear slowlog / Очистить slowlog
LATENCY LATEST                                                             # Latest latency events / Последние события задержки
LATENCY HISTORY <EVENT>                                                    # Latency history / История задержек
```

### Production Red Flags / Красные флаги в продакшене

| Issue / Проблема | Risk / Риск | Fix / Решение |
|-----------------|------------|--------------|
| No `maxmemory` | OOM kill at night / OOM ночью | Set `maxmemory` + eviction policy |
| Keys without TTL | Memory leak / Утечка памяти | Set TTL on all cache keys |
| Redis as primary storage | Data loss risk / Риск потери данных | Use a proper DBMS for primary data |
| Public internet exposure | Security breach / Взлом | Bind to `127.0.0.1`, use firewall |
| `noeviction` policy | Writes stop when full / Запись останавливается | Use `allkeys-lru` for caches |
| Cluster without need | Unnecessary complexity / Лишняя сложность | Use Sentinel for HA if sufficient |

### Pre-Production Checklist / Чеклист перед продакшеном

- [ ] `maxmemory` configured / Настроен `maxmemory`
- [ ] Eviction policy defined / Определена политика вытеснения
- [ ] Redis role is clear (cache / queue / storage) / Роль Redis ясна
- [ ] Acceptable data loss defined / Определена допустимая потеря данных
- [ ] Memory monitoring enabled / Мониторинг памяти включён
- [ ] Redis not publicly accessible / Redis не доступен извне
- [ ] `requirepass` or ACL configured / Авторизация настроена

---

## Data Structures

### Sorted Sets / Сортированные множества

Sorted sets store unique elements with a score, enabling ranking and top-N queries. / Сортированные множества хранят уникальные элементы с оценкой, позволяя рейтинги и top-N запросы.

```bash
ZADD leaderboard 100 "player1"                                             # Add element with score / Добавить элемент с оценкой
ZADD leaderboard 200 "player2" 150 "player3"                               # Add multiple / Добавить несколько
ZRANGE leaderboard 0 -1 WITHSCORES                                        # Get all (ascending) / Все (по возрастанию)
ZREVRANGE leaderboard 0 2 WITHSCORES                                       # Top 3 (descending) / Топ 3 (по убыванию)
ZRANK leaderboard "player1"                                                # Rank of element / Ранг элемента
ZSCORE leaderboard "player1"                                               # Score of element / Оценка элемента
```

### Streams / Потоки

Streams are an append-only log data structure, ideal for event sourcing, message queues, and consumer groups. / Потоки — структура данных с последовательной записью для событий, очередей и consumer groups.

```bash
XADD mystream * field1 value1 field2 value2                                # Add entry / Добавить запись
XLEN mystream                                                              # Stream length / Длина потока
XRANGE mystream - +                                                        # Read all entries / Все записи
XREAD COUNT 5 STREAMS mystream 0                                           # Read first 5 / Первые 5

# Consumer groups / Группы потребителей
XGROUP CREATE mystream mygroup $ MKSTREAM                                  # Create group / Создать группу
XREADGROUP GROUP mygroup consumer1 COUNT 1 STREAMS mystream >              # Read as consumer / Прочитать как потребитель
XACK mystream mygroup <MESSAGE_ID>                                         # Acknowledge message / Подтвердить сообщение
```

---

## Caching Patterns

### Read-Through Cache / Кэш сквозного чтения

Application checks Redis first → on cache miss, reads from database → stores in Redis.
Приложение проверяет Redis → при промахе читает из БД → сохраняет в Redis.

```text
Client → Redis (HIT?) → YES → Return data
                       → NO  → Read from MySQL/PostgreSQL → Store in Redis → Return data
```

### Write-Through Cache / Кэш сквозной записи

Application writes to both database and Redis simultaneously.
Приложение записывает в БД и Redis одновременно.

```text
Client → Write to MySQL/PostgreSQL + Write to Redis → Confirm
```

### Cache-Aside (Lazy Loading) / Отложенная загрузка

Most common pattern. Application manages cache manually. / Наиболее распространённый паттерн. Приложение управляет кэшем вручную.

```text
Read:  Check Redis → Miss → Query DB → SET in Redis with TTL
Write: Update DB → DELETE from Redis (invalidation)
```

---

## Troubleshooting & Tools

### Runbook: Redis Went Down at Night / Экстренное восстановление после падения

1. **Check service status / Проверить статус сервиса:**
   ```bash
   systemctl status redis-server                                           # Service state / Статус сервиса
   journalctl -u redis-server --since "2 hours ago"                        # Recent logs / Недавние логи
   ```

2. **Check for OOM kill / Проверить OOM:**
   ```bash
   dmesg | grep -i oom                                                     # OOM events / События OOM
   ```

3. **Diagnose Redis / Диагностика Redis:**
   ```bash
   redis-cli -a <PASSWORD> PING                                            # Connectivity / Связь
   redis-cli -a <PASSWORD> INFO memory                                     # Memory status / Статус памяти
   ```

4. **Common root causes / Частые причины:**

| Cause / Причина | Check / Проверка | Fix / Решение |
|----------------|-----------------|--------------|
| No `maxmemory` | `INFO memory \| grep maxmemory` | Set `maxmemory 2gb` |
| `noeviction` policy | `INFO stats \| grep rejected` | Set `maxmemory-policy allkeys-lru` |
| Fork failed (RDB) | `grep fork /var/log/redis/*.log` | Increase RAM or reduce snapshot freq |
| FD limit reached | `INFO clients` + `ulimit -n` | Set `LimitNOFILE=100000` in systemd |

### Emergency Start / Аварийный запуск

> [!CAUTION]
> This disables persistence. Use only to get Redis back online quickly while investigating.
> Это отключает персистентность. Используйте только для быстрого восстановления.

```bash
redis-server --appendonly no --save ""                                     # Start without persistence / Запуск без сохранения
```

### Interview Question / Вопрос на собеседовании

**Q:** What happens when Redis reaches `maxmemory`? / Что происходит при достижении `maxmemory`?

**A:** Behavior depends on `maxmemory-policy`:

| Policy / Политика | Behavior (EN) | Поведение (RU) |
|-------------------|--------------|----------------|
| `noeviction` | Returns errors on writes | Возвращает ошибки при записи |
| `allkeys-lru` | Evicts least recently used keys | Удаляет наименее используемые ключи |
| `volatile-lru` | Evicts LRU keys with TTL only | Удаляет LRU ключи только с TTL |
| `allkeys-random` | Evicts random keys | Удаляет случайные ключи |
| `volatile-random` | Evicts random keys with TTL | Удаляет случайные ключи с TTL |
| `volatile-ttl` | Evicts keys with shortest TTL | Удаляет ключи с наименьшим TTL |
| `allkeys-lfu` | Evicts least frequently used | Удаляет наименее часто используемые |
| `volatile-lfu` | Evicts LFU keys with TTL | Удаляет LFU ключи с TTL |

---

## Backup & Restore

### RDB Backup / Бэкап RDB

```bash
# Manual backup / Ручной бэкап
redis-cli -a <PASSWORD> BGSAVE                                             # Trigger background save / Фоновое сохранение
redis-cli -a <PASSWORD> LASTSAVE                                           # Check last save time / Время последнего сохранения

# Copy RDB file / Копировать файл RDB
cp /var/lib/redis/dump.rdb /backup/redis/dump_$(date +%Y%m%d_%H%M%S).rdb  # Backup with timestamp
```

### Restore / Восстановление

```bash
# 1. Stop Redis / Остановить Redis
sudo systemctl stop redis-server

# 2. Replace RDB file / Заменить файл RDB
sudo cp /backup/redis/dump_<TIMESTAMP>.rdb /var/lib/redis/dump.rdb
sudo chown redis:redis /var/lib/redis/dump.rdb

# 3. Start Redis / Запустить Redis
sudo systemctl start redis-server
```

### Automated Backup Script / Скрипт автоматического бэкапа

```bash
#!/bin/bash
# /usr/local/bin/redis-backup.sh
BACKUP_DIR="/backup/redis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

redis-cli -a <PASSWORD> BGSAVE
sleep 5
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/dump_$TIMESTAMP.rdb"
gzip "$BACKUP_DIR/dump_$TIMESTAMP.rdb"
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete                         # Delete backups older than 7 days
echo "✅ Redis backup completed: dump_$TIMESTAMP.rdb.gz"
```

**Cron:**

```bash
0 3 * * * /usr/local/bin/redis-backup.sh >> /var/log/redis-backup.log 2>&1
```

---

## Logrotate Configuration

`/etc/logrotate.d/redis-server`

```conf
/var/log/redis/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 redis adm
    sharedscripts
    postrotate
        redis-cli -a <PASSWORD> DEBUG RELOAD > /dev/null 2>&1 || true
    endscript
}
```

> [!TIP]
> Alternatively, use `redis-cli DEBUG RELOAD` or configure log rotation in `redis.conf` directly.
> Альтернативно можно использовать `redis-cli DEBUG RELOAD` или настроить ротацию логов в `redis.conf`.

---
