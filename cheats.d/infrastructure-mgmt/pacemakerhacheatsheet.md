---
Title: Pacemaker & Corosync High Availability
Group: Infrastructure Management
Icon: 🫀
Order: 16
---

# Pacemaker & Corosync — Linux High Availability Clustering

**Description / Описание:**
Pacemaker is an advanced, open-source high-availability cluster resource manager that runs on a set of nodes and ensures that critical services (resources) are always available. It works together with **Corosync** (the cluster messaging layer) to detect node failures and automatically migrate services. Pacemaker/Corosync is the standard HA stack for Linux, widely used for database failover, virtual IP management, and service High Availability.

> [!NOTE]
> **Current Status:** Pacemaker + Corosync is the industry standard for Linux HA clustering and is actively maintained. It is included in RHEL (via the HA Add-On), SUSE Linux Enterprise HA Extension, and Debian/Ubuntu. Alternatives include **Keepalived** (simpler, VRRP-based HA for Layer 4), **HAProxy** (load-balancing focused), and cloud-native solutions like Kubernetes for containerized workloads. / **Текущий статус:** Pacemaker + Corosync — промышленный стандарт для HA-кластеров в Linux, активно поддерживается. Альтернативы: **Keepalived** (VRRP), **HAProxy** (балансировка), Kubernetes.

---

## Table of Contents

1. [Installation & Configuration](#installation--configuration)
2. [Core Management (pcs)](#core-management-pcs)
3. [Resource Management](#resource-management)
4. [Constraints & Rules](#constraints--rules)
5. [STONITH & Fencing](#stonith--fencing)
6. [Quorum Management](#quorum-management)
7. [Troubleshooting & Maintenance](#troubleshooting--maintenance)
8. [Logrotate Configuration](#logrotate-configuration)
9. [Documentation Links](#documentation-links)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Protocol | Purpose / Назначение |
|:---|:---|:---|
| `2224` | TCP | `pcsd` Web UI and cluster communication / Порт `pcsd` |
| `3121` | TCP | Pacemaker Remote / Удалённый Pacemaker |
| `5404` | UDP | Corosync multicast/unicast (receive) / Приём Corosync |
| `5405` | UDP | Corosync multicast/unicast (send) / Отправка Corosync |

### Package Installation / Установка пакетов

```bash
# RHEL/AlmaLinux/Rocky
sudo dnf install -y pacemaker corosync pcs fence-agents-all

# Debian/Ubuntu
sudo apt update
sudo apt install -y pacemaker corosync pcs fence-agents
```

### Production Runbook: Initial Cluster Setup / Начальная настройка кластера

1. **Set `hacluster` user password (all nodes) / Пароль пользователя `hacluster`:**

   ```bash
   sudo passwd hacluster  # Set on ALL nodes / Установить на ВСЕХ узлах
   ```

2. **Start & Enable `pcsd` (all nodes) / Запуск службы демона `pcsd`:**

   ```bash
   sudo systemctl enable --now pcsd  # Start and enable pcsd daemon / Запустить и включить демон pcsd
   ```

3. **Authenticate nodes (run on one node) / Авторизация узлов:**

   ```bash
   sudo pcs host auth <NODE1> <NODE2> <NODE3> -u hacluster -p <PASSWORD>
   ```

4. **Create cluster & Start (run on one node) / Создание и запуск кластера:**

   ```bash
   sudo pcs cluster setup <CLUSTER_NAME> <NODE1> <NODE2> <NODE3>
   sudo pcs cluster start --all   # Start cluster on all nodes / Запустить кластер на всех узлах
   sudo pcs cluster enable --all  # Enable autostart / Включить автозапуск
   ```

5. **Verify cluster status / Проверить статус кластера:**

   ```bash
   sudo pcs status  # Should show all nodes Online / Все узлы должны быть Online
   ```

### Firewall Configuration / Настройка фаервола

```bash
# firewalld (RHEL/CentOS/AlmaLinux)
sudo firewall-cmd --permanent --add-service=high-availability  # Opens all HA ports / Открывает все HA-порты
sudo firewall-cmd --reload

# Or open ports individually / Или открыть порты отдельно
sudo firewall-cmd --permanent --add-port=2224/tcp   # pcsd
sudo firewall-cmd --permanent --add-port=3121/tcp   # Pacemaker Remote
sudo firewall-cmd --permanent --add-port=5404/udp   # Corosync
sudo firewall-cmd --permanent --add-port=5405/udp   # Corosync
sudo firewall-cmd --reload

# UFW (Debian/Ubuntu)
sudo ufw allow 2224/tcp   # pcsd
sudo ufw allow 3121/tcp   # Pacemaker Remote
sudo ufw allow 5404/udp   # Corosync
sudo ufw allow 5405/udp   # Corosync
```

### Configuration Files / Файлы конфигурации

| File / Файл | Purpose / Назначение |
|:---|:---|
| `/etc/corosync/corosync.conf` | Corosync network configuration / Настройки сети Corosync |
| `/etc/sysconfig/pacemaker` | Environment variables (RHEL) / Переменные (RHEL) |
| `/etc/default/pacemaker` | Environment variables (Debian) / Переменные (Debian) |
| `/var/lib/pacemaker/cib/cib.xml` | Cluster Information Base (CIB) / База информации кластера |
| `/var/log/pacemaker/pacemaker.log` | Main Pacemaker log / Главный лог Pacemaker |
| `/var/log/cluster/corosync.log` | Corosync log / Лог Corosync |

---

## Core Management (pcs)

### Checking Cluster Status / Проверка статуса

```bash
sudo pcs status                 # Full status overview / Полный статус
sudo pcs cluster status         # Minimal cluster status / Краткий статус
sudo crm_mon -1 -Afr            # Alternative detailed view / Альтернативный подробный просмотр
sudo pcs status nodes           # Node status only / Только статус узлов
sudo pcs status resources       # Resource status only / Только статус ресурсов
```

### Managing Cluster Services / Управление сервисами кластера

```bash
sudo pcs cluster start --all    # Start on all nodes / Запустить везде
sudo pcs cluster stop --all     # Stop on all nodes / Остановить везде
sudo pcs cluster start          # Start on local node / Запуск на локальном узле
sudo pcs cluster stop           # Stop on local node / Остановка локально

sudo pcs cluster destroy        # Destroy cluster config (!) / Удаление конфигурации (!)
```

> [!CAUTION]
> `pcs cluster destroy` wipes out all cluster configurations on the node. This is irreversible and will stop all resources. Be very careful. / `pcs cluster destroy` удаляет всю конфигурацию кластера. Это необратимо и остановит все ресурсы.

### Node Management / Управление узлами

```bash
sudo pcs node standby <NODE>      # Put node in standby (stops resources) / Перевод в спящий режим
sudo pcs node unstandby <NODE>    # Bring node online / Возврат в рабочий режим
sudo pcs node maintenance <NODE>  # Put node in maintenance (keeps resources running) / Обслуживание (без остановки)
sudo pcs node unmaintenance <NODE>  # Exit maintenance mode / Выход из режима обслуживания
```

### Standby vs Maintenance Mode / Сравнение режимов

| Mode / Режим | Resources / Ресурсы | Monitoring / Мониторинг | Use Case / Применение |
|:---|:---|:---|:---|
| **Standby** | Migrated away / Переносятся | Stopped / Остановлен | Hardware maintenance, planned migration / Обслуживание железа |
| **Maintenance** | Stay running / Остаются | Stopped / Остановлен | Software updates on node / Обновление ПО на узле |

---

## Resource Management

### Creating Resources / Создание ресурсов

```bash
# Virtual IP Example / Пример виртуального IP
sudo pcs resource create <VIP_NAME> ocf:heartbeat:IPaddr2 \
  ip=<VIP_ADDRESS> cidr_netmask=24 op monitor interval=30s

# Systemd Service Example / Пример Systemd сервиса
sudo pcs resource create <SVC_NAME> systemd:<UNIT_NAME> op monitor interval=30s

# Apache HTTPD Example / Пример Apache HTTPD
sudo pcs resource create <WEB_NAME> ocf:heartbeat:apache \
  configfile="/etc/httpd/conf/httpd.conf" statusurl="http://localhost/server-status" \
  op monitor interval=30s
```

> [!TIP]
> Use `pcs resource list` to list all configured resources and `pcs resource agents` to list available resource agents. Run `pcs resource describe <AGENT>` for detailed agent documentation. / Используйте `pcs resource list` для ресурсов и `pcs resource agents` для доступных агентов. `pcs resource describe <AGENT>` для документации.

### Managing Resources / Управление ресурсами

```bash
sudo pcs resource enable <RES_NAME>      # Start a resource / Включить ресурс
sudo pcs resource disable <RES_NAME>     # Stop a resource / Отключить ресурс
sudo pcs resource restart <RES_NAME>     # Restart a resource / Перезапуск ресурса
sudo pcs resource move <RES_NAME>        # Move away from current node / Перенос с текущего узла
sudo pcs resource move <RES_NAME> <NODE> # Move to a specific node / Перенос на конкретный узел
sudo pcs resource clear <RES_NAME>       # Clear movement constraints / Очистка правил перемещения
sudo pcs resource cleanup <RES_NAME>     # Reset failure counters / Сброс счетчиков ошибок
```

> [!WARNING]
> After using `pcs resource move`, always run `pcs resource clear <RES_NAME>` to remove the temporary location constraint. Otherwise, the resource will never move back automatically. / После `pcs resource move` всегда выполняйте `pcs resource clear`, чтобы удалить временное ограничение.

### Resource Groups / Группы ресурсов

Grouping ensures resources start sequentially on the same node and stop in reverse order. / Группировка обеспечивает последовательный запуск ресурсов на одном узле и остановку в обратном порядке.

```bash
sudo pcs resource group add <GROUP_NAME> <RES1> <RES2> <RES3>  # Create/add to group / Создать/добавить в группу
sudo pcs resource group remove <GROUP_NAME> <RES>               # Remove from group / Убрать из группы
```

### Common Resource Agents / Основные агенты ресурсов

| Agent / Агент | Description / Описание | Use Case / Применение |
|:---|:---|:---|
| `ocf:heartbeat:IPaddr2` | Manage virtual IP addresses / Управление виртуальными IP | Floating VIP for services / VIP для сервисов |
| `systemd:<UNIT>` | Manage any systemd service / Управление сервисом systemd | Any service with systemd unit / Любой сервис systemd |
| `ocf:heartbeat:apache` | Manage Apache HTTPD / Управление Apache | Web server HA / HA веб-сервера |
| `ocf:heartbeat:pgsql` | Manage PostgreSQL / Управление PostgreSQL | Database HA / HA базы данных |
| `ocf:heartbeat:Filesystem` | Mount/unmount filesystem / Монтирование файловой системы | Shared storage / Общее хранилище |
| `ocf:heartbeat:nginx` | Manage Nginx / Управление Nginx | Reverse proxy HA / HA обратного прокси |

---

## Constraints & Rules

Constraints control *where* and *when* resources can run. / Ограничения управляют *где* и *когда* ресурсы могут работать.

### Location Constraints / Ограничения расположения

Prefer specific nodes for a resource. / Привязка ресурса к конкретным узлам.

```bash
sudo pcs constraint location <RES_NAME> prefers <NODE>=<SCORE>
# Example: Infinity score forces resource strictly on node1 / INFINITY строго привязывает ресурс к node1
sudo pcs constraint location <RES_NAME> prefers node1=INFINITY
```

### Order Constraints / Ограничения порядка

Specify start/stop sequence. / Порядок запуска/остановки.

```bash
sudo pcs constraint order start <RES1> then start <RES2>
sudo pcs constraint order promote <MASTER_RES> then start <SLAVE_RES>
```

### Colocation Constraints / Ограничения совместного размещения

Ensure resources run together (or apart). / Совместное (или раздельное) размещение ресурсов.

```bash
sudo pcs constraint colocation add <RES1> with <RES2> score=INFINITY   # MUST run together / ДОЛЖНЫ на одном узле
sudo pcs constraint colocation add <RES1> with <RES2> score=-INFINITY  # MUST NOT run together / НЕ ДОЛЖНЫ на одном узле
```

### Constraint Scores Explained / Значения Score

| Score / Оценка | Meaning / Значение | Behavior / Поведение |
|:---|:---|:---|
| `INFINITY` | Mandatory / Обязательно | Must be honored, or resource won't start / Должно соблюдаться |
| `-INFINITY` | Mandatory negative / Обязательно отрицательное | Must NOT be on same node / НЕ должно быть на одном узле |
| `100-1000` | Preference / Предпочтение | Preferred but not mandatory / Предпочтительно, но не обязательно |
| `0` | No preference / Без предпочтения | No effect / Без эффекта |

### View All Constraints / Просмотр всех ограничений

```bash
sudo pcs constraint --full    # Show all constraints with IDs / Показать все ограничения с ID
sudo pcs constraint remove <CONSTRAINT_ID>  # Remove a constraint / Удалить ограничение
```

---

## STONITH & Fencing

> [!WARNING]
> High Availability clusters without STONITH/Fencing can suffer from split-brain data corruption. **Never disable STONITH in production!** / HA-кластеры без STONITH/Fencing подвержены расщеплению мозга (split-brain). **Никогда не отключайте STONITH в продакшене!**

### Why STONITH is Critical / Зачем нужен STONITH

STONITH ("Shoot The Other Node In The Head") ensures that a malfunctioning node is forcefully powered off before its resources are recovered on another node. Without it, two nodes may simultaneously believe they own the same resource (e.g., a shared filesystem), leading to **data corruption**. / STONITH гарантирует, что неисправный узел будет принудительно отключён перед переносом ресурсов. Без него два узла могут одновременно владеть ресурсом, что приведёт к **повреждению данных**.

### Disabling STONITH (Testing Only!) / Отключение STONITH (только для тестов)

```bash
sudo pcs property set stonith-enabled=false  # Only for lab/testing! / Только для лабораторий/тестов!
```

### Configuring STONITH Devices / Настройка устройств Fencing

```bash
# Example for VMware vCenter / Пример для VMware vCenter
sudo pcs stonith create vcenter_fence fence_vmware_rest \
    ipaddr=<VCENTER_IP> \
    login=<USER> \
    passwd=<PASSWORD> \
    pcmk_host_map="node1:vm1;node2:vm2" \
    op monitor interval=60s

# Example for IPMI/iLO/iDRAC / Пример для IPMI/iLO/iDRAC
sudo pcs stonith create ipmi_fence fence_ipmilan \
    ipaddr=<IPMI_IP> \
    login=<USER> \
    passwd=<PASSWORD> \
    pcmk_host_list="<NODE>" \
    op monitor interval=60s
```

### Testing STONITH / Проверка STONITH

```bash
# List configured STONITH devices / Список настроенных устройств STONITH
sudo pcs stonith status

# Verify STONITH can reach the target / Проверить доступность цели
sudo pcs stonith fence <NODE> --off  # Will power off the node! / ВЫКЛЮЧИТ узел!
```

> [!CAUTION]
> `pcs stonith fence <NODE>` will actually reboot or power off the target node. Use only for testing in controlled environments. / `pcs stonith fence <NODE>` реально перезагрузит или выключит узел. Используйте только в контролируемой среде.

### Common STONITH Agents / Основные STONITH-агенты

| Agent / Агент | Target | Description / Описание |
|:---|:---|:---|
| `fence_vmware_rest` | VMware vCenter | REST API fencing for VMs / Fencing ВМ через REST API |
| `fence_ipmilan` | IPMI/iLO/iDRAC | Hardware BMC fencing / Fencing через BMC |
| `fence_xvm` | libvirt/KVM | Fencing for KVM VMs / Fencing для KVM ВМ |
| `fence_aws` | AWS EC2 | Cloud fencing for AWS / Fencing в AWS |
| `fence_gce` | Google Cloud | Cloud fencing for GCE / Fencing в GCE |
| `fence_azure_arm` | Azure | Cloud fencing for Azure / Fencing в Azure |
| `fence_sbd` | Shared disk | SBD watchdog-based fencing / Fencing через SBD |

---

## Quorum Management

A cluster requires quorum (majority of voting nodes) to continue functioning and avoid split-brain. / Кластер требует кворума (большинства голосующих узлов) для продолжения работы.

### Quorum Strategies / Стратегии кворума

| Feature / Понятие | Description / Описание | Good for... / Для чего |
|:---|:---|:---|
| **2-Node Cluster** | Requires specific property to ignore quorum loss. / Игнорирует потерю кворума. | Small 2-node HA pairs / Простые HA пары |
| **QDevice** | A 3rd lightweight daemon (`corosync-qdevice`) on a neutral server that gives the tie-breaker vote. / 3-й легковесный демон-наблюдатель. | 2-node clusters + 1 tiny VPS / Даёт кворум 2 узлам |
| **3+ Node Cluster** | Natural majority quorum. / Естественное большинство. | Production HA / Продакшен HA |

### Two-Node Cluster Setup / Настройка для 2 узлов (без QDevice)

```bash
sudo pcs property set no-quorum-policy=ignore  # For 2-node clusters only / Только для 2-узловых кластеров
```

> [!CAUTION]
> If you set `no-quorum-policy=ignore`, having robust STONITH is **strictly mandatory**, otherwise you risk split-brain. / При `no-quorum-policy=ignore` наличие надёжного STONITH **строго обязательно**, иначе возможен split-brain.

### QDevice Setup / Настройка QDevice

```bash
# On the QDevice host (separate server) / На хосте QDevice (отдельный сервер)
sudo dnf install -y corosync-qnetd
sudo pcs qdevice setup model net --enable --start

# On one cluster node / На одном узле кластера
sudo pcs quorum device add model net host=<QDEVICE_HOST> algorithm=ffsplit
```

---

## Troubleshooting & Maintenance

### Runbook: Handling a Failed Resource / Решение проблем с ресурсом

1. **Identify the failure / Поиск ошибки:**

   ```bash
   sudo pcs status  # Look for "Failed Resource Actions" at the bottom / Ищите "Failed Resource Actions" внизу
   ```

2. **Read the logs for the specific resource / Логи ресурса:**

   ```bash
   sudo journalctl -u pacemaker | grep <RES_NAME>
   sudo grep <RES_NAME> /var/log/pacemaker/pacemaker.log
   ```

3. **Fix the underlying issue** (e.g., correct a config file, start DB). / **Исправьте основную проблему** (например, конфиг, запуск БД).

4. **Cleanup the resource to clear the error count / Сброс счетчика ошибок:**

   ```bash
   sudo pcs resource cleanup <RES_NAME>
   ```

5. **Verify resource is running / Проверить, что ресурс запущен:**

   ```bash
   sudo pcs status resources
   ```

### Global Cluster Properties / Глобальные свойства кластера

```bash
# Put entire cluster in maintenance mode (stops monitoring, freezes resources)
# Обслуживание всего кластера (заморозка ресурсов, остановка мониторинга)
sudo pcs property set maintenance-mode=true

# Disable maintenance mode / Возврат в обычный режим
sudo pcs property set maintenance-mode=false

# Prevent resources from moving after node recovers (prevents ping-pong effect)
# Запрет переезда ресурсов обратно после возвращения узла
sudo pcs property set resource-stickiness=100

# View all cluster properties / Просмотр всех свойств кластера
sudo pcs property list
```

### Cluster Configuration Backup / Резервное копирование конфигурации кластера

```bash
# Export the CIB (Cluster Information Base) / Экспорт CIB
sudo pcs cluster cib-push --config cib_backup.xml --scope=configuration

# Save current config to file / Сохранить текущий конфиг
sudo pcs config backup <BACKUP_FILE>

# Restore config from backup / Восстановить конфиг из бэкапа
sudo pcs config restore <BACKUP_FILE>
```

> [!WARNING]
> Restoring a CIB backup will overwrite all current resource and constraint definitions. / Восстановление CIB перезапишет все текущие определения ресурсов и ограничений.

### Useful Diagnostic Commands / Полезные диагностические команды

```bash
sudo corosync-cmapctl | grep members   # List cluster members / Список участников кластера
sudo corosync-quorumtool               # Quorum status / Статус кворума
sudo pcs config show                   # Full cluster configuration / Полная конфигурация
sudo crm_verify -LV                    # Verify CIB for errors / Проверить CIB на ошибки
sudo pcs resource failcount show <RES_NAME>  # Show fail count / Показать счётчик ошибок
```

---

## Logrotate Configuration

`/etc/logrotate.d/pacemaker`

```conf
/var/log/pacemaker/pacemaker.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 hacluster haclient
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/pacemaker/pacemaker.pid 2>/dev/null) 2>/dev/null || true
    endscript
}

/var/log/cluster/corosync.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Documentation Links

- **Pacemaker Official Documentation:** [https://clusterlabs.org/pacemaker/doc/](https://clusterlabs.org/pacemaker/doc/)
- **ClusterLabs Wiki:** [https://wiki.clusterlabs.org/](https://wiki.clusterlabs.org/)
- **Pacemaker Explained (Full Reference):** [https://clusterlabs.org/pacemaker/doc/2.1/Pacemaker_Explained/html/](https://clusterlabs.org/pacemaker/doc/2.1/Pacemaker_Explained/html/)
- **Red Hat HA Cluster Administration Guide:** [https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_high_availability_clusters/](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_high_availability_clusters/)
- **SUSE HA Extension Documentation:** [https://documentation.suse.com/sle-ha/](https://documentation.suse.com/sle-ha/)
- **Corosync Project:** [https://corosync.github.io/corosync/](https://corosync.github.io/corosync/)
- **Pacemaker GitHub Repository:** [https://github.com/ClusterLabs/pacemaker](https://github.com/ClusterLabs/pacemaker)
