---
Title: 🚀 vLLM — LLM Serving Engine
Group: AI
Icon: 🚀
Order: 3
tags:
  - ai
  - llm
  - vllm
  - inference
  - gpu
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

# 🚀 vLLM Cheatsheet

## Description

**vLLM** is a high-throughput **LLM inference and serving engine** (PagedAttention lineage). Provides offline batch and an online OpenAI-compatible server. Multi-backend: CUDA, ROCm, XPU, TPU, Apple Silicon. / **vLLM** — высокопроизводительный движок инференса LLM. Offline-batch и online OpenAI-совместимый сервер. Мультибэкенды: CUDA, ROCm, XPU, TPU, Apple Silicon.

**Common use cases / Типовые сценарии:**
- Production LLM API for teams/clusters / Production LLM API для команд
- High-concurrency chat completion / Высокая конкурентность chat completion
- Drop-in OpenAI-compatible endpoint / Замена OpenAI API
- GPU cluster inference / Инференс на GPU-кластере

**Status:** Very active (vllm-project/vllm). Alternatives: **TGI**, **TensorRT-LLM**, **llama.cpp server**, **Ollama**. / **Статус:** активно развивается; альтернативы — TGI, TensorRT-LLM, llama.cpp, Ollama.

**Default port:** `8000/tcp` (OpenAI `/v1/*`).  
**Docker image:** `vllm/vllm-openai`.  
**API key:** `VLLM_API_KEY` or `--api-key`.

Cross-reference: [Ollama](ollamacheatsheet.md), [llama.cpp](llamacppcheatsheet.md), [LiteLLM](litellmcheatsheet.md), [NVIDIA Container Toolkit](nvidiacontainertoolkitcheatsheet.md).

---

## Installation

### Install vLLM / Установка vLLM

```bash
# Recommended: uv
uv venv --python 3.12 --seed
source .venv/bin/activate
uv pip install vllm --torch-backend=auto

# pip (heavier)
pip install vllm
```

```bash
vllm --version
```

### Docker / Docker

```bash
docker run -d --name vllm \
  --gpus all \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  vllm/vllm-openai \
  --model Qwen/Qwen2.5-1.5B-Instruct
```

---

## Configuration

### Serve a model / Запуск модели

```bash
vllm serve Qwen/Qwen2.5-1.5B-Instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key <SECRET_KEY>

# Or env
export VLLM_API_KEY=<SECRET_KEY>
vllm serve meta-llama/Llama-3.1-8B-Instruct
```

### Key flags / Ключевые флаги

| Flag | Purpose |
| :--- | :--- |
| `--model` | Model id (HF hub or local path) |
| `--host` / `--port` | Bind address |
| `--api-key` | Require API key |
| `--gpu-memory-utilization` | GPU mem fraction |
| `--max-model-len` | Context length |
| `--tensor-parallel-size` | TP across GPUs |
| `--dtype` | Computation dtype |

---

## Core Management

### OpenAI-compatible API / OpenAI-совместимый API

```bash
# List models
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer <SECRET_KEY>"

# Chat completion
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <SECRET_KEY>" \
  -d '{
    "model": "Qwen/Qwen2.5-1.5B-Instruct",
    "messages": [{"role": "user", "content": "hi"}]
  }'
```

### Systemd unit / systemd unit

`/etc/systemd/system/vllm.service`

```bash
[Unit]
Description=vLLM OpenAI server
After=network.target

[Service]
User=llm
WorkingDirectory=/opt/vllm
Environment="VLLM_API_KEY=<SECRET_KEY>"
ExecStart=/opt/vllm/.venv/bin/vllm serve Qwen/Qwen2.5-1.5B-Instruct --host 0.0.0.0 --port 8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable --now vllm
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u vllm --no-pager -n 50
journalctl -u vllm -f
```

### GPU monitoring / Мониторинг GPU

```bash
nvidia-smi
watch -n 1 nvidia-smi
```

### Logrotate / Ротация логов

`/etc/logrotate.d/vllm`

```bash
/var/log/vllm/*.log {
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

1. Always set `--api-key` or `VLLM_API_KEY` in production / Всегда задавайте API key
2. Bind behind reverse proxy / Проксируйте через reverse proxy
3. Restrict filesystem via systemd sandbox / Ограничьте ФС через systemd
4. Monitor GPU memory / Мониторьте GPU memory
5. Keep vLLM and torch updated / Обновляйте vLLM и torch
6. Use private HF token if model gated / Используйте HF token для gated-моделей

```bash
# Example: nginx proxy + API key header
# proxy_pass http://127.0.0.1:8000;
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| CUDA OOM | Model too large | Smaller model; lower `--max-model-len` |
| Port in use | Another service | Change `--port` |
| 401 Unauthorized | Wrong/missing API key | Check `VLLM_API_KEY` |
| Slow first request | Model load | Wait; check logs |
| GPU not used | No CUDA / wrong torch | Install CUDA torch; check nvidia-smi |

```bash
journalctl -u vllm -n 40
nvidia-smi
curl -s http://localhost:8000/v1/models
```

---

## Comparison Tables

### LLM serving engines / Движки LLM-serving

| Engine | Best for | API |
| :--- | :--- | :--- |
| **vLLM** | High throughput GPU serving | OpenAI-compatible |
| **Ollama** | Simplest local runtime | OpenAI-compatible |
| **llama.cpp** | Portable / CPU edge | OpenAI via `llama serve` |
| **TGI** | Production HF stack | OpenAI-compatible |
| **LocalAI** | Multi-modal gateway | OpenAI/Anthropic |

---

## Production Runbooks

### Runbook: Production vLLM endpoint / Production vLLM

1. Provision GPU host; install NVIDIA drivers / Подготовить GPU-хост
2. Install vLLM (uv/pip) or Docker image / Установить vLLM
3. Serve model with API key and host/port / Запустить serve
4. Put nginx reverse proxy + TLS in front / Прокси + TLS
5. Create systemd unit; enable / Создать systemd unit
6. Monitor GPU and request latency / Мониторить GPU и latency
7. Document model id and capacity limits / Задокументировать модель и лимиты

### Runbook: API key rotation / Ротация API key

1. Generate new key / Сгенерировать новый ключ
2. Update VLLM_API_KEY; restart vllm / Обновить и перезапустить
3. Update clients / Обновить клиенты
4. Verify 401 on old key / Проверить отказ старого ключа
5. Document in secret manager / Задокументировать в vault

---

## Documentation Links

- vLLM docs — https://docs.vllm.ai/
- vLLM quickstart — https://docs.vllm.ai/en/latest/getting_started/quickstart.html
- vLLM GitHub — https://github.com/vllm-project/vllm
