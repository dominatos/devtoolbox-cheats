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

```bash
/etc/haproxy/haproxy.cfg                                # Main config / Основной конфиг
/run/haproxy.sock                                       # Runtime socket / Рантайм сокет
/run/haproxy.pid                                        # PID file / Файл PID
/var/log/haproxy.log                                    # Log file / Лог файл
/etc/haproxy/certs/                                     # SSL certificates / SSL сертификаты
```

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

```cfg
backend bk_pool
  balance roundrobin    # Round-robin / По кругу
  # balance leastconn   # Least connections / Меньше всего соединений
  # balance source      # Hash by client IP / Хеш по IP клиента
  # balance uri         # Hash by URI / Хеш по URI
  # balance url_param(<param>)  # Hash by URL param / Хеш по параметру URL
```

**Algorithms / Алгоритмы:**
* `roundrobin` → Round-robin / По кругу
* `leastconn` → Least connections / Меньше всего соединений
* `source` → Hash by client IP / Хеш по IP клиента
* `uri` → Hash by URI / Хеш по URI
* `url_param(<param>)` → Hash by URL param / Хеш по параметру URL

---

## ACL & Routing

Access Control Lists for traffic routing / ACL для маршрутизации трафика

```cfg
frontend fe_main
  bind *:443 ssl crt /etc/haproxy/certs/
  
  # Define ACLs / Определить ACL
  acl is_api   path_beg /api                           # Match path / Совпадение по пути
  acl is_admin path_beg /admin                         # Match /admin
  acl bad_bot hdr_sub(user-agent) -i curl wget python  # Match user-agent
  
  # Use backend / Использовать backend
  use_backend bk_api if is_api                         # Route to API / Перенаправление на API
  use_backend bk_admin if is_admin                     # Route to Admin
  
  # Block bad bots / Блокировка ботов
  http-request deny if bad_bot
  
  default_backend bk_www
```

**Common ACL Criteria / Общие критерии ACL:**
- `path_beg /api` — Path starts with / Путь начинается с
- `path_end .jpg` — Path ends with / Путь заканчивается на
- `hdr(host)` — Header value / Значение заголовка
- `src <IP>` — Source IP / IP источника
- `ssl_fc` — SSL/TLS connection / SSL/TLS соединение

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

### Passive Health Checks / Пассивные health checks

```cfg
backend bk_pool
  server web1 <IP1>:80 check max_fails=3 fail_timeout=30s  # Mark down after failures
  server web2 <IP2>:80 check max_fails=3 fail_timeout=30s
```

**Parameters:**
- `max_fails` — Failures before disable / Ошибок до исключения
- `fail_timeout` — Retry time / Время восстановления

### HTTP Health Check / HTTP проверка

```cfg
backend bk_app
  option httpchk GET /healthz                           # Health check endpoint
  http-check expect status 200                          # Expected status / Ожидаемый статус
  server app1 <IP1>:8080 check
  server app2 <IP2>:8080 check
```

### TCP Health Check / TCP проверка

```cfg
# MySQL
backend bk_mysql
  mode tcp
  option mysql-check user haproxy
  server db1 <IP1>:3306 check
  server db2 <IP2>:3306 check backup

# Redis
backend bk_redis
  mode tcp
  option tcp-check
  tcp-check connect
  tcp-check send PING\r\n
  tcp-check expect string +PONG
  server r1 <IP1>:6379 check
```

---

## Stick Tables & Rate Limiting

Stick tables for rate-limiting and tracking / Stick-таблицы для ограничения частоты

```cfg
frontend fe_guard
  bind *:80
  
  # Create stick-table / Создать stick-таблицу
  stick-table type ip size 100k expire 10s store http_req_rate(10s)
  
  # Track client IP / Отслеживание по IP
  http-request track-sc0 src
  
  # Rate limit / Ограничение частоты
  acl too_fast sc_http_req_rate(0) gt 100              # If >100 RPS / Если >100 запросов
  http-request deny if too_fast                        # Deny request / Запретить
  
  default_backend bk_site
```

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
  max-age 600                                           # Default TTL / Время жизни по умолчанию

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

### Runtime API / Runtime-API

```cfg
global
  stats socket /run/haproxy.sock mode 660 level admin expose-fd listeners
```

### Runtime Commands / Команды Runtime

```bash
# Disable server / Отключить сервер
echo "disable server bk_web/web2" | socat - /run/haproxy.sock

# Enable server / Включить сервер
echo "enable server bk_web/web2" | socat - /run/haproxy.sock

# Set server weight / Установить вес сервера
echo "set server bk_web/web2 weight 5" | socat - /run/haproxy.sock

# Show server state / Показать состояние серверов
echo "show servers state" | socat - /run/haproxy.sock

# Show stick-table / Показать stick-таблицу
echo "show table fe_guard" | socat - /run/haproxy.sock

# Show stats / Показать статистику
echo "show stat" | socat - /run/haproxy.sock
```

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
