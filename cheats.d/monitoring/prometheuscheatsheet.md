---
Title: 📈 Prometheus — Metrics & PromQL
Group: Monitoring
Icon: 📈
Order: 10
tags:
  - monitoring
  - prometheus
  - promql
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

# 📈 Prometheus Cheatsheet

## Description

**Prometheus** is an open-source **pull-based** metrics collection and TSDB system (CNCF). Scrapers poll HTTP `/metrics` endpoints; **PromQL** queries time series; **Alertmanager** routes alerts. / **Prometheus** — система сбора метрик (pull-модель) и TSDB из CNCF. Скрейперы опрашивают `/metrics`, запросы — PromQL, алерты — Alertmanager.

**Common use cases / Типовые сценарии:**
- Infra/service metrics + SLO dashboards / Метрики инфраструктуры и SLI/SLO
- Node/systemd/container observability / Наблюдаемость узлов, systemd, контейнеров
- Feeding Grafana / VictoriaMetrics / Источник данных для Grafana/VM
- Capacity planning and burn-rate alerts / Планирование ресурсов и burn-rate алерты

**Status:** Actively maintained industry default. Alternatives: **VictoriaMetrics** (compatible, higher performance), **Thanos/Cortex/Mimir** (HA/long-term), **InfluxDB** (general TSDB). / **Статус:** стандарт индустрии; альтернативы — VictoriaMetrics, Thanos/Mimir.

**Default ports:** `9090/tcp` (web UI + API).  
**Storage:** local TSDB under `--storage.tsdb.path` (default `/prometheus` or distro-specific).

Cross-reference: [Grafana](grafanacheatsheet.md), [VictoriaMetrics](victoriametricscheatsheet.md), [Telegraf](telegrafcheatsheet.md), [Node exporter](telegrafcheatsheet.md).

---

## Installation

### Install Prometheus / Установка

```bash
# RHEL/Rocky/Alma
dnf install prometheus
systemctl enable --now prometheus

# Debian/Ubuntu (may need backports or official repo)
apt install prometheus
systemctl enable --now prometheus

# Official tarball
PROM_VER=2.53.0
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
tar xzf prometheus-${PROM_VER}.linux-amd64.tar.gz
install -m755 prometheus-${PROM_VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
```

```bash
prometheus --version
promtool --version
```

---

## Configuration

### Main files / Основные файлы

`/etc/prometheus/prometheus.yml`

`/etc/prometheus/rules.yml`

`/etc/prometheus/alerts.yml`

`/var/lib/prometheus/` (TSDB data)

### Minimal scrape config / Минимальный scrape config

`/etc/prometheus/prometheus.yml`

```bash
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: <CLUSTER_NAME>
    env: production

rule_files:
  - /etc/prometheus/rules.yml
  - /etc/prometheus/alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - <ALERTMANAGER_HOST>:9093

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: node
    static_configs:
      - targets:
          - <NODE_EXPORTER_HOST>:9100

  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://<HOST>
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: <BLACKBOX_EXPORTER_HOST>:9115
```

### systemd unit notes / Заметки по systemd unit

`/etc/systemd/system/prometheus.service.d/override.conf`

```ini
[Service]
ExecStart=
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=15d \
  --web.listen-address=127.0.0.1:9090
```

```bash
systemctl daemon-reload
systemctl restart prometheus
```

### Reload config / Перезагрузка конфига

```bash
kill -HUP $(pidof prometheus)   # or: curl -X POST http://127.0.0.1:9090/-/reload
promtool check config /etc/prometheus/prometheus.yml
promtool check rules /etc/prometheus/rules.yml
```

---

## Core Management

### Status and UI / Статус и UI

```bash
systemctl status prometheus
ss -lntp | grep 9090
curl -s http://127.0.0.1:9090/-/healthy
curl -s http://127.0.0.1:9090/-/ready
curl -s http://127.0.0.1:9090/api/v1/status/config | head
```

### Targets / Цели скрейпа

```bash
curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | {job, health, lastError}'
```

### PromQL essentials / Основы PromQL

```bash
# Instant queries (via API)
curl -G --data-urlencode 'query=node_cpu_seconds_total' http://127.0.0.1:9090/api/v1/query

# Range query (5m samples, step 1m)
curl -G --data-urlencode 'query=rate(node_cpu_seconds_total[5m])' \
  --data-urlencode 'start=now-1h' --data-urlencode 'end=now' --data-urlencode 'step=1m' \
  http://127.0.0.1:9090/api/v1/query_range

# CPU utilisation (all cores)
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory used %
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk free %
100 * (1 - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"})

# HTTP error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Top 10 CPU consumers
topk(10, sum by (instance) (rate(process_cpu_seconds_total[5m])))
```

### Recording and alerting rules / Recording & alerting rules

`/etc/prometheus/rules.yml`

```bash
groups:
  - name: recording
    interval: 30s
    rules:
      - record: instance:node_cpu_utilisation:rate5m
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
      - record: instance:node_memory_utilisation:ratio
        expr: 1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

`/etc/prometheus/alerts.yml`

```bash
groups:
  - name: node-alerts
    rules:
      - alert: NodeHighCPU
        expr: instance:node_cpu_utilisation:rate5m > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
      - alert: NodeDiskFilling
        expr: 100 * (1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) > 90
        for: 15m
        labels:
          severity: critical
```

```bash
promtool check rules /etc/prometheus/alerts.yml
# Reload after check
curl -X POST http://127.0.0.1:9090/-/reload
```

---

## Sysadmin Operations

### Common exporters / Основные экспортеры

| Exporter | Port | Metric family |
| :--- | :---: | :--- |
| node_exporter | 9100 | CPU/mem/disk/net |
| process-exporter | 9256 | Process groups |
| blackbox_exporter | 9115 | Probe HTTP/TCP/ICMP/DNS |
| mysqld_exporter | 9104 | MySQL/MariaDB |
| postgres_exporter | 9187 | PostgreSQL |
| redis_exporter | 9121 | Redis |
| nginx-exporter | 9113 | nginx stub_status |
| snmp_exporter | 9116 | Network devices |
| kube-state-metrics | 8080 | K8s objects |

### Disk usage / Использование диска

```bash
du -sh /var/lib/prometheus
df -h /var/lib/prometheus
# Reduce retention if disk grows: --storage.tsdb.retention.time=15d
```

### Logrotate / Ротация логов

`/etc/logrotate.d/prometheus`

```bash
/var/log/prometheus/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0644 prometheus prometheus
}
```

> Note: TSDB files are managed by Prometheus retention, not logrotate. / Файлы TSDB управляются retention Prometheus, а не logrotate.

---

## Security

### Hardening / Ужесточение

1. Bind UI/API to localhost or private NIC / Слушайте только localhost/VPC
2. Put reverse proxy + TLS in front / Проксируйте через nginx/HAProxy с TLS
3. Restrict who can POST `/-/reload` / Ограничьте доступ к reload
4. Do not scrape secrets endpoints on public interfaces / Не выставляйте метрики наружу без ACL
5. Use TLS for scrape when crossing networks / TLS для скрейпа между сетями
6. Keep `--web.enable-admin-api` off unless needed / Не включайте admin-api без нужды

```bash
# Example: local bind only
--web.listen-address=127.0.0.1:9090
```

### Alertmanager security / Безопасность Alertmanager

```bash
# Alertmanager often listens on 9093 — lock down and front with auth proxy
# Avoid exposing chat webhook secrets in process listings
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Snapshot API (if enabled) or stop service and tar data dir
curl -X POST http://127.0.0.1:9090/api/v1/admin/tsdb/snapshot
# Snapshot under storage path/snapshots/<id>

# Config backup
tar czf /var/backups/prometheus-config-$(date +%F).tar.gz \
  /etc/prometheus
```

### Restore / Восстановление

```bash
systemctl stop prometheus
# Restore data dir or snapshot; restore /etc/prometheus
systemctl start prometheus
curl -s http://127.0.0.1:9090/-/ready
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Targets down | Network/firewall/exporter not running | Check scrape job, `ss -lntp` |
| `context deadline exceeded` scrape timeout | Slow target | Increase scrape_timeout carefully |
| OOM / disk full | Unbounded cardinality / long retention | Lower retention; fix label cardinality |
| Config reload fails | YAML/promtool errors | `promtool check config` |
| Alert not firing | `for:` duration / rule not loaded | Check `/api/v1/rules`, Alertmanager |
| High TSDB memory | Too many series | Audit jobs/labels; reduce scrape jobs |

```bash
promtool check config /etc/prometheus/prometheus.yml
promtool query instant http://127.0.0.1:9090 'up'
journalctl -u prometheus --no-pager -n 50
```

---

## Comparison Tables

### Metrics stacks / Стеки метрик

| System | Model | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Prometheus** | Pull | PromQL, ecosystem | Local TSDB scaling |
| **VictoriaMetrics** | Pull + VM | Fast, Prometheus-compatible | Different ops model |
| **Thanos/Mimir** | Global | HA + long-term | Complexity |
| **InfluxDB** | Push | General TSDB | Different query language |
| **Datadog/Cloud** | SaaS | Full platform | Cost, vendor lock-in |

---

## Production Runbooks

### Runbook: Add new exporter scrape / Добавление нового экспортера

1. Deploy exporter on target host / Развернуть экспортер
2. Confirm `/metrics` responds locally / Проверить endpoint
3. Add `scrape_configs` job in prometheus.yml / Добавить job
4. `promtool check config` + reload / Проверить и перезагрузить
5. Confirm target `up` in UI/API / Убедиться, что цель поднята
6. Add dashboard + basic alerts / Добавить дашборд и алерты

### Runbook: Capacity incident (disk/memory) / Инцидент по ресурсам TSDB

1. Check TSDB size and retention / Проверить размер и retention
2. Identify high-cardinality jobs (`count by (job)`) / Найти «тяжёлые» jobs
3. Reduce retention or move cold metrics to VM / Уменьшить retention
4. Add recording rules instead of raw high-card queries / Ввести recording rules
5. Scale disk or external storage before next peak / Масштабировать диск/хранилище

---

## Documentation Links

- Prometheus docs — https://prometheus.io/docs/introduction/overview/
- PromQL — https://prometheus.io/docs/prometheus/latest/querying/basics/
- Exporters overview — https://prometheus.io/docs/instrumenting/exporters/
- Alerting rules — https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- Blackbox exporter — https://github.com/prometheus/blackbox_exporter
- Grafana — https://grafana.com/docs/grafana/latest/
