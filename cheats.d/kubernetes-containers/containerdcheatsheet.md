---
Title: 🐳 containerd — Container Runtime
Group: "Kubernetes & Containers"
Icon: 🐳
Order: 20
tags:
  - containers
  - containerd
  - docker
  - kubernetes
  - runtime
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

# 🐳 containerd Cheatsheet

## Description

**containerd** is a core **container runtime** (CNCF) used by Kubernetes (via CRI), Docker Engine (as its runtime), and standalone deployments. It manages images, containers, and content storage. / **containerd** — ключевой runtime контейнеров (CNCF), используемый Kubernetes (CRI), Docker Engine и напрямую. Управляет образами, контейнерами и хранилищем контента.

**Common use cases / Типовые сценарии:**
- Kubernetes node runtime (CRI) / Runtime ноды Kubernetes
- Docker Engine backend / Бэкенд Docker Engine
- Image management without full Docker daemon / Управление образами без Docker daemon
- CRI-O/containerd alternatives in clusters / Выбор runtime в кластере

**Status:** Actively maintained (CNCF). Alternatives: **CRI-O** (K8s-focused), **Docker Engine** (product), **runc** (low-level OCI runtime under containerd). / **Статус:** активно развивается; альтернативы — CRI-O, Docker Engine.

**Default socket:** `/run/containerd/containerd.sock`.  
**Config:** `/etc/containerd/config.toml`.  
**Paths:** content store `/var/lib/containerd/io.containerd.content.v1.content`; snapshots under `/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs`.

Cross-reference: [Docker](dockercheatsheet.md), [Kubernetes](kubernetescheatsheet.md), [CRI-O](criocheatsheet.md), [runc](runccheatsheet.md), [Podman](podmancheatsheet.md).

---

## Installation

### Install containerd / Установка containerd

```bash
# Debian/Ubuntu (official package)
apt-get update
apt-get install -y containerd

# RHEL/Rocky/Alma/Fedora
dnf install containerd

# Manual install (Ubuntu)
CONTAINERD_VERSION=1.7.22
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
```

```bash
containerd --version
ctr version
```

### systemd service / Сервис systemd

```bash
# Package typically ships containerd.service
systemctl enable --now containerd
systemctl status containerd
```

### Generate default config / Генерация конфигурации

```bash
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
```

---

## Configuration

### Main files / Основные файлы

`/etc/containerd/config.toml`

`/etc/containerd/certs.d/` (registry mirrors, CRI)

`/etc/containerd/cri` (CRI plugins, older layouts)

### Key config.toml / Ключевые параметры config.toml

`/etc/containerd/config.toml`

```toml
version = 2

[plugins."io.containerd.grpc.v1.cri"]
  # pause image (align with your k8s version)
  sandbox_image = "registry.k8s.io/pause:3.9"
  # CRI plugin logging
  [plugins."io.containerd.grpc.v1.cri".containerd]
    default_runtime_name = "runc"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        SystemdCgroup = true   # required for kubeadm default

[plugins."io.containerd.snapshotter.v1.overlayfs"]
  # optional tuning

[plugins."io.containerd.cri.v1.image-streaming"]
  # enable if using streaming pull features
```

```bash
systemctl restart containerd
```

### Registry mirrors / Зеркала реестров

`/etc/containerd/certs.d/_default/hosts.toml`

```toml
server = "https://registry-1.docker.io"

[host."https://mirror.example.internal:5000"]
  capabilities = ["pull", "resolve"]
```

---

## Core Management

### ctr (CLI) / Клиент ctr

```bash
ctr version
ctr image ls
ctr image pull docker.io/library/nginx:alpine
ctr image tag nginx:alpine mirror.example/nginx:alpine
ctr image push mirror.example/nginx:alpine
ctr image rm docker.io/library/nginx:alpine
ctr image inspect docker.io/library/nginx:alpine

ctr run --rm docker.io/library/alpine:latest test1 uname -a
ctr container ls
ctr container kill test1
ctr container rm test1
ctr snapshot ls
```

### CRI via crictl / Через crictl (Kubernetes)

```bash
# Ensure crictl can find the socket
crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps
crictl images
crictl pull <IMAGE>
crictl inspect <CONTAINER_ID>
crictl logs <CONTAINER_ID>
crictl pods
```

### Docker Engine on containerd / Docker поверх containerd

```bash
# Docker Engine 23+ can use containerd as runtime
# Verify
docker info | grep -i runtime
docker info | grep -i containerd
```

---

## Sysadmin Operations

### Service health / Здоровье сервиса

```bash
systemctl status containerd
journalctl -u containerd --no-pager -n 50
ss -xp | grep containerd
```

### Disk usage / Использование диска

```bash
du -sh /var/lib/containerd
df -h /var/lib/containerd
# Prune images/containers as appropriate for your tooling
```

### Logrotate / Ротация логов

containerd typically logs to journal; keep journal retention configured.

```bash
journalctl -u containerd --since today | wc -l
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Bind containerd socket only to local/CRI needs / Не выставляйте сокет наружу
2. Use signed images + image pull policy / Используйте подписанные образы
3. Restrict registry mirrors to trusted sources / Доверяйте зеркалам реестров
4. Enable SystemdCgroup for Kubernetes consistency / Включите SystemdCgroup
5. Separate containerd from untrusted Docker socket users / Ограничьте доступ к сокету
6. Keep runc/containerd updated (CVEs) / Обновляйте containerd и runc
7. Use rootless where threat model allows / Rootless-режим при допустимости

```bash
# Socket permissions
ls -l /run/containerd/containerd.sock
# Usually root:root 660 — keep it that way
```

> [!WARNING]
> Anyone with access to `containerd.sock` (or equivalent CRI socket) can effectively run as root on the node. / Доступ к сокету containerd = root на ноде.

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/containerd-config-$(date +%F).tar.gz /etc/containerd
# For k8s nodes, also backup CRI certs/mirrors if customized
```

### Restore / Восстановление

```bash
systemctl stop containerd
tar xzf /var/backups/containerd-config-<DATE>.tar.gz -C /
systemctl start containerd
ctr version
```

> Note: image/content store is large and node-specific — for clusters, prefer rebuilding nodes over restoring full content stores. / Для кластеров предпочтительнее пересборка нод, чем полный restore content store.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `dial unix /run/containerd/containerd.sock` | containerd down | `systemctl start containerd` |
| CRI handshake errors | Wrong socket / CRI plugin | Check config.toml CRI section |
| Image pull failures | Registry auth / mirror | Check certs.d; `crictl pull` manually |
| OOM during pull | Disk/IO pressure | Check `df -h`; reduce concurrent pulls |
| Kubernetes node NotReady | CRI down / pause image | `crictl images`; check pause image |
| Overlay snapshotter errors | Kernel/overlay issues | Check dmesg; mount options |

```bash
systemctl status containerd
journalctl -u containerd -f
ctr version
crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
```

---

## Comparison Tables

### Container runtimes / Runtime контейнеров

| Runtime | Scope | Typical use |
| :--- | :--- | :--- |
| **containerd** | Image + container mgmt | K8s, Docker backend |
| **CRI-O** | K8s CRI runtime | Kubernetes-focused |
| **Docker Engine** | Full product | Dev / legacy prod |
| **Podman** | Daemonless CLI | Rootless / systemd units |
| **runc** | Low-level OCI | Under containerd/CRI-O |

---

## Production Runbooks

### Runbook: Kubernetes node with containerd / Нода Kubernetes на containerd

1. Install containerd + runc / Установить containerd и runc
2. Generate config.toml; set `SystemdCgroup = true` / Сгенерировать конфиг
3. Configure pause image matching cluster version / Настроить pause image
4. Open CRI socket for kubelet only / Ограничить доступ к сокету
5. `kubeadm join` or run kubelet / Присоединить ноду
6. Verify: `crictl ps`, `kubectl get nodes` / Проверить CRI и ноды
7. Add registry mirrors if offline / Добавить зеркала при офлайн-доступе

### Runbook: Image GC / Сборка мусора образов

1. Identify unused images (`ctr images`, `crictl images`) / Найти неиспользуемые
2. Confirm not referenced by running pods / Убедиться, что не используются
3. Remove with appropriate tool (`ctr image rm` / `crictl rmi`) / Удалить
4. Reclaim disk: check `du -sh /var/lib/containerd` / Освободить диск
5. Document policy (retention, GC cadence) / Зафиксировать политику

---

## Documentation Links

- containerd docs — https://containerd.io/docs/
- containerd GitHub — https://github.com/containerd/containerd
- CRI plugin — https://github.com/containerd/containerd/blob/main/docs/cri/config.md
- crictl — https://github.com/kubernetes-sigs/cri-tools
- Kubernetes container runtimes — https://kubernetes.io/docs/setup/production-environment/container-runtimes/
