Title: 🫀 Pacemaker & Corosync High Availability
Group: Infrastructure Management
Icon: 🫀
Order: 16

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Core Management (pcs)](#core-management-pcs)
3. [Resource Management](#resource-management)
4. [Constraints & Rules](#constraints--rules)
5. [STONITH & Fencing](#stonith--fencing)
6. [Quorum Management](#quorum-management)
7. [Troubleshooting & Maintenance](#troubleshooting--maintenance)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Protocol | Purpose / Назначение |
|-------------|----------|----------------------|
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

### Initial Setup / Начальная настройка

1. **Set `hacluster` user password (all nodes) / Пароль пользователя `hacluster`:**
   ```bash
   sudo passwd hacluster
   ```
2. **Start & Enable `pcsd` (all nodes) / Запуск службы демона `pcsd`:**
   ```bash
   sudo systemctl enable --now pcsd
   ```
3. **Authenticate nodes (run on one node) / Авторизация узлов:**
   ```bash
   sudo pcs host auth <NODE1> <NODE2> <NODE3> -u hacluster -p <PASSWORD>
   ```
4. **Create cluster & Start (run on one node) / Создание и запуск кластера:**
   ```bash
   sudo pcs cluster setup <CLUSTER_NAME> <NODE1> <NODE2> <NODE3>
   sudo pcs cluster start --all
   sudo pcs cluster enable --all
   ```

### Configuration Files / Файлы конфигурации

| File / Файл | Purpose / Назначение |
|-------------|----------------------|
| `/etc/corosync/corosync.conf` | Corosync network configuration / Настройки сети Corosync |
| `/etc/sysconfig/pacemaker` | Environment variables (RHEL) / Переменные (RHEL) |
| `/etc/default/pacemaker` | Environment variables (Debian) / Переменные (Debian) |
| `/var/log/pacemaker/pacemaker.log`| Main Pacemaker log / Главный лог Pacemaker |

---

## Core Management (pcs)

### Checking Cluster Status / Проверка статуса

```bash
sudo pcs status                 # Full status overview / Полный статус
sudo pcs cluster status         # Minimal cluster status / Краткий статус
sudo crm_mon -1 -Afr            # Alternative detailed view / Альтернативный подробный просмотр
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
> `pcs cluster destroy` wipes out all cluster configurations on the node. Be very careful.

### Node Management / Управление узлами

```bash
sudo pcs node standby <NODE>    # Put node in standby (stops resources) / Перевод в спящий режим
sudo pcs node unstandby <NODE>  # Bring node online / Возврат в рабочий режим
sudo pcs node maintenance <NODE># Put node in maintenance (keeps resources running) / Обслуживание (без остановки)
sudo pcs node unmaintenance <NODE>
```

---

## Resource Management

### Creating Resources / Создание ресурсов

```bash
# Virtual IP Example / Пример виртуального IP
sudo pcs resource create <VIP_NAME> ocf:heartbeat:IPaddr2 ip=<VIP_ADDRESS> cidr_netmask=24 op monitor interval=30s

# Systemd Service Example / Пример Systemd сервиса
sudo pcs resource create <SVC_NAME> systemd:<UNIT_NAME> op monitor interval=30s
```

> [!TIP]
> Use `pcs resource list` to list all configured resources and `pcs resource agents` to list available agents.

### Managing Resources / Управление ресурсами

```bash
sudo pcs resource enable <RES_NAME>     # Start a resource / Включить ресурс
sudo pcs resource disable <RES_NAME>    # Stop a resource / Отключить ресурс
sudo pcs resource restart <RES_NAME>    # Restart a resource / Перезапуск ресурса
sudo pcs resource move <RES_NAME>       # Move away from current node / Перенос с текущего узла
sudo pcs resource move <RES_NAME> <NODE># Move to a specific node / Перенос на конкретный узел
sudo pcs resource clear <RES_NAME>      # Clear movement constraints / Очистка правил перемещения
sudo pcs resource cleanup <RES_NAME>    # Reset failure counters / Сброс счетчиков ошибок
```

### Resource Groups / Группы ресурсов

Grouping ensures resources start sequentially on the same node and stop in reverse order.

```bash
sudo pcs resource group add <GROUP_NAME> <RES1> <RES2> <RES3>
sudo pcs resource group remove <GROUP_NAME> <RES>
```

---

## Constraints & Rules

Constraints control *where* and *when* resources can run.

### Location Constraints / Ограничения расположения

Prefer specific nodes for a resource.

```bash
sudo pcs constraint location <RES_NAME> prefers <NODE>=<SCORE>
# Example: Infinity score forces resource strictly on node1
sudo pcs constraint location <RES_NAME> prefers node1=INFINITY
```

### Order Constraints / Ограничения порядка

Specify start/stop sequence.

```bash
sudo pcs constraint order start <RES1> then start <RES2>
sudo pcs constraint order promote <MASTER_RES> then start <SLAVE_RES>
```

### Colocation Constraints / Ограничения совместного размещения

Ensure resources run together (or apart).

```bash
sudo pcs constraint colocation add <RES1> with <RES2> score=INFINITY
sudo pcs constraint colocation add <RES1> with <RES2> score=-INFINITY # Force them APART
```

> [!NOTE]
> `score=INFINITY` means "MUST run together". `score=-INFINITY` means "MUST NOT run together".

---

## STONITH & Fencing

> [!WARNING]
> High Availability clusters without STONITH/Fencing can suffer from split-brain data corruption. Never disable STONITH in production!

### Disabling STONITH (Testing Only!) / Отключение STONITH (только для тестов)

```bash
sudo pcs property set stonith-enabled=false
```

### Configuring STONITH Devices / Настройка устройств Fencing

```bash
# Example for VMware vCenter / Пример для VMware vCenter
sudo pcs stonith create vcenter_fence fence_vmware_rest \
    ipaddr=<VCENTER_IP> \
    login=<USER> \
    passwd=<PASSWORD> \
    # Mapping node names to VM names / Маппинг узлов на имена ВМ
    pcmk_host_map="node1:vm1;node2:vm2" \
    op monitor interval=60s
```

### Testing STONITH / Проверка STONITH

```bash
# Manually fence a node (will reboot it!) / Ручной fencing узла (ПЕРЕЗАГРУЗИТ!)
sudo pcs stonith fence <NODE>
```

---

## Quorum Management

A cluster requires quorum (majority of voting nodes) to continue functioning and avoid split-brain.

| Feature / Понятие | Description / Описание | Good for... / Для чего |
|-------------------|------------------------|------------------------|
| **2-Node Cluster**| Requires specific property to ignore quorum loss. / Игнорирует потерю кворума. | Small 2-node HA pairs / Простые HA пары |
| **QDevice**       | A 3rd lightweight daemon (corosync-qdevice) on a neutral server that gives the tie-breaker vote. / 3-й легковесный демон-наблюдатель. | 2-node clusters + 1 tiny VPS / Даёт кворум 2 узлам |

### Two-Node Cluster Setup / Настройка для 2 узлов (без QDevice)

```bash
sudo pcs property set no-quorum-policy=ignore
```

> [!CAUTION]
> If you set `no-quorum-policy=ignore`, having robust STONITH is strictly mandatory, otherwise you risk split-brain.

---

## Troubleshooting & Maintenance

### Runbook: Handling a Failed Resource / Решение проблем с ресурсом

1. **Identify the failure / Поиск ошибки:**
   ```bash
   sudo pcs status
   ```
   *(Look for "Failed Resource Actions" at the bottom)*
2. **Read the logs for the specific resource / Логи ресурса:**
   ```bash
   sudo journalctl -u pacemaker | grep <RES_NAME>
   ```
3. **Fix the underlying issue (e.g., correct a config file, start DB).**
4. **Cleanup the resource to clear the error count / Сброс счетчика ошибок:**
   ```bash
   sudo pcs resource cleanup <RES_NAME>
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
```
