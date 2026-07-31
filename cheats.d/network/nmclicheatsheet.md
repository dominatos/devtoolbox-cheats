Title: 🌐 nmcli — NetworkManager CLI
Group: Network
Icon: 🌐
Order: 20

# nmcli — NetworkManager Command Line Interface

`nmcli` is the command-line interface for NetworkManager, the default network management tool for RHEL, Fedora, Ubuntu, and many other distributions. It provides full control over network connections without requiring a GUI.

## Table of Contents
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management%20/%20Основное%20управление)
- [Connection Types](#Connection%20Types%20/%20Типы%20соединений)
- [WiFi Management](#WiFi%20Management%20/%20Управление%20WiFi)
- [VPN Connections](#VPN%20Connections%20/%20VPN%20соединения)
- [Advanced Networking](#Advanced%20Networking%20/%20Продвинутые%20настройки)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools%20/%20Устранение%20неполадок)
- [Comparison Tables](#Comparison%20Tables%20/%20Таблицы%20сравнения)

---

## Installation & Configuration

### Install NetworkManager / Установка NetworkManager

#### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y network-manager  # Install NetworkManager / Установить NetworkManager
```

#### RHEL / CentOS / AlmaLinux
```bash
sudo dnf install -y NetworkManager  # Install NetworkManager / Установить NetworkManager
```

### Enable NetworkManager Service / Включение сервиса
```bash
sudo systemctl enable --now NetworkManager  # Enable and start / Включить и запустить
sudo systemctl status NetworkManager          # Check status / Проверить статус
```

### Configuration Paths / Пути конфигурации
- **Main config:** `/etc/NetworkManager/NetworkManager.conf`
- **Connection profiles:** `/etc/NetworkManager/system-connections/`
- **Dispatcher scripts:** `/etc/NetworkManager/dispatcher.d/`
- **DNS config:** `/etc/NetworkManager/conf.d/`

### Log Locations / Расположение логов
- **Journal:** `journalctl -u NetworkManager -f`
- **Legacy log:** `/var/log/syslog` or `/var/log/messages`

---

## Core Management / Основное управление

### General Status / Общий статус
```bash
nmcli general status                  # Overall NM status / Общий статус NetworkManager
nmcli general hostname                # Show hostname / Показать имя хоста
sudo nmcli general hostname <HOST>    # Set hostname / Установить имя хоста
```

**Sample Output:**
```
STATE      CONNECTIVITY  WIFI-HW  WIFI     WWAN-HW  WWAN
connected  full          enabled  enabled  enabled  enabled
```

### Device Management / Управление устройствами
```bash
nmcli device status                   # List all devices / Список устройств
nmcli device show <DEVICE>            # Show device details / Детали устройства
nmcli device connect <DEVICE>         # Connect device / Подключить устройство
nmcli device disconnect <DEVICE>      # Disconnect device / Отключить устройство
nmcli device wifi list                # List WiFi networks / Список WiFi сетей
```

### Connection Management / Управление соединениями
```bash
nmcli connection show                 # List all connections / Список соединений
nmcli connection show <CONN>          # Show connection details / Детали соединения
nmcli connection up <CONN>            # Activate connection / Активировать соединение
nmcli connection down <CONN>          # Deactivate connection / Деактивировать соединение
nmcli connection reload               # Reload all configs / Перезагрузить конфигурации
nmcli connection delete <CONN>        # Delete connection / Удалить соединение
```

> [!TIP]
> Connection names with spaces must be quoted: `nmcli connection up "My WiFi"`

---

## Connection Types / Типы соединений

### Ethernet Static IP / Статический IP для Ethernet
```bash
nmcli connection add \
  type ethernet \
  con-name <CONN_NAME> \
  ifname <INTERFACE> \
  ip4 <IP>/24 \
  gw4 <GATEWAY> \
  ipv4.dns "<DNS1> <DNS2>"
# Create static Ethernet connection / Создать статическое Ethernet подключение
```

**Example:**
```bash
nmcli connection add \
  type ethernet \
  con-name office-eth \
  ifname enp0s3 \
  ip4 192.168.1.100/24 \
  gw4 192.168.1.1 \
  ipv4.dns "8.8.8.8 8.8.4.4"
```

### Ethernet DHCP / DHCP для Ethernet
```bash
nmcli connection add \
  type ethernet \
  con-name <CONN_NAME> \
  ifname <INTERFACE>
# Create DHCP Ethernet connection / Создать DHCP Ethernet подключение
```

### Modify Existing Connection / Изменить существующее соединение
```bash
nmcli connection modify <CONN> ipv4.addresses <IP>/24  # Change IP / Изменить IP
nmcli connection modify <CONN> ipv4.gateway <GATEWAY>  # Change gateway / Изменить шлюз
nmcli connection modify <CONN> ipv4.dns "<DNS1> <DNS2>"  # Change DNS / Изменить DNS
nmcli connection modify <CONN> ipv4.method manual      # Set to static / Переключить на статику
nmcli connection modify <CONN> ipv4.method auto        # Set to DHCP / Переключить на DHCP
nmcli connection up <CONN>                              # Apply changes / Применить изменения
```

> [!WARNING]
> Always run `nmcli connection up <CONN>` after modifying to apply changes. Without this, the configuration is saved but not active.

---

## WiFi Management / Управление WiFi

### List Available Networks / Список доступных сетей
```bash
nmcli device wifi list                # Show all WiFi networks / Показать WiFi сети
nmcli device wifi rescan              # Rescan for networks / Повторить сканирование
```

### Connect to WiFi / Подключиться к WiFi
```bash
nmcli device wifi connect "<SSID>" password "<PASSWORD>"  # Connect to WiFi / Подключиться к WiFi
```

### Create WiFi Connection / Создать WiFi соединение
```bash
nmcli connection add \
  type wifi \
  con-name <CONN_NAME> \
  ifname <INTERFACE> \
  ssid "<SSID>" \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "<PASSWORD>"
# Create WiFi connection / Создать WiFi подключение
```

### WiFi Hotspot / WiFi точка доступа
```bash
nmcli device wifi hotspot \
  ifname <INTERFACE> \
  ssid "<HOTSPOT_NAME>" \
  password "<PASSWORD>"
# Create WiFi hotspot / Создать WiFi точку доступа
```

---

## VPN Connections / VPN соединения

### OpenVPN Connection / OpenVPN подключение
```bash
nmcli connection import type openvpn file <CONFIG>.ovpn  # Import OpenVPN config / Импортировать OpenVPN
nmcli connection up <VPN_NAME>                            # Connect to VPN / Подключиться к VPN
```

### Manual VPN Setup / Ручная настройка VPN
```bash
nmcli connection add \
  type vpn \
  vpn-type openvpn \
  con-name <VPN_NAME> \
  vpn.data "remote=<VPN_SERVER>, connection-type=password"
# Create VPN connection / Создать VPN подключение
```

---

## Advanced Networking / Продвинутые настройки

### Bridge Creation / Создание моста
```bash
nmcli connection add type bridge con-name <BRIDGE_NAME> ifname <BRIDGE_IF>  # Create bridge / Создать мост
nmcli connection add type ethernet slave-type bridge con-name <SLAVE_NAME> ifname <INTERFACE> master <BRIDGE_IF>  # Add slave / Добавить slave
nmcli connection up <BRIDGE_NAME>  # Activate bridge / Активировать мост
```

### Bond (Link Aggregation) / Объединение каналов
```bash
nmcli connection add type bond con-name <BOND_NAME> ifname <BOND_IF> mode active-backup  # Create bond / Создать bond
nmcli connection add type ethernet slave-type bond con-name <SLAVE1> ifname <IF1> master <BOND_IF>  # Add first slave / Первый интерфейс
nmcli connection add type ethernet slave-type bond con-name <SLAVE2> ifname <IF2> master <BOND_IF>  # Add second slave / Второй интерфейс
nmcli connection up <BOND_NAME>  # Activate bond / Активировать bond
```

### VLAN Configuration / Настройка VLAN
```bash
nmcli connection add type vlan con-name <VLAN_NAME> dev <PARENT_IF> id <VLAN_ID>  # Create VLAN / Создать VLAN
nmcli connection modify <VLAN_NAME> ipv4.addresses <IP>/24  # Set IP / Установить IP
nmcli connection up <VLAN_NAME>  # Activate VLAN / Активировать VLAN
```

---

## Troubleshooting & Tools / Устранение неполадок

### Common Issues / Типичные проблемы
```bash
# Connection won't activate / Соединение не активируется
nmcli connection delete <CONN> && nmcli connection reload  # Delete and reload / Удалить и перезагрузить

# DNS not resolving / DNS не работает
nmcli connection modify <CONN> ipv4.ignore-auto-dns yes  # Ignore auto DNS / Игнорировать авто DNS
nmcli connection modify <CONN> ipv4.dns "8.8.8.8 8.8.4.4"  # Set manual DNS / Установить DNS вручную
nmcli connection up <CONN>  # Apply / Применить

# NetworkManager not managing interface / NetworkManager не управляет интерфейсом
sudo nmcli device set <DEVICE> managed yes  # Enable management / Включить управление
```

### Debug Logging / Отладочное логирование
```bash
sudo nmcli general logging level DEBUG  # Enable debug logging / Включить отладку
journalctl -u NetworkManager -f          # Watch logs / Смотреть логи
sudo nmcli general logging level INFO    # Restore normal logging / Восстановить обычное логирование
```

### Export/Import Connections / Экспорт/Импорт соединений
```bash
nmcli connection show <CONN> > <CONN>.txt  # Export connection details / Экспортировать детали
sudo cp /etc/NetworkManager/system-connections/<CONN> /backup/  # Backup connection file / Бэкап файла
```

---

## Comparison Tables / Таблицы сравнения

### Bond Modes Comparison / Сравнение режимов Bond

| Mode | Description (EN / RU) | Use Case |
| :--- | :--- | :--- |
| **balance-rr (0)** | Round-robin load balancing / Циклическая балансировка | Maximum throughput, requires switch support |
| **active-backup (1)** | Active/standby failover / Активный/резервный | Simple failover, no switch config needed |
| **balance-xor (2)** | XOR hash-based load balance / Балансировка по хэшу | Load balancing without LACP |
| **802.3ad (4)** | LACP (Link Aggregation) / LACP агрегация | Enterprise, requires LACP support on switch |

### Connection Types Comparison / Сравнение типов соединений

| Type | Typical Use | Configuration Complexity |
| :--- | :--- | :--- |
| **Ethernet** | Wired LAN / Проводная сеть | Simple / Простая |
| **WiFi** | Wireless LAN / Беспроводная сеть | Medium / Средняя |
| **Bridge** | VM networking, containers / ВМ, контейнеры | Medium / Средняя |
| **Bond** | High availability / Высокая доступность | Complex / Сложная |
| **VLAN** | Network segmentation / Сегментация сети | Medium / Средняя |
| **VPN** | Remote access / Удалённый доступ | Complex / Сложная |

## 📚 Documentation Links

- [nmcli Man Page](https://networkmanager.dev/docs/api/latest/nmcli.html)

#network #sysadmin #linux
