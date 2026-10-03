---
Title: 🍦 Varnish — HTTP Cache
Group: "Web Servers"
Icon: 🍦
Order: 9
tags:
  - web
  - varnish
  - cache
  - performance
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🍦 Varnish Cheatsheet

## Description

**Varnish Cache** is a high-performance **HTTP reverse proxy cache**. It stores responses in memory (or disk) and serves cached content faster than backend origin servers. / **Varnish Cache** — высокопроизводительный HTTP reverse proxy cache. Хранит ответы в памяти (или на диске) и отдаёт их быстрее origin-серверов.

**Common use cases / Типовые сценарии:**
- Edge caching for high-traffic websites / Edge-кэширование для высоконагруженных сайтов
- Cache invalidation with VCL / Инвалидация кэша через VCL
- Load shedding under load / Сброс нагрузки при пиках
- Microcaching for APIs / Микрокэширование API

**Status:** Actively maintained (Varnish Cache Project). Alternatives: **Nginx proxy_cache**, **Apache Traffic Server**, **CDN edge caches**, **Squid**. / **Статус:** активно развивается; альтернативы — Nginx proxy_cache, Apache Traffic Server, CDN.

**Default ports:** `6081/tcp` (HTTP proxy), often fronted on `80/tcp`.  
**Paths:** VCL `/etc/varnish/default.vcl`; data `/var/lib/varnish/`.

Cross-reference: [Nginx](nginxcheatsheet.md), [HAProxy](haproxycheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md).

---

## Installation

### Install Varnish / Установка Varnish

```bash
# Debian/Ubuntu
apt install varnish

# RHEL/Rocky/Alma
dnf install varnish

# SUSE
zypper install varnish
```

```bash
varnishd -V
systemctl enable --now varnish
```

---

## Configuration

### Main files / Основные файлы

`/etc/varnish/default.vcl`

`/etc/default/varnish` (Debian)

`/etc/varnish/varnish.params` (RHEL)

`/var/lib/varnish/`

### Basic VCL / Базовый VCL

`/etc/varnish/default.vcl`

```bash
vcl 4.1;

backend default {
  .host = "<BACKEND_HOST>";
  .port = "<BACKEND_PORT>";
}

sub vcl_recv {
  # Bypass cache for non-GET
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }
  # Bypass for admin paths
  if (req.url ~ "^/(admin|api/v1/internal)") {
    return (pass);
  }
  # Normalize URL
  if (req.url ~ "\?.*") {
    set req.url = regsub(req.url, "\?.*$", "");
  }
}

sub vcl_backend_response {
  # Cache static assets
  if (bereq.url ~ "\.(css|js|png|jpg|gif|ico|svg|woff2?)$") {
    set beresp.ttl = 24h;
    set beresp.grace = 1h;
  }
  # Default TTL
  if (!beresp.ttl) {
    set beresp.ttl = 120s;
  }
}

sub vcl_deliver {
  set resp.http.X-Cache = obj.hits > 0 ? "HIT" : "MISS";
  set resp.http.X-Cache-Hits = obj.hits;
}
```

### Start with custom VCL / Запуск с кастомным VCL

```bash
varnishd -f /etc/varnish/default.vcl -a :6081 -s malloc,1G
systemctl restart varnish
```

---

## Core Management

### varnishadm / varnishadm

```bash
varnishadm status
varnishadm vcl.list
varnishadm vcl.load custom /etc/varnish/default.vcl
varnishadm vcl.use custom
varnishadm ban obj.http.X-Host == "<HOST>"
varnishadm ban url ~ "^/blog/"
varnishadm stats
```

### varnishstat / varnishstat

```bash
varnishstat -1 | head -30
varnishstat -1 | grep -E 'cache_hit|cache_miss|client_req'
```

### varnishlog / varnishlog

```bash
varnishlog -g request -q 'ReqURL ~ "^/api/"' -n <VARNISH_NAME>
varnishncsa -d
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u varnish --no-pager -n 50
varnishncsa -d | tail -50
```

### Logrotate / Ротация логов

`/etc/logrotate.d/varnish`

```bash
/var/log/varnish/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl kill -s HUP varnish >/dev/null 2>&1 || true
    endscript
}
```

---

## Security

### Hardening / Ужесточение

1. Do not cache authenticated/personalized responses / Не кэшируйте персонализированные ответы
2. Bypass cache for admin/API write paths / Обход кэша для admin/write
3. Limit memory allocation (`malloc,N`) / Ограничьте malloc
4. Restrict varnishadm access / Ограничьте доступ к varnishadm
5. Keep Varnish updated / Обновляйте Varnish
6. Use HIT/MISS headers carefully (information disclosure) / Аккуратно с X-Cache headers

> [!WARNING]
> Caching personalized content can leak data between users. Always `pass` non-cacheable responses. / **Кэширование персонализированного контента может утекать данные между пользователями.**

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Everything MISS | TTL 0 / Cache-Control | Check backend headers |
| Stale content | grace period too long | Reduce `beresp.grace` |
| varnishd won't start | VCL syntax | `varnishd -C -f default.vcl` |
| Memory exhausted | malloc too small | Increase `-s malloc` or GC |
| Admin content cached | Wrong pass rules | Add pass for admin URLs |

```bash
varnishd -C -f /etc/varnish/default.vcl
varnishadm stats | head
curl -sI http://127.0.0.1:6081/ | grep -i x-cache
```

---

## Comparison Tables

### Caching proxies / Кэширующие прокси

| Tool | Language | Strengths |
| :--- | :--- | :--- |
| **Varnish** | VCL | Very fast, rich VCL |
| **Nginx proxy_cache** | Declarative | Easy, integrated with Nginx |
| **Apache ATS** | config files | Large cache features |
| **Squid** | squid.conf | Proxy + cache legacy |

---

## Production Runbooks

### Runbook: Deploy Varnish in front of Nginx / Varnish перед Nginx

1. Install Varnish; set backend to Nginx / Установить Varnish с backend Nginx
2. Write VCL with pass rules for dynamic paths / Написать VCL с pass-правилами
3. Validate VCL: `varnishd -C` / Проверить VCL
4. Start varnishd; point DNS/LB at :6081 / Запустить и переключить трафик
5. Verify X-Cache HIT/MISS headers / Проверить заголовки X-Cache
6. Load-test cache hit ratio / Проверить hit ratio под нагрузкой

### Runbook: Emergency cache purge / Экстренная очистка кэша

1. Confirm purge scope (URL prefix or host) / Определить область очистки
2. `varnishadm ban url ~ "<PREFIX>"` / Выполнить ban
3. Verify sample URLs return MISS / Проверить выборку URL
4. Document ban reason for audit / Задокументировать причину
5. Avoid full flush unless critical / Избегайте полного flush без необходимости

---

## Documentation Links

- Varnish docs — https://varnish-cache.org/docs/
- Varnish GitHub — https://github.com/varnishcache/varnish-cache
- VCL tutorial — https://varnish-cache.org/docs/6.0/tutorial/vcl.html
- varnishadm — https://varnish-cache.org/docs/6.0/reference/varnishadm.html
