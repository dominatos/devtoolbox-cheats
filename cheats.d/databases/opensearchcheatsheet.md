Title: 🔎 OpenSearch — Cheatsheet
Group: Databases
Icon: 🔎
Order: 4

# Cluster / Кластер
curl -sS -u 'admin:admin' http://localhost:9200/                                   # Ping cluster (version) / Пинг кластера (версия)
curl -sS -u 'admin:admin' http://localhost:9200/_cluster/health?pretty             # Cluster health / Здоровье кластера
curl -sS -u 'admin:admin' http://localhost:9200/_cat/nodes?v                       # Nodes table / Таблица узлов
curl -sS -u 'admin:admin' http://localhost:9200/_cat/indices?v                     # Indices table / Таблица индексов

# Index / Индекс
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/my-index \
  -H 'Content-Type: application/json' \
  -d '{ "settings": {"number_of_shards":1,"number_of_replicas":1} }'               # Create index / Создать индекс
curl -sS -u 'admin:admin' http://localhost:9200/my-index/_mapping?pretty           # Show mapping / Показать mapping
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/my-index/_mapping \
  -H 'Content-Type: application/json' \
  -d '{ "properties": { "tag": { "type": "keyword" } } }'                          # Update mapping / Обновить mapping
curl -sS -u 'admin:admin' -X DELETE http://localhost:9200/my-index                 # Delete index / Удалить индекс

# Documents / Документы
curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_doc/1 \
  -H 'Content-Type: application/json' \
  -d '{ "title":"hello","tag":"demo","ts":"2025-08-27T10:00:00Z" }'                # Index/replace id=1 / Создать/заменить doc id=1
curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_search \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "title": "hello" } }, "size": 5 }'                   # Search match / Поиск match
curl -sS -u 'admin:admin' -X POST http://localhost:9200/my-index/_update/1 \
  -H 'Content-Type: application/json' \
  -d '{ "doc": { "tag":"updated" } }'                                              # Partial update / Частичное обновление

# Bulk / Массовая загрузка
cat >bulk.json <<'B'
{ "index": { "_index":"my-index","_id":"2" } }
{ "title":"bulk item 2","tag":"demo" }
{ "index": { "_index":"my-index","_id":"3" } }
{ "title":"bulk item 3","tag":"demo" }
B
curl -sS -u 'admin:admin' -X POST http://localhost:9200/_bulk \
  -H 'Content-Type: application/x-ndjson' --data-binary @bulk.json                 # Bulk NDJSON / Массовая загрузка NDJSON

# Settings / Настройки
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_cluster/settings \
  -H 'Content-Type: application/json' \
  -d '{ "transient": { "search.default_search_timeout":"30s" } }'                  # Transient settings / Транзиентные настройки

# Snapshots / Снапшоты
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_snapshot/fsrepo \
  -H 'Content-Type: application/json' \
  -d '{ "type":"fs", "settings":{"location":"/var/backups/opensearch"} }'          # Create repo / Создать репозиторий
curl -sS -u 'admin:admin' -X PUT http://localhost:9200/_snapshot/fsrepo/snap-$(date +%Y%m%d)  # Create snapshot / Создать снапшот
curl -sS -u 'admin:admin' http://localhost:9200/_snapshot/fsrepo/_all?pretty      # List snapshots / Список снапшотов

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


# исключить ноду по имени/ DRAIN NODE
curl -XPUT localhost:9200/_cluster/settings -H 'Content-Type: application/json' -d '{
  "transient": { "cluster.routing.allocation.exclude._name": "os-data-1" }
}'
curl -s localhost:9200/_cat/shards?v | grep os-data-1 || echo "empty"



