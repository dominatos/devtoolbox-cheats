Title: 🗄️ rclone — Remotes/S3
Group: Backups & S3
Icon: 🗄️
Order: 2

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Remote Management](#remote-management  )
- [File Operations](#file-operations)
- [Copy & Sync](#copy--sync)
- [Advanced Operations](#advanced-operations)
- [S3-Specific](#s3-specific)
- [Encryption](#encryption)
- [Monitoring & Logging](#monitoring--logging)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install

# Debian/Ubuntu
apt install rclone                             # Install rclone / Установить rclone

# RHEL/AlmaLinux/Rocky
dnf install rclone                             # Install rclone / Установить rclone

# Install script / Скрипт установки
curl https://rclone.org/install.sh | sudo bash

### Configure Remote

rclone config                                  # Interactive config / Интерактивная настройка
rclone config show                             # Show config / Показать конфигурацию
rclone config file                             # Show config file path / Путь к файлу конфигурации
rclone listremotes                             # List configured remotes / Список настроенных remotes

---

## Remote Management

### Providers

# Supported providers (60+): / Поддерживаемые провайдеры (60+):
# - Amazon S3
# - Google Drive
# - Google Cloud Storage
# - Dropbox
# - Microsoft OneDrive
# - Azure Blob Storage
# - Backblaze B2
# - MinIO
# - SFTP
# - WebDAV
# - And many more...

### Create Remote (Non-Interactive)

# AWS S3
rclone config create s3remote s3 \
  provider=AWS \
  access_key_id=<ACCESS_KEY> \
  secret_access_key=<SECRET_KEY> \
  region=us-east-1                             # Create S3 remote / Создать S3 remote

# MinIO
rclone config create minio s3 \
  provider=Minio \
  access_key_id=<ACCESS_KEY> \
  secret_access_key=<SECRET_KEY> \
  endpoint=https://<MINIO_HOST>                # Create MinIO remote / Создать MinIO remote

### Manage Remotes

rclone config delete <REMOTE>                  # Delete remote / Удалить remote
rclone config update <REMOTE> key=value        # Update remote / Обновить remote
rclone config providers                        # List providers / Список провайдеров

---

## File Operations

### List

rclone ls remote:bucket/path                   # List objects / Список объектов
rclone lsd remote:bucket/                      # List directories only / Только директории
rclone lsl remote:bucket/path                  # List with size/time / Список с размером/временем
rclone tree remote:bucket/path                 # Tree view / Древовидный вид

### Size & Statistics

rclone size remote:bucket/path                 # Total size / Общий размер
rclone ncdu remote:bucket/path                 # Interactive disk usage / Интерактивное использование диска

### Check & Compare

rclone check /local remote:bucket/path         # Check files match / Проверить совпадение файлов
rclone cryptcheck /local remote:bucket/ --crypted-remote crypt: # Check encrypted / Проверить зашифрованное
rclone md5sum remote:bucket/path               # MD5 checksums / MD5 контрольные суммы
rclone hashsum MD5 remote:bucket/path          # Hash checksums / Контрольные суммы хэшей

---

## Copy & Sync

### Copy vs Sync

rclone copy /data remote:bucket/path --progress # Copy local → remote / Копировать локальное → remote
rclone copy remote:bucket/path /restore --progress # Copy remote → local / Копировать remote → локальное
rclone sync /data remote:bucket/path --progress # Sync (make dest match source) / Синхронизация (сделать dest как source)

> **Warning**: `sync` делает dest  идентичным source, удаляя лишние файлы!

### Move & Delete

rclone move /data remote:bucket/path           # Move files / Переместить файлы
rclone delete remote:bucket/path               # Delete files / Удалить файлы
rclone purge remote:bucket/path                # Delete dir and contents / Удалить директорию и содержимое
rclone cleanup remote:                         # Cleanup old versions / Очистить старые версии

### Dedupe

rclone dedupe remote:bucket/path               # Remove duplicate files / Удалить дубликаты
rclone dedupe --dedupe-mode newest remote:bucket/ # Keep newest / Сохранить новейшие
rclone dedupe --dedupe-mode largest remote:bucket/ # Keep largest / Сохранить самые большие

---

## Advanced Operations

### Mount

rclone mount remote:bucket/path /mnt/remote --daemon # Mount as filesystem / Монтировать как файловую систему
rclone mount remote:bucket /mnt --vfs-cache-mode writes # With write cache / С кэшем записи
fusermount -u /mnt/remote                      # Unmount / Размонтировать

### Serve

rclone serve http remote:bucket --addr :8080   # Serve over HTTP / Раздача через HTTP
rclone serve webdav remote:bucket --addr :8080 # Serve WebDAV / Раздача WebDAV
rclone serve ftp remote:bucket --addr :2121    # Serve FTP / Раздача FTP
rclone serve restic remote:bucket --addr :8080 # Serve for restic / Раздача для restic

### Filtering

rclone copy /data remote:bucket --include "*.jpg" # Include pattern / Включить паттерн
rclone copy /data remote:bucket --exclude "*.tmp" # Exclude pattern / Исключить пат терн
rclone copy /data remote:bucket --filter-from filter.txt # Filter file / Файл фильтров
rclone copy /data remote:bucket --max-age 7d   # Only files modified in last 7 days / Только файлы за последние 7 дней

### Bandwidth Control

rclone copy /data remote:bucket --bwlimit 10M  # Limit to 10MB/s / Ограничить до 10МБ/с
rclone copy /data remote:bucket --bwlimit 08:00,512k 12:00,10M 13:00,512k 18:00,30M 23:00,off # Time-based / По времени

---

## S3-Specific

### AWS S3

# ~/.config/rclone/rclone.conf
[s3]
type = s3
provider = AWS
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
region = us-east-1
storage_class = STANDARD

### Storage Classes

rclone copy /data s3:bucket --s3-storage-class STANDARD # Standard / Стандартный
rclone copy /data s3:bucket --s3-storage-class STANDARD_IA # Infrequent Access / Нечастый доступ
rclone copy /data s3:bucket --s3-storage-class GLACIER  # Glacier / Glacier
rclone copy /data s3:bucket --s3-storage-class DEEP_ARCHIVE # Deep Archive / Глубокий архив

### Custom Endpoints (MinIO, etc.)

[minio]
type = s3
provider = Minio
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
endpoint = https://<MINIO_HOST>

### Server-Side Encryption

rclone copy /data s3:bucket --s3-server-side-encryption AES256 # S3 SSE / S3 SSE
rclone copy /data s3:bucket --s3-sse-kms-key-id <KEY_ID> # KMS encryption / KMS шифрование

---

## Encryption

### Create Encrypted Remote

rclone config create crypt crypt \
  remote=s3:bucket/encrypted \
  filename_encryption=standard \
  directory_name_encryption=true \
  password=<PASSWORD> \
  password2=<PASSWORD2>                        # Create crypt remote / Создать зашифрованный remote

### Use Encrypted Remote

rclone copy /data crypt:                       # Copy to encrypted / Копировать в зашифрованное
rclone ls crypt:                               # List encrypted / Список зашифрованного
rclone mount crypt: /mnt/encrypted --daemon    # Mount encrypted / Монтировать зашифрованное

### Encryption Modes

# standard — Encrypts file names / Шифрует имена файлов
# obfuscate — Obfuscates file names / Обфусцирует имена файлов  
# off — No filename encryption / Без шифрования имён

---

## Monitoring & Logging

### Progress & Stats

rclone copy /data remote:bucket --progress     # Show progress / Показать прогресс
rclone copy /data remote:bucket --stats 1s     # Stats every 1s / Статистика каждую 1с
rclone copy /data remote:bucket --stats-one-line # One line stats / Статистика в одну строку

### Logging

rclone copy /data remote:bucket -v             # Verbose / Подробный вывод
rclone copy /data remote:bucket -vv            # Very verbose / Очень подробный вывод
rclone copy /data remote:bucket --log-file=/var/log/rclone.log # Log to file / Логи в файл
rclone copy /data remote:bucket --log-level DEBUG # Debug level / Уровень отладки

### RC (Remote Control)

rclone rcd --rc-addr :5572                     # Start RC server / Запустить RC сервер
rclone rc core/stats                           # Get stats / Получить статистику
rclone rc core/bwlimit rate=1M                 # Change bandwidth / Изменить пропускную способность

---

## Sysadmin Operations

### Systemd Service for Sync

#### /etc/systemd/system/rclone-sync.service

[Unit]
Description=Rclone Sync to S3
After=network.target

[Service]
Type=oneshot
Environment="RCLONE_CONFIG=/root/.config/rclone/rclone.conf"
ExecStart=/usr/bin/rclone sync /data s3:bucket/data --log-file=/var/log/rclone-sync.log
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/rclone-sync.timer

[Unit]
Description=Rclone Sync Timer
Requires=rclone-sync.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

#### Enable Service

systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable rclone-sync.timer             # Enable timer / Включить таймер
systemctl start rclone-sync.timer              # Start timer / Запустить таймер
systemctl status rclone-sync.timer             # Check status / Проверить статус

### Configuration Paths

~/.config/rclone/rclone.conf                   # User config / Конфигурация пользователя
/root/.config/rclone/rclone.conf               # Root config / Конфигурация root

### Environment Variables

export RCLONE_CONFIG=/path/to/rclone.conf      # Custom config / Кастомная конфигурация
export RCLONE_CONFIG_PASS=<PASSWORD>           # Encrypted config password / Пароль зашифрованной конфигурации

---

## Troubleshooting

### Common Errors

# "Failed to create file system" / "Не удалось создать файловую систему"
rclone config show                             # Verify config / Проверить конфигурацию
rclone listremotes                             # Check remote exists / Проверить существование remote

# "403 Forbidden" (S3) / "403 Запрещено"
# Check IAM permissions / Проверьте права IAM
# Verify access keys / Проверьте ключи доступа

### Retries & Timeouts

rclone copy /data remote:bucket --retries 10   # Retry failed transfers / Повтор неудачных передач
rclone copy /data remote:bucket --timeout 5m   # Operation timeout / Таймаут операции
rclone copy /data remote:bucket --contimeout 10s # Connection timeout / Таймаут подключения

### Dry Run

rclone copy /data remote:bucket --dry-run      # Simulate operation / Симуляция операции
rclone sync /data remote:bucket --dry-run -v   # Check what would be deleted / Проверить что будет удалено

### Debug

rclone copy /data remote:bucket -vv --dump headers # Dump HTTP headers / Вывод HTTP заголовков
rclone copy /data remote:bucket --dump bodies  # Dump HTTP bodies / Вывод HTTP тел

### Performance

rclone copy /data remote:bucket --transfers 32 # Parallel transfers / Параллельные передачи
rclone copy /data remote:bucket --checkers 16  # Parallel checkers / Параллельные проверки
rclone copy /data remote:bucket --buffer-size 256M # Larger buffer / Больший буфер
