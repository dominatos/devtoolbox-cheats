---
Title: 📇 OpenLDAP — LDAP Directory
Group: "Identity Management"
Icon: 📇
Order: 11
tags:
  - identity
  - ldap
  - openldap
  - authentication
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

# 📇 OpenLDAP Cheatsheet

## Description

**OpenLDAP** is an open-source **LDAP directory service** used for centralized identity, authentication, and authorization. Clients include Linux PAM/nsswitch, Samba, FreeIPA, and custom apps. / **OpenLDAP** — открытый LDAP-каталог для централизованной идентификации, аутентификации и авторизации. Клиенты — PAM/nsswitch, Samba, FreeIPA, кастомные приложения.

**Common use cases / Типовые сценарии:**
- Central user/group directory / Централизованный каталог пользователей
- SSH/PAM authentication backend / Бэкенд аутентификации SSH/PAM
- Samba AD/DC integration / Интеграция с Samba
- Service account lookups / Поиск сервисных учёток

**Status:** Actively maintained (OpenLDAP Project). Alternatives: **FreeIPA** (integrated stack), **Microsoft AD**, **389-ds**, **OpenDJ**. / **Статус:** активно развивается; альтернативы — FreeIPA, AD, 389-ds.

**Default ports:** `389/tcp` (LDAP), `636/tcp` (LDAPS).  
**Paths:** Debian `/etc/ldap/slapd.conf` or cn=config; RHEL `/etc/openldap/slapd.d/`; data `/var/lib/ldap/`.

Cross-reference: [SSSD](sssdcheatsheet.md), [FreeIPA](freeipacheatsheet.md), [Samba](../storage-fs/sambacheatsheet.md), [sudoers/PAM](../security-crypto/sudoerspamcheatsheet.md).

---

## Installation

### Install OpenLDAP / Установка OpenLDAP

```bash
# Debian/Ubuntu
apt install slapd ldap-utils

# RHEL/Rocky/Alma/Fedora
dnf install openldap openldap-servers openldap-clients
```

```bash
slapd -VV 2>&1 | head
ldapsearch -VV 2>&1 | head
```

---

## Configuration

### Main files / Основные файлы

`/etc/ldap/slapd.conf` (Debian legacy)

`/etc/ldap/slapd.d/` (cn=config)

`/etc/openldap/slapd.d/` (RHEL)

`/etc/openldap/ldap.conf`

`/var/lib/ldap/`

### slapd.conf (legacy example) / slapd.conf (устаревший пример)

`/etc/ldap/slapd.conf`

```bash
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/inetorgperson.schema
include /etc/ldap/schema/nis.schema

pidfile /var/run/slapd/slapd.pid
argsfile /var/run/slapd/slapd.args

database mdb
maxsize 1073741824
suffix "dc=example,dc=com"
rootdn "cn=admin,dc=example,dc=com"
rootpw <SECRET_KEY>
directory /var/lib/ldap

index objectClass eq
index uid,uidNumber,gidNumber eq
index cn,sn,mail eq
```

```bash
slaptest -u -f /etc/ldap/slapd.conf
systemctl restart slapd
```

### Base DNs and OUs / Base DN и OU

```bash
# Example tree
# dc=example,dc=com
#   ou=people,dc=example,dc=com
#   ou=groups,dc=example,dc=com
```

---

## Core Management

### ldapsearch / ldapsearch

```bash
ldapsearch -x -H ldap://<LDAP_HOST> \
  -D "cn=admin,dc=example,dc=com" -w '<PASSWORD>' \
  -b "dc=example,dc=com" '(objectClass=person)' dn cn mail

ldapsearch -x -H ldap://<LDAP_HOST> -b "dc=example,dc=com" \
  '(uid=<USER>)' dn cn memberUid
```

### ldapadd / ldapadd

```bash
# LDIF add
ldapadd -x -H ldap://<LDAP_HOST> \
  -D "cn=admin,dc=example,dc=com" -w '<PASSWORD>' \
  -f /tmp/user.ldif
```

`/tmp/user.ldif`

```bash
dn: uid=alice,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
uid: alice
cn: Alice Example
sn: Example
mail: alice@<DOMAIN>
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/alice
loginShell: /bin/bash
userPassword: <SECRET_KEY>
```

### ldapmodify / ldapmodify

```bash
ldapmodify -x -H ldap://<LDAP_HOST> \
  -D "cn=admin,dc=example,dc=com" -w '<PASSWORD>' \
  -f /tmp/change.ldif
```

### ldapdelete / ldapdelete

```bash
ldapdelete -x -H ldap://<LDAP_HOST> \
  -D "cn=admin,dc=example,dc=com" -w '<PASSWORD>' \
  "uid=alice,ou=people,dc=example,dc=com"
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u slapd --no-pager -n 50
tail -f /var/log/slapd.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/slapd`

```bash
/var/log/slapd.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 openldap openldap
    sharedscripts
    postrotate
        systemctl kill -s HUP slapd >/dev/null 2>&1 || true
    endscript
}
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Use LDAPS (636) or StartTLS on production / Используйте LDAPS/StartTLS
2. Restrict rootdn network access / Ограничьте rootdn по сети
3. ACLs on sensitive attributes (userPassword) / ACL на userPassword
4. Disable anonymous binds where possible / Отключите anonymous binds
5. Backup database regularly / Регулярно бэкапьте БД
6. Keep OpenLDAP patched / Обновляйте OpenLDAP
7. Monitor failed binds / Мониторьте неудачные bind

```bash
# ACL example (slapd.conf)
access to attrs=userPassword
  by dn="cn=admin,dc=example,dc=com" write
  by anonymous auth
  by self write
  by * none
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Online backup via slapcat
slapcat -l /var/backups/ldap-$(date +%F).ldif
```

### Restore / Восстановление

```bash
systemctl stop slapd
rm -rf /var/lib/ldap/*   # only if intentional restore
slapadd -l /var/backups/ldap-<DATE>.ldif
chown -R openldap:openldap /var/lib/ldap
systemctl start slapd
```

> [!CAUTION]
> Restore replaces directory contents. Verify the LDIF and target DB before running slapadd. / **Restore перезаписывает каталог** — проверьте LDIF и БД.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Invalid credentials` | Wrong DN/password | Check rootdn, base DN |
| Connection refused | slapd down / firewall | Open 389/636; start slapd |
| No such object | Missing OU/base | Create base DN structure |
| TLS errors | Cert path / expired | Check slapd TLS config |
| High latency | Missing indexes | Add indexes; reindex |

```bash
slaptest -u -f /etc/ldap/slapd.conf
ldapsearch -x -H ldap://<LDAP_HOST> -b "dc=example,dc=com" -s base namingContexts
journalctl -u slapd -n 30
```

---

## Comparison Tables

### Directory services / Каталожные службы

| System | Notes |
| :--- | :--- |
| **OpenLDAP** | Flexible, DIY stack |
| **FreeIPA** | Integrated IdM (LDAP+Kerberos+DNS) |
| **Microsoft AD** | Enterprise Windows-centric |
| **389-ds** | Red Hat directory server |

---

## Production Runbooks

### Runbook: Bootstrap directory / Инициализация каталога

1. Install slapd; configure suffix/rootdn / Установить и настроить
2. Set root password; enable TLS / Задать пароль; включить TLS
3. Create base DN and OUs (people, groups) / Создать OU
4. Add first admin user / Добавить первого администратора
5. Configure PAM/nsswitch on clients / Настроить PAM/nsswitch
6. Test ldapsearch from client / Проверить ldapsearch
7. Schedule slapcat backups / Запланировать бэкапы

### Runbook: Rotate LDAP admin password / Ротация пароля LDAP admin

1. Ensure alternate admin access exists / Убедиться в альтернативном доступе
2. `ldappasswd -S cn=admin,dc=example,dc=com` / Сменить пароль
3. Update service accounts referencing rootdn / Обновить сервисные учётки
4. Test bind with new password / Проверить bind
5. Document change in secret manager / Задокументировать в vault

---

## Documentation Links

- OpenLDAP admin guide — https://www.openldap.org/doc/admin26/
- ldapsearch(1) — https://linux.die.net/man/1/ldapsearch
- slapd.conf(5) — https://linux.die.net/man/5/slapd.conf
- Debian OpenLDAP — https://wiki.debian.org/OpenLDAP
