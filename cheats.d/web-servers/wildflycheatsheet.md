Title: 🦅 WildFly (JBoss) — Cheatsheet
Group: Web Servers
Icon: 🦅
Order: 17

# 🦅 WildFly (JBoss) — Cheatsheet

## Description

**WildFly** (formerly JBoss AS) is a free, open-source Jakarta EE application server developed by Red Hat. It is the upstream project for **JBoss EAP** (Enterprise Application Platform). WildFly provides a full Jakarta EE implementation including EJB, JPA, JMS (ActiveMQ Artemis), CDI, and more.

**Common use cases / Типичные сценарии:**
- Full Jakarta EE application server / Полный Jakarta EE сервер приложений
- Enterprise Java deployments (EJB, JMS, JPA) / Корпоративные Java развертывания
- Clustered/High-Availability Java applications / Кластерные Java приложения
- Lightweight Java microservices (via WildFly Bootable JAR) / Легковесные микросервисы

> [!NOTE]
> WildFly is actively developed and is the **open-source upstream** for Red Hat's commercial **JBoss EAP**. Alternatives include **Apache Tomcat** (servlet container only), **Payara** (GlassFish fork), and **Open Liberty** (IBM). For microservices, consider **Quarkus** (also by Red Hat, built on WildFly components) or **Spring Boot**.
> WildFly — open-source основа для коммерческого **JBoss EAP** от Red Hat. Альтернативы: **Tomcat** (только сервлеты), **Payara**, **Open Liberty**. Для микросервисов: **Quarkus** или **Spring Boot**.

---

## Table of Contents

- [Description](#description)
- [Installation & Configuration](#installation--configuration)
- [Operating Modes](#operating-modes)
- [Service & Access Management](#service--access-management)
- [Deployment (jboss-cli)](#deployment-jboss-cli)
- [JVM Tuning & Performance](#jvm-tuning--performance)
- [Security](#security)
- [Troubleshooting & Logs](#troubleshooting--logs)
- [Logrotate Configuration](#logrotate-configuration)
- [Documentation Links](#documentation-links)

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

## Operating Modes

WildFly supports two operating modes, each suited for different deployment scenarios:

- **Standalone Mode:** Single server instance. Simple configuration, ideal for development, testing, and single-node production deployments.
  **Standalone режим:** Один экземпляр сервера. Простая конфигурация, идеально для разработки и одиночных серверов.

- **Domain Mode:** Centrally managed cluster of WildFly instances using a Host Controller and Domain Controller. Suited for multi-server enterprise environments.
  **Domain режим:** Централизованно управляемый кластер через Host Controller и Domain Controller. Подходит для корпоративных многосерверных сред.

### Standalone Mode Configuration Profiles / Профили Standalone

`/opt/wildfly/standalone/configuration/`

| Profile | Contains / Содержит |
|---------|---------------------|
| `standalone.xml` | Default Java EE web profile (Servlet, JSP, EJB, JPA) |
| `standalone-ha.xml` | High Availability (Clustering, JGroups, mod_cluster) |
| `standalone-full.xml` | Full Java EE (adds Messaging — ActiveMQ Artemis) |
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
> НЕ открывайте management-интерфейс (`-bmanagement`) в публичный интернет. Ограничьте доступ файрволом.

### Service Control (Systemd) / Управление сервисом

```bash
sudo systemctl start wildfly     # Start / Старт
sudo systemctl stop wildfly      # Stop / Остановка
sudo systemctl restart wildfly   # Restart / Перезапуск
sudo systemctl status wildfly    # Status / Статус
sudo systemctl enable wildfly    # Enable at boot / Автозапуск
```

---

## Deployment (jboss-cli)

> [!TIP]
> The `jboss-cli.sh` is the most powerful tool for automating WildFly operations without restarting the server or editing XML files manually.
> `jboss-cli.sh` — самый мощный инструмент для автоматизации операций WildFly без перезапуска.

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

## Security

### SSL/TLS Configuration / Конфигурация SSL/TLS

```bash
# Create keystore / Создать keystore
keytool -genkey -alias wildfly -keyalg RSA -keysize 2048 \
  -keystore /opt/wildfly/standalone/configuration/keystore.jks \
  -storepass <PASSWORD>

# Import certificate / Импортировать сертификат
keytool -import -alias wildfly -file certificate.crt \
  -keystore /opt/wildfly/standalone/configuration/keystore.jks \
  -storepass <PASSWORD>
```

### Enable HTTPS via CLI / Включить HTTPS через CLI

```bash
# Configure Elytron SSL context / Настройка Elytron SSL
/opt/wildfly/bin/jboss-cli.sh --connect << EOF
/subsystem=elytron/key-store=httpsKS:add(path=keystore.jks,relative-to=jboss.server.config.dir,type=JKS,credential-reference={clear-text=<PASSWORD>})
/subsystem=elytron/key-manager=httpsKM:add(key-store=httpsKS,credential-reference={clear-text=<PASSWORD>})
/subsystem=elytron/server-ssl-context=httpsSSC:add(key-manager=httpsKM,protocols=[TLSv1.2,TLSv1.3])
/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=ssl-context,value=httpsSSC)
reload
EOF
```

### Security Best Practices / Лучшие практики безопасности

- Remove the welcome-content handler in production / Удалите welcome-content в продакшене
- Restrict management console to internal IPs / Ограничьте консоль управления внутренними IP
- Use strong passwords for management users / Используйте сильные пароли
- Enable HTTPS for all listeners / Включите HTTPS для всех листенеров
- Keep WildFly and Java updated / Обновляйте WildFly и Java

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

### Thread Dump / Дамп потоков

```bash
# Get PID / Получить PID
ps aux | grep wildfly

# Generate thread dump / Создать дамп потоков
kill -3 <PID>                                            # Output to server.log
jstack <PID> > thread_dump.txt                          # Save to file / Сохранить в файл
```

### Heap Dump / Дамп кучи

```bash
# Generate heap dump / Создать дамп кучи
jmap -dump:format=b,file=/tmp/heap_dump.bin <PID>

# Analyze with Eclipse MAT or VisualVM
# Анализ с помощью Eclipse MAT или VisualVM
```

### Check Port Usage / Проверка занятых портов

```bash
sudo ss -tlnp | grep java                               # Check Java ports / Проверить порты Java
sudo netstat -tlnp | grep :8080                          # Check specific port / Проверить порт
```

> [!CAUTION]
> If WildFly fails to start due to `Address already in use`, verify no other Tomcat/JBoss instance is running on port `:8080`.
> Если WildFly не запускается из-за `Address already in use`, убедитесь что другой Tomcat/JBoss не занимает порт `:8080`.

---

## Logrotate Configuration

`/etc/logrotate.d/wildfly`

```conf
/opt/wildfly/standalone/log/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

> [!WARNING]
> Use `copytruncate` for WildFly logs as the JVM keeps file handles open.
> Используйте `copytruncate` для логов WildFly, так как JVM держит файлы открытыми.

---

## Documentation Links

- [WildFly Official Documentation](https://docs.wildfly.org/)
- [WildFly Getting Started Guide](https://docs.wildfly.org/latest/Getting_Started_Guide.html)
- [WildFly Admin Guide](https://docs.wildfly.org/latest/Admin_Guide.html)
- [WildFly CLI (jboss-cli) Guide](https://docs.wildfly.org/latest/Admin_Guide.html#Command_Line_Interface)
- [WildFly High Availability Guide](https://docs.wildfly.org/latest/High_Availability_Guide.html)
- [WildFly GitHub Repository](https://github.com/wildfly/wildfly)
- [JBoss EAP Documentation (Commercial)](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/)

---
