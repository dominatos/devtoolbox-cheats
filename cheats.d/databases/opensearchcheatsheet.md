Title: 🔎 OpenSearch
Group: Databases
Icon: 🔎
Order: 4

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration / Установка и Настройка](#1-installation--configuration--установка-и-настройка)
2. [Cluster Management / Управление Кластером](#2-cluster-management--управление-кластером)
3. [Index Management / Управление Индексами](#3-index-management--управление-индексами)
4. [Document Management / Управление Документами](#4-document-management--управление-документами)
5. [Backup & Restore / Бэкап и Восстановление](#5-backup--restore--бэкап-и-восстановление)
6. [Security / Безопасность](#6-security--безопасность)
7. [Sysadmin Operations / Сисадминские Операции](#7-sysadmin-operations--сисадминские-операции)
8. [Tools / Инструменты](#8-tools--инструменты)
9. [Logrotate Configuration / Конфигурация Logrotate](#9-logrotate-configuration--конфигурация-logrotate)

---

## 1. 📦 Installation & Configuration / Установка и Настройка

### Install / Установка

```bash
env OPENSEARCH_INITIAL_ADMIN_PASSWORD=<PASSWORD> dpkg -i opensearch-2.19.2-linux-x64.deb # Install .deb with admin pass / Установка .deb с паролем
# or / или
tar -zxvf opensearch-1.3.0.tar.gz # Extract archive / Распаковка архива
./opensearch-tar-install.sh # Run installer / Запуск установщика
docker run opensearchproject/opensearch:3.7.0 # Run in Docker / Запуск в Docker
```

### System Tuning / Настройка системы

```bash
# /etc/sysctl.d/99-opensearch.conf
vm.max_map_count = 262144
vm.swappiness = 1
fs.file-max = 262144

# Apply sysctl / Применить sysctl
sysctl --system
```

```bash
# /etc/security/limits.d/99-opensearch.conf
opensearch soft nofile 65536
opensearch hard nofile 65536
opensearch soft nproc  4096
opensearch hard nproc  4096
opensearch soft memlock unlimited
opensearch hard memlock unlimited
```

### Systemd Override / Systemd Переопределение

`systemctl edit opensearch`

```ini
[Service]
LimitNOFILE=65536
LimitNPROC=4096
LimitMEMLOCK=infinity
```

---

## 2. ⚙️ Cluster Management / Управление Кластером

```bash
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/                                   # Ping cluster (version) / Пинг кластера (версия)
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/_cluster/health?pretty             # Cluster health / Здоровье кластера
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/_cat/nodes?v                       # Nodes table / Таблица узлов
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/_cluster/settings                  # View cluster settings / Настройки кластера
```

### Drain Node / Исключение ноды

```bash
# Exclude node by name (drain) / Исключить ноду по имени
curl -XPUT localhost:9200/_cluster/settings -H 'Content-Type: application/json' -d '{
  "transient": { "cluster.routing.allocation.exclude._name": "os-data-1" }
}'

# Check shards on node / Проверить шарды на ноде
curl -s localhost:9200/_cat/shards?v | grep os-data-1 || echo "empty"
```

---

## 3. 🗂️ Index Management / Управление Индексами

### Basics / Основы

```bash
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/_cat/indices?v                     # Indices table / Таблица индексов
curl -sS -u 'admin:<PASSWORD>' -X DELETE http://localhost:9200/my-index                 # Delete index / Удалить индекс

# Create index with settings / Создать индекс с настройками
curl -sS -u 'admin:<PASSWORD>' -X PUT http://localhost:9200/my-index \
  -H 'Content-Type: application/json' \
  -d '{ "settings": {"number_of_shards":1,"number_of_replicas":1} }'

# Show mapping / Показать mapping
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/my-index/_mapping?pretty

# Update mapping (add field) / Обновить mapping (добавить поле)
curl -sS -u 'admin:<PASSWORD>' -X PUT http://localhost:9200/my-index/_mapping \
  -H 'Content-Type: application/json' \
  -d '{ "properties": { "tag": { "type": "keyword" } } }'

# Force merge / Форс-мердж
curl -u 'admin:<PASSWORD>' -X POST "http://localhost:9200/my-index/_forcemerge?max_num_segments=1"
```

### 📘 Reindexing Guide / Руководство по реиндексации

#### 1. Create Destination Index / Создание целевого индекса
```bash
curl -u 'admin:<PASSWORD>' -X PUT "http://localhost:9200/logs-v2" -H 'Content-Type: application/json' -d '{
  "settings": {
    "number_of_shards": 6,
    "number_of_replicas": 0,     // Disable replicas for speed / Без реплик для скорости
    "refresh_interval": "-1"     // Disable refresh for speed / Отключить refresh
  },
  "mappings": { "dynamic": "strict", "properties": { ... } }
}'
```

#### 2. Run Reindex / Запуск
```bash
# Basic / Базовый
curl -u 'admin:<PASSWORD>' -X POST "http://localhost:9200/_reindex?refresh=true" -H 'Content-Type: application/json' -d '{
  "source": { "index": "logs-legacy" },
  "dest":   { "index": "logs-v2" }
}'

# Percentage/Async / Асинхронно
curl -u 'admin:<PASSWORD>' -X POST "http://localhost:9200/_reindex?wait_for_completion=false" ...
```

#### 3. Aliases / Алиасы (Zero Downtime)
```bash
curl -u 'admin:<PASSWORD>' -X POST "http://localhost:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    { "remove": { "alias": "logs", "index": "logs-legacy" } },
    { "add":    { "alias": "logs", "index": "logs-v2", "is_write_index": true } }
  ]
}'
```

---

## 4. 📄 Document Management / Управление Документами

### CRUD

```bash
# Index/Replace (ID=1) / Создать/Заменить (ID=1)
curl -sS -u 'admin:<PASSWORD>' -X POST http://localhost:9200/my-index/_doc/1 \
  -H 'Content-Type: application/json' \
  -d '{ "title":"hello","tag":"demo","ts":"2025-08-27T10:00:00Z" }'

# Get Document / Получить документ
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/my-index/_doc/1

# Partial Update / Частичное обновление
curl -sS -u 'admin:<PASSWORD>' -X POST http://localhost:9200/my-index/_update/1 \
  -H 'Content-Type: application/json' \
  -d '{ "doc": { "tag":"updated" } }'

# Delete Document / Удалить документ
curl -sS -u 'admin:<PASSWORD>' -X DELETE http://localhost:9200/my-index/_doc/1
```

### Search / Поиск

```bash
# Simple Match / Простой поиск
curl -sS -u 'admin:<PASSWORD>' -X POST http://localhost:9200/my-index/_search \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "title": "hello" } }, "size": 5 }'
```

### Bulk / Массовая загрузка

```bash
# bulk.json format / формат
# { "index": { "_index":"my-index","_id":"2" } }
# { "title":"bulk item 2","tag":"demo" }

curl -sS -u 'admin:<PASSWORD>' -X POST http://localhost:9200/_bulk \
  -H 'Content-Type: application/x-ndjson' --data-binary @bulk.json                 # Execute Bulk / Выполнить Bulk
```

---

## 5. 💾 Backup & Restore / Бэкап и Восстановление

### Snapshot Repository / Репозиторий

```bash
# Register FS Repository / Регистрация FS репозитория
curl -X PUT "https://localhost:9200/_snapshot/my_backup_repository" \
     -H "Content-Type: application/json" \
     -u 'admin:<PASSWORD>' --insecure \
     -d '{ "type": "fs", "settings": { "location": "/var/backups/opensearch", "compress": true } }'

# Register S3 Repository / Регистрация S3 репозитория
# Use type "s3" and configure bucket/base_path / Используйте type "s3" и укажите bucket
```

### Snapshots / Снапшоты

```bash
# Create Snapshot / Создать снапшот
curl -X PUT "https://localhost:9200/_snapshot/my_backup_repository/snapshot_$(date +%Y-%m-%d)" \
     -H "Content-Type: application/json" \
     -u 'admin:<PASSWORD>' --insecure \
     -d '{ "indices": "*", "ignore_unavailable": true, "include_global_state": false }'

# List Snapshots / Список снапшотов
curl -sS -u 'admin:<PASSWORD>' http://localhost:9200/_snapshot/my_backup_repository/_all?pretty
```

### Restore / Восстановление

```bash
# Restore All / Восстановить всё
curl -X POST "https://localhost:9200/_snapshot/my_backup_repository/snapshot_DATE/_restore" \
     -u 'admin:<PASSWORD>' --insecure \
     -H 'Content-Type: application/json' \
     -d '{ "indices": "*", "ignore_unavailable": true, "include_global_state": false }'

# Restore with Rename / Восстановить с переименованием
curl -X POST "https://localhost:9200/_snapshot/my_backup_repository/snapshot_DATE/_restore" \
     -u 'admin:<PASSWORD>' --insecure \
     -H 'Content-Type: application/json' \
     -d '{
       "indices": "logs-*",
       "rename_pattern": "^(.*)$",
       "rename_replacement": "restored_$1"
     }'
```

### 🕒 Automation Script / Скрипт автоматизации

```bash
#!/bin/bash
# /usr/local/bin/os-backup.sh
SNAPSHOT_NAME="snapshot_$(date +%Y-%m-%d)"
curl -X PUT "https://localhost:9200/_snapshot/my_backup_repository/$SNAPSHOT_NAME" \
     -H "Content-Type: application/json" -u 'admin:<PASSWORD>' --insecure \
     -d '{ "indices": "*", "ignore_unavailable": true, "include_global_state": false }'
echo "✅ Snapshot $SNAPSHOT_NAME is created"

# Clean old snapshots (example > 7 days) / Очистка старых (> 7 дней)
OLD=$(date -d "-7 days" +%Y-%m-%d)
curl -s -u 'admin:<PASSWORD>' -X DELETE "https://localhost:9200/_snapshot/my_backup_repository/snapshot_${OLD}*"
```

**Cron:**
```bash
0 3 * * * /usr/local/bin/os-backup.sh >> /var/log/opensearch_backup.log 2>&1
```

### 📡 NFS Setup for Shared Repo / Настройка NFS

> **Goal/Цель**: `/mnt/backups` shared across all nodes. / `/mnt/backups` доступен на всех нодах.

**Server (NFS Host):**

```bash
sudo dnf install -y nfs-utils                                       # Install NFS tools / Установка утилит
sudo mkdir -p /mnt/backups && sudo chown opensearch:opensearch /mnt/backups # Create & Chown / Создать и права
echo "/mnt/backups <SUBNET>/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports # Export / Экспорт
sudo exportfs -ra && sudo systemctl enable --now nfs-server         # Apply & Start / Применить и запустить
```

**Clients (OpenSearch Nodes):**

```bash
sudo dnf install -y nfs-utils                                       # Install tools / Установка утилит
sudo mkdir -p /mnt/backups                                          # Create mountpoint / Точка монтирования
# Update /etc/fstab
echo "<NFS_SERVER_IP>:/mnt/backups /mnt/backups nfs rw,noatime,hard,intr,_netdev,nfsvers=4.2 0 0" | sudo tee -a /etc/fstab
sudo mount -a                                                       # Mount / Примонтировать
```

---

## 6. 🔐 Security / Безопасность

### User Management / Управление пользователями

```bash
# Create Read-Only Role / Создать роль (Read-Only)
curl -u 'admin:<PASSWORD>' -X PUT "http://localhost:9200/_plugins/_security/api/roles/ro-logs" \
  -H "Content-Type: application/json" -d '{
  "cluster_permissions": [],
  "index_permissions": [ { "index_patterns": ["logs-*"], "allowed_actions": ["read"] } ] }'

# Create User / Создать пользователя
curl -u 'admin:<PASSWORD>' -X PUT "http://localhost:9200/_plugins/_security/api/internalusers/alice" \
  -H "Content-Type: application/json" -d '{ "password": "<STRONG_PASSWORD>", "backend_roles": [], "description": "RO User" }'

# Map User to Role / Привязать пользователя к роли
curl -u 'admin:<PASSWORD>' -X PUT "http://localhost:9200/_plugins/_security/api/rolesmapping/ro-logs" \
  -H "Content-Type: application/json" -d '{ "users": ["alice"], "backend_roles": [], "hosts": [] }'
```

### Action Groups / Группы действий

| Group | Actions | Desc (RU) |
|---|---|---|
| `read` | search, get, mget | Только чтение |
| `write` | index, update, delete | Запись без поиска |
| `crud` | read + write | Полный доступ к данным |
| `manage` | create/del index, mappings | Управление индексами |
| `all` | everything | Полный доступ |

### Change Admin Password / Смена пароля Admin

```bash
# Using securityadmin.sh (requires certificates) / Через скрипт (нужны сертификаты)
OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk /usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
  -icl -cacert /etc/opensearch/root-ca.pem \
  -cert /etc/opensearch/kirk.pem -key /etc/opensearch/kirk-key.pem \
  -t internalusers -f current-config/internal_users.yml
```

---

## 7. 🐧 Sysadmin Operations / Сисадминские Операции

### Service & Logs / Сервис и Логи

```bash
systemctl start opensearch                                      # Start service / Запустить сервис
systemctl stop opensearch                                       # Stop service / Остановить сервис
systemctl status opensearch                                     # Status / Статус
journalctl -u opensearch -f                                     # Follow service logs / Следить за логами сервиса
tail -f /var/log/opensearch/opensearch.log                      # Follow main log / Следить за основным логом
grep "ERROR" /var/log/opensearch/opensearch.log                 # Find errors / Найти ошибки
```

### Important Paths / Важные Пути

*   **Config**: `/etc/opensearch/opensearch.yml` — Main config / Основной конфиг
*   **JVM**: `/etc/opensearch/jvm.options` — Heap size & GC / Настройки Java
*   **Logs**: `/var/log/opensearch/` — Logs directory / Каталог логов
*   **Data**: `/var/lib/opensearch/` — Data directory (Indices) / Данные (Индексы)
*   **Home**: `/usr/share/opensearch/` — Binary home / Домашняя директория

### JVM Tuning / Настройка JVM

```bash
# Edit /etc/opensearch/jvm.options
-Xms4g
-Xmx4g
# Rule: Set Xms and Xmx to 50% of RAM, but not more than 31GB
# Правило: Ставьте Xms и Xmx = 50% RAM, но не больше 31GB
```

### Network & Firewall / Сеть и Файрвол

```bash
# Ports / Порты
# 9200: REST API (HTTP)
# 9300: Transport (Inter-node communication)

# Firewalld Rules / Правила Firewalld
firewall-cmd --permanent --add-port=9200/tcp
firewall-cmd --permanent --add-port=9300/tcp
firewall-cmd --reload
```

### Keystore / Хранилище секретов

```bash
# List secrets / Список секретов
/usr/share/opensearch/bin/opensearch-keystore list

# Add secret (e.g. s3 keys) / Добавить секрет
/usr/share/opensearch/bin/opensearch-keystore add s3.client.default.access_key
```

### Plugins / Плагины

```bash
# List plugins / Список плагинов
/usr/share/opensearch/bin/opensearch-plugin list

# Install plugin / Установить плагин
/usr/share/opensearch/bin/opensearch-plugin install analysis-icu

# Remove plugin / Удалить плагин
/usr/share/opensearch/bin/opensearch-plugin remove analysis-icu
```

---

## 8. 🛠️ Tools / Инструменты

### cURL Toolbox

```bash
curl -L https://example.com                                       # Follow redirects / Следовать редиректам
curl -H 'Content-Type: application/json' -d @file.json URL        # POST from file / POST из файла
curl -s -o /dev/null -w '%{http_code}\n' URL                      # Print Status Code / Вывести HTTP код
curl -u 'user:pass' --insecure URL                                # Auth & Skip SSL / Авторизация и игнор SSL
curl -s -o /dev/null -w 'dns:%{time_namelookup} total:%{time_total}\n' URL  # Timing / Тайминги
```

### Elasticdump

```bash
# Ignore SSL / Игнорировать SSL
export NODE_TLS_REJECT_UNAUTHORIZED=0

# Export Mapping / Экспорт Mapping
elasticdump --input=https://admin:<PASSWORD>@localhost:9200/my-index --output=mapping.json --type=mapping

# Export Data / Экспорт Данных
elasticdump --input=https://admin:<PASSWORD>@localhost:9200/my-index --output=data.json --type=data

# Import / Импорт
elasticdump --input=data.json --output=https://admin:<PASSWORD>@target:9200/my-index --type=data
```

---

## 9. Logrotate Configuration / Конфигурация Logrotate

```bash
/etc/logrotate.d/opensearch
```

```bash
/var/log/opensearch/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 opensearch opensearch
    sharedscripts
    postrotate
        systemctl reload opensearch > /dev/null 2>&1 || true
    endscript
}
```

> [!NOTE]
> OpenSearch can also manage logs internally via `logging.yml` configuration.
> OpenSearch также может управлять логами через конфигурацию `logging.yml`.

---

