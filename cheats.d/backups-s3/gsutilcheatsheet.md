Title: 🗄️ gsutil — Google Cloud Storage
Group: Backups & S3
Icon: 🗄️
Order: 10

## Table of Contents
- [Installation & Authentication](#installation--authentication)
- [Bucket Operations](#bucket-operations)
- [Upload & Download](#upload--download)
- [Rsync Operations](#rsync-operations)
- [Storage Classes](#storage-classes)
- [Lifecycle Management](#lifecycle-management)
- [Versioning & Retention](#versioning--retention)
- [Parallel Operations](#parallel-operations)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Authentication

### Install gcloud SDK / Установить gcloud SDK

```bash
# Script-based install / Установка через скрипт
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Debian/Ubuntu via apt / Через apt
echo "deb https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt update && apt install google-cloud-sdk

gsutil version                                  # Verify install / Проверить установку
```

### Authenticate / Аутентифицироваться

```bash
gcloud auth login                               # Interactive login / Интерактивный вход
gcloud auth activate-service-account \
  --key-file=<KEY_FILE>.json                    # Service account / Сервисный аккаунт

gsutil ls                                       # Test access / Тест доступа
```

---

## Bucket Operations

### Create Bucket / Создать bucket

```bash
gsutil mb gs://<BUCKET>                         # Make bucket (default region) / Создать bucket
gsutil mb -l us-east1 gs://<BUCKET>             # Specific region / Конкретный регион
gsutil mb -c NEARLINE gs://<BUCKET>             # Specific storage class / Конкретный класс
```

### List Buckets & Objects / Список buckets и объектов

```bash
gsutil ls                                       # List all buckets / Все buckets
gsutil ls gs://<BUCKET>                         # List objects in bucket / Объекты в bucket
gsutil ls -L gs://<BUCKET>/file.txt             # Detailed info / Подробная информация
gsutil ls -r gs://<BUCKET>/**                   # Recursive list / Рекурсивный список
```

### Delete Bucket / Удалить bucket

> [!WARNING]
> Deleting all objects before removing the bucket is irreversible. Double-check the bucket name.

```bash
gsutil -m rm -r gs://<BUCKET>/**               # Delete all objects / Удалить все объекты
gsutil rb gs://<BUCKET>                         # Remove empty bucket / Удалить пустой bucket
```

---

## Upload & Download

### Upload (cp) / Загрузить

```bash
gsutil cp file.txt gs://<BUCKET>/               # Upload file / Загрузить файл
gsutil cp -r /data gs://<BUCKET>/data           # Upload directory / Загрузить директорию
gsutil -m cp *.jpg gs://<BUCKET>/images/        # Parallel upload / Параллельная загрузка
```

### Download / Скачать

```bash
gsutil cp gs://<BUCKET>/file.txt .              # Download file / Скачать файл
gsutil cp -r gs://<BUCKET>/data /restore        # Download directory / Скачать директорию
gsutil -m cp gs://<BUCKET>/images/* .           # Parallel download / Параллельное скачивание
```

### Move & Remove / Переместить и удалить

```bash
gsutil mv gs://<BUCKET>/old.txt gs://<BUCKET>/new.txt  # Move/rename / Переместить/переименовать
gsutil rm gs://<BUCKET>/file.txt                # Delete file / Удалить файл
gsutil -m rm gs://<BUCKET>/path/**              # Delete directory / Удалить директорию
```

### Cat & Compose / Просмотр и объединение

```bash
gsutil cat gs://<BUCKET>/file.txt               # Display file content / Показать содержимое
gsutil compose \
  gs://<BUCKET>/part1 gs://<BUCKET>/part2 \
  gs://<BUCKET>/combined                        # Compose (merge) files / Объединить файлы
```

---

## Rsync Operations

### Sync Local → GCS / Синхронизация в GCS

```bash
gsutil -m rsync -r /data gs://<BUCKET>/data    # Parallel rsync / Параллельная синхронизация
gsutil rsync -d /data gs://<BUCKET>/data        # Delete removed files / Удалить удалённые
```

### Sync GCS → Local / Синхронизация из GCS

```bash
gsutil rsync gs://<BUCKET>/data /restore        # Sync from GCS / Синхронизация из GCS
gsutil rsync -d gs://<BUCKET>/data /restore     # Delete dest extras / Удалить лишние
```

### Advanced Rsync / Расширенная синхронизация

```bash
gsutil rsync -x ".*\.tmp$" /data gs://<BUCKET>/data  # Exclude by regex / Исключить по regex
gsutil rsync -c /data gs://<BUCKET>/data         # Compare by checksum / Сравнить по контрольной сумме
```

---

## Storage Classes

### Storage Class Comparison / Сравнение классов хранения

| Class | Access Frequency / Частота доступа | Min Duration | Use Case |
|-------|------------------------------------|--------------|----------|
| `STANDARD` | Frequent / Частый | None | Active data |
| `NEARLINE` | ~1×/month / ~раз/месяц | 30 days | Monthly backups |
| `COLDLINE` | ~1×/quarter / ~раз/квартал | 90 days | Quarterly archives |
| `ARCHIVE` | Rarely / Редко | 365 days | Compliance, long-term |

### Set Storage Class / Установить класс хранения

```bash
gsutil cp -s NEARLINE file.txt gs://<BUCKET>/   # Upload to Nearline / Загрузить в Nearline
gsutil -m setmeta -h "x-goog-storage-class:NEARLINE" gs://<BUCKET>/**  # Change existing / Изменить
```

### Default Bucket Class / Класс bucket по умолчанию

```bash
gsutil defstorageclass set NEARLINE gs://<BUCKET>  # Set default / Установить по умолчанию
gsutil defstorageclass get gs://<BUCKET>            # Get default / Получить текущий
```

---

## Lifecycle Management

### Apply Lifecycle Policy / Применить политику lifecycle

```bash
gsutil lifecycle set lifecycle.json gs://<BUCKET>  # Set policy / Установить политику
gsutil lifecycle get gs://<BUCKET>                  # View policy / Просмотреть политику
```

`/tmp/lifecycle.json`

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "SetStorageClass", "storageClass": "NEARLINE" },
        "condition": { "age": 30 }
      },
      {
        "action": { "type": "SetStorageClass", "storageClass": "ARCHIVE" },
        "condition": { "age": 90 }
      },
      {
        "action": { "type": "Delete" },
        "condition": { "age": 365 }
      }
    ]
  }
}
```

---

## Versioning & Retention

### Enable Versioning / Включить версионирование

```bash
gsutil versioning set on gs://<BUCKET>          # Enable / Включить
gsutil versioning get gs://<BUCKET>             # Check status / Проверить
gsutil ls -a gs://<BUCKET>/file.txt             # List all versions / Все версии
```

### Retention Policy / Политика хранения

```bash
gsutil retention set 30d gs://<BUCKET>          # Set 30-day retention / 30 дней хранения
gsutil retention get gs://<BUCKET>              # Get policy / Получить политику
gsutil retention clear gs://<BUCKET>            # Clear policy / Очистить политику
```

---

## Parallel Operations

```bash
gsutil -m cp -r /data gs://<BUCKET>/data        # Parallel copy / Параллельное копирование
gsutil -m rsync -r /data gs://<BUCKET>/data     # Parallel rsync / Параллельная синхронизация
gsutil -m rm gs://<BUCKET>/path/**              # Parallel delete / Параллельное удаление

# Fine-tuned parallelism / Точная настройка параллелизма
gsutil -o "GSUtil:parallel_thread_count=20" -m cp -r /data gs://<BUCKET>/
gsutil -o "GSUtil:parallel_process_count=8"  -m cp -r /data gs://<BUCKET>/
```

---

## Sysadmin Operations

### Automated Backup Script / Автоматический скрипт бэкапа

`/usr/local/bin/gcs-backup.sh`

```bash
#!/bin/bash
# GCS daily backup with Nearline storage class
# / Ежедневный бэкап в GCS с классом Nearline

set -euo pipefail

BUCKET="<BUCKET>"
SOURCE="/data"
DATE=$(date +%Y%m%d)
LOG="/var/log/gcs-backup.log"

echo "$(date): Starting GCS backup → gs://$BUCKET/backups/$DATE/" >> "$LOG"

gsutil -m rsync -r -d "$SOURCE" "gs://$BUCKET/backups/$DATE/" >> "$LOG" 2>&1
gsutil -m setmeta -h "x-goog-storage-class:NEARLINE" "gs://$BUCKET/backups/$DATE/**" >> "$LOG" 2>&1

echo "$(date): Backup complete." >> "$LOG"
```

```bash
chmod +x /usr/local/bin/gcs-backup.sh
```

### Service Account Setup / Настройка сервисного аккаунта

```bash
# Create service account / Создать сервисный аккаунт
gcloud iam service-accounts create backup-sa --display-name="Backup Service Account"

# Grant storage permissions / Права на хранилище
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:backup-sa@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Create JSON key / Создать ключ JSON
gcloud iam service-accounts keys create /etc/gcs-key.json \
  --iam-account=backup-sa@<PROJECT_ID>.iam.gserviceaccount.com
chmod 600 /etc/gcs-key.json

# Activate key / Активировать ключ
gcloud auth activate-service-account --key-file=/etc/gcs-key.json
```

### Cron Schedule / Расписание cron

`/etc/cron.d/gcs-backup`

```
# GCS daily backup at 02:30 / Ежедневный бэкап в GCS в 02:30
30 2 * * * root /usr/local/bin/gcs-backup.sh
```

### Environment Variables / Переменные окружения

```bash
export CLOUDSDK_CORE_PROJECT=<PROJECT_ID>       # Default project / Проект по умолчанию
export CLOUDSDK_COMPUTE_REGION=us-east1         # Default region / Регион по умолчанию
```

### Configuration Paths / Пути конфигурации

```bash
~/.config/gcloud/      # gcloud config dir / Директория конфигурации gcloud
~/.boto                # gsutil config / Конфигурация gsutil
```

```bash
gsutil config                                   # Interactive config / Интерактивная настройка
```

### Logrotate / Logrotate

`/etc/logrotate.d/gcs-backup`

```
/var/log/gcs-backup.log {
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
# "AccessDeniedException" / "Отказано в доступе"
gcloud auth list                                # List accounts / Список аккаунтов
gcloud config set account <ACCOUNT>             # Switch account / Переключить аккаунт

# "BucketNotFoundException" / "Bucket не найден"
gsutil ls                                       # List buckets / Список buckets
gsutil mb gs://<BUCKET>                         # Create bucket / Создать bucket

# Slow transfers / Медленные передачи
gsutil -m cp -r /data gs://<BUCKET>/            # Enable parallel / Использовать параллелизм
gsutil -o "GSUtil:parallel_thread_count=32" -m cp -r /data gs://<BUCKET>/
```

### Verify Upload / Проверить загрузку

```bash
gsutil ls -L gs://<BUCKET>/file.txt             # Check file metadata / Метаданные файла
gsutil hash file.txt                            # Local hash / Локальный хэш
gsutil hash gs://<BUCKET>/file.txt              # Remote hash / Удалённый хэш
```

### Debug Mode / Режим отладки

```bash
gsutil -D cp file.txt gs://<BUCKET>/            # Full debug output / Полный отладочный вывод
gsutil -d rsync /data gs://<BUCKET>/data        # Verbose rsync / Подробная синхронизация
```

### Performance Test / Тест производительности

```bash
gsutil perfdiag -n 100 -s 1M gs://<BUCKET>     # Performance diagnostic / Диагностика производительности
gsutil -o "GSUtil:sliced_object_download_threshold=100M" \
  cp gs://<BUCKET>/large-file .                 # Sliced download / Разбитое скачивание
```
