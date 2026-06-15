Title: 🗄️ SSH Chroot Backup
Group: Backups & S3
Icon: 🗄️
Order: 15

# Secure SSH Chroot Backup Server Configuration

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Client-Side Key Generation](#client-side-key-generation)
- [Server-Side Configuration](#server-side-configuration)
- [Verification & Path Mapping](#verification--path-mapping)
- [Integration with Rclone](#integration-with-rclone)
- [Documentation Links](#documentation-links)

---

**Description:**  
SSH (Secure Shell) chroot environment combined with SFTP provides a highly secure, restricted method for automated remote backups. By forcing a user into a "jail" (`chroot`) and disabling their shell access (`/usr/sbin/nologin`), the backup process can write data securely without allowing lateral movement across the file system if the private key is compromised. Currently, this remains an industry standard for secure, agentless data ingestion over SSH.

### Why Use a Chroot Backup User? / Зачем использовать Chroot для бэкап-пользователя?

When a client machine sends automated backups, it typically uses an SSH private key for passwordless authentication. If that client machine is compromised, the attacker steals the SSH key. Without a chroot jail, that stolen key grants full SSH shell access to your backup server, allowing the attacker to read system files, map your network, or destroy other data.
Когда клиентская машина отправляет автоматические бэкапы, она использует приватный SSH-ключ для входа без пароля. Если эта машина скомпрометирована, злоумышленник крадет SSH-ключ. Без chroot-окружения этот украденный ключ дает полный доступ к shell на вашем сервере бэкапов, позволяя злоумышленнику читать системные файлы, сканировать сеть или уничтожать другие данные.

By implementing a **chroot jail**:
Внедряя **chroot jail**:
1. **Isolation / Изоляция:** The attacker is locked inside `/var/sftp/<USER>`. They cannot see or access `/etc`, `/home`, or `/var` of the main server.
2. **No Command Execution / Запрет выполнения команд:** With shell access disabled (`/usr/sbin/nologin` + `ForceCommand internal-sftp`), the attacker cannot run bash scripts, binaries, or exploit local vulnerabilities. They are restricted purely to SFTP file transfer operations.

## Architecture Overview

* **Chroot Jail Root:** `/var/sftp/<USER>` (Owned by `root:root`, Perms: `755`)
* **Writable Backup Target:** `/var/sftp/<USER>/backups` (Owned by `<USER>:ssh-chroot`, Perms: `700`)
* **Shell Level:** Completely disabled (`/usr/sbin/nologin` + OpenSSH `ForceCommand`)
* **Authentication:** Dedicated Ed25519 Public Key Only

## Client-Side Key Generation

### Generate Automation Key / Создание ключа для автоматизации

*Run these commands on your local machine or production server that will **send** the backups. / Выполните на локальной машине или сервере, который будет отправлять бэкапы.*

```bash
# Generate a secure Ed25519 key pair with no passphrase for automation / Создать пару Ed25519 ключей без пароля для автоматизации
ssh-keygen -t ed25519 -f ~/.ssh/<KEY_NAME> -N ""

# Print the public key to copy it for the next part / Вывести публичный ключ для копирования
cat ~/.ssh/<KEY_NAME>.pub
```

## Server-Side Configuration

### 1. Create Users and Groups / Создание пользователей и групп

```bash
# Create a dedicated group for chrooted users / Создать группу для chroot-пользователей
sudo groupadd ssh-chroot

# Create the service account with no interactive shell access / Создать сервисный аккаунт без доступа к интерактивной оболочке
sudo useradd -m -g ssh-chroot -s /usr/sbin/nologin <USER>
```

### 2. Establish the Chroot Directory Structure / Создание структуры Chroot

OpenSSH enforces a strict security policy: **every directory in the chroot path must be owned by root and non-writable by any other user.** Therefore, we create a sub-folder inside the jail for actual file writing.
Политика OpenSSH требует: **все директории в пути chroot должны принадлежать root и не быть доступны для записи другим пользователям.**

> [!CAUTION]
> If the chroot root directory (`/var/sftp/<USER>`) is not owned by root, the SSH daemon will refuse the connection.

```bash
# Create the jail root and enforce strict root ownership / Создать корень chroot и назначить владельца root
sudo mkdir -p /var/sftp/<USER>
sudo chown root:root /var/sftp/<USER>
sudo chmod 755 /var/sftp/<USER>

# Create the actual writable backup payload directory inside the jail / Создать директорию для записи бэкапов внутри chroot
sudo mkdir /var/sftp/<USER>/backups
sudo chown <USER>:ssh-chroot /var/sftp/<USER>/backups
sudo chmod 700 /var/sftp/<USER>/backups
```

### 3. Deploy the SSH Public Key / Развертывание публичного SSH-ключа

`/home/<USER>/.ssh/authorized_keys`

```bash
# Create the hidden .ssh directory in the user's SYSTEM home directory / Создать скрытую директорию .ssh в домашней папке
sudo mkdir -p /home/<USER>/.ssh
sudo chmod 700 /home/<USER>/.ssh

# Authorize your client public key (Paste your key string inside this file) / Авторизовать публичный ключ (Вставьте строку ключа в этот файл)
sudo nano /home/<USER>/.ssh/authorized_keys
sudo chmod 600 /home/<USER>/.ssh/authorized_keys

# Fix ownership of the home infrastructure assets / Исправить права собственности на инфраструктуру домашней директории
sudo chown -R <USER>:ssh-chroot /home/<USER>/.ssh
sudo chown <USER>:ssh-chroot /home/<USER>
sudo chmod 750 /home/<USER>

# Note for Oracle Linux / RHEL nodes: Restore SELinux contexts / Для Oracle Linux / RHEL: Восстановить контексты SELinux
sudo restorecon -Rv /home/<USER>/.ssh
```

### 4. Reconfigure the OpenSSH Daemon / Настройка демона OpenSSH

`/etc/ssh/sshd_config`

Append this block at the **absolute bottom** of the file. / Добавьте этот блок в **самый конец** файла.

```sshdconfig
Match Group ssh-chroot
    ChrootDirectory /var/sftp/%u
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
    AllowAgentForwarding no
    PermitTTY no
```

```bash
# Test configurations for syntax errors / Проверить конфигурацию на синтаксические ошибки
sudo sshd -t

# Restart service if no syntax errors are returned / Перезапустить сервис, если нет ошибок
sudo systemctl restart sshd  # Restart SSH service / Перезапуск службы SSH
```

> [!WARNING]
> Always verify SSH configuration with `sshd -t` before restarting the service to prevent being locked out of the server.

## Verification & Path Mapping

### 1. Verification Commands / Команды проверки

*Run from Client Machine / Выполнить с клиентской машины*

```bash
# Test 1: Verify interactive terminal login is explicitly blocked / Проверка блокировки интерактивного терминала
ssh -i ~/.ssh/<KEY_NAME> <USER>@<HOST>
# Expected Output: "This service allows sftp connections only. Connection closed."

# Test 2: Connect via SFTP interactive console / Подключение через интерактивную консоль SFTP
sftp -i ~/.ssh/<KEY_NAME> <USER>@<HOST>
```

### 2. The Chroot Path Paradigm Shift / Изменение парадигмы путей Chroot

Because the user is jailed inside `/var/sftp/<USER>`, that path effectively becomes their real root (`/`). Standard system absolute paths like `/var` or `/home` do not exist to this user.
Поскольку пользователь заблокирован в `/var/sftp/<USER>`, этот путь фактически становится его настоящим корнем (`/`). Стандартные абсолютные пути системы не существуют для этого пользователя.

| True Path on VPS Storage | Path seen by Client Tool (rclone/sftp) | Permissions |
|---|---|---|
| `/var/sftp/<USER>/` | `/` | **Read-Only** |
| `/var/sftp/<USER>/backups/` | `/backups/` | **Read & Write** |

## Integration with Rclone

When setting up your `rclone.conf` profile for this host, ensure your paths reflect the jailed environment.

### Configuring SSH Key for Rclone / Настройка SSH-ключа для Rclone

**Why is this needed? / Зачем это нужно?**
Using an SSH key instead of a password provides stronger security and enables automated, non-interactive backups (especially since password authentication should be disabled on the server). Furthermore, if your private key is protected by a passphrase, Rclone requires it to decrypt the key during automated runs. We use the secure prompt method below to inject this passphrase into the Rclone config without ever exposing it in your `.bash_history` or system process lists.
Использование SSH-ключа вместо пароля обеспечивает более высокую безопасность и позволяет выполнять бэкапы автоматически (особенно если вход по паролю на сервере отключен). Если ваш приватный ключ защищен парольной фразой, Rclone должен знать её. Мы используем метод безопасного запроса ниже, чтобы передать пароль в конфигурацию Rclone, не оставляя следов в истории shell (`.bash_history`) или списке запущенных процессов.

To configure an existing rclone remote to use your SSH private key instead of a password:
Для настройки существующего remote в rclone на использование SSH-ключа вместо пароля:

#### 1. Set the SSH Private Key Path / Укажите путь к приватному ключу

Replace `<REMOTE_NAME>` with your remote name, and the path with your actual private key (NOT `.pub`).
Замените `<REMOTE_NAME>` на имя вашего remote, а путь — на фактический приватный ключ (НЕ `.pub`).

```bash
# Update rclone config with the key path / Обновить конфигурацию rclone с путем к ключу
sudo rclone --config /etc/rclone/rclone.conf config update <REMOTE_NAME> key_file ~/.ssh/<KEY_NAME>
```

#### 2. Store the Passphrase (If Applicable) / Сохраните парольную фразу (Если применимо)

If your SSH private key is protected by a passphrase, you must add it to the rclone configuration securely:
Если ваш приватный ключ защищен парольной фразой, безопасно добавьте ее в конфигурацию rclone:

```bash
# Securely prompt and save key passphrase without saving in history / Безопасно запросить и сохранить пароль ключа
read -rsp "SSH key passphrase: " PASS && \
sudo rclone --config /etc/rclone/rclone.conf config password <REMOTE_NAME> key_file_pass "$PASS" && \
unset PASS
```

### Target Command Syntax / Синтаксис команд

To make directories or sync payloads, strip out the server-side prefix paths:
Чтобы создать директории или синхронизировать данные, уберите префиксные пути сервера:

```bash
# CORRECT syntax (Targets /var/sftp/<USER>/backups/test_dir) / ПРАВИЛЬНЫЙ синтаксис
rclone --config /etc/rclone/rclone.conf mkdir <REMOTE_NAME>:/backups/test_dir

# WRONG syntax (Will fail with "Permission denied" trying to write to a root-owned /var folder) / НЕПРАВИЛЬНЫЙ синтаксис
rclone --config /etc/rclone/rclone.conf mkdir <REMOTE_NAME>:/var/sftp/<USER>/backups/test_dir
```

### Optimization: Automating Subdirectories / Оптимизация: Автоматизация поддиректорий

To keep your script arguments short, append `sub_dir` to your native remote configurations.
Чтобы сократить аргументы скрипта, добавьте `sub_dir` к вашей конфигурации remote.

`/etc/rclone/rclone.conf`
```ini
[<REMOTE_NAME>]
type = sftp
host = <HOST>
user = <USER>
key_file = ~/.ssh/<KEY_NAME>
sub_dir = backups
```

With `sub_dir = backups` declared, rclone drops you directly into your write-ready folder, shortening all automation commands to:

```bash
# Shortened automation command / Сокращенная команда для автоматизации
rclone --config /etc/rclone/rclone.conf mkdir <REMOTE_NAME>:test_dir
```

## Documentation Links

* [OpenSSH sshd_config Documentation](https://man.openbsd.org/sshd_config)
* [Rclone SFTP Configuration](https://rclone.org/sftp/)
