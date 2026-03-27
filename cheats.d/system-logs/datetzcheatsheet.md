Title: 📅 date & timedatectl — Time Management
Group: System & Logs
Icon: 📅
Order: 9

# date & timedatectl — Time Management

**date** and **timedatectl** are core Linux utilities for displaying, setting, and managing system time, dates, timezones, and NTP synchronization.

**date** (GNU coreutils) formats and sets the system clock from the command line. It supports relative date arithmetic (`date -d "2 days ago"`), Unix timestamp conversion, and custom output formats — essential for scripting, log filenames, and backup rotation.

**timedatectl** (part of systemd) is the modern tool for managing system time settings: timezone, NTP sync, and RTC (hardware clock). It replaces `tzconfig` and manual `/etc/localtime` symlink management.

**Key differences / Ключевые различия:**
- `date` — read/format time, date arithmetic, scripting timestamps
- `timedatectl` — system-level time management (timezone, NTP, RTC)
- `chronyc` / `ntpq` — NTP daemon status and synchronization details

> [!NOTE]
> `date -d` is a GNU coreutils extension and **does not work on macOS/BSD**. Use `gdate` (from `coreutils` Homebrew package) on macOS. / `date -d` не работает на macOS/BSD — используйте `gdate`.

---

## 📚 Table of Contents / Содержание

1. [date Command](#date-command)
2. [timedatectl](#timedatectl)
3. [Timezones](#timezones)
4. [Format Specifiers](#format-specifiers)
5. [Real-World Examples](#real-world-examples)
6. [Troubleshooting](#troubleshooting)

---

## date Command

### Display Date / Показать дату

```bash
date                                          # Default format / Формат по умолчанию
date '+%Y-%m-%d'                              # ISO date (YYYY-MM-DD) / ISO дата
date '+%Y-%m-%d %H:%M:%S'                     # Date and time / Дата и время
date '+%F %T'                                 # Same as above / То же что выше
date '+%s'                                    # Unix timestamp / Unix timestamp
```

### UTC Time / UTC время

```bash
date -u                                       # UTC time / UTC время
date -u '+%Y-%m-%dT%H:%M:%SZ'                 # ISO-8601 UTC / ISO-8601 UTC
date --utc '+%s'                              # Unix timestamp UTC / Unix timestamp UTC
```

### Convert Timestamp / Конвертировать timestamp

```bash
date -d '@1693152000'                         # Unix to date / Unix в дату
date -d '@1693152000' '+%Y-%m-%d %H:%M:%S'    # Unix to formatted / Unix в форматированную
date -d '2023-08-27 10:00:00' '+%s'           # Date to Unix / Дата в Unix
```

### Relative Dates / Относительные даты

```bash
date -d 'yesterday'                           # Yesterday / Вчера
date -d 'tomorrow'                            # Tomorrow / Завтра
date -d 'next Monday'                         # Next Monday / Следующий понедельник
date -d '2 days ago'                          # 2 days ago / 2 дня назад
date -d '+3 hours'                            # 3 hours from now / Через 3 часа
date -d '1 week ago'                          # 1 week ago / Неделю назад
```

### Custom Formats / Пользовательские форматы

```bash
date '+%A, %B %d, %Y'                         # Monday, January 01, 2024
date '+%Y%m%d_%H%M%S'                         # Timestamp for filenames / Timestamp для имён файлов
date '+Week %V of %Y'                         # Week number / Номер недели
date '+%Z %z'                                 # Timezone / Часовой пояс
```

---

## timedatectl

### Show Status / Показать статус

```bash
timedatectl                                   # Show time/date/timezone / Показать время/дату/часовой пояс
timedatectl status                            # Same as above / То же что выше
timedatectl show                              # Machine-readable output / Машинно-читаемый вывод
```

### Set Time / Установить время

```bash
sudo timedatectl set-time '2024-01-01 12:00:00'  # Set date and time / Установить дату и время
sudo timedatectl set-time '12:00:00'          # Set time only / Установить только время
```

> [!WARNING]
> Setting time manually will be overridden if NTP is enabled. Disable NTP first with `sudo timedatectl set-ntp false`.
> Установка времени вручную будет перезаписана если NTP включен. Сначала отключите NTP.

### Set Timezone / Установить часовой пояс

```bash
timedatectl list-timezones                    # List available timezones / Список доступных часовых поясов
sudo timedatectl set-timezone Europe/London   # Set timezone / Установить часовой пояс
sudo timedatectl set-timezone UTC             # Set to UTC / Установить UTC
```

### NTP / NTP

```bash
sudo timedatectl set-ntp true                 # Enable NTP / Включить NTP
sudo timedatectl set-ntp false                # Disable NTP / Отключить NTP
timedatectl timesync-status                   # NTP sync status / Статус синхронизации NTP
```

---

## Timezones

### Show Time in Different TZ / Показать время в разных часовых поясах

```bash
TZ=Europe/London date                         # London time / Лондонское время
TZ=America/New_York date                      # New York time / Нью-Йоркское время
TZ=Asia/Tokyo date                            # Tokyo time / Токийское время
TZ=UTC date                                   # UTC time / UTC время
```

### List Timezones / Список часовых поясов

```bash
timedatectl list-timezones                    # All timezones / Все часовые пояса
timedatectl list-timezones | grep Europe      # European timezones / Европейские часовые пояса
timedatectl list-timezones | grep America     # American timezones / Американские часовые пояса
```

### Timezone Files / Файлы часовых поясов

```bash
ls /usr/share/zoneinfo/                       # Timezone database / База данных часовых поясов
cat /etc/timezone                             # Current timezone (Debian) / Текущий часовой пояс (Debian)
readlink /etc/localtime                       # Current timezone (all distros) / Текущий часовой пояс
```

---

## Format Specifiers

### Common Format Specifiers / Распространённые спецификаторы формата

| Specifier | Description (EN / RU) | Example |
| :--- | :--- | :--- |
| `%Y` | Year (4 digits) / Год (4 цифры) | `2024` |
| `%m` | Month (01–12) / Месяц (01–12) | `03` |
| `%d` | Day (01–31) / День (01–31) | `15` |
| `%H` | Hour (00–23) / Час (00–23) | `14` |
| `%M` | Minute (00–59) / Минута (00–59) | `30` |
| `%S` | Second (00–59) / Секунда (00–59) | `45` |
| `%s` | Unix timestamp / Unix timestamp | `1710510645` |
| `%Z` | Timezone name / Имя часового пояса | `CET` |
| `%z` | Timezone offset / Смещение | `+0100` |
| `%F` | ISO date (`%Y-%m-%d`) / ISO дата | `2024-03-15` |
| `%T` | Time (`%H:%M:%S`) / Время | `14:30:45` |
| `%A` | Full weekday / День недели | `Monday` |
| `%B` | Full month name / Название месяца | `March` |
| `%V` | Week number / Номер недели | `11` |
| `%u` | Day of week (1=Mon, 7=Sun) / День недели | `1` |
| `%j` | Day of year (001–366) / День года | `075` |

---

## Real-World Examples

### Backup Filenames / Имена файлов резервных копий

```bash
# Create backup with timestamp / Создать резервную копию с timestamp
BACKUP_DATE=$(date '+%Y%m%d_%H%M%S')
tar -czf backup_${BACKUP_DATE}.tar.gz /data

# Create daily backup / Создать ежедневную резервную копию
BACKUP_DATE=$(date '+%Y-%m-%d')
tar -czf backup_${BACKUP_DATE}.tar.gz /data
```

### Log Timestamps / Временные метки логов

```bash
# Log with timestamp / Лог с временной меткой
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log message" >> /var/log/app.log

# ISO-8601 format / Формат ISO-8601
echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] UTC log" >> /var/log/app.log
```

### Calculate Time Differences / Вычислить разницу во времени

```bash
# Start time / Время начала
START=$(date '+%s')

# ... do work ...

# End time / Время окончания
END=$(date '+%s')
DIFF=$((END - START))
echo "Execution time: $DIFF seconds"
```

### Convert Between Formats / Конвертировать между форматами

```bash
# ISO to Unix / ISO в Unix
ISO_DATE="2023-08-27 10:00:00"
UNIX_TS=$(date -d "$ISO_DATE" '+%s')
echo "Unix timestamp: $UNIX_TS"

# Unix to ISO / Unix в ISO
UNIX_TS=1693152000
ISO_DATE=$(date -d "@$UNIX_TS" '+%Y-%m-%d %H:%M:%S')
echo "ISO date: $ISO_DATE"
```

### Multi-Timezone Monitoring / Мониторинг в нескольких часовых поясах

```bash
#!/bin/bash
echo "=== Server Times ==="
echo "UTC:        $(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')"
echo "New York:   $(TZ=America/New_York date '+%Y-%m-%d %H:%M:%S %Z')"
echo "London:     $(TZ=Europe/London date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Tokyo:      $(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S %Z')"
```

### Date Arithmetic / Арифметика дат

```bash
# First day of month / Первый день месяца
date -d "$(date '+%Y-%m-01')"

# Last day of month / Последний день месяца
date -d "$(date '+%Y-%m-01') +1 month -1 day"

# 30 days ago / 30 дней назад
date -d '30 days ago' '+%Y-%m-%d'

# Next Sunday / Следующее воскресенье
date -d 'next Sunday'
```

### Cron Job Logging / Логирование cron задач

```bash
# Log execution time / Логировать время выполнения
0 2 * * * echo "Backup started at $(date '+\%Y-\%m-\%d \%H:\%M:\%S')" >> /var/log/backup.log && /usr/local/bin/backup.sh
```

---

## Troubleshooting

### Check NTP Synchronization / Проверить синхронизацию NTP

```bash
# Check NTP status / Проверить статус NTP
timedatectl timesync-status

# Check chronyd / Проверить chronyd
chronyc tracking

# Check systemd-timesyncd / Проверить systemd-timesyncd
systemctl status systemd-timesyncd
```

### Fix Time Drift / Исправить дрейф времени

```bash
# Disable NTP / Отключить NTP
sudo timedatectl set-ntp false

# Set correct time / Установить правильное время
sudo timedatectl set-time '2024-01-01 12:00:00'

# Re-enable NTP / Включить NTP снова
sudo timedatectl set-ntp true
```

### Useful One-Liners / Полезные однострочники

```bash
date '+%Y%m%d%H%M%S'                          # Timestamp filename / Timestamp имя файла
date '+%Y-W%V'                                # Year and week number / Год и номер недели
date -d "@$(($(date '+%s') - 86400))"         # Yesterday / Вчера
echo $(($(date '+%s') / 86400))               # Days since epoch / Дней с начала epoch
```

---

## 💡 Best Practices / Лучшие практики

- Use **ISO-8601 format** for portability. / Используйте формат ISO-8601 для переносимости.
- Store timestamps in **UTC**. / Храните временные метки в UTC.
- Use **NTP** for accurate time in production. / Используйте NTP для точного времени в продакшене.
- Use `date '+%s'` for calculations. / Используйте `date '+%s'` для вычислений.
- Use `timedatectl` instead of `date` for system time management. / Используйте `timedatectl` для системного времени.

> [!NOTE]
> Timezone changes may require service restart to take effect. Always verify with `timedatectl` after changes. / Изменения часового пояса могут потребовать рестарта сервисов.

---

## Documentation Links

- **date(1):** https://man7.org/linux/man-pages/man1/date.1.html
- **timedatectl(1):** https://man7.org/linux/man-pages/man1/timedatectl.1.html
- **chronyc(1):** https://man7.org/linux/man-pages/man1/chronyc.1.html
- **ArchWiki — System time:** https://wiki.archlinux.org/title/System_time
- **ArchWiki — chrony:** https://wiki.archlinux.org/title/Chrony
- **Red Hat — Configuring Time:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_configuring-time-and-date_configuring-basic-system-settings
