Title: 🔑 SSH Keys & Access Management
Group: Security & Crypto
Icon: 🔑
Order: 30

# SSH Keys & Access Management Sysadmin Cheatsheet

> **Context:** SSH (Secure Shell) key-based authentication is the standard method for secure remote server access. This cheatsheet covers the complete lifecycle of SSH keys: generation (ED25519/RSA), secure distribution, client/server configuration, security hardening, and troubleshooting. Key-based auth is more secure than passwords and enables automated workflows. / SSH-аутентификация по ключам — стандартный метод безопасного удалённого доступа к серверам. Это руководство охватывает полный жизненный цикл SSH-ключей: генерацию, распространение, настройку, усиление безопасности и диагностику.
> **Role:** Sysadmin / DevOps Engineer
> **Default Port:** `22`
> **See also:** [SSH Honeypot + CrowdSec](ssh_honeypot_crowdsec.md)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Key Generation](#2-key-generation)
3. [Key Distribution](#3-key-distribution)
4. [Client Configuration](#4-client-configuration)
5. [Server Configuration](#5-server-configuration)
6. [Security Hardening](#6-security-hardening)
7. [Troubleshooting & Tools](#7-troubleshooting--tools)
8. [Comparison Tables](#8-comparison-tables)
9. [Documentation Links](#9-documentation-links)

---

## 1. Installation & Configuration

### Important Paths / Важные пути

| File Path | Location | Purpose (EN / RU) |
|-----------|----------|-------------------|
| `~/.ssh/id_ed25519` | Client | **Private Key**. NEVER SHARE! / Приватный ключ. Не передавать! |
| `~/.ssh/id_ed25519.pub` | Client | **Public Key**. Distribute to servers. / Публичный ключ. На серверы. |
| `~/.ssh/authorized_keys` | Server | List of allowed Public Keys / Список разрешённых ключей |
| `~/.ssh/known_hosts` | Client | Fingerprints of trusted servers / Отпечатки серверов |
| `~/.ssh/config` | Client | Client-side connection shortcuts / Настройки подключений |
| `/etc/ssh/sshd_config` | Server | Server daemon configuration / Конфигурация демона сервера |

---

## 2. Key Generation

### Modern Standard (ED25519) / Современный стандарт

Recommended for all modern systems (OpenSSH 6.5+). Faster and more secure. / Рекомендуется для всех современных систем.

```bash
# Generate ED25519 key / Генерация ключа ED25519
ssh-keygen -t ed25519 -C "<USER_EMAIL>" -f ~/.ssh/id_ed25519

# With extra KDF rounds (better brute-force protection) / С дополнительными раундами KDF
ssh-keygen -t ed25519 -o -a 100 -C "<USER_EMAIL>"
```

### Legacy Compatibility (RSA 4096) / Наследие (RSA 4096)

Use only if connecting to very old legacy systems (Cisco routers, old CentOS 5/6). / Используйте только для подключения к старым системам.

```bash
# Generate RSA 4096 key / Генерация ключа RSA 4096
ssh-keygen -t rsa -b 4096 -C "<USER_EMAIL>"
```

---

## 3. Key Distribution

### Method 1: ssh-copy-id (Standard) / Стандартный метод

The safest and easiest way to install a public key. / Самый безопасный и простой способ установки ключа.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub <USER>@<HOST>  # Install key / Установить ключ
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p <PORT> <USER>@<HOST>  # Non-standard port / Нестандартный порт
```

### Method 2: Manual Install (One-liner) / Ручная установка

Use when `ssh-copy-id` is not available. / Когда `ssh-copy-id` недоступен.

```bash
cat ~/.ssh/id_ed25519.pub | ssh <USER>@<HOST> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Method 3: Bulk Distribution / Массовое распространение

```bash
# Distribute to hosts matching pattern / Перебор хостов по шаблону
grep '^Host ' ~/.ssh/config | awk '{for(i=2;i<=NF;i++) print $i}' | grep 'prod-*' | while read -r host; do
    echo "Deploying to $host..."
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "$host"
done
```

---

## 4. Client Configuration

`~/.ssh/config`

### Common Patterns / Частые шаблоны

```bash
# Global defaults / Глобальные настройки
Host *
    User sysadmin
    IdentityFile ~/.ssh/id_ed25519
    Compression yes
    ServerAliveInterval 60

# Specific Server / Конкретный сервер
Host prod-db
    HostName <IP_OR_DNS>
    User postgres
    Port 2222
    IdentityFile ~/.ssh/db_key

# Jump Host (Bastion) / Бастион
Host bastion
    HostName <BASTION_IP>

Host internal-app
    HostName 10.0.0.5
    ProxyJump bastion
```

---

## 5. Server Configuration

`/etc/ssh/sshd_config`

### Critical Settings / Критические настройки

```bash
# Allow Public Key Authentication / Разрешить вход по ключам
PubkeyAuthentication yes

# Location of authorized keys / Расположение файла авторизованных ключей
AuthorizedKeysFile .ssh/authorized_keys

# Disable Password Authentication (Hardening) / Отключить пароли (Усиление)
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
```

```bash
# Always reload SSH after changes / Всегда перезагружать SSH после изменений
systemctl reload sshd  # Apply config / Применить конфиг
```

---

## 6. Security Hardening

### File Permissions / Права доступа к файлам

> [!IMPORTANT]
> Incorrect permissions are the #1 reason SSH keys fail.
> Неверные права доступа — причина №1 неработающих SSH ключей.

```bash
# Client side / На клиенте
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config

# Server side / На сервере
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Restrict Key Capabilities / Ограничение возможностей ключа

In `~/.ssh/authorized_keys`:

```bash
# Key can only run backup script, no PTY, no forwarding
# Ключ запускает только скрипт бэкапа, без консоли
command="/usr/local/bin/backup.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3... user@email
```

### Disable Root Login / Отключение входа root

`/etc/ssh/sshd_config`

```bash
PermitRootLogin no
# OR allow root ONLY with keys (better) / ИЛИ разрешить root только по ключам
PermitRootLogin prohibit-password
```

> [!WARNING]
> Before disabling PasswordAuthentication or Root Login, ensure you have a working SSH key session active in another terminal. Do not close it until verified!
> Не закрывайте текущую сессию, пока не проверите вход по ключу!

---

## 7. Troubleshooting & Tools

### Diagnostics Workflow / Порядок диагностики

1. **Verbose Mode / Подробный режим:**
   ```bash
   ssh -v <USER>@<HOST>    # Info / Инфо
   ssh -vvv <USER>@<HOST>  # Debug (packet level) / Отладка
   ```

2. **Check Key Offering / Проверить предложение ключа:**
   ```bash
   ssh -v <HOST> 2>&1 | grep "Offering public key"
   ssh-add -l  # List loaded keys / Список загруженных ключей
   ```

3. **Check Server Logs / Проверить логи сервера:**
   ```bash
   tail -f /var/log/auth.log   # Debian/Ubuntu
   tail -f /var/log/secure     # RHEL/CentOS
   journalctl -u sshd -f       # Systemd universal
   ```

### Common Errors / Частые ошибки

- **"Permission denied (publickey)":**
    - Check `~/.ssh` directory permissions / Проверьте права директории `~/.ssh`
    - `AuthorizedKeysFile` path correct? / Путь к `AuthorizedKeysFile` верный?
    - SELinux blocking access? → `restorecon -Rv ~/.ssh`
- **"UNPROTECTED PRIVATE KEY FILE!":**
    - Fix permissions: `chmod 600 ~/.ssh/private_key`

---

## 8. Comparison Tables

### Key Algorithms / Алгоритмы ключей

| Algorithm | Security | Performance | Key Size | Recommendation |
|-----------|----------|-------------|----------|----------------|
| **ED25519** | Excellent | Fast | Small (68 chars) | **Default** |
| **RSA-4096** | Good | Slow | Large (544+ chars) | Legacy only |
| **RSA-2048** | Weakening | Medium | Medium | Avoid |
| **DSA** | **Unsafe** | Fast | Small | **Deprecated** |
| **ECDSA** | Good | Fast | Small | Good (NIST curves) |

> [!TIP]
> Always use ED25519 unless you specifically need RSA for legacy compatibility. ED25519 keys are shorter, faster, and more resistant to side-channel attacks.
> Всегда используйте ED25519, если не нужна RSA-совместимость. ED25519 ключи короче, быстрее и устойчивее к атакам по побочным каналам.

---

## 9. Documentation Links

- [OpenSSH Official Documentation](https://www.openssh.com/manual.html)
- [OpenSSH sshd_config Manual](https://man.openbsd.org/sshd_config)
- [OpenSSH ssh_config Manual](https://man.openbsd.org/ssh_config)
- [SSH Key Best Practices (Mozilla)](https://infosec.mozilla.org/guidelines/openssh)
- [SSH Hardening Guide (ssh-audit)](https://github.com/jtesta/ssh-audit)
- [GitHub SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---
