---
Title: 🧱 UFW — Uncomplicated Firewall
Group: Network
Icon: 🧱
Order: 16
tags:
  - network
  - sysadmin
  - linux
---

# UFW — Uncomplicated Firewall

`ufw` (Uncomplicated Firewall) is a user-friendly frontend for `iptables` designed to simplify firewall management on Ubuntu and Debian-based systems. It provides simple commands for managing rules while supporting complex configurations through application profiles.

📚 **Official Docs / Официальная документация:** [UFW Community Help](https://help.ubuntu.com/community/UFW)

## Table of Contents
- [Basic Commands](#Basic%20Commands)
- [Allow Rules](#Allow%20Rules)
- [Deny Rules](#Deny%20Rules)
- [Delete Rules](#Delete%20Rules)
- [Advanced Rules](#Advanced%20Rules)
- [Application Profiles](#Application%20Profiles)
- [Logging & Status](#Logging%20&%20Status)
- [Real-World Examples](#Real-World%20Examples)
- [Reference Tables](#Reference%20Tables)

---

## Basic Commands

### Enable & Disable
```bash
sudo ufw enable                               # Enable firewall / Включить фаервол
sudo ufw disable                              # Disable firewall / Отключить фаервол
sudo ufw reload                               # Reload rules / Перезагрузить правила
sudo ufw reset                                # Reset to defaults / Сбросить к умолчаниям
```

### Status
```bash
sudo ufw status                               # Show status / Показать статус
sudo ufw status verbose                       # Verbose status / Подробный статус
sudo ufw status numbered                      # Numbered rules / Пронумерованные правила
```

### Default Policies
```bash
sudo ufw default deny incoming                # Deny incoming / Запретить входящие
sudo ufw default allow outgoing               # Allow outgoing / Разрешить исходящие
sudo ufw default reject incoming              # Reject incoming / Отклонять входящие
sudo ufw default deny forward                 # Deny forwarding / Запретить пересылку
```

---

## Allow Rules

### Basic Allow
```bash
sudo ufw allow 22                             # Allow port 22 / Разрешить порт 22
sudo ufw allow 22/tcp                         # Allow TCP port 22 / Разрешить TCP порт 22
sudo ufw allow 53/udp                         # Allow UDP port 53 / Разрешить UDP порт 53
sudo ufw allow 80,443/tcp                     # Allow multiple ports / Разрешить несколько портов
```

### Port Ranges
```bash
sudo ufw allow 8000:9000/tcp                  # Allow port range / Разрешить диапазон портов
sudo ufw allow 10000:20000/udp                # UDP port range / UDP диапазон портов
```

### Allow from Specific IP
```bash
sudo ufw allow from <IP>                      # Allow from IP / Разрешить с IP
sudo ufw allow from <IP> to any port 22       # Allow SSH from IP / Разрешить SSH с IP
sudo ufw allow from <IP> to any port 3306     # Allow MySQL from IP / Разрешить MySQL с IP
```

### Allow from Subnet
```bash
sudo ufw allow from 192.168.1.0/24            # Allow from subnet / Разрешить из подсети
sudo ufw allow from 192.168.1.0/24 to any port 22  # SSH from subnet / SSH из подсети
```

### Allow on Interface
```bash
sudo ufw allow in on eth0 to any port 80      # Allow on eth0 / Разрешить на eth0
sudo ufw allow in on tun0                     # Allow on VPN interface / Разрешить на VPN интерфейсе
```

---

## Deny Rules

### Basic Deny
```bash
sudo ufw deny 23                              # Deny port 23 / Запретить порт 23
sudo ufw deny 23/tcp                          # Deny TCP port 23 / Запретить TCP порт 23
sudo ufw deny from <IP>                       # Deny from IP / Запретить с IP
sudo ufw deny from <IP> to any port 22        # Deny SSH from IP / Запретить SSH с IP
```

### Reject vs Deny
```bash
sudo ufw reject out 25                        # Reject outgoing SMTP / Отклонить исходящий SMTP
sudo ufw deny out 25                          # Drop outgoing SMTP / Отбросить исходящий SMTP
```

---

## Delete Rules

### Delete by Rule
```bash
sudo ufw delete allow 22                      # Delete allow rule / Удалить правило разрешения
sudo ufw delete allow 80/tcp                  # Delete specific rule / Удалить конкретное правило
sudo ufw delete deny from <IP>                # Delete deny rule / Удалить правило запрета
```

### Delete by Number
```bash
sudo ufw status numbered                      # Show numbered rules / Показать пронумерованные правила
sudo ufw delete 3                             # Delete rule #3 / Удалить правило #3
sudo ufw delete 1                             # Delete rule #1 / Удалить правило #1
```

---

## Advanced Rules

### Limit Connections
```bash
sudo ufw limit 22/tcp                         # Rate limit SSH / Ограничить скорость SSH
sudo ufw limit ssh                            # Same as above / То же что выше
```

### Allow Specific Protocol
```bash
sudo ufw allow proto tcp from <IP> to any port 22  # TCP from IP / TCP с IP
sudo ufw allow proto udp from <IP> to any port 53  # UDP from IP / UDP с IP
```

### Insert Rules
```bash
sudo ufw insert 1 allow from <IP>             # Insert at position 1 / Вставить в позицию 1
sudo ufw insert 2 deny from <IP>              # Insert at position 2 / Вставить в позицию 2
```

### Interface-Specific
```bash
sudo ufw allow in on eth0 from 192.168.1.0/24 to any port 22  # LAN SSH / SSH из LAN
sudo ufw deny in on eth1 from any to any      # Deny all on eth1 / Запретить всё на eth1
```

### Direction Specific
```bash
sudo ufw allow out 53/udp                     # Allow outgoing DNS / Разрешить исходящий DNS
sudo ufw deny out on eth0 to <IP>             # Deny outgoing to IP / Запретить исходящий к IP
```

---

## Application Profiles

### List Applications
```bash
sudo ufw app list                             # List available apps / Список доступных приложений
sudo ufw app info <APP>                       # Show app info / Показать информацию о приложении
```

### Allow Applications
```bash
sudo ufw allow OpenSSH                        # Allow SSH / Разрешить SSH
sudo ufw allow 'Nginx Full'                   # Allow Nginx HTTP+HTTPS / Разрешить Nginx HTTP+HTTPS
sudo ufw allow 'Nginx HTTP'                   # Allow Nginx HTTP only / Разрешить только Nginx HTTP
sudo ufw allow 'Apache Full'                  # Allow Apache HTTP+HTTPS / Разрешить Apache HTTP+HTTPS
```

### Custom Application Profiles
`/etc/ufw/applications.d/myapp`

```ini
[MyApp]
title=My Application
description=Custom App Profile
ports=8080/tcp|8443/tcp
```

```bash
sudo ufw app update MyApp                     # Update app profile / Обновить профиль приложения
sudo ufw allow MyApp                          # Allow custom app / Разрешить пользовательское приложение
```

---

## Logging & Status

### Logging
```bash
sudo ufw logging on                           # Enable logging / Включить логирование
sudo ufw logging off                          # Disable logging / Отключить логирование
sudo ufw logging low                          # Low verbosity / Низкая детализация
sudo ufw logging medium                       # Medium verbosity / Средняя детализация
sudo ufw logging high                         # High verbosity / Высокая детализация
sudo ufw logging full                         # Full verbosity / Полная детализация
```

### View Logs
```bash
sudo tail -f /var/log/ufw.log                 # Follow UFW log / Следовать за логом UFW
sudo journalctl -u ufw -f                     # Follow UFW journal / Следовать за журналом UFW
sudo grep UFW /var/log/syslog                 # Search syslog / Поиск в syslog
```

### Show Rules
```bash
sudo ufw show raw                             # Show raw rules / Показать сырые правила
sudo ufw show added                           # Show added rules / Показать добавленные правила
sudo ufw show listening                       # Show listening ports / Показать слушающие порты
```

---

## Real-World Examples

### Basic Web Server
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 80/tcp                         # HTTP
sudo ufw allow 443/tcp                        # HTTPS
sudo ufw enable
```

### SSH Hardening
```bash
sudo ufw limit 22/tcp                         # Rate limit SSH to prevent brute force / Ограничить SSH
sudo ufw allow from 192.168.1.0/24 to any port 22  # Allow from LAN / Разрешить из LAN
sudo ufw enable
```

### Database Server
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from <APP_SERVER_IP> to any port 3306  # MySQL
sudo ufw allow from <APP_SERVER_IP> to any port 5432  # PostgreSQL
sudo ufw allow 22/tcp                         # SSH admin
sudo ufw enable
```

### Docker Host
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 2376/tcp                       # Docker TLS
sudo ufw allow from <TRUSTED_IP> to any port 2375  # Docker API
sudo ufw allow 8080/tcp                       # Published container port / Порт контейнера
sudo ufw route allow proto tcp from any to any port 8080
sudo ufw enable
```

### VPN Server / VPN
```bash
# OpenVPN server
sudo ufw allow 1194/udp                       # OpenVPN
sudo ufw allow 22/tcp                         # SSH
sudo ufw default allow routed                 # Allow VPN routing / Разрешить маршрутизацию VPN
sudo ufw enable

# WireGuard server
sudo ufw allow 51820/udp                      # WireGuard
sudo ufw enable
```

### Kubernetes Node
```bash
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 6443/tcp                       # Kubernetes API
sudo ufw allow 2379:2380/tcp                  # etcd
sudo ufw allow 10250/tcp                      # Kubelet
sudo ufw allow 10251/tcp                      # Scheduler
sudo ufw allow 10252/tcp                      # Controller
sudo ufw allow 30000:32767/tcp                # NodePort Services
sudo ufw enable
```

### Emergency Block
```bash
sudo ufw insert 1 deny from <ATTACKER_IP>     # Block specific IP immediately / Немедленно заблокировать IP
sudo ufw insert 1 deny from 192.168.100.0/24  # Block subnet / Заблокировать подсеть
```

> [!WARNING]
> Always allow SSH before enabling UFW, or you risk locking yourself out of a remote server! / Всегда разрешайте SSH перед включением UFW, иначе вы можете потерять доступ к удалённому серверу!

---

## Reference Tables

### Configuration Files

| File | Description (EN / RU) |
| :--- | :--- |
| `/etc/ufw/ufw.conf` | Main config / Основная конфигурация |
| `/etc/ufw/before.rules` | Rules processed first / Правила обрабатываемые первыми |
| `/etc/ufw/after.rules` | Rules processed last / Правила обрабатываемые последними |
| `/etc/default/ufw` | Default settings / Настройки по умолчанию |
| `/etc/ufw/applications.d/` | Application profiles / Профили приложений |
| `/var/log/ufw.log` | UFW log file / Файл логов UFW |

### Common Ports

| Port | Service | Port | Service |
| :--- | :--- | :--- | :--- |
| 22 | SSH | 3306 | MySQL |
| 80 | HTTP | 5432 | PostgreSQL |
| 443 | HTTPS | 6379 | Redis |
| 25 | SMTP | 27017 | MongoDB |
| 53 | DNS | 8080 | Alt HTTP |

> [!TIP]
> Use `reject` for informative denial (sends ICMP unreachable), use `deny` for silent drop (stealth). Use `limit` for SSH to prevent brute force. / Используйте `reject` для информативного отказа, `deny` для тихого отбрасывания. Используйте `limit` для SSH.

## 📚 Documentation Links

- [UFW Wiki](https://wiki.ubuntu.com/UncomplicatedFirewall)
- [ufw Man Page](https://manpages.ubuntu.com/manpages/noble/man8/ufw.8.html)
