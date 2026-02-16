Title: 🗄️ aws-cli — AWS S3 Backups
Group: Backups & S3
Icon: 🗄️
Order: 9

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [S3 Bucket Operations](#s3-bucket-operations)
- [Upload & Download](#upload--download)
- [Sync Operations](#sync-operations)
- [Storage Classes](#storage-classes)
- [Lifecycle Policies](#lifecycle-policies)
- [Versioning & Encryption](#versioning--encryption)
- [Multipart Uploads](#multipart-uploads)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Configuration

### Install

# Debian/Ubuntu
apt install awscli                             # Install AWS CLI / Установить AWS CLI

# RHEL/AlmaLinux/Rocky
dnf install awscli                             # Install AWS CLI / Установить AWS CLI

# Using pip / Используя pip
pip3 install awscli                            # Install via pip / Установить через pip

### Configure

aws configure                                  # Interactive config / Интерактивная настройка
# AWS Access Key ID: <ACCESS_KEY>
# AWS Secret Access Key: <SECRET_KEY>
# Default region: us-east-1
# Default output: json

aws configure list                             # Show config / Показать конфигурацию
aws configure get region                       # Get specific value / Получить конкретное значение

### Profiles

aws configure --profile production             # Create profile / Создать профиль
aws s3 ls --profile production                 # Use profile / Использовать профиль
export AWS_PROFILE=production                  # Set default profile / Установить профиль по умолчанию

---

## S3 Bucket Operations

### Create Bucket

aws s3 mb s3://<BUCKET>                        # Make bucket / Создать bucket
aws s3 mb s3://<BUCKET> --region us-west-2     # Specific region / Конкретный регион

### List Buckets

aws s3 ls                                      # List buckets / Список buckets
aws s3 ls s3://<BUCKET>                        # List objects / Список объектов
aws s3 ls s3://<BUCKET>/path/                  # List path / Список по пути

### Delete Bucket

aws s3 rb s3://<BUCKET>                        # Remove bucket (empty) / Удалить bucket (пустой)
aws s3 rb s3://<BUCKET> --force                # Force delete / Принудительно удалить

---

## Upload & Download

### Upload (Put)

aws s3 cp file.txt s3://<BUCKET>/              # Upload file / Загрузить файл
aws s3 cp /data s3://<BUCKET>/data --recursive # Upload directory / Загрузить директорию
aws s3 cp file.txt s3://<BUCKET>/ --storage-class GLACIER # To Glacier / В Glacier

### Download (Get)

aws s3 cp s3://<BUCKET>/file.txt .             # Download file / Скачать файл
aws s3 cp s3://<BUCKET>/data /restore --recursive # Download directory / Скачать директорию

### Move & Remove

aws s3 mv file.txt s3://<BUCKET>/              # Move file / Переместить файл
aws s3 rm s3://<BUCKET>/file.txt               # Delete file / Удалить файл
aws s3 rm s3://<BUCKET>/path --recursive       # Delete directory / Удалить директорию

---

## Sync Operations

### Sync Local → S3

aws s3 sync /data s3://<BUCKET>/data           # Sync to S3 / Синхронизация в S3
aws s3 sync /data s3://<BUCKET>/data --delete  # Delete removed files / Удалить удалённые файлы

### Sync S3 → Local

aws s3 sync s3://<BUCKET>/data /restore        # Sync from S3 / Синхронизация из S3

### Advanced Sync

aws s3 sync /data s3://<BUCKET>/ \
  --exclude "*.tmp" \
  --exclude ".cache/*"                         # With excludes / С исключениями

aws s3 sync /data s3://<BUCKET>/ \
  --include "*.jpg" \
  --include "*.png" \
  --exclude "*"                                # Include only images / Только изображения

---

## Storage Classes

### Available Classes

# STANDARD — Default, frequent access / По умолчанию, частый доступ
# STANDARD_IA — Infrequent Access / Нечастый доступ
# INTELLIGENT_TIERING — Auto-tiering / Автоматическая градация
# GLACIER — Archive / Архив
# GLACIER_IR — Instant Retrieval / Мгновенное извлечение
# DEEP_ARCHIVE — Long-term archive / Долгосрочный архив

### Set Storage Class

aws s3 cp file.txt s3://<BUCKET>/ --storage-class STANDARD_IA # Upload to IA / Загрузить в IA
aws s3 cp file.txt s3://<BUCKET>/ --storage-class GLACIER     # Upload to Glacier / Загрузить в Glacier

### Change Storage Class

aws s3api copy-object \
  --copy-source <BUCKET>/file.txt \
  --key file.txt \
  --bucket <BUCKET> \
  --storage-class GLACIER                      # Move to Glacier / Переместить в Glacier

---

## Lifecycle Policies

### Create Lifecycle Rule

aws s3api put-bucket-lifecycle-configuration \
  --bucket <BUCKET> \
  --lifecycle-configuration file://lifecycle.json

#### lifecycle.json Example

{
  "Rules": [
    {
      "Id": "Move to IA after 30 days",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    }
  ]
}

### View Lifecycle

aws s3api get-bucket-lifecycle-configuration --bucket <BUCKET> # Get lifecycle / Получить lifecycle

---

## Versioning & Encryption

### Enable Versioning

aws s3api put-bucket-versioning \
  --bucket <BUCKET> \
  --versioning-configuration Status=Enabled    # Enable versioning / Включить версионирование

aws s3api get-bucket-versioning --bucket <BUCKET> # Check versioning / Проверить версионирование

### List Versions

aws s3api list-object-versions --bucket <BUCKET> # List versions / Список версий

### Enable Encryption

aws s3api put-bucket-encryption \
  --bucket <BUCKET> \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'                                           # Enable AES256 encryption / Включить AES256 шифрование

aws s3api get-bucket-encryption --bucket <BUCKET> # Check encryption / Проверить шифрование

---

## Multipart Uploads

### Automatic Multipart

# AWS CLI automatically uses multipart for files > 8MB / AWS CLI автоматически использует multipart для файлов > 8МБ
aws s3 cp large-file.iso s3://<BUCKET>/        # Auto multipart / Авто multipart

### Manual Multipart

# Initiate / Инициировать
aws s3api create-multipart-upload --bucket <BUCKET> --key large-file.iso

# Upload parts / Загрузить части
aws s3api upload-part --bucket <BUCKET> --key large-file.iso --part-number 1 --body part1 --upload-id <UPLOAD_ID>

# Complete / Завершить
aws s3api complete-multipart-upload --bucket <BUCKET> --key large-file.iso --upload-id <UPLOAD_ID> --multipart-upload file://parts.json

### List Incomplete Uploads

aws s3api list-multipart-uploads --bucket <BUCKET> # List incomplete / Список незавершённых

### Abort Upload

aws s3api abort-multipart-upload --bucket <BUCKET> --key large-file.iso --upload-id <UPLOAD_ID> # Abort / Прервать

---

## Sysadmin Operations

### Automated Backup Script

#!/bin/bash
# /usr/local/bin/s3-backup.sh

BUCKET="<BUCKET>"
SOURCE="/data"
DATE=$(date +%Y%m%d)

# Sync to S3 / Синхронизация в S3
aws s3 sync $SOURCE s3://$BUCKET/backups/$DATE/ \
  --storage-class STANDARD_IA \
  --exclude "*.tmp" \
  --exclude ".cache/*"

# Remove old backups (>30 days) / Удалить старые бэкапы (>30 дней)
aws s3 ls s3://$BUCKET/backups/ | while read -r line; do
  backup_date=$(echo $line | cut -d' ' -f2)
  if [[ $(date -d "$backup_date" +%s) -lt $(date -d "30 days ago" +%s) ]]; then
    aws s3 rm s3://$BUCKET/backups/$backup_date --recursive
  fi
done

### IAM Policies for Backup User

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::<BUCKET>/*",
        "arn:aws:s3:::<BUCKET>"
      ]
    }
  ]
}

### Environment Variables

export AWS_ACCESS_KEY_ID=<ACCESS_KEY>          # Access key / Ключ доступа
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>      # Secret key / Секретный ключ
export AWS_DEFAULT_REGION=us-east-1            # Default region / Регион по умолчанию

### Configuration Files

~/.aws/credentials                             # Credentials file / Файл учётных данных
~/.aws/config                                  # Config file / Файл конфигурации

---

## Troubleshooting

### Common Errors

# "AccessDenied" / "Доступ запрещён"
aws iam get-user                               # Verify credentials / Проверить учётные данные
# Check IAM policies / Проверить IAM политики

# "NoSuchBucket" / "Bucket не существует"
aws s3 ls                                      # List buckets / Список buckets
aws s3 mb s3://<BUCKET>                        # Create bucket / Создать bucket

# Slow transfers / Медленные передачи
aws configure set default.s3.max_concurrent_requests 20 # Increase concurrency / Увеличить параллелизм
aws configure set default.s3.multipart_threshold 64MB   # Adjust multipart threshold / Настроить порог multipart

### Verify Upload

aws s3 ls s3://<BUCKET>/file.txt               # Check file exists / Проверить существование файла
aws s3api head-object --bucket <BUCKET> --key file.txt # Get metadata / Получить метаданные

### Debug Mode

aws s3 ls --debug                              # Debug output / Отладочный вывод
aws s3 sync /data s3://<BUCKET>/ --dryrun      # Dry run / Пробный запуск

### Performance Tuning

aws configure set default.s3.max_concurrent_requests 50 # Max concurrent / Макс параллельных
aws configure set default.s3.multipart_chunk_size 16MB  # Chunk size / Размер части
aws configure set default.s3.max_bandwidth 100MB/s      # Bandwidth limit / Ограничение пропускной способности
