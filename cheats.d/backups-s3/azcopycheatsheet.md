Title: 🗄️ azcopy — Azure Blob Storage
Group: Backups & S3
Icon: 🗄️
Order: 11

## Table of Contents
- [Installation & Authentication](#installation--authentication)
- [Copy Operations](#copy-operations)
- [Sync Operations](#sync-operations)
- [Storage Tiers](#storage-tiers)
- [Blob Lifecycle](#blob-lifecycle)
- [Performance Tuning](#performance-tuning)
- [Benchmark Mode](#benchmark-mode)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation & Authentication

### Install

# Linux
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
mv azcopy_linux_amd64_*/azcopy /usr/local/bin/
chmod +x /usr/local/bin/azcopy

azcopy --version                               # Check version / Проверить версию

### Authentication

#### SAS Token

export AZCOPY_SPA_CLIENT_SECRET=<SAS_TOKEN>    # Use SAS token / Использовать SAS токен
# Or pass in URL / Или передать в URL
azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>?<SAS_TOKEN>"

#### Azure AD

azcopy login                                   # Interactive login / Интерактивный вход
azcopy login --tenant-id <TENANT_ID>           # Specific tenant / Конкретный tenant

#### Managed Identity

azcopy login --identity                        # System-assigned identity / Системная идентичность
azcopy login --identity --identity-client-id <CLIENT_ID> # User-assigned / Пользовательская

### Logout

azcopy logout                                  # Logout / Выход

---

## Copy Operations

### Upload

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" # Upload file / Загрузить файл
azcopy copy "/data/*" "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" # Upload directory / Загрузить директорию
azcopy copy "/data" "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" --recursive # Recursive upload / Рекурсивная загрузка

### Download

azcopy copy "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/file .txt" . # Download file / Скачать файл
azcopy copy "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/*" /restore # Download directory / Скачать директорию
azcopy copy "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>" /restore --recursive # Recursive download / Рекурсивное скачивание

### Copy Between Storage Accounts

azcopy copy \
  "https://<SRC_ACCOUNT>.blob.core.windows.net/<CONTAINER>/*" \
  "https://<DST_ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --recursive                                  # Copy between accounts / Копировать между аккаунтами

---

## Sync Operations

### Sync Local → Azure

azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" # Sync to Azure / Синхронизация в Azure
azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" --delete-destination=true # Delete removed files / Удалить удалённые файлы

### Sync Azure → Local

azcopy sync "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" /restore # Sync from Azure / Синхронизация из Azure

### Advanced Sync

azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --exclude-pattern "*.tmp;*.log"              # With excludes / С исключениями

azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --include-pattern "*.jpg;*.png"              # Include only images / Только изображения

---

## Storage Tiers

### Available Tiers

# Hot — Frequent access / Частый доступ
# Cool — Infrequent access / Нечастый доступ
# Archive — Long-term storage / Долгосрочное хранилище

### Set Tier on Upload

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --blob-type BlockBlob \
  --block-blob-tier Hot                        # Upload to Hot tier / Загрузить в Hot tier

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-blob-tier Cool                       # Upload to Cool tier / Загрузить в Cool tier

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-blob-tier Archive                    # Upload to Archive tier / Загрузить в Archive tier

---

## Blob Lifecycle

### Lifecycle Policy (via Azure CLI)

# Install Azure CLI / Установить Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create lifecycle policy / Создать политику lifecycle
az storage account management-policy create \
  --account-name <ACCOUNT> \
  --policy @policy.json \
  --resource-group <RESOURCE_GROUP>

#### policy.json Example

{
  "rules": [
    {
      "enabled": true,
      "name": "moveToCool",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"]
        }
      }
    }
  ]
}

---

## Performance Tuning

### Concurrency & Parallelism

azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --recursive \
  --cap-mbps 100                               # Limit bandwidth to 100 Mbps / Ограничить до 100 Мбит/с

### Block Size

azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-size-mb 16                           # 16MB blocks / Блоки по 16МБ

### Performance Settings

export AZCOPY_CONCURRENCY_VALUE=32             # 32 concurrent operations / 32 параллельных операции
export AZCOPY_BUFFER_GB=4                      # 4GB buffer / Буфер 4ГБ

---

## Benchmark Mode

azcopy bench "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --file-count 100 \
  --size-per-file 10M                          # Benchmark upload / Тест загрузки

azcopy bench "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --mode Download \
  --file-count 100                             # Benchmark download / Тест скачивания

---

## Sysadmin Operations

### Automated Backup Script

#!/bin/bash
# /usr/local/bin/azure-backup.sh

ACCOUNT="<ACCOUNT>"
CONTAINER="<CONTAINER>"
SOURCE="/data"
DATE=$(date +%Y%m%d)

# Login with managed identity / Вход с managed identity
azcopy login --identity

# Sync to Azure / Синхронизация в Azure
azcopy sync $SOURCE "https://$ACCOUNT.blob.core.windows.net/$CONTAINER/backups/$DATE/" \
  --delete-destination=true \
  --block-blob-tier Cool

# Log completion / Лог завершения
echo "$(date): Backup completed" >> /var/log/azure-backup.log

### Systemd Service

#### /etc/systemd/system/azure-backup.service

[Unit]
Description=Azure Blob Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/azure-backup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

#### /etc/systemd/system/azure-backup.timer

[Unit]
Description=Azure Backup Timer
Requires=azure-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

### Environment Variables

export AZCOPY_LOG_LOCATION=/var/log/azcopy     # Log location / Расположение логов
export AZCOPY_JOB_PLAN_LOCATION=/var/azcopy/plans # Job plan location / Расположение планов задач
export AZCOPY_CONCURRENCY_VALUE=16             # Concurrency / Параллелизм
export AZCOPY_BUFFER_GB=2                      # Buffer size / Размер буфера

### Configuration

~/.azcopy/                                     # Config directory / Директория конфигурации

---

## Troubleshooting

### Common Errors

# "Failed to perform copy command" / "Не удалось выполнить команду копирования"
azcopy login                                   # Re-authenticate / Переаутентификация
# Check SAS token expiration / Проверить срок действия SAS токена

# "403 Forbidden" / "403 Запрещено"
# Check storage account permissions / Проверить права доступа к учётной записи хранилища
# Verify firewall rules / Проверить правила файрвола

# Slow transfers / Медленные передачи
export AZCOPY_CONCURRENCY_VALUE=32             # Increase concurrency / Увеличить параллелизм
azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" --cap-mbps 0 # Remove bandwidth limit / Убрать ограничение пропускной способности

### Resume Failed Jobs

azcopy jobs list                               # List jobs / Список задач
azcopy jobs show <JOB_ID>                      # Show job details / Показать детали задачи
azcopy jobs resume <JOB_ID>                    # Resume job / Возобновить задачу
azcopy jobs remove <JOB_ID>                    # Remove job / Удалить задачу

### Dry Run

azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --dry-run                                    # Simulate operation / Симуляция операции

### Debug & Logging

azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --log-level=DEBUG                            # Debug logging / Отладочные логи

tail -f ~/.azcopy/*.log                        # View logs / Просмотр логов

### Performance Analysis

azcopy jobs show <JOB_ID> --with-status=All    # Show all file statuses / Показать все статусы файлов
