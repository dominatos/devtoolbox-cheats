---
Title: 📧 Dovecot — IMAP/POP3 Server
Group: Mail
Icon: 📧
Order: 2
tags:
  - mail
  - dovecot
  - imap
  - pop3
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

# 📧 Dovecot Cheatsheet

## Description

**Dovecot** is a secure, open-source **IMAP and POP3 server** with Maildir/mbox storage, modern authentication (SCRAM), and strong performance. Works with Postfix and LDAP. / **Dovecot** — безопасный open-source сервер IMAP и POP3 с Maildir/mbox, современной аутентификацией (SCRAM) и высокой производительностью. Работает с Postfix и LDAP.

**Common use cases / Типовые сценарии:**
- IMAP/POP3 for mailboxes / IMAP/POP3 для почтовых ящиков
- Mail storage backend for Postfix / Хранилище почты для Postfix
- Webmail backend (Roundcube, SOGo) / Бэкенд для webmail
- LDAP-backed auth / Аутентификация через LDAP

**Status:** Actively maintained (Dovecot Foundation / Pigeonhole). Alternatives: **Courier IMAP**, **Cyrus IMAP**, **Zimbra**. / **Статус:** активно развивается; альтернативы — Courier, Cyrus IMAP, Zimbra.

**Default ports:** `143/tcp` (IMAP), `993/tcp` (IMAPS), `110/tcp` (POP3), `995/tcp` (POP3S).  
**Paths:** config `/etc/dovecot/`; Maildir `/var/mail/vhosts/<DOMAIN>/<USER>/`.

Cross-reference: [Postfix](postfixcheatsheet.md), [OpenLDAP](../identity-management/openldapcheatsheet.md), [SSL/TLS](../security-crypto/opensslcheatsheet.md).

---

## Installation

### Install Dovecot / Установка Dovecot

```bash
# Debian/Ubuntu
apt install dovecot-imapd dovecot-pop3d dovecot-sieve

# RHEL/Rocky/Alma/Fedora
dnf install dovecot
```

```bash
dovecot --version
systemctl enable --now dovecot
```

---

## Configuration

### Main files / Основные файлы

`/etc/dovecot/dovecot.conf`

`/etc/dovecot/conf.d/10-mail.conf`

`/etc/dovecot/conf.d/10-auth.conf`

`/etc/dovecot/conf.d/10-ssl.conf`

`/etc/dovecot/conf.d/10-master.conf`

`/etc/dovecot/conf.d/10-logging.conf`

### dovecot.conf / dovecot.conf

`/etc/dovecot/dovecot.conf`

```bash
protocols = imap pop3 lmtp
listen = *, ::
mail_location = maildir:/var/mail/vhosts/%d/%n
ssl = required
ssl_cert = </etc/ssl/certs/dovecot.pem
ssl_key = </etc/ssl/private/dovecot.key
auth_mechanisms = plain login
disable_plaintext_auth = yes
auth_username_format = %Lu
mail_debug = no
```

### Maildir setup / Настройка Maildir

```bash
mkdir -p /var/mail/vhosts/example.com/alice
chown -R vmail:vmail /var/mail/vhosts/example.com/alice
```

### TLS certs / TLS-сертификаты

```bash
openssl req -new -x509 -days 365 -nodes \
  -out /etc/ssl/certs/dovecot.pem \
  -keyout /etc/ssl/private/dovecot.key \
  -subj "/CN=<MAIL_HOST>"
chmod 600 /etc/ssl/private/dovecot.key
chown root:root /etc/ssl/private/dovecot.key
```

```bash
systemctl restart dovecot
```

---

## Core Management

### doveconf / doveconf

```bash
doveconf
doveconf -n
doveconf -h
doveconf mail_location
doveconf ssl_cert
```

### Test connection / Тест подключения

```bash
openssl s_client -connect <MAIL_HOST>:993 -crlf
# LOGIN <USER> <PASSWORD>
# LIST "" ""
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u dovecot --no-pager -n 50
tail -f /var/log/mail.log
doveadm log errors
```

### Logrotate / Ротация логов

`/etc/logrotate.d/dovecot`

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
        systemctl reload dovecot >/dev/null 2>&1 || true
    endscript
}
```

---

## Security

### Hardening / Ужесточение

1. Require TLS: `ssl = required` / Требуйте TLS
2. Disable plaintext auth: `disable_plaintext_auth = yes` / Отключите plaintext
3. Use SCRAM-SHA-256 if possible / Используйте SCRAM-SHA-256
4. Protect SSL private key (0600 root) / Защитите приватный ключ
5. Restrict who can read Maildir / Ограничьте доступ к Maildir
6. Keep Dovecot patched / Обновляйте Dovecot
7. Monitor auth failures / Мониторьте неудачные auth

```bash
# /etc/dovecot/conf.d/10-ssl.conf
# ssl = required
# ssl_min_protocol = TLSv1.2
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/dovecot-$(date +%F).tar.gz \
  /etc/dovecot /var/mail/vhosts
```

### Restore / Восстановление

```bash
systemctl stop dovecot
tar xzf /var/backups/dovecot-<DATE>.tar.gz -C /
chown -R vmail:vmail /var/mail/vhosts
systemctl start dovecot
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Auth failed | Wrong credentials / PAM | Check auth config; passwords |
| No mail location | mail_location unset | Set mail_location |
| TLS errors | Cert path / expired | Check cert; regenerate |
| Connection refused | Firewall / service down | Open 143/993; start dovecot |
| Permission denied Maildir | Ownership | chown vmail:vmail |

```bash
doveconf -n
doveadm auth test <USER>
systemctl status dovecot
```

---

## Comparison Tables

### IMAP servers / IMAP-серверы

| Server | Notes |
| :--- | :--- |
| **Dovecot** | Secure, flexible, fast |
| **Courier IMAP** | Legacy, stable |
| **Cyrus IMAP** | Scalable, complex |
| **Zimbra** | Full suite (paid/community) |

---

## Production Runbooks

### Runbook: Deploy IMAP with Postfix / Развёртывание IMAP с Postfix

1. Install Dovecot and Postfix / Установить Dovecot и Postfix
2. Generate TLS certificates / Создать TLS-сертификаты
3. Configure Maildir location; create vmail user / Настроить Maildir
4. Configure Dovecot auth (PAM or SQL or LDAP) / Настроить аутентификацию
5. Point Postfix to Dovecot LMTP for delivery / Настроить LMTP-доставку
6. Open 993/995 (and 143 if needed) / Открыть порты
7. Restart both services; test IMAPS login / Перезапустить; проверить вход
8. Document mailbox provisioning process / Задокументировать процесс создания ящиков

### Runbook: Provision new mailbox / Создание нового ящика

1. Create system/vmail user if needed / Создать пользователя
2. Create Maildir directory / Создать Maildir
3. chown vmail:vmail on directory / Исправить владельца
4. Add user to auth backend (PAM/SQL/LDAP) / Добавить в auth-бэкенд
5. Test `doveadm auth test` / Проверить auth
6. Test IMAPS login from client / Проверить вход
7. Document quota if configured / Задокументировать квоту

---

## Documentation Links

- Dovecot docs — https://doc.dovecot.org/
- Dovecot wiki — https://wiki.dovecot.org/
- Pigeonhole (sieve) — https://doc.dovecot.org/configuration_manual/sieve/
- Maildir format — https://cr.yp.to/proto/maildir.html
