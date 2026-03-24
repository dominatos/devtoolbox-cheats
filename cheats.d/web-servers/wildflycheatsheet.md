Title: 🦅 WildFly (JBoss)
Group: Web Servers
Icon: 🦅
Order: 17

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#installation--configuration)
2. [Operating Modes (Standalone vs Domain)](#operating-modes-standalone-vs-domain)
3. [Service & Access Management](#service--access-management)
4. [Deployment (jboss-cli)](#deployment-jboss-cli)
5. [JVM Tuning & Performance](#jvm-tuning--performance)
6. [Troubleshooting & Logs](#troubleshooting--logs)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `8080` | HTTP Application traffic / HTTP-трафик приложения |
| `8443` | HTTPS Application traffic / HTTPS-трафик |
| `9990` | Management API & Web Console / Веб-консоль управления |
| `9993` | Management HTTPS / Защищённое управление |

### Directory Structure / Структура каталогов

Assuming WildFly is installed in `/opt/wildfly` (WILDFLY_HOME).

| Path / Путь | Purpose / Назначение |
|-------------|----------------------|
| `/opt/wildfly/bin/` | Start/stop scripts, CLI (`jboss-cli.sh`) / Скрипты запуска |
| `/opt/wildfly/standalone/configuration/` | Config files (Standalone) / Конфиги Standalone |
| `/opt/wildfly/standalone/deployments/` | Auto-deploy directory / Папка авто-деплоя |
| `/opt/wildfly/standalone/log/` | Server logs / Логи сервера |
| `/opt/wildfly/domain/` | Domain mode directories / Папки режима Domain |

---

## Operating Modes (Standalone vs Domain)

Wait, what's the difference?
- **Standalone:** Single server instance. Simple, good for most basic apps.
- **Domain:** Centrally managed cluster of WildFly instances (Host Controller + Domain Controller).

### Standalone Mode Configuration Profiles / Профили Standalone

`/opt/wildfly/standalone/configuration/`

| Profile | Contains / Содержит |
|---------|---------------------|
| `standalone.xml` | Default Java EE web profile (Servlet, JSP, EJB, JPA) |
| `standalone-ha.xml` | High Availability (Clustering, JGroups, mod_cluster) |
| `standalone-full.xml` | Full Java EE (adds Messaging - ActiveMQ Artemis) |
| `standalone-full-ha.xml` | Full Java EE + High Availability |

---

## Service & Access Management

### User Management / Управление пользователями

WildFly has no default users. You must create one to access the Web Management Console (`:9990`).

```bash
# Add Management user (Interactive) / Создание пользователя управления
/opt/wildfly/bin/add-user.sh -u <ADMIN_USER> -p <PASSWORD> --silent

# Add Application user (Interactive) / Создание пользователя приложения
/opt/wildfly/bin/add-user.sh -a -u <APP_USER> -p <PASSWORD> -g <GROUP_NAME>
```

### Binding to External IPs / Привязка к внешним IP

By default, WildFly binds to `127.0.0.1`. To allow external access:

```bash
# Start standalone bound to all IPv4 addresses / Запуск на всех IP
/opt/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0

# Using specific profile / Использование конкретного профиля
/opt/wildfly/bin/standalone.sh -c standalone-ha.xml -b 0.0.0.0
```

> [!WARNING]
> Do NOT expose the management interface (`-bmanagement`) to the public internet. Restrict access via firewall to admin IPs only.

### Service Control (Systemd) / Управление сервисом

```bash
sudo systemctl start wildfly     # Start / Старт
sudo systemctl stop wildfly      # Stop / Остановка
sudo systemctl restart wildfly   # Restart / Перезапуск
sudo systemctl status wildfly    # Status / Статус
```

---

## Deployment (jboss-cli)

> [!TIP]
> The `jboss-cli.sh` is the most powerful tool for automating WildFly operations without restarting the server or editing XML files manually.

### Connecting to CLI / Подключение к CLI

```bash
# Connect to local management port / Подключение к локальному CLI
/opt/wildfly/bin/jboss-cli.sh --connect

# Connect with credentials / Подключение с авторизацией
/opt/wildfly/bin/jboss-cli.sh --connect --user=<USER> --password=<PASSWORD>
```

### Application Deployment / Деплой приложений

```bash
# Inside jboss-cli.sh / Внутри консоли jboss-cli
[standalone@localhost:9990 /]

# Deploy a WAR/EAR file / Деплой архива
deploy /path/to/application.war

# Force overwrite existing deployment / Перезапись существующего
deploy /path/to/application.war --force

# Undeploy / Удаление приложения
undeploy application.war

# List deployed apps / Список развёрнутых приложений
deployment-info
```

### Scripted CLI (Non-interactive) / Скриптовое исполнение CLI

```bash
# Run CLI commands automatically / Автоматическое выполнение команд
/opt/wildfly/bin/jboss-cli.sh --connect --command="deploy /path/to/app.war --force"
```

---

## JVM Tuning & Performance

`/opt/wildfly/bin/standalone.conf`

```ini
# --- Memory Allocation (Heap & Metaspace) / Память ---
# Set min/max heap equally to prevent resizing overhead
JAVA_OPTS="-Xms2G -Xmx2G -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=512m"

# --- Garbage Collector (G1GC is default in modern Java) / Сборщик мусора ---
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"

# --- IPv4 Stack Force / Принудительный IPv4 ---
JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"

# --- GC Logging / Логирование GC ---
JAVA_OPTS="$JAVA_OPTS -Xlog:gc*:file=/opt/wildfly/standalone/log/gc.log:time,uptime:filecount=5,filesize=10M"
```

### DataSource Creation (CLI) / Создание пула подключений

```bash
# 1. Add JDBC Driver module / Добавление модуля драйвера
/opt/wildfly/bin/jboss-cli.sh --connect --command="module add --name=com.mysql --resources=/tmp/mysql-connector-java.jar --dependencies=javax.api,javax.transaction.api"

# 2. Add driver to subsystem / Регистрация драйвера
/opt/wildfly/bin/jboss-cli.sh --connect --command="/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-xa-datasource-class-name=com.mysql.cj.jdbc.MysqlXADataSource)"

# 3. Create DataSource / Создание источника данных
/opt/wildfly/bin/jboss-cli.sh --connect --command="data-source add --name=MySqlDS --jndi-name=java:/MySqlDS --driver-name=mysql --connection-url=jdbc:mysql://<DB_IP>:3306/<DB_NAME> --user-name=<DB_USER> --password=<DB_PASSWORD> --min-pool-size=10 --max-pool-size=50 --valid-connection-checker-class-name=org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker"
```

---

## Troubleshooting & Logs

### Log File Locations / Расположение логов

| Log / Лог | Path / Путь |
|-----------|-------------|
| Main Server Log / Главный лог сервера | `/opt/wildfly/standalone/log/server.log` |
| HTTP Access Log / Лог доступа HTTP | `/opt/wildfly/standalone/log/access_log.log` (if enabled) |
| Garbage Collection Log / Лог GC | `/opt/wildfly/standalone/log/gc.log` |

```bash
# View live server logs / Просмотр логов в реальном времени
tail -f /opt/wildfly/standalone/log/server.log

# Filter for errors / Поиск ошибок
grep -i "ERROR" /opt/wildfly/standalone/log/server.log
```

### Changing Log Levels via CLI / Изменение уровня логирования

```bash
# Set root logger to DEBUG (Temporary without restart) / Временное включение DEBUG
/opt/wildfly/bin/jboss-cli.sh --connect --command="/subsystem=logging/root-logger=ROOT:write-attribute(name=level,value=DEBUG)"
```

### Check Port Usage / Проверка занятых портов

```bash
sudo ss -tlnp | grep java
```

> [!CAUTION]
> If WildFly fails to start due to `Address already in use`, verify no other Tomcat/JBoss instance is running on port `:8080`.
