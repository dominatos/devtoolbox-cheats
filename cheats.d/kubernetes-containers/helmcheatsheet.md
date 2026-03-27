---
Title: Helm — Commands
Group: Kubernetes & Containers
Icon: ⛏
Order: 4
---

# ⛏ Helm — Kubernetes Package Manager

**Description / Описание:**
Helm is the **package manager for Kubernetes**, analogous to `apt` or `yum` for Linux. It uses **charts** — pre-configured Kubernetes resource packages — to define, install, and upgrade complex applications on Kubernetes clusters. Helm simplifies deployment management by handling templating, versioning, rollback, and dependency resolution. It supports OCI registries for chart distribution and integrates seamlessly into CI/CD pipelines.

> [!NOTE]
> **Current Status:** Helm v3 is the current standard (v2 is deprecated and EOL). It is a CNCF graduated project and the de facto tool for Kubernetes application packaging. Alternatives include **Kustomize** (built into `kubectl`), **Kapp** (from Carvel), and **Timoni** (CUE-based, experimental). / **Текущий статус:** Helm v3 — текущий стандарт (v2 устарел). Проект CNCF. Альтернативы: **Kustomize**, **Kapp**, **Timoni**.

---

## Table of Contents

- [Repository Management](#repository-management)
- [Chart Operations](#chart-operations)
- [Values & Configuration](#values--configuration)
- [Templating & Validation](#templating--validation)
- [Debugging](#debugging)
- [Chart Development](#chart-development)
- [Sysadmin Essentials](#sysadmin-essentials)
- [Documentation Links](#documentation-links)

---

## Repository Management

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami   # Add repo / Добавить репозиторий
helm repo add <REPO_NAME> <REPO_URL>                       # Add custom repo / Добавить кастомный репо
helm repo update                                           # Update repo index / Обновить индекс репо
helm repo list                                             # List repos / Список репозиториев
helm repo remove <REPO_NAME>                               # Remove repo / Удалить репозиторий

helm search repo nginx                                     # Search charts / Поиск чартов
helm search repo nginx --versions                          # Show all versions / Показать все версии
helm search hub wordpress                                  # Search Artifact Hub / Поиск в Artifact Hub
```

---

## Chart Operations

### Install & Upgrade / Установка и обновление

```bash
helm install my-nginx bitnami/nginx                        # Install chart / Установить чарт
helm install my-nginx oci://registry-1.docker.io/bitnamicharts/nginx  # Install OCI / Установка OCI
helm install my-app ./chart -n demo                        # Install from local / Установка из локального чарта
helm upgrade my-app ./chart -n demo                        # Upgrade release / Обновить релиз
helm upgrade --install my-app ./chart -n demo              # Upsert release / Установка/обновление
helm upgrade --install my-app ./chart -n demo -f values.yaml # With values / С values
```

### List & Status / Список и статус

```bash
helm list -A                                               # List all releases / Список всех релизов
helm list -n demo                                          # List in namespace / Список в namespace
helm status my-app -n demo                                 # Release status / Статус релиза
helm history my-app -n demo                                # Release history / История релиза
```

### Rollback & Uninstall / Откат и удаление

```bash
helm rollback my-app -n demo                               # Rollback to previous / Откат к предыдущей версии
helm rollback my-app 2 -n demo                             # Rollback to revision / Откат к ревизии
helm uninstall my-app -n demo                              # Remove release / Удалить релиз
helm uninstall my-app -n demo --keep-history               # Keep history / Сохранить историю
```

---

## Values & Configuration

```bash
helm show values bitnami/nginx                             # Show default values / Показать values по умолчанию
helm get values my-app -n demo                             # Effective values / Итоговые значения
helm get values my-app -n demo --all                       # All values (computed) / Все values (вычисленные)

helm upgrade --install my-app ./chart -f values.yaml       # From file / Из файла
helm upgrade --install my-app ./chart -f values-prod.yaml -f values-override.yaml # Merge values / Объединить values
helm upgrade --install my-app ./chart --set replicas=3     # Set value / Установить значение
helm upgrade --install my-app ./chart --set-string tag=v1.2.3 # Set string / Установить строку
```

> [!TIP]
> Values precedence (last wins): `values.yaml` → `-f file` → `--set`. Use `--set-string` for values that could be misinterpreted as numbers or booleans. / Приоритет values (последний побеждает): `values.yaml` → `-f файл` → `--set`.

---

## Templating & Validation

```bash
helm template my-app ./chart                               # Render templates / Рендер шаблонов
helm template my-app ./chart -f values.yaml                # With values / С values
helm template my-app ./chart -f values.yaml -f values-prod.yaml # Merge values / Объединить values
helm template my-app ./chart -f values.yaml | kubectl apply -f - # Render+apply / Рендер и применить

helm lint ./chart                                          # Lint chart / Проверка чарта
helm lint ./chart -f values.yaml                           # Lint with values / Проверка с values

# Helm diff plugin (install: helm plugin install https://github.com/databus23/helm-diff)
helm diff upgrade my-app ./chart -f values.yaml            # Show diff / Показать разницу
```

---

## Debugging

```bash
helm install my-app ./chart --dry-run                      # Dry run / Предварительный просмотр
helm install my-app ./chart --dry-run --debug              # Debug mode / Режим отладки
helm template my-app ./chart > output.yaml                 # Save rendered / Сохранить рендер

helm get manifest my-app -n demo                           # Get manifests / Получить манифесты
helm get hooks my-app -n demo                              # Get hooks / Получить hooks
helm get notes my-app -n demo                              # Get notes / Получить заметки
```

---

## Chart Development

```bash
helm create mychart                                        # Create chart skeleton / Создать скелет чарта
helm package ./mychart                                     # Package chart / Упаковать чарт
helm dependency update ./mychart                           # Update dependencies / Обновить зависимости
helm dependency list ./mychart                             # List dependencies / Список зависимостей

helm show chart bitnami/nginx                              # Show Chart.yaml / Показать Chart.yaml
helm show readme bitnami/nginx                             # Show README / Показать README
helm show all bitnami/nginx                                # Show all info / Показать всю информацию
```

---

## Sysadmin Essentials

### Configuration Paths / Пути конфигурации

```bash
~/.config/helm/                                            # Helm config directory / Директория конфигурации Helm
~/.cache/helm/                                             # Helm cache directory / Директория кэша Helm
~/.local/share/helm/                                       # Helm data directory / Директория данных Helm
```

### OCI Registry Patterns / Работа с OCI реестром

```bash
helm registry login <REGISTRY_URL>                         # Login to OCI registry / Войти в OCI реестр
helm registry logout <REGISTRY_URL>                        # Logout / Выйти

helm pull oci://<REGISTRY_URL>/charts/mychart --version 1.0.0 # Pull OCI chart / Скачать OCI чарт
helm push mychart-1.0.0.tgz oci://<REGISTRY_URL>/charts    # Push to OCI / Отправить в OCI
```

### Troubleshooting / Устранение неполадок

```bash
# Check Helm version / Проверка версии Helm
helm version

# Verify chart integrity / Проверка целостности чарта
helm verify mychart-1.0.0.tgz

# Get release info (stored as K8s secrets) / Информация о релизе (хранится как K8s секреты)
kubectl get secret -n demo -l owner=helm

# Force delete stuck release / Принудительное удаление застрявшего релиза
kubectl delete secret -n demo sh.helm.release.v1.<RELEASE_NAME>.v<VERSION>
```

> [!CAUTION]
> Manually deleting Helm release secrets will break Helm's release tracking. Only do this as a last resort when `helm uninstall` fails. / Ручное удаление секретов релиза нарушит отслеживание Helm. Используйте только как крайнюю меру.

### Best Practices / Лучшие практики

```bash
# Always use --atomic for production deployments / Всегда используйте --atomic для продакшн развёртываний
helm upgrade --install my-app ./chart --atomic --timeout 5m

# Use --wait for complete rollout / Используйте --wait для полного развёртывания
helm upgrade --install my-app ./chart --wait --timeout 5m

# Create namespace if not exists / Создать namespace если не существует
helm upgrade --install my-app ./chart -n demo --create-namespace
```

### Production Runbook (Deploy/Rollback) / Прод-ранбук (Deploy/Rollback)

1. **Deploy / Деплой:**
   1. `helm repo update` — Update chart repos / Обновить репозитории
   2. `helm diff upgrade my-app ./chart -f values.yaml` — Preview changes / Предпросмотр изменений
   3. `helm upgrade --install my-app ./chart -f values.yaml --atomic --timeout 5m` — Deploy / Развернуть
   4. `helm status my-app -n demo` — Verify / Проверить
2. **Rollback / Откат:**
   1. `helm history my-app -n demo` — Check revision history / Проверить историю ревизий
   2. `helm rollback my-app <REVISION> -n demo` — Rollback / Откат
   3. `helm status my-app -n demo` — Verify / Проверить

---

## Documentation Links

- **Helm Official Documentation:** [https://helm.sh/docs/](https://helm.sh/docs/)
- **Helm Chart Best Practices:** [https://helm.sh/docs/chart_best_practices/](https://helm.sh/docs/chart_best_practices/)
- **Helm CLI Reference:** [https://helm.sh/docs/helm/](https://helm.sh/docs/helm/)
- **Artifact Hub (Chart Registry):** [https://artifacthub.io/](https://artifacthub.io/)
- **Helm GitHub Repository:** [https://github.com/helm/helm](https://github.com/helm/helm)
- **Helm Diff Plugin:** [https://github.com/databus23/helm-diff](https://github.com/databus23/helm-diff)
