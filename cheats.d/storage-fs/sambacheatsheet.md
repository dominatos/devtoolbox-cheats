---
Title: 📁 Samba — SMB/CIFS Shares
Group: "Storage & FS"
Icon: 📁
Order: 21
tags:
  - storage
  - samba
  - smb
  - cifs
  - file-sharing
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

# 📁 Samba Cheatsheet

## Description

**Samba** implements the **SMB/CIFS** protocol on Linux/Unix, enabling Windows-compatible file/print shares and AD/DC features. Clients mount shares via **cifs-utils** (`mount.cifs`) or Windows Explorer. / **Samba** — реализация **SMB/CIFS** на Linux: файловые/принтерные шары и AD/DC. Клиенты — через `mount.cifs` или Windows.

**Common use cases / Типовые сценарии:**
- File shares for Windows/macOS/Linux mixed fleets / Файловые шары для смешанного флота
- Integration with Active Directory / Интеграция с Active Directory
- Home directories and roaming profiles / Домашние каталоги и профили
- Central backups drop zone / Центральная точка бэкапов

**Status:** Actively maintained (Samba project). Alternatives: **NFS** (Unix-native, better perf), **WebDAV**, **Nextcloud** (sync-centric), **10.0.0.x NAS UIs** (vendor). / **Статус:** активно развивается; альтернативы — NFS, WebDAV, Nextcloud.

**Default ports:** `137-139/udp` (NetBIOS), `139/tcp`, `445/tcp` (SMB).  
**Paths:** config `/etc/samba/smb.conf`; logs `/var/log/samba/`; users via `smbpasswd`/`tdbsam`.

Cross-reference: [NFS](nfssharecheatsheet.md), [storage](diskcheatsheet.md), [LVM](lvmcheatsheet.md).

---

## Installation

### Install Samba / Установка Samba

```bash
# Debian/Ubuntu
apt install samba samba-common-bin smbclient

# RHEL/Rocky/Alma/Fedora
dnf install samba samba-common samba-client

# SUSE
zypper install samba
```

```bash
systemctl enable --now smb nmb    # Debian: smbd nmbd
systemctl status smbd
```

### Client tools / Клиентские инструменты

```bash
# Debian/Ubuntu
apt install cifs-utils

# RHEL
dnf install cifs-utils
```

---

## Configuration

### Main files / Основные файлы

`/etc/samba/smb.conf`

`/etc/samba/smb.conf.d/*.conf` (drop-ins, newer)

`/var/lib/samba/` (tdbsam database)

`/var/log/samba/log.smbd`

### Global + share config / Глобальные и шаровые настройки

`/etc/samba/smb.conf`

```bash
[global]
   workgroup = <WORKGROUP>
   security = user
   map to guest = bad user
   server string = File Server %h
   netbios name = <NETBIOS_NAME>
   interfaces = <LAN_IF> lo
   bind interfaces only = yes
   smb ports = 445
   server min protocol = SMB2
   server max protocol = SMB3
   log file = /var/log/samba/log.%m
   max log size = 10000
   dns proxy = no
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes
   # Domain member example:
   # realm = <REALM>
   # security = ads
   # idmap config * : range = 100000-999999
   # winbind use default domain = yes

[data]
   path = /srv/samba/data
   browseable = yes
   read only = no
   valid users = @staff
   write list = @staff
   create mask = 0664
   directory mask = 0775
   force group = staff
   # veto files = /.AppleDouble/._*
```

```bash
testparm                 # Validate smb.conf
systemctl restart smbd nmbd
```

### Samba user database / База пользователей Samba

```bash
# Create system user first (if local)
useradd -M -s /usr/sbin/nologin sambauser

# Set Samba password (tdbsam)
smbpasswd -a sambauser
smbpasswd -e sambauser
smbpasswd -d sambauser
pdbedit -L -v
```

### CIFS mount / Монтирование CIFS

```bash
# Interactive
mount -t cifs //<SERVER>/<SHARE> /mnt/share -o username=<USER>,uid=1000,gid=1000,iocharset=utf8

# With credentials file
//<SERVER>/<SHARE>  /mnt/share  cifs  credentials=/etc/samba/cred,uid=1000,gid=1000,_netdev,nofail  0  0
```

`/etc/samba/cred`

```bash
username=<USER>
password=<SECRET_KEY>
domain=<DOMAIN>
```

```bash
chmod 0600 /etc/samba/cred
```

---

## Core Management

### Client access / Доступ клиентов

```bash
smbclient //<SERVER>/<SHARE> -U <USER>
smbclient //<SERVER>/<SHARE> -U <USER> -c 'ls; put local.txt; get remote.txt'
smbtree -U <USER>
```

### Server monitoring / Мониторинг сервера

```bash
smbstatus
smbstatus --profile
smbstatus -p          # processes
smbstatus -S          # shares
smbstatus -L          # locks
```

Sample `smbstatus` excerpt:

```text
PID     Username     Group        Machine
12345   sambauser    staff        <CLIENT_IP> (ipv4:<CLIENT_IP>:45234)
```

### DNS/NBNS / DNS и NetBIOS

```bash
# Ensure 445/tcp open
ss -lntp | grep -E '445|139'
smbclient -L <SERVER> -U <USER>
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u smbd --no-pager -n 50
tail -f /var/log/samba/log.smbd
```

### Logrotate / Ротация логов

`/etc/logrotate.d/samba`

```bash
/var/log/samba/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl kill -s HUP smbd >/dev/null 2>&1 || true
    endscript
}
```

### Disk quota / Квоты диска

```bash
# Optional: setquota for share users (XFS/ext4)
setquota -u sambauser 50G 60G 0 0 /srv/samba/data
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Use `security = user` (or ads) — never `security = share` / Не используйте share-безопасность
2. Prefer SMB3 + encryption if supported / Предпочитайте SMB3
3. Bind to specific interfaces / Привязывайтесь к интерфейсам
4. Restrict `valid users` per share / Ограничьте `valid users`
5. Keep credentials files mode 0600 / Файлы cred — только root
6. Disable guest/anonymous where not required / Отключите guest
7. Monitor `smbstatus` for anomalies / Мониторьте активные сессии
8. Apply filesystem ACLs consistent with smb.conf / Согласуйте ACL ФС с smb.conf

```bash
# Encrypt SMB3 when client supports it
# mount -t cifs ... -o vers=3.0,seal
```

> [!WARNING]
> SMB on untrusted networks can leak credentials if forced to older dialects. Prefer VPN/VLAN + SMB3. / На незащищённых сетях SMB может утекать учётки — используйте SMB3 и изолированные сети.

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Data
tar czf /var/backups/samba-data-$(date +%F).tar.gz -C /srv/samba/data .

# Config + user DB (tdbsam)
tar czf /var/backups/samba-config-$(date +%F).tar.gz \
  /etc/samba /var/lib/samba/private /var/lib/samba/users
```

### Restore / Восстановление

```bash
systemctl stop smbd nmbd
tar xzf /var/backups/samba-config-<DATE>.tar.gz -C /
tar xzf /var/backups/samba-data-<DATE>.tar.gz -C /srv/samba/data
systemctl start smbd nmbd
smbstatus
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Connection refused` on 445 | smbd down / firewall | `systemctl start smbd`; open 445/tcp |
| `NT_STATUS_LOGON_FAILURE` | Wrong smbpasswd / not enabled | `smbpasswd -a`/`-e`; check pdbedit |
| `NT_STATUS_ACCESS_DENIED` | valid users / unix perms | Check share ACL + unix ownership |
| Share visible but empty | browseable / path perms | `ls -la /srv/samba/data` |
| Slow large copies | smb3 vs dialect / disk | Force `vers=3.0`; check disk I/O |
| macOS Finder issues | ntdot / vfs modules | Add `vfs objects = catia fruit streams_xattr` |

```bash
testparm -s
smbclient //<SERVER>/<SHARE> -U <USER> -c ls
smbstatus
tail -20 /var/log/samba/log.smbd
```

---

## Comparison Tables

### File sharing protocols / Протоколы файлового доступа

| Protocol | Client ecosystem | Auth | Performance | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **SMB/CIFS** | Windows, macOS, Linux | SMB user/AD | Good | Windows-native |
| **NFS** | Linux/Unix | Kerberos / IP | Better raw | No Windows-native |
| **WebDAV** | HTTP clients | HTTP basic/SSO | Medium | Firewall-friendly |
| **FTP/SFTP** | Legacy automation | Password/key | Variable | Not real-time shares |

---

## Production Runbooks

### Runbook: New department share / Новый общий доступ для отдела

1. Create unix group `dept_abc` / Создать группу unix
2. Create `/srv/samba/dept_abc` with correct ownership / Создать каталог
3. Add smb.conf share block with `valid users = @dept_abc` / Добавить share
4. `testparm` + restart smbd / Проверить и перезапустить
5. `smbpasswd -a` for each user / Добавить пользователей
6. Test mount from Windows and Linux / Проверить доступ
7. Configure quota if required / Настроить квоты

### Runbook: Migrate share to new server / Миграция шары на новый сервер

1. rsync data to new path (idle window) / Синхронизировать данные
2. Freeze writes on source (optional) / Заморозить запись
3. Final rsync + verify checksums / Финальная синхронизация
4. Cut DNS/IP or inform clients / Переключить клиентов
5. Keep old share read-only for 1–2 weeks / Оставить старый share read-only

---

## Documentation Links

- Samba docs — https://wiki.samba.org/index.php/Main_Page
- smb.conf man — https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- smbstatus — https://www.samba.org/samba/docs/current/man-html/smbstatus.1.html
- mount.cifs — https://manpages.ubuntu.com/manpages/jammy/en/man8/mount.cifs.8.html
- Samba AD — https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
