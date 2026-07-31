---
Title: 📝 netplan — Network Configuration
Group: Network
Icon: 📝
Order: 21
tags:
  - network
  - sysadmin
  - linux
---

# Netplan — Network Configuration for Ubuntu

Netplan is the default network configuration abstraction layer used by Ubuntu 17.10+ and other modern Ubuntu-based distributions. It uses YAML configuration files and can render configurations for NetworkManager or systemd-networkd as backends.

## Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Static & DHCP Configuration](#Static%20&%20DHCP%20Configuration)
- [Advanced Networking](#Advanced%20Networking)
- [WiFi Configuration](#WiFi%20Configuration)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Migration Guide](#Migration%20Guide)
- [Comparison Tables](#Comparison%20Tables)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

## Installation & Configuration

### Install Netplan
```bash
sudo apt update && sudo apt install -y netplan.io  # Install netplan / Установить netplan
```

### Configuration Paths
- **Main config directory:** `/etc/netplan/`
- **Common config file:** `/etc/netplan/01-netcfg.yaml` or `/etc/netplan/50-cloud-init.yaml`
- **Rendered configs:** `/run/netplan/` (read-only)

> [!IMPORTANT]
> Netplan files must have `.yaml` extension and use valid YAML syntax (indentation with spaces, not tabs).

### Backend Selection
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd  # Use systemd-networkd / Использовать systemd-networkd
  # renderer: NetworkManager  # Use NetworkManager / Использовать NetworkManager
```

---

## Core Management

### Apply Configuration
```bash
sudo netplan apply               # Apply netplan config / Применить конфигурацию
sudo netplan --debug apply       # Apply with debug output / Применить с отладкой
sudo netplan try                 # Try config with auto-rollback / Попробовать с откатом
```

> [!TIP]
> Use `netplan try` in production to test changes safely. It will revert automatically after timeout if you don't confirm.

### Validate Configuration
```bash
sudo netplan generate            # Generate backend config / Сгенерировать конфигурацию бэкенда
sudo netplan --debug generate    # Generate with debug / Сгенерировать с отладкой
```

### View Current Configuration
```bash
cat /etc/netplan/*.yaml          # View all netplan configs / Просмотреть все конфигурации
sudo netplan get                 # Show merged config / Показать объединённую конфигурацию
```

---

## Static & DHCP Configuration

### DHCP Configuration
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:  # Replace with your interface / Замените на ваш интерфейс
      dhcp4: true
      dhcp6: false
```

```bash
sudo netplan apply  # Apply configuration / Применить конфигурацию
```

### Static IP Configuration
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      addresses:
        - 192.168.1.100/24  # Static IP / Статический IP
      routes:
        - to: default
          via: 192.168.1.1  # Gateway / Шлюз
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]  # DNS servers / DNS серверы
```

### Multiple IP Addresses
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses:
        - 192.168.1.100/24
        - 192.168.1.101/24  # Second IP / Второй IP
        - 2001:db8::1/64    # IPv6 / IPv6 адрес
```

---

## Advanced Networking

### Bridge Configuration
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  bridges:
    br0:
      interfaces: [enp0s3]  # Bridge member / Член моста
      addresses: [192.168.1.100/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8]
      parameters:
        stp: true  # Enable Spanning Tree / Включить STP
        forward-delay: 4
```

```bash
sudo netplan apply  # Apply bridge config / Применить конфигурацию моста
```

### Bond (Link Aggregation)
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
    enp0s8:
      dhcp4: false
  bonds:
    bond0:
      interfaces: [enp0s3, enp0s8]  # Bond members / Члены bond
      addresses: [192.168.1.100/24]
      routes:
        - to: default
          via: 192.168.1.1
      parameters:
        mode: active-backup  # Bond mode / Режим bond
        primary: enp0s3      # Primary interface / Основной интерфейс
        mii-monitor-interval: 100
```

### VLAN Configuration
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  vlans:
    vlan10:
      id: 10              # VLAN ID / VLAN ID
      link: enp0s3        # Parent interface / Родительский интерфейс
      addresses: [192.168.10.100/24]
```

---

## WiFi Configuration

### Basic WiFi
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlp2s0:  # WiFi interface / WiFi интерфейс
      access-points:
        "<SSID>":
          password: "<PASSWORD>"
      dhcp4: true
```

### WiFi with Multiple Networks / WiFi
`/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlp2s0:
      access-points:
        "Home_WiFi":
          password: "<HOME_PASSWORD>"
        "Office_WiFi":
          password: "<OFFICE_PASSWORD>"
      dhcp4: true
```

> [!NOTE]
> WiFi configuration typically requires NetworkManager as the renderer. systemd-networkd has limited WiFi support.

---

## Troubleshooting & Tools

### Common Issues
```bash
# YAML syntax errors
sudo netplan --debug generate  # Check for YAML errors / Проверить ошибки YAML

# Configuration not applying
sudo netplan apply
sudo systemctl restart systemd-networkd  # Restart backend / Перезапустить бэкенд
# OR for NetworkManager:
sudo systemctl restart NetworkManager

# Revert to previous config
sudo cp /etc/netplan/01-netcfg.yaml.bak /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

### Debug Mode
```bash
sudo netplan --debug apply       # Verbose apply / Подробное применение
sudo networkctl status           # Check systemd-networkd status / Проверить статус
journalctl -u systemd-networkd -f  # Follow networkd logs / Смотреть логи
```

### Backup Configuration
```bash
sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak  # Backup / Бэкап
```

---

## Migration Guide

### Production Runbook: Migrate from ifupdown to netplan

1. **Backup current configuration / Бэкап текущей конфигурации**
   ```bash
   sudo cp /etc/network/interfaces /etc/network/interfaces.bak  # Backup old config / Бэкап старой конфигурации
   ip addr show > /tmp/current-network-config.txt  # Save current state / Сохранить текущее состояние
   ```

2. **Create netplan configuration / Создать конфигурацию netplan**
   ```bash
   sudo nano /etc/netplan/01-netcfg.yaml  # Create new config / Создать новую конфигурацию
   ```

3. **Test the configuration / Тестировать конфигурацию**
   ```bash
   sudo netplan try  # Try with auto-rollback / Попробовать с автооткатом
   ```

4. **Apply permanently / Применить постоянно**
   ```bash
   sudo netplan apply  # Apply configuration / Применить конфигурацию
   ```

5. **Verify connectivity / Проверить связь**
   ```bash
   ip addr show  # Check IP addresses / Проверить IP адреса
   ping -c 3 8.8.8.8  # Test connectivity / Проверить связь
   ```

6. **Disable old ifupdown (optional) / Отключить старый ifupdown (опционально)**
   ```bash
   sudo systemctl disable networking  # Disable ifupdown / Отключить ifupdown
   ```

---

## Comparison Tables

### Netplan Renderers Comparison

| Renderer | Best For | WiFi Support | Desktop Integration |
| :--- | :--- | :--- | :--- |
| **systemd-networkd** | Servers, minimal systems / Серверы, минимальные системы | Limited / Ограниченная | No / Нет |
| **NetworkManager** | Desktops, laptops / Десктопы, ноутбуки | Full / Полная | Yes / Да |

### Bond Modes

| Mode | Description (EN / RU) | Use Case |
| :--- | :--- | :--- |
| **balance-rr** | Round-robin / Циклическая балансировка | Maximum throughput |
| **active-backup** | Failover only / Только отказоустойчивость | Simple HA, no switch config |
| **802.3ad** | LACP aggregation / LACP агрегация | Enterprise, switch support required |

## 📚 Documentation Links

- [Netplan Official Docs](https://netplan.io/)
- [Netplan Man Page](https://manpages.ubuntu.com/manpages/noble/man5/netplan.5.html)
