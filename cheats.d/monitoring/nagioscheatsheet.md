Title: 📈 Nagios Core
Group: Monitoring
Icon: 📈
Order: 1

# Nagios Core Sysadmin Cheatsheet

> **Nagios Core** is an open-source IT infrastructure monitoring system originally developed by Ethan Galstad in 1999. It provides monitoring of hosts, services, and network devices with alerting capabilities. Nagios pioneered the modern monitoring landscape and inspired many successors.
>
> **Common use cases / Типичные сценарии:** Host/service availability monitoring, network device monitoring, alerting via email/SMS/Slack, performance data collection, SLA reporting.
>
> **Status / Статус:** Nagios Core is still maintained but is considered a **legacy** monitoring solution. Modern alternatives include **Checkmk** (Nagios evolution with auto-discovery), **Zabbix** (enterprise-grade, auto-discovery), **Prometheus + Grafana** (cloud-native, metrics-focused), **Icinga 2** (modern Nagios fork with improved configuration and API).
>
> **Default ports / Порты по умолчанию:** `80/443` (Web UI via Apache), `5666/tcp` (NRPE agent), `5667/tcp` (NSCA passive checks)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [NRPE Remote Monitoring](#4-nrpe-remote-monitoring)
5. [Security](#5-security)
6. [Maintenance](#6-maintenance)
7. [Troubleshooting & Tools](#7-troubleshooting--tools)
8. [Logrotate Configuration](#8-logrotate-configuration)

---

## 1. Installation & Configuration

### Install Nagios Core / Установка Nagios Core

```bash
# RHEL/AlmaLinux — install from EPEL or compile from source
# Установка из EPEL или компиляция из исходников
dnf install epel-release
dnf install nagios nagios-plugins-all nagios-plugins-nrpe

# Debian/Ubuntu
apt install nagios4 nagios-plugins nagios-nrpe-plugin

# From source (any distro) / Из исходников
wget "https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.0/nagios-4.5.0.tar.gz"
tar -xzf nagios-4.5.0.tar.gz
cd nagios-4.5.0
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
make install install-init install-commandmode install-config install-webconf
```

### Main Config Files / Основные файлы конфигурации

Root directory: `/usr/local/nagios/etc/` or `/etc/nagios/`

| File | Description / Описание |
|------|------------------------|
| `nagios.cfg` | Main configuration / Основной конфиг |
| `objects/commands.cfg` | Command definitions / Определения команд |
| `objects/contacts.cfg` | Contact definitions / Определения контактов |
| `objects/localhost.cfg` | Local host monitoring / Мониторинг локальной машины |
| `objects/templates.cfg` | Object templates / Шаблоны объектов |
| `cgi.cfg` | CGI/Web interface config / Конфиг веб-интерфейса |
| `resource.cfg` | User macros ($USERn$) / Пользовательские макросы |

### Host Definition Example / Пример определения хоста

`/usr/local/nagios/etc/objects/servers.cfg`

```cfg
define host {
    use                     linux-server
    host_name               <HOST>
    alias                   Production Server
    address                 <IP>
    max_check_attempts      5
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service {
    use                     generic-service
    host_name               <HOST>
    service_description     PING
    check_command           check_ping!100.0,20%!500.0,60%
}

define service {
    use                     generic-service
    host_name               <HOST>
    service_description     SSH
    check_command           check_ssh
}
```

### User Management / Управление пользователями (Web UI)

Using `htpasswd` for Basic Auth. / Использование `htpasswd` для Basic Auth.

```bash
# Create initial nagiosadmin user / Создать начального пользователя nagiosadmin
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Add new user / Добавить нового пользователя
htpasswd /usr/local/nagios/etc/htpasswd.users <USER>

# Don't forget to add contacts in objects/contacts.cfg / Не забудьте добавить контакты в contacts.cfg
```

---

## 2. Core Management

### Verify Config / Проверка конфигурации

> [!IMPORTANT]
> Always verify configuration before restarting Nagios. A bad config will prevent the service from starting. / Всегда проверяйте конфигурацию перед перезапуском.

```bash
# Validate configuration / Проверить конфигурацию
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Quick test (returns exit code 0 on success) / Быстрый тест
nagios -v /etc/nagios/nagios.cfg && echo "Config OK" || echo "Config ERROR"
```

### Service Control / Управление сервисом

```bash
systemctl start nagios     # Start / Запустить
systemctl stop nagios      # Stop / Остановить
systemctl restart nagios   # Restart / Перезапустить
systemctl reload nagios    # Reload config / Перезагрузить конфиг
systemctl enable nagios    # Enable on boot / Автозапуск
systemctl status nagios    # Check status / Проверить статус
```

---

## 3. Sysadmin Operations

### Plugins / Плагины

Nagios plugins are located in `/usr/local/nagios/libexec/` or `/usr/lib64/nagios/plugins/`.

```bash
# Test Ping / Тест пинга
./check_ping -H <HOST> -w 100.0,20% -c 500.0,60% -p 5

# Test HTTP / Тест HTTP
./check_http -H <HOST> -u /

# Test Disk / Тест диска
./check_disk -w 20% -c 10% -p /

# Test SMTP / Тест SMTP
./check_smtp -H <HOST>

# Test DNS / Тест DNS
./check_dns -H <HOST> -s <DNS_SERVER>

# Test TCP port / Тест TCP порта
./check_tcp -H <HOST> -p 443
```

### Important Paths / Важные пути

| Path | Description / Описание |
|------|------------------------|
| `/usr/local/nagios/etc/` | Configuration directory / Каталог конфигурации |
| `/usr/local/nagios/var/` | State and log data / Данные состояния и логи |
| `/usr/local/nagios/var/nagios.log` | Main log / Основной лог |
| `/usr/local/nagios/var/retention.dat` | State retention file / Файл сохранения состояния |
| `/usr/local/nagios/var/status.dat` | Current status / Текущий статус |
| `/usr/local/nagios/var/rw/nagios.cmd` | External command pipe / Канал внешних команд |
| `/usr/local/nagios/libexec/` | Plugins / Плагины |
| `/usr/local/nagios/share/` | Web UI files / Файлы веб-интерфейса |

### Log Monitoring / Мониторинг логов

```bash
# Follow main log / Следить за основным логом
tail -f /usr/local/nagios/var/nagios.log

# Search for errors / Поиск ошибок
grep -i error /usr/local/nagios/var/nagios.log | tail -20

# Check notification history / Проверить историю уведомлений
grep NOTIFICATION /usr/local/nagios/var/nagios.log | tail -20
```

### Firewall Configuration / Настройка фаервола

```bash
# Allow web UI / Разрешить веб-интерфейс
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Allow NRPE / Разрешить NRPE
firewall-cmd --permanent --add-port=5666/tcp

# Allow NSCA (passive checks) / Разрешить NSCA (пассивные проверки)
firewall-cmd --permanent --add-port=5667/tcp
firewall-cmd --reload
```

---

## 4. NRPE Remote Monitoring

### NRPE Architecture / Архитектура NRPE

| Component | Description / Описание |
|-----------|------------------------|
| NRPE Plugin (Server) | Installed on Nagios server, sends commands / На сервере Nagios |
| NRPE Daemon (Client) | Installed on remote host, executes checks / На удалённом хосте |

### Install NRPE Agent / Установка агента NRPE

```bash
# On monitored host / На контролируемом хосте
dnf install nrpe nagios-plugins-all    # RHEL/AlmaLinux
apt install nagios-nrpe-server nagios-plugins   # Debian/Ubuntu
```

### NRPE Configuration / Конфигурация NRPE

`/etc/nagios/nrpe.cfg`

```ini
# Allow Nagios server IP / Разрешить IP сервера Nagios
allowed_hosts=127.0.0.1,<NAGIOS_SERVER_IP>

# Command definitions / Определения команд
command[check_load]=/usr/lib64/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_procs]=/usr/lib64/nagios/plugins/check_procs -w 250 -c 400
```

```bash
# Start NRPE service / Запустить NRPE
systemctl enable --now nrpe
```

### Check NRPE Status / Проверка статуса NRPE

Run from Nagios Server to Client. / Запуск с сервера Nagios на клиент.

```bash
# Check NRPE connection / Проверить подключение NRPE
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP>
# Expected output: NRPE v4.x.x

# Run remote check / Запустить удалённую проверку
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP> -c check_load
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP> -c check_disk
```

---

## 5. Security

### Web UI Authentication / Аутентификация веб-интерфейса

```bash
# Change nagiosadmin password / Сменить пароль nagiosadmin
htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin
```

### NRPE Security / Безопасность NRPE

> [!WARNING]
> Always restrict `allowed_hosts` in NRPE config to your Nagios server IP only. An unrestricted NRPE allows remote command execution. / Всегда ограничивайте `allowed_hosts` только IP сервера Nagios.

```ini
# In nrpe.cfg / В nrpe.cfg
allowed_hosts=127.0.0.1,<NAGIOS_SERVER_IP>
dont_blame_nrpe=0    # Disable command arguments / Отключить аргументы команд (безопасно)
```

---

## 6. Maintenance

### Acknowledge Alert (CLI) / Подтверждение алерта (CLI)

Via external command file (cmd.cgi). / Через файл внешних команд.

```bash
# Acknowledge host problem / Подтвердить проблему хоста
now=$(date +%s)
commandfile='/usr/local/nagios/var/rw/nagios.cmd'
printf "[%lu] ACKNOWLEDGE_HOST_PROBLEM;<HOST>;1;1;1;<USER>;Admin Ack\n" $now > $commandfile

# Acknowledge service problem / Подтвердить проблему сервиса
printf "[%lu] ACKNOWLEDGE_SVC_PROBLEM;<HOST>;CPU Load;1;1;1;<USER>;Investigating\n" $now > $commandfile
```

### Schedule Downtime / Плановое обслуживание

```bash
# Schedule host downtime / Запланировать обслуживание хоста
now=$(date +%s)
end=$(date -d '+2 hours' +%s)
printf "[%lu] SCHEDULE_HOST_DOWNTIME;<HOST>;%lu;%lu;1;0;7200;<USER>;Maintenance window\n" $now $now $end > $commandfile
```

### Performance Data / Данные производительности

Nagios writes perfdata to `host-perfdata` and `service-perfdata` files if enabled. Processed by PNP4Nagios or Graphite. / Nagios пишет perfdata в файлы, если включено. Обрабатывается PNP4Nagios или Graphite.

---

## 7. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. "Failed to start nagios" / Nagios не запускается

```bash
# Always check config first / Всегда проверяйте конфиг
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Check permissions / Проверить права
ls -la /usr/local/nagios/var/rw/nagios.cmd
chown nagios:nagios /usr/local/nagios/var/rw/nagios.cmd
```

#### 2. Web UI Not Loading / Веб-интерфейс не загружается

```bash
# Check Apache / Проверить Apache
systemctl status httpd
systemctl status apache2

# Check CGI configuration / Проверить конфигурацию CGI
cat /etc/httpd/conf.d/nagios.conf
```

#### 3. No Notifications / Нет уведомлений

```bash
# Check notification log / Проверить лог уведомлений
grep NOTIFICATION /usr/local/nagios/var/nagios.log | tail -20

# Check notification settings / Проверить настройки уведомлений
grep notification /usr/local/nagios/etc/objects/contacts.cfg
```

#### 4. Agent (NRPE) Not Responding / Агент (NRPE) не отвечает

```bash
# Test NRPE from server / Тест NRPE с сервера
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP>

# On client: check NRPE service / На клиенте: проверить сервис NRPE
systemctl status nrpe
ss -tlnp | grep 5666

# Check firewall on client / Проверить фаервол на клиенте
firewall-cmd --list-all | grep 5666
```

---

## 8. Logrotate Configuration

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

## Documentation Links / Ссылки на документацию

- **Official Documentation:** https://www.nagios.org/documentation/
- **Nagios Core Manual:** https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/
- **Plugin Development:** https://nagios-plugins.org/doc/guidelines.html
- **NRPE Documentation:** https://github.com/NagiosEnterprises/nrpe
- **Nagios Exchange (Plugins):** https://exchange.nagios.org/
- **Community Forum:** https://support.nagios.com/forum/

---
