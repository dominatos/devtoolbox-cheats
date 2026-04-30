Title: 🗃️ PostgreSQL — psql/pg_dump
Group: Databases
Icon: 🗃️
Order: 1

---

> **PostgreSQL** (often called "Postgres") is a powerful, open-source, object-relational database system with over 35 years of active development. It is known for its reliability, feature robustness, extensibility, and standards compliance (SQL:2023).
>
> **Common use cases / Типичные сценарии:** Enterprise applications, geospatial data (PostGIS), time-series data (TimescaleDB), financial systems, analytics/OLAP, web applications, data warehousing.
>
> **Status / Статус:** Actively developed (current stable: 17.x). PostgreSQL is widely considered the most advanced open-source RDBMS. Managed cloud options: **AWS RDS/Aurora**, **Google Cloud SQL**, **Azure Database for PostgreSQL**, **Supabase**, **Neon** (serverless). For distributed SQL: **CockroachDB**, **YugabyteDB**, **Citus** (PostgreSQL extension for sharding).
>
> **Default port / Порт по умолчанию:** `5432/tcp`

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-настройка)
2. [Core Management](#core-management--управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [Security](#security--безопасность)
5. [Backup & Restore](#backup--restore--бэкап-и-восстановление)
6. [Troubleshooting](#troubleshooting--устранение-проблем)
7. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## Installation & Configuration / Установка и Настройка

### Install / Установка

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y postgresql postgresql-contrib      # Install PostgreSQL / Установка PostgreSQL

# RHEL/AlmaLinux/Rocky
sudo dnf install -y postgresql-server postgresql-contrib                  # Install PostgreSQL / Установка PostgreSQL
sudo postgresql-setup --initdb                                            # Initialize DB / Инициализация БД
```

### Configuration / Конфигурация

**Main config files / Основной файл конфигурации:**

```bash
/etc/postgresql/<VERSION>/main/postgresql.conf    # Debian/Ubuntu
/var/lib/pgsql/data/postgresql.conf               # RHEL-based

/etc/postgresql/<VERSION>/main/pg_hba.conf        # Debian/Ubuntu
/var/lib/pgsql/data/pg_hba.conf                   # RHEL-based
```

**Common postgresql.conf settings / Основные настройки:**

```ini
listen_addresses = 'localhost'              # Listen address / Адрес прослушивания
port = 5432                                 # Default port / Порт по умолчанию
max_connections = 100                       # Max connections / Максимум подключений
shared_buffers = 256MB                      # Shared memory buffer / Общий буфер памяти
effective_cache_size = 1GB                  # OS cache estimate / Оценка кэша ОС
work_mem = 4MB                              # Memory per operation / Память на операцию
maintenance_work_mem = 64MB                 # Memory for maintenance / Память для обслуживания
wal_buffers = 16MB                          # WAL buffers / Буферы WAL
```

**pg_hba.conf (authentication) / Аутентификация:**

```bash
/etc/postgresql/<VERSION>/main/pg_hba.conf
```

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             <SUBNET>/24             md5
```

### System Tuning / Настройка системы

```bash
# Shared memory settings (add to /etc/sysctl.conf) / Настройки shared memory
kernel.shmmax = 17179869184                                               # 16GB in bytes / 16ГБ в байтах
kernel.shmall = 4194304                                                   # Pages (16GB / 4KB) / Страницы

sudo sysctl -p                                                            # Apply sysctl / Применить
```

---

## Core Management / Управление

### Connection / Подключение

```bash
psql -h <HOST> -U <USER> -d <DB>                                          # Connect to database / Подключение к базе
psql -h <HOST> -U <USER> -d <DB> -c 'SELECT version();'                   # Execute command / Выполнить команду
psql postgres://\<USER\>:\<PASSWORD\>@\<HOST\>:5432/\<DB\>                # Connection string / Строка подключения
sudo -u postgres psql                                                     # Connect as postgres user / Как пользователь postgres
```

### Database Operations / Операции с базами

```sql
\l                                                                        -- List databases / Список баз
\c <DB>                                                                   -- Connect to database / Подключиться к базе
CREATE DATABASE <DB_NAME>;                                                -- Create database / Создать базу
DROP DATABASE <DB_NAME>;                                                  -- Delete database / Удалить базу
\dt                                                                       -- List tables in current DB / Список таблиц
\dt+                                                                      -- List tables with sizes / Таблицы с размерами
\d <TABLE>                                                                -- Describe table / Описание таблицы
\d+ <TABLE>                                                               -- Detailed table info / Подробная информация
```

### Schema Operations / Операции со схемами

```sql
\dn                                                                       -- List schemas / Список схем
\dn+                                                                      -- Schemas with permissions / Схемы с правами
CREATE SCHEMA <SCHEMA_NAME>;                                              -- Create schema / Создать схему
DROP SCHEMA <SCHEMA_NAME> CASCADE;                                        -- Delete schema / Удалить схему
SET search_path TO <SCHEMA>, public;                                      -- Set default schema / Установить схему по умолчанию
```

### Table Operations / Операции с таблицами

```sql
CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100));            -- Create table / Создать таблицу
ALTER TABLE <TABLE> ADD COLUMN <COL> VARCHAR(50);                         -- Add column / Добавить колонку
ALTER TABLE <TABLE> DROP COLUMN <COL>;                                    -- Drop column / Удалить колонку
DROP TABLE <TABLE> CASCADE;                                               -- Delete table / Удалить таблицу
TRUNCATE TABLE <TABLE> CASCADE;                                           -- Empty table / Очистить таблицу
```

### CRUD Operations / Операции CRUD

```sql
INSERT INTO users (name) VALUES ('Alice');                                -- Insert row / Вставить строку
SELECT * FROM users WHERE name = 'Alice';                                 -- Select rows / Выбрать строки
UPDATE users SET name = 'Bob' WHERE id = 1;                               -- Update row / Обновить строку
DELETE FROM users WHERE id = 1;                                           -- Delete row / Удалить строку
```

### Indexes / Индексы

```sql
CREATE INDEX idx_name ON users(name);                                     -- Create index / Создать индекс
CREATE UNIQUE INDEX idx_email ON users(email);                            -- Unique index / Уникальный индекс
\di                                                                       -- List indexes / Список индексов
DROP INDEX idx_name;                                                      -- Drop index / Удалить индекс
```

### psql Commands / Команды psql

```sql
\?                                                                        -- Help / Справка
\q                                                                        -- Quit / Выйти
\timing on                                                                -- Show query timing / Показать время запросов
\x                                                                        -- Toggle expanded output / Расширенный вывод
\i <FILE>                                                                 -- Execute SQL file / Выполнить SQL файл
\o <FILE>                                                                 -- Output to file / Вывод в файл
\du                                                                       -- List roles / Список ролей
\dp <TABLE>                                                               -- Show table permissions / Права доступа к таблице
```

---

## Sysadmin Operations / Операции Сисадмина

### Service Control / Управление сервисом

```bash
sudo systemctl start postgresql                                           # Start service / Запустить сервис
sudo systemctl stop postgresql                                            # Stop service / Остановить сервис
sudo systemctl restart postgresql                                         # Restart service / Перезапустить сервис
sudo systemctl status postgresql                                          # Service status / Статус сервиса
sudo systemctl enable postgresql                                          # Enable on boot / Включить автозапуск
sudo systemctl reload postgresql                                          # Reload config / Перезагрузить конфиг
```

### Logs / Логи

```bash
sudo tail -f /var/log/postgresql/postgresql-<VERSION>-main.log            # Main log (Debian/Ubuntu) / Основной лог
sudo tail -f /var/lib/pgsql/data/log/postgresql-*.log                     # Main log (RHEL-based) / Основной лог
sudo journalctl -u postgresql -f                                          # Systemd logs / Логи systemd
grep "ERROR" /var/log/postgresql/*.log                                    # Find errors / Найти ошибки
```

### Important Paths / Важные пути

```bash
/var/lib/postgresql/<VERSION>/main/                                       # Data directory (Debian/Ubuntu)
/var/lib/pgsql/data/                                                      # Data directory (RHEL-based)
/etc/postgresql/<VERSION>/main/postgresql.conf                            # Main config (Debian/Ubuntu)
/var/lib/pgsql/data/postgresql.conf                                       # Main config (RHEL-based)
/tmp/.s.PGSQL.5432                                                        # Unix socket / Unix-сокет
```

### Default Port / Порт по умолчанию

```bash
5432/tcp                                                                  # PostgreSQL default port / Порт по умолчанию
```

### Firewall / Файрвол

```bash
sudo firewall-cmd --permanent --add-service=postgresql                    # Open PostgreSQL port / Открыть порт
sudo firewall-cmd --reload                                                # Reload firewall / Перезагрузить файрвол
sudo ufw allow 5432/tcp                                                   # UFW: allow PostgreSQL / UFW: разрешить PostgreSQL
```

### Performance / Производительность

```sql
SELECT * FROM pg_stat_activity;                                           -- Active connections / Активные подключения
SELECT pg_cancel_backend(<PID>);                                          -- Cancel query / Отменить запрос
SELECT pg_terminate_backend(<PID>);                                       -- Kill connection / Убить подключение
SELECT * FROM pg_stat_database;                                           -- Database statistics / Статистика баз
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC; -- Table sizes / Размеры таблиц
```

---

## Security / Безопасность

### Role Management / Управление ролями

```sql
CREATE ROLE <USER> WITH LOGIN PASSWORD '<PASSWORD>';                     -- Create user / Создать пользователя
CREATE ROLE <USER> WITH LOGIN PASSWORD '<PASSWORD>' SUPERUSER;           -- Create superuser / Создать суперпользователя
DROP ROLE <USER>;                                                         -- Delete role / Удалить роль
ALTER ROLE <USER> WITH PASSWORD '<NEW_PASSWORD>';                        -- Change password / Сменить пароль
ALTER ROLE <USER> WITH SUPERUSER;                                        -- Grant superuser / Дать права суперпользователя
ALTER ROLE <USER> WITH NOSUPERUSER;                                      -- Revoke superuser / Отозвать права
\du                                                                       -- List roles / Список ролей
```

### Permissions / Права доступа

```sql
GRANT ALL PRIVILEGES ON DATABASE <DB> TO <USER>;                         -- Grant all on DB / Все права на базу
GRANT SELECT, INSERT ON <TABLE> TO <USER>;                               -- Specific privileges / Конкретные права
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO <USER>;           -- All tables in schema / Все таблицы в схеме
REVOKE ALL PRIVILEGES ON DATABASE <DB> FROM <USER>;                      -- Revoke privileges / Отозвать права
\dp <TABLE>                                                               -- Show table permissions / Показать права
```

### SSL Configuration / Настройка SSL

```bash
# Generate SSL certificates / Генерация SSL сертификатов
sudo openssl req -new -x509 -days 365 -nodes -text -out server.crt \
  -keyout server.key -subj "/CN=<HOSTNAME>"
sudo chmod 600 /var/lib/postgresql/<VERSION>/main/server.key             # Set permissions / Установить права
```

**In postgresql.conf:**

```ini
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

---

## Backup & Restore / Бэкап и Восстановление

### pg_dump / Логический бэкап

```bash
# Dump single database / Дамп одной базы
pg_dump -h <HOST> -U <USER> -d <DB> > dump.sql                            # Dump to SQL / Дамп в SQL
pg_dump -h <HOST> -U <USER> -d <DB> | gzip > dump.sql.gz                  # Dump to gzip / Дамп в gzip
pg_dump -h <HOST> -U <USER> -d <DB> -Fc > dump.custom                     # Custom format / Пользовательский формат
pg_dump -h <HOST> -U <USER> -d <DB> -Fd -j 4 -f dumpdir                   # Directory format / Формат директории

# Dump all databases / Дамп всех баз
pg_dumpall -h <HOST> -U <USER> > all_dbs.sql                              # All databases / Все базы
pg_dumpall -h <HOST> -U <USER> --globals-only > globals.sql               # Only roles/tablespaces / Только роли

# Dump specific table / Дамп конкретной таблицы
pg_dump -h <HOST> -U <USER> -d <DB> -t <TABLE> > table_dump.sql           # Table dump / Дамп таблицы
```

### Restore / Восстановление

```bash
psql -h <HOST> -U <USER> -d <DB> < dump.sql                               # Restore from SQL / Восстановить из SQL
gunzip < dump.sql.gz | psql -h <HOST> -U <USER> -d <DB>                   # Restore from gzip / Из gzip
pg_restore -h <HOST> -U <USER> -d <DB> dump.custom                        # Restore custom format / Из custom формата
pg_restore -h <HOST> -U <USER> -d <DB> -Fd -j 4 dumpdir                   # Restore directory format / Из директории
psql -h <HOST> -U <USER> -d postgres < all_dbs.sql                        # Restore all databases / Все базы
```

### Physical Backup (pg_basebackup) / Физический бэкап

```bash
# Base backup / Базовый бэкап
pg_basebackup -h <HOST> -U <USER> -D /backup/pgdata -Ft -z -P             # Tar gzip format / Формат tar gzip
pg_basebackup -h <HOST> -U <USER> -D /backup/pgdata -Fp -Xs -P            # Plain format with WAL / Обычный формат с WAL
```

### WAL Archiving & PITR / Архивирование WAL и восстановление на момент времени

**In postgresql.conf:**

```ini
wal_level = replica
archive_mode = on
archive_command = 'cp %p /archive/%f'
```

**Restore with PITR:**

```bash
# 1. Restore base backup / Восстановить базовый бэкап
sudo systemctl stop postgresql
rm -rf /var/lib/postgresql/<VERSION>/main/*
tar -xzf base.tar.gz -C /var/lib/postgresql/<VERSION>/main/

# 2. Create recovery.signal / Создать recovery.signal
touch /var/lib/postgresql/<VERSION>/main/recovery.signal

# 3. Configure recovery in postgresql.conf / Настроить восстановление
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2025-08-27 12:00:00'

sudo systemctl start postgresql
```

---

## Troubleshooting / Устранение проблем

### Common Issues / Частые проблемы

**Can't connect to PostgreSQL / Не могу подключиться:**

```bash
sudo systemctl status postgresql                                          # Check if running / Проверить запущен ли
sudo netstat -tuln | grep 5432                                            # Check if listening / Проверить прослушивание
sudo tail -f /var/log/postgresql/*.log                                    # Check error log / Проверить лог ошибок
# Check pg_hba.conf for auth rules / Проверить правила аутентификации
```

**Reset postgres password / Сброс пароля postgres:**

```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '<NEW_PASSWORD>';"
```

### Query Analysis / Анализ запросов

```sql
EXPLAIN SELECT * FROM users WHERE name = 'Alice';                         -- Explain query plan / План выполнения запроса
EXPLAIN ANALYZE SELECT * FROM users WHERE name = 'Alice';                 -- Execute and explain / Выполнить и показать план
```

### Database Maintenance / Обслуживание базы

```sql
VACUUM;                                                                   -- Vacuum database / Очистка базы
VACUUM FULL;                                                              -- Full vacuum (locks table) / Полная очистка (блокирует)
VACUUM ANALYZE <TABLE>;                                                   -- Vacuum and analyze / Очистка и анализ
ANALYZE <TABLE>;                                                          -- Update statistics / Обновить статистику
REINDEX TABLE <TABLE>;                                                    -- Rebuild indexes / Перестроить индексы
REINDEX DATABASE <DB>;                                                    -- Rebuild all indexes / Все индексы в базе
```

### Bloat Check / Проверка раздувания

```sql
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;         -- Find largest tables / Найти самые большие таблицы
```

### Monitoring / Мониторинг

```sql
SELECT datname, numbackends FROM pg_stat_database;                        -- Connections per DB / Подключения по базам
SELECT * FROM pg_stat_activity WHERE state = 'active';                    -- Active queries / Активные запросы
SELECT * FROM pg_locks;                                                   -- Locks / Блокировки
SELECT * FROM pg_stat_user_tables;                                        -- Table statistics / Статистика таблиц
```

### Slow Queries / Медленные запросы

**Enable slow query logging in postgresql.conf:**

```ini
log_min_duration_statement = 1000                                         # Log queries > 1s / Логировать запросы > 1с
```

---

## Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/postgresql`

```conf
/var/log/postgresql/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 postgres adm
    sharedscripts
    postrotate
        /usr/lib/postgresql/*/bin/pg_ctl reload -D /var/lib/postgresql/*/main > /dev/null 2>&1 || true
    endscript
}
```

> [!NOTE]
> PostgreSQL typically handles log rotation internally via `log_rotation_age` and `log_rotation_size` in `postgresql.conf`.
> PostgreSQL обычно управляет ротацией логов через `log_rotation_age` и `log_rotation_size` в `postgresql.conf`.

---

