Title: 🛠️ Apache Zookeeper
Group: Dev & Tools
Icon: 🛠️
Order: 8

# Zookeeper Sysadmin Cheatsheet

> **Description:** Apache ZooKeeper is a centralized service for maintaining configuration information, naming, distributed synchronization, and group services. It is widely used as a coordination service for distributed systems (Kafka, HBase, Solr, etc.).
> Apache ZooKeeper — это централизованный сервис для управления конфигурацией, именования, распределённой синхронизации и групповых сервисов. Широко используется как координатор для распределённых систем.

> **Status:** Actively maintained. However, **Kafka is removing its Zookeeper dependency** via KRaft mode (Kafka 3.3+). For new Kafka deployments, KRaft is preferred. Alternatives for coordination: **etcd** (Kubernetes, simpler API), **Consul** (HashiCorp, service mesh).
> **Role:** Sysadmin / DevOps
> **Version:** 3.6+

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
File: `/etc/systemd/system/zookeeper.service`

```ini
[Unit]
Description=Apache ZooKeeper
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
Type=simple
User=zookeeper
Group=zookeeper
Environment="JAVA_HOME=/usr/lib/jvm/jre-11-openjdk"
ExecStart=/opt/zookeeper/bin/zkServer.sh start-foreground
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Essential `zoo.cfg` Settings / Основные настройки
File: `/opt/zookeeper/conf/zoo.cfg`

```properties
# Basic time unit in ms / Базовая единица времени в мс
tickTime=2000

# Directory for snapshots and myid file / Директория для снимков и файла myid
dataDir=/var/lib/zookeeper

# Client port / Порт клиента
clientPort=2181

# Limit on concurrent connections (0 = unlimited) / Лимит одновременных подключений
maxClientCnxns=60

# Autopurge config / Автоочистка логов
autopurge.snapRetainCount=3
autopurge.purgeInterval=1

# Cluster nodes (server.<ID>=<HOST>:<PEER_PORT>:<LEADER_PORT>) / Узлы кластера
server.1=<IP1>:2888:3888
server.2=<IP2>:2888:3888
server.3=<IP3>:2888:3888
```

### ID Configuration / Настройка ID
File: `/var/lib/zookeeper/myid`

Contains only the integer ID of the server (e.g., `1`). / Содержит только числовой ID сервера (например, `1`).

---

## 2. Core Management / Базовое управление

### CLI Client / CLI Клиент

```bash
# Connect to local server / Подключение к локальному серверу
/opt/zookeeper/bin/zkCli.sh -server 127.0.0.1:2181

# Connect to remote server / Подключение к удаленному серверу
/opt/zookeeper/bin/zkCli.sh -server <HOST>:2181
```

### Common Commands (Inside zkCli) / Частые команды (Внутри zkCli)

```bash
ls /                   # List root nodes / Список корневых узлов
ls -R /                # Recursive list / Рекурсивный список
create /my-node "data" # Create node / Создать узел
get /my-node           # Get data / Получить данные
set /my-node "new"     # Update data / Обновить данные
delete /my-node        # Delete node / Удалить узел
rmr /my-node           # Recursive delete (deprecated but useful) / Удалить рекурсивно
deleteall /my-node     # Delete all (newer version) / Удалить всё
stat /my-node          # Check node stats / Статистика узла
```

---

## 3. Sysadmin Operations / Операции сисадмина

### 4-Letter Word Commands / Команды из 4 букв (4lw)
Send simple commands via netcat or telnet. / Отправка простых команд через netcat или telnet.

**Enable in `zoo.cfg`:** `4lw.commands.whitelist=*`

```bash
# Server status (Mode: leader/follower) / Статус сервера (Режим: лидер/фолловер)
echo srvr | nc <HOST> 2181

# Detailed statistics / Подробная статистика
echo stat | nc <HOST> 2181

# List of connections / Список подключений
echo cons | nc <HOST> 2181

# Health check (imok output) / Проверка здоровья (вывод imok)
echo ruok | nc <HOST> 2181

# Dump environment / Дамп окружения
echo envi | nc <HOST> 2181

# Monitor-ready key-value stats / K/V статистика для мониторинга
echo mntr | nc <HOST> 2181
```

### Service Management / Управление сервисом

```bash
systemctl start zookeeper   # Start / Запуск
systemctl stop zookeeper    # Stop / Остановка
systemctl restart zookeeper # Restart / Рестарт
tail -f /opt/zookeeper/logs/zookeeper-*.out # Logs / Логи
```

---

## 4. Security / Безопасность

### ACL (Access Control Lists) / Списки контроля доступа

Permissions: `c` (create), `d` (delete), `r` (read), `w` (write), `a` (admin).

```bash
# Create protected node (user:pass generated via SHA1) / Создать защищенный узел
create /secure-node "secret" digest:<USER>:<BASE64_HASH>:cdrwa

# Get ACL info / Получить ACL
getAcl /secure-node

# Set ACL (World readable) / Установить ACL (Чтение для всех)
setAcl /public-node world:anyone:r
```

---

## 5. Backup & Restore / Резервное копирование и восстановление

Zookeeper stores data in `dataDir` (snapshots) and `dataLogDir` (transaction logs).

### Backup Strategy / Стратегия бэкапа
Simply archive the `dataDir`. / Просто архивируйте `dataDir`.

```bash
# Backup script / Скрипт бэкапа
tar -czf zk_backup_$(date +%F).tar.gz /var/lib/zookeeper/version-2
```

### Cleanup / Очистка
Use `zkCleanup.sh` to remove old snapshots/logs manually if autopurge is disabled.
Используйте `zkCleanup.sh` для удаления старых логов, если автоочистка выключена.

```bash
/opt/zookeeper/bin/zkCleanup.sh -n 3 # Keep last 3 snapshots / Оставить 3 последних
```

---

## 6. Troubleshooting & Tools / Устранение неполадок и инструменты

### Common Issues / Частые проблемы

1.  **Connection Refused / Отказ в соединении**
    *   Check `clientPort` in `zoo.cfg`. / Проверьте порт клиента.
    *   Check Firewall. / Проверьте фаервол.
    *   Check if Java process is running. / Проверьте запущен ли Java процесс.

2.  **Too many connections / Слишком много подключений**
    *   Increase `maxClientCnxns` in `zoo.cfg`. / Увеличьте лимит подключений.

3.  **Leader Election Loop / Цикл выбора лидера**
    *   Check network latency between nodes. / Проверьте задержки сети.
    *   Ensure all nodes have unique IDs in `myid`. / Проверьте уникальность ID в `myid`.

### Debugging / Отладка

```bash
# Check if listening on port / Проверка прослушивания порта
netstat -tulpn | grep 2181

# Check process specific logs / Логи процесса
grep -E "ERROR|WARN" /opt/zookeeper/logs/zookeeper-*.log
```

---

## 7. Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/zookeeper`

```conf
/opt/zookeeper/logs/*.log {
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
> Zookeeper manages snapshot cleanup via `autopurge.*` settings in `zoo.cfg`.
> Zookeeper управляет очисткой снапшотов через настройки `autopurge.*` в `zoo.cfg`.

---

## Official Documentation / Официальная документация

- **Apache ZooKeeper:** https://zookeeper.apache.org/doc/current/
- **ZooKeeper Admin Guide:** https://zookeeper.apache.org/doc/current/zookeeperAdmin.html
- **ZooKeeper CLI:** https://zookeeper.apache.org/doc/current/zookeeperCLI.html
- **etcd (alternative):** https://etcd.io/docs/
