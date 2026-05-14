---
Title: KUBECTL — JSONPath
Group: Kubernetes & Containers
Icon: ☸️
Order: 2
---

# ☸️ KUBECTL — JSONPath Queries

**Description / Описание:**
JSONPath is a query language for JSON data, integrated into `kubectl` via the `-o jsonpath` output format. It enables precise extraction of specific fields from Kubernetes resources without resorting to `jq` or `grep`. JSONPath is essential for automation scripts, CI/CD pipelines, and quick cluster inspection. Combined with `custom-columns`, it provides powerful tabular output directly from the Kubernetes API.

> [!NOTE]
> **When to use:** JSONPath is built into `kubectl` and requires no additional tools. For complex filtering and transformation, consider combining with **jq** or using `kubectl -o json | jq`. / **Когда использовать:** JSONPath встроен в `kubectl`. Для сложной фильтрации комбинируйте с **jq**.

---

## Table of Contents

- [Basic JSONPath Queries](#basic-jsonpath-queries)
- [Resource Filtering](#resource-filtering)
- [Node Information](#node-information)
- [Container & Image Queries](#container--image-queries)
- [Custom Columns](#custom-columns)
- [Troubleshooting JSONPath](#troubleshooting-jsonpath)
- [Documentation Links](#documentation-links)

---

## Basic JSONPath Queries

```bash
kubectl get pods -o jsonpath='{.items[*].status.podIP}'                            # All pod IPs / Все IP подов
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'        # Names one per line / Имена по одному в строке
kubectl get secret my -o jsonpath='{.data.password}' | base64 -d                   # Decode secret field / Декодировать поле секрета
kubectl get pods -o jsonpath='{.items[0].metadata.name}'                           # First pod name / Имя первого pod-а
kubectl get svc -o jsonpath='{.items[*].spec.clusterIP}'                           # All service IPs / Все IP сервисов
```

---

## Resource Filtering

```bash
# Get pods by phase / Получить pod-ы по фазе
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'

# Get pods with restarts > 0 / Получить pod-ы с перезапусками > 0
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '$2>0'

# Get services of type LoadBalancer / Получить сервисы типа LoadBalancer
kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].metadata.name}'

# Get pods without ready status / Получить pod-ы без статуса ready
kubectl get pods -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status!="True")].metadata.name}'
```

---

## Node Information

```bash
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
```

---

## Container & Image Queries

```bash
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
```

---

## Custom Columns

```bash
# Custom columns for pods / Кастомные колонки для pod-ов
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,NODE:.spec.nodeName

# Custom columns for nodes / Кастомные колонки для узлов
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory

# Deployments with replicas / Deployment-ы с репликами
kubectl get deploy -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,AVAILABLE:.status.availableReplicas

# Services with type and IPs / Сервисы с типом и IP
kubectl get svc -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip
```

---

## Troubleshooting JSONPath

```bash
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
```

> [!TIP]
> Use `kubectl get <resource> -o json | jq .` first to explore the JSON structure, then build your JSONPath query. / Используйте `kubectl get <ресурс> -o json | jq .` для изучения структуры JSON перед составлением JSONPath-запроса.

---

## Documentation Links

- **Kubernetes JSONPath Support:** [https://kubernetes.io/docs/reference/kubectl/jsonpath/](https://kubernetes.io/docs/reference/kubectl/jsonpath/)
- **kubectl Output Formatting:** [https://kubernetes.io/docs/reference/kubectl/#output-options](https://kubernetes.io/docs/reference/kubectl/#output-options)
- **JSONPath Specification:** [https://goessner.net/articles/JsonPath/](https://goessner.net/articles/JsonPath/)
- **jq Manual (complementary tool):** [https://jqlang.github.io/jq/manual/](https://jqlang.github.io/jq/manual/)
