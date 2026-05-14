---
Title: AWX (Ansible Tower)
Group: Infrastructure Management
Icon: 🤖
Order: 2
---

# AWX (Ansible Tower) — IT Automation Platform

**Description / Описание:**
AWX is the open-source upstream project for **Red Hat Ansible Automation Platform** (formerly Ansible Tower). It provides a web-based UI, REST API, and task engine built on top of Ansible for centralized automation management. AWX allows teams to manage inventories, launch and schedule Ansible playbooks, track job results, and integrate with CI/CD pipelines via its REST API. It is widely used for infrastructure automation, configuration management, and orchestration.

> [!NOTE]
> **Current Status:** AWX is actively developed and is the de facto standard for self-hosted Ansible automation UI. For enterprise support, Red Hat offers **Ansible Automation Platform** (commercial). Alternatives include **Semaphore UI** (lightweight, Go-based), **Rundeck**, and **StackStorm**. / **Текущий статус:** AWX активно развивается. Для промышленной поддержки Red Hat предлагает **Ansible Automation Platform**. Альтернативы: **Semaphore UI**, **Rundeck**, **StackStorm**.

> **Default Ports:** Web UI: `8052` (HTTP), `8053` (HTTPS) | PostgreSQL: `5432`

---

## Table of Contents

1. [Installation & Configuration](#installation--configuration)
2. [Core Management](#core-management)
3. [Sysadmin Operations](#sysadmin-operations)
4. [Security](#security)
5. [Backup & Restore](#backup--restore)
6. [Troubleshooting & Tools](#troubleshooting--tools)
7. [Logrotate Configuration](#logrotate-configuration)
8. [Documentation Links](#documentation-links)

---

## Installation & Configuration

> [!IMPORTANT]
> AWX 18+ requires Kubernetes (K8s/K3s/Minikube) or Docker Compose for deployment. Standalone RPM/DEB installs are no longer supported. / AWX 18+ требует Kubernetes или Docker Compose для развёртывания.

### Install via AWX Operator (Kubernetes) / Установка через AWX Operator

```bash
# Install K3s (lightweight Kubernetes) / Установить K3s
curl -sfL https://get.k3s.io | sh -

# Install AWX Operator via Helm / Установить AWX Operator через Helm
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update
helm install awx-operator awx-operator/awx-operator -n awx --create-namespace
```

### AWX Instance CR / Ресурс AWX Instance

`awx-instance.yaml`

```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: NodePort
  nodeport_port: 30080
  admin_user: admin
  postgres_storage_class: local-path
```

```bash
# Deploy AWX instance / Развернуть AWX
kubectl apply -f awx-instance.yaml -n awx

# Check deployment status / Проверить статус развёртывания
kubectl get pods -n awx -w

# Get admin password / Получить пароль администратора
kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d; echo
```

### Install via Docker Compose / Установка через Docker Compose

```bash
# Clone AWX repository / Клонировать репозиторий AWX
git clone -b <VERSION_TAG> https://github.com/ansible/awx.git
cd awx

# Copy and edit inventory / Скопировать и отредактировать inventory
cp tools/docker-compose/inventory.example tools/docker-compose/inventory

# Build and start / Собрать и запустить
make docker-compose-build
make docker-compose
```

### Deployment Methods Comparison / Сравнение методов развёртывания

| Method / Метод | Complexity / Сложность | Production Ready | Best for / Лучше для... |
|:---|:---|:---|:---|
| **AWX Operator (K8s)** | High / Высокая | ✅ Yes | Production, HA, scale / Продакшен, HA, масштабирование |
| **K3s + Operator** | Medium / Средняя | ✅ Yes | Single-server prod / Продакшен на одном сервере |
| **Docker Compose** | Low / Низкая | ⚠️ Dev/Test only | Development, PoC / Разработка, PoC |
| **Minikube + Operator** | Medium / Средняя | ❌ No | Local testing / Локальное тестирование |

### Essential Configuration / Основная конфигурация

AWX settings are managed via the Web UI or REST API. Key settings:

```bash
# Configure AWX settings via CLI / Настроить AWX через CLI
awx-manage shell_plus  # Django management shell / Управляющая оболочка Django
```

```python
# In Django shell / В оболочке Django
from awx.conf.models import Setting
Setting.objects.filter(key='AWX_TASK_ENV').update(value={'ANSIBLE_TIMEOUT': '60'})
```

---

## Core Management

### Web UI Access / Доступ к веб-интерфейсу

```bash
# Web UI endpoints / Адреса веб-интерфейса
http://<HOST>:8052/           # Web UI
https://<HOST>:8053/          # HTTPS (if configured / если настроен)
http://<HOST>:8052/api/v2/    # REST API
```

### awx CLI (tower-cli replacement) / CLI awx

```bash
# Install awx CLI / Установить awx CLI
pip install awxkit

# Configure connection / Настроить подключение
export TOWER_HOST=http://<HOST>:8052
export TOWER_USERNAME=<USER>
export TOWER_PASSWORD=<PASSWORD>
```

### Common CLI Commands / Основные команды CLI

```bash
# List organizations / Список организаций
awx organizations list

# List projects / Список проектов
awx projects list

# List inventories / Список инвентарей
awx inventories list

# List job templates / Список шаблонов задач
awx job_templates list

# Launch a job / Запустить задачу
awx job_templates launch <TEMPLATE_ID> --monitor

# List running jobs / Список запущенных задач
awx jobs list --status running

# Cancel a job / Отменить задачу
awx jobs cancel <JOB_ID>

# List hosts in inventory / Список хостов в инвентаре
awx hosts list --inventory <INVENTORY_ID>

# List credentials / Список учётных данных
awx credentials list

# List workflow templates / Список шаблонов workflow
awx workflow_job_templates list
```

### AWX Object Hierarchy / Иерархия объектов AWX

| Object | Description / Описание | Parent |
|:---|:---|:---|
| Organization | Top-level grouping / Группировка верхнего уровня | — |
| Team | Group of users / Группа пользователей | Organization |
| Project | Ansible playbook source (Git, SVN) / Источник playbook | Organization |
| Inventory | Collection of hosts / Коллекция хостов | Organization |
| Credential | Auth secrets (SSH, API keys) / Секреты аутентификации | Organization |
| Job Template | Playbook + Inventory + Credential / Шаблон задачи | Project |
| Workflow | Chain of Job Templates / Цепочка шаблонов задач | Organization |

### Credential Types / Типы учётных данных

| Type | Use Case / Применение |
|:---|:---|
| Machine | SSH access to managed hosts / SSH-доступ к управляемым хостам |
| Source Control | Git/SVN project access / Доступ к проектам Git/SVN |
| Vault | Ansible Vault passwords / Пароли Ansible Vault |
| Network | Network device access / Доступ к сетевым устройствам |
| Cloud | AWS, GCP, Azure credentials / Учётные данные облаков |
| Container Registry | Docker/Podman registry auth / Авторизация в реестрах контейнеров |

---

## Sysadmin Operations

### Service Management (Kubernetes) / Управление сервисами (Kubernetes)

```bash
# Check AWX pods / Проверить поды AWX
kubectl get pods -n awx

# Check service status / Проверить статус сервисов
kubectl get svc -n awx

# View AWX task pod logs / Логи пода задач AWX
kubectl logs -f deployment/awx-task -n awx

# View AWX web pod logs / Логи веб-пода AWX
kubectl logs -f deployment/awx-web -n awx

# Restart AWX deployment / Перезапустить AWX
kubectl rollout restart deployment/awx-web -n awx
kubectl rollout restart deployment/awx-task -n awx

# Scale AWX workers / Масштабировать воркеры
kubectl scale deployment awx-task --replicas=3 -n awx
```

### Django Management Commands / Команды управления Django

```bash
# Enter AWX task container / Войти в контейнер задач AWX
kubectl exec -it deployment/awx-task -n awx -- bash

# Useful awx-manage commands inside container / Полезные команды awx-manage
awx-manage inventory_import --source=/path/to/hosts --inventory-name="<INVENTORY>"  # Import inventory / Импорт инвентаря
awx-manage createsuperuser                            # Create admin user / Создать суперпользователя
awx-manage changepassword <USER>                      # Change password / Сменить пароль
awx-manage cleanup_jobs --days=30                     # Clean old job data / Очистить старые данные задач
awx-manage cleanup_activitystream --days=90           # Clean activity stream / Очистить журнал активности
awx-manage list_instances                             # List cluster instances / Список экземпляров кластера
awx-manage update_password --username=admin --password=<PASSWORD>  # Reset admin password / Сбросить пароль admin
```

> [!WARNING]
> `cleanup_jobs` permanently deletes job history. Make sure to configure appropriate retention. / `cleanup_jobs` безвозвратно удаляет историю задач. Настройте подходящий период хранения.

### Important Paths (Container) / Важные пути (контейнер)

| Path / Путь | Description / Описание |
|:---|:---|
| `/var/lib/awx/projects/` | Project files (playbooks) / Файлы проектов |
| `/var/lib/awx/public/static/` | Static web assets / Статические веб-файлы |
| `/var/lib/awx/venv/` | Virtual environments / Виртуальные окружения |
| `/var/log/tower/` | AWX logs / Логи AWX |
| `/etc/tower/settings.py` | AWX settings / Настройки AWX |
| `/etc/tower/conf.d/` | Custom settings fragments / Фрагменты настроек |

### Log Locations / Расположение логов

```bash
# AWX task logs / Логи задач AWX
kubectl logs deployment/awx-task -n awx --tail=100

# AWX web logs / Логи веб-сервера AWX
kubectl logs deployment/awx-web -n awx --tail=100

# Inside container / Внутри контейнера
tail -f /var/log/tower/tower.log              # Main app log / Основной лог
tail -f /var/log/tower/callback_receiver.log  # Callback receiver / Приёмник callback
tail -f /var/log/tower/dispatcher.log         # Task dispatcher / Диспетчер задач
tail -f /var/log/tower/rsyslog.err            # Rsyslog errors / Ошибки rsyslog
```

---

## Security

### User & Team Management / Управление пользователями и командами

```bash
# Create user via CLI / Создать пользователя через CLI
awx users create --username <USER> --password <PASSWORD> --email <EMAIL>

# List users / Список пользователей
awx users list

# Add user to team / Добавить пользователя в команду
awx teams associate --user <USER_ID> <TEAM_ID>
```

### Role-Based Access Control (RBAC) / Ролевой доступ (RBAC)

| Role | Scope / Область | Description / Описание |
|:---|:---|:---|
| Admin | Organization | Full control / Полный контроль |
| Auditor | Organization | Read-only access / Доступ только на чтение |
| Execute | Job Template | Can run jobs / Может запускать задачи |
| Use | Credential/Inventory | Can use in templates / Может использовать в шаблонах |
| Update | Project | Can update from SCM / Может обновлять из SCM |
| Read | Any object | View-only / Только просмотр |

### LDAP/AD Integration / Интеграция с LDAP/AD

Configure via Web UI: **Settings → Authentication → LDAP**

Key parameters:

`/etc/tower/conf.d/ldap.py` (or via API)

```python
AUTH_LDAP_SERVER_URI = "ldaps://<LDAP_HOST>:636"
AUTH_LDAP_BIND_DN = "cn=<BIND_USER>,dc=example,dc=com"
AUTH_LDAP_BIND_PASSWORD = "<PASSWORD>"
AUTH_LDAP_USER_SEARCH = LDAPSearch("ou=users,dc=example,dc=com", ldap.SCOPE_SUBTREE, "(uid=%(user)s)")
```

---

## Backup & Restore

### Backup PostgreSQL / Резервная копия PostgreSQL

```bash
# From Kubernetes / Из Kubernetes
kubectl exec -it deployment/awx-postgres-13 -n awx -- \
  pg_dump -U awx -d awx | gzip > /backup/awx_db_$(date +%F).sql.gz

# Backup AWX secrets / Бэкап секретов AWX
kubectl get secret -n awx -o yaml > /backup/awx_secrets_$(date +%F).yaml
```

### Production Runbook: Full Backup / Полное резервное копирование

1. **Backup the database / Сделать бэкап БД:**

   ```bash
   kubectl exec -it deployment/awx-postgres-13 -n awx -- \
     pg_dump -U awx -d awx | gzip > /backup/awx_db_$(date +%F).sql.gz
   ```

2. **Backup Kubernetes secrets / Бэкап секретов K8s:**

   ```bash
   kubectl get secret -n awx -o yaml > /backup/awx_secrets_$(date +%F).yaml
   ```

3. **Verify backup integrity / Проверить целостность бэкапа:**

   ```bash
   ls -lh /backup/awx_db_$(date +%F).sql.gz
   gunzip -t /backup/awx_db_$(date +%F).sql.gz  # Test gzip integrity / Проверить целостность gzip
   ```

### Restore Runbook / Сценарий восстановления

> [!CAUTION]
> Restore will overwrite all current data. Perform only on a clean system or after understanding the full impact. / Восстановление перезапишет все данные. Выполняйте только на чистой системе.

1. **Restore database / Восстановить БД:**

   ```bash
   kubectl exec -i deployment/awx-postgres-13 -n awx -- \
     psql -U awx -d awx < <(gunzip -c /backup/awx_db_<DATE>.sql.gz)
   ```

2. **Restore secrets / Восстановить секреты:**

   ```bash
   kubectl apply -f /backup/awx_secrets_<DATE>.yaml
   ```

3. **Restart AWX pods / Перезапустить поды AWX:**

   ```bash
   kubectl rollout restart deployment/awx-web -n awx
   kubectl rollout restart deployment/awx-task -n awx
   ```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Jobs Stuck in "Pending" / Задачи зависли в "Pending"

```bash
# Check task pod logs / Проверить логи пода задач
kubectl logs deployment/awx-task -n awx --tail=50 | grep -i error

# Check dispatcher / Проверить диспетчер
kubectl exec -it deployment/awx-task -n awx -- awx-manage list_instances

# Restart task pod / Перезапустить под задач
kubectl rollout restart deployment/awx-task -n awx
```

#### 2. Project Sync Fails / Ошибка синхронизации проекта

```bash
# Check SCM credentials / Проверить SCM-credentials
awx credentials get <CREDENTIAL_ID>

# Test Git connectivity from container / Тест подключения к Git из контейнера
kubectl exec -it deployment/awx-task -n awx -- git ls-remote <REPO_URL>

# Clear project cache / Очистить кэш проекта
kubectl exec -it deployment/awx-task -n awx -- rm -rf /var/lib/awx/projects/<PROJECT_NAME>
```

> [!WARNING]
> Clearing project cache forces a full re-clone from SCM on next sync. Ensure SCM connectivity before clearing. / Очистка кэша проекта приведёт к полному повторному клонированию из SCM.

#### 3. High Memory Usage / Высокое потребление памяти

```bash
# Check pod resource usage / Проверить потребление ресурсов пода
kubectl top pods -n awx

# Cleanup old jobs / Очистить старые задачи
kubectl exec -it deployment/awx-task -n awx -- awx-manage cleanup_jobs --days=14
kubectl exec -it deployment/awx-task -n awx -- awx-manage cleanup_activitystream --days=30
```

### Common Issues Quick Reference / Краткий справочник проблем

| Issue / Проблема | Fix / Решение |
|:---|:---|
| **Jobs stuck in "Pending"** | Restart `awx-task` pod, check `list_instances` / Перезапустить `awx-task`, проверить `list_instances` |
| **Project sync fails** | Verify SCM credentials and network connectivity / Проверить SCM-credentials и сеть |
| **Web UI 502 errors** | Check `awx-web` pod logs, restart deployment / Проверить логи `awx-web`, перезапустить деплоймент |
| **High memory** | Run `cleanup_jobs`, check pod resource limits / Запустить `cleanup_jobs`, проверить лимиты ресурсов |
| **LDAP login fails** | Check LDAP config in `/etc/tower/conf.d/ldap.py` / Проверить конфиг LDAP |
| **API returns 401** | Token may be expired; regenerate via `/api/v2/tokens/` / Токен мог истечь; перегенерировать |

### API Examples / Примеры API

```bash
# Get API token / Получить API-токен
curl -s -X POST http://<HOST>:8052/api/v2/tokens/ \
  -H "Content-Type: application/json" \
  -u "<USER>:<PASSWORD>" | jq .token

# Launch job template via API / Запустить шаблон задачи через API
curl -s -X POST http://<HOST>:8052/api/v2/job_templates/<TEMPLATE_ID>/launch/ \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"env": "production"}}'

# Check job status / Проверить статус задачи
curl -s http://<HOST>:8052/api/v2/jobs/<JOB_ID>/ \
  -H "Authorization: Bearer <TOKEN>" | jq '.status, .failed'
```

---

## Logrotate Configuration

> [!NOTE]
> In Kubernetes deployments, logs are managed by the container runtime. This logrotate config applies to Docker Compose or local installs. / В Kubernetes-развёртываниях логи управляются средой выполнения контейнеров.

`/etc/logrotate.d/awx`

```conf
/var/log/tower/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 awx awx
    sharedscripts
    postrotate
        supervisorctl signal HUP tower-processes:* 2>/dev/null || true
    endscript
}
```

---

## Documentation Links

- **AWX Official Documentation:** [https://ansible.readthedocs.io/projects/awx/en/latest/](https://ansible.readthedocs.io/projects/awx/en/latest/)
- **AWX GitHub Repository:** [https://github.com/ansible/awx](https://github.com/ansible/awx)
- **AWX Operator GitHub:** [https://github.com/ansible/awx-operator](https://github.com/ansible/awx-operator)
- **AWX REST API Reference:** [https://ansible.readthedocs.io/projects/awx/en/latest/rest_api/](https://ansible.readthedocs.io/projects/awx/en/latest/rest_api/)
- **AWX CLI (awxkit) Documentation:** [https://docs.ansible.com/automation-controller/latest/html/controllercli/](https://docs.ansible.com/automation-controller/latest/html/controllercli/)
- **Red Hat Ansible Automation Platform (commercial):** [https://www.redhat.com/en/technologies/management/ansible](https://www.redhat.com/en/technologies/management/ansible)
