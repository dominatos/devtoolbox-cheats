Title: 📜 Kibana
Group: System & Logs
Icon: 📜
Order: 5

# Kibana Sysadmin Cheatsheet

> **Context:** Kibana is a data visualization and exploration tool used for log and time-series analytics, application monitoring, and operational intelligence. / Kibana - инструмент визуализации и исследования данных для аналитики логов, мониторинга приложений и операционной аналитики.
> **Role:** Sysadmin / DevOps
> **Stack:** ELK (Elasticsearch, Logstash, Kibana)

---

## 📚 Table of Contents / Содержание

1. [Discovery & Search](#discovery--search--исследование-и-поиск)
2. [Management](#management--управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Discovery & Search / Исследование и поиск

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

## 2. Management / Управление

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

## 3. Sysadmin Operations / Операции сисадмина

### Config File / Файл конфигурации
File: `/etc/kibana/kibana.yml`

```yaml
server.port: 5601
server.host: "0.0.0.0" # Listen on all interfaces / Слушать на всех интерфейсах

# Elasticsearch connection / Подключение к Elasticsearch
elasticsearch.hosts: ["http://<ES_IP>:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "<PASSWORD>"
```

### Service Management / Управление сервисом

```bash
systemctl start kibana
systemctl status kibana
journalctl -u kibana -f
```

---

## 4. Troubleshooting / Устранение неполадок

### Status Page / Страница статуса
UI: `http://<KIBANA_HOST>:5601/status`
Checks plugin status and Elasticsearch connectivity. / Проверяет статус плагинов и связь с Elasticsearch.

### Common Errors / Частые ошибки

1.  **"Kibana server is not ready yet"**
    *   Elasticsearch is down or initializing. / Elasticsearch упал или инициализируется.
    *   Check `kibana.yml` credentials. / Проверьте данные в `kibana.yml`.

2.  **Date Format Issues / Проблемы с форматом дат**
    *   Check mappings in Elasticsearch (`GET _mapping`). / Проверьте маппинг в ES.
    *   Ensure Index Pattern time field matches data. / Убедитесь, что поле времени в Index Pattern совпадает с данными.

3.  **Heap Memory / Память Heap**
    *   Node.js options via `NODE_OPTIONS="--max-old-space-size=4096"` in environment/systemd if crashing.
