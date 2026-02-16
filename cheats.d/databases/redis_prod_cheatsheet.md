Title:  Redis
Group: Databases
Icon: 🗃️
Order: 99

---

## 📚 Table of Contents / Содержание

1. [Minimal Safe redis.conf for PROD](#1-минимальный-безопасный-redisconf-для-prod--minimal-safe-redisconf-for-prod)
2. [Typical Incident: Redis Down](#2-типовой-инцидент-redis-упал-ночью--typical-incident-redis-went-down-at-night)
3. [Emergency Start](#3-аварийный-запуск-если-redis-не-стартует--emergency-start-redis-does-not-start)
4. [Admin Command Cheatsheet](#4-шпаргалка-команд-администратора--admin-command-cheatsheet)
5. [Production Red Flags](#5-красные-флаги-в-prod--production-red-flags)
6. [Pre-PROD Checklist](#6-мини-чеклист-перед-prod--pre-prod-checklist)
7. [Interview Question](#7-вопрос-с-собеседования--interview-question)
8. [Persistence: RDB / AOF / None](#8-persistence-rdb--aof--none)
9. [Sorted Set / Stream](#9-sorted-set--stream)
10. [Read-through / Write-through Cache](#10-read-through--write-through-cache)
11. [Redis Eviction](#11-redis-eviction--как-работает)

---

# Redis — PROD шпаргалка для сисадмина / Redis — PROD cheatsheet for sysadmins

> Практический документ: конфигурация, инциденты, диагностика.
> Practical document: configuration, incidents, diagnostics.
> Без теории, только реальный продакшен.
> No theory, real production only.

---

## 1. Минимальный безопасный `redis.conf` для PROD / Minimal safe `redis.conf` for PROD

```conf
# === NETWORK / СЕТЬ ===
bind 127.0.0.1              # Listen only locally / Слушать только локально
protected-mode yes           # Extra safety / Доп. защита
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# === AUTH / АВТОРИЗАЦИЯ ===
requirepass STRONG_PASSWORD  # Mandatory in prod / Обязательно в проде

# === MEMORY / ПАМЯТЬ ===
maxmemory 2gb                # Hard RAM limit / Жёсткий лимит RAM
maxmemory-policy allkeys-lru # Cache eviction policy / Политика вытеснения
maxmemory-samples 5

# === PERSISTENCE / СОХРАНЕНИЕ ===
save 900 1
save 300 10
save 60 10000

appendonly yes               # Enable AOF / Включить AOF
appendfsync everysec         # Balance safety/perf / Баланс надёжности
no-appendfsync-on-rewrite yes

# === PERFORMANCE / ПРОИЗВОДИТЕЛЬНОСТЬ ===
lazyfree-lazy-eviction yes   # Async key deletion / Асинхронное удаление
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes

# === LIMITS / ЛИМИТЫ ===
maxclients 10000             # Connection limit / Лимит подключений

# === LOGGING / ЛОГИ ===
loglevel notice
logfile /var/log/redis/redis-server.log

# === SAFETY / БЕЗОПАСНОСТЬ ===
stop-writes-on-bgsave-error yes
```

**Важно / Important:**
- `maxmemory` обязателен / mandatory
- Redis без лимита памяти = OOM ночью / no limit = OOM kill

---

## 2. Типовой инцидент: «Redis упал ночью" / Typical incident: "Redis went down at night"

### Быстрая проверка / Quick check

```bash
systemctl status redis        # Service state
journalctl -u redis --since "2 hours ago"  # Recent logs
```

Проверка OOM / OOM check:

```bash
dmesg | grep -i oom
```

### Диагностика Redis / Redis diagnostics

```bash
redis-cli -a PASSWORD ping
redis-cli -a PASSWORD INFO
```

Ключевые метрики / Key metrics:
- `used_memory` — RAM usage
- `maxmemory` — configured limit
- `evicted_keys` — evictions count
- `rejected_connections` — connection issues

---

### Частые причины падений / Common root causes

#### 1. Нет `maxmemory` / No `maxmemory`

```bash
redis-cli INFO memory | grep maxmemory
```

Фикс / Fix:

```conf
maxmemory 2gb
maxmemory-policy allkeys-lru
```

---

#### 2. `noeviction` policy

Redis stops accepting writes when memory is full.

```bash
redis-cli INFO stats | grep rejected
```

Фикс / Fix:

```conf
maxmemory-policy allkeys-lru
```

---

#### 3. Fork failed (RDB snapshot)

```bash
grep fork /var/log/redis/redis-server.log
```

Причины / Causes:
- insufficient RAM
- too frequent snapshots

---

#### 4. Закончились file descriptors / FD limit reached

```bash
redis-cli INFO clients
ulimit -n
```

Фикс / Fix (systemd):

```ini
LimitNOFILE=100000
```

---

## 3. Аварийный запуск (если Redis не стартует) / Emergency start (Redis does not start)

```bash
redis-server --appendonly no --save ""
```

Очистка данных / Data cleanup:

```bash
FLUSHALL
```

---

## 4. Шпаргалка команд администратора / Admin command cheatsheet

### Общие / General

```bash
PING                    # Health check
INFO                    # Full info
INFO memory             # Memory stats
INFO stats              # Runtime stats
INFO persistence        # RDB/AOF state
INFO replication        # Master/replica
INFO clients            # Connected clients
```

### Память / Memory

```bash
MEMORY STATS            # Memory internals
MEMORY USAGE key        # Per-key usage
redis-cli --bigkeys     # Find large keys
```

### TTL / Expiration

```bash
TTL key                 # Seconds to expire
PTTL key                # Milliseconds to expire
```

### Клиенты / Clients

```bash
CLIENT LIST             # Active connections
CLIENT KILL ip:port     # Kill client
```

### Производительность / Performance

```bash
SLOWLOG GET 10          # Last slow commands
SLOWLOG LEN             # Slowlog size
```

### Опасные команды / Dangerous commands

```bash
FLUSHALL
FLUSHDB
MONITOR
KEYS *
```
`KEYS *` blocks Redis in production.

---

## 5. Красные флаги в PROD / Production red flags

- Redis without `maxmemory`
- Keys without TTL
- Redis used as primary storage
- Redis exposed to the Internet
- Redis Cluster without real need

---

## 6. Мини-чеклист перед PROD / Pre-PROD checklist

- [ ] `maxmemory` configured
- [ ] eviction policy defined
- [ ] Redis role is clear (cache / queue / storage)
- [ ] acceptable data loss defined
- [ ] memory monitoring enabled
- [ ] Redis not publicly accessible

---

## 7. Вопрос с собеседования / Interview question

**What happens when Redis reaches `maxmemory`?**

Expected answer: eviction policies, `noeviction`, impact on application.

---

## 8. Persistence: RDB / AOF / None

### RDB (snapshot)
**RU:** снимок базы каждые N секунд, быстрый, возможна потеря последних данных
**EN:** full DB snapshot every N seconds, fast, may lose last changes

### AOF (Append Only File)
**RU:** лог команд, минимальные потери, медленнее
**EN:** append commands to log, minimal loss, slower

### None
**RU:** только RAM, потеря при падении
**EN:** RAM only, lost on crash

---

## 9. Sorted Set / Stream

### Sorted Set
**RU:** уникальные элементы + score, рейтинг, топ-N
**EN:** unique elements + score, ranking, top-N

### Stream
**RU:** последовательность событий, очередь, лог, consumer group
**EN:** sequential events, queue, log, consumer group

---

## 10. Read-through / Write-through cache

### Read-through
**RU:** проверка Redis → MySQL → Redis
**EN:** check Redis → MySQL → Redis

### Write-through
**RU:** обновление MySQL + Redis одновременно
**EN:** write to MySQL + Redis simultaneously

---

## 11. Redis eviction / Как работает

**RU:** при достижении `maxmemory` удаляются ключи по `maxmemory-policy`
- allkeys-lru, volatile-lru, allkeys-random, volatile-random, noeviction
**EN:** on reaching `maxmemory`, keys evicted based on `maxmemory-policy`
- allkeys-lru, volatile-lru, allkeys-random, volatile-random, noeviction

