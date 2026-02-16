Title: ☸️ OpenShift (OCP)
Group: Kubernetes & Containers
Icon: ☸️
Order: 10

# OpenShift (OCP) Cheatsheet

> **Context:** Red Hat OpenShift Container Platform is an enterprise Kubernetes platform. / Red Hat OpenShift - корпоративная платформа Kubernetes.
> **Role:** DevOps / Developer / Cluster Admin
> **CLI:** `oc` (Superset of `kubectl`) / `oc` (Надмножество `kubectl`)

---

## 📚 Table of Contents / Содержание

1. [Authentication & Context](#authentication--context--аутентификация-и-контекст)
2. [Core Operations](#core-operations--простые-операции)
3. [Admin Operations](#admin-operations-admin-only--админские-операции)
4. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Authentication & Context / Аутентификация и Контекст

### Login / Вход

```bash
# Login via Token / Вход по токену
oc login --token=<TOKEN> --server=https://api.<CLUSTER>:6443

# Login with User/Pass / Вход по логину/паролю
oc login -u <USER> -p <PASSWORD> https://api.<CLUSTER>:6443

# Login as System Admin (if certs available) / Вход как админ
export KUBECONFIG=<PATH_TO_KUBECONFIG>
oc whoami
```

### Project Management / Управление проектами (Namespaces)

```bash
# Switch Project / Переключить проект
oc project <PROJECT_NAME>

# New Project / Новый проект
oc new-project <PROJECT_NAME>

# List Projects / Список проектов
oc get projects
```

---

## 2. Core Operations / Простые операции

The same as Kubernetes (`kubectl`), but `oc` specific aliases exist. / То же, что и Kubernetes, но есть алиасы `oc`.

### Get Resources / Получение ресурсов

```bash
oc get pods
oc get svc
oc get routes  # OpenShift specific Ingress / Специфичный для OCP Ingress
oc get dc      # DeploymentConfig (Legacy) / DeploymentConfig (Устаревшее)
```

### Logs & Exec / Логи и вход

```bash
# Container Logs / Логи контейнера
oc logs -f <POD_NAME>

# Exec bash / Зайти в баш
oc rsh <POD_NAME>   # 'oc rsh' is friendlier than 'exec -it' / 'oc rsh' удобнее 'exec -it'
```

---

## 3. Admin Operations (Admin Only) / Админские операции

### Node Management / Управление узлами

```bash
# List Nodes / Список узлов
oc get nodes

# Debug Node (Mounts host OS) / Отладка узла (Монтирует хостовую ОС)
oc debug node/<NODE_NAME>
# -> chroot /host
```

### Policy & Users / Политики и пользователи

```bash
# Add Admin Role to User / Дать админа пользователю
oc adm policy add-cluster-role-to-user cluster-admin <USER>

# Add View Role in Project / Дать права просмотра в проекте
oc policy add-role-to-user view <USER> -n <PROJECT>
```

---

## 4. Troubleshooting / Устранение неполадок

### Events / События

```bash
oc get events --sort-by='.lastTimestamp'
```

### Image Streams / Потоки образов
OpenShift internal registry objects. / Объекты внутреннего реестра OpenShift.

```bash
oc get is -n openshift
```
