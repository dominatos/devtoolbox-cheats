Title: 🌀 logrotate — Log Management
Group: System & Logs
Icon: 🌀
Order: 6

# logrotate — Log Rotation & Management

**logrotate** is a system utility for automating the rotation, compression, removal, and mailing of log files. It prevents log files from consuming all available disk space and is essential for maintaining healthy servers.

**How it works / Как работает:**
logrotate runs periodically (usually daily) via cron (`/etc/cron.daily/logrotate`) or a systemd timer (`logrotate.timer`). It reads its configuration and rotates logs that match the defined criteria (age, size, or both).

**Key features / Ключевые возможности:**
- **Time-based rotation** — daily, weekly, monthly, yearly
- **Size-based rotation** — rotate when file exceeds a threshold
- **Compression** — gzip (default), xz, bzip2
- **Pre/post-rotate scripts** — reload services, cleanup, notifications
- **copytruncate** — for applications that can't reopen log files

logrotate is part of virtually all Linux distributions and has been the standard log management tool for decades. For journald-managed logs, rotation is handled by `journald.conf` instead.

---

## 📚 Table of Contents / Содержание

1. [Basic Commands](#basic-commands)
2. [Configuration](#configuration)
3. [Rotation Strategies](#rotation-strategies)
4. [Real-World Examples](#real-world-examples)

---

## Basic Commands

### Test & Force / Тест и принудительный запуск

```bash
sudo logrotate -d /etc/logrotate.conf         # Dry-run (debug mode) / Тестовый прогон
sudo logrotate -v /etc/logrotate.conf         # Verbose mode / Подробный режим
sudo logrotate -f /etc/logrotate.conf         # Force rotation / Принудительная ротация
sudo logrotate -f /etc/logrotate.d/nginx      # Force specific config / Принудительно для конкретного конфига
```

### Check Configuration / Проверить конфигурацию

```bash
sudo logrotate -d /etc/logrotate.d/nginx      # Test nginx config / Проверить конфиг nginx
cat /etc/logrotate.d/nginx                    # View nginx config / Просмотр конфига nginx
cat /var/lib/logrotate/status                 # Check last rotation / Проверить последнюю ротацию
```

> [!TIP]
> Always test with `-d` (dry-run) before deploying a new config to production. / Всегда тестируйте с `-d` перед развёртыванием.

---

## Configuration

### Main Config File / Основной файл конфигурации

`/etc/logrotate.conf`

```bash
weekly                                        # Rotate weekly / Ротация еженедельно
rotate 4                                      # Keep 4 weeks / Хранить 4 недели
create                                        # Create new file after rotation / Создать новый файл после ротации
compress                                      # Compress rotated logs / Сжимать ротированные логи
include /etc/logrotate.d                      # Include conf.d directory / Включить conf.d директорию
```

### Rotation Frequency Options / Опции частоты ротации

```bash
daily                                         # Rotate daily / Ротация ежедневно
weekly                                        # Rotate weekly / Ротация еженедельно
monthly                                       # Rotate monthly / Ротация ежемесячно
yearly                                        # Rotate yearly / Ротация ежегодно
rotate 7                                      # Keep 7 rotations / Хранить 7 ротаций
size 100M                                     # Rotate when size > 100MB / Ротация когда размер > 100МБ
maxsize 500M                                  # Force rotate if > 500MB / Принудительная ротация если > 500МБ
minsize 1M                                    # Don't rotate if < 1MB / Не ротировать если < 1МБ
```

### Compression Options / Опции сжатия

```bash
compress                                      # Compress rotated logs / Сжимать ротированные логи
delaycompress                                 # Delay compression by one cycle / Отложить сжатие на один цикл
compresscmd /usr/bin/xz                       # Use xz for compression / Использовать xz для сжатия
compressoptions -9                            # Compression options / Опции сжатия
```

### File Handling / Обработка файлов

```bash
create 0644 www-data www-data                 # Create with permissions / Создать с правами
copytruncate                                  # Copy then truncate / Скопировать затем обрезать
nocreate                                      # Don't create new file / Не создавать новый файл
missingok                                     # OK if file missing / ОК если файл отсутствует
notifempty                                    # Don't rotate if empty / Не ротировать если пусто
sharedscripts                                 # Run scripts once / Запустить скрипты один раз
dateext                                       # Add date to rotated filename / Добавить дату к имени
```

### copytruncate vs create / Сравнение

| Method | Description (EN / RU) | When to Use / Когда использовать |
| :--- | :--- | :--- |
| `create` | Rename old log, create new one / Переименовать старый, создать новый | Apps that can reopen log files (via HUP signal) |
| `copytruncate` | Copy log, then truncate original / Скопировать, обрезать оригинал | Apps that can't reopen logs (e.g. some Java apps) |

> [!WARNING]
> `copytruncate` can lose log lines written between copy and truncate. Prefer `create` with `postrotate` signal when possible. / `copytruncate` может потерять строки, записанные между копированием и обрезкой.

---

## Rotation Strategies

### Size-Based Rotation / Ротация по размеру

```bash
/var/log/app/*.log {
    size 100M                                 # Rotate at 100MB / Ротация при 100МБ
    rotate 10                                 # Keep 10 files / Хранить 10 файлов
    compress                                  # Compress / Сжимать
    missingok                                 # OK if missing / ОК если отсутствует
    notifempty                                # Don't rotate if empty / Не ротировать если пусто
}
```

### Time-Based Rotation / Ротация по времени

```bash
/var/log/nginx/*.log {
    daily                                     # Daily rotation / Ежедневная ротация
    rotate 30                                 # Keep 30 days / Хранить 30 дней
    compress                                  # Compress / Сжимать
    delaycompress                             # Delay compression / Отложить сжатие
    sharedscripts                             # Shared scripts / Общие скрипты
    postrotate                                # After rotation / После ротации
        /usr/sbin/nginx -s reload             # Reload nginx / Перезагрузить nginx
    endscript
}
```

### Combined Strategy / Комбинированная стратегия

```bash
/var/log/app/access.log {
    daily                                     # Daily rotation / Ежедневная ротация
    size 50M                                  # Also rotate at 50MB / Также ротация при 50МБ
    rotate 14                                 # Keep 14 days / Хранить 14 дней
    compress                                  # Compress / Сжимать
    create 0640 app app                       # Create with permissions / Создать с правами
    postrotate                                # After rotation / После ротации
        systemctl reload app                  # Reload service / Перезагрузить сервис
    endscript
}
```

---

## Real-World Examples

### Nginx Logs / Логи Nginx

`/etc/logrotate.d/nginx`

```bash
/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi
    endscript
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
```

### Apache Logs / Логи Apache

`/etc/logrotate.d/apache2`

```bash
/var/log/apache2/*.log {
    weekly
    rotate 52
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        /etc/init.d/apache2 reload > /dev/null
    endscript
}
```

### Application Logs / Логи приложений

`/etc/logrotate.d/myapp`

```bash
/var/log/myapp/*.log {
    daily
    size 100M
    rotate 30
    compress
    compresscmd /usr/bin/xz
    compressoptions -9
    missingok
    notifempty
    create 0644 myapp myapp
    dateext
    dateformat -%Y%m%d
    postrotate
        systemctl reload myapp.service
    endscript
}
```

### Docker Container Logs / Логи контейнеров Docker

`/etc/logrotate.d/docker`

```bash
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    maxsize 100M
    missingok
    notifempty
    copytruncate
}
```

### System Logs / Системные логи

`/etc/logrotate.d/rsyslog`

```bash
/var/log/syslog
/var/log/mail.log
/var/log/kern.log
{
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

### Database Logs / Логи баз данных

`/etc/logrotate.d/mysql`

```bash
/var/log/mysql/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 mysql adm
    sharedscripts
    postrotate
        test -x /usr/bin/mysqladmin || exit 0
        /usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf flush-logs
    endscript
}
```

### Dated Archives / Архивы с датами

```bash
/var/log/app/*.log {
    daily
    rotate 365
    compress
    dateext                                   # Add date extension / Добавить расширение с датой
    dateformat -%Y-%m-%d                      # Date format / Формат даты
    extension .log                            # Keep extension / Сохранить расширение
    missingok
    notifempty
}
```

### Custom Cleanup Script / Пользовательский скрипт очистки

```bash
/var/log/custom/*.log {
    weekly
    rotate 4
    compress
    postrotate
        find /var/log/custom -type f -name "*.gz" -mtime +90 -delete
        echo "Cleaned logs older than 90 days" | logger
    endscript
}
```

---

## Default Paths / Пути по умолчанию

| Path | Purpose (EN) | Назначение (RU) |
| :--- | :--- | :--- |
| `/etc/logrotate.conf` | Main configuration | Основная конфигурация |
| `/etc/logrotate.d/` | Per-app configs | Конфигурации приложений |
| `/var/lib/logrotate/status` | Rotation status/state | Статус ротации |
| `/etc/cron.daily/logrotate` | Cron trigger (traditional) | Запуск через cron |

---

## 💡 Best Practices / Лучшие практики

- Use **size limits** to prevent disk full situations. / Используйте ограничения размера.
- **Compress** rotated logs to save space. / Сжимайте ротированные логи.
- Use `delaycompress` with applications that keep log files open. / Используйте `delaycompress` с приложениями, держащими логи открытыми.
- **Test configs** with `-d` before deploying. / Тестируйте конфиги с `-d` перед развёртыванием.
- Use `sharedscripts` for efficiency with wildcard paths. / Используйте `sharedscripts` с масками.
- Set **proper permissions** with `create`. / Устанавливайте правильные права с `create`.
- Use `dateext` for better organization. / Используйте `dateext` для лучшей организации.

> [!NOTE]
> logrotate runs via cron (typically `/etc/cron.daily/logrotate`) or a systemd timer (`logrotate.timer`). Check which method your system uses. / logrotate запускается через cron или systemd таймер.

---

## Documentation Links

- **logrotate(8):** https://man7.org/linux/man-pages/man8/logrotate.8.html
- **logrotate on GitHub:** https://github.com/logrotate/logrotate
- **ArchWiki — Logrotate:** https://wiki.archlinux.org/title/Logrotate
- **Red Hat — Managing Log Files:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_troubleshooting-problems-using-log-files_configuring-basic-system-settings
