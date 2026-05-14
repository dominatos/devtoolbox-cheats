Title: 🐬 MySQL Galera Cluster
Group: Databases
Icon: 🐬
Order: 15

---

> **MySQL Galera Cluster** is a synchronous multi-master replication plugin for MySQL/MariaDB based on the Galera library. It provides true multi-master topology with synchronous replication, automatic node provisioning, and automatic membership control.
>
> **Common use cases / Типичные сценарии:** High-availability MySQL clusters, multi-master write setups, geographic redundancy, zero-downtime deployments.
>
> **Status / Статус:** Actively maintained. Galera is available as a standalone plugin for MySQL, built into **MariaDB Galera Cluster**, and as part of **Percona XtraDB Cluster (PXC)**. For managed solutions, consider **AWS Aurora** (MySQL-compatible) or **Google Cloud SQL** with HA. See also the dedicated [Percona XtraDB Cluster cheatsheet](percona-xtradb-cluster.md) for PXC-specific operations.
>
> **Default ports / Порты по умолчанию:** `3306` (MySQL), `4567` (Galera replication), `4568` (IST), `4444` (SST)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Core Management & UID](#core-management--uid)
3. [Sysadmin Operations](#sysadmin-operations)
4. [Security](#security)
5. [Backup & Restore](#backup--restore)
6. [Troubleshooting & Tools](#troubleshooting--tools)
7. [Logrotate Configuration](#logrotate-configuration)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `3306` | Client connections / Клиентские подключения |
| `4567` | Galera Cluster replication traffic / Трафик репликации Galera |
| `4568` | Incremental State Transfer (IST) / Частичная передача состояния |
| `4444` | State Snapshot Transfer (SST) / Полная передача состояния |

### Package Installation / Установка пакетов

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y galera-4 mysql-server mysql-client rsync socat

# RHEL/AlmaLinux/Rocky
sudo dnf install -y galera mysql-server mysql rsync socat
```

### Configuration Files / Файлы конфигурации

| File / Файл | Purpose / Назначение |
|-------------|----------------------|
| `/etc/mysql/mysql.conf.d/mysqld.cnf` | Main MySQL config / Главный конфиг MySQL |
| `/etc/mysql/conf.d/galera.cnf` | Galera cluster config / Конфиг кластера Galera |
| `/var/lib/mysql/` | Data directory / Каталог данных |
| `/var/log/mysql/error.log` | Error log / Лог ошибок |

### Node Configuration / Конфигурация узла

`/etc/mysql/conf.d/galera.cnf`

```ini
[mysqld]
# --- Galera Provider / Провайдер Galera ---
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# For RHEL/AlmaLinux use: /usr/lib64/galera/libgalera_smm.so

# --- Cluster Configuration / Настройка кластера ---
wsrep_cluster_name="galera_cluster_prod"
wsrep_cluster_address="gcomm://<NODE1_IP>,<NODE2_IP>,<NODE3_IP>"

# --- Node Specific Settings / Специфичные настройки узла ---
wsrep_node_name="<HOSTNAME_THIS_NODE>"
wsrep_node_address="<THIS_NODE_IP>"

# --- SST Method / Метод полной синхронизации ---
wsrep_sst_method=rsync
# Alternative: xtrabackup-v2 or mariabackup
# wsrep_sst_auth="<SST_USER>:<SST_PASSWORD>"

# --- InnoDB Requirements / Требования InnoDB ---
binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
```

> [!IMPORTANT]
> `wsrep_cluster_name` must be **identical** on all nodes. `binlog_format` must be `ROW` to ensure replication consistency. 

### SST Method Comparison / Сравнение методов SST

| Method | Description (EN / RU) | Use Case / В каких случаях применять |
|--------|-----------------------|--------------------------------------|
| `rsync` | Raw file sync / Прямая синхронизация файлов | Small databases, simple setup, blocks donor / Маленькие базы, блокирует донора |
| `xtrabackup`| Percona hot backup / Горячий бэкап Percona | Large databases, production ready, non-blocking / Большие базы, продакшен |
| `mariabackup`| MariaDB hot backup / Горячий бэкап MariaDB | Same as xtrabackup but tailored for MariaDB / Аналог xtrabackup для MariaDB |

---

## Core Management & UID

> [!NOTE]
> **Galera UID (UUID)** is an important concept in cluster synchronization. The UUID identifies the cluster state. It is stored in the `grastate.dat` file.

### First Node Bootstrap / Первый запуск кластера

> [!CAUTION]
> Bootstrapping creates a new Primary Component. **Only do this once** on the node with the most up-to-date data. Bootstrapping on a stale node will cause data loss!

```bash
# Bootstrap the first node (creates cluster) / Запуск первого узла
sudo systemctl set-environment MYSQLD_OPTS="--wsrep-new-cluster"
sudo systemctl start mysql
sudo systemctl unset-environment MYSQLD_OPTS

# OR alternatively, using the script
sudo mysqld_bootstrap
```

### Joining Subsequent Nodes / Подключение остальных узлов

```bash
# Start MySQL normally on Node 2 and Node 3
sudo systemctl start mysql
```

### Cluster Status Checking / Проверка статуса кластера

```sql
-- Check cluster size (amount of nodes) / Проверка количества узлов
SHOW STATUS LIKE 'wsrep_cluster_size';

-- Check current node state (should be Synced) / Состояние узла
SHOW STATUS LIKE 'wsrep_local_state_comment';

-- Check cluster state UUID (Galera UID) / UID состояния кластера
SHOW STATUS LIKE 'wsrep_cluster_state_uuid';

-- Check if node is ready / Готов ли узел к работе
SHOW STATUS LIKE 'wsrep_ready';
```

### Galera UID and State / Galera UID и состояние (`grastate.dat`)

`/var/lib/mysql/grastate.dat`

The `grastate.dat` file stores the UUID and the `seqno` (sequence number) of the node. When a node restarts, it uses this file to determine if it needs IST (Incremental) or SST (Full Snapshot).

```bash
# Check node sequence state
sudo cat /var/lib/mysql/grastate.dat
```

*Example Output:*
```text
version: 2.1
uuid:    <UUID-STRING_IDENTIFYING-CLUSTER>
seqno:   <SEQUENCE_NUMBER>
safe_to_bootstrap: 0
```

> [!TIP]
> If all nodes crash, find the node with the highest `seqno`. On that node, edit `/var/lib/mysql/grastate.dat`, set `safe_to_bootstrap: 1`, and run bootstrap.

---

## Sysadmin Operations

### Service Control / Управление сервисом

```bash
sudo systemctl status mysql    # Check status / Статус
sudo systemctl start mysql     # Start / Старт
sudo systemctl stop mysql      # Stop / Остановка
sudo systemctl restart mysql   # Restart / Рестарт (triggers state transfer if needed)
```

> [!WARNING]
> Do NOT restart all nodes at once. Use a rolling restart: restart Node 1, wait for `wsrep_local_state_comment` to be `Synced`, then restart Node 2, etc.

### Log Locations / Расположение логов

```bash
# MySQL Error log (Contains Galera/wsrep messages) / Лог ошибок MySQL 
sudo tail -f /var/log/mysql/error.log

# General query and slow queries (if enabled)
sudo tail -f /var/log/mysql/mysql.log
sudo tail -f /var/log/mysql/mysql-slow.log
```

### Network & Firewall / Сеть и брандмауэр

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 3306/tcp
sudo ufw allow 4567/tcp
sudo ufw allow 4568/tcp
sudo ufw allow 4444/tcp
sudo ufw allow 4567/udp
sudo ufw reload

# Firewalld (RHEL/AlmaLinux)
sudo firewall-cmd --permanent --add-port={3306,4567,4568,4444}/tcp
sudo firewall-cmd --permanent --add-port=4567/udp
sudo firewall-cmd --reload
```

---

## Security

### SST User Credentials / Пользователь для SST

If using `xtrabackup` or `mariabackup` for `wsrep_sst_method`, you must create an SST user on the first node before bootstrapping others.

```sql
-- Run on existing node / Запустить на существующем узле
CREATE USER '<SST_USER>'@'localhost' IDENTIFIED BY '<SST_PASSWORD>';
GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '<SST_USER>'@'localhost';
FLUSH PRIVILEGES;
```

### Securing Cluster Traffic / Шифрование трафика кластера

To secure Galera replication traffic (node-to-node), add SSL configuration.

`/etc/mysql/conf.d/galera.cnf`

```ini
[mysqld]
wsrep_provider_options="socket.ssl=yes;socket.ssl_key=/etc/ssl/mysql/server-key.pem;socket.ssl_cert=/etc/ssl/mysql/server-cert.pem;socket.ssl_ca=/etc/ssl/mysql/ca-cert.pem"
```

---

## Backup & Restore

### Logical Dump (mysqldump) / Логический дамп

```bash
# Dump all databases / Дамп всех баз
mysqldump -u root -p<PASSWORD> --all-databases --single-transaction --routines --events > /backup/mysql_full_$(date +%F).sql

# Restore / Восстановление
mysql -u root -p<PASSWORD> < /backup/mysql_full_<DATE>.sql
```

### Runbook: Hot Backup with XtraBackup / Резервное копирование XtraBackup

1. **Install XtraBackup / Установить XtraBackup:**
   ```bash
   sudo apt install percona-xtrabackup-80
   ```
2. **Execute Full Backup / Создать полный бекап:**
   ```bash
   xtrabackup --backup --target-dir=/data/backups/base --user=<USER> --password=<PASSWORD>
   ```
3. **Prepare Backup for Restore / Подготовка бекапа:**
   ```bash
   xtrabackup --prepare --target-dir=/data/backups/base
   ```

---

## Troubleshooting & Tools

### Split-Brain Avoidance / Избежание Split-Brain

A split-brain occurs if the cluster splits into two or more independent parts, none of which has a quorum. 

- Keep an **odd number of nodes** (e.g., 3, 5).
- If you have an even number of nodes, use a **Galera Arbitrator (garbd)** to provide a tie-breaking vote without storing data.

```bash
# Install and configure arbitraror
sudo apt install galera-arbitrator-4
sudo systemctl enable --now garbd
```

### Dealing with Desync / Устранение рассинхронизации

If node state is `Donor/Desynced` or it refuses to start due to inconsistent state:

1. Stop MySQL on the faulty node:
   ```bash
   sudo systemctl stop mysql
   ```
2. Clear the data directory:
   ```bash
   sudo rm -rf /var/lib/mysql/*
   ```
3. Restart the node to force a full SST (State Snapshot Transfer):
   ```bash
   sudo systemctl start mysql
   ```

### Check InnoDB Lock Issues / Проверка блокировок InnoDB

```sql
SHOW ENGINE INNODB STATUS\G
```

---

## Logrotate Configuration

`/etc/logrotate.d/mysql-server`

```text
/var/log/mysql/*.log {
    daily
    rotate 7
    missingok
    create 640 mysql adm
    compress
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
