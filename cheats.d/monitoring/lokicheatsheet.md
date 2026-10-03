---
Title: 🟣 Loki — Log Aggregation
Group: Monitoring
Icon: 🟣
Order: 12
tags:
  - monitoring
  - loki
  - logs
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🟣 Loki Cheatsheet

## Description

**Loki** is a horizontally scalable, multi-tenant **log aggregation system** (Grafana Labs / CNCF ecosystem). Unlike Elasticsearch, it indexes only metadata (labels), not full-text of logs — cheaper to operate. / **Loki** — масштабируемая мультиарендная система агрегации логов. Индексирует только метаданные (labels), а не полный текст — дешевле в эксплуатации, чем Elasticsearch.

**Common use cases / Типовые сценарии:**
- Cheap central logging with Prometheus-style labels / Дешёвый централизованный сбор логов
- Kubernetes log aggregation with Promtail/Alloy / Сбор логов Kubernetes
- LogQL queries in Grafana / Запросы LogQL в Grafana
- Retention-tiered log storage / Хранение логов по retention-политике

**Status:** Actively maintained (Grafana Labs, CNCF). Alternatives: **Elasticsearch/OpenSearch**, **ClickHouse**, **VictoriaLogs**, **Splunk**. / **Статус:** активно развивается; альтернативы — Elasticsearch/OpenSearch, ClickHouse, VictoriaLogs.

**Default ports:** `3100/tcp` (HTTP API/ingest).  
**Paths:** config `/etc/loki/local-config.yaml`; data `/var/lib/loki/`.

Cross-reference: [Promtail](promtailcheatsheet.md), [Vector](vectorcheatsheet.md), [Grafana](grafanacheatsheet.md), [Prometheus](prometheuscheatsheet.md), [Filebeat](filebeatcheatsheet.md).

---

## Installation

### Install Loki / Установка Loki

```bash
# Manual
LOKI_VER=3.1.1
wget https://github.com/grafana/loki/releases/download/v${LOKI_VER}/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
install -m755 loki-linux-amd64 /usr/local/bin/loki
```

```bash
loki --version
systemctl enable --now loki
systemctl status loki
```

---

## Configuration

### Main files / Основные файлы

`/etc/loki/local-config.yaml`

`/etc/loki/config.yaml`

`/var/lib/loki/`

### Local single-binary config / Конфигурация single-binary

`/etc/loki/local-config.yaml`

```bash
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  retention_period: 720h

compactor:
  working_directory: /var/lib/loki/compactor
  retention_enabled: true
  delete_request_store: filesystem

analytics:
  reporting_enabled: false
```

```bash
systemctl restart loki
```

---

## Core Management

### Status / Статус

```bash
curl -s http://127.0.0.1:3100/ready
curl -s http://127.0.0.1:3100/loki/api/v1/status/buildinfo
curl -s http://127.0.0.1:3100/metrics | grep loki_ | head
```

### LogQL / LogQL

```bash
# Instant query
curl -G --data-urlencode 'query={job="systemd"} |~ "error"' \
  http://127.0.0.1:3100/loki/api/v1/query

# Range query
curl -G --data-urlencode 'query={app="nginx"} |= "GET" | json | status=500' \
  --data-urlencode 'start=now-1h' --data-urlencode 'end=now' \
  http://127.0.0.1:3100/loki/api/v1/query_range

# Labels
curl -s http://127.0.0.1:3100/loki/api/v1/labels
curl -s http://127.0.0.1:3100/loki/api/v1/label/job/values
```

### Push API / Push API

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": { "job": "manual", "host": "<HOST>" },
        "values": [ [ "'$(date +%s%N)'", "hello from curl" ] ]
      }
    ]
  }' \
  http://127.0.0.1:3100/loki/api/v1/push
```

---

## Sysadmin Operations

### Logrotate / Ротация логов

`/etc/logrotate.d/loki`

```bash
/var/log/loki/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 loki loki
}
```

### Disk / Диск

```bash
du -sh /var/lib/loki
df -h /var/lib/loki
```

---

## Security

### Hardening / Ужесточение

1. Enable auth (tenant ID / basic auth / proxy) / Включите аутентификацию
2. Bind to localhost or private NIC; front with reverse proxy / Ограничьте bind
3. Restrict push/query endpoints / Ограничьте push/query
4. Set retention and max stream limits / Задайте retention и limits
5. Do not log secrets in labels / Не логируйте секреты в labels

```bash
# auth_enabled: true
# tenant_ids: <TENANT_A>,<TENANT_B>
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
systemctl stop loki
tar czf /var/backups/loki-$(date +%F).tar.gz /var/lib/loki /etc/loki
systemctl start loki
```

### Restore / Восстановление

```bash
systemctl stop loki
tar xzf /var/backups/loki-<DATE>.tar.gz -C /
systemctl start loki
curl -s http://127.0.0.1:3100/ready
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Push 400/429 | Limits / sample age | Check `limits_config` |
| Empty queries | Wrong labels / stream gone | Verify label matchers |
| Disk full | No retention | Enable retention/compactor |
| Ready=false | WAL/storage issue | Check journalctl -u loki |
| High ingest CPU | Too many streams | Reduce label cardinality |

```bash
journalctl -u loki --no-pager -n 50
curl -s http://127.0.0.1:3100/ready
curl -s http://127.0.0.1:3100/loki/api/v1/labels
```

---

## Comparison Tables

### Log platforms / Лог-платформы

| System | Indexing | Ops cost | Best for |
| :--- | :--- | :--- | :--- |
| **Loki** | Labels only | Low | Prometheus-style log ops |
| **Elasticsearch** | Full-text | High | Rich search/analyst UX |
| **ClickHouse** | Structured | Medium | Analytics on logs |
| **VictoriaLogs** | Structured | Low | VictoriaMetrics ecosystem |
| **Splunk** | Full-text | Very high | Enterprise SIEM |

---

## Production Runbooks

### Runbook: Standalone Loki + Grafana / Одиночный Loki + Grafana

1. Deploy Loki with filesystem storage / Развернуть Loki
2. Configure retention in local-config.yaml / Настроить retention
3. Point Promtail/Alloy at Loki / Настроить Promtail/Alloy
4. Add Grafana Loki datasource / Подключить datasource в Grafana
5. Verify with LogQL query in Grafana / Проверить запросом LogQL
6. Document retention and disk growth expectations / Зафиксировать retention и рост диска

### Runbook: Disk filling / Заполнение диска

1. Check `/var/lib/loki` usage / Проверить использование
2. Confirm retention is enabled / Убедиться, что retention включён
3. Reduce `retention_period` if policy allows / Уменьшить retention_period
4. Compactor run; wait for delete delay / Запустить компактор
5. Add capacity if logs are long-term / При необходимости масштабировать диск

---

## Documentation Links

- Loki docs — https://grafana.com/docs/loki/latest/
- LogQL — https://grafana.com/docs/loki/latest/query/
- Loki GitHub — https://github.com/grafana/loki
- Promtail — https://grafana.com/docs/loki/latest/send-data/promtail/
