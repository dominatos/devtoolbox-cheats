Title: 🗃️ MySQL/MariaDB & Cluster
Group: Databases
Icon: 🗃️
Order: 2

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-настройка)
2. [MySQL Cluster Setup](#mysql-cluster-setup--установка-и-настройка-mysql-cluster)
3. [Core Management](#core-management--управление)
4. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
5. [Security](#security--безопасность)
6. [Backup & Restore](#backup--restore--бэкап-и-восстановление)
7. [Troubleshooting & Tools](#troubleshooting--tools--устранение-проблем-и-инструменты)
8. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## Installation & Configuration / Установка и настройка

### Package Installation / Установка пакетов

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

### Configuration Files / Файлы конфигурации

| OS / ОС | Main Config Path / Основной путь |
|---------|---------------------------------|
| Ubuntu/Debian | `/etc/mysql/my.cnf` |
| RHEL-based | `/etc/my.cnf` |
| Custom Configs | `/etc/mysql/mysql.conf.d/` or `/etc/my.cnf.d/` |

### Common Settings / Основные настройки
`/etc/mysql/my.cnf` or `/etc/my.cnf`

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

### Storage Engines Comparison / Сравнение движков хранилищ

| Feature / Особенность | InnoDB | MyISAM | NDB (Cluster) |
|----------------------|--------|--------|---------------|
| Transactions / Транзакции | Yes / Да | No / Нет | Yes / Да |
| Locking / Блокировки | Row-level / Строки | Table-level / Таблицы | Row-level / Строки |
| High Availability / Отказоустойчивость | Manual / Ручная | No / Нет | Native / Нативная |
| Main Use Case / Применение | General purpose / Общее | Read-heavy / Чтение | High-load HA / Высокая доступность |

---

## MySQL Cluster Setup / Установка и настройка MySQL Cluster

**MySQL Cluster** — это высокодоступная база данных с синхронной репликацией и in-memory хранением данных.

### Architecture Components / Компоненты архитектуры

- **Management Node (MGM)** – Controls cluster, configuration, and node status / Контролирует кластер и состояние нод.
- **Data Node (NDBD)** – Stores data, multiple nodes for replication / Хранит данные, репликация.
- **SQL Node (mysqld)** – Standard MySQL server for application connections / Обычный MySQL для приложений.

### Proposed Architecture / Пример архитектуры

| Role / Роль | IP | Node ID |
|-------------|----|---------|
| Management (MGM) | `<IP_MGM>` | 1 |
| Data Node 1 | `<IP_DATA_1>` | 2 |
| Data Node 2 | `<IP_DATA_2>` | 3 |
| SQL Node | `<IP_SQL>` | 4 |

### Installation / Установка

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install mysql-cluster-community-management-server \
                 mysql-cluster-community-data-node \
                 mysql-client                                             # Install Cluster packages / Установка пакетов кластера
```

#### RHEL/CentOS/AlmaLinux:
```bash
sudo dnf install https://repo.mysql.com/mysql80-community-release-el9-3.noarch.rpm
sudo dnf module disable mysql
sudo dnf install mysql-cluster-community-management-server \
                 mysql-cluster-community-data-node \
                 mysql-cluster-community-client                           # Install Cluster packages / Установка пакетов кластера
```

### Configuration: Management Node / Настройка Management Node
`/var/lib/mysql-cluster/config.ini`

```ini
[NDBD DEFAULT]
NoOfReplicas=2

[MYSQLD DEFAULT]
ServerPort=3306

[MANAGEMENT]
HostName=<IP_MGM>
NodeId=1

[NDBD]
HostName=<IP_DATA_1>
NodeId=2

[NDBD]
HostName=<IP_DATA_2>
NodeId=3

[MYSQLD]
HostName=<IP_SQL>
NodeId=4
```

### Runbook: Starting the Cluster / Запуск кластера

1. **Start Management Node / Запуск MGM:**
   ```bash
   sudo ndb_mgmd -f /var/lib/mysql-cluster/config.ini --initial           # Initial start / Первый запуск
   sudo systemctl enable ndb_mgmd && sudo systemctl start ndb_mgmd       # Enable and start / Включить и запустить
   ```

2. **Start Data Nodes (on <IP_DATA_1>, <IP_DATA_2>) / Запуск Data нод:**
   `/etc/my.cnf`
   ```ini
   [mysqld]
   ndbcluster
   [NDBD]
   connect-string=<IP_MGM>
   ```
   ```bash
   sudo ndbd                                                              # Start data node / Запуск data ноды
   ```

3. **Start SQL Node / Запуск SQL ноды:**
   `/etc/my.cnf`
   ```ini
   [mysqld]
   ndbcluster
   ndb-connectstring=<IP_MGM>                                             # Connect to MGM IP / Подключение к MGM
   ```
   ```bash
   sudo systemctl enable mysql && sudo systemctl start mysql             # Start MySQL / Запуск MySQL
   ```

### Verify Status / Проверка статуса

```bash
ndb_mgm -e show                                                           # Show cluster status / Показать статус кластера
```

---

## Core Management / Управление

### Connection / Подключение

```bash
mysql -h <HOST> -u <USER> -p                                              # Connect to MySQL / Подключение к MySQL
mysql -h <HOST> -u <USER> -p<PASSWORD> <DB>                               # Connect to specific DB / Подключение к базе
mysql --socket=/var/run/mysqld/mysqld.sock -u <USER> -p                  # Connect via socket / Через сокет
```

### Database & Table Operations / Операции с БД и таблицами

```sql
SHOW DATABASES;                                                           -- List databases / Список баз
CREATE DATABASE <DB_NAME>;                                                -- Create database / Создать базу
USE <DB_NAME>;                                                            -- Switch to database / Переключиться на базу
SHOW TABLES;                                                              -- List tables / Список таблиц
DESCRIBE <TABLE>;                                                         -- Table structure / Структура таблицы
SHOW CREATE TABLE <TABLE>;                                                -- CREATE statement / Показать SQL создания
DROP TABLE <TABLE>;                                                        -- Delete table / Удалить таблицу
```

### Working with Cluster Tables / Работа с таблицами в кластере

> [!IMPORTANT]
> All cluster tables must use `ENGINE=NDBCLUSTER`.

```sql
CREATE TABLE users (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR(50)
) ENGINE=NDBCLUSTER;                                                      -- Create cluster table / Создать таблицу в кластере
```

---

## Sysadmin Operations / Операции сисадмина

### Service Control / Управление сервисом

```bash
sudo systemctl start mysql                                                # Start service / Запустить сервис
sudo systemctl stop mysql                                                 # Stop service / Остановить сервис
sudo systemctl restart mysql                                              # Restart service / Перезапустить сервис
sudo systemctl status mysql                                               # Service status / Статус сервиса
sudo systemctl enable mysql                                               # Enable on boot / Включить автозапуск
```

### Runbook: Emergency Restart / Экстренный перезапуск

> [!CAUTION]
> Restarting in production can drop active connections. Always check load first.

```bash
# 1. Check current load / Проверить текущую нагрузку
mysqladmin -u <USER> -p status
# 2. Graceful restart / Обычный перезапуск
sudo systemctl restart mysql
# 3. If stuck, force kill (Extreme cases) / Если завис - принудительно (Экстрим)
sudo killall -9 mysqld
sudo systemctl start mysql
```

### Logs & Paths / Логи и пути

| Type / Тип | Path / Путь |
|------------|-------------|
| Data Directory / Данные | `/var/lib/mysql/` |
| Error Log / Ошибки | `/var/log/mysql/error.log` |
| Slow Query Log / Медленные | `/var/log/mysql/slow.log` |
| Unix Socket / Сокет | `/var/run/mysqld/mysqld.sock` |

### Network & Firewall / Сеть и Файрвол

```bash
# Default Port: 3306 / Порт по умолчанию: 3306
sudo ufw allow 3306/tcp                                                   # UFW: allow MySQL / UFW: разрешить MySQL
sudo firewall-cmd --permanent --add-service=mysql && sudo firewall-cmd --reload # RHEL Firewall
```

---

## Security / Безопасность

### User Management / Управление пользователями

```sql
CREATE USER '<USER>'@'localhost' IDENTIFIED BY '<PASSWORD>';              -- Create local user / Создать локального пользователя
CREATE USER '<USER>'@'%' IDENTIFIED BY '<PASSWORD>';                      -- Remote user / Удаленный пользователь
GRANT ALL PRIVILEGES ON <DB>.* TO '<USER>'@'localhost';                   -- Grant access / Выдать права
REVOKE ALL PRIVILEGES ON <DB>.* FROM '<USER>'@'localhost';                -- Revoke access / Отозвать права
SHOW GRANTS FOR '<USER>'@'localhost';                                     -- Show grants / Показать права
FLUSH PRIVILEGES;                                                         -- Reload / Перезагрузить права
```

### Runbook: Reset Root Password / Сброс пароля Root

```bash
# 1. Stop service / Остановить сервис
sudo systemctl stop mysql
# 2. Start in bypass mode / Запустить без проверки прав
sudo mysqld_safe --skip-grant-tables &
# 3. Connect and reset / Подключиться и сбросить
mysql -u root
# SQL commands:
# FLUSH PRIVILEGES;
# ALTER USER 'root'@'localhost' IDENTIFIED BY '<NEW_PASSWORD>';
# FLUSH PRIVILEGES;
# 4. Restart normally / Перезапустить нормально
sudo systemctl restart mysql # Note: may need to kill mysqld_safe process first
```

---

## Backup & Restore / Бэкап и восстановление

### Backup Methods Comparison / Сравнение методов бэкапа

| Method / Метод | Tools / Инструменты | Advantages / Плюсы | Disadvantages / Минусы |
|----------------|-------------------|--------------------|------------------------|
| Logical / Логический | `mysqldump` | Human-readable, portable / Понятный, переносимый | Slow for large DBs / Медленно для больших БД |
| Physical / Физический | `tar`, `cp`, `XtraBackup` | Very fast / Очень быстро | Less portable / Менее переносимый |
| Cluster Backup | `ndb_mgm` (START BACKUP) | Consistent cluster state / Консистентный для кластера | Requires NDB / Только для NDB |

### mysqldump Samples / Примеры mysqldump

```bash
mysqldump -u <USER> -p <DB> > dump.sql                                    # Dump DB / Дамп одной базы
mysqldump -u <USER> -p --all-databases | gzip > all_dbs.sql.gz            # All DBs gzipped / Все базы сжатые
```

### Restore / Восстановление

```bash
mysql -u <USER> -p <DB> < dump.sql                                        # Restore from SQL / Восстановить из SQL
gunzip < dump.sql.gz | mysql -u <USER> -p <DB>                            # Restore from gzip / Из gzip
```

---

## Troubleshooting & Tools / Устранение проблем и инструменты

### Monitoring / Мониторинг

```sql
SHOW FULL PROCESSLIST;                                                    -- View active queries / Просмотр активных запросов
KILL <PROCESS_ID>;                                                        -- Terminate query / Принудительно завершить запрос
SHOW STATUS;                                                              -- Global server status / Общий статус сервера
SHOW ENGINE INNODB STATUS\G                                               -- Detailed InnoDB status / Подробный статус InnoDB
```

### Performance Analysis / Анализ производительности

```bash
sudo mysqldumpslow /var/log/mysql/slow.log                                # Analyze slow queries / Анализ медленных запросов
```

```sql
EXPLAIN SELECT * FROM users WHERE name = '<USER>';                        -- Query execution plan / План выполнения запроса
ANALYZE TABLE <TABLE>;                                                    -- Update statistics / Обновить статистику
OPTIMIZE TABLE <TABLE>;                                                   -- Rebuild table index / Перестроить индекс таблицы
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
