Title: 🔑 SSH Keys & Access Management
Group: Security & Crypto
Icon: 🔑
Order: 30

# SSH Keys & Access Management

This cheatsheet covers the complete lifecycle of SSH keys: generation (ED25519/RSA), secure distribution, server-side configuration, security hardening, and advanced troubleshooting.

## Table of Contents
- [Key Generation](#key-generation-генерация-ключей)
- [Key Distribution](#key-distribution-распространение-ключей)
- [Client Configuration](#client-configuration-конфигурация-клиента)
- [Server Configuration](#server-configuration-конфигурация-сервера)
- [Security Hardening](#security-hardening-усиление-безопасности)
- [Troubleshooting](#troubleshooting-устранение-неполадок)
- [Comparison Tables](#comparison-tables-таблицы-сравнения)

---

## Key Generation / Генерация ключей

### Modern Standard (ED25519) / Современный стандарт
Recommended for all modern systems (OpenSSH 6.5+). Faster and more secure.

```bash
# Generate ED25519 key / Генерация ключа ED25519
ssh-keygen -t ed25519 -C "<USER_EMAIL>" -f ~/.ssh/id_ed25519

# -o : Use new OpenSSH format (better protection for private key) / Новый формат OpenSSH
ssh-keygen -t ed25519 -o -a 100 -C "<USER_EMAIL>"
```

### Legacy Compatibility (RSA 4096) / Наследие (RSA 4096)
Use only if connecting to very old legacy systems (Cisco routers, old CentOS 5/6).

```bash
# Generate RSA 4096 key / Генерация ключа RSA 4096
ssh-keygen -t rsa -b 4096 -C "<USER_EMAIL>"
```

---

## Key Distribution / Распространение ключей

### Method 1: ssh-copy-id (Standard) / Стандартный метод
The safest and easiest way to install a public key.

```bash
# Install specific key / Установить конкретный ключ
ssh-copy-id -i ~/.ssh/id_ed25519.pub <USER>@<HOST>

# Specify port if non-standard / Указать порт, если нестандартный
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p <PORT> <USER>@<HOST>
```

### Method 2: Manual Install (One-liner) / Ручная установка
Use when `ssh-copy-id` is not available.

```bash
cat ~/.ssh/id_ed25519.pub | ssh <USER>@<HOST> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Method 3: Bulk Distribution / Массовое распространение
Distribute keys to multiple servers defined in `~/.ssh/config`.

```bash
# Iterate over hosts matching a pattern / Перебор хостов по шаблону
grep '^Host ' ~/.ssh/config | awk '{for(i=2;i<=NF;i++) print $i}' | grep 'prod-*' | while read -r host; do
    echo "Deploying to $host..."
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "$host"
done
```

---

## Client Configuration / Конфигурация клиента
`~/.ssh/config`

### Common Patterns / Частые шаблоны

```bash
# ~/.ssh/config

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

## Server Configuration / Конфигурация сервера
`/etc/ssh/sshd_config`

### Critical Settings / Критические настройки
Always reload SSH after changes: `systemctl reload sshd`.

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

---

## Security Hardening / Усиление безопасности

### 1. File Permissions / Права доступа к файлам
Incorrect permissions are the #1 reason SSH keys fail.

```bash
# Client side permissions / Права на клиенте
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config

# Server side permissions / Права на сервере
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 2. Restrict Key Capabilities / Ограничение возможностей ключа
Restrict what a specific key can do in `~/.ssh/authorized_keys`.

```bash
# Example: Key can only run one backup script, no PTY, no port forwarding
# Пример: Ключ запускает только скрипт бэкапа, без консоли
command="/usr/local/bin/backup.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3... user@email
```

### 3. Disable Root Login / Отключение входа root
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
# OR allow root ONLY with keys (better) / ИЛИ разрешить root только по ключам
PermitRootLogin prohibit-password
```

> [!WARNING]
> Before disabling PasswordAuthentication or Root Login, ensure you have a working SSH key session active in another terminal. Do not close it until verified! / Не закрывайте текущую сессию, пока не проверите вход по ключу!

---

## Troubleshooting / Устранение неполадок

### Diagnostics Workflow / Порядок диагностики

1. **Verbose Mode**: The best tool.
   ```bash
   ssh -v <USER>@<HOST>    # Info / Инфо
   ssh -vvv <USER>@<HOST>  # Debug / Отладка (packet level)
   ```

2. **Check Key Offering**:
   ```bash
   ssh -v <HOST> 2>&1 | grep "Offering public key"
   # If key is not offered, check identities / Если ключ не предлагается, проверьте identities
   ssh-add -l
   ```

3. **Check Server Logs**:
   ```bash
   # On remote server / На удаленном сервере
   tail -f /var/log/auth.log   # Debian/Ubuntu
   tail -f /var/log/secure     # RHEL/CentOS
   journalctl -u sshd -f       # Systemd universal
   ```

### Common Errors / Частые ошибки

- **"Permission denied (publickey)"**: 
    - Server `mkdir` privileges?
    - `AuthorizedKeysFile` path correct?
    - SELinux blocking access? (`restorecon -Rv ~/.ssh`)
- **"UNPROTECTED PRIVATE KEY FILE!"**:
    - Fix permissions: `chmod 600 ~/.ssh/private_key`

---

## Comparison Tables / Таблицы сравнения

### Key Algorithms / Алгоритмы ключей

| Algorithm | Security | Performance | Key Size | Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| **ED25519** | Excellent | Fast | Small (68 chars) | **Default** |
| **RSA-4096** | Good | Slow | Large (544+ chars) | Legacy only |
| **RSA-2048** | Weakening | Medium | Medium | Avoid |
| **DSA** | **Unsafe** | Fast | Small | **Deprecated** |
| **ECDSA** | Good | Fast | Small | Good (NIST curves) |

### SSH Files Overview / Обзор файлов SSH

| File Path | Location | Purpose (EN / RU) |
| :--- | :--- | :--- |
| `~/.ssh/id_ed25519` | Client | **Private Key**. NEVER SHARE! / Приватный ключ. Не передавать! |
| `~/.ssh/id_ed25519.pub` | Client | **Public Key**. Distribute to servers. / Публичный ключ. На серверы. |
| `~/.ssh/authorized_keys` | Server | List of allowed Public Keys. / Список разрешенных ключей. |
| `~/.ssh/known_hosts` | Client | Fingerprints of trusted servers. / Отпечатки серверов. |
| `~/.ssh/config` | Client | Client-side connection shortcuts. / Настройки подключений клиента. |
| `/etc/ssh/sshd_config` | Server | Server daemon configuration. / Конфигурация демона сервера. |
