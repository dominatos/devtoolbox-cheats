Title: 🛠️ Debezium CDC
Group: Dev & Tools
Icon: 🛠️
Order: 15

# Debezium CDC Sysadmin Cheatsheet

> **Debezium** is an open-source Change Data Capture (CDC) platform that streams database changes in near real-time. It monitors database transaction logs (WAL/binlog/oplog/redologs) and publishes changes as events, most commonly into Apache Kafka.
>
> **Common use cases / Типичные сценарии:** Real-time replication, event-driven architectures, database audit trails, synchronization with search engines (OpenSearch/Elasticsearch), data lake ingestion, cache invalidation, microservices integration.
>
> **Status / Статус:** Actively maintained and widely used in production. Alternatives: **Apache NiFi** (flow-based data integration), **Maxwell's Daemon** (lightweight MySQL CDC), **Oracle GoldenGate** (enterprise CDC), **AWS DMS** (managed CDC), **Kafka Connect JDBC** (polling-based sync).
>
> **Default ports / Порты по умолчанию:** Kafka `9092`, Kafka Connect REST API `8083`, Schema Registry `8081`

---

## 📚 Table of Contents / Содержание

1. [Architecture](#architecture)
2. [Installation & Configuration](#installation--configuration)
3. [Core Management](#core-management)
4. [Sysadmin Operations](#sysadmin-operations)
5. [Security](#security)
6. [Backup & Restore](#backup--restore)
7. [Troubleshooting & Tools](#troubleshooting--tools)
8. [Production Runbooks](#production-runbooks)
9. [Logrotate Configuration](#logrotate-configuration)
10. [Additional Notes](#additional-notes)
11. [Official Documentation](#official-documentation)

---

## Architecture

### CDC Flow / Поток CDC

```text
Database → Transaction Logs (WAL/binlog/oplog) → Debezium Connector → Kafka Connect → Kafka Topics → Consumers / Search / Analytics
```

### Supported Databases / Поддерживаемые БД

| Database | Transaction Log | Notes / Примечания |
|---|---|---|
| PostgreSQL | WAL | Requires logical replication / Нужна логическая репликация |
| MySQL | binlog | Requires ROW binlog format / Нужен формат ROW |
| MariaDB | binlog | Similar to MySQL / Аналогично MySQL |
| MongoDB | oplog | Replica set required / Нужен replica set |
| Oracle | redo logs | XStream/LogMiner |
| SQL Server | CDC tables | SQL Server CDC feature |
| Db2 | Transaction logs | Enterprise usage |

### Layer 4 vs Layer 7 Balancing / Балансировка L4 vs L7

| Layer | Description EN | Описание RU | Best Use Case |
|---|---|---|---|
| Layer 4 | TCP-level balancing | Балансировка TCP уровня | Raw Kafka traffic |
| Layer 7 | HTTP-aware balancing | HTTP-aware балансировка | Kafka Connect REST API |

### Active vs Passive Health Checks / Активные vs Пассивные проверки

| Type | Description EN | Описание RU | Best For |
|---|---|---|---|
| Active | Load balancer probes service | Балансировщик проверяет сервис | HA production clusters |
| Passive | Detects failures from traffic | Ошибки из трафика | Simpler environments |

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Service / Сервис | Port / Порт | Description / Описание |
|---|---|---|
| Kafka Broker | `9092` | Kafka plaintext |
| Kafka SSL | `9093` | Kafka TLS |
| Kafka Connect REST API | `8083` | Connect API |
| Schema Registry | `8081` | Avro schema registry |
| PostgreSQL | `5432` | PostgreSQL |
| MySQL | `3306` | MySQL |

### Docker Compose Deployment / Развёртывание через Docker Compose

`/opt/debezium/docker-compose.yml`

```yaml
version: '3.9'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://<HOST>:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1 # DEV ONLY: Use 3 for production

> [!WARNING]
> The `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1` setting is for single-node development only. Production environments must run at least 3 brokers and set topic replication factors to 3.

  connect:
    image: debezium/connect:2.6
    ports:
      - "8083:8083"
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: 1
      CONFIG_STORAGE_TOPIC: connect_configs
      OFFSET_STORAGE_TOPIC: connect_offsets
      STATUS_STORAGE_TOPIC: connect_statuses
```

### Start Services / Запуск сервисов

```bash
docker compose up -d  # Start stack / Запустить стек
docker compose ps     # Check containers / Проверить контейнеры
```

Sample output:

```text
NAME        STATUS
kafka       Up
connect     Up
zookeeper   Up
```

### PostgreSQL Configuration / Конфигурация PostgreSQL

`/var/lib/pgsql/data/postgresql.conf`

```bash
wal_level = logical            # Required for CDC / Обязательно для CDC
max_replication_slots = 10     # Slots for connectors / Слоты для коннекторов
max_wal_senders = 10           # WAL sender processes / Процессы WAL sender
```

`/var/lib/pgsql/data/pg_hba.conf`

```bash
host replication <USER> <IP>/32 md5  # Allow replication / Разрешить репликацию
```

```bash
systemctl restart postgresql  # Restart PostgreSQL / Перезапустить PostgreSQL
```

### Create Replication User / Создание пользователя репликации

```bash
psql -U postgres
```

```sql
CREATE ROLE <USER> WITH REPLICATION LOGIN PASSWORD '<PASSWORD>';
```

### MySQL Configuration / Конфигурация MySQL

`/etc/my.cnf`

```bash
server-id=1
log_bin=mysql-bin
binlog_format=ROW              # Required for CDC / Обязательно для CDC
binlog_row_image=FULL          # Full row images / Полные образы строк
expire_logs_days=7             # Retention / Хранение
```

### Register Connector / Регистрация коннектора

`/opt/debezium/connectors/postgres.json`

```json
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "<HOST>",
    "database.port": "5432",
    "database.user": "<USER>",
    "database.password": "<PASSWORD>",
    "database.dbname": "appdb",
    "database.server.name": "app-postgres",
    "topic.prefix": "app",
    "plugin.name": "pgoutput"
  }
}
```

```bash
# Register connector / Зарегистрировать коннектор
curl -X POST http://<HOST>:8083/connectors \
  -H "Content-Type: application/json" \
  --data @postgres.json
```

### Verify Connector Status / Проверка статуса коннектора

```bash
curl http://<HOST>:8083/connectors/postgres-connector/status  # Check status / Проверить статус
```

Sample output:

```json
{
  "name": "postgres-connector",
  "connector": {
    "state": "RUNNING"
  }
}
```

---

## Core Management

### List Kafka Topics / Список топиков Kafka

```bash
kafka-topics.sh \
  --bootstrap-server <HOST>:9092 \
  --list                                                   # List all topics / Все топики
```

### Consume Messages / Чтение сообщений

```bash
kafka-console-consumer.sh \
  --bootstrap-server <HOST>:9092 \
  --topic app.public.users \
  --from-beginning                                         # Read from start / Читать сначала
```

Sample output:

```json
{
  "before": null,
  "after": {
    "id": 1,
    "name": "Ivan"
  },
  "op": "c"
}
```

### Connector CRUD Operations / CRUD операции с коннекторами

#### Create Connector / Создание коннектора

```bash
curl -X POST http://<HOST>:8083/connectors \
  -H "Content-Type: application/json" \
  --data @connector.json                                   # Create / Создать
```

#### List Connectors / Список коннекторов

```bash
curl http://<HOST>:8083/connectors                         # List all / Список всех
```

#### Get Connector Config / Получить конфиг

```bash
curl http://<HOST>:8083/connectors/<CONNECTOR>/config      # Get config / Получить конфиг
```

#### Pause Connector / Пауза коннектора

```bash
curl -X PUT http://<HOST>:8083/connectors/<CONNECTOR>/pause   # Pause / Пауза
```

#### Resume Connector / Возобновление коннектора

```bash
curl -X PUT http://<HOST>:8083/connectors/<CONNECTOR>/resume  # Resume / Возобновить
```

#### Delete Connector / Удаление коннектора

> [!WARNING]
> Deleting connector offsets may cause full resnapshot or duplicate events.
> Удаление офсетов коннектора может вызвать полный ресnapshot или дубликаты.

```bash
curl -X DELETE http://<HOST>:8083/connectors/<CONNECTOR>   # Delete / Удалить
```

---

## Sysadmin Operations

### Service Management / Управление сервисами

#### Docker Environment / Docker окружение

```bash
docker ps                      # List containers / Список контейнеров
docker logs -f connect         # Follow logs / Смотреть логи
docker restart connect         # Restart service / Перезапуск
```

#### Systemd Environment / Systemd окружение

```bash
systemctl status kafka-connect    # Check service / Проверить сервис
systemctl restart kafka-connect   # Restart service / Перезапустить
journalctl -u kafka-connect -f   # Follow logs / Логи
```

### Important Log Locations / Расположение логов

| Path / Путь | Description / Описание |
|---|---|
| `/var/log/kafka/server.log` | Kafka broker logs / Логи брокера |
| `/var/log/kafka-connect/connect.log` | Kafka Connect logs / Логи Connect |
| `/var/lib/kafka/data/` | Kafka topic storage / Хранилище топиков |
| `/var/lib/postgresql/data/pg_wal/` | PostgreSQL WAL files / WAL файлы |
| `/var/lib/mysql/` | MySQL binlogs / Бинлоги MySQL |

### JVM Tuning / Настройка JVM

`/etc/kafka/connect-distributed.properties`

```bash
KAFKA_HEAP_OPTS="-Xms2G -Xmx2G"  # JVM heap size / Размер кучи JVM
```

#### Recommended Heap Sizing / Рекомендуемый размер кучи

| RAM | Heap Recommendation / Рекомендация |
|---|---|
| 4 GB | 1-2 GB |
| 8 GB | 2-4 GB |
| 16 GB+ | 4-8 GB |

### Check Kafka Consumer Lag / Проверка лага консьюмеров

```bash
kafka-consumer-groups.sh \
  --bootstrap-server <HOST>:9092 \
  --describe \
  --group connect-cluster                                  # Check lag / Проверить лаг
```

### Network Checks / Проверки сети

```bash
ss -lntp                          # Listening TCP ports / TCP порты
nc -zv <HOST> 9092                # Test Kafka port / Проверить Kafka
curl http://<HOST>:8083/          # Test Connect API / Проверить API
```

### Firewall Configuration / Настройка файрвола

#### firewalld

```bash
firewall-cmd --permanent --add-port=9092/tcp               # Allow Kafka / Разрешить Kafka
firewall-cmd --permanent --add-port=8083/tcp               # Allow Connect / Разрешить Connect
firewall-cmd --reload                                      # Apply rules / Применить
```

#### iptables

```bash
iptables -A INPUT -p tcp --dport 9092 -j ACCEPT            # Allow Kafka
iptables -A INPUT -p tcp --dport 8083 -j ACCEPT            # Allow Connect
```

---

## Security

### TLS Configuration / Конфигурация TLS

`/etc/kafka/connect-distributed.properties`

```bash
security.protocol=SSL
ssl.truststore.location=/etc/kafka/secrets/kafka.truststore.jks
ssl.truststore.password=<PASSWORD>
ssl.keystore.location=/etc/kafka/secrets/kafka.keystore.jks
ssl.keystore.password=<PASSWORD>
```

> [!CAUTION]
> Storing `ssl.truststore.password` and `ssl.keystore.password` in plaintext is unsafe in production. Replace inline passwords with provider-based secret lookups using Kafka Connect secrets management (`config.providers`), HashiCorp Vault, or Kubernetes Secrets.

### Generate Java Keystore / Создание Java Keystore

```bash
keytool -genkeypair \
  -alias kafka-connect \
  -keyalg RSA \
  -keystore kafka.keystore.jks                             # Generate keystore / Создать keystore
```

### Verify Certificate / Проверка сертификата

```bash
openssl s_client -connect <HOST>:9093                      # Verify TLS / Проверить TLS
```

### Minimal Database Permissions / Минимальные права БД

#### PostgreSQL

```sql
GRANT CONNECT ON DATABASE appdb TO <USER>;
GRANT USAGE ON SCHEMA public TO <USER>;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO <USER>;
```

#### MySQL

```sql
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT
ON *.* TO '<USER>'@'%';
```

---

## Backup & Restore

### Backup Connector Configurations / Бэкап конфигураций

```bash
mkdir -p /opt/backups/debezium

curl http://<HOST>:8083/connectors/<CONNECTOR>/config \
  -o /opt/backups/debezium/<CONNECTOR>.json                # Save config / Сохранить конфиг
```

### Backup Kafka Topics / Бэкап топиков Kafka

> [!CAUTION]
> Using `tar` on `/var/lib/kafka/data` while Kafka is running can produce inconsistent snapshots. Filesystem backups should only be used when Kafka is stopped or quiesced. For production, rely on Kafka replication, use MirrorMaker2 for cross-cluster/topic replication, or use Kafka-aware backup tools that support consistent snapshots.

```bash
# ONLY WHEN KAFKA IS STOPPED / ТОЛЬКО ПРИ ОСТАНОВЛЕННОМ KAFKA
tar czf kafka-data-backup.tar.gz /var/lib/kafka/data/      # Backup Kafka data / Бэкап данных Kafka
```

### PostgreSQL Logical Backup / Логический бэкап PostgreSQL

```bash
pg_dump -U <USER> appdb > appdb.sql                        # Dump database / Дамп БД
```

### Restore PostgreSQL Backup / Восстановление PostgreSQL

```bash
psql -U <USER> appdb < appdb.sql                           # Restore database / Восстановить БД
```

### Snapshot Topics with MirrorMaker2 / Репликация через MirrorMaker2

```bash
connect-mirror-maker.sh mm2.properties                     # Start MirrorMaker2 / Запустить MirrorMaker2
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

| Problem / Проблема | Cause / Причина | Fix / Решение |
|---|---|---|
| Connector FAILED | Invalid config / Невалидный конфиг | Validate JSON / Проверить JSON |
| No events in Kafka | Replication disabled / Репликация отключена | Enable WAL/binlog |
| Duplicate events | Offset reset / Сброс офсетов | Check offsets / Проверить офсеты |
| Lag increasing | Slow consumers / Медленные консьюмеры | Scale consumers / Масштабировать |
| WAL growing | Connector stopped / Коннектор остановлен | Resume connector / Возобновить |

### Check Connector Status / Проверить статус коннектора

```bash
curl http://<HOST>:8083/connectors/<CONNECTOR>/status | jq  # Check status / Проверить статус
```

### Validate Kafka Connectivity / Проверка связи с Kafka

```bash
kcat -b <HOST>:9092 -L                                     # List metadata / Метаданные
```

### Check PostgreSQL Replication Slots / Проверка слотов репликации

```bash
psql -U postgres -c "SELECT * FROM pg_replication_slots;"   # List slots / Список слотов
```

### Check MySQL Binlog Status / Статус бинлога MySQL

```bash
mysql -e "SHOW MASTER STATUS;"                              # Binlog status / Статус бинлога
```

### Monitor WAL Growth / Мониторинг роста WAL

```bash
du -sh /var/lib/postgresql/data/pg_wal/                     # WAL size / Размер WAL
```

### Restart Failed Connector Task / Перезапуск задачи коннектора

```bash
curl -X POST \
  http://<HOST>:8083/connectors/<CONNECTOR>/tasks/0/restart  # Restart task / Перезапуск
```

### JVM Diagnostics / Диагностика JVM

```bash
jcmd <PID> VM.flags                                        # JVM flags / Флаги JVM
jstat -gc <PID> 5s                                         # GC stats / Статистика GC
jmap -heap <PID>                                           # Heap info / Информация о куче
```

---

## Production Runbooks

### Connector Deployment Runbook / План развёртывания коннектора

1. Validate database replication settings / Проверить настройки репликации
2. Create dedicated replication user / Создать пользователя репликации
3. Verify Kafka connectivity / Проверить связь с Kafka
4. Register connector JSON / Зарегистрировать JSON коннектора
5. Verify connector status / Проверить статус
6. Consume test events / Прочитать тестовые события
7. Configure monitoring and alerting / Настроить мониторинг
8. Configure backups / Настроить бэкапы

### Connector Rollback Runbook / План отката коннектора

> [!WARNING]
> Incorrect rollback may cause duplicate or missing events.
> Некорректный откат может вызвать дубликаты или потерю событий.

1. Pause connector / Поставить на паузу
2. Export current config / Экспортировать текущий конфиг
3. Restore previous connector config / Восстановить предыдущий конфиг
4. Resume connector / Возобновить работу
5. Validate offsets / Проверить офсеты
6. Verify event ordering / Проверить порядок событий

### Incident Response: Connector Down / Коннектор упал

1. Check Docker/systemd status / Проверить статус
2. Review logs / Просмотреть логи
3. Validate Kafka broker availability / Проверить доступность Kafka
4. Validate DB connectivity / Проверить связь с БД
5. Restart failed task / Перезапустить задачу
6. Resume connector / Возобновить коннектор
7. Verify topic ingestion / Проверить поступление данных

### Incident Response: WAL/Binlog Disk Full / Диск WAL/binlog полон

> [!CAUTION]
> Full WAL/binlog storage can stop database writes.
> Заполненное хранилище WAL/binlog может остановить запись в БД.

1. Verify connector status / Проверить статус коннектора
2. Resume failed connector / Возобновить коннектор
3. Increase storage / Увеличить хранилище
4. Remove obsolete logs only if replication confirmed / Удалять только при подтверждённой репликации
5. Validate replication lag / Проверить лаг репликации

---

## Logrotate Configuration

`/etc/logrotate.d/kafka-connect`

```conf
/var/log/kafka-connect/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    copytruncate
}
```

---

## Additional Notes

### Important Kafka Internal Topics / Внутренние топики Kafka

| Topic / Топик | Purpose / Назначение |
|---|---|
| `connect_configs` | Connector configurations / Конфигурации коннекторов |
| `connect_offsets` | Connector offsets / Офсеты коннекторов |
| `connect_statuses` | Connector states / Состояния коннекторов |

### Snapshot Modes / Режимы snapshot

| Mode / Режим | Description EN | Описание RU |
|---|---|---|
| `initial` | Full initial snapshot | Полный начальный snapshot |
| `schema_only` | Only schema | Только схема |
| `never` | No snapshot | Без snapshot |
| `when_needed` | Snapshot if required | Snapshot при необходимости |

### Event Operations / Операции событий

| Code / Код | Meaning / Значение |
|---|---|
| `c` | Create / Создание |
| `u` | Update / Обновление |
| `d` | Delete / Удаление |
| `r` | Snapshot read / Чтение snapshot |

### Best Practices / Лучшие практики

- Use dedicated replication users / Используйте выделенных пользователей репликации
- Enable TLS in production / Включите TLS в продакшене
- Monitor replication lag / Мониторьте лаг репликации
- Store connector configs in Git / Храните конфиги коннекторов в Git
- Avoid resetting offsets in production / Не сбрасывайте офсеты в продакшене
- Use Schema Registry for Avro/Protobuf / Используйте Schema Registry
- Separate Kafka disks from OS disks / Разделяйте диски Kafka и ОС
- Configure alerting for connector failures / Настройте алертинг

---

## Official Documentation

- **Debezium Official:** https://debezium.io/documentation/
- **Apache Kafka:** https://kafka.apache.org/documentation/
- **Kafka Connect:** https://docs.confluent.io/platform/current/connect/index.html
- **PostgreSQL Logical Replication:** https://www.postgresql.org/docs/current/logical-replication.html
- **MySQL Binary Log:** https://dev.mysql.com/doc/refman/en/binary-log.html
- **OpenSearch:** https://opensearch.org/docs/

---
