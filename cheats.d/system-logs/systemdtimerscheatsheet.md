Title: 🕰️ systemd Timers — Scheduled Tasks
Group: System & Logs
Icon: 🕰️
Order: 4

# systemd Timers — Scheduled Tasks

**systemd timers** are the modern replacement for cron jobs, offering calendar-based and monotonic scheduling with full integration into the systemd ecosystem. Each timer triggers a corresponding `.service` unit, with output logged via journald.

**Advantages over cron / Преимущества перед cron:**
- **Journald integration** — all output logged automatically, queryable via `journalctl -u <service>`
- **Dependency support** — `After=`, `Requires=`, integration with network/mount targets
- **Persistent flag** — automatically runs missed jobs if system was off
- **RandomizedDelaySec** — spreads load across time window
- **Resource control** — cgroups limits, sandboxing via `[Service]` directives
- **Easy testing** — `systemd-analyze calendar` validates expressions before deployment

**When to use cron vs timers / Когда использовать cron vs таймеры:**
- Use **systemd timers** for new setups, complex dependencies, resource limits
- Use **cron** for simple one-liners, legacy compatibility, or minimal systems without systemd

---

## 📚 Table of Contents / Содержание

1. [Timer Basics](#timer-basics)
2. [Creating Timers](#creating-timers)
3. [Management](#management)
4. [Real-World Examples](#real-world-examples)

---

## Timer Basics

### List Timers / Список таймеров

```bash
systemctl list-timers                         # List active timers / Список активных таймеров
systemctl list-timers --all                   # List all timers / Список всех таймеров
systemctl list-timers --state=failed          # Failed timers / Неудавшиеся таймеры
```

### Timer Status / Статус таймера

```bash
systemctl status my.timer                     # Show timer status / Показать статус таймера
systemctl show my.timer                       # Detailed timer properties / Подробные свойства таймера
journalctl -u my.timer                        # Timer logs / Логи таймера
journalctl -u my.service                      # Service logs / Логи сервиса
```

---

## Creating Timers

### Timer Unit File / Файл таймера

`/etc/systemd/system/my.timer`

```ini
[Unit]
Description=Run my service daily

[Timer]
OnCalendar=*-*-* 03:00:00                     # Every day at 3 AM / Каждый день в 3:00
Persistent=true                               # Run if missed / Запустить если пропущено
RandomizedDelaySec=30min                      # Random delay / Случайная задержка

[Install]
WantedBy=timers.target
```

### Service Unit File / Файл сервиса

`/etc/systemd/system/my.service`

```ini
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

### Timer Type Comparison / Сравнение типов таймеров

| Timer Type | Description (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| `OnCalendar` | Calendar-based (like cron) / По календарю | Backups at 3 AM, monthly tasks |
| `OnBootSec` | After system boot / После загрузки | Post-boot warmup, checks |
| `OnUnitActiveSec` | After last activation / После активации | Recurring polling intervals |
| `OnStartupSec` | After systemd starts / После запуска systemd | Similar to OnBootSec |

---

## Management

### Enable & Start / Включить и запустить

```bash
sudo systemctl daemon-reload                  # Reload systemd / Перезагрузить systemd
sudo systemctl enable my.timer                # Enable timer / Включить таймер
sudo systemctl start my.timer                 # Start timer / Запустить таймер
sudo systemctl enable --now my.timer          # Enable and start / Включить и запустить
```

### Control / Управление

```bash
sudo systemctl stop my.timer                  # Stop timer / Остановить таймер
sudo systemctl disable my.timer               # Disable timer / Отключить таймер
sudo systemctl restart my.timer               # Restart timer / Перезапустить таймер
```

### Trigger Manually / Запустить вручную

```bash
sudo systemctl start my.service               # Run service now / Запустить сервис сейчас
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

### Parse Calendar Specs / Разобрать спецификации календаря

```bash
systemd-analyze calendar daily                # Parse 'daily' / Разобрать 'daily'
systemd-analyze calendar hourly               # Parse 'hourly' / Разобрать 'hourly'
systemd-analyze calendar 'Mon *-*-* 10:00'    # Parse expression / Разобрать выражение
```

---

## Real-World Examples

### Daily Backup / Ежедневное резервное копирование

`/etc/systemd/system/backup.timer`

```ini
[Unit]
Description=Daily backup at 3 AM

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/backup.service`

```ini
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

`/etc/systemd/system/logrotate.timer`

```ini
[Unit]
Description=Hourly log rotation

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/logrotate.service`

```ini
[Unit]
Description=Rotate logs

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.conf
```

### Cleanup Old Files Every Week / Очистка старых файлов раз в неделю

`/etc/systemd/system/cleanup.timer`

```ini
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

`/etc/systemd/system/db-backup.timer`

```ini
[Unit]
Description=Database backup every 6 hours

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/db-backup.service`

```ini
[Unit]
Description=Backup PostgreSQL database

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pg-backup.sh
User=postgres
Environment="PGPASSWORD=<PASSWORD>"
```

### Monitor Service Every 5 Minutes / Мониторинг сервиса каждые 5 минут

`/etc/systemd/system/monitor.timer`

```ini
[Unit]
Description=Monitor service every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

### Certificate Renewal Daily / Обновление сертификатов ежедневно

`/etc/systemd/system/certbot.timer`

```ini
[Unit]
Description=Certbot renewal

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/certbot.service`

```ini
[Unit]
Description=Certbot renewal service

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet
ExecStartPost=/bin/systemctl reload nginx
```

---

## 💡 Best Practices / Лучшие практики

- Use `Persistent=true` to run missed jobs. / Используйте `Persistent=true` для пропущенных задач.
- Use `RandomizedDelaySec` to spread load. / Используйте `RandomizedDelaySec` для распределения нагрузки.
- Always create **both** `.timer` and `.service` files. / Всегда создавайте оба файла.
- Test with `systemd-analyze calendar`. / Тестируйте с `systemd-analyze calendar`.
- Use `Type=oneshot` for service units. / Используйте `Type=oneshot` для сервисных юнитов.
- Check logs with `journalctl -u <service>`. / Проверяйте логи через journalctl.

> [!NOTE]
> Common issues: Timer running but service not starting → check `Requires=`. Missed jobs not running → add `Persistent=true`. Wrong timezone → check `timedatectl`. / Частые проблемы: таймер работает но сервис нет → проверьте `Requires=`.

---

## Documentation Links

- **systemd.timer(5):** https://man7.org/linux/man-pages/man5/systemd.timer.5.html
- **systemd.time(7):** https://man7.org/linux/man-pages/man7/systemd.time.7.html
- **systemd-analyze(1):** https://man7.org/linux/man-pages/man1/systemd-analyze.1.html
- **ArchWiki — Timers:** https://wiki.archlinux.org/title/Systemd/Timers
- **Red Hat — systemd Timers:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/managing-system-services-with-systemctl_configuring-basic-system-settings#creating-and-managing-timer-units_managing-system-services-with-systemctl
