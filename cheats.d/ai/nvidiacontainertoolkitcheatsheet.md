---
Title: 🖥️ NVIDIA Container Toolkit
Group: AI
Icon: 🖥️
Order: 8
tags:
  - ai
  - gpu
  - nvidia
  - docker
  - containerd
  - cuda
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

# 🖥️ NVIDIA Container Toolkit Cheatsheet

## Description

**NVIDIA Container Toolkit** provides libraries and utilities to build and run **GPU-accelerated containers**: NVIDIA Container Runtime, `nvidia-ctk` CLI, CDI hooks, `nvidia-container-runtime-hook`, `nvidia-container-cli`. Required for Ollama, vLLM, LocalAI, and any GPU AI runtime in Docker/Kubernetes. / **NVIDIA Container Toolkit** — библиотеки и утилиты для GPU-контейнеров: runtime, `nvidia-ctk`, CDI hooks. Обязателен для Ollama, vLLM, LocalAI и любого GPU AI-runtime в Docker/K8s.

**Common use cases / Типовые сценарии:**
- GPU access inside Docker containers / GPU-доступ в Docker-контейнерах
- GPU pods on Kubernetes / GPU-поды в Kubernetes
- AI inference containers (Ollama/vLLM/LocalAI) / AI-inference-контейнеры
- CUDA workloads in CI/CD / CUDA-workloads в CI/CD

**Status:** Actively maintained by NVIDIA. Alternatives: **AMD ROCm container stack** (different toolchain). / **Статус:** активно поддерживается NVIDIA; альтернатива — ROCm (другой стек).

**Components:** `nvidia-smi` (driver), `nvidia-ctk`, runtime hook, CDI (`nvidia-cdi-hook`).  
**Integrations:** Docker, containerd, Kubernetes.

Cross-reference: [Ollama](ollamacheatsheet.md), [vLLM](vllmcheatsheet.md), [LocalAI](localaicheatsheet.md), [containerd](../kubernetes-containers/containerdcheatsheet.md), [Docker](../kubernetes-containers/dockercheatsheet.md).

---

## Installation

### Prerequisites / Предварительные требования

```bash
# NVIDIA driver must be installed first
nvidia-smi
```

### Install toolkit / Установка toolkit

```bash
# Follow NVIDIA install guide for your distro
# Debian/Ubuntu example (see docs for current repo setup)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# RHEL/Rocky/Alma
dnf install nvidia-container-toolkit
```

```bash
nvidia-ctk --version
```

### Configure runtime / Настройка runtime

```bash
# Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# containerd
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd
```

---

## Configuration

### Docker GPU test / Тест GPU в Docker

```bash
docker run --gpus all nvidia/cuda:12.x-base-ubuntu22.04 nvidia-smi
```

### CDI / CDI

```bash
# Modern path: Container Device Interface
sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
```

### Kubernetes / Kubernetes

```bash
# GPU device plugin typically installed via Helm/manifests
# See NVIDIA GPU Operator docs for full stack
```

---

## Core Management

### Verify GPU in containers / Проверка GPU в контейнерах

```bash
docker run --rm --gpus all nvidia/cuda:12.x-base-ubuntu22.04 nvidia-smi
# Ollama
docker run --rm --gpus all ollama/ollama nvidia-smi
# vLLM
docker run --rm --gpus all vllm/vllm-openai nvidia-smi
```

### nvidia-ctk CLI / nvidia-ctk CLI

```bash
nvidia-ctk --version
nvidia-ctk runtime configure --runtime=docker
nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml
```

---

## Sysadmin Operations

### Driver and toolkit versions / Версии драйвера и toolkit

```bash
nvidia-smi
nvidia-ctk --version
dpkg -l | grep nvidia-container   # Debian
rpm -qa | grep nvidia-container   # RHEL
```

### Logs / Логи

```bash
journalctl -u docker --no-pager -n 50
journalctl -u containerd --no-pager -n 50
# Docker daemon logs for runtime errors
```

### Logrotate / Ротация логов

`/etc/logrotate.d/nvidia-container`

```bash
/var/log/nvidia-container-runtime/*.log {
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

1. Keep NVIDIA drivers patched / Обновляйте драйверы
2. Keep container toolkit updated / Обновляйте toolkit
3. Restrict who can run GPU containers / Ограничьте доступ к GPU-контейнерам
4. Prefer rootless/containerd CDI where possible / Предпочитайте CDI
5. Monitor GPU usage per container / Мониторьте GPU по контейнерам
6. Do not expose GPU hosts publicly / Не выставляйте GPU-хосты наружу

```bash
# nvidia-smi for usage monitoring
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `could not select device driver` | Runtime not configured | `nvidia-ctk runtime configure` |
| GPU not visible in container | Hook/runtime missing | Restart docker/containerd |
| Driver/toolkit mismatch | Version skew | Align driver + toolkit |
| Permission denied | cgroup/device rules | Check runtime config |
| Kubernetes GPU pending | No device plugin | Install GPU operator/plugin |

```bash
nvidia-smi
nvidia-ctk --version
docker info | grep -i nvidia
docker run --rm --gpus all nvidia/cuda:12.x-base-ubuntu22.04 nvidia-smi
```

---

## Comparison Tables

### GPU container stacks / GPU-контейнерные стеки

| Stack | Vendor | Notes |
| :--- | :--- | :--- |
| **NVIDIA Container Toolkit** | NVIDIA | CUDA, wide ecosystem |
| **ROCm container stack** | AMD | ROCm toolchain |
| **Intel oneAPI / SYCL** | Intel | XPU path |

---

## Production Runbooks

### Runbook: Enable GPU for Docker AI stack / Включение GPU для Docker AI

1. Install NVIDIA driver; verify `nvidia-smi` / Установить драйвер
2. Install NVIDIA Container Toolkit / Установить toolkit
3. `nvidia-ctk runtime configure --runtime=docker` / Настроить runtime
4. Restart Docker / Перезапустить Docker
5. Test: `docker run --gpus all ... nvidia-smi` / Проверить
6. Deploy Ollama/vLLM/LocalAI with `--gpus all` / Развернуть AI-runtime
7. Document driver/toolkit versions / Задокументировать версии

### Runbook: Driver upgrade / Обновление драйвера

1. Schedule maintenance window / Окно обслуживания
2. Stop GPU workloads / Остановить GPU-нагрузки
3. Upgrade NVIDIA driver per distro docs / Обновить драйвер
4. Reboot if required / Перезагрузить при необходимости
5. Verify `nvidia-smi` / Проверить
6. Re-test GPU containers / Протестировать контейнеры
7. Document new versions / Задокументировать версии

---

## Documentation Links

- NVIDIA Container Toolkit — https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html
- GPU Operator — https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html
- CDI — https://github.com/NVIDIA/nvidia-container-toolkit
