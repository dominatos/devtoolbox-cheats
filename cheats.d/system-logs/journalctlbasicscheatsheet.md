---
Title: 📜 journalctl — Basics
Group: "System & Logs"
Icon: 📜
Order: 3
tags:
  - system
  - logs
  - sysadmin
  - linux
---

# journalctl — Quick Reference Guide

**journalctl** is the command-line tool for querying the systemd journal. This cheatsheet covers everyday usage patterns for quick reference. For full documentation and advanced usage, see the [journalctl — Systemd Journal](journalctlcheatsheet.md) cheatsheet.

📚 **Official Docs / Официальная документация:**
[journalctl(1)](https://man7.org/linux/man-pages/man1/journalctl.1.html) · [journald.conf(5)](https://man7.org/linux/man-pages/man5/journald.conf.5.html)

## Table of Contents

- [Basic Viewing](#Basic%20Viewing)
- [Time Filters](#Time%20Filters)
- [Unit Filters](#Unit%20Filters)
- [Priority & Field Filters](#Priority%20&%20Field%20Filters)
- [Output Formats](#Output%20Formats)
- [Maintenance](#Maintenance)
- [Troubleshooting](#Troubleshooting)
- [💡 Best Practices](#💡%20Best%20Practices)
- [Documentation Links](#Documentation%20Links)

---

## Basic Viewing

### Quick Access

```bash
journalctl                                # All logs / Все логи
journalctl -xe                            # Recent errors (extended) / Недавние ошибки (расширенно)
journalctl -f                             # Follow (tail -f) / Следить в реальном времени
journalctl -n 100                         # Last 100 lines / Последние 100 строк
```

### Reverse Order

```bash
journalctl -r                             # Newest first / Новые сначала
journalctl -r -n 50                       # Last 50, newest first / Последние 50, новые сначала
```

### Boot Logs

```bash
journalctl -b                             # Current boot / Текущая загрузка
journalctl -b -1                          # Previous boot / Предыдущая загрузка
journalctl -b -2                          # Boot before last / Позапрошлая загрузка
journalctl --list-boots                   # List all boots / Список всех загрузок
```

---

## Time Filters

### Since / Until

```bash
journalctl --since "1 hour ago"           # Last hour / Последний час
journalctl --since "2 hours ago" --until "1 hour ago"  # Range / Диапазон
journalctl --since today                  # Since midnight / С полуночи
journalctl --since yesterday              # Since yesterday / С вчера
```

### Specific Date/Time

```bash
journalctl --since "2025-02-01"           # Since date / С даты
journalctl --since "2025-02-01 09:00:00"  # With time / С временем
journalctl --since "2025-02-01" --until "2025-02-05"  # Date range / Диапазон дат
```

### Relative Time

```bash
journalctl --since "30 min ago"           # Last 30 minutes / Последние 30 минут
journalctl --since "1 week ago"           # Last week / Последняя неделя
journalctl --since "-1 day"               # Alternative syntax / Альтернативный синтаксис
```

---

## Unit Filters

### By Service

```bash
journalctl -u nginx                       # Nginx logs / Логи nginx
journalctl -u nginx.service               # Same, explicit / То же, явно
journalctl -u nginx -u php-fpm            # Multiple units / Несколько юнитов
journalctl -u nginx -f                    # Follow nginx logs / Следить за nginx
```

### By Unit Pattern

```bash
journalctl -u 'docker*'                   # All docker units / Все docker юниты
journalctl -u 'mysql*'                    # All mysql units / Все mysql юниты
```

### Combine with Time

```bash
journalctl -u nginx --since "1 hour ago"  # Nginx last hour / Nginx за последний час
journalctl -u nginx -f --since "1 hour ago"  # Follow from 1 hour / Следить с часа назад
```

---

## Priority & Field Filters

### By Priority

```bash
journalctl -p err                         # Errors and above / Ошибки и выше
journalctl -p warning                     # Warnings and above / Предупреждения и выше
journalctl -p warning..emerg              # Range warning to emergency / От warning до emergency
journalctl -p 0..3                        # By number (0=emerg, 7=debug) / По номеру
```

### Priority Levels

```text
0 = emerg     — System unusable / Система неработоспособна
1 = alert     — Action required / Требуется действие
2 = crit      — Critical conditions / Критические условия
3 = err       — Error conditions / Условия ошибки
4 = warning   — Warning conditions / Предупреждения
5 = notice    — Normal but significant / Нормально, но важно
6 = info      — Informational / Информационные
7 = debug     — Debug messages / Отладочные сообщения
```

### By Field

```bash
journalctl _PID=<PID>                     # By PID / По PID
journalctl _UID=1000                      # By UID / По UID
journalctl _SYSTEMD_UNIT=sshd.service     # By unit field / По полю юнита
journalctl _HOSTNAME=<HOST>               # By hostname / По имени хоста
journalctl _COMM=nginx                    # By command name / По имени команды
```

### Combine Filters

```bash
journalctl -u nginx -p err --since today  # Nginx errors today / Ошибки nginx за сегодня
journalctl _UID=1000 -p warning           # User warnings / Предупреждения пользователя
```

---

## Output Formats

### Standard Formats

```bash
journalctl -o short                       # Default format / Формат по умолчанию
journalctl -o short-precise               # With microseconds / С микросекундами
journalctl -o verbose                     # All fields / Все поля
journalctl -o json                        # JSON format / Формат JSON
journalctl -o json-pretty                 # Pretty JSON / Читаемый JSON
journalctl -o cat                         # Message only / Только сообщение
```

### Export

```bash
journalctl -u nginx > nginx.log           # Save to file / Сохранить в файл
journalctl -u nginx -o json > nginx.json  # JSON export / JSON экспорт
journalctl --no-pager -u nginx            # No pager (for piping) / Без пейджера
```

---

## Maintenance

### Disk Usage

```bash
journalctl --disk-usage                   # Show journal size / Показать размер журнала
```

### Cleanup

```bash
sudo journalctl --vacuum-size=500M        # Keep only 500MB / Оставить только 500MB
sudo journalctl --vacuum-time=7d          # Keep only 7 days / Оставить только 7 дней
sudo journalctl --vacuum-files=5          # Keep only 5 files / Оставить только 5 файлов
```

### Persistent Storage

```bash
# Enable persistent journal
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

### Configuration

`/etc/systemd/journald.conf`

```ini
[Journal]
Storage=persistent                        # Auto/persistent/volatile/none
SystemMaxUse=500M                         # Max disk usage / Макс. использование диска
SystemMaxFileSize=50M                     # Max file size / Макс. размер файла
MaxRetentionSec=1week                     # Max retention / Макс. хранение
```

---

## Troubleshooting

### Debug Service Failures

```bash
# Check failed units
systemctl list-units --failed

# Get logs for failed service
journalctl -u failed-service.service -xe

# Get logs around failure time
journalctl -u myapp --since "10 min ago" -n 100
```

### Kernel Messages

```bash
journalctl -k                             # Kernel messages / Сообщения ядра
journalctl -k -b                          # Kernel since boot / Ядро с загрузки
journalctl -k -p err                      # Kernel errors / Ошибки ядра
```

### Find Specific Events

```bash
# SSH login attempts
journalctl -u sshd --since today | grep "Accepted"

# Failed logins
journalctl -u sshd --since today | grep "Failed"

# Out of memory
journalctl -k | grep -i "oom\|out of memory"
```

---

## 💡 Best Practices

- Use `-u` for service logs, not `grep` in `/var/log`. / Используйте `-u` для логов сервисов.
- Enable persistent journal for post-reboot debugging. / Включите постоянный журнал для отладки после перезагрузки.
- Set up log rotation via `journald.conf`. / Настройте ротацию через `journald.conf`.
- Use `--since` and `--until` to narrow down issues. / Используйте `--since` и `--until` для сужения поиска.

---

## Documentation Links

- **journalctl(1):** https://man7.org/linux/man-pages/man1/journalctl.1.html
- **journald.conf(5):** https://man7.org/linux/man-pages/man5/journald.conf.5.html
- **ArchWiki — systemd/Journal:** https://wiki.archlinux.org/title/Systemd/Journal
