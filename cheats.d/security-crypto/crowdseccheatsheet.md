Title: 🛡️ CrowdSec — Intrusion Prevention
Group: Security & Crypto
Icon: 🛡️
Order: 1

# CrowdSec Sysadmin Cheatsheet

> **Context:** CrowdSec is a modern, open-source, collaborative intrusion prevention system (IPS). It analyzes logs, detects attacks using community-driven scenarios, and applies remediation via bouncers (firewalls, Nginx, etc.). It features a crowd-sourced threat intelligence network — blocked IPs are shared across the community. / CrowdSec — современная open-source коллаборативная система предотвращения вторжений (IPS). Анализирует логи, обнаруживает атаки с помощью сценариев и применяет блокировки через баунсеры. Заблокированные IP делятся между сообществом.
> **Role:** Security Engineer / Sysadmin
> **Default Port:** `8080` (LAPI)
> **Version:** CrowdSec 1.x

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Troubleshooting & Tools](#5-troubleshooting--tools)
6. [Logrotate Configuration](#6-logrotate-configuration)
7. [Documentation Links](#7-documentation-links)

---

## 1. Installation & Configuration

### Install CrowdSec / Установка CrowdSec

```bash
# Add repository and install / Добавить репозиторий и установить
curl -s https://install.crowdsec.net | sudo sh  # Add repo / Добавить репозиторий
sudo apt install -y crowdsec                    # Install CrowdSec / Установить CrowdSec

# Install firewall bouncer / Установить файрвол-баунсер
sudo apt install -y crowdsec-firewall-bouncer-iptables  # iptables bouncer / iptables-баунсер

# RHEL/CentOS/Fedora
sudo dnf install crowdsec
sudo dnf install crowdsec-firewall-bouncer-iptables
```

### Core Commands / Основные команды

```bash
cscli version                               # Show version / Показать версию
cscli -h                                    # Show global help / Общая справка
cscli -o json <subcommand>                  # JSON output / Вывод в JSON (удобно для скриптов)
cscli --info|--debug|--trace <cmd>          # Verbose logs / Подробные логи
```

### Default Paths / Пути по умолчанию

| Path | Description (EN / RU) |
|------|----------------------|
| `/etc/crowdsec/` | Main config directory / Основная директория конфигурации |
| `/etc/crowdsec/config.yaml` | Main config / Основной конфиг |
| `/etc/crowdsec/bouncers/` | Bouncer configs / Конфиги баунсеров |
| `/var/lib/crowdsec/data/` | Data directory / Директория данных |
| `/var/log/crowdsec.log` | Engine log / Лог движка |

---

## 2. Core Management

### Service Control / Управление сервисами

```bash
sudo systemctl status crowdsec               # Engine status / Статус движка CrowdSec
sudo systemctl start crowdsec                # Start engine / Запустить движок
sudo systemctl stop crowdsec                 # Stop engine / Остановить движок
sudo systemctl restart crowdsec              # Restart engine / Перезапустить движок
sudo systemctl status crowdsec-firewall-bouncer  # Bouncer status / Статус файрвол-баунсера
```

### Logs / Логи

```bash
sudo journalctl -u crowdsec -e               # Tail engine logs / Хвост логов движка
sudo journalctl -u crowdsec-firewall-bouncer -e  # Tail bouncer logs / Хвост логов баунсера
sudo journalctl -u crowdsec -f               # Follow engine logs / Следить за логами движка
```

### LAPI & CAPI / Локальное и Центральное API

#### Local API (LAPI) / Локальное API

```bash
cscli lapi status                           # Check auth to LAPI / Проверить авторизацию к LAPI
sudo cscli lapi register -u http://<LAPI_HOST>:8080  # Register to remote LAPI / Регистрация на удалённом LAPI
sudo cscli lapi register -u http://<IP>:8080 --machine web-01  # Register with name / С именем ноды
```

#### Central API (CAPI) / Центральное API

```bash
cscli capi status                           # Check Central API link / Проверить связь с CAPI
cscli capi register                         # Register to Central API / Регистрация в Central API
cscli capi status -o json                   # JSON status / Статус в JSON
```

> [!NOTE]
> LAPI listens on port `8080` by default. CAPI connects to CrowdSec's cloud service at `api.crowdsec.net`.
> LAPI слушает на порту `8080` по умолчанию. CAPI подключается к облачному сервису CrowdSec на `api.crowdsec.net`.

### Console Integration / Веб-консоль

```bash
cscli console enroll                        # Enroll instance to Console / Привязать инстанс к консоли
cscli console enable context                # Enable context export / Включить экспорт контекстов
cscli console status                        # Show integration status / Проверить статус интеграции
```

### Hub Management / Операции с Hub

```bash
cscli hub list                              # List available/installed items / Список доступных и установленных пакетов
sudo cscli hub update                       # Refresh hub index / Обновить индекс Hub
sudo cscli hub upgrade                      # Upgrade installed items / Обновить установленные пакеты
```

#### Install / Remove / Установка / Удаление

```bash
sudo cscli collections install crowdsecurity/linux       # Install collection / Установка коллекции
sudo cscli scenarios install crowdsecurity/ssh-bf        # Install scenario / Установка сценария брутфорса SSH
sudo cscli parsers install crowdsecurity/nginx           # Install parser / Установка парсера Nginx
sudo cscli postoverflows install crowdsecurity/grok-geoip # Install postoverflow / Постобработка
sudo cscli collections remove crowdsecurity/linux        # Remove collection / Удалить коллекцию
```

### Machines / Управление машинами

```bash
cscli machines list                          # List machines / Список машин (агентов)
sudo cscli machines add my-agent -f -        # Create machine creds to stdout / Создать креды агента в stdout
sudo cscli machines validate my-agent        # Validate machine / Подтвердить агента
sudo cscli machines delete my-agent          # Delete machine / Удалить агента
```

### Bouncers / Управление баунсерами

```bash
cscli bouncers list                         # List bouncers / Список баунсеров
sudo cscli bouncers add fw-bouncer          # Create API key / Создать ключ для баунсера
sudo cscli bouncers delete fw-bouncer       # Remove bouncer / Удалить баунсер
sudo cscli bouncers add myfw --key <SECRET_KEY>  # Use custom key / Задать свой ключ
sudo systemctl enable --now crowdsec-firewall-bouncer  # Enable/start bouncer / Включить и запустить баунсер
```

---

## 3. Sysadmin Operations

### Decision Management (ban/captcha) / Управление решениями

```bash
cscli decisions list                         # List active decisions / Список активных решений
cscli decisions add --ip <IP>                # Ban one IP / Забанить IP
cscli decisions add --range <IP>/24          # Ban CIDR / Забанить подсеть
cscli decisions add --ip <IP> --duration 24h --type captcha  # Temporary captcha / Временная капча
cscli decisions add --scope username --value <USER>  # Ban by username / Бан по username
cscli decisions delete --ip <IP>             # Delete decisions for IP / Снять бан с IP
cscli decisions import -f decisions.json     # Import from file / Импорт решений из файла
```

> [!CAUTION]
> Be careful with `decisions add` — banning wrong IPs can lock out legitimate users or even yourself!
> Будьте осторожны с `decisions add` — блокировка неверных IP может заблокировать легитимных пользователей или даже вас!

#### Decision Filters / Фильтры решений

```bash
cscli decisions list --origin cscli          # Show manual bans / Только ручные баны
cscli decisions list -i <IP>                 # Filter by IP / Фильтр по IP
cscli decisions list --type ban --since 24h  # Recent bans / Баны за последние 24 часа
```

### Alert Management / Управление алертами

```bash
cscli alerts list                            # List alerts / Список алертов
cscli alerts list --since 24h --type ban     # Alerts in last 24h / Алерты за 24 часа
cscli alerts list -i <IP>                    # Alerts for IP / Алерты по IP
cscli alerts inspect -a <ALERT_ID>           # Inspect alert / Подробно об алерте
sudo cscli alerts flush                      # Flush all alerts (local only) / Сбросить алерты (локально)
sudo cscli alerts delete -a <ALERT_ID>       # Delete one alert / Удалить конкретный алерт
```

> [!WARNING]
> `cscli alerts flush` removes all local alert history. Use with caution in production.
> `cscli alerts flush` удаляет всю локальную историю алертов. Используйте осторожно в продакшене.

### Hub Items by Type / Списки по типам

```bash
cscli collections list                       # List collections / Список коллекций
cscli parsers list                           # List parsers / Список парсеров
cscli scenarios list                         # List scenarios / Список сценариев
cscli postoverflows list                     # List postoverflows / Список пост-процессоров
```

#### Version Pinning / Закрепление версий

```bash
sudo cscli scenarios install crowdsecurity/ssh-bf@<VERSION>  # Install specific version / Установить конкретную версию
```

### Monitoring / Мониторинг

```bash
cscli metrics                                # Show engine metrics / Показать метрики движка
cscli explain --log <FILE>                   # Explain parsing/detection / Объяснить разбор логов
cscli config show                            # Show running config / Текущая конфигурация
cscli hubtest run                            # Test hub items against samples / Тест парсеров/сценариев
```

### Docker Usage / Использование в Docker

```bash
docker exec crowdsec cscli metrics           # Run cscli in container / Вызов cscli внутри контейнера
docker exec -it crowdsec /bin/bash           # Attach shell / Зайти в контейнер
docker exec crowdsec cscli decisions add -i <IP> -d 2m  # Quick test ban / Тестовый бан из Docker
```

### Firewall Bouncer / Файрвол-баунсер

#### Configuration / Конфигурация

`/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`

```bash
# Auto-install usually calls 'cscli bouncers add' / Автоустановка обычно вызывает 'cscli bouncers add'
# After configuration — start the service / После настройки — запустить сервис:
sudo systemctl enable --now crowdsec-firewall-bouncer  # Start bouncer / Запуск баунсера
sudo systemctl status crowdsec-firewall-bouncer        # Check status / Проверить статус
```

### Windows Usage / Windows-баунсер

```bash
cscli.exe bouncers add windows-firewall-bouncer  # Create key for Windows bouncer / Ключ для Windows-баунсера
```

### Handy One-Liners / Полезные однострочники

#### Mass Operations / Массовые операции

```bash
# Ban all IPs from file (one per line) / Забанить все IP из файла (по одному в строке):
while read ip; do cscli decisions add --ip "$ip" --duration 24h; done < bad_ips.txt

# Unban all IPs from file / Снять бан со всех IP из файла:
while read ip; do cscli decisions delete --ip "$ip"; done < unban_ips.txt
```

> [!CAUTION]
> Mass ban operations can lock out legitimate traffic. Always verify the IP list before executing.
> Массовые операции бана могут заблокировать легитимный трафик. Всегда проверяйте список IP перед выполнением.

#### Analytics / Аналитика

```bash
# Top sources in last 24h / ТОП источников за 24 часа:
cscli alerts list --since 24h -o json | jq -r '.[].source.ip' | sort | uniq -c | sort -nr | head

# Show decisions with expiration / Список решений с таймингом истечения:
cscli decisions list -o json | jq -r '.[] | "\(.value)\t\(.type)\t\(.until)"'
```

#### Health Check / Быстрая проверка

```bash
# Quick connectivity check / Быстрая проверка связности:
cscli lapi status && cscli capi status && cscli bouncers list
```

---

## 4. Security

### CrowdSec Architecture Comparison / Сравнение архитектуры CrowdSec

| Component | Description (EN) | Description (RU) | Purpose |
|-----------|-----------------|-------------------|---------|
| **Agent** | Log parser & scenario engine | Парсер логов и движок сценариев | Detect attacks / Обнаружение атак |
| **LAPI** | Local API server | Локальный API-сервер | Store decisions locally / Хранение решений |
| **CAPI** | Central API (cloud) | Центральное API (облако) | Community threat sharing / Обмен угрозами |
| **Bouncer** | Remediation component | Компонент блокировки | Apply bans / Применение блокировок |

### Bouncer Types / Типы баунсеров

| Bouncer Type | Description (EN / RU) | Use Case |
|-------------|------------------------|----------|
| `firewall-bouncer` | iptables/nftables blocking / Блокировка через iptables/nftables | Network-level protection / Сетевая защита |
| `nginx-bouncer` | Nginx integration / Интеграция с Nginx | Web application protection / Защита веб-приложений |
| `traefik-bouncer` | Traefik plugin / Плагин Traefik | Reverse proxy protection / Защита reverse proxy |
| `custom-bouncer` | Custom remediation / Пользовательская блокировка | Specific use cases / Специальные случаи |

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

1. **LAPI unavailable / LAPI недоступно:**
   - Check port/firewall and registration URL / Проверьте порт/файрвол и URL регистрации
   - `"failed to connect to LAPI ..."` → check `127.0.0.1:8080` or LAPI address / проверьте адрес LAPI

2. **Machine pending validation / Машина ожидает валидации:**
   - After `cscli lapi register`, validate on LAPI side with `cscli machines validate` / Подтвердите на стороне LAPI

3. **CAPI registration / Регистрация CAPI:**
   - `cscli capi register` creates/updates online API creds / создаёт/обновляет креды
   - Verify with `cscli capi status` / Проверьте статус

4. **Decisions not applied / Блокировки не применяются:**
   - Ensure the appropriate bouncer is installed and running / Убедитесь что установлен и запущен баунсер
   - Check with `systemctl status crowdsec-firewall-bouncer`

5. **Hub update fails (permissions) / Hub не обновляется (права):**
   - Check hub directory permissions / Проверьте права каталога hub
   - Common on OPNsense / Часто встречается на OPNsense

### Diagnostic Commands / Команды диагностики

```bash
cscli metrics                                # Engine metrics / Метрики движка
cscli config show                            # Running config / Текущая конфигурация
sudo journalctl -u crowdsec -e               # Engine logs / Логи движка
sudo journalctl -u crowdsec-firewall-bouncer -e  # Bouncer logs / Логи баунсера
```

---

## 6. Logrotate Configuration

`/etc/logrotate.d/crowdsec`

```conf
/var/log/crowdsec.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    postrotate
        systemctl reload crowdsec 2>/dev/null || true
    endscript
}
```

---

## 7. Documentation Links

- [CrowdSec Official Documentation](https://docs.crowdsec.net/)
- [CrowdSec Hub (Parsers, Scenarios, Collections)](https://hub.crowdsec.net/)
- [CrowdSec GitHub Repository](https://github.com/crowdsecurity/crowdsec)
- [CrowdSec Console (Web UI)](https://app.crowdsec.net/)
- [Firewall Bouncer Documentation](https://docs.crowdsec.net/docs/bouncers/firewall/)
- [CrowdSec Blog](https://www.crowdsec.net/blog)
- [CrowdSec Community Discord](https://discord.gg/crowdsec)

---
