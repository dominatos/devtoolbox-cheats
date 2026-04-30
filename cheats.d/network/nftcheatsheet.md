Title: 🕸 nftables — Modern Firewall
Group: Network
Icon: 🕸
Order: 14

# nftables — Modern Linux Firewall Framework

`nftables` is the modern replacement for `iptables`, `ip6tables`, `arptables`, and `ebtables`. It provides a unified, efficient, and more expressive syntax for packet filtering, NAT, and traffic classification on Linux systems. Available since kernel 3.13+.

📚 **Official Docs / Официальная документация:** [nftables wiki](https://wiki.nftables.org/)

## Table of Contents
- [Basic Commands](#basic-commands)
- [Tables & Chains](#tables--chains)
- [Rules](#rules)
- [NAT & Port Forwarding](#nat--port-forwarding)
- [Sets & Maps](#sets--maps)
- [Migration from iptables](#migration-from-iptables)
- [Real-World Examples](#real-world-examples)
- [Reference Tables](#reference-tables)

---

## Basic Commands

### List & View / Список и просмотр
```bash
sudo nft list tables                          # List all tables / Список всех таблиц
sudo nft list ruleset                         # Show full ruleset / Показать полный набор правил
sudo nft list table inet filter               # List specific table / Список конкретной таблицы
sudo nft list chain inet filter input         # List specific chain / Список конкретной цепочки
```

### Flush / Очистка
```bash
sudo nft flush ruleset                        # Delete all rules / Удалить все правила
sudo nft flush table inet filter              # Flush specific table / Очистить конкретную таблицу
sudo nft flush chain inet filter input        # Flush specific chain / Очистить конкретную цепочку
```

### Save & Restore / Сохранение и восстановление
```bash
sudo nft list ruleset > /etc/nftables.conf    # Save ruleset / Сохранить правила
sudo nft -f /etc/nftables.conf                # Load ruleset / Загрузить правила
sudo sh -c 'nft list ruleset > /etc/nftables.conf'  # Persist rules / Сохранить правила
```

---

## Tables & Chains

### Create Tables / Создать таблицы
```bash
sudo nft add table inet filter                # Create filter table / Создать таблицу filter
sudo nft add table ip nat                     # Create NAT table (IPv4) / Создать таблицу NAT (IPv4)
sudo nft add table ip6 filter                 # Create IPv6 filter table / Создать таблицу filter IPv6
```

### Delete Tables / Удалить таблицы
```bash
sudo nft delete table inet filter             # Delete table / Удалить таблицу
sudo nft delete table ip nat                  # Delete NAT table / Удалить таблицу NAT
```

### Create Chains / Создать цепочки
```bash
sudo nft 'add chain inet filter input { type filter hook input priority 0; policy drop; }'  # Input chain / Цепочка input
sudo nft 'add chain inet filter forward { type filter hook forward priority 0; policy drop; }'  # Forward chain / Цепочка forward
sudo nft 'add chain inet filter output { type filter hook output priority 0; policy accept; }'  # Output chain / Цепочка output
```

### Chain Priorities / Приоритеты цепочек

| Priority | Hook Point | Description (EN / RU) |
| :--- | :--- | :--- |
| **-300** | raw | Raw processing / Сырая обработка |
| **-225** | connection tracking | Connection tracking / Отслеживание соединений |
| **-200** | mangle | Packet mangling / Изменение пакетов |
| **-150** | DNAT | Destination NAT / NAT назначения |
| **0** | filter (default) | Filtering / Фильтрация |
| **100** | security | Security / Безопасность |
| **225** | SNAT | Source NAT / NAT источника |
| **300** | postrouting | Post-routing / Пост-маршрутизация |

---

## Rules

### Basic Rules / Базовые правила
```bash
sudo nft add rule inet filter input ct state established,related accept  # Allow established / Разрешить established
sudo nft add rule inet filter input ct state invalid drop                # Drop invalid / Отбросить недействительные
sudo nft add rule inet filter input iif lo accept                        # Allow loopback / Разрешить loopback
```

### Port Rules / Правила портов
```bash
sudo nft add rule inet filter input tcp dport 22 accept                  # Allow SSH / Разрешить SSH
sudo nft add rule inet filter input tcp dport { 80, 443 } accept         # Allow HTTP/HTTPS / Разрешить HTTP/HTTPS
sudo nft add rule inet filter input tcp dport 8000-9000 accept           # Allow port range / Разрешить диапазон портов
sudo nft add rule inet filter input udp dport 53 accept                  # Allow DNS / Разрешить DNS
```

### IP-Based Rules / Правила на основе IP
```bash
sudo nft add rule inet filter input ip saddr 192.168.1.0/24 accept       # Allow subnet / Разрешить подсеть
sudo nft add rule inet filter input ip saddr <IP> drop                   # Block IP / Заблокировать IP
sudo nft add rule inet filter input ip saddr { <IP1>, <IP2> } drop       # Block multiple IPs / Заблокировать несколько IP
```

### Interface Rules / Правила интерфейсов
```bash
sudo nft add rule inet filter input iif eth0 accept                      # Allow from eth0 / Разрешить с eth0
sudo nft add rule inet filter forward iif eth0 oif eth1 accept           # Forward eth0→eth1 / Пересылка eth0→eth1
```

### Drop & Reject / Отбросить и отклонить
```bash
sudo nft add rule inet filter input drop                                 # Drop packets / Отбросить пакеты
sudo nft add rule inet filter input reject                               # Reject packets / Отклонить пакеты
sudo nft add rule inet filter input tcp dport 23 reject                  # Reject telnet / Отклонить telnet
```

### Handle-Based Deletion / Удаление по handle
```bash
sudo nft -a list chain inet filter input                                 # Show handles / Показать handles
sudo nft delete rule inet filter input handle 5                          # Delete rule by handle / Удалить правило по handle
```

---

## NAT & Port Forwarding

### SNAT / Masquerade
```bash
sudo nft add table ip nat                                                # Create NAT table / Создать таблицу NAT
sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority 100; }'  # Postrouting chain / Цепочка postrouting
sudo nft add rule ip nat postrouting oif eth0 masquerade                 # Masquerade / Masquerade
```

### DNAT / Port Forwarding / Проброс портов
```bash
sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority -100; }'  # Prerouting chain / Цепочка prerouting
sudo nft add rule ip nat prerouting iif eth0 tcp dport 80 dnat to 192.168.1.10:8080  # Forward port 80→8080 / Переслать порт 80→8080
sudo nft add rule ip nat prerouting tcp dport 443 dnat to 192.168.1.10               # Forward port 443 / Переслать порт 443
```

---

## Sets & Maps

### Named Sets / Именованные множества
```bash
sudo nft add set inet filter blacklist { type ipv4_addr\; }             # Create IP set / Создать набор IP
sudo nft add element inet filter blacklist { <IP1>, <IP2> }             # Add IPs to set / Добавить IP в набор
sudo nft add rule inet filter input ip saddr @blacklist drop            # Use set in rule / Использовать набор в правиле
```

### Dynamic Sets / Динамические множества
```bash
sudo nft 'add set inet filter ssh_attackers { type ipv4_addr; flags timeout; }'  # Set with timeout / Набор с таймаутом
sudo nft 'add rule inet filter input tcp dport 22 ct state new meter ssh_meter { ip saddr timeout 60s limit rate 5/minute } accept'  # Rate limit / Ограничение скорости
```

### Maps / Карты
```bash
sudo nft 'add map inet filter portmap { type inet_service : ipv4_addr; }'  # Create port map / Создать карту портов
sudo nft 'add element inet filter portmap { 80 : 192.168.1.10, 443 : 192.168.1.11 }'  # Add mappings / Добавить сопоставления
sudo nft 'add rule ip nat prerouting dnat to tcp dport map @portmap'    # Use map / Использовать карту
```

---

## Migration from iptables

### Translation Tools / Инструменты перевода
```bash
iptables-save > iptables.rules                # Save iptables rules / Сохранить правила iptables
iptables-restore-translate -f iptables.rules > nftables.rules  # Translate to nftables / Перевести в nftables
iptables-translate -A INPUT -p tcp --dport 22 -j ACCEPT  # Translate single rule / Перевести одно правило
```

### Disable iptables / Отключить iptables
```bash
sudo systemctl stop iptables                  # Stop iptables / Остановить iptables
sudo systemctl disable iptables               # Disable iptables / Отключить iptables
sudo systemctl mask iptables                  # Mask iptables / Замаскировать iptables
```

### Enable nftables / Включить nftables
```bash
sudo systemctl enable nftables                # Enable nftables / Включить nftables
sudo systemctl start nftables                 # Start nftables / Запустить nftables
```

---

## Real-World Examples

### Basic Firewall / Базовый файрвол
`/etc/nftables.conf`

```bash
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    
    # Allow established/related / Разрешить established/related
    ct state established,related accept
    
    # Drop invalid / Отбросить недействительные
    ct state invalid drop
    
    # Allow loopback / Разрешить loopback
    iif lo accept
    
    # Allow ICMP / Разрешить ICMP
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
    
    # Allow SSH / Разрешить SSH
    tcp dport 22 accept
    
    # Allow HTTP/HTTPS / Разрешить HTTP/HTTPS
    tcp dport { 80, 443 } accept
    
    # Log dropped packets / Логировать отброшенные пакеты
    log prefix "nftables drop: " drop
  }
  
  chain forward {
    type filter hook forward priority 0; policy drop;
  }
  
  chain output {
    type filter hook output priority 0; policy accept;
  }
}
```

### NAT Router / NAT роутер
```bash
#!/usr/sbin/nft -f

table ip nat {
  chain prerouting {
    type nat hook prerouting priority -100;
    
    # Port forwarding / Проброс портов
    iif eth0 tcp dport 80 dnat to 192.168.1.10
    iif eth0 tcp dport 443 dnat to 192.168.1.11
  }
  
  chain postrouting {
    type nat hook postrouting priority 100;
    
    # Masquerade / Masquerade
    oif eth0 masquerade
  }
}

table inet filter {
  chain forward {
    type filter hook forward priority 0; policy drop;
    
    ct state established,related accept
    iif eth1 oif eth0 accept
  }
}
```

### Rate Limiting / Ограничение скорости
```bash
#!/usr/sbin/nft -f

table inet filter {
  set ssh_attackers {
    type ipv4_addr
    flags timeout
  }
  
  chain input {
    type filter hook input priority 0; policy drop;
    
    # Rate limit SSH / Ограничение скорости SSH
    tcp dport 22 ct state new meter ssh_meter { ip saddr timeout 60s limit rate 5/minute } accept
    
    # Rate limit HTTP / Ограничение скорости HTTP
    tcp dport 80 meter http_meter { ip saddr limit rate 100/second } accept
  }
}
```

### GeoIP Blocking / Блокировка по GeoIP
```bash
#!/usr/sbin/nft -f

table inet filter {
  set country_block {
    type ipv4_addr
    flags interval
    elements = { 1.0.1.0/24, 1.0.2.0/23 }
  }
  
  chain input {
    type filter hook input priority 0; policy drop;
    
    ip saddr @country_block drop
    
    # Rest of rules / Остальные правила
  }
}
```

### Docker Integration / Интеграция с Docker
```bash
#!/usr/sbin/nft -f

table inet filter {
  chain forward {
    type filter hook forward priority 0; policy drop;
    
    # Allow Docker containers / Разрешить контейнеры Docker
    iif docker0 accept
    oif docker0 ct state related,established accept
  }
}

table ip nat {
  chain prerouting {
    type nat hook prerouting priority -100;
    
    # Docker port mappings / Сопоставления портов Docker
    iif eth0 tcp dport 8080 dnat to 172.17.0.2:80
  }
  
  chain postrouting {
    type nat hook postrouting priority 100;
    
    # Docker masquerade / Docker masquerade
    oif eth0 masquerade
  }
}
```

### Kubernetes Integration / Интеграция с Kubernetes
```bash
#!/usr/sbin/nft -f

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    
    # Kubernetes API / Kubernetes API
    tcp dport 6443 accept
    
    # Kubelet / Kubelet
    tcp dport 10250 accept
    
    # NodePort range / Диапазон NodePort
    tcp dport 30000-32767 accept
  }
}
```

---

## Reference Tables

### Table Families / Семейства таблиц

| Family | Description (EN / RU) |
| :--- | :--- |
| **inet** | IPv4 and IPv6 / IPv4 и IPv6 |
| **ip** | IPv4 only / Только IPv4 |
| **ip6** | IPv6 only / Только IPv6 |
| **arp** | ARP packets / ARP пакеты |
| **bridge** | Bridge packets / Bridge пакеты |
| **netdev** | Ingress/egress / Ingress/egress |

### Common Actions / Распространённые действия

| Action | Description (EN / RU) |
| :--- | :--- |
| **accept** | Accept packet / Принять пакет |
| **drop** | Drop packet silently / Отбросить пакет тихо |
| **reject** | Reject with ICMP / Отклонить с ICMP |
| **queue** | Send to userspace / Отправить в userspace |
| **return** | Return to calling chain / Вернуться в вызывающую цепочку |

### Debugging Flags / Флаги отладки

| Flag | Description (EN / RU) |
| :--- | :--- |
| `nft -n` | Numeric output / Числовой вывод |
| `nft -a` | Show handles / Показать handles |
| `nft -nn` | No name resolution / Без разрешения имён |
| `nft monitor` | Real-time monitoring / Мониторинг в реальном времени |

> [!IMPORTANT]
> nftables replaces iptables. Do not use iptables and nftables simultaneously — this causes unpredictable behavior. / nftables заменяет iptables. Не используйте iptables и nftables одновременно.
