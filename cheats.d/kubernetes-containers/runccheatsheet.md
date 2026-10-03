---
Title: ⚙️ runc — OCI Runtime
Group: "Kubernetes & Containers"
Icon: ⚙️
Order: 21
tags:
  - containers
  - runc
  - oci
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
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# ⚙️ runc Cheatsheet

## Description

**runc** is a low-level **OCI (Open Container Initiative) runtime** that creates and runs containers according to the OCI Runtime Specification. It is the default runtime under **containerd** and **CRI-O**. / **runc** — низкоуровневый OCI-runtime, запускающий контейнеры по спецификации OCI. Является runtime по умолчанию для containerd и CRI-O.

**Common use cases / Типовые сценарии:**
- Debugging container start failures at runtime layer / Отладка сбоев запуска на уровне runtime
- Running OCI bundles manually for testing / Ручной запуск OCI-bundle для тестов
- Inspecting container state and config / Инспекция состояния и конфигурации
- Understanding cgroups/namespaces/seccomp mapping / Разбор cgroups/namespaces/seccomp

**Status:** Actively maintained (CNCF opencontainers/runc). Alternatives: **crun** (C implementation, faster, used by some CRI-O setups), **youki** (Rust), **gVisor/Kata** (sandboxed runtimes). / **Статус:** активно развивается; альтернативы — crun, youki, gVisor, Kata.

**Paths:** bundle layout `config.json` + `rootfs/`; state dir often `/run/runc/`; debug via `runc events` / `runc list`.

Cross-reference: [containerd](containerdcheatsheet.md), [CRI-O](criocheatsheet.md), [Docker](dockercheatsheet.md), [Podman](podmannerdctlcheatsheet.md).

---

## Installation

### Install runc / Установка runc

```bash
# Debian/Ubuntu
apt install runc

# RHEL/Rocky/Alma/Fedora
dnf install runc

# Official static binary
RUNC_VER=1.1.15
wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VER}/runc.amd64
install -m755 runc.amd64 /usr/local/bin/runc
```

```bash
runc --version
runc --help
```

---

## Configuration

### Main files / Основные файлы

`<BUNDLE>/config.json`

`<BUNDLE>/rootfs/`

`/run/runc/` (state, if default)

### Minimal OCI bundle / Минимальный OCI-bundle

`/var/lib/oci-bundles/demo/config.json`

```bash
{
  "ociVersion": "1.0.2",
  "process": {
    "terminal": false,
    "user": { "uid": 0, "gid": 0 },
    "args": ["sh", "-c", "echo hello from runc && sleep 5"],
    "env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],
    "cwd": "/"
  },
  "root": { "path": "rootfs", "readonly": false },
  "hostname": "runc-demo",
  "mounts": [
    { "destination": "/proc", "type": "proc", "source": "proc" },
    { "destination": "/dev", "type": "tmpfs", "source": "tmpfs", "options": ["nosuid","strictatime","mode=755","size=65536k"] },
    { "destination": "/dev/pts", "type": "devpts", "source": "devpts", "options": ["nosuid","noexec","newinstance","ptmxmode=0666","mode=0620"] },
    { "destination": "/sys", "type": "sysfs", "source": "sysfs", "options": ["nosuid","noexec","nodev","ro"] }
  ],
  "linux": {
    "namespaces": [
      { "type": "pid" },
      { "type": "network" },
      { "type": "ipc" },
      { "type": "uts" },
      { "type": "mount" }
    ]
  }
}
```

> [!NOTE]
> In production you almost never craft `config.json` by hand — containerd/CRI-O generate it. Manual bundles are for labs and debugging. / В проде `config.json` генерируется runtime-обёртками; ручные bundles — для лабораторий и отладки.

### Seccomp / Seccomp

```bash
# Default profile often shipped with containerd/docker
# /usr/share/containers/seccomp.json
# /usr/share/docker/seccomp/seccomp.json
```

---

## Core Management

### Run and manage / Запуск и управление

```bash
# Create container (detached) from bundle
cd /var/lib/oci-bundles/demo
runc create demo
runc start demo
runc list
runc state demo
runc kill demo KILL
runc delete demo

# Run one-shot
runc run demo
```

### Inspect / Инспекция

```bash
runc state demo
runc events demo
runc exec demo ps aux
runc exec -t -i demo /bin/sh
```

Sample `runc state`:

```json
{
  "ociVersion": "1.0.2",
  "id": "demo",
  "status": "running",
  "pid": 12345,
  "bundle": "/var/lib/oci-bundles/demo"
}
```

### Events stream / Поток событий

```bash
runc events demo | jq .
```

---

## Sysadmin Operations

### Service integration / Интеграция с сервисами

```bash
# Confirm runc is the runtime under containerd
containerd config default | grep -A5 runtimes
crictl info | jq '.config.runtimes'
```

### Logs / Логи

```bash
journalctl -u containerd --no-pager -n 50 | grep runc
```

> Note: runc itself is short-lived per container create/run — logs live in the parent runtime (containerd/CRI-O) and container stdout. / runc краткоживущий; логи — в containerd/CRI-O и stdout контейнера.

---

## Security

### Hardening / Ужесточение

1. Do not run untrusted OCI bundles as root / Не запускайте непроверенные bundles от root
2. Prefer containerd/CRI-O over raw runc in prod / Предпочитайте containerd/CRI-O в проде
3. Enable seccomp + namespaces in config.json / Включайте seccomp и namespaces
4. Keep runc updated (runc CVEs are high-impact) / Обновляйте runc
5. Use user namespaces where possible / Используйте user namespaces
6. Restrict who can invoke runc on a node / Ограничьте доступ к runc

```bash
# Verify no privileged container escape surface
runc spec --help
```

> [!WARNING]
> runc runs with high privileges by design. A misused bundle or vulnerable runc version can lead to node compromise. / runc работает с высокими привилегиями — ошибка bundle или уязвимость может привести к компрометации ноды.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `container does not exist` | Wrong id / already deleted | `runc list` |
| `permission denied` on state | Wrong state dir / namespaces | Check `/run/runc`, capabilities |
| Start fails immediately | Bad config.json / missing rootfs | Validate bundle layout |
| `no such file or directory` for args | Rootfs incomplete | Populate `rootfs/` correctly |
| Events stream empty | Container exited | Check parent runtime logs |

```bash
runc list
runc state demo
ls -la /var/lib/oci-bundles/demo
journalctl -u containerd -n 30
```

---

## Comparison Tables

### OCI runtimes / OCI-runtime

| Runtime | Language | Notes |
| :--- | :--- | :--- |
| **runc** | Go | Default for containerd/CRI-O |
| **crun** | C | Faster start, used by Podman/CRI-O option |
| **youki** | Rust | OCI-compliant alternative |
| **gVisor** | Go | Application kernel sandbox |
| **Kata** | Go/C | VM-based isolation |

---

## Production Runbooks

### Runbook: Validate OCI bundle / Проверка OCI-bundle

1. Create bundle directory with `config.json` + `rootfs/` / Создать структуру bundle
2. Populate minimal rootfs (busybox/static binary) / Положить минимальный rootfs
3. `runc validate` if supported; else dry-run create / Проверить конфигурацию
4. `runc create` + `runc start` in lab / Проверить запуск в лаборатории
5. `runc state` and `runc events` for liveness / Проверить состояние
6. Tear down with `kill` + `delete` / Очистить ресурсы

### Runbook: Runtime incident on k8s node / Инцидент runtime на ноде k8s

1. Check CRI socket: `crictl ps` / Проверить CRI
2. Confirm runc binary version / Проверить версию runc
3. Inspect failed pod: `crictl inspect` / Инспектировать под
4. Check containerd logs for runc errors / Проверить логи containerd
5. If runc CVE applies — patch before restart / Патчить runc до перезапуска
6. Recreate workloads; document root cause / Пересоздать рабочие нагрузки

---

## Documentation Links

- runc GitHub — https://github.com/opencontainers/runc
- OCI runtime spec — https://github.com/opencontainers/runtime-spec
- containerd runtimes — https://github.com/containerd/containerd/blob/main/docs/cri/config.md
- crun — https://github.com/containers/crun
- gVisor — https://gvisor.dev/
