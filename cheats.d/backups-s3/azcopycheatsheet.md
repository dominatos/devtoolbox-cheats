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

### Install / Установить

```bash
# Linux amd64 / Linux amd64
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
mv azcopy_linux_amd64_*/azcopy /usr/local/bin/
chmod +x /usr/local/bin/azcopy

azcopy --version                                # Verify install / Проверить установку
```

### Authentication Methods / Методы аутентификации

| Method | Description / Описание | Best For |
|--------|------------------------|----------|
| SAS Token | URL-scoped time-limited token | Scripts, CI/CD |
| Azure AD (interactive) | Login via browser | Manual use |
| Service Principal | App registration | Automated jobs |
| Managed Identity | No credentials in code | Azure VMs / AKS |

#### SAS Token / SAS токен

```bash
# Pass SAS token in URL / Передать SAS токен в URL
azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>?<SAS_TOKEN>"
```

#### Azure AD Interactive / Интерактивный вход через Azure AD

```bash
azcopy login                                    # Interactive login / Интерактивный вход
azcopy login --tenant-id <TENANT_ID>            # Specific tenant / Конкретный tenant
```

#### Managed Identity / Managed Identity

```bash
azcopy login --identity                         # System-assigned identity / Системная идентичность
azcopy login --identity --identity-client-id <CLIENT_ID>  # User-assigned / Пользовательская
```

```bash
azcopy logout                                   # Logout / Выход
```

---

## Copy Operations

### Upload / Загрузить

```bash
# Single file / Один файл
azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/"

# Directory (recursive) / Директория (рекурсивно)
azcopy copy "/data" "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" --recursive
```

### Download / Скачать

```bash
# Single file / Один файл
azcopy copy "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/file.txt" .

# Directory / Директория
azcopy copy "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>" /restore --recursive
```

### Copy Between Storage Accounts / Копировать между аккаунтами

```bash
azcopy copy \
  "https://<SRC_ACCOUNT>.blob.core.windows.net/<CONTAINER>/*" \
  "https://<DST_ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --recursive                                   # Server-side copy / Копирование на стороне сервера
```

> [!TIP]
> Server-side copy between storage accounts does not consume local bandwidth — data moves directly in Azure.

---

## Sync Operations

### Sync Local → Azure / Синхронизация в Azure

```bash
azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/"
azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --delete-destination=true                     # Delete removed files / Удалить удалённые файлы
```

### Sync Azure → Local / Синхронизация из Azure

```bash
azcopy sync "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" /restore
```

### Advanced Sync / Расширенная синхронизация

```bash
azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --exclude-pattern "*.tmp;*.log"               # Exclude patterns / Исключить паттерны

azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --include-pattern "*.jpg;*.png"               # Include only images / Только изображения

azcopy sync /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --dry-run                                     # Preview changes / Предпросмотр изменений
```

---

## Storage Tiers

### Tier Comparison / Сравнение уровней

| Tier | Access Frequency | Min Duration | Storage Cost | Access Cost |
|------|-----------------|--------------|-------------|-------------|
| **Hot** | Frequent / Частый | None | High / Высокая | Low / Низкая |
| **Cool** | ~1×/month / ~1×/месяц | 30 days | Medium / Средняя | Medium / Средняя |
| **Cold** | ~1×/quarter / ~1×/квартал | 90 days | Low / Низкая | High / Высокая |
| **Archive** | Rarely / Редко | 180 days | Very low / Очень низкая | Very high + rehydration delay |

### Set Tier on Upload / Установить уровень при загрузке

```bash
azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --blob-type BlockBlob --block-blob-tier Hot   # Hot tier / Hot уровень

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-blob-tier Cool                        # Cool tier / Cool уровень

azcopy copy file.txt "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-blob-tier Archive                     # Archive tier / Archive уровень
```

---

## Blob Lifecycle

### Install Azure CLI / Установить Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | bash  # Install Azure CLI / Установить Azure CLI
az login                                            # Log in / Войти
```

### Create Lifecycle Policy / Создать политику lifecycle

```bash
az storage account management-policy create \
  --account-name <ACCOUNT> \
  --policy @policy.json \
  --resource-group <RESOURCE_GROUP>
```

`/tmp/policy.json`

```json
{
  "rules": [
    {
      "enabled": true,
      "name": "autoTierAndDelete",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool":    { "daysAfterModificationGreaterThan": 30  },
            "tierToArchive": { "daysAfterModificationGreaterThan": 90  },
            "delete":        { "daysAfterModificationGreaterThan": 365 }
          }
        },
        "filters": { "blobTypes": ["blockBlob"] }
      }
    }
  ]
}
```

---

## Performance Tuning

### Concurrency & Parallelism / Параллелизм

```bash
azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --recursive --cap-mbps 100                    # Limit to 100 Mbps / Ограничить до 100 Мбит/с
```

### Block Size / Размер блока

```bash
azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --block-size-mb 16                            # 16 MB blocks / Блоки по 16 МБ
```

### Performance Environment Variables / Переменные производительности

```bash
export AZCOPY_CONCURRENCY_VALUE=32              # 32 concurrent operations / 32 параллельных
export AZCOPY_BUFFER_GB=4                       # 4 GB buffer / Буфер 4 ГБ
```

---

## Benchmark Mode

```bash
# Benchmark upload / Тест производительности загрузки
azcopy bench "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --file-count 100 --size-per-file 10M

# Benchmark download / Тест скачивания
azcopy bench "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --mode Download --file-count 100
```

---

## Sysadmin Operations

### Automated Backup Script / Автоматический скрипт бэкапа

`/usr/local/bin/azure-backup.sh`

```bash
#!/bin/bash
# Azure Blob daily backup using Managed Identity
# / Ежедневный бэкап в Azure Blob с Managed Identity

set -euo pipefail

ACCOUNT="<ACCOUNT>"
CONTAINER="<CONTAINER>"
SOURCE="/data"
DATE=$(date +%Y%m%d)
LOG="/var/log/azure-backup.log"

echo "$(date): Starting Azure backup → $CONTAINER/backups/$DATE/" >> "$LOG"

azcopy login --identity                         # Authenticate via Managed Identity

azcopy sync "$SOURCE" \
  "https://$ACCOUNT.blob.core.windows.net/$CONTAINER/backups/$DATE/" \
  --delete-destination=true \
  --block-blob-tier Cool >> "$LOG" 2>&1

echo "$(date): Azure backup complete." >> "$LOG"
```

```bash
chmod +x /usr/local/bin/azure-backup.sh
```

### Systemd Service / Systemd-сервис

`/etc/systemd/system/azure-backup.service`

```ini
[Unit]
Description=Azure Blob Backup
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
Environment="AZCOPY_LOG_LOCATION=/var/log/azcopy"
Environment="AZCOPY_CONCURRENCY_VALUE=16"
ExecStart=/usr/local/bin/azure-backup.sh
StandardOutput=append:/var/log/azure-backup.log
StandardError=append:/var/log/azure-backup.log

[Install]
WantedBy=multi-user.target
```

### Systemd Timer / Systemd-таймер

`/etc/systemd/system/azure-backup.timer`

```ini
[Unit]
Description=Azure Backup Timer
Requires=azure-backup.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload                         # Reload systemd / Перезагрузить systemd
systemctl enable azure-backup.timer             # Enable / Включить
systemctl start azure-backup.timer              # Start / Запустить
systemctl status azure-backup.timer             # Check status / Проверить статус
```

### Configuration Paths / Пути конфигурации

```bash
~/.azcopy/                                      # User config dir / Директория конфигурации
export AZCOPY_LOG_LOCATION=/var/log/azcopy      # Log dir / Директория логов
export AZCOPY_JOB_PLAN_LOCATION=/var/azcopy/plans  # Job plans / Планы задач
```

### Logrotate / Logrotate

`/etc/logrotate.d/azure-backup`

```
/var/log/azure-backup.log
/var/log/azcopy/*.log {
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
# Error: "Failed to perform copy" — re-authenticate
azcopy login                                    # Re-login / Переаутентификация
# Check SAS token expiration in URL / Проверить срок действия SAS токена

# Error: "403 Forbidden"
# Check storage account firewall rules / Проверить правила брандмауэра
# Verify IAM role: "Storage Blob Data Contributor" / Проверить роль IAM

# Slow transfers / Медленные передачи
export AZCOPY_CONCURRENCY_VALUE=32
azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --cap-mbps 0                                  # Remove bandwidth cap / Убрать ограничение
```

### Resume Failed Jobs / Возобновление прерванных задач

```bash
azcopy jobs list                                # List jobs / Список задач
azcopy jobs show <JOB_ID>                       # Job details / Детали задачи
azcopy jobs resume <JOB_ID>                     # Resume / Возобновить
azcopy jobs remove <JOB_ID>                     # Remove / Удалить
```

### Debug & Logging / Отладка и логи

```bash
azcopy copy /data "https://<ACCOUNT>.blob.core.windows.net/<CONTAINER>/" \
  --log-level=DEBUG                             # Debug logging / Отладочные логи
tail -f ~/.azcopy/*.log                         # View live logs / Просмотр логов
azcopy jobs show <JOB_ID> --with-status=All     # All file statuses / Все статусы файлов
```
