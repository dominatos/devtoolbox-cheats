---
Title: 📦 supervisord — Process Manager
Group: "System & Logs"
Icon: 📦
Order: 22
tags:
  - process
  - supervisor
  - supervisord
  - daemon
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 📦 supervisord Cheatsheet

## Description

**supervisord** is a client/server system to **control UNIX processes** (daemons). Monitors and restarts processes, manages logs, and provides a web/XML-RPC interface. / **supervisord** — клиент-серверная система управления UNIX-процессами (демонами). Мониторинг, перезапуск, управление логами, web/XML-RPC-интерфейс.

**Common use cases / Типовые сценарии:**
- Keep app daemons running / Поддержание приложений запущенными
- Multi-process apps without systemd / Мультисервисные приложения без systemd
- Development environment process control / Управление процессами в dev
- Legacy app supervision / Супервизия легаси-приложений

**Status:** Maintained (Supervisord upstream). Alternatives: **systemd**, **runit**, **s6**, **pm2** (Node), **Docker restart policies**. / **Статус:** поддерживается; альтернативы — systemd, runit, s6, pm2, Docker restart.

**Paths:** config `/etc/supervisor/supervisord.conf`; programs `/etc/supervisor/conf.d/`; sock `/var/run/supervisor.sock`.

Cross-reference: [systemd](systemctlcheatsheet.md), [runit](runitcheatsheet.md), [journalctl](journalctlcheatsheet.md).

---

## Installation

### Install supervisord / Установка supervisord

```bash
# Debian/Ubuntu
apt install supervisor

# RHEL/Rocky/Alma/Fedora
dnf install supervisor

# pip
pip install supervisor
```

```bash
supervisord --version
systemctl enable --now supervisord
```

---

## Configuration

### Main files / Основные файлы

`/etc/supervisor/supervisord.conf`

`/etc/supervisor/conf.d/<PROGRAM>.conf`

`/var/log/supervisor/`

### supervisord.conf / supervisord.conf

`/etc/supervisor/supervisord.conf`

```bash
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
nodaemon=false

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
```

### Program config / Конфигурация программы

`/etc/supervisor/conf.d/myapp.conf`

```bash
[program:myapp]
command=/usr/local/bin/myapp --config /etc/myapp/config.yaml
directory=/srv/myapp
autostart=true
autorestart=true
startsecs=10
startretries=3
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/supervisor/myapp.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=5
environment=APP_ENV="production",LOG_LEVEL="info"
```

```bash
supervisorctl reread
supervisorctl update
```

---

## Core Management

### supervisorctl / supervisorctl

```bash
supervisorctl status
supervisorctl start myapp
supervisorctl stop myapp
supervisorctl restart myapp
supervisorctl reload
supervisorctl update
supervisorctl tail -f myapp stdout
supervisorctl tail -f myapp stderr
supervisorctl pid myapp
```

### Web interface / Web-интерфейс

```bash
# In supervisord.conf
[inet_http_server]
port=127.0.0.1:9001
```

---

## Sysadmin Operations

### Logs / Логи

```bash
tail -f /var/log/supervisor/supervisord.log
tail -f /var/log/supervisor/myapp.log
supervisorctl tail myapp stdout
```

### Logrotate / Ротация логов

`/etc/logrotate.d/supervisor`

```bash
/var/log/supervisor/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## Security

### Hardening / Ужесточение

1. Restrict unix socket permissions / Ограничьте права unix-сокета
2. Run processes as non-root users / Запускайте процессы от non-root
3. Do not expose web interface publicly / Не выставляйте web-интерфейс наружу
4. Use environment files for secrets / Храните секреты в env-файлах
5. Monitor restart loops / Мониторьте циклы перезапуска
6. Keep supervisord updated / Обновляйте supervisord

```bash
# chmod=0700 on unix_http_server
# user= non-root in [program:...]
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Program not starting | Bad command / perms | Check command, user |
| FATAL backoff | Repeated crashes | Check app logs |
| socket permission denied | Wrong socket path/perm | Fix unix_http_server |
| Config not applied | Missing reread/update | supervisorctl reread; update |
| Process exits immediately | App crash on start | Check app error output |

```bash
supervisorctl status
supervisorctl tail myapp stderr
tail -f /var/log/supervisor/supervisord.log
```

---

## Comparison Tables

### Process managers / Менеджеры процессов

| Manager | Notes |
| :--- | :--- |
| **supervisord** | Mature, Python, simple |
| **systemd** | Modern, distro default |
| **runit** | Minimal, fast |
| **pm2** | Node.js focused |
| **s6** | Feature-rich, complex |

---

## Production Runbooks

### Runbook: Add new supervised app / Добавление нового приложения

1. Install app dependencies / Установить зависимости
2. Create conf.d/myapp.conf / Создать конфигурацию
3. `supervisorctl reread; update` / Применить конфигурацию
4. `supervisorctl status myapp` / Проверить статус
5. Test start/stop/restart / Протестировать управление
6. Configure logrotate / Настроить logrotate
7. Document process name and user / Задокументировать имя и пользователя

### Runbook: Process crash loop / Циклические падения процесса

1. `supervisorctl status` — see state / Проверить статус
2. `supervisorctl tail myapp stderr` — check errors / Проверить ошибки
3. Check app config and dependencies / Проверить конфиг и зависимости
4. Increase startretries or fix root cause / Исправить корневую причину
5. `supervisorctl restart myapp` / Перезапустить
6. Monitor for stability / Мониторить стабильность
7. Document incident / Задокументировать инцидент

---

## Documentation Links

- supervisord docs — http://supervisord.org/
- supervisord GitHub — https://github.com/Supervisor/supervisor
- supervisorctl man — http://supervisord.org/faq.html
