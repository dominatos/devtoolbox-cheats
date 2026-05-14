---
Title: KUBECTL — Commands
Group: Kubernetes & Containers
Icon: ☸️
Order: 1
---

# ☸️ KUBECTL — Kubernetes CLI

**Description / Описание:**
`kubectl` is the official command-line tool for interacting with **Kubernetes** clusters. It communicates with the Kubernetes API server to manage cluster resources: pods, deployments, services, configmaps, secrets, nodes, and more. It supports declarative (`apply`) and imperative (`create`, `delete`) workflows, integrated RBAC checking, and extensive output formatting (JSON, YAML, JSONPath, custom-columns). `kubectl` is the primary tool for Kubernetes operators and developers.

> [!NOTE]
> **Current Status:** `kubectl` is maintained as part of the Kubernetes project and is the standard CLI for all Kubernetes distributions (vanilla K8s, K3s, EKS, GKE, AKS, OpenShift). Complementary tools include **k9s** (TUI), **Lens** (GUI), **Helm** (package management), and **Kustomize** (built-in template-free overlays). / **Текущий статус:** `kubectl` — стандартный CLI для всех дистрибутивов Kubernetes. Дополнительные инструменты: **k9s**, **Lens**, **Helm**, **Kustomize**.

> **Default Ports:** API Server: `6443` | Kubelet: `10250` | kube-proxy healthz: `10256` | etcd: `2379`/`2380`

---

## Table of Contents

- [Quick Reference](#quick-reference)
- [Contexts, Clusters, Namespaces](#contexts-clusters-namespaces)
- [Pods](#pods)
- [Deployments / ReplicaSets / StatefulSets](#deployments--replicasets--statefulsets)
- [Services / Ingress / Networking](#services--ingress--networking)
- [ConfigMaps & Secrets](#configmaps--secrets)
- [Storage (PV / PVC)](#storage-pv--pvc)
- [Nodes / Cluster](#nodes--cluster)
- [Metrics / Debug / Troubleshooting](#metrics--debug--troubleshooting)
- [YAML / Apply / Diff](#yaml--apply--diff)
- [RBAC / Security](#rbac--security)
- [Useful One-liners](#useful-one-liners)
- [Sysadmin Essentials](#sysadmin-essentials)
- [Documentation Links](#documentation-links)

---

## Quick Reference

```bash
kubectl config get-contexts && kubectl get ns   # Contexts & namespaces / Контексты и неймспейсы
kubectl get pods -A                             # All pods / Все pod-ы
kubectl get deploy,svc,ing -n demo              # Deploy/Svc/Ing in ns / Обзор в namespace
kubectl describe pod POD -n demo                # Describe pod / Детали pod-а
kubectl logs -f POD -n demo --tail=200          # Follow logs / Логи (последние 200)
kubectl exec -it POD -n demo -- /bin/sh         # Shell in container / Оболочка в контейнере
kubectl cp demo/POD:/path/in/pod ./local/       # Copy from pod / Копировать из pod-а
kubectl apply -f manifest.yaml                  # Apply manifests / Применить манифест
kubectl rollout restart deploy/myapp -n demo    # Restart deployment / Перезапуск деплоймента
kubectl scale deploy/myapp -n demo --replicas=3 # Scale to 3 / Масштаб до 3
kubectl port-forward deploy/myapp 8080:80 -n demo # Local 8080→svc 80 / Проброс портов
kubectl top pods -n demo                        # Pods CPU/mem / Ресурсы pod-ов
```

---

## Contexts, Clusters, Namespaces

### Context Management / Управление контекстами

```bash
kubectl config view                                   # Show kubeconfig / Показать kubeconfig
kubectl config get-contexts                           # List contexts / Список контекстов
kubectl config current-context                        # Current context / Текущий контекст
kubectl config use-context CONTEXT                    # Switch context / Переключить контекст
kubectl config set-context --current --namespace=ns   # Set default ns / Установить namespace по умолчанию
kubectl get ns                                        # List namespaces / Список namespace
kubectl get all -n kube-system                        # All objects in ns / Все объекты в namespace
```

---

## Pods

```bash
kubectl get pods                                      # List pods / Список pod-ов
kubectl get pods -A                                   # Pods in all ns / Pod-ы во всех namespace
kubectl get pods -o wide                              # Pods with nodes/IP / Pod-ы с node/IP
kubectl get pods -l app=myapp                         # Pods by label / Pod-ы по label
kubectl describe pod POD                              # Pod details / Детали pod-а
kubectl delete pod POD                                # Delete pod / Удалить pod
kubectl logs POD                                      # Pod logs / Логи pod-а
kubectl logs POD -c CONTAINER                         # Container logs / Логи контейнера
kubectl logs -f POD --tail=200                        # Follow logs / Следить за логами
kubectl exec -it POD -- /bin/sh                       # Shell in pod / Оболочка в pod-е
kubectl exec POD -- env                               # Show env vars / Переменные окружения
kubectl cp POD:/path ./local                          # Copy from pod / Копировать из pod-а
kubectl cp ./local POD:/path                          # Copy to pod / Копировать в pod
```

---

## Deployments / ReplicaSets / StatefulSets

```bash
kubectl get deploy                                    # List deployments / Список deployment
kubectl describe deploy APP                           # Deployment details / Детали deployment
kubectl rollout status deploy/APP                     # Rollout status / Статус обновления
kubectl rollout history deploy/APP                    # Rollout history / История rollout
kubectl rollout undo deploy/APP                       # Rollback last / Откат последнего
kubectl rollout undo deploy/APP --to-revision=2       # Rollback to revision / Откат к версии
kubectl scale deploy/APP --replicas=3                 # Scale deployment / Масштабировать
kubectl edit deploy/APP                               # Edit live / Редактировать на лету
kubectl set image deploy/APP c=img:tag                # Update image / Обновить image

kubectl get rs                                        # List ReplicaSets / Список ReplicaSet
kubectl get sts                                       # List StatefulSets / Список StatefulSet
kubectl delete sts APP                                # Delete StatefulSet / Удалить StatefulSet
```

---

## Services / Ingress / Networking

```bash
kubectl get svc                                       # List services / Список сервисов
kubectl describe svc APP                              # Service details / Детали сервиса
kubectl get ing                                       # List ingress / Список ingress
kubectl describe ing APP                              # Ingress details / Детали ingress
kubectl port-forward svc/APP 8080:80                  # Port forward svc / Проброс портов
kubectl port-forward pod/POD 8080:80                  # Port forward pod / Проброс портов pod-а
```

### Traefik IngressRoute (CRD) / Traefik IngressRoute

```bash
kubectl get crd | grep traefik                        # List CRD of Traefik / Список CRD Traefik
kubectl get ingressroutes.traefik.io -n default       # IngressRoute in default / IngressRoute в default
kubectl get ingressroutes.traefik.containo.us -A      # Alternative API group / Альтернативная группа API
kubectl describe ingressroute APP                     # IngressRoute details / Детали IngressRoute
kubectl get ingressroutes.traefik.io -n default -o yaml | grep -A3 host # Show host / Показать хост
kubectl get ingressroutes.traefik.io -n default -o jsonpath='{.items[0].spec.entryPoints}' # Show entryPoints / Показать entryPoints
```

---

## ConfigMaps & Secrets

```bash
kubectl get cm                                        # List ConfigMaps / Список ConfigMap
kubectl describe cm NAME                              # ConfigMap details / Детали ConfigMap
kubectl create cm NAME --from-file=file.conf          # CM from file / ConfigMap из файла
kubectl create cm NAME --from-literal=k=v             # CM from literal / ConfigMap из значения

kubectl get secret                                    # List secrets / Список Secret
kubectl describe secret NAME                          # Secret metadata / Метаданные Secret
kubectl get secret NAME -o yaml                       # Secret yaml / Secret в yaml
kubectl create secret generic NAME --from-literal=k=v # Create secret / Создать Secret
```

---

## Storage (PV / PVC)

```bash
kubectl get pv                                        # List PV / Список PersistentVolume
kubectl get pvc                                       # List PVC / Список PersistentVolumeClaim
kubectl describe pvc NAME                             # PVC details / Детали PVC
kubectl delete pvc NAME                               # Delete PVC / Удалить PVC
```

---

## Nodes / Cluster

```bash
kubectl get nodes                                     # List nodes / Список нод
kubectl describe node NODE                            # Node details / Детали ноды
kubectl cordon NODE                                   # Mark unschedulable / Запретить планирование
kubectl uncordon NODE                                 # Enable scheduling / Разрешить планирование
kubectl drain NODE --ignore-daemonsets                # Drain node / Освободить ноду
```

> [!CAUTION]
> `kubectl drain` evicts all pods from the node. Ensure sufficient capacity on other nodes before draining. / `kubectl drain` вытесняет все pod-ы с ноды. Убедитесь в достаточной ёмкости на других нодах.

---

## Metrics / Debug / Troubleshooting

```bash
kubectl top nodes                                     # Node CPU/mem / Ресурсы нод
kubectl top pods                                      # Pod CPU/mem / Ресурсы pod-ов
kubectl get events                                    # Cluster events / События кластера
kubectl get events --sort-by=.metadata.creationTimestamp # Events sorted / События по времени
kubectl auth can-i create pods                        # RBAC check / Проверка прав
kubectl explain pod.spec                              # Explain fields / Документация API
```

---

## YAML / Apply / Diff

```bash
kubectl apply -f file.yaml                            # Apply manifest / Применить манифест
kubectl apply -k ./dir                                # Apply kustomize / Применить kustomize
kubectl delete -f file.yaml                           # Delete by file / Удалить по файлу
kubectl diff -f file.yaml                             # Diff local vs cluster / Разница
kubectl get deploy APP -o yaml                        # Export yaml / Получить yaml
kubectl create deploy APP --image=nginx --dry-run=client -o yaml > app.yaml # Generate yaml / Сгенерировать yaml
```

---

## RBAC / Security

```bash
kubectl get sa                                        # ServiceAccounts / Сервисные аккаунты
kubectl get role,clusterrole                          # Roles / Роли
kubectl get rolebinding,clusterrolebinding            # RoleBindings / Привязки ролей
kubectl describe rolebinding NAME                     # RBAC details / Детали RBAC
```

---

## Useful One-liners

```bash
kubectl get pods -A | grep CrashLoop                  # Find crashing pods / Найти падающие pod-ы
kubectl delete pod -l app=myapp                       # Delete by label / Удалить по label
kubectl get pods -o json | jq '.items[].metadata.name'# Pods via jq / Pod-ы через jq
kubectl get pods --field-selector=status.phase=Running # Filter by field / Фильтр по полю
kubectl get deploy -A -o wide | grep -v "1/1"         # Find unhealthy deploys / Найти нездоровые deployment
```

---

## Sysadmin Essentials

### Kubeconfig & Authentication / Kubeconfig и аутентификация

```bash
~/.kube/config                                        # Default kubeconfig path / Путь kubeconfig по умолчанию
/etc/kubernetes/                                      # Kubernetes config dir / Директория конфигурации Kubernetes
export KUBECONFIG=/path/to/config                     # Set custom kubeconfig / Установить кастомный kubeconfig

# Verify certificate expiration / Проверка срока действия сертификата
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -noout -dates
```

> [!TIP]
> Very handy script for [GNOME Argos](https://github.com/p-e-w/argos) to switch contexts if you manage different clusters: [Kubernetes Config Switcher for Argos](https://github.com/dominatos/Kubernetes-Config-Switcher-for-Argos)

### API Server & Cluster Health / API сервер и здоровье кластера

```bash
kubectl cluster-info                                  # Cluster endpoints / Эндпоинты кластера
kubectl get componentstatuses                         # Component health / Здоровье компонентов
kubectl version --short                               # Client/server version / Версия клиент/сервер

# API server direct access / Прямой доступ к API серверу
kubectl proxy --port=8080                             # Start API proxy / Запустить прокси API
curl http://localhost:8080/api/v1/namespaces          # Access via proxy / Доступ через прокси
```

### Common Ports / Порты по умолчанию

| Port | Description (EN / RU) |
| :--- | :--- |
| **6443** | Kubernetes API Server / API сервер Kubernetes |
| **10250** | Kubelet API / API Kubelet |
| **10256** | kube-proxy healthz / Проверка здоровья kube-proxy |
| **2379** | etcd client / Клиент etcd |
| **2380** | etcd peer / Пир etcd |

### Resource Quotas & Limits / Квоты и лимиты ресурсов

```bash
kubectl get resourcequotas -A                         # All resource quotas / Все квоты ресурсов
kubectl describe quota -n default                     # Quota details / Детали квоты
kubectl get limitrange -A                             # Limit ranges / Диапазоны лимитов
```

### Troubleshooting Commands / Команды устранения неполадок

```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp' # Recent events / Последние события
kubectl describe node NODE | grep -A 5 Conditions    # Node conditions / Состояние ноды
kubectl get pods --all-namespaces -o wide | grep -v Running # Non-running pods / Незапущенные pod-ы

# Debug pod network / Отладка сети pod-а
kubectl run debug --rm -it --image=nicolaka/netshoot -- bash

# Check pod resource requests/limits / Проверка запросов и лимитов ресурсов
kubectl describe pod POD | grep -A 10 "Limits\|Requests"
```

---

## Documentation Links

- **Kubernetes Official Documentation:** [https://kubernetes.io/docs/](https://kubernetes.io/docs/)
- **kubectl Reference:** [https://kubernetes.io/docs/reference/kubectl/](https://kubernetes.io/docs/reference/kubectl/)
- **kubectl Cheat Sheet (Official):** [https://kubernetes.io/docs/reference/kubectl/cheatsheet/](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- **Kubernetes API Reference:** [https://kubernetes.io/docs/reference/kubernetes-api/](https://kubernetes.io/docs/reference/kubernetes-api/)
- **kubectl GitHub:** [https://github.com/kubernetes/kubectl](https://github.com/kubernetes/kubectl)
