---
Title: 🔍 Network Backend Detection — Linux (Universal)
Group: Network
Icon: 🔍
Order: 25
tags:
  - network
  - sysadmin
  - linux
---

# Network Backend Detection — Linux (Universal)

This cheatsheet provides a universal workflow to determine which network management backend (NetworkManager, systemd-networkd, Netplan, or legacy scripts) is controlling your network interfaces. Essential for troubleshooting network configuration conflicts on any Linux distribution (Ubuntu, Debian, RHEL, CentOS, Fedora).

## Table of Contents

- [Quick Detection Workflow](#Quick%20Detection%20Workflow)
- [Universal Backend Check](#Universal%20Backend%20Check)
- [NetworkManager (NM)](#NetworkManager%20(NM))
- [systemd-networkd](#systemd-networkd)
- [Distro-Specific Layers](#Distro-Specific%20Layers)
- [Interface Ownership](#Interface%20Ownership)
- [Comparison Tables](#Comparison%20Tables)
- [Troubleshooting](#Troubleshooting)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

## Quick Detection Workflow

### Production Runbook: Identify Network Backend

Run these commands in sequence to identify your active network backend on any Linux system:

```bash
# Step 1: Check active services
systemctl is-active NetworkManager systemd-networkd networking network

# Step 2: Check active listening processes
sudo netstat -tulpn | grep -E 'NetworkManager|systemd-networkd'

# Step 3: Check interface ownership (Universal)
networkctl list      # systemd-networkd check / Проверка systemd-networkd
nmcli device status  # NetworkManager check / Проверка NetworkManager

# Step 4: Check routing table source
ip route show default
```

---

## Universal Backend Check

### Service Status Matrix

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

### Check Status & Managed Devices
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

### Configuration Locations
- **Main Config:** `/etc/NetworkManager/NetworkManager.conf`
- **Connections:** `/etc/NetworkManager/system-connections/` (Keyfiles)
- **Legacy Configs:** `/etc/sysconfig/network-scripts/ifcfg-*` (RHEL/CentOS)

---

## systemd-networkd

Common on: Ubuntu Server, Arch Linux, Container OS, Embedded.

### Check Status & Managed Devices
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

### Configuration Locations
- **Global:** `/etc/systemd/networkd.conf`
- **Profiles:** `/etc/systemd/network/*.network`, `/lib/systemd/network/*.network`

---

## Distro-Specific Layers

### Netplan (Ubuntu/Debian)
*Abstract renderer generator. Runs on top of NM or networkd.*

#### Check Renderer
```bash
sudo netplan get
# OR look at config files
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

#### Check Status
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

#### Check Status
```bash
systemctl status network
ls /etc/sysconfig/network-scripts/ifcfg-*
```
> [!NOTE]
> On modern RHEL 8/9, `ifcfg` files are often read by NetworkManager via the `nm-settings-ifcfg-rh` plugin, even if the legacy `network` service is gone.

---

## Interface Ownership

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

## Comparison Tables

### Network Management Backends

| Backend | Primary Distros | Config Path | Service Name | Command Tool |
| :--- | :--- | :--- | :--- | :--- |
| **NetworkManager** | Fedora, RHEL, Ubuntu Desktop | `/etc/NetworkManager/` | `NetworkManager` | `nmcli`, `nmtui` |
| **systemd-networkd** | Arch, Ubuntu Server, CoreOS | `/etc/systemd/network/` | `systemd-networkd` | `networkctl` |
| **ifupdown** | Debian, Old Ubuntu, Alpine | `/etc/network/interfaces` | `networking` | `ifup`, `ifdown` |
| **sysconfig** | Old RHEL/CentOS | `/etc/sysconfig/network-scripts/` | `network` | `ip`, `ifup` |
| **Netplan** | Ubuntu 18.04+ | `/etc/netplan/*.yaml` | Generates configs | `netplan` |

### Interface States

| State | NetworkManager | systemd-networkd | Meaning (EN / RU) |
| :--- | :--- | :--- | :--- |
| **Active** | `connected` | `routable` / `configured` | Interface is Up and Managed / Интерфейс поднят и управляется |
| **Unmanaged** | `unmanaged` | `unmanaged` | Ignored by this backend / Игнорируется этим бэкендом |
| **Down** | `unavailable` | `no-carrier` | Cable unplugged or down / Кабель отключен или интерфейс выключен |

---

## Troubleshooting

### Conflict Resolution

> [!CAUTION]
> Never run two network managers managing the *same* interface simultaneously. This causes route flapping and connection drops.

#### Scenario 1: Switch from NetworkManager to networkd
```bash
# 1. Stop NM
sudo systemctl disable --now NetworkManager

# 2. Enable networkd
sudo systemctl enable --now systemd-networkd

# 3. (Ubuntu only) Apply Netplan / (Только Ubuntu)
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

### Logs & Debugging
```bash
# NetworkManager logs
journalctl -u NetworkManager -f

# systemd-networkd logs
journalctl -u systemd-networkd -f

# Kernel network events
dmesg | grep -i <INTERFACE>
```

## 📚 Documentation Links

- [systemd.network Man Page](https://man7.org/linux/man-pages/man5/networkd.network.5.html)
