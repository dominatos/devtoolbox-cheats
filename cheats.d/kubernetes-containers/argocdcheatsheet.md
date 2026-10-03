---
Title: 🚀 ArgoCD — GitOps Delivery
Group: "Kubernetes & Containers"
Icon: 🚀
Order: 22
tags:
  - kubernetes
  - gitops
  - argocd
  - delivery
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

# 🚀 ArgoCD Cheatsheet

## Description

**ArgoCD** is a declarative, **GitOps** continuous delivery tool for Kubernetes. Desired state lives in Git; ArgoCD continuously syncs clusters and visualizes drift. / **ArgoCD** — декларативный GitOps-инструмент доставки для Kubernetes. Желаемое состояние хранится в Git; ArgoCD синхронизирует кластеры и показывает дрейф.

**Common use cases / Типовые сценарии:**
- GitOps CD for multi-cluster environments / GitOps-CD для мультикластерных сред
- Application of Helm/Kustomize/JSONnet from Git / Применение Helm/Kustomize из Git
- Drift detection and auto-sync / Обнаружение дрейфа и auto-sync
- Progressive delivery with Argo Rollouts / Прогрессивная доставка через Argo Rollouts

**Status:** Actively maintained (CNCF Argo Project). Alternatives: **Flux** (lighter, more Kubernetes-native), **Spinnaker** (enterprise CD), **Jenkins X**, **Harness**. / **Статус:** активно развивается; альтернативы — Flux, Spinnaker, Jenkins X.

**Default ports:** `8080/tcp` (server UI/API, often behind reverse proxy), `9090-9091` (metrics).  
**Paths:** install manifests via Helm/`argocd` CLI; config `argocd-cm`, `argocd-rbac-cm`; secrets in `argocd-secret`.

Cross-reference: [Flux](fluxcheatsheet.md), [kubectl](kubectlcheatsheet.md), [Helm](helmcheatsheet.md), [Kustomize](kubectlkustomizecheatsheet.md).

---

## Installation

### Install ArgoCD CLI / Установка CLI

```bash
# Latest CLI
ARGOCD_VER=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VER}/argocd-linux-amd64
install -m755 argocd-linux-amd64 /usr/local/bin/argocd
argocd version --client
```

### Install ArgoCD in cluster / Установка в кластер

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
```

### Get initial admin password / Получение пароля admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

> [!WARNING]
> Change the initial admin password immediately and delete `argocd-initial-admin-secret`. / Немедленно смените пароль admin и удалите `argocd-initial-admin-secret`.

---

## Configuration

### Main files / Основные файлы

`argocd-cm` (ConfigMap)

`argocd-rbac-cm` (RBAC)

`argocd-secret` (admin password, repo creds)

`argocd-cmd-params-cm` (server flags)

### RBAC example / Пример RBAC

`argocd-rbac-cm`

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:deployers, applications, sync, <APP_NS>/<APP_NAME>, allow
    p, role:deployers, applications, get, <APP_NS>/<APP_NAME>, allow
    g, <USER_EMAIL>, role:deployers
  scopes: '[groups]'
```

### Server behind reverse proxy / Сервер за reverse proxy

`argocd-cmd-params-cm`

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  server.insecure: "true"
```

> Note: TLS termination is usually done by ingress; keep ArgoCD itself insecure only when behind trusted proxy. / TLS обычно завершается на ingress; `server.insecure` — только за доверенным прокси.

---

## Core Management

### CLI basics / Основы CLI

```bash
argocd login <ARGOCD_HOST> --grpc-web
argocd app list
argocd app get <APP_NAME>
argocd app diff <APP_NAME>
argocd app history <APP_NAME>
argocd app logs <APP_NAME>
argocd app sync <APP_NAME>
argocd app wait <APP_NAME> --health
argocd app rollback <APP_NAME> <HISTORY_ID>
argocd app delete <APP_NAME>
```

### Create application / Создание приложения

```bash
argocd app create <APP_NAME> \
  --repo https://git@github.com:<ORG>/<REPO>.git \
  --path deploy/overlays/<ENV> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace <TARGET_NS> \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Sync waves / Волны синхронизации

```bash
# Annotation on resources
# argocd.argoproj.io/sync-wave: "0"
# Order: lower waves sync first (e.g., CRDs before CRs)
```

---

## Sysadmin Operations

### Health and metrics / Здоровье и метрики

```bash
kubectl -n argocd get svc
curl -s http://<ARGOCD_HOST>:8080/healthz
argocd app list -o name | wc -l
```

### Logs / Логи

```bash
kubectl -n argocd logs deploy/argocd-server --tail=100
kubectl -n argocd logs deploy/argocd-repo-server --tail=50
```

### Logrotate / Ротация логов

ArgoCD components log to stdout → Kubernetes logging (rotate via cluster log pipeline). / ArgoCD пишет в stdout — ротация через кластерный pipeline логов.

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Change default admin password; remove initial secret / Смените admin-пароль
2. Enable SSO (OIDC/OAuth2) via `argocd-cm` / Включите SSO
3. Strict RBAC — deny-by-default / Включите deny-by-default RBAC
4. Restrict who can create Applications / Ограничьте право создания Application
5. Use repo credentials in secrets, not hardcoded / Учётные данные Git — в Secret
6. Network policies for argocd namespace / NetworkPolicy для argocd
7. Keep ArgoCD updated (API/auth CVEs) / Обновляйте ArgoCD
8. Audit syncs via Kubernetes audit + ArgoCD audit / Аудитируйте sync-события

```bash
# Example: restrict sync to deployers only
# policy.csv: p, role:deployers, applications, sync, <NS>/<APP>, allow
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# Export Application manifests (declarative)
kubectl get applications.argoproj.io -A -o yaml > /var/backups/argocd-apps-$(date +%F).yaml
kubectl get appprojects.argoproj.io -A -o yaml > /var/backups/argocd-projects-$(date +%F).yaml
```

### Restore / Восстановление

```bash
kubectl apply -f /var/backups/argocd-apps-<DATE>.yaml
kubectl apply -f /var/backups/argocd-projects-<DATE>.yaml
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| App `Unknown` / `Missing` | Manifest path wrong | `argocd app get`; check repo path |
| Sync fails RBAC | ArgoCD SA lacks rights | Bind Role/ClusterRole to SA |
| Repo connection failed | SSH key / URL | Update repo secret |
| UI login fails | OIDC / password | Check `argocd-cm`, Dex config |
| Resource pruning removed too much | auto-prune + bad path | Review diff before re-enable prune |

```bash
argocd app get <APP_NAME> -o yaml | head -80
argocd app logs <APP_NAME>
kubectl -n argocd get events --sort-by=.lastTimestamp | tail
```

---

## Comparison Tables

### GitOps CD tools / GitOps CD инструменты

| Tool | Model | Best for |
| :--- | :--- | :--- |
| **ArgoCD** | UI + API, multi-tenancy | Enterprise GitOps UX |
| **Flux** | K8s-native controllers | Lightweight, ecosystem fit |
| **Spinnaker** | Pipeline-centric | Complex CD + approvals |
| **Harness** | SaaS enterprise | Managed CD platform |

---

## Production Runbooks

### Runbook: Promote release to production / Промоушен релиза в production

1. Tag release in Git / Поставить тег в Git
2. Update prod overlay to new tag / Обновить prod overlay
3. Open PR; require review / Открыть PR с ревью
4. Merge; wait for ArgoCD sync / Слить и дождаться sync
5. Verify health: `argocd app wait --health` / Проверить здоровье
6. Watch logs/metrics for regressions / Мониторить регрессии
7. Rollback plan: revert Git commit / План отката — revert коммита

### Runbook: Incident — bad sync removed workload / Инцидент — синхронизация удалила workload

1. Stop auto-sync if needed (`argocd app set --sync-policy none`) / Остановить auto-sync
2. Identify last good history ID: `argocd app history` / Найти последний good-состояние
3. `argocd app rollback <APP> <ID>` / Выполнить откат
4. Or revert Git and sync / Или revert в Git и sync
5. Re-enable auto-sync after validation / Включить auto-sync после проверки
6. Capture diffs for postmortem / Сохранить диффы для постмортема

---

## Documentation Links

- ArgoCD docs — https://argo-cd.readthedocs.io/
- Argo CD GitHub — https://github.com/argoproj/argo-cd
- Argo Rollouts — https://argoproj.github.io/rollouts/
- GitOps principles — https://opengitops.dev/
