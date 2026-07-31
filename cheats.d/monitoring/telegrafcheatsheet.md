---
Title: 📈 Telegraf
Group: Monitoring
Icon: 📈
Order: 6
tags:
  - monitoring
  - sysadmin
  - linux
---

# Telegraf Sysadmin Cheatsheet

> **Telegraf** is an open-source, plugin-driven server agent from InfluxData for collecting, processing, aggregating, and writing metrics. First released in 2015, it is part of the TICK stack (Telegraf, InfluxDB, Chronograf, Kapacitor) and supports 300+ input/output plugins.
>
> **Common use cases / Типичные сценарии:** System metrics collection (CPU, memory, disk, network), application monitoring (MySQL, PostgreSQL, Redis, Nginx), SNMP polling, Docker/Kubernetes metrics, cloud metrics (AWS CloudWatch, Azure Monitor), custom script execution, Prometheus metrics scraping.
>
> **Status / Статус:** Actively developed by InfluxData. Telegraf is one of the most versatile metrics collection agents. Alternatives include **Prometheus node_exporter** (Prometheus ecosystem), **Grafana Alloy** (Grafana LGTM stack), **collectd** (legacy, C-based), **Vector** (Rust-based, high-performance), **vmagent** (VictoriaMetrics ecosystem).
>
> **Default ports / Порты по умолчанию:** None (outbound agent) | InfluxDB: `8086` | Prometheus metrics endpoint: `9273`

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

### Install Telegraf

```bash
# RHEL/CentOS/AlmaLinux
cat > /etc/yum.repos.d/influxdb.repo << 'EOF'
[influxdb]
name=InfluxDB Repository
baseurl=https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://repos.influxdata.com/influxdata-archive_compat.key
EOF
dnf install telegraf

# Debian/Ubuntu
wget -qO- https://repos.influxdata.com/influxdata-archive_compat.key | apt-key add -
echo "deb https://repos.influxdata.com/debian stable main" > /etc/apt/sources.list.d/influxdb.list
apt update && apt install telegraf
```

### Main Configuration

`/etc/telegraf/telegraf.conf`

```toml
# Global agent settings
[agent]
  interval = "10s"                    # Collection interval / Интервал сбора
  round_interval = true               # Round collection to interval / Округлить до интервала
  metric_batch_size = 1000            # Batch size for output / Размер пакета
  metric_buffer_limit = 10000         # Buffer size / Размер буфера
  flush_interval = "10s"              # Flush interval / Интервал сброса
  flush_jitter = "0s"                 # Jitter for flush / Разброс сброса
  hostname = ""                       # Auto-detect / Авто-определение
  omit_hostname = false

# Output to InfluxDB v2
[[outputs.influxdb_v2]]
  urls = ["http://<INFLUXDB_HOST>:8086"]
  token = "<TOKEN>"
  organization = "<ORG>"
  bucket = "<BUCKET>"

# Output to Prometheus
# [[outputs.prometheus_client]]
#   listen = ":9273"
#   metric_version = 2

# System inputs (default)
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]
[[inputs.mem]]
[[inputs.net]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
```

### Output Plugin Comparison

| Output | Protocol | Best For / Лучше для |
|--------|----------|---------------------|
| `influxdb_v2` | HTTP/HTTPS | InfluxDB v2 / TSDB |
| `prometheus_client` | HTTP | Prometheus scraping / Сбор Prometheus |
| `elasticsearch` | HTTP/HTTPS | ELK stack / Стек ELK |
| `kafka` | TCP | High-throughput pipeline / Высоконагруженный пайплайн |
| `file` | Filesystem | Debug/local storage / Отладка |
| `http` | HTTP POST | Custom webhooks / Кастомные вебхуки |

---

## 2. Core Management

### Generate Configuration

```bash
# Generate full default config
telegraf config > /etc/telegraf/telegraf.conf.default

# Generate config with specific plugins only
telegraf config --input-filter cpu:mem:disk:net --output-filter influxdb_v2 > /etc/telegraf/telegraf.conf

# List available input plugins
telegraf --input-list

# List available output plugins
telegraf --output-list

# Print sample config for specific plugin
telegraf --usage cpu
telegraf --usage influxdb_v2
```

### Popular Input Plugins

```toml
# Nginx status
[[inputs.nginx]]
  urls = ["http://localhost/nginx_status"]

# MySQL statistics
[[inputs.mysql]]
  servers = ["<USER>:<PASSWORD>@tcp(<HOST>:3306)/"]

# PostgreSQL / PostgreSQL
[[inputs.postgresql]]
  address = "host=<HOST> user=<USER> password=<PASSWORD> sslmode=disable dbname=<DB>"

# Docker containers
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"

# HTTP response check
[[inputs.http_response]]
  urls = ["https://<HOST>"]
  response_timeout = "5s"

# SNMP polling
[[inputs.snmp]]
  agents = ["udp://<HOST>:161"]
  community = "<COMMUNITY_STRING>"
  [[inputs.snmp.field]]
    oid = ".1.3.6.1.2.1.1.3.0"
    name = "uptime"

# Execute custom script
[[inputs.exec]]
  commands = ["/usr/local/bin/custom_metric.sh"]
  data_format = "influx"
  timeout = "5s"
  interval = "60s"
```

---

## 3. Sysadmin Operations

### Service Management

```bash
systemctl start telegraf      # Start / Запустить
systemctl stop telegraf       # Stop / Остановить
systemctl restart telegraf    # Restart / Перезапустить
systemctl enable telegraf     # Enable on boot / Автозапуск
systemctl status telegraf     # Check status / Проверить статус
```

### Important Paths

| Path | Description / Описание |
|------|------------------------|
| `/etc/telegraf/telegraf.conf` | Main configuration / Основной конфиг |
| `/etc/telegraf/telegraf.d/` | Drop-in config fragments / Фрагменты конфигов |
| `/var/log/telegraf/` | Telegraf logs / Логи Telegraf |

> [!TIP]
> Use `/etc/telegraf/telegraf.d/` to split configs into per-service files (e.g., `nginx.conf`, `mysql.conf`). Telegraf loads all `.conf` files from this directory. / Разделяйте конфиг на файлы по сервисам в `/etc/telegraf/telegraf.d/`.

### Test Configuration

```bash
# Test config syntax
telegraf --config /etc/telegraf/telegraf.conf --test

# Dry run (collect once, print to stdout)
telegraf --config /etc/telegraf/telegraf.conf --once --test

# Run with debug output
telegraf --config /etc/telegraf/telegraf.conf --debug
```

---

## 4. Security

### Environment Variables

`/etc/default/telegraf` (Debian) or `/etc/sysconfig/telegraf` (RHEL)

```ini
# Store secrets in environment
INFLUX_TOKEN=<TOKEN>
DB_PASSWORD=<PASSWORD>
```

```toml
# Reference in telegraf.conf
[[outputs.influxdb_v2]]
  token = "$INFLUX_TOKEN"
```

---

## 5. Troubleshooting & Tools

### Common Issues

#### 1. No Data in Output

```bash
# Test specific input
telegraf --config /etc/telegraf/telegraf.conf --input-filter cpu --test

# Test output connectivity
telegraf --config /etc/telegraf/telegraf.conf --output-filter influxdb_v2 --test

# Check logs
journalctl -u telegraf -f --no-pager
```

#### 2. Plugin Permission Errors

```bash
# Add telegraf user to required groups
usermod -aG docker telegraf     # For Docker input / Для Docker
usermod -aG systemd-journal telegraf  # For journal input / Для journald

systemctl restart telegraf
```

#### 3. High CPU/Memory Usage

```bash
# Reduce collection interval
# agent.interval = "30s" instead of "10s"

# Reduce buffer
# agent.metric_buffer_limit = 5000

# Check which plugins are slow
telegraf --config /etc/telegraf/telegraf.conf --debug 2>&1 | grep "took"
```

---

## 6. Logrotate Configuration

`/etc/logrotate.d/telegraf`

```conf
/var/log/telegraf/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 telegraf telegraf
    postrotate
        systemctl kill --signal=HUP telegraf 2>/dev/null || true
    endscript
}
```

---

## Documentation Links

- **Official Documentation:** https://docs.influxdata.com/telegraf/
- **Plugin Directory:** https://docs.influxdata.com/telegraf/latest/plugins/
- **Configuration Guide:** https://docs.influxdata.com/telegraf/latest/configuration/
- **Telegraf Downloads:** https://www.influxdata.com/downloads/
- **GitHub:** https://github.com/influxdata/telegraf
- **Community Forum:** https://community.influxdata.com/

---
