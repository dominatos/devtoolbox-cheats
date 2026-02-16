Title: 🔥 iptables — Firewall Rules
Group: Network
Icon: 🔥
Order: 13

## Table of Contents
- [Basics](#-basics--основы)
- [List & View Rules](#-list--view-rules--просмотр-правил)
- [INPUT Chain](#-input-chain--входящий-трафик)
- [OUTPUT Chain](#-output-chain--исходящий-трафик)
- [FORWARD Chain](#-forward-chain--пересылка)
- [NAT & Port Forwarding](#-nat--port-forwarding--nat-и-проброс-портов)
- [Saving & Restoring](#-saving--restoring--сохранение-и-восстановление)
- [Common Patterns](#-common-patterns--распространённые-шаблоны)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)

---

# 📘 Basics / Основы

### Chains & Tables / Цепочки и таблицы
```bash
# filter table: INPUT, FORWARD, OUTPUT / таблица filter: INPUT, FORWARD, OUTPUT
# nat table: PREROUTING, POSTROUTING, OUTPUT / таблица nat: PREROUTING, POSTROUTING, OUTPUT
# mangle table: PREROUTING, POSTROUTING, INPUT, OUTPUT, FORWARD / таблица mangle
```

### Policy / Политика по умолчанию
```bash
sudo iptables -P INPUT ACCEPT                 # Allow all input / Разрешить весь входящий
sudo iptables -P INPUT DROP                   # Drop all input / Запретить весь входящий
sudo iptables -P FORWARD DROP                 # Drop all forwarding / Запретить всю пересылку
sudo iptables -P OUTPUT ACCEPT                # Allow all output / Разрешить весь исходящий
```

---

# 🔍 List & View Rules / Просмотр правил

```bash
sudo iptables -L                              # List rules / Список правил
sudo iptables -L -n                           # List without DNS / Без DNS разрешения
sudo iptables -L -v                           # Verbose / Подробный
sudo iptables -L -n -v                        # Numeric verbose / Числа и подробности
sudo iptables -L INPUT                        # List INPUT chain / Список цепочки INPUT
sudo iptables -L OUTPUT                       # List OUTPUT chain / Список цепочки OUTPUT
sudo iptables -L -t nat                       # List NAT table / Список таблицы NAT
sudo iptables -L -t mangle                    # List mangle table / Список таблицы mangle
sudo iptables -L --line-numbers               # Show line numbers / Показать номера строк
sudo iptables -S                              # Show rules as commands / Показать как команды
```

---

# ⬇️ INPUT Chain / Входящий трафик

### Allow Specific Ports / Разрешить конкретные порты
```bash
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Allow SSH / Разрешить SSH
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # Allow HTTP / Разрешить HTTP
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT # Allow HTTPS / Разрешить HTTPS
sudo iptables -A INPUT -p tcp --dport 3306 -j ACCEPT # Allow MySQL / Разрешить MySQL
sudo iptables -A INPUT -p tcp --dport 5432 -j ACCEPT # Allow PostgreSQL / Разрешить PostgreSQL
sudo iptables -A INPUT -p tcp --dport 6379 -j ACCEPT # Allow Redis / Разрешить Redis
```

### Allow Port Range / Разрешить диапазон портов
```bash
sudo iptables -A INPUT -p tcp --dport 8000:8999 -j ACCEPT  # Ports 8000-8999 / Порты 8000-8999
```

### Allow Specific IP / Разрешить конкретный IP
```bash
sudo iptables -A INPUT -s <IP> -j ACCEPT      # Allow from IP / Разрешить с IP
sudo iptables -A INPUT -s <IP>/24 -j ACCEPT   # Allow from subnet / Разрешить с подсети
sudo iptables -A INPUT -s <IP> -p tcp --dport 22 -j ACCEPT  # Allow IP to SSH / Разрешить IP на SSH
```

### Allow Established Connections / Разрешить установленные соединения
```bash
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  # Allow established / Разрешить установленные
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  # Alternative / Альтернатива
```

### Allow Loopback / Разрешить loopback
```bash
sudo iptables -A INPUT -i lo -j ACCEPT        # Allow loopback / Разрешить loopback
```

### Drop/Reject Traffic / Запретить трафик
```bash
sudo iptables -A INPUT -j DROP                # Drop all / Запретить всё
sudo iptables -A INPUT -j REJECT              # Reject all / Отклонить всё
sudo iptables -s <IP> -A INPUT -j DROP        # Drop from IP / Запретить с IP
sudo iptables -A INPUT -p tcp --dport 23 -j DROP  # Drop telnet / Запретить telnet
```

---

# ⬆️ OUTPUT Chain / Исходящий трафик

```bash
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT  # Allow HTTP out / Разрешить HTTP исходящий
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT # Allow HTTPS out / Разрешить HTTPS исходящий
sudo iptables -A OUTPUT -d <IP> -j DROP       # Block destination IP / Заблокировать IP назначения
sudo iptables -A OUTPUT -m owner --uid-owner <USER> -j ACCEPT  # Allow user / Разрешить пользователю
```

---

# 🔀 FORWARD Chain / Пересылка

```bash
sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT  # Forward eth0→eth1 / Пересылка eth0→eth1
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  # Forward established / Пересылка установленных
sudo iptables -A FORWARD -i wg0 -j ACCEPT     # Forward from VPN / Пересылка с VPN
sudo iptables -A FORWARD -o wg0 -j ACCEPT     # Forward to VPN / Пересылка в VPN
```

---

# 🌐 NAT & Port Forwarding / NAT и проброс портов

### SNAT (Source NAT) / SNAT (NAT источника)
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  # Masquerade / Маскарад
sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <PUBLIC_IP>  # Static SNAT / Статический SNAT
```

### DNAT (Destination NAT) / DNAT (NAT назначения)
```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination <INTERNAL_IP>:80  # Port forward / Проброс порта
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination <INTERNAL_IP>:80  # Port redirect / Перенаправление порта
```

### Docker NAT / Docker NAT
```bash
sudo iptables -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE  # Docker NAT / Docker NAT
```

---

# 💾 Saving & Restoring / Сохранение и восстановление

### Save Rules / Сохранение правил
```bash
sudo iptables-save > /etc/iptables/rules.v4  # Save IPv4 / Сохранить IPv4
sudo ip6tables-save > /etc/iptables/rules.v6 # Save IPv6 / Сохранить IPv6
sudo iptables-save | sudo tee /etc/iptables/rules.v4  # Alternative / Альтернатива
```

### Restore Rules / Восстановление правил
```bash
sudo iptables-restore < /etc/iptables/rules.v4  # Restore IPv4 / Восстановить IPv4
sudo ip6tables-restore < /etc/iptables/rules.v6  # Restore IPv6 / Восстановить IPv6
```

### Persistent Rules (Debian/Ubuntu) / Постоянные правила (Debian/Ubuntu)
```bash
sudo apt install iptables-persistent         # Install persistence / Установить сохранение
sudo netfilter-persistent save                # Save current rules / Сохранить текущие правила
sudo netfilter-persistent reload              # Reload rules / Перезагрузить правила
```

### Persistent Rules (RHEL/CentOS) / Постоянные правила (RHEL/CentOS)
```bash
sudo service iptables save                    # Save rules / Сохранить правила
sudo systemctl enable iptables                # Enable on boot / Включить при загрузке
```

---

# 🧩 Common Patterns / Распространённые шаблоны

### Basic Firewall Setup / Базовая настройка файрвола
```bash
# Flush existing rules / Очистить существующие правила
sudo iptables -F
sudo iptables -X

# Set default policies / Установить политики по умолчанию
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback / Разрешить loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established / Разрешить установленные
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH / Разрешить SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS / Разрешить HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Save rules / Сохранить правила
sudo iptables-save > /etc/iptables/rules.v4
```

### Web Server Firewall / Файрвол веб-сервера
```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set  # SSH rate limit
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
```

### Database Server Firewall / Файрвол сервера БД
```bash
# Allow only from app server / Разрешить только с сервера приложений
sudo iptables -A INPUT -s <APP_SERVER_IP> -p tcp --dport 3306 -j ACCEPT  # MySQL
sudo iptables -A INPUT -s <APP_SERVER_IP> -p tcp --dport 5432 -j ACCEPT  # PostgreSQL
sudo iptables -A INPUT -p tcp --dport 3306 -j DROP   # Drop other MySQL
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP   # Drop other PostgreSQL
```

### Rate Limiting / Ограничение частоты
```bash
# SSH brute force protection / Защита SSH от перебора
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

# HTTP rate limit / Ограничение HTTP
sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
```

### Block Specific Country (using ipset) / Блокировка конкретной страны
```bash
sudo ipset create blocklist hash:net          # Create ipset / Создать ipset
sudo ipset add blocklist <COUNTRY_CIDR>       # Add CIDR / Добавить CIDR
sudo iptables -A INPUT -m set --match-set blocklist src -j DROP  # Block / Заблокировать
```

---

# 🔧 Rule Management / Управление правилами

### Insert Rule / Вставить правило
```bash
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT  # Insert at position 1 / Вставить в позицию 1
```

### Delete Rule / Удалить правило
```bash
sudo iptables -D INPUT -p tcp --dport 22 -j ACCEPT  # Delete by specification / Удалить по спецификации
sudo iptables -D INPUT 1                      # Delete by line number / Удалить по номеру строки
```

### Replace Rule / Заменить правило
```bash
sudo iptables -R INPUT 1 -p tcp --dport 2222 -j ACCEPT  # Replace rule 1 / Заменить правило 1
```

### Flush Rules / Очистить правила
```bash
sudo iptables -F                              # Flush all chains / Очистить все цепочки
sudo iptables -F INPUT                        # Flush INPUT chain / Очистить INPUT
sudo iptables -t nat -F                       # Flush NAT table / Очистить таблицу NAT
sudo iptables -X                              # Delete user chains / Удалить пользовательские цепочки
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Debug Rules / Отладка правил
```bash
sudo iptables -L -n -v --line-numbers         # Detailed list / Подробный список
sudo iptables -L -t nat -n -v                 # NAT table / Таблица NAT
sudo iptables -L -t mangle -n -v              # Mangle table / Таблица mangle
```

### Check Packet Counters / Проверка счётчиков пакетов
```bash
sudo iptables -L -n -v                        # View counters / Просмотр счётчиков
sudo iptables -Z                              # Reset counters / Сбросить счётчики
```

### Log Dropped Packets / Логирование отброшенных пакетов
```bash
sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES-DROPPED: " --log-level 4  # Log before drop / Лог перед отбросом
sudo iptables -A INPUT -j DROP                # Drop / Отбросить
sudo journalctl -k | grep IPTABLES            # View logs / Просмотр логов
```

### Test Rule Without Applying / Тестирование правила без применения
```bash
sudo iptables -C INPUT -p tcp --dport 22 -j ACCEPT  # Check if rule exists / Проверить существование правила
```

### IPv6 / IPv6
```bash
sudo ip6tables -L -n -v                       # List IPv6 rules / Список IPv6 правил
sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT  # Allow SSH IPv6 / Разрешить SSH IPv6
sudo ip6tables-save > /etc/iptables/rules.v6  # Save IPv6 / Сохранить IPv6
```

---

# 🌟 Real-World Examples / Примеры из практики

### Docker Host Firewall / Файрвол хоста Docker
```bash
# Allow Docker containers / Разрешить Docker контейнеры
sudo iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
```

### VPN Server (WireGuard) / VPN сервер (WireGuard)
```bash
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### Port Knocking / Порт knock
```bash
# Advanced port knocking setup / Продвинутая настройка port knocking
# Requires recent module / Требует модуль recent
sudo iptables -A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 1111 -m recent --set --name KNOCK1
sudo iptables -A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 2222 -m recent --rcheck --seconds 10 --name KNOCK1 -m recent --set --name KNOCK2
sudo iptables -A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 10 --name KNOCK2 -j ACCEPT
```

### Kubernetes NodePort / Kubernetes NodePort
```bash
# Allow Kubernetes NodePort range / Разрешить диапазон NodePort Kubernetes
sudo iptables -A INPUT -p tcp --dport 30000:32767 -j ACCEPT
```

### Load Balancer / Балансировщик нагрузки
```bash
# Round-robin to backends / Round-robin на бэкенды
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -m statistic --mode nth --every 2 --packet 0 -j DNAT --to-destination <BACKEND1>:80
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -m statistic --mode nth --every 2 --packet 1 -j DNAT --to-destination <BACKEND2>:80
```

# 💡 Best Practices / Лучшие практики
# Always test rules before saving / Всегда тестируйте правила перед сохранением
# Use --line-numbers for easy management / Используйте --line-numbers для управления
# Log dropped packets for debugging / Логируйте отброшенные пакеты для отладки
# Prefer nftables for new deployments / Предпочтите nftables для новых развёртываний
# Keep backup of working rules / Держите резервную копию рабочих правил
# Test connectivity after rule changes / Тестируйте подключение после изменений

# 🔧 Configuration Files / Файлы конфигурации
```bash
# /etc/iptables/rules.v4    — IPv4 rules / Правила IPv4
# /etc/iptables/rules.v6    — IPv6 rules / Правила IPv6
# /etc/sysconfig/iptables   — RHEL/CentOS rules / Правила RHEL/CentOS
```

# 📋 Migration to nftables / Миграция на nftables
```bash
iptables-translate -A INPUT -p tcp --dport 22 -j ACCEPT  # Convert to nftables / Конвертировать в nftables
iptables-restore-translate -f /etc/iptables/rules.v4     # Convert entire ruleset / Конвертировать весь набор
```
