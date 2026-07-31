---
Title: 📈 VictoriaMetrics
Group: Monitoring
Icon: 📈
Order: 8
tags:
  - monitoring
  - sysadmin
  - linux
---

# VictoriaMetrics Sysadmin Cheatsheet

> **VictoriaMetrics** is an open-source, high-performance time series database (TSDB) and monitoring solution developed by VictoriaMetrics Inc. First released in 2018, it is designed as a cost-effective, scalable, long-term storage backend for Prometheus and other monitoring systems. VictoriaMetrics uses an advanced compression algorithm achieving ~0.4 bytes per data point.
>
> **Common use cases / Типичные сценарии:** Long-term Prometheus metrics storage, high-cardinality metrics handling, Grafana data source, multi-tenant metrics platform, Prometheus federation replacement, IoT metrics collection, cost-effective alternative to commercial TSDBs.
>
> **Status / Статус:** Actively developed and rapidly growing in adoption. VictoriaMetrics is a modern, high-performance alternative to Prometheus TSDB. Alternatives include **Prometheus** (reference implementation, limited retention), **Thanos** (Prometheus HA + long-term), **Cortex/Mimir** (Grafana Labs, horizontally scalable), **InfluxDB** (general-purpose TSDB), **TimescaleDB** (PostgreSQL-based TSDB).
>
> **Default ports / Порты по умолчанию:** Single-node: `8428` | vmselect: `8481` | vminsert: `8480` | vmstorage: `8482` | vmui: `8428/vmui` | vmagent: `8429`

---

## 📚 Table of Contents

- [1. Installation & Configuration](#1.%20Installation%20&%20Configuration)
- [2. Core Management](#2.%20Core%20Management)
- [3. Sysadmin Operations](#3.%20Sysadmin%20Operations)
- [4. Security](#4.%20Security)
- [5. Backup & Restore](#5.%20Backup%20&%20Restore)
- [6. Troubleshooting & Tools](#6.%20Troubleshooting%20&%20Tools)
- [7. Logrotate Configuration](#7.%20Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## 1. Installation & Configuration

### Deployment Modes Comparison

| Mode | Components | Use Case / Применение |
|------|-----------|----------------------|
| Single-node | `victoria-metrics` | Up to millions of metrics/sec, simple setup / Простая настройка, до миллионов метрик/с |
| Cluster | `vminsert` + `vmstorage` + `vmselect` | Horizontal scaling, high availability / Горизонтальное масштабирование, HA |
| vmagent | `vmagent` (standalone) | Prometheus-compatible scraper/forwarder / Prometheus-совместимый сборщик |

> [!NOTE]
> **Single-node vs Cluster:** Start with single-node. It handles up to 10M+ metrics/sec on modern hardware. Only use cluster mode when you need horizontal scaling or multi-tenancy. / Начинайте с single-node. Он обрабатывает до 10M+ метрик/с. Кластер нужен только для горизонтального масштабирования или мультитенантности.

### Install Single-Node

```bash
# Download latest release
RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep tag_name | cut -d '"' -f 4)
wget "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${RELEASE}/victoria-metrics-linux-amd64-${RELEASE}.tar.gz"

# Extract and install
tar -xzf victoria-metrics-linux-amd64-*.tar.gz
mv victoria-metrics-prod /usr/local/bin/victoria-metrics
chmod +x /usr/local/bin/victoria-metrics
```

### Systemd Service

`/etc/systemd/system/victoria-metrics.service`

```ini
[Unit]
Description=VictoriaMetrics
After=network.target

[Service]
Type=simple
User=victoriametrics
Group=victoriametrics
ExecStart=/usr/local/bin/victoria-metrics \
  -storageDataPath=/var/lib/victoria-metrics \
  -retentionPeriod=12 \
  -httpListenAddr=:8428 \
  -promscrape.config=/etc/victoria-metrics/scrape.yml
ExecStop=/bin/kill -s SIGTERM $MAINPID
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
# Create user and directories
useradd -r -s /sbin/nologin victoriametrics
mkdir -p /var/lib/victoria-metrics /etc/victoria-metrics
chown victoriametrics:victoriametrics /var/lib/victoria-metrics

# Enable and start
systemctl daemon-reload
systemctl enable --now victoria-metrics
```

### Main Configuration (CLI Flags)

```bash
# Key flags
victoria-metrics \
  -storageDataPath=/var/lib/victoria-metrics \   # Data directory / Каталог данных
  -retentionPeriod=12 \                          # Retention in months / Хранение в месяцах
  -httpListenAddr=:8428 \                        # Listen address / Адрес прослушивания
  -promscrape.config=/etc/victoria-metrics/scrape.yml \  # Scrape config / Конфиг сбора
  -search.maxUniqueTimeseries=300000 \           # Max unique series / Максимум уникальных серий
  -search.maxStalenessInterval=5m \              # Staleness interval / Интервал устаревания
  -memory.allowedPercent=60                      # Memory limit % / Лимит памяти %
```

### Prometheus Scrape Configuration

`/etc/victoria-metrics/scrape.yml`

```yaml
scrape_configs:
  - job_name: 'node-exporter'
    scrape_interval: 15s
    static_configs:
      - targets:
          - '<HOST_1>:9100'
          - '<HOST_2>:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '(.+):.*'
        replacement: '${1}'

  - job_name: 'victoriametrics'
    static_configs:
      - targets: ['localhost:8428']
```

### Install vmagent

```bash
# vmagent is a lightweight Prometheus-compatible scraper / vmagent —
wget "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${RELEASE}/vmutils-linux-amd64-${RELEASE}.tar.gz"
tar -xzf vmutils-linux-amd64-*.tar.gz
mv vmagent-prod /usr/local/bin/vmagent
```

`/etc/systemd/system/vmagent.service`

```ini
[Unit]
Description=VictoriaMetrics Agent
After=network.target

[Service]
Type=simple
User=victoriametrics
ExecStart=/usr/local/bin/vmagent \
  -promscrape.config=/etc/victoria-metrics/scrape.yml \
  -remoteWrite.url=http://<VM_HOST>:8428/api/v1/write
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 2. Core Management

### Web UI & API

```bash
http://<HOST>:8428/vmui       # Built-in query UI / Встроенный UI запросов
http://<HOST>:8428/metrics    # Internal metrics / Внутренние метрики
http://<HOST>:8428/targets    # Scrape targets / Цели сбора
http://<HOST>:8428/api/v1/    # Prometheus-compatible API / Prometheus-совместимый API
```

### Query API (Prometheus-compatible) / API

```bash
# Instant query
curl -s "http://<HOST>:8428/api/v1/query?query=up"

# Range query
curl -s "http://<HOST>:8428/api/v1/query_range?query=up&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60"

# List all metric names
curl -s "http://<HOST>:8428/api/v1/label/__name__/values" | jq .

# List label values
curl -s "http://<HOST>:8428/api/v1/label/job/values" | jq .

# Series count
curl -s "http://<HOST>:8428/api/v1/series/count" | jq .

# TSDB status (cardinality)
curl -s "http://<HOST>:8428/api/v1/status/tsdb" | jq .
```

### Data Import/Export

```bash
# Import data in Prometheus format
curl -d 'metric_name{label="value"} 123 1609459200000' http://<HOST>:8428/api/v1/import/prometheus

# Export data in JSON
curl -s "http://<HOST>:8428/api/v1/export?match[]={__name__=~'cpu.*'}&start=-1h" | head

# Export to CSV
curl -s "http://<HOST>:8428/api/v1/export/csv?format=__name__,__value__,__timestamp__&match[]={job='node-exporter'}&start=-1h"
```

### MetricsQL vs PromQL / MetricsQL

| Feature | PromQL | MetricsQL |
|---------|--------|-----------|
| Range functions / Функции диапазона | `rate()`, `irate()` | `rate()`, `irate()` + auto lookbehind |
| Rollup functions / Функции свёртки | Limited | `rollup()`, `rollup_rate()`, `rollup_delta()` |
| Keep metric names / Сохранение имён | No / Нет | `keep_metric_names` modifier |
| Label manipulation / Манипуляция метками | `label_replace` | `label_set`, `label_del`, `label_copy` + more |
| Default lookbehind / Окно по умолчанию | Must specify / Указывать обязательно | Auto from scrape interval / Автоматически из интервала сбора |
| Subqueries / Подзапросы | Limited | Full support / Полная поддержка |

---

## 3. Sysadmin Operations

### Service Management

```bash
systemctl start victoria-metrics      # Start / Запустить
systemctl stop victoria-metrics       # Stop / Остановить
systemctl restart victoria-metrics    # Restart / Перезапустить
systemctl enable victoria-metrics     # Enable on boot / Автозапуск
systemctl status victoria-metrics     # Check status / Проверить статус
```

### Important Paths

| Path | Description / Описание |
|------|------------------------|
| `/usr/local/bin/victoria-metrics` | Main binary / Основной бинарник |
| `/usr/local/bin/vmagent` | Agent binary / Бинарник агента |
| `/var/lib/victoria-metrics/` | Data storage / Хранилище данных |
| `/etc/victoria-metrics/scrape.yml` | Scrape config / Конфиг сбора |
| System journal | Logs (via journalctl) / Логи |

### Retention & Storage

```bash
# Check storage size
du -sh /var/lib/victoria-metrics/

# Check internal VM stats
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '{totalSeries, totalDatapoints, retentionMonths: .retentionMonths}'

# Force merge (compact storage)
curl -s http://<HOST>:8428/internal/force_merge
```

> [!TIP]
> VictoriaMetrics achieves ~0.4 bytes per data point on average with compression. For 1M active series at 15s intervals, expect ~15GB/month. / VictoriaMetrics сжимает до ~0.4 байт на точку. Для 1М серий с интервалом 15с ожидайте ~15ГБ/мес.

### Firewall Configuration

```bash
# Single-node
firewall-cmd --permanent --add-port=8428/tcp   # VM data + query / Данные и запросы
firewall-cmd --permanent --add-port=8429/tcp   # vmagent

# Cluster mode
firewall-cmd --permanent --add-port=8480/tcp   # vminsert
firewall-cmd --permanent --add-port=8481/tcp   # vmselect
firewall-cmd --permanent --add-port=8482/tcp   # vmstorage
firewall-cmd --reload
```

---

## 4. Security

### Authentication

> [!NOTE]
> VictoriaMetrics single-node doesn't have built-in auth. Use a reverse proxy (nginx, caddy) with basic auth or vmauth. / VictoriaMetrics single-node не имеет встроенной аутентификации. Используйте обратный прокси или vmauth.

```bash
# vmauth config example
cat > /etc/victoria-metrics/vmauth.yml << 'EOF'
users:
  - username: <USER>
    password: <PASSWORD>
    url_prefix: http://localhost:8428
  - bearer_token: <TOKEN>
    url_prefix: http://localhost:8428
EOF

# Start vmauth
vmauth -auth.config=/etc/victoria-metrics/vmauth.yml -httpListenAddr=:8427
```

---

## 5. Backup & Restore

### Snapshot-Based Backup

```bash
# Create snapshot
curl -s http://<HOST>:8428/snapshot/create | jq .
# Output: {"status":"ok","snapshot":"20240101T120000Z-abc123"}

# List snapshots
curl -s http://<HOST>:8428/snapshot/list | jq .

# Backup snapshot using vmbackup
vmbackup -storageDataPath=/var/lib/victoria-metrics \
  -snapshot.createURL=http://localhost:8428/snapshot/create \
  -dst=fs:///backup/victoria-metrics/

# Delete snapshot
curl -s "http://<HOST>:8428/snapshot/delete?snapshot=<SNAPSHOT_NAME>"

# Delete all snapshots
curl -s http://<HOST>:8428/snapshot/delete_all
```

> [!CAUTION]
> Snapshots consume additional disk space until deleted. Always clean up after successful backup. / Snapshots занимают дополнительное место. Удаляйте после успешного бэкапа.

### Restore

```bash
# Restore using vmrestore
systemctl stop victoria-metrics

vmrestore -src=fs:///backup/victoria-metrics/ \
  -storageDataPath=/var/lib/victoria-metrics

systemctl start victoria-metrics
```

### Backup to S3

```bash
# Backup to S3
vmbackup -storageDataPath=/var/lib/victoria-metrics \
  -snapshot.createURL=http://localhost:8428/snapshot/create \
  -dst=s3://<BUCKET>/victoria-metrics/

# Backup to S3-compatible (MinIO)
vmbackup -storageDataPath=/var/lib/victoria-metrics \
  -snapshot.createURL=http://localhost:8428/snapshot/create \
  -dst=s3://<BUCKET>/victoria-metrics/ \
  -customS3Endpoint=http://<MINIO_HOST>:9000
```

---

## 6. Troubleshooting & Tools

### Common Issues

#### 1. High Cardinality

```bash
# Check cardinality stats
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '.seriesCountByMetricName[:10]'

# Find high-cardinality metrics
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '.seriesCountByLabelValuePair[:10]'
```

#### 2. Slow Queries

```bash
# Check top slow queries
curl -s http://<HOST>:8428/api/v1/status/top_queries | jq .

# Increase query timeout
# Add flag: -search.maxQueryDuration=120s
```

#### 3. Out of Disk Space

```bash
# Check disk usage
du -sh /var/lib/victoria-metrics/data/

# Reduce retention
# Change -retentionPeriod flag and restart

# Force merge to reclaim space
curl -s http://<HOST>:8428/internal/force_merge
```

> [!WARNING]
> `force_merge` is a CPU-intensive operation. Run during maintenance windows. / `force_merge` — ресурсоёмкая операция. Запускайте в окно обслуживания.

### Health Check

```bash
# Check VM health
curl -s http://<HOST>:8428/health
# Expected: "VictoriaMetrics is Healthy"

# Check flags
curl -s http://<HOST>:8428/flags

# Check internal metrics
curl -s http://<HOST>:8428/metrics | grep vm_rows_inserted_total
```

---

## 7. Logrotate Configuration

> [!TIP]
> VictoriaMetrics logs to stderr by default. With systemd, logs are managed via journald. This logrotate applies if redirecting logs to a file. / VictoriaMetrics пишет в stderr по умолчанию. Logrotate нужен только при перенаправлении в файл.

`/etc/logrotate.d/victoria-metrics`

```conf
/var/log/victoria-metrics/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 victoriametrics victoriametrics
    postrotate
        systemctl kill --signal=HUP victoria-metrics 2>/dev/null || true
    endscript
}
```

---

## Documentation Links

- **Official Documentation:** https://docs.victoriametrics.com/
- **Single-node Guide:** https://docs.victoriametrics.com/single-server-victoriametrics/
- **Cluster Guide:** https://docs.victoriametrics.com/cluster-victoriametrics/
- **vmagent:** https://docs.victoriametrics.com/vmagent/
- **vmauth:** https://docs.victoriametrics.com/vmauth/
- **vmbackup/vmrestore:** https://docs.victoriametrics.com/vmbackup/
- **MetricsQL:** https://docs.victoriametrics.com/metricsql/
- **GitHub:** https://github.com/VictoriaMetrics/VictoriaMetrics
- **Community Slack:** https://slack.victoriametrics.com/

---
