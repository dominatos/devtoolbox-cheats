---
Title: 🔥 firewalld — Firewall Management
Group: Network
Icon: 🔥
Order: 12
tags:
  - network
  - sysadmin
  - linux
---

# firewalld — Dynamic Firewall Daemon

`firewalld` is a dynamically managed firewall daemon with support for network/firewall zones. It provides a D-Bus interface for managing rules at runtime without restarting the firewall service. It is the default firewall on RHEL, CentOS, Fedora, and AlmaLinux, replacing direct iptables management.

📚 **Official Docs / Официальная документация:** [firewalld.org](https://firewalld.org/documentation/)

## Table of Contents
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Basic Commands](#Basic%20Commands)
- [Zone Management](#️%20Zone%20Management)
- [Service Management](#Service%20Management)
- [Port Management](#Port%20Management)
- [Rich Rules](#Rich%20Rules)
- [Direct Rules](#Direct%20Rules)
- [Masquerading & Port Forwarding](#Masquerading%20&%20Port%20Forwarding)
- [Troubleshooting](#Troubleshooting)
- [Real-World Examples](#Real-World%20Examples)

---

## 📦 Installation & Configuration

### Installation
```bash
sudo dnf install firewalld              # RHEL/Fedora
sudo apt install firewalld              # Debian/Ubuntu
```

### Service Management
```bash
sudo systemctl start firewalld          # Start service / Запустить сервис
sudo systemctl stop firewalld           # Stop service / Остановить сервис
sudo systemctl enable firewalld         # Enable on boot / Включить при загрузке
sudo systemctl disable firewalld        # Disable on boot / Отключить при загрузке
sudo systemctl status firewalld         # Check status / Проверить статус
sudo firewall-cmd --state               # Check daemon state / Проверить состояние демона
```

---

## 🔧 Basic Commands

### General Information
```bash
sudo firewall-cmd --state               # Daemon state / Состояние демона
sudo firewall-cmd --get-default-zone    # Get default zone / Получить зону по умолчанию
sudo firewall-cmd --set-default-zone=<ZONE>  # Set default zone / Установить зону по умолчанию
sudo firewall-cmd --get-active-zones    # Active zones / Активные зоны
sudo firewall-cmd --get-zones           # List all zones / Список всех зон
sudo firewall-cmd --get-services        # Predefined services / Предустановленные сервисы
sudo firewall-cmd --reload              # Reload firewall / Перезагрузить файрвол
sudo firewall-cmd --complete-reload     # Full reload (drops connections) / Полная перезагрузка
sudo firewall-cmd --runtime-to-permanent  # Save runtime rules / Сохранить runtime правила
```

---

## 🛡️ Zone Management

### Zone Information
```bash
sudo firewall-cmd --get-zones           # List all zones / Список всех зон
sudo firewall-cmd --list-all            # List default zone rules / Список правил зоны по умолчанию
sudo firewall-cmd --zone=<ZONE> --list-all  # List specific zone rules / Список правил конкретной зоны
sudo firewall-cmd --get-active-zones    # Show active zones / Показать активные зоны
```

### Default Zones
```bash
# drop      — Drop all incoming, allow outgoing
# block     — Reject with ICMP error
# public    — Default, selective incoming
# external  — For external use (masquerading)
# dmz       — DMZ zone, limited incoming / DMZ
# work      — Work environments
# home      — Home networks
# internal  — Internal networks
# trusted   — Accept all
```

### Zone Operations
```bash
sudo firewall-cmd --new-zone=<ZONE> --permanent  # Create new zone / Создать новую зону
sudo firewall-cmd --delete-zone=<ZONE> --permanent  # Delete zone / Удалить зону
sudo firewall-cmd --zone=<ZONE> --change-interface=<INTERFACE>  # Assign interface to zone / Назначить интерфейс зоне
sudo firewall-cmd --zone=<ZONE> --add-source=<IP>/24  # Add source to zone / Добавить источник в зону
sudo firewall-cmd --zone=<ZONE> --remove-source=<IP>/24  # Remove source / Удалить источник
```

---

## 🌐 Service Management

### Add/Remove Services
```bash
sudo firewall-cmd --zone=<ZONE> --add-service=<SERVICE>  # Add service (runtime) / Добавить сервис (runtime)
sudo firewall-cmd --zone=<ZONE> --add-service=<SERVICE> --permanent  # Add service (permanent) / Добавить сервис (постоянно)
sudo firewall-cmd --zone=<ZONE> --remove-service=<SERVICE>  # Remove service / Удалить сервис
sudo firewall-cmd --zone=<ZONE> --remove-service=<SERVICE> --permanent  # Remove permanent / Удалить постоянно
```

### Common Services
```bash
sudo firewall-cmd --zone=public --add-service=ssh --permanent  # Allow SSH / Разрешить SSH
sudo firewall-cmd --zone=public --add-service=http --permanent  # Allow HTTP / Разрешить HTTP
sudo firewall-cmd --zone=public --add-service=https --permanent  # Allow HTTPS / Разрешить HTTPS
sudo firewall-cmd --zone=public --add-service=mysql --permanent  # Allow MySQL / Разрешить MySQL
sudo firewall-cmd --zone=public --add-service=postgresql --permanent  # Allow PostgreSQL / Разрешить PostgreSQL
sudo firewall-cmd --zone=public --add-service=dns --permanent  # Allow DNS / Разрешить DNS
```

### List Services
```bash
sudo firewall-cmd --get-services        # List all available services / Список всех доступных сервисов
sudo firewall-cmd --zone=<ZONE> --list-services  # List enabled services in zone / Список включённых сервисов в зоне
```

---

## 🔌 Port Management

### Add/Remove Ports
```bash
sudo firewall-cmd --zone=<ZONE> --add-port=<PORT>/<PROTOCOL>  # Add port (runtime) / Добавить порт (runtime)
sudo firewall-cmd --zone=<ZONE> --add-port=<PORT>/<PROTOCOL> --permanent  # Add port (permanent) / Добавить порт (постоянно)
sudo firewall-cmd --zone=<ZONE> --remove-port=<PORT>/<PROTOCOL>  # Remove port / Удалить порт
sudo firewall-cmd --zone=<ZONE> --remove-port=<PORT>/<PROTOCOL> --permanent  # Remove permanent / Удалить постоянно
```

### Port Range
```bash
sudo firewall-cmd --zone=<ZONE> --add-port=8000-9000/tcp --permanent  # Add port range / Добавить диапазон портов
```

### Common Ports Examples
```bash
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent  # SSH port / Порт SSH
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent  # HTTP port / Порт HTTP
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent  # HTTPS port / Порт HTTPS
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent  # MySQL port / Порт MySQL
sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent  # PostgreSQL port / Порт PostgreSQL
sudo firewall-cmd --zone=public --add-port=6379/tcp --permanent  # Redis port / Порт Redis
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent  # Custom HTTP / Пользовательский HTTP
```

### List Ports
```bash
sudo firewall-cmd --zone=<ZONE> --list-ports  # List open ports / Список открытых портов
```

---

## 🎯 Rich Rules

### Rich Rule Syntax
```bash
sudo firewall-cmd --zone=<ZONE> --add-rich-rule='<RULE>' --permanent  # Add rich rule / Добавить сложное правило
```

### Rich Rule Examples
```bash
# Allow SSH from specific IP
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" service name="ssh" accept' --permanent

# Block specific IP
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" reject' --permanent

# Allow port from subnet
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>/24" port port="8080" protocol="tcp" accept' --permanent

# Rate limit SSH
sudo firewall-cmd --zone=public --add-rich-rule='rule service name="ssh" limit value="10/m" accept' --permanent

# Log dropped packets
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" log prefix="DROPPED: " level="info" drop' --permanent
```

### List Rich Rules
```bash
sudo firewall-cmd --zone=<ZONE> --list-rich-rules  # List all rich rules / Список всех сложных правил
```

---

## ⚡ Direct Rules

### Direct Rule Management
```bash
sudo firewall-cmd --direct --add-rule ipv4 filter INPUT 0 -p tcp --dport 9000 -j ACCEPT  # Add direct rule / Добавить прямое правило
sudo firewall-cmd --direct --get-all-rules  # List all direct rules / Список всех прямых правил
sudo firewall-cmd --direct --remove-rule ipv4 filter INPUT 0 -p tcp --dport 9000 -j ACCEPT  # Remove direct rule / Удалить прямое правило
```

---

## 🔀 Masquerading & Port Forwarding

### Masquerading
```bash
sudo firewall-cmd --zone=<ZONE> --add-masquerade  # Enable masquerading (runtime) / Включить маскарадинг (runtime)
sudo firewall-cmd --zone=<ZONE> --add-masquerade --permanent  # Enable permanent / Включить постоянно
sudo firewall-cmd --zone=<ZONE> --remove-masquerade  # Disable masquerading / Отключить маскарадинг
sudo firewall-cmd --zone=<ZONE> --query-masquerade  # Check if enabled / Проверить включён ли
```

### Port Forwarding
```bash
sudo firewall-cmd --zone=<ZONE> --add-forward-port=port=<PORT>:proto=<PROTOCOL>:toport=<TARGET_PORT>  # Forward to local port / Перенаправить на локальный порт
sudo firewall-cmd --zone=<ZONE> --add-forward-port=port=<PORT>:proto=<PROTOCOL>:toaddr=<IP>:toport=<TARGET_PORT>  # Forward to remote / Перенаправить на удалённый
```

### Examples
```bash
# Forward port 80 to 8080
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent

# Forward port 443 to internal server
sudo firewall-cmd --zone=external --add-forward-port=port=443:proto=tcp:toaddr=<INTERNAL_IP>:toport=443 --permanent
```

---

## 🐛 Troubleshooting

### Check Configuration
```bash
sudo firewall-cmd --check-config        # Validate configuration / Проверить конфигурацию
sudo firewall-cmd --list-all-zones      # List all zone configurations / Список всех конфигураций зон
sudo firewall-cmd --get-log-denied      # Check log denied setting / Проверить настройку логирования отклонённых
sudo firewall-cmd --set-log-denied=all  # Enable logging denied / Включить логирование отклонённых
```

### View Logs
```bash
sudo journalctl -u firewalld            # View firewalld logs / Просмотр логов firewalld
sudo journalctl -u firewalld -f         # Follow firewalld logs / Следовать за логами firewalld
sudo journalctl -k | grep -i firewall   # Kernel firewall messages / Сообщения файрвола ядра
```

### Debug Mode
```bash
sudo firewall-cmd --set-log-denied=all  # Log all denied packets / Логировать все отброшенные пакеты
sudo firewall-cmd --get-log-denied      # Check current log setting / Проверить текущую настройку логов
```

---

## 🌟 Real-World Examples

### Web Server Setup
```bash
# Allow HTTP and HTTPS
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
```

### Database Server Setup
```bash
# Allow MySQL only from app server
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<APP_SERVER_IP>" service name="mysql" accept' --permanent
sudo firewall-cmd --reload
```

### NAT Gateway Setup
```bash
# Enable masquerading for external zone
sudo firewall-cmd --zone=external --add-masquerade --permanent
sudo firewall-cmd --zone=internal --set-target=ACCEPT --permanent
sudo firewall-cmd --reload
```

### SSH Lockdown
```bash
# Allow SSH only from management subnet
sudo firewall-cmd --zone=public --remove-service=ssh --permanent
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<MGMT_SUBNET>/24" service name="ssh" accept' --permanent
sudo firewall-cmd --reload
```

### Development Environment
```bash
# Open common development ports
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent  # Node.js
sudo firewall-cmd --zone=public --add-port=8000/tcp --permanent  # Django
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent  # Tomcat
sudo firewall-cmd --zone=public --add-port=9000/tcp --permanent  # PHP-FPM
sudo firewall-cmd --reload
```

## 💡 Best Practices
# Always use --permanent for production
# Reload after making changes
# Use zones to organize rules
# Test rules before making permanent
# Use rich rules for complex scenarios
# Log denied packets for troubleshooting
# Keep default zone restrictive

## 🔧 Configuration Files
```bash
# /etc/firewalld/firewalld.conf                    — Main configuration
# /etc/firewalld/zones/                             — Zone definitions
# /etc/firewalld/services/                          — Service definitions
```

## 📋 Common Ports
```bash
# SSH: 22/tcp, HTTP: 80/tcp, HTTPS: 443/tcp
# MySQL: 3306/tcp, PostgreSQL: 5432/tcp
# Redis: 6379/tcp, MongoDB: 27017/tcp
# DNS: 53/udp, NTP: 123/udp
```

## 📚 Documentation Links

- [firewalld Official Docs](https://firewalld.org/documentation)
- [firewall-cmd Man Page](https://man7.org/linux/man-pages/man1/firewall-cmd.1.html)
