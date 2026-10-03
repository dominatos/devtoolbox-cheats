---
Title: ⏰ chrony / NTP — Time Sync
Group: "System & Logs"
Icon: ⏰
Order: 20
tags:
  - system
  - ntp
  - chrony
  - time
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
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# ⏰ chrony / NTP Cheatsheet

## Description

**Time synchronization** is critical for TLS validity, log correlation, Kerberos, databases, HA clusters, and distributed systems. **chrony** is the modern default client/server on RHEL 8+/Debian/Ubuntu (replacing ntpd). **systemd-timesyncd** is a lighter client used by many desktop distros. / **Синхронизация времени** критична для TLS, логов, Kerberos, БД и HA. **chrony** — современный стандарт; **timesyncd** — лёгкий клиент.

**Common use cases / Типовые сценарии:**
- Keep VMs/containers in sync behind NAT / Синхронизация VM/контейнеров за NAT
- Local NTP stratum for lab/DC / Локальный NTP для ЦОД/лаборатории
- chrony as NTP server for LAN / chrony как NTP-сервер для LAN
- Troubleshoot TLS "certificate not yet valid" / Разбор ошибок TLS из-за времени

**Status:** chrony is actively maintained and preferred on modern Linux; ntpd remains for legacy. / **Статус:** chrony предпочтителен на современных системах; ntpd — для legacy.

**Default ports:** NTP `123/udp`.  
**Paths:** `/etc/chrony/chrony.conf` (Debian) or `/etc/chrony.conf` (RHEL); logs `journalctl -u chronyd`.

Cross-reference: [date/TZ](datetzcheatsheet.md), [systemd timers](systemdtimerscheatsheet.md), [kernel panic](kernelpanicscheatsheet.md).

---

## Installation

### Install chrony / Установка chrony

```bash
# Debian/Ubuntu
apt install chrony

# RHEL/Rocky/Alma/Fedora
dnf install chrony

# SUSE
zypper install chrony
```

```bash
systemctl enable --now chronyd    # RHEL family
systemctl enable --now chrony     # Debian family (unit name: chrony)
```

---

## Configuration

### Main files / Основные файлы

`/etc/chrony/chrony.conf` (Debian)

`/etc/chrony.conf` (RHEL)

`/etc/chrony/sources.d/*.sources` (drop-in, newer versions)

### Client-only config / Конфигурация клиента

`/etc/chrony/chrony.conf`

```bash
# Public NTP pool
pool 2.debian.pool.ntp.org iburst
pool 2.pool.ntp.org iburst

# Drift file and logs
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony

# Optional: allow large steps only at start
# maxchange 1 0 0
```

### Server mode (LAN) / Режим сервера (LAN)

`/etc/chrony/chrony.conf`

```bash
# Listen on LAN
allow 10.0.0.0/8
allow 192.168.0.0/16
allow 172.16.0.0/12

# Serve NTP
local stratum 8

# Prefer hardware clock if available
hwtimestamp *

pool ntp.example.internal iburst
```

```bash
systemctl restart chronyd
```

### Verify sources / Проверка источников

```bash
chronyc sources -v
chronyc tracking
timedatectl status
```

---

## Core Management

### Basic commands / Базовые команды

```bash
# Source status (NTP server list, offset, delay)
chronyc sources

# Detailed tracking (stratum, leap status, system time)
chronyc tracking

# Activity
chronyc activity

# Manual online/offline
chronyc online
chronyc offline

# Force step to selected source (careful)
chronyc makestep
```

Sample `chronyc tracking`:

```text
Reference ID    : 0A0A0A0A (ntp.example.internal)
Stratum         : 3
Ref time (UTC)  : Fri Oct 02 12:00:00 2026
System time     : 0.000123456 seconds fast of NTP time
Last offset     : -0.000045678 seconds
```

### timedatectl / Через systemd

```bash
timedatectl status
timedatectl set-timezone <TZ>          # e.g. Europe/Warsaw, UTC
timedatectl set-ntp true               # enable NTP (chrony/timesyncd)
timedatectl set-ntp false
timedatectl timesync-status
timedatectl show-timezone
```

---

## Sysadmin Operations

### Open port 123 / Открыть UDP 123

```bash
# firewalld
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload

# ufw
ufw allow 123/udp

# nftables (example)
nft add rule inet filter input udp dport 123 accept
```

### Chrony as container sidecar / chrony в контейнере

```bash
# Share host network for time accuracy
docker run --network=host -v /etc/chrony:/etc/chrony:ro chrony/chrony

# Or host-time + makestep from containerized workloads
```

### Logrotate / Ротация логов

`/etc/logrotate.d/chrony`

```bash
/var/log/chrony/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

> Note: many chrony packages log to journal instead of files. / Часто chrony пишет в journal, а не в файлы.

---

## Security

### Hardening / Ужесточение

1. Restrict `allow` to trusted subnets / Ограничьте `allow` доверенными подсетями
2. Do not expose NTP to the Internet without need / Не публикуйте NTP наружу без необходимости
3. Prefer pool + iburst for clients / Предпочитайте pool iburst для клиентов
4. On VMs, ensure guest time tools are not fighting chrony / Не конфликтуйте с guest-агентами
5. Monitor offset (`chronyc tracking`) for drift alarms / Мониторьте offset

```bash
# Firewall example: allow only internal NTP server clients
# allow 10.20.30.0/24
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Unsynchronised` | No reachable NTP / firewall | Check UDP 123; `chronyc sources` |
| Large offset after boot | VM pause / clock jump | `makestep` after resume; enable `makestep 1.0 3` |
| TLS errors "not yet valid" | Clock too far behind | Sync time; restart affected services |
| chronyd failing | Config syntax / ports | `journalctl -u chronyd -b` |
| Both chronyd + ntpd running | Package conflict | Disable one; keep chrony on modern systems |

```bash
chronyc sources
chronyc tracking
journalctl -u chronyd --no-pager -n 30
ss -ulnp | grep 123
```

---

## Comparison Tables

### Time sync tools / Инструменты синхронизации

| Tool | Role | Notes |
| :--- | :--- | :--- |
| **chrony** | Client + server | Modern default; good for VMs/NAT |
| **ntpd** | Client + server | Legacy; simpler but heavier |
| **systemd-timesyncd** | Client only | Lightweight; no server mode |
| **ntpsec** | Client + server | Security-hardened ntpd fork |

---

## Production Runbooks

### Runbook: New VM time sync / Настройка времени на новой VM

1. Install chrony / Установить chrony
2. Configure pool servers in chrony.conf / Настроить pool
3. Open UDP 123 outbound (and inbound if server) / Открыть firewall
4. `systemctl enable --now chronyd`
5. `chronyc tracking` — confirm small offset / Проверить offset
6. Set timezone with timedatectl / Задать timezone
7. Verify TLS and log timestamps / Проверить TLS и метки времени

### Runbook: Local NTP server for DC / Локальный NTP-сервер

1. Choose 2–3 upstream pools / Выбрать upstream pool
2. Set `allow` to internal subnets only / Ограничить allow
3. Set `local stratum 8` if isolated / Задать local stratum при изоляции
4. Restart chronyd; open UDP 123 inbound / Перезагрузить и открыть порт
5. Point clients at this server via DHCP or config / Настроить клиентов
6. Monitor offsets on clients / Мониторить offset на клиентах

---

## Documentation Links

- chrony docs — https://chrony-project.org/docs.html
- chrony.conf — https://chrony-project.org/doc/chrony.conf.html
- chronyc(8) — https://chrony-project.org/doc/chronyc.1.html
- systemd-timesyncd — https://www.freedesktop.org/software/systemd/man/systemd-timesyncd.html
- NTP pool project — https://www.pool.ntp.org/
- Debian NTP — https://wiki.debian.org/NTP
