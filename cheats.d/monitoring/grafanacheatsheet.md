---
Title: 📊 Grafana — Dashboards & Data Sources
Group: Monitoring
Icon: 📊
Order: 11
tags:
  - monitoring
  - grafana
  - dashboards
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

# 📊 Grafana Cheatsheet

## Description

**Grafana** is an open-source observability platform for visualizing metrics, logs, and traces from multiple data sources (Prometheus, VictoriaMetrics, Loki, Elasticsearch, MySQL, etc.). / **Grafana** — открытая платформа визуализации метрик, логов и трассировок из различных источников данных.

**Common use cases / Типовые сценарии:**
- Infra/service dashboards / Дашборды инфраструктуры и сервисов
- SLO/SLI monitoring with burn-rate / Мониторинг SLI/SLO
- Log exploration with Loki / Исследование логов через Loki
- Unified view across Prometheus/VictoryMetrics/SQL / Единый вид поверх нескольких СУБД

**Status:** Actively maintained (Grafana Labs / CNCF). Alternatives: **Kibana** (Elastic-centric), **Metabase** (BI-focused), **Netdata** (all-in-one). / **Статус:** активно развивается; альтернативы — Kibana, Metabase, Netdata.

**Default ports:** `3000/tcp` (HTTP).  
**Paths:** config `/etc/grafana/grafana.ini`; data `/var/lib/grafana`; plugins `/var/lib/grafana/plugins`.

Cross-reference: [Prometheus](prometheuscheatsheet.md), [VictoriaMetrics](victoriametricscheatsheet.md), [Kibana](../system-logs/kibanacheatsheet.md), [OpenSearch](../databases/opensearchcheatsheet.md).

---

## Installation

### Install Grafana / Установка Grafana

```bash
# Official APT repo (Debian/Ubuntu)
apt-get install -y apt-transport-https software-properties-common wget
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt update && apt install grafana

# RPM (RHEL/Rocky/Alma/Fedora)
cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
dnf install grafana
```

```bash
systemctl enable --now grafana-server
systemctl status grafana-server
```

---

## Configuration

### Main files / Основные файлы

`/etc/grafana/grafana.ini`

`/etc/grafana/provisioning/datasources/`

`/etc/grafana/provisioning/dashboards/`

`/var/lib/grafana/grafana.db` (SQLite default)

`/var/log/grafana/grafana.log`

### Key grafana.ini settings / Ключевые параметры grafana.ini

`/etc/grafana/grafana.ini`

```bash
[server]
http_port = 3000
domain = grafana.<DOMAIN>
root_url = https://grafana.<DOMAIN>/

[security]
admin_user = admin
admin_password = <SECRET_KEY>
cookie_secure = true
cookie_samesite = lax

[auth]
disable_login_form = false

[auth.proxy]
enabled = true
header_name = X-Email
auto_login = true

[analytics]
reporting_enabled = false
check_for_updates = false

[log]
mode = console file
level = info
```

### Provision Prometheus datasource / Провижининг datasource

`/etc/grafana/provisioning/datasources/prometheus.yml`

```bash
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://<PROMETHEUS_HOST>:9090
    isDefault: true
    editable: false
    jsonData:
      timeInterval: "15s"
```

### Provision dashboard provider / Провижининг дашбордов

`/etc/grafana/provisioning/dashboards/default.yml`

```bash
apiVersion: 1
providers:
  - name: default
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    updateIntervalSeconds: 60
    options:
      path: /etc/grafana/provisioning/dashboards/json
```

```bash
systemctl restart grafana-server
```

---

## Core Management

### Service and health / Сервис и health-check

```bash
systemctl status grafana-server
ss -lntp | grep 3000
curl -s http://127.0.0.1:3000/api/health
curl -s -u admin:<SECRET_KEY> http://127.0.0.1:3000/api/datasources | jq
```

Sample health output:

```json
{"database": "ok", "version": "11.x.x", "commit": "..."}
```

### grafana-cli / Управление плагинами

```bash
grafana-cli plugins list-remote
grafana-cli plugins install grafana-piechart-panel
grafana-cli plugins install grafana-clock-panel
grafana-cli plugins ls
grafana-cli plugins rm grafana-piechart-panel
systemctl restart grafana-server
```

### Import dashboards / Импорт дашбордов

```bash
# By Grafana.com ID via UI: + → Import → paste ID
# CLI import (requires HTTP API + admin)
curl -s -X POST -H "Content-Type: application/json" \
  -u admin:<SECRET_KEY> \
  -d '{"dashboard": <DASHBOARD_JSON>, "overwrite": true}' \
  http://127.0.0.1:3000/api/dashboards/db
```

### HTTP API essentials / Основы HTTP API

```bash
# Search dashboards
curl -s -u admin:<SECRET_KEY> 'http://127.0.0.1:3000/api/search?query=node' | jq

# Query Prometheus datasource
curl -s -u admin:<SECRET_KEY> -H "Content-Type: application/json" \
  -d '{"queries":[{"expr":"up","refId":"A"}],"from":"now-1h","to":"now"}' \
  http://127.0.0.1:3000/api/ds/query

# List orgs/users (admin)
curl -s -u admin:<SECRET_KEY> http://127.0.0.1:3000/api/org/users | jq
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u grafana-server --no-pager -n 50
tail -f /var/log/grafana/grafana.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/grafana`

```bash
/var/log/grafana/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 grafana grafana
    sharedscripts
    postrotate
        systemctl kill -s HUP grafana-server >/dev/null 2>&1 || true
    endscript
}
```

### SQLite maintenance / Обслуживание SQLite

```bash
# Offline maintenance only
systemctl stop grafana-server
cp /var/lib/grafana/grafana.db /var/lib/grafana/grafana.db.bak
sqlite3 /var/lib/grafana/grafana.db "VACUUM;"
systemctl start grafana-server
```

> [!NOTE]
> Large installations should use PostgreSQL/MySQL for the Grafana database instead of SQLite. / На больших установках используйте PostgreSQL/MySQL вместо SQLite.

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Change default `admin` password immediately / Смените пароль admin сразу
2. Enable HTTPS via reverse proxy (nginx/HAProxy) / Включите TLS через прокси
3. Restrict port 3000 to localhost or private network / Ограничьте доступ к 3000
4. Use SSO/OAuth (OIDC, LDAP) for humans / Используйте SSO для людей
5. Create service accounts + scoped API tokens for automation / API-токены для автоматизации
6. Disable public signup / Отключите публичную регистрацию
7. Review dashboard permissions / Проверьте права на дашборды
8. Keep plugins updated / Обновляйте плагины

```bash
# Example: force secure cookies and disable registration
# [security]
# cookie_secure = true
# [auth.anonymous]
# enabled = false
```

### API tokens / API-токены

```bash
# Create service account + token via UI or API
# Store tokens in secret manager — never in dashboards/repos
```

> [!CAUTION]
> Grafana API tokens can read all visible data sources. Scope them and rotate regularly. / Токены Grafana дают доступ к данным — ограничивайте и ротируйте.

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Stop service for consistent SQLite backup
systemctl stop grafana-server
cp /var/lib/grafana/grafana.db /var/backups/grafana.db.$(date +%F)
tar czf /var/backups/grafana-config-$(date +%F).tar.gz /etc/grafana
systemctl start grafana-server
```

### Restore / Восстановление

```bash
systemctl stop grafana-server
cp /var/backups/grafana.db.<DATE> /var/lib/grafana/grafana.db
tar xzf /var/backups/grafana-config-<DATE>.tar.gz -C /
chown -R grafana:grafana /var/lib/grafana /etc/grafana
systemctl start grafana-server
curl -s http://127.0.0.1:3000/api/health
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Invalid username or password` | Wrong admin creds / DB mismatch | Reset admin password via CLI |
| Datasource timeout | Prometheus down / firewall | Test `curl` to Prometheus from Grafana host |
| `Plugin not found` | Missing/outdated plugin | `grafana-cli plugins install` + restart |
| Dashboards empty after restore | Provisioning overwrite / wrong DB path | Check provisioning vs DB |
| High memory | Too many panels/series | Reduce query load; add recording rules |

```bash
grafana-cli admin reset-admin-password <NEW_PASSWORD>
journalctl -u grafana-server -f
curl -s http://127.0.0.1:3000/api/health
```

---

## Comparison Tables

### Visualization tools / Инструменты визуализации

| Tool | Strengths | Best for |
| :--- | :--- | :--- |
| **Grafana** | Multi-datasource, alerting | Metrics/logs/traces unified |
| **Kibana** | Elastic stack, full-text | Log analytics on ES/OpenSearch |
| **Metabase** | BI, SQL-friendly | Business questions on SQL DBs |
| **Netdata** | Real-time, low config | Single-node live metrics |

---

## Production Runbooks

### Runbook: New datasource + first dashboard / Новый источник и дашборд

1. Deploy and secure Grafana / Развернуть и защитить Grafana
2. Provision datasource YAML (Prometheus/VM) / Провижининг datasource
3. Verify API: `curl /api/datasources` / Проверить datasource
4. Import node-exporter / app dashboard from grafana.com / Импортировать дашборд
5. Save as folder with team permissions / Настроить права
6. Add basic alerts (CPU/mem/disk) / Добавить базовые алерты
7. Document dashboard UIDs for automation / Задокументировать UID

### Runbook: Password reset / Сброс пароля

1. Stop grafana-server / Остановить сервис
2. `grafana-cli admin reset-admin-password <NEW_PASSWORD>` / Сбросить пароль
3. Start service; login and change password in UI / Проверить вход
4. Rotate any leaked API tokens / Ротировать скомпрометированные токены

---

## Documentation Links

- Grafana docs — https://grafana.com/docs/grafana/latest/
- Grafana HTTP API — https://grafana.com/docs/grafana/latest/developers/http_api/
- Provisioning — https://grafana.com/docs/grafana/latest/administration/provisioning/
- grafana-cli — https://grafana.com/docs/grafana/latest/cli/
- Grafana Labs plugins — https://grafana.com/grafana/plugins/
