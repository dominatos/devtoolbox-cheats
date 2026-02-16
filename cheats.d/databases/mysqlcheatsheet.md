Title: 🗃️ MySQL/MariaDB
Group: Databases
Icon: 🗃️
Order: 2

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
sudo apt update && sudo apt install -y mysql-server                      # Install MySQL / Установка MySQL
sudo apt install -y mariadb-server                                        # Install MariaDB / Установка MariaDB

# RHEL/AlmaLinux/Rocky
sudo dnf install -y mysql-server                                          # Install MySQL / Установка MySQL
sudo dnf install -y mariadb-server                                        # Install MariaDB / Установка MariaDB
```

### Initial Setup / Первичная настройка

```bash
sudo mysql_secure_installation                                            # Secure installation wizard / Мастер безопасной установки
```

### Configuration / Конфигурация

**Main config file / Основной файл конфигурации:**

```bash
/etc/mysql/my.cnf           # Debian/Ubuntu
/etc/my.cnf                 # RHEL/CentOS/AlmaLinux
```

**Config directory / Директория конфигураций:**

```bash
/etc/mysql/mysql.conf.d/    # Ubuntu/Debian
/etc/my.cnf.d/              # RHEL-based
```

**Common settings / Основные настройки:**

```ini
[mysqld]
bind-address = 127.0.0.1                    # Listen address / Адрес прослушивания
port = 3306                                 # Default port / Порт по умолчанию
max_connections = 200                       # Max connections / Максимум подключений
innodb_buffer_pool_size = 1G                # InnoDB buffer pool / Буфер InnoDB
slow_query_log = 1                          # Enable slow query log / Включить лог медленных запросов
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2                         # Queries > 2s logged / Запросы > 2с логируются
```

---

## Core Management / Управление

### Connection / Подключение

```bash
mysql -h <HOST> -u <USER> -p                                              # Connect to MySQL / Подключение к MySQL
mysql -h <HOST> -u <USER> -p<PASSWORD> <DB>                               # Connect to specific DB / Подключение к базе
mysql --socket=/var/run/mysqld/mysqld.sock -u <USER> -p                  # Connect via socket / Через сокет
```

### Database Operations / Операции с базами

```sql
SHOW DATABASES;                                                           -- List databases / Список баз
CREATE DATABASE <DB_NAME>;                                                -- Create database / Создать базу
USE <DB_NAME>;                                                            -- Switch to database / Переключиться на базу
DROP DATABASE <DB_NAME>;                                                  -- Delete database / Удалить базу
SHOW TABLES;                                                              -- List tables in current DB / Список таблиц
DESCRIBE <TABLE>;                                                         -- Show table structure / Структура таблицы
SHOW CREATE TABLE <TABLE>;                                                -- Show CREATE statement / Показать CREATE
```

### Table Operations / Операции с таблицами

```sql
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100)); -- Create table / Создать таблицу
ALTER TABLE <TABLE> ADD COLUMN <COL> VARCHAR(50);                         -- Add column / Добавить колонку
ALTER TABLE <TABLE> DROP COLUMN <COL>;                                    -- Drop column / Удалить колонку
DROP TABLE <TABLE>;                                                        -- Delete table / Удалить таблицу
TRUNCATE TABLE <TABLE>;                                                    -- Empty table / Очистить таблицу
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
SHOW INDEX FROM <TABLE>;                                                  -- Show indexes / Показать индексы
DROP INDEX idx_name ON users;                                             -- Drop index / Удалить индекс
```

---

## Sysadmin Operations / Операции Сисадмина

### Service Control / Управление сервисом

```bash
sudo systemctl start mysql                                                # Start service / Запустить сервис
sudo systemctl stop mysql                                                 # Stop service / Остановить сервис
sudo systemctl restart mysql                                              # Restart service / Перезапустить сервис
sudo systemctl status mysql                                               # Service status / Статус сервиса
sudo systemctl enable mysql                                               # Enable on boot / Включить автозапуск
```

### Logs / Логи

```bash
sudo tail -f /var/log/mysql/error.log                                     # Error log / Лог ошибок
sudo tail -f /var/log/mysql/slow.log                                      # Slow query log / Лог медленных запросов
sudo journalctl -u mysql -f                                               # Systemd logs / Логи systemd
grep "ERROR" /var/log/mysql/error.log                                     # Find errors / Найти ошибки
```

### Important Paths / Важные пути

```bash
/var/lib/mysql/                                                           # Data directory / Директория данных
/etc/mysql/my.cnf                                                         # Main config / Основной конфиг
/var/log/mysql/                                                           # Logs directory / Директория логов
/var/run/mysqld/mysqld.sock                                               # Unix socket / Unix-сокет
```

### Default Port / Порт по умолчанию

```bash
3306/tcp                                                                  # MySQL/MariaDB default port / Порт по умолчанию
```

### Firewall / Файрвол

```bash
sudo firewall-cmd --permanent --add-service=mysql                         # Open MySQL port / Открыть порт MySQL
sudo firewall-cmd --reload                                                # Reload firewall / Перезагрузить файрвол
sudo ufw allow 3306/tcp                                                   # UFW: allow MySQL / UFW: разрешить MySQL
```

### Performance / Производительность

```sql
SHOW PROCESSLIST;                                                         -- Active connections / Активные подключения
SHOW FULL PROCESSLIST;                                                    -- Detailed processlist / Подробный список
KILL <PROCESS_ID>;                                                        -- Kill query / Убить запрос
SHOW STATUS;                                                              -- Server status / Статус сервера
SHOW VARIABLES;                                                           -- Server variables / Переменные сервера
SHOW ENGINE INNODB STATUS\G                                               -- InnoDB status / Статус InnoDB
```

---

## Security / Безопасность

### User Management / Управление пользователями

```sql
CREATE USER '<USER>'@'localhost' IDENTIFIED BY '<PASSWORD>';              -- Create user / Создать пользователя
CREATE USER '<USER>'@'%' IDENTIFIED BY '<PASSWORD>';                      -- User from any host / С любого хоста
DROP USER '<USER>'@'localhost';                                           -- Delete user / Удалить пользователя
RENAME USER '<OLD_USER>'@'localhost' TO '<NEW_USER>'@'localhost';         -- Rename user / Переименовать
```

### Password Management / Управление паролями

```sql
SET PASSWORD FOR '<USER>'@'localhost' = PASSWORD('<NEW_PASSWORD>');       -- Change password (old syntax) / Сменить пароль
ALTER USER '<USER>'@'localhost' IDENTIFIED BY '<NEW_PASSWORD>';           -- Change password (new syntax) / Новый синтаксис
```

### Permissions / Права доступа

```sql
GRANT ALL PRIVILEGES ON <DB>.* TO '<USER>'@'localhost';                   -- Grant all on DB / Все права на базу
GRANT SELECT, INSERT ON <DB>.<TABLE> TO '<USER>'@'localhost';             -- Specific privileges / Конкретные права
GRANT ALL PRIVILEGES ON *.* TO '<USER>'@'%' WITH GRANT OPTION;            -- Admin user / Администратор
REVOKE ALL PRIVILEGES ON <DB>.* FROM '<USER>'@'localhost';                -- Revoke privileges / Отозвать права
SHOW GRANTS FOR '<USER>'@'localhost';                                     -- Show user grants / Показать права
FLUSH PRIVILEGES;                                                         -- Reload privileges / Перезагрузить права
```

---

## Backup & Restore / Бэкап и Восстановление

### mysqldump

```bash
# Dump single database / Дамп одной базы
mysqldump -h <HOST> -u <USER> -p <DB> > dump.sql                          # Dump to SQL / Дамп в SQL
mysqldump -h <HOST> -u <USER> -p <DB> | gzip > dump.sql.gz                # Dump to gzip / Дамп в gzip

# Dump all databases / Дамп всех баз
mysqldump -h <HOST> -u <USER> -p --all-databases > all_dbs.sql            # All databases / Все базы
mysqldump -h <HOST> -u <USER> -p --all-databases | gzip > all_dbs.sql.gz  # All databases gzipped / Все базы сжатые

# Dump with additional options / Дамп с доп. опциями
mysqldump -h <HOST> -u <USER> -p <DB> \
  --single-transaction \
  --routines \
  --triggers \
  --events > dump_full.sql                                                # Complete dump / Полный дамп

# Dump specific table / Дамп конкретной таблицы
mysqldump -h <HOST> -u <USER> -p <DB> <TABLE> > table_dump.sql            # Table dump / Дамп таблицы
```

### Restore / Восстановление

```bash
mysql -h <HOST> -u <USER> -p <DB> < dump.sql                              # Restore from SQL / Восстановить из SQL
gunzip < dump.sql.gz | mysql -h <HOST> -u <USER> -p <DB>                  # Restore from gzip / Из gzip
mysql -h <HOST> -u <USER> -p --one-database <DB> < all_dbs.sql            # Restore one DB from all / Одну базу из всех
```

### Physical Backup / Физический бэкап

```bash
# Stop MySQL before physical backup / Остановите MySQL перед физическим бэкапом
sudo systemctl stop mysql                                                 # Stop MySQL / Остановить MySQL
sudo tar -czf mysql_backup.tar.gz /var/lib/mysql/                         # Backup data dir / Бэкап директории данных
sudo systemctl start mysql                                                # Start MySQL / Запустить MySQL

# Restore physical backup / Восстановление физического бэкапа
sudo systemctl stop mysql                                                 # Stop MySQL / Остановить MySQL
sudo rm -rf /var/lib/mysql/*                                              # Clear data dir / Очистить директорию
sudo tar -xzf mysql_backup.tar.gz -C /                                    # Extract backup / Распаковать бэкап
sudo chown -R mysql:mysql /var/lib/mysql/                                 # Fix permissions / Исправить права
sudo systemctl start mysql                                                # Start MySQL / Запустить MySQL
```

---

## Troubleshooting / Устранение проблем

### Common Issues / Частые проблемы

**Can't connect to MySQL server / Не могу подключиться:**

```bash
sudo systemctl status mysql                                               # Check if running / Проверить запущен ли
sudo netstat -tuln | grep 3306                                            # Check if listening / Проверить прослушивание
sudo tail -f /var/log/mysql/error.log                                     # Check error log / Проверить лог ошибок
```

**Access denied for user / Доступ запрещен:**

```bash
# Reset root password / Сброс пароля root
sudo systemctl stop mysql
sudo mysqld_safe --skip-grant-tables &
mysql -u root
# Then run: FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '<NEW_PASSWORD>'; FLUSH PRIVILEGES;
sudo systemctl restart mysql
```

### Slow Query Analysis / Анализ медленных запросов

```bash
sudo mysqldumpslow /var/log/mysql/slow.log                                # Analyze slow log / Анализ медленных запросов
```

```sql
EXPLAIN SELECT * FROM users WHERE name = 'Alice';                         -- Explain query plan / План выполнения запроса
SHOW PROFILE FOR QUERY 1;                                                 -- Query profiling / Профилирование запроса
```

### Database Maintenance / Обслуживание базы

```sql
OPTIMIZE TABLE <TABLE>;                                                   -- Optimize table / Оптимизировать таблицу
REPAIR TABLE <TABLE>;                                                     -- Repair table / Восстановить таблицу
ANALYZE TABLE <TABLE>;                                                    -- Analyze table / Анализировать таблицу
CHECK TABLE <TABLE>;                                                      -- Check table / Проверить таблицу
```

### Monitoring / Мониторинг

```bash
mysqladmin -u <USER> -p status                                            # Server status / Статус сервера
mysqladmin -u <USER> -p extended-status                                   # Extended status / Расширенный статус
mysqladmin -u <USER> -p processlist                                       # Process list / Список процессов
mysqladmin -u <USER> -p variables                                         # Server variables / Переменные сервера
```

```sql
SELECT * FROM information_schema.processlist;                             -- Current queries / Текущие запросы
SELECT table_schema AS 'Database', 
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables 
GROUP BY table_schema;                                                    -- Database sizes / Размеры баз
```

---

## Logrotate Configuration / Конфигурация Logrotate

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
        /usr/bin/mysqladmin flush-logs > /dev/null 2>&1 || true
    endscript
}
```

> [!TIP]
> Use `mysqladmin flush-logs` to rotate binary logs: `mysqladmin -u root -p flush-logs`
> Для ротации бинарных логов используйте: `mysqladmin -u root -p flush-logs`

---

