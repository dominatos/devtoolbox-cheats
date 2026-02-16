Title: 🗃️ Oracle Database
Group: Databases
Icon: 🗃️
Order: 10

# Oracle DB Sysadmin Cheatsheet

> **Context:** Oracle Database is a multi-model database management system. / Oracle Database - это мультимодельная система управления базами данных.
> **Role:** Sysadmin / DBA
> **Version:** 19c+

---

## 📚 Table of Contents / Содержание

1. [Environment & Connection](#environment--connection--окружение-и-подключение)
2. [Listener Management](#listener-management--управление-прослушивателем)
3. [Core Management](#core-management--базовое-управление)
4. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
5. [Security](#security--безопасность)
6. [Maintenance & Troubleshooting](#maintenance--troubleshooting--обслуживание-и-проблемы)

---

## 1. Environment & Connection / Окружение и подключение

### Essential Info / Основная информация

*   **Default Port:** `1521` (TCP)
*   **Default User:** `SYS`, `SYSTEM`
*   **Service Name:** `<SID>` or `<SERVICE_NAME>`

### Environment Variables / Переменные окружения
Always ensure these are set before running commands. / Всегда проверяйте их перед запуском команд.

```bash
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=<SID_NAME>
export PATH=$ORACLE_HOME/bin:$PATH
```

### SQL*Plus Connection / Подключение SQL*Plus

```bash
# Connect as SYSDBA (OS Auth) / Подключение как SYSDBA (OS Auth)
sqlplus / as sysdba

# Connect via Network / Подключение по сети
sqlplus <USER>/<PASSWORD>@//<HOST>:1521/<SERVICE_NAME>

# Silent mode (for scripts) / Тихий режим (для скриптов)
sqlplus -s / as sysdba
```

---

## 2. Listener Management / Управление прослушивателем

### lsnrctl Commands / Команды lsnrctl

```bash
# Check Status / Проверить статус
lsnrctl status

# Start Listener / Запустить
lsnrctl start

# Stop Listener / Остановить
lsnrctl stop

# Reload Config (listener.ora) / Перечитать конфиг
lsnrctl reload
```

---

## 3. Core Management / Базовое управление

### Startup & Shutdown / Запуск и Остановка

```sql
-- Startup / Запуск
STARTUP;

-- Shutdown Immediate (Safe) / Безопасная остановка
SHUTDOWN IMMEDIATE;

-- Shutdown Abort (Kill, requires recovery) / Жесткая остановка
SHUTDOWN ABORT;
```

### User Management / Управление пользователями

```sql
-- Create User / Создать пользователя
CREATE USER <USER> IDENTIFIED BY <PASSWORD>;

-- Grant Connect & Resource / Дать права на подключение и ресурсы
GRANT CONNECT, RESOURCE TO <USER>;

-- Unlock Account / Разблокировать аккаунт
ALTER USER <USER> ACCOUNT UNLOCK;

-- Change Password / Сменить пароль
ALTER USER <USER> IDENTIFIED BY <NEW_PASSWORD>;
```

---

## 4. Sysadmin Operations / Операции сисадмина

### Tablespaces / Табличные пространства

```sql
-- List Tablespaces / Список табличных пространств
SELECT tablespace_name, status, contents FROM dba_tablespaces;

-- Check Free Space / Проверка свободного места
SELECT tablespace_name, used_percent FROM dba_tablespace_usage_metrics;

-- Add Datafile / Добавить файл данных
ALTER TABLESPACE <TS_NAME> ADD DATAFILE '/u01/oradata/<SID>/<FILE>.dbf' SIZE 1G AUTOEXTEND ON;
```

### Sessions / Сессии

```sql
-- Active Sessions / Активные сессии
SELECT sid, serial#, username, status, program FROM v$session WHERE status = 'ACTIVE' AND username IS NOT NULL;

-- Kill Session / Убить сессию
ALTER SYSTEM KILL SESSION '<SID>,<SERIAL#>';
```

---

## 5. Security / Безопасность

### Password Expiry / Срок действия пароля

```sql
-- Check Expiry Date / Проверка даты истечения
SELECT username, expiry_date FROM dba_users WHERE username = '<USER>';

-- Set Profile to Unlimited Password Life / Установить профиль с вечным паролем
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
```

---

## 6. Maintenance & Troubleshooting / Обслуживание и проблемы

### Alert Log / Лог алертов
File: `$ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log`

```bash
tail -f $ORACLE_BASE/diag/rdbms/<DB_NAME>/<SID>/trace/alert_<SID>.log
```

### Common Issues / Частые проблемы

**ORA-12541: TNS:no listener / Нет прослушивателя:**
*   Check if listener is running: `lsnrctl status`
*   Start it: `lsnrctl start`

**ORA-01034: ORACLE not available / Oracle недоступен:**
*   Instance is down. Connect as sysdba and run `STARTUP;`.

**Locked Account / Заблокированный аккаунт:**
*   `ALTER USER <USER> ACCOUNT UNLOCK;`

### RMAN (Backup Basics) / RMAN (Основы бэкапа)

```bash
# Connect to target / Подключение к цели
rman target /

# Backup Database / Бэкап БД
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;

# Delete Obsolete Backups / Удалить устаревшие бэкапы
RMAN> DELETE OBSOLETE;
```
