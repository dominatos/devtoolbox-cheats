Title: 🪶 Apache HTTPD — Cheatsheet
Group: Web Servers
Icon: 🪶
Order: 2

# 🪶 Apache HTTPD — Cheatsheet

## Description

**Apache HTTP Server (httpd)** is one of the most widely used open-source web servers in the world, maintained by the Apache Software Foundation. First released in 1995, it remains a cornerstone of the LAMP stack (Linux, Apache, MySQL, PHP).

**Common use cases / Типичные сценарии:**
- Serving static and dynamic web content / Раздача статического и динамического контента
- Virtual hosting (multiple sites on one server) / Виртуальный хостинг
- Reverse proxy and load balancing / Обратный прокси и балансировка нагрузки
- `.htaccess`-based per-directory configuration / Децентрализованная настройка через `.htaccess`

> [!NOTE]
> Apache remains actively developed and widely deployed, but for high-concurrency reverse proxy/load balancing scenarios, **Nginx** and **Caddy** are often preferred due to their event-driven architecture. Apache excels in shared hosting and `.htaccess`-based workflows.
> Apache активно развивается, но для высоконагруженных сценариев обратного прокси/балансировки предпочтительны **Nginx** и **Caddy**. Apache лучше подходит для shared-хостинга и `.htaccess`-конфигураций.

---

## Table of Contents

- [Description](#description)
- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Virtual Hosts](#virtual-hosts)
- [Modules Management](#modules-management)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Security & Access Control](#security--access-control)
- [Performance Tuning](#performance-tuning)
- [Logs & Monitoring](#logs--monitoring)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Logrotate Configuration](#logrotate-configuration--конфигурация-logrotate)

---

## Installation & Configuration

### Package Installation / Установка пакетов

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install apache2             # Install Apache / Установить Apache

# RHEL/CentOS/AlmaLinux
sudo dnf install httpd                                   # Install Apache / Установить Apache
sudo systemctl enable httpd                              # Enable at boot / Автозапуск
```

### Default Paths / Пути по умолчанию

**Debian/Ubuntu:**  
`/etc/apache2/apache2.conf` — Main config / Основной конфиг  
`/etc/apache2/sites-available/` — Available sites / Доступные сайты  
`/etc/apache2/sites-enabled/` — Enabled sites / Включенные сайты  
`/etc/apache2/mods-available/` — Available modules / Доступные модули  
`/etc/apache2/mods-enabled/` — Enabled modules / Включенные модули  
`/var/www/html/` — Default document root / Корень по умолчанию  
`/var/log/apache2/` — Logs directory / Директория логов

**RHEL/CentOS/AlmaLinux:**  
`/etc/httpd/conf/httpd.conf` — Main config / Основной конфиг  
`/etc/httpd/conf.d/` — Additional configs / Дополнительные конфиги  
`/var/www/html/` — Default document root / Корень по умолчанию  
`/var/log/httpd/` — Logs directory / Директория логов

### Default Ports / Порты по умолчанию

- **80** — HTTP
- **443** — HTTPS

---

## Core Management

### Service Control / Управление сервисом

```bash
sudo systemctl start apache2                             # Start service / Запустить сервис
sudo systemctl stop apache2                              # Stop service / Остановить сервис
sudo systemctl restart apache2                           # Restart service / Перезапустить сервис
sudo systemctl reload apache2                            # Reload config / Перечитать конфиг
sudo systemctl status apache2                            # Service status / Статус сервиса
sudo systemctl enable apache2                            # Enable at boot / Автозапуск

# RHEL/CentOS: replace apache2 with httpd
```

### Configuration Testing / Проверка конфигурации

```bash
sudo apachectl configtest                                # Test config / Проверка конфига
sudo apachectl -t                                        # Short form / Краткая форма
sudo apachectl -S                                        # Show vhost config / Показать конфиг vhost
sudo apache2ctl -M                                       # List loaded modules / Список модулей
```

### Graceful Restart / Плавный перезапуск

```bash
sudo apachectl graceful                                  # Graceful restart / Плавный перезапуск
# Allows active connections to complete
# Позволяет завершить активные соединения
```

---

## Virtual Hosts

### Basic HTTP Virtual Host / Базовый HTTP виртуальный хост
`/etc/apache2/sites-available/<HOST>.conf`

```apache
<VirtualHost *:80>
  ServerName <HOST>                                      # Server name / Имя хоста
  ServerAlias www.<HOST>                                 # Alias / Псевдоним
  DocumentRoot /var/www/<HOST>                           # Document root / Корневая директория
  
  <Directory /var/www/<HOST>>
    Options -Indexes +FollowSymLinks                     # Directory options / Опции директории
    AllowOverride All                                    # Allow .htaccess / Разрешить .htaccess
    Require all granted                                  # Access control / Контроль доступа
  </Directory>
  
  ErrorLog ${APACHE_LOG_DIR}/<HOST>_error.log            # Error log / Лог ошибок
  CustomLog ${APACHE_LOG_DIR}/<HOST>_access.log combined # Access log / Лог доступа
</VirtualHost>
```

### Reverse Proxy Virtual Host / Виртуальный хост обратный прокси
`/etc/apache2/sites-available/<HOST>.conf`

```apache
<VirtualHost *:80>
  ServerName <HOST>                                      # ServerName / Имя хоста
  
  ProxyPreserveHost On                                   # Preserve Host header / Сохранить заголовок Host
  ProxyPass        / http://<IP>:3000/                   # Proxy to backend / Проксировать на backend
  ProxyPassReverse / http://<IP>:3000/                   # Reverse proxy / Обратный прокси
  
  ErrorLog  ${APACHE_LOG_DIR}/<HOST>_error.log           # Error log / Лог ошибок
  CustomLog ${APACHE_LOG_DIR}/<HOST>_access.log combined # Access log / Лог доступа
</VirtualHost>
```

### HTTPS Virtual Host / HTTPS виртуальный хост
`/etc/apache2/sites-available/<HOST>.conf`

```apache
<VirtualHost *:443>
  ServerName <HOST>
  DocumentRoot /var/www/<HOST>
  
  SSLEngine on                                           # Enable SSL / Включить SSL
  SSLCertificateFile /etc/ssl/certs/<HOST>.crt           # Certificate / Сертификат
  SSLCertificateKeyFile /etc/ssl/private/<HOST>.key      # Private key / Приватный ключ
  SSLCertificateChainFile /etc/ssl/certs/<HOST>-chain.crt # Chain / Цепочка
  
  <Directory /var/www/<HOST>>
    AllowOverride All
    Require all granted
  </Directory>
  
  ErrorLog ${APACHE_LOG_DIR}/<HOST>_ssl_error.log
  CustomLog ${APACHE_LOG_DIR}/<HOST>_ssl_access.log combined
</VirtualHost>
```

### HTTP to HTTPS Redirect / Редирект с HTTP на HTTPS
`/etc/apache2/sites-available/<HOST>.conf`

```apache
<VirtualHost *:80>
  ServerName <HOST>
  Redirect permanent / https://<HOST>/                   # Permanent redirect / Постоянный редирект
</VirtualHost>
```

---

## Modules Management

### Enable/Disable Modules / Включить/выключить модули

```bash
# Debian/Ubuntu
sudo a2enmod rewrite                                     # Enable module / Включить модуль
sudo a2enmod ssl                                         # Enable SSL / Включить SSL
sudo a2enmod proxy                                       # Enable proxy / Включить прокси
sudo a2enmod proxy_http                                  # Enable HTTP proxy / Включить HTTP прокси
sudo a2enmod headers                                     # Enable headers / Включить заголовки
sudo a2dismod <MODULE>                                   # Disable module / Выключить модуль
sudo systemctl reload apache2                            # Reload after change / Перечитать после изменений

# RHEL/CentOS (edit /etc/httpd/conf.modules.d/*)
# Manually uncomment/comment LoadModule directives
# Вручную раскомментировать/закомментировать директивы LoadModule
```

### Essential Modules / Необходимые модули

```bash
# Common production modules / Часто используемые модули
sudo a2enmod rewrite proxy proxy_http ssl headers deflate expires
sudo systemctl reload apache2
```

- **rewrite** — URL rewriting / Перезапись URL
- **ssl** — SSL/TLS support / Поддержка SSL/TLS
- **proxy** — Proxy functionality / Функциональность прокси
- **proxy_http** — HTTP proxy / HTTP прокси
- **headers** — HTTP headers control / Управление заголовками
- **deflate** — Compression / Сжатие
- **expires** — Cache control / Управление кешированием

---

## SSL/TLS Configuration

### Enable SSL/TLS / Включение SSL/TLS

```bash
sudo a2enmod ssl                                         # Enable SSL module / Включить модуль SSL
sudo a2ensite default-ssl                                # Enable default SSL site / Включить SSL-сайт
sudo systemctl reload apache2                            # Reload service / Перечитать конфиг
```

### Let's Encrypt (Certbot) / Let's Encrypt

```bash
# Install Certbot / Установка Certbot
sudo apt install certbot python3-certbot-apache         # Debian/Ubuntu
sudo dnf install certbot python3-certbot-apache         # RHEL/CentOS

# Obtain certificate / Получить сертификат
sudo certbot --apache -d <HOST> -d www.<HOST>           # Interactive / Интерактивно

# Auto-renewal / Автообновление
sudo certbot renew --dry-run                             # Test renewal / Тест обновления
# Cron/systemd timer usually set up automatically
# Cron/systemd таймер обычно настраивается автоматически
```

### SSL Best Practices / Лучшие практики SSL
`/etc/apache2/sites-available/<HOST>.conf`

```apache
<VirtualHost *:443>
  ServerName <HOST>
  
  SSLEngine on
  SSLCertificateFile /etc/ssl/certs/<HOST>.crt
  SSLCertificateKeyFile /etc/ssl/private/<HOST>.key
  
  # Modern SSL configuration / Современная конфигурация SSL
  SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1                 # Only TLS 1.2+ / Только TLS 1.2+
  SSLCipherSuite HIGH:!aNULL:!MD5                        # Strong ciphers / Сильные шифры
  SSLHonorCipherOrder on                                 # Prefer server ciphers / Приоритет серверу
  
  # HSTS header / Заголовок HSTS
  Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
  
  DocumentRoot /var/www/<HOST>
</VirtualHost>
```

---

## Security & Access Control

### Directory Access Control / Контроль доступа к директориям
`.htaccess` or `/etc/apache2/sites-available/<HOST>.conf`

```apache
<Directory /var/www/<HOST>/admin>
  # Require authentication / Требовать аутентификацию
  AuthType Basic
  AuthName "Restricted Area"
  AuthUserFile /etc/apache2/.htpasswd                    # Password file / Файл паролей
  Require valid-user                                     # Require valid user / Требовать пользователя
</Directory>

<Directory /var/www/<HOST>/private>
  # IP-based restriction / Ограничение по IP
  Require ip <IP>                                        # Allow specific IP / Разрешить IP
  Require ip <IP>/24                                     # Allow subnet / Разрешить подсеть
</Directory>
```

### Create Password File / Создание файла паролей

```bash
sudo htpasswd -c /etc/apache2/.htpasswd <USER>           # Create file + user / Создать файл + пользователь
sudo htpasswd /etc/apache2/.htpasswd <USER>              # Add another user / Добавить пользователя
```

### Security Headers / Заголовки безопасности
`/etc/apache2/conf-available/security.conf` or Vhost

```apache
<IfModule mod_headers.c>
  Header always set X-Frame-Options "DENY"               # Clickjacking protection / Защита от clickjacking
  Header always set X-Content-Type-Options "nosniff"     # MIME sniffing / MIME sniffing
  Header always set X-XSS-Protection "1; mode=block"     # XSS protection / Защита от XSS
  Header always set Referrer-Policy "strict-origin-when-cross-origin"
  Header always set Content-Security-Policy "default-src 'self'"
</IfModule>
```

### Disable Directory Listing / Отключить листинг директорий
`.htaccess` or Vhost

```apache
<Directory /var/www/<HOST>>
  Options -Indexes                                       # Disable listing / Отключить листинг
</Directory>
```

### Hide Apache Version / Скрыть версию Apache
`/etc/apache2/conf-available/security.conf`

```apache
# Add to apache2.conf or httpd.conf
ServerTokens Prod                                        # Minimal version info / Минимальная информация
ServerSignature Off                                      # Hide signature / Скрыть подпись
```

---

## Performance Tuning

### Enable Compression / Включить сжатие
`/etc/apache2/mods-available/deflate.conf` or Vhost

```apache
<IfModule mod_deflate.c>
  # Compress HTML, CSS, JavaScript, Text, XML
  AddOutputFilterByType DEFLATE text/plain
  AddOutputFilterByType DEFLATE text/html
  AddOutputFilterByType DEFLATE text/xml
  AddOutputFilterByType DEFLATE text/css
  AddOutputFilterByType DEFLATE application/xml
  AddOutputFilterByType DEFLATE application/xhtml+xml
  AddOutputFilterByType DEFLATE application/rss+xml
  AddOutputFilterByType DEFLATE application/javascript
  AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>
```

### Browser Caching / Кеширование браузера
`/etc/apache2/mods-available/expires.conf` or Vhost

```apache
<IfModule mod_expires.c>
  ExpiresActive On                                       # Enable expiration / Включить истечение
  
  # Images / Изображения
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/gif "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
  
  # CSS and JavaScript / CSS и JavaScript
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
  ExpiresByType application/x-javascript "access plus 1 month"
  
  # Default / По умолчанию
  ExpiresDefault "access plus 2 days"
</IfModule>
```

### MPM Configuration / Конфигурация MPM
`/etc/apache2/mods-available/mpm_*.conf`

```apache
# MPM prefork (for mod_php) / MPM prefork (для mod_php)
<IfModule mpm_prefork_module>
  StartServers             5                             # Initial servers / Начальное число
  MinSpareServers          5                             # Min idle / Мин. простаивающих
  MaxSpareServers         10                             # Max idle / Макс. простаивающих
  MaxRequestWorkers      150                             # Max concurrent / Макс. одновременных
  MaxConnectionsPerChild   0                             # Requests per child / Запросов на поток
</IfModule>

# MPM event (high performance) / MPM event (высокая производительность)
<IfModule mpm_event_module>
  StartServers             3
  MinSpareThreads         75
  MaxSpareThreads        250
  ThreadsPerChild         25
  MaxRequestWorkers      400
  MaxConnectionsPerChild   0
</IfModule>
```

### KeepAlive Settings / Настройки KeepAlive
`/etc/apache2/apache2.conf`

```apache
KeepAlive On                                             # Enable KeepAlive / Включить KeepAlive
MaxKeepAliveRequests 100                                 # Max requests per connection / Макс. запросов
KeepAliveTimeout 5                                       # Timeout in seconds / Таймаут в секундах
```

---

## Logs & Monitoring

### Log Files / Файлы логов

```bash
# Debian/Ubuntu
sudo tail -f /var/log/apache2/access.log                 # Access log / Лог доступа
sudo tail -f /var/log/apache2/error.log                  # Error log / Лог ошибок
sudo tail -f /var/log/apache2/access.log /var/log/apache2/error.log # Both logs / Оба лога

# RHEL/CentOS
sudo tail -f /var/log/httpd/access_log
sudo tail -f /var/log/httpd/error_log
```

### Custom Log Formats / Пользовательские форматы логов
`/etc/apache2/apache2.conf` or Vhost

```apache
# Combined log format (default) / Комбинированный формат (по умолчанию)
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined

# Custom format with response time / Формат с временем ответа
LogFormat "%h %l %u %t \"%r\" %>s %b %D" custom
CustomLog ${APACHE_LOG_DIR}/<HOST>_access.log custom
```

### Log Rotation / Ротация логов

```bash
# Usually handled by logrotate / Обычно обрабатывается logrotate
cat /etc/logrotate.d/apache2                             # View config / Посмотреть конфиг

# Manual rotation / Ручная ротация
sudo logrotate -f /etc/logrotate.d/apache2               # Force rotation / Принудительная ротация
```

### Apache Status Module / Модуль статуса Apache
`/etc/apache2/mods-available/status.conf`

```bash
sudo a2enmod status                                      # Enable status module / Включить модуль
sudo systemctl reload apache2
```

```apache
<Location /server-status>
  SetHandler server-status                               # Status handler / Обработчик статуса
  Require ip <IP>                                        # Restrict access / Ограничить доступ
</Location>
```

Access: `http://<HOST>/server-status`

---

## Troubleshooting & Tools

### Common Issues / Частые проблемы

```bash
# Port already in use / Порт уже используется
sudo netstat -tlnp | grep :80                            # Check what's using port 80 / Проверить порт 80
sudo lsof -i :80                                         # Alternative / Альтернатива

# Permission denied / Доступ запрещен
sudo chown -R www-data:www-data /var/www/<HOST>          # Fix ownership (Debian/Ubuntu)
sudo chown -R apache:apache /var/www/<HOST>              # Fix ownership (RHEL/CentOS)
sudo chmod -R 755 /var/www/<HOST>                        # Fix permissions / Исправить права

# SELinux issues (RHEL/CentOS) / Проблемы SELinux
sudo setenforce 0                                        # Temporarily disable / Временно отключить
sudo setsebool -P httpd_can_network_connect on          # Allow network connections / Разрешить сеть
sudo chcon -R -t httpd_sys_content_t /var/www/<HOST>    # Set context / Установить контекст
```

### Enable/Disable Sites / Включить/выключить сайты

```bash
# Debian/Ubuntu
sudo a2ensite <HOST>.conf                                # Enable site / Включить сайт
sudo a2dissite <HOST>.conf                               # Disable site / Выключить сайт
sudo systemctl reload apache2                            # Reload / Перечитать

# RHEL/CentOS
# Manually manage files in /etc/httpd/conf.d/
# Вручную управлять файлами в /etc/httpd/conf.d/
```

### Debug Configuration / Отладка конфигурации

```bash
sudo apachectl -S                                        # Show vhost summary / Показать vhost
sudo apache2ctl -M                                       # Show loaded modules / Показать модули
sudo apachectl -V                                        # Show version and build options / Версия и опции
sudo apache2ctl -t -D DUMP_VHOSTS                        # Dump vhost config / Дамп конфига vhost
sudo apache2ctl -t -D DUMP_MODULES                       # Dump modules / Дамп модулей
```

### Increase Error Log Verbosity / Увеличить подробность логов
`/etc/apache2/apache2.conf` or Vhost

```apache
# In apache2.conf or httpd.conf
LogLevel warn                                            # Default / По умолчанию
LogLevel debug                                           # Debug mode / Режим отладки
LogLevel info ssl:warn                                   # Different levels per module / Разные уровни
```

### Test Configuration Changes / Тест изменений конфигурации

```bash
sudo apachectl configtest                                # Test config / Проверить конфиг
sudo apachectl -t                                        # Short form / Краткая форма
# If syntax OK, then:
sudo systemctl reload apache2                            # Reload service / Перечитать конфиг
```

---

## Quick Reference / Краткая справка

### Essential Commands / Основные команды

```bash
sudo apachectl configtest                                # Test config / Проверить конфиг
sudo systemctl reload apache2                            # Reload no downtime / Перечитать без простоя
sudo systemctl status apache2                            # Service status / Статус сервиса
sudo tail -f /var/log/apache2/access.log /var/log/apache2/error.log # Tail logs / Хвост логов
sudo a2enmod <MODULE>                                    # Enable module / Включить модуль
sudo a2ensite <SITE>.conf                                # Enable site / Включить сайт
```

### Best Practices / Лучшие практики

- Always test config before reload: `apachectl configtest` / Всегда проверяй конфиг: `apachectl configtest`
- Use `reload` instead of `restart` for zero downtime / Используй `reload` вместо `restart`
- Keep separate vhost files in `sites-available/` / Храни отдельные vhost в `sites-available/`
- Enable only needed modules / Включай только нужные модули
- Use HTTPS everywhere / Используй HTTPS везде
- Set up proper log rotation / Настрой ротацию логов
- Monitor logs regularly / Регулярно проверяй логи
- Keep Apache updated / Обновляй Apache

---

## Logrotate Configuration / Конфигурация Logrotate

### Debian/Ubuntu

`/etc/logrotate.d/apache2`

```conf
/var/log/apache2/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /usr/sbin/apachectl graceful > /dev/null 2>&1 || true
    endscript
}
```

### RHEL/CentOS/AlmaLinux

`/etc/logrotate.d/httpd`

```conf
/var/log/httpd/*log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>&1 || true
    endscript
}
```

> [!TIP]
> Use `graceful` instead of `restart` to avoid dropping connections.
> Используйте `graceful` вместо `restart` для сохранения соединений.

---

## Documentation Links

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/current/)
- [Apache Module Index](https://httpd.apache.org/docs/current/mod/)
- [Apache SSL/TLS HowTo](https://httpd.apache.org/docs/current/ssl/ssl_howto.html)
- [Apache Virtual Host Examples](https://httpd.apache.org/docs/current/vhosts/examples.html)
- [Apache Security Tips](https://httpd.apache.org/docs/current/misc/security_tips.html)
- [Apache Performance Tuning](https://httpd.apache.org/docs/current/misc/perf-tuning.html)

---
