Title:  Memcached
Group: Databases
Icon: 🗃️
Order: 99

---

> **Memcached** is a free, open-source, high-performance, distributed in-memory key–value cache system. It was originally developed by Brad Fitzpatrick for LiveJournal in 2003. Memcached is designed to reduce database load by caching data and objects in RAM.
>
> **Common use cases / Типичные сценарии:** Database query result caching, session storage (risky — no persistence), rate limiting, page fragment caching, API response caching.
>
> **Status / Статус:** Memcached is still actively maintained but is considered a legacy caching solution for most new projects. Modern alternatives include **Redis** (richer data structures, persistence, pub/sub), **Valkey** (open-source Redis fork), **KeyDB** (multi-threaded Redis fork). Memcached remains relevant for ultra-simple, high-throughput caching scenarios where its simplicity is an advantage.
>
> **Default port / Порт по умолчанию:** `11211/tcp` (also `11211/udp` — should be disabled in production)

---

## 📚 Table of Contents / Содержание

1. [Architecture](#architecture)
2. [Installation & Configuration](#installation--configuration)
3. [Core Management](#core-management)
4. [Sysadmin Operations](#sysadmin-operations)
5. [Security](#security)
6. [Monitoring & Performance](#monitoring--performance)
7. [Troubleshooting & Tools](#troubleshooting--tools)
8. [Logrotate Configuration](#logrotate-configuration)

---

## Architecture

### Key Properties / Ключевые свойства

**EN:**
- In-memory only — no persistence
- No replication — each instance is standalone
- No authentication (by default)
- Very fast, very simple
- Client–server model via TCP or UDP
- Clustering handled by the application, not Memcached

**RU:**
- Хранение только в RAM — нет персистентности
- Нет репликации — каждый инстанс отдельный
- Нет аутентификации (по умолчанию)
- Максимально быстрый и простой
- Клиент–серверная модель по TCP или UDP
- Кластеризация реализуется на стороне приложения

> [!WARNING]
> Multiple Memcached servers ≠ cluster. Data distribution is handled by client-side consistent hashing.
> Несколько серверов Memcached ≠ кластер. Распределение данных происходит на стороне клиента.

> [!CAUTION]
> Never store critical data in Memcached. A restart erases all data — this is expected behavior.
> Никогда не храните критичные данные в Memcached. Рестарт стирает все данные — это нормальное поведение.

### Memcached vs Redis Comparison / Сравнение Memcached и Redis

| Feature / Особенность | Memcached | Redis |
|----------------------|-----------|-------|
| Data structures / Структуры данных | Key–value only / Только ключ–значение | Strings, lists, sets, hashes, streams, etc. |
| Persistence / Персистентность | No / Нет | RDB, AOF, both |
| Replication / Репликация | No / Нет | Master–replica, Sentinel, Cluster |
| Authentication / Аутентификация | No (SASL optional) / Нет | `requirepass`, ACL (6.0+) |
| Max value size / Макс. размер значения | 1MB (default) | 512MB |
| Multi-threaded / Многопоточный | Yes / Да | Single-threaded (I/O threads in 6.0+) |
| Best for / Лучше для | Simple high-throughput caching / Простой высокопроизводительный кэш | Feature-rich caching, queues, storage / Кэш с функциями, очереди |

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y memcached libmemcached-tools        # Install Memcached / Установка Memcached

# RHEL/AlmaLinux/Rocky
sudo dnf install -y memcached libmemcached                                 # Install Memcached / Установка Memcached
```

### Quick Test / Быстрый тест

```bash
echo "stats" | nc localhost 11211                                          # Check if Memcached responds / Проверить ответ Memcached
```

### Configuration / Конфигурация

`/etc/memcached.conf` (Ubuntu/Debian)  
`/etc/sysconfig/memcached` (RHEL-based)

```bash
-m 512                                                                     # Memory limit in MB / Лимит памяти
-p 11211                                                                   # Port / Порт
-l 127.0.0.1                                                              # Bind address (CRITICAL) / Адрес привязки
-u memcache                                                                # Run as user / Пользователь
-c 1024                                                                    # Max connections / Макс. соединений
-U 0                                                                       # Disable UDP (security) / Отключить UDP (безопасность)
```

> [!CAUTION]
> Setting `-l 0.0.0.0` exposes Memcached to the internet with **no authentication**. Memcached was used in massive UDP DDoS amplification attacks (1.35 Tbps attack on GitHub in 2018).
> Установка `-l 0.0.0.0` открывает Memcached в интернет **без аутентификации**. Memcached использовался в масштабных DDoS-атаках.

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `11211/tcp` | Memcached client connections / Клиентские подключения |
| `11211/udp` | Memcached UDP (disable in production!) / UDP (отключить в продакшене!) |

---

## Core Management

### Common Use Cases / Типичные сценарии использования

#### Database Query Caching / Кэширование запросов к БД

```text
key: user:123:profile
ttl: 300
```

#### Session Storage (risky) / Хранение сессий (рискованно)

- Often used in PHP legacy apps / Часто используется в PHP legacy приложениях
- Memcached restart = user logout / Рестарт Memcached = разлогин пользователя

#### Rate Limiting / Ограничение запросов

- Counter + TTL pattern / Паттерн счётчик + TTL
- Simple but effective / Просто, но эффективно

---

## Sysadmin Operations

### Service Control / Управление сервисом

```bash
sudo systemctl start memcached                                             # Start service / Запустить сервис
sudo systemctl stop memcached                                              # Stop service / Остановить сервис
sudo systemctl restart memcached                                           # Restart service / Перезапустить сервис
sudo systemctl status memcached                                            # Service status / Статус сервиса
sudo systemctl enable memcached                                            # Enable on boot / Включить автозапуск
```

### Log Locations / Расположение логов

| Type / Тип | Path / Путь |
|------------|-------------|
| Log File / Лог | `/var/log/memcached.log` (if configured with `-v` or `-vv`) |
| PID File / Файл PID | `/var/run/memcached/memcached.pid` |

```bash
sudo journalctl -u memcached -f                                            # Follow service logs / Следить за логами
```

### Network & Firewall / Сеть и файрвол

```bash
# Default port: 11211 / Порт по умолчанию: 11211

# UFW / UFW
sudo ufw allow 11211/tcp                                                   # Allow Memcached TCP / Разрешить TCP
# Do NOT allow 11211/udp in production! / НЕ разрешайте UDP в продакшене!

# firewalld / firewalld
sudo firewall-cmd --permanent --add-port=11211/tcp && sudo firewall-cmd --reload
```

---

## Security

> [!WARNING]
> Memcached has **NO built-in authentication** by default. Security relies entirely on network-level access control.
> Memcached **НЕ имеет встроенной аутентификации** по умолчанию. Безопасность полностью зависит от сетевого контроля.

### Security Best Practices / Лучшие практики безопасности

- Bind only to `localhost` or private network / Привязывать только к `localhost` или приватной сети
- Disable UDP (`-U 0`) / Отключить UDP
- Protect with firewall / Закрывать файрволом
- Use SASL authentication if available / Использовать SASL аутентификацию при возможности
- Run as non-root user / Запускать от непривилегированного пользователя

### SASL Authentication (Optional) / Аутентификация SASL

```bash
# Enable SASL (requires memcached compiled with SASL support)
# /etc/sasl2/memcached.conf
mech_list: plain
log_level: 5
sasldb_path: /etc/sasl2/memcached-sasldb2
```

```bash
# Create SASL user / Создать пользователя SASL
saslpasswd2 -a memcached -c -f /etc/sasl2/memcached-sasldb2 <USER>

# Start with SASL / Запустить с SASL
memcached -S                                                               # Enable SASL authentication / Включить SASL
```

---

## Monitoring & Performance

### View Stats / Просмотр статистики

```bash
memcached-tool localhost:11211 stats                                       # Full stats / Полная статистика
memcached-tool localhost:11211 display                                     # Slab stats / Статистика слабов
echo "stats" | nc localhost 11211                                          # Raw stats via netcat / Статистика через netcat
echo "stats slabs" | nc localhost 11211                                    # Slab allocator stats / Статистика аллокатора
echo "stats items" | nc localhost 11211                                    # Item stats / Статистика элементов
```

### Key Metrics / Важные метрики

| Metric / Метрика | Meaning (EN) | Значение (RU) | Warning Threshold / Порог |
|-----------------|-------------|---------------|--------------------------|
| `get_hits` | Cache hits | Попадания в кэш | — |
| `get_misses` | Cache misses | Промахи | High ratio = bad caching |
| `evictions` | Removed items due to memory | Вытеснения из-за памяти | >0 = possible memory issue |
| `bytes` | Used memory | Используемая RAM | Near `limit_maxbytes` |
| `curr_items` | Current items count | Кол-во объектов | — |
| `curr_connections` | Active connections | Активные подключения | Near `maxconns` |

### Interpretation / Интерпретация

- **High misses** → bad caching strategy or TTL too low / Плохая стратегия кэширования
- **High evictions** → not enough memory (`-m` too small) / Недостаточно памяти
- **Memory near limit** → risk of eviction storms / Риск каскадных вытеснений

### When NOT to Use Memcached / Когда НЕ стоит использовать

- Persistence required / Нужна персистентность → **Use Redis**
- Replication needed / Нужна репликация → **Use Redis**
- Complex data structures / Сложные структуры данных → **Use Redis**
- Transactions / Транзакции → **Use a proper DBMS**

---

## Troubleshooting & Tools

### Cache is Ineffective / Кэш не работает

**Causes / Причины:**
- TTL too low / TTL слишком низкий
- Poor key design / Плохой дизайн ключей
- Different keys per request / Разные ключи на каждый запрос
- Insufficient memory causing evictions / Недостаточно памяти

```bash
# Check hit ratio / Проверить процент попаданий
echo "stats" | nc localhost 11211 | grep -E 'get_hits|get_misses'

# Calculate hit rate: hits / (hits + misses) × 100%
# Good: >90% / Хорошо: >90%
```

### Data Lost After Restart / Данные пропали после рестарта

> [!NOTE]
> This is expected behavior — Memcached is an in-memory cache with no persistence. If you need data to survive restarts, use Redis with persistence enabled.
> Это нормальное поведение — Memcached хранит данные только в RAM.

### Performance Degradation / Падение производительности

- Not enough RAM (`-m` parameter) / Недостаточно RAM
- High evictions / Много вытеснений
- Memory contention with application / Конкуренция за память с приложением
- Network issues / Сетевые проблемы

```bash
# Check eviction rate / Проверить частоту вытеснений
echo "stats" | nc localhost 11211 | grep evictions

# Monitor connections / Мониторинг подключений
echo "stats" | nc localhost 11211 | grep curr_connections
```

### Interview Questions / Вопросы на собеседовании

| Question / Вопрос | Answer / Ответ |
|-------------------|----------------|
| Does Memcached have persistence? | No — RAM only / Нет — только RAM |
| Does it support replication? | No — each instance is standalone / Нет — каждый инстанс отдельный |
| Is it secure by default? | No — no authentication / Нет — нет аутентификации |
| Memcached vs Redis? | Redis = feature-rich data store; Memcached = simple fast cache |
| How does Memcached cluster? | Client-side consistent hashing / Консистентное хеширование на клиенте |

---

## Logrotate Configuration

`/etc/logrotate.d/memcached`

```conf
/var/log/memcached.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 memcache adm
    postrotate
        /bin/kill -HUP $(cat /var/run/memcached/memcached.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
```

> [!NOTE]
> Memcached logs minimally by default. Enable verbose logging with `-v` (basic) or `-vv` (detailed) flag in the service configuration if needed.
> Memcached по умолчанию логирует минимально. Включите подробное логирование флагом `-v` или `-vv` при необходимости.

---
