Title: ☁️ Apache CloudStack
Group: Cloud
Icon: ☁️
Order: 2

# Apache CloudStack Sysadmin Cheatsheet

> **Context:** Apache CloudStack is an open-source IaaS cloud computing platform that manages and orchestrates pools of storage, network, and compute resources to build public/private cloud infrastructure. / Apache CloudStack — платформа IaaS с открытым исходным кодом для управления хранилищами, сетями и вычислительными ресурсами.
> **Role:** Sysadmin / Cloud Engineer
> **Version:** 4.18.x / 4.19.x
> **Default Ports:** Management UI: `8080` (HTTP), `8443` (HTTPS) | Agent: `8250` | MySQL: `3306` | System VM: `8443`

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
> CloudStack Management Server requires Java 11+ and MySQL 5.7+ / MariaDB 10.4+. Hypervisor hosts run the CloudStack Agent (KVM) or are managed via vCenter (VMware). / CloudStack Management Server требует Java 11+ и MySQL 5.7+.

### Repository Setup (RHEL/AlmaLinux) / Настройка репозиториев

```bash
# Add CloudStack repository / Добавить репозиторий CloudStack
cat > /etc/yum.repos.d/cloudstack.repo << 'EOF'
[cloudstack]
name=cloudstack
baseurl=http://download.cloudstack.org/el/$releasever/4.18/
enabled=1
gpgcheck=0
EOF

dnf clean all && dnf makecache  # Refresh repos / Обновить кэш репозиториев
```

### Repository Setup (Debian/Ubuntu) / Настройка репозиториев

```bash
# Add CloudStack APT repository / Добавить APT-репозиторий CloudStack
echo "deb http://download.cloudstack.org/ubuntu jammy 4.18" > /etc/apt/sources.list.d/cloudstack.list
wget -qO - http://download.cloudstack.org/release.asc | apt-key add -
apt update
```

### Install Management Server / Установка Management Server

```bash
# RHEL/Rocky/Alma
dnf install cloudstack-management cloudstack-common

# Debian/Ubuntu
apt install cloudstack-management cloudstack-common
```

### Database Setup / Настройка базы данных

```bash
# Install and start MySQL/MariaDB / Установить и запустить MySQL/MariaDB
dnf install mariadb-server
systemctl enable --now mariadb

# Secure installation / Безопасная установка
mysql_secure_installation
```

`/etc/my.cnf.d/cloudstack.cnf`

```ini
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format='ROW'
```

```bash
# Initialize CloudStack database / Инициализировать БД CloudStack
cloudstack-setup-databases cloud:<PASSWORD>@localhost --deploy-as=root:<ROOT_PASSWORD>

# Setup management server / Настроить Management Server
cloudstack-setup-management
```

### Essential Configuration / Основная конфигурация

`/etc/cloudstack/management/server.properties`

```ini
# Database connection / Подключение к БД
db.cloud.host=localhost
db.cloud.port=3306
db.cloud.username=cloud
db.cloud.password=<PASSWORD>

# JVM settings / Настройки JVM
Xmx=2g
Xms=1g
```

### Install KVM Agent (Hypervisor Host) / Установка KVM-агента

```bash
# On each KVM host / На каждом KVM-хосте
dnf install cloudstack-agent

# Configure libvirt / Настроить libvirt
cat >> /etc/libvirt/libvirtd.conf << 'EOF'
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
auth_tcp = "none"
mdns_adv = 0
EOF

systemctl restart libvirtd
```

---

## 2. Core Management

### Web UI Access / Доступ к веб-интерфейсу

```
http://<HOST>:8080/client         # Management UI / Панель управления
https://<HOST>:8443/client        # HTTPS Management UI
```

Default credentials: `admin` / `password` (change immediately!)

### CloudMonkey CLI / CLI CloudMonkey

CloudMonkey is the official CLI for CloudStack API. / CloudMonkey — официальный CLI для API CloudStack.

```bash
# Install CloudMonkey / Установить CloudMonkey
pip install cloudmonkey

# Configure CLI / Настроить CLI
cmk set url http://<HOST>:8080/client/api
cmk set apikey <API_KEY>
cmk set secretkey <SECRET_KEY>
cmk set display json
```

### Common CloudMonkey Commands / Основные команды CloudMonkey

```bash
# List zones / Список зон
cmk list zones

# List virtual machines / Список виртуальных машин
cmk list virtualmachines listall=true

# List hosts / Список хостов
cmk list hosts type=Routing

# List service offerings / Список пакетов услуг
cmk list serviceofferings

# List templates / Список шаблонов
cmk list templates templatefilter=all

# List networks / Список сетей
cmk list networks listall=true

# Deploy a VM / Создать ВМ
cmk deploy virtualmachine serviceofferingid=<UUID> templateid=<UUID> zoneid=<UUID> name=<VM_NAME>

# Start/Stop/Reboot VM / Запуск/Остановка/Перезагрузка ВМ
cmk start virtualmachine id=<VM_UUID>
cmk stop  virtualmachine id=<VM_UUID>
cmk reboot virtualmachine id=<VM_UUID>

# Destroy VM / Удалить ВМ
cmk destroy virtualmachine id=<VM_UUID> expunge=true
```

> [!CAUTION]
> `expunge=true` permanently deletes the VM and its root disk. There is no recovery after this. / `expunge=true` безвозвратно удаляет ВМ и её корневой диск.

### VM Lifecycle States / Состояния жизненного цикла ВМ

| State | Description / Описание |
|-------|------------------------|
| `Running` | VM is active / ВМ активна |
| `Stopped` | VM is powered off / ВМ выключена |
| `Destroyed` | VM is marked for deletion (recoverable within expunge delay) / Помечена для удаления |
| `Expunging` | VM is being permanently removed / Безвозвратное удаление |
| `Error` | VM is in error state / ВМ в состоянии ошибки |
| `Migrating` | VM is being live-migrated / ВМ в процессе live-миграции |

---

## 3. Sysadmin Operations

### Service Management / Управление сервисами

```bash
# Management Server / Management server
systemctl start cloudstack-management     # Start / Запустить
systemctl stop cloudstack-management      # Stop / Остановить
systemctl restart cloudstack-management   # Restart / Перезапустить
systemctl status cloudstack-management    # Status / Статус
systemctl enable cloudstack-management    # Enable on boot / Автозапуск

# KVM Agent (on hypervisor hosts) / KVM-агент (на гипервизорах)
systemctl restart cloudstack-agent        # Restart agent / Перезапустить агент
systemctl status cloudstack-agent         # Check status / Проверить статус
```

### Important Paths / Важные пути

| Path | Description |
|------|-------------|
| `/etc/cloudstack/management/` | Management server configs / Конфиги management server |
| `/etc/cloudstack/agent/` | KVM agent configs / Конфиги KVM-агента |
| `/var/log/cloudstack/management/` | Management server logs / Логи management |
| `/var/log/cloudstack/agent/` | Agent logs / Логи агента |
| `/var/log/cloudstack/management/management-server.log` | Main log / Основной лог |
| `/usr/share/cloudstack-management/` | Management binaries / Бинарные файлы |
| `/usr/share/cloudstack-common/scripts/` | CloudStack scripts / Скрипты CloudStack |
| `/var/lib/cloudstack/` | CloudStack data / Данные CloudStack |

### Log Locations / Расположение логов

```bash
# Main management server log / Основной лог management server
tail -f /var/log/cloudstack/management/management-server.log

# API access log / Лог доступа к API
tail -f /var/log/cloudstack/management/apilog.log

# Agent log (on hypervisor) / Лог агента (на гипервизоре)
tail -f /var/log/cloudstack/agent/agent.log

# System VM logs / Логи системных ВМ
tail -f /var/log/cloudstack/management/systemvm.log
```

### System VM Management / Управление системными ВМ

```bash
# List system VMs / Список системных ВМ
cmk list systemvms

# List routers / Список маршрутизаторов
cmk list routers listall=true

# Restart system VM / Перезапустить системную ВМ
cmk destroy systemvm id=<SYSTEM_VM_UUID>   # It auto-re-creates / Автоматически пересоздаётся

# Restart virtual router / Перезапустить виртуальный маршрутизатор
cmk restart router id=<ROUTER_UUID>
```

### Firewall Configuration / Настройка фаервола

```bash
# Management Server ports / Порты Management Server
firewall-cmd --permanent --add-port=8080/tcp   # HTTP UI
firewall-cmd --permanent --add-port=8443/tcp   # HTTPS UI
firewall-cmd --permanent --add-port=8250/tcp   # Agent communication / Связь с агентами
firewall-cmd --permanent --add-port=9090/tcp   # Console proxy / Консольный прокси

# KVM Host ports / Порты KVM-хоста
firewall-cmd --permanent --add-port=16509/tcp  # Libvirt / libvirt
firewall-cmd --permanent --add-port=49152-49261/tcp  # Live migration / Живая миграция
firewall-cmd --reload
```

### JVM / Performance Tuning / Настройка JVM

`/etc/default/cloudstack-management` (Debian) or `/etc/sysconfig/cloudstack-management` (RHEL)

```ini
JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError"
```

> [!TIP]
> For large clouds (1000+ VMs), increase `Xmx` to 8g+ and increase MySQL `max_connections` to 500+. Monitor GC logs: `-Xlog:gc*:file=/var/log/cloudstack/management/gc.log`. / Для больших облаков (1000+ ВМ) увеличьте `Xmx` до 8g+ и `max_connections` MySQL до 500+.

---

## 4. Security

### API Keys / Ключи API

```bash
# Register user API keys / Зарегистрировать API-ключи пользователя
cmk register userkeys id=<USER_UUID>

# List user's API keys / Показать API-ключи пользователя
cmk list users id=<USER_UUID>
```

### Domain & Account Management / Управление доменами и аккаунтами

```bash
# List domains / Список доменов
cmk list domains listall=true

# Create domain / Создать домен
cmk create domain name=<DOMAIN_NAME>

# Create account / Создать аккаунт
cmk create account username=<USER> password=<PASSWORD> email=<EMAIL> \
  firstname=<FIRST_NAME> lastname=<LAST_NAME> accounttype=0 domainid=<DOMAIN_UUID>
```

| Account Type | Description / Описание |
|--------------|------------------------|
| `0` | User account / Пользовательский аккаунт |
| `1` | Root admin / Администратор root |
| `2` | Domain admin / Администратор домена |

### SSL/TLS Configuration / Настройка SSL/TLS

`/etc/cloudstack/management/server.properties`

```ini
# Enable HTTPS / Включить HTTPS
https.enable=true
https.port=8443

# Keystore settings / Настройки keystore
https.keystore=/etc/cloudstack/management/cloud.jks
https.keystore.password=<PASSWORD>
```

```bash
# Generate keystore / Сгенерировать keystore
keytool -genkey -keyalg RSA -keysize 2048 -alias cloudstack \
  -keystore /etc/cloudstack/management/cloud.jks \
  -storepass <PASSWORD> -keypass <PASSWORD> \
  -dname "CN=<HOST>, OU=IT, O=<ORG>, L=<CITY>, S=<STATE>, C=<COUNTRY_CODE>"

# Import existing certificate / Импортировать существующий сертификат
keytool -import -alias cloudstack -file /path/to/cert.pem \
  -keystore /etc/cloudstack/management/cloud.jks -storepass <PASSWORD>
```

---

## 5. Backup & Restore

> [!CAUTION]
> Always stop the management server before performing database backups to ensure data consistency. / Всегда останавливайте management server перед бэкапом БД.

### Database Backup Runbook / Сценарий резервного копирования

1. **Stop management server / Остановить management server:**

```bash
systemctl stop cloudstack-management
```

2. **Dump database / Создать дамп БД:**

```bash
mysqldump -u cloud -p<PASSWORD> --single-transaction --routines --triggers cloud | gzip > /backup/cloudstack_db_$(date +%F).sql.gz
mysqldump -u cloud -p<PASSWORD> --single-transaction cloud_usage | gzip > /backup/cloudstack_usage_$(date +%F).sql.gz
```

3. **Backup configs / Бэкап конфигов:**

```bash
tar -czf /backup/cloudstack_conf_$(date +%F).tar.gz /etc/cloudstack/
```

4. **Start management server / Запустить management server:**

```bash
systemctl start cloudstack-management
```

### Database Restore / Восстановление БД

```bash
systemctl stop cloudstack-management
mysql -u cloud -p<PASSWORD> cloud < <(gunzip -c /backup/cloudstack_db_<DATE>.sql.gz)
systemctl start cloudstack-management
```

---

## 6. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Management Server Won't Start / Management server не запускается

```bash
# Check Java version / Проверить версию Java
java -version   # Must be 11+ / Должна быть 11+

# Check logs for errors / Проверить логи
tail -100 /var/log/cloudstack/management/management-server.log | grep -i "error\|exception"

# Check DB connectivity / Проверить подключение к БД
mysql -u cloud -p<PASSWORD> -e "SELECT 1" cloud
```

#### 2. Agent Disconnected / Агент отключён

```bash
# On hypervisor host / На гипервизоре
systemctl status cloudstack-agent
tail -50 /var/log/cloudstack/agent/agent.log | grep -i error

# Verify management server reachability / Проверить доступность management server
curl -s http://<MANAGEMENT_HOST>:8080 | head -5

# Check libvirt / Проверить libvirt
virsh list --all   # Should work without errors / Должно работать без ошибок
```

#### 3. System VM Not Starting / Системная ВМ не запускается

```bash
# Check system VM template / Проверить шаблон системной ВМ
cmk list templates templatefilter=all keyword=systemvm

# Check secondary storage / Проверить вторичное хранилище
cmk list imageStores

# Check console proxy / Проверить консольный прокси
cmk list systemvms systemvmtype=consoleproxy
```

#### 4. VMware to CloudStack Migration: GRUB Boot Failure / Ошибка загрузки GRUB после миграции

If a VM migrated from VMware fails to boot after an OS upgrade (e.g., Ubuntu `do-release-upgrade`), the GRUB bootloader may be pointed to the wrong disk (e.g., VMware used SCSI `/dev/sda`, KVM uses a different disk like `/dev/sdb` or `/dev/vda`).

```bash
# Verify current GRUB install devices / Проверить текущий диск установки GRUB
debconf-show grub-pc | grep install_devices

# If it shows an old disk (e.g., /dev/sda) instead of the correct one (e.g., /dev/sdb):
# Change GRUB install device / Изменить диск установки GRUB
echo "grub-pc grub-pc/install_devices multiselect /dev/sdb" | debconf-set-selections

# Re-install GRUB and update config / Переустановить GRUB и обновить конфиг
grub-install /dev/sdb
update-grub
```

> [!TIP]
> **CloudStack Template/VM Setting:** When importing the VM or template, ensure the **Root Disk Controller** is explicitly set to `scsi` (or `virtio`) depending on your KVM configuration to maintain device naming consistency. / При импорте шаблона или ВМ укажите Root Disk Controller = `scsi`.

### Useful API Queries / Полезные API-запросы

```bash
# Check cloud infrastructure capacity / Проверить ёмкость инфраструктуры
cmk list capacity

# List events (audit log) / Список событий (аудит)
cmk list events level=ERROR startdate=$(date -d '-1 day' +%Y-%m-%d)

# List async jobs / Список асинхронных задач
cmk list asyncjobs listall=true
```

---

## 7. Logrotate Configuration

`/etc/logrotate.d/cloudstack`

```conf
/var/log/cloudstack/management/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 cloud cloud
    sharedscripts
    postrotate
        systemctl kill --signal=HUP cloudstack-management 2>/dev/null || true
    endscript
}

/var/log/cloudstack/agent/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---
