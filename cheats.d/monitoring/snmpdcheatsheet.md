Title: 📡 SNMPD
Group: Monitoring
Icon: 📡
Order: 4

# SNMPD (Net-SNMP Agent) Sysadmin Cheatsheet

> **SNMPD** (Net-SNMP Agent) is the SNMP daemon from the Net-SNMP suite. SNMP (Simple Network Management Protocol) was first defined in RFC 1157 (1990) and has been a foundational protocol for network monitoring ever since. The snmpd agent exposes system metrics via a standardized MIB tree, allowing remote monitoring by NMS platforms.
>
> **Common use cases / Типичные сценарии:** Network device monitoring (routers, switches, firewalls), server system metrics collection (CPU, memory, disk, interfaces), integration with NMS platforms (Zabbix, Nagios, LibreNMS, Checkmk, Cacti), hardware monitoring (IPMI via SNMP), printer/UPS monitoring.
>
> **Status / Статус:** SNMP is a mature, well-established standard. Net-SNMP is actively maintained. While SNMP remains essential for network devices, modern server monitoring often uses agent-based solutions (**Zabbix Agent**, **node_exporter**, **Telegraf**) for richer metrics. SNMP is still the primary protocol for monitoring network infrastructure.
>
> **Default ports / Порты по умолчанию:** `161/udp` (agent queries), `162/udp` (trap receiver)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Troubleshooting & Tools](#5-troubleshooting--tools)
6. [Logrotate Configuration](#6-logrotate-configuration)

---

## 1. Installation & Configuration

### Install SNMPD / Установка SNMPD

```bash
# RHEL/CentOS/AlmaLinux
dnf install net-snmp net-snmp-utils net-snmp-libs

# Debian/Ubuntu
apt install snmpd snmp libsnmp-dev snmp-mibs-downloader

# openSUSE
zypper install net-snmp
```

### Main Configuration / Основная конфигурация

`/etc/snmp/snmpd.conf`

```ini
# System information / Информация о системе
sysLocation    "Server Room, <LOCATION>"
sysContact     "<USER> <admin@example.com>"
sysName        <HOST>

# SNMPv2c community string (read-only) / Строка сообщества SNMPv2c (только чтение)
rocommunity  <COMMUNITY_STRING>  <ALLOWED_NETWORK>/24
# Example: rocommunity public 10.0.0.0/24

# SNMPv2c community string (read-write) / Строка сообщества SNMPv2c (чтение-запись)
# rwcommunity <COMMUNITY_STRING> <ALLOWED_NETWORK>/24

# Listen address / Адрес прослушивания
agentAddress  udp:<IP>:161,udp6:[::1]:161

# Disk monitoring / Мониторинг дисков
disk / 10%
disk /var 10%
disk /tmp 10%

# Load average thresholds / Пороги средней нагрузки
load 12 10 5

# Process monitoring / Мониторинг процессов
proc sshd
proc nginx
proc mysqld

# Extend with custom script / Расширение через скрипт
extend custom_metric /usr/local/bin/custom_snmp_check.sh
```

### SNMP Protocol Versions Comparison / Сравнение версий SNMP

| Feature | SNMPv1 | SNMPv2c | SNMPv3 |
|---------|--------|---------|--------|
| Authentication / Авторизация | Community string | Community string | Username/Password |
| Encryption / Шифрование | None / Нет | None / Нет | DES, AES |
| Security Level / Безопасность | Low / Низкий | Low / Низкий | High / Высокий |
| 64-bit Counters / 64-бит счётчики | No / Нет | Yes / Да | Yes / Да |
| Use Case / Применение | Legacy / Устаревшие системы | Most common / Самый распространённый | Production / Продакшн |

> [!WARNING]
> SNMPv1/v2c community strings are sent in plaintext. Always use SNMPv3 in production environments. / Строки сообщества SNMPv1/v2c передаются в открытом виде. Всегда используйте SNMPv3 в продакшн.

### SNMPv3 User Setup / Настройка пользователя SNMPv3

```bash
# Stop the agent first / Сначала остановить агент
systemctl stop snmpd

# Create SNMPv3 user / Создать пользователя SNMPv3
net-snmp-create-v3-user -ro -a SHA -A <AUTH_PASSWORD> -x AES -X <PRIV_PASSWORD> <USER>

# Start the agent / Запустить агент
systemctl start snmpd
```

`/etc/snmp/snmpd.conf` (SNMPv3 config):

```ini
# SNMPv3 read-only user / Пользователь SNMPv3 только для чтения
rouser <USER> priv
```

---

## 2. Core Management

### SNMP Query Commands / Команды запросов SNMP

```bash
# Walk entire OID tree (SNMPv2c) / Обход всего дерева OID
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> .1

# Get specific OID / Получить конкретный OID
snmpget -v2c -c <COMMUNITY_STRING> <HOST> sysDescr.0

# Walk system subtree / Обход поддерева system
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> system

# Walk interfaces / Обход интерфейсов
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> ifDescr

# Get uptime / Получить uptime
snmpget -v2c -c <COMMUNITY_STRING> <HOST> sysUpTime.0

# Walk disk usage / Обход использования дисков
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> hrStorageDescr
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> hrStorageUsed

# Walk CPU load / Обход загрузки CPU
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> laLoad

# SNMPv3 query / Запрос SNMPv3
snmpwalk -v3 -u <USER> -l authPriv -a SHA -A <AUTH_PASSWORD> -x AES -X <PRIV_PASSWORD> <HOST> system
```

### Common OIDs / Общие OID

| OID | Name | Description / Описание |
|-----|------|------------------------|
| `.1.3.6.1.2.1.1.1.0` | sysDescr | System description / Описание системы |
| `.1.3.6.1.2.1.1.3.0` | sysUpTime | Uptime / Время работы |
| `.1.3.6.1.2.1.1.5.0` | sysName | Hostname / Имя хоста |
| `.1.3.6.1.2.1.2.2.1.2` | ifDescr | Interface names / Имена интерфейсов |
| `.1.3.6.1.2.1.2.2.1.10` | ifInOctets | Incoming bytes / Входящие байты |
| `.1.3.6.1.2.1.2.2.1.16` | ifOutOctets | Outgoing bytes / Исходящие байты |
| `.1.3.6.1.4.1.2021.10.1.3` | laLoad | Load average / Средняя нагрузка |
| `.1.3.6.1.4.1.2021.4` | memTotalReal | Memory info / Информация о памяти |
| `.1.3.6.1.4.1.2021.9` | dskTable | Disk usage / Использование дисков |
| `.1.3.6.1.2.1.25.2` | hrStorage | Host resources storage / Хранилище ресурсов |

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
systemctl start snmpd      # Start / Запустить
systemctl stop snmpd       # Stop / Остановить
systemctl restart snmpd    # Restart / Перезапустить
systemctl enable snmpd     # Enable on boot / Автозапуск
systemctl status snmpd     # Check status / Проверить статус
```

### SNMP Trap Receiver / Приёмник SNMP-трапов

```bash
# Install and enable trap daemon / Установить и включить демон трапов
systemctl enable --now snmptrapd
```

`/etc/snmp/snmptrapd.conf`

```ini
# Accept traps from community / Принимать трапы от community
authCommunity log,execute,net <COMMUNITY_STRING>

# Log traps to file / Логировать трапы в файл
[snmptrapd]
doNotLogTraps no
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/etc/snmp/snmpd.conf` | Agent configuration / Конфигурация агента |
| `/etc/snmp/snmptrapd.conf` | Trap receiver configuration / Конфигурация приёмника трапов |
| `/var/log/snmpd.log` | Agent log (if configured) / Лог агента |
| `/usr/share/snmp/mibs/` | MIB files / Файлы MIB |

### Firewall Configuration / Настройка фаервола

```bash
# Allow SNMP agent / Разрешить SNMP-агент
firewall-cmd --permanent --add-port=161/udp   # SNMP queries / Запросы SNMP
firewall-cmd --permanent --add-port=162/udp   # SNMP traps / Трапы SNMP
firewall-cmd --reload
```

### Custom Extensions / Кастомные расширения

```bash
# Example: custom script extension / Пример: расширение через скрипт
cat > /usr/local/bin/snmp_custom_check.sh << 'EOF'
#!/bin/bash
# Returns number of active connections / Возвращает число активных подключений
ss -tn state established | wc -l
EOF
chmod +x /usr/local/bin/snmp_custom_check.sh
```

Add to `/etc/snmp/snmpd.conf`:

```ini
extend active_connections /usr/local/bin/snmp_custom_check.sh
```

```bash
# Query the custom extension / Запросить кастомное расширение
snmpwalk -v2c -c <COMMUNITY_STRING> <HOST> NET-SNMP-EXTEND-MIB::nsExtendOutputFull
```

---

## 4. Security

### Restrict Access / Ограничение доступа

`/etc/snmp/snmpd.conf`

```ini
# Restrict to specific networks only / Ограничить доступ конкретными сетями
rocommunity <COMMUNITY_STRING> 10.0.0.0/24
rocommunity <COMMUNITY_STRING> 192.168.1.0/24

# Restrict OID view / Ограничить обзор OID
view systemonly included .1.3.6.1.2.1.1
view systemonly included .1.3.6.1.2.1.25.1
rocommunity <COMMUNITY_STRING> default -V systemonly
```

> [!TIP]
> Always change default community strings from `public`/`private`. Use SNMPv3 with `authPriv` for encrypted monitoring. / Всегда меняйте стандартные community strings. Используйте SNMPv3 с `authPriv` для шифрованного мониторинга.

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Agent Not Responding / Агент не отвечает

```bash
# Check if snmpd is running / Проверить, запущен ли snmpd
systemctl status snmpd
ss -ulnp | grep 161

# Test locally / Тест локально
snmpwalk -v2c -c <COMMUNITY_STRING> localhost system

# Check config syntax / Проверить синтаксис конфига
snmpd -C -c /etc/snmp/snmpd.conf -Le  # Check for errors / Проверить ошибки
```

#### 2. Timeout / Таймаут

```bash
# Check firewall / Проверить фаервол
firewall-cmd --list-all | grep 161

# Check bind address / Проверить адрес привязки
grep agentAddress /etc/snmp/snmpd.conf

# Check from remote / Проверить удалённо
snmpwalk -v2c -c <COMMUNITY_STRING> -t 10 <HOST> sysDescr.0
```

### Debug Mode / Режим отладки

```bash
# Run snmpd in foreground with debug / Запустить snmpd в foreground с отладкой
systemctl stop snmpd
snmpd -f -Le -Dread_config,snmp_agent  # Debug specific subsystems / Отладка конкретных подсистем

# Debug specific query / Отладка конкретного запроса
snmpwalk -v2c -c <COMMUNITY_STRING> -d <HOST> sysDescr.0
```

---

## 6. Logrotate Configuration

`/etc/logrotate.d/snmpd`

```conf
/var/log/snmpd.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    postrotate
        systemctl kill --signal=HUP snmpd 2>/dev/null || true
    endscript
}

/var/log/snmptrapd.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Documentation Links / Ссылки на документацию

- **Net-SNMP Official Site:** http://www.net-snmp.org/
- **Net-SNMP Documentation:** http://www.net-snmp.org/docs/man/
- **SNMPv3 Configuration:** http://www.net-snmp.org/wiki/index.php/TUT:snmpv3
- **snmpd.conf Manual:** http://www.net-snmp.org/docs/man/snmpd.conf.html
- **OID Repository:** http://www.oid-info.com/
- **GitHub:** https://github.com/net-snmp/net-snmp

---
