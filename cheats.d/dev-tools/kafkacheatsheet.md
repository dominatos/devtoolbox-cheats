Title: 🛠️ Apache Kafka
Group: Dev & Tools
Icon: 🛠️
Order: 9

# Kafka Sysadmin Cheatsheet

> **Description:** Apache Kafka is a distributed event streaming platform capable of handling trillions of events per day. It is used for real-time data pipelines, event sourcing, log aggregation, and stream processing. Kafka 3.3+ supports KRaft mode (no Zookeeper dependency).
> Apache Kafka — это распределённая платформа потоковой передачи событий, способная обрабатывать триллионы событий в день. Kafka 3.3+ поддерживает режим KRaft (без зависимости от Zookeeper).

> **Status:** Actively maintained by Apache/Confluent. 
> **Alternatives:** **Apache Pulsar** (multi-tenancy, tiered storage), **RabbitMQ** (traditional message broker), **NATS** (lightweight, cloud-native), **Amazon Kinesis** (AWS-managed).
> **Role:** Sysadmin / DevOps
> **Version:** 2.8+ (Zookeeper/KRaft modes noted where applicable)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Backup & Restore](#5-backup--restore)
6. [Troubleshooting & Tools](#6-troubleshooting--tools)
7. [Logrotate Configuration](#7-logrotate-configuration)
8. [Official Documentation](#8-official-documentation)

---

## 1. Installation & Configuration

### Systemd Service Unit / Юнит Systemd
`/etc/systemd/system/kafka.service`

```ini
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service
After=network.target zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka
Environment="JAVA_HOME=/usr/lib/jvm/jre-11-openjdk"
Environment="KAFKA_HEAP_OPTS=-Xmx1G -Xms1G"
# JMX Port for monitoring / Порт JMX для мониторинга
Environment="JMX_PORT=9999"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Essential `server.properties` Settings / Основные настройки
`/opt/kafka/config/server.properties`

```properties
# Valid broker id (unique) / Уникальный ID брокера
broker.id=1

# Listeners / Слушатели
listeners=PLAINTEXT://<IP>:9092
advertised.listeners=PLAINTEXT://<HOST>:9092

# Zookeeper connection (if not using KRaft) / Подключение к Zookeeper
zookeeper.connect=<IP1>:2181,<IP2>:2181,<IP3>:2181/kafka

# Log data directories / Директории для логов (данных)
log.dirs=/var/lib/kafka/data

# Auto topic creation (Production: false) / Автосоздание топиков (В проде: false)
auto.create.topics.enable=false

# Delete topic enable / Разрешить удаление топиков
delete.topic.enable=true
```

### KRaft Cluster Initialization / Инициализация кластера KRaft
Modern Kafka (KRaft mode) requires log directories to be formatted with a unique Cluster ID before the server can start. / Современная Kafka (режим KRaft) требует форматирования директорий логов с уникальным ID кластера перед запуском сервера.

**Step 1: Generate a unique Cluster ID / Шаг 1: Генерация уникального ID кластера**
```bash
# Generate a unique production-safe UUID / Генерация уникального UUID для продакшена
KAFKA_CLUSTER_ID="$(/opt/kafka/bin/kafka-storage.sh random-uuid)"
```

**Step 2: Format the storage directory / Шаг 2: Форматирование директории хранилища**
```bash
# Initialize directories and write meta.properties / Инициализация директорий и запись meta.properties
/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/server.properties
```

**Step 3: Start the Kafka Broker / Шаг 3: Запуск брокера Kafka**
```bash
# Launch the active broker process / Запуск активного процесса брокера
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
```

---

## 2. Core Management

### Core Concepts & Flags / Основные концепции и флаги
| Flag / Флаг | Description (EN) | Описание (RU) | Use Case / Best for... |
| --- | --- | --- | --- |
| `--bootstrap-server` | Entry point to cluster for dynamic discovery | Точка входа в кластер для динамического обнаружения | Client connections |
| `--topic` | Immutable, append-only commit log category | Неизменяемая категория логов для записи | Publishing/reading data |
| `--partitions` | Scalability chunks for parallel processing | Разделы для параллельной обработки | High-throughput concurrency |
| `--replication-factor` | Redundancy metric (copies of a partition) | Метрика избыточности (копии раздела) | High availability/failover |
| `--group` | Identifier to bundle consumer instances | Идентификатор группы консьюмеров | Workload balancing |

### Topics / Топики

```bash
# List all topics / Список всех топиков
kafka-topics.sh --bootstrap-server <HOST>:9092 --list

# Create basic topic / Создать базовый топик
kafka-topics.sh --bootstrap-server <HOST>:9092 --create --topic <TOPIC_NAME>

# Create multi-partition topic / Создать топик с несколькими разделами и репликами
kafka-topics.sh --bootstrap-server <HOST>:9092 --create --topic <TOPIC_NAME> \
  --partitions 5 --replication-factor 2

# Describe topic architecture (reveals ISR, leaders) / Подробная архитектура топика
kafka-topics.sh --bootstrap-server <HOST>:9092 --describe --topic <TOPIC_NAME>

# Delete topic / Удалить топик
kafka-topics.sh --bootstrap-server <HOST>:9092 --delete --topic <TOPIC_NAME>
```

### Dynamic Configuration Management / Динамическое управление конфигурацией
Alter configurations live at runtime without rolling restarts. / Изменение конфигураций в реальном времени без перезапуска.

```bash
# Describe dynamic overrides / Посмотреть динамические переопределения
kafka-configs.sh --bootstrap-server <HOST>:9092 --entity-type topics --entity-name <TOPIC_NAME> --describe

# Alter configurations dynamically (e.g., retention & size) / Динамическое изменение конфигураций
kafka-configs.sh --bootstrap-server <HOST>:9092 --entity-type topics --entity-name <TOPIC_NAME> \
  --alter --add-config retention.ms=3600000,max.message.bytes=2097152

# Delete a dynamic override / Удалить динамическое переопределение
kafka-configs.sh --bootstrap-server <HOST>:9092 --entity-type topics --entity-name <TOPIC_NAME> \
  --alter --delete-config retention.ms
```

### Producers & Consumers / Продюсеры и Консьюмеры

**Producers / Продюсеры**
```bash
# Standard Interactive Producer / Стандартный интерактивный продюсер
kafka-console-producer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME>

# Safe Producer (acks=all ensures disk write) / Безопасный продюсер (гарантия записи на диск)
kafka-console-producer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> \
  --producer-property acks=all

# Produce with explicit keys (forces ordering) / Продюсер с явными ключами (гарантирует порядок)
kafka-console-producer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> \
  --property parse.key=true --property key.separator=:

# Produce forcing round-robin (for testing load-balancing) / Принудительный round-robin
kafka-console-producer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> \
  --producer-property partitioner.class=org.apache.kafka.clients.producer.RoundRobinPartitioner
```

**Consumers / Консьюмеры**
```bash
# Live Real-Time Consumer (from now) / Консьюмер в реальном времени (с текущего момента)
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME>

# Historical Log Dump (from start) / Чтение исторических логов с начала
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> --from-beginning

# Read last N messages / Прочитать последние N сообщений
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> --max-messages 10

# Advanced Meta-Data Formatter (displays keys/partitions) / Расширенный форматтер метаданных
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> \
  --formatter kafka.tools.DefaultMessageFormatter \
  --property print.timestamp=true --property print.key=true \
  --property print.value=true --property print.partition=true --from-beginning
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start kafka    # Start Kafka / Запустить Kafka
systemctl stop kafka     # Stop Kafka / Остановить Kafka
systemctl restart kafka  # Restart Kafka / Перезапустить Kafka
systemctl status kafka   # Status / Статус
journalctl -u kafka -f   # Follow logs / Смотреть логи
```

### Consumer Groups & Management / Группы консьюмеров и управление

**Scenario A: Load-Balancing** - Same group ID divides the workload across instances. / Одинаковый ID группы распределяет нагрузку.
**Scenario B: Fan-Out / Pub-Sub** - Different group IDs process independent feeds. / Разные ID групп обрабатывают данные независимо.

```bash
# Consume in a specific group / Чтение в определенной группе
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> --group <GROUP_NAME>

# List all active consumer groups / Список всех активных групп консьюмеров
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --list

# Describe specific group (Check lag) / Описание конкретной группы (Проверка лага)
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --describe --group <GROUP_NAME>
```

> [!IMPORTANT]
> **Reading `--describe` output:**
> - `CURRENT-OFFSET`: Last processed message / Последнее обработанное сообщение.
> - `LOG-END-OFFSET`: Latest available message / Последнее доступное сообщение.
> - `LAG`: Difference. If continuously rising, consumers are too slow! / Разница. Если растет - консьюмеры не справляются!

**Resetting Consumer Group Offsets / Сброс офсетов группы консьюмеров**
> [!CAUTION]
> You **must shut down** all active consumer instances belonging to the group before resetting offsets. / Необходимо **остановить** все активные инстансы консьюмеров группы перед сбросом офсетов.

```bash
# Dry Run Reset (Safe Verification) / Пробный сброс (безопасная проверка)
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --group <GROUP_NAME> \
  --reset-offsets --to-earliest --topic <TOPIC_NAME> --dry-run

# Execute Reset (Apply Commit) / Выполнить сброс
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --group <GROUP_NAME> \
  --reset-offsets --to-earliest --topic <TOPIC_NAME> --execute
```

### Partition Rebalancing & Replication / Ребалансировка разделов и репликация
Use the 3-step lifecycle when data is uneven or to increase redundancy. / Используйте 3-шаговый цикл при неравномерных данных или для увеличения избыточности.

1. **Step 1: Generate Execution Map / Шаг 1: Генерация карты выполнения**
   File: `topics-to-move.json`
   ```json
   { "topics": [{"topic": "<TOPIC_NAME>"}], "version": 1 }
   ```
   ```bash
   # Generate plan targeting specific brokers (e.g. 1,2,3) / Генерация плана для брокеров (1,2,3)
   kafka-reassign-partitions.sh --bootstrap-server <HOST>:9092 \
     --topics-to-move-json-file topics-to-move.json --broker-list "1,2,3" --generate
   ```
   *Copy the "Proposed partition reassignment" output to `migration-plan.json`.*

2. **Step 2: Change Replication Factor (Manual) / Шаг 2: Изменение фактора репликации**
   Edit `migration-plan.json` to explicitly reference multiple broker IDs in `replicas` arrays. / Отредактируйте `migration-plan.json`, добавив несколько ID брокеров в массивы `replicas`.

3. **Step 3: Execute and Verify / Шаг 3: Выполнение и проверка**
   ```bash
   # Execute with throttle (bytes/sec) / Выполнение с ограничением пропускной способности
   kafka-reassign-partitions.sh --bootstrap-server <HOST>:9092 \
     --reassignment-json-file migration-plan.json --throttle 50000000 --execute

   # Track migration status / Отслеживание статуса миграции
   kafka-reassign-partitions.sh --bootstrap-server <HOST>:9092 \
     --reassignment-json-file migration-plan.json --verify
   ```

### Broker Lifecycle Management / Управление жизненным циклом брокера

**Rolling Restart of Brokers / Постепенный перезапуск брокеров**
1. **Verify Health**: No under-replicated partitions. / **Проверка**: Нет недореплицированных разделов.
   ```bash
   kafka-topics.sh --bootstrap-server <HOST>:9092 --describe | grep -i "under-replicated"
   ```
2. **Stop Node**: Safe kill (`kill -15 <PID>`) or `systemctl stop kafka`. / **Остановка узла**.
3. **Maintain**: Apply patches/changes. / **Обслуживание**.
4. **Boot Node**: Start broker, ensure it rejoins quorum. / **Запуск узла**.
5. **Verify Sync**: Wait until Node is in the active ISR list before moving to next. / **Ожидание синхронизации** перед переходом к следующему.

**Removing/Replacing a Broker / Удаление/замена брокера**
1. Generate reassignment map excluding target broker ID. / Сгенерируйте карту переназначения без ID целевого брокера.
2. Execute migration plan to shift log segments. / Выполните план миграции.
3. Verify broker is empty. / Убедитесь, что брокер пуст.
   ```bash
   kafka-log-dirs.sh --bootstrap-server <HOST>:9092 --describe --broker-list <TARGET_BROKER_ID>
   ```
4. Stop broker once metrics drop to zero. / Остановите брокер.

### Zero-Downtime Cluster Upgrades / Обновление кластера без простоев
Requires sequence to prevent protocol mismatch. / Требует строгой последовательности для избежания несовместимости протоколов.

| Step / Шаг | Core Action (EN) | Действие (RU) |
| --- | --- | --- |
| 1. Binary Replace | Download/replace old binaries on all nodes (do not start) | Замена бинарных файлов на всех узлах (без запуска) |
| 2. Config Lock | Lock protocol version in `server.properties`: `inter.broker.protocol.version=<OLD_VERS>` | Фиксация версии протокола в конфигурации |
| 3. Rolling Restart | Perform rolling restart. Nodes run new binary, old protocol. | Перезапуск. Узлы работают на новом бинарнике, но со старым протоколом. |
| 4. Protocol Advance | Update `server.properties`: `inter.broker.protocol.version=<NEW_VERS>` | Обновление версии протокола в конфигурации |
| 5. Final Restart | Perform final rolling restart to activate new features. | Финальный перезапуск для активации новых функций. |

### JVM & Performance / JVM и Производительность

> [!TIP]
> **Heap Size:** Start with 6GB-30GB depending on RAM. Do not exceed 32GB (Compressed oops).
> **GC:** G1GC is recommended for Kafka.

```bash
# Check JVM usage via jstat / Проверка использования JVM через jstat
jstat -gc <PID> 1000
```

---

## 4. Security

### ACL Configuration / Настройка ACL
(Requires `authorizer.class.name` configured in server.properties)

```bash
# Add Producer ACL / Добавить ACL для продюсера
kafka-acls.sh --bootstrap-server <HOST>:9092 --add --allow-principal User:<USER> \
  --producer --topic <TOPIC_NAME>

# Add Consumer ACL / Добавить ACL для консьюмера
kafka-acls.sh --bootstrap-server <HOST>:9092 --add --allow-principal User:<USER> \
  --consumer --topic <TOPIC_NAME> --group <GROUP_NAME>

# List ACLs / Список ACL
kafka-acls.sh --bootstrap-server <HOST>:9092 --list
```

### SSL/TLS Basics / Основы SSL/TLS

Locations:
- Keystore: `/var/private/ssl/kafka.server.keystore.jks`
- Truststore: `/var/private/ssl/kafka.server.truststore.jks`

**server.properties:**
```properties
security.inter.broker.protocol=SSL
ssl.keystore.location=/var/private/ssl/kafka.server.keystore.jks
ssl.keystore.password=<SECRET_KEY>
ssl.key.password=<SECRET_KEY>
ssl.truststore.location=/var/private/ssl/kafka.server.truststore.jks
ssl.truststore.password=<SECRET_KEY>
```

---

## 5. Backup & Restore

### MirrorMaker (Replication) / Репликация через MirrorMaker
Replicate topics from one cluster to another. / Репликация топиков из одного кластера в другой.

```bash
# Run MirrorMaker 2 / Запуск MirrorMaker 2
./bin/connect-mirror-maker.sh mm2.properties
```

### File System Backup / Бэкап файловой системы
Ideally, backup the `log.dirs` only when Kafka is stopped to ensure consistency.
В идеале, делайте бэкап `log.dirs` только при остановленной Kafka для обеспечения целостности.

```bash
# Snapshot logs dir / Снапшот директории логов
tar -czf kafka_data_backup_$(date +%F).tar.gz /var/lib/kafka/data
```

---

## 6. Troubleshooting & Tools

### Common Issues / Частые проблемы

1.  **Under-replicated Partitions / Недореплицированные разделы**
    ```bash
    # Check for under-replicated partitions / Проверка на недорепликацию
    kafka-topics.sh --bootstrap-server <HOST>:9092 --describe --under-replicated-partitions
    ```

2.  **Controller log errors / Ошибки в логах контроллера**
    Check `server.log` and `controller.log`. Ensure Zookeeper/KRaft quorum is stable.
    Проверьте `server.log` и `controller.log`. Убедитесь, что Zookeeper/KRaft стабилен.

3.  **"Leader Not Available" / "Лидер недоступен"**
    Usually means the broker hosting the leader partition is down.
    Обычно означает, что брокер с лидер-разделом упал.

### Diagnostic Tools / Инструменты диагностики

*   **kcat (kafkacat)**: Versatile CLI client. / Универсальный CLI клиент.
    ```bash
    kcat -b <HOST>:9092 -L  # List metadata / Список метаданных
    kcat -b <HOST>:9092 -C -t <TOPIC_NAME> # Consume / Читать
    ```
*   **Cruise Control**: For cluster rebalancing. / Для ребалансировки кластера.

---

> [!WARNING]
> Keep `delete.topic.enable=true` with caution in production!
> Будьте осторожны с `delete.topic.enable=true` в продакшене!

---

## 7. Logrotate Configuration

`/etc/logrotate.d/kafka`

```conf
/opt/kafka/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

> [!NOTE]
> Kafka manages data log rotation internally via `log.retention.hours` in `server.properties`.
> Kafka управляет ротацией логов данных через `log.retention.hours` в `server.properties`.

---

## 8. Official Documentation

- **Apache Kafka:** https://kafka.apache.org/documentation/
- **Kafka Quickstart:** https://kafka.apache.org/quickstart
- **KRaft Mode:** https://kafka.apache.org/documentation/#kraft
- **Confluent Platform:** https://docs.confluent.io/
- **kcat (kafkacat):** https://github.com/edenhill/kcat
