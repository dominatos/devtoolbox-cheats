---
Title: 🚪 LiteLLM — AI Gateway
Group: AI
Icon: 🚪
Order: 7
tags:
  - ai
  - llm
  - litellm
  - gateway
  - proxy
  - openai-api
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

# 🚪 LiteLLM Cheatsheet

## Description

**LiteLLM** is an open-source **AI gateway/proxy**: Python SDK + proxy for 100+ LLM providers in OpenAI format. Virtual keys, spend tracking, guardrails, load balancing, logging. MCP gateway; agent harnesses routed through the gateway. / **LiteLLM** — AI-шлюз/прокси: SDK и proxy для 100+ LLM-провайдеров в OpenAI-формате. Virtual keys, трекинг расходов, guardrails, балансировка, логи.

**Common use cases / Типовые сценарии:**
- Central place for API keys and budgets / Единый ключ и бюджет
- Load balance across providers / Балансировка между провайдерами
- Route cloud + local models / Роутинг cloud + local
- Cost tracking per team/key / Трекинг стоимости

**Status:** Very active (BerriAI/litellm). Alternatives: **Portkey**, **OpenRouter**, custom nginx. / **Статус:** активно развивается; альтернативы — Portkey, OpenRouter, nginx.

**Default port:** `4000/tcp` (OpenAI-compatible `/v1/*`).  
**Auth:** master key / virtual keys.  
**Config:** `proxy_server_config.yaml` / `.env`.  
**Deploy:** Docker, compose, Helm, Terraform.

Cross-reference: [Ollama](ollamacheatsheet.md), [vLLM](vllmcheatsheet.md), [Open WebUI](openwebuicheatsheet.md), [OpenCode](opencodecheatsheet.md).

---

## Installation

### pip / pip

```bash
uv tool install 'litellm[proxy]'
# or
pip install 'litellm[proxy]'
```

```bash
litellm --model gpt-4o
```

### Docker / Docker

```bash
docker run -d --name litellm \
  -p 4000:4000 \
  -e LITELLM_MASTER_KEY=<SECRET_KEY> \
  -e OPENAI_API_KEY=<OPENAI_KEY> \
  ghcr.io/berriai/litellm:main-latest \
  --model gpt-4o
```

### Docker Compose / Docker Compose

```bash
# Repo ships docker-compose.yml and docker-compose.hardened.yml
docker compose -f docker-compose.hardened.yml up -d
```

---

## Configuration

### proxy config / Конфигурация proxy

`proxy_server_config.yaml`

```bash
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
  - model_name: llama3.2
    litellm_params:
      model: ollama/llama3.2
      api_base: http://127.0.0.1:11434

litellm_settings:
  drop_params: true
  num_retries: 2
  request_timeout: 60
```

### Environment / Окружение

| Variable | Purpose |
| :--- | :--- |
| `LITELLM_MASTER_KEY` | Admin/master key |
| `OPENAI_API_KEY` | Provider key (example) |
| `LITELLM_LOG` | Log level |

```bash
litellm --config proxy_server_config.yaml --port 4000
```

---

## Core Management

### OpenAI-compatible API / OpenAI-совместимый API

```bash
curl http://localhost:4000/v1/models \
  -H "Authorization: Bearer <SECRET_KEY>"

curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SECRET_KEY>" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

### Virtual keys / Virtual keys

```bash
# Admin UI or API to create per-team virtual keys with budgets
# See docs.litellm.ai for key management endpoints
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u litellm --no-pager -n 50
docker logs litellm -f
```

### Prometheus metrics / Prometheus metrics

```bash
# Configure spend/metrics in litellm_settings — see docs
# Scrapable via standard Prometheus endpoint when enabled
```

### Logrotate / Ротация логов

`/etc/logrotate.d/litellm`

```bash
/var/log/litellm/*.log {
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

1. Always set `LITELLM_MASTER_KEY` / Всегда задавайте master key
2. Use virtual keys per team — never share master key / Virtual keys для команд
3. Bind behind TLS reverse proxy / TLS-прокси
4. Use hardened compose in production / Используйте hardened compose
5. Restrict network to provider APIs / Ограничьте сеть до provider APIs
6. Keep LiteLLM updated / Обновляйте LiteLLM
7. Review spend limits and budgets / Проверяйте лимиты расходов

```bash
# Never commit LITELLM_MASTER_KEY or provider keys
```

> [!WARNING]
> The master key has full admin access. Store it in a secret manager only. / **Master key — полный доступ. Храните только в secret manager.**

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| 401 Unauthorized | Wrong key | Check Bearer key |
| Provider errors | Bad upstream key/URL | Check model_list params |
| Timeout | Slow provider / network | Adjust request_timeout |
| Ollama model missing | Ollama down / wrong model | Check Ollama; model name |
| High spend | No budget limits | Set virtual key budgets |

```bash
curl -s http://localhost:4000/v1/models -H "Authorization: Bearer <SECRET_KEY>"
docker logs litellm -n 40
```

---

## Comparison Tables

### AI gateways / AI-шлюзы

| Gateway | Notes |
| :--- | :--- |
| **LiteLLM** | Open-source, multi-provider |
| **Portkey** | Managed gateway features |
| **OpenRouter** | Hosted router/marketplace |
| **nginx** | DIY multi-upstream |

---

## Production Runbooks

### Runbook: Deploy LiteLLM gateway / Развёртывание LiteLLM

1. Write proxy_server_config.yaml with models / Настроить модели
2. Set LITELLM_MASTER_KEY and provider keys in env / Задать ключи
3. Deploy via Docker hardened compose or systemd / Развернуть
4. Put TLS reverse proxy on :4000 / Прокси + TLS
5. Create virtual keys per team with budgets / Создать virtual keys
6. Point apps/OpenCode/Open WebUI at gateway / Подключить клиенты
7. Monitor spend metrics / Мониторить расходы

### Runbook: Add a new model backend / Новый бэкенд модели

1. Add entry under model_list in config / Добавить в config
2. Set provider env var if needed / Задать env
3. Reload/restart LiteLLM / Перезапустить
4. `curl /v1/models` — verify / Проверить
5. Test chat completion / Протестировать chat
6. Document model alias / Задокументировать алиас

---

## Documentation Links

- LiteLLM docs — https://docs.litellm.ai/
- Simple proxy — https://docs.litellm.ai/docs/simple_proxy
- LiteLLM GitHub — https://github.com/BerriAI/litellm
