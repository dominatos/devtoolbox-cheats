---
Title: 🚦 Traefik — Reverse Proxy
Group: "Web Servers"
Icon: 🚦
Order: 8
tags:
  - web
  - traefik
  - proxy
  - ingress
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
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🚦 Traefik Cheatsheet

## Description

**Traefik** is a modern **reverse proxy and ingress controller** with automatic service discovery (Docker labels, Kubernetes IngressRoute). It auto-generates TLS certificates via Let's Encrypt. / **Traefik** — современный reverse proxy и ingress controller с авто-discovery сервисов и автоматическими TLS-сертификатами Let's Encrypt.

**Common use cases / Типовые сценарии:**
- Docker Compose reverse proxy / Reverse proxy для Docker Compose
- Kubernetes Ingress / Ingress для Kubernetes
- Automatic HTTPS with ACME / Автоматический HTTPS через ACMTraffic routing with middleware / Маршрутизация трафика с middleware

**Status:** Actively maintained (Traefik Labs / CNCF). Alternatives: **Nginx**, **HAProxy**, **Caddy**, **Envoy**. / **Статус:** активно развивается; альтернативы — Nginx, HAProxy, Caddy, Envoy.

**Default ports:** `80/tcp` (HTTP), `443/tcp` (HTTPS), `8080/tcp` (dashboard/API).  
**Paths:** config `traefik.yml` or Docker labels; data `/etc/traefik/`.

Cross-reference: [Nginx](nginxcheatsheet.md), [Caddy](caddycheatsheet.md), [HAProxy](haproxycheatsheet.md), [Certbot](../security-crypto/certbotcheatsheet.md), [Docker](../kubernetes-containers/dockercheatsheet.md).

---

## Installation

### Install Traefik / Установка Traefik

```bash
# Docker (most common)
docker pull traefik:v3.1
docker run -d \
  --name traefik \
  -p 80:80 -p 443:443 -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc/traefik/traefik.yml:/etc/traefik/traefik.yml:ro \
  traefik:v3.1

# Debian/Ubuntu
apt install traefik
```

```bash
traefik version
```

---

## Configuration

### Main files / Основные файлы

`/etc/traefik/traefik.yml`

`/etc/traefik/dynamic/`

`/etc/traefik/certs/`

### Static config / Статическая конфигурация

`/etc/traefik/traefik.yml`

```bash
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: <ADMIN_EMAIL>
      storage: /etc/traefik/certs/acme.json
      httpChallenge:
        entryPoint: web
```

### Dynamic middleware / Динамический middleware

`/etc/traefik/dynamic/middleware.yml`

```bash
http:
  middlewares:
    secure-headers:
      headers:
        frameDeny: true
        stsSeconds: 31536000
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
    retry:
      retry:
        attempts: 3
```

### Docker labels / Docker labels

```bash
# docker-compose service labels
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`<HOST>`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
  - "traefik.http.routers.myapp.middlewares=secure-headers@file"
```

---

## Core Management

### Status / Статус

```bash
curl -s http://127.0.0.1:8080/api/overview
docker logs traefik --tail=50
```

### API queries / Запросы к API

```bash
curl -s http://127.0.0.1:8080/api/http/routers | jq .
curl -s http://127.0.0.1:8080/api/http/services | jq .
curl -s http://127.0.0.1:8080/api/overview | jq '.http, .tcp, .udp'
```

---

## Sysadmin Operations

### Logs / Логи

```bash
docker logs -f traefik
journalctl -u traefik --no-pager -n 50
```

### Logrotate / Ротация логов

`/etc/logrotate.d/traefik`

```bash
/var/log/traefik/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

> Note: Docker deployments typically use json-file logging driver — rotate via Docker daemon config. / При Docker-развёртывании используйте json-file logging driver.

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Disable dashboard in production or bind to localhost / Отключите dashboard в проде
2. Enable TLS on entrypoints / Включите TLS
3. Use `exposedByDefault: false` / Не выставляйте контейнеры по умолчанию
4. Add rate limiting and security headers / Добавьте rate-limit и security headers
5. Restrict Docker socket access (read-only) / Ограничьте доступ к Docker socket
6. Keep Traefik updated (CVEs) / Обновляйте Traefik

```bash
# Disable dashboard in production
# api:
#   dashboard: false
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/traefik-$(date +%F).tar.gz /etc/traefik
```

### Restore / Восстановление

```bash
systemctl stop traefik   # or docker stop traefik
tar xzf /var/backups/traefik-<DATE>.tar.gz -C /
systemctl start traefik  # or docker start traefik
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| 404 from router | Label/IngressRoute wrong | Check router rule |
| ACME fails | Port 80 blocked / rate limit | Verify HTTP challenge path |
| Dashboard 404 | insecure mode off | Enable API or bind to localhost |
| Service down | Backend port wrong | Check loadbalancer.server.port |
| TLS cert missing | certresolver misconfigured | Check certificatesResolvers |

```bash
curl -s http://127.0.0.1:8080/api/http/routers | jq '.[] | {name, rule, status}'
docker logs traefik --tail=100
```

---

## Comparison Tables

### Reverse proxies / Reverse proxy

| Tool | Config style | Auto-ACME | Best for |
| :--- | :--- | :--- | :--- |
| **Traefik** | Labels/CRDs | Yes | Docker/K8s dynamic |
| **Nginx** | Declarative files | With certbot | Manual, high perf |
| **HAProxy** | Declarative files | No | High-throughput TCP/HTTP |
| **Caddy** | Declarative files | Yes | Simple automatic HTTPS |
| **Envoy** | xDS/CRDs | No | Service mesh sidecars |

---

## Production Runbooks

### Runbook: New service behind Traefik / Новый сервис за Traefik

1. Deploy service with Traefik labels / Развернуть сервис с labels
2. Confirm router appears in API / Проверить router в API
3. Verify HTTPS cert issued / Проверить выпуск TLS
4. Test security headers / Проверить security headers
5. Document router name and domain / Зафиксировать router и домен

### Runbook: ACME cert renewal failure / Сбой продления ACME

1. Check rate limits on Let's Encrypt / Проверить rate limits
2. Verify port 80 reachable for challenge / Проверить доступность port 80
3. Inspect `acme.json` permissions (600) / Проверить права acme.json
4. Force renew via Traefik restart / Принудительно продлить
5. Consider staging endpoint for testing / Используйте staging для тестов

---

## Documentation Links

- Traefik docs — https://doc.traefik.io/traefik/
- Traefik GitHub — https://github.com/traefik/traefik
- Traefik ACME — https://doc.traefik.io/traefik/https/acme/
- Traefik Docker provider — https://doc.traefik.io/traefik/providers/docker/
