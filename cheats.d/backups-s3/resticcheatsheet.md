Title: 🗄️ restic — Backups
Group: Backups & S3
Icon: 🗄️
Order: 1

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Repository Management](#repository-management)
- [Backup Operations](#backup-operations)
- [Snapshot Management](#snapshot-management)
- [Restore Operations](#restore-operations)
- [Pruning & Retention](#pruning--retention)
- [S3/Cloud Integration](#s3cloud-integration)
- [Performance & Security](#performance--security)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install

# Debian/Ubuntu
apt install restic                             # Install restic / Установить restic

# RHEL/AlmaLinux/Rocky
dnf install restic                             # Install restic / Установить restic

# From binary / Из бинарника
wget https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_linux_amd64.bz2
bunzip2 restic_0.16.0_linux_amd64.bz2
chmod +x restic_0.16.0_linux_amd64
mv restic_0.16.0_linux_amd64 /usr/local/bin/restic

### Repository Types

restic -r /backup init                         # Local repository / Локальный репозиторий
restic -r sftp:<USER>@<HOST>:/backup init      # SFTP repository / SFTP репозиторий
restic -r s3:s3.amazonaws.com/<BUCKET> init    # AWS S3 / AWS S3
restic -r rest:https://<HOST>:8000/ init       # REST server / REST сервер

---

## Repository Management

restic -r /backup init                         # Initialize repo / Инициализировать репозиторий
restic -r /backup check                        # Check repo integrity / Проверить целостность
restic -r /backup check --read-data            # Deep check / Глубокая проверка
restic -r /backup unlock                       # Remove locks / Удалить блокировки
restic -r /backup migrate                      # Migrate repo format / Мигрировать формат
restic -r /backup stats                        # Repository stats / Статистика репозитория
restic -r /backup key list                     # List keys / Список ключей
restic -r /backup key add                      # Add new key / Добавить новый ключ
restic -r /backup key remove <KEY_ID>          # Remove key / Удалить ключ

---

## Backup Operations

### Basic Backup

restic -r /backup backup /var/www              # Backup directory / Бэкап каталога
restic -r /backup backup /etc /var/www         # Multiple paths / Несколько путей
restic -r /backup backup /home --exclude="*.tmp" # Exclude pattern / Исключить паттерн

### Advanced Backup Options

restic -r /backup backup /data --tag production # Tag snapshot / Тегировать снапшот
restic -r /backup backup /data --tag daily --tag db # Multiple tags / Несколько тегов
restic -r /backup backup /data --exclude-file=exclude.txt # Exclude file / Файл исключений
restic -r /backup backup /data --one-file-system # Don't cross mounts / Не пересекать точки монтирования

### Exclude Patterns

restic -r /backup backup /home \
  --exclude="*.log" \
  --exclude="*.tmp" \
  --exclude="node_modules" \
  --exclude=".cache"                           # Multiple excludes / Множественные исключения

### Backup with Environment Variables

export RESTIC_REPOSITORY=/backup
export RESTIC_PASSWORD=<PASSWORD>
restic backup /var/www                         # Use env vars / Использовать переменные окружения

---

## Snapshot Management

restic -r /backup snapshots                    # List snapshots / Список снапшотов
restic -r /backup snapshots --tag production   # Filter by tag / Фильтр по тегу
restic -r /backup snapshots --host <HOST>      # Filter by host / Фильтр по хосту
restic -r /backup snapshots --path /var/www    # Filter by path / Фильтр по пути

restic -r /backup ls latest                    # List files in snapshot / Список файлов в снапшоте
restic -r /backup ls <SNAPSHOT_ID>             # List specific snapshot / Конкретный снапшот
restic -r /backup ls latest /var/www           # List specific path / Конкретный путь

restic -r /backup diff <SNAP1> <SNAP2>         # Compare snapshots / Сравнить снапшоты
restic -r /backup find "*.conf"                # Find files / Найти файлы
restic -r /backup cat blob <BLOB_ID>           # Display blob / Показать blob

---

## Restore Operations

### Full Restore

restic -r /backup restore latest -t /restore   # Restore latest / Восстановить последний
restic -r /backup restore <SNAPSHOT_ID> -t /restore # Restore specific / Восстановить конкретный
restic -r /backup restore latest --tag production -t /restore # Restore by tag / По тегу

### Partial Restore

restic -r /backup restore latest -t /restore --path /var/www # Restore path / Восстановить путь
restic -r /backup restore latest -t /restore --include="*.conf" # Include pattern / Включить паттерн
restic -r /backup restore latest -t /restore --exclude="*.log" # Exclude pattern / Исключить паттерн

### Restore to Original Location

restic -r /backup restore latest -t /          # Restore to / / Восстановить в /
restic -r /backup restore latest --verify      # Verify after restore / Проверить после восстановления

---

## Pruning & Retention

### Forget Snapshots

restic -r /backup forget --keep-last 10        # Keep last 10 / Сохранить последние 10
restic -r /backup forget --keep-daily 7        # Keep daily for 7 days / Дневные за 7 дней
restic -r /backup forget --keep-weekly 4       # Keep weekly for 4 weeks / Недельные за 4 недели
restic -r /backup forget --keep-monthly 12     # Keep monthly for 12 months / Месячные за 12 месяцев
restic -r /backup forget --keep-yearly 3       # Keep yearly for 3 years / Годовые за 3 года

### Retention Policy

restic -r /backup forget \
  --keep-last 3 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --tag production                             # Combined policy / Комбинированная политика

### Prune (Free Space)

restic -r /backup prune                        # Remove unused data / Удалить неиспользуемые данные
restic -r /backup forget --keep-daily 7 --prune # Forget + prune / Забыть + очистить

---

## S3/Cloud Integration

### AWS S3

export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
restic -r s3:s3.amazonaws.com/<BUCKET> init    # Init S3 repo / Инициализировать S3 репозиторий
restic -r s3:s3.amazonaws.com/<BUCKET> backup /data # Backup to S3 / Бэкап в S3

### MinIO

export AWS_ACCESS_KEY_ID=<ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
restic -r s3:https://<MINIO_HOST>/<BUCKET> init # MinIO repo / MinIO репозиторий

### Backblaze B2

export B2_ACCOUNT_ID=<ACCOUNT_ID>
export B2_ACCOUNT_KEY=<ACCOUNT_KEY>
restic -r b2:<BUCKET>:/ init                   # B2 repo / B2 репозиторий

### Azure Blob Storage

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<ACCOUNT_KEY>
restic -r azure:<CONTAINER>:/ init             # Azure repo / Azure репозиторий

### Google Cloud Storage

export GOOGLE_PROJECT_ID=<PROJECT_ID>
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
restic -r gs:<BUCKET>:/ init                   # GCS repo / GCS репозиторий

---

## Performance & Security

### Compression

restic -r /backup backup /data --compression auto # Auto compression / Автоматическое сжатие
restic -r /backup backup /data --compression max  # Max compression / Максимальное сжатие
restic -r /backup backup /data --compression off  # No compression / Без сжатия

### Bandwidth Limiting

restic -r /backup backup /data --limit-upload 1024 # Limit to 1MB/s / Ограничить до 1МБ/с
restic -r /backup backup /data --limit-download 2048 # Download limit / Ограничить загрузку

### Cache

restic -r /backup --cache-dir /tmp/restic-cache backup /data # Custom cache / Кастомный кэш
restic cache --cleanup                         # Clean cache / Очистить кэш

### Encryption

# Restic uses AES-256 encryption by default / Restic использует AES-256 по умолчанию
export RESTIC_PASSWORD=<PASSWORD>              # Set password / Установить пароль
export RESTIC_PASSWORD_FILE=/root/.restic-pw   # Password file / Файл с паролем

---

## Sysadmin Operations

### Systemd Timer for Automated Backups

#### /etc/systemd/system/restic-backup.service

[Unit]
Description=Restic Backup
After=network.target

[Service]
Type=oneshot
Environment="RESTIC_REPOSITORY=/backup"
Environment="RESTIC_PASSWORD_FILE=/root/.restic-pw"
ExecStart=/usr/bin/restic backup /var/www /etc --tag daily
ExecStartPost=/usr/bin/restic forget --keep-daily 7 --keep-weekly 4 --prune

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/restic-backup.timer

[Unit]
Description=Restic Backup Timer
Requires=restic-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

#### Enable Timer

systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable restic-backup.timer           # Enable timer / Включить таймер
systemctl start restic-backup.timer            # Start timer / Запустить таймер
systemctl status restic-backup.timer           # Check status / Проверить статус

### Logs & Monitoring

journalctl -u restic-backup.service            # View backup logs / Просмотр логов бэкапа
journalctl -u restic-backup.service -f         # Follow logs / Следить за логами
restic -r /backup check --read-data-subset=5%  # Quick integrity check / Быстрая проверка целостности

### Default Paths

~/.cache/restic/                               # Cache directory / Директория кэша
~/.config/restic/                              # Config directory / Директория конфигурации
/root/.restic-pw                               # Common password file location / Обычное расположение файла пароля

---

## Troubleshooting

### Common Errors

# "repository is already locked" / "репозиторий уже заблокирован"
restic -r /backup unlock                       # Remove stale locks / Удалить устаревшие блокировки

# "wrong password" / "неверный пароль"
echo "<PASSWORD>" > /root/.restic-pw
export RESTIC_PASSWORD_FILE=/root/.restic-pw

# Check repository errors / Ошибки проверки репозитория
restic -r /backup check --read-data            # Deep check / Глубокая проверка
restic -r /backup rebuild-index                # Rebuild index / Пересоздать индекс

### Repair Operations

restic -r /backup repair index                 # Repair index / Восстановить индекс
restic -r /backup repair snapshots             # Repair snapshots / Восстановить снапшоты
restic -r /backup rebuild-index                # Rebuild index from scratch / Пересоздать индекс с нуля

### Verbose Output

restic -r /backup backup /data -v              # Verbose / Подробный вывод
restic -r /backup backup /data -vv             # Very verbose / Очень подробный вывод

### Performance Issues

restic -r /backup backup /data --read-concurrency 4 # Parallel reads / Параллельное чтение
restic -r /backup backup /data --pack-size 16  # Smaller pack size / Меньший размер пакета

### Check Backup Integrity

restic -r /backup check                        # Quick check / Быстрая проверка
restic -r /backup check --read-data            # Full check (slow) / Полная проверка (медленно)
restic -r /backup check --read-data-subset=10% # 10% sample check / Проверка 10% выборки
