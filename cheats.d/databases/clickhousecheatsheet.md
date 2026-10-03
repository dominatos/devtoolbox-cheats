---
Title: 📊 ClickHouse — Columnar OLAP
Group: Databases
Icon: 📊
Order: 7
tags:
  - databases
  - sysadmin
  - linux
---

---

> **ClickHouse** is an open-source, column-oriented OLAP (Online Analytical Processing) database management system designed for real-time analytical queries on large datasets. Originally developed at Yandex (open-sourced in 2016), it is now maintained by **ClickHouse, Inc.** with major contributions from **Altinity**. It uses vectorized query execution, sparse primary indexes, and massively parallel processing to scan billions of rows per second on a single node.
>
> **Common use cases / Типичные сценарии:** Web/user behavior analytics, real-time dashboards and reporting, observability & metrics (logs, traces), event data pipelines, IoT time-series, financial analytics, ad-tech, A/B testing, security analytics.
>
> **Status / Статус:** Actively developed (monthly releases; current stable: 25.x). Apache 2.0 licensed. **Not an OLTP replacement** — writes are optimized for bulk inserts, not row-level transactions. Managed options: **ClickHouse Cloud**, **Altinity**. Alternatives for similar workloads: **Apache Doris**, **Apache Druid**, **Apache Pinot**, **StarRocks**, **TimescaleDB** (time-series on PostgreSQL), cloud warehouses (**BigQuery**, **Snowflake**, **Redshift**).
>
> **Default ports / Порты по умолчанию:** `8123/tcp` (HTTP), `8443/tcp` (HTTPS), `9000/tcp` (native TCP), `9440/tcp` (native TCP+SSL), `9009/tcp` (inter-server replication), `9181/tcp` (ClickHouse Keeper)

---

## 📚 Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Table Engines](#Table%20Engines)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Security](#Security)
- [Backup & Restore](#Backup%20&%20Restore)
- [Replication & Keeper](#Replication%20&%20Keeper)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Logrotate Configuration](#Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

### Package Installation

```bash
# Ubuntu/Debian — official repo
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update && sudo apt-get install -y clickhouse-server clickhouse-client

# RHEL/AlmaLinux/Rocky — official repo
sudo yum install -y https://packages.clickhouse.com/rpm/lts/clickhouse-server-latest.rpm
sudo yum install -y clickhouse-client clickhouse-common-static

# Quick install (official script)
curl https://clickhouse.com/ | sh
./clickhouse install

# Docker (server)
docker run -d --name clickhouse-server \
  -p 8123:8123 -p 9000:9000 -p 9009:9009 \
  -v clickhouse-data:/var/lib/clickhouse \
  -v clickhouse-logs:/var/log/clickhouse-server \
  -e CLICKHOUSE_DB=<DB> -e CLICKHOUSE_USER=<USER> -e CLICKHOUSE_PASSWORD=<PASSWORD> \
  clickhouse/clickhouse-server
```

### Default Ports

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `8123` | HTTP interface / HTTP-интерфейс |
| `8443` | HTTPS interface / HTTPS-интерфейс |
| `9000` | Native TCP protocol / Нативный TCP-протокол |
| `9440` | Native TCP with SSL / Нативный TCP с SSL |
| `9009` | Inter-server replication / Межсерверная репликация |
| `9181` | ClickHouse Keeper / ClickHouse Keeper |

### Configuration Files

| OS / ОС | Config Path / Путь конфигурации |
|---------|-------------------------------|
| All | `/etc/clickhouse-server/config.xml` |
| All | `/etc/clickhouse-server/users.xml` |
| All (overrides) | `/etc/clickhouse-server/config.d/*.xml` |
| All (user overrides) | `/etc/clickhouse-server/users.d/*.xml` |
| Preprocessed | `/etc/clickhouse-server/preprocessed_configs/` |

### Main Configuration

`/etc/clickhouse-server/config.xml`

```xml
<clickhouse>
    <!-- Network / Сеть -->
    <listen_host>::</listen_host>
    <listen_port>9000</listen_port>
    <http_port>8123</http_port>
    <tcp_port_secure>9440</tcp_port_secure>
    <interserver_http_port>9009</interserver_http_port>

    <!-- Paths / Пути -->
    <path>/var/lib/clickhouse/</path>
    <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
    <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
    <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>

    <!-- Logging / Логирование -->
    <logger>
        <level>warning</level>
        <log>/var/log/clickhouse-server/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
        <size>1000M</size>
        <count>10</count>
        <console>1</console>
    </logger>

    <!-- Limits / Лимиты -->
    <max_concurrent_queries>100</max_concurrent_queries>
    <max_memory_usage>10000000000</max_memory_usage>
    <mark_cache_size>5368709120</mark_cache_size>
    <uncompressed_cache_size>8589934592</uncompressed_cache_size>
    <compiled_expression_cache_size>134217728</compiled_expression_cache_size>

    <!-- Background / Фоновые процессы -->
    <background_pool_size>16</background_pool_size>
    <background_merges_mutations_concurrency_ratio>4</background_merges_mutations_concurrency_ratio>
    <max_replicated_merges_in_queue>100</max_replicated_merges_in_queue>

    <!-- Async insert / Асинхронная вставка -->
    <async_insert>1</async_insert>
    <wait_for_async_insert>1</wait_for_async_insert>
    <async_insert_max_data_size>10485760</async_insert_max_data_size>
    <async_insert_busy_timeout_ms>200</async_insert_busy_timeout_ms>

    <!-- TLS (optional) / TLS (опционально) -->
    <!--
    <https_port>8443</https_port>
    <openSSL>
        <server>
            <certificateFile>/etc/clickhouse-server/server.crt</certificateFile>
            <privateKeyFile>/etc/clickhouse-server/server.key</privateKeyFile>
        </server>
    </openSSL>
    -->

    <!-- Embedded Keeper (optional) / Встроенный Keeper (опционально) -->
    <keeper_server>
        <tcp_port>9181</tcp_port>
        <server_id>1</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshot</snapshot_storage_path>
    </keeper_server>
</clickhouse>
```

### Users & Profiles

`/etc/clickhouse-server/users.xml`

```xml
<clickhouse>
    <profiles>
        <default>
            <max_memory_usage>10000000000</max_memory_usage>
            <use_uncompressed_cache>0</use_uncompressed_cache>
            <load_balancing>random</load_balancing>
            <max_execution_time>60</max_execution_time>
        </default>
        <readonly>
            <readonly>1</readonly>
        </readonly>
    </profiles>

    <quotas>
        <default>
            <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
            </interval>
        </default>
    </quotas>

    <users>
        <default>
            <password></password>
            <networks>
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
            <access_management>1</access_management>
        </default>
        <admin>
            <password><PASSWORD></password>
            <networks>
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
            <access_management>1</access_management>
        </admin>
    </users>
</clickhouse>
```

> [!WARNING]
> The default `default` user ships with an **empty password**. Always set a password or disable remote access for `default` before exposing ClickHouse to a network.
> Пользователь `default` по умолчанию имеет **пустой пароль**. Всегда задавайте пароль или блокируйте удалённый доступ, прежде чем открывать ClickHouse в сеть.

### System Tuning

`/etc/sysctl.d/99-clickhouse.conf`

```bash
vm.swappiness = 1                          # Prefer RAM over swap / Отдавать предпочтение RAM
fs.file-max = 2097152                      # Open file limit / Лимит открытых файлов
net.core.somaxconn = 4096                  # Listen backlog / Очередь соединений
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_tw_reuse = 1
```

```bash
sudo sysctl --system                                             # Apply sysctl / Применить
```

`/etc/security/limits.d/99-clickhouse.conf`

```bash
clickhouse soft nofile 262144
clickhouse hard nofile 262144
clickhouse soft nproc 65536
clickhouse hard nproc 65536
clickhouse soft memlock unlimited
clickhouse hard memlock unlimited
```

`/etc/systemd/system/clickhouse-server.service.d/override.conf`

```ini
[Service]
LimitNOFILE=262144
LimitNPROC=65536
LimitMEMLOCK=infinity
```

```bash
sudo systemctl daemon-reload                                    # Reload systemd / Перезагрузить systemd
```

---

## Core Management

### Connection

```bash
clickhouse-client                                                                    # Connect locally / Локальное подключение
clickhouse-client -h <HOST> -u <USER> --password '<PASSWORD>'                        # Connect with auth / С авторизацией
clickhouse-client --host <HOST> --port 9000 --user <USER> --password '<PASSWORD>'   # Explicit params / Явные параметры
clickhouse-client --secure                                                            # Native over SSL / Нативный с SSL
clickhouse-client -q "SELECT 1"                                                       # Run one query / Одиночный запрос
clickhouse-client --query "SHOW TABLES" --format Pretty                               # With format / С форматом вывода
clickhouse-local --query "SELECT 1"                                                   # Local mode (no server) / Локальный режим
```

**HTTP interface / HTTP-интерфейс:**

```bash
curl "http://<HOST>:8123/?query=SELECT%201"                                          # Simple HTTP query / Простой HTTP-запрос
curl "http://<HOST>:8123/" --data "SHOW TABLES"                                       # POST query / Запрос через POST
curl "http://<HOST>:8123/?user=<USER>&password=<PASSWORD>&query=SELECT%201"          # With auth / С авторизацией
curl "http://<HOST>:8123/?query=SELECT%201&default_format=TSV"                        # Output format / Формат вывода
```

### Databases & Tables

```sql
SHOW DATABASES;                                                                       -- List databases / Список баз
CREATE DATABASE IF NOT EXISTS <DB>;                                                   -- Create database / Создать базу
USE <DB>;                                                                             -- Switch database / Переключиться на базу
SHOW TABLES FROM <DB>;                                                                -- List tables / Список таблиц
SHOW TABLES LIKE '%events%';                                                          -- Filter tables / Фильтр таблиц
DESCRIBE TABLE <DB>.<TABLE>;                                                          -- Describe table / Описание таблицы
SHOW CREATE TABLE <DB>.<TABLE>;                                                       -- DDL statement / DDL-выражение
EXISTS TABLE <DB>.<TABLE>;                                                            -- Check existence / Проверить существование
DROP DATABASE IF EXISTS <DB>;                                                         -- Delete database / Удалить базу
```

### Table Creation (MergeTree)

```sql
CREATE TABLE IF NOT EXISTS <DB>.events
(
    event_date    Date,
    event_time    DateTime64(3),
    user_id       UInt64,
    event_type    LowCardinality(String),
    page          String,
    revenue       Decimal64(2),
    properties    String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_type, event_date, user_id)
SETTINGS index_granularity = 8192;

-- Insert / Вставка
INSERT INTO <DB>.events (event_date, event_time, user_id, event_type, page, revenue)
VALUES ('2025-01-15', '2025-01-15 10:00:00.000', 42, 'click', '/home', 1.50);

-- Batch insert from file / Пакетная вставка из файла
INSERT INTO <DB>.events FORMAT CSVWithNames;     -- Reads from stdin / Читает из stdin
```

### CRUD Operations

```sql
SELECT count() FROM <DB>.events;                                                     -- Count rows / Подсчёт строк
SELECT * FROM <DB>.events WHERE event_type = 'click' LIMIT 10;                       -- Filter + limit / Фильтр + лимит
SELECT event_type, count() AS cnt, sum(revenue) AS total
FROM <DB>.events
GROUP BY event_type
ORDER BY cnt DESC;                                                                   -- Aggregation / Агрегация

UPDATE <DB>.events SET revenue = 0 WHERE event_date < '2024-01-01';                  -- Async mutation / Асинхронная мутация
DELETE FROM <DB>.events WHERE event_date < '2024-01-01';                             -- Lightweight delete (24.3+) / Лёгкое удаление
TRUNCATE TABLE <DB>.events;                                                         -- Remove all rows / Удалить все строки
DROP TABLE IF EXISTS <DB>.events;                                                   -- Drop table / Удалить таблицу
```

> [!WARNING]
> `UPDATE` and `DELETE` in ClickHouse are **mutations** — they rewrite data parts in the background and are not instant. Prefer lightweight deletes for large tables, and avoid frequent point updates.
> `UPDATE` и `DELETE` в ClickHouse — это **мутации**: они перезаписывают части данных в фоне и не выполняются мгновенно. Избегайте частых точечных обновлений.

### Table Alterations

```sql
ALTER TABLE <DB>.events ADD COLUMN app_version String DEFAULT '0.0.0';             -- Add column / Добавить колонку
ALTER TABLE <DB>.events DROP COLUMN app_version;                                    -- Drop column / Удалить колонку
ALTER TABLE <DB>.events RENAME COLUMN page TO path;                                 -- Rename column / Переименовать колонку
ALTER TABLE <DB>.events MODIFY COLUMN revenue Float64;                             -- Change type (careful!) / Сменить тип (осторожно!)
ALTER TABLE <DB>.events MATERIALIZE COLUMN app_version;                            -- Materialize DEFAULT/ALIAS / Материализовать
ALTER TABLE <DB>.events REMOVE COLUMN app_version;                                 -- Remove metadata / Удалить метаданные

ALTER TABLE <DB>.events MOVE PARTITION TO TABLE <DB>.events_archive;               -- Move partition / Переместить партицию
ALTER TABLE <DB>.events FETCH PARTITION '202501' FROM '<REPLICA_HOST>';            -- Fetch partition / Забрать партицию с реплики
ALTER TABLE <DB>.events FREEZE PARTITION '202501';                                 -- Hard-link snapshot / Снимок жёсткой ссылкой
ALTER TABLE <DB>.events DELETE WHERE event_date < '2024-01-01';                    -- Mutation delete / Мутационное удаление
OPTIMIZE TABLE <DB>.events FINAL;                                                  -- Force merge / Принудительное слияние
```

### Query Management

```sql
SHOW PROCESSLIST;                                                                  -- Active queries / Активные запросы
SELECT query_id, user, elapsed, formatReadableSize(memory_usage) AS mem, query
FROM system.processes ORDER BY elapsed DESC;                                       -- Top long queries / Долгие запросы
KILL QUERY WHERE query_id = '<QUERY_ID>';                                          -- Cancel query / Отменить запрос
KILL MUTATION WHERE mutation_id = '<MUTATION_ID>';                                 -- Kill mutation / Убить мутацию
KILL QUERIES WHERE user = '<USER>' FORMAT Null;                                    -- Kill user queries / Убить запросы пользователя
```

---

## Table Engines

### MergeTree Family Comparison

| Engine / Движок | Description (EN / RU) | Use Case / Best for / Применение |
|-----------------|----------------------|----------------------------------|
| `MergeTree` | Base engine; ordered parts, background merges / Базовый; упорядоченные части, фоновые слияния | Large analytical tables / Крупные аналитические таблицы |
| `ReplacingMergeTree` | Dedup by `ORDER BY` key, keeps last (or by `ver`) / Дедупликация по ключу, хранит последнюю (или по версии) | Event logs with duplicates / Логи событий с дублями |
| `AggregatingMergeTree` | Stores `AggState` for incremental aggregation / Хранит агрегатные состояния | Materialized views, rollups / Мат. представления, сводки |
| `SummingMergeTree` | Sums numeric columns by `ORDER BY` key / Суммирует числовые колонки по ключу | Counters, metrics rollups / Счётчики, метрики |
| `CollapsingMergeTree` | Insert/cancel rows via `sign` column (+1/-1) / Вставка/отмена строк через `sign` | Event streams with corrections / Потоки событий с коррекциями |
| `VersionedCollapsingMergeTree` | Collapsing with `version` column for correct order / Сворачивание с колонкой `version` | Out-of-order event arrival / Прибытие событий вне порядка |
| `ReplicatedMergeTree` family | All above + Keeper-based replication / Все выше + репликация на базе Keeper | HA clusters / Кластеры с высокой доступностью |

> **Why different engines / Почему разные движки:** MergeTree itself never deduplicates — that is intentional for write throughput. `ReplacingMergeTree` trades some write amplification for read-side dedup. `AggregatingMergeTree` stores pre-aggregated states so dashboards query small rollup tables instead of raw events. Choose the engine by the **write pattern**, not by habit.

### Other Engines

| Engine / Движок | Description (EN / RU) | Use Case / Best for / Применение |
|-----------------|----------------------|----------------------------------|
| `Distributed` | Virtual table routing to shards/replicas / Виртуальная таблица с маршрутизацией по шардам/репликам | Transparent sharding / Прозрачное шардирование |
| `MaterializedView` | Stored query that runs on INSERT / Сохранённый запрос, выполняется при INSERT | Incremental rollups / Инкрементальные сводки |
| `Buffer` | Buffers inserts in RAM, flushes to target / Буферизует вставки в RAM, сбрасывает в целевую таблицу | Smoothing write bursts / Сглаживание пиков записи |
| `Memory` | Data in RAM only; lost on restart / Только в RAM; теряется при рестарте | Temp tables, joins / Временные таблицы, джойны |
| `Log` / `TinyLog` / `StripeLog` | Simple append-only, no merges / Простые append-only, без слияний | Small reference data / Небольшие справочные данные |
| `KeeperMap` | Key-value on top of Keeper / Ключ-значение поверх Keeper | Small config-like datasets / Небольшие конфигурационные данные |
| `File` / `S3` / `HDFS` | Read external files directly / Чтение внешних файлов напрямую | Data lakes, staging / Озёра данных, staging |
| `MySQL` / `PostgreSQL` / `SQLite` | External DB table functions/engines / Внешние БД через табличные функции/движки | Federated reads / Федеративное чтение |
| `Iceberg` / `DeltaLake` / `Hudi` | Open table format integrations / Интеграция с открытыми форматами таблиц | Lakehouse / Озеро-дом (lakehouse) |

### MergeTree Design Parameters

```sql
-- ORDER BY / PRIMARY KEY — sort key defines sparse index granularity
ORDER BY (event_type, event_date, user_id)

-- PARTITION BY — one part directory per partition value
PARTITION BY toYYYYMM(event_date)

-- TTL — auto-expire or move data / Автоудаление или перенос данных
TTL event_date + INTERVAL 365 DAY
    DELETE, event_date + INTERVAL 400 DAY TO VOLUME 'cold'
SETTINGS storage_policy = 'hot_cold';

-- CODECS — compression per column / Сжатие по колонкам
CODECS (Delta, ZSTD(3))
CODECS (DoubleDelta, Gorilla)
CODECS (LZ4)

-- Sparse (skip) indexes / Разреженные (skip) индексы
INDEX idx_user user_id TYPE bloom_filter GRANULARITY 4
INDEX idx_page page TYPE tokenbf_v1(32768, 3, 0) GRANULARITY 4
INDEX idx_set set_name TYPE set(100) GRANULARITY 4
```

### Materialized Views

```sql
-- Incremental aggregation MV / Инкрементальная агрегация через MV
CREATE MATERIALIZED VIEW <DB>.events_daily_mv
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_type)
POPULATE AS
SELECT
    event_date,
    event_type,
    sumState(revenue)           AS revenue_state,
    countState()                AS count_state
FROM <DB>.events
GROUP BY event_date, event_type;

-- Query the rollup / Запрос сводки
SELECT
    event_date,
    event_type,
    sumMerge(revenue_state) AS revenue,
    countMerge(count_state) AS cnt
FROM <DB>.events_daily_mv
GROUP BY event_date, event_type;
```

> [!NOTE]
> `POPULATE` backfills historical data once at creation; without it the MV only sees new inserts. MVs run on a separate thread pool and can lag under heavy insert load.
> `POPULATE` однократно заполняет исторические данные; без него MV видит только новые вставки. MV выполняются в отдельном пуле потоков и могут отставать при высокой нагрузке на запись.

---

## Sysadmin Operations

### Service Control

```bash
sudo systemctl start clickhouse-server                                             # Start service / Запустить сервис
sudo systemctl stop clickhouse-server                                              # Stop service / Остановить сервис
sudo systemctl restart clickhouse-server                                           # Restart service / Перезапустить сервис
sudo systemctl status clickhouse-server                                            # Service status / Статус сервиса
sudo systemctl enable clickhouse-server                                            # Enable on boot / Включить автозапуск
sudo systemctl reload clickhouse-server                                            # Reload (sends SIGHUP) / Перезагрузить конфиг
sudo systemctl enable --now clickhouse-keeper                                      # Start Keeper if separate / Запустить Keeper (если отдельно)
```

### Logs

```bash
sudo tail -f /var/log/clickhouse-server/clickhouse-server.log                     # Main log / Основной лог
sudo tail -f /var/log/clickhouse-server/clickhouse-server.err.log                 # Error log / Лог ошибок
sudo journalctl -u clickhouse-server -f                                            # Systemd logs / Логи systemd
grep -i "error\|exception" /var/log/clickhouse-server/clickhouse-server.log       # Find errors / Найти ошибки
```

### Important Paths

```bash
/var/lib/clickhouse/                                                              # Data directory / Каталог данных
/var/lib/clickhouse/store/                                                        # Table data parts / Части данных таблиц
/var/lib/clickhouse/flags/                                                        # Server flags (read-only start) / Флаги сервера
/var/lib/clickhouse/tmp/                                                          # Temporary files / Временные файлы
/var/lib/clickhouse/user_files/                                                   # Files for file() table func / Файлы для file()
/var/lib/clickhouse/metadata/                                                     # Legacy metadata (older versions) / Устаревшие метаданные
/var/lib/clickhouse/access/                                                       # Runtime access control / Доступ (runtime)
/var/lib/clickhouse/keepervolume/                                                 # Keeper data (if embedded) / Данные Keeper
/var/log/clickhouse-server/                                                       # Log directory / Каталог логов
/etc/clickhouse-server/                                                           # Config directory / Каталог конфигурации
```

### Firewall

```bash
sudo firewall-cmd --permanent --add-port=8123/tcp                                 # HTTP / HTTP
sudo firewall-cmd --permanent --add-port=8443/tcp                                 # HTTPS / HTTPS
sudo firewall-cmd --permanent --add-port=9000/tcp                                 # Native TCP / Нативный TCP
sudo firewall-cmd --permanent --add-port=9440/tcp                                 # Native TCP+SSL / Нативный TCP+SSL
sudo firewall-cmd --permanent --add-port=9009/tcp                                 # Replication / Репликация
sudo firewall-cmd --permanent --add-port=9181/tcp                                 # Keeper / Keeper
sudo firewall-cmd --reload                                                        # Reload firewall / Перезагрузить файрвол
sudo ufw allow from <SUBNET> to any port 9000 proto tcp comment 'ClickHouse native' # UFW: native only / UFW: только native
```

> [!IMPORTANT]
> Do **not** expose ports `8123`/`9000` to the public internet. Use a VPN, SSH tunnel, or reverse proxy with authentication. Prefer binding `listen_host` to internal interfaces only.
> **Не открывайте** порты `8123`/`9000` в публичный интернет. Используйте VPN, SSH-туннель или reverse proxy с аутентификацией. Ограничьте `listen_host` внутренними интерфейсами.

### Performance & System Tables

```sql
-- Active queries and resources / Активные запросы и ресурсы
SELECT query_id, user, elapsed, formatReadableSize(memory_usage) AS mem, read_rows, query
FROM system.processes ORDER BY elapsed DESC LIMIT 20;

-- Largest tables / Самые большие таблицы
SELECT database, table,
       sum(bytes_on_disk) AS bytes,
       formatReadableSize(sum(bytes_on_disk)) AS size,
       sum(rows) AS rows
FROM system.parts
WHERE active
GROUP BY database, table
ORDER BY bytes DESC
LIMIT 20;

-- Part counts (too many parts warning) / Счётчик частей (предупреждение о частях)
SELECT database, table, count() AS parts, formatReadableSize(sum(bytes_on_disk)) AS size
FROM system.parts
WHERE active
GROUP BY database, table
ORDER BY parts DESC
LIMIT 20;

-- Background merges / Фоновые слияния
SELECT database, table, elapsed, progress, num_parts, formatReadableSize(bytes_read_uncompressed) AS read
FROM system.merges;

-- Running mutations / Выполняющиеся мутации
SELECT mutation_id, database, table, is_done, parts_to_do, create_time
FROM system.mutations WHERE is_done = 0;

-- Replication status / Статус репликации
SELECT database, table, is_leader, is_readonly, absolute_delay, queue_size, inserts_in_queue
FROM system.replicas;

-- Server metrics / Метрики сервера
SELECT metric, value FROM system.metrics WHERE metric LIKE '%Query%' OR metric LIKE '%Memory%' OR metric LIKE '%Part%';
SELECT metric, value FROM system.asynchronous_metrics WHERE metric LIKE '%Memory%' OR metric LIKE '%Uptime%';

-- Table settings inspection / Проверка настроек таблицы
SELECT * FROM system.tables WHERE database = '<DB>' AND name = '<TABLE>' FORMAT Vertical;
```

### Query Explain

```sql
EXPLAIN SELECT * FROM <DB>.events WHERE event_type = 'click';                     -- Query plan / План запроса
EXPLAIN AST SELECT * FROM <DB>.events;                                            -- Abstract syntax tree / AST
EXPLAIN SYNTAX SELECT * FROM <DB>.events WHERE event_type = 'click';              -- Rewritten syntax / Переписанный синтаксис
EXPLAIN ESTIMATE SELECT count() FROM <DB>.events;                                 -- Cost estimate / Оценка стоимости
```

---

## Security

### User Management

```sql
CREATE USER <USER> IDENTIFIED WITH sha256_password BY '<PASSWORD>';               -- Create user / Создать пользователя
CREATE USER <USER> IDENTIFIED WITH sha256_password BY '<PASSWORD>' HOST IP '<IP>/32'; -- Restrict by IP / Ограничить по IP
CREATE USER <USER> IDENTIFIED WITH sha256_password BY '<PASSWORD>' HOST ANY;     -- Any host (dangerous) / Любой хост (опасно)
ALTER USER <USER> IDENTIFIED WITH sha256_password BY '<NEW_PASSWORD>';            -- Change password / Сменить пароль
DROP USER IF EXISTS <USER>;                                                       -- Delete user / Удалить пользователя
SHOW USERS;                                                                       -- List users / Список пользователей
SHOW CREATE USER <USER>;                                                          -- User DDL / DDL пользователя
SHOW GRANTS FOR <USER>;                                                           -- User grants / Права пользователя
SHOW ACCESS;                                                                      -- All access entities / Все сущности доступа
```

> [!CAUTION]
> `HOST ANY` + empty-password default user is a common ClickHouse breach vector. Always create named users with passwords and IP restrictions, and revoke or lock `default`.
> Сочетание `HOST ANY` + пустой пароль у `default` — частая вектор атаки. Всегда создавайте именованных пользователей с паролями и ограничениями по IP.

### Password Hash Generation (users.xml)

When a user must be reset via `users.xml` (for example after a DB migration, when SQL access is lost), generate a random password and its SHA-256 hash first. The hash goes into `<password_sha256_hex>` in `users.xml`; the plaintext password is used once in `clickhouse-client`.

```bash
PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
# Output line 1: <PASSWORD>   (copy this — shown once)
# Output line 2: <HASH>       (sha256 hex, goes into users.xml)
```

> [!NOTE]
> Store the generated `<PASSWORD>` in your secret manager immediately — it is printed only once. The `tr -d '-'` strips the trailing dash from `sha256sum` output; leading/trailing spaces around the hash are harmless in XML, or trim with `awk '{print $1}'`.
> Сохраните `<PASSWORD>` в менеджере секретов сразу — он выводится только один раз. Хеш из `sha256sum` после `tr -d '-'` можно использовать как есть.

`/etc/clickhouse-server/users.xml` (fragment / фрагмент):

```xml
<users>
    <default>
        <!-- Comment out the old credential / Закомментировать старые учётные данные -->
        <!-- <password_sha256_hex>OLD_HASH</password_sha256_hex> -->
        <!-- <password>OLD_PLAINTEXT</password> -->

        <!-- New SHA-256 hash / Новый SHA-256 хеш -->
        <password_sha256_hex><HASH></password_sha256_hex>

        <networks>
            <ip>::/0</ip>
        </networks>
        <profile>default</profile>
        <quota>default</quota>
        <access_management>1</access_management>
    </default>
</users>
```

> [!CAUTION]
> Back up `users.xml` **before** editing it — this is explicitly allowed and recommended. A bad edit locks everyone out of the server.
> Создайте резервную копию `users.xml` **до** правки — это разрешается и настоятельно рекомендуется. Ошибка в файле заблокирует доступ ко всем.

### Roles & Grants

```sql
CREATE ROLE <ROLE>;                                                               -- Create role / Создать роль
GRANT SELECT ON <DB>.* TO <ROLE>;                                                -- Grant read on DB / Право чтения на базу
GRANT SELECT, INSERT ON <DB>.<TABLE> TO <ROLE>;                                  -- Specific table rights / Права на таблицу
GRANT SELECT ON <DB>.* TO <USER> WITH GRANT OPTION;                             -- Re-grant allowed / Разрешена передача прав
REVOKE SELECT ON <DB>.* FROM <ROLE>;                                             -- Revoke / Отозвать права
GRANT <ROLE> TO <USER>;                                                          -- Assign role / Назначить роль
SHOW ROLES;                                                                      -- List roles / Список ролей
SHOW GRANTS FOR <ROLE>;                                                          -- Role grants / Права роли
```

### Row Policies (RLS)

```sql
CREATE ROW POLICY <POLICY_NAME> ON <DB>.<TABLE> USING event_type = currentDatabase() TO <ROLE>; -- Row filter / Фильтр строк
DROP ROW POLICY <POLICY_NAME> ON <DB>.<TABLE>;                                 -- Remove policy / Удалить политику
SHOW POLICIES;                                                                   -- List policies / Список политик
```

### SSL/TLS Configuration

Generate certificates / Генерация сертификатов:

```bash
sudo openssl req -new -x509 -days 365 -nodes -text \
  -out /etc/clickhouse-server/server.crt \
  -keyout /etc/clickhouse-server/server.key \
  -subj "/CN=<HOSTNAME>"
sudo chmod 600 /etc/clickhouse-server/server.key                                 # Lock key file / Ограничить доступ к ключу
sudo chown clickhouse:clickhouse /etc/clickhouse-server/server.crt /etc/clickhouse-server/server.key
```

`/etc/clickhouse-server/config.d/tls.xml`

```xml
<clickhouse>
    <https_port>8443</https_port>
    <tcp_port_secure>9440</tcp_port_secure>
    <openSSL>
        <server>
            <certificateFile>/etc/clickhouse-server/server.crt</certificateFile>
            <privateKeyFile>/etc/clickhouse-server/server.key</privateKeyFile>
            <verificationMode>none</verificationMode>
            <cacheSessions>1</cacheSessions>
        </server>
    </openSSL>
</clickhouse>
```

```bash
sudo systemctl restart clickhouse-server                                           # Apply TLS config / Применить TLS-конфиг
```

### Quotas & Profiles (SQL)

```sql
CREATE QUOTA <QUOTA_NAME> FOR INTERVAL 1 HOUR
    MAX queries = 10000,
    MAX read_rows = 1000000000,
    MAX execution_time = 60
    TO <ROLE>;

CREATE PROFILE <PROFILE_NAME>
    SETTINGS max_memory_usage = 2000000000, max_execution_time = 30;

ALTER USER <USER> PROFILE '<PROFILE_NAME>' QUOTA '<QUOTA_NAME>';
```

---

## Backup & Restore

### Backup Methods Comparison

| Method / Метод | Description (EN / RU) | Use Case / Best for / Применение |
|----------------|----------------------|----------------------------------|
| `BACKUP` / `RESTORE` SQL | Built-in since 22.8; to Disk/S3/Azure / Встроенный с 22.8; в Disk/S3/Azure | Regular prod backups / Регулярные бэкапы в проде |
| `clickhouse-backup` (Altinity) | Open-source CLI; click + restore + sync / Open-source CLI; сжатие + восстановление + синхронизация | Scheduling, S3, partial restore / Планирование, S3, частичное восстановление |
| Filesystem copy | `tar`/`rsync` of `/var/lib/clickhouse` / Копирование каталога данных | Simple DR, cold snapshots / Простой DR, холодные снимки |
| Logical dump | `INSERT ... FORMAT Native/CSV/JSONEachRow` via client / Логический дамп через клиент | Cross-version migration, small DBs / Миграция между версиями, малые базы |
| Replicas | Another replica is **not** a backup / Другая реплика — **не** бэкап | HA only / Только высокая доступность |

> [!WARNING]
> Replication protects against node failure, **not** against human error (bad `DROP`, bad mutation, ransomware). You still need independent backups with tested restore procedures.
> Репликация защищает от отказа узла, **не** от ошибок человека (плохой `DROP`, плохая мутация, рансомвэри). Независимые бэкапы с проверенным восстановлением обязательны.

### Built-in BACKUP / RESTORE

```bash
# Backup database to local disk / Бэкап базы на локальный диск
clickhouse-client -q "BACKUP DATABASE <DB> TO Disk('/var/lib/clickhouse/backups/<DB>_$(date +%Y%m%d_%H%M)')"

# Backup table / Бэкап таблицы
clickhouse-client -q "BACKUP TABLE <DB>.<TABLE> TO Disk('/var/lib/clickhouse/backups/table_backup')"

# Backup to S3 / Бэкап в S3
clickhouse-client -q "BACKUP DATABASE <DB> TO S3('https://<BUCKET>.s3.amazonaws.com/ch_backups/<DB>/', '<ACCESS_KEY>', '<SECRET_KEY>')"

# Incremental backup (new parts only) / Инкрементальный бэкап (только новые части)
clickhouse-client -q "BACKUP DATABASE <DB> TO Disk('/var/lib/clickhouse/backups/inc') AS INCREMENTAL FROM Disk('/var/lib/clickhouse/backups/base')"
```

`/etc/clickhouse-server/config.d/backups.xml`

```xml
<clickhouse>
    <backups>
        <allowed_path>/var/lib/clickhouse/backups</allowed_path>
        <!-- allow S3 if used / разрешить S3, если используется -->
        <!-- <s3>
            <access_key_id><ACCESS_KEY></access_key_id>
            <secret_access_key><SECRET_KEY></secret_access_key>
        </s3> -->
    </backups>
</clickhouse>
```

```sql
-- Check backups / Проверка бэкапов
SELECT * FROM system.backups ORDER BY start_time DESC LIMIT 10;

-- Restore database / Восстановление базы
RESTORE DATABASE <DB> FROM Disk('/var/lib/clickhouse/backups/<DB>_backup');
RESTORE TABLE <DB>.<TABLE> FROM Disk('/var/lib/clickhouse/backups/table_backup');

-- Restore with replacement (overwrite) / Восстановление с перезаписью
RESTORE DATABASE <DB> FROM Disk('/var/lib/clickhouse/backups/<DB>_backup') SETTINGS allow_concurrent_inserts = 0;
```

### clickhouse-backup (Altinity Tool)

```bash
# Install / Установка
curl https://raw.githubusercontent.com/Altinity/clickhouse-backup/master/install.sh | sudo sh

# Config / Конфиг
# /etc/clickhouse-backup/config.yml
```

`/etc/clickhouse-backup/config.yml`

```yaml
general:
  remote_storage: s3
  disable_progress_bar: false
  backups_to_keep: 7
  backups_to_keep_local: 3
  log_level: info

clickhouse:
  host: <HOST>
  port: 9000
  username: <USER>
  password: <PASSWORD>
  skip_tables: ['system.*', 'INFORMATION_SCHEMA.*', 'information_schema.*']

s3:
  bucket: <BUCKET>
  endpoint: https://s3.amazonaws.com
  region: us-east-1
  access_key: <ACCESS_KEY>
  secret_key: <SECRET_KEY>
```

```bash
sudo clickhouse-backup create daily_full                                        # Create backup / Создать бэкап
sudo clickhouse-backup create incremental daily_inc                             # Incremental / Инкрементальный
sudo clickhouse-backup list                                                     # List backups / Список бэкапов
sudo clickhouse-backup restore daily_full                                       # Restore backup / Восстановить бэкап
sudo clickhouse-backup restore remote daily_full                                # Restore from remote / Восстановить из remote
sudo clickhouse-backup delete local 7                                           # Cleanup old backups / Удалить старые бэкапы
sudo clickhouse-backup watch                                                    # Server-side schedule / Серверное планирование
```

### Filesystem / Physical Backup

```bash
# Graceful stop, snapshot, start / Остановка, снимок, запуск
sudo systemctl stop clickhouse-server
sudo tar --warning=no-file-changed -czf /backup/clickhouse-$(date +%Y%m%d).tar.gz \
  -C / var/lib/clickhouse
sudo systemctl start clickhouse-server

# Faster: rsync with --link-dest hardlinks / Быстрее: rsync с hardlink-ами
sudo systemctl stop clickhouse-server
rsync -a --delete --link-dest=/backup/clickhouse-prev /var/lib/clickhouse/ /backup/clickhouse-cold/
sudo systemctl start clickhouse-server

# Restore / Восстановление
sudo systemctl stop clickhouse-server
rm -rf /var/lib/clickhouse/*
tar -xzf /backup/clickhouse-20250115.tar.gz -C /
sudo systemctl start clickhouse-server
```

> [!CAUTION]
> Stopping the server for filesystem backup causes **write downtime**. For zero-downtime backups prefer `BACKUP TO S3` or `clickhouse-backup` with replicated tables, or snapshot-based volume backups.
> Остановка сервера для файлового бэкапа вызывает **простой записи**. Для бэкапа без простоя используйте `BACKUP TO S3`, `clickhouse-backup` или снапшоты томов.

### Logical Dump & Import

```bash
# Export table / Экспорт таблицы
clickhouse-client -q "SELECT * FROM <DB>.<TABLE> FORMAT CSVWithNames" > /backup/table.csv
clickhouse-client -q "SELECT * FROM <DB>.<TABLE> FORMAT Native" | gzip > /backup/table.native.gz

# Import / Импорт
clickhouse-client -q "INSERT INTO <DB>.<TABLE> FORMAT CSVWithNames" < /backup/table.csv
gunzip -c /backup/table.native.gz | clickhouse-client -q "INSERT INTO <DB>.<TABLE> FORMAT Native"

# Full DB dump via client / Полный дамп через клиент
clickhouse-client -q "SHOW TABLES FROM <DB>" --format TSV | while read -r t; do
  clickhouse-client -q "BACKUP TABLE ${DB}.${t} TO Disk('/var/lib/clickhouse/backups/logical_${t}')"
done
```

### Production Runbook — Backup & Restore / Инструкция — Бэкап и восстановление

1. **Plan** — decide RPO/RTO, backup type (full vs incremental), retention, and offsite copy target (S3 / another DC).
2. **Configure** — set `allowed_path` for `BACKUP`, create a dedicated backup user, enable `query_log` and `part_log`.
3. **Schedule** — cron/systemd timer for `clickhouse-backup create` or `BACKUP TO S3`; keep last N on local disk.
4. **Verify daily** — check `system.backups`, backup file sizes, and error logs; alert on failed backups.
5. **Test restore quarterly** — restore into a **staging** instance, run row-count and checksum queries against production baselines.
6. **Document** — write the exact restore commands (including Keeper state if using replicated tables) and store them with the backups.
7. **DR drill** — once a year, fail over to the standby with only the backups + docs available to the on-call engineer.

---

## Replication & Keeper

### Architecture Basics

- **ClickHouse Keeper** — drop-in ZooKeeper replacement (Raft-based, written in Rust); required for replicated tables and distributed DDL / Замена ZooKeeper (на базе Raft); нужен для реплицируемых таблиц и распределённого DDL
- **ReplicatedMergeTree*** — multi-master table replication; any replica can accept inserts / Мультимастерная репликация таблиц; вставки возможны с любой реплики
- **Distributed tables** — client-side sharding layer over local tables / Клиентский слой шардирования поверх локальных таблиц
- **Inter-server replication** (`9009`) — data transfer between replicas during merge/fetch / Передача данных между репликами

### Keeper Deployment (separate process)

`/etc/clickhouse-keeper/config.yaml`

```yaml
tcp_port: 9181
server_id: 1
log_storage_path: /var/lib/clickhouse-keeper/coordination/log
snapshot_storage_path: /var/lib/clickhouse-keeper/coordination/snapshot
state_storage_path: /var/lib/clickhouse-keeper/coordination/state
raft_configuration:
  server:
    - id: 1
      hostname: <HOST1>
      port: 9234
    - id: 2
      hostname: <HOST2>
      port: 9234
    - id: 3
      hostname: <HOST3>
      port: 9234
```

```bash
sudo systemctl enable --now clickhouse-keeper                                    # Start Keeper / Запустить Keeper
sudo systemctl status clickhouse-keeper                                         # Keeper status / Статус Keeper
clickhouse-client --secure --port 9440 -q "SELECT * FROM system.zookeeper WHERE path='/'"  # Keeper health / Здоровье Keeper
```

### Replicated Table DDL

```sql
CREATE TABLE <DB>.events_replicated ON CLUSTER '<CLUSTER_NAME>'
(
    event_date Date,
    user_id UInt64,
    event_type LowCardinality(String)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/<DB>.events_replicated', '{replica}')
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_type, event_date, user_id);

-- Distributed table / Распределённая таблица
CREATE TABLE <DB>.events_distributed ON CLUSTER '<CLUSTER_NAME>' AS <DB>.events_replicated
ENGINE = Distributed('<CLUSTER_NAME>', '<DB>', 'events_replicated', rand());

-- Insert via distributed table / Вставка через распределённую таблицу
INSERT INTO <DB>.events_distributed VALUES ('2025-01-15', 42, 'click');
```

### Replication Monitoring

```sql
SELECT database, table, is_leader, is_readonly, absolute_delay,
       queue_size, inserts_in_queue, merges_in_queue, zookeeper_exception
FROM system.replicas
WHERE database = '<DB>';

SELECT * FROM system.replication_queue WHERE database = '<DB>' LIMIT 20;

SHOW REPLICA STATUS '<DB>.events_replicated';                                 -- Replica status / Статус реплики
SYSTEM SYNC REPLICA <DB>.events_replicated;                                  -- Wait for sync / Дождаться синхронизации
SYSTEM RESTART REPLICA <DB>.events_replicated;                               -- Restart replica logic / Перезапустить логику реплики
```

> [!WARNING]
> `SYSTEM RESTART REPLICA` and `SYSTEM SYNC REPLICA` on a **read-only** or lagging replica are operational actions — test them in staging first. Never run them on all replicas of a table simultaneously during an incident without a runbook.
> `SYSTEM RESTART REPLICA` и `SYSTEM SYNC REPLICA` — операционные действия; сначала проверяйте их в staging. Не запускайте их на всех репликах таблицы одновременно во время инцидента без runbook.

### Production Runbook — Shard Recovery / Инструкция — Восстановление шарда

1. **Identify** — check `system.replicas` for `absolute_delay`, `zookeeper_exception`, and read-only state; confirm Keeper quorum is healthy.
2. **Drain** — remove the bad replica from the load balancer; stop writes to it if it is accepting them.
3. **Repair Keeper** — if Keeper lost quorum, restore from a Keeper snapshot on the surviving nodes; never delete Keeper data as a first step.
4. **Resync replica** — start the node, run `SYSTEM SYNC REPLICA <table>`, watch `system.replication_queue` until empty.
5. **Verify** — compare row counts on the repaired replica vs the leader for a sample of partitions; check `system.parts` active counts.
6. **Re-enable** — return the node to the load balancer; enable query logging to confirm traffic.
7. **If unrecoverable** — rebuild the replica from a backup + replication (see Backup & Restore), not by copying the leader's files while it is running.

---

## Troubleshooting & Tools

### Common Issues

**Connection refused / Отказ в соединении:**

```bash
sudo systemctl status clickhouse-server                                       # Check if running / Проверить запущен ли
sudo ss -tulnp | grep -E '8123|9000'                                        # Check listening ports / Проверить порты
sudo journalctl -u clickhouse-server -n 100 --no-pager                       # Recent errors / Последние ошибки
# Verify listen_host and listen_port in config.xml / Проверить listen_host и listen_port
```

**Too many parts / Слишком много частей:**

```sql
-- Diagnosis / Диагностика
SELECT database, table, count() AS parts
FROM system.parts WHERE active
GROUP BY database, table ORDER BY parts DESC LIMIT 10;

SELECT * FROM system.merges WHERE elapsed > 60;

-- Mitigation / Меры
-- 1. Enable async_insert / Включить асинхронную вставку
-- 2. Increase background_pool_size / Увеличить background_pool_size
-- 3. Reduce insert frequency, batch larger writes / Снизить частоту вставок, увеличить батчи
-- 4. OPTIMIZE TABLE ... FINAL (heavy!) / Принудительное слияние (тяжело!)
```

**Memory limit exceeded / Превышен лимит памяти:**

```sql
SELECT query_id, formatReadableSize(memory_usage) AS mem, peak_memory_usage, query
FROM system.processes WHERE memory_usage > 10000000000;

-- Per-query overrides / Переопределения на запросе
SELECT count() FROM <DB>.huge_table SETTINGS max_memory_usage = 20000000000, max_bytes_before_external_sort = 5000000000;
```

**Stuck mutations / Зависшие мутации:**

```sql
SELECT mutation_id, database, table, parts_to_do, is_done, latest_fail_reason
FROM system.mutations WHERE is_done = 0;

-- Detach/reattach data parts is NOT the fix; check disk space and system.merges / Проверить диск и system.merges
-- KILL MUTATION only if the mutation is wrong and you accept leftover data / KILL MUTATION только если мутация неверна
```

**Replica lag / Отставание реплики:**

```sql
SELECT database, table, absolute_delay, queue_size, inserts_in_queue, last_queue_update
FROM system.replicas WHERE absolute_delay > 60;

SELECT * FROM system.replication_queue WHERE status != 'Finished' LIMIT 20;
```

**Disk full / Диск заполнен:**

```bash
df -h /var/lib/clickhouse                                                     # Check space / Проверить место
sudo du -sh /var/lib/clickhouse/*                                            # Largest dirs / Крупные каталоги
# Free space: drop old partitions, remove old backups, increase volume / Освободить: DROP PARTITION, удалить старые бэкапы, расширить том
```

**Cannot login after migration / Нет доступа после миграции:**

If the ClickHouse password is lost or wrong after a DB migration, restore access by setting a new SHA-256 hash directly in `users.xml` (see also [Password Hash Generation](#Password%20Hash%20Generation%20(users.xml))).

### Production Runbook — Password Reset via users.xml / Инструкция — Сброс пароля через users.xml

> [!CAUTION]
> Comment out the **old** hash in `users.xml`; never delete the backup. Restart is required for `users.xml` changes to take effect.
> Закомментируйте **старый** хеш в `users.xml`; не удаляйте резервную копию. Изменения вступают в силу после перезапуска.

1. **Generate** a random password and its SHA-256 hash (copy both outputs):

   ```bash
   PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
   ```

   Output:
   ```text
   <PASSWORD>
   <HASH>
   ```

2. **Backup** the users config before any edit (allowed and recommended):

   ```bash
   # On the host / На хосте
   sudo cp -a /etc/clickhouse-server/users.xml /etc/clickhouse-server/users.xml.bak-$(date +%Y%m%d_%H%M)

   # Inside a Docker container (e.g. PMM server bundling ClickHouse) / В Docker-контейнере (напр. PMM со встроенным ClickHouse)
   docker exec -it <CONTAINER> bash
   ```

3. **Edit** the file and swap the credential — comment the original hash, insert the new one:

   ```bash
   vim /etc/clickhouse-server/users.xml
   ```

   `/etc/clickhouse-server/users.xml` (fragment / фрагмент):

   ```xml
   <default>
       <!-- <password_sha256_hex>OLD_HASH</password_sha256_hex> -->
       <password_sha256_hex><HASH></password_sha256_hex>
   </default>
   ```

4. **Restart** ClickHouse so `users.xml` is re-read:

   ```bash
   # Host / Хост
   sudo systemctl restart clickhouse-server

   # Container / Контейнер
   docker restart <CONTAINER>
   ```

5. **Login** with the password generated in step 1 — `clickhouse-client` prompts for it:

   ```bash
   clickhouse-client --host <HOST> -u <USER>
   # Password prompt / Запрос пароля: enter <PASSWORD> / введите <PASSWORD>
   ```

6. **Verify** and optionally move the new credential into SQL-based users (preferred over raw XML going forward):

   ```sql
   SELECT 1;                                                                   -- Connectivity check / Проверка связи
   SHOW GRANTS FOR <USER>;                                                     -- Confirm rights / Проверить права
   ```

### Diagnostics One-Liners

```bash
clickhouse-client -q "SELECT version()"                                       # Server version / Версия сервера
clickhouse-client -q "SELECT * FROM system.one"                              # Connectivity check / Проверка связи
clickhouse-client -q "SHOW TABLES" --format Pretty                            # Pretty output / Красивый вывод
clickhouse-client -q "SELECT * FROM system.errors ORDER BY value DESC LIMIT 10" --format Pretty  # Error counters / Счётчики ошибок
clickhouse-client -q "EXPLAIN indexes = 1 SELECT * FROM <DB>.events WHERE user_id = 1" --format Pretty  # Index usage / Использование индексов
```

### Useful System Tables

| Table / Таблица | Purpose / Назначение |
|-----------------|----------------------|
| `system.tables` | Table engines, engines_full DDL / Движки и DDL таблиц |
| `system.columns` | Column types and defaults / Типы и значения по умолчанию |
| `system.parts` | Active/historical parts and sizes / Части данных и размеры |
| `system.query_log` | Historical queries and exceptions / История запросов и исключений |
| `system.part_log` | Part lifecycle events / События жизненного цикла частей |
| `system.mutations` | Mutation status / Статус мутаций |
| `system.replicas` | Replica health / Здоровье реплик |
| `system.processes` | Currently running queries / Текущие запросы |
| `system.settings` | All settings with defaults / Все настройки и значения по умолчанию |
| `system.asynchronous_metrics` | Background metrics (memory, uptime) / Фоновые метрики |

### Maintenance Notes

```sql
-- Disable query logging temporarily (if log volume is huge) / Временно отключить лог запросов
SYSTEM STOP MERGES <DB>.<TABLE>;                                              -- Stop merges / Остановить слияния
SYSTEM START MERGES <DB>.<TABLE>;                                             -- Resume merges / Возобновить слияния
SYSTEM STOP REPLICATED Merges;                                                -- Careful! / Осторожно!

-- Drop old partitions instead of DELETE mutations / Удалять старые партиции вместо DELETE
ALTER TABLE <DB>.events DROP PARTITION '202301';

-- Reattach a detached part / Переустановить отсоединённую часть
ALTER TABLE <DB>.events ATTACH PARTITION '202501';
```

---

## Logrotate Configuration

`/etc/logrotate.d/clickhouse-server`

```conf
/var/log/clickhouse-server/clickhouse-server.log
/var/log/clickhouse-server/clickhouse-server.err.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    dateext
    dateformat -%Y%m%d
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/clickhouse-server/clickhouse-server.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
```

> [!NOTE]
> ClickHouse also rotates its own logs via `logger.size` and `logger.count` in `config.xml` (`size` = max file size, `count` = rotated files to keep). External logrotate with `copytruncate` is a safety net for the `.err.log` and for distro-packaged setups that rely on logrotate.
> ClickHouse также ротирует собственные логи через `logger.size` и `logger.count` в `config.xml`. Внешний logrotate с `copytruncate` — страховка для `.err.log` и дистрибутивных установок.

---

## Documentation Links

- **ClickHouse Official Documentation:** https://clickhouse.com/docs
- **SQL Reference:** https://clickhouse.com/docs/en/sql-reference
- **Engines (MergeTree family):** https://clickhouse.com/docs/en/engines/table-engines/mergetree-family
- **Backup & Restore (BACKUP/RESTORE):** https://clickhouse.com/docs/en/operations/backup
- **clickhouse-backup (Altinity):** https://github.com/Altinity/clickhouse-backup
- **ClickHouse Keeper:** https://clickhouse.com/docs/en/guides/sre/keeper
- **Replication:** https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replication
- **System Tables:** https://clickhouse.com/docs/en/operations/system-tables
- **Access Control:** https://clickhouse.com/docs/en/security/access-control
- **Configuration Files:** https://clickhouse.com/docs/en/operations/configuration-files
- **Performance Tuning:** https://clickhouse.com/docs/en/performance
- **ClickHouse Cloud:** https://clickhouse.com/cloud
