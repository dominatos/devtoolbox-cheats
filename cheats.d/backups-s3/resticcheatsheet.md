Title: 🗄️ restic — Backups
Group: Backups & S3
Icon: 🗄️
Order: 1

## Table of Contents
- [Installation & Configuration](#installation-configuration)
- [Repository Management](#repository-management)
- [Backup Operations](#backup-operations)
- [Snapshot Management](#snapshot-management)
- [Restore Operations](#restore-operations)
- [Pruning & Retention](#pruning-retention)
- [S3/Cloud Integration](#s3cloud-integration)
- [Performance & Security](#performance-security)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install / Установить

```bash
# Debian/Ubuntu
apt install restic                              # Install restic / Установить restic

# RHEL / AlmaLinux / Rocky Linux
dnf install restic                              # Install restic / Установить restic

# From binary (Linux amd64) / Из бинарника
wget https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2
bunzip2 restic_0.16.0_linux_amd64.bz2
chmod +x restic_0.16.0_linux_amd64
mv restic_0.16.0_linux_amd64 /usr/local/bin/restic  # Move to PATH / Переместить в PATH

restic version                                  # Verify install / Проверить установку
restic self-update                              # Self-update binary / Самообновление
```

### Repository Types / Типы репозиториев

| Backend | URI Format | Notes |
|---------|-----------|-------|
| Local | `/backup` | Local filesystem |
| SFTP | `sftp:<USER>@<HOST>:/backup` | Remote via SSH |
| REST Server | `rest:https://<HOST>:8000/` | restic REST server |
| AWS S3 | `s3:s3.amazonaws.com/<BUCKET>` | AWS credentials required |
| MinIO | `s3:https://<MINIO_HOST>/<BUCKET>` | S3-compatible |
| Backblaze B2 | `b2:<BUCKET>:/` | B2 credentials required |
| Azure Blob | `azure:<CONTAINER>:/` | Azure credentials required |
| Google Cloud | `gs:<BUCKET>:/` | GCS credentials required |

```bash
restic -r /backup init                          # Local repository / Локальный репозиторий
restic -r sftp:<USER>@<HOST>:/backup init       # SFTP repository / SFTP репозиторий
restic -r s3:s3.amazonaws.com/<BUCKET> init     # AWS S3 / AWS S3
restic -r rest:https://<HOST>:8000/ init        # REST server / REST сервер
```

### Environment Variables / Переменные окружения

`~/.bashrc` or `/etc/environment`

```bash
export RESTIC_REPOSITORY=/backup               # Repository path / Путь к репозиторию
export RESTIC_PASSWORD=<PASSWORD>              # Repo password (avoid in production!) / Пароль репозитория
export RESTIC_PASSWORD_FILE=/root/.restic-pw   # Recommended: password from file / Пароль из файла
export RESTIC_CACHE_DIR=/var/cache/restic      # Custom cache dir / Кастомная директория кэша
```

> [!TIP]
> Prefer `RESTIC_PASSWORD_FILE` over `RESTIC_PASSWORD` in production to avoid exposing the password in process listings or shell history.

---

## Repository Management

### Initialization & Integrity / Инициализация и целостность

```bash
restic -r /backup init                         # Initialize repo / Инициализировать репозиторий
restic -r /backup check                        # Quick integrity check / Быстрая проверка целостности
restic -r /backup check --read-data            # Deep check (reads all data) / Глубокая проверка (читает все данные)
restic -r /backup check --read-data-subset=5%  # Sample check — 5% of packs / Выборочная проверка
restic -r /backup unlock                       # Remove stale locks / Удалить устаревшие блокировки
restic -r /backup migrate                      # Migrate repo format / Мигрировать формат репозитория
restic -r /backup stats                        # Repository statistics / Статистика репозитория
```

Sample output of `restic stats`:
```
repository /backup
no snapshots were modified
Stats in restore-size mode:
Total File Count:   12345
Total Size:         45.678 GiB
```

### Key Management / Управление ключами

```bash
restic -r /backup key list                     # List encryption keys / Список ключей шифрования
restic -r /backup key add                      # Add new key / Добавить новый ключ
restic -r /backup key remove <KEY_ID>          # Remove key / Удалить ключ
restic -r /backup key passwd                   # Change password / Изменить пароль
```

> [!WARNING]
> Removing all keys will permanently lock you out of the repository. Always keep at least one valid key.

---

## Backup Operations

### Basic Backup / Базовый бэкап

```bash
restic -r /backup backup /var/www              # Backup single directory / Бэкап одного каталога
restic -r /backup backup /etc /var/www         # Multiple paths / Несколько путей
restic -r /backup backup /home --exclude="*.tmp"  # Exclude pattern / Исключить паттерн
```

### Advanced Options / Расширенные параметры

```bash
restic -r /backup backup /data --tag production            # Tag snapshot / Тегировать снапшот
restic -r /backup backup /data --tag daily --tag db        # Multiple tags / Несколько тегов
restic -r /backup backup /data --exclude-file=exclude.txt  # Exclude file / Файл исключений
restic -r /backup backup /data --one-file-system           # Don't cross mount points / Не пересекать точки монтирования
restic -r /backup backup /data --no-scan                   # Skip pre-scan (faster start) / Пропустить пресканирование
```

### Exclude Patterns / Исключения

```bash
restic -r /backup backup /home \
  --exclude="*.log" \
  --exclude="*.tmp" \
  --exclude="node_modules" \
  --exclude=".cache"                           # Multiple excludes / Множественные исключения
```

### Backup via Environment Variables / Бэкап через переменные окружения

```bash
export RESTIC_REPOSITORY=/backup
export RESTIC_PASSWORD_FILE=/root/.restic-pw
restic backup /var/www                         # Use env vars / Использовать переменные окружения
```

---

## Snapshot Management

### List & Filter / Список и фильтрация

```bash
restic -r /backup snapshots                    # List all snapshots / Список всех снапшотов
restic -r /backup snapshots --tag production   # Filter by tag / Фильтр по тегу
restic -r /backup snapshots --host <HOST>      # Filter by host / Фильтр по хосту
restic -r /backup snapshots --path /var/www    # Filter by path / Фильтр по пути
restic -r /backup snapshots --latest 5         # Show last 5 snapshots / Показать последние 5
```

Sample output:
```
ID        Time                 Host       Tags        Paths
----------------------------------------------------------------------
a1b2c3d4  2024-01-15 02:00:01  webserver  daily       /var/www
e5f6a7b8  2024-01-14 02:00:02  webserver  daily       /var/www
```

### Browse Snapshots / Просмотр снапшотов

```bash
restic -r /backup ls latest                    # List files in latest snapshot / Файлы в последнем снапшоте
restic -r /backup ls <SNAPSHOT_ID>             # List files in specific snapshot / Конкретный снапшот
restic -r /backup ls latest /var/www           # List specific path / Конкретный путь
restic -r /backup diff <SNAP1> <SNAP2>         # Compare two snapshots / Сравнить два снапшота
restic -r /backup find "*.conf"                # Find files across snapshots / Найти файлы в снапшотах
restic -r /backup cat blob <BLOB_ID>           # Display blob content / Показать содержимое blob
```

---

## Restore Operations

### Full Restore / Полное восстановление

> [!CAUTION]
> Restoring to `/` (root) will overwrite existing files. Always test restores to a separate path first.

```bash
restic -r /backup restore latest -t /restore               # Restore latest / Восстановить последний
restic -r /backup restore <SNAPSHOT_ID> -t /restore        # Restore specific snapshot / Конкретный снапшот
restic -r /backup restore latest --tag production -t /restore  # Restore by tag / По тегу
restic -r /backup restore latest -t / --verify             # Restore to root + verify / В корень + проверка
```

### Partial Restore / Частичное восстановление

```bash
restic -r /backup restore latest -t /restore --path /var/www         # Restore specific path / Конкретный путь
restic -r /backup restore latest -t /restore --include="*.conf"      # Include pattern / Включить паттерн
restic -r /backup restore latest -t /restore --exclude="*.log"       # Exclude pattern / Исключить паттерн
```

### Production Restore Runbook / Процедура восстановления в продакшне

1. Identify the correct snapshot:
   ```bash
   restic -r /backup snapshots --tag production  # Find target snapshot / Найти нужный снапшот
   ```
2. Restore to a staging directory first:
   ```bash
   restic -r /backup restore <SNAPSHOT_ID> -t /restore-staging --verify
   ```
3. Review the restored files:
   ```bash
   ls -la /restore-staging/
   ```
4. If correct, sync to production:
   ```bash
   rsync -av /restore-staging/ /var/www/         # Sync to target / Синхронизировать на цель
   ```
5. Verify application is working, then clean up:
   ```bash
   rm -rf /restore-staging
   ```

---

## Pruning & Retention

### Forget Snapshots / Удаление снапшотов

```bash
restic -r /backup forget --keep-last 10        # Keep last 10 / Сохранить последние 10
restic -r /backup forget --keep-daily 7        # Keep daily for 7 days / Дневные за 7 дней
restic -r /backup forget --keep-weekly 4       # Keep weekly for 4 weeks / Недельные за 4 недели
restic -r /backup forget --keep-monthly 12     # Keep monthly for 12 months / Месячные за 12 месяцев
restic -r /backup forget --keep-yearly 3       # Keep yearly for 3 years / Годовые за 3 года
```

### Combined Retention Policy / Комбинированная политика хранения

```bash
restic -r /backup forget \
  --keep-last 3 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --tag production \
  --dry-run                                    # Preview changes first! / Предварительный просмотр!
```

> [!WARNING]
> Always run with `--dry-run` first to preview which snapshots will be deleted before executing for real.

### Prune (Free Space) / Очистка (освобождение места)

```bash
restic -r /backup prune                        # Remove unreferenced data / Удалить неиспользуемые данные
restic -r /backup forget --keep-daily 7 --prune  # Forget + prune in one step / Забыть + очистить
restic -r /backup prune --max-repack-size 1G   # Limit repack size / Ограничить размер репаковки
```

> [!CAUTION]
> `prune` can be slow on large repositories and causes temporary lock. Schedule during low-load periods.

---

## S3/Cloud Integration

### AWS S3 / AWS S3

```bash
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
export AWS_DEFAULT_REGION=<REGION>             # e.g. eu-west-1
restic -r s3:s3.amazonaws.com/<BUCKET> init    # Init S3 repo / Инициализировать S3 репозиторий
restic -r s3:s3.amazonaws.com/<BUCKET> backup /data  # Backup to S3 / Бэкап в S3
```

### MinIO (S3-compatible) / MinIO (S3-совместимый)

```bash
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
restic -r s3:https://<MINIO_HOST>/<BUCKET> init  # MinIO repo / MinIO репозиторий
restic -r s3:https://<MINIO_HOST>/<BUCKET> backup /data
```

> [!TIP]
> For MinIO with self-signed TLS, set `--insecure-tls` or add the CA cert to your system trust store.

### Backblaze B2 / Backblaze B2

```bash
export B2_ACCOUNT_ID=<ACCOUNT_ID>
export B2_ACCOUNT_KEY=<ACCOUNT_KEY>
restic -r b2:<BUCKET>:/ init                   # B2 repo / B2 репозиторий
restic -r b2:<BUCKET>:/ backup /data
```

### Azure Blob Storage / Azure Blob Storage

```bash
export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<ACCOUNT_KEY>
restic -r azure:<CONTAINER>:/ init             # Azure repo / Azure репозиторий
restic -r azure:<CONTAINER>:/ backup /data
```

### Google Cloud Storage / Google Cloud Storage

```bash
export GOOGLE_PROJECT_ID=<PROJECT_ID>
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
restic -r gs:<BUCKET>:/ init                   # GCS repo / GCS репозиторий
restic -r gs:<BUCKET>:/ backup /data
```

---

## Performance & Security

### Compression / Сжатие

| Mode | Description | Use Case |
|------|-------------|----------|
| `auto` | Compress if beneficial | General purpose (recommended) |
| `max` | Always compress at max level | Slow networks, tight storage |
| `off` | No compression | Already-compressed data (media, zips) |

```bash
restic -r /backup backup /data --compression auto   # Auto compression / Автоматическое сжатие
restic -r /backup backup /data --compression max    # Max compression / Максимальное сжатие
restic -r /backup backup /data --compression off    # No compression / Без сжатия
```

### Bandwidth Limiting / Ограничение полосы пропускания

```bash
restic -r /backup backup /data --limit-upload 1024    # Limit upload to 1 MB/s / Ограничить загрузку до 1 МБ/с
restic -r /backup backup /data --limit-download 2048  # Limit download to 2 MB/s / Ограничить скачивание
```

### Cache Management / Управление кэшем

```bash
restic -r /backup --cache-dir /var/cache/restic backup /data  # Custom cache dir / Кастомный кэш
restic cache --cleanup                                        # Clean stale cache entries / Очистить кэш
restic cache --no-cache backup /data                          # Disable cache / Отключить кэш
```

### Encryption / Шифрование

```bash
# Restic uses AES-256-CTR + Poly1305-AES for authenticated encryption
# / Restic использует AES-256-CTR + Poly1305-AES для аутентифицированного шифрования

export RESTIC_PASSWORD=<PASSWORD>              # Set password via env / Установить пароль через env
export RESTIC_PASSWORD_FILE=/root/.restic-pw   # Set password via file / Установить пароль через файл

# Create password file securely / Создать файл пароля безопасно
echo "<PASSWORD>" > /root/.restic-pw
chmod 600 /root/.restic-pw                    # Restrict permissions / Ограничить права доступа
```

### Parallel Operations / Параллельные операции

```bash
restic -r /backup backup /data --read-concurrency 4   # Parallel reads / Параллельное чтение
restic -r /backup backup /data --pack-size 16          # Smaller pack size for many small files / Меньший пакет
```

---

## Sysadmin Operations

### Default Paths / Пути по умолчанию

```bash
~/.cache/restic/       # Cache directory / Директория кэша
~/.config/restic/      # Config directory / Директория конфигурации
/root/.restic-pw       # Common password file location / Типичное расположение файла пароля
/var/log/restic/       # Recommended log directory / Рекомендуемая директория логов
```

### Systemd Service for Automated Backups / Systemd-сервис для автоматических бэкапов

`/etc/systemd/system/restic-backup.service`

```ini
[Unit]
Description=Restic Backup
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
Environment="RESTIC_REPOSITORY=/backup"
Environment="RESTIC_PASSWORD_FILE=/root/.restic-pw"
ExecStart=/usr/bin/restic backup /var/www /etc --tag daily --compression auto
ExecStartPost=/usr/bin/restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune
StandardOutput=append:/var/log/restic/backup.log
StandardError=append:/var/log/restic/backup-error.log

[Install]
WantedBy=multi-user.target
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/restic-backup.timer`

```ini
[Unit]
Description=Restic Backup Timer
Requires=restic-backup.service

[Timer]
OnCalendar=*-*-* 02:00:00    # Run daily at 02:00 / Запуск ежедневно в 02:00
Persistent=true               # Run on next boot if missed / Запуск при следующей загрузке, если пропущен
RandomizedDelaySec=30m        # Spread load / Распределить нагрузку

[Install]
WantedBy=timers.target
```

### Enable & Manage Timer / Включить и управлять таймером

```bash
mkdir -p /var/log/restic                        # Create log directory / Создать директорию логов
systemctl daemon-reload                         # Reload systemd / Перезагрузить systemd
systemctl enable restic-backup.timer            # Enable timer / Включить таймер
systemctl start restic-backup.timer             # Start timer / Запустить таймер
systemctl status restic-backup.timer            # Check status / Проверить статус
systemctl list-timers restic-backup.timer       # Show next run / Показать следующий запуск
```

### Logs & Monitoring / Логи и мониторинг

```bash
journalctl -u restic-backup.service             # View backup logs / Просмотр логов бэкапа
journalctl -u restic-backup.service -f          # Follow live logs / Следить за логами в реальном времени
journalctl -u restic-backup.service --since today  # Today's logs / Сегодняшние логи
tail -f /var/log/restic/backup.log              # Tail log file / Следить за файлом лога
```

### Logrotate Configuration / Конфигурация logrotate

`/etc/logrotate.d/restic`

```
/var/log/restic/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    dateext
    dateformat -%Y%m%d
}
```

---

## Troubleshooting

### Compression / Common Errors / Распространённые ошибки

```bash
# Error: "repository is already locked" / "репозиторий уже заблокирован"
restic -r /backup unlock                       # Remove stale lock / Удалить устаревшую блокировку

# Error: "wrong password" / "неверный пароль"
echo "<PASSWORD>" > /root/.restic-pw
chmod 600 /root/.restic-pw
export RESTIC_PASSWORD_FILE=/root/.restic-pw

# Check repository errors / Ошибки целостности репозитория
restic -r /backup check --read-data            # Deep check / Глубокая проверка
restic -r /backup rebuild-index                # Rebuild index / Пересоздать индекс
```

### Repair Operations / Операции восстановления

> [!WARNING]
> Repair operations modify repository data. Run `check` first to understand the extent of damage before repairing.

```bash
restic -r /backup repair index                 # Repair index / Восстановить индекс
restic -r /backup repair snapshots             # Repair snapshots / Восстановить снапшоты
restic -r /backup repair packs                 # Remove invalid pack files / Удалить некорректные пакеты
restic -r /backup rebuild-index                # Rebuild index from scratch / Пересоздать индекс с нуля
```

### Verbose Output / Подробный вывод

```bash
restic -r /backup backup /data -v              # Verbose / Подробный вывод
restic -r /backup backup /data -vv             # Very verbose / Очень подробный вывод
restic -r /backup --log-file /tmp/restic.log backup /data  # Log to file / Лог в файл
```

### Performance Issues / Проблемы с производительностью

```bash
restic -r /backup backup /data --read-concurrency 4   # Increase parallelism / Увеличить параллелизм
restic -r /backup backup /data --pack-size 16         # Smaller packs (many small files) / Меньший пакет
restic -r /backup backup /data --no-scan              # Skip file count pre-scan / Пропустить пресканирование
restic cache --cleanup                                # Free stale cache / Освободить устаревший кэш
```

### Integrity Check Runbook / Процедура проверки целостности

1. Quick check (no data reads):
   ```bash
   restic -r /backup check
   ```
2. Sample read (5% of data — good for daily cron):
   ```bash
   restic -r /backup check --read-data-subset=5%
   ```
3. Full data read (monthly, slow):
   ```bash
   restic -r /backup check --read-data
   ```
4. If errors found, repair:
   ```bash
   restic -r /backup repair index
   restic -r /backup repair snapshots
   ```
5. Re-verify after repair:
   ```bash
   restic -r /backup check
   ```
