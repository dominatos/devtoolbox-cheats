---
Title: 🚚 Vector — Data Pipeline
Group: Monitoring
Icon: 🚚
Order: 14
tags:
  - monitoring
  - vector
  - logs
  - observability
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

# 🚚 Vector Cheatsheet

## Description

**Vector** (Datadog / CNCF) is a high-performance **observability data pipeline**: collect, transform, route logs, metrics, and traces to multiple sinks (Loki, Elasticsearch, S3, Datadog, etc.). / **Vector** — высокопроизводительный пайплайн наблюдаемости: сбор, трансформация и маршрутизация логов/метрик/трассировок в несколько sink.

**Common use cases / Типовые сценарии:**
- Multi-sink log routing (Loki + S3 + ELK) / Мульти-sink маршрутизация логов
- Enrichment and parsing before storage / Обогащение и парсинг перед записью
- Edge collection with backpressure control / Сбор на edge с контролем backpressure
- Metrics collection via host sources / Сбор метрик с хоста

**Status:** Actively maintained (Datadog, CNCF). Alternatives: **Promtail**, **Fluent Bit**, **Filebeat**, **Logstash**. / **Статус:** активно развивается; альтернативы — Promtail, Fluent Bit, Filebeat.

**Paths:** config `/etc/vector/vector.toml`; data `/var/lib/vector/`.

Cross-reference: [Loki](lokicheatsheet.md), [Promtail](promtailcheatsheet.md), [Filebeat](filebeatcheatsheet.md), [Telegraf](telegrafcheatsheet.md), [Grafana](grafanacheatsheet.md).

---

## Installation

### Install Vector / Установка Vector

```bash
# Debian/Ubuntu
curl -1sLf 'https://packages.timber.io/vector/setup.deb.sh' | sudo -E bash
apt install vector

# RHEL/Rocky/Alma
curl -1sLf 'https://packages.timber.io/vector/setup.rpm.sh' | sudo -E bash
dnf install vector

# Manual
VECTOR_VER=0.43.1
wget https://packages.timber.io/vector/${VECTOR_VER}/vector-${VECTOR_VER}-x86_64-unknown-linux-gnu.tar.gz
```

```bash
vector --version
systemctl enable --now vector
```

---

## Configuration

### Main files / Основные файлы

`/etc/vector/vector.toml`

`/etc/vector/vector.yaml`

`/var/lib/vector/`

### Minimal TOML config / Минимальная конфигурация TOML

`/etc/vector/vector.toml`

```bash
[data_dir]
path = "/var/lib/vector"

[sources.journal]
type = "journald"
current_boot_only = true

[sources.nginx]
type = "file"
include = ["/var/log/nginx/*log"]
read_from = "beginning"

[transforms.parse_nginx]
type = "remap"
inputs = ["nginx"]
source = '''
. = parse_json(.message) ?? .message
'''

[sinks.loki]
type = "loki"
inputs = ["journal", "parse_nginx"]
endpoint = "http://<LOKI_HOST>:3100"
encoding.codec = "json"

[sinks.s3_backup]
type = "aws_s3"
inputs = ["journal"]
bucket = "<S3_BUCKET>"
key_prefix = "vector/%Y-%m-%d/"
compression = "gzip"
```

```bash
vector validate --config /etc/vector/vector.toml
systemctl restart vector
```

---

## Core Management

### Status / Статус

```bash
vector top
vector tap --inputs journal --limit 10
curl -s http://127.0.0.1:8686/health
```

### Dry-run config / Проверка конфигурации

```bash
vector validate --config /etc/vector/vector.toml
vector config
```

---

## Sysadmin Operations

### Metrics / Метрики

```bash
curl -s http://127.0.0.1:9598/metrics | grep vector_ | head
```

### Logrotate / Ротация логов

`/etc/logrotate.d/vector`

```bash
/var/log/vector/*.log {
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

1. Run as non-root where possible / Запускайте от non-root
2. Restrict file source paths / Ограничьте пути file sources
3. Use least-privilege credentials for sinks / Минимальные права для sinks
4. Do not put secrets in config committed to Git / Секреты — не в Git
5. Validate transforms to avoid leaking PII / Проверяйте transforms на утечку PII

```bash
# AWS creds via env/instance role, not plaintext files
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/vector-config-$(date +%F).tar.gz /etc/vector
```

### Restore / Восстановление

```bash
systemctl stop vector
tar xzf /var/backups/vector-config-<DATE>.tar.gz -C /
systemctl start vector
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| No events in sink | Wrong path / permissions | `vector tap`; check file perms |
| High memory | Buffer growth | Tune `buffer.max_events`; check backpressure |
| Duplicate events | Multiple sources same file | Deduplicate inputs |
| Sink 401/403 | Creds/endpoint | Check sink auth config |
| Config validate fails | TOML syntax | `vector validate` |

```bash
journalctl -u vector --no-pager -n 50
vector top
vector validate --config /etc/vector/vector.toml
```

---

## Comparison Tables

### Observability pipelines / Пайплайны наблюдаемости

| Tool | Language | Strengths |
| :--- | :--- | :--- |
| **Vector** | Rust | High perf, multi-sink |
| **Promtail** | Go | Loki-native |
| **Fluent Bit** | C | Lightweight, plugins |
| **Filebeat** | Go | Elastic ecosystem |
| **Logstash** | JVM | Heavy transform power |

---

## Production Runbooks

### Runbook: Dual-ship logs to Loki + S3 / Двойная отправка в Loki + S3

1. Deploy Vector with journal + nginx sources / Развернуть Vector
2. Configure Loki sink and S3 sink / Настроить оба sink
3. Validate config; start service / Проверить и запустить
4. Verify events in Loki and S3 / Проверить оба sink
5. Add drop filters for noisy sources if needed / Добавить drop-фильтры
6. Document schema of labels/key_prefix / Зафиксировать схему labels

### Runbook: Pipeline overload / Перегрузка пайплайна

1. `vector top` — identify hot components / Найти горячие компоненты
2. Raise buffer or reduce noisy sources / Увеличить buffer / снизить шум
3. Drop debug-level logs in production / Отключить debug-логи в проде
4. Scale horizontally if needed / Горизонтально масштабировать
5. Verify sink recovery / Проверить восстановление sink

---

## Documentation Links

- Vector docs — https://vector.dev/docs/
- Vector GitHub — https://github.com/vectordotdev/vector
- Vector → Loki — https://vector.dev/docs/reference/configuration/sinks/loki/
- Vector remap — https://vector.dev/docs/reference/configuration/transforms/remap/
