---
Title: 📊 Filebeat
Group: Monitoring
Icon: 📊
Order: 5
tags:
  - monitoring
  - sysadmin
  - linux
---

# Filebeat Sysadmin Cheatsheet

> **Filebeat** is a lightweight log shipper from the Elastic Stack (ELK/Elastic), originally developed by Elastic. It monitors log files, collects log events, and forwards them to Elasticsearch, Logstash, Kafka, or other outputs. Filebeat uses a backpressure-sensitive protocol to handle spikes in data volume.
>
> **Common use cases / Типичные сценарии:** Centralized log collection, syslog/auth log forwarding, application log shipping, multiline log parsing (Java stack traces), container log collection, compliance log aggregation.
>
> **Status / Статус:** Actively developed as part of the Elastic Stack. Filebeat is the recommended log shipper for Elasticsearch/OpenSearch pipelines. Alternatives include **Fluent Bit** (lightweight, CNCF), **Fluentd** (plugin-rich, CNCF), **Vector** (Rust-based, high-performance by Datadog), **Promtail** (for Loki/Grafana stack), **rsyslog/syslog-ng** (traditional syslog).
>
> **Default ports / Порты по умолчанию:** None (outbound only) | Elasticsearch: `9200` | Logstash: `5044` | Kibana: `5601`

---

## 📚 Table of Contents

1. [Installation & Configuration](#1.%20Installation%20&%20Configuration)
2. [Core Management](#2.%20Core%20Management)
3. [Sysadmin Operations](#3.%20Sysadmin%20Operations)
4. [Security](#4.%20Security)
5. [Troubleshooting & Tools](#5.%20Troubleshooting%20&%20Tools)
6. [Logrotate Configuration](#6.%20Logrotate%20Configuration)

---

## 1. Installation & Configuration

### Install Filebeat

```bash
# RHEL/CentOS/AlmaLinux (add Elastic repo first)
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << 'EOF'
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
dnf install filebeat

# Debian/Ubuntu
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list
apt update && apt install filebeat
```

### Main Configuration

`/etc/filebeat/filebeat.yml`

```yaml
# Input configuration
filebeat.inputs:
  - type: filestream
    id: syslog
    enabled: true
    paths:
      - /var/log/syslog
      - /var/log/messages
    tags: ["syslog"]

  - type: filestream
    id: auth-logs
    enabled: true
    paths:
      - /var/log/auth.log
      - /var/log/secure
    tags: ["auth"]

  - type: filestream
    id: app-logs
    enabled: true
    paths:
      - /var/log/myapp/*.log
    multiline:
      type: pattern
      pattern: '^\d{4}-\d{2}-\d{2}'
      negate: true
      match: after

# Output to Elasticsearch
output.elasticsearch:
  hosts: ["https://<ES_HOST>:9200"]
  username: "<USER>"
  password: "<PASSWORD>"
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  index: "filebeat-%{+yyyy.MM.dd}"

# Output to Logstash (alternative)
# output.logstash:
#   hosts: ["<LOGSTASH_HOST>:5044"]
#   ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]

# Kibana setup
setup.kibana:
  host: "https://<KIBANA_HOST>:5601"
  username: "<USER>"
  password: "<PASSWORD>"

# Processors
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["agent.ephemeral_id", "agent.hostname"]
```

### Output Comparison

| Output | Use Case / Применение | Buffering / Буферизация | Notes / Примечания |
|--------|----------------------|------------------------|-------------------|
| Elasticsearch | Direct indexing / Прямая индексация | Yes | Simplest setup / Самый простой |
| Logstash | Complex processing / Сложная обработка | Yes (Logstash) | Transformation, enrichment / Трансформация |
| Kafka | High-volume buffering / Высоконагруженная буферизация | Yes (Kafka) | Best for large-scale / Для больших объёмов |
| Redis | Lightweight buffer / Лёгкий буфер | Yes (Redis) | Legacy, use Kafka instead / Устаревший |
| File | Local storage / Локальное хранение | No | Debug/testing / Отладка/тест |

> [!NOTE]
> **filestream vs log input:** The `filestream` input (introduced in 7.16) is the recommended replacement for the legacy `log` input. It provides better file tracking, native fingerprinting, and improved performance. / `filestream` — рекомендуемая замена для устаревшего `log` input.

---

## 2. Core Management

### Enable Built-in Modules

```bash
# List available modules
filebeat modules list

# Enable modules
filebeat modules enable system nginx apache mysql postgresql

# Disable module
filebeat modules disable apache

# View module config
cat /etc/filebeat/modules.d/system.yml
```

### Module Configuration Example

`/etc/filebeat/modules.d/system.yml`

```yaml
- module: system
  syslog:
    enabled: true
    var.paths: ["/var/log/syslog", "/var/log/messages"]
  auth:
    enabled: true
    var.paths: ["/var/log/auth.log", "/var/log/secure"]
```

### Setup Commands

```bash
# Setup index template
filebeat setup --index-management

# Setup Kibana dashboards
filebeat setup --dashboards

# Setup ILM policy
filebeat setup --ilm-policy

# Full setup (template + dashboards + ILM)
filebeat setup
```

---

## 3. Sysadmin Operations

### Service Management

```bash
systemctl start filebeat      # Start / Запустить
systemctl stop filebeat       # Stop / Остановить
systemctl restart filebeat    # Restart / Перезапустить
systemctl enable filebeat     # Enable on boot / Автозапуск
systemctl status filebeat     # Check status / Проверить статус
```

### Important Paths

| Path | Description / Описание |
|------|------------------------|
| `/etc/filebeat/filebeat.yml` | Main configuration / Основной конфиг |
| `/etc/filebeat/modules.d/` | Module configurations / Конфиги модулей |
| `/var/lib/filebeat/` | Data and registry / Данные и реестр |
| `/var/lib/filebeat/registry/` | File tracking registry / Реестр отслеживания файлов |
| `/var/log/filebeat/` | Filebeat logs / Логи Filebeat |

### Test Configuration

```bash
# Test config syntax
filebeat test config

# Test output connectivity
filebeat test output

# Run with debug output
filebeat -e -d "*"
```

---

## 4. Security

### TLS/SSL Configuration

`/etc/filebeat/filebeat.yml`

```yaml
# TLS to Elasticsearch / TLS
output.elasticsearch:
  hosts: ["https://<ES_HOST>:9200"]
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  ssl.certificate: "/etc/filebeat/filebeat.crt"
  ssl.key: "/etc/filebeat/filebeat.key"

# TLS to Logstash / TLS
output.logstash:
  hosts: ["<LOGSTASH_HOST>:5044"]
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  ssl.certificate: "/etc/filebeat/filebeat.crt"
  ssl.key: "/etc/filebeat/filebeat.key"
```

---

## 5. Troubleshooting & Tools

### Common Issues

#### 1. Filebeat Not Sending Data / Filebeat

```bash
# Check connectivity
filebeat test output

# Check config
filebeat test config

# Run in debug mode
filebeat -e -d "*" 2>&1 | head -100
```

#### 2. Duplicate Data

```bash
# Check registry state
cat /var/lib/filebeat/registry/filebeat/log.json | jq .

# Reset registry (resend all data)
systemctl stop filebeat
rm -rf /var/lib/filebeat/registry/
systemctl start filebeat
```

> [!CAUTION]
> Deleting the registry will cause Filebeat to re-read all log files from the beginning, potentially creating duplicate data. / Удаление реестра приведёт к повторному чтению всех файлов, что может создать дубликаты.

#### 3. High Memory Usage

```bash
# Limit bulk size and queue
# In filebeat.yml
# output.elasticsearch:
#   bulk_max_size: 50
# queue.mem:
#   events: 256
```

---

## 6. Logrotate Configuration

`/etc/logrotate.d/filebeat`

```conf
/var/log/filebeat/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

> [!TIP]
> Filebeat manages its own log rotation via `logging.files.rotateeverybytes` and `logging.files.keepfiles` in `filebeat.yml`. External logrotate is optional. / Filebeat управляет ротацией через `logging.files.rotateeverybytes`. Внешний logrotate опционален.

---

## Documentation Links

- **Official Documentation:** https://www.elastic.co/guide/en/beats/filebeat/current/index.html
- **Filebeat Modules:** https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-modules.html
- **Filebeat Configuration:** https://www.elastic.co/guide/en/beats/filebeat/current/configuring-howto-filebeat.html
- **Filestream Input:** https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-input-filestream.html
- **Beats Downloads:** https://www.elastic.co/downloads/beats/filebeat
- **GitHub:** https://github.com/elastic/beats

---
