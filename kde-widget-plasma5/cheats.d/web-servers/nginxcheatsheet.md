Title: 🌐 Nginx — Cheatsheet
Group: Web Servers
Icon: 🌐
Order: 1

# 🌐 Nginx — Cheatsheet

## Table of Contents

- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Basic Reverse Proxy](#basic-reverse-proxy)
- [Load Balancing](#load-balancing)
- [HTTPS & SSL/TLS](#https--ssltls)
- [WebSocket & Special Protocols](#websocket--special-protocols)
- [Static Files & Optimization](#static-files--optimization)
- [Security & Access Control](#security--access-control)
- [Caching & Performance](#caching--performance)
- [Advanced Features](#advanced-features)
- [Production Configuration](#production-configuration)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install nginx                # Install Nginx / Установить Nginx

# RHEL/CentOS/AlmaLinux
sudo dnf install nginx                                   # Install Nginx / Установить Nginx
sudo systemctl enable nginx                              # Enable at boot / Автозапуск
```

### Default Paths / Пути по умолчанию

```bash
/etc/nginx/nginx.conf                                    # Main config / Основной конфиг
/etc/nginx/sites-available/                              # Available sites (Debian/Ubuntu)
/etc/nginx/sites-enabled/                                # Enabled sites (Debian/Ubuntu)
/etc/nginx/conf.d/                                       # Additional configs (RHEL/CentOS)
/var/log/nginx/                                          # Logs directory / Директория логов
/usr/share/nginx/html/                                   # Default document root / Корень по умолчанию
/var/www/html/                                           # Alternative root / Альтернативный корень
```

### Default Ports / Порты по умолчанию

- **80** — HTTP
- **443** — HTTPS

---

## Core Management

### Service Control / Управление

```bash
sudo systemctl start nginx                               # Start service / Запустить сервис
sudo systemctl stop nginx                                # Stop service / Остановить сервис
sudo systemctl restart nginx                             # Restart service / Перезапустить сервис
sudo systemctl reload nginx                              # Reload no downtime / Перечитать без простоя
sudo systemctl status nginx                              # Service status / Статус сервиса
sudo systemctl enable nginx                              # Enable at boot / Автозапуск
```

### Configuration Testing / Проверка конфигурации

```bash
sudo nginx -t                                            # Test config / Проверить конфиг
sudo nginx -T                                            # Test and dump config / Проверить и показать конфиг
sudo nginx -s reload                                     # Reload signal / Сигнал перезагрузки
```

### Logs / Логи

```bash
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log  # Tail logs / Хвост логов
sudo tail -f /var/log/nginx/access.log                  # Access log / Лог доступа
sudo tail -f /var/log/nginx/error.log                   # Error log / Лог ошибок
```

---

## Basic Reverse Proxy

### 1️⃣ Basic Reverse Proxy vhost / Базовый reverse proxy

```nginx
server {
  listen 80;                                             # Listen :80 / Слушать :80
  server_name <HOST>;                                    # Server name / Имя хоста

  location / {
    proxy_pass http://<IP>:3000;                         # Backend / Backend-сервис
    proxy_set_header Host $host;                         # Preserve Host / Оставить Host
    proxy_set_header X-Real-IP $remote_addr;             # Client IP / IP клиента
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;  # Forwarded chain / Цепочка IP
    proxy_set_header X-Forwarded-Proto $scheme;          # HTTP/HTTPS
  }

  access_log /var/log/nginx/app_access.log;              # Access log / Логи доступа
  error_log  /var/log/nginx/app_error.log;               # Error log / Логи ошибок
}
```

---

## Load Balancing

### 2️⃣ Load Balancer (Round Robin) / Балансировщик (Round Robin)

```nginx
upstream backend_pool {
  server <IP1>:8080;                                     # Backend 1
  server <IP2>:8080;                                     # Backend 2
  server <IP3>:8080;                                     # Backend 3
}

server {
  listen 80;
  server_name <HOST>;

  location / {
    proxy_pass http://backend_pool;                      # Load balancing
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;
  }
}
```
**Default algorithm:** round-robin / алгоритм по умолчанию

---

### 3️⃣ Load Balancer with Least Connections / Минимум соединений

```nginx
upstream backend_pool {
  least_conn;                                            # Least connections / Меньше всего соединений
  server <IP1>:8080;
  server <IP2>:8080;
}
```

---

### 4️⃣ Sticky Sessions (IP Hash) / Привязка по IP

```nginx
upstream backend_pool {
  ip_hash;                                               # Same client → same backend
  server <IP1>:8080;
  server <IP2>:8080;
}
```
⚠️ Not suitable behind NAT / Плохо работает за NAT

---

### 5️⃣ Passive Health Checks / Пассивные health checks

```nginx
upstream backend_pool {
  server <IP1>:8080 max_fails=3 fail_timeout=30s;        # Mark down after failures
  server <IP2>:8080 max_fails=3 fail_timeout=30s;
}
```
- **max_fails** – failures before disable / ошибок до исключения
- **fail_timeout** – retry time / время восстановления

---

### 6️⃣ Active Health Checks (NGINX Plus only)

❌ **Not available in OSS** / Нет в open-source версии

---

## HTTPS & SSL/TLS

### 7️⃣ HTTPS + SSL (Let's Encrypt) / HTTPS

```nginx
server {
  listen 443 ssl http2;                                  # HTTPS + HTTP/2
  server_name <HOST>;

  ssl_certificate     /etc/letsencrypt/live/<HOST>/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/<HOST>/privkey.pem;

  ssl_protocols TLSv1.2 TLSv1.3;                         # Secure protocols
  ssl_ciphers HIGH:!aNULL:!MD5;

  location / {
    proxy_pass http://<IP>:3000;
  }
}
```

---

### 8️⃣ HTTP → HTTPS Redirect / Редирект на HTTPS

```nginx
server {
  listen 80;
  server_name <HOST>;
  return 301 https://$host$request_uri;                  # Permanent redirect
}
```

---

## WebSocket & Special Protocols

### 9️⃣ WebSocket Proxy / WebSocket прокси

```nginx
location /ws/ {
  proxy_pass http://<IP>:3000;
  proxy_http_version 1.1;                                # Required for WS
  proxy_set_header Upgrade $http_upgrade;                # Upgrade header
  proxy_set_header Connection "upgrade";
}
```

---

## Static Files & Optimization

### 🔟 Static Files / Статические файлы

```nginx
server {
  listen 80;
  server_name <HOST>;

  root /var/www/html;                                    # Document root
  index index.html;

  location / {
    try_files $uri $uri/ =404;                           # Return 404 if missing
  }
}
```

---

### 1️⃣1️⃣ Gzip Compression / Сжатие

```nginx
gzip on;                                                 # Enable gzip
gzip_types text/plain text/css application/json application/javascript;
gzip_min_length 1024;                                    # Min size
```

---

### 1️⃣2️⃣ Rate Limiting / Ограничение запросов

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;  # Define zone

server {
  location /api/ {
    limit_req zone=api burst=20 nodelay;                 # Apply limit
  }
}
```
- Protects from abuse / Защита от DDoS

---

## Security & Access Control

### 1️⃣3️⃣ Basic Auth / Базовая авторизация

```nginx
location /admin/ {
  auth_basic "Restricted";                               # Auth prompt
  auth_basic_user_file /etc/nginx/.htpasswd;             # Password file
}
```

---

### 1️⃣6️⃣ Security Headers / Заголовки безопасности

```nginx
add_header X-Frame-Options DENY;                         # Clickjacking protection
add_header X-Content-Type-Options nosniff;               # MIME sniffing
add_header Referrer-Policy no-referrer;                  # Referrer policy
```

---

### 1️⃣7️⃣ Deny by IP / Блокировка IP

```nginx
deny <IP>;                                               # Block IP
allow all;
```

---

### 1️⃣8️⃣ Maintenance Mode / Режим обслуживания

```nginx
if (-f /var/www/maintenance.flag) {
  return 503;                                            # Service unavailable
}

error_page 503 @maintenance;

location @maintenance {
  root /var/www;
  rewrite ^ /maintenance.html break;
}
```

---

## Caching & Performance

### 1️⃣4️⃣ Caching Proxy / Кеширование

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m inactive=60m;

location / {
  proxy_cache mycache;                                   # Enable cache
  proxy_cache_valid 200 302 10m;                         # Cache duration
  proxy_cache_valid 404 1m;
}
```

---

### 1️⃣5️⃣ PHP-FPM / PHP обработка

```nginx
location ~ \.php$ {
  include fastcgi_params;
  fastcgi_pass unix:/run/php/php8.2-fpm.sock;            # PHP socket
  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

---

### 1️⃣9️⃣ Logs per vhost / Логи на виртуальный хост

```nginx
access_log /var/log/nginx/site_access.log combined;
error_log  /var/log/nginx/site_error.log warn;
```

---

### 2️⃣0️⃣ Enable site (Debian/Ubuntu)

```bash
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## Advanced Features

### 2️⃣1️⃣ Real IP / Correct Client IP (behind LB / Proxy)

```nginx
set_real_ip_from <IP>/8;                                 # Trusted proxy subnet
set_real_ip_from <IP>/16;
real_ip_header X-Forwarded-For;                          # Header with real IP
real_ip_recursive on;                                    # Take last trusted IP
```
- Required behind LB / Нужно за балансировщиком

---

### 2️⃣2️⃣ geo / Country-based rules

```nginx
geo $allowed_country {
  default 0;                                             # Deny by default
  IT 1;                                                  # Allow Italy
  DE 1;                                                  # Allow Germany
}

server {
  if ($allowed_country = 0) {
    return 403;                                          # Forbidden
  }
}
```

---

### 2️⃣3️⃣ map (preferred over if) / map вместо if

```nginx
map $http_user_agent $is_bot {
  default 0;
  ~*(googlebot|bingbot|yandex) 1;                        # Detect bots
}

server {
  if ($is_bot) {
    set $rate_limit "bot";
  }
}
```

---

### 2️⃣4️⃣ Upstream Backup Server / Резервный backend

```nginx
upstream backend_pool {
  server <IP1>:8080;
  server <IP2>:8080;
  server <IP3>:8080 backup;                              # Used only if others fail
}
```

---

### 2️⃣5️⃣ slow_start / Плавное включение backend

```nginx
upstream backend_pool {
  server <IP1>:8080 slow_start=30s;                      # Gradual ramp-up
  server <IP2>:8080;
}
```
- Prevents traffic spike after restart / Защита после рестарта

---

### 2️⃣6️⃣ mirror (Traffic Shadowing) / Зеркалирование трафика

```nginx
location / {
  mirror /mirror;                                        # Send copy
  mirror_request_body on;
  proxy_pass http://prod_backend;
}

location /mirror {
  internal;
  proxy_pass http://test_backend;                        # Shadow backend
}
```
- Used for testing / Для тестирования

---

### 2️⃣7️⃣ sub_filter (Response rewrite) / Переписывание ответа

```nginx
sub_filter 'http://<OLD_HOST>' 'https://<NEW_HOST>';
sub_filter_once off;                                     # Replace all
```
- Useful for migrations / Для миграций

---

## Production Configuration

### 2️⃣8️⃣ High-load upstream (Production-ready)

```nginx
upstream backend_pool {
  least_conn;                                            # Efficient balancing
  keepalive 64;                                          # Keep connections

  server <IP1>:8080 max_fails=2 fail_timeout=10s slow_start=20s;
  server <IP2>:8080 max_fails=2 fail_timeout=10s slow_start=20s;
  server <IP3>:8080 backup;
}
```

---

### 2️⃣9️⃣ High-load Reverse Proxy (PROD TEMPLATE)

```nginx
server {
  listen 80 reuseport backlog=8192;                      # High concurrency
  server_name <HOST>;

  access_log /var/log/nginx/prod_access.log main;
  error_log  /var/log/nginx/prod_error.log warn;

  client_max_body_size 20m;                              # Upload limit

  proxy_connect_timeout 3s;                              # Fast fail
  proxy_send_timeout 30s;
  proxy_read_timeout 30s;

  location / {
    proxy_http_version 1.1;
    proxy_set_header Connection "";                      # Keepalive
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_pass http://backend_pool;
  }
}
```

---

### 3️⃣0️⃣ Kernel & Worker Tuning (High-load)

```nginx
worker_processes auto;                                   # One per CPU
worker_connections 65535;                                # Max connections
worker_rlimit_nofile 200000;                             # File descriptors
```

---

### 3️⃣1️⃣ Epoll & Sendfile Optimization

```nginx
events {
  use epoll;                                             # Linux only
  multi_accept on;
}

sendfile on;
tcp_nopush on;
tcp_nodelay on;
```

---

### 3️⃣2️⃣ Production Cache Strategy

```nginx
proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
proxy_cache_background_update on;                        # No cache stampede
```

---

### 3️⃣3️⃣ DDoS / Abuse Protection (PROD)

```nginx
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

server {
  limit_conn conn_limit 20;                              # Max connections per IP
}
```

---

### 3️⃣4️⃣ Disable Server Tokens / Hide version

```nginx
server_tokens off;                                       # Hide nginx version
```

---

### 3️⃣5️⃣ Full Production Checklist

- real_ip configured / real_ip настроен
- rate limit enabled / rate limit включён
- keepalive upstream / keepalive backend
- cache with stale / кеш со stale
- slow_start on backends / плавный старт
- backup backend / резервный backend
- monitoring ready / мониторинг готов

---

## Tips / Советы

- Prefer `map` over `if` / Используй `map`, а не `if`
- Always run `nginx -t` / Всегда проверяй конфиг
- Separate upstreams / Разделяй upstream-и
- Log slow backends / Логируй медленные бэкенды

---