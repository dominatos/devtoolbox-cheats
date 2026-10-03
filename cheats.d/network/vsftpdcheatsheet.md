---
Title: 📂 vsftpd — FTP Server
Group: Network
Icon: 📂
Order: 13
tags:
  - network
  - ftp
  - vsftpd
  - file-transfer
  - security
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

# 📂 vsftpd Cheatsheet

## Description

**vsftpd** (Very Secure FTP Daemon) is a stable, secure **FTP server** for Unix/Linux. Supports chroot jails, virtual users, SSL/TLS (FTPS), and passive mode. / **vsftpd** — стабильный и безопасный FTP-сервер для Unix/Linux. Поддерживает chroot-jails, виртуальных пользователей, SSL/TLS (FTPS) и passive-режим.

**Common use cases / Типовые сценарии:**
- Legacy FTP file exchange / Устаревший FTP-обмен файлами
- Anonymous download mirrors / Зеркала для anonymous-загрузки
- Automated upload from scripts / Автоматическая загрузка из скриптов
- Chroot-restricted user FTP / FTP с chroot для пользователей

**Status:** Maintained (Red Hat / upstream). Alternatives: **ProFTPD**, **Pure-FTPd**, **SFTP (OpenSSH)**, **Samba**. / **Статус:** поддерживается; альтернативы — ProFTPD, Pure-FTPd, SFTP, Samba.

**Default ports:** `21/tcp` (control), passive data ports (configurable range).  
**Paths:** config `/etc/vsftpd/vsftpd.conf`; chroot `/var/ftp/` or per-user.

Cross-reference: [Samba](../storage-fs/sambacheatsheet.md), [OpenSSL](../security-crypto/opensslcheatsheet.md), [systemd](../system-logs/systemctlcheatsheet.md).

---

## Installation

### Install vsftpd / Установка vsftpd

```bash
# Debian/Ubuntu
apt install vsftpd

# RHEL/Rocky/Alma/Fedora
dnf install vsftpd
```

```bash
vsftpd -v
systemctl enable --now vsftpd
```

---

## Configuration

### Main files / Основные файлы

`/etc/vsftpd/vsftpd.conf`

`/etc/vsftpd/ftpusers`

`/etc/vsftpd/user_list`

`/var/ftp/`

### vsftpd.conf / vsftpd.conf

`/etc/vsftpd/vsftpd.conf`

```bash
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=NO
pasv_enable=YES
pasv_min_port=<PASSIVE_PORT_MIN>
pasv_max_port=<PASSIVE_PORT_MAX>
pam_service_name=vsftpd
userlist_enable=YES
userlist_deny=NO
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
ssl_enable=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.key
tls_sslv2=NO
tls_sslv3=NO
```

```bash
systemctl restart vsftpd
```

### Chroot setup / Настройка chroot

```bash
mkdir -p /home/<USER>/ftpdir
chown <USER>:<USER> /home/<USER>/ftpdir
# vsftpd.conf: chroot_local_user=YES, allow_writeable_chroot=NO
```

---

## Core Management

### Logs / Логи

```bash
journalctl -u vsftpd --no-pager -n 50
tail -f /var/log/vsftpd.log
tail -f /var/log/xferlog
```

### Logrotate / Ротация логов

`/etc/logrotate.d/vsftpd`

```bash
/var/log/vsftpd.log /var/log/xferlog {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Disable anonymous login / Отключите anonymous-доступ
2. Enable TLS (FTPS) / Включите TLS (FTPS)
3. Use chroot_local_user / Используйте chroot_local_user
4. Restrict writable chroot / Ограничьте записываемый chroot
5. Use user_list allow-mode / Используйте user_list в режиме allow
6. Limit passive ports / Ограничьте passive-порты
7. Monitor logs / Мониторьте логи
8. Do not run as root if possible / Не запускайте от root

```bash
# /etc/vsftpd/ftpusers — block system users
root
bin
daemon
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/vsftpd-$(date +%F).tar.gz \
  /etc/vsftpd /var/ftp
```

### Restore / Восстановление

```bash
systemctl stop vsftpd
tar xzf /var/backups/vsftpd-<DATE>.tar.gz -C /
systemctl start vsftpd
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Connection refused | Service down / firewall | Start vsftpd; open 21 |
| 530 Login incorrect | PAM / user_list deny | Check PAM, user_list |
| 550 Permission denied | write_enable / chroot | Enable write; fix perms |
| Passive mode fails | Passive ports blocked | Open pasv port range |
| TLS errors | Cert path / openssl | Check cert files |

```bash
systemctl status vsftpd
vsftpd -v
ss -tlnp | grep 21
```

---

## Comparison Tables

### FTP / file transfer servers / FTP / файловые серверы

| Server | Notes |
| :--- | :--- |
| **vsftpd** | Secure, simple |
| **ProFTPD** | Feature-rich, Apache-like |
| **Pure-FTPd** | Lightweight |
| **OpenSSH SFTP** | Encrypted; modern default |

> [!WARNING]
> Plain FTP sends credentials in cleartext. Prefer SFTP or FTPS. / **Обычный FTP передаёт пароли открытым текстом — используйте SFTP/FTPS.**

---

## Production Runbooks

### Runbook: Deploy FTPS server / Развёртывание FTPS

1. Install vsftpd / Установить vsftpd
2. Generate or install TLS cert / Установить TLS-сертификат
3. Write vsftpd.conf with ssl_enable=YES / Настроить конфигурацию
4. Configure PAM and user_list / Настроить PAM и user_list
5. Create chroot directories; fix permissions / Создать chroot-каталоги
6. Open 21 and passive port range / Открыть порты
7. Start vsftpd; test FTPS login / Запустить; проверить вход
8. Document cert rotation / Задокументировать ротацию сертификатов

### Runbook: Restrict user to home FTP only / Ограничение пользователя FTP

1. Create system user with shell /bin/false or nologin / Создать пользователя
2. Create home/ftpdir owned by user / Создать ftpdir
3. Set chroot_local_user=YES; allow_writeable_chroot=NO / Настроить chroot
4. Add user to user_list (allow mode) / Добавить в user_list
5. Test login; verify cannot leave chroot / Проверить chroot
6. Document access / Задокументировать доступ

---

## Documentation Links

- vsftpd man — https://linux.die.net/man/8/vsftpd
- vsftpd.conf — https://linux.die.net/man/5/vsftpd.conf
- vsftpd security — https://security.appspot.com/vsftpd.html
