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

### Install

# Install gcloud SDK / Установить gcloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Or via package manager / Или через менеджер пакетов
# Debian/Ubuntu
echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
apt update && apt install google-cloud-sdk

### Authenticate

gcloud auth login                              # Interactive login / Интерактивный вход
gcloud auth activate-service-account --key-file=<KEY_FILE>.json # Service account / Сервисный аккаунт

gsutil version                                 # Check version / Проверить версию
gsutil ls                                      # Test access / Тестировать доступ

---

## Bucket Operations

### Create Bucket

gsutil mb gs://<BUCKET>                        # Make bucket / Создать bucket  
gsutil mb -l us-east1 gs://<BUCKET>            # Specific region / Конкретный регион
gsutil mb -c NEARLINE gs://<BUCKET>            # Specific storage class / Конкретный класс хранилища

### List Buckets & Objects

gsutil ls                                      # List buckets / Список buckets
gsutil ls gs://<BUCKET>                        # List objects / Список объектов
gsutil ls -L gs://<BUCKET>/file.txt            # Detailed info / Подробная информация
gsutil ls -r gs://<BUCKET>/**                  # Recursive list / Рекурсивный список

### Delete Bucket

gsutil rb gs://<BUCKET>                        # Remove bucket (empty) / Удалить bucket (пустой)
gsutil -m rm -r gs://<BUCKET>/**               # Delete all objects / Удалить все объекты
gsutil rb gs://<BUCKET>                        # Then remove bucket / Затем удалить bucket

---

## Upload & Download

### Upload (cp)

gsutil cp file.txt gs://<BUCKET>/              # Upload file / Загрузить файл
gsutil cp -r /data gs://<BUCKET>/data          # Upload directory / Загрузить директорию
gsutil -m cp *.jpg gs://<BUCKET>/images/       # Parallel upload / Параллельная загрузка

### Download

gsutil cp gs://<BUCKET>/file.txt .             # Download file / Скачать файл
gsutil cp -r gs://<BUCKET>/data /restore       # Download directory / Скачать директорию
gsutil -m cp gs://<BUCKET>/images/* .          # Parallel download / Параллельное скачивание

### Move & Remove

gsutil mv gs://<BUCKET>/old.txt gs://<BUCKET>/new.txt # Move/rename / Переместить/переименовать
gsutil rm gs://<BUCKET>/file.txt               # Delete file / Удалить файл
gsutil -m rm gs://<BUCKET>/path/**             # Delete directory / Удалить директорию

### Cat & Compose

gsutil cat gs://<BUCKET>/file.txt              # Display file / Показать файл
gsutil compose gs://<BUCKET>/part1 gs://<BUCKET>/part2 gs://<BUCKET>/combined # Combine files / Объединить файлы

---

## Rsync Operations

### Sync Local → GCS

gsutil rsync /data gs://<BUCKET>/data          # Sync to GCS / Синхронизация в GCS
gsutil rsync -d /data gs://<BUCKET>/data       # Delete removed files / Удалить удалённые файлы
gsutil rsync -r /data gs://<BUCKET>/data       # Recursive / Рекурсивно

### Sync GCS → Local

gsutil rsync gs://<BUCKET>/data /restore       # Sync from GCS / Синхронизация из GCS
gsutil rsync -d gs://<BUCKET>/data /restore    # Delete removed files / Удалить удалённые файлы

### Advanced Rsync

gsutil -m rsync -r /data gs://<BUCKET>/data    # Parallel rsync / Параллельная синхронизация
gsutil rsync -x ".*\.tmp$" /data gs://<BUCKET>/data # Exclude pattern / Исключить паттерн
gsutil rsync -c /data gs://<BUCKET>/data       # Compare checksums / Сравнить контрольные суммы

---

## Storage Classes

### Available Classes

# STANDARD — Default, frequent access / По умолчанию, частый доступ
# NEARLINE — Accessed ~once/month / Доступ ~раз/месяц
# COLDLINE — Accessed ~once/quarter / Доступ ~раз/квартал
# ARCHIVE — Long-term archive / Долгосрочный архив

### Set Storage Class

gsutil -m setmeta -h "x-goog-storage-class:NEARLINE" gs://<BUCKET>/** # Change class / Изменить класс
gsutil cp -s NEARLINE file.txt gs://<BUCKET>/  # Upload to Nearline / Загрузить в Nearline

### Default Bucket Class

gsutil defstorageclass set NEARLINE gs://<BUCKET> # Set default class / Установить класс по умолчанию
gsutil defstorageclass get gs://<BUCKET>       # Get default class / Получить класс по умолчанию

---

## Lifecycle Management

### Set Lifecycle Policy

gsutil lifecycle set lifecycle.json gs://<BUCKET> # Set lifecycle / Установить lifecycle

#### lifecycle.json Example

{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "NEARLINE"
        },
        "condition": {
          "age": 30
        }
      },
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": 365
        }
      }
    ]
  }
}

### View Lifecycle

gsutil lifecycle get gs://<BUCKET>             # Get lifecycle / Получить lifecycle

---

## Versioning & Retention

### Enable Versioning

gsutil versioning set on gs://<BUCKET>         # Enable versioning / Включить версионирование
gsutil versioning get gs://<BUCKET>            # Check versioning / Проверить версионирование

### List Versions

gsutil ls -a gs://<BUCKET>/file.txt            # List all versions / Список всех версий

### Retention Policy

gsutil retention set 30d gs://<BUCKET>         # Set 30-day retention / Установить хранение 30 дней
gsutil retention get gs://<BUCKET>             # Get retention / Получить политику хранения
gsutil retention clear gs://<BUCKET>           # Clear retention / Очистить политику хранения

---

## Parallel Operations

### Enable Parallel Transfers

gsutil -m cp -r /data gs://<BUCKET>/data       # Parallel copy / Параллельное копирование
gsutil -m rsync -r /data gs://<BUCKET>/data    # Parallel rsync / Параллельная синхронизация
gsutil -m rm gs://<BUCKET>/path/**             # Parallel delete / Параллельное удаление

### Performance Tuning

gsutil -o "GSUtil:parallel_thread_count=20" cp -r /data gs://<BUCKET>/ # 20 threads / 20 потоков
gsutil -o "GSUtil:parallel_process_count=8" cp -r /data gs://<BUCKET>/  # 8 processes / 8 процессов

---

## Sysadmin Operations

### Automated Backup Script

#!/bin/bash
# /usr/local/bin/gcs-backup.sh

BUCKET="<BUCKET>"
SOURCE="/data"
DATE=$(date +%Y%m%d)

# Rsync to GCS / Синхронизация в GCS
gsutil -m rsync -r -d $SOURCE gs://$BUCKET/backups/$DATE/

# Set storage class to Nearline / Установить класс хранилища Nearline
gsutil -m setmeta -h "x-goog-storage-class:NEARLINE" gs://$BUCKET/backups/$DATE/**

### Service Account

# Create service account / Создать сервисный аккаунт
gcloud iam service-accounts create backup-sa --display-name="Backup Service Account"

# Grant storage permissions / Выдать права на хранилище
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:backup-sa@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Create key / Создать ключ
gcloud iam service-accounts keys create key.json \
  --iam-account=backup-sa@<PROJECT_ID>.iam.gserviceaccount.com

# Use key / Использовать ключ
gcloud auth activate-service-account --key-file=key.json

### Environment Variables

export CLOUDSDK_CORE_PROJECT=<PROJECT_ID>      # Default project / Проект по умолчанию
export CLOUDSDK_COMPUTE_REGION=us-east1        # Default region / Регион по умолчанию

### Configuration

~/.config/gcloud/                              # Config directory / Директория конфигурации
~/.boto                                        # gsutil config / Конфигурация gsutil

gsutil config                                  # Interactive config / Интерактивная настройка

---

## Troubleshooting

### Common Errors

# "AccessDeniedException" / "Доступ запрещён"
gcloud auth list                               # List accounts / Список аккаунтов
gcloud config set account <ACCOUNT>            # Switch account / Переключить аккаунт

# "BucketNotFoundException" / "Bucket не найден"
gsutil ls                                      # List buckets / Список buckets
gsutil mb gs://<BUCKET>                        # Create bucket / Создать bucket

# Slow transfers / Медленные передачи
gsutil -m cp -r /data gs://<BUCKET>/           # Use parallel / Использовать параллелизм
gsutil -o "GSUtil:parallel_thread_count=32" cp -r /data gs://<BUCKET>/ # More threads / Больше потоков

### Verify Upload

gsutil ls -L gs://<BUCKET>/file.txt            # Check file / Проверить файл
gsutil hash file.txt                           # Local hash / Локальный хэш
gsutil hash gs://<BUCKET>/file.txt             # Remote hash / Удалённый хэш

### Debug Mode

gsutil -D cp file.txt gs://<BUCKET>/           # Debug output / Отладочный вывод
gsutil -d rsync /data gs://<BUCKET>/data       # Verbose rsync / Подробная синхронизация

### Performance

gsutil perfdiag -n 100 -s 1M gs://<BUCKET>     # Performance test / Тест производительности
gsutil -o "GSUtil:sliced_object_download_threshold=100M" cp gs://<BUCKET>/large-file . # Sliced download / Разбитое скачивание
