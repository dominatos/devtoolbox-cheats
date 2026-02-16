Title: 🧱 UFW — Uncomplicated Firewall
Group: Network
Icon: 🧱
Order: 16

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Allow Rules](#-allow-rules--правила-разрешения)
- [Deny Rules](#-deny-rules--правила-запрета)
- [Delete Rules](#-delete-rules--удаление-правил)
- [Advanced Rules](#-advanced-rules--продвинутые-правила)
- [Application Profiles](#-application-profiles--профили-приложений)
- [Logging & Status](#-logging--status--логирование-и-статус)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Basic Commands / Базовые команды

### Enable & Disable / Включение и отключение
```bash
sudo ufw enable                               # Enable firewall / Включить фаервол
sudo ufw disable                              # Disable firewall / Отключить фаервол
sudo ufw reload                               # Reload rules / Перезагрузить правила
sudo ufw reset                                # Reset to defaults / Сбросить к умолчаниям
```

### Status / Статус
```bash
sudo ufw status                               # Show status / Показать статус
sudo ufw status verbose                       # Verbose status / Подробный статус
sudo ufw status numbered                      # Numbered rules / Пронумерованные правила
```

### Default Policies / Политики по умолчанию
```bash
sudo ufw default deny incoming                # Deny incoming / Запретить входящие
sudo ufw default allow outgoing               # Allow outgoing / Разрешить исходящие
sudo ufw default reject incoming              # Reject incoming / Отклонять входящие
sudo ufw default deny forward                 # Deny forwarding / Запретить пересылку
```

---

# ✅ Allow Rules / Правила разрешения

### Basic Allow / Базовое разрешение
```bash
sudo ufw allow 22                             # Allow port 22 / Разрешить порт 22
sudo ufw allow 22/tcp                         # Allow TCP port 22 / Разрешить TCP порт 22
sudo ufw allow 53/udp                         # Allow UDP port 53 / Разрешить UDP порт 53
sudo ufw allow 80,443/tcp                     # Allow multiple ports / Разрешить несколько портов
```

### Port Ranges / Диапазоны портов
```bash
sudo ufw allow 8000:9000/tcp                  # Allow port range / Разрешить диапазон портов
sudo ufw allow 10000:20000/udp                # UDP port range / UDP диапазон портов
```

### Allow from Specific IP / Разрешить с конкретного IP
```bash
sudo ufw allow from <IP>                      # Allow from IP / Разрешить с IP
sudo ufw allow from <IP> to any port 22       # Allow SSH from IP / Разрешить SSH с IP
sudo ufw allow from <IP> to any port 3306     # Allow MySQL from IP / Разрешить MySQL с IP
```

### Allow from Subnet / Разрешить из подсети
```bash
sudo ufw allow from 192.168.1.0/24            # Allow from subnet / Разрешить из подсети
sudo ufw allow from 192.168.1.0/24 to any port 22  # SSH from subnet / SSH из подсети
```

### Allow on Interface / Разрешить на интерфейсе
```bash
sudo ufw allow in on eth0 to any port 80      # Allow on eth0 / Разрешить на eth0
sudo ufw allow in on tun0                     # Allow on VPN interface / Разрешить на VPN интерфейсе
```

---

# ❌ Deny Rules / Правила запрета

### Basic Deny / Базовый запрет
```bash
sudo ufw deny 23                              # Deny port 23 / Запретить порт 23
sudo ufw deny 23/tcp                          # Deny TCP port 23 / Запретить TCP порт 23
sudo ufw deny from <IP>                       # Deny from IP / Запретить с IP
sudo ufw deny from <IP> to any port 22        # Deny SSH from IP / Запретить SSH с IP
```

### Reject vs Deny / Отклонить vs Запретить
```bash
sudo ufw reject out 25                        # Reject outgoing SMTP / Отклонить исходящий SMTP
sudo ufw deny out 25                          # Drop outgoing SMTP / Отбросить исходящий SMTP
```

---

# 🗑️ Delete Rules / Удаление правил

### Delete by Rule / Удалить по правилу
```bash
sudo ufw delete allow 22                      # Delete allow rule / Удалить правило разрешения
sudo ufw delete allow 80/tcp                  # Delete specific rule / Удалить конкретное правило
sudo ufw delete deny from <IP>                # Delete deny rule / Удалить правило запрета
```

### Delete by Number / Удалить по номеру
```bash
sudo ufw status numbered                      # Show numbered rules / Показать пронумерованные правила
sudo ufw delete 3                             # Delete rule #3 / Удалить правило #3
sudo ufw delete 1                             # Delete rule #1 / Удалить правило #1
```

---

# 🔬 Advanced Rules / Продвинутые правила

### Limit Connections / Ограничить соединения
```bash
sudo ufw limit 22/tcp                         # Rate limit SSH / Ограничить скорость SSH
sudo ufw limit ssh                            # Same as above / То же что выше
```

### Allow Specific Protocol / Разрешить конкретный протокол
```bash
sudo ufw allow proto tcp from <IP> to any port 22  # TCP from IP / TCP с IP
sudo ufw allow proto udp from <IP> to any port 53  # UDP from IP / UDP с IP
```

### Insert Rules / Вставить правила
```bash
sudo ufw insert 1 allow from <IP>             # Insert at position 1 / Вставить в позицию 1
sudo ufw insert 2 deny from <IP>              # Insert at position 2 / Вставить в позицию 2
```

### Interface-Specific / Для конкретного интерфейса
```bash
sudo ufw allow in on eth0 from 192.168.1.0/24 to any port 22  # LAN SSH / SSH из LAN
sudo ufw deny in on eth1 from any to any      # Deny all on eth1 / Запретить всё на eth1
```

### Direction Specific / Для конкретного направления
```bash
sudo ufw allow out 53/udp                     # Allow outgoing DNS / Разрешить исходящий DNS
sudo ufw deny out on eth0 to <IP>             # Deny outgoing to IP / Запретить исходящий к IP
```

---

# 📱 Application Profiles / Профили приложений

### List Applications / Список приложений
```bash
sudo ufw app list                             # List available apps / Список доступных приложений
sudo ufw app info <APP>                       # Show app info / Показать информацию о приложении
```

### Allow Applications / Разрешить приложения
```bash
sudo ufw allow OpenSSH                        # Allow SSH / Разрешить SSH
sudo ufw allow 'Nginx Full'                   # Allow Nginx HTTP+HTTPS / Разрешить Nginx HTTP+HTTPS
sudo ufw allow 'Nginx HTTP'                   # Allow Nginx HTTP only / Разрешить только Nginx HTTP
sudo ufw allow 'Apache Full'                  # Allow Apache HTTP+HTTPS / Разрешить Apache HTTP+HTTPS
```

### Custom Application Profiles / Пользовательские профили
```bash
# Create /etc/ufw/applications.d/myapp / Создать /etc/ufw/applications.d/myapp
# [MyApp]
# title=My Application
# description=Custom App Profile
# ports=8080/tcp|8443/tcp

sudo ufw app update MyApp                     # Update app profile / Обновить профиль приложения
sudo ufw allow MyApp                          # Allow custom app / Разрешить пользовательское приложение
```

---

# 📊 Logging & Status / Логирование и статус

### Logging / Логирование
```bash
sudo ufw logging on                           # Enable logging / Включить логирование
sudo ufw logging off                          # Disable logging / Отключить логирование
sudo ufw logging low                          # Low verbosity / Низкая детализация
sudo ufw logging medium                       # Medium verbosity / Средняя детализация
sudo ufw logging high                         # High verbosity / Высокая детализация
sudo ufw logging full                         # Full verbosity / Полная детализация
```

### View Logs / Просмотр логов
```bash
sudo tail -f /var/log/ufw.log                 # Follow UFW log / Следовать за логом UFW
sudo journalctl -u ufw -f                     # Follow UFW journal / Следовать за журналом UFW
sudo grep UFW /var/log/syslog                 # Search syslog / Поиск в syslog
```

### Show Rules / Показать правила
```bash
sudo ufw show raw                             # Show raw rules / Показать сырые правила
sudo ufw show added                           # Show added rules / Показать добавленные правила
sudo ufw show listening                       # Show listening ports / Показать слушающие порты
```

---

# 🌟 Real-World Examples / Примеры из практики

### Basic Web Server / Базовый веб-сервер
```bash
# Setup firewall for web server / Настройка фаервола для веб-сервера
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 80/tcp                         # HTTP
sudo ufw allow 443/tcp                        # HTTPS
sudo ufw enable
```

### SSH Hardening / Усиление SSH
```bash
# Rate limit SSH to prevent brute force / Ограничить скорость SSH для предотвращения brute force
sudo ufw limit 22/tcp
sudo ufw allow from 192.168.1.0/24 to any port 22  # Allow from LAN / Разрешить из LAN
sudo ufw enable
```

### Database Server / Сервер базы данных
```bash
# Allow database only from app servers / Разрешить базу данных только с серверов приложений
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from <APP_SERVER_IP> to any port 3306  # MySQL
sudo ufw allow from <APP_SERVER_IP> to any port 5432  # PostgreSQL
sudo ufw allow 22/tcp                         # SSH admin
sudo ufw enable
```

### Docker Host / Хост Docker
```bash
# Basic Docker host setup / Базовая настройка хоста Docker
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 2376/tcp                       # Docker TLS
sudo ufw allow from <TRUSTED_IP> to any port 2375  # Docker API
sudo ufw enable

# Allow published container ports / Разрешить опубликованные порты контейнеров
sudo ufw allow 8080/tcp
sudo ufw route allow proto tcp from any to any port 8080
```

### VPN Server / VPN сервер
```bash
# OpenVPN server / Сервер OpenVPN
sudo ufw allow 1194/udp                       # OpenVPN
sudo ufw allow 22/tcp                         # SSH
sudo ufw default allow routed                 # Allow VPN routing / Разрешить маршрутизацию VPN
sudo ufw enable

# WireGuard server / Сервер WireGuard
sudo ufw allow 51820/udp                      # WireGuard
sudo ufw enable
```

### Kubernetes Node / Узел Kubernetes
```bash
# Basic Kubernetes node / Базовый узел Kubernetes
sudo ufw allow 22/tcp                         # SSH
sudo ufw allow 6443/tcp                       # Kubernetes API
sudo ufw allow 2379:2380/tcp                  # etcd
sudo ufw allow 10250/tcp                      # Kubelet
sudo ufw allow 10251/tcp                      # Scheduler
sudo ufw allow 10252/tcp                      # Controller
sudo ufw allow 30000:32767/tcp                # NodePort Services
sudo ufw enable
```

### Reset and Reconfigure / Сброс и переконфигурация
```bash
# Complete reset / Полный сброс
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
```

### Whitelist IP / Белый список IP
```bash
# Allow everything from trusted IP / Разрешить всё с доверенного IP
sudo ufw allow from <TRUSTED_IP>

# Allow specific services from office / Разрешить конкретные сервисы из офиса
sudo ufw allow from 10.0.0.0/8 to any port 22
sudo ufw allow from 10.0.0.0/8 to any port 3389  # RDP
```

### Emergency Block / Экстренная блокировка
```bash
# Block specific IP immediately / Немедленно заблокировать конкретный IP
sudo ufw insert 1 deny from <ATTACKER_IP>

# Block subnet / Заблокировать подсеть
sudo ufw insert 1 deny from 192.168.100.0/24
```

# 💡 Best Practices / Лучшие практики
# Always allow SSH before enabling UFW / Всегда разрешайте SSH перед включением UFW
# Use 'limit' for SSH to prevent brute force / Используйте 'limit' для SSH для предотвращения brute force
# Set default policies first / Сначала устанавливайте политики по умолчанию
# Use numbered rules for easier deletion / Используйте пронумерованные правила для упрощения удаления
# Enable logging for security audits / Включайте логирование для аудита безопасности
# Test rules before deploying to production / Тестируйте правила перед развёртыванием в продакшене

# 🔧 Configuration Files / Файлы конфигурации
```bash
# /etc/ufw/ufw.conf — Main config / Основная конфигурация
# /etc/ufw/before.rules — Rules processed first / Правила обрабатываемые первыми
# /etc/ufw/after.rules — Rules processed last / Правила обрабатываемые последними
# /etc/default/ufw — Default settings / Настройки по умолчанию
# /etc/ufw/applications.d/ — Application profiles / Профили приложений
# /var/log/ufw.log — UFW log file / Файл логов UFW
```

# 📋 Common Ports / Распространённые порты
```bash
# 22 — SSH, 80 — HTTP, 443 — HTTPS, 25 — SMTP, 53 — DNS
# 3306 — MySQL, 5432 — PostgreSQL, 6379 — Redis, 27017 — MongoDB
# 8080 — Alternative HTTP / Альтернативный HTTP
```

# ⚠️ Important Notes / Важные примечания
# UFW is frontend for iptables / UFW это фронтенд для iptables
# Changes take effect immediately / Изменения вступают в силу немедленно
# Always test SSH access after enabling / Всегда тестируйте SSH доступ после включения
# Use 'reject' for informative denial / Используйте 'reject' для информативного отказа
# Use 'deny' for silent drop / Используйте 'deny' для тихого отбрасывания
```
