Title:  Memcached
Group: Databases
Icon: 🗃️
Order: 99

---

## 📚 Table of Contents / Содержание

1. [What is Memcached](#1-what-is-memcached--что-такое-memcached)
2. [Architecture](#2-architecture--архитектура)
3. [Common Use Cases](#3-common-use-cases--типичные-сценарии)
4. [Installation](#4-installation--установка)
5. [Configuration](#5-configuration--конфигурация)
6. [Security](#6-security--безопасность)
7. [Monitoring](#7-monitoring--мониторинг)
8. [Performance & Tuning](#8-performance--tuning--производительность-и-тюнинг)
9. [Common Problems](#9-common-problems--типичные-проблемы)
10. [Interview Questions](#10-interview-questions--вопросы-на-собеседовании)
11. [Summary](#11-summary--итог)

---

# Memcached for System Administrators  
# Memcached для системных администраторов

---

## 1. What is Memcached / Что такое Memcached

**EN:**  
Memcached is a high-performance, in-memory **key–value cache**.  
It stores data in RAM to reduce database load and speed up applications.

Key properties:
- In-memory only
- No persistence
- No replication
- No authentication
- Very fast, very simple

**RU:**  
Memcached — это высокопроизводительный **in-memory key–value кэш**.  
Используется для снижения нагрузки на БД и ускорения приложений.

Ключевые свойства:
- Хранение только в RAM
- Нет персистентности
- Нет репликации
- Нет аутентификации
- Максимально быстрый и простой

⚠ **Never store critical data in Memcached**  
⚠ **Никогда не храни критичные данные**

---

## 2. Architecture / Архитектура

**EN:**
- Client–server model
- Access via TCP or UDP
- Each instance is standalone
- Clustering is handled by the application, not Memcached

**RU:**
- Клиент–серверная модель
- Доступ по TCP или UDP
- Каждый инстанс — отдельный
- Кластеризация реализуется на стороне приложения

❗ Multiple servers ≠ cluster  
❗ Несколько серверов ≠ кластер

---

## 3. Common Use Cases / Типичные сценарии

### 3.1 Database query caching  
### Кэширование запросов к БД

```text
key: user:123:profile
ttl: 300
```

### 3.2 Session storage (risky)  
### Хранение сессий (рискованно)

- Often used in PHP legacy apps
- Memcached restart = user logout

### 3.3 Rate limiting  
### Ограничение запросов

- Counter + TTL
- Simple but effective

---

## 4. Installation / Установка

### Ubuntu / Debian

```bash
apt install memcached libmemcached-tools
```

### Check service / Проверка сервиса

```bash
systemctl status memcached
```

### Quick test / Быстрый тест

```bash
echo "stats" | nc localhost 11211
```

---

## 5. Configuration / Конфигурация

Default config file:  

```bash
/etc/memcached.conf
```

### Key parameters / Важные параметры

```bash
-m 512        # Memory limit in MB / Лимит памяти
-p 11211      # Port / Порт
-l 127.0.0.1  # Bind address (CRITICAL) / Адрес привязки
-u memcache   # Run as user / Пользователь
-c 1024       # Max connections / Макс. соединений
```

### ❌ Dangerous configuration / Опасная конфигурация

```bash
-l 0.0.0.0
```

**EN:** Exposes Memcached to the internet (no auth!)  
**RU:** Открывает Memcached в интернет (без защиты!)

---

## 6. Security / Безопасность

**EN:**
- Memcached has NO authentication
- Never expose it publicly
- Bind only to localhost or private network
- Protect with firewall

**RU:**
- В Memcached НЕТ аутентификации
- Никогда не публиковать наружу
- Использовать localhost или private IP
- Закрывать firewall’ом

⚠ Memcached was used in massive UDP DDoS attacks  
⚠ Memcached использовался в масштабных DDoS

---

## 7. Monitoring / Мониторинг

### View stats / Просмотр статистики

```bash
memcached-tool localhost:11211 stats
```

### Key metrics / Важные метрики

| Metric | Meaning (EN) | Значение (RU) |
|------|-------------|---------------|
| get_hits | Cache hits | Попадания в кэш |
| get_misses | Cache misses | Промахи |
| evictions | Removed items | Вытеснения |
| bytes | Used memory | Используемая RAM |
| curr_items | Items count | Кол-во объектов |

### Interpretation / Интерпретация

- High misses → bad caching strategy  
- High evictions → not enough memory  
- Memory near limit → risk of eviction storms  

---

## 8. Performance & Tuning / Производительность и тюнинг

**EN:** Memcached is best for:
- Simple key–value data
- Very high throughput
- Minimal latency

**RU:** Memcached подходит для:
- Простых данных
- Очень большого количества запросов
- Минимальной задержки

### When NOT to use Memcached  
### Когда НЕ стоит использовать

- Persistence required
- Replication needed
- Complex data structures
- Transactions

➡ Use Redis instead  
➡ Используй Redis

---

## 9. Common Problems / Типичные проблемы

### Cache is ineffective  
### Кэш не работает

**Causes / Причины:**
- TTL too low
- Poor key design
- Different keys per request

---

### Data lost after restart  
### Данные пропали после рестарта

✅ Expected behavior  
✅ Это нормально

---

### Performance degradation  
### Падение производительности

- Not enough RAM
- High evictions
- Memory contention with app

---

## 10. Interview Questions / Вопросы на собеседовании

**Q:** Does Memcached have persistence?  
**A:** No

**Q:** Does it support replication?  
**A:** No

**Q:** Is it secure by default?  
**A:** No authentication

**Q:** Memcached vs Redis?  
**A:**  
- Redis = data store  
- Memcached = dumb cache

---

## 11. Summary / Итог

**EN:**  
Memcached is simple, fast, and dangerous if misconfigured.  
Every sysadmin must understand its limitations.

**RU:**  
Memcached простой, быстрый и опасный при неправильной настройке.  
Сисадмин обязан понимать его ограничения.

---

## Further Topics / Дальнейшие темы

- Memcached vs Redis (benchmarks)
- PHP / Java integration
- Monitoring with Prometheus
- Real incident analysis

---

## 12. Logrotate Configuration / Конфигурация Logrotate

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
> Memcached logs minimally by default. Enable verbose logging with `-vv` flag if needed.
> Memcached по умолчанию логирует минимально. Включите подробное логирование флагом `-vv` при необходимости.

---
