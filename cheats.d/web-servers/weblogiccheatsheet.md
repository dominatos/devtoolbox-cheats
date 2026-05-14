Title: 🌐 WebLogic Server — Cheatsheet
Group: Web Servers
Icon: 🌐
Order: 5

# 🌐 WebLogic Server — Cheatsheet

## Description

**Oracle WebLogic Server** is a commercial Java EE / Jakarta EE application server developed by Oracle. It provides a robust, scalable platform for deploying enterprise Java applications, including support for EJB, JMS, JTA, and web services. WebLogic is commonly used in large enterprise environments, especially those relying on Oracle's technology stack.

**Common use cases / Типичные сценарии:**
- Enterprise Java EE application hosting / Хостинг корпоративных Java EE приложений
- SOA (Service-Oriented Architecture) middleware / Middleware для SOA
- Oracle Fusion Middleware platform / Платформа Oracle Fusion Middleware
- WebSocket and RESTful API deployment / Деплой WebSocket и REST API
- Clustered, high-availability Java deployments / Кластерные развертывания Java

> [!NOTE]
> WebLogic is a **legacy commercial** product requiring an Oracle license. Modern open-source alternatives include **WildFly** (JBoss successor, Jakarta EE), **Payara** (GlassFish fork), and **Open Liberty** (IBM). For microservices, consider **Spring Boot**, **Quarkus**, or **Micronaut** with embedded servers.
> WebLogic — **коммерческий** продукт Oracle. Современные альтернативы: **WildFly**, **Payara**, **Open Liberty**. Для микросервисов: **Spring Boot**, **Quarkus**, **Micronaut**.

---

## Table of Contents

- [Description](#description)
- [Installation & Configuration](#installation--configuration)
- [Server Lifecycle](#server-lifecycle)
- [WLST (WebLogic Scripting Tool)](#wlst-weblogic-scripting-tool)
- [Security](#security)
- [Maintenance & Monitoring](#maintenance--monitoring)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Logrotate Configuration](#logrotate-configuration)
- [Documentation Links](#documentation-links)

---

## Installation & Configuration

### Default Paths / Пути по умолчанию

| Path / Путь | Purpose / Назначение |
|-------------|----------------------|
| `/u01/oracle/` | Oracle home directory / Домашняя директория Oracle |
| `$ORACLE_HOME/wlserver/` | WebLogic Server installation / Установка WebLogic |
| `$DOMAIN_HOME/` | Domain directory / Директория домена |
| `$DOMAIN_HOME/config/config.xml` | Domain configuration / Конфигурация домена |
| `$DOMAIN_HOME/bin/` | Start/stop scripts / Скрипты запуска/остановки |
| `$DOMAIN_HOME/servers/` | Server instances / Экземпляры серверов |
| `$DOMAIN_HOME/servers/*/logs/` | Server logs / Логи серверов |

### Default Ports / Порты по умолчанию

| Port / Порт | Purpose / Назначение |
|-------------|----------------------|
| `7001` | Admin Server HTTP / HTTP для Admin Server |
| `7002` | Admin Server HTTPS / HTTPS для Admin Server |
| `5556` | Node Manager / Менеджер узлов |
| `7003-7XXX` | Managed Servers (configurable) / Управляемые серверы |

### Environment Variables / Переменные окружения

```bash
export ORACLE_HOME=/u01/oracle                          # Oracle installation / Установка Oracle
export WL_HOME=$ORACLE_HOME/wlserver                    # WebLogic home / Домашняя WL
export DOMAIN_HOME=/u01/oracle/user_projects/domains/<DOMAIN_NAME>  # Domain home / Домен
export JAVA_HOME=/u01/oracle/java/jdk                   # Java home / Путь к Java
```

### Set Domain Environment / Установка окружения домена

Run this before any commands. / Запустите это перед любыми командами.

```bash
source /u01/oracle/user_projects/domains/<DOMAIN_NAME>/bin/setDomainEnv.sh
```

---

## Server Lifecycle

### Node Manager / Менеджер узлов

Before starting servers, ensure Node Manager is running. / Убедитесь, что Node Manager запущен.

```bash
# Start Node Manager / Запуск Node Manager
nohup $WL_HOME/server/bin/startNodeManager.sh > nm.log 2>&1 &
```

### Start/Stop Scripts / Скрипты запуска/остановки

```bash
# Start Admin Server / Запуск Admin Server
$DOMAIN_HOME/bin/startWebLogic.sh

# Stop Admin Server / Остановка Admin Server
$DOMAIN_HOME/bin/stopWebLogic.sh

# Start Managed Server / Запуск Managed Server
$DOMAIN_HOME/bin/startManagedWebLogic.sh <SERVER_NAME> <ADMIN_URL>

# Stop Managed Server / Остановка Managed Server
$DOMAIN_HOME/bin/stopManagedWebLogic.sh <SERVER_NAME> <ADMIN_URL>
```

> [!WARNING]
> Always stop Managed Servers before the Admin Server. Stopping the Admin Server first may leave Managed Servers in an inconsistent state.
> Всегда останавливайте Managed Server'ы перед Admin Server'ом.

### Check Running Status / Проверка статуса

```bash
ps aux | grep weblogic                                   # Check process / Проверить процесс
curl http://localhost:7001/console                       # Test Admin Console / Тест консоли
netstat -tlnp | grep :7001                               # Check port / Проверить порт
```

---

## WLST (WebLogic Scripting Tool)

### Interactive Mode / Интерактивный режим
```bash
java weblogic.WLST
```

### Common Commands / Частые команды

```python
# Connect / Подключение
connect('<USER>', '<PASSWORD>', 't3://<ADM_HOST>:<PORT>')

# Server Status / Статус сервера
state('<SERVER_NAME>')

# Start/Stop Server / Запуск/Остановка сервера
start('<SERVER_NAME>')
shutdown('<SERVER_NAME>')

# Deploy App / Деплой приложения
deploy('<APP_NAME>', '/path/to/app.war', targets='<CLUSTER_NAME>')

# Undeploy App / Удаление приложения
undeploy('<APP_NAME>')

# List servers / Список серверов
cd('Servers')
ls()

# List deployments / Список деплоев
cd('AppDeployments')
ls()

# Read server state / Статус всех серверов
domainRuntime()
cd('ServerLifeCycleRuntimes')
ls()
```

### Scripted WLST (Non-interactive) / Скриптовый режим

```bash
# Run a WLST script / Запуск скрипта WLST
java weblogic.WLST /path/to/script.py

# One-liner status check / Однострочная проверка
java weblogic.WLST -e "connect('<USER>','<PASSWORD>','t3://<HOST>:<PORT>'); state('<SERVER_NAME>')"
```

---

## Security

### Users & Roles / Пользователи и роли

```bash
# Access Admin Console / Доступ к Admin Console
# URL: http://<HOST>:7001/console
# Default security realm: myrealm
# Navigate: Security Realms → myrealm → Users and Groups

# Create boot.properties for auto-login / Создание boot.properties
mkdir -p $DOMAIN_HOME/servers/<SERVER_NAME>/security
cat > $DOMAIN_HOME/servers/<SERVER_NAME>/security/boot.properties << EOF
username=<USER>
password=<PASSWORD>
EOF
chmod 600 $DOMAIN_HOME/servers/<SERVER_NAME>/security/boot.properties
```

> [!CAUTION]
> `boot.properties` stores credentials in plain text initially. WebLogic encrypts them on first boot. Ensure proper file permissions.
> `boot.properties` хранит учётные данные в открытом виде до первого запуска. Убедитесь в правильных правах доступа.

### SSL/TLS Configuration / Конфигурация SSL/TLS

```bash
# Create keystore / Создать keystore
keytool -genkey -alias wls -keyalg RSA -keysize 2048 \
  -keystore $DOMAIN_HOME/identity.jks -storepass <PASSWORD>

# Import certificate / Импортировать сертификат
keytool -import -alias wls -file certificate.crt \
  -keystore $DOMAIN_HOME/identity.jks -storepass <PASSWORD>

# List certificates / Список сертификатов
keytool -list -keystore $DOMAIN_HOME/identity.jks -storepass <PASSWORD>
```

---

## Maintenance & Monitoring

### Log Files / Файлы логов

| Log / Лог | Path / Путь |
|-----------|-------------|
| Admin Server log / Лог Admin Server | `$DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log` |
| Managed Server log / Лог Managed Server | `$DOMAIN_HOME/servers/<SERVER_NAME>/logs/<SERVER_NAME>.log` |
| Access log / Лог доступа | `$DOMAIN_HOME/servers/<SERVER_NAME>/logs/access.log` |
| Domain log / Лог домена | `$DOMAIN_HOME/servers/AdminServer/logs/<DOMAIN_NAME>.log` |
| GC log / Лог GC | `$DOMAIN_HOME/servers/<SERVER_NAME>/logs/gc.log` |

```bash
# View live logs / Просмотр логов в реальном времени
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log

# Filter for errors / Поиск ошибок
grep -i "ERROR\|BEA-" $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log
```

### JVM Tuning / Настройка JVM

Set in `setDomainEnv.sh` or `USER_MEM_ARGS`.

```bash
export USER_MEM_ARGS="-Xms2g -Xmx2g"                    # Heap size / Размер кучи
export USER_MEM_ARGS="$USER_MEM_ARGS -XX:+UseG1GC"      # G1 garbage collector / Сборщик мусора
export USER_MEM_ARGS="$USER_MEM_ARGS -XX:MaxGCPauseMillis=200"
export USER_MEM_ARGS="$USER_MEM_ARGS -XX:+HeapDumpOnOutOfMemoryError"
export USER_MEM_ARGS="$USER_MEM_ARGS -XX:HeapDumpPath=$DOMAIN_HOME/servers/<SERVER_NAME>/logs/"
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

```bash
# Port already in use / Порт уже используется
sudo netstat -tlnp | grep :7001                          # Check port / Проверить порт
sudo lsof -i :7001                                       # Alternative / Альтернатива

# Server stuck in STARTING state / Сервер завис в STARTING
# Check for lock files / Проверить lock-файлы
ls -la $DOMAIN_HOME/servers/<SERVER_NAME>/tmp/
# Remove lock files if needed / Удалить lock-файлы при необходимости

# OutOfMemoryError / Ошибка памяти
# Increase heap in USER_MEM_ARGS / Увеличить heap в USER_MEM_ARGS
# Check for memory leaks in deployed applications
```

### Thread Dump / Дамп потоков

```bash
# Get PID / Получить PID
ps aux | grep weblogic

# Generate thread dump / Создать дамп потоков
kill -3 <PID>                                            # Output to server log
jstack <PID> > thread_dump.txt                          # Save to file / Сохранить в файл
```

### Heap Dump / Дамп кучи

```bash
# Generate heap dump / Создать дамп кучи
jmap -dump:format=b,file=/tmp/heap_dump.bin <PID>

# Analyze with Eclipse MAT or VisualVM
# Анализ с помощью Eclipse MAT или VisualVM
```

### Debug Logging / Отладочное логирование

```python
# Via WLST — Enable debug logging / Включить отладочное логирование
connect('<USER>', '<PASSWORD>', 't3://<HOST>:<PORT>')
edit()
startEdit()
cd('Servers/<SERVER_NAME>/Log/<SERVER_NAME>')
set('Severity', 'Debug')
save()
activate()
```

---

## Logrotate Configuration

`/etc/logrotate.d/weblogic`

```conf
/u01/oracle/user_projects/domains/<DOMAIN>/servers/*/logs/*.log {
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
> Use `copytruncate` for WebLogic logs as the JVM keeps file handles open.
> Используйте `copytruncate` для логов WebLogic, так как JVM держит файлы открытыми.

---

## Documentation Links

- [Oracle WebLogic Server Documentation](https://docs.oracle.com/en/middleware/standalone/weblogic-server/)
- [WebLogic Server 14c Documentation](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/)
- [WebLogic WLST Command Reference](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/wlstc/)
- [WebLogic Server Administration Guide](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/domcf/)
- [WebLogic Security Guide](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/scovr/)
- [WebLogic Performance & Tuning](https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/perfm/)

---
