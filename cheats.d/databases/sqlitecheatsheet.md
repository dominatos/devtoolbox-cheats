Title: 🗃️ SQLite
Group: Databases
Icon: 🗃️
Order: 3

---

## 📚 Table of Contents / Содержание

1. [Description](#description)
2. [Installation & Configuration](#installation--configuration)
3. [Core Management](#core-management)
4. [Sysadmin Operations](#sysadmin-operations)
5. [Security](#security)
6. [Backup & Restore](#backup--restore)
7. [Troubleshooting & Tools](#troubleshooting--tools)
8. [Additional Notes](#additional-notes)

---

## Description

### What is SQLite / Что такое SQLite

**SQLite** is a self-contained, serverless, zero-configuration, transactional SQL database engine. It is the most widely deployed database engine in the world — embedded in virtually every smartphone, web browser, operating system, and countless applications.

**SQLite** — автономный, бессерверный, транзакционный движок SQL-баз данных, не требующий настройки. Это самый распространённый движок баз данных в мире — встроен практически в каждый смартфон, браузер, операционную систему и множество приложений.

### Common Use Cases / Типичные сценарии использования

| Use Case / Сценарий | Description / Описание |
|---|---|
| **Embedded applications** | Mobile apps, desktop software, IoT devices / Мобильные приложения, ПО для настольных ПК, IoT |
| **Configuration storage** | Application settings, browser data, system config / Настройки приложений, данные браузера |
| **Testing & prototyping** | Drop-in replacement for dev/test instead of full RDBMS / Замена полной СУБД в разработке/тестировании |
| **Small-to-medium websites** | Sites with <100K hits/day work perfectly with SQLite / Сайты с <100K запросов/день |
| **Data analysis** | Lightweight analytics on CSV/TSV imports / Лёгкий анализ данных на импортированных CSV |
| **ProxySQL runtime DB** | ProxySQL stores its configuration in SQLite / ProxySQL хранит конфигурацию в SQLite |

### Current Status / Текущий статус

SQLite is actively maintained and is one of the most stable, battle-tested software projects in existence. The developers have committed to supporting it until **at least 2050**. It is **not legacy** — it is the gold standard for embedded/serverless SQL databases.

SQLite активно поддерживается и является одним из самых стабильных и проверенных временем программных проектов. Разработчики обязались поддерживать его как минимум до **2050 года**. Это **не устаревшее ПО** — это золотой стандарт для встроенных/бессерверных SQL-баз данных.

### When NOT to Use SQLite / Когда НЕ стоит использовать SQLite

| Scenario / Сценарий | Recommended Alternative / Рекомендуемая альтернатива |
|---|---|
| **High-concurrency writes** (many simultaneous writers) | PostgreSQL, MySQL/MariaDB |
| **Client-server architecture** (multiple network clients) | PostgreSQL, MySQL/MariaDB |
| **Very large databases** (>1 TB) | PostgreSQL, MySQL/MariaDB |
| **Complex access control** (roles, row-level security) | PostgreSQL |
| **Replication / HA** | PostgreSQL, MySQL with Galera, CockroachDB |

> [!NOTE]
> For embedded use, edge computing, and single-user applications, SQLite remains the **best choice**. Consider alternatives only when you need concurrent network access or enterprise-grade replication.

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y sqlite3                            # Install SQLite / Установка SQLite

# RHEL/AlmaLinux/Rocky
sudo dnf install -y sqlite                                                # Install SQLite / Установка SQLite

# From source / Из исходников
wget https://www.sqlite.org/2025/sqlite-autoconf-<VERSION>.tar.gz
tar -xzf sqlite-autoconf-<VERSION>.tar.gz
cd sqlite-autoconf-<VERSION>/
./configure && make && sudo make install                                  # Compile and install / Компиляция и установка
```

### Check Version / Проверка версии

```bash
sqlite3 --version                                                         # Check SQLite version / Проверить версию
# Sample output / Пример вывода:
# 3.45.1 2024-01-30 16:01:20
```

### Key Characteristics / Ключевые характеристики

| Feature / Характеристика | Value / Значение |
|---|---|
| Default port | **None** — serverless, file-based / Нет — бессерверная, файловая база |
| Max database size | 281 TB (theoretical) |
| Max row size | 1 GB |
| Default page size | 4096 bytes |
| Default journal mode | DELETE |
| Supported SQL | Most of SQL-92 |
| Transactions | ACID-compliant (even on power failure) / ACID-совместимая |
| Concurrency model | Single-writer, multiple-readers / Один писатель, множество читателей |

---

## Core Management

### Database Operations / Операции с базами

```bash
sqlite3 <FILE>.db                                                         # Open/create database / Открыть/создать базу
sqlite3 <FILE>.db '.databases'                                            # Show database info / Информация о базе
sqlite3 <FILE>.db '.quit'                                                 # Exit / Выйти
```

### Table Operations / Операции с таблицами

```sql
.tables                                                                   -- List tables / Список таблиц
.schema <TABLE>                                                           -- Show table schema / Показать схему таблицы
.schema                                                                   -- Show all schemas / Все схемы

CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);                   -- Create table / Создать таблицу
DROP TABLE <TABLE>;                                                       -- Delete table / Удалить таблицу
ALTER TABLE <TABLE> ADD COLUMN <COL> TEXT;                                -- Add column / Добавить колонку
ALTER TABLE <TABLE> RENAME TO <NEW_TABLE>;                                -- Rename table / Переименовать таблицу
```

> [!WARNING]
> SQLite does **not** support `ALTER TABLE DROP COLUMN` in versions below 3.35.0 (2021-03-12). You must recreate the table without the column in older versions.

### CRUD Operations / Операции CRUD

```sql
INSERT INTO users (name) VALUES ('Alice');                                -- Insert row / Вставить строку
SELECT * FROM users WHERE name = 'Alice';                                 -- Select rows / Выбрать строки
UPDATE users SET name = 'Bob' WHERE id = 1;                               -- Update row / Обновить строку
DELETE FROM users WHERE id = 1;                                           -- Delete row / Удалить строку
SELECT COUNT(*) FROM <TABLE>;                                             -- Count rows / Подсчитать строки
```

### Indexes / Индексы

```sql
CREATE INDEX idx_name ON users(name);                                     -- Create index / Создать индекс
CREATE UNIQUE INDEX idx_email ON users(email);                            -- Unique index / Уникальный индекс
.indexes <TABLE>                                                          -- List indexes for table / Индексы таблицы
DROP INDEX idx_name;                                                      -- Drop index / Удалить индекс
```

### Transactions / Транзакции

```sql
BEGIN TRANSACTION;                                                        -- Start transaction / Начать транзакцию
INSERT INTO users (name) VALUES ('Alice');
INSERT INTO users (name) VALUES ('Bob');
COMMIT;                                                                   -- Commit changes / Зафиксировать изменения

BEGIN TRANSACTION;
DELETE FROM users WHERE id > 100;
ROLLBACK;                                                                 -- Rollback changes / Откатить изменения
```

> [!TIP]
> Wrapping bulk `INSERT` operations in a transaction is **dramatically faster** (~50x). Without `BEGIN/COMMIT`, each `INSERT` is auto-committed as a separate transaction with an `fsync()` call.

### Views / Представления

```sql
CREATE VIEW active_users AS                                               -- Create view / Создать представление
    SELECT * FROM users WHERE active = 1;

SELECT * FROM active_users;                                               -- Query view / Запрос к представлению

DROP VIEW active_users;                                                   -- Drop view / Удалить представление
```

### Triggers / Триггеры

```sql
CREATE TRIGGER log_delete AFTER DELETE ON users                           -- Create trigger / Создать триггер
BEGIN
    INSERT INTO audit_log (action, user_id, ts)
    VALUES ('DELETE', OLD.id, datetime('now'));
END;

DROP TRIGGER log_delete;                                                  -- Drop trigger / Удалить триггер
```

### sqlite3 CLI Commands / Команды CLI

```sql
.help                                                                     -- Show help / Справка
.quit                                                                     -- Exit / Выйти
.mode csv                                                                 -- CSV output mode / Режим вывода CSV
.mode column                                                              -- Column output mode / Режим вывода колонками
.mode insert                                                              -- INSERT statement mode / Режим INSERT
.mode json                                                                -- JSON output mode (3.33+) / Режим JSON
.mode markdown                                                            -- Markdown table output (3.33+) / Вывод Markdown таблицей
.headers on                                                               -- Show column headers / Показать заголовки
.timer on                                                                 -- Show query timing / Время выполнения запросов
.output <FILE>                                                            -- Output to file / Вывод в файл
.output stdout                                                            -- Output to stdout / Вывод в консоль
.read <FILE>                                                              -- Execute SQL from file / Выполнить SQL из файла
.dump                                                                     -- Dump database as SQL / Дамп базы в SQL
.dump <TABLE>                                                             -- Dump table as SQL / Дамп таблицы в SQL
```

### Import/Export CSV / Импорт/Экспорт CSV

```bash
# Export to CSV / Экспорт в CSV
sqlite3 <FILE>.db -csv -header "SELECT * FROM users;" > users.csv

# Import CSV / Импорт CSV
sqlite3 <FILE>.db <<EOF
.mode csv
.import users.csv users
EOF
```

### Attach Multiple Databases / Подключение нескольких баз

```sql
ATTACH DATABASE 'other.db' AS other;                                      -- Attach database / Подключить базу
SELECT * FROM other.users;                                                -- Query from attached DB / Запрос из подключенной базы
DETACH DATABASE other;                                                    -- Detach database / Отключить базу
```

> [!TIP]
> Attaching databases lets you run cross-database `JOIN` queries and `INSERT ... SELECT` to migrate data between databases — very powerful for data migration tasks.

---

## Sysadmin Operations

### File Locations / Расположение файлов

```bash
# SQLite databases are just files / Базы SQLite — это просто файлы
ls -lh *.db                                                               # List database files / Список файлов баз
file <FILE>.db                                                            # Check file type / Проверить тип файла
du -h <FILE>.db                                                           # Check database size / Проверить размер базы
```

> [!NOTE]
> SQLite has **no daemon, no service, no ports, and no log files**. The database is a single ordinary file on the filesystem. Associated files (`-wal`, `-shm`, `-journal`) are temporary and created during write operations.

| File / Файл | Purpose / Назначение |
|---|---|
| `<FILE>.db` | Main database file / Основной файл базы данных |
| `<FILE>.db-wal` | Write-Ahead Log (WAL mode only) / Журнал упреждающей записи |
| `<FILE>.db-shm` | Shared-memory index for WAL / Индекс разделяемой памяти для WAL |
| `<FILE>.db-journal` | Rollback journal (DELETE mode) / Журнал отката |

### Permissions / Права доступа

```bash
chmod 600 <FILE>.db                                                       # Read/write for owner only / Только владелец
chmod 644 <FILE>.db                                                       # Read for all, write for owner / Чтение всем
chown <USER>:<GROUP> <FILE>.db                                            # Change owner / Сменить владельца
```

> [!IMPORTANT]
> The process writing to SQLite must have **write permissions on both the database file AND its parent directory**. SQLite creates temporary files (`-journal`, `-wal`, `-shm`) in the same directory.

### PRAGMA Commands / Команды PRAGMA

```sql
PRAGMA database_list;                                                     -- List attached databases / Список подключенных баз
PRAGMA table_info(<TABLE>);                                               -- Table schema info / Информация о схеме таблицы
PRAGMA index_list(<TABLE>);                                               -- List indexes for table / Список индексов таблицы
PRAGMA foreign_key_list(<TABLE>);                                         -- Foreign keys / Внешние ключи
PRAGMA page_size;                                                         -- Database page size / Размер страницы базы
PRAGMA page_count;                                                        -- Number of pages / Количество страниц
PRAGMA freelist_count;                                                    -- Free pages / Свободные страницы
PRAGMA encoding;                                                         -- Database encoding / Кодировка базы
PRAGMA journal_mode;                                                      -- Journal mode (DELETE/WAL/etc) / Режим журнала
PRAGMA synchronous;                                                       -- Synchronous mode / Режим синхронизации
PRAGMA foreign_keys = ON;                                                 -- Enable foreign keys / Включить внешние ключи
PRAGMA cache_size = 10000;                                                -- Set cache size (pages) / Установить размер кэша
```

### Journal Modes Comparison / Сравнение режимов журналирования

SQLite supports several journal modes that affect durability, performance, and concurrency:

| Mode / Режим | Description / Описание | Best For / Лучше всего для |
|---|---|---|
| **DELETE** | Default. Creates rollback journal, deletes after commit / По умолчанию. Создаёт журнал отката, удаляет после коммита | Single-user, simple apps / Простые приложения |
| **WAL** | Write-Ahead Log. Readers don't block writers / Журнал упреждающей записи. Читатели не блокируют писателей | Best concurrency and read performance / Лучшая конкуренция и скорость чтения |
| **TRUNCATE** | Like DELETE but truncates instead of deleting / Как DELETE, но обрезает файл вместо удаления | Slightly faster than DELETE on some filesystems / Чуть быстрее DELETE на некоторых ФС |
| **PERSIST** | Journal file kept but header zeroed / Файл журнала сохраняется, но заголовок обнуляется | Avoids file creation overhead / Избегает накладных расходов на создание файла |
| **MEMORY** | Journal in RAM only — no crash safety / Журнал только в RAM — нет защиты от сбоев | Temporary databases only / Только временные базы |
| **OFF** | No journal at all — dangerous / Без журнала — опасно | Read-only databases / Базы только для чтения |

> [!CAUTION]
> `PRAGMA journal_mode = OFF` and `PRAGMA journal_mode = MEMORY` provide **no crash recovery**. Database corruption will occur if the process crashes or loses power during a write.

### Synchronous Modes Comparison / Сравнение режимов синхронизации

| Mode / Режим | Description / Описание | Safety / Безопасность |
|---|---|---|
| **FULL** | Fsync after every transaction / Fsync после каждой транзакции | Maximum durability / Максимальная надёжность |
| **NORMAL** | Fsync at critical moments only / Fsync только в критические моменты | Safe with WAL mode / Безопасно с режимом WAL |
| **OFF** | No fsync — fastest but risky / Без fsync — быстрее, но рискованно | Data loss on crash / Потеря данных при сбое |

> [!TIP]
> The recommended production setup is `PRAGMA journal_mode = WAL` + `PRAGMA synchronous = NORMAL`. This gives the best performance/durability trade-off.

### Performance Tuning / Настройка производительности

```sql
PRAGMA journal_mode = WAL;                                                -- Enable WAL mode (better concurrency) / Режим WAL
PRAGMA synchronous = NORMAL;                                              -- Faster writes (safe with WAL) / Быстрее запись
PRAGMA temp_store = MEMORY;                                               -- Store temp tables in memory / Временные таблицы в RAM
PRAGMA mmap_size = 268435456;                                             -- Memory-mapped I/O (256MB) / Отображение в память
PRAGMA cache_size = -64000;                                               -- Cache size in KB (-64MB) / Размер кэша в KB
```

### Integrity Check / Проверка целостности

```sql
PRAGMA integrity_check;                                                   -- Full integrity check / Полная проверка целостности
PRAGMA quick_check;                                                       -- Quick integrity check / Быстрая проверка
```

### Analyze & Optimize / Анализ и оптимизация

```sql
ANALYZE;                                                                  -- Update query optimizer statistics / Обновить статистику
VACUUM;                                                                   -- Rebuild database file (reclaim space) / Перестроить базу
```

> [!WARNING]
> `VACUUM` creates a temporary copy of the entire database. Ensure you have **at least 2x the database size** in free disk space before running it, and it holds an exclusive lock during the operation.

---

## Security

### Overview / Обзор

SQLite has **no built-in authentication, users, or roles**. Security is managed entirely through **file system permissions** and optional extensions.

SQLite **не имеет встроенной аутентификации, пользователей или ролей**. Безопасность обеспечивается исключительно через **права файловой системы** и опциональные расширения.

### File-Level Security / Безопасность на уровне файлов

```bash
# Restrict to owner only / Ограничить доступ только владельцу
chmod 600 <FILE>.db                                                       # Owner read/write / Чтение/запись владельцу
chown <USER>:<GROUP> <FILE>.db                                            # Set ownership / Установить владельца

# Restrict directory access / Ограничить доступ к директории
chmod 700 /path/to/db/directory/                                          # Only owner can enter / Вход только владельцу
```

### Encryption (SQLCipher) / Шифрование (SQLCipher)

[SQLCipher](https://www.zetetic.net/sqlcipher/) is the de facto extension for SQLite encryption at rest:

```bash
# Install SQLCipher / Установка SQLCipher
sudo apt install sqlcipher                                                # Ubuntu/Debian
sudo dnf install sqlcipher                                                # RHEL/Fedora

# Create encrypted database / Создать зашифрованную базу
sqlcipher <FILE>.db
> PRAGMA key = '<PASSWORD>';
> CREATE TABLE sensitive (id INTEGER PRIMARY KEY, data TEXT);
> .quit

# Open encrypted database / Открыть зашифрованную базу
sqlcipher <FILE>.db
> PRAGMA key = '<PASSWORD>';
> SELECT * FROM sensitive;
```

### Foreign Key Enforcement / Применение внешних ключей

```sql
PRAGMA foreign_keys = ON;                                                 -- Enable foreign key constraints / Включить ограничения FK
PRAGMA foreign_keys;                                                      -- Check if enabled (0=off, 1=on) / Проверить включены ли
```

> [!IMPORTANT]
> Foreign key constraints are **disabled by default** in SQLite. You must enable them with `PRAGMA foreign_keys = ON` in **every** database connection — the setting is not persisted.

---

## Backup & Restore

### Backup Methods Comparison / Сравнение методов резервирования

| Method / Метод | Online-safe / Онлайн-безопасный | Description / Описание |
|---|---|---|
| **`.backup`** | ✅ Yes | SQLite built-in command, handles locking / Встроенная команда, обрабатывает блокировки |
| **`cp` / file copy** | ⚠️ Only when idle | Raw file copy — may corrupt if DB is in use / Может повредить если БД используется |
| **`.dump` → SQL** | ✅ Yes | SQL text export, portable across versions / Текстовый SQL-экспорт |
| **`VACUUM INTO`** | ✅ Yes (3.27+) | Creates compacted copy atomically / Атомарная компактная копия |

### Simple Backup / Простой бэкап

```bash
# Copy file (only when DB is not in use) / Копирование файла (только когда база не используется)
cp <FILE>.db <FILE>_backup.db                                             # Copy database file / Копировать файл базы
gzip -c <FILE>.db > <FILE>_backup.db.gz                                   # Compress backup / Сжатый бэкап

# Restore / Восстановление
cp <FILE>_backup.db <FILE>.db                                             # Restore from backup / Восстановить из бэкапа
gunzip < <FILE>_backup.db.gz > <FILE>.db                                  # Restore from gzip / Восстановить из gzip
```

> [!CAUTION]
> **Never** `cp` a SQLite database while it is being written to. In WAL mode, you must also copy the `-wal` and `-shm` files together, or use `.backup` instead.

### Online Backup / Онлайн бэкап

```bash
# Using .backup command (safe while DB is in use) / Использование .backup (безопасно во время использования)
sqlite3 <FILE>.db '.backup <FILE>_backup.db'                              # Backup database / Бэкап базы
sqlite3 <FILE>.db '.backup <FILE>_backup.sqlite'                          # Backup with different extension / Другое расширение

# Using VACUUM INTO (3.27+, creates compacted copy) / Компактная копия
sqlite3 <FILE>.db "VACUUM INTO '/backup/<FILE>_backup.db';"               # Compacted backup / Компактный бэкап
```

### Dump/Restore SQL / Дамп/Восстановление SQL

```bash
# Dump to SQL / Дамп в SQL
sqlite3 <FILE>.db .dump > dump.sql                                        # Full database dump / Полный дамп базы
sqlite3 <FILE>.db ".dump <TABLE>" > table_dump.sql                        # Dump single table / Дамп одной таблицы

# Restore from SQL / Восстановление из SQL
sqlite3 <FILE>_new.db < dump.sql                                          # Restore from dump / Восстановить из дампа
```

### Scheduled Backups / Автоматические бэкапы

```bash
#!/bin/bash
# /usr/local/bin/sqlite-backup.sh
BACKUP_DIR="/backups/sqlite"
DB_FILE="/path/to/<FILE>.db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
sqlite3 $DB_FILE ".backup $BACKUP_DIR/backup_$TIMESTAMP.db"
gzip $BACKUP_DIR/backup_$TIMESTAMP.db
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete                           # Delete backups older than 7 days / Удалить старше 7 дней
```

**Cron:**

```bash
0 2 * * * /usr/local/bin/sqlite-backup.sh >> /var/log/sqlite-backup.log 2>&1
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

#### Database is locked / База заблокирована

```bash
# Check for processes using the database / Проверить процессы использующие базу
lsof <FILE>.db
fuser <FILE>.db

# If in WAL mode, check for -wal and -shm files / В режиме WAL проверить файлы
ls -lh <FILE>.db*

# Remove lock (only if no process is using DB) / Удалить блокировку (только если база не используется)
rm <FILE>.db-shm <FILE>.db-wal
```

> [!CAUTION]
> Removing `-wal` and `-shm` files while a process is still writing **will cause data loss**. Always confirm with `lsof` / `fuser` first.

#### Corrupt database / Поврежденная база

```bash
# Try integrity check / Проверить целостность
sqlite3 <FILE>.db 'PRAGMA integrity_check;'

# Attempt recovery / Попытка восстановления
sqlite3 <FILE>.db '.dump' | sqlite3 <FILE>_recovered.db                   # Dump and restore / Дамп и восстановление

# If dump fails, try recover (3.29+) / Если дамп не работает
sqlite3 <FILE>.db '.recover' | sqlite3 <FILE>_recovered.db
```

> [!TIP]
> `.recover` (available since SQLite 3.29) extracts as much data as possible from a corrupt database, including data from pages not referenced by the schema.

### Query Optimization / Оптимизация запросов

```sql
EXPLAIN QUERY PLAN SELECT * FROM users WHERE name = 'Alice';              -- Show query plan / План выполнения запроса
CREATE INDEX idx_name ON users(name);                                     -- Add index to speed up queries / Добавить индекс
ANALYZE;                                                                  -- Update statistics / Обновить статистику
```

### Database Size / Размер базы

```sql
SELECT page_count * page_size AS size FROM pragma_page_count(), pragma_page_size(); -- Database size in bytes / Размер в байтах
```

```bash
du -h <FILE>.db                                                           # Human-readable size / Размер в читаемом виде
ls -lh <FILE>.db                                                          # Detailed file info / Подробная информация
```

### Vacuum to Reclaim Space / Очистка для освобождения места

```sql
VACUUM;                                                                   -- Rebuild database and reclaim space / Перестроить и освободить место
```

```bash
# Before and after vacuum / До и после vacuum
ls -lh <FILE>.db
sqlite3 <FILE>.db 'VACUUM;'
ls -lh <FILE>.db
```

### Monitoring / Мониторинг

```bash
# Watch file size changes / Отслеживать изменения размера
watch -n 1 'ls -lh <FILE>.db'

# Monitor active connections (check processes) / Мониторинг подключений
lsof <FILE>.db
fuser -v <FILE>.db
```

---

## Additional Notes

### Logrotate / Ротация логов

> [!NOTE]
> SQLite is serverless and does not produce log files. Logrotate configuration is **not applicable**. If your application logs SQLite queries, configure logrotate for the **application's** log files instead.

### Common SQLite Files in Production / Типичные SQLite-файлы в production

Many popular services use SQLite internally:

| Service / Сервис | Database Path / Путь к базе |
|---|---|
| **ProxySQL** | `/var/lib/proxysql/proxysql.db` |
| **Grafana** | `/var/lib/grafana/grafana.db` |
| **AWX / Ansible Tower** | Various internal SQLite stores |
| **Firefox** | `~/.mozilla/firefox/<PROFILE>/places.sqlite` |
| **Chrome/Chromium** | `~/.config/google-chrome/Default/History` |
| **GNOME Tracker** | `~/.local/share/tracker/data/` |
| **PHP/Python apps** | Application-specific paths |

### SQLite vs Full RDBMS Comparison / Сравнение SQLite с полноценными СУБД

| Feature / Функция | SQLite | MySQL/MariaDB | PostgreSQL |
|---|---|---|---|
| **Architecture** | Serverless / Бессерверная | Client-Server / Клиент-Сервер | Client-Server / Клиент-Сервер |
| **Setup** | Zero config / Нулевая настройка | Requires installation | Requires installation |
| **Concurrent writes** | ❌ Single writer | ✅ Multiple writers | ✅ Multiple writers |
| **Network access** | ❌ Local file only | ✅ Network protocol | ✅ Network protocol |
| **Access control** | ❌ File permissions only | ✅ Users/roles/grants | ✅ Users/roles/RLS |
| **Replication** | ❌ (3rd-party: Litestream) | ✅ Native | ✅ Native |
| **JSON support** | ✅ (json1 extension) | ✅ Native | ✅ Native (JSONB) |
| **Full-text search** | ✅ (FTS5) | ✅ (InnoDB FTS) | ✅ (tsvector) |
| **Max DB size** | 281 TB | Unlimited (per storage) | Unlimited (per storage) |
