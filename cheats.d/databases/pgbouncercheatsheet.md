---
Title: 🔀 PgBouncer — PostgreSQL Pooler
Group: Databases
Icon: 🔀
Order: 16
tags:
  - databases
  - postgresql
  - pgbouncer
  - pooling
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🔀 PgBouncer Cheatsheet

## Description

**PgBouncer** is a lightweight **connection pooler for PostgreSQL**. It multiplexes many client connections over a limited pool of server connections — critical for high-connection apps (PHP, serverless, microservices). / **PgBouncer** — лёгкий pooler соединений PostgreSQL. Мультиплексирует множество клиентских соединений поверх ограниченного пула серверных — критично для high-connection приложений.

**Common use cases / Типовые сценарии:**
- Reduce PostgreSQL connection storms / Снижение «штормов» соединений PostgreSQL
- Serverless / Lambda DB access / Доступ к БД из serverless
- Transaction-mode pooling for stateless apps / Transaction-mode для stateless apps
- Protect PostgreSQL from too many backends / Защита PostgreSQL от избыточных backend

**Status:** Actively maintained (Cybertec / PostgreSQL community). Alternatives: **Odyssey**, **pgcat** (Rust), **Supavisor**. / **Статус:** активно развивается; альтернативы — Odyssey, pgcat, Supavisor.

**Default ports:** `6432/tcp`.  
**Paths:** config `/etc/pgbouncer/pgbouncer.ini`; userlist `/etc/pgbouncer/userlist.txt`.

Cross-reference: [PostgreSQL](postgrescheatsheet.md), [ProxySQL](proxysqlcheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md).

---

## Installation

### Install PgBouncer / Установка PgBouncer

```bash
# Debian/Ubuntu
apt install pgbouncer

# RHEL/Rocky/Alma/Fedora
dnf install pgbouncer
```

```bash
pgbouncer --version
systemctl enable --now pgbouncer
```

---

## Configuration

### Main files / Основные файлы

`/etc/pgbouncer/pgbouncer.ini`

`/etc/pgbouncer/userlist.txt`

### pgbouncer.ini / pgbouncer.ini

`/etc/pgbouncer/pgbouncer.ini`

```bash
[databases]
<DB_NAME> = host=<PG_HOST> port=5432 dbname=<DB_NAME>

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
reserve_pool_size = 5
reserve_pool_timeout = 3
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60
admin_users = pgbouncer_admin
```

### userlist.txt / userlist.txt

`/etc/pgbouncer/userlist.txt`

```bash
"pgbouncer_admin" "SCRAM-SHA-256:<SECRET_KEY>"
"app_user" "md5<HASH>"
```

```bash
systemctl restart pgbouncer
```

### Pool modes / Режимы пула

| Mode | Use case | Notes |
| :--- | :--- | :--- |
| **session** | Stateful apps / prepared statements | Safest, least pooling |
| **transaction** | Stateless apps | Default for most web apps |
| **statement** | Simple stateless | Risky with multi-statement tx |

> [!WARNING]
> `statement` mode breaks any app that relies on session state (temp tables, prepared statements across statements). / **`statement` mode ломает приложения с session-state.**

---

## Core Management

### Console / Консоль

```bash
psql "host=127.0.0.1 port=6432 dbname=pgbouncer user=pgbouncer_admin"
# Then:
SHOW DATABASES;
SHOW POOLS;
SHOW STATS;
SHOW CLIENTS;
SHOW SERVERS;
RELOAD;
SHOW CONFIG;
```

### CLI / CLI

```bash
psql -h 127.0.0.1 -p 6432 -U pgbouncer_admin pgbouncer -c 'SHOW STATS;'
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u pgbouncer --no-pager -n 50
tail -f /var/log/postgresql/pgbouncer.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/pgbouncer`

```bash
/var/log/postgresql/pgbouncer.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 postgres postgres
}
```

---

## Security

### Hardening / Ужесточение

1. Bind to localhost or private NIC / Привязывайте к localhost/VPC
2. Use scram-sha-256 auth / Используйте scram-sha-256
3. Restrict admin_users / Ограничьте admin_users
4. Monitor pool saturation / Мониторьте насыщение пула
5. Do not expose 6432 publicly / Не выставляйте 6432 наружу

```bash
# listen_addr = 127.0.0.1
# auth_type = scram-sha-256
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/pgbouncer-$(date +%F).tar.gz /etc/pgbouncer
```

### Restore / Восстановление

```bash
systemctl stop pgbouncer
tar xzf /var/backups/pgbouncer-<DATE>.tar.gz -C /
systemctl start pgbouncer
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `no more connections allowed` | max_client_conn reached | Raise limit or fix client leak |
| Auth failures | userlist hash mismatch | Regenerate userlist |
| Pool starvation | default_pool_size too small | Increase pool size |
| `database is not a valid name` | wrong [databases] key | Check pgbouncer.ini |
| High server connections | pool_mode=session | Switch to transaction mode |

```bash
psql -h 127.0.0.1 -p 6432 -U pgbouncer_admin pgbouncer -c 'SHOW POOLS;'
journalctl -u pgbouncer -n 30
```

---

## Comparison Tables

### Connection poolers / Connection poolers

| Tool | Language | Notes |
| :--- | :--- | :--- |
| **PgBouncer** | C | Lightweight, battle-tested |
| **Odyssey** | C | Advanced routing |
| **pgcat** | Rust | Modern, features-rich |
| **Supavisor** | Elixir | Supabase stack |

---

## Production Runbooks

### Runbook: Add new database / Новая база в pooler

1. Create app user in PostgreSQL / Создать пользователя в PostgreSQL
2. Add `[databases]` entry in pgbouncer.ini / Добавить запись в databases
3. Update userlist.txt with SCRAM hash / Обновить userlist
4. `RELOAD;` via console or restart / Перезагрузить конфиг
5. Test connect via 6432 / Проверить подключение
6. Document pool size for the app / Зафиксировать размер пула

### Runbook: Pool saturation incident / Инцидент насыщения пула

1. `SHOW POOLS` — identify saturated pool / Найти насыщенный пул
2. Check PostgreSQL max_connections / Проверить max_connections
3. Increase default_pool_size if headroom exists / Увеличить default_pool_size
4. Fix client connection leaks / Исправить утечки клиентских соединений
5. Consider transaction mode if session / Перейти на transaction mode
6. Document capacity limits / Зафиксировать лимиты

---

## Documentation Links

- PgBouncer docs — https://www.pgbouncer.org/config.html
- PgBouncer GitHub — https://github.com/pgbouncer/pgbouncer
- PostgreSQL connection pooling — https://www.postgresql.org/docs/current/runtime-connection.html
