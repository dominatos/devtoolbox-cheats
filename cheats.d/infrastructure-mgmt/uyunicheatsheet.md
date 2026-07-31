---
Title: Uyuni
Group: Infrastructure Management
Icon: 🔧
Order: 1
tags:
  - infrastructure
  - sysadmin
  - devops
---

# Uyuni — Infrastructure & Configuration Management

**Description / Описание:**
Uyuni is an open-source systems management solution for software-defined infrastructure. It provides patch management, configuration management, system provisioning, monitoring integration, and software channel management for large-scale Linux environments. Uyuni is the community upstream project for **SUSE Manager**. It uses **Salt** as its configuration management engine and manages systems via a web-based UI, CLI (`spacecmd`), and XML-RPC API.

> [!NOTE]
> **Current Status:** Uyuni is actively maintained and is the recommended path for SUSE Manager community users. It requires **openSUSE Leap 15.x** as the host OS. For environments not running openSUSE, consider containerized deployment via `mgradm`. Modern alternatives include **Foreman/Katello** (Red Hat ecosystem), **Landscape** (Ubuntu/Canonical), and **Ansible AWX/Semaphore** (agentless automation). / **Текущий статус:** Uyuni активно поддерживается. Требует **openSUSE Leap 15.x**. Альтернативы: **Foreman/Katello**, **Landscape**, **Ansible AWX/Semaphore**.

> **Default Ports:** Web UI: `443` (HTTPS), `80` (HTTP redirect) | Salt Publisher: `4505` | Salt Return: `4506` | Jabber/OSAD: `5222`, `5269`

---

## Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Salt & Configuration Management](#Salt%20&%20Configuration%20Management)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Security](#Security)
- [Backup & Restore](#Backup%20&%20Restore)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Logrotate Configuration](#Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

> [!IMPORTANT]
> Uyuni requires openSUSE Leap 15.x as the host OS. It cannot be installed on RHEL/Debian directly. Use the official container or VM image for other platforms. / Uyuni требует openSUSE Leap 15.x. Для других платформ используйте контейнерный или VM-образ.

### Repository Setup

```bash
# Add Uyuni server repository
zypper addrepo https://download.opensuse.org/repositories/systemsmanagement:/Uyuni:/Stable/openSUSE_Leap_15.6/ Uyuni-Stable

# Refresh repos
zypper refresh
```

### Install Uyuni Server

```bash
# Install the Uyuni server pattern
zypper install -t pattern uyuni_server

# Or install via container (recommended for quick setup)
mgradm install podman <FQDN_HOSTNAME>
```

### Deployment Methods Comparison

| Method / Метод | Complexity / Сложность | Best for / Лучше для... |
|:---|:---|:---|
| **Pattern install (`zypper`)** | Low / Низкая | Traditional bare-metal or VM installs / Традиционная установка |
| **Container (`mgradm`)** | Low / Низкая | Quick setup, isolation, portability / Быстрый старт, изоляция |
| **Manual setup** | High / Высокая | Custom or hardened environments / Кастомные окружения |

### Initial Setup Wizard

After installation, access:

```bash
# Web UI first-user setup
https://<HOST>/rhn/newlogin/CreateFirstUser.do
```

Configure via YaST:

```bash
yast2 susemanager_setup  # Interactive setup wizard / Интерактивный мастер настройки
```

### Essential Configuration Files

#### Spacewalk config (rhn.conf)

`/etc/rhn/rhn.conf`

```ini
# Database connection
db_host = localhost
db_name = susemanager
db_user = susemanager
db_password = <PASSWORD>

# Web UI hostname / FQDN
java.hostname = <HOST>

# Maximum upload size
web.maximum_upload_size = 256
```

#### Salt Master configuration

`/etc/salt/master.d/susemanager.conf`

```yaml
# Uyuni auto-sign minions (use carefully in production)
auto_accept: False

# Timeout for Salt operations
timeout: 120
gather_job_timeout: 120
```

#### Taskomatic (scheduler)

`/etc/rhn/taskomatic.conf`

```ini
# JVM memory settings
JAVA_OPTS="-Xms512m -Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Database Initialization

```bash
# Setup PostgreSQL DB for Uyuni
spacewalk-setup --disconnected --answer-file=/root/answers.txt

# Or use the automated db-setup
uyuni-setup --setup
```

`/root/answers.txt` (example template):

```ini
admin-email = admin@<HOST>
ssl-set-org = <ORG_NAME>
ssl-set-org-unit = IT
ssl-set-city = <CITY>
ssl-set-state = <STATE>
ssl-set-country = <COUNTRY_CODE>
ssl-password = <PASSWORD>
db-host = localhost
db-port = 5432
db-name = susemanager
db-user = susemanager
db-pass = <PASSWORD>
enable-tftp = y
```

---

## Core Management

### Web UI Access

```bash
# Web UI endpoints
https://<HOST>/         # Main dashboard / Главная панель
https://<HOST>/rhn/     # Legacy namespace / Старое пространство имён
```

### spacecmd CLI Tool / CLI

`spacecmd` is the primary CLI for Uyuni management. / `spacecmd` — основной CLI для управления Uyuni.

```bash
# Login (interactive prompt)
spacecmd -u <USER> -p <PASSWORD>

# List all registered systems
spacecmd system_list

# Get system details
spacecmd system_details <SYSTEM_NAME>

# List all software channels
spacecmd softwarechannel_list

# List activation keys
spacecmd activationkey_list

# List configuration channels
spacecmd configchannel_list

# List organizations
spacecmd org_list

# List users
spacecmd user_list

# Apply errata to a system
spacecmd errata_apply <ERRATA_ID> -s <SYSTEM_NAME>
```

### System Registration

```bash
# Register a minion via bootstrap script (generated from UI)
curl -Sks https://<HOST>/pub/bootstrap/bootstrap.sh | bash

# Check minion key status on server
salt-key -L

# Accept all pending minion keys
salt-key -A

# Accept specific minion key
salt-key -a <MINION_ID>

# Reject a key
salt-key -r <MINION_ID>
```

> [!WARNING]
> Using `salt-key -A` accepts ALL pending keys including potentially unauthorized ones. In production, always verify minion identity before accepting keys. / `salt-key -A` принимает ВСЕ ожидающие ключи, включая потенциально неавторизованные. В продакшене проверяйте идентичность миньонов.

### Software Channels

| Operation / Операция | Command / Команда |
|:---|:---|
| List channels / Список каналов | `spacecmd softwarechannel_list` |
| Show channel details / Детали канала | `spacecmd softwarechannel_details <CHANNEL>` |
| List packages in channel / Пакеты в канале | `spacecmd softwarechannel_listpackages <CHANNEL>` |
| Subscribe system to channel / Подписать систему | `spacecmd system_addchildchannel <SYSTEM> <CHANNEL>` |
| Clone a channel / Клонировать канал | `spacecmd softwarechannel_clone -s <SRC> -n <NAME> -l <LABEL>` |

---

## Salt & Configuration Management

> [!NOTE]
> Uyuni uses Salt as its configuration management engine. Salt commands run via `salt` CLI on the Uyuni server or through the Web UI (Remote Command / States). / Uyuni использует Salt в качестве движка управления конфигурацией. Команды Salt запускаются через CLI на сервере или через веб-интерфейс.

### Salt Command Reference

```bash
# Test connectivity to all minions
salt '*' test.ping

# Test connectivity to specific minion
salt '<MINION_ID>' test.ping

# Run command on all minions
salt '*' cmd.run 'uptime'

# Run command on group of minions by grain
salt -G 'os:openSUSE Leap' cmd.run 'zypper ref'

# Apply a Salt state
salt '<MINION_ID>' state.apply <STATE_NAME>

# Apply highstate (all assigned states)
salt '<MINION_ID>' state.highstate

# Run a formula
salt '<MINION_ID>' state.apply formulas.<FORMULA_NAME>

# Refresh grains
salt '<MINION_ID>' saltutil.refresh_grains

# List available modules
salt '<MINION_ID>' sys.list_modules

# Get minion grains (system info)
salt '<MINION_ID>' grains.items
```

### Salt Targeting Methods

| Method / Метод | Flag / Флаг | Example / Пример | Description / Описание |
|:---|:---|:---|:---|
| Glob / Маска | (default) | `salt 'web*' test.ping` | Wildcard match on minion ID / Маска по ID |
| Grain / Grain | `-G` | `salt -G 'os:CentOS' test.ping` | Match by system fact / По факту системы |
| List / Список | `-L` | `salt -L 'host1,host2' test.ping` | Explicit list / Явный список |
| PCRE regex / Регулярное выражение | `-E` | `salt -E 'web[0-9]+' test.ping` | Regex match / Регулярное выражение |
| Compound / Комбинированный | `-C` | `salt -C 'G@os:SLES and web*' test.ping` | Combined / Комбинированный |
| Nodegroup / Группа | `-N` | `salt -N databases test.ping` | Predefined group / Предопределённая группа |

### Configuration Channels

```bash
# List config channels
spacecmd configchannel_list

# Create a config channel
spacecmd configchannel_create -n "<NAME>" -l <LABEL> -d "<DESCRIPTION>"

# Add a file to a config channel
spacecmd configchannel_addfile <CHANNEL_LABEL> -p /etc/myapp/config.conf -f /local/path/config.conf

# List files in a channel
spacecmd configchannel_listfiles <CHANNEL_LABEL>

# Deploy config to system
spacecmd configchannel_deploy -s <SYSTEM_NAME> <CHANNEL_LABEL>
```

### Formulas

Formulas are Salt states with a YAML-based configuration UI. / Формулы — это Salt states с веб-интерфейсом конфигурации на основе YAML.

```bash
# List available formulas
salt '<MINION_ID>' saltutil.list_states

# Show formula data
spacecmd system_runscript -s <SYSTEM> -e bash -c 'ls /usr/share/susemanager/formulas/'

# Apply formula state manually
salt '<MINION_ID>' state.apply formulas.<FORMULA_NAME>
```

---

## Sysadmin Operations

### Service Management

```bash
# Restart all Uyuni services
spacewalk-service restart

# Start all services
spacewalk-service start

# Stop all services
spacewalk-service stop

# Check status of all services
spacewalk-service status

# Restart only Taskomatic (scheduler)
systemctl restart taskomatic

# Restart Salt Master
systemctl restart salt-master

# Restart Tomcat (web app)
systemctl restart tomcat

# Restart PostgreSQL
systemctl restart postgresql
```

### Individual Service Stack

| Service / Сервис | Unit Name | Port / Порт | Description / Описание |
|:---|:---|:---|:---|
| Web App (Tomcat) | `tomcat` | `8080` (internal) | Java web frontend / Java веб-фронтенд |
| Scheduler | `taskomatic` | — | Background jobs / Фоновые задачи |
| Salt Master | `salt-master` | `4505`, `4506` | Config management engine / Движок упр. конфиг. |
| Database | `postgresql` | `5432` | Persistent storage / Хранилище данных |
| Apache/httpd | `apache2` | `80`, `443` | Reverse proxy / Обратный прокси |
| OSAD | `osa-dispatcher` | `5222` | Push notification / Push-уведомления |
| Search | `rhn-search` | — | Search indexer / Индексатор поиска |

### Important Paths

| Path / Путь | Description / Описание |
|:---|:---|
| `/etc/rhn/rhn.conf` | Main Uyuni configuration / Основной конфиг |
| `/etc/salt/master.d/` | Salt master config fragments / Фрагменты конфига Salt |
| `/srv/pillar/` | Salt pillars (sensitive data) / Salt pillars (секретные данные) |
| `/srv/salt/` | Salt states directory / Каталог Salt states |
| `/var/log/rhn/` | Uyuni application logs / Логи приложения |
| `/var/log/salt/` | Salt master/minion logs / Логи Salt |
| `/var/spacewalk/` | Uyuni data (packages, repos) / Данные Uyuni (пакеты, репозитории) |
| `/var/cache/rhn/` | Cache directory / Кэш |
| `/usr/share/susemanager/formulas/` | Installed formulas / Установленные формулы |
| `/root/ssl-build/` | Generated SSL certificates / Сгенерированные SSL-сертификаты |

### Log Locations

```bash
# Main application log
tail -f /var/log/rhn/rhn_web_api.log

# Taskomatic scheduler log
tail -f /var/log/rhn/rhn_taskomatic_daemon.log

# Salt master log
tail -f /var/log/salt/master

# Tomcat log
tail -f /var/log/tomcat/catalina.out

# spacewalk-repo-sync log
tail -f /var/log/rhn/reposync/<CHANNEL_LABEL>.log
```

### JVM / Performance Tuning

#### Taskomatic JVM Settings

`/etc/rhn/taskomatic.conf`

```ini
# Increase heap for large environments (> 1000 systems)
JAVA_OPTS="-Xms1024m -Xmx4096m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/rhn/"
```

#### Tomcat JVM Settings

`/etc/tomcat/conf.d/tomcat.conf` (or `/usr/share/tomcat/conf/catalina.sh`)

```ini
JAVA_OPTS="-Xms512m -Xmx2048m -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"
```

> [!TIP]
> For environments with 500+ systems, increase PostgreSQL `shared_buffers` to 25% of RAM and `max_connections` to at least 200 in `/etc/postgresql/<VERSION>/postgresql.conf`. / Для окружений с 500+ систем увеличьте `shared_buffers` до 25% RAM и `max_connections` до 200 в конфиге PostgreSQL.

### JVM Sizing Guidelines

| Systems / Систем | Taskomatic `-Xmx` | Tomcat `-Xmx` | PostgreSQL `shared_buffers` |
|:---|:---|:---|:---|
| < 100 | 2 GB | 1 GB | 256 MB |
| 100–500 | 4 GB | 2 GB | 1 GB |
| 500–2000 | 8 GB | 4 GB | 4 GB (25% RAM) |
| 2000+ | 16 GB | 8 GB | 8 GB (25% RAM) |

### Repository Synchronization

```bash
# Sync a specific software channel
spacewalk-repo-sync -c <CHANNEL_LABEL>

# Sync all channels
spacewalk-repo-sync --synchronize-all

# Sync with detailed output
spacewalk-repo-sync -c <CHANNEL_LABEL> --verbose

# List available metadata source types
spacewalk-repo-sync --list-types
```

### Firewall Configuration

```bash
# Required ports for Uyuni server
firewall-cmd --permanent --add-port=80/tcp    # HTTP redirect / Редирект HTTP
firewall-cmd --permanent --add-port=443/tcp   # HTTPS Web UI / Веб-интерфейс
firewall-cmd --permanent --add-port=4505/tcp  # Salt publisher / Публикация Salt
firewall-cmd --permanent --add-port=4506/tcp  # Salt return bus / Шина ответов Salt
firewall-cmd --permanent --add-port=5222/tcp  # OSAD push / Push OSAD
firewall-cmd --permanent --add-port=5269/tcp  # Jabber federation
firewall-cmd --reload
```

---

## Security

### User & Role Management

```bash
# List all users
spacecmd user_list

# Create a user
spacecmd user_create -u <USER> -p <PASSWORD> -e <EMAIL> -f <FIRST_NAME> -l <LAST_NAME>

# Delete a user
spacecmd user_delete <USER>

# List roles of a user
spacecmd user_listroles <USER>

# Add role to user
spacecmd user_addrole <USER> <ROLE>

# Remove role from user
spacecmd user_removerole <USER> <ROLE>
```

### Available Roles

| Role / Роль | Description / Описание |
|:---|:---|
| `org_admin` | Full organization admin / Полный администратор организации |
| `system_group_admin` | Manage system groups / Управление группами систем |
| `channel_admin` | Manage software channels / Управление каналами ПО |
| `config_admin` | Manage config channels / Управление каналами конфигурации |
| `activation_key_admin` | Manage activation keys / Управление ключами активации |
| `image_admin` | Manage container/OS images / Управление образами |

### SSL Certificate Management

```bash
# View current certificate info
openssl x509 -in /etc/apache2/ssl.crt/spacewalk.crt -noout -text | grep -E "Subject:|Not After"

# Regenerate self-signed SSL certificate
rhn-ssl-tool --gen-server-cert --dir=/root/ssl-build \
  --set-country=<COUNTRY_CODE> --set-state=<STATE> --set-city=<CITY> \
  --set-org=<ORG_NAME> --set-org-unit=IT \
  --set-hostname=<HOST> --set-email=admin@<HOST> \
  --set-cname=<HOST>

# Deploy new certificate
rhn-deploy-ca-cert --dir=/root/ssl-build --target=/etc/apache2/ssl.crt/

# Rebuild CA certificate RPM for distribution to clients
rhn-ssl-tool --gen-ca --dir=/root/ssl-build \
  --set-org=<ORG_NAME> --set-common-name=<HOST> \
  --password=<PASSWORD>
```

> [!WARNING]
> After regenerating SSL certificates, all registered minions will need to re-accept the new CA certificate. Plan for a maintenance window. / После перегенерации SSL-сертификатов все зарегистрированные миньоны должны принять новый CA-сертификат. Планируйте окно обслуживания.

### Activation Keys

```bash
# List activation keys
spacecmd activationkey_list

# Create an activation key
spacecmd activationkey_create -n "<DESCRIPTION>" -b <BASE_CHANNEL>

# Add entitlement to key
spacecmd activationkey_addentitlement <KEY_ID> <ENTITLEMENT>

# Add child channel to key
spacecmd activationkey_addchildchannel <KEY_ID> <CHANNEL>
```

---

## Backup & Restore

> [!CAUTION]
> Uyuni stores all data (packages, repositories) in `/var/spacewalk/`. This directory can be very large (hundreds of GB). Always verify available disk space before backup. / Uyuni хранит все данные в `/var/spacewalk/`. Этот каталог может быть очень большим. Всегда проверяйте свободное место перед резервным копированием.

### Production Runbook: Full Backup

1. **Stop non-critical services to ensure consistency / Остановить некритические сервисы для обеспечения согласованности:**

   ```bash
   spacewalk-service stop
   ```

2. **Backup PostgreSQL database / Резервная копия базы данных PostgreSQL:**

   ```bash
   # Dump Uyuni database / Дамп базы данных Uyuni
   sudo -u postgres pg_dump susemanager | gzip > /backup/uyuni_db_$(date +%F).sql.gz

   # Verify dump / Проверить дамп
   ls -lh /backup/uyuni_db_$(date +%F).sql.gz
   ```

3. **Backup configuration files / Резервная копия конфигурационных файлов:**

   ```bash
   tar -czf /backup/uyuni_conf_$(date +%F).tar.gz \
     /etc/rhn/ \
     /etc/salt/ \
     /root/ssl-build/ \
     /srv/pillar/ \
     /srv/salt/
   ```

4. **Backup package repository (optional, large) / Резервная копия репозитория пакетов (опционально, большой объём):**

   ```bash
   # Only if you cannot re-sync from upstream / Только если не можете пересинхронизировать из upstream
   rsync -av --delete /var/spacewalk/ /backup/var-spacewalk/
   ```

5. **Start services / Запустить сервисы:**

   ```bash
   spacewalk-service start
   ```

### Production Runbook: Restore

> [!CAUTION]
> Restore will overwrite all current data. Perform only on a clean system or after understanding the full impact. / Восстановление перезапишет все данные. Выполняйте только на чистой системе.

1. **Stop all services / Остановить все сервисы:**

   ```bash
   spacewalk-service stop
   ```

2. **Restore database / Восстановить базу данных:**

   ```bash
   sudo -u postgres dropdb susemanager
   sudo -u postgres createdb susemanager
   gunzip -c /backup/uyuni_db_<DATE>.sql.gz | sudo -u postgres psql susemanager
   ```

3. **Restore configuration / Восстановить конфигурацию:**

   ```bash
   tar -xzf /backup/uyuni_conf_<DATE>.tar.gz -C /
   ```

4. **Start services and verify / Запустить сервисы и проверить:**

   ```bash
   spacewalk-service start
   spacewalk-service status
   ```

### Incremental Content Backup Script

```bash
#!/bin/bash
# Uyuni Incremental Backup Script
BACKUP_DIR=/backup/uyuni
DATE=$(date +%F)
mkdir -p "$BACKUP_DIR/$DATE"

# DB dump
sudo -u postgres pg_dump susemanager | gzip > "$BACKUP_DIR/$DATE/db.sql.gz"

# Config
tar -czf "$BACKUP_DIR/$DATE/conf.tar.gz" /etc/rhn/ /etc/salt/ /root/ssl-build/ /srv/pillar/ /srv/salt/

# Keep last 7 days
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR/$DATE"
```

---

## Troubleshooting & Tools

### Common Issues

#### 1. Web UI Not Loading

```bash
# Check Tomcat status and logs
systemctl status tomcat
tail -50 /var/log/tomcat/catalina.out

# Check Apache status
systemctl status apache2
tail -20 /var/log/apache2/error_log

# Restart web stack
systemctl restart tomcat && systemctl restart apache2
```

#### 2. Minions Not Responding

```bash
# Check Salt master connectivity
salt '<MINION_ID>' test.ping

# Check salt-key state
salt-key -L

# Test connection from minion side (on minion)
salt-minion -l debug   # Run in foreground for debug output / Запустить в foreground для отладки

# Check Salt master log
tail -100 /var/log/salt/master | grep -i error
```

#### 3. Repository Sync Failures

```bash
# Check sync log for specific channel
tail -f /var/log/rhn/reposync/<CHANNEL_LABEL>.log

# Re-run sync verbosely
spacewalk-repo-sync -c <CHANNEL_LABEL> --verbose

# Check disk space (spacewalk data dir)
df -h /var/spacewalk
```

#### 4. Taskomatic Jobs Stuck

```bash
# Check Taskomatic log
tail -100 /var/log/rhn/rhn_taskomatic_daemon.log

# Restart Taskomatic
systemctl restart taskomatic

# Check DB connection from Uyuni
spacecmd -- system_list  # If this hangs, DB connection is likely broken / Если зависает — проблема с БД
```

#### 5. High Memory Usage

```bash
# Check JVM heap usage
jcmd $(pgrep -f taskomatic) VM.heap_info 2>/dev/null || \
  jstat -gc $(pgrep -f catalina) 2000 5

# Check overall system memory
free -h && top -b -n1 | head -20
```

### Common Issues Quick Reference

| Issue / Проблема | Fix / Решение |
|:---|:---|
| **Web UI blank/502** | Restart `tomcat` + `apache2`, check `catalina.out` / Перезапустить `tomcat` + `apache2` |
| **Minions not responding** | Check `salt-key -L`, verify ports `4505/4506` / Проверить ключи, порты `4505/4506` |
| **Repo sync fails** | Check `/var/log/rhn/reposync/*.log`, verify disk space / Проверить логи и место на диске |
| **Taskomatic stuck** | Restart `taskomatic`, check DB connection / Перезапустить `taskomatic`, проверить БД |
| **OOM errors** | Increase JVM `-Xmx` in `taskomatic.conf` / Увеличить `-Xmx` |
| **SSL cert expired** | Regenerate with `rhn-ssl-tool` / Перегенерировать через `rhn-ssl-tool` |

### Database Maintenance

```bash
# Check database size
sudo -u postgres psql susemanager -c "SELECT pg_size_pretty(pg_database_size('susemanager'));"

# List largest tables
sudo -u postgres psql susemanager -c "
SELECT schemaname, relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;"

# Vacuum analyze for performance / Vacuum analyze
sudo -u postgres psql susemanager -c "VACUUM ANALYZE;"

# Run spacewalk built-in cleanup
spacewalk-data-fsck    # Check data integrity / Проверить целостность данных
```

> [!TIP]
> Run `satellite-sync` (depending on version) to re-sync channels if the database and filesystem are out of sync. / Запустите `satellite-sync` для повторной синхронизации каналов, если база данных и файловая система рассинхронизированы.

### Useful Diagnostic Commands

```bash
# Check overall Uyuni health
spacewalk-service status

# Check spacewalk DB connectivity
spacewalk-sql --select-mode -
# Then type: SELECT 1;

# Inspect Salt event bus (live)
salt-run state.event pretty=True

# List all pending Salt jobs
salt-run jobs.list_jobs

# Kill a stuck Salt job
salt-run jobs.kill <JID>

# Verify SSL cert expiry
echo | openssl s_client -connect <HOST>:443 2>/dev/null | openssl x509 -noout -dates

# Show registered system count
spacecmd system_list | wc -l
```

---

## Logrotate Configuration

`/etc/logrotate.d/uyuni`

```conf
# Uyuni application logs
/var/log/rhn/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 tomcat www
    sharedscripts
    postrotate
        # Signal Tomcat to reopen log files / Сигнал Tomcat для переоткрытия логов
        /bin/kill -HUP $(cat /var/run/tomcat/tomcat.pid 2>/dev/null) 2>/dev/null || true
    endscript
}

# Salt master logs
/var/log/salt/*.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        systemctl kill --signal=HUP salt-master 2>/dev/null || true
    endscript
}

# Taskomatic scheduler logs
/var/log/rhn/rhn_taskomatic_daemon.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 tomcat www
}

# Repo sync logs (can grow large)
/var/log/rhn/reposync/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
```

> [!TIP]
> Uyuni generates significant log volume during repository synchronization. Consider adjusting `rotate` count for `reposync` logs based on your sync frequency and available disk space. / Uyuni генерирует значительный объём логов при синхронизации репозиториев. Настройте `rotate` для `reposync` в зависимости от частоты синхронизации.

---

## Documentation Links

- **Uyuni Official Documentation:** [https://www.uyuni-project.org/uyuni-docs/](https://www.uyuni-project.org/uyuni-docs/)
- **Uyuni Server Administration Guide:** [https://www.uyuni-project.org/uyuni-docs/en/uyuni/administration/](https://www.uyuni-project.org/uyuni-docs/en/uyuni/administration/)
- **Uyuni Client Configuration Guide:** [https://www.uyuni-project.org/uyuni-docs/en/uyuni/client-configuration/](https://www.uyuni-project.org/uyuni-docs/en/uyuni/client-configuration/)
- **Uyuni GitHub Repository:** [https://github.com/uyuni-project/uyuni](https://github.com/uyuni-project/uyuni)
- **SUSE Manager Documentation (commercial version):** [https://documentation.suse.com/suma/](https://documentation.suse.com/suma/)
- **SaltStack Documentation:** [https://docs.saltproject.io/en/latest/](https://docs.saltproject.io/en/latest/)
- **spacecmd Reference:** [https://www.uyuni-project.org/uyuni-docs/en/uyuni/reference/spacecmd/](https://www.uyuni-project.org/uyuni-docs/en/uyuni/reference/spacecmd/)
