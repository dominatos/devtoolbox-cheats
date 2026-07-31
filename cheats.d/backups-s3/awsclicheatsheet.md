Title: 🗄️ aws-cli — AWS S3 Backups
Group: Backups & S3
Icon: 🗄️
Order: 9

## Table of Contents
- [Installation & Configuration](#Installation%20&%20Configuration)
- [S3 Bucket Operations](#S3%20Bucket%20Operations)
- [Upload & Download](#Upload%20&%20Download)
- [Sync Operations](#Sync%20Operations)
- [Storage Classes](#Storage%20Classes)
- [Lifecycle Policies](#Lifecycle%20Policies)
- [Versioning & Encryption](#Versioning%20&%20Encryption)
- [Multipart Uploads](#Multipart%20Uploads)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Troubleshooting](#Troubleshooting)

---

## Installation & Configuration

### Install / Установить

```bash
# Debian/Ubuntu
apt install awscli                              # Install AWS CLI v1 / Установить AWS CLI v1

# RHEL/AlmaLinux/Rocky
dnf install awscli                              # Install AWS CLI v1 / Установить AWS CLI v1

# Via pip (v2 recommended) / Через pip (рекомендуется v2)
pip3 install awscli                             # Install via pip / Установить через pip

# AWS CLI v2 (official binary) / Официальный бинарник v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
aws --version                                   # Verify installation / Проверить установку
```

### Configure / Настроить

```bash
aws configure                                   # Interactive setup / Интерактивная настройка
# AWS Access Key ID:     <ACCESS_KEY>
# AWS Secret Access Key: <SECRET_KEY>
# Default region:        <REGION>       # e.g. eu-west-1
# Default output:        json

aws configure list                              # Show current config / Показать текущую конфигурацию
aws configure get region                        # Get specific value / Получить конкретное значение
```

### Profiles / Профили

```bash
aws configure --profile production              # Create profile / Создать профиль
aws s3 ls --profile production                  # Use profile / Использовать профиль
export AWS_PROFILE=production                   # Set default profile / Установить профиль по умолчанию
```

### Configuration Files / Файлы конфигурации

```bash
~/.aws/credentials    # Access keys / Ключи доступа
~/.aws/config         # Region, output, profiles / Регион, формат вывода, профили
```

### Environment Variables / Переменные окружения

```bash
export AWS_ACCESS_KEY_ID=<ACCESS_KEY>           # Access key / Ключ доступа
export AWS_SECRET_ACCESS_KEY=<SECRET_KEY>       # Secret key / Секретный ключ
export AWS_DEFAULT_REGION=<REGION>              # Default region / Регион по умолчанию
```

---

## S3 Bucket Operations

### Create Bucket / Создать bucket

```bash
aws s3 mb s3://<BUCKET>                         # Make bucket / Создать bucket
aws s3 mb s3://<BUCKET> --region <REGION>       # Specific region / Конкретный регион
```

### List Buckets / Список buckets

```bash
aws s3 ls                                       # List all buckets / Список всех buckets
aws s3 ls s3://<BUCKET>                         # List objects / Список объектов
aws s3 ls s3://<BUCKET>/path/                   # List specific prefix / Список по префиксу
```

### Delete Bucket / Удалить bucket

> [!WARNING]
> `--force` deletes all objects in the bucket first, then removes the bucket. This is irreversible.

```bash
aws s3 rb s3://<BUCKET>                         # Remove empty bucket / Удалить пустой bucket
aws s3 rb s3://<BUCKET> --force                 # Force delete with all objects / Принудительно удалить
```

---

## Upload & Download

### Upload (put) / Загрузить

```bash
aws s3 cp file.txt s3://<BUCKET>/               # Upload file / Загрузить файл
aws s3 cp /data s3://<BUCKET>/data --recursive  # Upload directory / Загрузить директорию
aws s3 cp file.txt s3://<BUCKET>/ --storage-class GLACIER  # To Glacier / В Glacier
```

### Download (get) / Скачать

```bash
aws s3 cp s3://<BUCKET>/file.txt .              # Download file / Скачать файл
aws s3 cp s3://<BUCKET>/data /restore --recursive  # Download directory / Скачать директорию
```

### Move & Remove / Переместить и удалить

> [!CAUTION]
> `aws s3 rm --recursive` deletes all objects under a prefix immediately with no confirmation.

```bash
aws s3 mv file.txt s3://<BUCKET>/               # Move file / Переместить файл
aws s3 rm s3://<BUCKET>/file.txt                # Delete file / Удалить файл
aws s3 rm s3://<BUCKET>/path --recursive        # Delete directory / Удалить директорию
```

---

## Sync Operations

### Sync Local → S3 / Синхронизация в S3

```bash
aws s3 sync /data s3://<BUCKET>/data            # Sync to S3 / Синхронизация в S3
aws s3 sync /data s3://<BUCKET>/data --delete   # Delete files removed locally / Удалить удалённые
```

### Sync S3 → Local / Синхронизация из S3

```bash
aws s3 sync s3://<BUCKET>/data /restore         # Sync from S3 / Синхронизация из S3
```

### Advanced Sync / Расширенная синхронизация

```bash
aws s3 sync /data s3://<BUCKET>/ \
  --exclude "*.tmp" \
  --exclude ".cache/*"                          # With excludes / С исключениями

aws s3 sync /data s3://<BUCKET>/ \
  --include "*.jpg" \
  --include "*.png" \
  --exclude "*"                                 # Include only images / Только изображения

aws s3 sync /data s3://<BUCKET>/ --dryrun       # Preview changes / Предварительный просмотр
```

---

## Storage Classes

### Storage Class Comparison / Сравнение классов хранения

| Class | Description / Описание | Min Duration | Use Case |
|-------|------------------------|--------------|----------|
| `STANDARD` | Frequent access / Частый доступ | None | Active data |
| `STANDARD_IA` | Infrequent access / Нечастый доступ | 30 days | Monthly backups |
| `INTELLIGENT_TIERING` | Auto-tiering / Авто-градация | None | Unknown access pattern |
| `GLACIER_IR` | Archive, instant retrieval / Архив мгновенного доступа | 90 days | Quarterly backups |
| `GLACIER` | Archive, 1–5h retrieval / Архив, извлечение 1–5ч | 90 days | Long-term archive |
| `DEEP_ARCHIVE` | Cheapest, 12h retrieval / Дешевейший, 12ч доступ | 180 days | Compliance, rarely accessed |

### Set Storage Class on Upload / Установить класс при загрузке

```bash
aws s3 cp file.txt s3://<BUCKET>/ --storage-class STANDARD_IA  # IA class / IA класс
aws s3 cp file.txt s3://<BUCKET>/ --storage-class GLACIER       # Glacier / Glacier
```

### Change Storage Class / Изменить класс хранения

```bash
aws s3api copy-object \
  --copy-source <BUCKET>/file.txt \
  --key file.txt \
  --bucket <BUCKET> \
  --storage-class GLACIER                       # Move existing object to Glacier / Переместить в Glacier
```

---

## Lifecycle Policies

### Apply Lifecycle Rule / Применить правило lifecycle

```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket <BUCKET> \
  --lifecycle-configuration file://lifecycle.json  # Apply policy / Применить политику
```

`/tmp/lifecycle.json`

```json
{
  "Rules": [
    {
      "Id": "AutoTierAndExpire",
      "Status": "Enabled",
      "Transitions": [
        { "Days": 30,  "StorageClass": "STANDARD_IA" },
        { "Days": 90,  "StorageClass": "GLACIER" }
      ],
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
```

### View Lifecycle / Просмотр lifecycle

```bash
aws s3api get-bucket-lifecycle-configuration --bucket <BUCKET>  # Get lifecycle / Получить lifecycle
```

---

## Versioning & Encryption

### Enable Versioning / Включить версионирование

```bash
aws s3api put-bucket-versioning \
  --bucket <BUCKET> \
  --versioning-configuration Status=Enabled    # Enable / Включить

aws s3api get-bucket-versioning --bucket <BUCKET>   # Check status / Проверить статус
aws s3api list-object-versions --bucket <BUCKET>    # List versions / Список версий
```

### Enable Server-Side Encryption / Включить шифрование

```bash
aws s3api put-bucket-encryption \
  --bucket <BUCKET> \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'                                            # Enable AES256 SSE / Включить AES256

aws s3api get-bucket-encryption --bucket <BUCKET>   # Check encryption / Проверить шифрование
```

---

## Multipart Uploads

### How It Works / Принцип работы

> AWS CLI automatically uses multipart upload for files > 8 MB. Use `aws s3api` for manual control.

```bash
aws s3 cp large-file.iso s3://<BUCKET>/         # Auto multipart / Авто multipart (>8MB)
```

### Manual Multipart / Ручная загрузка по частям

```bash
# 1. Initiate upload / Инициировать загрузку
aws s3api create-multipart-upload --bucket <BUCKET> --key large-file.iso

# 2. Upload parts / Загрузить части
aws s3api upload-part \
  --bucket <BUCKET> --key large-file.iso \
  --part-number 1 --body part1 \
  --upload-id <UPLOAD_ID>

# 3. Complete upload / Завершить загрузку
aws s3api complete-multipart-upload \
  --bucket <BUCKET> --key large-file.iso \
  --upload-id <UPLOAD_ID> \
  --multipart-upload file://parts.json

# List incomplete uploads / Список незавершённых
aws s3api list-multipart-uploads --bucket <BUCKET>

# Abort upload / Прервать загрузку
aws s3api abort-multipart-upload \
  --bucket <BUCKET> --key large-file.iso \
  --upload-id <UPLOAD_ID>
```

---

## Sysadmin Operations

### Automated Backup Script / Автоматический скрипт бэкапа

`/usr/local/bin/s3-backup.sh`

```bash
#!/bin/bash
# S3 daily backup with 30-day rolling cleanup
# / Ежедневный бэкап в S3 с ротацией 30 дней

set -euo pipefail

BUCKET="<BUCKET>"
SOURCE="/data"
DATE=$(date +%Y%m%d)
LOG="/var/log/s3-backup.log"

echo "$(date): Starting backup of $SOURCE → s3://$BUCKET/backups/$DATE/" >> "$LOG"

# Sync to S3 / Синхронизация в S3
aws s3 sync "$SOURCE" "s3://$BUCKET/backups/$DATE/" \
  --storage-class STANDARD_IA \
  --exclude "*.tmp" \
  --exclude ".cache/*" >> "$LOG" 2>&1

# Remove old backups (>30 days) / Удалить старые бэкапы (>30 дней)
aws s3 ls "s3://$BUCKET/backups/" | while read -r line; do
  backup_date=$(echo "$line" | awk '{print $2}' | tr -d '/')
  if [[ -n "$backup_date" ]] && \
     [[ $(date -d "$backup_date" +%s 2>/dev/null) -lt $(date -d "30 days ago" +%s) ]]; then
    echo "$(date): Removing old backup: $backup_date" >> "$LOG"
    aws s3 rm "s3://$BUCKET/backups/$backup_date" --recursive >> "$LOG" 2>&1
  fi
done

echo "$(date): Backup complete." >> "$LOG"
```

```bash
chmod +x /usr/local/bin/s3-backup.sh
```

### IAM Policy for Backup User / IAM политика для пользователя бэкапа

`/tmp/s3-backup-policy.json`

```json
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
```

### Cron Schedule / Расписание cron

`/etc/cron.d/s3-backup`

```
# S3 daily backup at 02:00 / Ежедневный бэкап в S3 в 02:00
0 2 * * * root /usr/local/bin/s3-backup.sh
```

### Logrotate Configuration / Конфигурация logrotate

`/etc/logrotate.d/s3-backup`

```
/var/log/s3-backup.log {
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
# Error: "AccessDenied" / "Доступ запрещён"
aws iam get-user                                # Verify credentials / Проверить учётные данные
aws iam list-attached-user-policies --user-name <USER>  # Check policies / Проверить политики

# Error: "NoSuchBucket" / "Bucket не существует"
aws s3 ls                                       # List all buckets / Список всех buckets
aws s3 mb s3://<BUCKET>                         # Create bucket / Создать bucket

# Slow transfers / Медленные передачи
aws configure set default.s3.max_concurrent_requests 20  # Increase concurrency / Увеличить параллелизм
aws configure set default.s3.multipart_threshold 64MB    # Adjust multipart threshold / Порог multipart
```

### Verify Upload / Проверить загрузку

```bash
aws s3 ls s3://<BUCKET>/file.txt               # Check existence / Проверить существование
aws s3api head-object --bucket <BUCKET> --key file.txt  # Get metadata / Получить метаданные
```

### Debug Mode / Режим отладки

```bash
aws s3 ls --debug                               # Full debug log / Полный отладочный лог
aws s3 sync /data s3://<BUCKET>/ --dryrun       # Dry run / Пробный запуск
```

### Performance Tuning / Настройка производительности

```bash
aws configure set default.s3.max_concurrent_requests 50  # Max concurrent / Макс параллельных
aws configure set default.s3.multipart_chunk_size 16MB   # Chunk size / Размер части
aws configure set default.s3.max_bandwidth 100MB/s        # Bandwidth limit / Ограничение пропускной способности
```

## Documentation

- **AWS CLI Documentation:** https://docs.aws.amazon.com/cli/latest/reference/
- **AWS CLI User Guide:** https://docs.aws.amazon.com/cli/latest/userguide/
- **S3 CLI Reference:** https://docs.aws.amazon.com/cli/latest/reference/s3/

#backups #s3 #sysadmin #linux
