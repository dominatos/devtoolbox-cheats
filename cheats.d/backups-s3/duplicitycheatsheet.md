Title: 🗄️ Duplicity — Encrypted Incremental Backups
Group: Backups & S3
Icon: 🗄️
Order: 4

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [GPG Key Setup](#gpg-key-setup)
- [Backup Operations](#backup-operations)
- [Restore Operations](#restore-operations)
- [Collection Management](#collection-management)
- [Retention & Cleanup](#retention--cleanup)
- [Backend URLs](#backend-urls)
- [Performance & Encryption](#performance--encryption)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install / Установить

```bash
# Debian/Ubuntu
apt install duplicity python3-boto3             # Install duplicity + S3 backend / Установить

# RHEL/AlmaLinux/Rocky
dnf install duplicity python3-boto3             # Install duplicity + S3 backend / Установить

duplicity --version                             # Verify / Проверить
```

### Environment Variables / Переменные окружения

```bash
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>           # AWS access key / AWS ключ доступа
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>       # AWS secret key / AWS секретный ключ
export PASSPHRASE=<PASSWORD>                    # GPG passphrase / Пароль GPG
export FTP_PASSWORD=<PASSWORD>                  # FTP password (if using FTP) / FTP пароль
```

> [!TIP]
> Store sensitive env vars in a protected file sourced by your scripts, not exported globally in `.bashrc`.

---

## GPG Key Setup

### Generate GPG Key / Сгенерировать ключ GPG

```bash
gpg --full-generate-key                         # Generate new key / Сгенерировать новый ключ
gpg --list-keys                                 # List public keys / Список публичных ключей
gpg --list-secret-keys                          # List secret keys / Список секретных ключей
```

### Export/Import Keys / Экспорт/импорт ключей

```bash
gpg --export <KEY_ID> > publickey.gpg           # Export public key / Экспортировать публичный ключ
gpg --export-secret-keys <KEY_ID> > secretkey.gpg  # Export secret key / Экспортировать секретный ключ
gpg --import publickey.gpg                      # Import key / Импортировать ключ
```

> [!IMPORTANT]
> Back up both the public and secret GPG keys to a separate secure location. Without the secret key, all duplicity backups become unrecoverable.

---

## Backup Operations

### Full Backup / Полный бэкап

```bash
duplicity /data file:///backup                  # Local backup / Локальный бэкап
duplicity /data s3://s3.amazonaws.com/<BUCKET>  # S3 backup / Бэкап в S3
duplicity /data sftp://<USER>@<HOST>/backup     # SFTP backup / SFTP бэкап
```

### Incremental Backup / Инкрементальный бэкап

```bash
duplicity incr /data file:///backup             # Force incremental / Принудительно инкрементальный
duplicity /data file:///backup                  # Auto: inc if full exists / Авто: инкр. если есть полный
```

### Advanced Backup Options / Расширенные опции

```bash
duplicity /data file:///backup \
  --exclude /data/tmp \
  --exclude /data/*.log                         # With excludes / С исключениями

duplicity /data file:///backup \
  --include /data/important \
  --exclude /data/**                            # Include specific path / Только конкретный путь

duplicity /data file:///backup \
  --full-if-older-than 7D                       # Full backup if last full > 7 days / Полный если >7 дней

duplicity /data file:///backup \
  --volsize 100                                 # 100 MB volumes / Тома по 100 МБ
```

---

## Restore Operations

### Full Restore / Полное восстановление

```bash
duplicity restore file:///backup /restore       # Restore latest / Восстановить последний
duplicity restore s3://s3.amazonaws.com/<BUCKET> /restore  # From S3 / Из S3
```

### Partial Restore / Частичное восстановление

```bash
duplicity restore --file-to-restore var/www file:///backup /restore
duplicity restore --file-to-restore var/www file:///backup /restore/www  # To alt path / В другое место
```

### Time-Based Restore / Восстановление по времени

```bash
duplicity restore --time 3D file:///backup /restore           # 3 days ago / 3 дня назад
duplicity restore --time 2024-01-01 file:///backup /restore   # Specific date / Конкретная дата
```

---

## Collection Management

```bash
duplicity collection-status file:///backup      # Show backup chain / Цепочка бэкапов
duplicity collection-status s3://s3.amazonaws.com/<BUCKET>  # S3 collection / S3 коллекция

duplicity list-current-files file:///backup     # Files in latest / Файлы в последнем
duplicity list-current-files --time 7D file:///backup  # Files from 7 days ago / 7 дней назад

duplicity verify file:///backup /data           # Verify backup / Проверить бэкап
duplicity verify --compare-data file:///backup /data  # Deep verify / Глубокая проверка
```

---

## Retention & Cleanup

### Remove Old Backups / Удалить старые бэкапы

> [!WARNING]
> Always use `--dry-run` first to preview what will be removed.

```bash
duplicity remove-older-than 30D --dry-run file:///backup  # Preview / Предпросмотр
duplicity remove-older-than 30D file:///backup            # Remove older than 30 days / >30 дней
duplicity remove-older-than 6M file:///backup             # Remove older than 6 months / >6 месяцев
duplicity remove-all-but-n-full 3 file:///backup          # Keep last 3 full backups / 3 полных
duplicity remove-all-inc-of-but-n-full 2 file:///backup   # Remove inc except last 2 full / инкр. кроме 2 полных
```

### Cleanup Orphans / Очистка потерянных файлов

```bash
duplicity cleanup --dry-run file:///backup      # Preview cleanup / Предпросмотр очистки
duplicity cleanup file:///backup                # Cleanup orphaned files / Очистить
duplicity cleanup --force file:///backup        # Force cleanup / Принудительно
```

---

## Backend URLs

### URL Format Reference / Справка по форматам URL

| Backend | URL Format | Notes |
|---------|-----------|-------|
| Local | `file:///backup` | Absolute path |
| AWS S3 | `s3://s3.amazonaws.com/<BUCKET>` | Needs AWS credentials |
| S3 + region | `s3://s3.<REGION>.amazonaws.com/<BUCKET>` | Specific region |
| MinIO (HTTP) | `s3+http://<MINIO_HOST>/<BUCKET>` | S3-compatible |
| SFTP | `sftp://<USER>@<HOST>/backup` | Default port 22 |
| SFTP custom port | `sftp://<USER>@<HOST>:2222/backup` | Custom port |
| FTP | `ftp://<USER>@<HOST>/backup` | Insecure |
| FTPS | `ftps://<USER>@<HOST>/backup` | FTP over TLS |
| WebDAV | `webdav://<USER>@<HOST>/backup` | HTTP |
| WebDAV TLS | `webdavs://<USER>@<HOST>/backup` | HTTPS |
| Google Drive | `gdocs://<USER>@gmail.com/backup` | |
| Dropbox | `dpbx:///backup` | |

---

## Performance & Encryption

### Encryption / Шифрование

```bash
duplicity /data file:///backup \
  --encrypt-key <KEY_ID>                        # Encrypt with GPG key / Шифрование GPG ключом

duplicity /data file:///backup \
  --sign-key <KEY_ID>                           # Sign with GPG key / Подпись GPG ключом

duplicity /data file:///backup --no-encryption  # No encryption (not recommended / не рекомендуется)
```

### Compression / Сжатие

```bash
duplicity /data file:///backup --compression    # Enable compression (default) / Включить сжатие (по умолч.)
duplicity /data file:///backup --no-compression # Disable compression / Отключить сжатие
```

### Volume Size & Upload / Размер тома и загрузка

```bash
duplicity /data file:///backup --volsize 200    # 200 MB volume size / Размер тома 200 МБ
duplicity /data file:///backup --volsize 1024   # 1 GB volumes / 1 ГБ
duplicity /data file:///backup --asynchronous-upload  # Async uploads / Асинхронная загрузка
```

---

## Sysadmin Operations

### Systemd Service / Systemd-сервис

`/etc/systemd/system/duplicity-backup.service`

```ini
[Unit]
Description=Duplicity Backup
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
EnvironmentFile=/etc/duplicity/env
ExecStart=/usr/bin/duplicity \
  --full-if-older-than 7D \
  /data s3://s3.amazonaws.com/<BUCKET>
ExecStartPost=/usr/bin/duplicity \
  remove-older-than 30D --force \
  s3://s3.amazonaws.com/<BUCKET>
ExecStartPost=/usr/bin/duplicity \
  cleanup --force \
  s3://s3.amazonaws.com/<BUCKET>
StandardOutput=append:/var/log/duplicity/backup.log
StandardError=append:/var/log/duplicity/backup.log

[Install]
WantedBy=multi-user.target
```

`/etc/duplicity/env`

```bash
AWS_ACCESS_KEY_ID=<ACCESS_KEY>
AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
PASSPHRASE=<PASSWORD>
```

```bash
chmod 600 /etc/duplicity/env                    # Restrict permissions / Ограничить права
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/duplicity-backup.timer`

```ini
[Unit]
Description=Duplicity Backup Timer
Requires=duplicity-backup.service

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
```

```bash
mkdir -p /var/log/duplicity
systemctl daemon-reload
systemctl enable duplicity-backup.timer
systemctl start duplicity-backup.timer
systemctl status duplicity-backup.timer
```

### Cache Location / Директория кэша

```bash
~/.cache/duplicity/        # Default cache / Кэш по умолчанию
```

### Logrotate / Logrotate

`/etc/logrotate.d/duplicity`

```
/var/log/duplicity/*.log {
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

### Common Errors / Распространённые ошибки

```bash
# "GPG error" / "Ошибка GPG"
gpg --list-keys                                 # Verify key exists / Проверить ключ
gpg --list-secret-keys                          # Verify secret key / Секретный ключ
export PASSPHRASE=<PASSWORD>                    # Set passphrase / Установить пароль

# "Orphaned signature" / "Потерянная подпись"
duplicity cleanup --force file:///backup        # Remove orphaned files / Удалить потерянные

# "No such file or directory" in backup
duplicity collection-status file:///backup      # Check collection / Проверить коллекцию
duplicity verify file:///backup /data           # Verify integrity / Проверить целостность
```

### Verbose Output / Подробный вывод

```bash
duplicity -v5 /data file:///backup             # Info level / Уровень info
duplicity -v8 /data file:///backup             # Debug level / Уровень debug
duplicity -v9 /data file:///backup             # Full debug / Полная отладка
```

### Dry Run / Пробный запуск

```bash
duplicity --dry-run /data file:///backup        # Simulate backup / Симуляция бэкапа
duplicity remove-older-than 30D --dry-run file:///backup  # Simulate removal / Симуляция удаления
```
