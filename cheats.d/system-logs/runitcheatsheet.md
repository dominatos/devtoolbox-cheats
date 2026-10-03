---
Title: ⚡ runit — Init & Process Manager
Group: "System & Logs"
Icon: ⚡
Order: 23
tags:
  - process
  - runit
  - init
  - supervision
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

# ⚡ runit Cheatsheet

## Description

**runit** is a UNIX **init scheme and service supervision** suite. Lightweight, fast boot, and used as PID 1 or process supervisor on Void Linux and embedded systems. / **runit** — UNIX-схема инициализации и супервизии сервисов. Лёгкая, быстрая загрузка; используется как PID 1 или процесс-супервизор на Void Linux и embedded-системах.

**Common use cases / Типовые сценарии:**
- Fast boot on minimal systems / Быстрая загрузка минимальных систем
- Process supervision without systemd / Супервизия без systemd
- Embedded / container base images / Embedded и базовые образы контейнеров
- Void Linux default init / Дефолтный init на Void Linux

**Status:** Maintained (Void Linux / runit upstream). Alternatives: **systemd**, **OpenRC**, **s6**, **supervisord**. / **Статус:** поддерживается; альтернативы — systemd, OpenRC, s6, supervisord.

**Paths:** service dirs `/etc/sv/`, `/var/service/`; run scripts `run`, `finish`, `log/run`.

Cross-reference: [supervisord](supervisordcheatsheet.md), [systemd](systemctlcheatsheet.md), [s6](https://skarnet.org/software/s6/).

---

## Installation

### Install runit / Установка runit

```bash
# Debian/Ubuntu
apt install runit

# Void Linux (already default init)
xbps-install -S runit

# From source
git clone https://github.com/runit/runit
cd runit && package/compile
```

```bash
chpst -V
runsvdir -V 2>&1 | head
```

---

## Configuration

### Service directory layout / Раскладка сервисного каталога

`/etc/sv/<SERVICE>/run`

`/etc/sv/<SERVICE>/finish`

`/etc/sv/<SERVICE>/log/run`

### run script / run-скрипт

`/etc/sv/myapp/run`

```bash
#!/bin/sh
exec 2>&1
exec chpst -u myuser:mygroup \
  /usr/local/bin/myapp --config /etc/myapp/config.yaml
```

### log/run / log/run

`/etc/sv/myapp/log/run`

```bash
#!/bin/sh
exec svlogd -tt /var/log/myapp/
```

```bash
chmod 0755 /etc/sv/myapp/run /etc/sv/myapp/finish /etc/sv/myapp/log/run
mkdir -p /var/log/myapp
```

### Enable service / Включение сервиса

```bash
ln -s /etc/sv/myapp /var/service/myapp
# Or on Void:
ln -s /etc/sv/myapp /var/service/myapp
```

---

## Core Management

### sv commands / команды sv

```bash
sv status myapp
sv up myapp
sv down myapp
sv restart myapp
sv reload myapp
sv pause myapp
sv cont myapp
sv once myapp
sv hup myapp
sv kill myapp TERM
```

### runsvdir / runsvdir

```bash
runsvdir /var/service
# Runs all services in directory; supervised by init
```

---

## Sysadmin Operations

### Logs / Логи

```bash
tail -f /var/log/myapp/current
svlogd -tt /var/log/myapp/
```

### Logrotate (svlogd) / Ротация логов (svlogd)

`/var/log/myapp/config`

```bash
s1000000
n5
!gzip
```

---

## Security

### Hardening / Ужесточение

1. Run services as non-root / Запускайте сервисы от non-root
2. Use chpst -u / -U for user switching / Используйте chpst -u/-U
3. Restrict service dir permissions / Ограничьте права сервисного каталога
4. Use svlogd for structured logs / Используйте svlogd для структурированных логов
5. Monitor restart loops / Мониторьте циклы перезапуска
6. Keep runit patched / Обновляйте runit

```bash
# chpst -u user:group in run script
# ls -ld /etc/sv/myapp /var/service/myapp
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Service down | run script crash | Check run script; logs |
| Permission denied | Wrong user/perms | chpst -u; fix ownership |
| log not written | log/run missing/bad | Create log/run; exec svlogd |
| Won't start | Port in use | Check port; fix conflict |
| restart loop | App config error | Check app config; fix |

```bash
sv status myapp
cat /etc/sv/myapp/run
tail -f /var/log/myapp/current
```

---

## Comparison Tables

### Init / process supervisors / Init / процесс-супервизоры

| Manager | Notes |
| :--- | :--- |
| **runit** | Minimal, fast, script-based |
| **systemd** | Full-featured, distro default |
| **supervisord** | Python, config-file based |
| **s6 / s6-rc** | Feature-rich, complex |
| **OpenRC** | Gentoo-style init |

---

## Production Runbooks

### Runbook: Create new service / Создание нового сервиса

1. Install app; create non-root user / Установить приложение; создать пользователя
2. Create /etc/sv/myapp/run with chpst / Создать run-скрипт
3. Create log/run with svlogd / Создать log/run
4. chmod 0755 run scripts / Исправить права
5. ln -s /etc/sv/myapp /var/service/myapp / Подключить сервис
6. `sv status myapp` — verify up / Проверить статус
7. Test restart: `sv restart myapp` / Проверить перезапуск
8. Document service layout / Задокументировать раскладку

### Runbook: Graceful reload / Корректная перезагрузка сервиса

1. Check if app supports SIGHUP / Проверить поддержку SIGHUP
2. `sv hup myapp` / Отправить SIGHUP
3. If not, `sv restart myapp` / Или перезапустить
4. Verify health after reload / Проверить здоровье
5. Monitor logs for errors / Мониторить логи
6. Document reload semantics / Задокументировать семантику

---

## Documentation Links

- runit guide — http://smarden.org/runit/
- runit GitHub — https://github.com/runit/runit
- chpst — http://smarden.org/runit/chpst.8.html
- svlogd — http://smarden.org/runit/svlogd.8.html
