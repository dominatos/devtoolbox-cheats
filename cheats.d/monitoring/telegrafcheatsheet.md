Title: 📈 Telegraf
Group: Monitoring
Icon: 📈
Order: 6

# Telegraf Sysadmin Cheatsheet

> **Telegraf** is an open-source, plugin-driven server agent from InfluxData for collecting, processing, aggregating, and writing metrics. First released in 2015, it is part of the TICK stack (Telegraf, InfluxDB, Chronograf, Kapacitor) and supports 300+ input/output plugins.
>
> **Common use cases / Типичные сценарии:** System metrics collection (CPU, memory, disk, network), application monitoring (MySQL, PostgreSQL, Redis, Nginx), SNMP polling, Docker/Kubernetes metrics, cloud metrics (AWS CloudWatch, Azure Monitor), custom script execution, Prometheus metrics scraping.
>
> **Status / Статус:** Actively developed by InfluxData. Telegraf is one of the most versatile metrics collection agents. Alternatives include **Prometheus node_exporter** (Prometheus ecosystem), **Grafana Alloy** (Grafana LGTM stack), **collectd** (legacy, C-based), **Vector** (Rust-based, high-performance), **vmagent** (VictoriaMetrics ecosystem).
>
> **Default ports / Порты по умолчанию:** None (outbound agent) | InfluxDB: `8086` | Prometheus metrics endpoint: `9273`

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

### Install Telegraf / Установка Telegraf

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

### Main Configuration / Основная конфигурация

`/etc/telegraf/telegraf.conf`

```toml
# Global agent settings / Глобальные настройки агента
[agent]
  interval = "10s"                    # Collection interval / Интервал сбора
  round_interval = true               # Round collection to interval / Округлить до интервала
  metric_batch_size = 1000            # Batch size for output / Размер пакета
  metric_buffer_limit = 10000         # Buffer size / Размер буфера
  flush_interval = "10s"              # Flush interval / Интервал сброса
  flush_jitter = "0s"                 # Jitter for flush / Разброс сброса
  hostname = ""                       # Auto-detect / Авто-определение
  omit_hostname = false

# Output to InfluxDB v2 / Вывод в InfluxDB v2
[[outputs.influxdb_v2]]
  urls = ["http://<INFLUXDB_HOST>:8086"]
  token = "<TOKEN>"
  organization = "<ORG>"
  bucket = "<BUCKET>"

# Output to Prometheus / Вывод в Prometheus
# [[outputs.prometheus_client]]
#   listen = ":9273"
#   metric_version = 2

# System inputs (default) / Системные входы (по умолчанию)
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

### Output Plugin Comparison / Сравнение плагинов вывода

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

### Generate Configuration / Генерация конфигурации

```bash
# Generate full default config / Сгенерировать полный конфиг по умолчанию
telegraf config > /etc/telegraf/telegraf.conf.default

# Generate config with specific plugins only / Конфиг только с конкретными плагинами
telegraf config --input-filter cpu:mem:disk:net --output-filter influxdb_v2 > /etc/telegraf/telegraf.conf

# List available input plugins / Список входных плагинов
telegraf --input-list

# List available output plugins / Список выходных плагинов
telegraf --output-list

# Print sample config for specific plugin / Показать пример конфига плагина
telegraf --usage cpu
telegraf --usage influxdb_v2
```

### Popular Input Plugins / Популярные плагины ввода

```toml
# Nginx status / Статус Nginx
[[inputs.nginx]]
  urls = ["http://localhost/nginx_status"]

# MySQL statistics / Статистика MySQL
[[inputs.mysql]]
  servers = ["<USER>:<PASSWORD>@tcp(<HOST>:3306)/"]

# PostgreSQL / PostgreSQL
[[inputs.postgresql]]
  address = "host=<HOST> user=<USER> password=<PASSWORD> sslmode=disable dbname=<DB>"

# Docker containers / Контейнеры Docker
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"

# HTTP response check / Проверка HTTP-ответа
[[inputs.http_response]]
  urls = ["https://<HOST>"]
  response_timeout = "5s"

# SNMP polling / Опрос SNMP
[[inputs.snmp]]
  agents = ["udp://<HOST>:161"]
  community = "<COMMUNITY_STRING>"
  [[inputs.snmp.field]]
    oid = ".1.3.6.1.2.1.1.3.0"
    name = "uptime"

# Execute custom script / Выполнить кастомный скрипт
[[inputs.exec]]
  commands = ["/usr/local/bin/custom_metric.sh"]
  data_format = "influx"
  timeout = "5s"
  interval = "60s"
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start telegraf      # Start / Запустить
systemctl stop telegraf       # Stop / Остановить
systemctl restart telegraf    # Restart / Перезапустить
systemctl enable telegraf     # Enable on boot / Автозапуск
systemctl status telegraf     # Check status / Проверить статус
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/etc/telegraf/telegraf.conf` | Main configuration / Основной конфиг |
| `/etc/telegraf/telegraf.d/` | Drop-in config fragments / Фрагменты конфигов |
| `/var/log/telegraf/` | Telegraf logs / Логи Telegraf |

> [!TIP]
> Use `/etc/telegraf/telegraf.d/` to split configs into per-service files (e.g., `nginx.conf`, `mysql.conf`). Telegraf loads all `.conf` files from this directory. / Разделяйте конфиг на файлы по сервисам в `/etc/telegraf/telegraf.d/`.

### Test Configuration / Тест конфигурации

```bash
# Test config syntax / Проверить синтаксис конфига
telegraf --config /etc/telegraf/telegraf.conf --test

# Dry run (collect once, print to stdout) / Пробный запуск
telegraf --config /etc/telegraf/telegraf.conf --once --test

# Run with debug output / Запуск с отладкой
telegraf --config /etc/telegraf/telegraf.conf --debug
```

---

## 4. Security

### Environment Variables / Переменные окружения

`/etc/default/telegraf` (Debian) or `/etc/sysconfig/telegraf` (RHEL)

```ini
# Store secrets in environment / Хранить секреты в переменных окружения
INFLUX_TOKEN=<TOKEN>
DB_PASSWORD=<PASSWORD>
```

```toml
# Reference in telegraf.conf / Использование в telegraf.conf
[[outputs.influxdb_v2]]
  token = "$INFLUX_TOKEN"
```

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. No Data in Output / Нет данных на выходе

```bash
# Test specific input / Тест конкретного входа
telegraf --config /etc/telegraf/telegraf.conf --input-filter cpu --test

# Test output connectivity / Проверить подключение к выходу
telegraf --config /etc/telegraf/telegraf.conf --output-filter influxdb_v2 --test

# Check logs / Проверить логи
journalctl -u telegraf -f --no-pager
```

#### 2. Plugin Permission Errors / Ошибки прав плагинов

```bash
# Add telegraf user to required groups / Добавить пользователя telegraf в необходимые группы
usermod -aG docker telegraf     # For Docker input / Для Docker
usermod -aG systemd-journal telegraf  # For journal input / Для journald

systemctl restart telegraf
```

#### 3. High CPU/Memory Usage / Высокое потребление CPU/памяти

```bash
# Reduce collection interval / Уменьшить интервал сбора
# agent.interval = "30s" instead of "10s"

# Reduce buffer / Уменьшить буфер
# agent.metric_buffer_limit = 5000

# Check which plugins are slow / Проверить какие плагины медленные
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

## Documentation Links / Ссылки на документацию

- **Official Documentation:** https://docs.influxdata.com/telegraf/
- **Plugin Directory:** https://docs.influxdata.com/telegraf/latest/plugins/
- **Configuration Guide:** https://docs.influxdata.com/telegraf/latest/configuration/
- **Telegraf Downloads:** https://www.influxdata.com/downloads/
- **GitHub:** https://github.com/influxdata/telegraf
- **Community Forum:** https://community.influxdata.com/

---
