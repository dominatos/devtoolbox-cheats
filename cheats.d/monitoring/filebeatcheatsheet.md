Title: 📊 Filebeat
Group: Monitoring
Icon: 📊
Order: 5

# Filebeat Sysadmin Cheatsheet

> **Context:** Filebeat is a lightweight log shipper from the Elastic Stack (ELK). It monitors log files, collects log events, and forwards them to Elasticsearch, Logstash, or other outputs. / Filebeat — легковесный шиппер логов из стека Elastic (ELK). Мониторит лог-файлы, собирает события и пересылает в Elasticsearch, Logstash и другие приёмники.
> **Role:** Sysadmin / DevOps / SRE
> **Version:** 8.x
> **Default Port:** None (outbound only) | Elasticsearch: `9200` | Logstash: `5044` | Kibana: `5601`

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

### Install Filebeat / Установка Filebeat

```bash
# RHEL/CentOS/AlmaLinux (add Elastic repo first) / Добавить репозиторий Elastic
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

### Main Configuration / Основная конфигурация

`/etc/filebeat/filebeat.yml`

```yaml
# Input configuration / Конфигурация ввода
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

# Output to Elasticsearch / Вывод в Elasticsearch
output.elasticsearch:
  hosts: ["https://<ES_HOST>:9200"]
  username: "<USER>"
  password: "<PASSWORD>"
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  index: "filebeat-%{+yyyy.MM.dd}"

# Output to Logstash (alternative) / Вывод в Logstash (альтернатива)
# output.logstash:
#   hosts: ["<LOGSTASH_HOST>:5044"]
#   ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]

# Kibana setup / Настройка Kibana
setup.kibana:
  host: "https://<KIBANA_HOST>:5601"
  username: "<USER>"
  password: "<PASSWORD>"

# Processors / Обработчики
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - drop_fields:
      fields: ["agent.ephemeral_id", "agent.hostname"]
```

### Output Comparison / Сравнение выходов

| Output | Use Case / Применение | Buffering / Буферизация | Notes / Примечания |
|--------|----------------------|------------------------|--------------------|
| Elasticsearch | Direct indexing / Прямая индексация | Yes | Simplest setup / Самый простой |
| Logstash | Complex processing / Сложная обработка | Yes (Logstash) | Transformation, enrichment / Трансформация |
| Kafka | High-volume buffering / Высоконагруженная буферизация | Yes (Kafka) | Best for large-scale / Для больших объёмов |
| Redis | Lightweight buffer / Лёгкий буфер | Yes (Redis) | Legacy, use Kafka instead / Устаревший |
| File | Local storage / Локальное хранение | No | Debug/testing / Отладка/тест |

---

## 2. Core Management

### Enable Built-in Modules / Включение встроенных модулей

```bash
# List available modules / Список доступных модулей
filebeat modules list

# Enable modules / Включить модули
filebeat modules enable system nginx apache mysql postgresql

# Disable module / Отключить модуль
filebeat modules disable apache

# View module config / Посмотреть конфиг модуля
cat /etc/filebeat/modules.d/system.yml
```

### Module Configuration Example / Пример конфигурации модуля

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

### Setup Commands / Команды установки

```bash
# Setup index template / Настроить шаблон индекса
filebeat setup --index-management

# Setup Kibana dashboards / Настроить дашборды Kibana
filebeat setup --dashboards

# Setup ILM policy / Настроить ILM-политику
filebeat setup --ilm-policy

# Full setup (template + dashboards + ILM) / Полная настройка
filebeat setup
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start filebeat      # Start / Запустить
systemctl stop filebeat       # Stop / Остановить
systemctl restart filebeat    # Restart / Перезапустить
systemctl enable filebeat     # Enable on boot / Автозапуск
systemctl status filebeat     # Check status / Проверить статус
```

### Important Paths / Важные пути

| Path | Description |
|------|-------------|
| `/etc/filebeat/filebeat.yml` | Main configuration / Основной конфиг |
| `/etc/filebeat/modules.d/` | Module configurations / Конфиги модулей |
| `/var/lib/filebeat/` | Data and registry / Данные и реестр |
| `/var/lib/filebeat/registry/` | File tracking registry / Реестр отслеживания файлов |
| `/var/log/filebeat/` | Filebeat logs / Логи Filebeat |

### Test Configuration / Тест конфигурации

```bash
# Test config syntax / Проверить синтаксис конфига
filebeat test config

# Test output connectivity / Проверить подключение к выходу
filebeat test output

# Run with debug output / Запуск с отладочным выводом
filebeat -e -d "*"
```

---

## 4. Security

### TLS/SSL Configuration / Настройка TLS/SSL

`/etc/filebeat/filebeat.yml`

```yaml
# TLS to Elasticsearch / TLS к Elasticsearch
output.elasticsearch:
  hosts: ["https://<ES_HOST>:9200"]
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  ssl.certificate: "/etc/filebeat/filebeat.crt"
  ssl.key: "/etc/filebeat/filebeat.key"

# TLS to Logstash / TLS к Logstash
output.logstash:
  hosts: ["<LOGSTASH_HOST>:5044"]
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
  ssl.certificate: "/etc/filebeat/filebeat.crt"
  ssl.key: "/etc/filebeat/filebeat.key"
```

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Filebeat Not Sending Data / Filebeat не отправляет данные

```bash
# Check connectivity / Проверить подключение
filebeat test output

# Check config / Проверить конфиг
filebeat test config

# Run in debug mode / Запустить в режиме отладки
filebeat -e -d "*" 2>&1 | head -100
```

#### 2. Duplicate Data / Дублирование данных

```bash
# Check registry state / Проверить состояние реестра
cat /var/lib/filebeat/registry/filebeat/log.json | jq .

# Reset registry (resend all data) / Сбросить реестр (повторная отправка данных)
systemctl stop filebeat
rm -rf /var/lib/filebeat/registry/
systemctl start filebeat
```

> [!CAUTION]
> Deleting the registry will cause Filebeat to re-read all log files from the beginning, potentially creating duplicate data. / Удаление реестра приведёт к повторному чтению всех файлов, что может создать дубликаты.

#### 3. High Memory Usage / Высокое потребление памяти

```bash
# Limit bulk size and queue / Ограничить размер bulks и очереди
# In filebeat.yml / В filebeat.yml:
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
