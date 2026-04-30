Title: ✅ Checkmk Agent
Group: Monitoring
Icon: ✅
Order: 7

# Checkmk Agent (check_mk_agent) Sysadmin Cheatsheet

> **Checkmk Agent** is a lightweight monitoring agent installed on target hosts to collect system metrics and expose them to the Checkmk monitoring server. Starting with version 2.1, the agent includes the **Agent Controller** (`cmk-agent-ctl`) which provides TLS-encrypted communication, replacing the legacy xinetd-based plain TCP transport.
>
> **Common use cases / Типичные сценарии:** System metrics collection (CPU, memory, disk, processes), custom local checks, plugin-based monitoring (Oracle, MySQL, Docker, etc.), file integrity monitoring, certificate expiration checks.
>
> **Status / Статус:** Actively maintained as part of the Checkmk ecosystem. The Agent Controller (Go-based) is the recommended deployment method for Checkmk 2.2+. Legacy xinetd mode is deprecated but still supported.
>
> **Default ports / Порты по умолчанию:** `6556/tcp` (agent data), `8000/tcp` (Agent Controller registration)

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

### Install Checkmk Agent / Установка агента Checkmk

> [!TIP]
> The recommended way is to download the agent package from your Checkmk server's web UI: **Setup → Agents → Linux**. This ensures version compatibility. / Рекомендуется скачивать пакет агента из веб-интерфейса вашего сервера Checkmk.

```bash
# Download from Checkmk server / Скачать с сервера Checkmk
wget "https://<CHECKMK_HOST>/<SITE>/check_mk/agents/check-mk-agent-2.3.0-1.noarch.rpm"
wget "https://<CHECKMK_HOST>/<SITE>/check_mk/agents/check-mk-agent_2.3.0-1_all.deb"

# Install on RHEL/CentOS/AlmaLinux
dnf install check-mk-agent-*.rpm

# Install on Debian/Ubuntu
dpkg -i check-mk-agent_*.deb

# Install agent updater plugin (optional, auto-updates agent) / Установить плагин авто-обновления
wget "https://<CHECKMK_HOST>/<SITE>/check_mk/agents/plugins/cmk-update-agent" -O /usr/lib/check_mk_agent/plugins/cmk-update-agent
chmod +x /usr/lib/check_mk_agent/plugins/cmk-update-agent
```

### Agent Communication Modes / Режимы связи агента

| Mode | Description / Описание | Checkmk Version |
|------|------------------------|-----------------|
| Legacy (xinetd) | Plain TCP on port 6556 / Простой TCP на порту 6556 | 1.x, 2.0 |
| Agent Controller (pull) | TLS-encrypted, server pulls / TLS, сервер запрашивает | 2.1+ |
| Agent Controller (push) | TLS-encrypted, agent pushes / TLS, агент отправляет | 2.2+ |

> [!NOTE]
> **Pull vs Push:** Pull mode requires the server to initiate connections (firewall must allow inbound 6556 on agent). Push mode has the agent initiate connections to the server (useful behind NAT/firewalls). / Pull — сервер инициирует подключение. Push — агент отправляет данные сам (удобно за NAT).

### Register Agent with Controller / Регистрация агента через Controller

```bash
# Register agent with Checkmk server (TLS mode) / Зарегистрировать агент с сервером
cmk-agent-ctl register \
  --hostname <THIS_HOST> \
  --server <CHECKMK_HOST> \
  --site <SITE> \
  --user <USER> \
  --password <PASSWORD>

# Register with trust on first use / Регистрация с доверием при первом подключении
cmk-agent-ctl register \
  --hostname <THIS_HOST> \
  --server <CHECKMK_HOST> \
  --site <SITE> \
  --user <USER> \
  --trust-cert

# Check registration status / Проверить статус регистрации
cmk-agent-ctl status

# Show agent controller status / Показать статус контроллера
cmk-agent-ctl dump
```

### Legacy Mode (xinetd) / Устаревший режим (xinetd)

`/etc/xinetd.d/check_mk`

```ini
service check_mk
{
    type           = UNLISTED
    port           = 6556
    socket_type    = stream
    protocol       = tcp
    wait           = no
    user           = root
    server         = /usr/bin/check_mk_agent
    only_from      = <CHECKMK_SERVER_IP>
    disable        = no
}
```

```bash
systemctl restart xinetd  # Restart xinetd / Перезапустить xinetd
```

---

## 2. Core Management

### Agent Output / Вывод агента

```bash
# Run agent manually (test output) / Запустить агент вручную (тестовый вывод)
check_mk_agent

# Run agent via controller / Запустить через контроллер
cmk-agent-ctl dump

# Check agent output from server / Проверить вывод агента с сервера (на сервере Checkmk)
su - <SITE>
cmk -d <HOST>              # Fetch agent output / Получить вывод агента
cmk --detect-plugins <HOST>  # Detect available plugins / Определить доступные плагины
```

### Agent Plugins / Плагины агента

```bash
# List installed plugins / Список установленных плагинов
ls -la /usr/lib/check_mk_agent/plugins/

# List local checks / Список локальных проверок
ls -la /usr/lib/check_mk_agent/local/

# Download available plugins from server / Скачать доступные плагины с сервера
wget "https://<CHECKMK_HOST>/<SITE>/check_mk/agents/plugins/" -O /tmp/plugins_list.html
```

### Plugin Conventions / Соглашения по плагинам

| Directory | Execution | Description / Описание |
|-----------|-----------|------------------------|
| `/usr/lib/check_mk_agent/plugins/` | Every check interval / Каждый интервал | Standard plugins / Стандартные плагины |
| `/usr/lib/check_mk_agent/plugins/<N>/` | Every N seconds / Каждые N секунд | Cached plugins / Кэшированные плагины |
| `/usr/lib/check_mk_agent/local/` | Every check interval / Каждый интервал | Custom local checks / Кастомные проверки |
| `/etc/check_mk/` | — | Agent configuration / Конфигурация агента |

### Custom Local Check Example / Пример кастомной локальной проверки

`/usr/lib/check_mk_agent/local/check_disk_usage`

```bash
#!/bin/bash
# Custom disk usage check / Кастомная проверка использования дисков
USAGE=$(df / --output=pcent | tail -1 | tr -d ' %')

if [ "$USAGE" -gt 90 ]; then
    echo "2 Disk_Root usage=$USAGE;80;90;0;100 CRITICAL - Root partition at ${USAGE}%"
elif [ "$USAGE" -gt 80 ]; then
    echo "1 Disk_Root usage=$USAGE;80;90;0;100 WARNING - Root partition at ${USAGE}%"
else
    echo "0 Disk_Root usage=$USAGE;80;90;0;100 OK - Root partition at ${USAGE}%"
fi
```

```bash
chmod +x /usr/lib/check_mk_agent/local/check_disk_usage
```

> [!NOTE]
> Local check output format: `<STATUS> <SERVICE_NAME> <PERF_DATA> <TEXT>` where STATUS: 0=OK, 1=WARN, 2=CRIT, 3=UNKNOWN. / Формат: `<СТАТУС> <ИМЯ_СЕРВИСА> <МЕТРИКИ> <ТЕКСТ>`, где 0=OK, 1=WARN, 2=CRIT, 3=UNKNOWN.

### Real-World Local Check Examples / Примеры реальных локальных проверок

`/usr/lib/check_mk_agent/local/local_aide_data.sh`

```bash
#!/bin/bash
# AIDE integrity check for Checkmk / Проверка целостности AIDE для Checkmk
DB_FILE="/var/lib/aide/aide.db.gz"
DB_AGE=$(( ($(date +%s) - $(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)) / 86400 ))

if [ ! -f "$DB_FILE" ]; then
    echo "2 AIDE_DB - CRITICAL - AIDE database not found"
elif [ "$DB_AGE" -gt 30 ]; then
    echo "1 AIDE_DB db_age=${DB_AGE}d;14;30 WARNING - AIDE DB is ${DB_AGE} days old"
else
    echo "0 AIDE_DB db_age=${DB_AGE}d;14;30 OK - AIDE DB is ${DB_AGE} days old"
fi
```

`/usr/lib/check_mk_agent/local/local_filebeat.sh`

```bash
#!/bin/bash
# Filebeat service check for Checkmk / Проверка сервиса Filebeat для Checkmk
if systemctl is-active --quiet filebeat; then
    echo "0 Filebeat_Service - OK - Filebeat is running"
else
    echo "2 Filebeat_Service - CRITICAL - Filebeat is NOT running"
fi
```

`/usr/lib/check_mk_agent/local/local_check_conntrack.sh`

```bash
#!/bin/bash
# Conntrack table usage for Checkmk / Использование таблицы conntrack для Checkmk
MAX=$(cat /proc/sys/net/nf_conntrack_max 2>/dev/null || echo 0)
CUR=$(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo 0)
[ "$MAX" -eq 0 ] && { echo "3 Conntrack - UNKNOWN - conntrack not available"; exit; }
PCT=$(( CUR * 100 / MAX ))

if [ "$PCT" -gt 90 ]; then
    echo "2 Conntrack used=${CUR};$((MAX*80/100));$((MAX*90/100));0;${MAX} CRITICAL - Conntrack ${PCT}% (${CUR}/${MAX})"
elif [ "$PCT" -gt 80 ]; then
    echo "1 Conntrack used=${CUR};$((MAX*80/100));$((MAX*90/100));0;${MAX} WARNING - Conntrack ${PCT}% (${CUR}/${MAX})"
else
    echo "0 Conntrack used=${CUR};$((MAX*80/100));$((MAX*90/100));0;${MAX} OK - Conntrack ${PCT}% (${CUR}/${MAX})"
fi
```

```bash
chmod +x /usr/lib/check_mk_agent/local/local_*
```

---

## 3. Sysadmin Operations

### Service Management / Управление сервисом

```bash
# Agent Controller service / Сервис контроллера агента
systemctl start cmk-agent-ctl      # Start / Запустить
systemctl stop cmk-agent-ctl       # Stop / Остановить
systemctl restart cmk-agent-ctl    # Restart / Перезапустить
systemctl enable cmk-agent-ctl     # Enable on boot / Автозапуск
systemctl status cmk-agent-ctl     # Check status / Проверить статус

# Legacy xinetd / Устаревший xinetd
systemctl restart xinetd
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/usr/bin/check_mk_agent` | Agent binary / Исполняемый файл агента |
| `/etc/check_mk/` | Agent configuration / Конфигурация агента |
| `/etc/check_mk/mrpe.cfg` | MRPE (Nagios plugin wrapper) config / Конфиг MRPE |
| `/usr/lib/check_mk_agent/plugins/` | Agent plugins / Плагины агента |
| `/usr/lib/check_mk_agent/local/` | Local checks / Локальные проверки |
| `/var/lib/check_mk_agent/cache/` | Local check cache files / Кэш локальных проверок |
| `/var/lib/cmk-agent/` | Agent controller data / Данные контроллера |
| `/var/log/cmk-agent-ctl.log` | Controller log / Лог контроллера |

### Cache Management / Управление кэшем

```bash
# List cached check results / Список кэшированных результатов проверок
ls -la /var/lib/check_mk_agent/cache/
# Example entries / Примеры файлов:
# chrony.cache
# local_aide_data.sh.cache
# local_filebeat.sh.cache
# local_filebeat_cert.sh.cache
# local_check_conntrack.sh.cache
# plugins_cmk-update-agent.cache

# Clear stale local check cache / Очистить устаревший кэш локальных проверок
rm /var/lib/check_mk_agent/cache/local_*

# Clear all cache / Очистить весь кэш
rm /var/lib/check_mk_agent/cache/*
```

### Firewall Configuration / Настройка фаервола

```bash
# Allow Checkmk agent port / Разрешить порт агента
firewall-cmd --permanent --add-port=6556/tcp
firewall-cmd --reload

# Or restrict to monitoring server only / Или ограничить только сервером мониторинга
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<CHECKMK_SERVER_IP>" port port="6556" protocol="tcp" accept'
firewall-cmd --reload
```

---

## 4. Security

### Encrypted Agent (TLS) / Шифрованный агент (TLS)

```bash
# Check TLS status / Проверить статус TLS
cmk-agent-ctl status --json | jq .

# Re-register with new credentials / Перерегистрировать с новыми учётными данными
cmk-agent-ctl register \
  --hostname <THIS_HOST> \
  --server <CHECKMK_HOST> \
  --site <SITE> \
  --user <USER> \
  --password <PASSWORD>
```

### Restrict Agent Access / Ограничение доступа к агенту

`/etc/check_mk/encryption.cfg`

```ini
# Enable encryption / Включить шифрование
ENCRYPTED=yes
PASSPHRASE=<SECRET_KEY>
```

> [!TIP]
> In Checkmk 2.2+, always use the Agent Controller with TLS instead of legacy xinetd. This eliminates the need for manual encryption config. / В Checkmk 2.2+ всегда используйте Agent Controller с TLS.

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Agent Not Responding / Агент не отвечает

```bash
# Test agent locally / Тест агента локально
check_mk_agent | head -20

# Test from monitoring server / Тест с сервера мониторинга
nc -w 5 <HOST> 6556 | head -20

# Check controller status / Проверить статус контроллера
cmk-agent-ctl status
systemctl status cmk-agent-ctl

# Check firewall / Проверить фаервол
ss -tlnp | grep 6556
```

#### 2. Plugin Not Working / Плагин не работает

```bash
# Run plugin manually / Запустить плагин вручную
/usr/lib/check_mk_agent/plugins/<PLUGIN_NAME>

# Check permissions / Проверить правa
ls -la /usr/lib/check_mk_agent/plugins/<PLUGIN_NAME>

# Check plugin output in agent / Проверить вывод плагина в агенте
check_mk_agent | grep -A 5 "<<<plugin_section>>>"
```

#### 3. Registration Fails / Ошибка регистрации

```bash
# Verify server connectivity / Проверить подключение к серверу
curl -kv https://<CHECKMK_HOST>/<SITE>/check_mk/api/1.0/version

# Check agent controller log / Проверить лог контроллера
journalctl -u cmk-agent-ctl -f --no-pager
cat /var/log/cmk-agent-ctl.log
```

---

## 6. Logrotate Configuration

`/etc/logrotate.d/check-mk-agent`

```conf
/var/log/cmk-agent-ctl.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Documentation Links / Ссылки на документацию

- **Agent Installation (Linux):** https://docs.checkmk.com/latest/en/agent_linux.html
- **Agent Controller:** https://docs.checkmk.com/latest/en/agent_linux.html#agent_controller
- **Local Checks:** https://docs.checkmk.com/latest/en/localchecks.html
- **Agent Plugins:** https://docs.checkmk.com/latest/en/agent_linux.html#plugins
- **MRPE (Nagios Plugin Wrapper):** https://docs.checkmk.com/latest/en/agent_linux.html#mrpe
- **Agent Bakery (Enterprise):** https://docs.checkmk.com/latest/en/wato_monitoringagents.html

---
