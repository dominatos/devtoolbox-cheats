Title: ☸️ KUBECTL — Commands
Group: Kubernetes & Containers
Icon: ☸️
Order: 1

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

---

## 🔧 Контексты, кластеры, неймспейсы

kubectl config view                                   # Show kubeconfig / Показать kubeconfig
kubectl config get-contexts                           # List contexts / Список контекстов
kubectl config current-context                        # Current context / Текущий контекст
kubectl config use-context CONTEXT                    # Switch context / Переключить контекст
kubectl config set-context --current --namespace=ns   # Set default ns / Установить namespace по умолчанию
kubectl get ns                                        # List namespaces / Список namespace
kubectl get all -n kube-system                        # All objects in ns / Все объекты в namespace

---

## 📦 Pods

kubectl get pods                                      # List pods / Список pod-ов
kubectl get pods -A                                   # Pods in all ns / Pod-ы во всех namespace
kubectl get pods -o wide                              # Pods with nodes/IP / Pod-ы с node/IP
kubectl describe pod POD                              # Pod details / Детали pod-а
kubectl delete pod POD                                # Delete pod / Удалить pod
kubectl logs POD                                      # Pod logs / Логи pod-а
kubectl logs POD -c CONTAINER                         # Container logs / Логи контейнера
kubectl logs -f POD --tail=200                        # Follow logs / Следить за логами
kubectl exec -it POD -- /bin/sh                       # Shell in pod / Оболочка в pod-е
kubectl exec POD -- env                               # Show env vars / Переменные окружения
kubectl cp POD:/path ./local                          # Copy from pod / Копировать из pod-а
kubectl cp ./local POD:/path                          # Copy to pod / Копировать в pod

---

## 🚀 Deployments / ReplicaSets / StatefulSets

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

---

## 🌐 Services / Ingress / Networking

kubectl get svc                                       # List services / Список сервисов
kubectl describe svc APP                              # Service details / Детали сервиса
kubectl get ing                                       # List ingress / Список ingress
kubectl describe ing APP                              # Ingress details / Детали ingress
kubectl port-forward svc/APP 8080:80                  # Port forward svc / Проброс портов
kubectl port-forward pod/POD 8080:80                  # Port forward pod / Проброс портов pod-а

---

## 📄 ConfigMaps & Secrets

kubectl get cm                                        # List ConfigMaps / Список ConfigMap
kubectl describe cm NAME                              # ConfigMap details / Детали ConfigMap
kubectl create cm NAME --from-file=file.conf          # CM from file / ConfigMap из файла
kubectl create cm NAME --from-literal=k=v             # CM from literal / ConfigMap из значения

kubectl get secret                                    # List secrets / Список Secret
kubectl describe secret NAME                          # Secret metadata / Метаданные Secret
kubectl get secret NAME -o yaml                       # Secret yaml / Secret в yaml
kubectl create secret generic NAME --from-literal=k=v # Create secret / Создать Secret

---

## 💾 Storage (PV / PVC)

kubectl get pv                                        # List PV / Список PersistentVolume
kubectl get pvc                                       # List PVC / Список PersistentVolumeClaim
kubectl describe pvc NAME                             # PVC details / Детали PVC
kubectl delete pvc NAME                               # Delete PVC / Удалить PVC

---

## 🧠 Nodes / Cluster

kubectl get nodes                                     # List nodes / Список нод
kubectl describe node NODE                            # Node details / Детали ноды
kubectl cordon NODE                                   # Mark unschedulable / Запретить планирование
kubectl uncordon NODE                                 # Enable scheduling / Разрешить планирование
kubectl drain NODE --ignore-daemonsets                # Drain node / Освободить ноду

---

## 📊 Metrics / Debug / Troubleshooting

kubectl top nodes                                     # Node CPU/mem / Ресурсы нод
kubectl top pods                                      # Pod CPU/mem / Ресурсы pod-ов
kubectl get events                                    # Cluster events / События кластера
kubectl get events --sort-by=.metadata.creationTimestamp # Events sorted / События по времени
kubectl auth can-i create pods                        # RBAC check / Проверка прав
kubectl explain pod.spec                              # Explain fields / Документация API

---

## 📁 YAML / Apply / Diff

kubectl apply -f file.yaml                            # Apply manifest / Применить манифест
kubectl apply -k ./dir                                # Apply kustomize / Применить kustomize
kubectl delete -f file.yaml                           # Delete by file / Удалить по файлу
kubectl diff -f file.yaml                             # Diff local vs cluster / Разница
kubectl get deploy APP -o yaml                        # Export yaml / Получить yaml
kubectl create deploy APP --image=nginx --dry-run=client -o yaml > app.yaml # Generate yaml / Сгенерировать yaml

---

## 🔐 RBAC / Security

kubectl get sa                                        # ServiceAccounts / Сервисные аккаунты
kubectl get role,clusterrole                          # Roles / Роли
kubectl get rolebinding,clusterrolebinding            # RoleBindings / Привязки ролей
kubectl describe rolebinding NAME                     # RBAC details / Детали RBAC

---

## 🧪 Полезные one-liners

kubectl get pods -A | grep CrashLoop                  # Find crashing pods / Найти падающие pod-ы
kubectl delete pod -l app=myapp                       # Delete by label / Удалить по label
kubectl get pods -o json | jq '.items[].metadata.name'# Pods via jq / Pod-ы через jq
