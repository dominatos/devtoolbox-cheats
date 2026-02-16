Title: 🗄️ BorgBackup — Deduplicating Backups
Group: Backups & S3
Icon: 🗄️
Order: 3

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Repository Management](#repository-management)
- [Create Archives](#create-archives)
- [List & Info](#list--info)
- [Extract & Restore](#extract--restore)
- [Pruning & Retention](#pruning--retention)
- [Compression & Encryption](#compression--encryption)
- [Remote Repositories](#remote-repositories)
- [Mount Archives](#mount-archives)
- [Performance & Deduplication](#performance--deduplication)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install

# Debian/Ubuntu
apt install borgbackup                         # Install borg / Установить borg

# RHEL/AlmaLinux/Rocky
dnf install borgbackup                         # Install borg / Установить borg

# From binary / Из бинарника
wget https://github.com/borgbackup/borg/releases/download/1.2.6/borg-linux64
chmod +x borg-linux64
mv borg-linux64 /usr/local/bin/borg

### Initialize Repository

borg init --encryption=repokey /backup         # Init with repokey encryption / Инициализация с repokey шифрованием
borg init --encryption=keyfile /backup         # Init with keyfile encryption / Инициализация с keyfile шифрованием
borg init --encryption=none /backup            # Init without encryption / Без шифрования

---

## Repository Management

borg info /backup                              # Repository info / Информация о репозитории
borg list /backup                              # List archives / Список архивов
borg check /backup                             # Check repository / Проверить репозиторий
borg check --repository-only /backup           # Quick check / Быстрая проверка
borg compact /backup                           # Free disk space / Освободить место на диске

### Key Management

borg key export /backup backup.key             # Export key / Экспортировать ключ
borg key import /backup backup.key             # Import key / Импортировать ключ
borg key change-passphrase /backup             # Change passphrase / Изменить пароль

---

## Create Archives

### Basic Backup

borg create /backup::archive-{now} /var/www    # Create archive / Создать архив
borg create /backup::daily-{now:%Y-%m-%d} /data # With date / С датой
borg create /backup::backup-{hostname}-{now} /data # With hostname / С hostname

### Advanced Options

borg create /backup::archive-{now} /data \
  --exclude '*.tmp' \
  --exclude '*.log' \
  --exclude 'node_modules'                     # With excludes / С исключениями

borg create /backup::archive-{now} /data \
  --stats \
  --progress \
  --compression lz4                            # With options / С опциями

### Exclude Patterns

borg create /backup::archive-{now} /home \
  --exclude-from exclude.txt                   # Exclude file / Файл исключений

# exclude.txt example:
*.tmp
*.log
*.cache
node_modules/
.git/

---

## List & Info

borg list /backup                              # List archives / Список архивов
borg list /backup::archive-name                # List archive contents / Содержимое архива
borg list /backup --short                      # Short list / Короткий список
borg list /backup --sort-by timestamp          # Sort by time / Сортировать по времени

borg info /backup::archive-name                # Archive info / Информация об архиве
borg info /backup::archive-name --stats        # With statistics / Со статистикой

borg diff /backup::archive1 archive2           # Compare archives / Сравнить архивы

---

## Extract & Restore

### Full Restore

borg extract /backup::archive-name             # Extract to current dir / Извлечь в текущую директорию
borg extract /backup::latest                   # Extract latest / Извлечь последний

### Partial Restore

borg extract /backup::archive-name /var/www    # Extract specific path / Извлечь конкретный путь
borg extract /backup::archive-name --dry-run   # Simulate extraction / Симуляция извлечения
borg extract /backup::archive-name --numeric-ids # Preserve numeric IDs / Сохранить числовые ID

---

## Pruning & Retention

### Prune Archives

borg prune /backup --keep-daily=7              # Keep 7 daily / Сохранить 7 дневных
borg prune /backup --keep-weekly=4             # Keep 4 weekly / Сохранить 4 недельных
borg prune /backup --keep-monthly=12           # Keep 12 monthly / Сохранить 12 месячных

### Combined Retention Policy

borg prune /backup \
  --keep-daily=7 \
  --keep-weekly=4 \
  --keep-monthly=6 \
  --keep-yearly=2                              # Full retention policy / Полная политика хранения

borg prune /backup --dry-run --list --stats    # Preview prune / Предпросмотр удаления

### Delete Archive

borg delete /backup::archive-name              # Delete specific archive / Удалить конкретный архив
borg delete /backup --stats                    # Delete repo (careful!) / Удалить репозиторий (осторожно!)

---

## Compression & Encryption

### Compression Levels

borg create /backup::archive-{now} /data --compression none # No compression / Без сжатия
borg create /backup::archive-{now} /data --compression lz4  # Fast (default) / Быстрое (по умолчанию)
borg create /backup::archive-{now} /data --compression zstd # Balanced / Сбалансированное
borg create /backup::archive-{now} /data --compression zstd,10 # High compression / Высокое сжатие
borg create /backup::archive-{now} /data --compression lzma,6  # Max compression / Максимальное сжатие

### Encryption Modes

# repokey — Key stored in repo / Ключ в репозитории
borg init --encryption=repokey /backup

# keyfile — Key stored locally (~/.config/borg/keys/) / Ключ локально
borg init --encryption=keyfile /backup

# authenticated — Authenticated only, no encryption / Только аутентификация, без шифрования
borg init --encryption=authenticated /backup

---

## Remote Repositories

### SSH

borg init --encryption=repokey ssh://<USER>@<HOST>/backup # SSH repo / SSH репозиторий
borg create ssh://<USER>@<HOST>/backup::archive-{now} /data # Backup over SSH / Бэкап через SSH

export BORG_REPO=ssh://<USER>@<HOST>/backup
borg create ::archive-{now} /data              # Use env var / Использовать переменную окружения

### S3 (via rclone)

# Setup rclone remote first / Сначала настроить rclone remote
rclone mount s3:bucket /mnt/s3-borg --daemon
borg init --encryption=repokey /mnt/s3-borg/backup

---

## Mount Archives

borg mount /backup /mnt/borg                   # Mount all archives / Монтировать все архивы
borg mount /backup::archive-name /mnt/borg     # Mount specific archive / Монтировать конкретный архив
borg umount /mnt/borg                          # Unmount / Размонтировать

# Browse as regular filesystem / Просмотр как обычная файловая система
ls /mnt/borg/
cd /mnt/borg/archive-name/var/www/

---

## Performance & Deduplication

### Deduplication Stats

borg info /backup                              # Show dedupe stats / Показать статистику дедупликации
borg info /backup::archive-name --stats        # Archive-specific stats / Статистика архива

### Performance Tuning

borg create /backup::archive-{now} /data \
  --checkpoint-interval 600                    # Checkpoint every 10min / Контрольная точка каждые 10мин

borg create /backup::archive-{now} /data \
  --chunker-params 19,23,21,4095               # Custom chunking / Кастомное разбиение

---

## Sysadmin Operations

### Systemd Timer

#### /etc/systemd/system/borg-backup.service

[Unit]
Description=Borg Backup
After=network.target

[Service]
Type=oneshot
Environment="BORG_REPO=/backup"
Environment="BORG_PASSPHRASE=<PASSWORD>"
ExecStart=/usr/bin/borg create --stats --compression lz4 ::daily-{now:%%Y-%%m-%%d} /var/www /etc
ExecStart=/usr/bin/borg prune --keep-daily=7 --keep-weekly=4 --keep-monthly=6
ExecStart=/usr/bin/borg compact

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/borg-backup.timer

[Unit]
Description=Borg Backup Timer
Requires=borg-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

#### Enable

systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable borg-backup.timer             # Enable timer / Включить таймер
systemctl start borg-backup.timer              # Start timer / Запустить таймер

### Environment Variables

export BORG_REPO=/backup                       # Default repo / Репозиторий по умолчанию
export BORG_PASSPHRASE=<PASSWORD>              # Passphrase / Пароль
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes    # Allow relocated repo / Разрешить перемещённый репозиторий

### Configuration Paths

~/.config/borg/keys/                           # Key storage (keyfile mode) / Хранилище ключей
~/.cache/borg/                                 # Cache directory / Директория кэша

---

## Troubleshooting

### Common Errors

# "Failed to create/acquire the lock" / "Не удалось создать/получить блокировку"
borg break-lock /backup                        # Remove stale lock / Удалить устаревшую блокировку

# "Repository was relocated" / "Репозиторий был перемещён"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
borg list /backup

### Repair Operations

borg check /backup                             # Check integrity / Проверить целостность
borg check --repair /backup                    # Repair repository / Восстановить репозиторий
borg compact /backup                           # Compact after repair / Упаковать после восстановления

### Verbose Output

borg create /backup::archive-{now} /data -v    # Verbose / Подробный вывод
borg create /backup::archive-{now} /data --debug # Debug / Отладка
borg create /backup::archive-{now} /data --list  # List processed files / Список обработанных файлов

### Performance Issues

borg create /backup::archive-{now} /data --one-file-system # Don't cross filesystems / Не пересекать файловые системы
borg create /backup::archive-{now} /data --read-special # Backup special files / Бэкап специальных файлов
