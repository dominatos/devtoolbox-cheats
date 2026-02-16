Title: ☸️ KUBECTL — Commands
Group: Kubernetes & Containers
Icon: ☸️
Order: 1

## Table of Contents
- [Quick Reference](#quick-reference)
- [Contexts, Clusters, Namespaces](#-контексты-кластеры-неймспейсы)
- [Pods](#-pods)
- [Deployments / ReplicaSets / StatefulSets](#-deployments--replicasets--statefulsets)
- [Services / Ingress / Networking](#-services--ingress--networking)
- [ConfigMaps & Secrets](#-configmaps--secrets)
- [Storage (PV / PVC)](#-storage-pv--pvc)
- [Nodes / Cluster](#-nodes--cluster)
- [Metrics / Debug / Troubleshooting](#-metrics--debug--troubleshooting)
- [YAML / Apply / Diff](#-yaml--apply--diff)
- [RBAC / Security](#-rbac--security)
- [Useful One-liners](#-полезные-one-liners)
- [Sysadmin Essentials](#-sysadmin-essentials)

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

## 🔧 Контексты, кластеры, неймспейсы

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

## 📦 Pods

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

## 🚀 Deployments / ReplicaSets / StatefulSets

```bash
kubectl get deploy                                    # List deployments / Список deployment
kubectl describe deploy APP                           # Deployment details / Детали deployment
kubectl rollout status deploy/APP                     # Rollout status / Статус обновления
kubectl rollout history deploy/APP                    # Rollout history / История rollout
kubectl rollout undo deploy/APP                       # Rollback last / Откат последнего
kubectl rollout history deploy/APP                    # Rollout history / История rollout   
kubectl rollout undo deploy/APP --to-revision=2       # Rollback to revision / Откат к версии
kubectl scale deploy/APP --replicas=3                 # Scale deployment / Масштабировать
kubectl edit deploy/APP                               # Edit live / Редактировать на лету
kubectl set image deploy/APP c=img:tag                # Update image / Обновить image

kubectl get rs                                        # List ReplicaSets / Список ReplicaSet
kubectl get sts                                       # List StatefulSets / Список StatefulSet
kubectl delete sts APP                                # Delete StatefulSet / Удалить StatefulSet
```

---

## 🌐 Services / Ingress / Networking

```bash
kubectl get svc                                       # List services / Список сервисов
kubectl describe svc APP                              # Service details / Детали сервиса
kubectl get ing                                       # List ingress / Список ingress
kubectl describe ing APP                              # Ingress details / Детали ingress
kubectl get crd | grep traefik                        # List crd of traefik / Список crd traefik
kubectl get ingressroutes.traefik.io -n default     # IngressRoute in default / IngressRoute в default
kubectl get ingressroutes.traefik.containo.us -A    # Alternative group / Альтернативная группа
kubectl describe ingressroute wordpress-https -n default  # IngressRoute details / Детали IngressRoute
kubectl get ingressroutes.traefik.io -n default -o yaml | grep -A3 host # Show host from IngressRoute / Показать хост из IngressRoute
kubectl get ingressroutes.traefik.io -n default -o jsonpath='{.items[0].spec.entryPoints}' # Show entryPoints / Показать entryPoints
kubectl describe ingressroute APP                     # IngressRoute details / Детали IngressRoute
kubectl port-forward svc/APP 8080:80                  # Port forward svc / Проброс портов
kubectl port-forward pod/POD 8080:80                  # Port forward pod / Проброс портов pod-а

```

---

## 📄 ConfigMaps & Secrets

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

## 💾 Storage (PV / PVC)

```bash
kubectl get pv                                        # List PV / Список PersistentVolume
kubectl get pvc                                       # List PVC / Список PersistentVolumeClaim
kubectl describe pvc NAME                             # PVC details / Детали PVC
kubectl delete pvc NAME                               # Delete PVC / Удалить PVC
```

---

## 🧠 Nodes / Cluster

```bash
kubectl get nodes                                     # List nodes / Список нод
kubectl describe node NODE                            # Node details / Детали ноды
kubectl cordon NODE                                   # Mark unschedulable / Запретить планирование
kubectl uncordon NODE                                 # Enable scheduling / Разрешить планирование
kubectl drain NODE --ignore-daemonsets                # Drain node / Освободить ноду
```

---

## 📊 Metrics / Debug / Troubleshooting

```bash
kubectl top nodes                                     # Node CPU/mem / Ресурсы нод
kubectl top pods                                      # Pod CPU/mem / Ресурсы pod-ов
kubectl get events                                    # Cluster events / События кластера
kubectl get events --sort-by=.metadata.creationTimestamp # Events sorted / События по времени
kubectl auth can-i create pods                        # RBAC check / Проверка прав
kubectl explain pod.spec                              # Explain fields / Документация API
```

---

## 📁 YAML / Apply / Diff

```bash
kubectl apply -f file.yaml                            # Apply manifest / Применить манифест
kubectl apply -k ./dir                                # Apply kustomize / Применить kustomize
kubectl delete -f file.yaml                           # Delete by file / Удалить по файлу
kubectl diff -f file.yaml                             # Diff local vs cluster / Разница
kubectl get deploy APP -o yaml                        # Export yaml / Получить yaml
kubectl create deploy APP --image=nginx --dry-run=client -o yaml > app.yaml # Generate yaml / Сгенерировать yaml
```

---

## 🔐 RBAC / Security

```bash
kubectl get sa                                        # ServiceAccounts / Сервисные аккаунты
kubectl get role,clusterrole                          # Roles / Роли
kubectl get rolebinding,clusterrolebinding            # RoleBindings / Привязки ролей
kubectl describe rolebinding NAME                     # RBAC details / Детали RBAC
```

---

## 🧪 Полезные one-liners

```bash
kubectl get pods -A | grep CrashLoop                  # Find crashing pods / Найти падающие pod-ы
kubectl delete pod -l app=myapp                       # Delete by label / Удалить по label
kubectl get pods -o json | jq '.items[].metadata.name'# Pods via jq / Pod-ы через jq
kubectl get pods --field-selector=status.phase=Running # Filter by field / Фильтр по полю
kubectl get deploy -A -o wide | grep -v "1/1"         # Find unhealthy deploys / Найти нездоровые deployment
```

---

## 🔧 Sysadmin Essentials

### Kubeconfig & Authentication

```bash
~/.kube/config                                        # Default kubeconfig path / Путь kubeconfig по умолчанию
/etc/kubernetes/                                      # Kubernetes config dir / Директория конфигурации Kubernetes
export KUBECONFIG=/path/to/config                     # Set custom kubeconfig / Установить кастомный kubeconfig

# Verify certificate expiration / Проверка срока действия сертификата
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -noout -dates
```
Very handy script for [GNOME Argos](https://github.com/p-e-w/argos) to switch contexts if you manage different clusters: [kubernetes switcher script](https://github.com/dominatos/Kubernetes-Config-Switcher-for-Argos) 


### API Server & Cluster Health

```bash
kubectl cluster-info                                  # Cluster endpoints / Эндпоинты кластера
kubectl get componentstatuses                         # Component health / Здоровье компонентов
kubectl version --short                               # Client/server version / Версия клиент/сервер

# API server direct access / Прямой доступ к API серверу
kubectl proxy --port=8080                             # Start API proxy / Запустить прокси API
curl http://localhost:8080/api/v1/namespaces          # Access via proxy / Доступ через прокси
```

### Common Ports

```bash
# 6443  Kubernetes API Server / API сервер Kubernetes
# 10250 Kubelet API / API Kubelet
# 10256 kube-proxy healthz / Проверка здоровья kube-proxy
# 2379  etcd client / Клиент etcd
# 2380  etcd peer / Пир etcd
```

### Resource Quotas & Limits

```bash
kubectl get resourcequotas -A                         # All resource quotas / Все квоты ресурсов
kubectl describe quota -n default                     # Quota details / Детали квоты
kubectl get limitrange -A                             # Limit ranges / Диапазоны лимитов
```

### Troubleshooting Commands

```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp' # Recent events / Последние события
kubectl describe node NODE | grep -A 5 Conditions    # Node conditions / Состояние ноды
kubectl get pods --all-namespaces -o wide | grep -v Running # Non-running pods / Незапущенные pod-ы

# Debug pod network / Отладка сети pod-а
kubectl run debug --rm -it --image=nicolaka/netshoot -- bash

# Check pod resource requests/limits / Проверка запросов и лимитов ресурсов
kubectl describe pod POD | grep -A 10 "Limits\|Requests"
```

