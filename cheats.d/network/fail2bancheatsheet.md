---
Title: 🚓 Fail2Ban — Intrusion Prevention
Group: Network
Icon: 🚓
Order: 17
tags:
  - network
  - sysadmin
  - linux
---

# Fail2Ban — Intrusion Prevention Framework

`fail2ban` is an intrusion prevention software framework that monitors log files for suspicious activity (e.g., repeated failed login attempts) and bans offending IP addresses using firewall rules (iptables/nftables/firewalld). It is the standard brute-force protection tool for SSH, web servers, and mail servers on Linux.

📚 **Official Docs / Официальная документация:** [Fail2Ban](https://www.fail2ban.org/)

## Table of Contents

- [🔧 Basic Commands](#🔧%20Basic%20Commands)
- [🔒 Jail Management](#🔒%20Jail%20Management)
- [🚫 Ban Operations](#🚫%20Ban%20Operations)
- [⚙️ Configuration](#⚙️%20Configuration)
- [🎯 Filters & Actions](#🎯%20Filters%20&%20Actions)
- [📊 Monitoring & Logs](#📊%20Monitoring%20&%20Logs)
- [🌟 Real-World Examples](#🌟%20Real-World%20Examples)
- [💡 Best Practices](#💡%20Best%20Practices)
- [🔧 Configuration Files](#🔧%20Configuration%20Files)
- [📋 Common Jails](#📋%20Common%20Jails)
- [⚠️ Important Notes](#⚠️%20Important%20Notes)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

## 🔧 Basic Commands

### Service Management
```bash
sudo systemctl start fail2ban                 # Start fail2ban / Запустить fail2ban
sudo systemctl stop fail2ban                  # Stop fail2ban / Остановить fail2ban
sudo systemctl restart fail2ban               # Restart fail2ban / Перезапустить fail2ban
sudo systemctl status fail2ban                # Check status / Проверить статус
sudo systemctl enable fail2ban                # Enable on boot / Включить при загрузке
```

### Client Commands
```bash
sudo fail2ban-client status                   # List active jails / Список активных jails
sudo fail2ban-client ping                     # Test connection / Проверить соединение
sudo fail2ban-client reload                   # Reload configuration / Перезагрузить конфигурацию
sudo fail2ban-client version                  # Show version / Показать версию
```

---

## 🔒 Jail Management

### Jail Status
```bash
sudo fail2ban-client status                   # List all jails / Список всех jails
sudo fail2ban-client status sshd              # Status of sshd jail / Статус jail sshd
sudo fail2ban-client status nginx-limit-req   # Status of nginx jail / Статус jail nginx
sudo fail2ban-client status apache-auth       # Status of apache jail / Статус jail apache
```

### Jail Control
```bash
sudo fail2ban-client start sshd               # Start jail / Запустить jail
sudo fail2ban-client stop sshd                # Stop jail / Остановить jail
sudo fail2ban-client reload sshd              # Reload jail / Перезагрузить jail
```

---

## 🚫 Ban Operations

### Manual Ban
```bash
sudo fail2ban-client set sshd banip <IP>      # Ban IP in sshd jail / Забанить IP в jail sshd
sudo fail2ban-client set nginx-limit-req banip <IP>  # Ban IP in nginx jail / Забанить IP в jail nginx
```

### Unban IP
```bash
sudo fail2ban-client set sshd unbanip <IP>    # Unban IP from sshd / Разбанить IP из sshd
sudo fail2ban-client set sshd unbanip --all   # Unban all IPs / Разбанить все IP
```

### Check Banned IPs
```bash
sudo fail2ban-client status sshd | grep "Banned IP"  # List banned IPs / Список забаненных IP
sudo iptables -L -n | grep fail2ban           # Check iptables rules / Проверить правила iptables
sudo nft list ruleset | grep fail2ban         # Check nftables rules / Проверить правила nftables
```

---

## ⚙️ Configuration

### Configuration Files
```bash
# /etc/fail2ban/fail2ban.conf                   # Main config
# /etc/fail2ban/jail.conf                       # Default jail config
# /etc/fail2ban/jail.local                      # Local jail overrides
# /etc/fail2ban/jail.d/                         # Custom jail configs
```

### Test Configuration
```bash
sudo fail2ban-client -t                       # Test configuration / Проверить конфигурацию
sudo fail2ban-client reload                   # Reload after changes / Перезагрузить после изменений
```

### Common Jail Settings
```ini
[sshd]
enabled = true                                # Enable jail / Включить jail
port = ssh                                    # Port to protect / Порт для защиты
filter = sshd                                 # Filter to use / Фильтр для использования
logpath = /var/log/auth.log                   # Log file / Файл логов
maxretry = 5                                  # Max failed attempts / Макс неудачных попыток
findtime = 10m                                # Time window / Временное окно
bantime = 1h                                  # Ban duration / Длительность бана
```

---

## 🎯 Filters & Actions

### Filters
```bash
# /etc/fail2ban/filter.d/                       # Filter directory
# /etc/fail2ban/filter.d/sshd.conf              # SSH filter / SSH
# /etc/fail2ban/filter.d/nginx-limit-req.conf   # Nginx filter / Nginx
```

### Test Filter
```bash
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf  # Test SSH filter / Проверить SSH фильтр
sudo fail2ban-regex /var/log/nginx/error.log /etc/fail2ban/filter.d/nginx-limit-req.conf  # Test nginx filter / Проверить nginx фильтр
```

### Actions
```bash
# /etc/fail2ban/action.d/                       # Action directory
# /etc/fail2ban/action.d/iptables.conf          # iptables action / iptables
# /etc/fail2ban/action.d/sendmail.conf          # Email notification / Email
```

---

## 📊 Monitoring & Logs

### View Logs
```bash
sudo tail -f /var/log/fail2ban.log            # Follow fail2ban log / Следовать за логом fail2ban
sudo journalctl -u fail2ban -f                # Follow journal / Следовать за журналом
sudo grep "Ban" /var/log/fail2ban.log         # Show bans / Показать баны
sudo grep "Unban" /var/log/fail2ban.log       # Show unbans / Показать разбаны
```

### Statistics
```bash
sudo fail2ban-client status sshd              # Show jail stats / Показать статистику jail
sudo awk '($(NF-1) = /Ban/){print $NF}' /var/log/fail2ban.log | sort | uniq -c | sort -n  # Count bans by IP / Подсчитать баны по IP
```

---

## 🌟 Real-World Examples

### Basic SSH Protection
```ini
# /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 10m
bantime = 1h
```

### Nginx Rate Limiting
```ini
# /etc/fail2ban/jail.local
[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 1m
bantime = 1h

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
findtime = 1m
bantime = 1h
```

### Apache Protection
```ini
# /etc/fail2ban/jail.local
[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 3
findtime = 10m
bantime = 1h

[apache-noscript]
enabled = true
port = http,https
filter = apache-noscript
logpath = /var/log/apache2/error.log
maxretry = 6
findtime = 1m
bantime = 1h
```

### MySQL/PostgreSQL Protection
```ini
# /etc/fail2ban/jail.local
[mysqld-auth]
enabled = true
port = 3306
filter = mysqld-auth
logpath = /var/log/mysql/error.log
maxretry = 5
findtime = 10m
bantime = 1h

[postgresql]
enabled = true
port = 5432
filter = postgresql
logpath = /var/log/postgresql/postgresql-*-main.log
maxretry = 5
findtime = 10m
bantime = 1h
```

### Email Notifications / Email
```ini
# /etc/fail2ban/jail.local
[DEFAULT]
destemail = <EMAIL>
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
action = %(action_mwl)s
```

### Permanent Ban After Recidive
```ini
# /etc/fail2ban/jail.local
[recidive]
enabled = true
logpath = /var/log/fail2ban.log
banaction = iptables-allports
bantime = -1
findtime = 1d
maxretry = 5
```

### Whitelist IPs
```ini
# /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8
```

### Custom Filter Example
```ini
# /etc/fail2ban/filter.d/myapp.conf
[Definition]
failregex = ^.*Failed login attempt from <HOST>.*$
            ^.*Authentication failure for .* from <HOST>.*$
ignoreregex =
```

### Custom Action Example
```bash
# /etc/fail2ban/action.d/telegram.conf
[Definition]
actionban = curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" -d "chat_id=<CHAT_ID>" -d "text=Banned IP: <ip>"
actionunban =
```

### Monitor Fail2Ban Activity
```bash
#!/bin/bash
# Monitor fail2ban bans

while true; do
  echo "=== $(date) ==="
  sudo fail2ban-client status | grep "Jail list" | sed 's/.*://; s/,//g' | xargs -n1 | while read jail; do
    echo "Jail: $jail"
    sudo fail2ban-client status $jail | grep "Currently banned"
  done
  sleep 300
done
```

### Unban All IPs
```bash
#!/bin/bash
# Unban all IPs from all jails

for jail in $(sudo fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')
do
  echo "Processing jail: $jail"
  sudo fail2ban-client set $jail unbanip --all
done
```

### Export Ban List
```bash
# Export currently banned IPs
for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*://; s/,//g'); do
  echo "=== $jail ==="
  sudo fail2ban-client status $jail | grep "Banned IP" | awk '{print $NF}'
done > banned-ips.txt
```

## 💡 Best Practices

- Use `jail.local` instead of modifying `jail.conf` / Используйте `jail.local` вместо изменения `jail.conf`
- Whitelist your own IPs / Внесите свои IP в белый список
- Start with conservative maxretry / Начните с консервативного maxretry
- Monitor logs regularly / Регулярно мониторьте логи
- Test filters before deploying / Тестируйте фильтры перед развёртыванием
- Set reasonable ban times / Устанавливайте разумные времена бана
- Enable recidive jail for repeat offenders / Включите jail recidive для рецидивистов

## 🔧 Configuration Files

| File | Description (EN / RU) |
|------|----------------------|
| `/etc/fail2ban/fail2ban.conf` | Main config / Основная конфигурация |
| `/etc/fail2ban/jail.conf` | Default jails / Jails по умолчанию |
| `/etc/fail2ban/jail.local` | Local overrides / Локальные переопределения |
| `/etc/fail2ban/filter.d/` | Filter definitions / Определения фильтров |
| `/etc/fail2ban/action.d/` | Action definitions / Определения действий |

## 📋 Common Jails

| Jail | Description (EN / RU) |
|------|----------------------|
| `sshd` | SSH protection / Защита SSH |
| `apache-auth` | Apache authentication / Аутентификация Apache |
| `nginx-limit-req` | Nginx rate limiting / Ограничение скорости Nginx |
| `mysqld-auth` | MySQL protection / Защита MySQL |
| `postfix` | Mail server protection / Защита почтового сервера |
| `recidive` | Repeat offender jail / Jail для рецидивистов |

## ⚠️ Important Notes

- Always whitelist your own IPs / Всегда вносите свои IP в белый список
- Test configuration before reloading / Тестируйте конфигурацию перед перезагрузкой
- Monitor for false positives / Мониторьте на ложные срабатывания
- Fail2ban requires iptables or nftables / Fail2ban требует iptables или nftables
- Ban time -1 means permanent ban / Время бана -1 означает постоянный бан

## 📚 Documentation Links

- [fail2ban GitHub](https://github.com/fail2ban/fail2ban)
- [fail2ban-client Man Page](https://man7.org/linux/man-pages/man1/fail2ban-client.1.html)
