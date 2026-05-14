Title: 🔍 Network Backend Detection — Linux (Universal)
Group: Network
Icon: 🔍
Order: 25

# Network Backend Detection — Linux (Universal)

This cheatsheet provides a universal workflow to determine which network management backend (NetworkManager, systemd-networkd, Netplan, or legacy scripts) is controlling your network interfaces. Essential for troubleshooting network configuration conflicts on any Linux distribution (Ubuntu, Debian, RHEL, CentOS, Fedora).

## Table of Contents
- [Quick Detection Workflow](#quick-detection-workflow)
- [Universal Backend Check](#universal-backend-check)
- [NetworkManager (NM)](#networkmanager-nm)
- [systemd-networkd](#systemd-networkd)
- [Distro-Specific Layers](#distro-specific-layers)
    - [Netplan (Ubuntu/Debian)](#netplan-ubuntudebian)
    - [Legacy: Ifupdown (Debian/Old Ubuntu)](#legacy-ifupdown-debianold-ubuntu)
    - [Legacy: Sysconfig (RHEL/CentOS/Fedora)](#legacy-sysconfig-rhelcentosfedora)
- [Interface Ownership](#interface-ownership)
- [Routing Table](#routing-table)
- [Comparison Tables](#comparison-tables)
- [Troubleshooting](#troubleshooting)

---

## Quick Detection Workflow / Быстрая проверка

### Production Runbook: Identify Network Backend / Определение сетевого бэкенда

Run these commands in sequence to identify your active network backend on any Linux system:

```bash
# Step 1: Check active services / Проверить активные сервисы
systemctl is-active NetworkManager systemd-networkd networking network

# Step 2: Check active listening processes / Проверить процессы, слушающие сеть
sudo netstat -tulpn | grep -E 'NetworkManager|systemd-networkd' 

# Step 3: Check interface ownership (Universal) / Проверить владение интерфейсами
networkctl list      # systemd-networkd check / Проверка systemd-networkd
nmcli device status  # NetworkManager check / Проверка NetworkManager

# Step 4: Check routing table source / Проверить источник таблицы маршрутизации
ip route show default
```

---

## Universal Backend Check / Универсальная проверка бэкенда

### Service Status Matrix / Матрица статусов сервисов

Check which service is actually running and enabled.

```bash
systemctl status NetworkManager systemd-networkd networking network --no-pager
```

**Interpretation:**
- **NetworkManager**: Active on most Desktops (Gnome/KDE) and RHEL/CentOS 7+.
- **systemd-networkd**: Active on modern Servers (Ubuntu Server 18.04+, Arch, CoreOS).
- **networking**: Active on legacy Debian/Ubuntu (`ifupdown`).
- **network**: Active on legacy RHEL/CentOS (`initscripts`).

---

## NetworkManager (NM)

Common on: Ubuntu Desktop, Fedora, RHEL 7/8/9, CentOS.

### Check Status & Managed Devices / Проверка статуса и устройств
```bash
systemctl status NetworkManager  # Check service / Проверить сервис
nmcli general status             # minimal status / Краткий статус
nmcli device status              # List devices / Список устройств
```

**Sample Output:**
```
DEVICE       TYPE      STATE      CONNECTION 
enp3s0       ethernet  connected  Wired connection 1 
wlan0        wifi      connected  MyWiFi 
lo           loopback  unmanaged  --
```
- `connected`: Managed by NM.
- `unmanaged`: Ignored by NM (likely managed by another backend).

### Configuration Locations / Расположение конфигурации
- **Main Config:** `/etc/NetworkManager/NetworkManager.conf`
- **Connections:** `/etc/NetworkManager/system-connections/` (Keyfiles)
- **Legacy Configs:** `/etc/sysconfig/network-scripts/ifcfg-*` (RHEL/CentOS)

---

## systemd-networkd

Common on: Ubuntu Server, Arch Linux, Container OS, Embedded.

### Check Status & Managed Devices / Проверка статуса и устройств
```bash
systemctl status systemd-networkd  # Check service / Проверить сервис
networkctl list                    # List interfaces / Список интерфейсов
networkctl status <INTERFACE>      # Detail status / Детальный статус
```

**Sample Output:**
```
IDX LINK    TYPE     OPERATIONAL SETUP     
  1 lo      loopback carrier     unmanaged 
  2 enp3s0  ether    routable    configured
```
- `configured`: Managed by systemd-networkd.
- `unmanaged`: Ignored (likely managed by NM or legacy scripts).

### Configuration Locations / Расположение конфигурации
- **Global:** `/etc/systemd/networkd.conf`
- **Profiles:** `/etc/systemd/network/*.network`, `/lib/systemd/network/*.network`

---

## Distro-Specific Layers / Дистрибутив-специфичные слои

### Netplan (Ubuntu/Debian)
*Abstract renderer generator. Runs on top of NM or networkd.*

#### Check Renderer / Проверить рендерер
```bash
sudo netplan get
# OR look at config files / ИЛИ посмотреть файлы конфигурации
cat /etc/netplan/*.yaml
```

**Config Interpretation:**
```yaml
network:
  version: 2
  renderer: networkd  # OR NetworkManager
```
- if `renderer` is missing, default is `networkd` on Server, `NetworkManager` on Desktop.

---

### Legacy: Ifupdown (Debian/Old Ubuntu)
*Traditional Debian-style networking.*

#### Check Status / Проверка статуса
```bash
systemctl status networking
cat /etc/network/interfaces
ls /etc/network/interfaces.d/
```

**Active Check:**
If `/run/network/ifstate` exists and interacts with active interfaces.

---

### Legacy: Sysconfig (RHEL/CentOS/Fedora)
*Traditional Red Hat-style networking (`initscripts`).*

#### Check Status / Проверка статуса
```bash
systemctl status network
ls /etc/sysconfig/network-scripts/ifcfg-*
```
> [!NOTE]
> On modern RHEL 8/9, `ifcfg` files are often read by NetworkManager via the `nm-settings-ifcfg-rh` plugin, even if the legacy `network` service is gone.

---

## Interface Ownership / Принадлежность интерфейса

Use this script block to determine the "owner" of a specific interface (replace `<INTERFACE>`).

```bash
INTF="<INTERFACE>" # e.g., eth0

echo "Checking owner for $INTF..."

# 1. Check NetworkManager
if nmcli device status | grep -q "$INTF.*connected"; then
    echo "[X] NetworkManager is managing $INTF"
fi

# 2. Check systemd-networkd
if networkctl status "$INTF" | grep -q "configured"; then
    echo "[X] systemd-networkd is managing $INTF"
fi

# 3. Check legacy ifupdown (Debian)
if grep -q "$INTF" /etc/network/interfaces; then
    echo "[X] defined in /etc/network/interfaces (ifupdown)"
fi

# 4. Check legacy sysconfig (RHEL)
if [ -f "/etc/sysconfig/network-scripts/ifcfg-$INTF" ]; then
    echo "[X] defined in /etc/sysconfig/network-scripts/ifcfg-$INTF"
fi
```

---

## Comparison Tables / Таблицы сравнения

### Network Management Backends / Сетевые бэкенды

| Backend | Primary Distros | Config Path | Service Name | Command Tool |
| :--- | :--- | :--- | :--- | :--- |
| **NetworkManager** | Fedora, RHEL, Ubuntu Desktop | `/etc/NetworkManager/` | `NetworkManager` | `nmcli`, `nmtui` |
| **systemd-networkd** | Arch, Ubuntu Server, CoreOS | `/etc/systemd/network/` | `systemd-networkd` | `networkctl` |
| **ifupdown** | Debian, Old Ubuntu, Alpine | `/etc/network/interfaces` | `networking` | `ifup`, `ifdown` |
| **sysconfig** | Old RHEL/CentOS | `/etc/sysconfig/network-scripts/` | `network` | `ip`, `ifup` |
| **Netplan** | Ubuntu 18.04+ | `/etc/netplan/*.yaml` | Generates configs | `netplan` |

### Interface States / Состояния интерфейсов

| State | NetworkManager | systemd-networkd | Meaning (EN / RU) |
| :--- | :--- | :--- | :--- |
| **Active** | `connected` | `routable` / `configured` | Interface is Up and Managed / Интерфейс поднят и управляется |
| **Unmanaged** | `unmanaged` | `unmanaged` | Ignored by this backend / Игнорируется этим бэкендом |
| **Down** | `unavailable` | `no-carrier` | Cable unplugged or down / Кабель отключен или интерфейс выключен |

---

## Troubleshooting / Устранение неполадок

### Conflict Resolution / Разрешение конфликтов

> [!CAUTION]
> Never run two network managers managing the *same* interface simultaneously. This causes route flapping and connection drops.

#### Scenario 1: Switch from NetworkManager to networkd
```bash
# 1. Stop NM / Остановить NM
sudo systemctl disable --now NetworkManager

# 2. Enable networkd / Включить networkd
sudo systemctl enable --now systemd-networkd

# 3. (Ubuntu only) Apply Netplan / (Только Ubuntu) Применить Netplan
# Edit /etc/netplan/01-config.yaml -> set renderer: networkd
sudo netplan apply
```

#### Scenario 2: Ignored Interface (Unmanaged)
If an interface shows `unmanaged` in both `nmcli` and `networkctl`:
1. Check `/etc/network/interfaces`: If listed here, it might be locked by legacy ifupdown.
2. Check `NetworkManager.conf`:
   ```ini
   [keyfile]
   unmanaged-devices=interface-name:<INTERFACE>
   ```

### Logs & Debugging / Логи и отладка
```bash
# NetworkManager logs / Логи NM
journalctl -u NetworkManager -f

# systemd-networkd logs / Логи networkd
journalctl -u systemd-networkd -f

# Kernel network events / События ядра сети
dmesg | grep -i <INTERFACE>
```
