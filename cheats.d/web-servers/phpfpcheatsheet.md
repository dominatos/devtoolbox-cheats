---
Title: 🔌 php-fpm — PHP Process Manager
Group: "Web Servers"
Icon: 🔌
Order: 10
tags:
  - web
  - php
  - php-fpm
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

# 🔌 php-fpm Cheatsheet

## Description

**PHP-FPM** (FastCGI Process Manager) is the production process manager for PHP applications. It replaces mod_php and provides pool-based process management, slow-log debugging, and status pages. / **PHP-FPM** — production process manager для PHP. Замена mod_php: управление процессами по пулам, slow-log, status-страницы.

**Common use cases / Типовые сценарии:**
- Serve PHP apps via Nginx/Apache FastCGI / Обслуживание PHP через Nginx/Apache
- Per-pool user isolation / Изоляция пользователей по пулам
- Production status/health checks / Production status/health-checks
- Slow request debugging / Отладка медленных запросов

**Status:** Actively maintained with PHP. Alternatives: **mod_php** (legacy), **Apache prefork + php-cgi**, **HHVM** (legacy), **RoadRunner/Swoole** (async PHP). / **Статус:** активно развивается; альтернативы — mod_php (legacy), RoadRunner/Swoole.

**Default ports:** `9000/tcp` (FastCGI TCP) or Unix socket `/run/php/php*-fpm.sock`.  
**Paths:** pool config `/etc/php/X.Y/fpm/pool.d/www.conf` (Debian) or `/etc/php-fpm.d/www.conf` (RHEL).

Cross-reference: [Nginx](nginxcheatsheet.md), [Apache](apachecheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md), [journalctl](../system-logs/journalctlcheatsheet.md).

---

## Installation

### Install php-fpm / Установка php-fpm

```bash
# Debian/Ubuntu
apt install php-fpm php-cli php-mysql php-xml php-curl

# RHEL/Rocky/Alma/Fedora
dnf install php-fpm php-cli php-mysqlnd php-xml
```

```bash
php-fpm -v
systemctl enable --now php8.3-fpm    # Debian versioned unit
# RHEL:
systemctl enable --now php-fpm
```

---

## Configuration

### Main files / Основные файлы

`/etc/php/X.Y/fpm/php.ini`

`/etc/php/X.Y/fpm/pool.d/www.conf`

`/etc/php-fpm.conf`

`/etc/php-fpm.d/www.conf`

`/var/log/php*-fpm.log`

`/run/php/php*-fpm.sock`

### Pool config / Конфигурация пула

`/etc/php/8.3/fpm/pool.d/www.conf`

```bash
[www]
user = www-data
group = www-data

listen = /run/php/php8.3-fpm.sock
listen.owner = www-data
listen.group = www-data
; listen = 9000
; listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.status_path = /status
ping.path = /ping
access.log = /var/log/php8.3-fpm-www-access.log
slowlog = /var/log/php8.3-fpm-www-slow.log
request_slowlog_timeout = 5s
php_admin_value[error_log] = /var/log/php8.3-fpm-www-error.log
php_admin_flag[log_errors] = on
```

```bash
systemctl restart php8.3-fpm
```

### Nginx FastCGI / Nginx FastCGI

```bash
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    # fastcgi_pass 127.0.0.1:9000;
}
```

---

## Core Management

### Status and ping / Статус и ping

```bash
curl -s http://127.0.0.1/status
curl -s http://127.0.0.1/ping
# Via Nginx location restricted to localhost
```

Sample status output:

```text
pool:                 www
process manager:      dynamic
start time:           02/Oct/2026 12:00:00
start since:          3600
accepted conn:        12345
listen queue:         0
max listen queue:     2
max processes:        50
```

### Pool management / Управление пулами

```bash
php-fpm -t              # Test config
php-fpm -D              # Daemonize (if not systemd)
systemctl reload php8.3-fpm
```

---

## Sysadmin Operations

### Logs / Логи

```bash
tail -f /var/log/php8.3-fpm-www-error.log
tail -f /var/log/php8.3-fpm-www-slow.log
journalctl -u php8.3-fpm --no-pager -n 50
```

### Logrotate / Ротация логов

`/etc/logrotate.d/php8.3-fpm`

```bash
/var/log/php8.3-fpm*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl kill -s USR2 php8.3-fpm >/dev/null 2>&1 || true
    endscript
}
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Run pools as dedicated non-root users / Запускайте пулы от non-root
2. Restrict status/ping to localhost / Ограничьте status/ping localhost
3. Disable dangerous functions in php.ini / Отключите опасные функции
4. Limit `pm.max_children` to RAM budget / Ограничьте max_children по RAM
5. Enable slowlog for debugging / Включите slowlog
6. Keep PHP updated (security releases) / Обновляйте PHP
7. Use open_basedir where appropriate / Используйте open_basedir

```bash
; php.ini hardening
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
open_basedir = /var/www/<APP>/:/tmp/
expose_php = Off
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/php-fpm-config-$(date +%F).tar.gz \
  /etc/php/8.3/fpm /etc/php-fpm.conf /etc/php-fpm.d 2>/dev/null
```

### Restore / Восстановление

```bash
systemctl stop php8.3-fpm
tar xzf /var/backups/php-fpm-config-<DATE>.tar.gz -C /
php-fpm -t
systemctl start php8.3-fpm
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| 502 Bad Gateway | FPM down / socket perms | `systemctl status php*-fpm` |
| 403 Forbidden | Wrong pool user/permissions | Check listen.owner, docroot perms |
| High load | max_children too low/high | Tune pm.dynamic values |
| Slow requests | App code / DB | Check slowlog |
| Status 404 | status_path not exposed | Add Nginx location for /status |

```bash
php-fpm -t
ss -xp | grep php-fpm
curl -s http://127.0.0.1/status | head
journalctl -u php8.3-fpm -n 30
```

---

## Comparison Tables

### PHP process managers / PHP process managers

| Manager | Model | Notes |
| :--- | :--- | :--- |
| **php-fpm** | Dedicated pools | Production standard |
| **mod_php** | Apache module | Legacy, less isolated |
| **php-cgi** | CGI spawn | Slower, legacy |
| **RoadRunner** | Persistent workers | Async, high perf |
| **Swoole** | Extension | Coroutine PHP |

---

## Production Runbooks

### Runbook: New PHP app pool / Новый пул для PHP-приложения

1. Create dedicated system user / Создать системного пользователя
2. Copy www.conf to `<APP>.conf`; set user/listen/pool / Настроить пул
3. `php-fpm -t` then reload / Проверить и перезагрузить
4. Configure Nginx `fastcgi_pass` to new socket/port / Настроить Nginx
5. Verify status endpoint and app response / Проверить статус и ответ
6. Set slowlog threshold for the app / Задать порог slowlog

### Runbook: Tune FPM under load / Тюнинг FPM под нагрузкой

1. Measure current RAM: `pm.max_children` × average PHP process RSS / Замерить RSS
2. Adjust `pm.start_servers`, `min/max_spare_servers` / Настроить spare
3. Reload FPM; watch `listen queue` in status / Проверить listen queue
4. Add slowlog for remaining slow requests / Включить slowlog
5. Document final values in config management / Зафиксировать значения

---

## Documentation Links

- PHP-FPM docs — https://www.php.net/manual/en/install.fpm.php
- PHP-FPM status — https://www.php.net/manual/en/install.fpm.configuration.php
- Nginx PHP — https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html
- PHP security — https://www.php.net/manual/en/security.php
