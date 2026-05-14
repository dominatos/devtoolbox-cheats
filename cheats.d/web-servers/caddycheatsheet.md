Title: 🔒 Caddy — Cheatsheet
Group: Web Servers
Icon: 🔒
Order: 2

# 🔒 Caddy — Web Server Cheatsheet

## Description

**Caddy** is a modern, open-source web server written in Go, known for **automatic HTTPS** via Let's Encrypt and ZeroSSL. Created by Matt Holt in 2015, Caddy provisions and renews TLS certificates by default with zero configuration, making it the simplest production-ready web server for HTTPS deployments.

**Common use cases / Типичные сценарии:**
- Automatic HTTPS reverse proxy / Автоматический HTTPS обратный прокси
- Static file serving with zero-config TLS / Раздача статики с автоматическим TLS
- Load balancing (HTTP, TCP) / Балансировка нагрузки
- API gateway / API-шлюз
- Local development server (self-signed certs) / Локальный сервер разработки
- File server with directory browsing / Файловый сервер с просмотром каталогов

> [!NOTE]
> Caddy is gaining rapid adoption due to its automatic HTTPS and simple configuration (`Caddyfile`). It supports both a human-readable `Caddyfile` syntax and a JSON-based configuration API. Caddy v2 (current) is a complete rewrite of v1. Alternatives include **Nginx** (most widely deployed, manual cert management), **HAProxy** (high-performance L4/L7 LB), and **Traefik** (auto-discovery, cloud-native).
> Caddy быстро набирает популярность благодаря автоматическому HTTPS и простой конфигурации. Поддерживает `Caddyfile` и JSON API. Caddy v2 — полная переработка v1. Альтернативы: **Nginx**, **HAProxy**, **Traefik**.

---

## Table of Contents

- [Description](#description)
- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Caddyfile Basics](#caddyfile-basics)
- [Reverse Proxy](#reverse-proxy)
- [Load Balancing](#load-balancing)
- [HTTPS & TLS](#https--tls)
- [Static Files & File Server](#static-files--file-server)
- [Security & Access Control](#security--access-control)
- [Logging & Monitoring](#logging--monitoring)
- [Advanced Features](#advanced-features)
- [Production Configuration](#production-configuration)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Comparison Tables](#comparison-tables)
- [Logrotate Configuration](#logrotate-configuration)
- [Documentation Links](#documentation-links)

---

## Installation & Configuration

### Package Installation / Установка пакетов

#### Debian / Ubuntu (Official Repo)
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl  # Prerequisites / Зависимости
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg  # Add GPG key / Добавить GPG ключ
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list  # Add repo / Добавить репозиторий
sudo apt update && sudo apt install caddy  # Install Caddy / Установить Caddy
```

#### RHEL / CentOS / Fedora
```bash
dnf install -y 'dnf-command(copr)'                       # Install copr plugin / Установить плагин copr
dnf copr enable @caddy/caddy                              # Enable Caddy repo / Включить репозиторий
dnf install caddy                                         # Install Caddy / Установить Caddy
```

#### Arch Linux
```bash
sudo pacman -S caddy                                      # Install from community / Установить из community
```

#### Binary / Go Install (Any OS)
```bash
# Download static binary / Скачать статический бинарник
curl -o /usr/local/bin/caddy "https://caddyserver.com/api/download?os=linux&arch=amd64"
chmod +x /usr/local/bin/caddy                             # Make executable / Сделать исполняемым

# Or install via Go / Или установить через Go
go install github.com/caddyserver/caddy/v2/cmd/caddy@latest
```

#### Docker
```bash
docker run -d --name caddy \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -v caddy_data:/data \
  -v caddy_config:/config \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  caddy:latest                                            # Run Caddy in Docker / Запуск в Docker
```

### Default Paths / Пути по умолчанию

**Main config / Основной конфиг:**
`/etc/caddy/Caddyfile`

**Data directory (certs, etc.) / Каталог данных (сертификаты и др.):**
`/var/lib/caddy/.local/share/caddy/` (systemd)
`~/.local/share/caddy/` (manual run)

**Config directory / Каталог конфигурации:**
`/var/lib/caddy/.config/caddy/` (systemd)
`~/.config/caddy/` (manual run)

**Logs directory / Директория логов:**
`/var/log/caddy/` (if configured)

**Binary location / Расположение бинарника:**
`/usr/bin/caddy`

### Default Ports / Порты по умолчанию

| Port | Protocol | Description (EN / RU) |
| :--- | :--- | :--- |
| 80 | HTTP | HTTP (auto-redirect to HTTPS) / HTTP (автоматический редирект на HTTPS) |
| 443 | HTTPS | HTTPS with auto TLS / HTTPS с автоматическим TLS |
| 443 | UDP | HTTP/3 (QUIC) / HTTP/3 (QUIC) |
| 2019 | HTTP | Admin API endpoint / Админ API |

> [!TIP]
> Caddy listens on port **2019** for the admin API by default. This is accessible only from localhost. You can use it to manage configuration dynamically without restarts.
> Caddy по умолчанию слушает порт **2019** для admin API. Доступен только с localhost. Через него можно управлять конфигурацией без перезапуска.

---

## Core Management

### Service Control / Управление сервисом

```bash
sudo systemctl start caddy                               # Start service / Запустить сервис
sudo systemctl stop caddy                                 # Stop service / Остановить сервис
sudo systemctl restart caddy                              # Restart service / Перезапустить сервис
sudo systemctl reload caddy                               # Reload config (graceful) / Перечитать конфиг (без простоя)
sudo systemctl status caddy                               # Service status / Статус сервиса
sudo systemctl enable caddy                               # Enable at boot / Автозапуск
```

### CLI Commands / Команды CLI

```bash
caddy version                                             # Show version / Показать версию
caddy list-modules                                        # List loaded modules / Список модулей
caddy environ                                             # Show environment / Показать окружение
caddy build-info                                          # Build info / Информация о сборке
```

### Configuration Management / Управление конфигурацией

```bash
caddy validate --config /etc/caddy/Caddyfile              # Validate Caddyfile / Проверить конфиг
caddy adapt --config /etc/caddy/Caddyfile                 # Convert Caddyfile to JSON / Конвертировать в JSON
caddy fmt --overwrite /etc/caddy/Caddyfile                # Format Caddyfile / Отформатировать конфиг
caddy reload --config /etc/caddy/Caddyfile                # Live reload / Перезагрузить конфиг на лету
```

### Admin API / Админ API

```bash
# Check current config / Проверить текущую конфигурацию
curl localhost:2019/config/ | jq .

# Load new config / Загрузить новую конфигурацию
curl -X POST localhost:2019/load \
  -H "Content-Type: application/json" \
  -d @caddy.json

# Stop Caddy via API / Остановить Caddy через API
curl -X POST localhost:2019/stop
```

### Run Without systemd / Запуск без systemd

```bash
caddy run --config /etc/caddy/Caddyfile                   # Run in foreground / Запуск на переднем плане
caddy start --config /etc/caddy/Caddyfile                 # Run as daemon / Запуск как демон
caddy stop                                                # Stop daemon / Остановить демон
```

---

## Caddyfile Basics

### Caddyfile Structure / Структура Caddyfile

Caddy's native config format uses a simple, human-readable syntax.
Нативный формат конфигурации Caddy — простой, человекочитаемый синтаксис.

```caddyfile
# Global options / Глобальные настройки
{
    email admin@example.com                               # ACME account email / Email для ACME
    admin off                                             # Disable admin API / Отключить admin API
}

# Site block / Блок сайта
example.com {
    respond "Hello, World!"                               # Simple response / Простой ответ
}
```

### Key Concepts / Ключевые концепции

| Concept | Description (EN) | Description (RU) |
| :--- | :--- | :--- |
| **Site Address** | Domain name or `:port` before `{` | Домен или `:port` перед `{` |
| **Directives** | Instructions inside a site block | Инструкции внутри блока сайта |
| **Matchers** | Conditions for when directives apply | Условия применения директив |
| **Snippets** | Reusable config blocks with `(name)` | Переиспользуемые блоки `(name)` |
| **Global Options** | Top-level `{}` block | Верхний блок `{}` |
| **Placeholders** | Dynamic values like `{host}`, `{path}` | Динамические значения |

---

## Reverse Proxy

### Basic Reverse Proxy / Базовый обратный прокси

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy localhost:3000                           # Proxy to backend / Проксировать на бэкенд
}
```

> [!TIP]
> With just these 3 lines, Caddy will: obtain and auto-renew a TLS certificate, redirect HTTP→HTTPS, proxy all traffic to port 3000, and set proper `X-Forwarded-For` headers. No additional configuration needed.
> Всего 3 строки, и Caddy: получит и обновит TLS сертификат, перенаправит HTTP→HTTPS, проксирует трафик на порт 3000 и выставит правильные заголовки `X-Forwarded-For`.

### Reverse Proxy with Headers / Обратный прокси с заголовками

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy localhost:3000 {
        header_up Host {upstream_hostport}                 # Preserve upstream host / Сохранить хост upstream
        header_up X-Real-IP {remote_host}                  # Client IP / IP клиента
        header_up X-Forwarded-Proto {scheme}               # HTTP/HTTPS scheme / Схема протокола
    }
}
```

### Multiple Backends / Несколько бэкендов

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy <IP1>:8080 <IP2>:8080 <IP3>:8080        # Multiple upstreams / Несколько upstream
}
```

### Path-Based Routing / Маршрутизация по пути

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy /api/* <IP1>:8080                        # API backend / API бэкенд
    reverse_proxy /ws/*  <IP2>:9000                        # WebSocket backend / WebSocket бэкенд
    reverse_proxy /*     <IP3>:3000                        # Default backend / Бэкенд по умолчанию
}
```

### Host-Based Routing / Маршрутизация по домену

`/etc/caddy/Caddyfile`

```caddyfile
api.example.com {
    reverse_proxy <IP1>:8080                               # API service
}

app.example.com {
    reverse_proxy <IP2>:3000                               # App service
}

admin.example.com {
    reverse_proxy <IP3>:8443                               # Admin panel
}
```

### WebSocket Proxy / WebSocket прокси

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy /ws/* <IP>:9000                          # Auto WebSocket support / Автоподдержка WebSocket
}
```

> [!NOTE]
> Caddy automatically handles WebSocket upgrade headers — no special configuration needed (unlike Nginx).
> Caddy автоматически обрабатывает WebSocket заголовки — никакой дополнительной настройки не требуется (в отличие от Nginx).

---

## Load Balancing

### Load Balancing Algorithms / Алгоритмы балансировки

| Algorithm | Description (EN) | Description (RU) | Use Case |
| :--- | :--- | :--- | :--- |
| **random** | Random selection (default) | Случайный выбор (по умолчанию) | General purpose / Общее назначение |
| **round_robin** | Sequentially distributes requests | Последовательное распределение | Equal capacity servers / Серверы равной мощности |
| **least_conn** | Server with fewest connections | Сервер с наименьшим числом соединений | Long connections / Долгие соединения |
| **first** | First available server | Первый доступный сервер | Active-standby / Актив-резерв |
| **ip_hash** | Hash client IP for persistence | Хеш IP для привязки сессии | Session stickiness / Привязка сессии |
| **uri_hash** | Hash URI for cache optimization | Хеш URI для кэш-оптимизации | Caching / Кэширование |
| **cookie** | Cookie-based persistence | Привязка по cookie | Application sessions / Сессии приложений |
| **header** | Hash specific header value | Хеш по значению заголовка | Custom routing / Пользовательская маршрутизация |

### Load Balancing Configuration / Конфигурация балансировки

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy <IP1>:8080 <IP2>:8080 <IP3>:8080 {
        lb_policy round_robin                              # Round Robin algorithm / Алгоритм Round Robin
    }
}
```

### Least Connections / Минимум соединений

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy <IP1>:8080 <IP2>:8080 {
        lb_policy least_conn                               # Least connections / Минимум соединений
    }
}
```

### Cookie-Based Persistence / Привязка по cookie

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy <IP1>:8080 <IP2>:8080 {
        lb_policy cookie                                   # Cookie-based sticky sessions / Липкие сессии по cookie
    }
}
```

### Health Checks / Проверки здоровья

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    reverse_proxy <IP1>:8080 <IP2>:8080 {
        lb_policy round_robin

        # Active health checks / Активные проверки здоровья
        health_uri /healthz                                # Check endpoint / Эндпоинт проверки
        health_interval 10s                                # Interval / Интервал
        health_timeout 5s                                  # Timeout / Таймаут
        health_status 200                                  # Expected status / Ожидаемый статус

        # Passive health checks / Пассивные проверки здоровья
        fail_duration 30s                                  # Mark down after failures / Пометить недоступным
        max_fails 3                                        # Max failures / Максимум ошибок
        unhealthy_latency 5s                               # Latency threshold / Порог задержки
    }
}
```

> [!NOTE]
> Caddy supports both **active** and **passive** health checks in the open-source edition (unlike Nginx which requires Nginx Plus for active checks).
> Caddy поддерживает и **активные**, и **пассивные** проверки здоровья в open-source версии (в отличие от Nginx, где активные проверки — только в Nginx Plus).

---

## HTTPS & TLS

### Automatic HTTPS (Default) / Автоматический HTTPS

```caddyfile
example.com {
    respond "Secure by default!"                           # HTTPS is automatic / HTTPS автоматический
}
```

> [!IMPORTANT]
> Caddy obtains and renews TLS certificates **automatically** using Let's Encrypt or ZeroSSL. No manual `certbot` commands needed. Requirements: port 80 and 443 accessible, valid DNS pointing to your server.
> Caddy получает и обновляет TLS-сертификаты **автоматически** через Let's Encrypt или ZeroSSL. Никаких ручных команд `certbot`. Требования: порты 80 и 443 доступны, DNS указывает на ваш сервер.

### Custom TLS / Пользовательский TLS

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    tls /path/to/cert.pem /path/to/key.pem                # Custom certificate / Пользовательский сертификат
    reverse_proxy localhost:3000
}
```

### Self-Signed (Local Dev) / Самоподписанный (Локальная разработка)

```caddyfile
localhost {
    tls internal                                           # Self-signed cert / Самоподписанный сертификат
    reverse_proxy localhost:3000
}
```

### ACME Configuration / Конфигурация ACME

`/etc/caddy/Caddyfile`

```caddyfile
{
    email admin@example.com                                # ACME email / Email для ACME
    acme_ca https://acme-v02.api.letsencrypt.org/directory # Let's Encrypt (default) / По умолчанию
    # acme_ca https://acme.zerossl.com/v2/DV90             # ZeroSSL alternative / Альтернатива ZeroSSL
}
```

### DNS Challenge (Wildcard Certs) / DNS Challenge (Wildcard)

`/etc/caddy/Caddyfile`

```caddyfile
*.example.com {
    tls {
        dns cloudflare {env.CF_API_TOKEN}                  # DNS provider plugin / DNS провайдер
    }
    reverse_proxy localhost:3000
}
```

> [!TIP]
> Wildcard certificates require the DNS challenge. You need to install the Caddy DNS provider plugin (e.g., `caddy-dns/cloudflare`) and rebuild Caddy with `xcaddy`.
> Wildcard-сертификаты требуют DNS challenge. Нужно установить плагин DNS провайдера и пересобрать Caddy с `xcaddy`.

### TLS Protocols & Ciphers / TLS протоколы и шифры

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    tls {
        protocols tls1.2 tls1.3                            # Allowed TLS versions / Разрешённые версии TLS
        ciphers TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    }
}
```

### On-Demand TLS / TLS по запросу

`/etc/caddy/Caddyfile`

```caddyfile
{
    on_demand_tls {
        ask http://localhost:5555/check                     # Verify domain before issuing / Проверить домен перед выпуском
    }
}

https:// {
    tls {
        on_demand                                          # Issue cert on first request / Выпуск сертификата по требованию
    }
    reverse_proxy localhost:3000
}
```

> [!WARNING]
> On-demand TLS should always have an `ask` endpoint to prevent abuse. Without it, anyone could trigger certificate issuance for any domain.
> On-demand TLS всегда должен иметь `ask` эндпоинт для предотвращения злоупотреблений. Без него кто угодно может запросить сертификат для любого домена.

---

## Static Files & File Server

### Basic File Server / Базовый файловый сервер

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    root * /var/www/html                                   # Document root / Корневая директория
    file_server                                            # Enable file serving / Включить раздачу файлов
}
```

### File Server with Directory Browsing / Файловый сервер с просмотром каталогов

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    root * /var/www/html
    file_server browse                                     # Directory listing / Листинг каталогов
}
```

### SPA (Single Page Application) / SPA

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    root * /var/www/app
    try_files {path} /index.html                           # SPA fallback / Фолбэк для SPA
    file_server
}
```

### Compression / Сжатие

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    encode gzip zstd                                       # Enable compression / Включить сжатие (gzip + zstd)
    root * /var/www/html
    file_server
}
```

---

## Security & Access Control

### Basic Authentication / Базовая аутентификация

```bash
# Generate password hash / Сгенерировать хеш пароля
caddy hash-password                                        # Interactive prompt / Интерактивный ввод
caddy hash-password --plaintext '<PASSWORD>'               # Direct hash / Прямое хеширование
```

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    basicauth /admin/* {
        <USER> <PASSWORD_HASH>                             # User:Hash / Пользователь:Хеш
    }
    reverse_proxy localhost:3000
}
```

### Security Headers / Заголовки безопасности

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    header {
        X-Frame-Options DENY                               # Clickjacking protection / Защита от clickjacking
        X-Content-Type-Options nosniff                     # MIME sniffing / Сниффинг MIME
        X-XSS-Protection "1; mode=block"                   # XSS protection / Защита от XSS
        Referrer-Policy no-referrer                        # Referrer policy / Политика реферера
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"  # HSTS
        -Server                                            # Hide server header / Скрыть заголовок Server
    }
    reverse_proxy localhost:3000
}
```

### IP Allow/Deny / Разрешение/блокировка по IP

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    @blocked remote_ip 203.0.113.0/24                      # Define blocked IPs / Заблокированные IP
    respond @blocked 403                                   # Return 403 / Вернуть 403

    @allowed remote_ip 10.0.0.0/8 192.168.0.0/16          # Internal only / Только внутренние
    handle @allowed {
        reverse_proxy localhost:3000
    }
    respond 403                                            # Default deny / По умолчанию запрет
}
```

### Rate Limiting / Ограничение запросов

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    rate_limit {
        zone dynamic {
            key {remote_host}                              # Key by client IP / Ключ по IP клиента
            events 100                                     # Max requests / Максимум запросов
            window 1m                                      # Time window / Временное окно
        }
    }
    reverse_proxy localhost:3000
}
```

> [!NOTE]
> Rate limiting requires the `caddy-ratelimit` plugin. Install with `xcaddy build --with github.com/mholt/caddy-ratelimit`.
> Ограничение скорости требует плагин `caddy-ratelimit`. Установка: `xcaddy build --with github.com/mholt/caddy-ratelimit`.

---

## Logging & Monitoring

### Access Logs / Логи доступа

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    log {
        output file /var/log/caddy/access.log {            # Log to file / Логировать в файл
            roll_size 100mb                                # Max file size / Макс. размер файла
            roll_keep 10                                   # Keep N rotated files / Хранить N ротированных файлов
            roll_keep_for 720h                             # Keep for 30 days / Хранить 30 дней
        }
        format json                                        # JSON format / Формат JSON
        level INFO                                         # Log level / Уровень логирования
    }
    reverse_proxy localhost:3000
}
```

### Structured JSON Log Example / Пример структурированного JSON лога

```json
{
  "level": "info",
  "ts": 1609459200.123,
  "logger": "http.log.access",
  "msg": "handled request",
  "request": {
    "remote_ip": "203.0.113.1",
    "method": "GET",
    "uri": "/api/health",
    "host": "example.com"
  },
  "status": 200,
  "duration": 0.001234
}
```

### Global Logging / Глобальное логирование

`/etc/caddy/Caddyfile`

```caddyfile
{
    log {
        output file /var/log/caddy/caddy.log               # Global log / Глобальный лог
        level ERROR                                        # Only errors / Только ошибки
    }
}
```

### Metrics (Prometheus) / Метрики (Prometheus)

`/etc/caddy/Caddyfile`

```caddyfile
{
    servers {
        metrics                                            # Enable Prometheus metrics / Включить метрики Prometheus
    }
}

:2019 {
    metrics /metrics                                       # Expose at /metrics / Доступ по /metrics
}
```

---

## Advanced Features

### Snippets (Reusable Config) / Сниппеты (Переиспользуемые блоки)

`/etc/caddy/Caddyfile`

```caddyfile
# Define snippet / Определение сниппета
(security_headers) {
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Strict-Transport-Security "max-age=31536000"
        -Server
    }
}

# Use snippet / Использование сниппета
example.com {
    import security_headers                                # Import snippet / Импортировать сниппет
    reverse_proxy localhost:3000
}

another.example.com {
    import security_headers                                # Reuse snippet / Переиспользовать сниппет
    reverse_proxy localhost:4000
}
```

### Import Files / Импорт файлов

`/etc/caddy/Caddyfile`

```caddyfile
import /etc/caddy/conf.d/*.caddy                          # Import all configs / Импортировать все конфиги
```

### Environment Variables / Переменные окружения

`/etc/caddy/Caddyfile`

```caddyfile
{$DOMAIN:localhost} {
    reverse_proxy {$BACKEND_HOST:localhost}:{$BACKEND_PORT:3000}  # Env vars with defaults / Переменные с умолчаниями
}
```

```bash
DOMAIN=example.com BACKEND_HOST=10.0.0.1 BACKEND_PORT=8080 caddy run  # Set env vars / Задать переменные
```

### Matchers / Сопоставления

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    @api {
        path /api/*                                        # Path matcher / Сопоставление по пути
        method GET POST                                    # Method matcher / Сопоставление по методу
    }
    reverse_proxy @api <IP>:8080                           # Apply to matched / Применить к совпадениям

    @static {
        path *.css *.js *.png *.jpg *.gif *.svg            # Static files / Статические файлы
    }
    header @static Cache-Control "public, max-age=86400"   # Cache headers / Заголовки кэша

    reverse_proxy localhost:3000                            # Default / По умолчанию
}
```

### Custom Error Pages / Пользовательские страницы ошибок

`/etc/caddy/Caddyfile`

```caddyfile
example.com {
    handle_errors {
        @404 expression `{err.status_code} == 404`
        handle @404 {
            rewrite * /404.html
            file_server
        }
        @5xx expression `{err.status_code} >= 500`
        handle @5xx {
            respond "Server Error" 500
        }
    }
    reverse_proxy localhost:3000
}
```

### Redirect / Редирект

`/etc/caddy/Caddyfile`

```caddyfile
www.example.com {
    redir https://example.com{uri} permanent               # WWW → non-WWW redirect / Редирект www → без www
}

example.com {
    redir /old-page /new-page 301                          # Path redirect / Редирект пути
    reverse_proxy localhost:3000
}
```

### Custom Caddy Builds with xcaddy / Сборка с плагинами через xcaddy

```bash
# Install xcaddy / Установить xcaddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build with plugins / Собрать с плагинами
xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/mholt/caddy-ratelimit \
  --with github.com/caddyserver/transform-encoder

# Replace system binary / Заменить системный бинарник
sudo mv caddy /usr/bin/caddy
sudo systemctl restart caddy
```

---

## Production Configuration

### Production-Ready Template / Шаблон для продакшена

`/etc/caddy/Caddyfile`

```caddyfile
{
    email admin@example.com                                # ACME notifications / Уведомления ACME
    admin off                                              # Disable admin API / Отключить admin API в проде
    log {
        output file /var/log/caddy/caddy.log {
            roll_size 100mb
            roll_keep 5
        }
        level ERROR
    }
}

# Reusable snippet / Переиспользуемый сниппет
(common) {
    encode gzip zstd
    header {
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        -Server
    }
    log {
        output file /var/log/caddy/{args[0]}_access.log {
            roll_size 100mb
            roll_keep 10
            roll_keep_for 720h
        }
        format json
    }
}

example.com {
    import common example.com

    reverse_proxy <IP1>:8080 <IP2>:8080 {
        lb_policy least_conn
        health_uri /healthz
        health_interval 10s
        health_timeout 5s
        fail_duration 30s
        max_fails 3
    }
}
```

### Production Checklist / Чеклист для продакшена

- [ ] `admin off` in production / `admin off` в продакшене
- [ ] ACME email configured / Настроен email для ACME
- [ ] TLS protocols restricted to 1.2+ / TLS протоколы ограничены до 1.2+
- [ ] Security headers set / Заголовки безопасности установлены
- [ ] Access logs configured / Логи доступа настроены
- [ ] Health checks enabled / Проверки здоровья включены
- [ ] Compression enabled / Сжатие включено
- [ ] Logrotate configured / Logrotate настроен
- [ ] Firewall rules for 80/443 only / Правила firewall только для 80/443
- [ ] Monitoring/metrics enabled / Мониторинг/метрики включены

### Systemd Override / Переопределение systemd

`/etc/systemd/system/caddy.service.d/override.conf`

```ini
[Service]
LimitNOFILE=65535                                         # Increase file descriptors / Увеличить число файловых дескрипторов
Environment=DOMAIN=example.com                            # Set environment / Задать переменные окружения
```

```bash
sudo systemctl daemon-reload && sudo systemctl restart caddy  # Apply override / Применить переопределение
```

---

## Troubleshooting & Tools

### Common Issues / Типичные проблемы

```bash
# Certificate not issuing / Сертификат не выдаётся
# 1. Check DNS A/AAAA record points to your server / Проверить DNS запись
dig +short example.com

# 2. Check ports 80 and 443 are open / Проверить что порты 80 и 443 открыты
sudo ss -tlnp | grep -E ':80|:443'

# 3. Check Caddy logs for ACME errors / Проверить логи на ACME ошибки
sudo journalctl -u caddy --no-pager --since "1 hour ago" | grep -i "acme\|tls\|certificate"

# Permission issues / Проблемы с правами
sudo chown -R caddy:caddy /var/lib/caddy                  # Fix ownership / Исправить владельца
sudo chown -R caddy:caddy /var/log/caddy

# Config syntax error / Ошибка синтаксиса
caddy validate --config /etc/caddy/Caddyfile              # Validate config / Проверить конфиг

# Port already in use / Порт занят
sudo ss -tlnp | grep -E ':80|:443'                        # Check what's using port / Проверить что использует порт
sudo systemctl stop nginx apache2                         # Stop conflicting service / Остановить конфликтующий сервис
```

### Debug Mode / Режим отладки

`/etc/caddy/Caddyfile`

```caddyfile
{
    debug                                                  # Enable debug logging / Включить отладочное логирование
}
```

```bash
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile  # Run with verbose output / Запуск с подробным выводом
```

### Certificate Management / Управление сертификатами

```bash
# View managed certificates / Просмотр управляемых сертификатов
curl -s localhost:2019/config/apps/tls/certificates | jq .

# Force certificate renewal / Принудительное обновление сертификата
caddy reload --config /etc/caddy/Caddyfile                # Reload triggers renewal check / Перезагрузка запускает проверку обновления

# Check certificate from outside / Проверить сертификат извне
openssl s_client -connect example.com:443 -servername example.com < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

### Useful Diagnostic Commands / Полезные диагностические команды

```bash
caddy version                                              # Check version / Проверить версию
caddy list-modules                                         # List modules / Список модулей
curl -s localhost:2019/config/ | jq .                      # Dump running config / Текущий конфиг
curl -s localhost:2019/reverse_proxy/upstreams | jq .      # Upstream status / Статус upstream
journalctl -u caddy -f                                     # Follow logs / Следить за логами
```

---

## Comparison Tables

### Caddy vs Other Web Servers / Сравнение Caddy с другими веб-серверами

| Feature | Caddy | Nginx | HAProxy | Traefik |
| :--- | :--- | :--- | :--- | :--- |
| **Auto HTTPS** | ✅ Built-in / Встроено | ❌ Manual (certbot) | ❌ Manual | ✅ Built-in |
| **Config Format** | Caddyfile / JSON | Custom (`nginx.conf`) | Custom (`haproxy.cfg`) | YAML / TOML |
| **HTTP/3 (QUIC)** | ✅ Default | ⚠️ Experimental | ❌ No | ✅ Yes |
| **Active Health Checks** | ✅ Free | ❌ Plus only | ✅ Free | ✅ Free |
| **Performance** | High / Высокая | Very High / Очень высокая | Very High / Очень высокая | High / Высокая |
| **Memory** | Moderate | Low / Низкое | Low / Низкое | Moderate |
| **Language** | Go | C | C | Go |
| **Config Reload** | ✅ Graceful | ✅ Graceful | ✅ Graceful | ✅ Auto |
| **Service Discovery** | Via plugins | ❌ Manual | ❌ Manual | ✅ Built-in |
| **Best For** | Simple HTTPS setup | High-perf reverse proxy | L4/L7 Load Balancing | Cloud-native/K8s |

### TLS Certificate Sources / Источники TLS-сертификатов

| Source | Description (EN / RU) | Use Case |
| :--- | :--- | :--- |
| **Let's Encrypt** | Free, auto-renew (default) / Бесплатные, автообновление | Production / Продакшн |
| **ZeroSSL** | Free alternative CA / Бесплатная альтернатива | Fallback CA / Резервный CA |
| **Custom certs** | User-provided PEM files / Пользовательские PEM файлы | Enterprise / Корпоративный |
| **Internal** | Self-signed for local dev / Самоподписанные для разработки | Development / Разработка |

---

## Logrotate Configuration

> [!NOTE]
> Caddy has **built-in log rotation** via `roll_size`, `roll_keep`, and `roll_keep_for` directives. External logrotate is optional but can be used for integration with existing systems.
> Caddy имеет **встроенную ротацию логов** через директивы `roll_size`, `roll_keep`, `roll_keep_for`. Внешний logrotate опционален.

### Built-in Rotation / Встроенная ротация

`/etc/caddy/Caddyfile`

```caddyfile
log {
    output file /var/log/caddy/access.log {
        roll_size 100mb                                    # Rotate at 100MB / Ротация при 100МБ
        roll_keep 10                                       # Keep 10 files / Хранить 10 файлов
        roll_keep_for 720h                                 # Keep for 30 days / Хранить 30 дней
    }
}
```

### External Logrotate / Внешний Logrotate

`/etc/logrotate.d/caddy`

```conf
/var/log/caddy/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 caddy caddy
    sharedscripts
    postrotate
        kill -USR1 $(cat /run/caddy.pid 2>/dev/null) > /dev/null 2>&1 || true
    endscript
}
```

---

## Documentation Links

- [Caddy Official Documentation](https://caddyserver.com/docs/)
- [Caddyfile Concepts](https://caddyserver.com/docs/caddyfile/concepts)
- [Caddyfile Directives](https://caddyserver.com/docs/caddyfile/directives)
- [Caddy Reverse Proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [Caddy TLS Configuration](https://caddyserver.com/docs/caddyfile/directives/tls)
- [Caddy JSON API](https://caddyserver.com/docs/api)
- [Caddy Community Plugins](https://caddyserver.com/download)
- [Caddy GitHub Repository](https://github.com/caddyserver/caddy)
- [Caddy Wiki](https://caddy.community/)
- [xcaddy — Custom Builds](https://github.com/caddyserver/xcaddy)

---
