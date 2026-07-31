---
Title: KUBECTL — JSONPath
Group: "Kubernetes & Containers"
Icon: ☸️
Order: 2
tags:
  - kubernetes
  - containers
  - docker
  - sysadmin
---

# ☸️ KUBECTL — JSONPath Queries

**Description / Описание:**
JSONPath is a query language for JSON data, integrated into `kubectl` via the `-o jsonpath` output format. It enables precise extraction of specific fields from Kubernetes resources without resorting to `jq` or `grep`. JSONPath is essential for automation scripts, CI/CD pipelines, and quick cluster inspection. Combined with `custom-columns`, it provides powerful tabular output directly from the Kubernetes API.

> [!NOTE]
> **When to use:** JSONPath is built into `kubectl` and requires no additional tools. For complex filtering and transformation, consider combining with **jq** or using `kubectl -o json | jq`. / **Когда использовать:** JSONPath встроен в `kubectl`. Для сложной фильтрации комбинируйте с **jq**.

---

## Table of Contents

- [Basic JSONPath Queries](#Basic%20JSONPath%20Queries)
- [Resource Filtering](#Resource%20Filtering)
- [Node Information](#Node%20Information)
- [Container & Image Queries](#Container%20&%20Image%20Queries)
- [Custom Columns](#Custom%20Columns)
- [Troubleshooting JSONPath](#Troubleshooting%20JSONPath)
- [Documentation Links](#Documentation%20Links)

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
# Get pods by phase
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'

# Get pods with restarts > 0
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '$2>0'

# Get services of type LoadBalancer
kubectl get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].metadata.name}'

# Get pods without ready status
kubectl get pods -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status!="True")].metadata.name}'
```

---

## Node Information

```bash
# Node names and kubelet versions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'

# Node capacity (CPU & memory) / Ёмкость
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\tCPU: "}{.status.capacity.cpu}{"\tMem: "}{.status.capacity.memory}{"\n"}{end}'

# Node allocatable resources
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'

# Node external IPs
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# Node OS information
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\n"}{end}'
```

---

## Container & Image Queries

```bash
# Deployment → images
kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.template.spec.containers[*].image}{"\n"}{end}'

# All container images in namespace
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u

# Container resource requests
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"\t"}{.name}{" CPU: "}{.resources.requests.cpu}{" Mem: "}{.resources.requests.memory}{"\n"}{end}{end}'

# Container resource limits
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"\t"}{.name}{" CPU: "}{.resources.limits.cpu}{" Mem: "}{.resources.limits.memory}{"\n"}{end}{end}'

# Pod image pull policy
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].imagePullPolicy}{"\n"}{end}'
```

---

## Custom Columns

```bash
# Custom columns for pods
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,NODE:.spec.nodeName

# Custom columns for nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory

# Deployments with replicas / Deployment-ы
kubectl get deploy -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,AVAILABLE:.status.availableReplicas

# Services with type and IPs
kubectl get svc -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip
```

---

## Troubleshooting JSONPath

```bash
# Pretty print JSON structure
kubectl get pod POD -o json | jq .

# Test JSONPath expressions
kubectl get pod POD -o jsonpath='{.metadata.name}'
kubectl get pod POD -o jsonpath='{.status.phase}'

# Common errors
# - Missing quotes around JSONPath expression
# - Incorrect array indexing
# - Missing range for multi-item output

# Combine with jq for complex queries
kubectl get pods -o json | jq '.items[] | select(.status.phase=="Running") | .metadata.name'

# Use grep/awk with JSONPath
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
