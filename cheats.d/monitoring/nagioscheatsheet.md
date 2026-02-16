Title: 📈 Nagios Core
Group: Monitoring
Icon: 📈
Order: 1

# Nagios Sysadmin Cheatsheet

> **Context:** Nagios Core is an open source computer-system monitoring, network monitoring and infrastructure monitoring software application. / Nagios Core - это open source ПО для мониторинга систем, сетей и инфраструктуры.
> **Role:** Sysadmin / DevOps
> **Version:** 4.x

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-конфигурация)
2. [Core Management](#core-management--базовое-управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [NRPE (Remote Monitoring)](#nrpe-remote-monitoring--nrpe-удаленный-мониторинг)
5. [Maintenance](#maintenance--обслуживание)
6. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## 1. Installation & Configuration / Установка и конфигурация

### Main Config Files / Основные файлы конфигурации

Root directory: `/usr/local/nagios/etc/` or `/etc/nagios/`

*   `nagios.cfg`: Main configuration file / Основной файл конфигурации
*   `objects/commands.cfg`: Command definitions / Определения команд
*   `objects/contacts.cfg`: Contact definitions / Определения контактов
*   `objects/localhost.cfg`: Monitoring definitions for local machine / Мониторинг локальной машины

### User Management / Управление пользователями (Web UI)
Using `htpasswd` for Basic Auth. / Использование `htpasswd` для Basic Auth.

```bash
# Create user/password / Создать пользователя/пароль
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Add new user / Добавить нового пользователя
htpasswd /usr/local/nagios/etc/htpasswd.users <USER>
```

---

## 2. Core Management / Базовое управление

### Verify Config / Проверка конфигурации
Always verify before restarting! / Всегда проверяйте перед перезагрузкой!

```bash
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

### Service Control / Управление сервисом

```bash
systemctl start nagios    # Start / Запуск
systemctl stop nagios     # Stop / Остановка
systemctl reload nagios   # Reload (Apply config) / Применить конфиг
systemctl status nagios   # Status / Статус
```

---

## 3. Sysadmin Operations / Операции сисадмина

### Plugins / Плагины
Located in `/usr/local/nagios/libexec/` or `/usr/lib64/nagios/plugins/`.

```bash
# Test Ping / Тест пинга
./check_ping -H <HOST> -w 100.0,20% -c 500.0,60% -p 5

# Test HTTP / Тест HTTP
./check_http -H <HOST> -u /

# Test Disk / Тест диска
./check_disk -w 20% -c 10% -p /
```

### Logs / Логи
File: `/usr/local/nagios/var/nagios.log` or `/var/log/nagios/nagios.log`

```bash
tail -f /usr/local/nagios/var/nagios.log
```

---

## 4. NRPE (Remote Monitoring) / NRPE (Удаленный мониторинг)

### Check NRPE Status / Проверка статуса NRPE
Run from Nagios Server to Client. / Запуск с сервера Nagios на клиент.

```bash
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP>
# Output: NRPE v4.0.3
```

### Run Remote Command / Запуск удаленной команды

```bash
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP> -c check_load
```

---

## 5. Maintenance / Обслуживание

### Acknowledge Alert (CLI) / Подтверждение алерта (CLI)
Via external command file (cmd.cgi). / Через файл внешних команд.

```bash
now=`date +%s`
commandfile='/usr/local/nagios/var/rw/nagios.cmd'
/bin/printf "[%lu] ACKNOWLEDGE_HOST_PROBLEM;<HOST>;1;1;1;<USER>;Admin Ack\n" $now > $commandfile
```

### Performance Data / Данные производительности
Nagios writes perfdata to `host-perfdata` and `service-perfdata` files if enabled. Processed by PNP4Nagios or Graphite.
Nagios пишет perfdata в файлы `host-perfdata` и `service-perfdata`, если включено. Обрабатывается PNP4Nagios или Graphite.

---

## 6. Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/nagios`

```conf
/var/log/nagios/*.log
/usr/local/nagios/var/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 nagios nagios
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/nagios/nagios.lock 2>/dev/null) 2>/dev/null || true
    endscript
}
```

---

