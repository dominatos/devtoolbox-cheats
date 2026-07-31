Title: 🗄️ tar + GPG — Classic Encrypted Backups
Group: Backups & S3
Icon: 🗄️
Order: 5

## Table of Contents
- [tar Basics](#tar%20Basics)
- [GPG Encryption](#GPG%20Encryption)
- [Combined tar + GPG](#Combined%20tar%20+%20GPG)
- [Compression Options](#Compression%20Options)
- [Incremental Backups](#Incremental%20Backups)
- [Split Archives](#Split%20Archives)
- [Remote Backups](#Remote%20Backups)
- [Sysadmin Patterns](#Sysadmin%20Patterns)
- [Troubleshooting](#Troubleshooting)

---

## tar Basics

### Create Archive / Создать архив

```bash
tar -cvf backup.tar /data                       # Create plain archive / Создать архив
tar -czf backup.tar.gz /data                    # Create with gzip / С gzip
tar -cjf backup.tar.bz2 /data                   # Create with bzip2 / С bzip2
tar -cJf backup.tar.xz /data                    # Create with xz / С xz
```

### Extract Archive / Извлечь архив

```bash
tar -xvf backup.tar                             # Extract plain / Извлечь
tar -xzf backup.tar.gz                          # Extract gzip / Извлечь gzip
tar -xjf backup.tar.bz2                         # Extract bzip2 / Извлечь bzip2
tar -xJf backup.tar.xz                          # Extract xz / Извлечь xz
tar -xvf backup.tar -C /restore                 # Extract to directory / Извлечь в директорию
```

### List Contents / Список содержимого

```bash
tar -tvf backup.tar                             # List files / Список файлов
tar -tzf backup.tar.gz                          # List gzip archive / Список gzip архива
```

### Exclude Patterns / Исключения

```bash
tar -czf backup.tar.gz /data \
  --exclude='*.tmp' \
  --exclude='*.log' \
  --exclude='node_modules'                      # Exclude by pattern / Исключить по паттерну

tar -czf backup.tar.gz /data \
  --exclude-from=/etc/backup/exclude.txt        # Exclude from file / Исключить из файла
```

---

## GPG Encryption

### Symmetric Encryption (Passphrase-based) / Симметричное шифрование

```bash
gpg --symmetric --cipher-algo AES256 file.tar   # Encrypt with passphrase / Зашифровать паролем
gpg --decrypt file.tar.gpg > file.tar           # Decrypt / Расшифровать
```

### Public Key Encryption / Асимметричное шифрование

```bash
gpg --encrypt --recipient <USER> file.tar       # Encrypt for recipient / Зашифровать для получателя
gpg --decrypt file.tar.gpg > file.tar           # Decrypt / Расшифровать
```

### Sign Files / Подписать файлы

```bash
gpg --sign file.tar                             # Sign file / Подписать файл
gpg --verify file.tar.gpg                       # Verify signature / Проверить подпись
gpg --clearsign file.txt                        # Clear sign / Подпись в читаемом виде
```

---

## Combined tar + GPG

### Create Encrypted Backup / Создать зашифрованный бэкап

```bash
# Symmetric (passphrase) / Симметричный (пароль)
tar -czf - /data | gpg --symmetric --cipher-algo AES256 > backup.tar.gz.gpg

# Asymmetric (recipient key) / Асимметричный (ключ получателя)
tar -czf - /data | gpg --encrypt --recipient <USER> > backup.tar.gz.gpg

# With date in filename / С датой в имени файла
tar -czf - /data | gpg --symmetric --cipher-algo AES256 \
  -o "backup-$(date +%Y%m%d).tar.gz.gpg"
```

### Restore Encrypted Backup / Восстановить зашифрованный бэкап

```bash
gpg --decrypt backup.tar.gz.gpg | tar -xz -C /restore  # Decrypt + extract / Расшифровать + извлечь
```

---

## Compression Options

### Compression Comparison / Сравнение компрессоров

| Algorithm | Speed | Ratio | Best For |
|-----------|-------|-------|----------|
| `none` | Fastest | None | Already-compressed data |
| `gzip` (`-z`) | Fast | Medium | General purpose, wide support |
| `bzip2` (`-j`) | Slow | Good | Slightly better than gzip |
| `xz` (`-J`) | Slowest | Best | Archive storage, bandwidth saving |

```bash
# Default compression / Стандартное сжатие
tar -czf backup.tar.gz /data                    # gzip (default) / gzip (по умолчанию)
tar -cjf backup.tar.bz2 /data                   # bzip2 / bzip2
tar -cJf backup.tar.xz /data                    # xz / xz
tar -cf backup.tar /data                        # No compression / Без сжатия
```

### Maximum Compression / Максимальное сжатие

```bash
GZIP=-9 tar -czf backup.tar.gz /data            # Max gzip / Максимальный gzip
XZ_OPT=-9 tar -cJf backup.tar.xz /data          # Max xz / Максимальный xz
```

### Parallel Compression / Параллельное сжатие

```bash
tar -cf - /data | pigz > backup.tar.gz           # Parallel gzip (pigz) / Параллельный gzip
tar -cJf backup.tar.xz /data --use-compress-program="xz -T0"  # Parallel xz / Параллельный xz
```

---

## Incremental Backups

### Snapshot-Based Incremental / Инкрементальный на основе снапшотов

```bash
# First run = full backup / Первый запуск = полный бэкап
tar -czf full-backup.tar.gz -g /var/backups/snapshot.snar /data

# Subsequent runs = incremental / Последующие запуски = инкрементальный
tar -czf inc-backup.tar.gz -g /var/backups/snapshot.snar /data
```

### Listed Incremental / Перечисленный инкрементальный

```bash
tar --create --listed-incremental=/var/backups/snapshot.file \
  --file=backup.tar /data                       # Create incremental / Создать инкрементальный

tar --extract --listed-incremental=/var/backups/snapshot.file \
  --file=backup.tar                             # Restore incremental / Восстановить инкрементальный
```

---

## Split Archives

### Split Large Archives / Разбить большие архивы

```bash
# Split into 1 GB parts / Разбить на части по 1 ГБ
tar -czf - /data | split -b 1G - backup.tar.gz.part

# Restore split archive / Восстановить разбитый архив
cat backup.tar.gz.part* | tar -xz
```

### Split with GPG / Разбить с шифрованием

```bash
tar -czf - /data | gpg --symmetric --cipher-algo AES256 \
  | split -b 1G - backup.tar.gz.gpg.part        # Split encrypted / Разбить зашифрованный

cat backup.tar.gz.gpg.part* | gpg --decrypt | tar -xz  # Restore / Восстановить
```

---

## Remote Backups

### Backup via SSH / Бэкап через SSH

```bash
tar -czf - /data | ssh <USER>@<HOST> "cat > /backup/backup.tar.gz"  # Plain / Обычный

tar -czf - /data | ssh <USER>@<HOST> \
  "gpg --symmetric --cipher-algo AES256 > /backup/backup.tar.gz.gpg"  # Encrypted / Зашифрованный
```

### Restore from Remote / Восстановить с удалённого

```bash
ssh <USER>@<HOST> "cat /backup/backup.tar.gz" | tar -xz -C /restore

ssh <USER>@<HOST> "gpg --decrypt /backup/backup.tar.gz.gpg" | tar -xz -C /restore
```

---

## Sysadmin Patterns

### Daily Encrypted Backup Script / Ежедневный зашифрованный бэкап

`/usr/local/bin/daily-backup.sh`

```bash
#!/bin/bash
# Daily encrypted tar+GPG backup with 7-day retention
# / Ежедневный зашифрованный бэкап tar+GPG с хранением 7 дней

set -euo pipefail

DATE=$(date +%Y%m%d)
BACKUP_DIR=/backup
SOURCE=/data
PASSPHRASE_FILE=/root/.backup-passphrase
LOG=/var/log/tar-backup.log

echo "$(date): Starting backup of $SOURCE" >> "$LOG"

tar -czf - "$SOURCE" | gpg --symmetric --cipher-algo AES256 \
  --batch --passphrase-file "$PASSPHRASE_FILE" \
  -o "$BACKUP_DIR/backup-$DATE.tar.gz.gpg"

echo "$(date): Backup created: $BACKUP_DIR/backup-$DATE.tar.gz.gpg" >> "$LOG"

# Keep only last 7 days / Сохранить только последние 7 дней
find "$BACKUP_DIR" -name "backup-*.tar.gz.gpg" -mtime +7 -delete
echo "$(date): Old backups pruned." >> "$LOG"
```

```bash
chmod 700 /usr/local/bin/daily-backup.sh
echo "<STRONG_PASSPHRASE>" > /root/.backup-passphrase
chmod 600 /root/.backup-passphrase
```

### Weekly Full + Daily Incremental / Еженедельный полный + ежедневный инкрементальный

`/usr/local/bin/weekly-incremental-backup.sh`

```bash
#!/bin/bash
# Weekly full on Monday, incremental on other days
# / Полный бэкап в понедельник, инкрементальный в остальные дни

set -euo pipefail

DAY=$(date +%u)   # 1=Monday / 1=Понедельник
DATE=$(date +%Y%m%d)
SNAPSHOT=/var/backups/snapshot.snar
BACKUP_DIR=/backup

if [ "$DAY" -eq 1 ]; then
    rm -f "$SNAPSHOT"
    tar -czf - -g "$SNAPSHOT" /data \
      | gpg --symmetric --cipher-algo AES256 --batch \
        --passphrase-file /root/.backup-passphrase \
        -o "$BACKUP_DIR/full-$DATE.tar.gz.gpg"
    echo "$(date): Full backup created."
else
    tar -czf - -g "$SNAPSHOT" /data \
      | gpg --symmetric --cipher-algo AES256 --batch \
        --passphrase-file /root/.backup-passphrase \
        -o "$BACKUP_DIR/inc-$DATE.tar.gz.gpg"
    echo "$(date): Incremental backup created."
fi
```

### Systemd Service / Systemd-сервис

`/etc/systemd/system/tar-backup.service`

```ini
[Unit]
Description=tar + GPG Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/daily-backup.sh
StandardOutput=append:/var/log/tar-backup.log
StandardError=append:/var/log/tar-backup.log

[Install]
WantedBy=multi-user.target
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/tar-backup.timer`

```ini
[Unit]
Description=tar Backup Timer
Requires=tar-backup.service

[Timer]
OnCalendar=*-*-* 01:30:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable tar-backup.timer
systemctl start tar-backup.timer
```

### Logrotate / Logrotate

`/etc/logrotate.d/tar-backup`

```
/var/log/tar-backup.log {
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
# "Cannot stat: No such file or directory" / "Нет такого файла"
tar -czf backup.tar.gz /data --ignore-failed-read  # Ignore missing / Игнорировать отсутствующие

# "File changed as we read it" / "Файл изменился во время чтения"
tar -czf backup.tar.gz /data --warning=no-file-changed  # Suppress warning / Подавить предупреждение

# GPG decryption failed / Ошибка расшифровки GPG
gpg --list-keys                                 # Verify keys / Проверить ключи
gpg --list-secret-keys                          # Verify secret keys / Секретные ключи
```

### Verify Archive Integrity / Проверить целостность архива

```bash
tar -tzf backup.tar.gz > /dev/null && echo "OK"  # Test gzip archive / Тест gzip архива
gpg --decrypt backup.tar.gz.gpg | tar -tz > /dev/null && echo "OK"  # Test encrypted / Тест зашифрованного
```

### Extract Specific Files / Извлечь конкретные файлы

```bash
tar -xzf backup.tar.gz data/important/file.txt  # Single file / Один файл
tar -xzf backup.tar.gz data/important/          # Directory / Директория
```

### Performance / Производительность

```bash
tar -czf backup.tar.gz /data --use-compress-program=pigz  # Parallel gzip / Параллельный gzip
tar -cJf backup.tar.xz /data --use-compress-program="xz -T0"  # Parallel xz / Параллельный xz
```

## Documentation

- **tar Man Page:** https://man7.org/linux/man-pages/man1/tar.1.html
- **GnuPG Documentation:** https://gnupg.org/documentation/

#backups #s3 #sysadmin #linux
