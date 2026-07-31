---
Title: 🔁 iptables → nftables Translation
Group: Network
Icon: 🔁
Order: 15
tags:
  - network
  - sysadmin
  - linux
---

# iptables → nftables Translation Guide

This cheatsheet provides a side-by-side translation reference for migrating firewall rules from `iptables` to `nftables`. It covers table management, chain operations, NAT, connection tracking, and advanced matching patterns with equivalent commands in both syntaxes.

📚 **Official Docs / Официальная документация:** [Moving from iptables to nftables](https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables)

## Table of Contents
- [Translation Basics](#Translation%20Basics)
- [Basic Rules](#Basic%20Rules)
- [Chain Management](#️%20Chain%20Management)
- [NAT Rules](#NAT%20Rules)
- [Connection Tracking](#Connection%20Tracking)
- [Advanced Matching](#Advanced%20Matching)
- [Migration Tools](#️%20Migration%20Tools)

---

## 📘 Translation Basics

### Key Differences
```bash
# iptables: Separate tables (filter, nat, mangle, raw)
# nftables: Unified inet family with configurable chains

# iptables: Rules appended/inserted with -A/-I
# nftables: Rules added to chains with explicit priority

# iptables: Verbose syntax with many flags
# nftables: Cleaner, more consistent syntax
```

### Table/Chain Family Mapping
```bash
# iptables -t filter  → nft add table inet filter
# iptables -t nat     → nft add table inet nat
# iptables -t mangle  → nft add table inet mangle
# iptables -t raw     → nft add table inet raw
```

---

## 🔧 Basic Rules

### Allow SSH
```bash
# iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 22 accept
```

### Allow HTTP and HTTPS
```bash
# iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport { 80, 443 } accept
```

### Allow Ping (ICMP)
```bash
# iptables
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# nftables
nft add rule inet filter input icmp type echo-request accept
nft add rule inet filter input icmpv6 type echo-request accept
```

### Drop All
```bash
# iptables
iptables -A INPUT -j DROP

# nftables
nft add rule inet filter input drop
```

---

## ⛓️ Chain Management

### Default Policy
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

### Create Custom Chain
```bash
# iptables
iptables -N CUSTOM_CHAIN
iptables -A INPUT -j CUSTOM_CHAIN

# nftables
nft add chain inet filter custom_chain
nft add rule inet filter input jump custom_chain
```

### Insert Rule at Position
```bash
# iptables
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# nftables
nft insert rule inet filter input position 0 tcp dport 22 accept
```

---

## 🔀 NAT Rules

### SNAT (Source NAT) / SNAT (NAT
```bash
# iptables
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <EXTERNAL_IP>

# nftables
nft add rule inet nat postrouting oifname "eth0" snat to <EXTERNAL_IP>
```

### MASQUERADE
```bash
# iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# nftables
nft add rule inet nat postrouting oifname "eth0" masquerade
```

### DNAT (Port Forwarding) / DNAT
```bash
# iptables
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination <INTERNAL_IP>:8080

# nftables
nft add rule inet nat prerouting tcp dport 80 dnat to <INTERNAL_IP>:8080
```

### Redirect (Port Redirect)
```bash
# iptables
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# nftables
nft add rule inet nat prerouting tcp dport 80 redirect to :8080
```

---

## 🔗 Connection Tracking

### Allow Established/Related
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# nftables
nft add rule inet filter input ct state established,related accept
```

### Drop Invalid Packets
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# nftables
nft add rule inet filter input ct state invalid drop
```

### Track New Connections
```bash
# iptables
iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ACCEPT

# nftables
nft add rule inet filter input ct state new tcp dport 22 accept
```

---

## 🎯 Advanced Matching

### Match Source IP
```bash
# iptables
iptables -A INPUT -s <IP>/24 -j ACCEPT

# nftables
nft add rule inet filter input ip saddr <IP>/24 accept
```

### Match Destination IP
```bash
# iptables
iptables -A INPUT -d <IP> -j ACCEPT

# nftables
nft add rule inet filter input ip daddr <IP> accept
```

### Match Multiple Ports
```bash
# iptables
iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport { 80, 443, 8080 } accept
```

### Match Port Range
```bash
# iptables
iptables -A INPUT -p tcp --dport 8000:9000 -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 8000-9000 accept
```

### Match Interface
```bash
# iptables
iptables -A INPUT -i eth0 -j ACCEPT

# nftables
nft add rule inet filter input iifname "eth0" accept
```

### Rate Limiting
```bash
# iptables
iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min -j ACCEPT

# nftables
nft add rule inet filter input tcp dport 22 limit rate 3/minute accept
```

### String Matching
```bash
# iptables
iptables -A INPUT -p tcp --dport 80 -m string --string "malicious" --algo bm -j DROP

# nftables
# Note: nftables doesn't have built-in string matching; use userspace tools
#
```

---

# 🛠️ Migration Tools

### iptables-translate / iptables-translate
```bash
# Translate single iptables rule
iptables-translate -A INPUT -p tcp --dport 22 -j ACCEPT

# Output
# nft add rule ip filter INPUT tcp dport 22 counter accept
```

### iptables-restore-translate / iptables-restore-translate
```bash
# Translate entire ruleset
iptables-save > /tmp/iptables.rules
iptables-restore-translate -f /tmp/iptables.rules > /tmp/nftables.conf

# Load translated rules
nft -f /tmp/nftables.conf
```

### ip6tables-translate / ip6tables-translate
```bash
# Translate IPv6 rules
ip6tables-translate -A INPUT -p tcp --dport 22 -j ACCEPT

# Output
# nft add rule ip6 filter INPUT tcp dport 22 counter accept
```

### Manual Migration Steps
```bash
# 1. Export current iptables rules
iptables-save > /tmp/iptables-backup.rules
ip6tables-save > /tmp/ip6tables-backup.rules

# 2. Translate to nftables
iptables-restore-translate -f /tmp/iptables-backup.rules > /tmp/nftables.conf
ip6tables-restore-translate -f /tmp/ip6tables-backup.rules >> /tmp/nftables.conf

# 3. Review and edit
vim /tmp/nftables.conf

# 4. Test nftables rules
nft -f /tmp/nftables.conf

# 5. Save nftables configuration
cp /tmp/nftables.conf /etc/nftables.conf
systemctl enable nftables
systemctl start nftables
```

---

## 🔄 Complete Example Comparison

### iptables Ruleset
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

### nftables Equivalent
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

## 💡 Best Practices
# Use iptables-translate for initial migration
# Test nftables rules before disabling iptables
# Use inet family for dual-stack (IPv4+IPv6)
# Group related rules in custom chains
# Use sets for multiple IPs/ports efficiently
# Document migration for rollback

## 🔧 Configuration Files
```bash
# /etc/nftables.conf                        — Main nftables configuration
# /tmp/iptables-backup.rules                — iptables backup
# /tmp/nftables.conf                        — Translated nftables config
```

## 📋 Quick Reference Chart
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

## 📚 Documentation Links

- [nftables Wiki](https://wiki.nftables.org/)
- [iptables-translate Man Page](https://man7.org/linux/man-pages/man8/iptables-translate.8.html)
