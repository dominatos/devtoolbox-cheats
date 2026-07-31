---
Title: 🗄️ rclone — Remotes/S3
Group: "Backups & S3"
Icon: 🗄️
Order: 2
tags:
  - backups
  - s3
  - sysadmin
  - linux
---

## Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Remote Management](#Remote%20Management)
- [File Operations](#File%20Operations)
- [Copy & Sync](#Copy%20&%20Sync)
- [Advanced Operations](#Advanced%20Operations)
- [S3-Specific](#S3-Specific)
- [Encryption](#Encryption)
- [Monitoring & Logging](#Monitoring%20&%20Logging)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Troubleshooting](#Troubleshooting)
- [Documentation](#Documentation)

---

## Installation & Configuration

### Install

```bash
# Debian/Ubuntu
apt install rclone                              # Install rclone / Установить

# RHEL/AlmaLinux/Rocky
dnf install rclone                              # Install rclone / Установить

# Official install script (always latest)
curl https://rclone.org/install.sh | sudo bash

rclone version                                  # Verify / Проверить версию
```

### Configure Remote

```bash
rclone config                                   # Interactive setup / Интерактивная настройка
rclone config show                              # Show current config / Показать конфигурацию
rclone config file                              # Show config file path / Путь к файлу
rclone listremotes                              # List configured remotes / Список remotes
```

---

## Remote Management

### Supported Providers (60+)

```bash
rclone config providers                         # List all providers / Список всех провайдеров
```

Key providers: Amazon S3, Google Drive, OneDrive, Dropbox, Azure Blob, Backblaze B2, MinIO, SFTP, WebDAV, GCS, and 50+ more.

### Create Remote Non-Interactively

```bash
# AWS S3
rclone config create s3remote s3 \
  provider=AWS \
  access_key_id=<ACCESS_KEY> \
  secret_access_key=<SECRET_KEY> \
  region=<REGION>                               # Create S3 remote / Создать S3 remote

# MinIO
rclone config create minio s3 \
  provider=Minio \
  access_key_id=<ACCESS_KEY> \
  secret_access_key=<SECRET_KEY> \
  endpoint=https://<MINIO_HOST>                 # Create MinIO remote / Создать MinIO remote
```

### Manage Remotes

```bash
rclone config delete <REMOTE>                   # Delete remote / Удалить remote
rclone config update <REMOTE> key=value         # Update remote / Обновить remote
```

---

## File Operations

### List

```bash
rclone ls remote:bucket/path                    # List objects with size / Список с размером
rclone lsd remote:bucket/                       # List directories only / Только директории
rclone lsl remote:bucket/path                   # List with size + time / Размер + время
rclone tree remote:bucket/path                  # Tree view / Древовидный вид
```

### Size & Statistics

```bash
rclone size remote:bucket/path                  # Total size / Общий размер
rclone ncdu remote:bucket/path                  # Interactive disk usage / Интерактивный просмотр
```

### Check & Compare

```bash
rclone check /local remote:bucket/path          # Compare files / Сравнить файлы
rclone md5sum remote:bucket/path                # MD5 checksums / MD5 суммы
rclone hashsum MD5 remote:bucket/path           # Hash checksums / Контрольные суммы
```

---

## Copy & Sync

### Copy vs Sync — Important Difference

| Command | Behavior / Поведение | Deletes destination extras? |
|---------|----------------------|----------------------------|
| `rclone copy` | Copies new/changed files only | **No** |
| `rclone sync` | Makes dest identical to source | **Yes** — removes extra files at dest |
| `rclone move` | Moves (deletes source after copy) | No (removes source) |

> [!WARNING]
> `rclone sync` **deletes files at destination** that are not present in source. Always test with `--dry-run` first.

```bash
rclone copy /data remote:bucket/path --progress  # Copy local → remote / Локальное → remote
rclone copy remote:bucket/path /restore --progress  # Copy remote → local / Remote → локальное
rclone sync /data remote:bucket/path --progress     # Sync (dest matches source) / Синхронизация
```

### Move & Delete

> [!CAUTION]
> `rclone purge` deletes the directory and all its contents immediately — no confirmation.

```bash
rclone move /data remote:bucket/path            # Move files / Переместить
rclone delete remote:bucket/path                # Delete files (recursive) / Удалить файлы
rclone purge remote:bucket/path                 # Delete dir + contents / Удалить директорию и содержимое
rclone cleanup remote:                          # Remove old versions / Очистить старые версии
```

### Dedupe

```bash
rclone dedupe remote:bucket/path                # Remove duplicate files / Удалить дубликаты
rclone dedupe --dedupe-mode newest remote:bucket/  # Keep newest / Сохранить новейшие
rclone dedupe --dedupe-mode largest remote:bucket/ # Keep largest / Сохранить самые большие
```

---

## Advanced Operations

### Mount as Filesystem

```bash
rclone mount remote:bucket/path /mnt/remote --daemon   # Mount / Монтировать
rclone mount remote:bucket /mnt --vfs-cache-mode writes  # With write cache / С кэшем записи
fusermount -u /mnt/remote                              # Unmount / Размонтировать
```

### Serve Protocols

```bash
rclone serve http remote:bucket --addr :8080    # Serve over HTTP / Раздача через HTTP
rclone serve webdav remote:bucket --addr :8080  # Serve WebDAV / WebDAV
rclone serve ftp remote:bucket --addr :2121     # Serve FTP / FTP
rclone serve restic remote:bucket --addr :8080  # Serve for restic REST / Для restic
```

### Filtering

```bash
rclone copy /data remote:bucket --include "*.jpg"     # Include pattern / Включить паттерн
rclone copy /data remote:bucket --exclude "*.tmp"     # Exclude pattern / Исключить паттерн
rclone copy /data remote:bucket --filter-from /etc/rclone/filter.txt  # Filter file / Файл фильтров
rclone copy /data remote:bucket --max-age 7d          # Only last 7 days / За последние 7 дней
```

### Bandwidth Control

```bash
rclone copy /data remote:bucket --bwlimit 10M   # Limit to 10 MB/s / Ограничить 10 МБ/с

# Schedule: 08:00–12:00 at 512k, 12:00–18:00 at 10M, etc.
rclone copy /data remote:bucket --bwlimit "08:00,512k 12:00,10M 18:00,30M 23:00,off"
```

---

## S3-Specific

### AWS S3 Config

`~/.config/rclone/rclone.conf`

```ini
[s3]
type = s3
provider = AWS
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
region = <REGION>
storage_class = STANDARD
```

### Storage Classes

```bash
rclone copy /data s3:bucket --s3-storage-class STANDARD       # Standard / Стандартный
rclone copy /data s3:bucket --s3-storage-class STANDARD_IA    # Infrequent Access / IA
rclone copy /data s3:bucket --s3-storage-class GLACIER        # Glacier archive / Архив
rclone copy /data s3:bucket --s3-storage-class DEEP_ARCHIVE   # Deep Archive / Глубокий архив
```

### MinIO / Custom S3 Endpoint

`~/.config/rclone/rclone.conf`

```ini
[minio]
type = s3
provider = Minio
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
endpoint = https://<MINIO_HOST>
```

### Server-Side Encryption

```bash
rclone copy /data s3:bucket --s3-server-side-encryption AES256   # S3 SSE-S3 / S3 шифрование
rclone copy /data s3:bucket --s3-sse-kms-key-id <KMS_KEY_ID>     # SSE-KMS / KMS шифрование
```

---

## Encryption

### Create Encrypted Remote

```bash
rclone config create crypt crypt \
  remote=s3:bucket/encrypted \
  filename_encryption=standard \
  directory_name_encryption=true \
  password=<PASSWORD> \
  password2=<PASSWORD2>                         # Create crypt remote / Создать зашифрованный remote
```

### Encryption Modes

| Mode | Effect |
|------|--------|
| `standard` | Encrypts filenames (irreversible obfuscation) |
| `obfuscate` | Obfuscates names (reversible, not secure) |
| `off` | No filename encryption, data still encrypted |

### Use Encrypted Remote

```bash
rclone copy /data crypt:                        # Copy to encrypted remote / Копировать в зашифрованный
rclone ls crypt:                                # List (shows decrypted names) / Список
rclone mount crypt: /mnt/encrypted --daemon     # Mount decrypted view / Монтировать расшифрованный вид
rclone cryptcheck /local crypt:                 # Verify encrypted checksums / Проверить контрольные суммы
```

---

## Monitoring & Logging

```bash
rclone copy /data remote:bucket --progress      # Live progress / Живой прогресс
rclone copy /data remote:bucket --stats 1s      # Stats every second / Статистика каждую секунду
rclone copy /data remote:bucket --stats-one-line  # Single-line stats / Одна строка

rclone copy /data remote:bucket -v              # Verbose / Подробный
rclone copy /data remote:bucket -vv             # Very verbose / Очень подробный
rclone copy /data remote:bucket \
  --log-file=/var/log/rclone.log \
  --log-level INFO                              # Log to file / Логирование в файл
```

### Remote Control (RC)

```bash
rclone rcd --rc-addr :5572                      # Start RC server / Запустить RC сервер
rclone rc core/stats                            # Get stats / Получить статистику
rclone rc core/bwlimit rate=1M                  # Change bandwidth live / Изменить полосу на лету
```

---

## Sysadmin Operations

### Systemd Service / Systemd-сервис

`/etc/systemd/system/rclone-sync.service`

```ini
[Unit]
Description=Rclone Sync to S3
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
Environment="RCLONE_CONFIG=/root/.config/rclone/rclone.conf"
ExecStart=/usr/bin/rclone sync /data s3:bucket/data \
  --log-file=/var/log/rclone-sync.log \
  --log-level INFO
StandardOutput=append:/var/log/rclone-sync.log
StandardError=append:/var/log/rclone-sync.log

[Install]
WantedBy=multi-user.target
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/rclone-sync.timer`

```ini
[Unit]
Description=Rclone Sync Timer
Requires=rclone-sync.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable rclone-sync.timer
systemctl start rclone-sync.timer
systemctl status rclone-sync.timer
```

### Configuration Paths

```bash
~/.config/rclone/rclone.conf      # User config / Конфиг пользователя
/root/.config/rclone/rclone.conf  # Root config / Конфиг root
```

### Environment Variables

```bash
export RCLONE_CONFIG=/path/to/rclone.conf       # Custom config file / Кастомный файл конфига
export RCLONE_CONFIG_PASS=<PASSWORD>            # Encrypted config password / Пароль зашифрованного конфига
```

### Logrotate / Logrotate

`/etc/logrotate.d/rclone`

```
/var/log/rclone*.log {
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

## Troubleshooting

### Common Errors

```bash
# "Failed to create file system" / "Не
rclone config show                              # Verify config / Проверить конфигурацию
rclone listremotes                              # Check remote exists / Проверить remote

# "403 Forbidden" (S3) / "403
# Check IAM permissions — need s3:GetObject, s3:PutObject, s3:ListBucket
```

### Retries & Timeouts

```bash
rclone copy /data remote:bucket --retries 10            # Retry failed ops / Повторить при ошибке
rclone copy /data remote:bucket --timeout 5m            # Operation timeout / Таймаут операции
rclone copy /data remote:bucket --contimeout 10s        # Connection timeout / Таймаут подключения
```

### Dry Run

```bash
rclone copy /data remote:bucket --dry-run       # Preview copy / Предварительный просмотр
rclone sync /data remote:bucket --dry-run -v    # Preview what would be deleted / Что будет удалено
```

### Debug

```bash
rclone copy /data remote:bucket -vv --dump headers  # HTTP headers / HTTP заголовки
rclone copy /data remote:bucket --dump bodies        # HTTP bodies / HTTP тела
```

### Performance Tuning

```bash
rclone copy /data remote:bucket --transfers 32  # Parallel transfers / Параллельные передачи
rclone copy /data remote:bucket --checkers 16   # Parallel checkers / Параллельные проверки
rclone copy /data remote:bucket --buffer-size 256M  # Buffer size / Размер буфера
```

## Documentation

- **Rclone Documentation:** https://rclone.org/docs/
- **Rclone Command Reference:** https://rclone.org/commands/
