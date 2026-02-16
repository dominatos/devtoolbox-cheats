Title: 📈 Zabbix Server
Group: Monitoring
Icon: 📈
Order: 3

# Zabbix Sysadmin Cheatsheet

> **Context:** Zabbix is an enterprise-class open source distributed monitoring solution. / Zabbix - это решение корпоративного уровня с открытым исходным кодом для распределенного мониторинга.
> **Role:** Sysadmin / DevOps
> **Version:** 6.0 LTS / 7.0 LTS

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration--установка-и-конфигурация)
2. [Core Management](#core-management--базовое-управление)
3. [Sysadmin Operations](#sysadmin-operations--операции-сисадмина)
4. [Security](#security--безопасность)
5. [Backup & Restore](#backup--restore--резервное-копирование-и-восстановление)
6. [Troubleshooting & Tools](#troubleshooting--tools--устранение-неполадок-и-инструменты)
7. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## 1. Installation & Configuration / Установка и конфигурация

### Repository Setup (AlmaLinux/RHEL) / Настройка репозитория
```bash
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
dnf clean all
```

### Install Server & Agent / Установка сервера и агента
```bash
dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2
```

### Essential Configs / Основные конфиги

**Server:** `/etc/zabbix/zabbix_server.conf`

```ini
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<PASSWORD>
```

**Agent:** `/etc/zabbix/zabbix_agentd.conf` (or `zabbix_agent2.conf`)

```ini
# Server IP for passive checks / IP сервера для пассивных проверок
Server=<IP_SERVER>

# Server IP for active checks / IP сервера для активных проверок
ServerActive=<IP_SERVER>

# Hostname must match frontend config / Hostname должен совпадать с конфигом в веб-интерфейсе
Hostname=<HOST>
```

---

## 2. Core Management / Базовое управление

### CLI Tools / CLI Инструменты

**zabbix_get** (Test passive checks / Тест пассивных проверок):
Run from server or proxy:
```bash
zabbix_get -s <HOST_IP> -k "system.cpu.load[all,avg1]"
```

**zabbix_sender** (Push data / Отправка данных):
```bash
zabbix_sender -z <IP_SERVER> -s "<HOST>" -k "custom.key" -o "value"
```

---

## 3. Sysadmin Operations / Операции сисадмина

### Service Management / Управление сервисом

```bash
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-agent2 httpd php-fpm
```

### Logs / Логи

*   **Server:** `/var/log/zabbix/zabbix_server.log`
*   **Agent:** `/var/log/zabbix/zabbix_agentd.log`
*   **Agent 2:** `/var/log/zabbix/zabbix_agent2.log`
*   **Web (Apache):** `/var/log/httpd/error_log`

### Database Creation / Создание базы данных
```bash
mysql -uroot -p
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by '<PASSWORD>';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit;

# Import schema / Импорт схемы
zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p zabbix
```

---

## 4. Security / Безопасность

### Firewall / Фаервол

```bash
# Agent (passive) listens on 10050 / Агент (пассивный) слушает 10050
firewall-cmd --permanent --add-port=10050/tcp

# Server/Proxy listens on 10051 / Сервер/Прокси слушает 10051
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --reload
```

### Encryption (PSK) / Шифрование (PSK)
Generate PSK:
```bash
openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk
```
Update `zabbix_agentd.conf`:
```ini
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=PSK_001
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
```

---

## 5. Backup & Restore / Резервное копирование и восстановление

### Database Backup / Бэкап БД
```bash
mysqldump -uzabbix -p<PASSWORD> --single-transaction --quick --lock-tables=false zabbix | gzip > zabbix_backup_$(date +%F).sql.gz
```

### Config Backup / Бэкап конфигов
```bash
tar -czf zabbix_conf_backup_$(date +%F).tar.gz /etc/zabbix /usr/share/zabbix/conf
```

---

## 6. Troubleshooting & Tools / Устранение неполадок и инструменты

### Common Issues / Частые проблемы

1.  **"Zabbix server is not running" in Frontend**
    *   Check SELinux: `setsebool -P zabbix_can_network 1`
    *   Check `zabbix_server.log` for DB connection errors.

2.  **Agent not reachable**
    *   Verify `Server=` IP in agent config matches actual zabbix server IP.
    *   Check firewall on agent host.

3.  **Poller processes busy**
    *   Increase `StartPollers` in `zabbix_server.conf`.
    *   Check "Zabbix internal process busy %" graph.

### Debugging / Отладка

Enable debug logs temporarily (Level 4):
```bash
zabbix_server -R log_level_increase
# ... wait for issue / ждем проблему ...
zabbix_server -R log_level_decrease
```

---

## 7. Logrotate Configuration / Конфигурация Logrotate

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
> Zabbix handles log rotation via config (`LogFileSize` parameter). External logrotate is optional.
> Zabbix управляет ротацией через конфиг (`LogFileSize`). Внешний logrotate опционален.

---

