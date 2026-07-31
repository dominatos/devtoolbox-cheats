---
Title: 🐬 Percona XtraDB Cluster (PXC)
Group: Databases
Icon: 🐬
Order: 7
tags:
  - databases
  - sysadmin
  - linux
---

---

> **Percona XtraDB Cluster (PXC)** is a free, open-source, enterprise-grade MySQL clustering solution by Percona. It integrates Percona Server for MySQL with the Galera library for synchronous multi-master replication. PXC provides high availability, strong data consistency, and transparent application failover.
>
> **Common use cases / Типичные сценарии:** High-availability MySQL deployments, multi-master write clusters, financial and e-commerce applications requiring zero data loss, geographic redundancy.
>
> **Status / Статус:** Actively developed (current stable: PXC 8.0). PXC is the recommended Percona solution for MySQL HA. Alternatives: **MariaDB Galera Cluster** (MariaDB-based), **MySQL Group Replication / InnoDB Cluster** (Oracle's native HA), **AWS Aurora** (managed MySQL-compatible), **Vitess** (horizontal scaling for MySQL). See also the [MySQL Galera Cluster cheatsheet](mysqlgaleracheatsheet.md) for generic Galera operations.
>
> **Default ports / Порты по умолчанию:** `3306` (MySQL), `4567` (Galera), `4568` (IST), `4444` (SST)

---

## 📚 Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Security](#Security)
- [Backup & Restore](#Backup%20&%20Restore)
- [Monitoring & Cluster Health](#Monitoring%20&%20Cluster%20Health)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Logrotate Configuration](#Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

### Default Ports

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `3306` | MySQL client connections / Клиентские подключения MySQL |
| `4444` | SST (State Snapshot Transfer) — full resync / Полная синхронизация |
| `4567` | Galera replication traffic (TCP + UDP) / Репликационный трафик |
| `4568` | IST (Incremental State Transfer) — partial resync / Частичная синхронизация |

### Package Installation

```bash
# Ubuntu/Debian — Official Percona repo
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup pxc80                          # Enable PXC 8.0 repo / Включить репозиторий PXC 8.0
sudo apt update && sudo apt install -y percona-xtradb-cluster

# RHEL/AlmaLinux/Rocky / RHEL-дистрибутивы
sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
sudo percona-release setup pxc80
sudo yum install -y percona-xtradb-cluster
```

> [!TIP]
> For PXC 5.7 compatibility use `pxc57` instead of `pxc80`. PXC 8.0 is the current recommended production version as of 2024.

### Dependencies

```bash
# Required: socat for SST
sudo apt install -y socat qpress                # Ubuntu/Debian
sudo yum install -y socat qpress                # RHEL/AlmaLinux

# Percona XtraBackup (required for xtrabackup-based SST)
sudo apt install -y percona-xtrabackup-80       # Ubuntu/Debian — PXC 8.0
sudo yum install -y percona-xtrabackup-80       # RHEL/AlmaLinux
```

### Configuration Files

| File / Файл | Purpose / Назначение |
|-------------|----------------------|
| `/etc/mysql/mysql.conf.d/mysqld.cnf` | Main MySQL config (Ubuntu/Debian) / Главный конфиг MySQL |
| `/etc/my.cnf` | Main MySQL config (RHEL/AlmaLinux) / Главный конфиг MySQL |
| `/etc/mysql/conf.d/wsrep.cnf` | Galera/WSREP settings (Debian-style) / Настройки Galera |
| `/var/lib/mysql/` | Data directory / Каталог данных |
| `/var/log/mysql/error.log` | MySQL error log / Лог ошибок MySQL |
| `/var/run/mysqld/mysqld.sock` | MySQL Unix socket / Unix-сокет |

### Node Configuration

`/etc/mysql/mysql.conf.d/mysqld.cnf` (Ubuntu/Debian)
`/etc/my.cnf` (RHEL/AlmaLinux)

```ini
[mysqld]
# --- Server Identity
server_id                   = 1          # Unique per node! / Уникально для каждого узла!
bind-address                = 0.0.0.0
datadir                     = /var/lib/mysql

# --- Binary Log (required for PXC)
log_bin                     = /var/log/mysql/mysql-bin.log
binlog_format               = ROW         # PXC requires ROW format / PXC требует ROW формат
expire_logs_days            = 7

# --- InnoDB Tuning
innodb_buffer_pool_size     = 4G          # ~70% of RAM / ~70% ОЗУ
innodb_log_file_size        = 512M
innodb_flush_log_at_trx_commit = 1        # Safest; use 2 for better perf / Безопаснее; 2 для производительности
innodb_flush_method         = O_DIRECT
innodb_file_per_table       = ON

# --- Galera / WSREP Settings
wsrep_on                    = ON
wsrep_provider              = /usr/lib/galera4/libgalera_smm.so
wsrep_cluster_name          = "pxc-cluster-prod"   # Must match on all nodes! / Одинаково на всех узлах!
wsrep_cluster_address       = "gcomm://<IP_NODE1>,<IP_NODE2>,<IP_NODE3>"
wsrep_node_address          = "<IP_THIS_NODE>"
wsrep_node_name             = "<HOSTNAME_THIS_NODE>"

# --- SST Method
wsrep_sst_method            = xtrabackup-v2   # Recommended for hot SST / Рекомендуется для горячего SST
wsrep_sst_auth              = "<SST_USER>:<SST_PASSWORD>"

# --- Slave threads
wsrep_slave_threads         = 4           # Match CPU cores / Число потоков == CPU ядра
```

> [!IMPORTANT]
> `server_id` must be **unique** on every node. `wsrep_cluster_name` must be **identical** across all nodes. A mismatch will prevent nodes from joining the cluster.

> [!WARNING]
> `binlog_format` **must** be `ROW` for PXC. `STATEMENT` or `MIXED` can cause data inconsistency in a multi-writer setup.

### SST Method Comparison

| Method / Метод | Description / Описание | Use Case / Применение |
|----------------|------------------------|----------------------|
| `xtrabackup-v2` | Hot backup via Percona XtraBackup / Горячее копирование | **Recommended for production** — no donor lock / Без блокировки донора |
| `mysqldump` | Logical dump via mysqldump / Логический дамп | Small datasets, no XtraBackup available / Маленькие БД |
| `rsync` | Raw file copy (blocks donor) / Прямое копирование файлов | Dev/test only — blocks donor writes / Только dev/test — блокирует донора |

> [!CAUTION]
> `rsync` SST **blocks all writes on the donor node** during transfer. Never use it in production environments.

---

## Core Management

### Bootstrap & Starting the Cluster

> [!IMPORTANT]
> **Bootstrap** must be done only once on the **first node** when bringing up a fresh cluster. All other nodes join normally afterwards.

#### Runbook: Initial Cluster Bootstrap

1. **Bootstrap the first node / Запустить первый узел в режиме bootstrap:**
   ```bash
   # Ubuntu/Debian
   sudo systemctl start mysql@bootstrap.service       # Bootstrap mode / Режим bootstrap

   # RHEL/AlmaLinux (PXC 8.x)
   sudo mysqld_bootstrap                               # Bootstrap alternative / Альтернативный bootstrap

   # OR: set in config then start normally
   # wsrep_cluster_address = "gcomm://"              # Empty = bootstrap node / Пусто = bootstrap
   sudo systemctl start mysql
   ```

2. **Verify first node is Primary / Проверить, что первый узел Primary:**
   ```sql
   SHOW STATUS LIKE 'wsrep_cluster_size';
   -- Expected: 1 / Ожидаемо: 1
   SHOW STATUS LIKE 'wsrep_local_state_comment';
   -- Expected: Synced / Ожидаемо: Synced
   ```

3. **Start remaining nodes normally / Запустить остальные узлы:**
   ```bash
   sudo systemctl start mysql                         # On node 2, then node 3
   ```

4. **Verify cluster formed / Проверить формирование кластера:**
   ```sql
   SHOW STATUS LIKE 'wsrep_cluster_size';
   -- Expected: 3 (or N nodes) / Ожидаемо: 3 или N узлов
   ```

### Connecting to MySQL

```bash
mysql -u root -p                                        # Connect as root / Подключиться как root
mysql -u <USER> -p<PASSWORD> -h <IP_NODE1> -P 3306   # Remote connection / Удалённое подключение
mysql -u <USER> -p<PASSWORD> --socket=/var/run/mysqld/mysqld.sock  # Unix socket / Через сокет
```

### Cluster Status Queries

```sql
-- Full cluster status overview / Полный обзор состояния кластера
SHOW STATUS LIKE 'wsrep_%';

-- Critical status variables / Ключевые переменные состояния
SHOW STATUS LIKE 'wsrep_cluster_size';         -- Number of nodes / Количество узлов
SHOW STATUS LIKE 'wsrep_cluster_status';       -- Primary / Non-Primary
SHOW STATUS LIKE 'wsrep_local_state_comment';  -- Synced / Donor / Joiner / Initialized
SHOW STATUS LIKE 'wsrep_connected';            -- ON/OFF
SHOW STATUS LIKE 'wsrep_ready';                -- ON = accepting queries / ON = принимает запросы
SHOW STATUS LIKE 'wsrep_flow_control_paused';  -- >0 means replication lag / >0 — отставание репликации
```

### wsrep State Reference

| State / Состояние | Meaning / Значение | Action / Действие |
|-------------------|--------------------|-------------------|
| `Synced` | Node is in sync with cluster / Узел синхронизирован | Normal operation / Нормальная работа |
| `Donor/Desynced` | Providing SST to joiner / Передаёт состояние соединяющемуся | Temporary; monitor donor load / Временно; следить за нагрузкой |
| `Joiner` | Receiving SST / Принимает полную синхронизацию | Normal new-node join / Нормальное добавление узла |
| `Initialized` | Local data ready, waiting / Данные готовы, ожидание | Pre-join state / Состояние до вступления |
| `Disconnected` | Not connected to cluster / Не подключён к кластеру | Investigate logs / Проверить логи |

### CRUD Quick Reference

```sql
-- Database operations / Операции с базами данных
SHOW DATABASES;
CREATE DATABASE <DB_NAME> CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP DATABASE <DB_NAME>;

-- Table operations / Операции с таблицами
SHOW TABLES FROM <DB_NAME>;
DESCRIBE <DB_NAME>.<TABLE_NAME>;

-- User management / Управление пользователями
CREATE USER '<USER>'@'%' IDENTIFIED BY '<PASSWORD>';
GRANT ALL PRIVILEGES ON <DB_NAME>.* TO '<USER>'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR '<USER>'@'%';
DROP USER '<USER>'@'%';

-- Process management / Управление процессами
SHOW FULL PROCESSLIST;
KILL <PROCESS_ID>;
```

---

## Sysadmin Operations

### Service Control

```bash
sudo systemctl start mysql                             # Start MySQL / Запустить MySQL
sudo systemctl stop mysql                              # Stop MySQL / Остановить MySQL
sudo systemctl restart mysql                           # Restart MySQL / Перезапустить MySQL
sudo systemctl status mysql                            # Service status / Статус сервиса
sudo systemctl enable mysql                            # Enable on boot / Автозапуск

# Bootstrap service (first-start only!) / Bootstrap
sudo systemctl start mysql@bootstrap.service           # Ubuntu/Debian only
sudo systemctl stop mysql@bootstrap.service
```

> [!CAUTION]
> `systemctl restart mysql` on a Galera node will cause it to leave and rejoin the cluster, triggering SST or IST. In production, always do rolling restarts — one node at a time — and verify each node is `Synced` before restarting the next.

### Runbook: Rolling Restart

1. **Identify nodes / Определить узлы:**
   ```sql
   SHOW STATUS LIKE 'wsrep_cluster_size';            -- Must be 3 before starting
   ```
2. **Restart node 3 (non-primary first) / Перезапустить третий узел:**
   ```bash
   sudo systemctl restart mysql
   ```
3. **Wait for Synced / Дождаться Synced на узле 3:**
   ```sql
   SHOW STATUS LIKE 'wsrep_local_state_comment';     -- Wait for: Synced
   SHOW STATUS LIKE 'wsrep_cluster_size';            -- Must be 3 again
   ```
4. **Repeat for node 2, then node 1.**

### Log Locations

| Log / Лог | Path / Путь |
|-----------|-------------|
| MySQL Error Log / Ошибки MySQL | `/var/log/mysql/error.log` |
| Binary Log / Бинарный лог | `/var/log/mysql/mysql-bin.*` |
| General Query Log (if enabled) | `/var/log/mysql/general.log` |
| Slow Query Log | `/var/log/mysql/slow.log` |

```bash
# View recent errors
sudo tail -f /var/log/mysql/error.log

# Filter for Galera/WSREP events
sudo grep -i 'wsrep\|galera\|sst' /var/log/mysql/error.log | tail -50
```

### Slow Query Log

`/etc/mysql/mysql.conf.d/mysqld.cnf`

```ini
slow_query_log          = 1
slow_query_log_file     = /var/log/mysql/slow.log
long_query_time         = 1              # Seconds / Секунды
log_queries_not_using_indexes = 1
```

### Performance Tuning

`/etc/mysql/mysql.conf.d/mysqld.cnf`

```ini
# InnoDB / InnoDB
innodb_buffer_pool_size       = 4G       # 60-80% of RAM / 60-80% ОЗУ
innodb_buffer_pool_instances  = 4        # 1 per GB of pool / 1 на каждый GB пула
innodb_log_file_size          = 512M
innodb_io_capacity            = 2000     # IOPS of disk / IOPS диска
innodb_read_io_threads        = 8
innodb_write_io_threads       = 8

# Connection
max_connections               = 500
thread_cache_size             = 50

# Galera-specific tuning
wsrep_slave_threads           = 4        # Parallel apply threads / Потоки параллельного применения
wsrep_max_ws_size             = 2G       # Max write-set size / Максимальный размер write-set
wsrep_provider_options        = "gcache.size=2G"  # Galera cache for IST / Кэш Galera для IST
```

> [!TIP]
> Increase `gcache.size` to avoid SST (full resync) when a node rejoins after a short outage. A larger gcache enables IST (incremental resync), which is much faster.

### Network & Firewall

```bash
# UFW — UFW
sudo ufw allow 3306/tcp                                 # MySQL client / Клиент MySQL
sudo ufw allow 4444/tcp                                 # SST / Полная синхронизация
sudo ufw allow 4567/tcp                                 # Galera replication / Репликация Galera
sudo ufw allow 4567/udp                                 # Galera replication (UDP) / Репликация (UDP)
sudo ufw allow 4568/tcp                                 # IST / Частичная синхронизация

# firewalld — firewalld
sudo firewall-cmd --permanent --add-port={3306,4444,4567,4568}/tcp
sudo firewall-cmd --permanent --add-port=4567/udp
sudo firewall-cmd --reload
```

> [!WARNING]
> **Never** expose port `3306` to the public internet without IP restrictions. Restrict Galera ports (4444/4567/4568) to cluster node IPs only.

---

## Security

### Root Password Reset

```bash
# Stop MySQL
sudo systemctl stop mysql

# Start with skip-grant-tables
sudo mysqld_safe --skip-grant-tables --skip-networking &

# Connect and reset password
mysql -u root
```
```sql
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '<NEW_PASSWORD>';
FLUSH PRIVILEGES;
EXIT;
```
```bash
sudo systemctl stop mysql
sudo systemctl start mysql
```

### SST User Creation

```sql
-- Create SST user on bootstrap node (replicated to all nodes)
-- Создать SST пользователя на bootstrap узле (реплицируется на все узлы)
CREATE USER '<SST_USER>'@'127.0.0.1' IDENTIFIED BY '<SST_PASSWORD>';
GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '<SST_USER>'@'127.0.0.1';
FLUSH PRIVILEGES;
```

> [!IMPORTANT]
> The SST user credentials must match `wsrep_sst_auth` in `/etc/my.cnf`. Mismatch will cause joiner nodes to fail SST and not rejoin the cluster.

### At-Rest Encryption

`/etc/mysql/mysql.conf.d/mysqld.cnf`

```ini
# Enable InnoDB tablespace encryption keyring
early-plugin-load            = keyring_file.so
keyring_file_data            = /var/lib/mysql-keyring/keyring
innodb_encrypt_tables        = ON
innodb_encrypt_log           = ON
```

```sql
-- Encrypt an existing table / Зашифровать существующую таблицу
ALTER TABLE <DB_NAME>.<TABLE_NAME> ENCRYPTION='Y';

-- Check encryption status / Проверить статус шифрования
SELECT SPACE, NAME, ENCRYPTION FROM information_schema.INNODB_TABLESPACES
WHERE NAME LIKE '<DB_NAME>%';
```

### TLS/SSL Client Connections / TLS/SSL

`/etc/mysql/mysql.conf.d/mysqld.cnf`

```ini
ssl-ca      = /etc/mysql/ssl/ca-cert.pem
ssl-cert    = /etc/mysql/ssl/server-cert.pem
ssl-key     = /etc/mysql/ssl/server-key.pem
require_secure_transport = ON          # Force TLS for all connections / Принудительный TLS
```

```sql
-- Verify SSL status / Проверить статус SSL
SHOW VARIABLES LIKE '%ssl%';
SHOW STATUS LIKE 'Ssl_cipher';

-- Require SSL for a specific user / Требовать SSL для конкретного пользователя
ALTER USER '<USER>'@'%' REQUIRE SSL;
```

### Galera Encryption (node-to-node)

`/etc/mysql/mysql.conf.d/mysqld.cnf`

```ini
wsrep_provider_options = "socket.ssl_key=/etc/mysql/ssl/server-key.pem;
                           socket.ssl_cert=/etc/mysql/ssl/server-cert.pem;
                           socket.ssl_ca=/etc/mysql/ssl/ca-cert.pem"
```

---

## Backup & Restore

### Backup Methods Comparison

| Method / Метод | Tool / Инструмент | Type / Тип | Notes / Примечания |
|----------------|-------------------|------------|--------------------|
| Physical hot backup / Физический горячий бэкап | `xtrabackup` | Binary | **Recommended for large DBs** — no locks / Без блокировок |
| Logical dump / Логический дамп | `mysqldump` | SQL | Simple; slow on large DBs / Прост; медленно на больших БД |
| Logical parallel dump | `mydumper` | SQL | Faster than mysqldump / Быстрее mysqldump |
| Snapshot / Снапшот | LVM/Cloud snapshot | Block | Instant; requires consistent state / Требует согласованного состояния |

### Runbook: Backup with Percona XtraBackup

```bash
# 1. Install XtraBackup
sudo apt install -y percona-xtrabackup-80

# 2. Full backup
sudo xtrabackup --backup \
    --user=<BACKUP_USER> \
    --password=<BACKUP_PASSWORD> \
    --target-dir=/backup/mysql/full-$(date +%Y%m%d_%H%M%S)    # Backup with timestamp

# 3. Prepare backup
sudo xtrabackup --prepare \
    --target-dir=/backup/mysql/full-<TIMESTAMP>

# 4. Incremental backup (after full)
sudo xtrabackup --backup \
    --user=<BACKUP_USER> \
    --password=<BACKUP_PASSWORD> \
    --target-dir=/backup/mysql/inc-$(date +%Y%m%d_%H%M%S) \
    --incremental-basedir=/backup/mysql/full-<TIMESTAMP>
```

### Runbook: Restore with XtraBackup

> [!CAUTION]
> Restoring overwrites all data in `/var/lib/mysql`. Stop MySQL first and take a pre-restore snapshot if possible.

```bash
# 1. Stop MySQL
sudo systemctl stop mysql

# 2. Move existing data directory
sudo mv /var/lib/mysql /var/lib/mysql.bak

# 3. Restore backup
sudo xtrabackup --copy-back \
    --target-dir=/backup/mysql/full-<TIMESTAMP>

# 4. Fix permissions
sudo chown -R mysql:mysql /var/lib/mysql

# 5. Start MySQL
sudo systemctl start mysql
```

### Logical Backup with mysqldump

```bash
# Full dump — all databases
mysqldump -u root -p<PASSWORD> \
    --all-databases \
    --single-transaction \
    --flush-logs \
    --master-data=2 \
    --routines \
    --triggers \
    | gzip > /backup/mysql/full-dump-$(date +%Y%m%d).sql.gz

# Single database dump
mysqldump -u root -p<PASSWORD> \
    --single-transaction \
    --databases <DB_NAME> \
    | gzip > /backup/mysql/<DB_NAME>-$(date +%Y%m%d).sql.gz

# Restore from dump
gunzip < /backup/mysql/full-dump-<DATE>.sql.gz \
    | mysql -u root -p<PASSWORD>
```

> [!TIP]
> Always use `--single-transaction` with InnoDB tables to get a consistent backup without locking the database.

### Backup User Permissions

```sql
CREATE USER '<BACKUP_USER>'@'localhost' IDENTIFIED BY '<BACKUP_PASSWORD>';
GRANT BACKUP_ADMIN, RELOAD, LOCK TABLES, REPLICATION CLIENT, PROCESS ON *.* TO '<BACKUP_USER>'@'localhost';
GRANT SELECT ON performance_schema.* TO '<BACKUP_USER>'@'localhost';
FLUSH PRIVILEGES;
```

---

## Monitoring & Cluster Health

### Key wsrep Status Variables

```sql
-- Comprehensive cluster health check / Полная проверка состояния кластера
SELECT VARIABLE_NAME, VARIABLE_VALUE
FROM performance_schema.global_status
WHERE VARIABLE_NAME IN (
    'wsrep_cluster_size',
    'wsrep_cluster_status',
    'wsrep_local_state_comment',
    'wsrep_connected',
    'wsrep_ready',
    'wsrep_flow_control_paused',
    'wsrep_flow_control_sent',
    'wsrep_flow_control_recv',
    'wsrep_local_recv_queue',
    'wsrep_local_send_queue',
    'wsrep_cert_deps_distance',
    'wsrep_apply_oooe',
    'wsrep_replicated_bytes',
    'wsrep_received_bytes'
);
```

### Health Indicators Quick Reference

| Variable / Переменная | Healthy Value / Норма | Warning / Предупреждение |
|-----------------------|-----------------------|--------------------------|
| `wsrep_cluster_size` | `= N` (all nodes) | `< N` — node(s) missing |
| `wsrep_cluster_status` | `Primary` | `Non-Primary` — split-brain! |
| `wsrep_local_state_comment` | `Synced` | Anything else |
| `wsrep_connected` | `ON` | `OFF` |
| `wsrep_ready` | `ON` | `OFF` |
| `wsrep_flow_control_paused` | `< 0.1` | `> 0.1` — replication lag |
| `wsrep_local_recv_queue` | `< 5` | `> 10` — overloaded |

### Replication Performance

```sql
-- Check replication lag indicators / Проверить индикаторы отставания репликации
SHOW STATUS LIKE 'wsrep_flow_control%';
SHOW STATUS LIKE 'wsrep_local_recv_queue%';
SHOW STATUS LIKE 'wsrep_cert_deps_distance';   -- Higher = more parallelism / Выше = больше параллелизма

-- Monitor transaction throughput / Мониторинг пропускной способности транзакций
SHOW STATUS LIKE 'wsrep_replicated';            -- Transactions sent / Отправлено транзакций
SHOW STATUS LIKE 'wsrep_received';              -- Transactions received / Получено транзакций
```

### InnoDB Status

```sql
SHOW ENGINE INNODB STATUS\G                    -- Full InnoDB engine status / Полный статус InnoDB

-- Connection metrics / Метрики подключений
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';
SHOW STATUS LIKE 'Connection_errors%';

-- Cache hit ratio / Коэффициент попаданий в кэш
SELECT
    ROUND(100 * (1 - (
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') /
        (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests')
    )), 2) AS buffer_pool_hit_ratio;           -- Should be > 99% / Должен быть > 99%
```

---

## Troubleshooting & Tools

### Common Issues

#### Node fails to join cluster (SST failing)

```bash
# Check SST error on joiner
sudo grep -i 'sst\|error\|wsrep' /var/log/mysql/error.log | tail -30

# Verify SST user exists on donor
mysql -u root -p -e "SELECT user, host FROM mysql.user WHERE user='<SST_USER>';"

# Verify ports are open (on joiner, check donor)
sudo ss -tlnp | grep -E '4444|4567|4568'
sudo nc -zv <IP_DONOR> 4444                   # Test SST port / Тест SST порта
```

#### Split-brain: `wsrep_cluster_status = Non-Primary`

> [!CAUTION]
> Split-brain means the cluster has partitioned. Do NOT allow writes on `Non-Primary` nodes — data divergence will occur.

```sql
-- Check partition status on each node / Проверить на каждом узле
SHOW STATUS LIKE 'wsrep_cluster_status';

-- If majority of nodes are reachable but stuck as Non-Primary, force primary
-- Если большинство узлов доступны но застряли как Non-Primary, принудительно назначить Primary
-- !! DANGEROUS — only if you are sure no Primary segment exists !!
SET GLOBAL wsrep_provider_options='pc.bootstrap=YES';
```

> [!WARNING]
> Running `pc.bootstrap=YES` on the wrong node during a real split-brain will cause two independent Primary segments and data divergence. Always identify the segment with the most recent data.

#### Flow Control firing frequently

```sql
-- Check flow control pause ratio / Проверить долю паузы flow control
SHOW STATUS LIKE 'wsrep_flow_control_paused';   -- Fraction of time paused / Доля времени в паузе

-- Identify slow replication applier / Найти медленный appliyer
SHOW STATUS LIKE 'wsrep_local_recv_queue%';
```

```bash
# Check system resources on slow node
iostat -xz 1 5                                 # Disk I/O / Дисковый ввод-вывод
vmstat 1 5                                     # Memory / Память
top -bn1 | head -20                            # CPU / ЦПУ
```

#### Node is stuck in Donor/Desynced state

```bash
# Check SST progress on donor
sudo grep -i 'sst\|xtrabackup' /var/log/mysql/error.log | tail -20

# Check xtrabackup process
sudo ps aux | grep xtrabackup
```

#### Galera cache (gcache) full

```sql
-- Check current gcache configuration / Проверить конфигурацию gcache
SHOW GLOBAL VARIABLES LIKE 'wsrep_provider_options';
```

```ini
# Increase gcache size to reduce SST frequency
# /etc/mysql/mysql.conf.d/mysqld.cnf
wsrep_provider_options = "gcache.size=4G"     # Increase from default 128M / Увеличить с 128M
```

### Useful Diagnostic Commands

```bash
# MySQLCheck — check all databases
mysqlcheck -u root -p<PASSWORD> --all-databases --check

# Check InnoDB tables
mysqlcheck -u root -p<PASSWORD> --all-databases --check --extended

# Check for galera inconsistencies in logs
sudo grep -i 'inconsistent\|conflict\|deadlock' /var/log/mysql/error.log | tail -50

# Verify binary log integrity
mysqlbinlog /var/log/mysql/mysql-bin.000001 | head -50

# Show binary log list
mysql -u root -p -e "SHOW BINARY LOGS;"

# Purge old binary logs
mysql -u root -p -e "PURGE BINARY LOGS TO 'mysql-bin.<LAST_SAFE_LOG>';"
mysql -u root -p -e "PURGE BINARY LOGS BEFORE NOW() - INTERVAL 7 DAY;"
```

> [!CAUTION]
> Only purge binary logs after verifying all cluster nodes have applied them (`wsrep_last_applied` >= log position). Premature purge may force a full SST on lag nodes.

### Runbook: Recovering a Crashed Cluster (All Nodes Down)

> [!WARNING]
> Only use this runbook when **all nodes** are down. Never bootstrap a node that may have stale data.

1. **Find the most advanced node / Найти наиболее актуальный узел:**
   ```bash
   # On each node, check grastate.dat / На каждом узле проверить grastate.dat
   sudo cat /var/lib/mysql/grastate.dat
   # Look for the highest seqno / Найти наибольший seqno
   # Node with highest seqno = most up-to-date / Узел с наибольшим seqno = самый актуальный
   ```

2. **If safe_to_bootstrap = 0, force it / Если safe_to_bootstrap = 0, принудительно:**
   ```bash
   sudo sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/' /var/lib/mysql/grastate.dat
   ```

3. **Bootstrap from most advanced node / Bootstrap с наиболее актуального узла:**
   ```bash
   sudo systemctl start mysql@bootstrap.service         # Debian/Ubuntu
   ```

4. **Verify and join other nodes / Проверить и добавить другие узлы:**
   ```sql
   SHOW STATUS LIKE 'wsrep_cluster_size';              -- Should be 1
   SHOW STATUS LIKE 'wsrep_local_state_comment';       -- Should be Synced
   ```
   ```bash
   # Then start remaining nodes normally
   sudo systemctl start mysql                           # On each remaining node
   ```

5. **After all nodes join, stop bootstrap node and restart normally:**
   ```bash
   sudo systemctl stop mysql@bootstrap.service
   sudo systemctl start mysql
   ```

### pt-toolkit Integration

```bash
# Install Percona Toolkit
sudo apt install -y percona-toolkit

# Check table checksums for consistency across nodes
pt-table-checksum \
    --host=<IP_NODE1> \
    --user=<USER> \
    --password=<PASSWORD> \
    --databases=<DB_NAME>

# Sync inconsistent tables
pt-table-sync \
    --execute \
    --host=<IP_NODE1> \
    --user=<USER> \
    --password=<PASSWORD> \
    --databases=<DB_NAME>

# Analyze slow queries
pt-query-digest /var/log/mysql/slow.log | head -100

# Check for duplicate indexes
pt-duplicate-key-checker \
    --host=<IP_NODE1> \
    --user=<USER> \
    --password=<PASSWORD>
```

---

## Logrotate Configuration

`/etc/logrotate.d/mysql`

```conf
/var/log/mysql/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 mysql adm
    sharedscripts
    postrotate
        if test -x /usr/bin/mysqladmin && \
           /usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf ping &>/dev/null
        then
            /usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf flush-logs
        fi
    endscript
}
```

> [!TIP]
> MySQL reopens log files after `FLUSH LOGS`. Binary logs are rotated automatically by MySQL based on `max_binlog_size` and `expire_logs_days` (or `binlog_expire_logs_seconds` in 8.0). You do NOT need logrotate for binary logs — MySQL manages them internally.

---

## Documentation Links

- **Percona XtraDB Cluster Documentation:** https://docs.percona.com/percona-xtradb-cluster/
