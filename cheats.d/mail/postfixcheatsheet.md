---
Title: ✉️ Postfix — SMTP Mail Server
Group: Mail
Icon: ✉️
Order: 1
tags:
  - mail
  - smtp
  - postfix
  - email
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

# ✉️ Postfix Cheatsheet

## Description

**Postfix** is a widely used open-source **MTA** (Mail Transfer Agent) for routing and delivering SMTP mail. It handles submission, relay, local delivery, and can work with **Dovecot** for IMAP/POP and **amavisd/ClamAV** for filtering. / **Postfix** — распространённый MTA для SMTP: маршрутизация, ретрансляция, локальная доставка; часто в паре с Dovecot (IMAP/POP) и фильтрами.

**Common use cases / Типовые сценарии:**
- Outbound relay for servers/apps / Исходящий релей для серверов и приложений
- Inbound MX for a domain / Приём почты MX для домена
- Internal mail hub for monitoring/alerts / Внутренний хаб для алертов
- Relay to Google Workspace / Microsoft 365 / Релей в облачные почтовые сервисы

**Status:** Actively maintained (Wietse Venema / IBM Research). Alternatives: **Exim**, **sendmail** (legacy), **msmtp** (client-only), **Haraka** (Node.js). / **Статус:** активно развивается; альтернативы — Exim, sendmail, msmtp.

**Default ports:** `25/tcp` (SMTP), `587/tcp` (submission), `465/tcp` (SMTPS, if enabled).  
**Paths:** config `/etc/postfix/main.cf`, `/etc/postfix/master.cf`; queue `/var/spool/postfix`; logs `journalctl -u postfix`.

Cross-reference: [Dovecot](dovecotcheatsheet.md), [OpenLDAP](../identity/openldapcheatsheet.md), [firewalld](../system-logs/firewalldcheatsheet.md), [Nginx](../web-servers/nginxcheatsheet.md).

---

## Installation

### Install Postfix / Установка Postfix

```bash
# Debian/Ubuntu
export DEBIAN_FRONTEND=noninteractive
apt install postfix

# RHEL/Rocky/Alma/Fedora
dnf install postfix

# SUSE
zypper install postfix
```

```bash
postfix -v
postconf -d | grep -E 'myhostname|mydomain|inet_interfaces'
```

### Common package set / Типовой набор пакетов

```bash
# Debian/Ubuntu (full mail stack example)
apt install postfix dovecot-imapd dovecot-pop3d postfix-pcre mailutils
# RHEL
dnf install postfix dovecot dovecot-pgsql mailx
```

---

## Configuration

### Main files / Основные файлы

`/etc/postfix/main.cf`

`/etc/postfix/master.cf`

`/etc/postfix/postfix.conf` (if present)

`/var/spool/postfix/` (queue dirs: incoming, active, deferred, maildrop, etc.)

`/etc/aliases` (local alias map)

### Core main.cf / Базовая конфигурация main.cf

`/etc/postfix/main.cf`

```bash
# Identity
myhostname = mail.<DOMAIN>
mydomain = <DOMAIN>
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
inet_interfaces = all
inet_protocols = ipv4

# Relay restrictions
mynetworks = 127.0.0.0/8, [::1]/128, 10.0.0.0/8
relay_domains =
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

# TLS (recommended)
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.<DOMAIN>/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.<DOMAIN>/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_ciphers = high

# SASL via Dovecot (optional but recommended for submission)
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous

# Outbound TLS
smtp_tls_security_level = dane
smtp_tls_note_starttls_offer = yes

# Queue / delivery
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/lib/postfix/sbin
data_directory = /var/lib/postfix
mail_owner = postfix
setgid_group = postfix

# Timeouts (seconds)
smtpd_timeout = 300s
smtpd_hard_error_limit = yes
default_process_limit = 100
queue_minfree = 0

# Optional: local destination for monitoring
# local_recipient_maps =
```

### Submission port / Порт отправки (587)

`/etc/postfix/master.cf`

```bash
# uncomment / add submission
smtp      inet  n       -       y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
  -o smtpd_sender_restrictions=reject_sender_login_mismatch
```

### Aliases / Алиасы

`/etc/aliases`

```bash
postmaster: root
abuse: abuse@<DOMAIN>
root: <ADMIN_EMAIL>
```

```bash
newaliases          # rebuild aliases.db
```

### Validation / Проверка конфигурации

```bash
postconf -n        # show non-default settings
postconf -e        # edit main.cf
postcheck          # syntax check (if available)
```

---

## Core Management

### Service control / Управление сервисом

```bash
systemctl status postfix
systemctl restart postfix
systemctl reload postfix
postfix start
postfix stop
postfix reload
postfix flush        # flush queue
postfix check        # consistency check
```

### Queue management / Управление очередью

```bash
mailq                          # list queue
postqueue -f                   # flush all
postqueue -j | head            # JSON queue info
postsuper -d ALL               # delete ALL queued mail (destructive)
postsuper -d <QUEUE_ID>        # delete one
postsuper -r ALL               # requeue all
postsuper -s 1h                # requeue deferred older than 1h
```

> [!CAUTION]
> `postsuper -d ALL` permanently deletes all queued mail. Double-check queue IDs first. / **`postsuper -d ALL` удаляет всю очередь** — проверьте очередь заранее.

### Manual send / Ручная отправка

```bash
echo -e "Subject: test\n\nhello" | mail -s "test" root@localhost
printf "Subject: test\n\nhello\n" | sendmail -t root@localhost
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u postfix --no-pager -n 50
tail -f /var/log/mail.log     # Debian/Ubuntu
tail -f /var/log/maillog      # RHEL family
postqueue -p | head
```

### Queue monitoring / Мониторинг очереди

```bash
# Alert if deferred grows
postqueue -p | awk '/^--/{n++} END{print n+0} deferred items'
```

### Logrotate / Ротация логов

`/etc/logrotate.d/postfix`

```bash
/var/log/mail.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl kill -s HUP postfix >/dev/null 2>&1 || true
    endscript
}
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Enable TLS with strong ciphers on 25/587 / Включите TLS
2. Restrict `mynetworks` to known sources / Ограничьте mynetworks
3. Require SASL for submission (587) / Требуйте SASL на 587
4. Reject unauthenticated relaying / Запрещайте неаутентифицированную ретрансляцию
5. Set SPF/DKIM/DMARC for outbound / Настройте SPF/DKIM/DMARC
6. Rate-limit connections (if supported) / Ограничивайте соединения
7. Monitor deferred queue and open-relay risk / Мониторьте очередь и open-relay
8. Keep Postfix updated / Обновляйте Postfix

```bash
# Verify TLS config
postconf -n | grep smtpd_tls
```

### SPF/DKIM/DMARC (outbound) / Внешняя аутентификация

```text
# SPF (DNS TXT): v=spf1 ip4:<SERVER_IP> -all
# DKIM: use opendkim/milter (external to core Postfix)
# DMARC (DNS TXT): v=DMARC1; p=reject; rua=mailto:dmarc@<DOMAIN>
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/postfix-config-$(date +%F).tar.gz \
  /etc/postfix /etc/aliases
# Optionally copy deferred queue
tar czf /var/backups/postfix-queue-$(date +%F).tar.gz /var/spool/postfix/deferred
```

### Restore / Восстановление

```bash
systemctl stop postfix
tar xzf /var/backups/postfix-config-<DATE>.tar.gz -C /
postfix check
systemctl start postfix
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Relay access denied` | Not in mynetworks / no SASL | Check mynetworks; enable SASL |
| `No route to host` on 25 | Firewall / port blocked | Open outbound 25/tcp |
| Mail stuck in deferred | DNS / remote timeouts | `postqueue -p`; check `maillog` |
| `Temporary lookup failure` | Postfix master down | Restart postfix; check master.cf |
| TLS errors on outbound | Cert path / remote TLS | `smtp_tls_security_level=dane`; verify certs |
| SASL login failed | Dovecot auth socket | Check `smtpd_sasl_path`; Dovecot auth |

```bash
postconf -n | grep -E 'mynetworks|sasl|relay'
postqueue -p | head
journalctl -u postfix -f
```

---

## Comparison Tables

### MTAs / МТA (Mail Transfer Agents)

| Tool | Strengths | Typical use |
| :--- | :--- | :--- |
| **Postfix** | Secure, modular, easy config | Modern Linux MTA |
| **Exim** | Flexible routing | Debian default historically |
| **sendmail** | Legacy compatibility | Old systems |
| **msmtp** | Lightweight client | Outbound-only from servers |
| **Haraka** | Node.js extensibility | Custom pipelines |

---

## Production Runbooks

### Runbook: New domain MX / Настройка MX для нового домена

1. Install postfix + TLS certs / Установить postfix и сертификаты
2. Set `myhostname`, `mydomain`, `mydestination` / Настроить identity
3. Configure `inet_interfaces` and `mynetworks` / Настроить интерфейсы
4. Enable TLS + submission on 587 / Включить TLS и 587
5. Restart postfix; verify listening ports / Перезапустить и проверить порты
6. Publish MX record; verify with `dig MX <DOMAIN>` / Опубликовать MX
7. Test inbound: `swaks --to postmaster@<DOMAIN>` / Проверить приём
8. Test outbound: send from local / Проверить исходящую почту

### Runbook: Deferred queue cleanup / Очистка отложенной очереди

1. `postqueue -p` — identify deferred IDs / Просмотреть очередь
2. Check DNS/remote reachability / Проверить DNS и сеть
3. `postsuper -r <QUEUE_ID>` — requeue selected / Перепоставить выбранные
4. Flush: `postfix flush` / Сбросить очередь
5. If spam/bounce storm: delete by ID only / Удаляйте только по ID
6. Document root cause for next runbook / Задокументировать причину

---

## Documentation Links

- Postfix docs — https://www.postfix.org/documentation.html
- postconf(5) — https://www.postfix.org/postconf.5.html
- master.cf — https://www.postfix.org/master.5.html
- Postfix security — https://www.postfix.org/SECURITY_README.html
- Postfix on Debian — https://wiki.debian.org/Postfix
