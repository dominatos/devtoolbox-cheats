---
Title: 🧩 LocalAI — Multi-modal AI Engine
Group: AI
Icon: 🧩
Order: 5
tags:
  - ai
  - llm
  - localai
  - multi-modal
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

# 🧩 LocalAI Cheatsheet

## Description

**LocalAI** is an open-source **AI engine**: small core + on-demand backends (llama.cpp, vLLM, whisper.cpp, stable-diffusion, MLX, …) behind OpenAI/Anthropic/ElevenLabs-compatible APIs. Supports agents, RAG, MCP, multi-user quotas. / **LocalAI** — AI-движок: ядро + бэкенды по требованию (llama.cpp, vLLM, whisper.cpp, stable-diffusion, MLX). OpenAI/Anthropic-совместимые API, agents, RAG, MCP, квоты.

**Common use cases / Типовые сценарии:**
- Single endpoint for LLM/vision/voice/image / Единый endpoint для модальностей
- OpenAI-compatible API for apps / OpenAI API для приложений
- Air-gapped / self-hosted AI stack / Air-gapped self-hosted AI
- Multi-user with quotas / Мультипользователь с квотами

**Status:** Active (mudler/LocalAI, MIT). Alternatives: **Ollama + Open WebUI**, **vLLM**, **ComfyUI** (images). / **Статус:** активно развивается; альтернативы — Ollama+Open WebUI, vLLM, ComfyUI.

**Default port:** `8080/tcp`.  
**Docker images:** `localai/localai:*` (CPU, GPU CUDA variants).  
**CLI:** `local-ai`.

Cross-reference: [Ollama](ollamacheatsheet.md), [vLLM](vllmcheatsheet.md), [Open WebUI](openwebuicheatsheet.md), [NVIDIA Container Toolkit](nvidiacontainertoolkitcheatsheet.md).

---

## Installation

### Docker / Docker (recommended)

```bash
# CPU
docker run -ti --name local-ai \
  -p 8080:8080 \
  -v localai-models:/models \
  localai/localai:latest

# NVIDIA CUDA 12
docker run -ti --name local-ai \
  --gpus all \
  -p 8080:8080 \
  -v localai-models:/models \
  localai/localai:latest-gpu-nvidia-cuda-12
```

### Binary / Бинарник

```bash
# See localai.io for distro packages and install methods
local-ai --version
```

---

## Configuration

### Model gallery / Галерея моделей

```bash
# List available models from gallery
local-ai models list

# Run a model (pulls backend on demand)
local-ai run llama-3.2-1b-instruct:q4_k_m
```

### API key auth / Аутентификация по API key

```bash
docker run -ti --name local-ai \
  -p 8080:8080 \
  -e API_KEY=<SECRET_KEY> \
  -v localai-models:/models \
  localai/localai:latest
```

### Distributed mode / Распределённый режим

```bash
# Uses PostgreSQL + NATS — see LocalAI docs for distributed setup
```

---

## Core Management

### OpenAI-compatible API / OpenAI-совместимый API

```bash
curl http://localhost:8080/v1/models \
  -H "Authorization: Bearer <SECRET_KEY>"

curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SECRET_KEY>" \
  -d '{
    "model": "llama-3.2-1b-instruct:q4_k_m",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

---

## Sysadmin Operations

### Logs / Логи

```bash
docker logs local-ai -f
# Or systemd if installed as service
journalctl -u localai -f
```

### GPU monitoring / Мониторинг GPU

```bash
nvidia-smi
docker stats local-ai
```

### Logrotate / Ротация логов

`/etc/logrotate.d/localai`

```bash
/var/log/localai/*.log {
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

1. Always set `API_KEY` in production / Всегда задавайте API_KEY
2. Bind behind reverse proxy / Проксируйте
3. Protect model volume permissions / Защитите volume моделей
4. Keep LocalAI updated / Обновляйте LocalAI
5. Monitor backend image pulls / Мониторьте загрузки бэкендов
6. Restrict gallery sources in air-gap / Ограничьте источники галереи в air-gap

```bash
# API_KEY required for multi-user deployments
-e API_KEY=<SECRET_KEY>
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Model not found | Not in gallery / wrong id | `local-ai models list` |
| Backend crash | Missing backend image | Pull backend on demand |
| 401 Unauthorized | Wrong API key | Check API_KEY |
| GPU not used | No CUDA runtime | Use GPU image; `--gpus all` |
| Slow startup | Backend download | Pre-pull models |

```bash
docker logs local-ai -n 40
curl -s http://localhost:8080/v1/models
```

---

## Comparison Tables

### Local AI engines / Локальные AI-движки

| Engine | Modalities | API |
| :--- | :--- | :--- |
| **LocalAI** | LLM, vision, voice, image | OpenAI/Anthropic |
| **Ollama** | LLM primarily | OpenAI-compatible |
| **vLLM** | LLM (text) | OpenAI-compatible |
| **Open WebUI** | UI in front of backends | Client |

---

## Production Runbooks

### Runbook: Deploy LocalAI for a team / Развёртывание LocalAI

1. Deploy Docker CPU or GPU image / Запустить Docker-образ
2. Set API_KEY; expose via reverse proxy / Задать API_KEY; проксировать
3. Pre-pull production models / Загрузить production-модели
4. Test /v1/chat/completions / Проверить API
5. Document model ids and quotas / Задокументировать модели и квоты
6. Monitor GPU/CPU and disk for models / Мониторить ресурсы

---

## Documentation Links

- LocalAI docs — https://localai.io/
- LocalAI GitHub — https://github.com/mudler/LocalAI
