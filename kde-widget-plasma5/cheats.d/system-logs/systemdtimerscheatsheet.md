Title: 🕰️ systemd Timers — Scheduled Tasks
Group: System & Logs
Icon: 🕰️
Order: 4

## Table of Contents
- [Timer Basics](#-timer-basics--основы-таймеров)
- [Creating Timers](#-creating-timers--создание-таймеров)
- [Management](#-management--управление)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Timer Basics / Основы таймеров

### List Timers / Список таймеров
systemctl list-timers                         # List active timers / Список активных таймеров
systemctl list-timers --all                   # List all timers / Список всех таймеров
systemctl list-timers --state=failed          # Failed timers / Неудавшиеся таймеры

### Timer Status / Статус таймера
systemctl status my.timer                     # Show timer status / Показать статус таймера
systemctl show my.timer                       # Detailed timer properties / Подробные свойства таймера
journalctl -u my.timer                        # Timer logs / Логи таймера
journalctl -u my.service                      # Service logs / Логи сервиса

---

# 📝 Creating Timers / Создание таймеров

### Timer Unit File / Файл таймера
```ini
# /etc/systemd/system/my.timer
[Unit]
Description=Run my service daily
Requires=my.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 03:00:00            # Every day at 3 AM / Каждый день в 3:00
Persistent=true                       # Run if missed / Запустить если пропущено
RandomizedDelaySec=30min              # Random delay / Случайная задержка

[Install]
WantedBy=timers.target
```

### Service Unit File / Файл сервиса
```ini
# /etc/systemd/system/my.service
[Unit]
Description=My backup job

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
User=backup
Group=backup
```

### OnCalendar Formats / Форматы OnCalendar
```bash
OnCalendar=hourly                             # Every hour / Каждый час
OnCalendar=daily                              # Daily at midnight / Ежедневно в полночь
OnCalendar=weekly                             # Weekly on Monday / Еженедельно по понедельникам
OnCalendar=monthly                            # Monthly on 1st / Ежемесячно 1-го числа
OnCalendar=*-*-* 00:00:00                     # Every day at midnight / Каждый день в полночь
OnCalendar=*-*-* 03:00:00                     # Every day at 3 AM / Каждый день в 3:00
OnCalendar=Mon,Wed,Fri 10:00                  # Mon/Wed/Fri at 10 AM / Пн/Ср/Пт в 10:00
OnCalendar=*-01-01 00:00:00                   # New Year / Новый год
OnCalendar=*-*-01 02:00:00                    # 1st of month at 2 AM / 1-го числа в 2:00
```

### Monotonic Timers / Монотонные таймеры
```ini
OnBootSec=15min                               # 15 min after boot / 15 мин после загрузки
OnUnitActiveSec=1h                            # 1 hour after last activation / 1 час после последней активации
OnUnitInactiveSec=30min                       # 30 min after last deactivation / 30 мин после последней деактивации
OnStartupSec=5min                             # 5 min after systemd started / 5 мин после запуска systemd
```

---

# 🛠️ Management / Управление

### Enable & Start / Включить и запустить
sudo systemctl daemon-reload                  # Reload systemd / Перезагрузить systemd
sudo systemctl enable my.timer                # Enable timer / Включить таймер
sudo systemctl start my.timer                 # Start timer / Запустить таймер
sudo systemctl enable --now my.timer          # Enable and start / Включить и запустить

### Control / Управление
sudo systemctl stop my.timer                  # Stop timer / Остановить таймер
sudo systemctl disable my.timer               # Disable timer / Отключить таймер
sudo systemctl restart my.timer               # Restart timer / Перезапустить таймер

### Trigger Manually / Запустить вручную
sudo systemctl start my.service               # Run service now / Запустить сервис сейчас

---

# 🌟 Real-World Examples / Примеры из практики

### Daily Backup / Ежедневное резервное копирование
```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily backup at 3 AM

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup script

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
User=backup
```

```bash
# Enable / Включить
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
```

### Hourly Log Rotation / Ежечасная ротация логов
```ini
# /etc/systemd/system/logrotate.timer
[Unit]
Description=Hourly log rotation

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/logrotate.service
[Unit]
Description=Rotate logs

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.conf
```

### Cleanup Old Files Every Week / Очистка старых файлов раз в неделю
```ini
# /etc/systemd/system/cleanup.timer
[Unit]
Description=Weekly cleanup

[Timer]
OnCalendar=Sun 02:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
#!/bin/bash
# /usr/local/bin/cleanup.sh
find /tmp -type f -mtime +7 -delete
find /var/log -name "*.log.gz" -mtime +30 -delete
```

### Database Backup Every 6 Hours / Резервное копирование БД каждые 6 часов
```ini
# /etc/systemd/system/db-backup.timer
[Unit]
Description=Database backup every 6 hours

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/db-backup.service
[Unit]
Description=Backup PostgreSQL database

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pg-backup.sh
User=postgres
Environment="PGPASSWORD=<PASSWORD>"
```

### Monitor Service Every 5 Minutes / Мониторинг сервиса каждые 5 минут
```ini
# /etc/systemd/system/monitor.timer
[Unit]
Description=Monitor service every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

### Certificate Renewal Daily / Обновление сертификатов ежедневно
```ini
# /etc/systemd/system/certbot.timer
[Unit]
Description=Certbot renewal

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/certbot.service
[Unit]
Description=Certbot renewal service

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet
ExecStartPost=/bin/systemctl reload nginx
```

### Verify Timer Schedule / Проверить расписание таймера
```bash
# Check next run time / Проверить следующий запуск
systemd-analyze calendar '*-*-* 03:00:00'

# Test timer expression / Тестировать выражение таймера
systemd-analyze calendar 'Mon,Wed,Fri 10:00'

# Show timer next run / Показать следующий запуск таймера
systemctl list-timers backup.timer
```

# 💡 Best Practices / Лучшие практики
# Use Persistent=true to run missed jobs / Используйте Persistent=true для запуска пропущенных задач
# Use RandomizedDelaySec to spread load / Используйте RandomizedDelaySec для распределения нагрузки
# Always create both .timer and .service / Всегда создавайте оба .timer и .service
# Test with systemd-analyze calendar / Тестируйте с systemd-analyze calendar
# Use Type=oneshot for service units / Используйте Type=oneshot для сервисных юнитов
# Check logs with journalctl / Проверяйте логи с journalctl

# 🔧 Timer Options / Опции таймера
# OnCalendar: Calendar-based scheduling / Расписание по календарю
# OnBootSec: After boot / После загрузки
# OnStartupSec: After systemd start / После запуска systemd
# OnUnitActiveSec: After last activation / После последней активации
# Persistent: Run missed jobs / Запускать пропущенные задачи
# RandomizedDelaySec: Random delay / Случайная задержка
# AccuracySec: Accuracy / Точность

# 📋 systemd-analyze Calendar / Анализ календаря
systemd-analyze calendar daily                # Parse 'daily' / Разобрать 'daily'
systemd-analyze calendar hourly               # Parse 'hourly' / Разобрать 'hourly'
systemd-analyze calendar 'Mon *-*-* 10:00'    # Parse expression / Разобрать выражение

# ⚠️ Common Issues / Распространённые проблемы
# Timer running but service not: Check Requires= / Таймер работает но сервис нет: Проверьте Requires=
# Missed jobs not running: Add Persistent=true / Пропущенные задачи не запускаются: Добавьте Persistent=true
# Wrong timezone: Check timedatectl / Неправильный часовой пояс: Проверьте timedatectl
