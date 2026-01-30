Title: 🔎 OpenSearch
Group: Databases
Icon: 🔎
Order: 4

---

## 📚 Table of Contents / Содержание

1. Cluster / Кластер
2. Index / Индекс
3. Documents / Документы
4. Bulk / Массовая загрузка
5. Settings / Настройки
6. Snapshots / Снапшоты
7. cURL toolbox / Набор приёмов cURL
8. Drain node / Исключение ноды (DRAIN)
9. OpenSearch Reindexing Guide / Руководство по реиндексации
10. Snapshot automation with cron / Автоматизация снапшотов через cron
11. Security: Read-Only user / Только чтение
12. Security: Read/Write user / Чтение и запись
13. Security Action Groups (Index & Cluster) / Группы действий (индекс и кластер)

---

## 1) Cluster / Кластер

```bash
curl -sS -u 'admin:admin' http://localhost:9200/                                   # Ping cluster (version) / Пинг кластера (версия)
curl -sS -u 'admin:admin' http://localhost:9200/_cluster/health?pretty             # Cluster health / Здоровье кластера
curl -sS -u 'admin:admin' http://localhost:9200/_cat/nodes?v                       # Nodes table / Таблица узлов
curl -sS -u 'admin:admin' http://localhost:9200/_cat/indices?v                     # Indices table / Таблица индексов
```

---

## 2) Index / Индекс

```bash
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/my-index \
  -H 'Content-Type: application/json' \
  -d '{ "settings": {"number_of_shards":1,"number_of_replicas":1} }'               # Create index / Создать индекс

curl -sS -u 'admin:admin' http://localhost:9200/my-index/_mapping?pretty           # Show mapping / Показать mapping

curl -sS -u 'admin:admin' -X PUT http://localhost:9200/my-index/_mapping \
  -H 'Content-Type: application/json' \
  -d '{ "properties": { "tag": { "type": "keyword" } } }'                          # Update mapping / Обновить mapping

curl -sS -u 'admin:admin' -X DELETE http://localhost:9200/my-index                 # Delete index / Удалить индекс
```

---

## 3) Documents / Документы

```bash
curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_doc/1 \
  -H 'Content-Type: application/json' \
  -d '{ "title":"hello","tag":"demo","ts":"2025-08-27T10:00:00Z" }'                # Index/replace id=1 / Создать/заменить doc id=1

curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_search \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "title": "hello" } }, "size": 5 }'                   # Search match / Поиск match

curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_update/1 \
  -H 'Content-Type: application/json' \
  -d '{ "doc": { "tag":"updated" } }'                                              # Partial update / Частичное обновление
```

---

## 4) Bulk / Массовая загрузка

```bash
cat >bulk.json <<'B'
{ "index": { "_index":"my-index","_id":"2" } }
{ "title":"bulk item 2","tag":"demo" }
{ "index": { "_index":"my-index","_id":"3" } }
{ "title":"bulk item 3","tag":"demo" }
B

curl -sS -u 'admin:admin' -X POST http://localhost:9200/_bulk \
  -H 'Content-Type: application/x-ndjson' --data-binary @bulk.json                 # Bulk NDJSON / Массовая загрузка NDJSON
```

---

## 5) Settings / Настройки

```bash
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_cluster/settings \
  -H 'Content-Type: application/json' \
  -d '{ "transient": { "search.default_search_timeout":"30s" } }'                  # Transient settings / Транзиентные настройки
```

---

## 6) Snapshots / Снапшоты

```bash
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_snapshot/fsrepo \
  -H 'Content-Type: application/json' \
  -d '{ "type":"fs", "settings":{"location":"/var/backups/opensearch"} }'          # Create repo / Создать репозиторий

curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_snapshot/fsrepo/snap-$(date +%Y%m%d)  # Create snapshot / Создать снапшот

curl -sS -u 'admin:admin' http://localhost:9200/_snapshot/fsrepo/_all?pretty      # List snapshots / Список снапшотов
```

---

## 7) cURL toolbox / Набор приёмов cURL

```bash
curl -L https://example.com                                       # Follow redirects / Следовать редиректам
curl -D headers.txt -o body.bin https://example.com               # Save headers and body separately / Сохранить заголовки и тело отдельно
curl -s -o /dev/null -w 'dns:%{time_namelookup} connect:%{time_connect} ttfb:%{time_starttransfer} total:%{time_total}\n' https://example.com  # Timing metrics / Метрики времени
curl -C - -O https://host/big.iso                                  # Resume interrupted download / Докачать прерванную загрузку
curl -H 'Content-Type: application/json' --data @payload.json https://api.example.com  # POST JSON from file / POST JSON из файла
curl -H 'Authorization: Bearer TOKEN' https://api.example.com/me   # Bearer token header / Заголовок с Bearer-токеном
curl --compressed https://example.com                              # Ask compressed response & auto-decompress / Запросить сжатый ответ и авторазжать
curl --retry 5 --retry-delay 2 --retry-all-errors https://example.com  # Retries on errors / Повторы при ошибках
curl --resolve example.com:443:1.2.3.4 https://example.com         # Override DNS for host:port / Переопределить DNS для host:port
curl --connect-to example.com:443:127.0.0.1:8443 https://example.com  # Reroute to another host:port / Принудительно направить на другой host:port
curl -s -o /dev/null -w '%{http_code}\n' https://example.com       # Print only HTTP status code / Вывести только HTTP-код
curl --pinnedpubkey 'sha256//BASE64==' https://example.com         # Public key pinning / Пиннинг публичного ключа
curl -F 'file=@image.png' https://host/upload                      # Multipart file upload / Мультизагрузка файла
curl --parallel -O https://h/a.bin -O https://h/b.bin              # Parallel downloads / Параллельные загрузки
```

---

## 8) Drain node / Исключить ноду по имени (DRAIN NODE)

```bash
curl -XPUT localhost:9200/_cluster/settings -H 'Content-Type: application/json' -d '{
  "transient": { "cluster.routing.allocation.exclude._name": "os-data-1" }
}'
curl -s localhost:9200/_cat/shards?v | grep os-data-1 || echo "empty"
```

---

## 9) 📘 OpenSearch Reindexing Guide / Руководство по реиндексации

> Ниже — твой оригинальный двуязычный блок. Для удобства он оформлен как раздел «how-to», но **содержимое сохранено без удаления**.

### 🔹 What is reindexing? / Что такое реиндексация?

* **EN**: Reindexing copies documents from one index to another (possibly with new mappings, settings, or transformations).
* **RU**: Реиндексация копирует документы из одного индекса в другой (часто с новыми маппингами, настройками или изменением структуры данных).

**Typical use cases / Типичные случаи применения**:

* EN: Changing mapping or analyzer.
* RU: Изменение mapping или analyzer.
* EN: Migrating to a new index name with better settings.
* RU: Миграция в новый индекс с улучшенными настройками.
* EN: Renaming/removing fields.
* RU: Переименование или удаление полей.
* EN: Cross-cluster migration.
* RU: Межкластерная миграция.

### 🔹 Step 1: Create a new index / Создание нового индекса

```bash
curl -u admin:pass -X PUT "http://os:9200/logs-v2" -H 'Content-Type: application/json' -d '{
  "settings": {
    "number_of_shards": 6,
    "number_of_replicas": 0,     // EN: no replicas during reindex / RU: без реплик во время реиндексации
    "refresh_interval": "-1"     // EN: disable refresh for speed / RU: отключить refresh для скорости
  },
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "@timestamp": { "type": "date" },
      "user":       { "type": "keyword" },
      "message":    { "type": "text" },
      "bytes":      { "type": "long" }
    }
  }
}'
```

### 🔹 Step 2: Run reindex / Запуск реиндексации

**Basic / Базовый вариант**

```bash
curl -u admin:pass -X POST "http://os:9200/_reindex?refresh=true" -H 'Content-Type: application/json' -d '{
  "source": { "index": "logs-legacy" },   // EN: source index / RU: исходный индекс
  "dest":   { "index": "logs-v2" }        // EN: destination index / RU: целевой индекс
}'
```

**Asynchronous / Асинхронный режим**

```bash
curl -u admin:pass -X POST "http://os:9200/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -d '{
  "source": { "index": "logs-legacy" },
  "dest":   { "index": "logs-v2" }
}'
# EN: returns task_id for monitoring / RU: вернёт task_id для мониторинга
curl -u admin:pass "http://os:9200/_tasks/<task_id>?detailed=true"
```

### 🔹 Step 3: Filtering and transformation / Фильтрация и трансформация

**Filter by date / Фильтр по дате**

```bash
curl -u admin:pass -X POST "http://os:9200/_reindex" -H 'Content-Type: application/json' -d '{
  "source": {
    "index": "logs-*",
    "query": { "range": { "@timestamp": { "gte": "2025-09-01", "lt": "2025-10-01" } } }
  },
  "dest": { "index": "logs-v2" }
}'
```

**Modify with script / Изменение скриптом**

```bash
curl -u admin:pass -X POST "http://os:9200/_reindex" -H 'Content-Type: application/json' -d '{
  "source": { "index": "app-logs" },
  "dest":   { "index": "app-logs-v2" },
  "script": {
    "lang": "painless",
    "source": "
      ctx._source.remove('legacyField');             // EN: remove old field / RU: удалить старое поле
      if (ctx._source.user != null) {                // EN: normalize user / RU: нормализовать user
        ctx._source.user = ctx._source.user.toUpperCase();
      }
      if (ctx._source.bytes == null) {               // EN: ensure bytes is not null / RU: гарантировать, что bytes не null
        ctx._source.bytes = 0;
      }
    "
  }
}'
```

### 🔹 Step 4: Performance / Производительность

```bash
curl -u admin:pass -X POST "http://os:9200/_reindex?wait_for_completion=false&requests_per_second=1500" -H 'Content-Type: application/json' -d '{
  "slices": 8,                        // EN: 8 parallel workers / RU: 8 потоков
  "source": { "index": "big-src", "size": 5000 },
  "dest":   { "index": "big-dst" },
  "conflicts": "proceed"              // EN: skip version conflicts / RU: пропустить конфликты версий
}'
```

### 🔹 Step 5: Alias switch / Переключение алиаса

```bash
curl -u admin:pass -X POST "http://os:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    { "remove": { "alias": "logs", "index": "logs-legacy" } },
    { "add":    { "alias": "logs", "index": "logs-v2", "is_write_index": true } }
  ]
}'
```

### 🔹 Step 6: Finalize / Завершение

```bash
curl -u admin:pass -X PUT "http://os:9200/logs-v2/_settings" -H 'Content-Type: application/json' -d '{
  "index": {
    "number_of_replicas": 1,        // EN: restore replicas / RU: вернуть реплики
    "refresh_interval": "1s"        // EN: restore refresh interval / RU: вернуть refresh_interval
  }
}'
```

```bash
curl -u admin:pass -X POST "http://os:9200/logs-v2/_forcemerge?max_num_segments=1"  # Optional force-merge / Опциональный форс-мердж
```

### 🔹 Step 7: Validation / Проверка

```bash
curl "http://os:9200/logs-legacy/_count"   // EN: check old index / RU: проверить старый индекс
curl "http://os:9200/logs-v2/_count"       // EN: check new index / RU: проверить новый индекс
```

---

## 10) 📘 OpenSearch Snapshot Automation with cron / Автоматизация бэкапов через cron

**Requirements / Требования**

```bash
curl -u admin:admin http://localhost:9200/_snapshot?pretty  # must show my_backup at /mnt/backups / должен показывать my_backup на /mnt/backups
```

**Backup script / Скрипт**

```bash
#!/bin/bash
# OpenSearch snapshot script / Скрипт для создания снапшота OpenSearch
DATE=$(date +%Y-%m-%d_%H-%M)
REPO="my_backup"
SNAP="snap-${DATE}"
AUTH="admin:admin"
URL="http://localhost:9200"
echo "[*] Creating snapshot $SNAP in repo $REPO..."
curl -s -u "$AUTH" -X PUT "$URL/_snapshot/$REPO/$SNAP?wait_for_completion=false" \
  -H "Content-Type: application/json" \
  -d '{ "indices": "*", "ignore_unavailable": true, "include_global_state": true }'
echo
```

```bash
chmod +x /usr/local/bin/os-backup.sh
/usr/local/bin/os-backup.sh
curl -u admin:admin http://localhost:9200/_snapshot/my_backup/_all?pretty
```

**Cron / Крон**

```
0 2 * * * /usr/local/bin/os-backup.sh >> /var/log/opensearch-backup.log 2>&1
```

**Retention by date (optional) / Ротация по дате (опц.)**

```bash
# Delete snapshots older than 7 days / Удалить снапшоты старше 7 дней
OLD=$(date -d "-7 days" +%Y-%m-%d)
curl -s -u "$AUTH" -X DELETE "$URL/_snapshot/$REPO/snap-${OLD}*"
```

---

## 11) 🔐 Security — Read-Only user / Только чтение

**Create role / Роль**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/roles/ro-logs-2025" \
  -H "Content-Type: application/json" -d '{
  "cluster_permissions": [],
  "index_permissions": [ { "index_patterns": ["logs-2025-*"], "allowed_actions": ["read"] } ] }'
```

**Create user / Пользователь**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/internalusers/alice" \
  -H "Content-Type: application/json" -d '{ "password": "Str0ng!Passw0rd", "description": "Read-only user for logs-2025-*", "backend_roles": [] }'
```

**Map / Привязка**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/rolesmapping/ro-logs-2025" \
  -H "Content-Type: application/json" -d '{ "users": ["alice"], "backend_roles": [], "hosts": [] }'
```

---

## 12) 🔐 Security — Read/Write user / Чтение и запись

**Create role / Роль**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/roles/rw-logs-2025" \
  -H "Content-Type: application/json" -d '{
  "cluster_permissions": [],
  "index_permissions": [ { "index_patterns": ["logs-2025-*"], "allowed_actions": ["read","write"] } ] }'
```

**Create user / Пользователь**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/internalusers/bob" \
  -H "Content-Type: application/json" -d '{ "password": "An0ther!Passw0rd", "description": "Read/Write user for logs-2025-*", "backend_roles": [] }'
```

**Map / Привязка**

```bash
curl -u admin:admin -X PUT "http://db1:9200/_plugins/_security/api/rolesmapping/rw-logs-2025" \
  -H "Content-Type: application/json" -d '{ "users": ["bob"], "backend_roles": [], "hosts": [] }'
```

---

## 13) 📋 Security Action Groups — Index & Cluster / Группы действий — Индексы и Кластер

**Index-level / Уровень индексов**

| Action Group  | English Description                       | Русское описание                                |
| ------------- | ----------------------------------------- | ----------------------------------------------- |
| `read`        | Search/get/mget/scroll/exists — read-only | Поиск/get/mget/scroll/exists — только чтение    |
| `write`       | Index/update/delete docs — no search      | Добавление/обновление/удаление — без поиска     |
| `search`      | Execute search queries (DSL)              | Выполнение поисковых запросов (DSL)             |
| `get`         | Fetch document by ID                      | Получение документа по ID                       |
| `crud`        | `read` + `write` (full document CRUD)     | `read` + `write` (полный CRUD по документам)    |
| `indices_all` | All index permissions (read/write/manage) | Все права на индекс (чтение/запись/управление)  |
| `manage`      | Create/delete, mappings, settings         | Создание/удаление, mapping, настройки           |
| `all`         | All index permissions (superuser-like)    | Все права на индекс (уровень суперпользователя) |

**Cluster-level / Уровень кластера**

| Action Group               | English Description                              | Русское описание                                |
| -------------------------- | ------------------------------------------------ | ----------------------------------------------- |
| `cluster_all`              | All cluster-level permissions                    | Все права на уровне кластера                    |
| `cluster_monitor`          | Cluster health, stats (monitoring APIs)          | Мониторинг: состояние кластера, статистика      |
| `manage_snapshots`         | Create/restore/delete snapshots                  | Создание/восстановление/удаление снапшотов      |
| `manage_templates`         | Manage index templates                           | Управление шаблонами индексов                   |
| `manage_ingest_pipelines`  | Manage ingest pipelines                          | Управление ingest-конвейерами                   |
| `manage_warmers`           | (Legacy/removed in new versions)                 | Устаревшее/удалено в новых версиях              |
| `manage_ml`                | Manage ML jobs/models (if ML plugin enabled)     | Управление ML задачами/моделями (если включено) |
| `cluster_composite_ops`    | Combined read/write cluster operations           | Комбинированные кластерные операции чт/зап      |
| `cluster_composite_ops_ro` | Read-only cluster operations (health/state/info) | Только чтение кластерных операций               |

---


