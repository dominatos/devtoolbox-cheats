Title: 🗃️ SQLite
Group: Databases
Icon: 🗃️
Order: 3

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-настройка)
2. [Core Management](#core-management--управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [Backup & Restore](#backup--restore--бэкап-и-восстановление)
5. [Troubleshooting](#troubleshooting--устранение-проблем)

---

## Installation & Configuration / Установка и Настройка

### Install / Установка

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
```

---

## Core Management / Управление

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

CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);                  -- Create table / Создать таблицу
DROP TABLE <TABLE>;                                                       -- Delete table / Удалить таблицу
ALTER TABLE <TABLE> ADD COLUMN <COL> TEXT;                               -- Add column / Добавить колонку
ALTER TABLE <TABLE> RENAME TO <NEW_TABLE>;                               -- Rename table / Переименовать таблицу
```

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

### sqlite3 CLI Commands / Команды CLI

```sql
.help                                                                     -- Show help / Справка
.quit                                                                     -- Exit / Выйти
.mode csv                                                                 -- CSV output mode / Режим вывода CSV
.mode column                                                              -- Column output mode / Режим вывода колонками
.mode insert                                                              -- INSERT statement mode / Режим INSERT
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

---

## Sysadmin Operations / Операции Сисадмина

### File Locations / Расположение файлов

```bash
# SQLite databases are just files / Базы SQLite - это просто файлы
ls -lh *.db                                                               # List database files / Список файлов баз
file <FILE>.db                                                            # Check file type / Проверить тип файла
du -h <FILE>.db                                                           # Check database size / Проверить размер базы
```

### Permissions / Права доступа

```bash
chmod 600 <FILE>.db                                                       # Read/write for owner only / Только владелец
chmod 644 <FILE>.db                                                       # Read for all, write for owner / Чтение всем
chown <USER>:<GROUP> <FILE>.db                                            # Change owner / Сменить владельца
```

### PRAGMA Commands / Команды PRAGMA

```sql
PRAGMA database_list;                                                     -- List attached databases / Список подключенных баз
PRAGMA table_info(<TABLE>);                                               -- Table schema info / Информация о схеме таблицы
PRAGMA index_list(<TABLE>);                                               -- List indexes for table / Список индексов таблицы
PRAGMA foreign_key_list(<TABLE>);                                         -- Foreign keys / Внешние ключи
PRAGMA page_size;                                                         -- Database page size / Размер страницы базы
PRAGMA page_count;                                                        -- Number of pages / Количество страниц
PRAGMA freelist_count;                                                    -- Free pages / Свободные страницы
PRAGMA encoding;                                                          -- Database encoding / Кодировка базы
PRAGMA journal_mode;                                                      -- Journal mode (DELETE/WAL/etc) / Режим журнала
PRAGMA synchronous;                                                       -- Synchronous mode / Режим синхронизации
PRAGMA foreign_keys = ON;                                                 -- Enable foreign keys / Включить внешние ключи
PRAGMA cache_size = 10000;                                                -- Set cache size (pages) / Установить размер кэша
```

### Performance Tuning / Настройка производительности

```sql
PRAGMA journal_mode = WAL;                                                -- Enable WAL mode (better concurrency) / Режим WAL
PRAGMA synchronous = NORMAL;                                              -- Faster writes (less safe) / Быстрее запись
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

---

## Backup & Restore / Бэкап и Восстановление

### Simple Backup / Простой бэкап

```bash
# Copy file (only when DB is not in use) / Копирование файла (только когда база не используется)
cp <FILE>.db <FILE>_backup.db                                             # Copy database file / Копировать файл базы
gzip -c <FILE>.db > <FILE>_backup.db.gz                                   # Compress backup / Сжатый бэкап

# Restore / Восстановление
cp <FILE>_backup.db <FILE>.db                                             # Restore from backup / Восстановить из бэкапа
gunzip < <FILE>_backup.db.gz > <FILE>.db                                  # Restore from gzip / Восстановить из gzip
```

### Online Backup / Онлайн бэкап

```bash
# Using .backup command (safe while DB is in use) / Использование .backup (безопасно во время использования)
sqlite3 <FILE>.db '.backup <FILE>_backup.db'                              # Backup database / Бэкап базы
sqlite3 <FILE>.db '.backup <FILE>_backup.sqlite'                          # Backup with different extension / Другое расширение
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

## Troubleshooting / Устранение проблем

### Common Issues / Частые проблемы

**Database is locked / База заблокирована:**

```bash
# Check for processes using the database / Проверить процессы использующие базу
lsof <FILE>.db
fuser <FILE>.db

# If in WAL mode, check for -wal and -shm files / В режиме WAL проверить файлы
ls -lh <FILE>.db*

# Remove lock (only if no process is using DB) / Удалить блокировку (только если база не используется)
rm <FILE>.db-shm <FILE>.db-wal
```

**Corrupt database / Поврежденная база:**

```bash
# Try integrity check / Проверить целостность
sqlite3 <FILE>.db 'PRAGMA integrity_check;'

# Attempt recovery / Попытка восстановления
sqlite3 <FILE>.db '.dump' | sqlite3 <FILE>_recovered.db                   # Dump and restore / Дамп и восстановление

# If dump fails, try recover / Если дамп не работает
sqlite3 <FILE>.db '.recover' | sqlite3 <FILE>_recovered.db
```

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

### Enable Foreign Keys / Включить внешние ключи

```sql
PRAGMA foreign_keys = ON;                                                 -- Enable foreign key constraints / Включить ограничения FK
PRAGMA foreign_keys;                                                      -- Check if enabled / Проверить включены ли
```

### Monitoring / Мониторинг

```bash
# Watch file size changes / Отслеживать изменения размера
watch -n 1 'ls -lh <FILE>.db'

# Monitor active connections (check processes) / Мониторинг подключений
lsof <FILE>.db
fuser -v <FILE>.db
```
