---
Title: 🪪 SSSD — System Security Services
Group: "Identity Management"
Icon: 🪪
Order: 13
tags:
  - identity
  - sssd
  - ldap
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
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🪪 SSSD Cheatsheet

## Description

**SSSD** (System Security Services Daemon) is the standard **PAM/nsswitch client** for LDAP, FreeIPA, and Active Directory. It provides caching, offline auth, and HBAC/sudo integration. / **SSSD** — стандартный PAM/nsswitch-клиент для LDAP, FreeIPA и Active Directory. Кэширование, offline-аутентификация, интеграция с HBAC/sudo.

**Common use cases / Типовые сценарии:**
- LDAP/AD user auth on Linux servers / Аутентификация LDAP/AD на Linux
- Offline login with cache / Offline-вход с кэшем
- Sudo rules from directory / Sudo-правила из каталога
- HBAC-like access via AD groups / Доступ через AD-группы

**Status:** Actively maintained (SSSD upstream / distros). Alternatives: **nslcd**, **pam_ldap**, **winbind** (Samba). / **Статус:** активно развивается; альтернативы — nslcd, pam_ldap, winbind.

**Paths:** config `/etc/sssd/sssd.conf` (mode 0600); cache `/var/lib/sss/db/`; logs journalctl.

Cross-reference: [OpenLDAP](openldapcheatsheet.md), [FreeIPA](freeipacheatsheet.md), [sudoers/PAM](../security-crypto/sudoerspamcheatsheet.md), [Samba](../storage-fs/sambacheatsheet.md).

---

## Installation

### Install SSSD / Установка SSSD

```bash
# Debian/Ubuntu
apt install sssd sssd-ldap sssd-ad sssd-tools

# RHEL/Rocky/Alma/Fedora
dnf install sssd sssd-ldap sssd-ad
```

```bash
sssctl --version
systemctl enable --now sssd
```

---

## Configuration

### Main files / Основные файлы

`/etc/sssd/sssd.conf`

`/etc/nsswitch.conf`

`/etc/pam.d/sshd`

`/etc/pam.d/system-auth`

### sssd.conf (LDAP) / sssd.conf (LDAP)

`/etc/sssd/sssd.conf`

```bash
[sssd]
domains = <DOMAIN>
config_file_version = 2
services = nss, pam, sudo, ssh

[domain/<DOMAIN>]
id_provider = ldap
auth_provider = ldap
access_provider = ldap
ldap_uri = ldap://<LDAP_HOST>
ldap_search_base = dc=example,dc=com
ldap_default_bind_dn = cn=admin,dc=example,dc=com
ldap_default_authtok = <SECRET_KEY>
ldap_default_authtok_type = password
cache_credentials = true
enumerate = false
default_shell = /bin/bash
fallback_homedir = /home/%u
use_fully_qualified_names = false
ldap_pwd_policy = shadow
access_provider = simple
simple_allow_groups = sysadmins
```

### nsswitch / nsswitch

`/etc/nsswitch.conf`

```bash
passwd: files sss
shadow: files sss
group:  files sss
sudoers: files sss
```

```bash
chmod 0600 /etc/sssd/sssd.conf
systemctl restart sssd
sssctl config-check
```

---

## Core Management

### sssctl / sssctl

```bash
sssctl config-check
sssctl domain-status <DOMAIN>
sssctl user-checks <USER>
sssctl cache-init
sssctl cache-remove
sssctl failover-show
```

### Debug / Отладка

```bash
sssctl domain-debug <DOMAIN>
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u sssd --no-pager -n 50
journalctl -t sssd --no-pager -n 50
```

### Logrotate / Ротация логов

`/etc/logrotate.d/sssd`

```bash
/var/log/sssd/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Security

### Hardening / Ужесточение

1. `sssd.conf` must be mode 0600 root / Права 0600 root
2. Prefer TLS (ldaps/StartTLS) / Предпочитайте ldaps/StartTLS
3. Limit `enumerate = false` unless needed / Не включайте enumerate без нужды
4. Restrict simple_allow_groups / Ограничьте simple_allow_groups
5. Cache is local — protect host / Кэш локальный — защищайте хост
6. Keep SSSD updated / Обновляйте SSSD

```bash
ls -l /etc/sssd/sssd.conf
# -rw------- 1 root root
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `getent passwd` no users | sssd down / wrong domain | `systemctl status sssd` |
| Auth fails | wrong bind DN/password | Check ldap_default_authtok |
| Offline login fails | cache empty | `sssctl cache-init`; enable cache |
| `sssctl config-check` fails | syntax | Fix sssd.conf |
| Slow logins | LDAP unreachable / timeout | Check network, reduce timeout |

```bash
sssctl config-check
sssctl domain-status <DOMAIN>
getent passwd <USER>
systemctl status sssd
```

---

## Comparison Tables

### NSS/PAM clients / NSS/PAM клиенты

| Client | Notes |
| :--- | :--- |
| **SSSD** | Cache, offline, multi-provider |
| **nslcd** | Simple LDAP client |
| **winbind** | Samba/AD focused |
| **pam_ldap** | Legacy LDAP PAM |

---

## Production Runbooks

### Runbook: Join server to LDAP via SSSD / Присоединение сервера к LDAP

1. Install sssd packages / Установить пакеты
2. Write sssd.conf with LDAP URI and bind DN / Настроить sssd.conf
3. `chmod 0600 sssd.conf` / Исправить права
4. `sssctl config-check` / Проверить конфигурацию
5. `systemctl enable --now sssd` / Запустить sssd
6. `getent passwd <USER>` / Проверить lookup
7. Test SSH login / Проверить SSH-вход

### Runbook: SSSD cache rebuild / Пересборка кэша SSSD

1. Stop sssd / Остановить sssd
2. `sssctl cache-remove` / Очистить кэш
3. Start sssd / Запустить sssd
4. `sssctl cache-init` / Инициализировать кэш
5. Verify user lookup / Проверить lookup

---

## Documentation Links

- SSSD docs — https://sssd.github.io/
- SSSD man — https://linux.die.net/man/8/sssd
- RHEL SSSD — https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_authentication_and_authorization_in_rhel/sssd
