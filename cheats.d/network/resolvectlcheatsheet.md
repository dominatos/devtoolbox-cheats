Title: 🖧 resolvectl — DNS Resolution Management
Group: Network
Icon: 🖧
Order: 19

# resolvectl — systemd-resolved DNS Management

`resolvectl` is the command-line tool for managing `systemd-resolved`, the systemd DNS resolver service. It provides DNS query, cache management, per-link DNS configuration, DNSSEC validation, and DNS-over-TLS support.

📚 **Official Docs / Официальная документация:** [systemd-resolved(8)](https://www.freedesktop.org/software/systemd/man/latest/resolvectl.html)

## Table of Contents
- [Basics & Status](#basics--status)
- [DNS Queries](#dns-queries)
- [Link Configuration](#link-configuration)
- [DNSSEC & DNS-over-TLS](#dnssec--dns-over-tls)
- [mDNS & LLMNR](#mdns--llmnr)
- [Service Management](#service-management)
- [Real-World Examples](#real-world-examples)
- [Reference Tables](#reference-tables)

---

## Basics & Status

### Status Commands / Команды статуса
```bash
resolvectl status                        # Show global and per-link DNS status / Показать общий статус DNS и по интерфейсам
resolvectl status <INTERFACE>            # Show status for specific link / Показать статус конкретного интерфейса
resolvectl statistics                    # Show resolver statistics / Показать статистику резолвера
resolvectl nss                           # Show NSS module info for resolved / Показать информацию NSS-модуля resolved
resolvectl compat                        # Show nss-compat state / Показать состояние совместимости nss
resolvectl --legend=no status            # Terse output without legend / Короткий вывод без легенды
```

### Cache Management / Управление кэшем
```bash
resolvectl flush-caches                  # Clear DNS cache / Очистить DNS-кэш
resolvectl reset-statistics              # Reset statistics counters / Сбросить счётчики статистики
resolvectl reset-server-features         # Forget probed DNS server features / Забыть обнаруженные возможности DNS-серверов
```

---

## DNS Queries

### Basic Queries / Базовые запросы
```bash
resolvectl query <DOMAIN>                # Resolve A/AAAA records / Разрешить A/AAAA для домена
resolvectl query -t <TYPE> <DOMAIN>      # Query specific RR type / Запросить конкретный тип записи
resolvectl query @<DNS_SERVER> <DOMAIN>  # Query via specific DNS server / Резолвить через указанный DNS-сервер
resolvectl query --search <HOSTNAME>     # Use search domains for short name / Использовать поисковые домены для короткого имени
```

### Query Options / Опции запросов
```bash
resolvectl -4 query <DOMAIN>             # IPv4-only resolution / Разрешать только по IPv4
resolvectl -6 query <DOMAIN>             # IPv6-only resolution / Разрешать только по IPv6
resolvectl -n query <DOMAIN>             # No-pager output / Вывод без пейджера
```

### Record Type Examples / Примеры типов записей
```bash
resolvectl query -t MX <DOMAIN>          # Query MX records / Запросить MX записи
resolvectl query -t TXT <DOMAIN>         # Query TXT records / Запросить TXT записи
resolvectl query -t AAAA <DOMAIN>        # Query IPv6 addresses / Запросить IPv6 адреса
resolvectl query -t SRV <SERVICE>        # Query SRV records / Запросить SRV записи
resolvectl query --class=CH -t TXT <DOMAIN>  # Custom class/type query / Кастомный класс/тип запроса
```

### Special Queries / Специальные запросы
```bash
resolvectl service <SERVICE_NAME>        # Resolve DNS-SD (SRV+TXT) / Разрешить сервис DNS-SD
resolvectl tlsa <TLS_SERVICE>            # Query TLSA (DANE) records / Запросить записи TLSA
resolvectl openpgp <DOMAIN>              # Query OPENPGPKEY record / Запросить OPENPGPKEY
```

### Examples / Примеры
```bash
# Query MX records / Запросить MX записи
resolvectl query -t MX example.com

# Use Cloudflare DNS / Использовать Cloudflare DNS
resolvectl query @1.1.1.1 example.com

# Query TLSA for HTTPS / Запросить TLSA для HTTPS
resolvectl tlsa _443._tcp.example.com

# Discover HTTPS service / Обнаружить HTTPS сервис
resolvectl service _https._tcp.example.com
```

---

## Link Configuration

### DNS Servers / DNS-серверы
```bash
resolvectl dns                           # List DNS servers per link / Список DNS-серверов по интерфейсам
resolvectl dns <INTERFACE> <DNS1> <DNS2>  # Set DNS servers for link / Установить DNS-серверы для интерфейса
resolvectl dns <INTERFACE> ""            # Clear DNS servers / Очистить DNS-серверы
```

### Search Domains / Поисковые домены
```bash
resolvectl domain                        # List per-link search domains / Показать поисковые домены по интерфейсам
resolvectl domain <INTERFACE> <DOMAIN>   # Set search domain / Задать поисковый домен
resolvectl domain <INTERFACE> ~<DOMAIN>  # Set routing-only domain / Задать только маршрутизируемый домен
resolvectl domain <INTERFACE> <DOMAIN> ~<INTERNAL>  # Set search & routing domains / Задать поисковые и маршрутизируемые домены
```

### Default Route / Маршрут по умолчанию
```bash
resolvectl default-route <INTERFACE> yes  # Mark link as default DNS route / Пометить интерфейс как дефолтный DNS-маршрут
resolvectl default-route <INTERFACE> no   # Unmark as default / Снять отметку дефолтного
```

### Revert Settings / Сброс настроек
```bash
resolvectl revert                        # Drop all runtime link settings / Сбросить все временные настройки интерфейсов
resolvectl revert <INTERFACE>            # Revert single link / Сбросить настройки для одного интерфейса
resolvectl reload                        # Reload resolved configuration / Перечитать конфигурацию resolved
```

---

## DNSSEC & DNS-over-TLS

### DNSSEC Configuration / Настройка DNSSEC
```bash
resolvectl dnssec <INTERFACE> yes        # Enable DNSSEC validation on link / Включить DNSSEC-валидацию для интерфейса
resolvectl dnssec <INTERFACE> allow-downgrade  # Opportunistic DNSSEC / Оппортунистический режим DNSSEC
resolvectl dnssec <INTERFACE> no         # Disable DNSSEC on link / Отключить DNSSEC для интерфейса
```

### Negative Trust Anchors / Отрицательные якоря доверия
```bash
resolvectl nta list                      # List Negative Trust Anchors / Показать список NTA
resolvectl nta add <DOMAIN>              # Add NTA (skip DNSSEC for zone) / Добавить NTA (пропуск DNSSEC для зоны)
resolvectl nta remove <DOMAIN>           # Remove NTA / Удалить NTA
```

### DNS-over-TLS / DNS-поверх-TLS
```bash
resolvectl dnsovertls <INTERFACE> opportunistic  # Enable DoT opportunistic / Включить DNS-over-TLS оппортунистически
resolvectl dnsovertls <INTERFACE> yes    # Force DNS-over-TLS / Принудительно использовать DoT
resolvectl dnsovertls <INTERFACE> no     # Disable DNS-over-TLS / Отключить DoT
```

---

## mDNS & LLMNR

### LLMNR Configuration / Настройка LLMNR
```bash
resolvectl llmnr <INTERFACE> yes         # Enable LLMNR on link / Включить LLMNR на интерфейсе
resolvectl llmnr <INTERFACE> no          # Disable LLMNR on link / Выключить LLMNR на интерфейсе
```

### Multicast DNS / Многоадресный DNS
```bash
resolvectl mdns <INTERFACE> yes          # Enable Multicast DNS on link / Включить mDNS на интерфейсе
resolvectl mdns <INTERFACE> no           # Disable Multicast DNS on link / Выключить mDNS на интерфейсе
```

### Local Network Queries / Запросы локальной сети
```bash
resolvectl query <HOSTNAME>.local        # Test mDNS/LLMNR host / Проверить резолвинг локального имени через mDNS/LLMNR
resolvectl query _workstation._tcp.local  # Discover LAN workstations / Обнаружить рабочие станции в локальной сети
resolvectl service _workstation._tcp.local  # Discover LAN services / Обнаружить сервисы в локальной сети
```

---

## Service Management

### systemd Service / Сервис systemd
```bash
systemctl status systemd-resolved        # Check resolver service state / Проверить состояние службы резолвера
sudo systemctl restart systemd-resolved  # Restart resolver service / Перезапустить службу резолвера
sudo systemctl enable systemd-resolved   # Enable on boot / Включить при загрузке
sudo systemctl disable systemd-resolved  # Disable on boot / Отключить при загрузке
```

### Configuration Files / Файлы конфигурации
```bash
sudoedit /etc/systemd/resolved.conf     # Edit persistent settings / Редактировать постоянные настройки resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf  # Use resolved-managed resolv.conf / Подключить управляемый resolved resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf  # Use stub resolver / Использовать заглушку резолвера
```

### Static Hosts / Статические хосты
```bash
resolvectl hosts                         # Show static hosts in memory / Показать загруженные статические записи hosts
```

---

## Real-World Examples

### Configure Custom DNS / Настроить пользовательский DNS
```bash
# Set Cloudflare DNS for eth0 / Установить Cloudflare DNS для eth0
sudo resolvectl dns eth0 1.1.1.1 1.0.0.1

# Set Google DNS for wlan0 / Установить Google DNS для wlan0
sudo resolvectl dns wlan0 8.8.8.8 8.8.4.4

# Set Quad9 DNS for eth0 / Установить Quad9 DNS для eth0
sudo resolvectl dns eth0 9.9.9.9 149.112.112.112
```

### VPN Split DNS / Разделённый DNS для VPN
```bash
# Route specific domain through VPN / Маршрутизировать конкретный домен через VPN
sudo resolvectl dns tun0 <VPN_DNS>
sudo resolvectl domain tun0 ~<INTERNAL_DOMAIN>

# Example: corporate VPN / Пример: корпоративный VPN
sudo resolvectl dns tun0 10.0.0.1
sudo resolvectl domain tun0 ~corp.example.com
```

### Enable DNSSEC / Включить DNSSEC
```bash
# Enable DNSSEC validation / Включить валидацию DNSSEC
sudo resolvectl dnssec eth0 yes

# Enable opportunistic DNSSEC / Включить оппортунистический DNSSEC
sudo resolvectl dnssec eth0 allow-downgrade

# Add negative trust anchor for local domain / Добавить NTA для локального домена
sudo resolvectl nta add example.local
```

### DNS-over-TLS Setup / Настройка DNS-over-TLS
```bash
# Enable opportunistic DoT / Включить оппортунистический DoT
sudo resolvectl dnsovertls eth0 opportunistic

# Force DoT / Принудительный DoT
sudo resolvectl dnsovertls eth0 yes

# Configure Cloudflare DoT / Настроить Cloudflare DoT
sudoedit /etc/systemd/resolved.conf
# Add: DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
sudo systemctl restart systemd-resolved
```

### Troubleshooting DNS / Устранение проблем DNS
```bash
# Check current DNS status / Проверить текущий статус DNS
resolvectl status | grep -A4 'Link'

# Flush DNS cache / Очистить DNS-кэш
sudo resolvectl flush-caches

# Test resolution / Тестировать разрешение
resolvectl query example.com

# Check which DNS server is used / Проверить какой DNS-сервер используется
resolvectl query -t A example.com
```

### Local Network Discovery / Обнаружение локальной сети
```bash
# Enable mDNS for local discovery / Включить mDNS для локального обнаружения
sudo resolvectl mdns eth0 yes

# Query local host / Запросить локальный хост
resolvectl query myhost.local

# Discover printers / Обнаружить принтеры
resolvectl query _ipp._tcp.local
```

---

## Reference Tables

### Configuration Files / Файлы конфигурации

| File | Description (EN / RU) |
| :--- | :--- |
| `/etc/systemd/resolved.conf` | Main configuration / Основная конфигурация |
| `/run/systemd/resolve/resolv.conf` | Managed resolv.conf / Управляемый resolv.conf |
| `/run/systemd/resolve/stub-resolv.conf` | Stub resolver / Заглушка резолвера |
| `/etc/resolv.conf` | System resolver config / Системная конфигурация резолвера |

### Common DNS Servers / Распространённые DNS-серверы

| Provider | Primary | Secondary |
| :--- | :--- | :--- |
| **Cloudflare** | 1.1.1.1 | 1.0.0.1 |
| **Google** | 8.8.8.8 | 8.8.4.4 |
| **Quad9** | 9.9.9.9 | 149.112.112.112 |
| **OpenDNS** | 208.67.222.222 | 208.67.220.220 |

> [!TIP]
> Use DNS-over-TLS for privacy. Enable DNSSEC in `allow-downgrade` mode for compatibility. Use split DNS for VPN connections. Disable mDNS/LLMNR on untrusted networks. / Используйте DoT для приватности. Включайте DNSSEC в режиме `allow-downgrade` для совместимости. Отключайте mDNS/LLMNR в недоверенных сетях.
