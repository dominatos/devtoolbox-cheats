---
Title: 📈 Zabbix Server
Group: Monitoring
Icon: 📈
Order: 3
tags:
  - monitoring
  - sysadmin
  - linux
---

# Zabbix Server Sysadmin Cheatsheet

> **Zabbix** is an enterprise-class open-source distributed monitoring solution developed by Zabbix SIA (Latvia). Originally released in 2001, it provides monitoring of networks, servers, cloud services, applications, and services with extensive template support, auto-discovery, and distributed architecture.
>
> **Common use cases / Типичные сценарии:** Infrastructure monitoring (servers, VMs, containers), network device monitoring (SNMP, IPMI), application performance monitoring, cloud monitoring (AWS, Azure), log monitoring, web scenario monitoring, SLA reporting.
>
> **Status / Статус:** Actively developed with LTS releases. Zabbix is one of the most popular open-source monitoring platforms. Alternatives include **Checkmk** (auto-discovery focused), **Prometheus + Grafana** (cloud-native, metrics), **Datadog** (SaaS), **Nagios** (legacy, Zabbix predecessor in some scenarios), **VictoriaMetrics + vmagent** (lightweight TSDB).
>
> **Default ports / Порты по умолчанию:** `10050/tcp` (Agent passive), `10051/tcp` (Server/Proxy trapper), `80/443` (Web UI), `10053/tcp` (Agent 2 gRPC)

---

## 📚 Table of Contents

- [1. Installation & Configuration](#1.%20Installation%20&%20Configuration)
- [2. Core Management](#2.%20Core%20Management)
- [3. Sysadmin Operations](#3.%20Sysadmin%20Operations)
- [4. Security](#4.%20Security)
- [5. Backup & Restore](#5.%20Backup%20&%20Restore)
- [6. Troubleshooting & Tools](#6.%20Troubleshooting%20&%20Tools)
- [7. Logrotate Configuration](#7.%20Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## 1. Installation & Configuration

### Repository Setup

```bash
# RHEL/AlmaLinux 9 (Zabbix 6.0 LTS)
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
dnf clean all

# Zabbix 7.0 LTS
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
dnf clean all

# Debian/Ubuntu (Zabbix 6.0 LTS)
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb
dpkg -i zabbix-release_*.deb
apt update
```

### Install Server & Agent

```bash
# RHEL/AlmaLinux (MySQL backend)
dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2

# Debian/Ubuntu (MySQL backend)
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
```

### Agent Versions Comparison

| Feature / Особенность | Zabbix Agent (C) | Zabbix Agent 2 (Go) |
|----------------------|-------------------|----------------------|
| Language / Язык | C | Go |
| Plugin Support / Поддержка плагинов | No / Нет | Yes (native) / Да |
| Active/Passive Checks | Both / Оба | Both / Оба |
| Concurrent Checks / Параллельные проверки | Fork-based / На форках | Goroutines |
| Built-in Plugins / Встроенные плагины | None / Нет | MongoDB, PostgreSQL, Docker, etc. |
| Recommended / Рекомендуемый | Legacy / Устаревший | Yes / Да |

### Essential Configs

#### Server Configuration

`/etc/zabbix/zabbix_server.conf`

```ini
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<PASSWORD>

# Performance tuning
StartPollers=10                    # Default: 5, increase for large setups / По умолчанию: 5
StartPollersUnreachable=3          # For unreachable hosts / Для недоступных хостов
StartTrappers=5                    # For active agent/proxy data / Для данных агентов
CacheSize=128M                     # Default: 8M, increase for large configs / Увеличить для больших конфигов
HistoryCacheSize=64M               # History cache / Кэш истории
ValueCacheSize=64M                 # Value cache / Кэш значений
```

#### Agent Configuration

`/etc/zabbix/zabbix_agentd.conf` (or `zabbix_agent2.conf`)

```ini
# Server IP for passive checks / IP
Server=<IP_SERVER>

# Server IP for active checks / IP
ServerActive=<IP_SERVER>

# Hostname must match frontend config / Hostname
Hostname=<HOST>
```

### Database Creation

```bash
# MySQL / MariaDB
mysql -uroot -p
```

```sql
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER zabbix@localhost IDENTIFIED BY '<PASSWORD>';
GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;
SET GLOBAL log_bin_trust_function_creators = 1;
QUIT;
```

```bash
# Import schema
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

# Disable after import
mysql -uroot -p -e "SET GLOBAL log_bin_trust_function_creators = 0;"
```

> [!WARNING]
> The schema import can take several minutes. Do not interrupt the process. / Импорт схемы может занять несколько минут. Не прерывайте процесс.

---

## 2. Core Management

### CLI Tools / CLI-инструменты

#### zabbix_get (Test Passive Checks)

Run from server or proxy. / Запуск с сервера или прокси.

```bash
# Test system metrics
zabbix_get -s <HOST_IP> -k "system.cpu.load[all,avg1]"
zabbix_get -s <HOST_IP> -k "vm.memory.size[available]"
zabbix_get -s <HOST_IP> -k "vfs.fs.size[/,pfree]"
zabbix_get -s <HOST_IP> -k "system.uptime"
zabbix_get -s <HOST_IP> -k "agent.version"
```

#### zabbix_sender (Push Data)

```bash
# Send single value
zabbix_sender -z <IP_SERVER> -s "<HOST>" -k "custom.key" -o "value"

# Send from file
zabbix_sender -z <IP_SERVER> -i /tmp/zabbix_data.txt
# File format: <HOST> <KEY> <VALUE>
```

### Web UI Access

```bash
# Default URL / URL
http://<HOST>/zabbix
# Default credentials
```

> [!CAUTION]
> Change the default Admin password immediately after first login. / Немедленно смените пароль Admin после первого входа.

---

## 3. Sysadmin Operations

### Service Management

```bash
# Server
systemctl start zabbix-server      # Start / Запустить
systemctl stop zabbix-server       # Stop / Остановить
systemctl restart zabbix-server    # Restart / Перезапустить
systemctl enable zabbix-server     # Enable on boot / Автозапуск
systemctl status zabbix-server     # Check status / Проверить статус

# Agent 2
systemctl start zabbix-agent2      # Start / Запустить
systemctl restart zabbix-agent2    # Restart / Перезапустить
systemctl enable zabbix-agent2     # Enable on boot / Автозапуск

# Web stack
systemctl restart httpd php-fpm    # RHEL/AlmaLinux
systemctl restart apache2 php-fpm  # Debian/Ubuntu
```

### Important Paths

| Path | Description / Описание |
|------|------------------------|
| `/etc/zabbix/zabbix_server.conf` | Server configuration / Конфиг сервера |
| `/etc/zabbix/zabbix_agentd.conf` | Agent configuration / Конфиг агента |
| `/etc/zabbix/zabbix_agent2.conf` | Agent 2 configuration / Конфиг агента 2 |
| `/usr/share/zabbix/` | Web UI files / Файлы веб-интерфейса |
| `/var/log/zabbix/` | All Zabbix logs / Все логи Zabbix |
| `/usr/lib/zabbix/externalscripts/` | External scripts / Внешние скрипты |
| `/usr/lib/zabbix/alertscripts/` | Alert scripts / Скрипты уведомлений |

### Log Locations

| Log File | Description / Описание |
|----------|------------------------|
| `/var/log/zabbix/zabbix_server.log` | Server log / Лог сервера |
| `/var/log/zabbix/zabbix_agentd.log` | Agent log / Лог агента |
| `/var/log/zabbix/zabbix_agent2.log` | Agent 2 log / Лог агента 2 |
| `/var/log/httpd/error_log` | Apache error log (RHEL) / Лог ошибок Apache |
| `/var/log/apache2/error.log` | Apache error log (Debian) / Лог ошибок Apache |

### Firewall Configuration

```bash
# Agent (passive) listens on 10050
firewall-cmd --permanent --add-port=10050/tcp

# Server/Proxy listens on 10051
firewall-cmd --permanent --add-port=10051/tcp

# Web UI
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

---

## 4. Security

### Encryption (PSK)

```bash
# Generate PSK key
openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk
chmod 640 /etc/zabbix/zabbix_agentd.psk
chown root:zabbix /etc/zabbix/zabbix_agentd.psk
```

Update agent config / Обновить конфиг агента:

`/etc/zabbix/zabbix_agentd.conf`

```ini
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=PSK_001
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
```

> [!NOTE]
> After configuring PSK on the agent, you must also configure the PSK identity and key in the Zabbix frontend: **Configuration → Hosts → Host → Encryption**. / Также настройте PSK в веб-интерфейсе: **Конфигурация → Хосты → Хост → Шифрование**.

### Encryption Comparison

| Method / Метод | Description / Описание | Best For / Лучше для |
|---------------|------------------------|---------------------|
| No Encryption / Без шифрования | Plaintext / Открытый текст | Internal trusted networks / Доверенные сети |
| PSK | Pre-shared key / Общий ключ | Most common, easy setup / Самый распространённый |
| Certificate / Сертификат | TLS with CA / TLS с центром сертификации | Enterprise, high security / Корпоративные среды |

---

## 5. Backup & Restore

### Database Backup

```bash
# MySQL full backup
mysqldump -uzabbix -p<PASSWORD> --single-transaction --quick --lock-tables=false zabbix | gzip > zabbix_backup_$(date +%F).sql.gz

# Config-only backup (smaller, faster)
mysqldump -uzabbix -p<PASSWORD> --single-transaction zabbix \
  hosts hosts_groups hosts_templates \
  items triggers actions \
  media media_type users usrgrp \
  | gzip > zabbix_config_backup_$(date +%F).sql.gz
```

### Config Backup

```bash
# Backup config files
tar -czf zabbix_conf_backup_$(date +%F).tar.gz /etc/zabbix /usr/share/zabbix/conf /usr/lib/zabbix/
```

### Restore

```bash
# Restore database
systemctl stop zabbix-server
zcat zabbix_backup_2024-01-01.sql.gz | mysql -uzabbix -p zabbix
systemctl start zabbix-server
```

> [!CAUTION]
> Full database restores will overwrite all current data including history. For large databases, consider using Zabbix's built-in housekeeping instead of full dumps. / Полное восстановление перезапишет все данные.

---

## 6. Troubleshooting & Tools

### Common Issues

#### 1. "Zabbix server is not running" in Frontend / "Zabbix

```bash
# Check server status
systemctl status zabbix-server
tail -50 /var/log/zabbix/zabbix_server.log

# Check SELinux (RHEL)
getenforce
setsebool -P zabbix_can_network 1      # Allow network access / Разрешить доступ к сети
setsebool -P httpd_can_connect_zabbix 1  # Allow Apache to connect / Разрешить Apache подключаться

# Check DB connection
mysql -uzabbix -p -e "SELECT 1" zabbix
```

#### 2. Agent Not Reachable

```bash
# Verify agent config
grep Server /etc/zabbix/zabbix_agentd.conf   # Must match actual server IP / Должен совпадать с IP сервера

# Test from server
zabbix_get -s <HOST_IP> -k "agent.ping"

# Check firewall on agent host
firewall-cmd --list-all | grep 10050
ss -tlnp | grep 10050
```

#### 3. Poller Processes Busy

```bash
# Check in web UI: Monitoring → Dashboard → "Zabbix internal process busy %"
#

# Increase pollers in zabbix_server.conf
# StartPollers=20         (default: 5)
# StartPollersUnreachable=5
# CacheSize=256M          (default: 8M)
systemctl restart zabbix-server
```

### Debugging

```bash
# Enable debug logging temporarily (Level 4)
zabbix_server -R log_level_increase
# ... wait for issue
zabbix_server -R log_level_decrease

# Increase log level for specific process
zabbix_server -R log_level_increase="poller"

# Check runtime values
zabbix_server -R diaginfo
```

---

## 7. Logrotate Configuration

`/etc/logrotate.d/zabbix-server`

```conf
/var/log/zabbix/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 zabbix zabbix
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/zabbix/zabbix_server.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
```

> [!TIP]
> Zabbix handles log rotation via config (`LogFileSize` parameter). Set `LogFileSize=100` to auto-rotate at 100MB. External logrotate is optional.
> Zabbix управляет ротацией через конфиг (`LogFileSize`). Установите `LogFileSize=100` для авто-ротации при 100МБ. Внешний logrotate опционален.

---

## Documentation Links

- **Official Documentation:** https://www.zabbix.com/documentation/current/en
- **Zabbix Downloads:** https://www.zabbix.com/download
- **Zabbix API:** https://www.zabbix.com/documentation/current/en/manual/api
- **Zabbix Templates:** https://www.zabbix.com/integrations
- **Zabbix Blog:** https://blog.zabbix.com/
- **Community Forum:** https://www.zabbix.com/forum
- **GitHub:** https://github.com/zabbix/zabbix

---
