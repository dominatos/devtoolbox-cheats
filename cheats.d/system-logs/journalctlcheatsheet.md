Title: 📜 journalctl — Systemd Journal
Group: System & Logs
Icon: 📜
Order: 2

# journalctl — Systemd Journal Log Viewer

**journalctl** is the command-line tool for querying and displaying logs from the **systemd journal** (journald). It replaces traditional syslog file browsing and provides structured, indexed, and queryable log access with rich filtering capabilities.

**journald** collects logs from:
- systemd services (stdout/stderr)
- Kernel messages (dmesg/kmsg)
- Syslog messages
- Audit logs
- Early boot messages (before syslog starts)

**Key advantages over traditional syslog / Преимущества над syslog:**
- **Structured data** — each log entry has typed fields (PID, UID, unit, etc.)
- **Binary format** — indexed for fast queries, impossible to tamper with
- **Automatic rotation** — size and time based, no logrotate needed for journal
- **Boot isolation** — easily view logs from current or previous boots
- **Cross-service correlation** — filter by time, then see all services together

**Storage modes / Режимы хранения:**
- `persistent` — stored in `/var/log/journal/`, survives reboots
- `volatile` — stored in `/run/log/journal/`, lost on reboot
- `auto` — persistent if `/var/log/journal/` exists, otherwise volatile

📚 **Official Docs / Официальная документация:**
[journalctl(1)](https://man7.org/linux/man-pages/man1/journalctl.1.html) · [journald.conf(5)](https://man7.org/linux/man-pages/man5/journald.conf.5.html) · [systemd-journald(8)](https://man7.org/linux/man-pages/man8/systemd-journald.service.8.html)

## Table of Contents
- [Basic Commands](#basic-commands)
- [Filtering](#filtering)
- [Output Formats](#output-formats)
- [Disk Management](#disk-management)
- [Real-World Examples](#real-world-examples)

---

## Basic Commands

### View Logs / Просмотр логов

```bash
journalctl                                    # Show all logs / Показать все логи
journalctl -f                                 # Follow (tail) logs / Следовать за логами
journalctl -e                                 # Jump to end / Перейти в конец
journalctl -r                                 # Reverse order (newest first) / Обратный порядок
journalctl -n 50                              # Show last 50 lines / Показать последние 50 строк
```

### Kernel Messages / Сообщения ядра

```bash
journalctl -k                                 # Kernel messages / Сообщения ядра
journalctl -k -f                              # Follow kernel messages / Следовать за сообщениями ядра
journalctl -k --since today                   # Today's kernel messages / Сегодняшние сообщения ядра
```

### Boot Logs / Логи загрузки

```bash
journalctl -b                                 # Current boot / Текущая загрузка
journalctl -b -1                              # Previous boot / Предыдущая загрузка
journalctl -b -2                              # Two boots ago / Две загрузки назад
journalctl --list-boots                       # List all boots / Список всех загрузок
```

---

## Filtering

### By Unit / По юниту

```bash
journalctl -u nginx                           # Nginx service logs / Логи сервиса Nginx
journalctl -u ssh.service                     # SSH service logs / Логи сервиса SSH
journalctl -u docker.service -f               # Follow Docker logs / Следовать за логами Docker
journalctl -u nginx -u php-fpm                # Multiple units / Несколько юнитов
```

### By Time / По времени

```bash
journalctl --since "2025-08-01"               # Since date / С даты
journalctl --since "2025-08-01" --until "2025-08-27"  # Date range / Диапазон дат
journalctl --since today                      # Since today / С сегодня
journalctl --since yesterday                  # Since yesterday / Со вчера
journalctl --since "10 minutes ago"           # Last 10 minutes / Последние 10 минут
journalctl --since "2 hours ago"              # Last 2 hours / Последние 2 часа
```

### By Priority / По приоритету

```bash
journalctl -p err                             # Errors and above / Ошибки и выше
journalctl -p warning                         # Warnings and above / Предупреждения и выше
journalctl -p crit                            # Critical and above / Критические и выше
journalctl -p emerg                           # Emergency only / Только критические
journalctl -p warning..emerg                  # Range / Диапазон
```

### Priority Levels / Уровни приоритета

| Level | Name | Description (EN / RU) |
| :--- | :--- | :--- |
| 0 | `emerg` | System unusable / Система неработоспособна |
| 1 | `alert` | Action required / Требуется действие |
| 2 | `crit` | Critical conditions / Критические условия |
| 3 | `err` | Error conditions / Ошибки |
| 4 | `warning` | Warning conditions / Предупреждения |
| 5 | `notice` | Normal but significant / Нормально, но важно |
| 6 | `info` | Informational / Информационные |
| 7 | `debug` | Debug messages / Отладочные сообщения |

### By Identifier / По идентификатору

```bash
journalctl -t sshd                            # SSH daemon / SSH демон
journalctl _COMM=nginx                        # By command / По команде
journalctl _PID=<PID>                         # By PID / По PID
journalctl _UID=1000                          # By UID / По UID
journalctl _HOSTNAME=<HOST>                   # By hostname / По имени хоста
journalctl _SYSTEMD_UNIT=sshd.service         # By unit field / По полю юнита
```

### Combined Filters / Комбинированные фильтры

```bash
journalctl -u nginx --since today -p err      # Nginx errors today / Ошибки Nginx сегодня
journalctl -u ssh --since "1 hour ago" -f     # Recent SSH logs / Недавние SSH логи
journalctl _UID=1000 -p warning               # User warnings / Предупреждения пользователя
```

### Search in Logs / Поиск в логах

```bash
journalctl -u nginx | grep "error"            # Grep for pattern / Grep по шаблону
journalctl -u nginx -g "error|failed"         # Builtin grep (regex) / Встроенный grep
```

---

## Output Formats

### Standard Output / Стандартный вывод

```bash
journalctl -o short                           # Default format / Формат по умолчанию
journalctl -o short-precise                   # With microseconds / С микросекундами
journalctl -o verbose                         # Verbose format / Подробный формат
journalctl -o json                            # JSON format / JSON формат
journalctl -o json-pretty                     # Pretty JSON / Красивый JSON
journalctl -o cat                             # Only message text / Только текст сообщения
```

### Special Formats / Специальные форматы

```bash
journalctl -xe                                # With explanations + errors / С объяснениями + ошибки
journalctl -l                                 # Full output (no ellipsis) / Полный вывод
journalctl --no-pager                         # Don't use pager / Не использовать pager
```

### Export / Экспорт

```bash
journalctl -u nginx > nginx.log               # Save to file / Сохранить в файл
journalctl -u nginx -o json > nginx.json      # JSON export / JSON экспорт
journalctl --no-pager -u nginx                # No pager (for piping) / Без пейджера
```

---

## Disk Management

### Disk Usage / Использование диска

```bash
journalctl --disk-usage                       # Show disk usage / Показать использование диска
journalctl --verify                           # Verify journal files / Проверить файлы журнала
```

### Vacuum / Очистка

```bash
sudo journalctl --vacuum-time=2weeks          # Keep last 2 weeks / Оставить последние 2 недели
sudo journalctl --vacuum-size=500M            # Keep max 500MB / Оставить макс 500МБ
sudo journalctl --vacuum-files=10             # Keep max 10 files / Оставить макс 10 файлов
```

> [!CAUTION]
> Vacuuming permanently deletes old journal entries. There is no undo. / Очистка необратимо удаляет старые записи журнала.

### Rotation / Ротация

```bash
sudo systemctl kill --kill-who=main --signal=SIGUSR2 systemd-journald.service  # Force rotation / Принудительная ротация
```

### Persistent Configuration / Постоянная конфигурация

`/etc/systemd/journald.conf`

```ini
[Journal]
Storage=persistent                            # Auto/persistent/volatile/none
SystemMaxUse=500M                             # Max disk usage / Макс. использование диска
SystemKeepFree=1G                             # Keep at least 1G free / Оставлять минимум 1G свободного места
SystemMaxFileSize=50M                         # Max file size / Макс. размер файла
MaxRetentionSec=1week                         # Max retention / Макс. хранение
Compress=yes                                  # Compress journal / Сжимать журнал
ForwardToSyslog=no                            # Don't duplicate to syslog / Не дублировать в syslog
```

```bash
sudo systemctl restart systemd-journald       # Apply changes / Применить изменения
```

### Enable Persistent Storage / Включить постоянное хранение

```bash
sudo mkdir -p /var/log/journal                # Create journal directory / Создать директорию журнала
sudo systemd-tmpfiles --create --prefix /var/log/journal  # Set permissions / Установить права
sudo systemctl restart systemd-journald       # Restart journald / Перезапустить journald
```

---

## Real-World Examples

### Debug Service Issues / Отладка проблем сервисов

```bash
# Check failed service / Проверить упавший сервис
journalctl -u nginx.service --since today -p err

# Follow service startup / Следовать за запуском сервиса
journalctl -u nginx -f -n 100

# Find service crashes / Найти крашы сервиса
journalctl -u nginx.service | grep -i "core\|segfault\|crash"
```

### System Boot Issues / Проблемы загрузки системы

```bash
# Check last boot / Проверить последнюю загрузку
journalctl -b -p err

# Compare boots / Сравнить загрузки
journalctl -b 0 -p err  # Current / Текущая
journalctl -b -1 -p err  # Previous / Предыдущая

# Boot timeline / Временная шкала загрузки
systemd-analyze critical-chain
```

### Security Audit / Аудит безопасности

```bash
# SSH login attempts / Попытки SSH входа
journalctl -u ssh.service | grep "Failed password"

# Sudo usage / Использование sudo
journalctl _COMM=sudo --since today

# Authentication logs / Логи аутентификации
journalctl -t sshd -t sudo --since yesterday
```

### Application Debugging / Отладка приложений

```bash
# Docker container logs / Логи контейнеров Docker
journalctl CONTAINER_NAME=myapp -f

# Follow multiple services / Следовать за несколькими сервисами
journalctl -u nginx -u php-fpm -f

# Grep in logs / Grep в логах
journalctl -u myapp | grep "ERROR\|FATAL"
```

### Performance Issues / Проблемы производительности

```bash
# OOM (Out of Memory) issues / Проблемы с памятью
journalctl -k | grep -i "out of memory\|oom"

# Find high CPU usage / Найти высокое использование CPU
journalctl --since "1 hour ago" | grep -i "cpu\|load"
```

### Monitoring / Мониторинг

```bash
# Watch for errors / Следить за ошибками
journalctl -f -p err

# Monitor specific pattern / Мониторить конкретный паттерн
journalctl -f | grep -i "error\|fail\|critical"

# Count errors per service / Подсчитать ошибки по сервисам
journalctl -p err --since today --no-pager | awk '/\[.*\]/ {print $6}' | sort | uniq -c | sort -nr
```

---

## 💡 Best Practices / Лучшие практики

- Use `--since` and `--until` to limit output. / Используйте `--since` и `--until` для ограничения вывода.
- Use `-p` to filter by priority. / Используйте `-p` для фильтрации по приоритету.
- Vacuum logs regularly. / Регулярно очищайте логи.
- Enable **persistent logging** for post-reboot debugging. / Включите постоянное логирование для отладки после перезагрузки.
- Monitor journal disk usage. / Мониторьте использование диска журналом.
- Use `-xe` for detailed error info. / Используйте `-xe` для подробной информации об ошибках.

> [!NOTE]
> Journald is part of systemd. Logs may be volatile (lost on reboot) or persistent depending on `Storage=` setting. Use `sudo mkdir -p /var/log/journal` and restart journald to enable persistence. / Journald часть systemd. Логи могут быть временными или постоянными.

---

## Documentation Links

- **journalctl(1):** https://man7.org/linux/man-pages/man1/journalctl.1.html
- **journald.conf(5):** https://man7.org/linux/man-pages/man5/journald.conf.5.html
- **systemd-journald(8):** https://man7.org/linux/man-pages/man8/systemd-journald.service.8.html
- **ArchWiki — systemd/Journal:** https://wiki.archlinux.org/title/Systemd/Journal
- **Red Hat — Viewing Logs:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_troubleshooting-problems-using-log-files_configuring-basic-system-settings
