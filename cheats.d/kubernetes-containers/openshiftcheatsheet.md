---
Title: OpenShift (OCP)
Group: Kubernetes & Containers
Icon: ☸️
Order: 10
---

# ☸️ OpenShift (OCP) — Enterprise Kubernetes Platform

**Description / Описание:**
Red Hat **OpenShift Container Platform (OCP)** is an enterprise-grade Kubernetes distribution that adds developer and operational tooling on top of Kubernetes. It provides a web console, integrated CI/CD (Pipelines/GitOps), built-in monitoring (Prometheus/Grafana), an internal container registry, enhanced security (SCCs, OAuth), and the `oc` CLI — a superset of `kubectl`. OpenShift uses **Operators** extensively for lifecycle management of cluster components and applications.

> [!NOTE]
> **Current Status:** OpenShift is actively developed by Red Hat (IBM). It is widely used in enterprise environments requiring commercial support and compliance certifications (FedRAMP, HIPAA). Free alternatives: **OKD** (upstream community edition), **vanilla Kubernetes** + add-ons, **Rancher** (SUSE), **Tanzu** (VMware/Broadcom). The `oc` CLI is a superset of `kubectl` — all `kubectl` commands work with `oc`. / **Текущий статус:** OpenShift активно развивается Red Hat. Используется в корпоративных средах. Бесплатные альтернативы: **OKD**, **Rancher**, **Tanzu**. CLI `oc` — надмножество `kubectl`.

> **Default Ports:** API Server: `6443` | Web Console: `443` | OAuth: `443` | Internal Registry: `5000`

---

## Table of Contents

- [Authentication & Context](#authentication--context)
- [Core Operations](#core-operations)
- [Admin Operations](#admin-operations)
- [Builds & Deployments](#builds--deployments)
- [Routes & Networking](#routes--networking)
- [Security](#security)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Sysadmin Essentials](#sysadmin-essentials)
- [Documentation Links](#documentation-links)

---

## Authentication & Context

### Login / Вход

```bash
# Login via Token / Вход по токену
oc login --token=<TOKEN> --server=https://api.<CLUSTER>:6443

# Login with User/Pass / Вход по логину/паролю
oc login -u <USER> -p <PASSWORD> https://api.<CLUSTER>:6443

# Login as System Admin (if certs available) / Вход как админ
export KUBECONFIG=<PATH_TO_KUBECONFIG>
oc whoami                                          # Show current user / Показать текущего пользователя
oc whoami --show-server                            # Show API server / Показать API сервер
oc whoami --show-token                             # Show current token / Показать текущий токен
```

### Project Management / Управление проектами (Namespaces)

```bash
oc project <PROJECT_NAME>                          # Switch project / Переключить проект
oc new-project <PROJECT_NAME>                      # New project / Новый проект
oc get projects                                    # List projects / Список проектов
oc delete project <PROJECT_NAME>                   # Delete project / Удалить проект
oc project                                         # Show current project / Показать текущий проект
```

> [!NOTE]
> OpenShift **Projects** are Kubernetes Namespaces with additional metadata (display name, description, annotations). `oc new-project` creates a namespace with default RBAC bindings. / OpenShift **Projects** — это Kubernetes Namespace с дополнительными метаданными.

---

## Core Operations

The `oc` CLI is a superset of `kubectl` — all `kubectl` commands work with `oc`. Below are OpenShift-specific commands and aliases. / CLI `oc` — надмножество `kubectl`. Ниже — команды, специфичные для OpenShift.

### Get Resources / Получение ресурсов

```bash
oc get pods                                        # List pods / Список pod-ов
oc get svc                                         # List services / Список сервисов
oc get routes                                      # OpenShift routes (Ingress equivalent) / Маршруты OpenShift
oc get dc                                          # DeploymentConfig (Legacy) / DeploymentConfig (устаревшее)
oc get builds                                      # List builds / Список сборок
oc get bc                                          # BuildConfig / Конфигурация сборки
oc get is                                          # ImageStreams / Потоки образов
```

### Logs & Exec / Логи и вход

```bash
oc logs -f <POD_NAME>                              # Container logs (follow) / Логи контейнера
oc logs -f bc/<BUILD_CONFIG>                       # Build logs / Логи сборки
oc rsh <POD_NAME>                                  # Shell into pod / Оболочка в pod-е
oc exec -it <POD_NAME> -- /bin/bash                # Exec bash / Выполнить bash
```

> [!TIP]
> `oc rsh` is more convenient than `kubectl exec -it` — it defaults to `/bin/sh` and requires fewer flags. / `oc rsh` удобнее `kubectl exec -it` — по умолчанию `/bin/sh` и требует меньше флагов.

### Resource Creation / Создание ресурсов

```bash
oc new-app nginx                                   # Deploy app from image / Развернуть из образа
oc new-app <GIT_REPO_URL>                          # Deploy from Git / Развернуть из Git
oc new-app <IMAGE> --name=<APP_NAME>               # Deploy with custom name / Развернуть с именем
oc expose svc/<SERVICE_NAME>                       # Create route for service / Создать маршрут для сервиса
```

---

## Admin Operations

> [!IMPORTANT]
> Admin operations require `cluster-admin` or equivalent privileges. / Админские операции требуют привилегий `cluster-admin`.

### Node Management / Управление узлами

```bash
oc get nodes                                       # List nodes / Список узлов
oc describe node <NODE_NAME>                       # Node details / Детали узла
oc debug node/<NODE_NAME>                          # Debug node (mounts host OS) / Отладка узла
# → chroot /host                                   # Access host filesystem / Доступ к ФС хоста
oc adm top nodes                                   # Node resource usage / Использование ресурсов нод
oc adm cordon <NODE_NAME>                          # Mark unschedulable / Запретить планирование
oc adm uncordon <NODE_NAME>                        # Enable scheduling / Разрешить планирование
oc adm drain <NODE_NAME> --ignore-daemonsets       # Drain node / Освободить ноду
```

### Policy & Users / Политики и пользователи

```bash
oc adm policy add-cluster-role-to-user cluster-admin <USER>  # Add cluster admin / Дать админа
oc policy add-role-to-user view <USER> -n <PROJECT>          # Add view role / Дать права просмотра
oc adm policy add-scc-to-user anyuid -z default -n <PROJECT> # Add SCC to SA / Добавить SCC к SA
oc get clusterrolebindings | grep <USER>                     # Check user roles / Проверить роли пользователя
```

### Cluster Management / Управление кластером

```bash
oc get clusterversion                              # Cluster version / Версия кластера
oc get clusteroperators                            # Cluster operators status / Статус операторов
oc adm upgrade                                     # Check available upgrades / Проверить обновления
oc get machineconfigpool                           # MachineConfigPool status / Статус MachineConfigPool
```

---

## Builds & Deployments

### OpenShift-specific Resources / Ресурсы, специфичные для OpenShift

| Resource | Description (EN / RU) | Use Case / Best for... |
| :--- | :--- | :--- |
| **DeploymentConfig (dc)** | Legacy deployment controller / Устаревший контроллер | Legacy apps; prefer `Deployment` for new apps. |
| **BuildConfig (bc)** | Automated build definitions / Определения автосборки | Source-to-Image (S2I), Docker builds. |
| **ImageStream (is)** | Image metadata & tagging / Метаданные и теги образов | Internal registry tracking, triggers. |
| **Route** | External access (HTTP/HTTPS) / Внешний доступ | Alternative to Ingress, TLS termination. |

```bash
# Start a build / Запустить сборку
oc start-build <BUILD_CONFIG>

# Start build from local directory / Сборка из локальной директории
oc start-build <BUILD_CONFIG> --from-dir=.

# Cancel a build / Отменить сборку
oc cancel-build <BUILD_NAME>

# Rollout / deployment management / Управление деплойментом
oc rollout latest dc/<APP_NAME>                    # Trigger new rollout / Запустить новое развёртывание
oc rollout status dc/<APP_NAME>                    # Rollout status / Статус развёртывания
oc rollout undo dc/<APP_NAME>                      # Rollback / Откат
```

> [!WARNING]
> `DeploymentConfig` (dc) is a legacy OpenShift resource. For new applications, use standard Kubernetes `Deployment` objects. / `DeploymentConfig` — устаревший ресурс OpenShift. Для новых приложений используйте стандартный `Deployment`.

---

## Routes & Networking

```bash
# Create route / Создать маршрут
oc expose svc/<SERVICE_NAME>                       # HTTP route / HTTP маршрут
oc create route edge --service=<SERVICE_NAME>      # HTTPS route (edge TLS) / HTTPS маршрут

# Manage routes / Управление маршрутами
oc get routes                                      # List routes / Список маршрутов
oc describe route <ROUTE_NAME>                     # Route details / Детали маршрута
oc delete route <ROUTE_NAME>                       # Delete route / Удалить маршрут

# Get route URL / Получить URL маршрута
oc get route <ROUTE_NAME> -o jsonpath='{.spec.host}'
```

### Route vs Ingress / Маршруты vs Ingress

| Feature | Route (OpenShift) | Ingress (Kubernetes) |
| :--- | :--- | :--- |
| TLS termination | Built-in (edge, passthrough, reencrypt) | Depends on Ingress controller |
| Wildcard domains | ✅ Supported | Depends on controller |
| API | `route.openshift.io/v1` | `networking.k8s.io/v1` |
| Best for | OpenShift-native apps | Multi-platform portability |

---

## Security

### Security Context Constraints (SCC) / Ограничения контекста безопасности

SCCs are OpenShift's extension of Kubernetes PodSecurityPolicies (now PodSecurityStandards). / SCC — расширение Kubernetes PodSecurityPolicies.

```bash
oc get scc                                         # List SCCs / Список SCC
oc describe scc restricted                         # SCC details / Детали SCC
oc adm policy add-scc-to-user anyuid -z <SA_NAME> -n <PROJECT>  # Grant SCC / Выдать SCC
oc adm policy who-can use scc anyuid               # Who has SCC / Кто имеет SCC
```

### OAuth & Identity / OAuth и идентификация

```bash
oc get oauth cluster -o yaml                       # OAuth config / Конфигурация OAuth
oc get identities                                  # List identities / Список идентификаций
oc get users                                       # List users / Список пользователей
oc adm groups new <GROUP_NAME>                     # Create group / Создать группу
oc adm groups add-users <GROUP_NAME> <USER>        # Add user to group / Добавить в группу
```

---

## Troubleshooting & Tools

### Events & Diagnostics / События и диагностика

```bash
oc get events --sort-by='.lastTimestamp'            # Recent events / Последние события
oc get events -n <PROJECT> --field-selector reason=Failed  # Failed events / Неудачные события
oc adm node-logs <NODE_NAME> -u kubelet            # Node kubelet logs / Логи kubelet узла
oc adm must-gather                                 # Collect diagnostic data / Собрать диагностику
```

### Image Streams & Registry / Потоки образов и реестр

```bash
oc get is -n openshift                             # OpenShift base images / Базовые образы OpenShift
oc describe is <IMAGE_STREAM> -n openshift         # IS details / Детали ImageStream
oc import-image <IMAGE>:<TAG> --from=<REGISTRY>/<IMAGE>:<TAG> --confirm  # Import image / Импорт образа
```

### Internal Registry / Внутренний реестр

```bash
# Login to internal registry / Вход во внутренний реестр
oc registry login

# Get registry URL / Получить URL реестра
oc registry info

# Push image to internal registry / Отправить образ во внутренний реестр
podman push <IMAGE> $(oc registry info)/<PROJECT>/<IMAGE>:<TAG>
```

### Common Issues Quick Reference / Краткий справочник проблем

| Issue / Проблема | Fix / Решение |
| :--- | :--- |
| **Pod CrashLoopBackOff** | `oc logs <POD>`, check SCC restrictions / Проверить SCC |
| **Permission denied (SCC)** | `oc adm policy add-scc-to-user` / Выдать нужный SCC |
| **ImagePullBackOff** | Check image stream, registry auth / Проверить IS и авторизацию |
| **Route not accessible** | Check router pods: `oc get pods -n openshift-ingress` |
| **Node NotReady** | `oc debug node/<NODE>`, check kubelet / Проверить kubelet |

---

## Sysadmin Essentials

### Important Paths / Важные пути

| Path / Путь | Description / Описание |
| :--- | :--- |
| `~/.kube/config` | Kubeconfig (same as K8s) / Kubeconfig |
| `/etc/kubernetes/` | Node-level K8s config / Конфигурация K8s на ноде |
| `/etc/origin/` | Legacy OpenShift 3.x config / Конфигурация OpenShift 3.x (устаревшее) |
| `/var/log/containers/` | Container logs on node / Логи контейнеров на ноде |

### oc vs kubectl Comparison / Сравнение oc и kubectl

| Feature | `oc` | `kubectl` |
| :--- | :--- | :--- |
| All kubectl commands | ✅ Yes | ✅ Yes |
| `oc new-app` | ✅ Yes | ❌ No |
| `oc new-project` | ✅ Yes | ❌ No (use `kubectl create ns`) |
| `oc rsh` | ✅ Yes | ❌ No (use `kubectl exec`) |
| `oc debug node` | ✅ Yes | ❌ No |
| OAuth login | ✅ Yes | ❌ No |
| Routes | ✅ Yes | ❌ No (use Ingress) |

---

## Documentation Links

- **OpenShift Official Documentation:** [https://docs.openshift.com/](https://docs.openshift.com/)
- **OpenShift CLI (oc) Reference:** [https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html)
- **OKD (Community Edition):** [https://www.okd.io/](https://www.okd.io/)
- **Red Hat OpenShift Product Page:** [https://www.redhat.com/en/technologies/cloud-computing/openshift](https://www.redhat.com/en/technologies/cloud-computing/openshift)
- **OpenShift GitHub:** [https://github.com/openshift](https://github.com/openshift)
- **OpenShift Interactive Learning:** [https://learn.openshift.com/](https://learn.openshift.com/)
