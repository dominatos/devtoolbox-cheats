Title: 📈 VictoriaMetrics
Group: Monitoring
Icon: 📈
Order: 8

# VictoriaMetrics Sysadmin Cheatsheet

> **Context:** VictoriaMetrics is an open-source, high-performance time series database and monitoring solution. It is compatible with Prometheus and can serve as a long-term storage backend. / VictoriaMetrics — высокопроизводительная TSDB с открытым исходным кодом, совместимая с Prometheus. Может служить как долгосрочное хранилище метрик.
> **Role:** Sysadmin / DevOps / SRE
> **Version:** VictoriaMetrics 1.99+
> **Default Ports:** Single-node: `8428` | vmselect: `8481` | vminsert: `8480` | vmstorage: `8482` | vmui: `8428/vmui` | vmagent: `8429`

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Backup & Restore](#5-backup--restore)
6. [Troubleshooting & Tools](#6-troubleshooting--tools)
7. [Logrotate Configuration](#7-logrotate-configuration)

---

## 1. Installation & Configuration

### Deployment Modes Comparison / Сравнение режимов развёртывания

| Mode | Components | Use Case / Применение |
|------|-----------|----------------------|
| Single-node | `victoria-metrics` | Up to millions of metrics/sec, simple setup / Простая настройка, до миллионов метрик/с |
| Cluster | `vminsert` + `vmstorage` + `vmselect` | Horizontal scaling, high availability / Горизонтальное масштабирование, HA |
| vmagent | `vmagent` (standalone) | Prometheus-compatible scraper/forwarder / Prometheus-совместимый сборщик |

### Install Single-Node / Установка single-node

```bash
# Download latest release / Скачать последний релиз
RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep tag_name | cut -d '"' -f 4)
wget "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${RELEASE}/victoria-metrics-linux-amd64-${RELEASE}.tar.gz"

# Extract and install / Распаковать и установить
tar -xzf victoria-metrics-linux-amd64-*.tar.gz
mv victoria-metrics-prod /usr/local/bin/victoria-metrics
chmod +x /usr/local/bin/victoria-metrics
```

### Systemd Service / Сервис systemd

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
# Create user and directories / Создать пользователя и каталоги
useradd -r -s /sbin/nologin victoriametrics
mkdir -p /var/lib/victoria-metrics /etc/victoria-metrics
chown victoriametrics:victoriametrics /var/lib/victoria-metrics

# Enable and start / Активировать и запустить
systemctl daemon-reload
systemctl enable --now victoria-metrics
```

### Main Configuration (CLI Flags) / Основная конфигурация (флаги CLI)

```bash
# Key flags / Основные флаги
victoria-metrics \
  -storageDataPath=/var/lib/victoria-metrics \   # Data directory / Каталог данных
  -retentionPeriod=12 \                          # Retention in months / Хранение в месяцах
  -httpListenAddr=:8428 \                        # Listen address / Адрес прослушивания
  -promscrape.config=/etc/victoria-metrics/scrape.yml \  # Scrape config / Конфиг сбора
  -search.maxUniqueTimeseries=300000 \           # Max unique series / Максимум уникальных серий
  -search.maxStalenessInterval=5m \              # Staleness interval / Интервал устаревания
  -memory.allowedPercent=60                      # Memory limit % / Лимит памяти %
```

### Prometheus Scrape Configuration / Конфигурация сбора Prometheus

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

### Install vmagent / Установка vmagent

```bash
# vmagent is a lightweight Prometheus-compatible scraper / vmagent — лёгкий Prometheus-совместимый сборщик
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

### Web UI & API / Веб-интерфейс и API

```
http://<HOST>:8428/vmui       # Built-in query UI / Встроенный UI запросов
http://<HOST>:8428/metrics    # Internal metrics / Внутренние метрики
http://<HOST>:8428/targets    # Scrape targets / Цели сбора
http://<HOST>:8428/api/v1/    # Prometheus-compatible API / Prometheus-совместимый API
```

### Query API (Prometheus-compatible) / API запросов

```bash
# Instant query / Мгновенный запрос
curl -s "http://<HOST>:8428/api/v1/query?query=up"

# Range query / Запрос за период
curl -s "http://<HOST>:8428/api/v1/query_range?query=up&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60"

# List all metric names / Список всех имён метрик
curl -s "http://<HOST>:8428/api/v1/label/__name__/values" | jq .

# List label values / Список значений меток
curl -s "http://<HOST>:8428/api/v1/label/job/values" | jq .

# Series count / Количество серий
curl -s "http://<HOST>:8428/api/v1/series/count" | jq .

# TSDB status (cardinality) / Статус TSDB (кардинальность)
curl -s "http://<HOST>:8428/api/v1/status/tsdb" | jq .
```

### Data Import/Export / Импорт/Экспорт данных

```bash
# Import data in Prometheus format / Импорт данных в формате Prometheus
curl -d 'metric_name{label="value"} 123 1609459200000' http://<HOST>:8428/api/v1/import/prometheus

# Export data in JSON / Экспорт данных в JSON
curl -s "http://<HOST>:8428/api/v1/export?match[]={__name__=~'cpu.*'}&start=-1h" | head

# Export to CSV / Экспорт в CSV
curl -s "http://<HOST>:8428/api/v1/export/csv?format=__name__,__value__,__timestamp__&match[]={job='node-exporter'}&start=-1h"
```

### MetricsQL vs PromQL / MetricsQL против PromQL

| Feature | PromQL | MetricsQL |
|---------|--------|-----------|
| Range functions / Функции диапазона | `rate()`, `irate()` | `rate()`, `irate()` + auto lookbehind |
| Rollup functions / Функции свёртки | Limited | `rollup()`, `rollup_rate()`, `rollup_delta()` |
| Keep metric names / Сохранение имён | No / Нет | `keep_metric_names` modifier |
| Label manipulation / Манипуляция метками | `label_replace` | `label_set`, `label_del`, `label_copy` + more |
| Default lookbehind / Okno по умолчанию | Must specify / Указывать обязательно | Auto from scrape interval / Автоматически из интервала сбора |
| Subqueries / Подзапросы | Limited | Full support / Полная поддержка |

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start victoria-metrics      # Start / Запустить
systemctl stop victoria-metrics       # Stop / Остановить
systemctl restart victoria-metrics    # Restart / Перезапустить
systemctl enable victoria-metrics     # Enable on boot / Автозапуск
systemctl status victoria-metrics     # Check status / Проверить статус
```

### Important Paths / Важные пути

| Path | Description |
|------|-------------|
| `/usr/local/bin/victoria-metrics` | Main binary / Основной бинарник |
| `/usr/local/bin/vmagent` | Agent binary / Бинарник агента |
| `/var/lib/victoria-metrics/` | Data storage / Хранилище данных |
| `/etc/victoria-metrics/scrape.yml` | Scrape config / Конфиг сбора |
| System journal | Logs (via journalctl) / Логи |

### Retention & Storage / Хранение и размер данных

```bash
# Check storage size / Проверить размер хранилища
du -sh /var/lib/victoria-metrics/

# Check internal VM stats / Проверить внутреннюю статистику
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '{totalSeries, totalDatapoints, retentionMonths: .retentionMonths}'

# Force merge (compact storage) / Принудительное слияние (уплотнение)
curl -s http://<HOST>:8428/internal/force_merge
```

> [!TIP]
> VictoriaMetrics achieves ~0.4 bytes per data point on average with compression. For 1M active series at 15s intervals, expect ~15GB/month. / VictoriaMetrics сжимает до ~0.4 байт на точку. Для 1М серий с интервалом 15с ожидайте ~15ГБ/мес.

### Firewall Configuration / Настройка фаервола

```bash
# Single-node / Одиночный узел
firewall-cmd --permanent --add-port=8428/tcp   # VM data + query / Данные и запросы
firewall-cmd --permanent --add-port=8429/tcp   # vmagent

# Cluster mode / Кластерный режим
firewall-cmd --permanent --add-port=8480/tcp   # vminsert
firewall-cmd --permanent --add-port=8481/tcp   # vmselect
firewall-cmd --permanent --add-port=8482/tcp   # vmstorage
firewall-cmd --reload
```

---

## 4. Security

### Authentication / Аутентификация

> [!NOTE]
> VictoriaMetrics single-node doesn't have built-in auth. Use a reverse proxy (nginx, caddy) with basic auth or vmauth. / VictoriaMetrics single-node не имеет встроенной аутентификации. Используйте обратный прокси или vmauth.

```bash
# vmauth config example / Пример конфига vmauth
cat > /etc/victoria-metrics/vmauth.yml << 'EOF'
users:
  - username: <USER>
    password: <PASSWORD>
    url_prefix: http://localhost:8428
  - bearer_token: <TOKEN>
    url_prefix: http://localhost:8428
EOF

# Start vmauth / Запустить vmauth
vmauth -auth.config=/etc/victoria-metrics/vmauth.yml -httpListenAddr=:8427
```

---

## 5. Backup & Restore

### Snapshot-Based Backup / Резервное копирование через snapshots

```bash
# Create snapshot / Создать snapshot
curl -s http://<HOST>:8428/snapshot/create | jq .
# Output: {"status":"ok","snapshot":"20240101T120000Z-abc123"}

# List snapshots / Список snapshots
curl -s http://<HOST>:8428/snapshot/list | jq .

# Backup snapshot using vmbackup / Бэкап через vmbackup
vmbackup -storageDataPath=/var/lib/victoria-metrics \
  -snapshot.createURL=http://localhost:8428/snapshot/create \
  -dst=fs:///backup/victoria-metrics/

# Delete snapshot / Удалить snapshot
curl -s "http://<HOST>:8428/snapshot/delete?snapshot=<SNAPSHOT_NAME>"

# Delete all snapshots / Удалить все snapshots
curl -s http://<HOST>:8428/snapshot/delete_all
```

> [!CAUTION]
> Snapshots consume additional disk space until deleted. Always clean up after successful backup. / Snapshots занимают дополнительное место. Удаляйте после успешного бэкапа.

### Restore / Восстановление

```bash
# Restore using vmrestore / Восстановление через vmrestore
systemctl stop victoria-metrics

vmrestore -src=fs:///backup/victoria-metrics/ \
  -storageDataPath=/var/lib/victoria-metrics

systemctl start victoria-metrics
```

---

## 6. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. High Cardinality / Высокая кардинальность

```bash
# Check cardinality stats / Проверить кардинальность
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '.seriesCountByMetricName[:10]'

# Find high-cardinality metrics / Найти метрики с высокой кардинальностью
curl -s http://<HOST>:8428/api/v1/status/tsdb | jq '.seriesCountByLabelValuePair[:10]'
```

#### 2. Slow Queries / Медленные запросы

```bash
# Check top slow queries / Проверить топ медленных запросов
curl -s http://<HOST>:8428/api/v1/status/top_queries | jq .

# Increase query timeout / Увеличить таймаут запроса
# Add flag: -search.maxQueryDuration=120s
```

#### 3. Out of Disk Space / Нет места на диске

```bash
# Check disk usage / Проверить использование диска
du -sh /var/lib/victoria-metrics/data/

# Reduce retention / Уменьшить срок хранения
# Change -retentionPeriod flag и restart

# Force merge to reclaim space / Принудительное слияние для освобождения места
curl -s http://<HOST>:8428/internal/force_merge
```

### Health Check / Проверка работоспособности

```bash
# Check VM health / Проверить здоровье VM
curl -s http://<HOST>:8428/health
# Expected: "VictoriaMetrics is Healthy"

# Check flags / Проверить флаги
curl -s http://<HOST>:8428/flags

# Check internal metrics / Проверить внутренние метрики
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
