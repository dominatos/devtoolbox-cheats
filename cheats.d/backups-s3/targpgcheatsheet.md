Title: 🗄️ tar + GPG — Classic Encrypted Backups
Group: Backups & S3
Icon: 🗄️
Order: 5

## Table of Contents
- [tar Basics](#tar-basics)
- [GPG Encryption](#gpg-encryption)
- [Combined tar + GPG](#combined-tar--gpg)
- [Compression Options](#compression-options)
- [Incremental Backups](#incremental-backups)
- [Split Archives](#split-archives)
- [Remote Backups](#remote-backups)
- [Sysadmin Patterns](#sysadmin-patterns)
- [Troubleshooting](#troubleshooting)

---

## tar Basics

### Create Archive

tar -cvf backup.tar /data                      # Create archive / Создать архив
tar -czf backup.tar.gz /data                   # Create with gzip / Создать с gzip
tar -cjf backup.tar.bz2 /data                  # Create with bzip2 / Создать с bzip2
tar -cJf backup.tar.xz /data                   # Create with xz / Создать с xz

### Extract Archive

tar -xvf backup.tar                            # Extract / Извлечь
tar -xzf backup.tar.gz                         # Extract gzip / Извлечь gzip
tar -xjf backup.tar.bz2                        # Extract bzip2 / Извлечь bzip2
tar -xJf backup.tar.xz                         # Extract xz / Извлечь xz

tar -xvf backup.tar -C /restore                # Extract to directory / Извлечь в директорию

### List Contents

tar -tvf backup.tar                            # List files / Список файлов
tar -tzf backup.tar.gz                         # List gzip archive / Список gzip архива

### Exclude Patterns

tar -czf backup.tar.gz /data \
  --exclude='*.tmp' \
  --exclude='*.log' \
  --exclude='node_modules'                     # Exclude patterns / Паттерны исключения

tar -czf backup.tar.gz /data \
  --exclude-from=exclude.txt                   # Exclude from file / Исключить из файла

---

## GPG Encryption

### Symmetric Encryption

gpg --symmetric --cipher-algo AES256 file.tar  # Encrypt file / Зашифровать файл
gpg --decrypt file.tar.gpg > file.tar          # Decrypt file / Расшифровать файл

### Public Key Encryption

gpg --encrypt --recipient <USER> file.tar      # Encrypt for recipient / Зашифровать для получателя
gpg --decrypt file.tar.gpg > file.tar          # Decrypt / Расшифровать

### Sign Files

gpg --sign file.tar                            # Sign file / Подписать файл
gpg --verify file.tar.gpg                      # Verify signature / Проверить подпись
gpg --clearsign file.txt                       # Clear sign / Подпись в читаемом виде

---

## Combined tar + GPG

### Create Encrypted Backup

tar -czf - /data | gpg --symmetric --cipher-algo AES256 > backup.tar.gz.gpg # Encrypt backup / Зашифровать бэкап
tar -czf - /data | gpg --encrypt --recipient <USER> > backup.tar.gz.gpg # Encrypt for user / Зашифровать для пользователя

### Restore Encrypted Backup

gpg --decrypt backup.tar.gz.gpg | tar -xz -C /restore # Decrypt and extract / Расшифровать и извлечь

### One-Line Encrypted Backup

tar -czf - /data | gpg --symmetric --cipher-algo AES256 -o backup-$(date +%Y%m%d).tar.gz.gpg # With date / С датой

---

## Compression Options

### Compression Comparison

# gzip (fast, moderate compression) / gzip (быстро, среднее сжатие)
tar -czf backup.tar.gz /data

# bzip2 (slower, better compression) / bzip2 (медленнее, лучшее сжатие)
tar -cjf backup.tar.bz2 /data

# xz (slowest, best compression) / xz (самое медленное, лучшее сжатие)
tar -cJf backup.tar.xz /data

# No compression / Без сжатия
tar -cf backup.tar /data

### Compression Levels

tar -czf backup.tar.gz /data --gzip            # Default gzip / gzip по умолчанию
GZIP=-9 tar -czf backup.tar.gz /data           # Maximum gzip / Максимальный gzip
XZ_OPT=-9 tar -cJf backup.tar.xz /data         # Maximum xz / Максимальный xz

---

## Incremental Backups

### Snapshot-Based Incremental

tar -czf full-backup.tar.gz -g snapshot.snar /data # Full backup / Полный бэкап  
tar -czf inc-backup.tar.gz -g snapshot.snar /data  # Incremental / Инкрементальный

### Listed Incremental

tar --create --listed-incremental=snapshot.file --file=backup.tar /data # Create incremental / Создать инкрементальный
tar --extract --listed-incremental=snapshot.file --file=backup.tar      # Restore incremental / Восстановить инкрементальный

---

## Split Archives

### Split Large Archives

tar -czf - /data | split -b 1G - backup.tar.gz.part # Split into 1GB parts / Разбить на части по 1ГБ
cat backup.tar.gz.part* | tar -xz                   # Restore split archive / Восстановить разбитый архив

### Split with GPG

tar -czf - /data | gpg --symmetric --cipher-algo AES256 | split -b 1G - backup.tar.gz.gpg.part # Split encrypted / Разбить зашифрованный
cat backup.tar.gz.gpg.part* | gpg --decrypt | tar -xz # Restore encrypted split / Восстановить зашифрованный разбитый

---

## Remote Backups

### Backup to Remote via SSH

tar -czf - /data | ssh <USER>@<HOST> "cat > /backup/backup.tar.gz" # Backup via SSH / Бэкап через SSH
tar -czf - /data | ssh <USER>@<HOST> "gpg --symmetric --cipher-algo AES256 > /backup/backup.tar.gz.gpg" # Encrypted remote / Зашифрованный удалённый

### Restore from Remote

ssh <USER>@<HOST> "cat /backup/backup.tar.gz" | tar -xz -C /restore # Restore from SSH / Восстановить с SSH
ssh <USER>@<HOST> "cat /backup/backup.tar.gz.gpg | gpg --decrypt" | tar -xz -C /restore # Restore encrypted / Восстановить зашифрованный

---

## Sysadmin Patterns

### Daily Encrypted Backup Script

#!/bin/bash
# /usr/local/bin/daily-backup.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR=/backup
SOURCE=/data

# Create encrypted backup / Создать зашифрованный бэкап
tar -czf - $SOURCE | gpg --symmetric --cipher-algo AES256 \
  --passphrase-file /root/.backup-passphrase \
  -o $BACKUP_DIR/backup-$DATE.tar.gz.gpg

# Keep only last 7 days / Сохранить только последние 7 дней
find $BACKUP_DIR -name "backup-*.tar.gz.gpg" -mtime +7 -delete

### Weekly Full + Daily Incremental

#!/bin/bash
# Weekly full, daily incremental / Еженедельный полный, ежедневный инкрементальный

DAY=$(date +%u)  # 1=Monday, 7=Sunday
DATE=$(date +%Y%m%d)
SNAPSHOT=/var/backups/snapshot.snar

if [ "$DAY" -eq 1 ]; then
    # Monday: full backup / Понедельник: полный бэкап
    rm -f $SNAPSHOT
    tar -czf /backup/full-$DATE.tar.gz -g $SNAPSHOT /data | \
      gpg --symmetric --cipher-algo AES256 -o /backup/full-$DATE.tar.gz.gpg
else
    # Other days: incremental / Другие дни: инкрементальный
    tar -czf /backup/inc-$DATE.tar.gz -g $SNAPSHOT /data | \
      gpg --symmetric --cipher-algo AES256 -o /backup/inc-$DATE.tar.gz.gpg
fi

### Systemd Service

#### /etc/systemd/system/tar-backup.service

[Unit]
Description=tar + GPG Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/daily-backup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/tar-backup.timer

[Unit]
Description=tar Backup Timer
Requires=tar-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

---

## Troubleshooting

### Common Errors

# "Cannot stat: No such file or directory" / "Не могу получить stat: Нет такого файла"
tar -czf backup.tar.gz /data --ignore-failed-read # Ignore missing files / Игнорировать отсутствующие файлы

# "File changed as we read it" / "Файл изменился во время чтения"
tar -czf backup.tar.gz /data --warning=no-file-changed # Ignore warnings / Игнорировать предупреждения

# GPG decryption failed / Ошибка расшифровки GPG
gpg --list-keys                                # Verify keys / Проверить ключи
gpg --list-secret-keys                         # Verify secret keys / Проверить секретные ключи

### Verify Archive Integrity

tar -tzf backup.tar.gz > /dev/null && echo "OK" # Test gzip archive / Тестировать gzip архив
gpg --decrypt backup.tar.gz.gpg | tar -tz > /dev/null && echo "OK" # Test encrypted / Тестировать зашифрованный

### Extract Specific Files

tar -xzf backup.tar.gz data/important/file.txt # Extract specific file / Извлечь конкретный файл
tar -xzf backup.tar.gz data/important/         # Extract directory / Извлечь директорию

### Performance

tar -czf backup.tar.gz /data --use-compress-program=pigz # Parallel gzip / Параллельный gzip
tar -cJf backup.tar.xz /data --use-compress-program="xz -T0" # Parallel xz / Параллельный xz
