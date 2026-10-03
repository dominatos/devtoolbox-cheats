---
Title: 🪪 FreeIPA — Integrated Identity
Group: "Identity Management"
Icon: 🪪
Order: 12
tags:
  - identity
  - freeipa
  - ipa
  - kerberos
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

# 🪪 FreeIPA Cheatsheet

## Description

**FreeIPA** (Identity, Policy, Authentication) is an integrated identity management solution combining **LDAP (389-ds)**, **Kerberos**, **DNS**, **NTP**, and **certificate management** with a web UI and CLI. / **FreeIPA** — интегрированное управление идентичностью: LDAP, Kerberos, DNS, NTP, сертификаты, web UI и CLI.

**Common use cases / Типовые сценарии:**
- Linux enterprise IdM / Корпоративное управление идентичностью Linux
- Kerberos SSO / Kerberos SSO
- Host-based access control / Доступ на уровне хостов
- Certificate issuance for hosts/services / Выпуск сертификатов для хостов/сервисов

**Status:** Actively maintained (Red Hat / community). Alternatives: **Microsoft AD**, **OpenLDAP + MIT Kerberos** DIY, **Keycloak** (app-focused IdP). / **Статус:** активно развивается; альтернативы — AD, OpenLDAP+Kerberos, Keycloak.

**Default ports:** `80/443` (UI/API), `389/636` (LDAP), `88/464` (Kerberos), `53` (DNS).  
**Paths:** config `/etc/ipa/`; client `/etc/ipa/default.conf`.

Cross-reference: [OpenLDAP](openldapcheatsheet.md), [SSSD](sssdcheatsheet.md), [adcli](adclicheatsheet.md), [Keycloak](keycloak.md).

---

## Installation

### Install FreeIPA server / Установка сервера FreeIPA

```bash
# RHEL/Rocky/Alma/Fedora
dnf install ipa-server ipa-server-dns

# DNS-less server
dnf install ipa-server
```

```bash
ipa-server-install --setup-dns \
  --realm=<REALM> \
  --domain=<DOMAIN> \
  --ds-password=<SECRET_KEY> \
  --admin-password=<SECRET_KEY> \
  --mkhomedir
```

### Install FreeIPA client / Установка клиента FreeIPA

```bash
dnf install ipa-client
ipa-client-install --domain=<DOMAIN> --realm=<REALM> \
  --server=<IPA_HOST> --principal=admin --password=<SECRET_KEY>
```

```bash
ipa --version
```

---

## Configuration

### Main files / Основные файлы

`/etc/ipa/default.conf`

`/etc/ipa/ca.crt`

`/var/log/ipaclient.log`

`/var/log/ipaserver.log`

### Client config / Конфигурация клиента

`/etc/ipa/default.conf`

```bash
[global]
realm = <REALM>
domain = <DOMAIN>
basedn = dc=<DOMAIN_PART>,dc=<DOMAIN_TLD>
server = <IPA_HOST>
host = <CLIENT_HOST>
xmlrpc_uri = https://<IPA_HOST>/ipa/xmlrpc
ldap_uri = ldap://<IPA_HOST>
enable_ra = True
```

---

## Core Management

### IPA CLI basics / Основы IPA CLI

```bash
ipa user-show <USER>
ipa user-add <USER> --first=<FIRST> --last=<LAST>
ipa group-show <GROUP>
ipa host-show <CLIENT_HOST>
ipa service-show HTTP/<HOST>
ipa env
ipa getent user <USER>
ipa getent group <GROUP>
```

### User and group / Пользователь и группа

```bash
ipa user-add alice --first=Alice --last=Example --password
ipa group-add sysadmins --desc="System administrators"
ipa group-add-member sysadmins --users=alice
ipa user-mod alice --shell=/bin/bash
```

### HBAC and sudo / HBAC и sudo

```bash
ipa hbacrule-add allow_ssh --desc="Allow SSH from jump hosts"
ipa hbacrule-add-host allow_ssh --hosts=<JUMP_HOST>
ipa hbacrule-add-user allow_ssh --users=alice
ipa sudorule-add sysadmins --desc="Sysadmin sudo rules"
ipa sudorule-add-allow-command sysadmins --cmdcat=all
ipa sudorule-add-user sysadmins --groups=sysadmins
```

---

## Sysadmin Operations

### Service control / Управление сервисами

```bash
systemctl status ipa
systemctl status krb5kdc
systemctl status kadmin
```

### Logs / Логи

```bash
journalctl -u ipa --no-pager -n 50
journalctl -u krb5kdc --no-pager -n 50
tail -f /var/log/ipaserver.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/ipa`

```bash
/var/log/ipa*.log {
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

1. Keep realm password and admin password in vault / Храните пароли в vault
2. Restrict HBAC rules per host group / Ограничивайте HBAC по хост-группам
3. Use host-based sudo rules / Используйте host-based sudo
4. Monitor failed Kerberos auth / Мониторьте неудачные Kerberos-auth
5. Back up IPA regularly / Регулярно бэкапьте IPA
6. Keep FreeIPA patched / Обновляйте FreeIPA

```bash
ipa env | grep -E 'domain|realm|basedn'
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
ipa-backup --data --logs
# Output under /var/lib/ipa/backup/
```

### Restore / Восстановление

```bash
# Only during maintenance window
ipa-restore /var/lib/ipa/backup/<BACKUP_DIR>
```

> [!CAUTION]
> ipa-restore is destructive and requires downtime. Verify backup integrity first. / **ipa-restore деструктивен и требует простоя.**

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `kinit: Password incorrect` | Wrong password / clock skew | Check time sync; password |
| Client cannot join | DNS / firewall | Verify DNS, ports 88/389 |
| HBAC denies access | Rule not matching | `ipa hbacrule-show` |
| Kerberos ticket expired | 10h default | `kinit` again |
| `ipa env` fails | Client misconfigured | Re-run ipa-client-install |

```bash
kinit admin
ipa env
ipa user-show <USER>
journalctl -u krb5kdc -n 30
```

---

## Comparison Tables

### Identity stacks / Стеки идентичности

| Stack | Components | Best for |
| :--- | :--- | :--- |
| **FreeIPA** | LDAP+Kerberos+DNS+certs | Integrated Linux IdM |
| **OpenLDAP DIY** | LDAP only | Custom setups |
| **Microsoft AD** | LDAP+Kerberos+GPO | Windows-centric |
| **Keycloak** | App IdP (OIDC/SAML) | Application SSO |

---

## Production Runbooks

### Runbook: Enroll new client / Присоединение нового клиента

1. Configure DNS to IPA server / Настроить DNS
2. Sync time (chrony/NTP) / Синхронизировать время
3. `ipa-client-install` with admin principal / Установить клиент
4. Verify `ipa env` and user lookup / Проверить env и lookup
5. Test SSH: `ssh <USER>@<CLIENT_HOST>` / Проверить SSH
6. Add client to HBAC/sudo rules if needed / Добавить в HBAC/sudo

### Runbook: Password reset for IPA user / Сброс пароля IPA-пользователя

1. `ipa user-mod <USER> --password` / Сменить пароль
2. Or self-service via web UI / Или self-service через web UI
3. Invalidate old Kerberos tickets if compromised / Инвалидировать тикеты
4. Document change / Задокументировать изменение

---

## Documentation Links

- FreeIPA docs — https://freeipa.org/page/Documentation
- FreeIPA admin guide — https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/identity_management/
- FreeIPA GitHub — https://github.com/freeipa/freeipa
- Kerberos — https://web.mit.edu/kerberos/
