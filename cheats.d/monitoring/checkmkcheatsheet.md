Title: 📈 CheckMK
Group: Monitoring
Icon: 📈
Order: 2

# CheckMK Sysadmin Cheatsheet

> **Context:** Checkmk is a leading software solution for IT Infrastructure Monitoring. / Checkmk - ведущее решение для мониторинга IT инфраструктуры.
> **Role:** Sysadmin / DevOps
> **Version:** 2.x+ (Raw/Enterprise)

---

## 📚 Table of Contents / Содержание

1. [Installation & Config](#installation--config--установка-и-конфигурация)
2. [OMD (Open Monitoring Distribution)](#omd-open-monitoring-distribution--omd-управление-сайтами)
3. [Core Management](#core-management-as-site-user--управление-как-пользователь-сайта)
4. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
5. [Backup (OMD)](#backup-omd--бэкап-omd)

---

## 1. Installation & Config / Установка и конфигурация

### Install Agent (Linux) / Установка агента (Linux)
Download from your CheckMK site URL: `http://<HOST>/<SITE>/check_mk/agents/`

```bash
# RPM (RHEL/Alma)
rpm -Uvh check-mk-agent-*.noarch.rpm

# DEB (Debian/Ubuntu)
dpkg -i check-mk-agent_*.deb
```

## 2. OMD (Open Monitoring Distribution) / OMD (Управление сайтами)

CheckMK uses OMD to manage monitoring "sites" (instances). / CheckMK использует OMD для управления "сайтами" (инстансами).

```bash
# List sites / Список сайтов
omd sites

# Create new site / Создать новый сайт
omd create <SITE_NAME>

# Start/Stop site / Запуск/Остановка сайта
omd start <SITE_NAME>
omd stop <SITE_NAME>

# Config site / Конфигурация сайта
omd config <SITE_NAME>
```

### Switch User / Переключение пользователя
To run commands as the site user. / Чтобы запускать команды от имени пользователя сайта.

```bash
su - <SITE_NAME>
```

---

## 3. Core Management (As Site User) / Управление (Как пользователь сайта)

### CheckMK CLI (`cmk`) / CLI CheckMK

```bash
# Inventory (Service Discovery) / Инвентаризация (Поиск сервисов)
cmk -I <HOST>

# Reload configuration (Activate Changes) / Перезагрузить конфиг (Активировать изменения)
cmk -R
# OR only generate config / ИЛИ только сгенерировать конфиг
cmk -G

# Verbose Check / Подробная проверка (Debug)
cmk -v <HOST>
cmk --debug -vvn <HOST>
```

### Agent Output / Вывод агента
Useful to debug agent connection and data. / Полезно для отладки соединения и данных агента.

```bash
# Dump agent output / Дамп вывода агента
cmk -d <HOST>
```

---

## 4. Sysadmin Operations / Операции сисадмина

### Local Checks / Локальные проверки
Place executable scripts in `/usr/lib/check_mk_agent/local/`. / Поместите исполняемые скрипты в эту папку.

Scale: `0 (OK), 1 (WARN), 2 (CRIT), 3 (UNKNOWN)`

**Example Script:**
```bash
#!/bin/bash
# Status ServiceName Metric=Value Output text
echo "0 MyService count=42 OK - Service is running fine"
```
*Modify permissions:* `chmod +x /usr/lib/check_mk_agent/local/myscript`

### Logs / Логи
Site logs are located in `~/var/log/`. / Логи сайта находятся в `~/var/log/`.

*   `~/var/log/cmc.log`: Core log (Enterprise)
*   `~/var/log/nagios.log`: Core log (Raw)
*   `~/var/log/web.log`: Web UI logs

---

## 5. Backup (OMD) / Бэкап (OMD)

```bash
# Backup site to file / Бэкап сайта в файл
omd backup <SITE_NAME> /tmp/backup.tar.gz

# Restore site / Восстановление сайта
omd restore <SITE_NAME> /tmp/backup.tar.gz
```
