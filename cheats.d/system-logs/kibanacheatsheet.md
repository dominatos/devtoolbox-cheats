Title: 📜 Kibana
Group: System & Logs
Icon: 📜
Order: 5

# Kibana — Data Visualization for Elasticsearch

**Kibana** is the open-source frontend for the **Elastic Stack (ELK)** — a data visualization and exploration tool for log analytics, application monitoring, and operational intelligence. Kibana connects to Elasticsearch to search, view, and interact with data stored in Elasticsearch indices.

**What Kibana does / Что делает Kibana:**
- **Discover** — search and filter raw log data with KQL (Kibana Query Language)
- **Visualize** — create charts, graphs, maps, and metrics from Elasticsearch data
- **Dashboard** — combine visualizations into interactive dashboards
- **Alerting** — configure rules to trigger alerts on log patterns
- **Dev Tools** — run Elasticsearch API queries directly from the browser

**ELK Stack / Стек ELK:**
- **Elasticsearch** — distributed search and analytics engine (stores data)
- **Logstash** — data processing pipeline (collects, transforms, ships)
- **Kibana** — visualization and UI (query with KQL, build dashboards)
- **Beats** — lightweight data shippers (Filebeat, Metricbeat, etc.)

**Modern alternatives / Современные альтернативы:**
- **Grafana + Loki** — lightweight log aggregation with Grafana dashboards
- **OpenSearch / OpenSearch Dashboards** — AWS-maintained fork of Elasticsearch/Kibana
- **Datadog, Splunk** — commercial SaaS log analytics platforms

📚 **Official Docs / Официальная документация:**
[Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html) · [KQL Reference](https://www.elastic.co/guide/en/kibana/current/kuery-query.html) · [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

## Table of Contents
- [Discovery & Search](#discovery--search)
- [Management](#management)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)
- [Logrotate for Kibana](#logrotate-for-kibana)

---

## Discovery & Search

### Default Ports & Services / Порты и сервисы по умолчанию

| Service | Port | Config File | Description (EN) | Описание (RU) |
| :--- | :--- | :--- | :--- | :--- |
| Kibana | `5601` | `/etc/kibana/kibana.yml` | Kibana web UI | Веб-интерфейс Kibana |
| Elasticsearch | `9200` | `/etc/elasticsearch/elasticsearch.yml` | ES REST API | REST API Elasticsearch |
| Logstash | `5044` | `/etc/logstash/logstash.yml` | Beats input | Ввод от Beats |

### KQL (Kibana Query Language) / Язык запросов KQL

Used in the "Search" bar. / Используется в строке "Search".

```text
# Exact match / Точное совпадение
status: 200

# Text search / Текстовый поиск
message: "error"

# Boolean logic / Логика
status: 500 AND method: "POST"
status: 404 OR status: 503
NOT status: 200

# Range / Диапазон
bytes > 1000
response_time >= 500

# Wildcard / Маска
host: web*
machinename: *"prod"*

# Exist check (Field is present) / Проверка на существование
_exists_: "user_id"

# Nested fields / Вложенные поля
http.response.status_code: 404
```

### Time Filter / Фильтр времени

Always verify the time picker in the top right corner! / Всегда проверяйте выбор времени в верхнем правом углу!
*   `Last 15 minutes` (Default)
*   `Last 24 hours`
*   `Absolute` (Specific range)

---

## Management

### Index Patterns / Шаблоны индексов

**Stack Management > Index Patterns**

Define how Kibana accesses indices. / Определяет, как Kibana обращается к индексам.
*   Pattern: `logstash-*` (Matches `logstash-2023.10.01`, etc.)
*   Time field: `@timestamp`

### Saved Objects / Сохраненные объекты

**Stack Management > Saved Objects**

*   Export Dashboards/Visualizations to JSON (Backup). / Экспорт Дашбордов/Визуализаций в JSON (Бэкап).
*   Import JSON to restore or migrate. / Импорт JSON для восстановления или миграции.

---

## Sysadmin Operations

### Installation / Установка

```bash
# Debian/Ubuntu
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update && sudo apt install kibana

# RHEL/Fedora/CentOS
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo dnf install kibana
```

### Config File / Файл конфигурации

`/etc/kibana/kibana.yml`

```yaml
server.port: 5601
server.host: "0.0.0.0"                        # Listen on all interfaces / Слушать на всех интерфейсах

# Elasticsearch connection / Подключение к Elasticsearch
elasticsearch.hosts: ["http://<ES_IP>:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "<PASSWORD>"

# TLS/SSL (production recommended) / TLS/SSL (рекомендуется для продакшена)
# server.ssl.enabled: true
# server.ssl.certificate: /path/to/cert.pem
# server.ssl.key: /path/to/key.pem
```

### Service Management / Управление сервисом

```bash
sudo systemctl start kibana                   # Start Kibana / Запустить Kibana
sudo systemctl stop kibana                    # Stop Kibana / Остановить Kibana
sudo systemctl restart kibana                 # Restart Kibana / Перезапустить Kibana
sudo systemctl enable kibana                  # Enable on boot / Включить автозапуск
systemctl status kibana                       # Check status / Проверить статус
journalctl -u kibana -f                       # Follow logs / Следить за логами
journalctl -u kibana --since "1 hour ago"     # Recent logs / Недавние логи
```

---

## Troubleshooting

### Status Page / Страница статуса

UI: `http://<KIBANA_HOST>:5601/status`
Checks plugin status and Elasticsearch connectivity. / Проверяет статус плагинов и связь с Elasticsearch.

### Common Errors / Частые ошибки

1.  **"Kibana server is not ready yet"**
    *   Elasticsearch is down or initializing. / Elasticsearch упал или инициализируется.
    *   Check `kibana.yml` credentials. / Проверьте данные в `kibana.yml`.
    *   Verify connectivity: `curl http://<ES_IP>:9200`

2.  **Date Format Issues / Проблемы с форматом дат**
    *   Check mappings in Elasticsearch (`GET _mapping`). / Проверьте маппинг в ES.
    *   Ensure Index Pattern time field matches data. / Убедитесь, что поле времени в Index Pattern совпадает с данными.

3.  **Heap Memory / Память Heap**
    *   Node.js options via systemd override if Kibana is crashing:

    ```bash
    sudo systemctl edit kibana
    # Add: [Service]
    # Environment="NODE_OPTIONS=--max-old-space-size=4096"
    sudo systemctl daemon-reload && sudo systemctl restart kibana
    ```

4.  **Slow Dashboards / Медленные дэшборды**
    *   Check Elasticsearch cluster health: `curl <ES_IP>:9200/_cluster/health?pretty`
    *   Reduce time range in the time picker
    *   Optimize visualizations — avoid heavy aggregations

---

## Logrotate for Kibana

`/etc/logrotate.d/kibana`

```bash
/var/log/kibana/kibana.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 kibana kibana
    postrotate
        systemctl reload kibana > /dev/null 2>&1 || true
    endscript
}
```

---

## 💡 Best Practices / Лучшие практики

- Always verify the **time picker** in the top right corner of Discover. / Всегда проверяйте выбор времени.
- Use `systemctl status kibana` to check health before debugging UI issues. / Проверяйте статус сервиса.
- Back up Saved Objects (dashboards, visualizations) as JSON regularly. / Регулярно бэкапьте Saved Objects.
- Use **Index Lifecycle Management (ILM)** to automate index rotation and deletion. / Используйте ILM для автоматизации ротации индексов.
- Enable **TLS/SSL** in production. / Включите TLS/SSL в продакшене.

---

## Documentation Links

- **Kibana Guide:** https://www.elastic.co/guide/en/kibana/current/index.html
- **KQL Reference:** https://www.elastic.co/guide/en/kibana/current/kuery-query.html
- **Elasticsearch Guide:** https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
- **Kibana on Docker:** https://www.elastic.co/guide/en/kibana/current/docker.html
- **ArchWiki — ELK:** https://wiki.archlinux.org/title/Elasticsearch
