---
Title: 🛡️ auditd — Linux Audit Framework
Group: "Security & Crypto"
Icon: 🛡️
Order: 22
tags:
  - security
  - auditd
  - compliance
  - forensics
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

# 🛡️ auditd Cheatsheet (Linux Audit)

## Description

**auditd** is the userspace daemon of the **Linux Audit** framework. It records security-relevant kernel events (exec, file access, mounts, auth, network) to disk. Rules are managed with **auditctl**; queries use **ausearch** / **aureport**; persistent rules are compiled from `/etc/audit/rules.d/` by **augenrules**. / **auditd** — демо Linux Audit: записывает события исполнения, доступа к файлам, авторизации и сети. Правила — auditctl, запросы — ausearch/aureport.

**Common use cases / Типовые сценарии:**
- CIS/PCI/HIPAA/DORA audit trails / Аудиторские следы для комплаенса
- Detect rootkit / unauthorized exec / Обнаружение руткитов и несанкционированных запусков
- Forensic timeline after incident / Таймлайн после инцидента
- Monitor sudo/su/ssh privileged actions / Мониторинг привилегированных действий

**Status:** Actively maintained on RHEL family and available on Debian/Ubuntu (`auditd`). Alternatives: **OSSEC/Wazuh** (HIDS with its own agent), **eBPF audit tools**, **fanotify/inotify** (lighter file events). / **Статус:** актуален; альтернативы — Wazuh, eBPF-аудит.

**Default paths:** daemon config `/etc/audit/auditd.conf`; rules `/etc/audit/rules.d/*.rules`; compiled `/etc/audit/audit.rules`; logs `/var/log/audit/audit.log`; state `/run/audit/auditd.state`.

**Boot note:** add `audit=1` on the kernel command line so early processes are auditable. / **Важно:** параметр ядра `audit=1` для аудита ранних процессов.

Cross-reference: [AIDE](aidecheatsheet.md), [journalctl](../system-logs/journalctlcheatsheet.md), [sudoers/PAM](sudoerspamcheatsheet.md).

---

## Installation

### Packages / Пакеты

```bash
# RHEL/Rocky/Alma/Fedora
dnf install audit audit-libs

# Debian/Ubuntu
apt install auditd audispd-plugins

# openSUSE
zypper install audit
```

```bash
# Enable and start
systemctl enable --now auditd
systemctl status auditd
```

> [!NOTE]
> On many systems `auditd` is not managed by systemd restart in the usual way (systemd may warn about restarting auditd). Prefer `service auditd restart` or the distro's helper when available. / На многих системах auditd перезапускается через `service auditd restart`.

---

## Configuration

### Main files / Основные файлы

`/etc/audit/auditd.conf`

`/etc/audit/rules.d/`

`/etc/audit/rules.d/10-base.rules`

`/etc/audit/audit.rules` (compiled by augenrules)

`/etc/audit/plugins.d/`

### auditd.conf essentials / Ключевые параметры auditd.conf

`/etc/audit/auditd.conf`

```bash
log_file = /var/log/audit/audit.log
log_format = RAW
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = 8
num_logs = 10
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SINGLE
disk_full_action = HALT
disk_error_action = HALT
```

### Base rules / Базовые правила

`/etc/audit/rules.d/10-base.rules`

```bash
# Delete all existing rules
-D

# Buffer and rate limits
-b 8192
-f 1

# Failure mode: 0=silent, 1=printk, 2=panic
-f 1

# Make loginuid immutable where supported
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k rootcmd
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k rootcmd

# Watch sudoers and PAM
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/pam.d/ -p wa -k pam

# Identity/auth files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# SSH
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/ssh/sshd_config.d/ -p wa -k sshd

# Kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules

# Mount/remount
-a always,exit -F arch=b64 -S mount -k mount
-a always,exit -F arch=b32 -S mount -k mount

# Time changes
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change

# Make rules immutable at end (requires reboot to change)
# -e 2
```

> [!CAUTION]
> `-e 2` makes rules immutable until reboot. Only set it after rules are validated on a maintenance window. / `-e 2` делает правила неизменными до перезагрузки — включайте только после проверки.

### Load persistent rules / Загрузка правил

```bash
augenrules --load          # Compile rules.d -> audit.rules and load
auditctl -l                # List loaded rules
auditctl -s                # Status (enabled, pid, backlog, lost)
```

---

## Core Management

### auditctl / Управление правилами

```bash
auditctl -s
auditctl -l
auditctl -D                # Delete all rules (runtime)
auditctl -e 1              # Enable
auditctl -e 0              # Disable (runtime only)
auditctl -f 1              # Failure mode printk
auditctl -b 8192           # Backlog limit
auditctl -k sudoers        # Show rules with key
```

### ausearch / Поиск событий

```bash
ausearch -m USER_AUTH,USER_CMD -ts recent
ausearch -k sudoers --start today
ausearch -x /usr/bin/sudo -ts yesterday
ausearch -ua <USER>
ausearch -f /etc/shadow
ausearch -ts 08:00:00 --end 09:00:00
ausearch --start boot
ausearch -i                 # Interpret numeric UIDs / Интерпретировать UID
```

Sample output:

```text
type=USER_AUTH msg=audit(1727900000.123:456): pid=1234 uid=1000 auid=1000 ses=3 msg='op=PAM:authentication grantors=pam_unix acct="alice" exe="/usr/bin/sudo" hostname=? addr=? terminal=pts/0 res=success'
```

### aureport / Отчёты

```bash
aureport --summary
aureport --summary -k
aureport --auth
aureport --failed
aureport --exec
aureport --file
aureport --login
aureport --user
aureport --change
aureport --anomaly
```

---

## Sysadmin Operations

### Service control / Управление сервисом

```bash
systemctl status auditd
service auditd restart     # Preferred restart method on many distros
systemctl reload auditd    # SIGHUP: re-read auditd.conf
```

### Remote collection (optional) / Удалённый сбор

```bash
# audisp-remote plugin (classic)
# /etc/audit/plugins.d/au-remote.conf
# type=always
# name=au-remote
# path=/sbin/audisp-remote
# args=-c /etc/audit/audisp-remote.conf
# format=string
# active=yes
```

> Note: modern deployments often ship audit logs via **Vector/Filebeat/Wazuh** instead of audisp-remote. / Современные стеки чаще собирают логи аудита через Vector/Filebeat/Wazuh.

### Logrotate / Ротация логов

`/etc/logrotate.d/audit`

```bash
/var/log/audit/audit.log {
    sharedscripts
    postrotate
        /usr/sbin/service auditd restart > /dev/null 2>&1 || true
        # Debian may use: /usr/lib/syzkaller/auditd-restart or augenrules
    endscript
}
```

> [!NOTE]
> Prefer the distro's audit logrotate snippet if present — some require a special restart path to avoid losing events. / Используйте дистрибутивный снippets ротации, если он есть.

---

## Security

### What to audit (starter policy) / Что аудировать (стартовая политика)

| Area | Examples | Key |
| :--- | :--- | :--- |
| Privilege exec | sudo, su, sshd | `privileged`, `sudoers` |
| Identity files | passwd, group, shadow | `identity` |
| Security config | sudoers, pam, sshd_config | `sudoers`, `pam`, `sshd` |
| Kernel modules | insmod/rmmod/modprobe | `modules` |
| File ops (sensitive) | /etc, /root, app secrets | `sensitive` |
| Time changes | settimeofday | `time-change` |

### Performance notes / Производительность

- Start with `-b 8192` and raise only if `backlog` errors appear / Начинайте с 8192 backlog
- Avoid watching entire `/var/log` or `/tmp` with always/exit rules / Не следите за всем `/tmp`
- Prefer `-w` watches on files; use `-S` syscalls sparingly for hot paths / `-w` предпочтительнее syscall-нагрузки
- Use key names (`-k`) so ausearch is fast / Используйте ключи для быстрого поиска

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/audit-rules-$(date +%F).tar.gz \
  /etc/audit/rules.d /etc/audit/auditd.conf /etc/audit/audit.rules
# Optionally export audit.log archive separately (large)
```

### Restore / Восстановление

```bash
tar xzf /var/backups/audit-rules-<DATE>.tar.gz -C /
augenrules --load
auditctl -s
auditctl -l | head
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| No audit events | auditd not running / kernel audit off | `systemctl status auditd`; cmdline `audit=1` |
| `Error sending audit request` | backlog overflow | Increase `-b`; reduce noisy rules |
| `auditd is not running` after restart | systemd conflict | `service auditd restart` |
| ausearch empty | wrong key/time range | Check `-k`, `-ts`, timezone |
| Disk full / HALT action | disk_full_action=HALT | Rotate sooner; expand disk; lower `max_log_file` |
| Rules lost after reboot | not in rules.d / not loaded | Put rules in `rules.d`; `augenrules --load` |

```bash
auditctl -s
dmesg | grep -i audit
ausearch -ts recent -i | head
ls -la /var/log/audit/
```

---

## Comparison Tables

### Audit approaches / Подходы к аудиту

| Tool | Level | Best for |
| :--- | :--- | :--- |
| **auditd** | Kernel + userspace | Compliance, syscall/file watches |
| **AIDE/Tripwire** | File integrity snapshots | Change detection of known paths |
| **Wazuh/OSSEC** | HIDS agent | Correlation + active response |
| **eBPF tools** | Dynamic kernel | Deep exec/network visibility |
| **journalctl** | Service logs | Operational, not kernel audit |

---

## Production Runbooks

### Runbook: Baseline audit on new server / Базовый аудит на новом сервере

1. Install auditd package / Установить auditd
2. Confirm `audit=1` if early-boot audit is required / Проверить параметр ядра
3. Drop starter rules in `/etc/audit/rules.d/10-base.rules` / Положить базовые правила
4. `augenrules --load && auditctl -s` / Загрузить правила
5. Trigger test: `sudo -l`, `touch /etc/shadow.test` (careful) / Сгенерировать тестовые события
6. Verify with `ausearch -k sudoers -i` / Проверить поиск по ключу
7. Configure logrotate and retention / Настроить ротацию и retention
8. Enable remote shipping if required / Включить удалённую доставку логов

### Runbook: After compromise (high-signal rules) / После компрометации

1. Preserve `/var/log/audit/audit.log` first (copy + hash) / Сначала сохранить логи
2. Do not restart auditd until logs are copied / Не перезапускать auditd до копирования
3. Expand watches: `/root`, app config, crontabs, authorized_keys / Добавить watch-и
4. Query: `ausearch --start boot -k identity`, `-x /usr/bin/sudo` / Собрать таймлайн
5. Build aureport summary for incident ticket / Сформировать отчёт для инцидента
6. Ship logs off-box; consider `-e 2` only after validation / Отправить логи вне хоста

---

## Documentation Links

- auditd(8) — https://man7.org/linux/man-pages/man8/auditd.8.html
- audit.rules(7) — https://man7.org/linux/man-pages/man7/audit.rules.7.html
- ausearch(8) — https://man7.org/linux/man-pages/man8/ausearch.8.html
- aureport(8) — https://man7.org/linux/man-pages/man8/aureport.8.html
- auditctl(8) — https://man7.org/linux/man-pages/man8/auditctl.8.html
- Red Hat audit overview — https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/auditing-in-rhel
- CIS auditd recommendations — CIS Benchmarks (subscription)
