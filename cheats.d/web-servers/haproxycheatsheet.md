Title: 🌀 HAProxy — Cheatsheet
Group: Web Servers
Icon: 🌀
Order: 5


---

# 🌀 HAProxy Mega-Cheatsheet — EN / RU

## 📂 Global section / Глобальный раздел

```cfg
global
  log /dev/log local0        # Syslog facility / Логирование в syslog (facility local0)
  chroot /var/lib/haproxy    # Jail dir / Директория chroot для безопасности
  pidfile /run/haproxy.pid   # PID file / Файл для хранения PID
  maxconn 10000              # Max concurrent connections / Макс. число соединений
  daemon                     # Run in background / Запуск как демон
  user haproxy               # User / Пользователь
  group haproxy              # Group / Группа
  master-worker              # Graceful reload / Безразрывный перезапуск
  stats socket /run/haproxy.sock mode 660 level admin expose-fd listeners
                             # Runtime socket / Управление через сокет
  nbproc 1                   # Number of processes / Кол-во процессов (deprecated)
  nbthread 4                 # Number of threads / Кол-во потоков (по ядрам CPU)
  tune.ssl.default-dh-param 2048  # DH param size / Размер ключа DH
  ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
                             # Disable weak TLS / Отключить слабые версии TLS
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:... 
                             # Allowed ciphers / Допустимые шифры
```

---

## ⚙️ Defaults section / Раздел defaults

```cfg
defaults
  mode http                  # default mode / Режим по умолчанию (http|tcp)
  log global                 # Use global logging / Использовать глобальный лог
  option httplog             # HTTP log format / Лог в формате HTTP
  option tcplog              # TCP log format / Лог TCP (если mode tcp)
  option dontlognull         # Skip empty conns / Не логировать пустые соединения
  option http-keep-alive     # Keep-Alive / Поддержка keep-alive
  option forwardfor if-none  # Add X-Forwarded-For / Добавить IP клиента
  timeout connect 5s         # Timeout to connect backend / Таймаут подключения
  timeout client  60s        # Timeout client / Таймаут клиента
  timeout server  60s        # Timeout server / Таймаут сервера
  retries 3                  # Retry attempts / Кол-во повторных попыток
  default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
                             # Server defaults / Настройки проверки серверов
```

---

## 🎛 Frontend section / Раздел frontend

```cfg
frontend fe_http
  bind *:80                  # Bind address:port / Адрес и порт для входящих коннектов
  mode http                  # Mode (http|tcp) / Режим работы
  default_backend bk_web     # Default backend / Бэкенд по умолчанию
  http-request redirect scheme https code 301 if !{ ssl_fc }
                             # Redirect HTTP→HTTPS / Редирект на HTTPS
  http-request set-header X-Request-ID %[unique-id]
                             # Add header / Добавить уникальный ID в заголовок
```

---

## 🔙 Backend section / Раздел backend

```cfg
backend bk_web
  balance roundrobin         # Load balancing algo / Алгоритм балансировки
  server web1 192.168.1.10:80 check
                             # Server + health-check / Сервер с проверкой
  server web2 192.168.1.11:80 check
```

**Алгоритмы балансировки / LB algorithms**:

* `roundrobin` → Round-robin / По кругу
* `leastconn` → Least connections / Меньше всего соединений
* `source` → Hash by client IP / Хеш по IP клиента
* `uri` → Hash by URI / Хеш по URI
* `url_param(<param>)` → Hash by URL param / Хеш по параметру URL

---

## 🎧 Listen section / Раздел listen

```cfg
listen stats
  bind *:8404                # Bind port / Порт веб-интерфейса
  stats enable               # Enable stats / Включить статистику
  stats uri /stats           # URI / Путь к странице статистики
  stats auth admin:password  # Login / Авторизация
  stats refresh 5s           # Auto-refresh / Автообновление
```

---

## 🧩 ACL (Access Control Lists) / ACL

```cfg
acl is_api   path_beg /api         # Match path / Совпадение по пути
acl is_admin path_beg /admin       # Match /admin
use_backend bk_api if is_api       # Route to API / Перенаправление на API
use_backend bk_admin if is_admin   # Route to Admin

acl bad_bot hdr_sub(user-agent) -i curl wget python
http-request deny if bad_bot       # Block bots / Блокировка ботов
```

---

## 🔒 TLS / SSL

```cfg
frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
                             # Enable TLS + HTTP/2 / Включение TLS и HTTP/2
  http-response set-header Strict-Transport-Security "max-age=31536000"
                             # HSTS header / HSTS заголовок
```

---

## 📦 Caching / Кэширование

```cfg
cache static_cache
  total-max-size 256          # Cache size (MB) / Размер кэша
  max-object-size 10485760    # Max object size / Макс. размер объекта
  max-age 600                 # Default TTL / Время жизни по умолчанию

backend bk_cache
  http-request cache-use static_cache
  http-response cache-store static_cache if { res.hdr(Cache-Control) -m found }
```

---

## 🔐 Stick-tables (Rate-limit / Анти-DDoS)

```cfg
frontend fe_limit
  stick-table type ip size 100k expire 10s store http_req_rate(10s)
                             # Table for rate / Таблица для подсчёта запросов
  http-request track-sc0 src  # Track client IP / Отслеживание по IP
  acl too_fast sc_http_req_rate(0) gt 100
                             # If >100 RPS / Если >100 запросов
  http-request deny if too_fast
                             # Deny request / Запретить
```

---

## 📊 Logging / Логирование

```cfg
global
  log /dev/log local0
defaults
  log global
  option httplog
  log-format "%ci:%cp -> %fi:%fp [%tr] %ST %HM %HP %HU ua=%{+Q}HV:user-agent req_id=%ID"
                             # Custom format / Пользовательский формат
```

---

## ⚡ Reload без простоя / Zero-downtime reload

```bash
# Проверка конфига / Validate config
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload (systemd)
systemctl reload haproxy

# Или вручную / Or manually
haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid)
```

---

## 📌 Основные параметры (краткий справочник) / Main directives

| Параметр            | EN                          | RU                           |
| ------------------- | --------------------------- | ---------------------------- |
| `mode`              | Proxy mode: `http` or `tcp` | Режим прокси: HTTP или TCP   |
| `bind`              | IP:port to listen           | IP:порт для входа            |
| `server`            | Backend server definition   | Определение backend-сервера  |
| `check`             | Enable health-check         | Включить проверку здоровья   |
| `balance`           | Load balancing algorithm    | Алгоритм балансировки        |
| `timeout connect`   | Timeout to backend connect  | Таймаут подключения          |
| `timeout client`    | Timeout for client activity | Таймаут активности клиента   |
| `timeout server`    | Timeout for server response | Таймаут ответа сервера       |
| `option httplog`    | HTTP log format             | Лог HTTP                     |
| `option tcplog`     | TCP log format              | Лог TCP                      |
| `option forwardfor` | Add X-Forwarded-For         | Добавить реальный IP клиента |
| `stats enable`      | Enable statistics page      | Включить статистику          |
| `http-request`      | Rules for requests          | Правила обработки запросов   |
| `http-response`     | Rules for responses         | Правила обработки ответов    |
| `acl`               | Define ACL condition        | Определить условие ACL       |
| `use_backend`       | Route to backend by ACL     | Использовать backend по ACL  |
| `stick-table`       | Create stick-table          | Создать stick-таблицу        |
| `cache`             | Define cache store          | Определить кэш               |

---


# 📖 HAProxy Parameters — EN/RU Detailed Manual

---

## 🔹 Global section / Глобальный раздел

### `log`

```cfg
log <address> <facility> [maxlevel [minlevel]]
```

**EN:** Define syslog server for logging.
**RU:** Указывает syslog-сервер для логов.

Пример:

```cfg
log /dev/log local0 info
```

---

### `chroot`

```cfg
chroot <path>
```

**EN:** Restrict HAProxy process to a directory for security.
**RU:** Ограничение процесса HAProxy директорией для безопасности.

---

### `user` / `group`

```cfg
user haproxy
group haproxy
```

**EN:** Drop privileges after start.
**RU:** Снижение привилегий, запуск от пользователя/группы.

---

### `maxconn`

```cfg
maxconn <number>
```

**EN:** Maximum concurrent connections globally.
**RU:** Глобальное ограничение количества соединений.

---

### `daemon`

```cfg
daemon
```

**EN:** Run as a background process.
**RU:** Запуск в фоне (демон).

---

### `nbthread`

```cfg
nbthread <number>
```

**EN:** Number of threads (recommended = CPU cores).
**RU:** Количество потоков (обычно = число ядер CPU).

---

### `master-worker`

```cfg
master-worker
```

**EN:** Enables master-worker mode for seamless reloads.
**RU:** Включает режим master-worker для безразрывных перезапусков.

---

### `stats socket`

```cfg
stats socket /run/haproxy.sock mode 660 level admin
```

**EN:** Enable runtime API via UNIX socket.
**RU:** Включает runtime API через сокет.

---

### `tune.ssl.default-dh-param`

```cfg
tune.ssl.default-dh-param 2048
```

**EN:** Default size for ephemeral DH keys.
**RU:** Размер ключа DH для шифрования.

---

---

## 🔹 Defaults section / Раздел defaults

### `mode`

```cfg
mode http | tcp
```

**EN:** Operating mode. `http` adds parsing, `tcp` is raw forwarding.
**RU:** Режим работы. `http` — уровень HTTP, `tcp` — простой прокси без анализа.

---

### `log global`

**EN:** Use logging settings from global section.
**RU:** Использовать настройки логирования из global.

---

### `option httplog`

**EN:** Use detailed HTTP log format.
**RU:** Включить подробный формат логов HTTP.

---

### `option tcplog`

**EN:** Use detailed TCP log format.
**RU:** Подробные логи TCP.

---

### `option dontlognull`

**EN:** Don’t log connections with no data.
**RU:** Не логировать пустые соединения.

---

### `option http-keep-alive`

**EN:** Enable persistent HTTP connections.
**RU:** Поддержка Keep-Alive.

---

### `option forwardfor [if-none]`

**EN:** Add `X-Forwarded-For` header with client IP.
**RU:** Добавить заголовок `X-Forwarded-For` с IP клиента.

---

### `timeout connect`

```cfg
timeout connect 5s
```

**EN:** Max time to connect to backend.
**RU:** Максимальное время соединения с backend.

---

### `timeout client`

```cfg
timeout client 60s
```

**EN:** Inactivity timeout for clients.
**RU:** Таймаут неактивности клиента.

---

### `timeout server`

```cfg
timeout server 60s
```

**EN:** Inactivity timeout for server responses.
**RU:** Таймаут ожидания ответа сервера.

---

### `retries`

```cfg
retries 3
```

**EN:** Retry attempts on failure.
**RU:** Количество повторных попыток при ошибке.

---

---

## 🔹 Frontend / Backend / Listen

### `frontend`

```cfg
frontend <name>
  bind *:80
  default_backend bk_site
```

**EN:** Defines entry point for connections.
**RU:** Определяет точку входа для соединений.

---

### `backend`

```cfg
backend <name>
  balance roundrobin
  server s1 192.168.1.10:80 check
```

**EN:** Defines backend pool.
**RU:** Определяет пул серверов.

---

### `listen`

```cfg
listen stats
  bind *:8404
  stats enable
```

**EN:** Combines frontend + backend.
**RU:** Объединяет frontend и backend.

---

---

## 🔹 Общие параметры

### `bind`

```cfg
bind <IP>:<port> [ssl crt ...]
```

**EN:** Defines listening address and port.
**RU:** Указывает адрес и порт для прослушивания.

---

### `balance`

```cfg
balance roundrobin | leastconn | source | uri | url_param(...)
```

**EN:** Load balancing algorithm.
**RU:** Алгоритм балансировки нагрузки.

---

### `server`

```cfg
server <name> <ip>:<port> [options]
```

**EN:** Defines backend server.
**RU:** Определяет сервер в backend.

Важные опции:

* `check` — включить health-check
* `backup` — использовать только при падении других
* `weight <n>` — вес (для балансировки)
* `maxconn <n>` — лимит соединений

---

---

## 🔹 ACL / Rules

### `acl`

```cfg
acl <name> <criterion> <value>
```

**EN:** Access control list rule.
**RU:** Условие для управления трафиком.

Пример:

```cfg
acl is_api path_beg /api
use_backend bk_api if is_api
```

---

### `http-request`

```cfg
http-request redirect scheme https code 301 if !{ ssl_fc }
```

**EN:** Define request rules (redirect, deny, set-header).
**RU:** Правила обработки запросов (редирект, deny, заголовки).

---

### `http-response`

```cfg
http-response set-header X-Served-By haproxy
```

**EN:** Modify response headers.
**RU:** Изменяет заголовки ответа.

---

---

## 🔹 Stick-tables

```cfg
stick-table type ip size 100k expire 10s store http_req_rate(10s)
http-request track-sc0 src
acl too_fast sc_http_req_rate(0) gt 100
http-request deny if too_fast
```

**EN:** Used for rate-limiting, tracking sessions, etc.
**RU:** Используются для ограничения частоты запросов, трекинга сессий и т.д.

---

---

## 🔹 Cache

```cfg
cache my_cache
  total-max-size 256
  max-object-size 10485760
  max-age 600

backend bk_cache
  http-request cache-use my_cache
  http-response cache-store my_cache if { res.hdr(Cache-Control) -m found }
```

**EN:** Built-in cache for responses.
**RU:** Встроенный кэш для ответов.

---

---

## 🔹 Logging

### `log-format`

```cfg
log-format "%ci:%cp -> %fi:%fp [%tr] %ST %HM %HU ua=%{+Q}HV:user-agent"
```

**EN:** Custom log format with variables.
**RU:** Пользовательский формат логов с переменными.

---


---

# 🎯 HAProxy — сценарии конфигураций (EN/RU)

## 1) Базовая HTTP-балансировка (RR)

**EN:** Simple L7 HTTP load balancer with health checks.
**RU:** Простейший L7-балансировщик HTTP с проверками.

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
  server web1 10.0.0.11:80 check
  server web2 10.0.0.12:80 check
```

---

## 2) HTTPS терминация + HTTP/2 + редирект с 80

**EN:** TLS termination at edge with H2 and HSTS; HTTP→HTTPS redirect.
**RU:** Терминация TLS на входе с H2 и HSTS; редирект с 80 на 443.

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
  server w1 10.0.0.21:80 check
  server w2 10.0.0.22:80 check
```

---

## 3) TLS passthrough с маршрутизацией по SNI (L4)

**EN:** End-to-end TLS to backends; route by SNI without decryption.
**RU:** Сквозной TLS до бэкендов; роутинг по SNI без расшифровки.

```cfg
defaults
  mode tcp
  log  global
  option tcplog
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_tls_passthrough
  bind :443
  tcp-request inspect-delay 5s
  tcp-request content accept if { req_ssl_hello_type 1 }
  use_backend bk_tls_www if { req_ssl_sni -i www.example.com }
  use_backend bk_tls_api if { req_ssl_sni -i api.example.com }
  default_backend bk_tls_www

backend bk_tls_www
  server w1 10.0.0.31:443 check

backend bk_tls_api
  server a1 10.0.0.32:443 check
```

---

## 4) Сайт: статика с кэшем + API отдельно + компрессия

**EN:** Static paths cached + gzip compression; API pool split.
**RU:** Кэш статики + gzip; API и WWW в отдельных пулах.

```cfg
global
  log /dev/log local0
defaults
  mode http
  log global
  option httplog
  option forwardfor if-none
  timeout connect 5s
  timeout client  60s
  timeout server  60s

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
  server w1 10.0.1.11:80 check
  server w2 10.0.1.12:80 check

backend bk_api
  option httpchk GET /health
  http-check expect status 200
  server a1 10.0.2.11:8080 check
  server a2 10.0.2.12:8080 check
```

---

## 5) Sticky-sessions (cookie) для stateful приложений

**EN:** Cookie-based persistence to keep user on the same node.
**RU:** Прилипание сессий по cookie для удержания пользователя на узле.

```cfg
defaults
  mode http
  option httplog
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_app
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  default_backend bk_app

backend bk_app
  balance roundrobin
  cookie SRV insert indirect nocache secure httponly
  server app1 10.0.3.11:8080 check cookie app1
  server app2 10.0.3.12:8080 check cookie app2
```

---

## 6) WebSocket через HTTPS

**EN:** WebSocket upgrade detection and dedicated backend.
**RU:** Обнаружение WebSocket и отправка в отдельный backend.

```cfg
frontend fe_ws
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  acl ws_upgrade hdr(Upgrade) -i websocket
  acl conn_up    hdr(Connection) -i upgrade
  use_backend bk_ws if ws_upgrade conn_up
  default_backend bk_site

backend bk_ws
  option http-server-close
  server ws1 10.0.4.11:8080 check

backend bk_site
  server s1 10.0.4.21:80 check
```

---

## 7) gRPC (HTTP/2 end-to-end)

**EN:** gRPC over H2; TLS terminated at edge or end-to-end.
**RU:** gRPC на H2; TLS можно завершать на входе или до бэкенда.

```cfg
frontend fe_grpc
  bind :8443 ssl crt /etc/haproxy/certs/ alpn h2
  mode http
  option http-use-htx
  default_backend bk_grpc

backend bk_grpc
  mode http
  option http-use-htx
  server g1 10.0.5.11:50051 check
```

---

## 8) Rate-limit + анти-скан + tarpit

**EN:** Stick-table limits: RPS and concurrent conns; block scanners.
**RU:** Ограничения по RPS и одновременным соединениям; стоп сканеров, tarpit.

```cfg
frontend fe_guard
  bind :80
  # RPS table
  stick-table type ip size 100k expire 10s store http_req_rate(10s),conn_cur
  http-request track-sc0 src
  acl too_fast  sc_http_req_rate(0) gt 100
  acl too_many  sc_conn_cur(0)      gt 50
  http-request deny if too_fast or too_many

  # common scanners & sensitive paths
  acl bad_paths path_reg -i \.(env|git|svn|bak|old)$
  http-request deny if bad_paths

  # tarpitting user-agents
  acl bad_bot hdr_sub(user-agent) -i curl wget python-requests
  http-request tarpit if bad_bot

  default_backend bk_site

backend bk_site
  server s1 10.0.6.11:80 check
```

---

## 9) Canary/Blue-Green релиз

**EN:** Weighted split; force canary by header.
**RU:** Взвешенное разделение; ручной форс канареечного трафика по заголовку.

```cfg
frontend fe_edge
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  default_backend bk_canary

backend bk_canary
  balance roundrobin
  acl is_canary hdr(X-Canary) -i 1
  use-server canary if is_canary
  server stable 10.0.7.11:8080 check weight 90
  server canary 10.0.7.12:8080 check weight 10
```

---

## 10) PROXY protocol: приём от внешнего LB и проксирование дальше

**EN:** Preserve original client IPs across multiple LBs.
**RU:** Сохранение реального IP клиента через несколько балансировщиков.

```cfg
frontend fe_proxy_in
  bind :443 ssl crt /etc/haproxy/certs/ accept-proxy
  default_backend bk_app

backend bk_app
  server a1 10.0.8.11:8443 send-proxy-v2 check
```

---

## 11) DNS-Discovery (SRV) с server-template

**EN:** Auto-scale backends via DNS SRV without config edits.
**RU:** Автопоиск бэкендов через SRV DNS без правок конфига.

```cfg
resolvers dns
  nameserver ns1 10.0.9.10:53
  resolve_retries 3
  timeout retry 1s
  hold valid 10s

backend bk_discovery
  balance roundrobin
  server-template app 1-10 _http._tcp.app.local resolvers dns init-addr none check
```

---

## 12) БД и кеши: TCP-проверки MySQL/Redis

**EN:** Native mysql-check; Redis TCP health with PING/PONG.
**RU:** Встроенная проверка MySQL; TCP-проверка Redis через PING/PONG.

```cfg
# MySQL
backend bk_mysql
  mode tcp
  option mysql-check user haproxy
  server db1 10.0.10.11:3306 check
  server db2 10.0.10.12:3306 check backup

# Redis
backend bk_redis
  mode tcp
  option tcp-check
  tcp-check connect
  tcp-check send PING\r\n
  tcp-check expect string +PONG
  server r1 10.0.10.21:6379 check
```

---

## 13) SMTP проксирование с TCP-проверкой

**EN:** Simple SMTP proxy with EHLO health check.
**RU:** Прокси SMTP с проверкой приветствия EHLO.

```cfg
defaults
  mode tcp
  option tcplog
  timeout connect 5s
  timeout client  60s
  timeout server  60s

frontend fe_smtp
  bind :25
  default_backend bk_smtp

backend bk_smtp
  option tcp-check
  tcp-check connect
  tcp-check send "EHLO haproxy\r\n"
  tcp-check expect rstring ^250
  server mx1 10.0.11.11:25 check
  server mx2 10.0.11.12:25 check backup
```

---

## 14) Маршрутизация по Host c map-файлом

**EN:** Maintain virtual-host → backend mapping outside config.
**RU:** Отделяем карту домен→бэкенд в файл для удобства.

```
# /etc/haproxy/domains.map
api.example.com bk_api
www.example.com bk_www
```

```cfg
frontend fe_map
  bind :443 ssl crt /etc/haproxy/certs/
  use_backend %[req.hdr(host),lower,map(/etc/haproxy/domains.map,bk_default)]

backend bk_api
  server a1 10.0.12.11:8080 check
backend bk_www
  server w1 10.0.12.21:80  check
backend bk_default
  server d1 10.0.12.99:80  check
```

---

## 15) Заголовки безопасности и маскировка баннера

**EN:** Security headers; hide backend/server details.
**RU:** Безопасные заголовки; скрытие баннеров.

```cfg
frontend fe_sec
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  http-response set-header X-Frame-Options DENY
  http-response set-header X-Content-Type-Options nosniff
  http-response set-header Referrer-Policy strict-origin-when-cross-origin
  http-response set-header Content-Security-Policy "default-src 'self'"
  http-response del-header Server
  default_backend bk_site
```

---

## 16) Runtime-API (stats socket) для живых операций

**EN:** Change weights, drain servers, inspect tables — on the fly.
**RU:** Меняем веса, выводим узлы в drain, смотрим stick-таблицы — на лету.

```cfg
global
  stats socket /run/haproxy.sock mode 660 level admin expose-fd listeners
```

```bash
# Примеры:
echo "disable server bk_web/web2"     | socat - /run/haproxy.sock
echo "set server bk_web/web2 weight 5"| socat - /run/haproxy.sock
echo "show servers state"             | socat - /run/haproxy.sock
echo "show table fe_guard"            | socat - /run/haproxy.sock
```

---

## 17) Zero-downtime reload (master-worker)

**EN:** Validation + smooth reload via systemd or CLI.
**RU:** Проверка и плавный reload через systemd или вручную.

```bash
# Validate
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload (systemd)
systemctl reload haproxy

# Manual with -sf (send FIN to old PIDs)
haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid)
```

---

## 18) Страница статистики (веб)

**EN:** Simple web stats with auth.
**RU:** Веб-страница статистики с авторизацией.

```cfg
listen stats
  bind :8404
  stats enable
  stats uri /stats
  stats refresh 5s
  stats auth admin:StrongPass!
```

---

## 19) Ограничение размера запроса/ответа и времени

**EN:** Protect backends from huge bodies or slow clients.
**RU:** Защита бэкенда от больших тел и “медленных” клиентов.

```cfg
defaults
  mode http
  option httplog
  timeout connect 5s
  timeout client  30s
  timeout server  30s

frontend fe_limits
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  tune.http.maxhdr  101   # EN: header count; RU: макс. число заголовков
  http-request deny if { req.body_size gt 10485760 }   # >10 MB
  default_backend bk_site
```

---

## 20) Безопасный upload: увеличение таймаутов только по пути

**EN:** Longer timeouts for uploads endpoint only.
**RU:** Длинные таймауты только для пути загрузки.

```cfg
frontend fe_upload
  bind :443 ssl crt /etc/haproxy/certs/
  acl is_upload path_beg /upload
  default_backend bk_www
  use_backend bk_upload if is_upload

backend bk_www
  timeout server  60s
  server w1 10.0.13.11:80 check

backend bk_upload
  timeout server  300s
  http-request set-header X-Upload-Path 1
  server u1 10.0.13.21:8080 check
```

---

````markdown
# 🌀 HAProxy — от минимума к продакшену (EN/RU)

аха, комбайн тот ещё 🙂  
но им удобно пользоваться, если держать в голове простую модель:  
**EN:** input → rules → output  
**RU:** вход → правила → выход  

ниже — короткий «пульт управления» — от простого реверс-прокси до production-шаблона.

---

## 1) 🟢 Minimal reverse-proxy (one backend) / Минимальный реверс-прокси (один бэкенд)

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
  server app1 127.0.0.1:8080 check
````

**EN:** one `frontend` listens on a port, one `backend` defines servers.
**RU:** один `frontend` слушает порт, один `backend` — список серверов.

---

## 2) 🔒 Basic production template (HTTPS, redirect, security, stats)

**EN:** Ready for production with HTTPS and stats.
**RU:** Базовый шаблон для продакшена с HTTPS и статистикой.

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
  server app1 127.0.0.1:8080 check

# Stats page
listen stats
  bind :8404
  mode http
  stats enable
  stats uri /stats
  stats refresh 5s
  stats auth admin:StrongPass!
```

---

## 3) 🌐 Multiple hosts (map file) / Несколько хостов (map-файл)

**`/etc/haproxy/domains.map`:**

```
docway4-sviatoslav.bo.priv bk_docway4
www.docway4-sviatoslav.bo.priv bk_docway4
api.example.com bk_api
example.com bk_site
```

**Config:**

```cfg
frontend fe_https
  bind :443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
  use_backend %[req.hdr(host),lower,map(/etc/haproxy/domains.map,bk_default)]

backend bk_docway4
  server tomcat1 127.0.0.1:8080 check

backend bk_api
  server api1 10.0.1.11:8080 check
  server api2 10.0.1.12:8080 check

backend bk_site
  server w1 10.0.0.21:80 check
  server w2 10.0.0.22:80 check

backend bk_default
  http-request return status 404 content-type "text/plain" string "Unknown host"
```

**EN:** add a new domain = one line in map.
**RU:** добавление домена = одна строка в map, без правки конфига.

---

## 4) 📌 Sticky sessions for Tomcat (JSESSIONID)

**EN:** Sticky sessions based on JSESSIONID (Tomcat cluster).
**RU:** Липкие сессии по JSESSIONID (кластер Tomcat).

```cfg
backend bk_tomcat
  balance leastconn
  cookie SRV insert indirect nocache secure httponly
  server node1 10.0.0.11:8080 check cookie node1
  server node2 10.0.0.12:8080 check cookie node2
```

> **EN:** in Tomcat set `jvmRoute="node1"` / `"node2"` in `server.xml`.
> **RU:** в Tomcat укажи `jvmRoute="node1"` / `"node2"` в `server.xml`.

---

## 5) 🧭 Mental map (where to configure what) / Ментальная карта (что где настраивать)

* **global** — process & OS: logs, master-worker, runtime socket / процесс и ОС: логи, master-worker, рантайм-сокет
* **defaults** — timeouts, log format, common options / таймауты, лог-формат, общие опции
* **frontend** — input: `bind`, ACL, redirects, headers, backend choice / «вход»: bind, ACL, редиректы, заголовки, выбор backend
* **backend** — output: balancing, servers, health-checks, cache/compression / «выход»: балансировка, сервера, проверки, кэш/компрессия
* **listen** — combined block (useful for stats) / комбинированный блок (удобно для stats)

---

## 6) 🔟 Top-10 useful tricks / Топ-10 полезных фишек

1. **Config check / Проверка конфига:**
   `haproxy -c -f /etc/haproxy/haproxy.cfg`
2. **Smooth reload / Плавный reload:**
   `systemctl reload haproxy`
3. **Runtime API / Runtime-API:**
   `echo "disable server bk_app/app1" | socat - /run/haproxy.sock`
4. **Rate limit per IP / Лимит на IP:**

   ```cfg
   frontend fe_guard
     stick-table type ip size 100k expire 10s store http_req_rate(10s)
     http-request track-sc0 src
     acl too_fast sc_http_req_rate(0) gt 100
     http-request deny if too_fast
   ```
5. **WebSocket detect / Детект WebSocket:**
   `hdr(Upgrade) -i websocket` → backend
6. **gRPC support / gRPC:**
   `bind :443 ssl ... alpn h2` + `option http-use-htx`
7. **TLS passthrough / Сквозной TLS:**
   `mode tcp` + SNI (`req_ssl_sni`)
8. **Static cache / Кэш статики:**
   `cache` + `cache-use`/`cache-store` for `\.(css|js|png|...)$`
9. **Security headers / Заголовки безопасности:**
   HSTS, X-Frame-Options, nosniff in `http-response set-header`
10. **Stats on loopback / Статистика на loopback:**
    `listen stats` + SSH-tunnel

---

## 7) ⚠️ Common pitfalls / Частые грабли

* **503 on /stats** → add `mode http` inside `listen stats` and open exact path.
  **RU:** 503 на /stats → добавь `mode http` и открывай именно `/stats`.
* **Redirects to 127.0.0.1:8080** → enable `RemoteIpValve` or `proxyName/proxyPort` in Tomcat.
  **RU:** редиректы на 127.0.0.1:8080 → включи `RemoteIpValve` или `proxyName/proxyPort`.
* **Sticky sessions fail** → mismatch between `jvmRoute` and `cookie`.
  **RU:** липкость не работает → не совпадают `jvmRoute` и cookie.
* **Certificates** → put all `.pem` into `/etc/haproxy/certs/` or use `crt-list`.
  **RU:** сертификаты → складывай все `.pem` в `/etc/haproxy/certs/` или используй crt-list.
* **Host header issues** → HAProxy keeps it by default, don’t override unless needed.
  **RU:** проблемы с Host → HAProxy сохраняет Host по умолчанию, не меняй без нужды.



---

## 8) HAProxy Configuration Templates



This document contains practical, production-oriented HAProxy configuration templates
for different real-world scenarios.  
All examples assume **HAProxy >= 2.4** on Linux.

---

## 1. Basic HTTP Load Balancer (Round-Robin)

```haproxy
global
    log /dev/log local0
    maxconn 4096
    daemon

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server web1 10.0.0.11:80 check
    server web2 10.0.0.12:80 check
```

---

## 2. HTTP → HTTPS Redirect + TLS Termination

```haproxy
frontend http_front
    bind *:80
    redirect scheme https if !{ ssl_fc }

frontend https_front
    bind *:443 ssl crt /etc/ssl/haproxy/site.pem
    default_backend app_back

backend app_back
    balance leastconn
    server app1 10.0.0.21:8080 check
    server app2 10.0.0.22:8080 check
```

---

## 3. Path-Based Routing

```haproxy
frontend https_front
    bind *:443 ssl crt /etc/ssl/haproxy/site.pem

    acl is_api   path_beg /api
    acl is_admin path_beg /admin

    use_backend api_back   if is_api
    use_backend admin_back if is_admin
    default_backend web_back

backend web_back
    server web1 10.0.0.10:80 check

backend api_back
    server api1 10.0.0.20:8080 check

backend admin_back
    server admin1 10.0.0.30:8080 check
```

---

## 4. TCP Load Balancer (Databases, Redis, MQTT)

```haproxy
defaults
    mode tcp
    timeout connect 5s
    timeout client  1m
    timeout server  1m

frontend redis_front
    bind *:6379
    default_backend redis_back

backend redis_back
    balance source
    server redis1 10.0.0.41:6379 check
    server redis2 10.0.0.42:6379 check
```

---

## 5. Sticky Sessions (Cookies)

```haproxy
backend app_back
    balance roundrobin
    cookie SERVERID insert indirect nocache

    server app1 10.0.0.11:80 check cookie app1
    server app2 10.0.0.12:80 check cookie app2
```

---

## 6. Restricted / Internal Admin Frontend

```haproxy
frontend admin_front
    bind 10.0.0.1:8443 ssl crt /etc/ssl/haproxy/admin.pem

    acl allowed_net src 10.0.0.0/24
    http-request deny if !allowed_net

    default_backend admin_back

backend admin_back
    server admin1 10.0.0.30:8080 check
```

---

## 7. Rate Limiting (Basic Anti-DDoS)

```haproxy
frontend https_front
    bind *:443 ssl crt /etc/ssl/haproxy/site.pem

    stick-table type ip size 1m expire 10s store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny if { sc_http_req_rate(0) gt 50 }

    default_backend app_back
```

---

## 8. Canary / Blue-Green Deployment

```haproxy
backend app_back
    balance roundrobin
    server stable1 10.0.0.11:80 check weight 90
    server canary1 10.0.0.12:80 check weight 10
```

---

## 9. Multiple Frontends, One Backend

```haproxy
frontend public_http
    bind *:80
    default_backend app_back

frontend internal_http
    bind 10.0.0.1:8080
    default_backend app_back
```

---

## 10. Production Skeleton with Stats

```haproxy
global
    log /dev/log local0
    maxconn 10000
    stats socket /run/haproxy/admin.sock mode 660 level admin
    daemon

defaults
    log global
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats auth admin:strongpassword
```

---

**Author:** Generated by ChatGPT  
**Use case:** Learning, labs, and production baselines


---

```
```



