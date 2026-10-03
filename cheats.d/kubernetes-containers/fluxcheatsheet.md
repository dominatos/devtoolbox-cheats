---
Title: 🌊 Flux — GitOps Controllers
Group: "Kubernetes & Containers"
Icon: 🌊
Order: 23
tags:
  - kubernetes
  - gitops
  - flux
  - controllers
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

# 🌊 Flux Cheatsheet

## Description

**Flux** is a set of Kubernetes controllers for **GitOps** (CNCF). It continuously reconciles cluster state with Git sources (Kustomization, HelmRelease, ImageRepository, ImageUpdateAutomation, etc.). / **Flux** — набор контроллеров Kubernetes для GitOps (CNCF). Непрерывно сверяет состояние кластера с Git-источниками.

**Common use cases / Типовые сценарии:**
- Lightweight GitOps without a separate CD UI / Лёгкий GitOps без отдельного CD UI
- Multi-tenancy via Kustomization namespaces / Мультитенантность через Kustomization
- Image update automation / Автообновление образов
- Helm chart delivery via HelmRelease / Доставка Helm-чартов через HelmRelease

**Status:** Actively maintained (CNCF Flux). Alternatives: **ArgoCD** (UI-centric), **Spinnaker**, **Jenkins X**. / **Статус:** активно развивается; альтернативы — ArgoCD, Spinnaker.

**Paths:** components via `flux bootstrap`; CRDs in `flux-system` namespace; sources in `flux-system`.

Cross-reference: [ArgoCD](argocdcheatsheet.md), [kubectl](kubectlcheatsheet.md), [Helm](helmcheatsheet.md), [Kustomize](kubectlkustomizecheatsheet.md).

---

## Installation

### Install Flux CLI / Установка CLI

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version
```

### Bootstrap GitOps / Бутстрап GitOps

```bash
flux bootstrap github \
  --owner=<ORG> \
  --repository=<REPO> \
  --branch=main \
  --path=clusters/<ENV> \
  --personal
```

```bash
flux check
kubectl get deploy -n flux-system
```

---

## Configuration

### Main files / Основные файлы

`clusters/<ENV>/flux-system/gotk-components.yaml`

`clusters/<ENV>/flux-system/gotk-sync.yaml`

`clusters/<ENV>/apps.yaml`

`apps/<APP>/kustomization.yaml`

`apps/<APP>/helmrelease.yaml`

### Kustomization / Kustomization

`clusters/<ENV>/apps.yaml`

```bash
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 5m
  path: ./apps/<ENV>
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: <TARGET_NS>
```

### HelmRelease / HelmRelease

`apps/<APP>/helmrelease.yaml`

```bash
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <APP_NAME>
  namespace: <NS>
spec:
  interval: 10m
  chart:
    spec:
      chart: <CHART>
      sourceRef:
        kind: HelmRepository
        name: <REPO_NAME>
  values:
    replicaCount: 2
```

---

## Core Management

### Flux CLI / CLI Flux

```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
flux get images all -A
flux reconcile kustomization apps
flux reconcile source git flux-system
flux suspend kustomization apps
flux resume kustomization apps
flux delete kustomization apps
```

### Diff and logs / Дифф и логи

```bash
flux diff kustomization apps
flux logs --follow
flux stats
```

---

## Sysadmin Operations

### Status / Статус

```bash
flux check
flux get all -A
kubectl -n flux-system get pods
```

### Logs / Логи

```bash
kubectl -n flux-system logs deploy/source-controller --tail=50
kubectl -n flux-system logs deploy/kustomize-controller --tail=50
kubectl -n flux-system logs deploy/helm-controller --tail=50
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Bootstrap with least-privilege Git tokens / Используйте минимальные Git-токены
2. Separate repositories/branches per environment per tenancy / Разделяйте репозитории по окружениям
3. Enable image verification (cosign/notation) where required / Верифицируйте образы
4. Restrict who can mutate flux-system / Ограничьте доступ к flux-system
5. Keep Flux components updated / Обновляйте компоненты Flux
6. Review prune behaviour before enabling auto-prune / Проверяйте prune перед auto-prune

```bash
flux check --kubernetes-version
```

> [!WARNING]
> `prune: true` deletes resources removed from Git. Always review diffs before enabling on production. / **`prune: true` удаляет ресурсы, исчезнувшие из Git** — проверяйте диффы в проде.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Kustomization not ready | Source not synced | `flux reconcile source git flux-system` |
| HelmRelease fails | Chart/repo missing | Check HelmRepository |
| Image automation stuck | Policy/registry auth | Check ImageRepository secret |
| No events | Controller down | `kubectl -n flux-system get pods` |
| Prune deleted needed resource | Git path drift | Restore in Git; suspend prune temporarily |

```bash
flux get kustomizations -A
flux logs --level=error
kubectl -n flux-system get events --sort-by=.lastTimestamp | tail
```

---

## Comparison Tables

### GitOps CD tools / GitOps CD инструменты

| Tool | Model | Best for |
| :--- | :--- | :--- |
| **Flux** | Controllers, K8s-native | Lightweight, multi-tenancy |
| **ArgoCD** | UI + API | Enterprise UX, dashboards |
| **Spinnaker** | Pipeline-centric | Complex CD + approvals |
| **Jenkins X** | CI/CD pipelines | Jenkins-style workflows |

---

## Production Runbooks

### Runbook: New app via Flux / Новое приложение через Flux

1. Create app manifests in Git path / Создать манифесты в Git
2. Add Kustomization (or HelmRelease) resource / Добавить Kustomization/HelmRelease
3. Commit + push to flux-tracked branch / Закоммитить и запушить
4. `flux reconcile kustomization apps` / Принудительно сверить
5. Verify workload: `kubectl get deploy -n <NS>` / Проверить workload
6. Enable auto-sync only after health check / Включить auto-sync после проверки

### Runbook: Suspend sync during incident / Приостановка sync при инциденте

1. Identify failing Kustomization/HelmRelease / Определить проблемный ресурс
2. `flux suspend kustomization <NAME>` / Приостановить
3. Mitigate on cluster (manual apply if needed) / Примитить на кластере
4. Fix Git source / Исправить Git-источник
5. `flux resume kustomization <NAME>` / Возобновить
6. Confirm ready state / Убедиться в Ready

---

## Documentation Links

- Flux docs — https://fluxcd.io/docs/
- Flux GitHub — https://github.com/fluxcd/flux2
- Kustomize controller — https://fluxcd.io/docs/components/kustomize/
- Helm controller — https://fluxcd.io/docs/components/helm/
- Image automation — https://fluxcd.io/docs/components/image/automation/
