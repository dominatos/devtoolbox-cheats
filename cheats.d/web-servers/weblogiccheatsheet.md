Title: 🌐 WebLogic Server
Group: Web Servers
Icon: 🌐
Order: 5

# WebLogic Sysadmin Cheatsheet

> **Context:** Oracle WebLogic Server is a Java EE application server. / Oracle WebLogic Server - это сервер приложений Java EE.
> **Role:** Middleware Admin / Sysadmin
> **Version:** 12c / 14c

---

## 📚 Table of Contents / Содержание

1. [Environment](#environment--окружение)
2. [Server Lifecycle](#server-lifecycle--жизненный-цикл-сервера)
3. [WLST (WebLogic Scripting Tool)](#wlst-weblogic-scripting-tool--wlst)
4. [Maintenance](#maintenance--обслуживание)
5. [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## 1. Environment / Окружение

### Set Domain Environment / Установка окружения домена
Run this before any commands. / Запустите это перед любыми командами.

```bash
source /u01/oracle/user_projects/domains/<DOMAIN_NAME>/bin/setDomainEnv.sh
```

---

## 2. Server Lifecycle / Жизненный цикл сервера

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

---

## 3. WLST (WebLogic Scripting Tool) / WLST

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

# List servers / Список серверов
cd('Servers')
ls()
```

---

## 4. Maintenance / Обслуживание

### Logs / Логи

*   **Admin Server:** `$DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log`
*   **Managed Server:** `$DOMAIN_HOME/servers/<SERVER_NAME>/logs/<SERVER_NAME>.log`
*   **Access Log:** `$DOMAIN_HOME/servers/<SERVER_NAME>/logs/access.log`

### Heap Size / Размер Heap
Set in `setDomainEnv.sh` or `USER_MEM_ARGS`.

```bash
export USER_MEM_ARGS="-Xms2g -Xmx2g"
```

---

## 5. Logrotate Configuration / Конфигурация Logrotate

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

