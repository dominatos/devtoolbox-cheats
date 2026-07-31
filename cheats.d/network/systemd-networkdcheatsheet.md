---
Title: ⚙️ systemd-networkd — Network Configuration
Group: Network
Icon: ⚙️
Order: 22
tags:
  - network
  - sysadmin
  - linux
---

# systemd-networkd — systemd Network Manager

`systemd-networkd` is systemd's native network configuration manager. It's ideal for servers and minimal systems where GUI tools are unnecessary. Configuration is done through `.network` and `.netdev` files.

## Table of Contents
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Network Configuration Files](#Network%20Configuration%20Files)
- [Advanced Networking](#Advanced%20Networking)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Comparison Tables](#Comparison%20Tables)

---

## Installation & Configuration

### Enable systemd-networkd
```bash
sudo systemctl enable --now systemd-networkd  # Enable and start / Включить и запустить
sudo systemctl enable --now systemd-resolved  # Enable DNS resolution / Включить DNS
sudo systemctl status systemd-networkd        # Check status / Проверить статус
```

### Configuration Paths
- **System configs:** `/etc/systemd/network/`
- **Network device files:** `/etc/systemd/network/*.netdev`
- **Network config files:** `/etc/systemd/network/*.network`
- **Runtime configs:** `/run/systemd/network/` (volatile)

### Log Locations
```bash
journalctl -u systemd-networkd -f  # Follow networkd logs / Смотреть логи
```

---

## Core Management

### Status Commands
```bash
networkctl status                   # Overall network status / Общий статус сети
networkctl list                     # List all interfaces / Список интерфейсов
networkctl status <INTERFACE>       # Interface details / Детали интерфейса
networkctl lldp                     # Show LLDP neighbors / Показать LLDP соседей
```

**Sample Output:**
```
IDX LINK   TYPE     OPERATIONAL SETUP
  1 lo     loopback carrier     unmanaged
  2 enp0s3 ether    routable    configured
```

### Reload Configuration
```bash
sudo networkctl reload              # Reload all configs / Перезагрузить конфигурации
sudo systemctl restart systemd-networkd  # Restart service / Перезапустить сервис
```

---

## Network Configuration Files

### DHCP Configuration
`/etc/systemd/network/20-wired.network`

```ini
[Match]
Name=enp0s3  # Interface name / Имя интерфейса

[Network]
DHCP=yes  # Enable DHCP / Включить DHCP
```

```bash
sudo systemctl restart systemd-networkd  # Apply config / Применить конфигурацию
```

### Static IP Configuration
`/etc/systemd/network/20-wired.network`

```ini
[Match]
Name=enp0s3

[Network]
Address=192.168.1.100/24  # Static IP / Статический IP
Gateway=192.168.1.1       # Gateway / Шлюз
DNS=8.8.8.8               # DNS server / DNS сервер
DNS=8.8.4.4
```

### Multiple IP Addresses
`/etc/systemd/network/20-wired.network`

```ini
[Match]
Name=enp0s3

[Network]
Address=192.168.1.100/24
Address=192.168.1.101/24  # Second IP / Второй IP
Address=2001:db8::1/64    # IPv6 / IPv6 адрес
Gateway=192.168.1.1
DNS=8.8.8.8
```

### Static Routes
`/etc/systemd/network/20-wired.network`

```ini
[Match]
Name=enp0s3

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1

[Route]
Destination=10.0.0.0/8    # Route to 10.0.0.0/8 / Маршрут к 10.0.0.0/8
Gateway=192.168.1.254     # Via gateway / Через шлюз
```

---

## Advanced Networking

### Bridge Configuration

**Step 1: Create bridge device / Создать устройство моста**

`/etc/systemd/network/10-bridge.netdev`

```ini
[NetDev]
Name=br0  # Bridge name / Имя моста
Kind=bridge
```

**Step 2: Configure bridge / Настроить мост**

`/etc/systemd/network/20-bridge.network`

```ini
[Match]
Name=br0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1
DNS=8.8.8.8
```

**Step 3: Add interface to bridge / Добавить интерфейс в мост**

`/etc/systemd/network/30-bridge-member.network`

```ini
[Match]
Name=enp0s3  # Physical interface / Физический интерфейс

[Network]
Bridge=br0  # Add to bridge / Добавить в мост
```

```bash
sudo systemctl restart systemd-networkd  # Apply / Применить
```

### Bond (Link Aggregation)

**Step 1: Create bond device / Создать устройство bond**

`/etc/systemd/network/10-bond.netdev`

```ini
[NetDev]
Name=bond0
Kind=bond

[Bond]
Mode=active-backup  # Bond mode / Режим bond
PrimaryReselectPolicy=always
MIIMonitorSec=100ms
```

**Step 2: Configure bond / Настроить bond**

`/etc/systemd/network/20-bond.network`

```ini
[Match]
Name=bond0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1
```

**Step 3: Add interfaces to bond / Добавить интерфейсы в bond**

`/etc/systemd/network/30-bond-member1.network`

```ini
[Match]
Name=enp0s3  # First interface / Первый интерфейс

[Network]
Bond=bond0
PrimarySlave=true  # Primary member / Основной член
```

`/etc/systemd/network/30-bond-member2.network`

```ini
[Match]
Name=enp0s8  # Second interface / Второй интерфейс

[Network]
Bond=bond0
```

### VLAN Configuration

**Step 1: Create VLAN device / Создать устройство VLAN**

`/etc/systemd/network/10-vlan10.netdev`

```ini
[NetDev]
Name=vlan10
Kind=vlan

[VLAN]
Id=10  # VLAN ID / VLAN ID
```

**Step 2: Configure VLAN / Настроить VLAN**

`/etc/systemd/network/20-vlan10.network`

```ini
[Match]
Name=vlan10

[Network]
Address=192.168.10.100/24
```

**Step 3: Attach VLAN to parent / Привязать VLAN к родительскому интерфейсу**

`/etc/systemd/network/30-parent.network`

```ini
[Match]
Name=enp0s3  # Parent interface / Родительский интерфейс

[Network]
VLAN=vlan10  # Attach VLAN / Привязать VLAN
```

---

## Troubleshooting & Tools

### Common Issues
```bash
# Interface not managed
networkctl status <INTERFACE>  # Check interface status / Проверить статус
sudo systemctl restart systemd-networkd  # Restart service / Перезапустить

# DNS not resolving / DNS
sudo systemctl enable --now systemd-resolved  # Enable resolved / Включить resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf  # Link resolv.conf / Привязать resolv.conf

# Configuration not applying
sudo networkctl reload  # Reload configs / Перезагрузить конфигурации
journalctl -u systemd-networkd --no-pager | tail -50  # Check logs / Проверить логи
```

### Debug Mode
```bash
sudo systemctl edit systemd-networkd --full  # Edit service file / Редактировать файл сервиса
# Add: Environment=SYSTEMD_LOG_LEVEL=debug
sudo systemctl daemon-reload  # Reload daemon / Перезагрузить демон
sudo systemctl restart systemd-networkd  # Restart with debug / Перезапустить с отладкой
journalctl -u systemd-networkd -f  # Watch debug logs / Смотреть отладочные логи
```

### Verify Configuration Syntax
```bash
sudo systemd-analyze verify /etc/systemd/network/*.network  # Verify syntax / Проверить синтаксис
```

---

## Comparison Tables

### systemd-networkd vs NetworkManager

| Feature | systemd-networkd | NetworkManager |
| :--- | :--- | :--- |
| **Target Use Case** | Servers, minimal systems / Серверы, минимальные системы | Desktops, laptops / Десктопы, ноутбуки |
| **WiFi Support** | Limited (wpa_supplicant) / Ограниченная | Full / Полная |
| **GUI Tools** | None / Нет | nmtui, nm-connection-editor |
| **Configuration Format** | .network files / .network файлы | keyfile, ifcfg, nmconnection |
| **Dependencies** | Minimal / Минимальные | Many / Много |
| **VPN Support** | Manual / Ручная | Plugin-based / На основе плагинов |

### Bond Modes

| Mode | systemd-networkd Value | Description (EN / RU) |
| :--- | :--- | :--- |
| **Active-Backup** | `active-backup` | Failover only / Только отказоустойчивость |
| **Balance-RR** | `balance-rr` | Round-robin load balance / Циклическая балансировка |
| **802.3ad (LACP)** | `802.3ad` | LACP aggregation / LACP агрегация |
| **Balance-XOR** | `balance-xor` | XOR hash-based balance / Балансировка по хэшу |

## 📚 Documentation Links

- [systemd.network Man Page](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
