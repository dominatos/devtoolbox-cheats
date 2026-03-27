---
Title: Kustomize — kustomization.yaml
Group: Kubernetes & Containers
Icon: ☸️
Order: 3
---

# ☸️ Kustomize — Template-Free Kubernetes Configuration

**Description / Описание:**
Kustomize is a **template-free** configuration management tool for Kubernetes, built directly into `kubectl`. It uses a **base and overlay** pattern to customize Kubernetes manifests without modifying the originals. Instead of Go templates (like Helm), Kustomize applies declarative patches, strategic merges, and generators to produce environment-specific configurations. It is ideal for managing multi-environment deployments (dev/staging/prod) from a single set of base manifests.

> [!NOTE]
> **Current Status:** Kustomize is a CNCF project and is integrated into `kubectl` (via `kubectl apply -k`). It is widely used as a simpler alternative to Helm when templating is not needed. Standalone `kustomize` CLI provides additional features over the `kubectl` built-in version. Alternatives: **Helm** (full package management with templating), **Timoni** (CUE-based), **cdk8s** (programmatic). / **Текущий статус:** Kustomize — проект CNCF, встроен в `kubectl`. Альтернативы: **Helm**, **Timoni**, **cdk8s**.

---

## Table of Contents

- [Basic Structure](#basic-structure)
- [Base & Overlay Pattern](#base--overlay-pattern)
- [Strategic Merge Patches](#strategic-merge-patches)
- [JSON Patches](#json-patches)
- [ConfigMap & Secret Generators](#configmap--secret-generators)
- [Image Tag Replacement](#image-tag-replacement)
- [Namespace & Labels](#namespace--labels)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)
- [Documentation Links](#documentation-links)

---

## Basic Structure

```yaml
# Minimal kustomization.yaml / Минимальный kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app: demo
```

---

## Base & Overlay Pattern

### Directory Structure / Структура директорий

```text
base/
  ├── kustomization.yaml
  ├── deployment.yaml
  └── service.yaml
overlays/
  ├── dev/
  │   └── kustomization.yaml
  ├── staging/
  │   └── kustomization.yaml
  └── prod/
      └── kustomization.yaml
```

> [!TIP]
> The base contains shared resources. Each overlay customizes the base for a specific environment without modifying the originals. / Base содержит общие ресурсы. Каждый overlay настраивает base под конкретное окружение без изменения оригиналов.

### base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app: myapp
```

### overlays/dev/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namePrefix: dev-

replicas:
  - name: myapp
    count: 1

images:
  - name: myapp
    newTag: dev
```

### overlays/prod/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namePrefix: prod-

replicas:
  - name: myapp
    count: 3

images:
  - name: myapp
    newTag: v1.2.3

configMapGenerator:
  - name: app-config
    literals:
      - MODE=production
      - LOG_LEVEL=info
```

> [!IMPORTANT]
> The `bases` field is deprecated in newer Kustomize versions. Use `resources` instead to reference base directories. / Поле `bases` устарело. Используйте `resources` для ссылки на base-директории.

---

## Strategic Merge Patches

```yaml
# overlays/prod/kustomization.yaml
patchesStrategicMerge:
  - patch-resources.yaml
  - patch-env.yaml
```

### patch-resources.yaml (Strategic Merge) / Патч ресурсов

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: myapp
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1Gi
```

---

## JSON Patches

```yaml
# overlays/prod/kustomization.yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: NEW_VAR
          value: "production"
```

---

## ConfigMap & Secret Generators

### ConfigMap from literals / ConfigMap из значений

```yaml
configMapGenerator:
  - name: app-config
    literals:
      - MODE=prod
      - LOG_LEVEL=info
      - MAX_CONNECTIONS=100
```

### ConfigMap from files / ConfigMap из файлов

```yaml
configMapGenerator:
  - name: app-config
    files:
      - config.properties
      - application.yaml
```

### Secret from literals / Secret из значений

```yaml
secretGenerator:
  - name: app-secret
    literals:
      - DB_PASSWORD=<PASSWORD>
      - API_KEY=<SECRET_KEY>
```

### Secret from files / Secret из файлов

```yaml
secretGenerator:
  - name: tls-secret
    files:
      - tls.crt=cert.pem
      - tls.key=key.pem
    type: kubernetes.io/tls
```

> [!NOTE]
> Kustomize automatically appends a hash suffix to generated ConfigMaps and Secrets, ensuring rolling updates on content changes. Use `generatorOptions.disableNameSuffixHash: true` to disable this. / Kustomize автоматически добавляет хеш-суффикс к сгенерированным ConfigMap/Secret. Используйте `generatorOptions.disableNameSuffixHash: true` для отключения.

---

## Image Tag Replacement

```yaml
# Replace image tags / Замена тегов образов
images:
  - name: nginx
    newName: nginx
    newTag: 1.21.0
  - name: myapp
    newName: <REGISTRY_URL>/myapp
    newTag: v1.2.3
```

```yaml
# Digest replacement (immutable) / Замена digest (неизменяемый)
images:
  - name: myapp
    digest: sha256:1234567890abcdef...
```

> [!TIP]
> Using `digest` instead of `newTag` ensures immutable deployments — the exact image is pinned regardless of tag changes. / Использование `digest` вместо `newTag` гарантирует неизменяемые развёртывания.

---

## Namespace & Labels

```yaml
# Set namespace for all resources / Установить namespace для всех ресурсов
namespace: production

# Common labels / Общие labels
commonLabels:
  app: myapp
  env: prod
  managed-by: kustomize

# Common annotations / Общие аннотации
commonAnnotations:
  monitoring: "true"
  team: platform

# Name prefix/suffix / Префикс/суффикс имени
namePrefix: prod-
nameSuffix: -v2
```

---

## Common Commands

```bash
# Render kustomization / Рендер kustomization
kubectl kustomize ./overlays/prod

# Apply kustomization / Применить kustomization
kubectl apply -k ./overlays/prod

# Diff before apply / Разница перед применением
kubectl diff -k ./overlays/prod

# Delete resources / Удалить ресурсы
kubectl delete -k ./overlays/prod

# Build to file / Сохранить в файл
kubectl kustomize ./overlays/prod > rendered.yaml
```

> [!WARNING]
> `kubectl delete -k` will delete all resources defined in the kustomization. Double-check the overlay path before running in production. / `kubectl delete -k` удалит все ресурсы. Проверяйте путь overlay перед запуском в продакшене.

---

## Troubleshooting

```bash
# Validate kustomization.yaml / Проверка kustomization.yaml
kubectl kustomize ./overlays/prod --enable-alpha-plugins

# Debug resource generation / Отладка генерации ресурсов
kubectl kustomize ./overlays/prod --load-restrictor=LoadRestrictionsNone

# Common errors / Часто встречающиеся ошибки:
# - "accumulating resources: ..." → Check base path is correct / Проверьте путь к base
# - "no matches for kind ..." → Ensure resources exist in base / Ресурсы должны быть в base
# - "multiple matches for ..." → Patches target must be unique / Цель патча уникальна

# View all resources / Просмотр всех ресурсов
kubectl kustomize ./overlays/prod | grep -E "^(kind|metadata):"
```

### Common Issues Quick Reference / Краткий справочник проблем

| Error / Ошибка | Cause / Причина | Fix / Решение |
| :--- | :--- | :--- |
| `accumulating resources` | Incorrect base path | Verify relative path to base directory / Проверить относительный путь |
| `no matches for kind` | Resource missing in base | Add resource to base `kustomization.yaml` / Добавить в base |
| `multiple matches` | Ambiguous patch target | Ensure unique `name` + `kind` in patch target / Уникальный `name` + `kind` |
| `must be a file` | Wrong path format | Use relative paths, not absolute / Относительные пути |

---

## Documentation Links

- **Kustomize Official Documentation:** [https://kustomize.io/](https://kustomize.io/)
- **Kustomize GitHub Repository:** [https://github.com/kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize)
- **Kustomize API Reference:** [https://kubectl.docs.kubernetes.io/references/kustomize/](https://kubectl.docs.kubernetes.io/references/kustomize/)
- **kubectl apply -k Documentation:** [https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- **Kustomize Examples:** [https://github.com/kubernetes-sigs/kustomize/tree/master/examples](https://github.com/kubernetes-sigs/kustomize/tree/master/examples)
