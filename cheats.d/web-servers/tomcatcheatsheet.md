Title: 🐱 Tomcat — Cheatsheet
Group: Web Servers
Icon: 🐱
Order: 3

# 🐱 Tomcat — Cheatsheet

## Table of Contents

- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Deployment](#deployment)
- [Configuration Files](#configuration-files)
- [JVM Tuning](#jvm-tuning)
- [Connectors & Ports](#connectors--ports)
- [Security](#security)
- [Logs & Monitoring](#logs--monitoring)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install tomcat9              # Install Tomcat 9 / Установить Tomcat 9
sudo apt install tomcat10                                # Install Tomcat 10 / Установить Tomcat 10

# RHEL/CentOS/AlmaLinux
sudo dnf install tomcat                                  # Install Tomcat / Установить Tomcat
sudo systemctl enable tomcat                             # Enable at boot / Автозапуск

# Manual installation / Ручная установка
wget https://dlcdn.apache.org/tomcat/tomcat-10/v<VERSION>/bin/apache-tomcat-<VERSION>.tar.gz
tar -xzf apache-tomcat-<VERSION>.tar.gz
sudo mv apache-tomcat-<VERSION> /opt/tomcat
```

### Default Paths / Пути по умолчанию

```bash
# Debian/Ubuntu (package install)
/etc/tomcat9/                                            # Configuration directory / Директория конфигурации
/etc/tomcat9/server.xml                                  # Main config / Основной конфиг
/etc/tomcat9/tomcat-users.xml                            # Users config / Пользователи
/var/lib/tomcat9/webapps/                                # Webapps directory / Директория приложений
/var/log/tomcat9/                                        # Logs directory / Директория логов
/usr/share/tomcat9/                                      # Tomcat home / Домашняя директория

# RHEL/CentOS (package install)
/etc/tomcat/                                             # Configuration directory
/var/lib/tomcat/webapps/                                 # Webapps directory
/var/log/tomcat/                                         # Logs directory

# Manual installation
/opt/tomcat/conf/server.xml                              # Main config
/opt/tomcat/webapps/                                     # Webapps directory
/opt/tomcat/logs/                                        # Logs directory
```

### Environment Variables / Переменные окружения

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64     # Java home / Путь к Java
export CATALINA_HOME=/opt/tomcat                         # Tomcat home / Домашняя директория Tomcat
export CATALINA_BASE=/opt/tomcat                         # Tomcat base / Базовая директория
```

### Default Ports / Порты по умолчанию

- **8080** — HTTP connector (default web port)
- **8443** — HTTPS connector (SSL/TLS)
- **8005** — Shutdown port
- **8009** — AJP connector (Apache integration)

---

## Core Management

### Service Control / Управление сервисом

```bash
# Systemd (package install) / Systemd (установка пакетом)
sudo systemctl start tomcat9                             # Start service / Запустить сервис
sudo systemctl stop tomcat9                              # Stop service / Остановить сервис
sudo systemctl restart tomcat9                           # Restart service / Перезапустить сервис
sudo systemctl status tomcat9                            # Service status / Статус сервиса
sudo systemctl enable tomcat9                            # Enable at boot / Автозапуск

# RHEL/CentOS: replace tomcat9 with tomcat
# Manual installation / Ручная установка
/opt/tomcat/bin/startup.sh                               # Start Tomcat / Запустить Tomcat
/opt/tomcat/bin/shutdown.sh                              # Stop Tomcat / Остановить Tomcat
/opt/tomcat/bin/catalina.sh run                          # Run in foreground / Запуск на переднем плане
```

### Check Running Status / Проверка статуса

```bash
ps aux | grep tomcat                                     # Check process / Проверить процесс
curl http://localhost:8080                               # Test HTTP / Тест HTTP
netstat -tlnp | grep :8080                               # Check port / Проверить порт
sudo lsof -i :8080                                       # Alternative / Альтернатива
```

---

## Deployment

### Deploy WAR File / Деплой WAR файла

```bash
# Drop-in deployment / Простой деплой
sudo cp app.war /var/lib/tomcat9/webapps/                # Copy WAR / Копировать WAR
# Tomcat auto-deploys on detect / Tomcat автоматически развернет

# Deploy as ROOT app / Деплой как ROOT приложение
sudo rm -rf /var/lib/tomcat9/webapps/ROOT                # Remove default ROOT / Удалить ROOT
sudo cp app.war /var/lib/tomcat9/webapps/ROOT.war        # Deploy as ROOT / Развернуть как ROOT

# Manual unpacking / Ручная распаковка
sudo mkdir /var/lib/tomcat9/webapps/app
sudo unzip app.war -d /var/lib/tomcat9/webapps/app/      # Exploded deployment / Распакованный деплой
```

### Undeploy Application / Удаление приложения

```bash
sudo rm /var/lib/tomcat9/webapps/app.war                 # Remove WAR / Удалить WAR
sudo rm -rf /var/lib/tomcat9/webapps/app/                # Remove directory / Удалить директорию
sudo systemctl restart tomcat9                           # Restart / Перезапустить
```

### Hot Deployment / Горячий деплой

```bash
# Enable auto-deployment in server.xml / Включить автодеплой в server.xml
# <Host autoDeploy="true" unpackWARs="true">
# Simply copy new WAR, Tomcat will redeploy automatically
# Просто скопируй новый WAR, Tomcat развернет автоматически
```

---

## Configuration Files

### server.xml / Основной конфигурационный файл

`/etc/tomcat9/server.xml`

```xml
<!-- Main configuration file / Основной конфигурационный файл -->

<!-- Shutdown port / Порт остановки -->
<Server port="8005" shutdown="SHUTDOWN">

<!-- HTTP Connector / HTTP коннектор -->
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />

<!-- HTTPS Connector / HTTPS коннектор -->
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true">
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="/path/to/keystore.jks"
                     type="RSA" />
    </SSLHostConfig>
</Connector>

<!-- AJP Connector (for Apache integration) / AJP коннектор (для Apache) -->
<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

<!-- Engine and Host / Движок и хост -->
<Engine name="Catalina" defaultHost="localhost">
  <Host name="localhost" appBase="webapps"
        unpackWARs="true" autoDeploy="true">
  </Host>
</Engine>
```

### tomcat-users.xml / Пользователи и роли

`/etc/tomcat9/tomcat-users.xml`

```xml
<tomcat-users>
  <!-- Manager GUI access / Доступ к Manager GUI -->
  <role rolename="manager-gui"/>
  <role rolename="admin-gui"/>
  
  <user username="<USER>" password="<PASSWORD>" roles="manager-gui,admin-gui"/>
</tomcat-users>
```

### context.xml / Конфигурация контекста

`/etc/tomcat9/context.xml` or `META-INF/context.xml`

```xml
<Context>
  <!-- Database connection pool / Пул соединений БД -->
  <Resource name="jdbc/mydb" auth="Container"
            type="javax.sql.DataSource"
            maxTotal="100" maxIdle="30" maxWaitMillis="10000"
            username="<USER>" password="<PASSWORD>"
            driverClassName="com.mysql.jdbc.Driver"
            url="jdbc:mysql://<IP>:3306/mydb"/>
</Context>
```

### web.xml / Дескриптор веб-приложения

`/etc/tomcat9/web.xml` or `WEB-INF/web.xml`

```xml
<web-app>
  <!-- Default servlet / Сервлет по умолчанию -->
  <!-- Session timeout / Таймаут сессии -->
  <session-config>
    <session-timeout>30</session-timeout>
  </session-config>
</web-app>
```

---

## JVM Tuning

### Set JVM Options / Настройка JVM

```bash
# Debian/Ubuntu: Edit /etc/default/tomcat9
# RHEL/CentOS: Edit /etc/tomcat/tomcat.conf
# Manual install: Create/edit /opt/tomcat/bin/setenv.sh

# Example setenv.sh / Пример setenv.sh
export JAVA_OPTS="-Xms512m -Xmx1024m"                    # Heap size / Размер кучи
export JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m"  # Metaspace
export JAVA_OPTS="$JAVA_OPTS -server"                   # Server mode / Режим сервера
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"              # G1 garbage collector / Сборщик мусора G1

export CATALINA_OPTS="-Dspring.profiles.active=prod"    # App options / Опции приложения
export CATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF-8"  # File encoding
```

### Common JVM Options / Общие опции JVM

```bash
# Memory settings / Настройки памяти
-Xms512m                                                 # Initial heap / Начальный размер кучи
-Xmx2048m                                                # Maximum heap / Максимальный размер кучи
-XX:MetaspaceSize=256m                                   # Metaspace size / Размер Metaspace
-XX:MaxMetaspaceSize=512m                                # Max Metaspace / Макс. Metaspace

# Garbage Collection / Сборка мусора
-XX:+UseG1GC                                             # Use G1 GC / Использовать G1 GC
-XX:+UseParallelGC                                       # Parallel GC
-XX:+UseConcMarkSweepGC                                  # CMS GC (deprecated)

# Performance / Производительность
-server                                                  # Server mode / Режим сервера
-XX:+UseStringDeduplication                              # String dedup / Дедупликация строк

# Debugging / Отладка
-Xdebug                                                  # Enable debug / Включить отладку
-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005  # Remote debug
```

### Production JVM Settings / Настройки для продакшена

```bash
export JAVA_OPTS="-Xms2g -Xmx2g"                         # Equal min/max for predictability
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
export JAVA_OPTS="$JAVA_OPTS -XX:MaxGCPauseMillis=200"
export JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"  # Heap dump on OOM
export JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=/var/log/tomcat9/"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails -XX:+PrintGCDateStamps"
export JAVA_OPTS="$JAVA_OPTS -Xloggc:/var/log/tomcat9/gc.log"
```

---

## Connectors & Ports

### HTTP Connector / HTTP коннектор

```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443"
           maxThreads="200"
           minSpareThreads="10"
           enableLookups="false"
           acceptCount="100"
           URIEncoding="UTF-8" />
```

### HTTPS Connector (SSL/TLS) / HTTPS коннектор

```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true"
           scheme="https" secure="true">
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="/etc/tomcat9/keystore.jks"
                     certificateKeystorePassword="<PASSWORD>"
                     type="RSA" />
    </SSLHostConfig>
</Connector>
```

### AJP Connector (Apache mod_jk) / AJP коннектор

```xml
<Connector port="8009" protocol="AJP/1.3"
           redirectPort="8443"
           secretRequired="false" />
```

### Behind Reverse Proxy / За обратным прокси

```xml
<!-- Add RemoteIpValve to preserve client IP / Добавить RemoteIpValve для сохранения IP -->
<Valve className="org.apache.catalina.valves.RemoteIpValve"
       remoteIpHeader="X-Forwarded-For"
       proxiesHeader="X-Forwarded-By"
       protocolHeader="X-Forwarded-Proto" />

<!-- Or configure connector / Или настроить коннектор -->
<Connector port="8080" protocol="HTTP/1.1"
           proxyName="<HOST>"
           proxyPort="80"
           scheme="http" />
```

---

## Security

### Manager Application Security / Безопасность Manager

```bash
# Restrict Manager access to localhost / Ограничить Manager локалхостом
# Edit /var/lib/tomcat9/webapps/manager/META-INF/context.xml

# Allow specific IPs / Разрешить конкретные IP
<Context antiResourceLocking="false" privileged="true" >
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|<IP>" />
</Context>
```

### SSL/TLS Configuration / Конфигурация SSL/TLS

```bash
# Create keystore / Создать keystore
keytool -genkey -alias tomcat -keyalg RSA -keystore /etc/tomcat9/keystore.jks

# Import certificate / Импортировать сертификат
keytool -import -alias tomcat -file certificate.crt -keystore /etc/tomcat9/keystore.jks

# List certificates / Список сертификатов
keytool -list -keystore /etc/tomcat9/keystore.jks
```

### Remove Default Apps / Удалить приложения по умолчанию

```bash
# Remove examples, docs, manager, host-manager for security
# Удалить примеры, документацию, manager для безопасности
sudo rm -rf /var/lib/tomcat9/webapps/examples
sudo rm -rf /var/lib/tomcat9/webapps/docs
sudo rm -rf /var/lib/tomcat9/webapps/manager
sudo rm -rf /var/lib/tomcat9/webapps/host-manager
```

### Security Best Practices / Лучшие практики безопасности

- Remove default applications / Удали приложения по умолчанию
- Use strong passwords in tomcat-users.xml / Используй сильные пароли
- Restrict Manager access by IP / Ограничь доступ к Manager по IP
- Run Tomcat as non-root user / Запускай Tomcat не от root
- Keep Tomcat updated / Обновляй Tomcat
- Use HTTPS / Используй HTTPS
- Disable unnecessary connectors / Отключи ненужные коннекторы

---

## Logs & Monitoring

### Log Files / Файлы логов

```bash
# Debian/Ubuntu
sudo tail -f /var/log/tomcat9/catalina.out              # Main log / Основной лог
sudo tail -f /var/log/tomcat9/catalina.<DATE>.log       # Daily log / Дневной лог
sudo tail -f /var/log/tomcat9/localhost.<DATE>.log      # Localhost log / Лог localhost
sudo tail -f /var/log/tomcat9/manager.<DATE>.log        # Manager log / Лог Manager
sudo tail -f /var/log/tomcat9/host-manager.<DATE>.log   # Host Manager log

# Manual installation
sudo tail -f /opt/tomcat/logs/catalina.out
```

### Enable Access Logs / Включить логи доступа

```xml
<!-- Add to server.xml in <Host> section -->
<Valve className="org.apache.catalina.valves.AccessLogValve"
       directory="logs"
       prefix="localhost_access_log" suffix=".txt"
       pattern="%h %l %u %t &quot;%r&quot; %s %b" />
```

### JMX Monitoring / Мониторинг JMX

```bash
# Enable JMX remote monitoring / Включить удаленный мониторинг JMX
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=9999"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"

# Connect with JConsole / Подключение через JConsole
jconsole <IP>:9999
```

### Application Monitoring / Мониторинг приложений

```bash
# Access Manager GUI / Доступ к Manager GUI
http://localhost:8080/manager/html

# Login with user from tomcat-users.xml
# Вход с пользователем из tomcat-users.xml
```

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

```bash
# Port already in use / Порт уже используется
sudo netstat -tlnp | grep :8080                          # Check port / Проверить порт
sudo lsof -i :8080                                       # Alternative / Альтернатива
sudo fuser -k 8080/tcp                                   # Kill process on port / Убить процесс

# Permission denied / Доступ запрещен
sudo chown -R tomcat:tomcat /var/lib/tomcat9/webapps/    # Fix ownership / Исправить владельца
sudo chmod -R 755 /var/lib/tomcat9/webapps/              # Fix permissions / Исправить права

# OutOfMemoryError / Ошибка памяти
# Increase heap size in JAVA_OPTS / Увеличь размер кучи в JAVA_OPTS
export JAVA_OPTS="-Xms1g -Xmx2g"

# Check JAVA_HOME / Проверить JAVA_HOME
echo $JAVA_HOME
which java
java -version
```

### Thread Dump / Дамп потоков

```bash
# Get PID / Получить PID
ps aux | grep tomcat

# Generate thread dump / Создать дамп потоков
sudo kill -3 <PID>                                       # Output to catalina.out
sudo jstack <PID> > thread_dump.txt                      # Save to file / Сохранить в файл
```

### Heap Dump / Дамп кучи

```bash
# Generate heap dump / Создать дамп кучи
sudo jmap -dump:format=b,file=/tmp/heap.bin <PID>

# Analyze with tools like Eclipse MAT or VisualVM
# Анализ с помощью Eclipse MAT или VisualVM
```

### Check Configuration / Проверка конфигурации

```bash
# Validate server.xml / Проверить server.xml
# Start Tomcat and check logs for errors
# Запусти Tomcat и проверь логи на ошибки

# Check effective configuration / Проверить действующую конфигурацию
# Access Manager → Server Status → Show server configuration
# Доступ Manager → Server Status → Показать конфигурацию сервера
```

### Debug Mode / Режим отладки

```bash
# Enable debug mode / Включить режим отладки
export JPDA_ADDRESS=5005
export JPDA_TRANSPORT=dt_socket
/opt/tomcat/bin/catalina.sh jpda start

# Connect debugger to port 5005 / Подключить отладчик к порту 5005
```

### Performance Tuning / Настройка производительности

```bash
# Increase connector threads / Увеличить потоки коннектора
# Edit maxThreads in server.xml Connector
# Редактировать maxThreads в Connector в server.xml

# Enable HTTP/2 / Включить HTTP/2
# Use NIO2 or APR connector with upgradeProtocol
# Использовать NIO2 или APR коннектор с upgradeProtocol

# Enable compression / Включить сжатие
<Connector compression="on"
           compressibleMimeType="text/html,text/xml,text/plain,text/css,application/javascript,application/json" />
```

---

## Quick Reference / Краткая справка

### Essential Commands / Основные команды

```bash
sudo systemctl status tomcat9                            # Status / Статус
sudo systemctl restart tomcat9                           # Restart / Перезапустить
sudo tail -f /var/log/tomcat9/catalina.out               # Tail main log / Хвост основного лога
sudo cp app.war /var/lib/tomcat9/webapps/                # Deploy WAR / Деплой WAR
sudo rm -rf /var/lib/tomcat9/webapps/app*                # Undeploy / Удалить приложение
```

### Best Practices / Лучшие практики

- Set equal `-Xms` and `-Xmx` for stable performance / Установить равные `-Xms` и `-Xmx`
- Use G1GC for better GC performance / Используй G1GC для лучшей производительности
- Enable heap dump on OOM / Включи heap dump при OOM
- Monitor logs regularly / Регулярно проверяй логи
- Remove default applications / Удали приложения по умолчанию
- Use HTTPS in production / Используй HTTPS в продакшене
- Configure behind reverse proxy / Настрой за обратным прокси
- Set up log rotation / Настрой ротацию логов
- Keep Tomcat and Java updated / Обновляй Tomcat и Java

---

## Logrotate Configuration / Конфигурация Logrotate

`/etc/logrotate.d/tomcat9`

```conf
/var/log/tomcat9/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 tomcat adm
    copytruncate
}

/var/log/tomcat9/catalina.out {
    daily
    rotate 7
    compress
    missingok
    notifempty
    size 100M
    copytruncate
}
```

> [!WARNING]
> Use `copytruncate` for Tomcat logs as the JVM keeps file handles open.
> Используйте `copytruncate` для логов Tomcat, так как JVM держит файлы открытыми.

---

