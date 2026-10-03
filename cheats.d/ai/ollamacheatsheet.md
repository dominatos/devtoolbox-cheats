---
Title: 🤖 Ollama — Local LLM Runtime
Group: AI
Icon: 🤖
Order: 1
tags:
  - ai
  - llm
  - local-llm
  - ollama
  - inference
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

# 🤖 Ollama Cheatsheet

## Description

**Ollama** is a local **LLM runtime** built on llama.cpp. It pulls and runs models with a simple CLI and exposes a REST API for chat, embeddings, and tools. Integrates with OpenCode, Claude Code, Open WebUI, and many clients. / **Ollama** — локальный LLM-рантайм на базе llama.cpp. Простой CLI и REST API для chat/embeddings. Интеграции с OpenCode, Claude Code, Open WebUI и другими клиентами.

**Common use cases / Типовые сценарии:**
- Private LLM endpoint on a server / Приватный LLM-endpoint на сервере
- CPU or GPU inference without cloud / Инференс на CPU/GPU без облака
- Backend for Open WebUI / OpenAI-compatible API / Бэкенд для Open WebUI / OpenAI API
- Team access to local models / Доступ команды к локальным моделям

**Status:** Very active (ollama/ollama, MIT). Alternatives: **llama.cpp server**, **vLLM** (throughput), **LocalAI** (multi-modal), **LM Studio** (desktop). / **Статус:** активно развивается; альтернативы — llama.cpp server, vLLM, LocalAI, LM Studio.

**Default port:** `11434/tcp`.  
**Paths:** models `~/.ollama`; systemd unit `ollama`.  
**Docker image:** `ollama/ollama`.

Cross-reference: [llama.cpp](llamacppcheatsheet.md), [vLLM](vllmcheatsheet.md), [Open WebUI](openwebuicheatsheet.md), [OpenCode](opencodecheatsheet.md), [NVIDIA Container Toolkit](nvidiacontainertoolkitcheatsheet.md).

---

## Installation

### Install Ollama / Установка Ollama

```bash
# Official install script (Linux/macOS)
curl -fsSL https://ollama.com/install.sh | sh

# Package managers
sudo pacman -S ollama
brew install ollama
# Nix
nix-env -iA nixpkgs.ollama
```

```bash
ollama --version
systemctl status ollama
```

### Docker / Docker

```bash
docker run -d --name ollama \
  -p 11434:11434 \
  -v ollama:/root/.ollama \
  ollama/ollama

# GPU
docker run -d --name ollama \
  --gpus all \
  -p 11434:11434 \
  -v ollama:/root/.ollama \
  ollama/ollama
```

---

## Configuration

### Main files / Основные файлы

`/etc/systemd/system/ollama.service` (override if needed)

`/etc/systemd/system/ollama.service.d/`

`~/.ollama/`

### systemd override / systemd override

`/etc/systemd/system/ollama.service.d/override.conf`

```bash
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/var/lib/ollama/models"
Environment="OLLAMA_ORIGINS=*"
```

```bash
systemctl daemon-reload
systemctl restart ollama
```

### Environment variables / Переменные окружения

| Variable | Purpose |
| :--- | :--- |
| `OLLAMA_HOST` | Bind address (default `127.0.0.1:11434`) |
| `OLLAMA_MODELS` | Model storage path |
| `OLLAMA_ORIGINS` | Allowed CORS origins |
| `OLLAMA_KEEP_ALIVE` | Model unload timeout |
| `OLLAMA_NUM_PARALLEL` | Parallel requests |

---

## Core Management

### CLI / CLI

```bash
ollama run llama3.2
ollama run llama3.2:1b
ollama list
ollama ps
ollama show llama3.2
ollama pull llama3.2
ollama push <USER>/<MODEL>
ollama cp llama3.2 myalias
ollama rm llama3.2:1b
ollama stop llama3.2
```

### REST API / REST API

```bash
# Chat
curl http://localhost:11434/api/chat \
  -d '{
    "model": "llama3.2",
    "messages": [{"role": "user", "content": "hi"}],
    "stream": false
  }'

# Generate
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.2", "prompt": "hello", "stream": false}'

# List models
curl http://localhost:11434/api/tags

# Show model
curl http://localhost:11434/api/show -d '{"name": "llama3.2"}'

# Version
curl http://localhost:11434/api/version
```

### OpenAI-compatible endpoint / OpenAI-совместимый endpoint

```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2",
    "messages": [{"role": "user", "content": "hi"}]
  }'

curl http://localhost:11434/v1/models
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u ollama --no-pager -n 50
journalctl -u ollama -f
```

### GPU monitoring / Мониторинг GPU

```bash
nvidia-smi
watch -n 1 nvidia-smi
ollama ps
```

### Logrotate / Ротация логов

`/etc/logrotate.d/ollama`

```bash
/var/log/ollama/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

### Firewall / Firewall

```bash
# firewalld — only if remote access needed
firewall-cmd --permanent --add-port=11434/tcp
firewall-cmd --reload

# Or bind to localhost only (default)
# OLLAMA_HOST=127.0.0.1:11434
```

---

## Security

### Hardening / Ужесточение

1. Keep `OLLAMA_HOST=127.0.0.1` unless remote access required / Не выставляйте 11434 наружу без нужды
2. Put reverse proxy + auth in front for teams / Прокси + аутентификация для команды
3. Restrict filesystem access via systemd / Ограничьте доступ к ФС через systemd
4. Monitor model downloads / Мониторьте загрузки моделей
5. Keep Ollama updated / Обновляйте Ollama
6. Do not expose API without auth / Не выставляйте API без auth

```bash
# Example: nginx reverse proxy with basic auth
# proxy_pass http://127.0.0.1:11434;
```

> [!WARNING]
> Ollama has no built-in authentication. Never expose port 11434 directly to the internet. / **У Ollama нет встроенной аутентификации — не выставляйте 11434 в интернет.**

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Models
tar czf /var/backups/ollama-models-$(date +%F).tar.gz -C /var/lib/ollama models
# Or ~/.ollama
tar czf /var/backups/ollama-$(date +%F).tar.gz -C "$HOME" .ollama
```

### Restore / Восстановление

```bash
systemctl stop ollama
tar xzf /var/backups/ollama-<DATE>.tar.gz -C /var/lib/ollama --strip-components=0
# Or extract to ~/.ollama
systemctl start ollama
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `connection refused` | Service down / wrong port | `systemctl status ollama` |
| OOM on large models | Model too big for RAM/VRAM | Use smaller quantized model |
| Slow on CPU | No GPU / small quant | Use GPU host or `:1b` models |
| CORS errors in browser | Origins not allowed | Set `OLLAMA_ORIGINS` |
| Model not found | Not pulled | `ollama pull <MODEL>` |
| GPU not used | No NVIDIA runtime | Install NVIDIA Container Toolkit |

```bash
systemctl status ollama
journalctl -u ollama -n 30
ollama ps
nvidia-smi
```

---

## Comparison Tables

### Local LLM runtimes / Локальные LLM-рантаймы

| Runtime | Best for | API |
| :--- | :--- | :--- |
| **Ollama** | Simplest local endpoint | OpenAI-compatible |
| **llama.cpp** | Minimal / portable | OpenAI-compatible via `llama serve` |
| **vLLM** | High throughput | OpenAI-compatible |
| **LocalAI** | Multi-modal | OpenAI/Anthropic-compatible |
| **LM Studio** | Desktop + `lms` CLI | OpenAI-compatible |

---

## Production Runbooks

### Runbook: Deploy Ollama for a team / Развёртывание Ollama для команды

1. Install Ollama; enable systemd / Установить Ollama; включить systemd
2. Pull production model(s) (e.g. llama3.2:8b) / Загрузить модели
3. Override OLLAMA_HOST if remote; prefer reverse proxy / Настроить доступ
4. Open firewall only behind proxy / Открыть порт только за прокси
5. Point Open WebUI or clients at endpoint / Подключить клиенты
6. Monitor GPU/CPU with nvidia-smi / Мониторить ресурсы
7. Document model list and quotas / Задокументировать модели и квоты

### Runbook: Rotate or update models / Обновление моделей

1. `ollama pull <NEW_MODEL>` / Загрузить новую модель
2. Test chat via API / Проверить chat через API
3. Update client configs to new model alias / Обновить конфиги клиентов
4. `ollama stop <OLD_MODEL>` — unload / Выгрузить старую модель
5. `ollama rm <OLD_MODEL>` if unused / Удалить если не нужна
6. Document change / Задокументировать изменение

---

## Documentation Links

- Ollama docs — https://docs.ollama.com/
- Ollama GitHub — https://github.com/ollama/ollama
- Ollama API — https://docs.ollama.com/api/
- Docker image — https://hub.docker.com/r/ollama/ollama
