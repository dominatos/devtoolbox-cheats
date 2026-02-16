Title: ☸️ Kustomize — kustomization.yaml
Group: Kubernetes & Containers
Icon: ☸️
Order: 3

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

---

## Basic Structure

# Minimal kustomization.yaml / Минимальный kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app: demo

---

## Base & Overlay Pattern

# Directory structure / Структура директорий
# base/
#   ├── kustomization.yaml
#   ├── deployment.yaml
#   └── service.yaml
# overlays/
#   ├── dev/
#   │   └── kustomization.yaml
#   ├── staging/
#   │   └── kustomization.yaml
#   └── prod/
#       └── kustomization.yaml

### base/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app: myapp

---

### overlays/dev/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namePrefix: dev-

replicas:
  - name: myapp
    count: 1

images:
  - name: myapp
    newTag: dev

---

### overlays/prod/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
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

---

## Strategic Merge Patches

# overlays/prod/kustomization.yaml
patchesStrategicMerge:
  - patch-resources.yaml
  - patch-env.yaml

### patch-resources.yaml (Strategic Merge)

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

---

## JSON Patches

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

---

## ConfigMap & Secret Generators

### ConfigMap from literals / ConfigMap из значений

configMapGenerator:
  - name: app-config
    literals:
      - MODE=prod
      - LOG_LEVEL=info
      - MAX_CONNECTIONS=100

### ConfigMap from files / ConfigMap из файлов

configMapGenerator:
  - name: app-config
    files:
      - config.properties
      - application.yaml

### Secret from literals / Secret из значений

secretGenerator:
  - name: app-secret
    literals:
      - DB_PASSWORD=<PASSWORD>
      - API_KEY=<SECRET_KEY>

### Secret from files / Secret из файлов

secretGenerator:
  - name: tls-secret
    files:
      - tls.crt=cert.pem
      - tls.key=key.pem
    type: kubernetes.io/tls

---

## Image Tag Replacement

# Replace image tags / Замена тегов образов
images:
  - name: nginx
    newName: nginx
    newTag: 1.21.0
  - name: myapp
    newName: <REGISTRY_URL>/myapp
    newTag: v1.2.3

# Digest replacement / Замена digest
images:
  - name: myapp
    digest: sha256:1234567890abcdef...

---

## Namespace & Labels

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

---

## Common Commands

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

---

## Troubleshooting

# Validate kustomization.yaml / Проверка kustomization.yaml
kubectl kustomize ./overlays/prod --enable-alpha-plugins

# Debug resource generation / Отладка генерации ресурсов
kubectl kustomize ./overlays/prod --load-restrictor=LoadRestrictionsNone

# Common errors / Часто встречающиеся ошибки:
# - "accumulating resources: accumulation err='accumulating resources from '../../base': ..."
#   → Check base path is correct / Проверьте правильность пути к base
# - "no matches for kind ..."
#   → Ensure resources exist in base / Убедитесь что ресурсы существуют в base
# - "multiple matches for ..."
#   → Patches target must be unique / Цель патча должна быть уникальной

# View all resources / Просмотр всех ресурсов
kubectl kustomize ./overlays/prod | grep -E "^(kind|metadata):"
