Title: 🗃️ Oracle Database
Group: Databases
Icon: 🗃️
Order: 10

---

> **Oracle Database** is a proprietary, multi-model relational database management system (RDBMS) developed by Oracle Corporation. It is one of the most widely used enterprise databases for OLTP, data warehousing, and mixed workloads. Oracle is known for its advanced features including Real Application Clusters (RAC), Data Guard, and comprehensive PL/SQL support.
>
> **Common use cases / Типичные сценарии:** Enterprise applications, ERP/CRM systems (SAP, Oracle E-Business Suite), financial systems, telecommunications, government.
>
> **Status / Статус:** Actively developed and widely used in enterprise environments. Modern open-source alternatives include **PostgreSQL** (feature-rich, extensible) and **MySQL/MariaDB** (simpler use cases). Cloud-managed alternatives: **AWS RDS for Oracle**, **Oracle Cloud Autonomous Database**.
>
> **Versions / Версии:** Current major release is 23ai (23c). Version 19c remains the most common in production as a Long Term Support release.

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Environment & Connection](#environment--connection)
3. [Listener Management](#listener-management)
4. [Core Management](#core-management)
5. [Sysadmin Operations](#sysadmin-operations)
6. [Security](#security)
7. [Backup & Restore](#backup--restore)
8. [Troubleshooting & Tools](#troubleshooting--tools)
9. [Logrotate Configuration](#logrotate-configuration)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `1521` | Oracle Listener (TNS) — default client connections / Клиентские подключения |
| `1522` | Oracle Listener (secondary, if configured) / Альтернативный порт |
| `5500` | Enterprise Manager Express (EM Express) — web UI / Веб-интерфейс |
| `1158` | Enterprise Manager DB Console (legacy) / Консоль (устаревший) |

### Installation Overview / Обзор установки

> [!IMPORTANT]
> Oracle Database installation requires specific OS prerequisites (kernel parameters, packages, user/group setup). Always follow the official Oracle Installation Guide for your OS version.
> Установка Oracle Database требует определённых системных предпосылок. Всегда следуйте официальному руководству по установке.

```bash
# Prerequisites (RHEL/AlmaLinux) / Предварительные требования
sudo dnf install -y oracle-database-preinstall-19c                         # Install prerequisite package / Установка пакета предпосылок

# Silent installation example / Пример тихой установки
sudo /u01/app/oracle/product/19.0.0/dbhome_1/runInstaller -silent \
  -responseFile /path/to/db_install.rsp                                    # Run silent installer / Тихая установка
```

### Important Paths / Важные пути

| Type / Тип | Path / Путь |
|------------|-------------|
| Oracle Home / Домашняя директория | `/u01/app/oracle/product/19.0.0/dbhome_1` |
| Data Files / Файлы данных | `/u01/oradata/<SID>/` |
| Alert Log / Лог алертов | `$ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log` |
| Listener Config / Конфиг Listener | `$ORACLE_HOME/network/admin/listener.ora` |
| TNS Config / Конфиг TNS | `$ORACLE_HOME/network/admin/tnsnames.ora` |
| SQL*Net Config / Конфиг SQL*Net | `$ORACLE_HOME/network/admin/sqlnet.ora` |
| Init Parameter File / Файл параметров | `$ORACLE_HOME/dbs/init<SID>.ora` or `spfile<SID>.ora` |

### Environment Variables / Переменные окружения

Always ensure these are set before running commands. / Всегда проверяйте их перед запуском команд.

```bash
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1                # Oracle Home directory / Домашняя директория Oracle
export ORACLE_SID=<SID_NAME>                                               # Instance name / Имя инстанса
export ORACLE_BASE=/u01/app/oracle                                         # Oracle Base directory / Базовая директория
export PATH=$ORACLE_HOME/bin:$PATH                                         # Add Oracle binaries to PATH / Добавить в PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH                   # Oracle libraries / Библиотеки Oracle
```

> [!TIP]
> Add these variables to `/home/oracle/.bash_profile` for persistence.
> Добавьте переменные в `/home/oracle/.bash_profile` для постоянного использования.

---

## Environment & Connection

### SQL*Plus Connection / Подключение SQL*Plus

```bash
# Connect as SYSDBA (OS Auth) / Подключение как SYSDBA (OS Auth)
sqlplus / as sysdba

# Connect via Network / Подключение по сети
sqlplus <USER>/<PASSWORD>@//<HOST>:1521/<SERVICE_NAME>

# Connect with TNS name / Подключение с TNS именем
sqlplus <USER>/<PASSWORD>@<TNS_ALIAS>

# Silent mode (for scripts) / Тихий режим (для скриптов)
sqlplus -s / as sysdba

# Connect as SYSOPER / Подключение как SYSOPER
sqlplus / as sysoper
```

### Quick Health Check / Быстрая проверка состояния

```bash
# Check if Oracle is running / Проверить, работает ли Oracle
ps -ef | grep pmon                                                         # PMON process = instance running / PMON = инстанс работает
ps -ef | grep tnslsnr                                                      # Listener process / Процесс Listener
```

---

## Listener Management

### lsnrctl Commands / Команды lsnrctl

```bash
lsnrctl status                                                             # Check listener status / Проверить статус
lsnrctl start                                                              # Start listener / Запустить
lsnrctl stop                                                               # Stop listener / Остановить
lsnrctl reload                                                             # Reload config (listener.ora) / Перечитать конфиг
lsnrctl services                                                           # Show registered services / Показать зарегистрированные сервисы
```

### Listener Configuration / Конфигурация Listener

`$ORACLE_HOME/network/admin/listener.ora`

```text
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = <HOST>)(PORT = 1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = <SERVICE_NAME>)
      (ORACLE_HOME = /u01/app/oracle/product/19.0.0/dbhome_1)
      (SID_NAME = <SID>)
    )
  )
```

---

## Core Management

### Startup & Shutdown / Запуск и Остановка

```sql
-- Startup stages / Этапы запуска
STARTUP;                                                                   -- Full startup / Полный запуск
STARTUP NOMOUNT;                                                           -- Start instance only / Только инстанс
STARTUP MOUNT;                                                             -- Mount database / Примонтировать базу
ALTER DATABASE OPEN;                                                       -- Open database / Открыть базу
```

### Shutdown Modes Comparison / Сравнение режимов остановки

| Mode / Режим | New Connections / Новые подключения | Waits for Sessions / Ожидает сессии | Recovery Needed / Нужно восстановление | Use Case / Применение |
|-------------|-------------------------------------|-------------------------------------|----------------------------------------|----------------------|
| `SHUTDOWN NORMAL` | Blocked / Блокируются | Yes / Да | No / Нет | Clean shutdown / Чистое завершение |
| `SHUTDOWN TRANSACTIONAL` | Blocked / Блокируются | Waits for transactions / Ждёт транзакций | No / Нет | Safe for active txns / Безопасно при активных транзакциях |
| `SHUTDOWN IMMEDIATE` | Blocked / Блокируются | No / Нет | No / Нет | **Recommended for production** / Рекомендуется |
| `SHUTDOWN ABORT` | Blocked / Блокируются | No / Нет | **Yes** / **Да** | Emergency only / Только экстренно |

> [!CAUTION]
> `SHUTDOWN ABORT` is equivalent to pulling the power cord. Instance recovery will run on next startup. Use only when `SHUTDOWN IMMEDIATE` hangs.
> `SHUTDOWN ABORT` — аналог выдёргивания провода. Восстановление инстанса запустится при следующем старте.

```sql
SHUTDOWN IMMEDIATE;                                                        -- Safe shutdown / Безопасная остановка
SHUTDOWN ABORT;                                                            -- Emergency shutdown (requires recovery) / Экстренная остановка
```

### User Management / Управление пользователями

```sql
CREATE USER <USER> IDENTIFIED BY <PASSWORD>;                               -- Create user / Создать пользователя
GRANT CONNECT, RESOURCE TO <USER>;                                         -- Grant connect & resource / Дать права подключения
ALTER USER <USER> ACCOUNT UNLOCK;                                          -- Unlock account / Разблокировать аккаунт
ALTER USER <USER> IDENTIFIED BY <NEW_PASSWORD>;                            -- Change password / Сменить пароль
DROP USER <USER> CASCADE;                                                  -- Drop user and all objects / Удалить пользователя с объектами
SELECT username, account_status FROM dba_users ORDER BY username;          -- List users / Список пользователей
```

---

## Sysadmin Operations

### Service Control (systemd) / Управление сервисом

```bash
sudo systemctl start oracle-database                                       # Start Oracle service / Запустить сервис
sudo systemctl stop oracle-database                                        # Stop Oracle service / Остановить сервис
sudo systemctl status oracle-database                                      # Service status / Статус сервиса
sudo systemctl enable oracle-database                                      # Enable on boot / Автозапуск

# Manual start (as oracle user) / Ручной запуск (от пользователя oracle)
su - oracle
sqlplus / as sysdba <<< "STARTUP;"
lsnrctl start
```

### Tablespaces / Табличные пространства

```sql
SELECT tablespace_name, status, contents FROM dba_tablespaces;             -- List tablespaces / Список табличных пространств
SELECT tablespace_name, used_percent FROM dba_tablespace_usage_metrics;    -- Check free space / Проверка свободного места

-- Add datafile / Добавить файл данных
ALTER TABLESPACE <TS_NAME> ADD DATAFILE '/u01/oradata/<SID>/<FILE>.dbf' SIZE 1G AUTOEXTEND ON;

-- Resize existing datafile / Изменить размер файла данных
ALTER DATABASE DATAFILE '/u01/oradata/<SID>/<FILE>.dbf' RESIZE 2G;
```

> [!WARNING]
> Running out of tablespace causes `ORA-01653` errors and can halt application writes. Monitor tablespace usage proactively.
> Исчерпание пространства таблиц вызывает ошибку `ORA-01653` и может остановить запись приложений.

### Sessions / Сессии

```sql
-- Active sessions / Активные сессии
SELECT sid, serial#, username, status, program, sql_id
FROM v$session WHERE status = 'ACTIVE' AND username IS NOT NULL;

-- Kill session / Убить сессию
ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>';

-- Kill session immediately / Убить сессию немедленно
ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>' IMMEDIATE;
```

> [!CAUTION]
> `KILL SESSION` with `IMMEDIATE` will roll back the transaction. Without `IMMEDIATE`, Oracle waits for the current operation to finish.
> `KILL SESSION` с `IMMEDIATE` откатит транзакцию. Без `IMMEDIATE` Oracle ждёт завершения текущей операции.

### Network & Firewall / Сеть и файрвол

```bash
# Default port: 1521 (TCP) / Порт по умолчанию: 1521

# firewalld / firewalld
sudo firewall-cmd --permanent --add-port=1521/tcp                          # Allow Oracle Listener / Разрешить Oracle Listener
sudo firewall-cmd --permanent --add-port=5500/tcp                          # Allow EM Express / Разрешить EM Express
sudo firewall-cmd --reload                                                 # Reload firewall / Перезагрузить файрвол

# UFW / UFW
sudo ufw allow 1521/tcp                                                    # Allow Oracle Listener / Разрешить Oracle Listener
sudo ufw allow 5500/tcp                                                    # Allow EM Express / Разрешить EM Express
```

### Database Size & Space / Размер базы и пространство

```sql
-- Total database size / Общий размер базы
SELECT ROUND(SUM(bytes)/1024/1024/1024, 2) AS size_gb FROM dba_data_files;

-- Size per tablespace / Размер по табличным пространствам
SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024, 2) AS used_mb,
       ROUND(SUM(maxbytes)/1024/1024, 2) AS max_mb
FROM dba_data_files GROUP BY tablespace_name;
```

---

## Security

### Password Expiry / Срок действия пароля

```sql
-- Check expiry date / Проверка даты истечения
SELECT username, expiry_date, account_status FROM dba_users WHERE username = '<USER>';

-- Set profile to unlimited password life / Установить профиль с вечным паролем
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
```

### Audit Configuration / Настройка аудита

```sql
-- Enable unified audit / Включить единый аудит (Oracle 12c+)
ALTER SYSTEM SET audit_trail = 'DB' SCOPE=SPFILE;

-- Create audit policy / Создать политику аудита
CREATE AUDIT POLICY login_audit
  ACTIONS LOGON, LOGOFF;
AUDIT POLICY login_audit;

-- View audit log / Просмотр аудита
SELECT event_timestamp, dbusername, action_name, return_code
FROM unified_audit_trail
ORDER BY event_timestamp DESC
FETCH FIRST 50 ROWS ONLY;
```

---

## Backup & Restore

### RMAN (Recovery Manager) / RMAN (Менеджер восстановления)

RMAN is the recommended backup tool for Oracle databases. / RMAN — рекомендуемый инструмент резервного копирования для Oracle.

```bash
# Connect to target / Подключение к цели
rman target /

# Connect to target with catalog / Подключение с каталогом
rman target / catalog <USER>/<PASSWORD>@<CATALOG_DB>
```

### Runbook: Full Database Backup / Полный бэкап базы

```bash
rman target / <<EOF
CONFIGURE CONTROLFILE AUTOBACKUP ON;
BACKUP DATABASE PLUS ARCHIVELOG;
EOF
```

### Runbook: Incremental Backup / Инкрементальный бэкап

```bash
rman target / <<EOF
# Level 0 (full baseline) / Уровень 0 (полный базовый)
BACKUP INCREMENTAL LEVEL 0 DATABASE;

# Level 1 (changes since last level 0) / Уровень 1 (изменения с последнего уровня 0)
BACKUP INCREMENTAL LEVEL 1 DATABASE;
EOF
```

### Backup Management / Управление бэкапами

```bash
rman target / <<EOF
# List backups / Список бэкапов
LIST BACKUP SUMMARY;

# Delete obsolete backups / Удалить устаревшие бэкапы
DELETE OBSOLETE;

# Validate backup / Проверить бэкап
VALIDATE BACKUPSET <BACKUP_SET_ID>;

# Crosscheck backups / Перекрёстная проверка
CROSSCHECK BACKUP;
EOF
```

> [!WARNING]
> `DELETE OBSOLETE` removes backups exceeding the retention policy. Ensure your retention policy is correctly configured before running this command.
> `DELETE OBSOLETE` удаляет бэкапы, превышающие политику хранения. Проверьте политику перед выполнением.

### Data Pump (Export/Import) / Data Pump (Экспорт/Импорт)

```bash
# Export full database / Экспорт полной базы
expdp <USER>/<PASSWORD> FULL=YES DIRECTORY=DATA_PUMP_DIR \
  DUMPFILE=full_export_%U.dmp LOGFILE=full_export.log PARALLEL=4

# Export specific schema / Экспорт конкретной схемы
expdp <USER>/<PASSWORD> SCHEMAS=<SCHEMA_NAME> DIRECTORY=DATA_PUMP_DIR \
  DUMPFILE=schema_export.dmp LOGFILE=schema_export.log

# Import / Импорт
impdp <USER>/<PASSWORD> FULL=YES DIRECTORY=DATA_PUMP_DIR \
  DUMPFILE=full_export_%U.dmp LOGFILE=full_import.log PARALLEL=4
```

---

## Troubleshooting & Tools

### Alert Log / Лог алертов

```bash
# Alert Log Path / Путь к логу алертов
# $ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log

tail -f $ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log     # Follow alert log / Следить за логом
grep "ORA-" $ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log | tail -50  # Find errors / Найти ошибки
```

### Common Issues / Частые проблемы

**ORA-12541: TNS:no listener / Нет прослушивателя:**

```bash
lsnrctl status                                                             # Check if listener is running / Проверить прослушиватель
lsnrctl start                                                              # Start listener / Запустить прослушиватель
```

**ORA-01034: ORACLE not available / Oracle недоступен:**

```sql
-- Connect as sysdba and start / Подключиться и запустить
STARTUP;
```

**ORA-28000: Locked Account / Заблокированный аккаунт:**

```sql
ALTER USER <USER> ACCOUNT UNLOCK;                                          -- Unlock account / Разблокировать аккаунт
```

**ORA-01555: Snapshot too old / Снимок слишком старый:**

```sql
-- Increase undo retention / Увеличить время хранения undo
ALTER SYSTEM SET undo_retention=3600 SCOPE=BOTH;                           -- 1 hour / 1 час
```

### Performance Diagnostics / Диагностика производительности

```sql
-- AWR Report (Automatic Workload Repository) / Отчёт AWR
@$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- ASH Report (Active Session History) / Отчёт ASH
@$ORACLE_HOME/rdbms/admin/ashrpt.sql

-- Top SQL by elapsed time / Топ SQL по времени выполнения
SELECT sql_id, elapsed_time, executions, buffer_gets, sql_text
FROM v$sql
ORDER BY elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;
```

---

## Logrotate Configuration

> [!NOTE]
> Oracle manages its alert log and trace files internally. However, you can configure logrotate for listener logs and custom application logs if needed.
> Oracle управляет логами алертов и трейсов самостоятельно. Logrotate можно настроить для логов listener и custom-приложений.

`/etc/logrotate.d/oracle`

```conf
/u01/app/oracle/diag/tnslsnr/*/listener/trace/listener.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 640 oracle oinstall
}
```

> [!TIP]
> Use `adrci` (Automatic Diagnostic Repository Command Interpreter) to manage Oracle diagnostic data and purge old trace files:
> Используйте `adrci` для управления диагностическими данными и очистки старых файлов трассировки:

```bash
adrci exec="SET HOME diag/rdbms/<DB_NAME>/<SID>; PURGE -age 10080 -type TRACE"  # Purge traces older than 7 days / Удалить трейсы старше 7 дней
```

---
