Title: 🔁 iptables → nftables Translation
Group: Network
Icon: 🔁
Order: 15

## Table of Contents
- [Translation Basics](#-translation-basics--основы-перевода)
- [Basic Rules](#-basic-rules--базовые-правила)
- [Chain Management](#-chain-management--управление-цепочками)
- [NAT Rules](#-nat-rules--правила-nat)
- [Connection Tracking](#-connection-tracking--отслеживание-соединений)
- [Advanced Matching](#-advanced-matching--расширенное-сопоставление)
- [Migration Tools](#-migration-tools--инструменты-миграции)

---

# 📘 Translation Basics / Основы перевода

### Key Differences / Ключевые отличия
```bash
# iptables: Separate tables (filter, nat, mangle, raw)
# nftables: Unified inet family with configurable chains

# iptables: Rules appended/inserted with -A/-I
# nftables: Rules added to chains with explicit priority

# iptables: Verbose syntax with many flags
# nftables: Cleaner, more consistent syntax
```

### Table/Chain Family Mapping / Соответствие таблиц/семейств
```bash
# iptables -t filter  → nft add table inet filter
# iptables -t nat     → nft add table inet nat
# iptables -t mangle  → nft add table inet mangle
# iptables -t raw     → nft add table inet raw
```

---

# 🔧 Basic Rules / Базовые правила

### Allow SSH / Разрешить SSH
```bash
# iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 22 accept
```

### Allow HTTP and HTTPS / Разрешить HTTP и HTTPS
```bash
# iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport { 80, 443 } accept
```

### Allow Ping (ICMP) / Разрешить ping (ICMP)
```bash
# iptables
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# nftables
nft add rule inet filter input icmp type echo-request accept
nft add rule inet filter input icmpv6 type echo-request accept
```

### Drop All / Отбросить всё
```bash
# iptables
iptables -A INPUT -j DROP

# nftables
nft add rule inet filter input drop
```

---

# ⛓️ Chain Management / Управление цепочками

### Default Policy / Политика по умолчанию
```bash
# iptables
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# nftables
nft add chain inet filter input { type filter hook input priority 0; policy drop; }
nft add chain inet filter forward { type filter hook forward priority 0; policy drop; }
nft add chain inet filter output { type filter hook output priority 0; policy accept; }
```

### Create Custom Chain / Создать пользовательскую цепочку
```bash
# iptables
iptables -N CUSTOM_CHAIN
iptables -A INPUT -j CUSTOM_CHAIN

# nftables
nft add chain inet filter custom_chain
nft add rule inet filter input jump custom_chain
```

### Insert Rule at Position / Вставить правило в позицию
```bash
# iptables
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# nftables
nft insert rule inet filter input position 0 tcp dport 22 accept
```

---

# 🔀 NAT Rules / Правила NAT

### SNAT (Source NAT) / SNAT (NAT источника)
```bash
# iptables
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <EXTERNAL_IP>

# nftables
nft add rule inet nat postrouting oifname "eth0" snat to <EXTERNAL_IP>
```

### MASQUERADE / Маскарадинг
```bash
# iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# nftables
nft add rule inet nat postrouting oifname "eth0" masquerade
```

### DNAT (Port Forwarding) / DNAT (проброс портов)
```bash
# iptables
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination <INTERNAL_IP>:8080

# nftables
nft add rule inet nat prerouting tcp dport 80 dnat to <INTERNAL_IP>:8080
```

### Redirect (Port Redirect) / Перенаправление портов
```bash
# iptables
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# nftables
nft add rule inet nat prerouting tcp dport 80 redirect to :8080
```

---

# 🔗 Connection Tracking / Отслеживание соединений

### Allow Established/Related / Разрешить established/related
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# nftables
nft add rule inet filter input ct state established,related accept
```

### Drop Invalid Packets / Отбросить недействительные пакеты
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# nftables
nft add rule inet filter input ct state invalid drop
```

### Track New Connections / Отслеживать новые соединения
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ACCEPT

# nftables
nft add rule inet filter input ct state new tcp dport 22 accept
```

---

# 🎯 Advanced Matching / Расширенное сопоставление

### Match Source IP / Сопоставить IP источника
```bash
# iptables
iptables -A INPUT -s <IP>/24 -j ACCEPT

# nftables
nft add rule inet filter input ip saddr <IP>/24 accept
```

### Match Destination IP / Сопоставить IP назначения
```bash
# iptables
iptables -A INPUT -d <IP> -j ACCEPT

# nftables
nft add rule inet filter input ip daddr <IP> accept
```

### Match Multiple Ports / Сопоставить несколько портов
```bash
# iptables
iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport { 80, 443, 8080 } accept
```

### Match Port Range / Сопоставить диапазон портов
```bash
# iptables
iptables -A INPUT -p tcp --dport 8000:9000 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 8000-9000 accept
```

### Match Interface / Сопоставить интерфейс
```bash
# iptables
iptables -A INPUT -i eth0 -j ACCEPT

# nftables
nft add rule inet filter input iifname "eth0" accept
```

### Rate Limiting / Ограничение частоты
```bash
# iptables
iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 22 limit rate 3/minute accept
```

### String Matching / Сопоставление строк
```bash
# iptables
iptables -A INPUT -p tcp --dport 80 -m string --string "malicious" --algo bm -j DROP

# nftables
# Note: nftables doesn't have built-in string matching; use userspace tools
# Примечание: в nftables нет встроенного сопоставления строк; используйте инструменты пользовательского пространства
```

---

# 🛠️ Migration Tools / Инструменты миграции

### iptables-translate / iptables-translate
```bash
# Translate single iptables rule / Перевести одно правило iptables
iptables-translate -A INPUT -p tcp --dport 22 -j ACCEPT

# Output / Вывод:
# nft add rule ip filter INPUT tcp dport 22 counter accept
```

### iptables-restore-translate / iptables-restore-translate
```bash
# Translate entire ruleset / Перевести весь набор правил
iptables-save > /tmp/iptables.rules
iptables-restore-translate -f /tmp/iptables.rules > /tmp/nftables.conf

# Load translated rules / Загрузить переведённые правила
nft -f /tmp/nftables.conf
```

### ip6tables-translate / ip6tables-translate
```bash
# Translate IPv6 rules / Перевести правила IPv6
ip6tables-translate -A INPUT -p tcp --dport 22 -j ACCEPT

# Output / Вывод:
# nft add rule ip6 filter INPUT tcp dport 22 counter accept
```

### Manual Migration Steps / Шаги ручной миграции
```bash
# 1. Export current iptables rules / Экспортировать текущие правила iptables
iptables-save > /tmp/iptables-backup.rules
ip6tables-save > /tmp/ip6tables-backup.rules

# 2. Translate to nftables / Перевести в nftables
iptables-restore-translate -f /tmp/iptables-backup.rules > /tmp/nftables.conf
ip6tables-restore-translate -f /tmp/ip6tables-backup.rules >> /tmp/nftables.conf

# 3. Review and edit / Проверить и отредактировать
vim /tmp/nftables.conf

# 4. Test nftables rules / Тестировать правила nftables
nft -f /tmp/nftables.conf

# 5. Save nftables configuration / Сохранить конфигурацию nftables
cp /tmp/nftables.conf /etc/nftables.conf
systemctl enable nftables
systemctl start nftables
```

---

# 🔄 Complete Example Comparison / Полный пример сравнения

### iptables Ruleset / Набор правил iptables
```bash
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
```

### nftables Equivalent / Эквивалент nftables
```bash
nft add table inet filter

nft add chain inet filter input { type filter hook input priority 0; policy drop; }
nft add chain inet filter forward { type filter hook forward priority 0; policy drop; }
nft add chain inet filter output { type filter hook output priority 0; policy accept; }

nft add rule inet filter input iifname "lo" accept
nft add rule inet filter input ct state { established, related } accept
nft add rule inet filter input tcp dport 22 accept
nft add rule inet filter input tcp dport { 80, 443 } accept
nft add rule inet filter input drop
```

# 💡 Best Practices / Лучшие практики
# Use iptables-translate for initial migration / Используйте iptables-translate для начальной миграции
# Test nftables rules before disabling iptables / Тестируйте правила nftables перед отключением iptables
# Use inet family for dual-stack (IPv4+IPv6) / Используйте семейство inet для dual-stack
# Group related rules in custom chains / Группируйте связанные правила в пользовательские цепочки
# Use sets for multiple IPs/ports efficiently / Используйте наборы для эффективной работы с несколькими IP/портами
# Document migration for rollback / Документируйте миграцию для отката

# 🔧 Configuration Files / Файлы конфигурации
```bash
# /etc/nftables.conf                        — Main nftables configuration / Основная конфигурация nftables
# /tmp/iptables-backup.rules                — iptables backup / Резервная копия iptables
# /tmp/nftables.conf                        — Translated nftables config / Переведённая конфигурация nftables
```

# 📋 Quick Reference Chart / Краткая справочная таблица
```bash
# iptables -A         → nft add rule
# iptables -I         → nft insert rule
# iptables -D         → nft delete rule
# iptables -L         → nft list ruleset
# iptables -F         → nft flush ruleset
# iptables -P         → policy in chain definition
# -j ACCEPT           → accept, -j DROP             → drop
# -j REJECT           → reject, --dport             → dport
# --sport             → sport, -s                  → ip saddr
# -d                  → ip daddr, -i                  → iifname
# -o                  → oifname
```
