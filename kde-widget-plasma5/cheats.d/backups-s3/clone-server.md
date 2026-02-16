Title: 🗄️ Complete Server Clone & Backup Cheatsheet — Linux
Group: Backups & S3
Icon: 🗄️
Order: 7

# 🗄️ Complete Server Clone & Backup Cheatsheet — Linux

A professional, production-ready guide for server cloning, data migration, and backup management.

## 📋 Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Core Management (Tar & Backups)](#core-management-tar--backups)
- [Server Cloning (Piped Transfer)](#server-cloning-piped-transfer)
- [Database Management (MySQL/MariaDB)](#database-management-mysqlmariadb)
- [Automation & Scripts](#automation--scripts)
- [Advanced Operations (Multi-volume archives)](#advanced-operations-multi-volume-archives)
- [Comparison of Cloning Approaches](#comparison-of-cloning-approaches)
- [Sysadmin Operations](#sysadmin-operations)

---

## 🛠 Installation & Configuration

### Dependencies
Ensure `tar` and `ssh` are installed and up to date.
```bash
apt update && apt install tar openssh-client  # Debian/Ubuntu / Установка на Debian/Ubuntu
yum install tar openssh-clients               # RHEL/CentOS/AlmaLinux / Установка на RHEL/CentOS/AlmaLinux
```

### SSH Performance Tuning
For faster cloning over SSH, use lighter encryption or compression.
```bash
ssh -oCiphers=arcfour ...        # Fast but insecure / Быстро, но небезопасно
ssh -oCompression=no ...        # Disable compression for fast networks / Отключить сжатие для быстрых сетей
```

---

## 📦 Core Management (Tar & Backups)

### Basic Backup Commands
```bash
# Full system backup excluding system directories / Полный бэкап системы, исключая системные директории
tar -cvpzf backup-`date +%m-%d-%Y-%H%M`.tar.gz \
    --exclude=/backup.tar.gz \
    --exclude=/dev --exclude=/boot --exclude=/proc --exclude=/sys \
    --exclude=/mnt --exclude=/lost+found \
    --one-file-system /

# Backup specific directory (e.g., public_html) / Бэкап конкретной папки
tar -czvf backup-`date +%m-%d-%Y-%H%M`.tar.gz \
     --exclude={./public_html/templates/cache,./public_html/templates/compiled,./public_html/images} \
     ./public_html
```

### Unpacking & Restoring
```bash
tar -xvf backup.tar.gz                   # Extract archive / Распаковать архив
tar -C /dest -xvf backup.tar.gz          # Extract to specific directory / Распаковать в конкретную папку
```

---

## 🚀 Server Cloning (Piped Transfer)

> [!IMPORTANT]
> This method clones the filesystem directly across the network. Ensure the target server has identical or compatible hardware settings (especially for the bootloader).

### Clone Entire Server via SSH
```bash
# Execute on SOURCE server / Выполнить на ИСХОДНОМ сервере
cd /; \
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

### Cleanup After Cloning
```bash
# Remove temporary maildrop files / Удалить временные файлы почты
find /var/spool/postfix/maildrop/ -type f -exec rm {} \;
```

---

## 🗄 Database Management (MySQL/MariaDB)

### Secure Credential Management
> [!TIP]
> Never use `-p<PASSWORD>` in shell commands or scripts. Use `mysql_config_editor` or `.my.cnf`.

#### Using mysql_config_editor (Recommended)
```bash
# Create login profile / Создать профиль входа (запрашивает пароль интерактивно)
mysql_config_editor set --login-path=backup --host=localhost --user=root --password

# Use login path for dumps / Использовать профиль для дампов
mysqldump --login-path=backup --all-databases | gzip > all-databases.sql.gz
```

#### Using .my.cnf
Create a file `/root/.my.cnf` with:
```ini
[client]
user=<USER>
password=<PASSWORD>
```
`chmod 600 /root/.my.cnf`

### Backup & Restore
```bash
# Dump all databases / Дамп всех баз данных
mysqldump -u root -p --all-databases | gzip > /mysql-backup-`date +%F`.sql.gz

# Restore from SQL file / Восстановить из файла SQL
mysql -u root -p < file.sql

# Restore from compressed SQL / Восстановить из сжатого SQL
gunzip -cd mysql-backup.sql.gz | mysql -u root -p
```

---

## 🤖 Automation & Scripts

### Integrated Backup Script
This script combines database dumps and filesystem backups.

```bash
#!/bin/bash
# Description: Automated backup script for DB and files / Скрипт автоматического бэкапа БД и файлов

BACKUP_DIR="/backup"
mkdir -p $BACKUP_DIR
rm $BACKUP_DIR/*.zip $BACKUP_DIR/*.tar.gz 2>/dev/null

NOW=$(date +%d%m%Y-%H%M%S)
FILENAME="server-backup"
FULL_PATH="$BACKUP_DIR/$FILENAME-$NOW"

# Database dump using credentials / Дамп БД с использованием учетных данных
# NOTE: Use --login-path for better security / Используйте --login-path для лучшей безопасности
mysqldump --no-tablespaces -y -u <USER> -p<PASSWORD> -h <SOURCE_IP> <DB_NAME> > $FULL_PATH.sql

# Compress SQL dump / Сжать дамп SQL
zip -j $FULL_PATH.zip $FULL_PATH.sql
rm $FULL_PATH.sql

# Create system archive / Создать системный архив
tar -cvpzf $FULL_PATH.tar.gz \
    --exclude=/var/spool/postfix/maildrop/ \
    --exclude=/dev --exclude=/boot --exclude=/proc --exclude=/sys \
    --exclude=/mnt --exclude=/lost+found --exclude=/swap \
    --exclude=/var/lib/mysql/ --exclude=/etc/sysconfig/network-scripts/* \
    --exclude=$BACKUP_DIR/* \
    --one-file-system /

# Optional: Upload to remote server / Опционально: загрузить на удаленный сервер
# scp -P 22 $FULL_PATH.tar.gz backup_user@<HOST>:/path/to/backups/
```

---

## 🛠 Advanced Operations (Multi-volume archives)

### Using tarcat
Used to concatenate GNU tar multi-volume archives.

```bash
#!/bin/sh
# Usage: tarcat volume1 volume2 ...
# Author: Bruno Haible, Sergey Poznyakoff

dump_type() {
  dd if="$1" skip=${2:-0} bs=512 count=1 2>/dev/null | tr '\0' ' ' | cut -c157
}

case `dump_type "$1"` in
  [gx]) PAX=1;;
esac

cat "$1"
shift
for f; do
  SKIP=0
  T=`dump_type "$f"`
  if [ -n "$PAX" ]; then
    if [ "$T" = "g" ]; then
      SKIP=5
    fi
  else
    if [ "$T" = "V" ]; then T=`dump_type "$f" 1`; fi
    if [ "$T" = "M" ]; then SKIP=$(($SKIP + 1)); fi
  fi
  dd skip=$SKIP if="$f"
done
```
**Usage:** `tarcat archive-* | tar -xf -`

---

## ⚖️ Comparison of Cloning Approaches

| Method | Pros (Плюсы) | Cons (Минусы) |
| :--- | :--- | :--- |
| **Tar over SSH** | Fast, simple, preserves permissions exactly. | Manual cleanup of system files (fstab, network). No deduplication. |
| **Rsync** | Incremental sync, resume capability, bandwidth efficient. | Slightly slower initial sync than tar. Requires identical versions for best results. |
| **Restic / Borg** | Deduplication, encryption, snapshots history. | Requires client installation on both sides. More complex setup. |
| **Clonezilla / DD** | Bit-perfect clone (including bootloader). | Usually requires downtime (offline clone). Large image size (if not sparse). |

---

## 🛡 Sysadmin Operations

### Network & IP Updates
After cloning to a new server, you must update the IP addresses.
```bash
# Bulk replace IP in config files / Массовая замена IP в конфигурационных файлах
find ./etc/ -type f -exec sed -i 's/<SOURCE_IP>/<REMOTE_IP>/g' {} \;
```

### Path & Log Reference
- **Logs:** `/var/log/syslog` or `/var/log/messages` / Журналы системы
- **Backup Logs:** Check your cron job outputs or `/var/log/cron`.
- **Default Ports:** 
  - SSH: 22
  - MySQL/MariaDB: 3306

### Service Management
```bash
systemctl restart sshd    # Restart SSH / Перезапустить SSH
systemctl status mysql     # Check MySQL status / Проверить статус MySQL
```

---
> [!CAUTION]
> Always verify your backups! A backup is only as good as its last successful restoration.
