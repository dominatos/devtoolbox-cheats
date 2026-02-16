Title: ☸️ KUBECTL — JSONPath
Group: Kubernetes & Containers
Icon: ☸️
Order: 2

## Table of Contents
- [Basic JSONPath Queries](#basic-jsonpath-queries)
- [Resource Filtering](#resource-filtering)
- [Node Information](#node-information)
- [Container & Image Queries](#container--image-queries)
- [Custom Columns](#custom-columns)
- [Troubleshooting JSONPath](#troubleshooting-jsonpath)

---

## Basic JSONPath Queries

kubectl get pods -o jsonpath='{.items[*].status.podIP}'                            # All pod IPs / Все IP подов
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'        # Names one per line / Имена по одному в строке
kubectl get secret my -o jsonpath='{.data.password}' | base64 -d                   # Decode secret field / Декодировать поле секрета
kubectl get pods -o jsonpath='{.items[0].metadata.name}'                           # First pod name / Имя первого pod-а
kubectl get svc -o jsonpath='{.items[*].spec.clusterIP}'                           # All service IPs / Все IP сервисов

---

## Resource Filtering

# Get pods by phase / Получить pod-ы по фазе
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'

# Get pods with restarts > 0 / Получить pod-ы с перезапусками > 0
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '$2>0'

# Get services of type LoadBalancer / Получить сервисы типа LoadBalancer
kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].metadata.name}'

# Get pods without ready status / Получить pod-ы без статуса ready
kubectl get pods -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status!="True")].metadata.name}'

---

## Node Information

# Node names and kubelet versions / Имена узлов и версии kubelet
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'

# Node capacity (CPU & memory) / Ёмкость узла (CPU и память)
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\tCPU: "}{.status.capacity.cpu}{"\tMem: "}{.status.capacity.memory}{"\n"}{end}'

# Node allocatable resources / Доступные ресурсы узла
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'

# Node external IPs / Внешние IP узлов
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# Node OS information / Информация об ОС узла
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\n"}{end}'

---

## Container & Image Queries

# Deployment → images / Деплой → образы
kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.template.spec.containers[*].image}{"\n"}{end}'

# All container images in namespace / Все образы контейнеров в namespace
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u

# Container resource requests / Запросы ресурсов контейнеров
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"\t"}{.name}{" CPU: "}{.resources.requests.cpu}{" Mem: "}{.resources.requests.memory}{"\n"}{end}{end}'

# Container resource limits / Лимиты ресурсов контейнеров
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"\t"}{.name}{" CPU: "}{.resources.limits.cpu}{" Mem: "}{.resources.limits.memory}{"\n"}{end}{end}'

# Pod image pull policy / Политика загрузки образов pod-ов
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].imagePullPolicy}{"\n"}{end}'

---

## Custom Columns

# Custom columns for pods / Кастомные колонки для pod-ов
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,NODE:.spec.nodeName

# Custom columns for nodes / Кастомные колонки для узлов
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory

# Deployments with replicas / Deployment-ы с репликами
kubectl get deploy -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,AVAILABLE:.status.availableReplicas

# Services with type and IPs / Сервисы с типом и IP
kubectl get svc -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip

---

## Troubleshooting JSONPath

# Pretty print JSON structure / Вывод структуры JSON
kubectl get pod POD -o json | jq .

# Test JSONPath expressions / Тестирование JSONPath выражений
kubectl get pod POD -o jsonpath='{.metadata.name}'
kubectl get pod POD -o jsonpath='{.status.phase}'

# Common errors / Часто встречающиеся ошибки:
# - Missing quotes around JSONPath expression / Отсутствие кавычек вокруг JSONPath выражения
# - Incorrect array indexing / Неправильная индексация массива
# - Missing range for multi-item output / Отсутствие range для вывода нескольких элементов

# Combine with jq for complex queries / Комбинация с jq для сложных запросов
kubectl get pods -o json | jq '.items[] | select(.status.phase=="Running") | .metadata.name'

# Use grep/awk with JSONPath / Использование grep/awk с JSONPath
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' | grep Running
