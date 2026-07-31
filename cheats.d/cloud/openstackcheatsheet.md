---
Title: ☁️ OpenStack
Group: Cloud
Icon: ☁️
Order: 1
tags:
  - cloud
  - sysadmin
---

# OpenStack Sysadmin Cheatsheet

> **OpenStack** is an open-source cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter. It is the de-facto standard for building private and public IaaS clouds. OpenStack is actively developed by a large community and widely adopted by enterprises, telecoms, and research institutions. While Kubernetes has taken over container orchestration, OpenStack remains the leading platform for managing virtualized infrastructure and bare-metal provisioning.
> / **OpenStack** — облачная операционная система с открытым исходным кодом для управления пулами вычислений, хранилищ и сетей. Стандарт де-факто для построения частных и публичных IaaS-облаков. Активно развивается и широко используется в корпоративном и телеком-секторах.

> **Role:** Cloud Admin / Cloud Engineer
> **CLI:** `openstack` (Unified Client — python-openstackclient)
> **Current Release Cycle:** 2024.x (Dalmatian) — releases every 6 months
> **Default Ports:** Keystone (Identity): `5000` | Nova (Compute): `8774` | Glance (Image): `9292` | Neutron (Network): `9696` | Cinder (Block Storage): `8776` | Horizon (Dashboard): `80`/`443` | Placement: `8778` | Swift (Object Storage): `8080` | Heat (Orchestration): `8004` | Barbican (Key Manager): `9311`

---

## 📚 Table of Contents

- [1. Installation & Configuration](#1.%20Installation%20&%20Configuration)
- [2. Core Management](#2.%20Core%20Management)
- [3. Sysadmin Operations](#3.%20Sysadmin%20Operations)
- [4. Security](#4.%20Security)
- [5. Backup & Restore](#5.%20Backup%20&%20Restore)
- [6. Troubleshooting & Tools](#6.%20Troubleshooting%20&%20Tools)
- [7. Logrotate Configuration](#7.%20Logrotate%20Configuration)
- [📖 Documentation](#📖%20Documentation)

---

## 1. Installation & Configuration

> [!IMPORTANT]
> OpenStack deployment is complex. For production, use deployment tools like **Kolla-Ansible**, **TripleO**, **Charmed OpenStack (Juju)**, or **OpenStack-Ansible**. Manual installation is only recommended for learning. / Развёртывание OpenStack сложное. Для прода используйте Kolla-Ansible, TripleO или OpenStack-Ansible.

### Deployment Methods Comparison

| Method | Description (EN / RU) | Best For |
|--------|----------------------|----------|
| **Kolla-Ansible** | Containerized deployment using Docker + Ansible / Контейнерное развёртывание через Docker + Ansible | Production, upgrades |
| **DevStack** | All-in-one developer setup script / Скрипт для разработки «всё в одном» | Development, testing |
| **TripleO** | OpenStack-on-OpenStack (undercloud→overcloud) / OpenStack поверх OpenStack | Large-scale telco/enterprise |
| **Charmed (Juju)** | Model-driven deployment via Canonical Juju / Модельное развёртывание через Juju | Ubuntu-based production |
| **Packstack** | Quick RDO-based deployment for RHEL/CentOS / Быстрое развёртывание на RDO | Small labs, PoC |
| **MicroStack (Sunbeam)** | Snap-based minimal cloud / Минимальное облако через Snap | Edge, single-node |

### DevStack (Development / Lab) / DevStack (Разработка

```bash
# Install prerequisites
sudo apt install -y git python3-pip  # Debian/Ubuntu

# Clone DevStack
git clone https://opendev.org/openstack/devstack.git
cd devstack

# Create config
cat > local.conf << 'EOF'
[[local|localrc]]
ADMIN_PASSWORD=<PASSWORD>
DATABASE_PASSWORD=<PASSWORD>
RABBIT_PASSWORD=<PASSWORD>
SERVICE_PASSWORD=<PASSWORD>
HOST_IP=<IP>
# Enable services
enable_service n-cpu n-api n-sch n-cond
enable_service g-api g-reg
enable_service q-svc q-agt q-dhcp q-l3 q-meta
enable_service c-api c-vol c-sch
enable_service horizon
EOF

# Run DevStack
./stack.sh
```

> [!WARNING]
> DevStack is **NOT** suitable for production. It installs everything on a single node and does not survive reboots cleanly. / DevStack **НЕ** подходит для продакшена.

### Kolla-Ansible (Production) / Kolla-Ansible

```bash
# Install Kolla-Ansible
pip install kolla-ansible

# Generate config files
kolla-ansible install-deps
kolla-ansible genconfig

# Deploy
kolla-ansible -i multinode bootstrap-servers   # Prepare hosts / Подготовить хосты
kolla-ansible -i multinode prechecks           # Pre-flight checks / Предварительная проверка
kolla-ansible -i multinode deploy              # Deploy services / Развернуть сервисы
kolla-ansible -i multinode post-deploy         # Post-deploy config / Пост-настройка
```

### Install OpenStack Client

```bash
# pip (recommended) / pip
pip install python-openstackclient

# Debian/Ubuntu
apt install python3-openstackclient

# RHEL/AlmaLinux (via RDO)
dnf install python3-openstackclient
```

### Authentication Setup

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
# Source RC file to authenticate
source ~/admin-openrc.sh

# Verify authentication
openstack token issue  # Should return a token / Должен вернуть токен
```

---

## 2. Core Management

### OpenStack Core Services Overview

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

### Compute (Nova)

```bash
# List instances
openstack server list

# List instances (all projects — admin only)
openstack server list --all-projects

# Show instance details
openstack server show <VM_NAME>

# Create instance
openstack server create \
  --flavor <FLAVOR> \
  --image <IMAGE> \
  --network <NET> \
  --key-name <KEY> \
  --security-group <SEC_GROUP> \
  <VM_NAME>

# Start / Stop / Reboot instance
openstack server start <VM_NAME>    # Start / Запустить
openstack server stop <VM_NAME>     # Stop / Остановить
openstack server reboot <VM_NAME>   # Soft reboot / Мягкая перезагрузка
openstack server reboot --hard <VM_NAME>  # Hard reboot / Жёсткая перезагрузка

# Resize instance
openstack server resize --flavor <NEW_FLAVOR> <VM_NAME>
openstack server resize confirm <VM_NAME>   # Confirm resize / Подтвердить
openstack server resize revert <VM_NAME>    # Revert resize / Откатить

# Live migration
openstack server migrate --live-migration --host <TARGET_HOST> <VM_NAME>

# Delete instance
openstack server delete <VM_NAME>

# Console URL (VNC)
openstack console url show <VM_NAME>

# Console log
openstack console log show <VM_NAME>
```

> [!CAUTION]
> `openstack server delete` permanently destroys the instance and its root disk. Attached volumes may persist depending on `delete_on_termination` setting. / `openstack server delete` безвозвратно удаляет инстанс и его корневой диск.

### Flavors

```bash
# List flavors
openstack flavor list

# Create flavor (admin)
openstack flavor create --ram 4096 --vcpus 2 --disk 40 m1.medium

# Show flavor details
openstack flavor show m1.medium

# Delete flavor
openstack flavor delete m1.medium
```

### Image (Glance)

```bash
# List images
openstack image list

# Upload image
openstack image create "Ubuntu-24.04" \
  --file ubuntu-24.04-server-cloudimg-amd64.img \
  --disk-format qcow2 \
  --container-format bare \
  --public

# Download image
openstack image save --file /tmp/image.qcow2 <IMAGE_ID>

# Delete image
openstack image delete <IMAGE_ID>

# Set image properties
openstack image set --property hw_disk_bus=scsi <IMAGE_ID>
```

### Networking (Neutron)

```bash
# List networks
openstack network list

# List subnets
openstack subnet list

# Create network
openstack network create <NET_NAME>

# Create subnet
openstack subnet create --network <NET_NAME> \
  --subnet-range 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --dns-nameserver 8.8.8.8 \
  <SUBNET_NAME>

# Create router
openstack router create <ROUTER_NAME>
openstack router set --external-gateway <EXT_NET> <ROUTER_NAME>
openstack router add subnet <ROUTER_NAME> <SUBNET_NAME>

# List floating IPs
openstack floating ip list

# Allocate floating IP
openstack floating ip create <EXT_NET>

# Assign floating IP to instance
openstack server add floating ip <VM_NAME> <FLOATING_IP>

# Security groups
openstack security group list
openstack security group rule create --proto tcp --dst-port 22 <SEC_GROUP>   # Allow SSH
openstack security group rule create --proto icmp <SEC_GROUP>                # Allow ping
```

### Storage (Cinder)

```bash
# List volumes
openstack volume list

# Create volume
openstack volume create --size 10 <VOL_NAME>

# Create volume from image
openstack volume create --size 20 --image <IMAGE> <VOL_NAME>

# Attach volume to instance
openstack server add volume <VM_NAME> <VOL_NAME>

# Detach volume
openstack server remove volume <VM_NAME> <VOL_NAME>

# Create volume snapshot
openstack volume snapshot create --volume <VOL_NAME> <SNAP_NAME>

# Delete volume
openstack volume delete <VOL_NAME>
```

> [!WARNING]
> You cannot delete a volume that is attached to an instance. Detach it first. / Нельзя удалить том, подключённый к инстансу. Сначала отключите его.

### Keypairs

```bash
# List keypairs
openstack keypair list

# Create keypair
openstack keypair create <KEY_NAME> > ~/.ssh/<KEY_NAME>.pem
chmod 600 ~/.ssh/<KEY_NAME>.pem

# Import existing key
openstack keypair create --public-key ~/.ssh/id_rsa.pub <KEY_NAME>
```

---

## 3. Sysadmin Operations

### Service Management

```bash
# Keystone (Identity) / Keystone
systemctl status apache2            # Keystone runs under Apache / Keystone работает под Apache
systemctl restart apache2           # Restart Keystone / Перезапустить Keystone

# Nova (Compute) / Nova
systemctl status nova-api           # API service / API-сервис
systemctl status nova-scheduler     # Scheduler / Планировщик
systemctl status nova-conductor     # Conductor / Conductor
systemctl status nova-compute       # Compute agent (on each node) / Агент (на каждом узле)
systemctl restart nova-api nova-scheduler nova-conductor

# Neutron (Network) / Neutron
systemctl status neutron-server           # API server / API-сервер
systemctl status neutron-linuxbridge-agent  # L2 agent / L2-агент
systemctl status neutron-dhcp-agent       # DHCP agent / DHCP-агент
systemctl status neutron-l3-agent         # L3/router agent / L3-агент
systemctl status neutron-metadata-agent   # Metadata agent / Агент метаданных

# Glance (Image) / Glance
systemctl status glance-api         # Image API / API образов

# Cinder (Block Storage) / Cinder
systemctl status cinder-api         # API / API
systemctl status cinder-scheduler   # Scheduler / Планировщик
systemctl status cinder-volume      # Volume manager / Менеджер томов

# Horizon (Dashboard) / Horizon
systemctl status apache2            # Horizon runs under Apache / Horizon под Apache
```

### Important Paths

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

### Log Locations

```bash
# Nova logs
tail -f /var/log/nova/nova-api.log           # API log / Лог API
tail -f /var/log/nova/nova-compute.log       # Compute log / Лог compute
tail -f /var/log/nova/nova-scheduler.log     # Scheduler log / Лог планировщика

# Neutron logs
tail -f /var/log/neutron/server.log          # Neutron server / Сервер Neutron
tail -f /var/log/neutron/l3-agent.log        # L3 agent / L3-агент
tail -f /var/log/neutron/dhcp-agent.log      # DHCP agent / DHCP-агент

# Keystone / Keystone
tail -f /var/log/keystone/keystone.log       # Keystone log / Лог Keystone
# or via Apache
tail -f /var/log/apache2/keystone*.log

# Glance / Glance
tail -f /var/log/glance/api.log              # Glance API / API Glance

# Cinder / Cinder
tail -f /var/log/cinder/cinder-api.log       # Cinder API / API Cinder
tail -f /var/log/cinder/cinder-volume.log    # Volume service / Сервис томов
```

### Service Status Check

```bash
# Check all compute services
openstack compute service list

# Check network agents
openstack network agent list

# Check volume services
openstack volume service list

# Check endpoints
openstack endpoint list

# Check Hypervisor stats
openstack hypervisor list
openstack hypervisor stats show
openstack hypervisor show <HYPERVISOR_NAME>
```

### Firewall Configuration

```bash
# Controller node ports
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

# Compute node ports
firewall-cmd --permanent --add-port=5900-5999/tcp  # VNC consoles / VNC-консоли
firewall-cmd --permanent --add-port=16509/tcp      # Libvirt (live migration) / Живая миграция
firewall-cmd --permanent --add-port=49152-49261/tcp  # QEMU live migration

firewall-cmd --reload  # Apply rules / Применить правила
```

### Quota Management

```bash
# Show project quotas
openstack quota show <PROJECT_NAME>

# Update quotas
openstack quota set --instances 50 --cores 100 --ram 204800 <PROJECT_NAME>
openstack quota set --volumes 100 --gigabytes 5000 <PROJECT_NAME>
openstack quota set --floating-ips 20 <PROJECT_NAME>
```

---

## 4. Security

### Keystone (Identity Service) / Keystone

```bash
# List users
openstack user list

# Create user
openstack user create --domain Default --project <PROJECT> --password <PASSWORD> <USER>

# List projects (tenants)
openstack project list

# Create project
openstack project create --domain Default --description "Description" <PROJECT_NAME>

# List roles
openstack role list

# Assign role to user
openstack role add --project <PROJECT> --user <USER> <ROLE>

# Revoke role
openstack role remove --project <PROJECT> --user <USER> <ROLE>
```

### Role Types

| Role | Description / Описание |
|------|------------------------|
| `admin` | Full administrative access / Полный административный доступ |
| `member` | Standard project operations / Стандартные операции проекта |
| `reader` | Read-only access / Доступ только на чтение |

### Domain Management

```bash
# List domains
openstack domain list

# Create domain
openstack domain create <DOMAIN_NAME>

# Create user in specific domain
openstack user create --domain <DOMAIN> --password <PASSWORD> <USER>
```

### SSL/TLS Configuration

`/etc/keystone/keystone.conf`

```ini
[ssl]
enable = true
certfile = /etc/keystone/ssl/certs/keystone.pem
keyfile = /etc/keystone/ssl/private/keystone-key.pem
ca_certs = /etc/keystone/ssl/certs/ca.pem
```

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/keystone/ssl/private/keystone-key.pem \
  -out /etc/keystone/ssl/certs/keystone.pem \
  -days 365 -nodes \
  -subj "/CN=<HOST>/O=<ORG>/C=<COUNTRY_CODE>"
```

### Application Credentials

```bash
# Create application credential (no password exposure)
openstack application credential create <CRED_NAME> \
  --secret <SECRET_KEY> \
  --role member

# Use in clouds.yaml
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

### Database Backup Runbook

1. **Identify databases / Определить базы данных:**

```bash
# OpenStack typically uses these databases
# keystone, nova, nova_api, nova_cell0, neutron, glance, cinder, placement, heat
mysql -u root -p<PASSWORD> -e "SHOW DATABASES;" | grep -E "keystone|nova|neutron|glance|cinder|placement|heat"
```

2. **Dump all OpenStack databases / Дамп всех БД OpenStack:**

```bash
# Full backup
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

### Database Restore

```bash
# Restore a single database
gunzip -c /backup/openstack/<DATE>/keystone.sql.gz | mysql -u root -p<PASSWORD> keystone

# Restore and sync DB schema
keystone-manage db_sync         # Keystone
nova-manage db sync             # Nova
neutron-db-manage upgrade head  # Neutron
glance-manage db_sync           # Glance
cinder-manage db sync           # Cinder
```

### Volume Snapshots

```bash
# Create volume snapshot
openstack volume snapshot create --volume <VOL_NAME> <SNAP_NAME>

# List snapshots
openstack volume snapshot list

# Restore from snapshot (create new volume)
openstack volume create --snapshot <SNAP_NAME> --size 20 <NEW_VOL_NAME>
```

### Instance Snapshots

```bash
# Create instance snapshot (image)
openstack server image create --name <SNAP_NAME> <VM_NAME>

# List snapshots
openstack image list --property image_type=snapshot
```

---

## 6. Troubleshooting & Tools

### Common Issues

#### 1. Service Not Responding

```bash
# Check service status
openstack compute service list   # Should show "up" / Должен показать "up"
openstack network agent list     # Check alive status / Проверить статус

# Check RabbitMQ
systemctl status rabbitmq-server
rabbitmqctl list_queues | head -20

# Check database connectivity
mysql -u <USER> -p<PASSWORD> -e "SELECT 1"

# Check Memcached
systemctl status memcached
echo stats | nc localhost 11211
```

#### 2. Instance Stuck in ERROR

```bash
# Check instance fault
openstack server show <VM_NAME> -c fault

# Check nova-compute log on the host
grep -i "error\|exception" /var/log/nova/nova-compute.log | tail -20

# Force-delete stuck instance
openstack server delete --force <VM_NAME>

# Reset instance state
nova reset-state --active <VM_UUID>
```

#### 3. Network Connectivity Issues

```bash
# Check Neutron agents
openstack network agent list   # All should be "alive" / Все должны быть "alive"

# Check OVS/Linux bridge
ovs-vsctl show                 # Open vSwitch status
brctl show                     # Linux bridge status

# Check namespaces
ip netns list                  # List network namespaces / Список namespace
ip netns exec qdhcp-<NET_UUID> ip a   # Check DHCP namespace / Проверить DHCP namespace

# Test from router namespace
ip netns exec qrouter-<ROUTER_UUID> ping <IP>
```

#### 4. Cinder Volume Issues

```bash
# Volume stuck in "creating" or "deleting"
cinder reset-state --state available <VOL_UUID>
cinder reset-state --state error <VOL_UUID>   # Then delete / Затем удалить

# Check LVM backend
lvs                            # List logical volumes / Список LV
vgs                            # List volume groups / Список VG
pvs                            # List physical volumes / Список PV
```

### Useful Administrative Commands

```bash
# List all resources across projects
openstack server list --all-projects
openstack volume list --all-projects
openstack floating ip list

# Check resource usage
openstack hypervisor stats show

# List all endpoints
openstack endpoint list

# Catalog (service registry)
openstack catalog list

# Token management
openstack token issue           # Issue new token / Выпустить токен
openstack token revoke <TOKEN>  # Revoke token / Отозвать токен

# DB management commands
nova-manage db sync             # Sync Nova DB / Синхронизировать БД Nova
nova-manage cell_v2 discover_hosts  # Discover new compute hosts / Обнаружить хосты
```

### Health Check Script

```bash
#!/bin/bash
# Quick OpenStack health check
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

## 📖 Documentation

- **OpenStack Documentation:** https://docs.openstack.org/
- **OpenStack CLI Reference:** https://docs.openstack.org/cli/latest/
- **OpenStack Administrator Guide:** https://docs.openstack.org/admin/

---
