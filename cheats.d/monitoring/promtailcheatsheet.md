---
Title: 📤 Promtail — Log Shipper
Group: Monitoring
Icon: 📤
Order: 13
tags:
  - monitoring
  - promtail
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
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 📤 Promtail Cheatsheet

## Description

**Promtail** is the official **log shipper for Loki**. It tails log files, adds labels (static + discovered), and pushes batches to Loki's push API. Replaced in newer stacks by **Grafana Alloy**, but Promtail remains widely deployed. / **Promtail** — официальный шиппер Loki: читает логи, добавляет labels и отправляет в Loki. В новых стеках часто заменён **Grafana Alloy**, но Promtail остаётся распространённым.

**Common use cases / Типовые сценарии:**
- Ship systemd/journal logs to Loki / Отправка журналов в Loki
- Kubernetes pod log collection (node_exporter-style) / Сбор логов подов Kubernetes
- Label enrichment before ingest / Обогащение labels перед ingest
- Local debugging of log pipelines / Отладка лог-пайплайнов

**Status:** Maintained but Alloy is the preferred successor for new deployments. / **Статус:** поддерживается; для новых deployments предпочтителен Alloy.

**Paths:** config `/etc/promtail/config.yml`; positions file `/var/lib/promtail/positions.yaml`.

Cross-reference: [Loki](lokicheatsheet.md), [Vector](vectorcheatsheet.md), [Filebeat](filebeatcheatsheet.md), [Grafana](grafanacheatsheet.md).

---

## Installation

### Install Promtail / Установка Promtail

```bash
PROMTAIL_VER=3.1.1
wget https://github.com/grafana/loki/releases/download/v${PROMTAIL_VER}/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
install -m755 promtail-linux-amd64 /usr/local/bin/promtail
```

```bash
promtail --version
systemctl enable --now promtail
```

---

## Configuration

### Main files / Основные файлы

`/etc/promtail/config.yml`

`/var/lib/promtail/positions.yaml`

### Minimal config / Минимальная конфигурация

`/etc/promtail/config.yml`

```bash
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: http://<LOKI_HOST>:3100/loki/api/v1/push
    # tenant_id: <TENANT>   # if auth_enabled

scrape_configs:
  - job_name: journal
    journal:
      path: /var/log/journal
      labels:
        job: systemd
        host: <HOST>
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: unit

  - job_name: syslog
    static_configs:
      - targets: []
        labels:
          job: syslog
          host: <HOST>
          __path__: /var/log/syslog

  - job_name: app-nginx
    static_configs:
      - targets: []
        labels:
          job: nginx
          app: <APP_NAME>
          __path__: /var/log/nginx/*log
```

```bash
promtail -config.file=/etc/promtail/config.yml -config.check
systemctl restart promtail
```

---

## Core Management

### Status / Статус

```bash
curl -s http://127.0.0.1:9080/ready
curl -s http://127.0.0.1:9080/metrics | grep promtail_ | head
```

### Dry-run / Пробный запуск

```bash
promtail -config.file=/etc/promtail/config.yml -dry-run
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u promtail --no-pager -n 50
```

### Logrotate / Ротация логов

`/etc/logrotate.d/promtail`

```bash
/var/log/promtail/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Security

### Hardening / Ужесточение

1. Read-only access to log paths / Только чтение путей логов
2. Use tenant header if Loki multi-tenant / Передавайте tenant_id при multi-tenant
3. Restrict who can change positions file / Ограничьте доступ к positions.yaml
4. Do not ship secrets into labels / Не кладите секреты в labels
5. Prefer Alloy for new installs (security fixes) / Для новых установок предпочтителен Alloy

```bash
# Basic auth to Loki (via reverse proxy)
# clients[].url with embedded creds is discouraged — use proxy
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Promtail not shipping | Loki URL down / firewall | `curl` Loki from Promtail host |
| Missing logs after restart | positions.yaml issue | Check positions file ownership |
| High CPU | Too many files / parsers | Reduce scrape_configs; simplify pipeline |
| Duplicate logs | positions reset | Ensure positions volume persistent |
| 401/403 from Loki | Auth/tenant | Configure tenant_id / proxy auth |

```bash
journalctl -u promtail -f
curl -s http://127.0.0.1:9080/ready
ls -la /var/lib/promtail/positions.yaml
```

---

## Comparison Tables

### Log shippers / Лог-шипперы

| Shipper | Ecosystem | Notes |
| :--- | :--- | :--- |
| **Promtail** | Loki | Official Loki shipper |
| **Alloy** | Loki/Grafana | Preferred successor |
| **Vector** | Multi-sink | High-performance, multi-target |
| **Filebeat** | Elastic | Strong Elastic integration |
| **Fluent Bit** | Multi | Lightweight, popular |

---

## Production Runbooks

### Runbook: Add new log source / Новый источник логов

1. Confirm file path exists and is readable / Проверить путь и права
2. Add scrape_configs entry with labels / Добавить scrape_config с labels
3. `promtail -config.check` / Проверить конфигурацию
4. Restart Promtail / Перезапустить Promtail
5. Verify in Loki: `{job="<JOB>"}` / Проверить выборку в Loki
6. Document expected labels / Зафиксировать labels

### Runbook: Migrate Promtail to Alloy / Миграция Promtail → Alloy

1. Deploy Alloy alongside Promtail / Развернуть Alloy параллельно
2. Translate scrape_configs to Alloy components / Перенести scrape_configs
3. Dual-ship and compare queries / Двойная отправка и сравнение
4. Cut DNS/agents to Alloy / Переключить на Alloy
5. Disable Promtail; keep config for rollback / Отключить Promtail

---

## Documentation Links

- Promtail — https://grafana.com/docs/loki/latest/send-data/promtail/
- Promtail config — https://grafana.com/docs/loki/latest/send-data/promtail/configuration/
- Grafana Alloy — https://grafana.com/docs/alloy/latest/
- Loki — https://grafana.com/docs/loki/latest/
