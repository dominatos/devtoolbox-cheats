---
Title: 🌐 Open WebUI — Self-hosted AI Chat
Group: AI
Icon: 🌐
Order: 6
tags:
  - ai
  - llm
  - open-webui
  - chat
  - self-hosted
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

# 🌐 Open WebUI Cheatsheet

## Description

**Open WebUI** is a self-hosted **AI chat platform**: connect Ollama, OpenAI, Anthropic, or any OpenAI-compatible backend. RAG, tools/functions, multi-user. The UI teams expect in front of local models. / **Open WebUI** — self-hosted AI-чат: Ollama, OpenAI, Anthropic или любой OpenAI-совместимый бэкенд. RAG, tools/functions, мультипользователь.

**Common use cases / Типовые сценарии:**
- Team chat UI over Ollama / Чат-интерфейс поверх Ollama
- Air-gapped self-hosted AI / Air-gapped self-hosted AI
- Multi-user with auth / Мультипользователь с auth
- RAG over documents / RAG по документам

**Status:** Very active (open-webui/open-webui). Alternatives: **LibreChat**, **LobeChat**, plain curl. / **Статус:** активно развивается; альтернативы — LibreChat, LobeChat.

**Default port:** typically `8080` (pip) — confirm with your install.  
**Install:** `pip install open-webui` or Docker.  
**Backends:** Ollama at `:11434`, OpenAI-compatible APIs.

Cross-reference: [Ollama](ollamacheatsheet.md), [LiteLLM](litellmcheatsheet.md), [LocalAI](localaicheatsheet.md).

---

## Installation

### pip / pip

```bash
pip install open-webui
open-webui serve --port 8080 --host 0.0.0.0
```

### Docker / Docker

```bash
docker run -d --name open-webui \
  -p 8080:8080 \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

---

## Configuration

### Connect Ollama / Подключение Ollama

```bash
# Admin UI → Settings → Connections
# Ollama URL: http://127.0.0.1:11434 (or Docker host gateway)
```

### Key environment variables / Ключевые переменные

| Variable | Purpose |
| :--- | :--- |
| `OLLAMA_BASE_URL` | Ollama endpoint |
| `OPENAI_API_BASE_URL` | OpenAI-compatible endpoint |
| `OPENAI_API_KEY` | API key for OpenAI backend |
| `WEBUI_AUTH` | Enable/disable auth (default on) |
| `DATA_DIR` | Persistent data path |

### Systemd unit / systemd unit

`/etc/systemd/system/open-webui.service`

```bash
[Unit]
Description=Open WebUI
After=network.target

[Service]
User=www-data
Environment="OLLAMA_BASE_URL=http://127.0.0.1:11434"
ExecStart=/usr/local/bin/open-webui serve --port 8080 --host 0.0.0.0
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable --now open-webui
```

---

## Core Management

### Service control / Управление сервисом

```bash
systemctl status open-webui
journalctl -u open-webui --no-pager -n 50
```

### First-run admin / Первый администратор

```bash
# Open http://<HOST>:8080 — first registered user becomes admin
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u open-webui -f
docker logs open-webui -f
```

### Backup / Резервное копирование

```bash
# Docker volume or data dir
tar czf /var/backups/open-webui-$(date +%F).tar.gz /app/backend/data
# Or named volume
docker run --rm -v open-webui:/data -v /var/backups:/backup alpine \
  tar czf /backup/open-webui-$(date +%F).tar.gz -C /data .
```

### Logrotate / Ротация логов

`/etc/logrotate.d/open-webui`

```bash
/var/log/open-webui/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Security

### Hardening / Ужесточение

1. Keep auth enabled (WEBUI_AUTH=on) / Не отключайте auth
2. TLS via reverse proxy / TLS через reverse proxy
3. Persistent volume with restricted perms / Volume с ограниченными правами
4. Restrict Ollama to localhost / Ollama только localhost
5. Keep Open WebUI updated / Обновляйте Open WebUI
6. Review admin users / Проверяйте администраторов

```bash
# TLS example
# server → proxy_pass http://127.0.0.1:8080;
# ssl_certificate ...
```

> [!WARNING]
> First user becomes admin. Do not expose the port before setting a strong admin password. / **Первый пользователь — администратор. Задайте сильный пароль до публикации.**

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Cannot connect to Ollama | Wrong URL / Docker network | Check OLLAMA_BASE_URL |
| Models list empty | Backend not reachable | Test Ollama API from same host |
| Port conflict | 8080 in use | Change `--port` |
| Slow responses | Small model / CPU | Use GPU Ollama; larger model |
| Auth issues | WEBUI_AUTH off/on | Check auth setting |

```bash
curl http://127.0.0.1:11434/api/tags
systemctl status open-webui
```

---

## Comparison Tables

### Self-hosted AI UIs / Self-hosted AI-интерфейсы

| UI | Backend | Notes |
| :--- | :--- | :--- |
| **Open WebUI** | Ollama, OpenAI, many | Large community |
| **LibreChat** | Multi-provider | Chat-focused |
| **LobeChat** | Multi-provider | Modern UI |

---

## Production Runbooks

### Runbook: Team Open WebUI + Ollama / Команда Open WebUI + Ollama

1. Deploy Ollama; pull models / Развернуть Ollama; загрузить модели
2. Deploy Open WebUI with persistent volume / Развернуть Open WebUI
3. Connect to Ollama; create admin account / Подключить Ollama; создать admin
4. Put TLS reverse proxy in front / Прокси + TLS
5. Invite users; document roles / Пригласить пользователей; роли
6. Monitor disk (models + data) / Мониторить диск
7. Backup data volume regularly / Регулярный бэкап

---

## Documentation Links

- Open WebUI docs — https://docs.openwebui.com/
- Open WebUI GitHub — https://github.com/open-webui/open-webui
- Open WebUI site — https://openwebui.com/
