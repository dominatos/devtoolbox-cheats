Title: 📅 date & timedatectl — Time Management
Group: System & Logs
Icon: 📅
Order: 9

## Table of Contents
- [date Command](#-date-command--команда-date)
- [timedatectl](#-timedatectl)
- [Timezones](#-timezones--часовые-пояса)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📆 date Command / Команда date

### Display Date / Показать дату
date                                          # Default format / Формат по умолчанию
date '+%Y-%m-%d'                              # ISO date (YYYY-MM-DD) / ISO дата
date '+%Y-%m-%d %H:%M:%S'                     # Date and time / Дата и время
date '+%F %T'                                 # Same as above / То же что выше
date '+%s'                                    # Unix timestamp / Unix timestamp

### UTC Time / UTC время
date -u                                       # UTC time / UTC время
date -u '+%Y-%m-%dT%H:%M:%SZ'                 # ISO-8601 UTC / ISO-8601 UTC
date --utc '+%s'                              # Unix timestamp UTC / Unix timestamp UTC

### Convert Timestamp / Конвертировать timestamp
date -d '@1693152000'                         # Unix to date / Unix в дату
date -d '@1693152000' '+%Y-%m-%d %H:%M:%S'    # Unix to formatted / Unix в форматированную
date -d '2023-08-27 10:00:00' '+%s'           # Date to Unix / Дата в Unix

### Relative Dates / Относительные даты
date -d 'yesterday'                           # Yesterday / Вчера
date -d 'tomorrow'                            # Tomorrow / Завтра
date -d 'next Monday'                         # Next Monday / Следующий понедельник
date -d '2 days ago'                          # 2 days ago / 2 дня назад
date -d '+3 hours'                            # 3 hours from now / Через 3 часа
date -d '1 week ago'                          # 1 week ago / Неделю назад

### Custom Formats / Пользовательские форматы
date '+%A, %B %d, %Y'                         # Monday, January 01, 2024
date '+%Y%m%d_%H%M%S'                         # Timestamp for filenames / Timestamp для имён файлов
date '+Week %V of %Y'                         # Week number / Номер недели
date '+%Z %z'                                 # Timezone / Часовой пояс

---

# ⏰ timedatectl

### Show Status / Показать статус
timedatectl                                   # Show time/date/timezone / Показать время/дату/часовой пояс
timedatectl status                            # Same as above / То же что выше
timedatectl show                              # Machine-readable output / Машинно-читаемый вывод

### Set Time / Установить время
sudo timedatectl set-time '2024-01-01 12:00:00'  # Set date and time / Установить дату и время
sudo timedatectl set-time '12:00:00'          # Set time only / Установить только время

### Set Timezone / Установить часовой пояс
timedatectl list-timezones                    # List available timezones / Список доступных часовых поясов
sudo timedatectl set-timezone Europe/London   # Set timezone / Установить часовой пояс
sudo timedatectl set-timezone UTC             # Set to UTC / Установить UTC

### NTP / NTP
sudo timedatectl set-ntp true                 # Enable NTP / Включить NTP
sudo timedatectl set-ntp false                # Disable NTP / Отключить NTP
timedatectl timesync-status                   # NTP sync status / Статус синхронизации NTP

---

# 🌍 Timezones / Часовые пояса

### Show Time in Different TZ / Показать время в разных часовых поясах
TZ=Europe/London date                         # London time / Лондонское время
TZ=America/New_York date                      # New York time / Нью-Йоркское время
TZ=Asia/Tokyo date                            # Tokyo time / Токийское время
TZ=UTC date                                   # UTC time / UTC время

### List Timezones / Список часовых поясов
timedatectl list-timezones                    # All timezones / Все часовые пояса
timedatectl list-timezones | grep Europe      # European timezones / Европейские часовые пояса
timedatectl list-timezones | grep America     # American timezones / Американские часовые пояса

### Timezone Files / Файлы часовых поясов
ls /usr/share/zoneinfo/                       # Timezone database / База данных часовых поясов
cat /etc/timezone                             # Current timezone / Текущий часовой пояс

---

# 🌟 Real-World Examples / Примеры из практики

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

### Schedule Tasks in Specific TZ / Планирование задач в конкретном часовом поясе
```bash
# Run command at specific time in different TZ / Запустить команду в конкретное время в другом часовом поясе
TZ=America/New_York crontab -e
# 0 9 * * * /path/to/script.sh  # 9 AM New York time
```

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

# 💡 Best Practices / Лучшие практики
# Use ISO-8601 format for portability / Используйте формат ISO-8601 для переносимости
# Store timestamps in UTC / Храните временные метки в UTC
# Use NTP for accurate time / Используйте NTP для точного времени
# Use date '+%s' for calculations / Используйте date '+%s' для вычислений
# Set correct timezone / Установите правильный часовой пояс
# Use timedatectl instead of date for system time / Используйте timedatectl вместо date для системного времени

# 🔧 Common Format Specifiers / Распространённые спецификаторы формата
# %Y: Year (4 digits) / Год (4 цифры)
# %m: Month (01-12) / Месяц (01-12)
# %d: Day (01-31) / День (01-31)
# %H: Hour (00-23) / Час (00-23)
# %M: Minute (00-59) / Минута (00-59)
# %S: Second (00-59) / Секунда (00-59)
# %s: Unix timestamp / Unix timestamp
# %Z: Timezone name / Название часового пояса
# %z: Timezone offset / Смещение часового пояса
# %F: ISO date (%Y-%m-%d) / ISO дата
# %T: Time (%H:%M:%S) / Время

# 📋 Useful One-Liners / Полезные однострочники
date '+%Y%m%d%H%M%S'                          # Timestamp filename / Timestamp имя файла
date '+%Y-W%V'                                # Year and week number / Год и номер недели
date -d "@$(($(date '+%s') - 86400))"         # Yesterday / Вчера
echo $(($(date '+%s') / 86400))               # Days since epoch / Дней с начала epoch

# ⚠️ Important Notes / Важные примечания
# Always use NTP in production / Всегда используйте NTP в продакшене
# Timezone changes need reboot or service restart / Изменения часового пояса требуют перезагрузки или рестарта сервиса
# Use UTC for logs and databases / Используйте UTC для логов и баз данных
# date -d doesn't work on macOS (use gdate) / date -d не работает на macOS (используйте gdate)
