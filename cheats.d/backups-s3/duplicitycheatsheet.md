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

### Install

# Debian/Ubuntu
apt install duplicity python3-boto3             # Install duplicity + S3 / Установить duplicity + S3

# RHEL/AlmaLinux/Rocky
dnf install duplicity python3-boto3             # Install duplicity + S3 / Установить duplicity + S3

### Environment Variables

export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
export PASSPHRASE=<PASSWORD>                   # GPG passphrase / Пароль GPG

---

## GPG Key Setup

### Generate GPG Key

gpg --full-generate-key                        # Generate new key / Сгенерировать новый ключ
gpg --list-keys                                # List keys / Список ключей
gpg --list-secret-keys                         # List secret keys / Список секретных ключей

### Export/Import Keys

gpg --export <KEY_ID> > publickey.gpg          # Export public key / Экспортировать публичный ключ
gpg --export-secret-keys <KEY_ID> > secretkey.gpg # Export secret key / Экспортировать секретный ключ
gpg --import publickey.gpg                     # Import key / Импортировать ключ

---

## Backup Operations

### Full Backup

duplicity /data file:///backup                 # Local backup / Локальный бэкап
duplicity /data s3://s3.amazonaws.com/<BUCKET> # S3 backup / S3 бэкап
duplicity /data sftp://<USER>@<HOST>/backup    # SFTP backup / SFTP бэкап

### Incremental Backup

duplicity incr /data file:///backup            # Incremental / Инкрементальный
duplicity /data file:///backup                 # Auto inc/full / Автоматический

### Advanced Backup Options

duplicity /data file:///backup \
  --exclude /data/tmp \
  --exclude /data/*.log                        # With excludes / С исключениями

duplicity /data file:///backup \
  --include /data/important \
  --exclude /data/**                           # Include pattern / Паттерн включения

duplicity /data file:///backup \
  --full-if-older-than 7D                      # Full backup after 7 days / Полный бэкап после 7 дней

duplicity /data file:///backup \
  --volsize 100                                # 100MB volumes / Тома по 100МБ

---

## Restore Operations

### Full Restore

duplicity restore file:///backup /restore      # Restore latest / Восстановить последний
duplicity restore s3://s3.amazonaws.com/<BUCKET> /restore # From S3 / Из S3

### Partial Restore

duplicity restore --file-to-restore var/www file:///backup /restore # Restore specific file / Восстановить конкретный файл
duplicity restore --file-to-restore var/www file:///backup /restore/www # To different location / В другое место

### Time-Based Restore

duplicity restore --time 3D file:///backup /restore # Restore from 3 days ago / Восстановить 3 дня назад
duplicity restore --time 2023-12-01 file:///backup /restore # Restore from date / Восстановить с даты

---

## Collection Management

### Collection Status

duplicity collection-status file:///backup     # Show backups / Показать бэкапы
duplicity collection-status s3://s3.amazonaws.com/<BUCKET> # S3 collection / S3 коллекция

### List Files

duplicity list-current-files file:///backup    # List files in latest / Список файлов в последнем
duplicity list-current-files --time 7D file:///backup # Files from 7 days ago / Файлы 7 дней назад

### Verify

duplicity verify file:///backup /data          # Verify backup / Проверить бэкап
duplicity verify --compare-data file:///backup /data # Deep verify / Глубокая проверка

---

## Retention & Cleanup

### Remove Old Backups

duplicity remove-older-than 30D file:///backup # Remove older than 30 days / Удалить старше 30 дней
duplicity remove-older-than 6M file:///backup  # Remove older than 6 months / Удалить старше 6 месяцев

### Remove All But N Full

duplicity remove-all-but-n-full 3 file:///backup # Keep 3 full backups / Сохранить 3 полных бэкапа

### Remove Incremental Backups

duplicity remove-all-inc-of-but-n-full 2 file:///backup # Remove inc except last 2 full / Удалить инк кроме последних 2 полных

### Cleanup

duplicity cleanup file:///backup               # Cleanup orphaned files / Очистить потерянные файлы
duplicity cleanup --force file:///backup       # Force cleanup / Принудительная очистка

---

## Backend URLs

### Local File

file:///backup                                 # Local directory / Локальная директория

### AWS S3

s3://s3.amazonaws.com/<BUCKET>                 # AWS S3 / AWS S3
s3://s3.amazonaws.com/<BUCKET>/prefix          # With prefix / С префиксом

### Other S3-Compatible

s3://s3.<REGION>.amazonaws.com/<BUCKET>        # Specific region / Конкретный регион
s3+http://<MINIO_HOST>/<BUCKET>                # MinIO HTTP / MinIO HTTP

### SFTP

sftp://<USER>@<HOST>/backup                    # SFTP / SFTP
sftp://<USER>@<HOST>:2222/backup               # Custom port / Кастомный порт

### FTP/FTPS

ftp://<USER>@<HOST>/backup                     # FTP / FTP
ftps://<USER>@<HOST>/backup                    # FTP over SSL / FTP через SSL

### WebDAV

webdav://<USER>@<HOST>/backup                  # WebDAV / WebDAV
webdavs://<USER>@<HOST>/backup                 # WebDAV over HTTPS / WebDAV через HTTPS

### Google Drive

gdocs://<USER>@gmail.com/backup                # Google Drive / Google Drive

### Dropbox

dpbx:///backup                                 # Dropbox / Dropbox

---

## Performance & Encryption

### Encryption

duplicity /data file:///backup \
  --encrypt-key <KEY_ID>                       # Encrypt with GPG key / Шифровать GPG ключом

duplicity /data file:///backup \
  --sign-key <KEY_ID>                          # Sign with GPG key / Подписать GPG ключом

### No Encryption (Not Recommended)

duplicity /data file:///backup --no-encryption # No encryption / Без шифрования

### Compression

duplicity /data file:///backup --compression   # Enable compression (default) / Включить сжатие
duplicity /data file:///backup --no-compression # Disable compression / Отключить сжатие

### Volume Size

duplicity /data file:///backup --volsize 200   # 200MB volumes / Тома по 200МБ
duplicity /data file:///backup --volsize 1024  # 1GB volumes / Тома по 1ГБ

### Bandwidth Limiting

duplicity /data file:///backup --asynchronous-upload # Async upload / Асинхронная загрузка

---

## Sysadmin Operations

### Systemd Service

#### /etc/systemd/system/duplicity-backup.service

[Unit]
Description=Duplicity Backup
After=network.target

[Service]
Type=oneshot
Environment="AWS_ACCESS_KEY_ID=<ACCESS_KEY>"
Environment="AWS_SECRET_ACCESS_KEY=<SECRET_KEY>"
Environment="PASSPHRASE=<PASSWORD>"
ExecStart=/usr/bin/duplicity --full-if-older-than 7D /data s3://s3.amazonaws.com/<BUCKET>
ExecStart=/usr/bin/duplicity remove-older-than 30D --force s3://s3.amazonaws.com/<BUCKET>
ExecStart=/usr/bin/duplicity cleanup --force s3://s3.amazonaws.com/<BUCKET>

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/duplicity-backup.timer

[Unit]
Description=Duplicity Backup Timer
Requires=duplicity-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

#### Enable

systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable duplicity-backup.timer        # Enable timer / Включить таймер
systemctl start duplicity-backup.timer         # Start timer / Запустить таймер

### Environment Variables

export PASSPHRASE=<PASSWORD>                   # GPG passphrase / Пароль GPG
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>          # AWS access key / AWS ключ доступа
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>      # AWS secret key / AWS секретный ключ
export FTP_PASSWORD=<PASSWORD>                 # FTP password / FTP пароль

### Cache Location

~/.cache/duplicity/                            # Cache directory / Директория кэша

---

## Troubleshooting

### Common Errors

# "GPG error" / "Ошибка GPG"
gpg --list-keys                                # Verify key exists / Проверить существование ключа
export PASSPHRASE=<PASSWORD>                   # Set passphrase / Установить пароль

# "Orphaned signature" / "Потерянная подпись"
duplicity cleanup --force file:///backup       # Cleanup orphans / Очистить потерянные файлы

# "No such file or directory" in backup / "Нет такого файла" в бэкапе  
duplicity collection-status file:///backup     # Check collection / Проверить коллекцию
duplicity verify file:///backup /data          # Verify integrity / Проверить целостность

### Repair Operations

duplicity cleanup file:///backup               # Remove orphaned files / Удалить потерянные файлы
duplicity cleanup --force file:///backup       # Force cleanup / Принудительная очистка

### Verbose Output

duplicity -v5 /data file:///backup             # Info level / Уровень info
duplicity -v8 /data file:///backup             # Debug level / Уровень debug
duplicity -v9 /data file:///backup             # Full debug / Полная отладка

### Dry Run

duplicity --dry-run /data file:///backup       # Simulate backup / Симуляция бэкапа
duplicity remove-older-than 30D --dry-run file:///backup # Simulate removal / Симуляция удаления
