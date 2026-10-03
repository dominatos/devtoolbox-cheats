---
Title: 🔐 Certbot — Let's Encrypt TLS
Group: "Security & Crypto"
Icon: 🔐
Order: 20
tags:
  - security
  - tls
  - letsencrypt
  - certbot
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

# 🔐 Certbot Cheatsheet (Let's Encrypt / ACME)

## Description

**Certbot** is the official EFF client for the **ACME protocol** (RFC 8555). It automates TLS certificate issuance, renewal, and revocation against public CAs such as **Let's Encrypt**, **ZeroSSL**, and **Google Trust Services**. / **Certbot** — официальный клиент ACME-протокола (RFC 8555) для автоматического выпуска, продления и отзыва TLS-сертификатов (Let's Encrypt, ZeroSSL, Google Trust Services).

**Common use cases / Типовые сценарии:**
- HTTPS for nginx/Apache/caddy/HAProxy / HTTPS для веб-серверов
- Wildcard certificates via DNS-01 / Вайлдкард-сертификаты через DNS-01
- Internal PKI-less public cert automation / Автоматизация публичных сертификатов без собственного CA
- Cert export for mail/VPN/non-web services / Экспорт сертификатов для почты/VPN/не-web

**Status:** Actively maintained; production default for public TLS. Alternatives: **acme.sh** (POSIX shell), **lego** (Go), **win-acme**, **Traefik**/*Caddy* (built-in ACME). / **Статус:** Активно поддерживается; стандарт для публичного TLS. Альтернативы: acme.sh, lego, Caddy (встроенный ACME).

**Default ports:** ACME HTTP-01 `80/tcp`; DNS-01 `53/tcp/udp` (DNS provider).  
**Paths:** certs `/etc/letsencrypt/live/<NAME>/`; renewal `/etc/letsencrypt/renewal/<NAME>.conf`.

Cross-reference: [OpenSSL](opensslcheatsheet.md), [OpenSSL CSR SAN](opensslsancsrcheatsheet.md), [nginx](../web-servers/nginxcheatsheet.md), [Apache](../web-servers/apachecheatsheet.md).

---

## Installation

### Install Certbot / Установка Certbot

```bash
# Debian/Ubuntu (distro package)
apt update
apt install certbot python3-certbot-nginx   # or python3-certbot-apache

# RHEL/Rocky/Alma/Fedora
dnf install certbot python3-certbot-nginx

# Snap (often newest version + DNS plugins)
apt install snapd
snap install --classic certbot
snap install --classic certbot-dns-cloudflare   # example DNS plugin

# Pip (last resort; prefer distro/snap)
pip install certbot certbot-dns-cloudflare
```

```bash
certbot --version  # Verify install / Проверить установку
```

### Nginx/Apache integration packages / Интеграция с веб-серверами

```bash
# Debian/Ubuntu
apt install python3-certbot-nginx
apt install python3-certbot-apache
```

---

## Configuration

### Main paths / Основные пути

`/etc/letsencrypt/`

`/etc/letsencrypt/live/<CERT_NAME>/`

`/etc/letsencrypt/renewal/<CERT_NAME>.conf`

`/etc/letsencrypt/renewal-hooks/{pre,deploy,post}/`

`/etc/letsencrypt/keys/` (account keys; mode `0700`)

```bash
# Certificate files per domain
ls -la /etc/letsencrypt/live/<HOST>/
# cert.pem      — leaf/server certificate
# chain.pem     — intermediates only
# fullchain.pem — leaf + intermediates (use this for nginx)
# privkey.pem   — private key (0600 root-only by default)
```

> [!CAUTION]
> Never copy private keys out of `/etc/letsencrypt` into chat, tickets, or world-readable paths. Point webserver configs at `/etc/letsencrypt/live/...` symlinks. / Не копируйте приватные ключи в чаты и world-readable пути; настройте веб-сервер на симлинки.

### Main client config / Основной конфиг клиента

`/etc/letsencrypt/cli.ini`

```bash
# Non-interactive production defaults
agree-tos = true
email = <EMAIL>
# key-type = ecdsa          # default for new certs (P-256)
# rsa-key-size = 4096       # only if you force RSA
# prefer-challenges = dns   # for wildcard-capable runs
```

### DNS plugin credentials (Cloudflare example) / Учётные данные DNS-плагина

`/etc/letsencrypt/dns-cloudflare.ini`

```bash
dns_cloudflare_api_token = <SECRET_KEY>
```

```bash
chmod 600 /etc/letsencrypt/dns-cloudflare.ini  # Protect credentials / Ограничить доступ
```

---

## Core Management

### Issue certificates / Выпуск сертификатов

```bash
# Nginx auto-issue + install + redirect
certbot --nginx -d <HOST> -d www.<HOST>

# Apache auto-issue + install
certbot --apache -d <HOST>

# Certificate only (certbot certonly) — no webserver install
certbot certonly --standalone -d <HOST>

# Webroot (already-running webserver, no restart)
certbot certonly --webroot -w /var/www/html -d <HOST>

# DNS-01 (wildcard)
certbot certonly --dns-cloudflare -d <HOST> -d '*.<HOST>'

# Staging (test rate limits; trust chain not for production browsers)
certbot certonly --staging -d <HOST>

# Force RSA key
certbot certonly --nginx --key-type rsa --rsa-key-size 4096 -d <HOST>
```

### List and inspect / Список и инспекция

```bash
certbot certificates                 # List known certs / Список сертификатов
certbot show                          # Alias-ish overview on some builds; prefer certificates
openssl x509 -in /etc/letsencrypt/live/<HOST>/cert.pem -noout -text  # Detail / Детали
openssl x509 -in /etc/letsencrypt/live/<HOST>/cert.pem -noout -enddate
```

Sample output:

```text
Certificate Name: example.com
  Domains: example.com www.example.com
  Expiry Date: 2027-01-15 12:00:00+00:00 (VALID: 80 days)
  Certificate Path: /etc/letsencrypt/live/example.com/fullchain.pem
  Key Type: ECDSA
  Private Key Path: /etc/letsencrypt/live/example.com/privkey.pem
```

### Renew / Продление

```bash
certbot renew                         # Renew all due certs
certbot renew --dry-run               # Simulate against staging / Тестовое продление
certbot renew -q --quiet
certbot renew --cert-name <HOST> --force-renewal   # Force (watch rate limits!)
```

> [!WARNING]
> `--force-renewal` counts against Let's Encrypt rate limits (typically 5 duplicate certs/week per registered domain set). Use only for key rotation or controlled migrations. / `--force-renewal` учитывается в rate limits Let's Encrypt; используйте только для ротации ключей и миграций.

### Expand / change domains / Изменение доменов

```bash
certbot certonly --expand -d <HOST> -d www.<HOST> -d api.<HOST>
certbot certonly --cert-name <HOST> -d <HOST>   # Set exact domain set

# Modern preferred: reconfigure renewal params
certbot reconfigure --cert-name <HOST> --webroot-path /var/www/new
```

### Revoke and delete / Отзыв и удаление

```bash
certbot revoke --cert-name <HOST>
certbot revoke --cert-path /etc/letsencrypt/live/<HOST>/cert.pem \
  --key-path /etc/letsencrypt/live/<HOST>/privkey.pem
certbot revoke --cert-name <HOST> --reason keycompromise

# Remove cert files after config references are gone
certbot delete --cert-name <HOST>
```

> [!CAUTION]
> Deleting a cert without removing nginx/Apache references first breaks TLS on reload. Always `grep -R live/<HOST> /etc/{nginx,apache2,httpd}` first. / Удалите ссылки из конфигов веб-серверов **до** `certbot delete`.

---

## Sysadmin Operations

### Automated renewal timer / Автоматическое продление

```bash
# systemd timer (Debian/Ubuntu often ships this)
systemctl list-timers | grep -i certbot
cat /etc/cron.d/certbot 2>/dev/null || true
```

`/etc/systemd/system/certbot-renew.service` (optional explicit unit)

```ini
[Unit]
Description=Certbot renewal

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --deploy-hook /usr/local/bin/reload-tls.sh
```

`/etc/systemd/system/certbot-renew.timer`

```ini
[Unit]
Description=Run certbot renew twice daily

[Timer]
OnCalendar=*-*-* 00,12:07:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl enable --now certbot-renew.timer
```

### Deploy hooks / Скрипты после продления

`/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh`

```bash
#!/bin/bash
# Reload TLS after cert change / Перезагрузить TLS после смены сертификата
systemctl reload nginx
# or: systemctl reload apache2
```

```bash
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

### Pre/post hooks for standalone / Хуки для standalone

```bash
certbot renew \
  --pre-hook "systemctl stop nginx" \
  --post-hook "systemctl start nginx"
```

### Permissions for non-root daemons / Права для нерутовых демонов

```bash
# Allow nginx worker user to read privkey
chgrp <WEB_GROUP> /etc/letsencrypt/live/<HOST>/privkey.pem
chmod 0640 /etc/letsencrypt/live/<HOST>/privkey.pem
# live/ and archive/ are 0700 by default — optional relax for non-root only
# chmod 0755 /etc/letsencrypt/{live,archive}   # only if you never downgrade Certbot
```

### Export / convert / Экспорт и конвертация

```bash
# PEM → PKCS#12 for Windows/clients
openssl pkcs12 -export \
  -inkey /etc/letsencrypt/live/<HOST>/privkey.pem \
  -in /etc/letsencrypt/live/<HOST>/fullchain.pem \
  -out /tmp/<HOST>.p12 -name <HOST>

# Split fullchain into leaf + chain for some MTAs/load balancers
openssl crl2pkcs7 -nocrl -certfile /etc/letsencrypt/live/<HOST>/fullchain.pem | \
  openssl pkcs7 -print_certs -out /tmp/<HOST>-chain-only.pem
```

### Logrotate / Ротация логов

`/etc/logrotate.d/certbot`

```bash
/var/log/letsencrypt/letsencrypt.log {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

> Note: most distro packages already manage logs under `/var/log/letsencrypt/`. / Обычно ротацию уже настраивает дистрибутивный пакет.

---

## Security

### Best practices / Рекомендации

- Prefer **DNS-01** for wildcards and internal hosts behind firewalls / Предпочитайте DNS-01 для вайлдкардов и внутренних хостов
- Use **ECDSA P-256** unless old clients require RSA / Используйте ECDSA P-256, если клиенты не требуют RSA
- Keep renewal automated and monitored / Следите за автопродлением (мониторинг expiry)
- Never use `--force-renewal` on a schedule / Не запускайте force-renew по расписанию
- Staging for tests; production only for real traffic / Staging для тестов

```bash
# Expiry monitoring without waiting for CA email
certbot certificates | grep -A2 "Expiry Date"
# Or prometheus/blackbox style HTTP check on 443
```

### Compromise response / Реакция на компрометацию ключа

1. Revoke with `--reason keycompromise` / Отозвать сертификат с причиной keycompromise
2. Delete compromised `privkey.pem` via `certbot delete` / Удалить приватный ключ
3. Re-issue with new key (prefer ECDSA) / Выпустить новый сертификат
4. Reload services; rotate any exported PKCS#12 / Перезагрузить сервисы, ротировать экспорты
5. Investigate how the key was exposed / Разобраться в источнике утечки

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Backup certs + renewal configs + account keys (private data — encrypt!)
tar czf /var/backups/letsencrypt-$(date +%F).tar.gz \
  /etc/letsencrypt/{live,archive,renewal,accounts,cli.ini}
# Prefer age/GPG encryption for the archive
```

### Restore / Восстановление

```bash
# Stop certbot timer
systemctl stop certbot-renew.timer

# Restore tree
tar xzf /var/backups/letsencrypt-<DATE>.tar.gz -C /

# Point webserver at restored live paths; reload
systemctl reload nginx

# Dry-run renew
certbot renew --dry-run
systemctl start certbot-renew.timer
```

> [!NOTE]
> Restoring accounts/keys is preferred over re-issuing to stay under rate limits. Store backups encrypted; private keys are full material. / Восстанавливайте accounts/keys, а не перевыпускайте сертификаты; храните бэкапы в зашифрованном виде.

---

## Troubleshooting

### Common errors / Частые ошибки

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `Unauthorized` / 403 HTTP-01 | Port 80 blocked, wrong vhost, `/.well-known` not served | Open 80; fix webroot; check firewall |
| `DNS problem: NXDOMAIN` | DNS-01 TXT not visible | Wait for propagation; verify provider API token |
| `RateLimited` | Too many duplicate issues | Use staging; wait; stop `--force-renewal` |
| `CertbotError: Invalid or insecure challenge` | TLS-only redirect before challenge | Temporarily allow HTTP; disable force-HTTPS during issue |
| Renewal fails but manual works | Wrong plugin args in renewal.conf | `certbot reconfigure --cert-name ...` or dry-run with explicit plugin |
| nginx reload fails after renew | Bad cert path or missing chain | Check `ssl_certificate` points to `fullchain.pem` |

### Debug commands / Отладка

```bash
certbot renew --dry-run -v
certbot certificates --verbose
journalctl -u certbot-renew.service --no-pager -n 50
ss -lntp | grep -E ':80\b'   # Confirm HTTP-01 listener / Проверить порт 80
curl -I http://<HOST>/.well-known/acme-challenge/test
```

---

## Comparison Tables

### Auth plugins / Плагины аутентификации

| Plugin | Challenge | Wildcard? | Best for |
| :--- | :--- | :--- | :--- |
| `nginx` / `apache` | HTTP-01 | No | Standard public web on that server / Обычный public web |
| `webroot` | HTTP-01 | No | Existing webserver, no downtime / Уже работающий веб-сервер |
| `standalone` | HTTP-01 | No | One-shot issue; needs port 80 free / Разовый выпуск, свободный порт 80 |
| `dns-cloudflare` (etc.) | DNS-01 | **Yes** | Wildcards, firewalled hosts / Вайлдкарды, закрытые хосты |
| `manual` | HTTP/DNS | Depends | Emergency only / Только в крайнем случае |

### Certificate clients / Клиенты ACME

| Client | Language | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **Certbot** | Python | Official, plugins, docs | Heavier runtime |
| **acme.sh** | POSIX shell | Light, many DNS hooks | Fewer server installers |
| **lego** | Go | Fast, good CI use | No auto nginx config |
| **Caddy** | Go | Zero-touch ACME | Tied to Caddy |

---

## Production Runbooks

### Runbook: Issue cert for new site on nginx / Выпуск сертификата для нового сайта

1. Confirm DNS A/AAAA for `<HOST>` points at this server / Проверить DNS-записи
2. Confirm port 80 reachable from Internet / Проверить доступность 80/tcp
3. Backup nginx config / Сделать бэкап конфига nginx
4. Run `certbot --nginx -d <HOST> -d www.<HOST>` / Выпустить сертификат
5. Verify TLS: `curl -I https://<HOST>` shows valid chain / Проверить цепочку
6. Confirm timer exists: `systemctl list-timers | grep certbot` / Проверить автопродление
7. Document cert name, domains, deploy hook / Задокументировать параметры

### Runbook: Emergency renewal failure (expiring <7 days) / Экстренное продление

1. `certbot renew --cert-name <HOST> -v` — capture full error / Собрать ошибку
2. If HTTP-01 fails: temporarily allow port 80; disable force-HTTPS redirect / Открыть 80, отключить редирект
3. If DNS-01 fails: verify API token, proxy settings (Cloudflare orange-cloud off for TXT) / Проверить DNS API
4. Retry `certbot renew --cert-name <HOST> --force-renewal` (once) / Повторить принудительно один раз
5. `certbot certificates` — confirm new expiry / Проверить дату
6. `systemctl reload nginx` (or apache) / Перезагрузить веб-сервер
7. File incident; fix automation before next window / Закрыть инцидент, починить автоматизацию

### Runbook: Key rotation / Ротация приватного ключа

1. `certbot renew --cert-name <HOST> --key-type ecdsa --force-renewal` / Выпустить новый ключ
2. `openssl x509 -in .../cert.pem -noout -text` — verify Key Type / Проверить тип ключа
3. Reload dependent services (nginx, postfix, openvpn) / Перезагрузить зависимые сервисы
4. Re-export any PKCS#12/clients if used / Переэкспортировать клиентские артефакты
5. Delete old archived key material after validation (retain short audit window) / Удалить старые ключи после проверки

---

## Documentation Links

- Certbot User Guide — https://eff-certbot.readthedocs.io/en/latest/using.html
- Certbot Instructions (OS-specific) — https://certbot.eff.org/instructions
- Let's Encrypt Rate Limits — https://letsencrypt.org/docs/rate-limits/
- ACME RFC 8555 — https://datatracker.ietf.org/doc/html/rfc8555
- Certbot DNS plugin docs (Cloudflare example) — https://certbot-dns-cloudflare.readthedocs.io
- Caddy automatic HTTPS — https://caddyserver.com/docs/automatic-https
