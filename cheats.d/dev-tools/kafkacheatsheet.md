Title: 🛠️ Apache Kafka
Group: Dev & Tools
Icon: 🛠️
Order: 9

# Kafka Sysadmin Cheatsheet

> **Description:** Apache Kafka is a distributed event streaming platform capable of handling trillions of events per day. Originally developed at LinkedIn (2011), it is now used for real-time data pipelines, event sourcing, log aggregation, and stream processing. Kafka 3.3+ supports KRaft mode (no Zookeeper dependency).
> Apache Kafka — это распределённая платформа потоковой передачи событий, способная обрабатывать триллионы событий в день. Kafka 3.3+ поддерживает режим KRaft (без зависимости от Zookeeper).

> **Status:** Actively maintained by Apache/Confluent. Alternatives: **Apache Pulsar** (multi-tenancy, tiered storage), **RabbitMQ** (traditional message broker), **NATS** (lightweight, cloud-native), **Amazon Kinesis** (AWS-managed).
> **Role:** Sysadmin / DevOps
> **Version:** 2.8+ (Zookeeper/KRaft modes noted where applicable)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-конфигурация)
2. [Core Management](#core-management--базовое-управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [Security](#security--безопасность)
5. [Backup & Restore](#backup--restore--резервное-копирование-и-восстановление)
6. [Troubleshooting & Tools](#troubleshooting--tools--устранение-неполадок-и-инструменты)
7. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## 1. Installation & Configuration / Установка и конфигурация

### Systemd Service Unit / Юнит Systemd
File: `/etc/systemd/system/kafka.service`

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
File: `/opt/kafka/config/server.properties`

```properties
# Valid broker id (unique) / Уникальный ID брокера
broker.id=1

# Listeners / Слушатели
listeners=PLAINTEXT://<IP>:9092
advertised.listeners=PLAINTEXT://<HOST>:9092

# Zookeeper connection / Подключение к Zookeeper
zookeeper.connect=<IP1>:2181,<IP2>:2181,<IP3>:2181/kafka

# Log data directories / Директории для логов (данных)
log.dirs=/var/lib/kafka/data

# Auto topic creation (Production: false) / Автосоздание топиков (В проде: false)
auto.create.topics.enable=false

# Delete topic enable / Разрешить удаление топиков
delete.topic.enable=true
```

---

## 2. Core Management / Базовое управление

### Topics / Топики

```bash
# List all topics / Список всех топиков
kafka-topics.sh --bootstrap-server <HOST>:9092 --list

# Create topic / Создать топик
kafka-topics.sh --bootstrap-server <HOST>:9092 --create --topic <TOPIC_NAME> \
  --partitions 3 --replication-factor 2

# Describe topic details / Подробная информация о топике
kafka-topics.sh --bootstrap-server <HOST>:9092 --describe --topic <TOPIC_NAME>

# Delete topic / Удалить топик
kafka-topics.sh --bootstrap-server <HOST>:9092 --delete --topic <TOPIC_NAME>

# Alter topic configuration / Изменить конфигурацию топика
kafka-configs.sh --bootstrap-server <HOST>:9092 --entity-type topics --entity-name <TOPIC_NAME> \
  --alter --add-config retention.ms=86400000
```

### Producers & Consumers / Продюсеры и Консьюмеры

```bash
# Console Producer (Input) / Консольный продюсер (Ввод)
kafka-console-producer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME>
# Type message and press Enter / Введите сообщение и нажмите Enter

# Console Consumer (Output) / Консольный консьюмер (Вывод)
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> --from-beginning

# Read last N messages / Прочитать последние N сообщений
kafka-console-consumer.sh --bootstrap-server <HOST>:9092 --topic <TOPIC_NAME> --max-messages 10
```

---

## 3. Sysadmin Operations / Операции сисадмина

### Service Management / Управление сервисом

```bash
systemctl start kafka    # Start Kafka / Запустить Kafka
systemctl stop kafka     # Stop Kafka / Остановить Kafka
systemctl restart kafka  # Restart Kafka / Перезапустить Kafka
systemctl status kafka   # Status / Статус
journalctl -u kafka -f   # Follow logs / Смотреть логи
```

### Consumer Groups / Группы консьюмеров

```bash
# List consumer groups / Список групп консьюмеров
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --list

# Describe group (Check lag) / Описание группы (Проверка лага)
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --describe --group <GROUP_NAME>

# Reset offsets to latest / Сброс офсетов к последним
kafka-consumer-groups.sh --bootstrap-server <HOST>:9092 --group <GROUP_NAME> \
  --reset-offsets --to-latest --execute --topic <TOPIC_NAME>
```

### JVM & Performance / JVM и Производительность

> [!TIP]
> **Heap Size:** Start with 6GB-30GB depending on RAM. Do not exceed 32GB (Compressed oops).
> **GC:** G1GC is recommended for Kafka.

```bash
# Check JVM usage via jstat / Проверка использования JVM через jstat
jstat -gc <PID> 1000
```

---

## 4. Security / Безопасность

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

## 5. Backup & Restore / Резервное копирование и восстановление

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

## 6. Troubleshooting & Tools / Устранение неполадок и инструменты

### Common Issues / Частые проблемы

1.  **Under-replicated Partitions / Недореплицированные разделы**
    ```bash
    # Check for under-replicated partitions / Проверка на недорепликацию
    kafka-topics.sh --bootstrap-server <HOST>:9092 --describe --under-replicated-partitions
    ```

2.  **Controller log errors / Ошибки в логах контроллера**
    Check `server.log` and `controller.log`. Ensure Zookeeper is stable.
    Проверьте `server.log` и `controller.log`. Убедитесь, что Zookeeper стабилен.

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

## 7. Logrotate Configuration / Конфигурация Logrotate

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

## Official Documentation / Официальная документация

- **Apache Kafka:** https://kafka.apache.org/documentation/
- **Kafka Quickstart:** https://kafka.apache.org/quickstart
- **KRaft Mode:** https://kafka.apache.org/documentation/#kraft
- **Confluent Platform:** https://docs.confluent.io/
- **kcat (kafkacat):** https://github.com/edenhill/kcat
