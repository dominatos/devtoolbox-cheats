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

### Install / Установить

```bash
# Debian/Ubuntu
apt install borgbackup                          # Install borg / Установить borg

# RHEL/AlmaLinux/Rocky
dnf install borgbackup                          # Install borg / Установить borg

# From binary (static, no dependencies) / Из бинарника
wget https://github.com/borgbackup/borg/releases/download/1.2.6/borg-linux64
chmod +x borg-linux64
mv borg-linux64 /usr/local/bin/borg
borg --version                                  # Verify / Проверить
```

### Initialize Repository / Инициализировать репозиторий

```bash
borg init --encryption=repokey /backup          # Init with repokey (key stored in repo) / Ключ в репозитории
borg init --encryption=keyfile /backup          # Init with keyfile (key stored locally) / Ключ локально
borg init --encryption=none /backup             # Init without encryption (not recommended) / Без шифрования
```

### Encryption Mode Comparison / Сравнение режимов шифрования

| Mode | Key Location | Passphrase | Use Case |
|------|-------------|------------|----------|
| `repokey` | In repository | Required | Simple setup; repo must stay private |
| `keyfile` | `~/.config/borg/keys/` | Required | Key backup is separate from data |
| `authenticated` | In repository | Required | Integrity only, no confidentiality |
| `none` | — | Not used | Internal/trusted storage only |

> [!IMPORTANT]
> Always export and securely store the encryption key: `borg key export /backup backup.key`. Without the key, the repository is unrecoverable.

---

## Repository Management

```bash
borg info /backup                               # Repository info / Информация о репозитории
borg list /backup                               # List all archives / Список архивов
borg check /backup                              # Full integrity check / Полная проверка
borg check --repository-only /backup           # Quick check (no archive read) / Быстрая проверка
borg compact /backup                            # Reclaim space after delete/prune / Освободить место
```

### Key Management / Управление ключами

```bash
borg key export /backup backup.key              # Export key / Экспортировать ключ
borg key import /backup backup.key              # Import key / Импортировать ключ
borg key change-passphrase /backup              # Change passphrase / Изменить пароль
```

---

## Create Archives

### Basic Backup / Базовый бэкап

```bash
borg create /backup::archive-{now} /var/www     # Create archive / Создать архив
borg create /backup::daily-{now:%Y-%m-%d} /data # With date tag / С датой
borg create /backup::backup-{hostname}-{now} /data  # With hostname / С hostname
```

### Advanced Options / Расширенные опции

```bash
borg create /backup::archive-{now} /data \
  --exclude '*.tmp' \
  --exclude '*.log' \
  --exclude 'node_modules'                      # With excludes / С исключениями

borg create /backup::archive-{now} /data \
  --stats \
  --progress \
  --compression lz4                             # With stats and progress / Со статистикой и прогрессом
```

### Exclude from File / Исключения из файла

`/etc/borg/exclude.txt`

```
*.tmp
*.log
*.cache
node_modules/
.git/
```

```bash
borg create /backup::archive-{now} /home \
  --exclude-from /etc/borg/exclude.txt          # Exclude from file / Исключить из файла
```

---

## List & Info

```bash
borg list /backup                               # List archives / Список архивов
borg list /backup::archive-name                 # List archive contents / Содержимое архива
borg list /backup --short                       # Short list / Короткий список
borg list /backup --sort-by timestamp           # Sort by time / Сортировать по времени

borg info /backup::archive-name                 # Archive info / Информация об архиве
borg info /backup::archive-name --stats         # With statistics / Со статистикой

borg diff /backup::archive1 archive2            # Compare two archives / Сравнить архивы
```

---

## Extract & Restore

### Full Restore / Полное восстановление

```bash
cd /restore && borg extract /backup::archive-name   # Extract to current dir / Извлечь в текущую директорию
cd /restore && borg extract /backup::latest          # Extract latest archive / Последний архив
```

### Partial Restore / Частичное восстановление

```bash
borg extract /backup::archive-name /var/www     # Extract specific path / Конкретный путь
borg extract /backup::archive-name --dry-run    # Simulate extraction / Симуляция
borg extract /backup::archive-name --numeric-ids  # Preserve numeric UIDs / Числовые UID
```

---

## Pruning & Retention

### Prune Archives / Удалить архивы

```bash
borg prune /backup --keep-daily=7               # Keep 7 daily / Сохранить 7 дневных
borg prune /backup --keep-weekly=4              # Keep 4 weekly / Сохранить 4 недельных
borg prune /backup --keep-monthly=12            # Keep 12 monthly / Сохранить 12 месячных
```

### Combined Retention Policy / Комбинированная политика

```bash
borg prune /backup --dry-run --list --stats \
  --keep-daily=7 \
  --keep-weekly=4 \
  --keep-monthly=6 \
  --keep-yearly=2                               # Preview policy first / Предпросмотр политики
```

> [!WARNING]
> Always use `--dry-run` to preview what will be deleted before running `prune` for real.

### Delete Archive / Удалить архив

> [!CAUTION]
> `borg delete /backup` without `::archive-name` deletes the **entire repository**.

```bash
borg delete /backup::archive-name              # Delete specific archive / Удалить конкретный архив
borg compact /backup                            # Reclaim freed space / Освободить место после удаления
```

---

## Compression & Encryption

### Compression Comparison / Сравнение компрессии

| Method | Speed | Ratio | Best For |
|--------|-------|-------|----------|
| `none` | Fastest | None | Already-compressed data |
| `lz4` | Fast | Low | Real-time / frequent backups |
| `zstd` | Balanced | Medium | General purpose (recommended) |
| `zstd,10` | Slow | High | Slow networks, tight storage |
| `lzma,6` | Slowest | Highest | Cold archival |

```bash
borg create /backup::archive-{now} /data --compression none      # No compression / Без сжатия
borg create /backup::archive-{now} /data --compression lz4       # Fast / Быстрое
borg create /backup::archive-{now} /data --compression zstd      # Balanced / Сбалансированное
borg create /backup::archive-{now} /data --compression zstd,10   # High / Высокое сжатие
borg create /backup::archive-{now} /data --compression lzma,6    # Max / Максимальное
```

---

## Remote Repositories

### SSH / SSH

```bash
borg init --encryption=repokey ssh://<USER>@<HOST>/backup
borg create ssh://<USER>@<HOST>/backup::archive-{now} /data

# Using environment variable / Через переменную окружения
export BORG_REPO=ssh://<USER>@<HOST>/backup
borg create ::archive-{now} /data
```

### S3 (via rclone mount) / S3 через монтирование rclone

```bash
rclone mount s3:bucket /mnt/s3-borg --daemon   # Mount S3 first / Сначала смонтировать S3
borg init --encryption=repokey /mnt/s3-borg/backup
borg create /mnt/s3-borg/backup::archive-{now} /data
```

---

## Mount Archives

```bash
mkdir -p /mnt/borg
borg mount /backup /mnt/borg                    # Mount all archives / Монтировать все архивы
borg mount /backup::archive-name /mnt/borg      # Mount specific archive / Конкретный архив
ls /mnt/borg/archive-name/var/www/              # Browse files / Просматривать файлы
borg umount /mnt/borg                           # Unmount / Размонтировать
```

---

## Performance & Deduplication

```bash
borg info /backup                               # Show dedupe stats / Статистика дедупликации
borg info /backup::archive-name --stats         # Archive-specific stats / Статистика архива

borg create /backup::archive-{now} /data \
  --checkpoint-interval 600                     # Checkpoint every 10 min / Контрольная точка 10 мин

borg create /backup::archive-{now} /data \
  --chunker-params 19,23,21,4095                # Custom chunking (for many small files) / Кастомное разбиение
```

---

## Sysadmin Operations

### Environment Variables / Переменные окружения

```bash
export BORG_REPO=/backup                        # Default repo / Репозиторий по умолчанию
export BORG_PASSPHRASE=<PASSWORD>               # Passphrase / Пароль (avoid on multiuser systems)
export BORG_PASSCOMMAND="cat /root/.borg-passphrase"  # Read from file / Из файла (safer)
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes     # Allow relocated repo / Перемещённый репозиторий
```

### Configuration Paths / Пути конфигурации

```bash
~/.config/borg/keys/       # Key storage (keyfile mode) / Хранилище ключей
~/.cache/borg/             # Cache directory / Директория кэша
/var/log/borg/             # Recommended log directory / Рекомендуемая директория логов
```

### Systemd Service / Systemd-сервис

`/etc/systemd/system/borg-backup.service`

```ini
[Unit]
Description=Borg Backup
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
Environment="BORG_REPO=/backup"
Environment="BORG_PASSCOMMAND=cat /root/.borg-passphrase"
ExecStart=/usr/bin/borg create \
  --stats --compression lz4 \
  ::daily-{now:%%Y-%%m-%%d} /var/www /etc
ExecStartPost=/usr/bin/borg prune \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=6
ExecStartPost=/usr/bin/borg compact
StandardOutput=append:/var/log/borg/backup.log
StandardError=append:/var/log/borg/backup.log

[Install]
WantedBy=multi-user.target
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/borg-backup.timer`

```ini
[Unit]
Description=Borg Backup Timer
Requires=borg-backup.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
```

```bash
mkdir -p /var/log/borg
systemctl daemon-reload                         # Reload systemd / Перезагрузить systemd
systemctl enable borg-backup.timer              # Enable timer / Включить таймер
systemctl start borg-backup.timer              # Start timer / Запустить таймер
systemctl status borg-backup.timer             # Check status / Проверить статус
```

### Logrotate / Logrotate

`/etc/logrotate.d/borg`

```
/var/log/borg/*.log {
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
# "Failed to create/acquire the lock" / "Не удалось получить блокировку"
borg break-lock /backup                         # Remove stale lock / Удалить блокировку

# "Repository was relocated" / "Репозиторий был перемещён"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
borg list /backup
```

### Repair Operations / Операции восстановления

```bash
borg check /backup                              # Check integrity / Проверить целостность
borg check --repair /backup                     # Repair (use only when check fails) / Восстановить
borg compact /backup                            # Compact after repair / Упаковать после восстановления
```

### Verbose Output & Debug / Подробный вывод

```bash
borg create /backup::archive-{now} /data -v     # Verbose / Подробный вывод
borg create /backup::archive-{now} /data --debug  # Debug / Отладка
borg create /backup::archive-{now} /data --list    # List all processed files / Список файлов
```

### Performance Tips / Советы по производительности

```bash
borg create /backup::archive-{now} /data \
  --one-file-system                             # Don't cross filesystem boundaries / Не пересекать ФС

borg create /backup::archive-{now} /data \
  --read-special                                # Include special files (sockets, etc.) / Специальные файлы
```
