---
Title: 📈 Nagios Core
Group: Monitoring
Icon: 📈
Order: 1
tags:
  - monitoring
  - sysadmin
  - linux
---

# Nagios Core Sysadmin Cheatsheet

> **Nagios Core** is an open-source IT infrastructure monitoring system originally developed by Ethan Galstad in 1999. It provides monitoring of hosts, services, and network devices with alerting capabilities. Nagios pioneered the modern monitoring landscape and inspired many successors.
>
> **Common use cases / Типичные сценарии:** Host/service availability monitoring, network device monitoring, alerting via email/SMS/Slack, performance data collection, SLA reporting.
>
> **Status / Статус:** Nagios Core is still maintained but is considered a **legacy** monitoring solution. Modern alternatives include **Checkmk** (Nagios evolution with auto-discovery), **Zabbix** (enterprise-grade, auto-discovery), **Prometheus + Grafana** (cloud-native, metrics-focused), **Icinga 2** (modern Nagios fork with improved configuration and API).
>
> **Default ports / Порты по умолчанию:** `80/443` (Web UI via Apache), `5666/tcp` (NRPE agent), `5667/tcp` (NSCA passive checks)

---

## 📚 Table of Contents

1. [Installation & Configuration](#1.%20Installation%20&%20Configuration)
2. [Core Management](#2.%20Core%20Management)
3. [Sysadmin Operations](#3.%20Sysadmin%20Operations)
4. [NRPE Remote Monitoring](#4.%20NRPE%20Remote%20Monitoring)
5. [Security](#5.%20Security)
6. [Maintenance](#6.%20Maintenance)
7. [Troubleshooting & Tools](#7.%20Troubleshooting%20&%20Tools)
8. [Logrotate Configuration](#8.%20Logrotate%20Configuration)

---

## 1. Installation & Configuration

### Install Nagios Core

```bash
# RHEL/AlmaLinux — install from EPEL or compile from source
#
dnf install epel-release
dnf install nagios nagios-plugins-all nagios-plugins-nrpe

# Debian/Ubuntu
apt install nagios4 nagios-plugins nagios-nrpe-plugin

# From source (any distro)
wget "https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.0/nagios-4.5.0.tar.gz"
tar -xzf nagios-4.5.0.tar.gz
cd nagios-4.5.0
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
make install install-init install-commandmode install-config install-webconf
```

### Main Config Files

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

### Host Definition Example

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

### User Management

Using `htpasswd` for Basic Auth. / Использование `htpasswd` для Basic Auth.

```bash
# Create initial nagiosadmin user
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Add new user
htpasswd /usr/local/nagios/etc/htpasswd.users <USER>

# Don't forget to add contacts in objects/contacts.cfg
```

---

## 2. Core Management

### Verify Config

> [!IMPORTANT]
> Always verify configuration before restarting Nagios. A bad config will prevent the service from starting. / Всегда проверяйте конфигурацию перед перезапуском.

```bash
# Validate configuration
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Quick test (returns exit code 0 on success)
nagios -v /etc/nagios/nagios.cfg && echo "Config OK" || echo "Config ERROR"
```

### Service Control

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

### Plugins

Nagios plugins are located in `/usr/local/nagios/libexec/` or `/usr/lib64/nagios/plugins/`.

```bash
# Test Ping
./check_ping -H <HOST> -w 100.0,20% -c 500.0,60% -p 5

# Test HTTP
./check_http -H <HOST> -u /

# Test Disk
./check_disk -w 20% -c 10% -p /

# Test SMTP
./check_smtp -H <HOST>

# Test DNS
./check_dns -H <HOST> -s <DNS_SERVER>

# Test TCP port
./check_tcp -H <HOST> -p 443
```

### Important Paths

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

### Log Monitoring

```bash
# Follow main log
tail -f /usr/local/nagios/var/nagios.log

# Search for errors
grep -i error /usr/local/nagios/var/nagios.log | tail -20

# Check notification history
grep NOTIFICATION /usr/local/nagios/var/nagios.log | tail -20
```

### Firewall Configuration

```bash
# Allow web UI
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Allow NRPE
firewall-cmd --permanent --add-port=5666/tcp

# Allow NSCA (passive checks)
firewall-cmd --permanent --add-port=5667/tcp
firewall-cmd --reload
```

---

## 4. NRPE Remote Monitoring

### NRPE Architecture

| Component | Description / Описание |
|-----------|------------------------|
| NRPE Plugin (Server) | Installed on Nagios server, sends commands / На сервере Nagios |
| NRPE Daemon (Client) | Installed on remote host, executes checks / На удалённом хосте |

### Install NRPE Agent

```bash
# On monitored host
dnf install nrpe nagios-plugins-all    # RHEL/AlmaLinux
apt install nagios-nrpe-server nagios-plugins   # Debian/Ubuntu
```

### NRPE Configuration

`/etc/nagios/nrpe.cfg`

```ini
# Allow Nagios server IP
allowed_hosts=127.0.0.1,<NAGIOS_SERVER_IP>

# Command definitions
command[check_load]=/usr/lib64/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /
command[check_procs]=/usr/lib64/nagios/plugins/check_procs -w 250 -c 400
```

```bash
# Start NRPE service
systemctl enable --now nrpe
```

### Check NRPE Status

Run from Nagios Server to Client. / Запуск с сервера Nagios на клиент.

```bash
# Check NRPE connection
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP>
# Expected output: NRPE v4.x.x

# Run remote check
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP> -c check_load
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP> -c check_disk
```

---

## 5. Security

### Web UI Authentication

```bash
# Change nagiosadmin password
htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin
```

### NRPE Security

> [!WARNING]
> Always restrict `allowed_hosts` in NRPE config to your Nagios server IP only. An unrestricted NRPE allows remote command execution. / Всегда ограничивайте `allowed_hosts` только IP сервера Nagios.

```ini
# In nrpe.cfg
allowed_hosts=127.0.0.1,<NAGIOS_SERVER_IP>
dont_blame_nrpe=0    # Disable command arguments / Отключить аргументы команд (безопасно)
```

---

## 6. Maintenance

### Acknowledge Alert (CLI)

Via external command file (cmd.cgi). / Через файл внешних команд.

```bash
# Acknowledge host problem
now=$(date +%s)
commandfile='/usr/local/nagios/var/rw/nagios.cmd'
printf "[%lu] ACKNOWLEDGE_HOST_PROBLEM;<HOST>;1;1;1;<USER>;Admin Ack\n" $now > $commandfile

# Acknowledge service problem
printf "[%lu] ACKNOWLEDGE_SVC_PROBLEM;<HOST>;CPU Load;1;1;1;<USER>;Investigating\n" $now > $commandfile
```

### Schedule Downtime

```bash
# Schedule host downtime
now=$(date +%s)
end=$(date -d '+2 hours' +%s)
printf "[%lu] SCHEDULE_HOST_DOWNTIME;<HOST>;%lu;%lu;1;0;7200;<USER>;Maintenance window\n" $now $now $end > $commandfile
```

### Performance Data

Nagios writes perfdata to `host-perfdata` and `service-perfdata` files if enabled. Processed by PNP4Nagios or Graphite. / Nagios пишет perfdata в файлы, если включено. Обрабатывается PNP4Nagios или Graphite.

---

## 7. Troubleshooting & Tools

### Common Issues

#### 1. "Failed to start nagios" / Nagios

```bash
# Always check config first
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Check permissions
ls -la /usr/local/nagios/var/rw/nagios.cmd
chown nagios:nagios /usr/local/nagios/var/rw/nagios.cmd
```

#### 2. Web UI Not Loading

```bash
# Check Apache
systemctl status httpd
systemctl status apache2

# Check CGI configuration
cat /etc/httpd/conf.d/nagios.conf
```

#### 3. No Notifications

```bash
# Check notification log
grep NOTIFICATION /usr/local/nagios/var/nagios.log | tail -20

# Check notification settings
grep notification /usr/local/nagios/etc/objects/contacts.cfg
```

#### 4. Agent (NRPE) Not Responding

```bash
# Test NRPE from server
/usr/local/nagios/libexec/check_nrpe -H <CLIENT_IP>

# On client: check NRPE service
systemctl status nrpe
ss -tlnp | grep 5666

# Check firewall on client
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

## Documentation Links

- **Official Documentation:** https://www.nagios.org/documentation/
- **Nagios Core Manual:** https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/
- **Plugin Development:** https://nagios-plugins.org/doc/guidelines.html
- **NRPE Documentation:** https://github.com/NagiosEnterprises/nrpe
- **Nagios Exchange (Plugins):** https://exchange.nagios.org/
- **Community Forum:** https://support.nagios.com/forum/

---
