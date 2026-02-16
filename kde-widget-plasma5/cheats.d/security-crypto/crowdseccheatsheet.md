Title: CrowdSec Cheatsheet
Group: Security & Crypto
Icon: 🔐
Order: 1

## Table of Contents
- [General](#general--основное)
- [Service Basics](#service-basics-linux-units--сервисы-для-справки)
- [LAPI & CAPI](#lapi--capi--локальное-api-и-центральное-api)
- [Console Integration](#console--веб-консоль-crowdsec-appcrowdsecnet)
- [Hub Management](#hub-management--управление-hub-коллекции-парсеры-сценарии)
- [Machines](#machines-lapi-db--машины-агенты-управляются-на-lapi)
- [Bouncers](#bouncers--баунсеры-файрвол-nginx-caddy-и-тд)
- [Decisions](#decisions-bancaptcha--решения-блокировкикапча)
- [Alerts](#alerts-detections--алерты-сработки)
- [Hub Items by Type](#hub-items-by-type--по-типам-пакетов-hub)
- [Metrics & Diagnostics](#metrics--diag--метрики-и-диагностика)
- [Docker Usage](#docker-usage--использование-в-docker)
- [Firewall Bouncer](#firewall-bouncer-notes--заметки-по-файрвол-баунсеру)
- [Windows Example](#windows-пример--windows-example)
- [Handy One-Liners](#handy-one-liners--полезные-однострочники)
- [Troubleshooting](#troubleshooting-tips--советы-по-отладке)

---

#==============================================================================
# GENERAL / ОСНОВНОЕ
#==============================================================================

cscli version                               # Show version / Показать версию. :contentReference[oaicite:0]{index=0}
cscli -h                                    # Show global help / Общая справка
cscli -o json <subcommand>                  # JSON output / Вывод в JSON (удобно для скриптов). :contentReference[oaicite:1]{index=1}
cscli --info|--debug|--trace <cmd>          # Verbose logs / Подробные логи. :contentReference[oaicite:2]{index=2}

#==============================================================================
# SERVICE BASICS (Linux units) / СЕРВИСЫ (для справки)
#==============================================================================

sudo systemctl status crowdsec               # Engine status / Статус движка CrowdSec
sudo systemctl status crowdsec-firewall-bouncer  # Bouncer status / Статус файрвол-баунсера
sudo journalctl -u crowdsec -e               # Tail logs / Хвост логов движка
sudo journalctl -u crowdsec-firewall-bouncer -e  # Tail bouncer logs / Хвост логов баунсера

#==============================================================================
# LAPI & CAPI / ЛОКАЛЬНОЕ API И ЦЕНТРАЛЬНОЕ API
#==============================================================================

cscli lapi status                           # Check auth to Local API (LAPI) / Проверить авторизацию к LAPI. :contentReference[oaicite:3]{index=3}
sudo cscli lapi register -u http://LAPI:8080  # Register this machine to remote LAPI / Регистрация агента на удалённом LAPI. :contentReference[oaicite:4]{index=4}
cscli capi status                           # Check Central API link / Проверить связь с Central API (CAPI). :contentReference[oaicite:5]{index=5}
cscli capi register                         # Register to Central API / Регистрация в Central API (получить токены). :contentReference[oaicite:6]{index=6}

# Полезные примеры:
sudo cscli lapi register -u http://10.0.0.1:8080 --machine web-01   # Name machine / С именем ноды. :contentReference[oaicite:7]{index=7}
cscli capi status -o json                    # JSON status / Статус в JSON. :contentReference[oaicite:8]{index=8}

#==============================================================================
# CONSOLE / ВЕБ-КОНСОЛЬ CrowdSec (app.crowdsec.net)
#==============================================================================

cscli console enroll                        # Enroll instance to Console / Привязать инстанс к консоли (локально на LAPI). :contentReference[oaicite:9]{index=9}
cscli console enable context                # Enable context export / Включить экспорт контекстов в консоль. :contentReference[oaicite:10]{index=10}
cscli console status                        # Show console integration status / Проверить статус интеграции консоли. :contentReference[oaicite:11]{index=11}

#==============================================================================
# HUB MANAGEMENT / УПРАВЛЕНИЕ HUB (коллекции, парсеры, сценарии)
#==============================================================================

cscli hub list                              # List available/installed items / Список доступных и установленных пакетов. :contentReference[oaicite:12]{index=12}
sudo cscli hub update                       # Refresh hub index / Обновить индекс HUB. :contentReference[oaicite:13]{index=13}
sudo cscli hub upgrade                      # Upgrade installed items / Обновить установленные пакеты. :contentReference[oaicite:14]{index=14}

# Установка/удаление:
sudo cscli collections install crowdsecurity/linux       # Install collection / Установка коллекции. :contentReference[oaicite:15]{index=15}
sudo cscli scenarios install crowdsecurity/ssh-bf        # Install scenario / Установка сценария брутфорса SSH. :contentReference[oaicite:16]{index=16}
sudo cscli parsers install crowdsecurity/nginx           # Install parser / Установка парсера Nginx. :contentReference[oaicite:17]{index=17}
sudo cscli postoverflows install crowdsecurity/grok-geoip # Install postoverflow / Постобработка. :contentReference[oaicite:18]{index=18}
sudo cscli collections remove crowdsecurity/linux        # Remove collection / Удалить коллекцию. :contentReference[oaicite:19]{index=19}

#==============================================================================
# MACHINES (LAPI DB) / МАШИНЫ (агенты), управляются на LAPI
#==============================================================================

cscli machines list                          # List machines / Список машин (агентов). :contentReference[oaicite:20]{index=20}
sudo cscli machines add my-agent -f -        # Create machine creds to stdout / Создать креды агента в stdout (для копирования). :contentReference[oaicite:21]{index=21}
sudo cscli machines validate my-agent        # Validate machine / Подтвердить агента. :contentReference[oaicite:22]{index=22}
sudo cscli machines delete my-agent          # Delete machine / Удалить агента. :contentReference[oaicite:23]{index=23}

#==============================================================================
# BOUNCERS / БАУНСЕРЫ (файрвол, nginx, caddy, и т.д.)
#==============================================================================

cscli bouncers list                         # List bouncers / Список баунсеров. :contentReference[oaicite:24]{index=24}
sudo cscli bouncers add fw-bouncer          # Create API key / Создать ключ для баунсера. :contentReference[oaicite:25]{index=25}
sudo cscli bouncers delete fw-bouncer       # Remove bouncer / Удалить баунсер. :contentReference[oaicite:26]{index=26}

# Примеры и заметки:
sudo cscli bouncers add myfw --key <KEY>    # Use custom key / Задать свой ключ. :contentReference[oaicite:27]{index=27}
sudo systemctl enable --now crowdsec-firewall-bouncer   # Enable/start bouncer / Включить и запустить баунсер. :contentReference[oaicite:28]{index=28}

#==============================================================================
# DECISIONS (ban/captcha) / РЕШЕНИЯ (блокировки/капча)
#==============================================================================

cscli decisions list                         # List active decisions / Список активных решений. :contentReference[oaicite:29]{index=29}
cscli decisions add --ip 1.2.3.4             # Ban one IP / Забанить IP. :contentReference[oaicite:30]{index=30}
cscli decisions add --range 1.2.3.0/24       # Ban CIDR / Забанить подсеть. :contentReference[oaicite:31]{index=31}
cscli decisions add --ip 1.2.3.4 --duration 24h --type captcha  # Temporary captcha / Временная «капча». :contentReference[oaicite:32]{index=32}
cscli decisions add --scope username --value alice      # Scope=username / Бан по «username». :contentReference[oaicite:33]{index=33}
cscli decisions delete --ip 1.2.3.4          # Delete decisions for IP / Снять бан с IP. :contentReference[oaicite:34]{index=34}
cscli decisions import -f decisions.json     # Import from file / Импорт решений из файла/pipe. :contentReference[oaicite:35]{index=35}

# Частые фильтры:
cscli decisions list --origin cscli          # Show manual bans / Только ручные баны. :contentReference[oaicite:36]{index=36}
cscli decisions list -i 1.2.3.4              # Filter by IP / Фильтр по IP. :contentReference[oaicite:37]{index=37}
cscli decisions list --type ban --since 24h  # Recent bans / Баны за последние 24 часа. :contentReference[oaicite:38]{index=38}

#==============================================================================
# ALERTS (detections) / АЛЕРТЫ (сработки)
#==============================================================================

cscli alerts list                            # List alerts / Список алертов. :contentReference[oaicite:39]{index=39}
cscli alerts list --since 24h --type ban     # Alerts in last 24h / Алерты за 24 часа. :contentReference[oaicite:40]{index=40}
cscli alerts list -i 1.2.3.4                 # Alerts for IP / Алерты по IP. :contentReference[oaicite:41]{index=41}
cscli alerts inspect -a <ALERT_ID>           # Inspect alert / Подробно об алерте. :contentReference[oaicite:42]{index=42}
sudo cscli alerts flush                      # Flush all alerts (local only) / Сбросить алерты (локально). :contentReference[oaicite:43]{index=43}
sudo cscli alerts delete -a <ALERT_ID>       # Delete one alert (local) / Удалить конкретный алерт (локально). :contentReference[oaicite:44]{index=44}

#==============================================================================
# HUB ITEMS BY TYPE / ПО ТИПАМ ПАКЕТОВ HUB
#==============================================================================

cscli collections list                       # List collections / Список коллекций. :contentReference[oaicite:45]{index=45}
cscli parsers list                           # List parsers / Список парсеров. :contentReference[oaicite:46]{index=46}
cscli scenarios list                         # List scenarios / Список сценариев. :contentReference[oaicite:47]{index=47}
cscli postoverflows list                     # List postoverflows / Список пост-процессоров. :contentReference[oaicite:48]{index=48}

# Установка конкретных версий/веток:
sudo cscli scenarios install crowdsecurity/ssh-bf@<version>  # Install specific version / Установить версию. :contentReference[oaicite:49]{index=49}

#==============================================================================
# METRICS & DIAG / МЕТРИКИ И ДИАГНОСТИКА
#==============================================================================

cscli metrics                                # Show engine metrics / Показать метрики движка (парсеры/сценарии).
cscli explain --log <file>                   # Explain parsing/detection / Объяснить разбор логов (почему сработало/нет).
cscli config show                            # Show running config / Текущая конфигурация.
cscli hubtest run                            # Test hub items against samples / Тест парсеров/сценариев по образцам.

#==============================================================================
# DOCKER USAGE / ИСПОЛЬЗОВАНИЕ В DOCKER
#==============================================================================

docker exec crowdsec cscli metrics           # Run cscli in container / Вызов cscli внутри контейнера. :contentReference[oaicite:50]{index=50}
docker exec -it crowdsec /bin/bash           # Attach shell then use cscli / Зайти в контейнер и работать cscli. :contentReference[oaicite:51]{index=51}
docker exec crowdsec cscli decisions add -i 1.2.3.4 -d 2m  # Quick test ban / Тестовый бан из Docker. :contentReference[oaicite:52]{index=52}

#==============================================================================
# FIREWALL BOUNCER NOTES / ЗАМЕТКИ ПО ФАЙРВОЛ-БАУНСЕРУ
#==============================================================================

# Автоустановка обычно сама вызывает 'cscli bouncers add'.
# Конфиг по умолчанию: /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
# После настройки — запустить сервис:
sudo systemctl enable --now crowdsec-firewall-bouncer   # Start bouncer / Запуск баунсера. :contentReference[oaicite:53]{index=53}

#==============================================================================
# WINDOWS (пример) / WINDOWS EXAMPLE
#==============================================================================

cscli.exe bouncers add windows-firewall-bouncer  # Create key for Windows bouncer / Ключ для Windows-баунсера. :contentReference[oaicite:54]{index=54}

#==============================================================================
# HANDY ONE-LINERS / ПОЛЕЗНЫЕ ОДНОСТРОЧНИКИ
#==============================================================================

# Забанить все IP из файла (по одному в строке):
while read ip; do cscli decisions add --ip "$ip" --duration 24h; done < bad_ips.txt  # Mass ban / Массовый бан (осторожно!)

# Снять бан со всех IP из файла:
while read ip; do cscli decisions delete --ip "$ip"; done < unban_ips.txt            # Mass unban / Массовое снятие бана

# Посмотреть ТОП источников за 24 часа:
cscli alerts list --since 24h -o json | jq -r '.[].source.ip' | sort | uniq -c | sort -nr | head  # Top sources / Топ источников

# Список активных решений с таймингом истечения:
cscli decisions list -o json | jq -r '.[] | "\(.value)\t\(.type)\t\(.until)"'       # Show value/type/until / Вывод значения/типа/когда истекает

# Проверить связность компонентов быстро:
cscli lapi status && cscli capi status && cscli bouncers list                       # Quick health / Быстрая проверка. :contentReference[oaicite:55]{index=55}

#==============================================================================
# TROUBLESHOOTING TIPS / СОВЕТЫ ПО ОТЛАДКЕ
#==============================================================================

# 1) LAPI недоступно: проверь порт/файрвол и URL регистрации:
#    "failed to connect to LAPI ..." → проверьте 127.0.0.1:8088 или адрес LAPI. :contentReference[oaicite:56]{index=56}
# 2) После 'cscli lapi register' агент ожидает валидации на LAPI (machines validate). :contentReference[oaicite:57]{index=57}
# 3) 'capi register' — создаёт/обновляет креды онлайн-API; после — проверьте 'capi status'. :contentReference[oaicite:58]{index=58}
# 4) Блокировки не применяются? Убедитесь, что установлен и запущен соответствующий bouncer (firewall/nginx/... ). :contentReference[oaicite:59]{index=59}
# 5) Hub не обновляется (permissions): проверьте права каталога hub (часто встречается на OPNsense). :contentReference[oaicite:60]{index=60}


