Title: 🌀 HAProxy — Cheatsheet
Group: Web Servers
Icon: 🌀
Order: 5

# 🌀 HAProxy — Cheatsheet (EN / RU)

## Table of Contents

- [Installation & Configuration](#installation--configuration)
- [Core Concepts](#core-concepts)
- [Configuration Sections](#configuration-sections)
  - [Global Section](#global-section)
  - [Defaults Section](#defaults-section)
  - [Frontend Section](#frontend-section)
  - [Backend Section](#backend-section)
  - [Listen Section](#listen-section)
- [Load Balancing Algorithms](#load-balancing-algorithms)
- [ACL & Routing](#acl--routing)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Health Checks](#health-checks)
- [Stick Tables & Rate Limiting](#stick-tables--rate-limiting)
- [Caching](#caching)
- [Logging](#logging)
- [Runtime Management](#runtime-management)
- [Production Scenarios](#production-scenarios)
- [Quick Templates](#quick-templates)
- [Troubleshooting](#troubleshooting)
- [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install haproxy             # Install HAProxy / Установить HAProxy

# RHEL/CentOS/AlmaLinux
sudo dnf install haproxy                                # Install HAProxy / Установить HAProxy
sudo systemctl enable haproxy                           # Enable at boot / Автозапуск
```

### Default Paths / Пути по умолчанию

`/etc/haproxy/haproxy.cfg` — Main config / Основной конфиг  
`/run/haproxy.sock` — Runtime socket / Рантайм сокет  
`/run/haproxy.pid` — PID file / Файл PID  
`/var/log/haproxy.log` — Log file / Лог файл  
`/etc/haproxy/certs/` — SSL certificates / SSL сертификаты

### Service Control / Управление сервисом

```bash
sudo systemctl start haproxy                            # Start service / Запустить сервис
sudo systemctl stop haproxy                             # Stop service / Остановить сервис
sudo systemctl restart haproxy                          # Restart service / Перезапустить сервис
sudo systemctl reload haproxy                           # Reload config / Перечитать конфиг
sudo systemctl status haproxy                           # Service status / Статус сервиса
```

### Configuration Testing / Проверка конфигурации

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg                  # Test config / Проверка конфига
haproxy -f /etc/haproxy/haproxy.cfg -c -db              # Debug mode / Режим отладки
```

### Zero-Downtime Reload / Reload без простоя

```bash
# Validate config / Проверка конфига
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload (systemd) / Reload через systemd
sudo systemctl reload haproxy

# Manual reload / Ручной reload
haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid)
```

### Default Ports / Порты по умолчанию

- **80** — HTTP (configurable in frontend)
- **443** — HTTPS (configurable in frontend)
- **8404** — Stats page (configurable)

---

## Core Concepts

**EN:** HAProxy operates as: **input → rules → output**  
**RU:** HAProxy работает как: **вход → правила → выход**

### Mental Map / Ментальная карта

* **global** — Process & OS: logs, master-worker, runtime socket / Процесс и ОС
* **defaults** — Timeouts, log format, common options / Таймауты, общие опции
* **frontend** — Input: `bind`, ACL, redirects, headers, backend choice / «Вход»
* **backend** — Output: balancing, servers, health-checks, cache/compression / «Выход»
* **listen** — Combined block (useful for stats) / Комбинированный блок

---

## Configuration Sections

### Global Section

Global section defines process-level settings / Глобальный раздел определяет настройки процесса

```cfg
global
  log /dev/log local0                                   # Syslog facility / Логирование в syslog
  chroot /var/lib/haproxy                               # Jail dir / Директория chroot
  pidfile /run/haproxy.pid                              # PID file / Файл PID
  maxconn 10000                                         # Max concurrent connections / Макс. соединений
  daemon                                                # Run in background / Запуск как демон
  user haproxy                                          # User / Пользователь
  group haproxy                                         # Group / Группа
  master-worker                                         # Graceful reload / Безразрывный перезапуск
  stats socket /run/haproxy.sock mode 660 level admin expose-fd listeners
                                                        # Runtime socket / Управление через сокет
  nbthread 4                                            # Number of threads / Кол-во потоков (по ядрам CPU)
  tune.ssl.default-dh-param 2048                        # DH param size / Размер ключа DH
  ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 # Disable weak TLS / Отключить слабые версии TLS
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:... # Allowed ciphers / Шифры
```

**Key Parameters:**
- `log <address> <facility>` — Define syslog server / Указать syslog-сервер
- `maxconn <number>` — Global connection limit / Глобальное ограничение соединений
- `nbthread <number>` — Threads (recommended = CPU cores) / Потоки (= число ядер)
- `master-worker` — Enables seamless reloads / Безразрывные перезапуски
- `stats socket` — Enable runtime API / Включить runtime API

---

### Defaults Section

Defaults section sets common settings for all proxies / Раздел defaults задает общие настройки

```cfg
defaults
  mode http                                             # default mode / Режим по умолчанию (http|tcp)
  log global                                            # Use global logging / Использовать глобальный лог
  option httplog                                        # HTTP log format / Лог в формате HTTP
  option dontlognull                                    # Skip empty conns / Не логировать пустые соединения
  option http-keep-alive                                # Keep-Alive / Поддержка keep-alive
  option forwardfor if-none                             # Add X-Forwarded-For / Добавить IP клиента
  timeout connect 5s                                    # Timeout to connect backend / Таймаут подключения
  timeout client  60s                                   # Timeout client / Таймаут клиента
  timeout server  60s                                   # Timeout server / Таймаут сервера
  retries 3                                             # Retry attempts / Кол-во повторных попыток
  default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
                                                        # Server defaults / Настройки проверки серверов
```

**Key Parameters:**
- `mode http|tcp` — Operating mode / Режим работы
- `option httplog` — Detailed HTTP log format / Подробный формат логов HTTP
- `option forwardfor` — Add `X-Forwarded-For` header / Добавить заголовок с IP клиента
- `timeout connect/client/server` — Connection timeouts / Таймауты соединений
- `retries` — Retry attempts on failure / Повторные попытки при ошибке

---

### Frontend Section

Frontend defines entry point for connections / Frontend определяет точку входа

```cfg
frontend fe_http
  bind *:80                                             # Bind address:port / Адрес и порт
  mode http                                             # Mode (http|tcp) / Режим работы
  default_backend bk_web                                # Default backend / Бэкенд по умолчанию
  
  # HTTP→HTTPS redirect / Редирект HTTP→HTTPS
  http-request redirect scheme https code 301 if !{ ssl_fc }
  
  # Add unique request ID / Добавить уникальный ID
  http-request set-header X-Request-ID %[unique-id]
```

**Key Parameters:**
- `bind <IP>:<port>` — Listening address and port / Адрес и порт для прослушивания
- `default_backend` — Default backend pool / Бэкенд по умолчанию
- `http-request` — Request rules (redirect, deny, set-header) / Правила обработки запросов

---

### Backend Section

Backend defines server pool / Backend определяет пул серверов

```cfg
backend bk_web
  balance roundrobin                                    # Load balancing algo / Алгоритм балансировки
  server web1 <IP1>:80 check                            # Server + health-check / Сервер с проверкой
  server web2 <IP2>:80 check
  server web3 <IP3>:80 check backup                     # Backup server / Резервный сервер
```

**Key Parameters:**
- `balance` — Load balancing algorithm / Алгоритм балансировки
- `server <name> <ip>:<port> [options]` — Define backend server / Определить сервер
- `check` — Enable health-check / Включить проверку здоровья
- `backup` — Use only if others fail / Использовать только при падении других

---

### Listen Section

Listen combines frontend + backend / Listen объединяет frontend и backend

```cfg
listen stats
  bind *:8404                                           # Bind port / Порт веб-интерфейса
  mode http                                             # HTTP mode / Режим HTTP
  stats enable                                          # Enable stats / Включить статистику
  stats uri /stats                                      # URI / Путь к странице статистики
  stats auth <USER>:<PASSWORD>                          # Login / Авторизация
  stats refresh 5s                                      # Auto-refresh / Автообновление
```

---

## Load Balancing Algorithms

### Common Algorithms / Основные алгоритмы

| Algorithm | Description (EN) | Description (RU) | Use Case |
| :--- | :--- | :--- | :--- |
| **roundrobin** | Sequentially distributes requests. Dynamic (can change weight on the fly). Default. | Последовательно распределяет запросы. Динамический (можно менять вес на лету). По умолчанию. | General purpose / Общее назначение |
| **leastconn** | Selects server with fewest active connections. Recommended for long sessions (DB, WebSocket). | Выбирает сервер с наименьшим числом активных соединений. Рекомендуется для долгих сессий (БД, WebSocket). | Databases, long sessions / Базы данных, долгие сессии |
| **source** | Hashes client IP. Ensures specific IP always hits the same server (unless server goes down). | Хеширует IP клиента. Гарантирует, что IP попадает на тот же сервер (если он доступен). | IP Persistence / Привязка по IP |
| **uri** | Hashes the URI (path + query). Optimizes cache hit rates. | Хеширует URI (путь + запрос). Оптимизирует попадание в кэш. | Caching proxies / Кэширующие прокси |
| **url_param** | Hashes a specific URL parameter. | Хеширует конкретный параметр URL. | Tracking, User ID / Трекинг, ID пользователя |
| **hdr(name)** | Hashes a specific HTTP header (e.g., `hdr(User-Agent)`). | Хеширует конкретный HTTP заголовок (например, `User-Agent`). | Specialized routing / Специальная маршрутизация |
| **random** | Randomly chooses a server. Consistent hashing available. | Случайный выбор сервера. Доступно консистентное хеширование. | Large farms / Большие фермы |

### Configuration Example / Пример конфигурации

```cfg
backend bk_web
    # 1. Round Robin (Default) / По кругу (По умолчанию)
    balance roundrobin

    # 2. Least Connections (DBs) / Меньше всего соединений (БД)
    # balance leastconn

    # 3. Source IP Hash (Session stickiness) / Хеш по IP (Липкость сессии)
    # balance source

    # 4. URI Hash (Cache) / Хеш по URI (Кэш)
    # balance uri
    # hash-type consistent # Consistent hashing for cache / Консистентное хеширование для кэша

    # 5. URL Parameter / Параметр URL
    # balance url_param userid checkout
```

---

## ACL & Routing

Access Control Lists (ACLs) are the core of HAProxy's flexibility. They define conditions to route traffic, block requests, or modify headers.
ACL - это основа гибкости HAProxy. Они определяют условия для маршрутизации трафика, блокировки запросов или изменения заголовков.

### 1. Basic Syntax / Базовый синтаксис

`acl <acl_name> <criterion> [flags] [operator] <value> ...`

*   **acl_name**: Arbitrary name (e.g., `is_api`, `bad_ip`). / Произвольное имя.
*   **criterion**: What to check (e.g., `src`, `path`, `hdr`). / Что проверять.
*   **flags**: `-i` (ignore case), `-m` (match method). / Флаги: `-i` (без учета регистра).
*   **value**: Pattern to match. / Значение для проверки.

### 2. Logical Operators / Логические операторы

*   **AND**: Implicit (listing ACLs one after another). / Неявный (перечисление ACL подряд).
*   **OR**: `||` or `or`. / `||` или `or`.
*   **Negation (NOT)**: `!`. / Отрицание: `!`.

```cfg
http-request deny if is_admin !is_internal_ip      # Deny if admin AND NOT internal IP
http-request deny if bad_bot || bad_referer        # Deny if bad bot OR bad referer
```

### 3. Common Matching Methods / Методы сравнения

| Suffix | Meaning | Example |
| :--- | :--- | :--- |
| **(exact)** | Exact match / Точное совпадение | `path /api` |
| **_beg** | Prefix match / Начало строки | `path_beg /api/` |
| **_end** | Suffix match / Конец строки | `path_end .jpg` |
| **_sub** | Substring match / Подстрока | `hdr_sub(User-Agent) Mozilla` |
| **_reg** | Regular expression / Регулярное выражение | `path_reg ^/api/v[0-9]+/` |
| **_dir** | Subdirectory match / Подпапка | `path_dir api` (matches `/api/foo`) |
| **_dom** | Domain match / Домен | `hdr_dom(host) example.com` |

### 4. Common Criteria / Основные критерии

| Criterion | Description (EN) | Description (RU) |
| :--- | :--- | :--- |
| **src** | Source IP address. | IP адрес источника. |
| **path** | Request path (URI without query string). | Путь запроса (без query string). |
| **url** | Full URL. | Полный URL. |
| **method** | HTTP method (GET, POST, etc.). | HTTP метод. |
| **hdr(name)** | specific HTTP header value. | Значение конкретного заголовка. |
| **query** | Query string parameters. | Параметры строки запроса. |
| **ssl_fc** | Returns true if connection is SSL/TLS. | Истина, если соединение SSL/TLS. |
| **ssl_fc_sni** | SNI value sent by client. | Значение SNI от клиента. |
| **dst_port** | Destination port. | Порт назначения. |

### 5. Detailed Examples / Подробные примеры

```cfg
frontend fe_main
  bind *:443 ssl crt /etc/haproxy/certs/

  # --- DEFINITIONS / ОПРЕДЕЛЕНИЯ ---

  # Path matching / Совпадение по пути
  acl is_api        path_beg /api
  acl is_static     path_end .jpg .png .css .js

  # Host matching / Совпадение по хосту
  acl is_admin_host hdr(host) -i admin.example.com

  # IP Whitelist / Белый список IP
  acl is_internal   src 10.0.0.0/8 192.168.1.0/24

  # User-Agent blocking / Блокировка по User-Agent
  acl is_bad_bot    hdr_sub(User-Agent) -i curl wget python scan

  # Method check / Проверка метода
  acl is_post       method POST

  # --- ACTIONS / ДЕЙСТВИЯ ---

  # 1. Block bad bots / Блокировка ботов
  http-request deny if is_bad_bot

  # 2. Protect Admin Area (Allow only internal IPs) / Защита админки
  # Deny if trying to access admin host AND NOT from internal IP
  http-request deny if is_admin_host !is_internal

  # 3. Routing / Маршрутизация
  use_backend bk_api      if is_api
  use_backend bk_static   if is_static
  use_backend bk_admin    if is_admin_host

  # 4. Default / По умолчанию
  default_backend bk_www
```

---

## SSL/TLS Configuration

### HTTPS Termination / Терминация HTTPS

```cfg
frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1  # Enable TLS + HTTP/2 / Включение TLS и HTTP/2
  
  # HSTS header / HSTS заголовок
  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  
  default_backend bk_app
```

### HTTP → HTTPS Redirect / Редирект HTTP→HTTPS

```cfg
frontend fe_http
  bind :80
  http-request redirect scheme https code 301 unless { ssl_fc }
```

### TLS Passthrough (L4) / Сквозной TLS

```cfg
defaults
  mode tcp                                              # TCP mode / TCP режим
  option tcplog                                         # TCP log format / Лог TCP

frontend fe_tls_passthrough
  bind :443
  tcp-request inspect-delay 5s
  tcp-request content accept if { req_ssl_hello_type 1 }
  
  use_backend bk_tls_www if { req_ssl_sni -i <HOST> }  # Route by SNI / Роутинг по SNI
  default_backend bk_tls_www

backend bk_tls_www
  server w1 <IP1>:443 check
```

### SSL Best Practices / Лучшие практики SSL

```cfg
global
  tune.ssl.default-dh-param 2048
  ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
  ssl-default-bind-ciphers HIGH:!aNULL:!MD5

frontend fe_secure
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  http-response set-header Strict-Transport-Security "max-age=31536000"
```

---

## Health Checks

Health checks determine if a server is available to receive traffic.
Проверки здоровья определяют, доступен ли сервер для приема трафика.

### 1. Active Health Checks (Polling) / Активные проверки (Опрос)

The `check` keyword enables active periodic checks. HAProxy probes the server.
Ключевое слово `check` включает активные периодические проверки. HAProxy опрашивает сервер.

```cfg
backend bk_pool
  # Basic TCP check / Базовая TCP проверка
  server web1 192.168.1.10:80 check inter 2s rise 3 fall 2
```

**Parameters / Параметры:**
*   `check`: Enables health checking.
*   `inter <time>`: Interval between checks (default: 2s). / Интервал между проверками.
*   `rise <count>`: Number of successful checks to mark server UP. / Число успехов для статуса UP.
*   `fall <count>`: Number of failed checks to mark server DOWN. / Число неудач для статуса DOWN.
*   `port <port>`: Port to check (if different from traffic port). / Порт проверки (если отличается).

### 2. HTTP Health Check / HTTP проверка

Checks a specific URL endpoint instead of just TCP connection.
Проверяет конкретный URL вместо простого TCP соединения.

```cfg
backend bk_app
  option httpchk GET /healthz HTTP/1.1\r\nHost:\ www.example.com
  http-check expect status 200-299
  
  server app1 10.0.0.1:8080 check inter 5s
  server app2 10.0.0.2:8080 check inter 5s
```

*   `option httpchk <Method> <URI> <Version>`
*   `http-check expect`: Condition for success (status code, string, regex).

### 3. Passive Health Checks (Traffic Observation) / Пассивные проверки (Наблюдение)

Monitors real traffic. If requests fail, the server is marked down or ignored temporarily.
Мониторит реальный трафик. Если запросы падают, сервер помечается недоступным или временно игнорируется.

```cfg
backend bk_passive
  # Observe L4 (TCP) connection problems
  # Наблюдать за L4 (TCP) проблемами соединения
  server db1 10.0.0.1:3306 check observe layer4 error-limit 10 on-error mark-down

  # Observe L7 (HTTP) errors
  # Наблюдать за L7 (HTTP) ошибками
  server web1 10.0.0.1:80 check observe layer7 error-limit 50 on-error mark-down
```

**Parameters:**
*   `observe <layer4|layer7>`: What to monitor.
*   `error-limit <count>`: Number of errors allowed.
*   `on-error <mark-down|fastinter>`: Action on error limit.
    *   `mark-down`: Mark server dead.
    *   `fastinter`: Switch to faster active checks (if `check` is enabled).

### 4. Agent Check (Sidecar) / Проверка через Агента

HAProxy connects to a specific port where an agent (like `xinetd` script) reports status.
HAProxy подключается к порту, где агент сообщает статус (текстом: `up`, `down`, `maint`, `ready`).

```cfg
backend bk_agent
  server app1 10.0.0.1:80 check agent-check agent-port 9999 agent-inter 5s
```

### 5. Advanced Parameters / Продвинутые параметры

*   `check-ssl`: Force SSL for health checks.
*   `check-send-proxy`: Send PROXY protocol header during check.
*   `fail_timeout <time>`: (Deprecated/Synonym) Time to wait for a check response (usually covered by `inter` logic).
*   `max_fails <count>`: (Deprecated/Synonym) Same as `fall`.
    *   *Note:* User snippet `check max_fails=3 fail_timeout=30s` is valid legacy syntax but `check inter 30s fall 3` is preferred.
    *   *Заметка:* Сниппет `check max_fails=3 fail_timeout=30s` валиден (старый синтаксис), но `active check` параметры предпочтительнее.

---

### Detailed Example / Подробный пример

```cfg
backend bk_production
  balance roundrobin
  
  # HTTP Check: GET /api/health
  option httpchk GET /api/health
  http-check expect status 200
  
  # Check every 2s, 3 fails = DOWN, 2 success = UP
  server s1 10.0.0.1:80 check inter 2s fall 3 rise 2
  
  # Backup server (used only if s1 is down)
  server b1 10.0.0.2:80 check backup
  
  # Maintenance mode (static code)
  server maint 127.0.0.1:8080 disabled
```

---

## Stick Tables & Rate Limiting

Stick tables are HAProxy’s in-memory key-value storage. They allow making decisions based on past client behavior (requests, errors, rates), not just the current request.
Stick-таблицы — это in-memory хранилище HAProxy. Они позволяют принимать решения на основе истории поведения клиента (запросы, ошибки, скорость), а не только текущего запроса.

### 1. Core Concepts / Основные концепции

| Element | Description (EN) | Description (RU) |
| :--- | :--- | :--- |
| **Key** | Identifier (IP, cookie, header). | Идентификатор (IP, куки, заголовок). |
| **Store** | Stored data (counters, rates, flags). | Хранимые данные (счетчики, скорость). |
| **Expire** | Time to keep inactive entries. | Время хранения неактивных записей. |
| **Size** | Max number of entries in RAM. | Макс. число записей в памяти. |

### 2. Basic Configuration / Базовая конфигурация

```cfg
backend bk_app
  # Define table: Key=IP, Max=100k, TTL=30m, Track=ReqRate(10s)
  stick-table type ip size 100k expire 30m store http_req_rate(10s)
  
  # Track every request by Source IP
  stick on src
```

### 3. Rate Limiting Example / Пример ограничения скорости

Block clients exceeding 50 requests per 10 seconds.
Блокировка клиентов, превышающих 50 запросов за 10 секунд.

```cfg
frontend fe_http
  bind :80
  
  # Define table
  stick-table type ip size 200k expire 10m store http_req_rate(10s)
  
  # Track request
  http-request track-sc0 src
  
  # Check limit (gt = greater than)
  acl too_fast sc_http_req_rate(0) gt 50
  
  # Deny if limit exceeded
  http-request deny if too_fast
  
  default_backend bk_app
```

### 4. Sticky Sessions (Persistence) / Липкие сессии

Ensure a client always hits the same server.
Гарантия того, что клиент всегда попадает на один и тот же сервер.

**By Cookie (Recommended) / По куки:**

```cfg
backend bk_app
  # Key is a string (32 chars max)
  stick-table type string len 32 size 100k expire 1h
  
  # Use 'sessionid' cookie as key
  stick on req.cook(sessionid)
  
  server s1 10.0.0.1:80 check
  server s2 10.0.0.2:80 check
```

**By IP (Not recommended due to NAT/VPN) / По IP:**

```cfg
backend bk_app
  stick-table type ip size 100k expire 1h
  stick on src
  server s1 10.0.0.1:80 check
  server s2 10.0.0.2:80 check
```

### 5. What Can Be Stored? / Что можно хранить?

| Store | Purpose (EN) | Purpose (RU) |
| :--- | :--- | :--- |
| `http_req_rate(<period>)` | HTTP request rate. | Скорость HTTP запросов. |
| `http_err_rate(<period>)` | HTTP error rate (4xx/5xx). | Скорость ошибок HTTP. |
| `conn_rate(<period>)` | TCP connection rate. | Скорость TCP соединений. |
| `conn_cur` | Current open connections. | Текущие открытые соединения. |
| `bytes_in_rate(<period>)` | Traffic ingress rate. | Скорость входящего трафика. |
| `gpc0`, `gpc1` | General Purpose Counters. | Счетчики общего назначения. |

### 6. Custom Logic (GPC) / Пользовательская логика

Example: Ban IP after 5 failed logins.
Пример: Бан IP после 5 неудачных логинов.

```cfg
frontend fe_login
  stick-table type ip size 100k expire 1h store gpc0
  
  # Track request
  http-request track-sc0 src
  
  # Increment limit if login failed (detected by path/status)
  acl login_fail path_beg /login method POST status 401
  http-request sc-inc-gpc0(0) if login_fail
  
  # Deny if counter > 5
  acl is_banned sc_get_gpc0(0) gt 5
  http-request deny if is_banned
```

### 7. Tables vs Cookies / Таблицы против Кук

| Feature | Stick Tables | Cookies |
| :--- | :--- | :--- |
| **Storage** | Server RAM (Shared state possible via peers). | Client Browser. |
| **Visibility** | Invisible to client. | Visible to client. |
| **Logic** | Rate limits, Bans, Tracking. | Session ID, Routing only. |
| **Usage** | Security, DDoS, complex routing. | Simple session persistence. |

---



### DDoS Protection / Защита от DDoS

```cfg
frontend fe_protected
  bind *:80
  stick-table type ip size 100k expire 10s store http_req_rate(10s),conn_cur
  http-request track-sc0 src
  
  # RPS limit / Лимит RPS
  acl too_fast  sc_http_req_rate(0) gt 100
  # Connection limit / Лимит соединений
  acl too_many  sc_conn_cur(0)      gt 50
  
  http-request deny if too_fast or too_many
  
  default_backend bk_site
```

---

## Caching

Built-in HTTP cache / Встроенный HTTP кэш

```cfg
cache static_cache
  total-max-size 256                                    # Cache size (MB) / Размер кэша
  max-object-size 10485760                              # Max object size / Макс. размер объекта
  max-age 600                                           # Default TTL (seconds) / Время жизни (сек)

backend bk_www
  http-request cache-use static_cache
  http-response cache-store static_cache if { res.hdr(Cache-Control) -m found }
  
  server w1 <IP1>:80 check
```

---

## Logging

### Basic Logging / Базовое логирование

```cfg
global
  log /dev/log local0

defaults
  log global
  option httplog                                        # HTTP log format / Лог HTTP
  # option tcplog                                       # TCP log format / Лог TCP
```

### Custom Log Format / Пользовательский формат

```cfg
defaults
  log-format "%ci:%cp -> %fi:%fp [%tr] %ST %HM %HP %HU ua=%{+Q}HV:user-agent req_id=%ID"
```

### Log Variables / Переменные логов

- `%ci` — Client IP / IP клиента
- `%cp` — Client port / Порт клиента
- `%fi` — Frontend IP / IP фронтенда
- `%fp` — Frontend port / Порт фронтенда
- `%tr` — Time received / Время получения
- `%ST` — Status code / Код статуса
- `%HM` — HTTP method / HTTP метод
- `%HU` — Request URI / URI запроса

---

## Runtime Management

**Runtime commands** are used to manage a **running HAProxy** instance via the admin/stat socket **without reload or restart**.
**Runtime-команды** — это команды управления **работающим HAProxy** через admin/stat socket **без reload и restart**.

> HAProxy can be managed "on the fly" without dropping active connections or downtime.
> HAProxy можно управлять «на лету», не разрывая активные соединения и без downtime.

---

### Admin Socket / Админ-сокет

Typical configuration in `global` section:
Типовая конфигурация в разделе `global`:

```cfg
global
    stats socket /run/haproxy.sock mode 660 level admin
```

*   **level admin**: Required for state-changing commands. / Требуется для команд изменения состояния.
*   **socat**: Common tool to send commands to the socket. / Инструмент для отправки команд в сокет.

**Sending commands / Отправка команд:**

```bash
echo "<command>" | socat - /run/haproxy.sock
```

---

### Core Runtime Commands / Основные команды

#### Disable server / Отключить сервер
```bash
echo "disable server bk_web/web2" | socat - /run/haproxy.sock
```
*   Server marked as `MAINT`. New connections are not accepted.
*   Active connections are **not dropped**.
*   Сервер помечается как `MAINT`. Новые соединения не принимаются.
*   Активные соединения **не рвутся**.

#### Enable server / Включить сервер
```bash
echo "enable server bk_web/web2" | socat - /run/haproxy.sock
```
*   Server returns to the pool. Traffic is distributed again.
*   Сервер возвращается в пул. Трафик снова распределяется.

#### Set server weight / Изменить вес
```bash
echo "set server bk_web/web2 weight 5" | socat - /run/haproxy.sock
```
*   Used for gradual rollout, canary, or node degradation.
*   Используется для плавного вывода, canary-релизов или деградации нод.

#### Show server state / Состояние серверов
```bash
echo "show servers state" | socat - /run/haproxy.sock
```
*   Shows state (`UP`, `DOWN`, `MAINT`) and effective weight.
*   Показывает состояние (`UP`, `DOWN`, `MAINT`) и текущий вес.

#### Show stick-table / Показать stick-таблицу
```bash
echo "show table fe_guard" | socat - /run/haproxy.sock
```
*   Used for debugging rate-limits and bans.
*   Критично для отладки rate-limit и банов.

#### Show stat / Показать статистику
```bash
echo "show stat" | socat - /run/haproxy.sock
```
*   Detailed CSV statistics (connections, errors, latency).
*   Полная CSV-статистика (соединения, ошибки, задержки).

---

### Dangerous Runtime Commands / Опасные команды ⚠️

> [!WARNING]
> These commands can impact production if used without full understanding.
> Эти команды **могут уронить прод**, если использовать без понимания.

#### Clear stick-table / Очистить таблицу
```bash
echo "clear table fe_guard" | socat - /run/haproxy.sock
```
*   **Risk**: Removes all bans and resets rate-limit counters.
*   **Опасность**: Снимаются все баны, обнуляются счётчики.

#### Shutdown sessions / Разорвать сессии
```bash
echo "shutdown sessions server bk_web/web2" | socat - /run/haproxy.sock
```
*   **Risk**: **Immediately drops all active connections**.
*   **Опасность**: **Немедленно рвёт все активные соединения**.

#### Disable backend / Отключить бэкенд
```bash
echo "disable backend bk_web" | socat - /run/haproxy.sock
```
*   **Risk**: Backend stops serving traffic entirely; frontend returns errors.
*   **Опасность**: Backend перестаёт обслуживать трафик; frontend отдаёт ошибки.

---

### Important Notes / Важные замечания

*   Changes are **not persistent**. They disappear on reload/restart.
*   Изменения **не сохраняются** в конфиге. Пропадают при reload/restart.
*   Exist only in memory. If you need it permanent — update the config.
*   Существуют только в памяти. Для постоянства — правь конфиг.

---

### Production Runbook / Сценарии для продакшена

#### Zero-Downtime Deploy / Деплой без простоя
1. `disable server bk_web/web2`
2. Wait for `conn_cur = 0`. / Дождаться завершения соединений.
3. Deploy / Update. / Деплой / Обновление.
4. `enable server bk_web/web2`

#### Emergency (Immediate Removal) / Авария (Срочно убрать ноду)
1. `shutdown sessions server bk_web/web2`
2. `disable server bk_web/web2`

---

## Production Scenarios

### 1) Basic HTTP Load Balancer / Базовая HTTP-балансировка

```cfg
global
  log /dev/log local0
defaults
  mode http
  log  global
  option httplog
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_http
  bind :80
  default_backend bk_web

backend bk_web
  balance roundrobin
  option httpchk GET /healthz
  http-check expect status 200
  server web1 <IP1>:80 check
  server web2 <IP2>:80 check
```

---

### 2) HTTPS Termination + HTTP/2 / Терминация HTTPS

```cfg
global
  log /dev/log local0
  master-worker
  tune.ssl.default-dh-param 2048

defaults
  mode http
  log global
  option httplog
  option forwardfor if-none
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_http
  bind :80
  http-request redirect scheme https code 301 unless { ssl_fc }

frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  default_backend bk_www

backend bk_www
  balance leastconn
  server w1 <IP1>:80 check
  server w2 <IP2>:80 check
```

---

### 3) Static Cache + Compression / Кэш статики + компрессия

```cfg
cache static_cache
  total-max-size 256
  max-object-size 10485760
  max-age 600

frontend fe_edge
  bind :80
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  http-request redirect scheme https code 301 if !{ ssl_fc }
  
  acl is_api path_beg /api
  use_backend bk_api if is_api
  default_backend bk_www

backend bk_www
  compression algo gzip
  compression type text/html text/css application/javascript application/json image/svg+xml
  balance leastconn
  
  # cache: only static files
  acl static path_reg -i \.(css|js|png|jpg|jpeg|gif|svg|webp|ico|woff2?)$
  http-request  cache-use  static_cache
  http-response cache-store static_cache if static
  
  server w1 <IP1>:80 check

backend bk_api
  option httpchk GET /health
  http-check expect status 200
  server a1 <IP1>:8080 check
```

---

### 4) Sticky Sessions (Cookie) / Липкие сессии

```cfg
frontend fe_app
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  default_backend bk_app

backend bk_app
  balance roundrobin
  cookie SRV insert indirect nocache secure httponly
  server app1 <IP1>:8080 check cookie app1
  server app2 <IP2>:8080 check cookie app2
```

---

### 5) WebSocket Proxy / WebSocket прокси

```cfg
frontend fe_ws
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  
  acl ws_upgrade hdr(Upgrade) -i websocket
  acl conn_up    hdr(Connection) -i upgrade
  use_backend bk_ws if ws_upgrade conn_up
  default_backend bk_site

backend bk_ws
  option http-server-close
  server ws1 <IP1>:8080 check

backend bk_site
  server s1 <IP1>:80 check
```

---

### 6) Canary / Blue-Green Deployment / Канареечный релиз

```cfg
frontend fe_edge
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  default_backend bk_canary

backend bk_canary
  balance roundrobin
  acl is_canary hdr(X-Canary) -i 1
  use-server canary if is_canary
  server stable <IP1>:8080 check weight 90            # 90% traffic / 90% трафика
  server canary <IP2>:8080 check weight 10            # 10% traffic / 10% трафика
```

---

### 7) Multi-Host Routing (Map File) / Маршрутизация по Host

**`/etc/haproxy/domains.map`:**

```
<HOST1> bk_app1
<HOST2> bk_app2
<HOST3> bk_app3
```

**Config:**

```cfg
frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  use_backend %[req.hdr(host),lower,map(/etc/haproxy/domains.map,bk_default)]

backend bk_app1
  server a1 <IP1>:8080 check

backend bk_app2
  server a2 <IP2>:8080 check

backend bk_app3
  server a3 <IP3>:8080 check

backend bk_default
  http-request return status 404 content-type "text/plain" string "Unknown host"
```

---

## Quick Templates

### Minimal Reverse Proxy / Минимальный реверс-прокси

```cfg
global
  log /dev/log local0
  master-worker

defaults
  mode http
  log  global
  option httplog
  option forwardfor if-none
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_http
  bind :80
  default_backend bk_app

backend bk_app
  balance roundrobin
  server app1 <IP>:8080 check
```

---

### Production Template / Шаблон для продакшена

```cfg
global
  log /dev/log local0
  master-worker
  tune.ssl.default-dh-param 2048
  stats socket /run/haproxy.sock mode 660 level admin

defaults
  mode http
  log  global
  option httplog
  option forwardfor if-none
  timeout connect 5s
  timeout client  60s
  timeout server  60s

# HTTP → HTTPS
frontend fe_http
  bind :80
  http-request redirect scheme https code 301 unless { ssl_fc }

# Edge HTTPS
frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  default_backend bk_app

backend bk_app
  balance leastconn
  option httpchk GET /
  http-check expect rstatus 200|3[0-9][0-9]
  server app1 <IP>:8080 check

# Stats page
listen stats
  bind :8404
  mode http
  stats enable
  stats uri /stats
  stats refresh 5s
  stats auth <USER>:<PASSWORD>
```

---

## Troubleshooting

### Common Issues / Частые проблемы

```bash
# 503 errors / Ошибки 503
# Check backend servers health / Проверить здоровье backend серверов
echo "show stat" | socat - /run/haproxy.sock | grep DOWN

# Redirects to 127.0.0.1:8080 (Tomcat)
# Enable RemoteIpValve or set proxyName/proxyPort in server.xml
# Включить RemoteIpValve или установить proxyName/proxyPort

# Sticky sessions not working / Липкость не работает
# Check jvmRoute matches cookie in Tomcat
# Проверить совпадение jvmRoute и cookie

# Certificate errors / Ошибки сертификатов
# Check certificate bundle includes full chain
# Проверить что сертификат включает полную цепочку
ls -la /etc/haproxy/certs/

# Port already in use / Порт уже используется
sudo netstat -tlnp | grep :80                          # Check port / Проверить порт
sudo lsof -i :80                                       # Alternative / Альтернатива
```

### Debug Commands / Команды отладки

```bash
# Test configuration / Тест конфигурации
haproxy -c -f /etc/haproxy/haproxy.cfg

# Show vhost summary / Показать vhost
echo "show info" | socat - /run/haproxy.sock

# Show backend status / Показать статус backend
echo "show stat" | socat - /run/haproxy.sock

# Enable debug logging / Включить отладочное логирование
# Add to global section:
# debug

# Check systemd status / Проверить статус systemd
sudo systemctl status haproxy -l
sudo journalctl -u haproxy -f                          # Follow logs / Следить за логами
```

### Best Practices / Лучшие практики

- Always validate config before reload: `haproxy -c -f /etc/haproxy/haproxy.cfg`
- Use `systemctl reload` for zero-downtime / Используй `reload` для безразрывности
- Enable runtime socket for live management / Включи runtime socket
- Use `master-worker` mode / Используй режим `master-worker`
- Set up health checks on all backends / Настрой health checks
- Configure SSL/TLS properly (TLS 1.2+) / Настрой SSL/TLS (TLS 1.2+)
- Use stick-tables for rate limiting / Используй stick-таблицы для ограничения
- Monitor logs and stats / Мониторь логи и статистику
- Keep HAProxy updated / Обновляй HAProxy

---

## Production Checklist / Чеклист для продакшена

- [ ] `master-worker` enabled / `master-worker` включён
- [ ] Runtime socket configured / Runtime socket настроен
- [ ] Health checks on all backends / Health checks на всех backends
- [ ] SSL/TLS with TLS 1.2+ / SSL/TLS с TLS 1.2+
- [ ] HSTS header configured / HSTS заголовок настроен
- [ ] Rate limiting enabled / Rate limiting включён
- [ ] Logging configured / Логирование настроено
- [ ] Stats page accessible / Статистика доступна
- [ ] Backup servers defined / Резервные серверы определены
- [ ] Monitoring in place / Мониторинг установлен

---

## Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/haproxy`

```conf
/var/log/haproxy.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 haproxy adm
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /run/haproxy.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
```

> [!TIP]
> HAProxy logs to syslog by default. Configure rsyslog to separate HAProxy logs if needed.
> HAProxy по умолчанию пишет в syslog. Настройте rsyslog для отдельных логов HAProxy.

---

