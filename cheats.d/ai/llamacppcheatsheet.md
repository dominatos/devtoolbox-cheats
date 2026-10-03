---
Title: ⚡ llama.cpp — Inference Engine
Group: AI
Icon: ⚡
Order: 4
tags:
  - ai
  - llm
  - llama.cpp
  - inference
  - gguf
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

# ⚡ llama.cpp Cheatsheet

## Description

**llama.cpp** is a portable **LLM (and VLM) inference engine** in C/C++ on ggml. Provides CLI tools and `llama serve` — an OpenAI-compatible HTTP API server. GGUF quantization; backends for CUDA, Metal, Vulkan, SYCL, HIP, CPU. / **llama.cpp** — переносимый движок инференса LLM/VLM на C/C++ (ggml). CLI и `llama serve` — OpenAI-совместимый HTTP-сервер. GGUF; CUDA, Metal, Vulkan, SYCL, HIP, CPU.

**Common use cases / Типовые сценарии:**
- CPU/edge inference boxes / Инференс на CPU/edge
- Foundation under Ollama and many stacks / База под Ollama и другими стеками
- Self-hosted OpenAI-compatible API / Self-hosted OpenAI API
- Quantized models on modest hardware / Квантованные модели на скромном железе

**Status:** Very active (ggml-org/llama.cpp, MIT). Alternatives: **Ollama**, **vLLM**, **LocalAI**. / **Статус:** активно развивается; альтернативы — Ollama, vLLM, LocalAI.

**Paths:** GGUF model files; Docker under ggml-org.  
**Common port:** `8080` for `llama serve` (confirm with `--port`).

Cross-reference: [Ollama](ollamacheatsheet.md), [vLLM](vllmcheatsheet.md), [LocalAI](localaicheatsheet.md).

---

## Installation

### Install llama.cpp / Установка llama.cpp

```bash
# Official installer
curl -LsSf https://llama.app/install.sh | sh

# Package managers (varies by distro)
# Build from source also supported
```

```bash
llama --version
llama cli --help
```

### Docker / Docker

```bash
docker run -d --name llama-cpp \
  -p 8080:8080 \
  -v models:/models \
  ghcr.io/ggml-org/llama.cpp:full \
  --hf-repo ggml-org/Qwen3.5-0.8B-GGUF --hf-file model.gguf -c 4096 --host 0.0.0.0 --port 8080
```

---

## Configuration

### Run interactively / Интерактивный запуск

```bash
llama cli -hf ggml-org/Qwen3.5-0.8B-GGUF
# Or with local GGUF
llama cli -m /models/model.gguf -c 4096
```

### Serve OpenAI-compatible API / OpenAI-совместимый сервер

```bash
llama serve -hf ggml-org/Qwen3.5-0.8B-GGUF --host 0.0.0.0 --port 8080

# Local GGUF
llama serve -m /models/model.gguf --host 127.0.0.1 --port 8080 -c 8192
```

### Key flags / Ключевые флаги

| Flag | Purpose |
| :--- | :--- |
| `-m` / `--model` | Path to GGUF model |
| `-hf` | Download from Hugging Face |
| `-c` / `--ctx-size` | Context size |
| `--host` / `--port` | Bind address |
| `-ngl` | GPU layers |
| `--threads` | CPU threads |

---

## Core Management

### OpenAI-compatible API / OpenAI-совместимый API

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [{"role": "user", "content": "hi"}]
  }'

curl http://localhost:8080/v1/models
```

### Systemd unit / systemd unit

`/etc/systemd/system/llamacpp.service`

```bash
[Unit]
Description=llama.cpp server
After=network.target

[Service]
User=llm
ExecStart=/usr/local/bin/llama serve -m /var/lib/llama/models/model.gguf --host 127.0.0.1 --port 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable --now llamacpp
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u llamacpp --no-pager -n 50
journalctl -u llamacpp -f
```

### GPU layers / GPU-слои

```bash
# Use GPU when available
llama serve -m /models/model.gguf -ngl 99 --port 8080
```

### Logrotate / Ротация логов

`/etc/logrotate.d/llamacpp`

```bash
/var/log/llamacpp/*.log {
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

1. Bind to localhost unless remote API needed / Не выставляйте наружу без нужды
2. Put reverse proxy + auth in front / Прокси + аутентификация
3. Restrict model directory permissions / Ограничьте права на каталог моделей
4. Keep llama.cpp updated / Обновляйте llama.cpp
5. Monitor resource usage / Мониторьте ресурсы

```bash
# Default: bind 127.0.0.1
llama serve -m /models/model.gguf --host 127.0.0.1 --port 8080
```

> [!WARNING]
> `llama serve` has no built-in authentication. Never expose without a reverse proxy. / **У `llama serve` нет встроенной аутентификации.**

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- |
| Model file not found | Wrong path | Check `-m` path |
| OOM | Context too large | Lower `-c`; smaller quant |
| Slow on CPU | No GPU layers | Add `-ngl` if GPU present |
| Port in use | Conflict | Change `--port` |
| Bad GGUF | Corrupt download | Re-download model |

```bash
llama serve -m /models/model.gguf --port 8080 2>&1 | head -20
```

---

## Comparison Tables

### Inference engines / Движки инференса

| Engine | Best for | Notes |
| :--- | :--- | :--- |
| **llama.cpp** | Portable / CPU edge | Minimal deps, GGUF |
| **Ollama** | Simplest local runtime | Wrapper around llama.cpp |
| **vLLM** | GPU high throughput | PagedAttention |
| **LocalAI** | Multi-modal | Backend gallery |

---

## Production Runbooks

### Runbook: Deploy llama.cpp server / Развёртывание llama.cpp

1. Install llama.cpp / Установить
2. Download GGUF model; place in /var/lib/llama/models / Загрузить модель
3. Create systemd unit with host/port/model / Создать unit
4. Bind localhost; add reverse proxy for remote / Прокси для удалённого доступа
5. Start service; test /v1/chat/completions / Запустить; проверить
6. Document model and context size / Задокументировать модель и context

---

## Documentation Links

- llama.cpp GitHub — https://github.com/ggml-org/llama.cpp
- llama.app — https://llama.app
- Docker — https://github.com/ggml-org/llama.cpp/blob/master/docs/docker.md
