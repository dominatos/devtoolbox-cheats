Title: 🌐 ip — Network Configuration
Group: Network
Icon: 🌐
Order: 3

# ip — Network Configuration Utility

`ip` is the primary command-line tool from the `iproute2` package for configuring network interfaces, routing, tunnels, and ARP entries on Linux. It replaces the legacy `ifconfig`, `route`, and `arp` commands, providing a unified and more powerful interface.

📚 **Official Docs / Официальная документация:** [ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html)

## Table of Contents
- [Address Management](#-address-management--управление-адресами)
- [Link Management](#-link-management--управление-ссылками)
- [Routing](#-routing--маршрутизация)
- [Neighbor (ARP/NDP)](#-neighbor-arpndp--соседи)
- [Tunnels & VLANs](#-tunnels--vlans--туннели-и-vlan)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

## 📍 Address Management / Управление адресами

### Show Addresses / Показать адреса
```bash
ip addr                                       # Show all addresses / Показать все адреса
ip addr show                                  # Same as above / То же что выше
ip -brief addr                                # Brief format / Краткий формат
ip -4 addr                                    # IPv4 only / Только IPv4
ip -6 addr                                    # IPv6 only / Только IPv6
ip addr show dev eth0                         # Show for specific interface / Показать для конкретного интерфейса
```

### Add Addresses / Добавить адреса
```bash
sudo ip addr add 10.0.0.10/24 dev eth0        # Add IPv4 address / Добавить IPv4 адрес
sudo ip addr add 2001:db8::10/64 dev eth0     # Add IPv6 address / Добавить IPv6 адрес
sudo ip addr add 192.168.1.10/24 broadcast 192.168.1.255 dev eth0  # With broadcast / С broadcast
```

### Delete Addresses / Удалить адреса
```bash
sudo ip addr del 10.0.0.10/24 dev eth0        # Delete address / Удалить адрес
sudo ip addr flush dev eth0                   # Remove all addresses / Удалить все адреса
```

---

## 🔗 Link Management / Управление ссылками

### Show Links / Показать ссылки
```bash
ip link                                       # Show all links / Показать все ссылки
ip link show                                  # Same as above / То же что выше
ip -brief link                                # Brief format / Краткий формат
ip -s link                                    # With statistics / Со статистикой
ip -s -s link                                 # Detailed statistics / Подробная статистика
```

### Link Control / Управление ссылками
```bash
sudo ip link set eth0 up                      # Bring interface up / Поднять интерфейс
sudo ip link set eth0 down                    # Bring interface down / Опустить интерфейс
sudo ip link set eth0 mtu 1500                # Set MTU / Установить MTU
sudo ip link set eth0 address 00:11:22:33:44:55  # Change MAC / Изменить MAC
sudo ip link set eth0 promisc on              # Enable promiscuous mode / Включить promiscuous режим
```

### Create Virtual Interfaces / Создать виртуальные интерфейсы
```bash
sudo ip link add veth0 type veth peer name veth1  # Create veth pair / Создать veth пару
sudo ip link add br0 type bridge              # Create bridge / Создать bridge
sudo ip link set eth0 master br0              # Add to bridge / Добавить в bridge
```

### Delete Links / Удалить ссылки
```bash
sudo ip link delete veth0                     # Delete interface / Удалить интерфейс
sudo ip link delete br0 type bridge           # Delete bridge / Удалить bridge
```

---

## 🗺️ Routing / Маршрутизация

### Show Routes / Показать маршруты
```bash
ip route                                      # Show routing table / Показать таблицу маршрутизации
ip route show                                 # Same as above / То же что выше
ip -4 route                                   # IPv4 routes / IPv4 маршруты
ip -6 route                                   # IPv6 routes / IPv6 маршруты
ip route get 8.8.8.8                          # Show route to IP / Показать маршрут к IP
```

### Add Routes / Добавить маршруты
```bash
sudo ip route add 192.168.1.0/24 via 10.0.0.1  # Add route / Добавить маршрут
sudo ip route add default via 10.0.0.1        # Add default gateway / Добавить шлюз по умолчанию
sudo ip route add 192.168.1.0/24 dev eth0     # Add direct route / Добавить прямой маршрут
sudo ip route add 192.168.1.0/24 via 10.0.0.1 metric 100  # With metric / С метрикой
```

### Delete Routes / Удалить маршруты
```bash
sudo ip route del 192.168.1.0/24              # Delete route / Удалить маршрут
sudo ip route del default via 10.0.0.1        # Delete default gateway / Удалить шлюз по умолчанию
sudo ip route flush cache                     # Flush routing cache / Очистить кэш маршрутизации
```

---

## 🏘️ Neighbor (ARP/NDP) / Соседи

### Show Neighbors / Показать соседей
```bash
ip neigh                                      # Show ARP/NDP table / Показать таблицу ARP/NDP
ip neigh show                                 # Same as above / То же что выше
ip -4 neigh                                   # IPv4 neighbors (ARP) / IPv4 соседи (ARP)
ip -6 neigh                                   # IPv6 neighbors (NDP) / IPv6 соседи (NDP)
```

### Manage Neighbors / Управление соседями
```bash
sudo ip neigh add 192.168.1.10 lladdr 00:11:22:33:44:55 dev eth0  # Add entry / Добавить запись
sudo ip neigh del 192.168.1.10 dev eth0       # Delete entry / Удалить запись
sudo ip neigh flush dev eth0                  # Flush neighbors / Очистить соседей
```

---

## 🚇 Tunnels & VLANs / Туннели и VLAN

### VLANs
```bash
sudo ip link add link eth0 name eth0.100 type vlan id 100  # Create VLAN / Создать VLAN
sudo ip addr add 192.168.100.1/24 dev eth0.100  # Add IP to VLAN / Добавить IP в VLAN
sudo ip link set eth0.100 up                  # Bring VLAN up / Поднять VLAN
```

### GRE Tunnels / GRE туннели
```bash
sudo ip tunnel add gre1 mode gre remote <REMOTE_IP> local <LOCAL_IP> ttl 255
sudo ip addr add 10.0.0.1/30 dev gre1
sudo ip link set gre1 up
```

### VXLAN
```bash
sudo ip link add vxlan0 type vxlan id 42 dev eth0 dstport 4789 group 239.1.1.1
sudo ip addr add 10.0.0.1/24 dev vxlan0
sudo ip link set vxlan0 up
```

---

## 🌟 Real-World Examples / Примеры из практики

### Basic Network Setup / Базовая настройка сети
```bash
# Configure static IP / Настроить статический IP
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.10/24 dev eth0
sudo ip route add default via 192.168.1.1
sudo ip link set eth0 up
```

### Temporary IP for Testing / Временный IP для тестирования
```bash
# Add temporary IP / Добавить временный IP
sudo ip addr add 10.0.0.100/24 dev eth0

# Test / Тест
ping -c 3 10.0.0.1

# Remove / Удалить
sudo ip addr del 10.0.0.100/24 dev eth0
```

### Bridge Configuration / Конфигурация bridge
```bash
# Create bridge / Создать bridge
sudo ip link add br0 type bridge
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0
sudo ip link set br0 up
sudo ip addr add 192.168.1.1/24 dev br0
```

### Docker-Like Network / Сеть как в Docker
```bash
# Create bridge network / Создать bridge сеть
sudo ip link add docker0 type bridge
sudo ip addr add 172.17.0.1/16 dev docker0
sudo ip link set docker0 up

# Create veth pair / Создать veth пару
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 master docker0
sudo ip link set veth0 up
```

### Multi-Homed Host / Хост с несколькими сетями
```bash
# eth0: Internal network / Внутренняя сеть
sudo ip addr add 192.168.1.10/24 dev eth0
sudo ip route add 192.168.0.0/16 via 192.168.1.1 dev eth0

# eth1: External network / Внешняя сеть
sudo ip addr add 10.0.0.10/24 dev eth1
sudo ip route add default via 10.0.0.1 dev eth1
```

### Policy Routing / Политическая маршрутизация
```bash
# Create routing table / Создать таблицу маршрутизации
echo "200 custom" >> /etc/iproute2/rt_tables

# Add rule / Добавить правило
sudo ip rule add from 192.168.1.0/24 table custom
sudo ip route add default via 10.0.0.1 table custom
```

### Monitor Network Changes / Мониторить изменения сети
```bash
# Watch addresses / Следить за адресами
ip -timestamp monitor address

# Watch routes / Следить за маршрутами
ip -timestamp monitor route

# Watch all / Следить за всем
ip -timestamp monitor all
```

### Quick Network Check / Быстрая проверка сети
```bash
# Check network config / Проверить конфигурацию сети
ip -br addr
ip -br link
ip route show
ip neigh show
```

## 💡 Best Practices / Лучшие практики

- Use `-brief` for quick overview / Используйте `-brief` для быстрого обзора
- Use `-4` or `-6` to filter by IP version / Используйте `-4` или `-6` для фильтрации по версии IP
- Changes with ip are temporary (lost on reboot) / Изменения с ip временные (теряются при перезагрузке)
- Use netplan/networkd for persistent config / Используйте netplan/networkd для постоянной конфигурации
- Use `ip` instead of deprecated `ifconfig` / Используйте `ip` вместо устаревшего `ifconfig`
- Monitor with `ip -timestamp monitor` / Мониторьте с `ip -timestamp monitor`

## 🔧 Common Subcommands / Распространённые подкоманды

| Subcommand | Description (EN / RU) |
|------------|----------------------|
| `ip addr` | Address management / Управление адресами |
| `ip link` | Link management / Управление ссылками |
| `ip route` | Routing / Маршрутизация |
| `ip neigh` | Neighbor/ARP / Соседи/ARP |
| `ip tunnel` | Tunnels / Туннели |
| `ip rule` | Policy routing / Политическая маршрутизация |
| `ip monitor` | Monitor changes / Мониторить изменения |

## 📋 Useful Options / Полезные опции

| Option | Description (EN / RU) |
|--------|----------------------|
| `-4` | IPv4 only / Только IPv4 |
| `-6` | IPv6 only / Только IPv6 |
| `-brief` | Brief output / Краткий вывод |
| `-s` | Statistics / Статистика |
| `-d` | Details / Детали |
| `-timestamp` | Add timestamps / Добавить временные метки |
| `-json` | JSON output / JSON вывод |

## ⚠️ Important Notes / Важные примечания

- `ip` is part of iproute2 package / `ip` часть пакета iproute2
- Changes are not persistent / Изменения не постоянные
- Use NetworkManager or netplan for persistence / Используйте NetworkManager или netplan для постоянства
- `ip` replaces `ifconfig`, `route`, `arp` / `ip` заменяет `ifconfig`, `route`, `arp`
