Title: ☁️ OpenStack
Group: Cloud
Icon: ☁️
Order: 1

# OpenStack Sysadmin Cheatsheet

> **OpenStack** is an open-source cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter. It is the de-facto standard for building private and public IaaS clouds. OpenStack is actively developed by a large community and widely adopted by enterprises, telecoms, and research institutions. While Kubernetes has taken over container orchestration, OpenStack remains the leading platform for managing virtualized infrastructure and bare-metal provisioning.
> / **OpenStack** — облачная операционная система с открытым исходным кодом для управления пулами вычислений, хранилищ и сетей. Стандарт де-факто для построения частных и публичных IaaS-облаков. Активно развивается и широко используется в корпоративном и телеком-секторах.

> **Role:** Cloud Admin / Cloud Engineer
> **CLI:** `openstack` (Unified Client — python-openstackclient)
> **Current Release Cycle:** 2024.x (Dalmatian) — releases every 6 months
> **Default Ports:** Keystone (Identity): `5000` | Nova (Compute): `8774` | Glance (Image): `9292` | Neutron (Network): `9696` | Cinder (Block Storage): `8776` | Horizon (Dashboard): `80`/`443` | Placement: `8778` | Swift (Object Storage): `8080` | Heat (Orchestration): `8004` | Barbican (Key Manager): `9311`

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Backup & Restore](#5-backup--restore)
6. [Troubleshooting & Tools](#6-troubleshooting--tools)
7. [Logrotate Configuration](#7-logrotate-configuration)

---

## 1. Installation & Configuration

> [!IMPORTANT]
> OpenStack deployment is complex. For production, use deployment tools like **Kolla-Ansible**, **TripleO**, **Charmed OpenStack (Juju)**, or **OpenStack-Ansible**. Manual installation is only recommended for learning. / Развёртывание OpenStack сложное. Для прода используйте Kolla-Ansible, TripleO или OpenStack-Ansible.

### Deployment Methods Comparison / Сравнение методов развёртывания

| Method | Description (EN / RU) | Best For |
|--------|----------------------|----------|
| **Kolla-Ansible** | Containerized deployment using Docker + Ansible / Контейнерное развёртывание через Docker + Ansible | Production, upgrades |
| **DevStack** | All-in-one developer setup script / Скрипт для разработки «всё в одном» | Development, testing |
| **TripleO** | OpenStack-on-OpenStack (undercloud→overcloud) / OpenStack поверх OpenStack | Large-scale telco/enterprise |
| **Charmed (Juju)** | Model-driven deployment via Canonical Juju / Модельное развёртывание через Juju | Ubuntu-based production |
| **Packstack** | Quick RDO-based deployment for RHEL/CentOS / Быстрое развёртывание на RDO | Small labs, PoC |
| **MicroStack (Sunbeam)** | Snap-based minimal cloud / Минимальное облако через Snap | Edge, single-node |

### DevStack (Development / Lab) / DevStack (Разработка / Лаборатория)

```bash
# Install prerequisites / Установить зависимости
sudo apt install -y git python3-pip  # Debian/Ubuntu

# Clone DevStack / Клонировать DevStack
git clone https://opendev.org/openstack/devstack.git
cd devstack

# Create config / Создать конфигурацию
cat > local.conf << 'EOF'
[[local|localrc]]
ADMIN_PASSWORD=<PASSWORD>
DATABASE_PASSWORD=<PASSWORD>
RABBIT_PASSWORD=<PASSWORD>
SERVICE_PASSWORD=<PASSWORD>
HOST_IP=<IP>
# Enable services / Включить сервисы
enable_service n-cpu n-api n-sch n-cond
enable_service g-api g-reg
enable_service q-svc q-agt q-dhcp q-l3 q-meta
enable_service c-api c-vol c-sch
enable_service horizon
EOF

# Run DevStack / Запустить DevStack
./stack.sh
```

> [!WARNING]
> DevStack is **NOT** suitable for production. It installs everything on a single node and does not survive reboots cleanly. / DevStack **НЕ** подходит для продакшена.

### Kolla-Ansible (Production) / Kolla-Ansible (Продакшен)

```bash
# Install Kolla-Ansible / Установить Kolla-Ansible
pip install kolla-ansible

# Generate config files / Сгенерировать конфигурационные файлы
kolla-ansible install-deps
kolla-ansible genconfig

# Deploy / Развернуть
kolla-ansible -i multinode bootstrap-servers   # Prepare hosts / Подготовить хосты
kolla-ansible -i multinode prechecks           # Pre-flight checks / Предварительная проверка
kolla-ansible -i multinode deploy              # Deploy services / Развернуть сервисы
kolla-ansible -i multinode post-deploy         # Post-deploy config / Пост-настройка
```

### Install OpenStack Client / Установка клиента OpenStack

```bash
# pip (recommended) / pip (рекомендуется)
pip install python-openstackclient

# Debian/Ubuntu
apt install python3-openstackclient

# RHEL/AlmaLinux (via RDO)
dnf install python3-openstackclient
```

### Authentication Setup / Настройка аутентификации

`~/admin-openrc.sh`

```bash
#!/bin/bash
# OpenStack RC file / RC-файл OpenStack
export OS_AUTH_URL=http://<HOST>:5000/v3
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USERNAME=admin
export OS_PASSWORD=<PASSWORD>
export OS_REGION_NAME=RegionOne
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3
```

```bash
# Source RC file to authenticate / Загрузить RC-файл для аутентификации
source ~/admin-openrc.sh

# Verify authentication / Проверить аутентификацию
openstack token issue  # Should return a token / Должен вернуть токен
```

---

## 2. Core Management

### OpenStack Core Services Overview / Обзор основных сервисов

| Service | Project | Port | Description (EN / RU) |
|---------|---------|------|----------------------|
| Identity | Keystone | `5000` | Authentication & authorization / Аутентификация и авторизация |
| Compute | Nova | `8774` | VM lifecycle management / Управление жизненным циклом ВМ |
| Image | Glance | `9292` | VM image registry / Реестр образов ВМ |
| Networking | Neutron | `9696` | SDN, routers, subnets, firewalls / SDN, маршрутизаторы, подсети |
| Block Storage | Cinder | `8776` | Persistent block volumes / Постоянные блочные тома |
| Object Storage | Swift | `8080` | S3-compatible object store / S3-совместимое хранилище объектов |
| Dashboard | Horizon | `80`/`443` | Web UI for management / Веб-интерфейс управления |
| Orchestration | Heat | `8004` | Infrastructure-as-Code templates / Шаблоны IaC |
| Placement | Placement | `8778` | Resource inventory tracking / Учёт ресурсов |

### Compute (Nova) / Вычисления (Nova)

```bash
# List instances / Список инстансов
openstack server list

# List instances (all projects — admin only) / Все проекты (только админ)
openstack server list --all-projects

# Show instance details / Детали инстанса
openstack server show <VM_NAME>

# Create instance / Создать инстанс
openstack server create \
  --flavor <FLAVOR> \
  --image <IMAGE> \
  --network <NET> \
  --key-name <KEY> \
  --security-group <SEC_GROUP> \
  <VM_NAME>

# Start / Stop / Reboot instance / Запуск / Остановка / Перезагрузка
openstack server start <VM_NAME>    # Start / Запустить
openstack server stop <VM_NAME>     # Stop / Остановить
openstack server reboot <VM_NAME>   # Soft reboot / Мягкая перезагрузка
openstack server reboot --hard <VM_NAME>  # Hard reboot / Жёсткая перезагрузка

# Resize instance / Изменить размер
openstack server resize --flavor <NEW_FLAVOR> <VM_NAME>
openstack server resize confirm <VM_NAME>   # Confirm resize / Подтвердить
openstack server resize revert <VM_NAME>    # Revert resize / Откатить

# Live migration / Живая миграция
openstack server migrate --live-migration --host <TARGET_HOST> <VM_NAME>

# Delete instance / Удалить инстанс
openstack server delete <VM_NAME>

# Console URL (VNC) / Ссылка на консоль (VNC)
openstack console url show <VM_NAME>

# Console log / Лог консоли
openstack console log show <VM_NAME>
```

> [!CAUTION]
> `openstack server delete` permanently destroys the instance and its root disk. Attached volumes may persist depending on `delete_on_termination` setting. / `openstack server delete` безвозвратно удаляет инстанс и его корневой диск.

### Flavors / Флейворы (Конфигурации)

```bash
# List flavors / Список флейворов
openstack flavor list

# Create flavor (admin) / Создать флейвор (админ)
openstack flavor create --ram 4096 --vcpus 2 --disk 40 m1.medium

# Show flavor details / Детали флейвора
openstack flavor show m1.medium

# Delete flavor / Удалить флейвор
openstack flavor delete m1.medium
```

### Image (Glance) / Образы (Glance)

```bash
# List images / Список образов
openstack image list

# Upload image / Загрузить образ
openstack image create "Ubuntu-24.04" \
  --file ubuntu-24.04-server-cloudimg-amd64.img \
  --disk-format qcow2 \
  --container-format bare \
  --public

# Download image / Скачать образ
openstack image save --file /tmp/image.qcow2 <IMAGE_ID>

# Delete image / Удалить образ
openstack image delete <IMAGE_ID>

# Set image properties / Установить свойства образа
openstack image set --property hw_disk_bus=scsi <IMAGE_ID>
```

### Networking (Neutron) / Сети (Neutron)

```bash
# List networks / Список сетей
openstack network list

# List subnets / Список подсетей
openstack subnet list

# Create network / Создать сеть
openstack network create <NET_NAME>

# Create subnet / Создать подсеть
openstack subnet create --network <NET_NAME> \
  --subnet-range 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --dns-nameserver 8.8.8.8 \
  <SUBNET_NAME>

# Create router / Создать маршрутизатор
openstack router create <ROUTER_NAME>
openstack router set --external-gateway <EXT_NET> <ROUTER_NAME>
openstack router add subnet <ROUTER_NAME> <SUBNET_NAME>

# List floating IPs / Список плавающих IP
openstack floating ip list

# Allocate floating IP / Выделить плавающий IP
openstack floating ip create <EXT_NET>

# Assign floating IP to instance / Назначить плавающий IP инстансу
openstack server add floating ip <VM_NAME> <FLOATING_IP>

# Security groups / Группы безопасности
openstack security group list
openstack security group rule create --proto tcp --dst-port 22 <SEC_GROUP>   # Allow SSH
openstack security group rule create --proto icmp <SEC_GROUP>                # Allow ping
```

### Storage (Cinder) / Хранилище (Cinder)

```bash
# List volumes / Список томов
openstack volume list

# Create volume / Создать том
openstack volume create --size 10 <VOL_NAME>

# Create volume from image / Том из образа
openstack volume create --size 20 --image <IMAGE> <VOL_NAME>

# Attach volume to instance / Подключить том к инстансу
openstack server add volume <VM_NAME> <VOL_NAME>

# Detach volume / Отключить том
openstack server remove volume <VM_NAME> <VOL_NAME>

# Create volume snapshot / Создать снимок тома
openstack volume snapshot create --volume <VOL_NAME> <SNAP_NAME>

# Delete volume / Удалить том
openstack volume delete <VOL_NAME>
```

> [!WARNING]
> You cannot delete a volume that is attached to an instance. Detach it first. / Нельзя удалить том, подключённый к инстансу. Сначала отключите его.

### Keypairs / Ключевые пары

```bash
# List keypairs / Список ключевых пар
openstack keypair list

# Create keypair / Создать ключевую пару
openstack keypair create <KEY_NAME> > ~/.ssh/<KEY_NAME>.pem
chmod 600 ~/.ssh/<KEY_NAME>.pem

# Import existing key / Импортировать существующий ключ
openstack keypair create --public-key ~/.ssh/id_rsa.pub <KEY_NAME>
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисами

```bash
# Keystone (Identity) / Keystone (Идентификация)
systemctl status apache2            # Keystone runs under Apache / Keystone работает под Apache
systemctl restart apache2           # Restart Keystone / Перезапустить Keystone

# Nova (Compute) / Nova (Вычисления)
systemctl status nova-api           # API service / API-сервис
systemctl status nova-scheduler     # Scheduler / Планировщик
systemctl status nova-conductor     # Conductor / Conductor
systemctl status nova-compute       # Compute agent (on each node) / Агент (на каждом узле)
systemctl restart nova-api nova-scheduler nova-conductor

# Neutron (Network) / Neutron (Сеть)
systemctl status neutron-server           # API server / API-сервер
systemctl status neutron-linuxbridge-agent  # L2 agent / L2-агент
systemctl status neutron-dhcp-agent       # DHCP agent / DHCP-агент
systemctl status neutron-l3-agent         # L3/router agent / L3-агент
systemctl status neutron-metadata-agent   # Metadata agent / Агент метаданных

# Glance (Image) / Glance (Образы)
systemctl status glance-api         # Image API / API образов

# Cinder (Block Storage) / Cinder (Блочное хранилище)
systemctl status cinder-api         # API / API
systemctl status cinder-scheduler   # Scheduler / Планировщик
systemctl status cinder-volume      # Volume manager / Менеджер томов

# Horizon (Dashboard) / Horizon (Веб-панель)
systemctl status apache2            # Horizon runs under Apache / Horizon под Apache
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/etc/keystone/` | Keystone configs / Конфиги Keystone |
| `/etc/nova/` | Nova configs / Конфиги Nova |
| `/etc/neutron/` | Neutron configs / Конфиги Neutron |
| `/etc/glance/` | Glance configs / Конфиги Glance |
| `/etc/cinder/` | Cinder configs / Конфиги Cinder |
| `/etc/horizon/` or `/etc/openstack-dashboard/` | Horizon configs / Конфиги Horizon |
| `/var/log/nova/` | Nova logs / Логи Nova |
| `/var/log/neutron/` | Neutron logs / Логи Neutron |
| `/var/log/keystone/` | Keystone logs / Логи Keystone |
| `/var/log/glance/` | Glance logs / Логи Glance |
| `/var/log/cinder/` | Cinder logs / Логи Cinder |
| `/var/lib/nova/instances/` | VM instance data / Данные инстансов |
| `/var/lib/glance/images/` | Glance image storage / Хранилище образов |

### Log Locations / Расположение логов

```bash
# Nova logs / Логи Nova
tail -f /var/log/nova/nova-api.log           # API log / Лог API
tail -f /var/log/nova/nova-compute.log       # Compute log / Лог compute
tail -f /var/log/nova/nova-scheduler.log     # Scheduler log / Лог планировщика

# Neutron logs / Логи Neutron
tail -f /var/log/neutron/server.log          # Neutron server / Сервер Neutron
tail -f /var/log/neutron/l3-agent.log        # L3 agent / L3-агент
tail -f /var/log/neutron/dhcp-agent.log      # DHCP agent / DHCP-агент

# Keystone / Keystone
tail -f /var/log/keystone/keystone.log       # Keystone log / Лог Keystone
# or via Apache / или через Apache
tail -f /var/log/apache2/keystone*.log

# Glance / Glance
tail -f /var/log/glance/api.log              # Glance API / API Glance

# Cinder / Cinder
tail -f /var/log/cinder/cinder-api.log       # Cinder API / API Cinder
tail -f /var/log/cinder/cinder-volume.log    # Volume service / Сервис томов
```

### Service Status Check / Проверка статуса сервисов

```bash
# Check all compute services / Проверить все compute-сервисы
openstack compute service list

# Check network agents / Проверить сетевые агенты
openstack network agent list

# Check volume services / Проверить сервисы хранилища
openstack volume service list

# Check endpoints / Проверить эндпоинты
openstack endpoint list

# Check Hypervisor stats / Статистика гипервизоров
openstack hypervisor list
openstack hypervisor stats show
openstack hypervisor show <HYPERVISOR_NAME>
```

### Firewall Configuration / Настройка фаервола

```bash
# Controller node ports / Порты контроллера
firewall-cmd --permanent --add-port=5000/tcp    # Keystone
firewall-cmd --permanent --add-port=8774/tcp    # Nova API
firewall-cmd --permanent --add-port=8775/tcp    # Nova metadata
firewall-cmd --permanent --add-port=9292/tcp    # Glance
firewall-cmd --permanent --add-port=9696/tcp    # Neutron
firewall-cmd --permanent --add-port=8776/tcp    # Cinder
firewall-cmd --permanent --add-port=8778/tcp    # Placement
firewall-cmd --permanent --add-port=5672/tcp    # RabbitMQ (AMQP)
firewall-cmd --permanent --add-port=11211/tcp   # Memcached
firewall-cmd --permanent --add-port=6080/tcp    # noVNC console proxy
firewall-cmd --permanent --add-port=443/tcp     # Horizon HTTPS

# Compute node ports / Порты compute-узла
firewall-cmd --permanent --add-port=5900-5999/tcp  # VNC consoles / VNC-консоли
firewall-cmd --permanent --add-port=16509/tcp      # Libvirt (live migration) / Живая миграция
firewall-cmd --permanent --add-port=49152-49261/tcp  # QEMU live migration

firewall-cmd --reload  # Apply rules / Применить правила
```

### Quota Management / Управление квотами

```bash
# Show project quotas / Показать квоты проекта
openstack quota show <PROJECT_NAME>

# Update quotas / Обновить квоты
openstack quota set --instances 50 --cores 100 --ram 204800 <PROJECT_NAME>
openstack quota set --volumes 100 --gigabytes 5000 <PROJECT_NAME>
openstack quota set --floating-ips 20 <PROJECT_NAME>
```

---

## 4. Security

### Keystone (Identity Service) / Keystone (Служба идентификации)

```bash
# List users / Список пользователей
openstack user list

# Create user / Создать пользователя
openstack user create --domain Default --project <PROJECT> --password <PASSWORD> <USER>

# List projects (tenants) / Список проектов
openstack project list

# Create project / Создать проект
openstack project create --domain Default --description "Description" <PROJECT_NAME>

# List roles / Список ролей
openstack role list

# Assign role to user / Назначить роль пользователю
openstack role add --project <PROJECT> --user <USER> <ROLE>

# Revoke role / Отозвать роль
openstack role remove --project <PROJECT> --user <USER> <ROLE>
```

### Role Types / Типы ролей

| Role | Description / Описание |
|------|------------------------|
| `admin` | Full administrative access / Полный административный доступ |
| `member` | Standard project operations / Стандартные операции проекта |
| `reader` | Read-only access / Доступ только на чтение |

### Domain Management / Управление доменами

```bash
# List domains / Список доменов
openstack domain list

# Create domain / Создать домен
openstack domain create <DOMAIN_NAME>

# Create user in specific domain / Создать пользователя в конкретном домене
openstack user create --domain <DOMAIN> --password <PASSWORD> <USER>
```

### SSL/TLS Configuration / Настройка SSL/TLS

`/etc/keystone/keystone.conf`

```ini
[ssl]
enable = true
certfile = /etc/keystone/ssl/certs/keystone.pem
keyfile = /etc/keystone/ssl/private/keystone-key.pem
ca_certs = /etc/keystone/ssl/certs/ca.pem
```

```bash
# Generate self-signed certificate / Сгенерировать самоподписанный сертификат
openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/keystone/ssl/private/keystone-key.pem \
  -out /etc/keystone/ssl/certs/keystone.pem \
  -days 365 -nodes \
  -subj "/CN=<HOST>/O=<ORG>/C=<COUNTRY_CODE>"
```

### Application Credentials / Учётные данные приложений

```bash
# Create application credential (no password exposure) / Создать учётные данные приложения
openstack application credential create <CRED_NAME> \
  --secret <SECRET_KEY> \
  --role member

# Use in clouds.yaml / Использование в clouds.yaml
# ~/.config/openstack/clouds.yaml
```

`~/.config/openstack/clouds.yaml`

```yaml
clouds:
  mycloud:
    auth_type: v3applicationcredential
    auth:
      auth_url: http://<HOST>:5000/v3
      application_credential_id: <CRED_ID>
      application_credential_secret: <SECRET_KEY>
```

---

## 5. Backup & Restore

> [!CAUTION]
> Always coordinate backups with service maintenance windows. Backing up databases while services are writing can cause inconsistencies. / Всегда координируйте бэкапы с окнами обслуживания. Бэкап БД во время записи может привести к несогласованности данных.

### Database Backup Runbook / Сценарий резервного копирования БД

1. **Identify databases / Определить базы данных:**

```bash
# OpenStack typically uses these databases / Обычно используются эти БД:
# keystone, nova, nova_api, nova_cell0, neutron, glance, cinder, placement, heat
mysql -u root -p<PASSWORD> -e "SHOW DATABASES;" | grep -E "keystone|nova|neutron|glance|cinder|placement|heat"
```

2. **Dump all OpenStack databases / Дамп всех БД OpenStack:**

```bash
# Full backup / Полный бэкап
BACKUP_DIR="/backup/openstack/$(date +%F)"
mkdir -p "$BACKUP_DIR"

for db in keystone nova nova_api nova_cell0 neutron glance cinder placement; do
  mysqldump -u root -p<PASSWORD> --single-transaction --routines --triggers "$db" \
    | gzip > "${BACKUP_DIR}/${db}.sql.gz"
done
```

3. **Backup configuration files / Бэкап конфигурации:**

```bash
tar -czf /backup/openstack/openstack_conf_$(date +%F).tar.gz \
  /etc/keystone /etc/nova /etc/neutron /etc/glance /etc/cinder /etc/horizon
```

4. **Backup Glance images / Бэкап образов Glance:**

```bash
tar -czf /backup/openstack/glance_images_$(date +%F).tar.gz /var/lib/glance/images/
```

### Database Restore / Восстановление БД

```bash
# Restore a single database / Восстановить одну БД
gunzip -c /backup/openstack/<DATE>/keystone.sql.gz | mysql -u root -p<PASSWORD> keystone

# Restore and sync DB schema / Восстановить и синхронизировать схему
keystone-manage db_sync         # Keystone
nova-manage db sync             # Nova
neutron-db-manage upgrade head  # Neutron
glance-manage db_sync           # Glance
cinder-manage db sync           # Cinder
```

### Volume Snapshots / Снапшоты томов

```bash
# Create volume snapshot / Создать снимок тома
openstack volume snapshot create --volume <VOL_NAME> <SNAP_NAME>

# List snapshots / Список снимков
openstack volume snapshot list

# Restore from snapshot (create new volume) / Восстановить из снимка
openstack volume create --snapshot <SNAP_NAME> --size 20 <NEW_VOL_NAME>
```

### Instance Snapshots / Снапшоты инстансов

```bash
# Create instance snapshot (image) / Создать снимок инстанса
openstack server image create --name <SNAP_NAME> <VM_NAME>

# List snapshots / Список снимков
openstack image list --property image_type=snapshot
```

---

## 6. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Service Not Responding / Сервис не отвечает

```bash
# Check service status / Проверить статус сервиса
openstack compute service list   # Should show "up" / Должен показать "up"
openstack network agent list     # Check alive status / Проверить статус

# Check RabbitMQ / Проверить RabbitMQ
systemctl status rabbitmq-server
rabbitmqctl list_queues | head -20

# Check database connectivity / Проверить подключение к БД
mysql -u <USER> -p<PASSWORD> -e "SELECT 1"

# Check Memcached / Проверить Memcached
systemctl status memcached
echo stats | nc localhost 11211
```

#### 2. Instance Stuck in ERROR / Инстанс завис в ERROR

```bash
# Check instance fault / Проверить ошибку инстанса
openstack server show <VM_NAME> -c fault

# Check nova-compute log on the host / Проверить лог nova-compute
grep -i "error\|exception" /var/log/nova/nova-compute.log | tail -20

# Force-delete stuck instance / Принудительно удалить зависший инстанс
openstack server delete --force <VM_NAME>

# Reset instance state / Сбросить состояние инстанса
nova reset-state --active <VM_UUID>
```

#### 3. Network Connectivity Issues / Проблемы с сетью

```bash
# Check Neutron agents / Проверить агенты Neutron
openstack network agent list   # All should be "alive" / Все должны быть "alive"

# Check OVS/Linux bridge / Проверить OVS/Linux bridge
ovs-vsctl show                 # Open vSwitch status
brctl show                     # Linux bridge status

# Check namespaces / Проверить пространства имён
ip netns list                  # List network namespaces / Список namespace
ip netns exec qdhcp-<NET_UUID> ip a   # Check DHCP namespace / Проверить DHCP namespace

# Test from router namespace / Тест из namespace маршрутизатора
ip netns exec qrouter-<ROUTER_UUID> ping <IP>
```

#### 4. Cinder Volume Issues / Проблемы с томами Cinder

```bash
# Volume stuck in "creating" or "deleting" / Том завис в "creating" или "deleting"
cinder reset-state --state available <VOL_UUID>
cinder reset-state --state error <VOL_UUID>   # Then delete / Затем удалить

# Check LVM backend / Проверить LVM бэкенд
lvs                            # List logical volumes / Список LV
vgs                            # List volume groups / Список VG
pvs                            # List physical volumes / Список PV
```

### Useful Administrative Commands / Полезные административные команды

```bash
# List all resources across projects / Ресурсы всех проектов
openstack server list --all-projects
openstack volume list --all-projects
openstack floating ip list

# Check resource usage / Проверить использование ресурсов
openstack hypervisor stats show

# List all endpoints / Все эндпоинты
openstack endpoint list

# Catalog (service registry) / Каталог (реестр сервисов)
openstack catalog list

# Token management / Управление токенами
openstack token issue           # Issue new token / Выпустить токен
openstack token revoke <TOKEN>  # Revoke token / Отозвать токен

# DB management commands / Команды управления БД
nova-manage db sync             # Sync Nova DB / Синхронизировать БД Nova
nova-manage cell_v2 discover_hosts  # Discover new compute hosts / Обнаружить хосты
```

### Health Check Script / Скрипт проверки здоровья

```bash
#!/bin/bash
# Quick OpenStack health check / Быстрая проверка OpenStack
echo "=== Compute Services ==="
openstack compute service list -f value -c Binary -c Status -c State

echo "=== Network Agents ==="
openstack network agent list -f value -c "Agent Type" -c Alive -c State

echo "=== Volume Services ==="
openstack volume service list -f value -c Binary -c Status -c State

echo "=== Hypervisor Summary ==="
openstack hypervisor stats show -f value -c vcpus -c vcpus_used -c memory_mb -c memory_mb_used
```

---

## 7. Logrotate Configuration

`/etc/logrotate.d/openstack`

```conf
/var/log/nova/*.log
/var/log/neutron/*.log
/var/log/keystone/*.log
/var/log/glance/*.log
/var/log/cinder/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        # Reload services to reopen log files / Перезагрузить сервисы для переоткрытия логов
        systemctl reload apache2 2>/dev/null || true
        for svc in nova-api nova-scheduler nova-conductor nova-compute \
                   neutron-server glance-api cinder-api cinder-scheduler cinder-volume; do
            systemctl kill --signal=HUP "$svc" 2>/dev/null || true
        done
    endscript
}
```

---
