---
Title: 🧭 DNS — dig/nslookup/host
Group: Network
Icon: 🧭
Order: 5
tags:
  - network
  - sysadmin
  - linux
---

# DNS — dig / nslookup / host

`dig`, `nslookup`, and `host` are DNS query utilities used for domain name resolution troubleshooting. `dig` (Domain Information Groper) is the most powerful and widely used, providing detailed DNS record information. `nslookup` offers interactive mode, and `host` provides simple, quick lookups.

📚 **Official Docs / Официальная документация:** [dig(1)](https://manpages.debian.org/bookworm/bind9-dnsutils/dig.1.en.html) · [nslookup(1)](https://manpages.debian.org/bookworm/bind9-dnsutils/nslookup.1.en.html)

## Table of Contents
- [DIG — DNS Lookup](#DIG%20—%20DNS%20Lookup)
- [NSLOOKUP — Interactive DNS](#NSLOOKUP%20—%20Interactive%20DNS)
- [HOST — Simple DNS](#HOST%20—%20Simple%20DNS)
- [Record Types](#Record%20Types)
- [Advanced Queries](#Advanced%20Queries)
- [Troubleshooting](#Troubleshooting)
- [Real-World Examples](#Real-World%20Examples)

---

## 🔍 DIG — DNS Lookup

### Basic Queries
```bash
dig example.com                               # Default A record / A запись по умолчанию
dig example.com +short                        # Short output / Короткий вывод
dig example.com A                             # IPv4 address / IPv4 адрес
dig example.com AAAA                          # IPv6 address / IPv6 адрес
dig example.com MX                            # Mail exchangers / Почтовые MX
dig example.com NS                            # Nameservers / DNS серверы
dig example.com TXT                           # TXT records / TXT записи
dig example.com SOA                           # Start of Authority / Начало зоны
dig example.com CNAME                         # Canonical name / Каноническое имя
dig example.com ANY                           # All records / Все типы записей
```

### Specific DNS Server
```bash
dig @1.1.1.1 example.com                      # Query Cloudflare / Запрос Cloudflare
dig @8.8.8.8 example.com                      # Query Google DNS / Запрос Google DNS
dig @208.67.222.222 example.com               # Query OpenDNS / Запрос OpenDNS
dig @<DNS_SERVER_IP> example.com              # Custom DNS / Пользовательский DNS
```

### Query Options
```bash
dig example.com +noall +answer                # Only answer section / Только раздел ответа
dig example.com +trace                        # Full delegation trace / Полная трассировка делегации
dig example.com +dnssec                       # DNSSEC validation / Проверка DNSSEC
dig example.com +tcp                          # Use TCP / Использовать TCP
dig example.com +short +noquestion            # Minimal output / Минимальный вывод
dig example.com +norecurse                    # No recursion / Без рекурсии
dig example.com +timeout=5                    # Timeout 5s / Таймаут 5с
dig example.com +tries=3                      # Retry count / Число попыток
```

### Reverse DNS
```bash
dig -x 1.2.3.4                                # Reverse lookup / Обратный поиск
dig -x 1.2.3.4 +short                         # Short reverse / Короткий обратный
```

### Batch Queries
```bash
dig example.com MX +short                     # MX records / MX записи
dig example.com NS +short                     # NS records / NS записи
dig example.com TXT +short                    # TXT records / TXT записи
```

---

## 🔎 NSLOOKUP — Interactive DNS

### Basic Usage
```bash
nslookup example.com                          # Default query / Запрос по умолчанию
nslookup example.com 1.1.1.1                  # Specific DNS / Конкретный DNS
nslookup -type=A example.com                  # A record / A запись
nslookup -type=MX example.com                 # MX record / MX запись
nslookup -type=NS example.com                 # NS record / NS запись
nslookup -type=TXT example.com                # TXT record / TXT запись
nslookup -type=SOA example.com                # SOA record / SOA запись
nslookup -type=SRV _service._tcp.example.com  # SRV record / SRV запись
nslookup -type=PTR 4.3.2.1.in-addr.arpa       # Reverse DNS / Обратный DNS
```

### Interactive Mode
```bash
nslookup
> server 8.8.8.8                              # Change DNS server / Сменить DNS сервер
> set type=MX                                 # Set record type / Установить тип записи
> example.com                                 # Query domain / Запросить домен
> exit                                        # Exit / Выход
```

---

## 🌐 HOST — Simple DNS

### Basic Queries
```bash
host example.com                              # Default A record / A запись по умолчанию
host -t A example.com                         # A record / A запись
host -t AAAA example.com                      # AAAA record / AAAA запись
host -t MX example.com                        # MX record / MX запись
host -t NS example.com                        # NS record / NS запись
host -t TXT example.com                       # TXT record / TXT запись
host -t SOA example.com                       # SOA record / SOA запись
host -t CNAME www.example.com                 # CNAME record / CNAME запись
```

### Reverse Lookup
```bash
host 1.2.3.4                                  # Reverse DNS / Обратный DNS
host -t PTR 1.2.3.4                           # PTR query / PTR запрос
```

### Specific Server
```bash
host example.com 1.1.1.1                      # Query server / Запросить сервер
host -a example.com                           # All records / Все записи
host -v example.com                           # Verbose output / Подробный вывод
```

---

## 📋 Record Types

### Common Record Types
```bash
# A       - IPv4 address / IPv4
# AAAA    - IPv6 address / IPv6
# MX      - Mail exchanger
# NS      - Nameserver / DNS
# TXT     - Text record
# CNAME   - Canonical name
# SOA     - Start of authority
# PTR     - Pointer (reverse DNS)
# SRV     - Service locator
# CAA     - Certificate authority authorization
# DNSKEY  - DNSSEC public key
# DS      - Delegation signer
```

### SRV Record Format
```bash
dig _service._proto.name SRV                  # Generic SRV / Общий SRV
dig _xmpp-server._tcp.example.com SRV         # XMPP server / XMPP сервер
dig _ldap._tcp.example.com SRV                # LDAP server / LDAP сервер
dig _kerberos._tcp.example.com SRV            # Kerberos server / Kerberos сервер
```

---

## 🔬 Advanced Queries

### Trace Full Delegation
```bash
dig +trace example.com                        # Full trace / Полная трассировка
dig +trace example.com | grep -A2 "example"   # Filter output / Фильтр вывода
```

### DNSSEC Validation
```bash
dig example.com +dnssec                       # DNSSEC query / DNSSEC запрос
dig example.com +dnssec +multiline            # Multiline output / Многострочный вывод
dig DNSKEY example.com                        # DNSSEC keys / DNSSEC ключи
dig DS example.com                            # DS records / DS записи
```

### Zone Transfer (AXFR)
```bash
dig @<NS_SERVER> example.com AXFR             # Zone transfer / Передача зоны
dig @<NS_SERVER> example.com AXFR +short      # Short zone transfer / Короткая передача зоны
```

### Query Statistics
```bash
dig example.com +stats                        # Query stats / Статистика запроса
dig example.com +noall +stats                 # Only stats / Только статистика
```

### Multiple Queries
```bash
dig example.com A example.com MX              # Multiple types / Несколько типов
dig @1.1.1.1 @8.8.8.8 example.com             # Multiple servers / Несколько серверов
```

---

## 🐛 Troubleshooting

### Check DNS Resolution
```bash
dig example.com                               # Basic check / Базовая проверка
dig example.com @8.8.8.8                      # Alternative DNS / Альтернативный DNS
dig example.com +trace                        # Trace delegation / Трассировка делегации
```

### Check Specific Record
```bash
dig example.com MX +short                     # MX records / MX записи
dig example.com NS +short                     # NS records / NS записи
dig example.com A +short                      # A records / A записи
```

### DNS Propagation
```bash
dig example.com @1.1.1.1                      # Cloudflare DNS / Cloudflare DNS
dig example.com @8.8.8.8                      # Google DNS / Google DNS
dig example.com @208.67.222.222               # OpenDNS / OpenDNS
dig example.com @<AUTHORITATIVE_NS>           # Authoritative NS / Авторитативный NS
```

### Check TTL
```bash
dig example.com | grep -A1 "ANSWER SECTION"   # Show TTL / Показать TTL
dig example.com +noall +answer +ttlid         # TTL display / Отображение TTL
```

### DNS Response Time
```bash
dig example.com +stats | grep "Query time"    # Query time / Время запроса
time dig example.com +short                   # Total time / Общее время
```

### Check Local DNS
```bash
cat /etc/resolv.conf                          # Local DNS config / Локальная конфигурация DNS
systemd-resolve --status                      # Systemd DNS status / Статус DNS systemd
resolvectl status                             # Alternative status / Альтернативный статус
```

---

## 🌟 Real-World Examples

### Email Server Setup
```bash
dig example.com MX +short                     # Mail servers / Почтовые серверы
dig example.com TXT +short | grep spf         # SPF record / SPF запись
dig _dmarc.example.com TXT +short             # DMARC record / DMARC запись
dig default._domainkey.example.com TXT +short # DKIM record / DKIM запись
```

### SSL/TLS Certificate Validation
```bash
dig example.com CAA                           # CAA records / CAA записи
dig _acme-challenge.example.com TXT           # LetsEncrypt validation / Проверка LetsEncrypt
```

### Cloudflare Check
```bash
dig example.com A +short                      # Check if Cloudflare / Проверка Cloudflare
dig example.com NS +short                     # Cloudflare nameservers / NS Cloudflare
```

### Kubernetes DNS / DNS Kubernetes
```bash
dig kubernetes.default.svc.cluster.local @10.96.0.10  # K8s service / Сервис K8s
dig myapp.default.svc.cluster.local @10.96.0.10       # Custom service / Пользовательский сервис
```

### Monitor DNS Changes
```bash
watch -n 5 'dig example.com +short'           # Monitor every 5s / Мониторинг каждые 5с
while true; do dig example.com +short; sleep 10; done  # Continuous monitoring / Непрерывный мониторинг
```

### Batch DNS Lookup
```bash
for domain in example.com example.org example.net; do dig $domain A +short; done  # Multiple domains / Несколько доменов
cat domains.txt | xargs -I{} dig {} A +short  # From file / Из файла
```

### DNS Leak Test
```bash
dig whoami.akamai.net +short                  # Your resolver IP / IP вашего резолвера
dig resolver.dnscrypt.info TXT +short         # DNSCrypt resolver / DNSCrypt резолвер
dig o-o.myaddr.l.google.com TXT +short        # Google resolver check / Проверка Google резолвера
```

### Root Nameservers
```bash
dig . NS +short                               # Root nameservers / Корневые NS серверы
dig @a.root-servers.net . NS                  # Query root server / Запрос корневого сервера
```

### Check Subdomain
```bash
dig www.example.com                           # WWW subdomain / WWW поддомен
dig mail.example.com                          # Mail subdomain / Mail поддомен
dig api.example.com                           # API subdomain / API поддомен
```

### DNS over HTTPS (DoH) / DNS
```bash
curl -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=example.com&type=A'  # Cloudflare DoH / Cloudflare DoH
curl -H 'accept: application/dns-json' 'https://dns.google/resolve?name=example.com&type=A'  # Google DoH / Google DoH
```

## 💡 Best Practices
# Always check authoritative nameservers
# Use +short for scripting
# Check multiple DNS servers for propagation
# Use +trace to debug delegation issues
# Monitor TTL for cache timing

## 📋 Common DNS Servers
```bash
# 1.1.1.1, 1.0.0.1          — Cloudflare
# 8.8.8.8, 8.8.4.4          — Google
# 9.9.9.9, 149.112.112.112  — Quad9
# 208.67.222.222, 208.67.220.220 — OpenDNS
# 94.140.14.14, 94.140.15.15     — AdGuard
```

## 🔧 Configuration Files
```bash
# /etc/resolv.conf          — DNS resolver config
# /etc/hosts                — Local DNS overrides
# /etc/systemd/resolved.conf — Systemd DNS config
```

## 📚 Documentation Links

- [resolvectl Man Page](https://man7.org/linux/man-pages/man8/resolvectl.8.html)
- [Domain Name Resolution (Arch Wiki)](https://wiki.archlinux.org/title/Domain_name_resolution)
