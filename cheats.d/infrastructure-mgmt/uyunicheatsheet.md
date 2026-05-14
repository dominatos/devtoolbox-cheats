---
Title: Uyuni
Group: Infrastructure Management
Icon: 🔧
Order: 1
---

# Uyuni — Infrastructure & Configuration Management

**Description / Описание:**
Uyuni is an open-source systems management solution for software-defined infrastructure. It provides patch management, configuration management, system provisioning, monitoring integration, and software channel management for large-scale Linux environments. Uyuni is the community upstream project for **SUSE Manager**. It uses **Salt** as its configuration management engine and manages systems via a web-based UI, CLI (`spacecmd`), and XML-RPC API.

> [!NOTE]
> **Current Status:** Uyuni is actively maintained and is the recommended path for SUSE Manager community users. It requires **openSUSE Leap 15.x** as the host OS. For environments not running openSUSE, consider containerized deployment via `mgradm`. Modern alternatives include **Foreman/Katello** (Red Hat ecosystem), **Landscape** (Ubuntu/Canonical), and **Ansible AWX/Semaphore** (agentless automation). / **Текущий статус:** Uyuni активно поддерживается. Требует **openSUSE Leap 15.x**. Альтернативы: **Foreman/Katello**, **Landscape**, **Ansible AWX/Semaphore**.

> **Default Ports:** Web UI: `443` (HTTPS), `80` (HTTP redirect) | Salt Publisher: `4505` | Salt Return: `4506` | Jabber/OSAD: `5222`, `5269`

---

## Table of Contents

1. [Installation & Configuration](#installation--configuration)
2. [Core Management](#core-management)
3. [Salt & Configuration Management](#salt--configuration-management)
4. [Sysadmin Operations](#sysadmin-operations)
5. [Security](#security)
6. [Backup & Restore](#backup--restore)
7. [Troubleshooting & Tools](#troubleshooting--tools)
8. [Logrotate Configuration](#logrotate-configuration)
9. [Documentation Links](#documentation-links)

---

## Installation & Configuration

> [!IMPORTANT]
> Uyuni requires openSUSE Leap 15.x as the host OS. It cannot be installed on RHEL/Debian directly. Use the official container or VM image for other platforms. / Uyuni требует openSUSE Leap 15.x. Для других платформ используйте контейнерный или VM-образ.

### Repository Setup / Настройка репозитория

```bash
# Add Uyuni server repository / Добавить репозиторий Uyuni Server
zypper addrepo https://download.opensuse.org/repositories/systemsmanagement:/Uyuni:/Stable/openSUSE_Leap_15.6/ Uyuni-Stable

# Refresh repos / Обновить репозитории
zypper refresh
```

### Install Uyuni Server / Установка сервера

```bash
# Install the Uyuni server pattern / Установить паттерн Uyuni server
zypper install -t pattern uyuni_server

# Or install via container (recommended for quick setup) / Через контейнер (рекомендуется для быстрого старта)
mgradm install podman <FQDN_HOSTNAME>
```

### Deployment Methods Comparison / Сравнение методов развёртывания

| Method / Метод | Complexity / Сложность | Best for / Лучше для... |
|:---|:---|:---|
| **Pattern install (`zypper`)** | Low / Низкая | Traditional bare-metal or VM installs / Традиционная установка |
| **Container (`mgradm`)** | Low / Низкая | Quick setup, isolation, portability / Быстрый старт, изоляция |
| **Manual setup** | High / Высокая | Custom or hardened environments / Кастомные окружения |

### Initial Setup Wizard / Первоначальная настройка

After installation, access:

```bash
# Web UI first-user setup / Создание первого пользователя через веб
https://<HOST>/rhn/newlogin/CreateFirstUser.do
```

Configure via YaST:

```bash
yast2 susemanager_setup  # Interactive setup wizard / Интерактивный мастер настройки
```

### Essential Configuration Files / Основные конфигурационные файлы

#### Spacewalk config (rhn.conf) / Конфигурация Spacewalk

`/etc/rhn/rhn.conf`

```ini
# Database connection / Подключение к БД
db_host = localhost
db_name = susemanager
db_user = susemanager
db_password = <PASSWORD>

# Web UI hostname / FQDN веб-интерфейса
java.hostname = <HOST>

# Maximum upload size / Максимальный размер загрузки (MB)
web.maximum_upload_size = 256
```

#### Salt Master configuration / Конфигурация Salt Master

`/etc/salt/master.d/susemanager.conf`

```yaml
# Uyuni auto-sign minions (use carefully in production) / Авто-подпись миньонов (осторожно в продакшн)
auto_accept: False

# Timeout for Salt operations / Таймаут для операций Salt
timeout: 120
gather_job_timeout: 120
```

#### Taskomatic (scheduler) / Планировщик Taskomatic

`/etc/rhn/taskomatic.conf`

```ini
# JVM memory settings / Настройки памяти JVM
JAVA_OPTS="-Xms512m -Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Database Initialization / Инициализация базы данных

```bash
# Setup PostgreSQL DB for Uyuni / Настройка PostgreSQL для Uyuni
spacewalk-setup --disconnected --answer-file=/root/answers.txt

# Or use the automated db-setup / Или автоматическая настройка БД
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

### Web UI Access / Доступ к веб-интерфейсу

```bash
# Web UI endpoints / Адреса веб-интерфейса
https://<HOST>/         # Main dashboard / Главная панель
https://<HOST>/rhn/     # Legacy namespace / Старое пространство имён
```

### spacecmd CLI Tool / CLI инструмент spacecmd

`spacecmd` is the primary CLI for Uyuni management. / `spacecmd` — основной CLI для управления Uyuni.

```bash
# Login (interactive prompt) / Войти (интерактивный ввод)
spacecmd -u <USER> -p <PASSWORD>

# List all registered systems / Список всех зарегистрированных систем
spacecmd system_list

# Get system details / Детали системы
spacecmd system_details <SYSTEM_NAME>

# List all software channels / Список всех каналов ПО
spacecmd softwarechannel_list

# List activation keys / Список ключей активации
spacecmd activationkey_list

# List configuration channels / Список каналов конфигурации
spacecmd configchannel_list

# List organizations / Список организаций
spacecmd org_list

# List users / Список пользователей
spacecmd user_list

# Apply errata to a system / Применить патчи к системе
spacecmd errata_apply <ERRATA_ID> -s <SYSTEM_NAME>
```

### System Registration / Регистрация систем

```bash
# Register a minion via bootstrap script (generated from UI) / Регистрация через bootstrap-скрипт
curl -Sks https://<HOST>/pub/bootstrap/bootstrap.sh | bash

# Check minion key status on server / Проверить статус ключа минионов на сервере
salt-key -L

# Accept all pending minion keys / Принять все ожидающие ключи
salt-key -A

# Accept specific minion key / Принять ключ конкретного миньона
salt-key -a <MINION_ID>

# Reject a key / Отклонить ключ
salt-key -r <MINION_ID>
```

> [!WARNING]
> Using `salt-key -A` accepts ALL pending keys including potentially unauthorized ones. In production, always verify minion identity before accepting keys. / `salt-key -A` принимает ВСЕ ожидающие ключи, включая потенциально неавторизованные. В продакшене проверяйте идентичность миньонов.

### Software Channels / Каналы программного обеспечения

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

### Salt Command Reference / Справочник команд Salt

```bash
# Test connectivity to all minions / Проверить связь со всеми миньонами
salt '*' test.ping

# Test connectivity to specific minion / Проверить связь с конкретным миньоном
salt '<MINION_ID>' test.ping

# Run command on all minions / Выполнить команду на всех миньонах
salt '*' cmd.run 'uptime'

# Run command on group of minions by grain / Выполнить команду по grain
salt -G 'os:openSUSE Leap' cmd.run 'zypper ref'

# Apply a Salt state / Применить Salt state
salt '<MINION_ID>' state.apply <STATE_NAME>

# Apply highstate (all assigned states) / Применить highstate (все назначенные состояния)
salt '<MINION_ID>' state.highstate

# Run a formula / Запустить формулу
salt '<MINION_ID>' state.apply formulas.<FORMULA_NAME>

# Refresh grains / Обновить grains
salt '<MINION_ID>' saltutil.refresh_grains

# List available modules / Список доступных модулей
salt '<MINION_ID>' sys.list_modules

# Get minion grains (system info) / Получить grains (информация о системе)
salt '<MINION_ID>' grains.items
```

### Salt Targeting Methods / Методы таргетинга Salt

| Method / Метод | Flag / Флаг | Example / Пример | Description / Описание |
|:---|:---|:---|:---|
| Glob / Маска | (default) | `salt 'web*' test.ping` | Wildcard match on minion ID / Маска по ID |
| Grain / Grain | `-G` | `salt -G 'os:CentOS' test.ping` | Match by system fact / По факту системы |
| List / Список | `-L` | `salt -L 'host1,host2' test.ping` | Explicit list / Явный список |
| PCRE regex / Регулярное выражение | `-E` | `salt -E 'web[0-9]+' test.ping` | Regex match / Регулярное выражение |
| Compound / Комбинированный | `-C` | `salt -C 'G@os:SLES and web*' test.ping` | Combined / Комбинированный |
| Nodegroup / Группа | `-N` | `salt -N databases test.ping` | Predefined group / Предопределённая группа |

### Configuration Channels / Каналы конфигурации

```bash
# List config channels / Список каналов конфигурации
spacecmd configchannel_list

# Create a config channel / Создать канал конфигурации
spacecmd configchannel_create -n "<NAME>" -l <LABEL> -d "<DESCRIPTION>"

# Add a file to a config channel / Добавить файл в канал конфигурации
spacecmd configchannel_addfile <CHANNEL_LABEL> -p /etc/myapp/config.conf -f /local/path/config.conf

# List files in a channel / Список файлов в канале
spacecmd configchannel_listfiles <CHANNEL_LABEL>

# Deploy config to system / Применить конфиг на систему
spacecmd configchannel_deploy -s <SYSTEM_NAME> <CHANNEL_LABEL>
```

### Formulas / Формулы

Formulas are Salt states with a YAML-based configuration UI. / Формулы — это Salt states с веб-интерфейсом конфигурации на основе YAML.

```bash
# List available formulas / Список доступных формул
salt '<MINION_ID>' saltutil.list_states

# Show formula data / Показать данные формулы
spacecmd system_runscript -s <SYSTEM> -e bash -c 'ls /usr/share/susemanager/formulas/'

# Apply formula state manually / Применить состояние формулы вручную
salt '<MINION_ID>' state.apply formulas.<FORMULA_NAME>
```

---

## Sysadmin Operations

### Service Management / Управление сервисами

```bash
# Restart all Uyuni services / Перезапустить все сервисы Uyuni
spacewalk-service restart

# Start all services / Запустить все сервисы
spacewalk-service start

# Stop all services / Остановить все сервисы
spacewalk-service stop

# Check status of all services / Проверить статус всех сервисов
spacewalk-service status

# Restart only Taskomatic (scheduler) / Перезапустить только Taskomatic (планировщик)
systemctl restart taskomatic

# Restart Salt Master / Перезапустить Salt Master
systemctl restart salt-master

# Restart Tomcat (web app) / Перезапустить Tomcat (веб-приложение)
systemctl restart tomcat

# Restart PostgreSQL / Перезапустить PostgreSQL
systemctl restart postgresql
```

### Individual Service Stack / Стек отдельных сервисов

| Service / Сервис | Unit Name | Port / Порт | Description / Описание |
|:---|:---|:---|:---|
| Web App (Tomcat) | `tomcat` | `8080` (internal) | Java web frontend / Java веб-фронтенд |
| Scheduler | `taskomatic` | — | Background jobs / Фоновые задачи |
| Salt Master | `salt-master` | `4505`, `4506` | Config management engine / Движок упр. конфиг. |
| Database | `postgresql` | `5432` | Persistent storage / Хранилище данных |
| Apache/httpd | `apache2` | `80`, `443` | Reverse proxy / Обратный прокси |
| OSAD | `osa-dispatcher` | `5222` | Push notification / Push-уведомления |
| Search | `rhn-search` | — | Search indexer / Индексатор поиска |

### Important Paths / Важные пути

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

### Log Locations / Расположение логов

```bash
# Main application log / Основной лог приложения
tail -f /var/log/rhn/rhn_web_api.log

# Taskomatic scheduler log / Лог планировщика Taskomatic
tail -f /var/log/rhn/rhn_taskomatic_daemon.log

# Salt master log / Лог Salt master
tail -f /var/log/salt/master

# Tomcat log / Лог Tomcat
tail -f /var/log/tomcat/catalina.out

# spacewalk-repo-sync log / Лог синхронизации репозиториев
tail -f /var/log/rhn/reposync/<CHANNEL_LABEL>.log
```

### JVM / Performance Tuning / Настройка JVM и производительности

#### Taskomatic JVM Settings / Настройки JVM для Taskomatic

`/etc/rhn/taskomatic.conf`

```ini
# Increase heap for large environments (> 1000 systems) / Увеличить heap для больших окружений
JAVA_OPTS="-Xms1024m -Xmx4096m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/rhn/"
```

#### Tomcat JVM Settings / Настройки JVM для Tomcat

`/etc/tomcat/conf.d/tomcat.conf` (or `/usr/share/tomcat/conf/catalina.sh`)

```ini
JAVA_OPTS="-Xms512m -Xmx2048m -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"
```

> [!TIP]
> For environments with 500+ systems, increase PostgreSQL `shared_buffers` to 25% of RAM and `max_connections` to at least 200 in `/etc/postgresql/<VERSION>/postgresql.conf`. / Для окружений с 500+ систем увеличьте `shared_buffers` до 25% RAM и `max_connections` до 200 в конфиге PostgreSQL.

### JVM Sizing Guidelines / Рекомендации по размерам JVM

| Systems / Систем | Taskomatic `-Xmx` | Tomcat `-Xmx` | PostgreSQL `shared_buffers` |
|:---|:---|:---|:---|
| < 100 | 2 GB | 1 GB | 256 MB |
| 100–500 | 4 GB | 2 GB | 1 GB |
| 500–2000 | 8 GB | 4 GB | 4 GB (25% RAM) |
| 2000+ | 16 GB | 8 GB | 8 GB (25% RAM) |

### Repository Synchronization / Синхронизация репозиториев

```bash
# Sync a specific software channel / Синхронизировать конкретный канал
spacewalk-repo-sync -c <CHANNEL_LABEL>

# Sync all channels / Синхронизировать все каналы
spacewalk-repo-sync --synchronize-all

# Sync with detailed output / Синхронизировать с подробным выводом
spacewalk-repo-sync -c <CHANNEL_LABEL> --verbose

# List available metadata source types / Список типов источников метаданных
spacewalk-repo-sync --list-types
```

### Firewall Configuration / Настройка фаервола

```bash
# Required ports for Uyuni server / Необходимые порты для сервера Uyuni
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

### User & Role Management / Управление пользователями и ролями

```bash
# List all users / Список всех пользователей
spacecmd user_list

# Create a user / Создать пользователя
spacecmd user_create -u <USER> -p <PASSWORD> -e <EMAIL> -f <FIRST_NAME> -l <LAST_NAME>

# Delete a user / Удалить пользователя
spacecmd user_delete <USER>

# List roles of a user / Список ролей пользователя
spacecmd user_listroles <USER>

# Add role to user / Добавить роль пользователю
spacecmd user_addrole <USER> <ROLE>

# Remove role from user / Убрать роль у пользователя
spacecmd user_removerole <USER> <ROLE>
```

### Available Roles / Доступные роли

| Role / Роль | Description / Описание |
|:---|:---|
| `org_admin` | Full organization admin / Полный администратор организации |
| `system_group_admin` | Manage system groups / Управление группами систем |
| `channel_admin` | Manage software channels / Управление каналами ПО |
| `config_admin` | Manage config channels / Управление каналами конфигурации |
| `activation_key_admin` | Manage activation keys / Управление ключами активации |
| `image_admin` | Manage container/OS images / Управление образами |

### SSL Certificate Management / Управление SSL-сертификатами

```bash
# View current certificate info / Просмотр текущего сертификата
openssl x509 -in /etc/apache2/ssl.crt/spacewalk.crt -noout -text | grep -E "Subject:|Not After"

# Regenerate self-signed SSL certificate / Перегенерировать самоподписанный сертификат
rhn-ssl-tool --gen-server-cert --dir=/root/ssl-build \
  --set-country=<COUNTRY_CODE> --set-state=<STATE> --set-city=<CITY> \
  --set-org=<ORG_NAME> --set-org-unit=IT \
  --set-hostname=<HOST> --set-email=admin@<HOST> \
  --set-cname=<HOST>

# Deploy new certificate / Развернуть новый сертификат
rhn-deploy-ca-cert --dir=/root/ssl-build --target=/etc/apache2/ssl.crt/

# Rebuild CA certificate RPM for distribution to clients / Пересобрать RPM сертификата CA для клиентов
rhn-ssl-tool --gen-ca --dir=/root/ssl-build \
  --set-org=<ORG_NAME> --set-common-name=<HOST> \
  --password=<PASSWORD>
```

> [!WARNING]
> After regenerating SSL certificates, all registered minions will need to re-accept the new CA certificate. Plan for a maintenance window. / После перегенерации SSL-сертификатов все зарегистрированные миньоны должны принять новый CA-сертификат. Планируйте окно обслуживания.

### Activation Keys / Ключи активации

```bash
# List activation keys / Список ключей активации
spacecmd activationkey_list

# Create an activation key / Создать ключ активации
spacecmd activationkey_create -n "<DESCRIPTION>" -b <BASE_CHANNEL>

# Add entitlement to key / Добавить entitlement к ключу
spacecmd activationkey_addentitlement <KEY_ID> <ENTITLEMENT>

# Add child channel to key / Добавить дочерний канал к ключу
spacecmd activationkey_addchildchannel <KEY_ID> <CHANNEL>
```

---

## Backup & Restore

> [!CAUTION]
> Uyuni stores all data (packages, repositories) in `/var/spacewalk/`. This directory can be very large (hundreds of GB). Always verify available disk space before backup. / Uyuni хранит все данные в `/var/spacewalk/`. Этот каталог может быть очень большим. Всегда проверяйте свободное место перед резервным копированием.

### Production Runbook: Full Backup / Операционный сценарий резервного копирования

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

### Production Runbook: Restore / Сценарий восстановления

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

### Incremental Content Backup Script / Скрипт инкрементального резервного копирования

```bash
#!/bin/bash
# Uyuni Incremental Backup Script / Скрипт инкрементального бэкапа Uyuni
BACKUP_DIR=/backup/uyuni
DATE=$(date +%F)
mkdir -p "$BACKUP_DIR/$DATE"

# DB dump / Дамп БД
sudo -u postgres pg_dump susemanager | gzip > "$BACKUP_DIR/$DATE/db.sql.gz"

# Config / Конфиги
tar -czf "$BACKUP_DIR/$DATE/conf.tar.gz" /etc/rhn/ /etc/salt/ /root/ssl-build/ /srv/pillar/ /srv/salt/

# Keep last 7 days / Хранить 7 дней
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR/$DATE"
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Web UI Not Loading / Веб-интерфейс не загружается

```bash
# Check Tomcat status and logs / Проверить статус и логи Tomcat
systemctl status tomcat
tail -50 /var/log/tomcat/catalina.out

# Check Apache status / Проверить статус Apache
systemctl status apache2
tail -20 /var/log/apache2/error_log

# Restart web stack / Перезапустить веб-стек
systemctl restart tomcat && systemctl restart apache2
```

#### 2. Minions Not Responding / Миньоны не отвечают

```bash
# Check Salt master connectivity / Проверить связь Salt master
salt '<MINION_ID>' test.ping

# Check salt-key state / Проверить состояние ключей Salt
salt-key -L

# Test connection from minion side (on minion) / Проверить связь со стороны миньона
salt-minion -l debug   # Run in foreground for debug output / Запустить в foreground для отладки

# Check Salt master log / Проверить лог Salt master
tail -100 /var/log/salt/master | grep -i error
```

#### 3. Repository Sync Failures / Ошибки синхронизации репозиториев

```bash
# Check sync log for specific channel / Проверить лог синхронизации конкретного канала
tail -f /var/log/rhn/reposync/<CHANNEL_LABEL>.log

# Re-run sync verbosely / Запустить синхронизацию с отладкой
spacewalk-repo-sync -c <CHANNEL_LABEL> --verbose

# Check disk space (spacewalk data dir) / Проверить место на диске
df -h /var/spacewalk
```

#### 4. Taskomatic Jobs Stuck / Зависшие задачи Taskomatic

```bash
# Check Taskomatic log / Проверить лог Taskomatic
tail -100 /var/log/rhn/rhn_taskomatic_daemon.log

# Restart Taskomatic / Перезапустить Taskomatic
systemctl restart taskomatic

# Check DB connection from Uyuni / Проверить подключение к БД
spacecmd -- system_list  # If this hangs, DB connection is likely broken / Если зависает — проблема с БД
```

#### 5. High Memory Usage / Высокое потребление памяти

```bash
# Check JVM heap usage / Проверить использование JVM heap
jcmd $(pgrep -f taskomatic) VM.heap_info 2>/dev/null || \
  jstat -gc $(pgrep -f catalina) 2000 5

# Check overall system memory / Проверить общую память системы
free -h && top -b -n1 | head -20
```

### Common Issues Quick Reference / Краткий справочник проблем

| Issue / Проблема | Fix / Решение |
|:---|:---|
| **Web UI blank/502** | Restart `tomcat` + `apache2`, check `catalina.out` / Перезапустить `tomcat` + `apache2` |
| **Minions not responding** | Check `salt-key -L`, verify ports `4505/4506` / Проверить ключи, порты `4505/4506` |
| **Repo sync fails** | Check `/var/log/rhn/reposync/*.log`, verify disk space / Проверить логи и место на диске |
| **Taskomatic stuck** | Restart `taskomatic`, check DB connection / Перезапустить `taskomatic`, проверить БД |
| **OOM errors** | Increase JVM `-Xmx` in `taskomatic.conf` / Увеличить `-Xmx` |
| **SSL cert expired** | Regenerate with `rhn-ssl-tool` / Перегенерировать через `rhn-ssl-tool` |

### Database Maintenance / Обслуживание базы данных

```bash
# Check database size / Проверить размер базы данных
sudo -u postgres psql susemanager -c "SELECT pg_size_pretty(pg_database_size('susemanager'));"

# List largest tables / Список крупнейших таблиц
sudo -u postgres psql susemanager -c "
SELECT schemaname, relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;"

# Vacuum analyze for performance / Vacuum analyze для производительности
sudo -u postgres psql susemanager -c "VACUUM ANALYZE;"

# Run spacewalk built-in cleanup / Запустить встроенную очистку spacewalk
spacewalk-data-fsck    # Check data integrity / Проверить целостность данных
```

> [!TIP]
> Run `satellite-sync` (depending on version) to re-sync channels if the database and filesystem are out of sync. / Запустите `satellite-sync` для повторной синхронизации каналов, если база данных и файловая система рассинхронизированы.

### Useful Diagnostic Commands / Полезные диагностические команды

```bash
# Check overall Uyuni health / Общая проверка состояния Uyuni
spacewalk-service status

# Check spacewalk DB connectivity / Проверить подключение к БД spacewalk
spacewalk-sql --select-mode -                     
# Then type: SELECT 1; / Затем введите: SELECT 1;

# Inspect Salt event bus (live) / Просмотр шины событий Salt в реальном времени
salt-run state.event pretty=True

# List all pending Salt jobs / Список всех ожидающих задач Salt
salt-run jobs.list_jobs

# Kill a stuck Salt job / Остановить зависшую задачу Salt
salt-run jobs.kill <JID>

# Verify SSL cert expiry / Проверить срок действия SSL-сертификата
echo | openssl s_client -connect <HOST>:443 2>/dev/null | openssl x509 -noout -dates

# Show registered system count / Показать количество зарегистрированных систем
spacecmd system_list | wc -l
```

---

## Logrotate Configuration

`/etc/logrotate.d/uyuni`

```conf
# Uyuni application logs / Логи приложения Uyuni
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

# Salt master logs / Логи Salt master
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

# Taskomatic scheduler logs / Логи планировщика Taskomatic
/var/log/rhn/rhn_taskomatic_daemon.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 tomcat www
}

# Repo sync logs (can grow large) / Логи синхронизации репозиториев (могут быть большими)
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
