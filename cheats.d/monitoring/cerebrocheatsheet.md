Title: 🧠 Cerebro
Group: Monitoring
Icon: 🧠
Order: 9

# Cerebro (Elasticsearch Admin) Sysadmin Cheatsheet

> **Cerebro** is an open-source web administration tool for Elasticsearch clusters, developed by Leonardo Menezes. It is the successor to the deprecated **Elasticsearch Kopf** plugin. Cerebro provides a visual interface for cluster monitoring, index management, node operations, and REST API queries.
>
> **Common use cases / Типичные сценарии:** Elasticsearch cluster health monitoring, index management (create, delete, open/close), shard visualization, alias management, template editing, snapshot management, REST API exploration.
>
> **Status / Статус:** Cerebro is still functional but **no longer actively maintained** (last release 0.9.4 in 2021). Modern alternatives include **Kibana** (official Elastic UI with full management), **Elasticsearch Head** (Chrome extension), **ElasticVue** (modern Vue.js-based UI), **OpenSearch Dashboards** (for OpenSearch clusters).
>
> **Default port / Порт по умолчанию:** `9000/tcp` (Cerebro UI)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Troubleshooting & Tools](#5-troubleshooting--tools)
6. [Logrotate Configuration](#6-logrotate-configuration)

---

## 1. Installation & Configuration

### Install Cerebro / Установка Cerebro

```bash
# Download latest release / Скачать последний релиз
RELEASE="0.9.4"
wget "https://github.com/lmenezes/cerebro/releases/download/v${RELEASE}/cerebro-${RELEASE}.tgz"
tar -xzf cerebro-${RELEASE}.tgz
mv cerebro-${RELEASE} /opt/cerebro
```

### Install via Docker / Установка через Docker

```bash
# Run Cerebro in Docker / Запустить Cerebro в Docker
docker run -d --name cerebro \
  -p 9000:9000 \
  -e CEREBRO_PORT=9000 \
  lmenezes/cerebro:latest

# Or with custom config / Или с кастомным конфигом
docker run -d --name cerebro \
  -p 9000:9000 \
  -v /etc/cerebro/application.conf:/opt/cerebro/conf/application.conf:ro \
  lmenezes/cerebro:latest
```

### Main Configuration / Основная конфигурация

`/opt/cerebro/conf/application.conf`

```hocon
# Server settings / Настройки сервера
play {
  server.http.port = 9000
}

# Elasticsearch cluster connections / Подключения к кластерам Elasticsearch
hosts = [
  {
    host = "http://<ES_HOST_1>:9200"
    name = "Production Cluster"
  },
  {
    host = "http://<ES_HOST_2>:9200"
    name = "Staging Cluster"
  }
]

# Authentication (optional) / Аутентификация (опционально)
auth = {
  type: "basic"
  settings {
    username = "<USER>"
    password = "<PASSWORD>"
  }
}

# LDAP authentication / Аутентификация через LDAP
# auth = {
#   type: "ldap"
#   settings {
#     url = "ldap://<LDAP_HOST>:389"
#     base-dn = "dc=example,dc=com"
#     method = "simple"
#     user-template = "uid=%s,ou=users,dc=example,dc=com"
#   }
# }
```

### Systemd Service / Сервис systemd

`/etc/systemd/system/cerebro.service`

```ini
[Unit]
Description=Cerebro - Elasticsearch Web Admin
After=network.target

[Service]
Type=simple
User=cerebro
Group=cerebro
WorkingDirectory=/opt/cerebro
ExecStart=/opt/cerebro/bin/cerebro -Dconfig.file=/opt/cerebro/conf/application.conf
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
# Create user and set permissions / Создать пользователя и настроить права
useradd -r -s /sbin/nologin cerebro
chown -R cerebro:cerebro /opt/cerebro

# Enable and start / Активировать и запустить
systemctl daemon-reload
systemctl enable --now cerebro
```

---

## 2. Core Management

### Web UI Access / Доступ к веб-интерфейсу

```bash
http://<HOST>:9000    # Cerebro dashboard / Панель Cerebro
```

On first access, enter your Elasticsearch cluster URL to connect. / При первом доступе введите URL вашего кластера Elasticsearch.

### Cerebro UI Features / Функции интерфейса Cerebro

| Feature | Description / Описание |
|---------|------------------------|
| **Overview** | Cluster health, nodes, shards visual map / Здоровье кластера, узлы, визуальная карта шардов |
| **Nodes** | Node stats (heap, CPU, disk, load) / Статистика узлов |
| **Rest** | Execute Elasticsearch REST API queries / Выполнение REST-запросов к ES |
| **Aliases** | Manage index aliases / Управление алиасами индексов |
| **Templates** | View/edit index templates / Просмотр/редактирование шаблонов |
| **Cluster Settings** | View/modify cluster-level settings / Настройки кластера |
| **Index Settings** | Per-index settings, replicas, routings / Настройки индексов |
| **Snapshots** | Manage repository snapshots / Управление snapshot-репозиториями |
| **Cat API** | Visual /_cat API browser / Визуальный браузер Cat API |

### Useful Elasticsearch API Queries via Cerebro / Полезные запросы через REST-интерфейс

```bash
# Cluster health / Здоровье кластера
GET /_cluster/health

# Node stats / Статистика узлов
GET /_nodes/stats

# Index list / Список индексов
GET /_cat/indices?v&s=store.size:desc

# Shard allocation / Распределение шардов
GET /_cat/shards?v&s=store:desc

# Pending tasks / Ожидающие задачи
GET /_cluster/pending_tasks

# Check disk allocation / Проверить распределение дисков
GET /_cat/allocation?v
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start cerebro      # Start / Запустить
systemctl stop cerebro       # Stop / Остановить
systemctl restart cerebro    # Restart / Перезапустить
systemctl enable cerebro     # Enable on boot / Автозапуск
systemctl status cerebro     # Check status / Проверить статус
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/opt/cerebro/` | Cerebro installation directory / Каталог установки |
| `/opt/cerebro/conf/application.conf` | Main configuration / Основной конфиг |
| `/opt/cerebro/logs/` | Application logs / Логи приложения |

### JVM Tuning / Настройка JVM

`/opt/cerebro/conf/jvm.options` or environment variable:

```bash
# Set JVM heap size / Установить размер heap JVM
export JAVA_OPTS="-Xms256m -Xmx512m"

# Or in systemd override / Или через переопределение systemd
# /etc/systemd/system/cerebro.service.d/override.conf
# [Service]
# Environment="JAVA_OPTS=-Xms256m -Xmx512m"
```

### Firewall Configuration / Настройка фаервола

```bash
# Allow Cerebro port / Разрешить порт Cerebro
firewall-cmd --permanent --add-port=9000/tcp
firewall-cmd --reload
```

> [!TIP]
> For security, do not expose Cerebro to the public internet. Use a VPN or SSH tunnel. / Не выставляйте Cerebro в публичный интернет. Используйте VPN или SSH-туннель.

---

## 4. Security

### Authentication Types / Типы аутентификации

| Type | Description / Описание | Best For / Лучше для |
|------|------------------------|---------------------|
| None | No auth (default) / Без аутентификации | Development / Разработка |
| Basic | Username/password in config / Логин/пароль в конфиге | Small teams / Маленькие команды |
| LDAP | Corporate directory integration / Интеграция с каталогом | Enterprise / Корпоративное |

### Reverse Proxy with TLS / Обратный прокси с TLS

`/etc/nginx/conf.d/cerebro.conf`

```nginx
server {
    listen 443 ssl;
    server_name cerebro.<DOMAIN>;

    ssl_certificate     /etc/ssl/certs/cerebro.crt;
    ssl_certificate_key /etc/ssl/private/cerebro.key;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

> [!WARNING]
> Cerebro has full access to your Elasticsearch cluster. Anyone with Cerebro access can delete indices, change settings, and modify data. / Cerebro имеет полный доступ к кластеру Elasticsearch. Обеспечьте надлежащую защиту.

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Cerebro Cannot Connect to Elasticsearch / Cerebro не может подключиться к ES

```bash
# Check Elasticsearch connectivity / Проверить подключение к ES
curl -s http://<ES_HOST>:9200/_cluster/health | jq .

# Check Cerebro logs / Проверить логи Cerebro
tail -50 /opt/cerebro/logs/application.log

# Verify network / Проверить сеть
curl -v http://<ES_HOST>:9200
```

#### 2. Cerebro UI Loads Slowly / Интерфейс Cerebro загружается медленно

```bash
# Check JVM heap usage / Проверить использование JVM heap
jcmd $(pgrep -f cerebro) VM.heap_info 2>/dev/null

# Increase JVM heap / Увеличить JVM heap
# Set JAVA_OPTS="-Xms512m -Xmx1g"
```

#### 3. Cluster Shows Red/Yellow Status / Кластер показывает статус Red/Yellow

This is an Elasticsearch issue, not Cerebro. Use Cerebro's UI to diagnose: / Это проблема Elasticsearch, не Cerebro. Используйте Cerebro для диагностики:

```bash
# In Cerebro REST tab / В REST-интерфейсе Cerebro
GET /_cluster/health
GET /_cat/shards?v&h=index,shard,prirep,state,unassigned.reason&s=state
GET /_cluster/allocation/explain
```

| Status | Description / Описание | Action / Действие |
|--------|------------------------|-------------------|
| Green / Зелёный | All shards assigned / Все шарды назначены | None / Ничего |
| Yellow / Жёлтый | Primary OK, replicas unassigned / Первичные ОК, реплики не назначены | Add nodes or reduce replicas / Добавить узлы или уменьшить реплики |
| Red / Красный | Primary shards unassigned / Первичные шарды не назначены | Immediate investigation / Срочное расследование |

---

## 6. Logrotate Configuration

`/etc/logrotate.d/cerebro`

```conf
/opt/cerebro/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 cerebro cerebro
}
```

---

## Documentation Links / Ссылки на документацию

- **GitHub Repository:** https://github.com/lmenezes/cerebro
- **Releases:** https://github.com/lmenezes/cerebro/releases
- **Docker Hub:** https://hub.docker.com/r/lmenezes/cerebro
- **Alternative — ElasticVue:** https://elasticvue.com/
- **Alternative — Kibana:** https://www.elastic.co/kibana

---
