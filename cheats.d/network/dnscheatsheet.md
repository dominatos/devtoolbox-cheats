Title: 🧭 DNS — dig/nslookup/host
Group: Network
Icon: 🧭
Order: 5

# DNS — dig / nslookup / host

`dig`, `nslookup`, and `host` are DNS query utilities used for domain name resolution troubleshooting. `dig` (Domain Information Groper) is the most powerful and widely used, providing detailed DNS record information. `nslookup` offers interactive mode, and `host` provides simple, quick lookups.

📚 **Official Docs / Официальная документация:** [dig(1)](https://manpages.debian.org/bookworm/bind9-dnsutils/dig.1.en.html) · [nslookup(1)](https://manpages.debian.org/bookworm/bind9-dnsutils/nslookup.1.en.html)

## Table of Contents
- [DIG — DNS Lookup](#-dig--dns-lookup)
- [NSLOOKUP — Interactive DNS](#-nslookup--interactive-dns)
- [HOST — Simple DNS](#-host--simple-dns)
- [Record Types](#-record-types--типы-записей)
- [Advanced Queries](#-advanced-queries--продвинутые-запросы)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

## 🔍 DIG — DNS Lookup

### Basic Queries / Базовые запросы
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

### Specific DNS Server / Конкретный DNS сервер
```bash
dig @1.1.1.1 example.com                      # Query Cloudflare / Запрос Cloudflare
dig @8.8.8.8 example.com                      # Query Google DNS / Запрос Google DNS
dig @208.67.222.222 example.com               # Query OpenDNS / Запрос OpenDNS
dig @<DNS_SERVER_IP> example.com              # Custom DNS / Пользовательский DNS
```

### Query Options / Опции запросов
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

### Reverse DNS / Обратный DNS
```bash
dig -x 1.2.3.4                                # Reverse lookup / Обратный поиск
dig -x 1.2.3.4 +short                         # Short reverse / Короткий обратный
```

### Batch Queries / Пакетные запросы
```bash
dig example.com MX +short                     # MX records / MX записи
dig example.com NS +short                     # NS records / NS записи
dig example.com TXT +short                    # TXT records / TXT записи
```

---

## 🔎 NSLOOKUP — Interactive DNS

### Basic Usage / Базовое использование
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

### Interactive Mode / Интерактивный режим
```bash
nslookup
> server 8.8.8.8                              # Change DNS server / Сменить DNS сервер
> set type=MX                                 # Set record type / Установить тип записи
> example.com                                 # Query domain / Запросить домен
> exit                                        # Exit / Выход
```

---

## 🌐 HOST — Simple DNS

### Basic Queries / Базовые запросы
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

### Reverse Lookup / Обратный поиск
```bash
host 1.2.3.4                                  # Reverse DNS / Обратный DNS
host -t PTR 1.2.3.4                           # PTR query / PTR запрос
```

### Specific Server / Конкретный сервер
```bash
host example.com 1.1.1.1                      # Query server / Запросить сервер
host -a example.com                           # All records / Все записи
host -v example.com                           # Verbose output / Подробный вывод
```

---

## 📋 Record Types / Типы записей

### Common Record Types / Распространённые типы
```bash
# A       - IPv4 address / IPv4 адрес
# AAAA    - IPv6 address / IPv6 адрес
# MX      - Mail exchanger / Почтовый обменник
# NS      - Nameserver / DNS сервер
# TXT     - Text record / Текстовая запись
# CNAME   - Canonical name / Каноническое имя
# SOA     - Start of authority / Начало зоны
# PTR     - Pointer (reverse DNS) / Указатель (обратный DNS)
# SRV     - Service locator / Локатор сервиса
# CAA     - Certificate authority authorization / Авторизация центра сертификации
# DNSKEY  - DNSSEC public key / Публичный ключ DNSSEC
# DS      - Delegation signer / Делегированный подписант
```

### SRV Record Format / Формат SRV записи
```bash
dig _service._proto.name SRV                  # Generic SRV / Общий SRV
dig _xmpp-server._tcp.example.com SRV         # XMPP server / XMPP сервер
dig _ldap._tcp.example.com SRV                # LDAP server / LDAP сервер
dig _kerberos._tcp.example.com SRV            # Kerberos server / Kerberos сервер
```

---

## 🔬 Advanced Queries / Продвинутые запросы

### Trace Full Delegation / Трассировка полной делегации
```bash
dig +trace example.com                        # Full trace / Полная трассировка
dig +trace example.com | grep -A2 "example"   # Filter output / Фильтр вывода
```

### DNSSEC Validation / Проверка DNSSEC
```bash
dig example.com +dnssec                       # DNSSEC query / DNSSEC запрос
dig example.com +dnssec +multiline            # Multiline output / Многострочный вывод
dig DNSKEY example.com                        # DNSSEC keys / DNSSEC ключи
dig DS example.com                            # DS records / DS записи
```

### Zone Transfer (AXFR) / Передача зоны (AXFR)
```bash
dig @<NS_SERVER> example.com AXFR             # Zone transfer / Передача зоны
dig @<NS_SERVER> example.com AXFR +short      # Short zone transfer / Короткая передача зоны
```

### Query Statistics / Статистика запросов
```bash
dig example.com +stats                        # Query stats / Статистика запроса
dig example.com +noall +stats                 # Only stats / Только статистика
```

### Multiple Queries / Множественные запросы
```bash
dig example.com A example.com MX              # Multiple types / Несколько типов
dig @1.1.1.1 @8.8.8.8 example.com             # Multiple servers / Несколько серверов
```

---

## 🐛 Troubleshooting / Устранение неполадок

### Check DNS Resolution / Проверка разрешения DNS
```bash
dig example.com                               # Basic check / Базовая проверка
dig example.com @8.8.8.8                      # Alternative DNS / Альтернативный DNS
dig example.com +trace                        # Trace delegation / Трассировка делегации
```

### Check Specific Record / Проверка конкретной записи
```bash
dig example.com MX +short                     # MX records / MX записи
dig example.com NS +short                     # NS records / NS записи
dig example.com A +short                      # A records / A записи
```

### DNS Propagation / Распространение DNS
```bash
dig example.com @1.1.1.1                      # Cloudflare DNS / Cloudflare DNS
dig example.com @8.8.8.8                      # Google DNS / Google DNS
dig example.com @208.67.222.222               # OpenDNS / OpenDNS
dig example.com @<AUTHORITATIVE_NS>           # Authoritative NS / Авторитативный NS
```

### Check TTL / Проверка TTL
```bash
dig example.com | grep -A1 "ANSWER SECTION"   # Show TTL / Показать TTL
dig example.com +noall +answer +ttlid         # TTL display / Отображение TTL
```

### DNS Response Time / Время ответа DNS
```bash
dig example.com +stats | grep "Query time"    # Query time / Время запроса
time dig example.com +short                   # Total time / Общее время
```

### Check Local DNS / Проверка локального DNS
```bash
cat /etc/resolv.conf                          # Local DNS config / Локальная конфигурация DNS
systemd-resolve --status                      # Systemd DNS status / Статус DNS systemd
resolvectl status                             # Alternative status / Альтернативный статус
```

---

## 🌟 Real-World Examples / Примеры из практики

### Email Server Setup / Настройка почтового сервера
```bash
dig example.com MX +short                     # Mail servers / Почтовые серверы
dig example.com TXT +short | grep spf         # SPF record / SPF запись
dig _dmarc.example.com TXT +short             # DMARC record / DMARC запись
dig default._domainkey.example.com TXT +short # DKIM record / DKIM запись
```

### SSL/TLS Certificate Validation / Проверка SSL/TLS сертификата
```bash
dig example.com CAA                           # CAA records / CAA записи
dig _acme-challenge.example.com TXT           # LetsEncrypt validation / Проверка LetsEncrypt
```

### Cloudflare Check / Проверка Cloudflare
```bash
dig example.com A +short                      # Check if Cloudflare / Проверка Cloudflare
dig example.com NS +short                     # Cloudflare nameservers / NS Cloudflare
```

### Kubernetes DNS / DNS Kubernetes
```bash
dig kubernetes.default.svc.cluster.local @10.96.0.10  # K8s service / Сервис K8s
dig myapp.default.svc.cluster.local @10.96.0.10       # Custom service / Пользовательский сервис
```

### Monitor DNS Changes / Мониторинг изменений DNS
```bash
watch -n 5 'dig example.com +short'           # Monitor every 5s / Мониторинг каждые 5с
while true; do dig example.com +short; sleep 10; done  # Continuous monitoring / Непрерывный мониторинг
```

### Batch DNS Lookup / Пакетный DNS поиск
```bash
for domain in example.com example.org example.net; do dig $domain A +short; done  # Multiple domains / Несколько доменов
cat domains.txt | xargs -I{} dig {} A +short  # From file / Из файла
```

### DNS Leak Test / Тест утечки DNS
```bash
dig whoami.akamai.net +short                  # Your resolver IP / IP вашего резолвера
dig resolver.dnscrypt.info TXT +short         # DNSCrypt resolver / DNSCrypt резолвер
dig o-o.myaddr.l.google.com TXT +short        # Google resolver check / Проверка Google резолвера
```

### Root Nameservers / Корневые NS серверы
```bash
dig . NS +short                               # Root nameservers / Корневые NS серверы
dig @a.root-servers.net . NS                  # Query root server / Запрос корневого сервера
```

### Check Subdomain / Проверка поддомена
```bash
dig www.example.com                           # WWW subdomain / WWW поддомен
dig mail.example.com                          # Mail subdomain / Mail поддомен
dig api.example.com                           # API subdomain / API поддомен
```

### DNS over HTTPS (DoH) / DNS через HTTPS
```bash
curl -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=example.com&type=A'  # Cloudflare DoH / Cloudflare DoH
curl -H 'accept: application/dns-json' 'https://dns.google/resolve?name=example.com&type=A'  # Google DoH / Google DoH
```

## 💡 Best Practices / Лучшие практики
# Always check authoritative nameservers / Всегда проверяйте авторитативные NS
# Use +short for scripting / Используйте +short для скриптов
# Check multiple DNS servers for propagation / Проверяйте несколько DNS серверов для распространения
# Use +trace to debug delegation issues / Используйте +trace для отладки делегации
# Monitor TTL for cache timing / Мониторьте TTL для кеширования

## 📋 Common DNS Servers / Распространённые DNS серверы
```bash
# 1.1.1.1, 1.0.0.1          — Cloudflare
# 8.8.8.8, 8.8.4.4          — Google
# 9.9.9.9, 149.112.112.112  — Quad9
# 208.67.222.222, 208.67.220.220 — OpenDNS
# 94.140.14.14, 94.140.15.15     — AdGuard
```

## 🔧 Configuration Files / Файлы конфигурации
```bash
# /etc/resolv.conf          — DNS resolver config / Конфигурация DNS резолвера
# /etc/hosts                — Local DNS overrides / Локальные DNS переопределения
# /etc/systemd/resolved.conf — Systemd DNS config / Конфигурация DNS systemd
```
