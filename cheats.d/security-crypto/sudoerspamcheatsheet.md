---
Title: 🔐 sudoers / PAM — Privilege & Auth
Group: "Security & Crypto"
Icon: 🔐
Order: 21
tags:
  - security
  - sudo
  - pam
  - access-control
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

# 🔐 sudoers / PAM Cheatsheet

## Description

**sudo** grants controlled privilege escalation; the **sudoers** file defines who may run which commands as which users. **PAM (Pluggable Authentication Modules)** is the authentication stack used by sudo, SSH, login, and systemd sessions. / **sudo** — контролируемое повышение привилегий; **sudoers** — кто и что может запускать. **PAM** — стек аутентификации для sudo, SSH, login.

**Common use cases / Типовые сценарии:**
- Delegating admin without full root / Делегирование админских прав без root
- Time-limited / command-specific access / Доступ с ограничением по времени и командам
- Central policy via LDAP sudoers / Централизация политик через LDAP
- PAM hardening for SSH and local logins / Ужесточение аутентификации через PAM

**Status:** sudo + sudoers is the default privilege mechanism on mainstream Linux (not legacy). Alternatives: **doas** (OpenBSD-style, lighter), **pkexec/PolicyKit** (desktop polkit), **RBAC** (Solaris/illumos style). / **Статус:** стандарт для Linux; альтернативы — doas, polkit, RBAC.

**Paths:** `/etc/sudoers`, `/etc/sudoers.d/*`, `/etc/pam.d/sudo`, `/etc/pam.d/sshd`, logs `/var/log/auth.log` or `/var/log/secure`.

Cross-reference: [Polkit](polkicheatsheet.md), [SSH keys](ssh_keys_cheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md).

---

## Installation

### Packages / Пакеты

```bash
# Debian/Ubuntu (usually preinstalled)
apt install sudo

# RHEL/Rocky/Alma
dnf install sudo

# doas alternative (if policy chooses it)
apt install doas
```

```bash
sudo --version
visudo --version
```

---

## Configuration

### Main files / Основные файлы

`/etc/sudoers` (read-only policy; edit via visudo)

`/etc/sudoers.d/` (include directory)

`/etc/sudo.conf` (plugin loading)

`/etc/pam.d/sudo` (PAM stack for sudo)

`/etc/pam.d/sshd` (PAM stack for SSH)

`/etc/pam.d/common-auth` (Debian family shared auth)

```bash
# Edit policy SAFELY (syntax check + backup)
visudo -f /etc/sudoers
visudo -f /etc/sudoers.d/90-sysadmin
```

> [!CAUTION]
> A syntax error in sudoers can lock out privilege escalation. Always use `visudo` (it validates and refuses to save a broken file). Keep an open root session while testing. / Ошибка в sudoers может лишить доступа. Всегда правьте через `visudo`; держите открытую root-сессию.

### sudoers basics / Основы sudoers

```bash
# Format: who where = (as_whom) what
# File: /etc/sudoers.d/10-admins
```

```bash
# /etc/sudoers.d/10-admins
Defaults        env_reset
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

User_Alias      ADMINS = alice, bob, %sysadmins
Runas_Alias     DB = postgres, mysql
Cmnd_Alias      SERVICE = /usr/bin/systemctl restart *, /usr/bin/systemctl reload *
Cmnd_Alias      DOCKER = /usr/bin/docker
Cmnd_Alias      PKG = /usr/bin/apt, /usr/bin/apt-get, /usr/bin/dnf

ADMINS          ALL = (ALL:ALL) ALL
%sysadmins      ALL = (DB) NOPASSWD: SERVICE
alice           ALL = (root) NOPASSWD: DOCKER
bob             ALL = ALL:SERVICE
```

### Common Defaults / Частые Defaults

```bash
# /etc/sudoers.d/00-defaults
Defaults        timestamp_timeout=15
Defaults        env_reset
Defaults        mail_badpass
Defaults        logfile="/var/log/sudo.log"
Defaults        lecture=never
# Defaults      requiretty          # only if policy demands terminal
```

### Passwordless patterns / Паттерны без пароля

```bash
# Restricted: only specific service commands
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp.service

# Group-based
%ops ALL=(root) NOPASSWD: /usr/bin/journalctl -u *

# sudoedit for config-only access
%editors ALL=(root) sudoedit /etc/nginx/nginx.conf, /etc/nginx/conf.d/*.conf
```

> [!WARNING]
> Avoid `ALL=(ALL) NOPASSWD: ALL` for regular users. Prefer command aliases + group grants. / Избегайте `ALL=(ALL) NOPASSWD: ALL` для обычных пользователей.

### PAM — basic hardening / Базовое ужесточение PAM

`/etc/pam.d/sshd`

```bash
# Debian family (common-auth chain)
auth       required     pam_unix.so
auth       optional     pam_faillock.so preauth
auth       [success=1 default=ignore] pam_succeed_if.so user ingroup wheel
auth       required     pam_deny.so
account    required     pam_unix.so
account    required     pam_faillock.so
account    required     pam_succeed_if.so user ingroup wheel
account    required     pam_unix.so
session    required     pam_limits.so
```

`/etc/security/faillock.conf`

```bash
deny = 5
unlock_time = 900
even_deny_root
root_unlock_time = 900
```

```bash
# Optional: faillock CLI
faillock --user <USER>
faillock --user <USER> --reset
```

### sudo + PAM interaction / Взаимодействие sudo и PAM

```bash
# pam_unix authenticates the INVOKING user for sudo
# sudo timestamp cache (default 5 min) may skip PAM after first auth
# Force re-auth per command via timestamp_timeout=0
```

---

## Core Management

### Inspect rights / Просмотр прав

```bash
sudo -l                 # List own privileges
sudo -l -U <USER>       # List another user (needs rights)
sudo -V | head          # Version + environment policy details
sudo -n true            # Test passwordless non-interactively
```

### Validate policy / Проверка политики

```bash
visudo -c               # Syntax check sudoers + includes
visudo -f /etc/sudoers.d/90-sysadmin -c
```

Sample output:

```text
/etc/sudoers: parsed OK
/etc/sudoers.d: parsed OK
```

### Audit sudo usage / Аудит использования sudo

```bash
# journal (systemd systems)
journalctl -t sudo --no-pager -n 50
journalctl -t sudo -f

# traditional logs
grep sudo /var/log/auth.log | tail -50
grep sudo /var/log/secure | tail -50
```

### I/O logging (optional) / Логирование ввода-вывода

```bash
# /etc/sudoers.d/20-iolog
Defaults        log_input, log_output
Defaults        iolog_dir=/var/log/sudo-io/%{user}
Defaults        iolog_file=%{seq}
```

```bash
# Replay session
sudo -re <SEQ_ID>
```

> [!NOTE]
> I/O logs can contain secrets typed into terminals. Protect `/var/log/sudo-io` (root-only) and rotate/retention carefully. / Логи iolog могут содержать секреты — ограничьте доступ и ротацию.

---

## Sysadmin Operations

### Service interaction / Работа с сервисами

```bash
sudo systemctl restart nginx   # Check status / Проверить статус
sudo systemctl status sshd
sudo -l -U alice | grep systemctl
```

### Limits / Ограничения

```bash
# Resource limits via PAM
cat /etc/security/limits.conf
# /etc/security/limits.d/50-nofile.conf
# nginx soft nofile 65535
# nginx hard nofile 65535
```

### Logrotate / Ротация логов

`/etc/logrotate.d/sudo`

```bash
/var/log/sudo.log {
    monthly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0600 root adm
}
```

`/etc/logrotate.d/auth`

```bash
# Debian/Ubuntu typically own /var/log/auth.log via rsyslog/logrotate
# RHEL: /var/log/secure
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Never edit sudoers with a raw editor — only `visudo` / Правьте только через visudo
2. Grant least privilege commands, not shells / Минимальные команды, не оболочки
3. Prefer groups over per-user snowflakes / Группы вместо индивидуальных правил
4. Disable NOPASSWD where MFA is mandatory / Отключайте NOPASSWD при обязательном MFA
5. Monitor `auth.log`/`secure` for sudo anomalies / Мониторинг sudo-событий
6. Restrict `sudoedit` paths / Ограничьте пути sudoedit
7. Keep `secure_path` correct to avoid PATH hijack / Не доверяйте PATH пользователя
8. Test with `sudo -l` after every change / Проверяйте права после каждой правки

### Common dangerous patterns / Опасные паттерны

```bash
# BAD — full shell escalation for everyone
%wheel ALL=(ALL) ALL   # acceptable only with strong account hygiene

# BAD — wildcard commands
user ALL=(root) /usr/bin/systemctl *   # too broad

# BAD — passwordless root for automation accounts without monitoring
backup ALL=(root) NOPASSWD: ALL
```

---

## Troubleshooting

| Symptom | Likely cause | Check |
| :--- | :--- | :--- |
| `sudo: a terminal is required` | `requiretty` / missing TTY | `sudo -V`; remove requiretty if unwanted |
| `user is not in the sudoers file` | typo / not in group | `getent group sudo wheel`; `visudo -c` |
| `sudo: parse error` | broken sudoers | `visudo -c`; fix last good snippet |
| `pam_unix(sudo:auth): authentication failure` | PAM module missing | `ls /etc/pam.d/sudo`; package deps |
| timestamp not expiring | timestamp_timeout too high | Defaults `timestamp_timeout=` |
| SSH deny after PAM edit | faillock / pam_deny | `faillock --user`; read auth.log |

```bash
sudo -V | grep -i path
journalctl -t sudo --since today --no-pager
sudo -l -U <USER> -vv
```

---

## Comparison Tables

### Escalation tools / Инструменты эскалации

| Tool | Policy source | UI/UX | Typical use |
| :--- | :--- | :--- | :--- |
| **sudo/sudoers** | `/etc/sudoers(.d)` or LDAP | CLI | Default Linux admin path |
| **doas** | `/etc/doas.conf` | CLI | Minimal, OpenBSD-style |
| **polkit** | `/usr/share/polkit-1/actions` | Desktop + pkexec | GUI/desktop actions |
| **SELinux RBAC** | MAC policies | Kernel | High-assurance confinement |

### Passwordless vs NOPASSWD vs PAM MFA / Сравнение аутентификации

| Mechanism | Security | Automation | Notes |
| :--- | :--- | :--- | :--- |
| Password each time (`timestamp_timeout=0`) | Strongest interactive | Poor | Best for shared jump hosts |
| Timestamp cache (default 5m) | Balanced | OK | Re-auth after timeout |
| NOPASSWD specific cmds | Medium | Best | Monitor heavily; lock down cmds |
| sudo + MFA (pam_otp/yubikey) | Strong | Medium | Pair with short timestamp |

---

## Production Runbooks

### Runbook: Grant deploy access to service group / Выдача deploy-прав группе

1. Create OS group `deployers` / Создать группу
2. `usermod -aG deployers <USER>` for each deployer / Добавить пользователей
3. Add sudoers.d rule with command alias only for `systemctl restart myapp` / Добавить правило с командой
4. `visudo -c` — must parse OK / Проверить синтаксис
5. `sudo -l -U <USER>` — verify granted commands / Проверить выданные права
6. Test as deployer: `sudo -n systemctl restart myapp` / Проверить запуск без пароля
7. Monitor auth log for sudo events / Включить мониторинг событий sudo

### Runbook: Emergency lockout recovery / Восстановление после блокировки

1. Do NOT edit sudoers via scp/ansible without validation / Не правьте файл напрямую
2. Use console/IPMI/serial access (physical or hypervisor) / Используйте консоль доступа
3. `visudo -c` to locate syntax error / Найти синтаксическую ошибку
4. Fix or comment offending line; save via visudo / Исправить и сохранить через visudo
5. Open new root shell; test `su -` and `sudo -l` / Проверить root-доступ
6. Re-enable monitoring; document root cause / Задокументировать причину

---

## Documentation Links

- sudoers(5) — https://www.sudo.ws/docs/man/sudoers.man/
- PAM — https://github.com/linux-pam/linux-pam
- faillock — https://github.com/linux-pam/linux-pam (pam_faillock)
- OpenBSD doas — https://github.com/sudo-project/doas
- Polkit — https://www.freedesktop.org/software/polkit/docs/latest/
- Debian sudoers — https://wiki.debian.org/sudo
