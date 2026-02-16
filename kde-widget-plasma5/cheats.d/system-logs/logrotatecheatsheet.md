Title: 🌀 logrotate — Log Management
Group: System & Logs
Icon: 🌀
Order: 6

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Configuration](#-configuration--конфигурация)
- [Rotation Strategies](#-rotation-strategies--стратегии-ротации)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Basic Commands / Базовые команды

### Test & Force / Тест и принудительный запуск
sudo logrotate -d /etc/logrotate.conf         # Dry-run (debug mode) / Тестовый прогон
sudo logrotate -v /etc/logrotate.conf         # Verbose mode / Подробный режим
sudo logrotate -f /etc/logrotate.conf         # Force rotation / Принудительная ротация
sudo logrotate -f /etc/logrotate.d/nginx      # Force specific config / Принудительно для конкретного конфига

### Check Configuration / Проверить конфигурацию
sudo logrotate -d /etc/logrotate.d/nginx      # Test nginx config / Проверить конфиг nginx
cat /etc/logrotate.d/nginx                    # View nginx config / Просмотр конфига nginx
cat /var/lib/logrotate/status                 # Check last rotation / Проверить последнюю ротацию

---

# ⚙️ Configuration / Конфигурация

### Main Config File / Основной файл конфигурации
```bash
# /etc/logrotate.conf
weekly                                        # Rotate weekly / Ротация еженедельно
rotate 4                                      # Keep 4 weeks / Хранить 4 недели
create                                        # Create new file after rotation / Создать новый файл после ротации
compress                                      # Compress rotated logs / Сжимать ротированные логи
include /etc/logrotate.d                      # Include conf.d directory / Включить conf.d директорию
```

### Basic Options / Базовые опции
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

### Compression / Сжатие
```bash
compress                                      # Compress rotated logs / Сжимать ротированные логи
compress
delaycompress                                 # Delay compression by one cycle / Отложить сжатие на один цикл
delaycompress
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
```

---

# 🔄 Rotation Strategies / Стратегии ротации

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

# 🌟 Real-World Examples / Примеры из практики

### Nginx Logs / Логи Nginx
```bash
# /etc/logrotate.d/nginx
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
```bash
# /etc/logrotate.d/apache2
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
```bash
# /etc/logrotate.d/myapp
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
```bash
# /etc/logrotate.d/docker
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
```bash
# /etc/logrotate.d/rsyslog
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
```bash
# /etc/logrotate.d/mysql
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

# 💡 Best Practices / Лучшие практики
# Use size limits to prevent disk full / Используйте ограничения размера для предотвращения заполнения диска
# Compress rotated logs to save space / Сжимайте ротированные логи для экономии места
# Use delaycompress with applications that keep log files open / Используйте delaycompress с приложениями, которые держат файлы логов открытыми
# Test configs with -d before deploying / Тестируйте конфиги с -d перед развёртыванием
# Use sharedscripts for efficiency / Используйте sharedscripts для эффективности
# Set proper permissions with create / Устанавливайте правильные права с create
# Use dateext for better organization / Используйте dateext для лучшей организации

# 🔧 Configuration Files / Файлы конфигурации
# /etc/logrotate.conf — Main config / Основная конфигурация
# /etc/logrotate.d/ — Per-application configs / Конфигурации по приложениям
# /var/lib/logrotate/status — Rotation status / Статус ротации

# 📋 Common Options / Распространённые опции
# daily, weekly, monthly: Rotation frequency / Частота ротации
# rotate N: Keep N rotated logs / Хранить N ротированных логов
# compress: Compress rotated logs / Сжимать ротированные логи
# create: Create new file / Создать новый файл
# copytruncate: Copy then truncate / Скопировать затем обрезать
# missingok: OK if missing / ОК если отсутствует
# notifempty: Don't rotate if empty / Не ротировать если пусто
# size: Rotate by size / Ротация по размеру

# ⚠️ Important Notes / Важные примечания
# logrotate runs via cron (usually daily) / logrotate запускается через cron (обычно ежедневно)
# Use copytruncate for apps that can't reopen logs / Используйте copytruncate для приложений, которые не могут переоткрыть логи
# Test before deploying to production / Тестируйте перед развёртыванием в продакшене
# Monitor disk space regularly / Регулярно мониторьте дисковое пространство
