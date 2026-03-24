Title: 🔀 ProxySQL — MySQL Proxy
Group: Databases
Icon: 🔀
Order: 6

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Core Management](#core-management)
3. [Backends & Hostgroups](#backends--hostgroups)
4. [Query Rules & Routing](#query-rules--routing)
5. [Connection Pooling](#connection-pooling)
6. [Sysadmin Operations](#sysadmin-operations)
7. [Security](#security)
8. [Monitoring & Stats](#monitoring--stats)
9. [Backup & Restore](#backup--restore)
10. [Troubleshooting & Tools](#troubleshooting--tools)
11. [Logrotate Configuration](#logrotate-configuration)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Ubuntu/Debian — Official repo / Официальный репозиторий
curl -fsSL https://repo.proxysql.com/ProxySQL/proxysql-2.x/repo_pub_key \
    | sudo apt-key add -
echo "deb https://repo.proxysql.com/ProxySQL/proxysql-2.x/$(lsb_release -sc)/ ./" \
    | sudo tee /etc/apt/sources.list.d/proxysql.list
sudo apt update && sudo apt install -y proxysql2     # Install ProxySQL 2.x / Установка ProxySQL 2.x

# RHEL/AlmaLinux/Rocky / RHEL-дистрибутивы
cat <<EOF | sudo tee /etc/yum.repos.d/proxysql.repo
[proxysql]
name=ProxySQL Repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.x/centos/\$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.x/repo_pub_key
EOF
sudo dnf install -y proxysql2                        # Install ProxySQL 2.x / Установка ProxySQL 2.x
```

> [!TIP]
> ProxySQL 2.x is the current stable branch. Always pin to the 2.x repo for production use.

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `6032` | Admin interface (MySQL protocol) / Интерфейс администратора |
| `6033` | MySQL traffic proxy port / Порт проксирования MySQL |
| `6070` | REST API / HTTP Stats (ProxySQL 2.1+) |

### Configuration Files / Файлы конфигурации

| File / Файл | Purpose / Назначение |
|-------------|----------------------|
| `/etc/proxysql.cnf` | Bootstrap config (read once on first start) / Начальная конфигурация |
| `/var/lib/proxysql/proxysql.db` | SQLite runtime database (persisted config) / Рабочая БД |
| `/var/lib/proxysql/proxysql_stats.db` | Statistics database / База статистики |

> [!IMPORTANT]
> Once `/var/lib/proxysql/proxysql.db` exists, ProxySQL **ignores** `/etc/proxysql.cnf` on restart. All config changes must be made via the Admin interface and saved with `SAVE ... TO DISK`.

### Bootstrap Config / Начальная конфигурация

`/etc/proxysql.cnf`

```ini
datadir="/var/lib/proxysql"
errorlog="/var/log/proxysql/proxysql.log"

admin_variables=
{
    admin_credentials="<ADMIN_USER>:<ADMIN_PASSWORD>"  # Admin credentials / Учётные данные администратора
    mysql_ifaces="127.0.0.1:6032"                      # Admin listen address / Адрес прослушивания admin
    refresh_interval=2000
    web_enabled=true                                   # Enable REST stats API / Включить REST API
    web_port=6070
}

mysql_variables=
{
    threads=4                         # Worker threads / Рабочие потоки
    max_connections=2048              # Max client connections / Максимум клиентских подключений
    default_query_delay=0
    default_query_timeout=36000000
    poll_timeout=2000
    interfaces="0.0.0.0:6033"        # MySQL proxy listen / Адрес проксирования MySQL
    default_schema="information_schema"
    stacksize=1048576
    server_version="8.0.27"          # Version reported to clients / Версия, видимая клиентам
    connect_timeout_server=3000
    monitor_username="<MONITOR_USER>"
    monitor_password="<MONITOR_PASSWORD>"
    monitor_history=600000
    monitor_connect_interval=60000
    monitor_ping_interval=10000
    monitor_read_only_interval=1500
    monitor_read_only_timeout=500
    ping_interval_server_msec=120000
    ping_timeout_server=500
    sessions_sort=true
    ssl_p2s_ca=""
    ssl_p2s_cert=""
    ssl_p2s_key=""
    ssl_p2s_verify_peer=false
}

mysql_replication_hostgroups=
(
    { writer_hostgroup=10, reader_hostgroup=20, comment="MySQL HA Group" }
)

mysql_servers=
(
    { address="<IP_MASTER>", port=3306, hostgroup_id=10, max_connections=100 },
    { address="<IP_REPLICA1>", port=3306, hostgroup_id=20, max_connections=100 },
    { address="<IP_REPLICA2>", port=3306, hostgroup_id=20, max_connections=100 }
)

mysql_users=
(
    { username="<APP_USER>", password="<APP_PASSWORD>", default_hostgroup=10 }
)
```

---

## Core Management

### Connecting to Admin Interface / Подключение к интерфейсу администратора

```bash
mysql -h 127.0.0.1 -P 6032 -u <ADMIN_USER> -p<ADMIN_PASSWORD>  # Connect to ProxySQL admin / Подключиться к admin
mysql -h 127.0.0.1 -P 6033 -u <APP_USER> -p<APP_PASSWORD>      # Connect as app user (proxied) / Подключиться как приложение
```

### Config Layer Explanation / Уровни конфигурации

ProxySQL uses a **3-layer config model** / ProxySQL использует **3 уровня конфигурации**:

| Layer / Уровень | Description / Описание | Persistence / Сохранение |
|-----------------|------------------------|--------------------------|
| **RUNTIME** | Active in-memory config / Активная конфигурация в памяти | Lost on restart / Сбрасывается при рестарте |
| **MEMORY** | Staging area (edited via Admin SQL) / Промежуточный слой | Lost on restart / Сбрасывается при рестарте |
| **DISK** | Persisted to SQLite DB / Сохранено в SQLite | Survives restart / Переживает рестарт |

```sql
-- Promote MEMORY → RUNTIME (apply changes) / Применить изменения из памяти
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
LOAD MYSQL VARIABLES TO RUNTIME;

-- Persist MEMORY → DISK (survive restart) / Сохранить на диск
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
SAVE MYSQL VARIABLES TO DISK;
```

> [!WARNING]
> Forgetting `SAVE ... TO DISK` means all changes are **lost on restart**. Always run both LOAD and SAVE after every config change in production.

---

## Backends & Hostgroups

### Hostgroup Concept / Концепция Hostgroup

Hostgroups are logical groups of MySQL servers. Traffic is routed to a hostgroup based on users, query rules, or replication topology.

| Hostgroup ID | Typical Role / Типичная роль |
|---|---|
| `10` | Writer / Primary — writes go here / Запись — сюда идут записи |
| `20` | Reader / Replica — reads go here / Чтение — сюда идут чтения |

### Managing MySQL Servers / Управление MySQL серверами

```sql
-- Add backend server / Добавить backend сервер
INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_connections, weight, comment)
VALUES (10, '<IP_MASTER>', 3306, 200, 1000, 'primary');

INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_connections, weight, comment)
VALUES (20, '<IP_REPLICA1>', 3306, 200, 500, 'replica-1');

INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_connections, weight, comment)
VALUES (20, '<IP_REPLICA2>', 3306, 200, 500, 'replica-2');

-- List all servers / Список всех серверов
SELECT hostgroup_id, hostname, port, status, weight, max_connections, comment
FROM mysql_servers;

-- Temporarily take a server offline / Временно вывести сервер из эксплуатации
UPDATE mysql_servers SET status='OFFLINE_SOFT' WHERE hostname='<IP_REPLICA1>';

-- Remove a server / Удалить сервер
DELETE FROM mysql_servers WHERE hostname='<IP_MASTER>' AND hostgroup_id=10;

-- Apply changes / Применить изменения
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Server Status Values / Значения статуса серверов

| Status / Статус | Meaning / Значение |
|---|---|
| `ONLINE` | Accepts connections normally / Принимает подключения |
| `SHUNNED` | Temporarily excluded (auto, too many errors) / Временно исключён |
| `OFFLINE_SOFT` | Drains existing connections, no new ones / Дожидается завершения сессий |
| `OFFLINE_HARD` | Immediately kills all connections / Немедленно убивает все соединения |

> [!CAUTION]
> `OFFLINE_HARD` immediately kills all active connections to that backend. Use `OFFLINE_SOFT` in production to allow graceful drain.

### Replication Hostgroups / Группы репликации

```sql
-- Auto-detect writer/reader based on read_only variable / Авто-определение writer/reader по read_only
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup, comment)
VALUES (10, 20, 'Primary-Replica Setup');

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Galera / PXC Hostgroups (ProxySQL 2.x)

```sql
-- Galera cluster group / Группа кластера Galera
INSERT INTO mysql_galera_hostgroups
    (writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup,
     max_writers, writer_is_also_reader, max_transactions_behind)
VALUES (10, 30, 20, 40, 1, 2, 100);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

---

## Query Rules & Routing

### Query Routing Concept / Концепция маршрутизации запросов

| Rule Priority / Приоритет | Use Case / Применение |
|---|---|
| Lower `rule_id` = processed first / Меньший `rule_id` = обрабатывается первым | Order rules from most specific to most general |

### Common Query Rules / Типичные правила маршрутизации

```sql
-- Route SELECT (reads) to replicas (hostgroup 20) / Направить SELECT на реплики
INSERT INTO mysql_query_rules
    (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (10, 1, '^SELECT', 20, 1);

-- Route SELECT FOR UPDATE to writer (hostgroup 10) / SELECT FOR UPDATE — на мастер
INSERT INTO mysql_query_rules
    (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (5, 1, '^SELECT.*FOR UPDATE', 10, 1);

-- Route specific table to writer / Конкретную таблицу — на мастер
INSERT INTO mysql_query_rules
    (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (20, 1, '^SELECT.*FROM orders', 10, 1);

-- Catch-all default (writes to writer) / По умолчанию — на мастер (запись)
INSERT INTO mysql_query_rules
    (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (100, 1, '.*', 10, 1);

-- Apply and persist / Применить и сохранить
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Query Rules Field Reference / Поля правил запросов

| Field / Поле | Description / Описание |
|---|---|
| `rule_id` | Processing order (lower = first) / Порядок обработки |
| `active` | Enable/disable rule / Включить/выключить правило |
| `match_digest` | Regex match on normalized query / Регулярное выражение на нормализованный запрос |
| `match_pattern` | Regex match on raw query / Регулярное выражение на исходный запрос |
| `destination_hostgroup` | Target hostgroup / Целевая hostgroup |
| `cache_ttl` | Cache result TTL in ms / TTL кэша в мс |
| `apply` | Stop rule processing after match / Остановить обработку правил |
| `mirror_hostgroup` | Mirror queries to another hostgroup / Зеркалировать запросы |

### Query Cache / Кэш запросов

```sql
-- Enable query cache for specific rule (TTL=30s) / Включить кэш запросов на 30 секунд
INSERT INTO mysql_query_rules
    (rule_id, active, match_digest, cache_ttl, destination_hostgroup, apply)
VALUES (30, 1, '^SELECT.*FROM product_catalog', 30000, 20, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

> [!WARNING]
> Query cache returns **stale data**. Only cache read-heavy, rarely-updated tables. Never cache user-session or financial data.

---

## Connection Pooling

### Connection Pool Overview / Обзор пула соединений

ProxySQL uses a **multiplexing connection pool**: many client connections share fewer backend connections.

```sql
-- View connection pool status / Просмотр состояния пула соединений
SELECT * FROM stats.stats_mysql_connection_pool;

-- Key fields / Ключевые поля:
-- ConnUsed: in-use connections / используемые соединения
-- ConnFree: available connections / доступные соединения
-- ConnOK: successful new connections / успешных новых соединений
-- ConnERR: failed connections / ошибочных соединений
-- Latency_us: backend latency in microseconds / задержка до backend
```

### Tuning Pool Parameters / Настройка параметров пула

```sql
-- Set connection pool parameters per hostgroup / Настройка на hostgroup
UPDATE mysql_servers SET max_connections=300 WHERE hostgroup_id=10;
UPDATE mysql_servers SET max_connections=200 WHERE hostgroup_id=20;

-- Global max client connections / Глобальный лимит клиентских подключений
SET mysql-max_connections=4096;

-- Connection timeout tuning / Таймауты
SET mysql-connection_max_age_ms=0;          -- 0 = never expire / никогда не истекает
SET mysql-free_connections_pct=10;          -- Keep 10% free per pool / Держать 10% свободными

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

---

## Sysadmin Operations

### Service Control / Управление сервисом

```bash
sudo systemctl start proxysql          # Start service / Запустить сервис
sudo systemctl stop proxysql           # Stop service / Остановить сервис
sudo systemctl restart proxysql        # Restart service / Перезапустить сервис
sudo systemctl status proxysql         # Service status / Статус сервиса
sudo systemctl enable proxysql         # Enable on boot / Включить автозапуск
sudo systemctl reload proxysql         # Reload config (not always safe) / Перечитать конфиг
```

> [!CAUTION]
> `systemctl restart proxysql` in production will drop all active client connections. Always use `LOAD ... TO RUNTIME` for zero-downtime config changes.

### Runbook: Zero-Downtime Config Change / Изменение конфигурации без простоя

1. **Connect to admin / Подключиться к admin:**
   ```bash
   mysql -h 127.0.0.1 -P 6032 -u <ADMIN_USER> -p<ADMIN_PASSWORD>
   ```

2. **Make changes in MEMORY / Внести изменения в память:**
   ```sql
   -- Example: add new rule / Пример: добавить новое правило
   INSERT INTO mysql_query_rules (...) VALUES (...);
   ```

3. **Verify in MEMORY / Проверить в памяти:**
   ```sql
   SELECT * FROM mysql_query_rules ORDER BY rule_id;
   ```

4. **Apply to RUNTIME (zero-downtime) / Применить без простоя:**
   ```sql
   LOAD MYSQL QUERY RULES TO RUNTIME;
   ```

5. **Persist to DISK / Сохранить на диск:**
   ```sql
   SAVE MYSQL QUERY RULES TO DISK;
   ```

### Runbook: Drain & Remove a Backend / Плавный вывод backend из эксплуатации

1. **Set server to OFFLINE_SOFT / Плавное отключение:**
   ```sql
   UPDATE mysql_servers SET status='OFFLINE_SOFT'
   WHERE hostname='<IP_REPLICA1>' AND hostgroup_id=20;
   LOAD MYSQL SERVERS TO RUNTIME;
   ```

2. **Wait for active connections to drain / Подождать завершения соединений:**
   ```sql
   SELECT srv_host, ConnUsed, ConnFree
   FROM stats.stats_mysql_connection_pool
   WHERE srv_host='<IP_REPLICA1>';
   -- Wait until ConnUsed=0 / Подождать ConnUsed=0
   ```

3. **Remove server / Удалить сервер:**
   ```sql
   DELETE FROM mysql_servers WHERE hostname='<IP_REPLICA1>';
   LOAD MYSQL SERVERS TO RUNTIME;
   SAVE MYSQL SERVERS TO DISK;
   ```

### Logs & Paths / Логи и пути

| Type / Тип | Path / Путь |
|------------|-------------|
| Error Log / Ошибки | `/var/log/proxysql/proxysql.log` |
| Data Directory / Данные | `/var/lib/proxysql/` |
| Runtime DB / Рабочая БД | `/var/lib/proxysql/proxysql.db` |
| Stats DB / База статистики | `/var/lib/proxysql/proxysql_stats.db` |
| Bootstrap Config / Начальный конфиг | `/etc/proxysql.cnf` |

### Network & Firewall / Сеть и брандмауэр

```bash
# Default ports: 6032 (admin), 6033 (proxy), 6070 (REST stats)

# UFW / UFW
sudo ufw allow 6033/tcp                                    # Allow app traffic / Трафик приложения
sudo ufw allow 6032/tcp                                    # Allow admin (restrict to trusted IPs!) / Admin — только доверенные IP!

# firewalld / firewalld
sudo firewall-cmd --permanent --add-port=6033/tcp && sudo firewall-cmd --reload
sudo firewall-cmd --permanent --add-port=6032/tcp && sudo firewall-cmd --reload
```

> [!WARNING]
> **NEVER** expose port 6032 (admin) to the public internet. Restrict it to management networks with firewall rules.

---

## Security

### Monitor User Setup / Настройка пользователя мониторинга

ProxySQL requires a **dedicated monitor user** on all MySQL backends to check health.

```sql
-- On each MySQL backend (run as root) / На каждом MySQL backend (от root)
CREATE USER '<MONITOR_USER>'@'%' IDENTIFIED BY '<MONITOR_PASSWORD>';
GRANT USAGE, REPLICATION CLIENT ON *.* TO '<MONITOR_USER>'@'%';
FLUSH PRIVILEGES;
```

```sql
-- In ProxySQL admin / В ProxySQL admin
SET mysql-monitor_username='<MONITOR_USER>';
SET mysql-monitor_password='<MONITOR_PASSWORD>';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

### Application User Management / Управление пользователями приложения

```sql
-- Add app user (must match MySQL backend user) / Добавить пользователя приложения
INSERT INTO mysql_users (username, password, default_hostgroup, max_connections, comment)
VALUES ('<APP_USER>', '<APP_PASSWORD>', 10, 200, 'main application user');

-- Verify / Проверить
SELECT username, default_hostgroup, max_connections, active FROM mysql_users;

-- Apply / Применить
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

> [!IMPORTANT]
> The user credentials in `mysql_users` must exactly match those on the MySQL backends. ProxySQL forwards the auth to the backend and must authenticate successfully.

### Admin Credentials Update / Обновление учётных данных администратора

```sql
-- Update admin password / Обновить пароль администратора
SET admin-admin_credentials='<ADMIN_USER>:<NEW_PASSWORD>';
LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;
```

### SSL/TLS to Backends / SSL/TLS до backend серверов

`/etc/proxysql.cnf`

```ini
mysql_variables=
{
    ssl_p2s_ca="/etc/proxysql/ca.pem"
    ssl_p2s_cert="/etc/proxysql/client-cert.pem"
    ssl_p2s_key="/etc/proxysql/client-key.pem"
    ssl_p2s_verify_peer=true
}
```

```sql
-- Per-server SSL override / SSL для отдельного сервера
UPDATE mysql_servers SET use_ssl=1 WHERE hostname='<IP_MASTER>';
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

---

## Monitoring & Stats

### Key Stats Tables / Ключевые таблицы статистики

> All stats are in the `stats` schema within the admin interface.

```sql
-- Global query stats (by digest) / Глобальная статистика запросов
SELECT hostgroup, schemaname, digest_text,
       count_star, sum_time, min_time, max_time
FROM stats.stats_mysql_query_digest
ORDER BY sum_time DESC
LIMIT 20;                                                  -- Top slow queries / Топ медленных запросов

-- Connection pool stats / Статистика пула соединений
SELECT hostgroup, srv_host, srv_port,
       status, ConnUsed, ConnFree, ConnOK, ConnERR, Latency_us
FROM stats.stats_mysql_connection_pool;

-- Global status counters / Глобальные счётчики
SELECT * FROM stats.stats_mysql_global;

-- Active sessions / Активные сессии
SELECT * FROM stats.stats_mysql_processlist;

-- Monitor results (backend health checks) / Результаты мониторинга backend
SELECT hostname, port, time_start_us, connect_success_time_us, ping_success_time_us
FROM monitor.mysql_server_connect_log
ORDER BY time_start_us DESC LIMIT 20;

SELECT hostname, port, time_start_us, read_only, error
FROM monitor.mysql_server_read_only_log
ORDER BY time_start_us DESC LIMIT 20;
```

### Query Digest Analysis / Анализ дайджестов запросов

```sql
-- Reset query digest stats / Сбросить статистику дайджестов
SELECT * FROM stats.stats_mysql_query_digest_reset LIMIT 1;

-- Find queries routing to wrong hostgroup / Найти запросы на неверной hostgroup
SELECT hostgroup, digest_text, count_star
FROM stats.stats_mysql_query_digest
WHERE hostgroup NOT IN (10, 20)
ORDER BY count_star DESC;

-- Cache hit analysis / Анализ попаданий в кэш
SELECT sum(cache_count_get), sum(cache_count_set), sum(cache_bytes_in), sum(cache_bytes_out)
FROM stats.stats_mysql_global
WHERE variable_name LIKE 'Query_Cache%';
```

### Backend Health / Состояние backend серверов

```sql
-- Check backend health status / Проверить состояние backend серверов
SELECT hostgroup_id, hostname, port, status, weight, max_connections
FROM mysql_servers;

-- Monitor connectivity errors / Ошибки подключения к backend
SELECT hostname, port, connect_error
FROM monitor.mysql_server_connect_log
WHERE connect_error IS NOT NULL
ORDER BY time_start_us DESC LIMIT 10;
```

---

## Backup & Restore

### Backup Methods Comparison / Сравнение методов резервирования

| Method / Метод | What / Что | Notes / Примечания |
|---|---|---|
| SQLite DB copy / Копия SQLite | `/var/lib/proxysql/proxysql.db` | Full config backup / Полный бэкап конфигурации |
| Admin SQL export / Экспорт SQL | `mysqldump` via admin port 6032 | Can script individual tables / Можно выгрузить отдельные таблицы |
| `/etc/proxysql.cnf` export | Manual recreation / Ручное воссоздание | Use only for initial bootstrap / Только для первого запуска |

### Runbook: Backup ProxySQL Config / Резервное копирование конфигурации

```bash
# 1. Stop service before copying SQLite DB / Остановить перед копированием SQLite
sudo systemctl stop proxysql

# 2. Backup the SQLite runtime DB / Резервная копия рабочей БД
sudo cp /var/lib/proxysql/proxysql.db \
    /backup/proxysql/proxysql.db.$(date +%Y%m%d_%H%M%S)                 # Backup with timestamp / С меткой времени

# 3. Start again / Запустить снова
sudo systemctl start proxysql
```

```bash
# Hot backup via admin SQL (no downtime) / Горячий бэкап через SQL (без простоя)
mysql -h 127.0.0.1 -P 6032 -u <ADMIN_USER> -p<ADMIN_PASSWORD> \
    -e "SAVE MYSQL SERVERS TO DISK; SAVE MYSQL USERS TO DISK; \
        SAVE MYSQL QUERY RULES TO DISK; SAVE MYSQL VARIABLES TO DISK;"
sudo cp /var/lib/proxysql/proxysql.db /backup/proxysql/proxysql.db.$(date +%Y%m%d)
```

### Runbook: Restore ProxySQL Config / Восстановление конфигурации

```bash
# 1. Stop service / Остановить сервис
sudo systemctl stop proxysql

# 2. Replace SQLite DB with backup / Заменить рабочую БД резервной копией
sudo cp /backup/proxysql/proxysql.db.<TIMESTAMP> /var/lib/proxysql/proxysql.db

# 3. Start service / Запустить сервис
sudo systemctl start proxysql

# 4. Verify config loaded correctly / Проверить загрузку конфигурации
mysql -h 127.0.0.1 -P 6032 -u <ADMIN_USER> -p<ADMIN_PASSWORD> \
    -e "SELECT hostgroup_id, hostname, port, status FROM mysql_servers;"
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

#### Backend unreachable / Backend недоступен

```sql
-- Check connect errors / Проверить ошибки подключения
SELECT hostname, port, connect_error
FROM monitor.mysql_server_connect_log
WHERE connect_error IS NOT NULL
ORDER BY time_start_us DESC LIMIT 20;

-- Check monitor credentials / Проверить учётные данные мониторинга
SHOW VARIABLES LIKE 'mysql-monitor%';
```

#### All traffic going to writer, reads not routed / Весь трафик на мастер

```sql
-- Check if read rules are active / Проверить активность правил чтения
SELECT rule_id, active, match_digest, destination_hostgroup, apply
FROM mysql_query_rules
WHERE active=1
ORDER BY rule_id;

-- Check if replicas are online / Проверить, что реплики онлайн
SELECT hostgroup_id, hostname, port, status FROM mysql_servers WHERE hostgroup_id=20;
```

#### High connection count / Большое количество соединений

```sql
-- Find top connection consumers / Найти потребителей соединений
SELECT user, db, count(*) FROM stats.stats_mysql_processlist GROUP BY user, db;

-- Check connection pool utilization / Использование пула
SELECT hostgroup, srv_host, ConnUsed, ConnFree,
       ROUND(ConnUsed*100.0/(ConnUsed+ConnFree),1) AS used_pct
FROM stats.stats_mysql_connection_pool;
```

#### Slow queries / Медленные запросы

```sql
-- Top queries by total time / Топ запросов по суммарному времени
SELECT hostgroup, digest_text,
       count_star,
       ROUND(sum_time/1000000.0, 2) AS total_sec,
       ROUND(sum_time/count_star/1000.0, 2) AS avg_ms
FROM stats.stats_mysql_query_digest
ORDER BY sum_time DESC
LIMIT 20;
```

### Useful Admin Commands / Полезные команды администратора

```sql
-- Show all running queries / Все активные запросы
SELECT * FROM stats.stats_mysql_processlist;

-- Kill a session / Завершить сессию
PROXYSQL KILL <SESSION_ID>;

-- Reload config from disk (e.g. after manual SQLite edit) / Перечитать конфиг с диска
LOAD MYSQL SERVERS FROM DISK;
LOAD MYSQL USERS FROM DISK;
LOAD MYSQL QUERY RULES FROM DISK;
LOAD MYSQL VARIABLES FROM DISK;

-- Check ProxySQL version / Версия ProxySQL
SELECT @@version;

-- Show all global variables / Все глобальные переменные
SELECT * FROM global_variables;
```

### ProxySQL CLI Utility / Утилита proxysql

```bash
# Reload/reinitialize from config file (deletes proxysql.db!) / Пересоздать БД из конфига
# WARNING: Destructive! All DISK config will be replaced / ВНИМАНИЕ: Удаляет текущую конфигурацию
sudo proxysql --initial -c /etc/proxysql.cnf                 # Reinit from proxysql.cnf / Пересоздать из proxysql.cnf

# Start in foreground for debugging / Запустить на переднем плане для отладки
sudo proxysql --foreground -D /var/lib/proxysql               # Foreground mode / Режим переднего плана
```

> [!CAUTION]
> `proxysql --initial` deletes the existing `proxysql.db` and rebuilds from `/etc/proxysql.cnf`. This **erases all runtime changes** not backed up first.

---

## Logrotate Configuration

`/etc/logrotate.d/proxysql`

```conf
/var/log/proxysql/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 proxysql proxysql
    sharedscripts
    postrotate
        systemctl reload proxysql > /dev/null 2>&1 || true
    endscript
}
```

> [!TIP]
> ProxySQL reopens its log file on `SIGHUP`, which `systemctl reload proxysql` triggers. You can also run `kill -HUP $(pidof proxysql)` if reload is not available.
