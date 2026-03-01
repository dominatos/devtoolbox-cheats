Title: 🗄️ Complete Server Clone & Backup — Linux
Group: Backups & S3
Icon: 🗄️
Order: 7

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Core Management (Tar & Backups)](#core-management-tar--backups)
- [Server Cloning (Piped Transfer)](#server-cloning-piped-transfer)
- [Database Management (MySQL/MariaDB)](#database-management-mysqlmariadb)
- [Automation & Scripts](#automation--scripts)
- [Advanced Operations (Multi-volume)](#advanced-operations-multi-volume)
- [Comparison of Cloning Approaches](#comparison-of-cloning-approaches)
- [Sysadmin Operations](#sysadmin-operations)

---

## Installation & Configuration

### Dependencies / Зависимости

```bash
# Debian/Ubuntu
apt update && apt install tar openssh-client   # Install tar + SSH / Установка tar + SSH

# RHEL/CentOS/AlmaLinux
yum install tar openssh-clients                # Install tar + SSH / Установка tar + SSH
```

### SSH Performance Tuning / Настройка производительности SSH

```bash
# Lighter cipher for fast networks (less secure — use only in trusted LAN)
# / Более лёгкий шифр для быстрых сетей (менее безопасно — только в доверенной LAN)
ssh -oCiphers=aes128-ctr <USER>@<HOST>

# Disable SSH compression (faster on fast networks) / Отключить сжатие SSH (быстрее на быстрых сетях)
ssh -oCompression=no <USER>@<HOST>
```

---

## Core Management (Tar & Backups)

### Basic Backup Commands / Основные команды бэкапа

```bash
# Full system backup excluding virtual/system directories
# / Полный бэкап системы, исключая виртуальные/системные директории
tar -cvpzf "backup-$(date +%m-%d-%Y-%H%M).tar.gz" \
    --exclude=/backup.tar.gz \
    --exclude=/dev --exclude=/boot --exclude=/proc --exclude=/sys \
    --exclude=/mnt --exclude=/lost+found \
    --one-file-system /

# Backup specific directory (e.g., web root) / Бэкап конкретной директории
tar -czvf "backup-$(date +%m-%d-%Y-%H%M).tar.gz" \
    --exclude={./public_html/templates/cache,./public_html/templates/compiled,./public_html/images} \
    ./public_html
```

### Unpacking & Restoring / Распаковка и восстановление

```bash
tar -xvf backup.tar.gz                          # Extract archive / Распаковать архив
tar -C /dest -xvf backup.tar.gz                 # Extract to specific directory / В конкретную папку
```

---

## Server Cloning (Piped Transfer)

> [!IMPORTANT]
> This method clones the filesystem directly across the network over SSH. Ensure the target server has identical or compatible hardware (especially for the bootloader). Run from the **source** server only.

### Clone Entire Server via SSH / Клонировать сервер через SSH

> [!CAUTION]
> This overwrites everything on the target server. Always verify `<REMOTE_IP>` before running. There is no undo.

```bash
# Execute on SOURCE server / Выполнить на ИСХОДНОМ сервере
cd / && \
tar cvpzf - \
  --exclude=/dev \
  --exclude=/boot \
  --exclude=/etc/fstab \
  --exclude=/etc/mtab \
  --exclude=/etc/blkid \
  --exclude=/etc/modprobe.conf \
  --exclude=/proc \
  --exclude=/mnt \
  --exclude=/sys \
  --exclude=/lost+found \
  --exclude=/etc/sysconfig/network-scripts/* \
  --ignore-failed-read \
  / | ssh -T root@<REMOTE_IP> 'tar -C / -xvpz'
```

### Cleanup After Cloning / Очистка после клонирования

```bash
# Remove temporary maildrop files / Удалить временные файлы почты
find /var/spool/postfix/maildrop/ -type f -exec rm {} \;
```

---

## Database Management (MySQL/MariaDB)

### Secure Credential Management / Безопасное управление учётными данными

> [!TIP]
> Never use `-p<PASSWORD>` directly in shell commands or scripts — it appears in process listings and shell history. Use `mysql_config_editor` or `.my.cnf` instead.

#### Using mysql_config_editor (Recommended / Рекомендуется)

```bash
# Create login profile (password prompted interactively) / Создать профиль (пароль запрашивается)
mysql_config_editor set --login-path=backup --host=localhost --user=root --password

# Use login path for dumps / Использовать профиль для дампов
mysqldump --login-path=backup --all-databases | gzip > all-databases.sql.gz
```

#### Using .my.cnf / Использование .my.cnf

`/root/.my.cnf`

```ini
[client]
user=<USER>
password=<PASSWORD>
```

```bash
chmod 600 /root/.my.cnf                         # Restrict permissions / Ограничить права
```

### Backup & Restore / Бэкап и восстановление

```bash
# Dump all databases / Дамп всех баз данных
mysqldump -u root -p --all-databases | gzip > "/mysql-backup-$(date +%F).sql.gz"

# Restore from SQL file / Восстановить из SQL файла
mysql -u root -p < file.sql

# Restore from compressed SQL / Из сжатого SQL
gunzip -cd mysql-backup.sql.gz | mysql -u root -p
```

---

## Automation & Scripts

### Integrated Backup Script / Интегрированный скрипт бэкапа

`/usr/local/bin/server-backup.sh`

```bash
#!/bin/bash
# Automated backup script: DB dump + filesystem archive
# / Автоматический бэкап: дамп БД + архив файловой системы

set -euo pipefail

BACKUP_DIR="/backup"
mkdir -p "$BACKUP_DIR"
rm -f "$BACKUP_DIR"/*.zip "$BACKUP_DIR"/*.tar.gz 2>/dev/null || true

NOW=$(date +%d%m%Y-%H%M%S)
FILENAME="server-backup"
FULL_PATH="$BACKUP_DIR/$FILENAME-$NOW"

# Database dump / Дамп базы данных
# NOTE: Use --login-path for production / Используйте --login-path в продакшне
mysqldump --no-tablespaces -y -u <USER> -p<PASSWORD> -h <SOURCE_IP> <DB_NAME> > "$FULL_PATH.sql"

# Compress SQL dump / Сжать дамп SQL
zip -j "$FULL_PATH.zip" "$FULL_PATH.sql"
rm "$FULL_PATH.sql"

# Create system archive / Системный архив
tar -cvpzf "$FULL_PATH.tar.gz" \
    --exclude=/var/spool/postfix/maildrop/ \
    --exclude=/dev --exclude=/boot \
    --exclude=/proc --exclude=/sys \
    --exclude=/mnt --exclude=/lost+found \
    --exclude=/swap \
    --exclude=/var/lib/mysql/ \
    --exclude=/etc/sysconfig/network-scripts/* \
    --exclude="$BACKUP_DIR"/* \
    --one-file-system /

# Optional: Upload to remote server / Опционально: отправить на удалённый сервер
# scp -P 22 "$FULL_PATH.tar.gz" backup_user@<HOST>:/path/to/backups/
echo "$(date): Backup complete: $FULL_PATH"
```

```bash
chmod +x /usr/local/bin/server-backup.sh
```

### Cron Schedule / Расписание cron

`/etc/cron.d/server-backup`

```
# Full server backup daily at 01:00 / Полный бэкап сервера ежедневно в 01:00
0 1 * * * root /usr/local/bin/server-backup.sh >> /var/log/server-backup.log 2>&1
```

### Logrotate / Logrotate

`/etc/logrotate.d/server-backup`

```
/var/log/server-backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Advanced Operations (Multi-volume)

### Using tarcat / Использование tarcat

Used to concatenate GNU tar multi-volume archives / Объединение многотомных архивов GNU tar.

`/usr/local/bin/tarcat`

```bash
#!/bin/sh
# Usage: tarcat volume1 volume2 ... | tar -xf -
# Author: Bruno Haible, Sergey Poznyakoff

dump_type() {
  dd if="$1" skip=${2:-0} bs=512 count=1 2>/dev/null | tr '\0' ' ' | cut -c157
}

case $(dump_type "$1") in
  [gx]) PAX=1;;
esac

cat "$1"
shift
for f; do
  SKIP=0
  T=$(dump_type "$f")
  if [ -n "$PAX" ]; then
    if [ "$T" = "g" ]; then
      SKIP=5
    fi
  else
    if [ "$T" = "V" ]; then T=$(dump_type "$f" 1); fi
    if [ "$T" = "M" ]; then SKIP=$((SKIP + 1)); fi
  fi
  dd skip=$SKIP if="$f"
done
```

```bash
chmod +x /usr/local/bin/tarcat
# Usage / Использование:
tarcat archive-* | tar -xf -
```

---

## Comparison of Cloning Approaches

| Method | Pros / Плюсы | Cons / Минусы |
|--------|-------------|---------------|
| **Tar over SSH** | Fast, simple, preserves permissions exactly | Manual cleanup of system files (fstab, network). No deduplication |
| **Rsync** | Incremental sync, resume capability, bandwidth efficient | Slightly slower initial sync than tar |
| **Restic / Borg** | Deduplication, encryption, snapshot history | Requires client installation, more complex setup |
| **Clonezilla / DD** | Bit-perfect clone including bootloader | Usually requires downtime; large image if not sparse |

---

## Sysadmin Operations

### Network & IP Updates After Cloning / Обновление IP после клонирования

```bash
# Bulk replace old IP in config files / Массовая замена старого IP в конфигурационных файлах
find /etc/ -type f -exec sed -i 's/<SOURCE_IP>/<REMOTE_IP>/g' {} \;
```

### Path & Log Reference / Справка по путям и логам

```bash
/var/log/syslog           # System log (Debian/Ubuntu) / Системный лог
/var/log/messages         # System log (RHEL) / Системный лог
/var/log/cron             # Cron job log / Лог задач cron
/var/log/server-backup.log  # Script log (if configured) / Лог скрипта
```

### Default Ports / Порты по умолчанию

```bash
# SSH: 22
# MySQL/MariaDB: 3306
```

### Service Management / Управление сервисами

```bash
systemctl restart sshd                          # Restart SSH / Перезапустить SSH
systemctl status mysql                          # Check MySQL status / Проверить MySQL
```

> [!CAUTION]
> Always verify your backups are restorable! Run a test restore to a staging server regularly. A backup is only as good as its last verified restoration.
