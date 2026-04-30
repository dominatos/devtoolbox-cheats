Title: 📈 CheckMK
Group: Monitoring
Icon: 📈
Order: 2

# Checkmk Server Sysadmin Cheatsheet

> **Checkmk** is a comprehensive IT monitoring solution originally developed by Mathias Kettner in 2008 as an extension to Nagios. It has since evolved into a standalone monitoring platform available in two editions: **Raw** (open-source, Nagios core) and **Enterprise/Cloud** (commercial, proprietary CMC core). Checkmk provides auto-discovery, agent-based and agentless monitoring, alerting, graphing, and dashboards.
>
> **Common use cases / Типичные сценарии:** Infrastructure monitoring (servers, network, cloud), application monitoring, SNMP-based device monitoring, log monitoring, service-level monitoring (SLA), auto-discovery of services.
>
> **Status / Статус:** Actively developed and widely used in enterprise environments. Checkmk is a modern evolution of the Nagios ecosystem. Alternatives include **Zabbix** (full-featured open-source), **Prometheus + Grafana** (cloud-native, metrics-focused), **Datadog** (SaaS), **VictoriaMetrics** (TSDB), **Icinga** (Nagios fork).
>
> **Default ports / Порты по умолчанию:** `80/443` (Web UI), `6556/tcp` (Agent), `5000/tcp` (Site Apache), `8000/tcp` (Agent Controller registration)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [OMD Site Management](#2-omd-site-management)
3. [Core Management](#3-core-management)
4. [Sysadmin Operations](#4-sysadmin-operations)
5. [Security](#5-security)
6. [Backup & Restore](#6-backup--restore)
7. [Troubleshooting & Tools](#7-troubleshooting--tools)
8. [Logrotate Configuration](#8-logrotate-configuration)

---

## 1. Installation & Configuration

### Install Checkmk Server / Установка сервера Checkmk

> [!TIP]
> Download the correct edition and OS version from the official site: https://checkmk.com/download / Скачайте нужную редакцию и версию ОС с официального сайта.

```bash
# RHEL/AlmaLinux 9 (Raw Edition) / Установка Raw Edition
wget "https://download.checkmk.com/checkmk/2.3.0/check-mk-raw-2.3.0-el9-38.x86_64.rpm"
dnf install check-mk-raw-*.rpm

# Debian/Ubuntu (Raw Edition)
wget "https://download.checkmk.com/checkmk/2.3.0/check-mk-raw-2.3.0_0.bookworm_amd64.deb"
dpkg -i check-mk-raw-*.deb
apt -f install  # Fix dependencies / Установить зависимости
```

### Install Checkmk Agent / Установка агента Checkmk

Download from your Checkmk site URL: `http://<HOST>/<SITE>/check_mk/agents/`

```bash
# RPM (RHEL/AlmaLinux) / Установка RPM
rpm -Uvh check-mk-agent-*.noarch.rpm

# DEB (Debian/Ubuntu) / Установка DEB
dpkg -i check-mk-agent_*.deb
```

### Editions Comparison / Сравнение редакций

| Feature / Особенность | Raw (Open Source) | Enterprise |
|----------------------|-------------------|------------|
| Core Engine / Ядро | Nagios Core | CMC (Checkmk Micro Core) |
| Performance / Производительность | Good / Хорошая | Excellent / Отличная |
| Agent Bakery / Сборка агентов | No / Нет | Yes / Да |
| BI Module / Модуль BI | Limited / Ограничен | Full / Полный |
| Distributed Monitoring / Распределённый мониторинг | Yes / Да | Yes (enhanced) / Да (расширенный) |
| Support / Поддержка | Community / Сообщество | Commercial / Коммерческая |
| License / Лицензия | GPLv2 | Commercial / Коммерческая |

---

## 2. OMD Site Management

Checkmk uses OMD (Open Monitoring Distribution) to manage monitoring "sites" (instances). Each site is an isolated environment with its own configuration, users, and data. / Checkmk использует OMD для управления «сайтами» (инстансами) мониторинга.

### Create & Manage Sites / Создание и управление сайтами

```bash
# List all sites / Список всех сайтов
omd sites

# Create new site / Создать новый сайт
omd create <SITE_NAME>

# Start/Stop site / Запуск/Остановка сайта
omd start <SITE_NAME>
omd stop <SITE_NAME>

# Restart site / Перезапуск сайта
omd restart <SITE_NAME>

# Site status / Статус сайта
omd status <SITE_NAME>

# Configure site interactively / Конфигурация сайта интерактивно
omd config <SITE_NAME>

# Update site to new version / Обновить сайт до новой версии
omd update <SITE_NAME>
```

### Switch to Site User / Переключение на пользователя сайта

All `cmk` commands must be run as the site user. / Все команды `cmk` запускаются от пользователя сайта.

```bash
su - <SITE_NAME>
```

### Important OMD Paths / Важные пути OMD

| Path | Description / Описание |
|------|------------------------|
| `/opt/omd/sites/<SITE>/` | Site home directory / Домашний каталог сайта |
| `~/etc/check_mk/` | Checkmk configuration / Конфигурация Checkmk |
| `~/etc/check_mk/main.mk` | Main config (legacy) / Главный конфиг (устаревший) |
| `~/etc/check_mk/conf.d/` | WATO-managed config / Конфиг WATO |
| `~/var/log/` | Site logs / Логи сайта |
| `~/var/check_mk/` | Runtime data / Данные времени выполнения |
| `~/local/` | Custom extensions / Кастомные расширения |

---

## 3. Core Management

### Checkmk CLI (`cmk`) / CLI Checkmk

All commands below are run as site user (`su - <SITE_NAME>`). / Все команды ниже запускаются от пользователя сайта.

```bash
# Service discovery (inventory) / Обнаружение сервисов (инвентаризация)
cmk -I <HOST>              # Discover new services / Обнаружить новые сервисы
cmk -II <HOST>             # Full re-discovery / Полное переобнаружение
cmk --detect-plugins <HOST>  # Detect available plugins / Определить доступные плагины

# Activate changes / Активировать изменения
cmk -R                    # Reload configuration / Перезагрузить конфигурацию
cmk -O                    # Restart core / Перезапустить ядро
cmk -G                    # Generate config only (no reload) / Только сгенерировать конфиг

# Debugging / Отладка
cmk -v <HOST>             # Verbose check / Подробная проверка
cmk --debug -vvn <HOST>   # Detailed debug check / Детальная отладка
cmk -D <HOST>             # Show host info / Показать информацию о хосте

# Agent output / Вывод агента
cmk -d <HOST>             # Fetch raw agent output / Получить сырой вывод агента
```

### Web UI Access / Доступ к веб-интерфейсу

```bash
# Default URL / URL по умолчанию
http://<HOST>/<SITE>/check_mk/
# Default credentials: cmkadmin / <PASSWORD_SET_AT_CREATION>
```

### Local Checks / Локальные проверки

Place executable scripts in `/usr/lib/check_mk_agent/local/` on monitored hosts. / Поместите исполняемые скрипты в эту папку на контролируемых хостах.

Output format: `<STATUS> <SERVICE_NAME> <PERF_DATA> <TEXT_OUTPUT>`
Status codes: `0` (OK), `1` (WARN), `2` (CRIT), `3` (UNKNOWN)

```bash
#!/bin/bash
# Example local check / Пример локальной проверки
echo "0 MyService count=42 OK - Service is running fine"
```

```bash
# Set executable permission / Установить разрешение на исполнение
chmod +x /usr/lib/check_mk_agent/local/myscript
```

---

## 4. Sysadmin Operations

### Service Management / Управление сервисом

```bash
# Manage via OMD (preferred) / Управление через OMD (предпочтительно)
omd start <SITE_NAME>       # Start all site services / Запустить все сервисы сайта
omd stop <SITE_NAME>        # Stop all site services / Остановить все сервисы
omd restart <SITE_NAME>     # Restart all site services / Перезапустить все сервисы
omd status <SITE_NAME>      # Check status / Проверить статус

# Or via systemd (starts all sites) / Или через systemd (запускает все сайты)
systemctl start apache2     # Start web server / Запустить веб-сервер
systemctl status apache2    # Check web server status / Статус веб-сервера
```

### Log Locations / Расположение логов

Logs are stored in the site's `~/var/log/` directory. / Логи хранятся в каталоге `~/var/log/` сайта.

| Log File | Description / Описание | Edition |
|----------|------------------------|---------|
| `~/var/log/cmc.log` | CMC core log / Лог ядра CMC | Enterprise |
| `~/var/log/nagios.log` | Nagios core log / Лог ядра Nagios | Raw |
| `~/var/log/web.log` | Web UI log / Лог веб-интерфейса | Both / Оба |
| `~/var/log/notify.log` | Notification log / Лог уведомлений | Both / Оба |
| `~/var/log/mknotifyd.log` | Notification spooler / Очередь уведомлений | Enterprise |
| `~/var/log/liveproxyd.log` | Livestatus proxy / Прокси Livestatus | Enterprise |

```bash
# View logs as site user / Просмотр логов от пользователя сайта
su - <SITE_NAME>
tail -f var/log/cmc.log       # Enterprise core log / Лог ядра Enterprise
tail -f var/log/nagios.log    # Raw core log / Лог ядра Raw
tail -f var/log/web.log       # Web UI log / Лог веб-интерфейса
```

### Firewall Configuration / Настройка фаервола

```bash
# Allow web UI / Разрешить веб-интерфейс
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Allow agent port / Разрешить порт агента
firewall-cmd --permanent --add-port=6556/tcp

# Distributed monitoring (Livestatus) / Распределённый мониторинг
firewall-cmd --permanent --add-port=6557/tcp
firewall-cmd --reload
```

---

## 5. Security

### User Management / Управление пользователями

```bash
# Reset cmkadmin password / Сброс пароля cmkadmin
su - <SITE_NAME>
cmk-passwd cmkadmin

# Or via htpasswd (for Nagios core) / Или через htpasswd (для ядра Nagios)
htpasswd ~/etc/htpasswd cmkadmin
```

### LDAP Integration / Интеграция LDAP

Configure via Web UI: **Setup → Users → LDAP & Active Directory**

### Agent Encryption / Шифрование агента

> [!TIP]
> In Checkmk 2.2+, use the built-in Agent Controller with TLS for encrypted agent communication. This is the preferred method over legacy symmetric encryption. / В Checkmk 2.2+ используйте Agent Controller с TLS.

---

## 6. Backup & Restore

### OMD Backup / Бэкап OMD

```bash
# Backup site to file / Бэкап сайта в файл
omd backup <SITE_NAME> /backup/checkmk_<SITE_NAME>_$(date +%F).tar.gz

# Restore site from backup / Восстановить сайт из бэкапа
omd restore <SITE_NAME> /backup/checkmk_<SITE_NAME>.tar.gz
```

> [!WARNING]
> `omd backup` stops the site during backup. Schedule during maintenance windows. / `omd backup` останавливает сайт на время бэкапа. Планируйте на время обслуживания.

### Manual Config Backup / Ручной бэкап конфигурации

```bash
# Backup configuration only / Бэкап только конфигурации
su - <SITE_NAME>
tar -czf /backup/checkmk_config_$(date +%F).tar.gz etc/check_mk/ etc/nagios/ etc/htpasswd
```

---

## 7. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. "Checkmk server is not running" in Web UI / "Checkmk сервер не запущен" в веб-интерфейсе

```bash
# Check site status / Проверить статус сайта
omd status <SITE_NAME>

# Check SELinux (RHEL) / Проверить SELinux
getenforce
setsebool -P httpd_can_network_connect 1  # Allow Apache to connect / Разрешить Apache подключения
```

#### 2. Agent Not Reachable / Агент недоступен

```bash
# Test agent from server / Тест агента с сервера
su - <SITE_NAME>
cmk -d <HOST>               # Fetch agent output / Получить вывод агента
cmk --debug -vvn <HOST>     # Detailed debug / Подробная отладка

# Test from network / Тест по сети
nc -w 5 <HOST> 6556 | head -20
```

#### 3. Performance Issues / Проблемы производительности

```bash
# Check helper usage (Enterprise) / Проверить утилизацию хелперов
su - <SITE_NAME>
cmk --check-helper-usage

# Increase checkers in global settings / Увеличить число checker'ов
# Setup → General → Global Settings → Monitoring Core → Number of checker helpers
```

### Debugging / Отладка

```bash
# Enable debug logging temporarily / Включить отладочное логирование временно
su - <SITE_NAME>

# Verbose check of specific host / Подробная проверка конкретного хоста
cmk --debug -vvn <HOST>

# Check core status / Статус ядра
omd status
```

---

## 8. Logrotate Configuration

> [!NOTE]
> Checkmk/OMD manages log rotation internally via the site framework. Logs are rotated automatically in the OMD site's `~/var/log/` directory.
> Checkmk/OMD управляет ротацией логов внутренне через фреймворк сайта. Логи ротируются автоматически.

No external logrotate configuration is typically needed for Checkmk. / Внешняя конфигурация logrotate для Checkmk обычно не требуется.

---

## Documentation Links / Ссылки на документацию

- **Official Documentation:** https://docs.checkmk.com/
- **Checkmk Downloads:** https://checkmk.com/download
- **Checkmk User Guide:** https://docs.checkmk.com/latest/en/
- **Agent Installation:** https://docs.checkmk.com/latest/en/agent_linux.html
- **Checkmk REST API:** https://docs.checkmk.com/latest/en/rest_api.html
- **Community Forum:** https://forum.checkmk.com/
- **GitHub (Raw Edition):** https://github.com/Checkmk/checkmk

---
