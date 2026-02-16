Title: 📜 journalctl — Systemd Journal
Group: System & Logs
Icon: 📜
Order: 2

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Filtering](#-filtering--фильтрация)
- [Output Formats](#-output-formats--форматы-вывода)
- [Disk Management](#-disk-management--управление-диском)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Basic Commands / Базовые команды

### View Logs / Просмотр логов
journalctl                                    # Show all logs / Показать все логи
journalctl -f                                 # Follow (tail) logs / Следовать за логами
journalctl -e                                 # Jump to end / Перейти в конец
journalctl -r                                 # Reverse order (newest first) / Обратный порядок
journalctl -n 50                              # Show last 50 lines / Показать последние 50 строк

### Kernel Messages / Сообщения ядра
journalctl -k                                 # Kernel messages / Сообщения ядра
journalctl -k -f                              # Follow kernel messages / Следовать за сообщениями ядра
journalctl -k --since today                   # Today's kernel messages / Сегодняшние сообщения ядра

### Boot Logs / Логи загрузки
journalctl -b                                 # Current boot / Текущая загрузка
journalctl -b -1                              # Previous boot / Предыдущая загрузка
journalctl -b -2                              # Two boots ago / Две загрузки назад
journalctl --list-boots                       # List all boots / Список всех загрузок

---

# 🔍 Filtering / Фильтрация

### By Unit / По юниту
journalctl -u nginx                           # Nginx service logs /Логи сервиса Nginx
journalctl -u ssh.service                     # SSH service logs / Логи сервиса SSH
journalctl -u docker.service -f               # Follow Docker logs / Следовать за логами Docker

### By Time / По времени
journalctl --since "2025-08-01"               # Since date / С даты
journalctl --since "2025-08-01" --until "2025-08-27"  # Date range / Диапазон дат
journalctl --since today                      # Since today / С сегодня
journalctl --since yesterday                  # Since yesterday / Со вчера
journalctl --since "10 minutes ago"           # Last 10 minutes / Последние 10 минут
journalctl --since "2 hours ago"              # Last 2 hours / Последние 2 часа

### By Priority / По приоритету
journalctl -p err                             # Errors and above / Ошибки и выше
journalctl -p warning                         # Warnings and above / Предупреждения и выше
journalctl -p crit                            # Critical and above / Критические и выше
journalctl -p emerg                           # Emergency only / Только критические

### Priority Levels / Уровни приоритета
# 0: emerg — Emergency / Критические
# 1: alert — Alert / Оповещение
# 2: crit — Critical / Критические
# 3: err — Error / Ошибки
# 4: warning — Warning / Предупреждения
# 5: notice — Notice / Уведомления
# 6: info — Info / Информация
# 7: debug — Debug / Отладка

### By Identifier / По идентификатору
journalctl -t sshd                            # SSH daemon / SSH демон
journalctl _COMM=nginx                        # By command / По команде
journalctl _PID=1234                          # By PID / По PID

### Combined Filters / Комбинированные фильтры
journalctl -u nginx --since today -p err      # Nginx errors today / Ошибки Nginx сегодня
journalctl -u ssh --since "1 hour ago" -f     # Recent SSH logs / Недавние SSH логи

---

# 📊 Output Formats / Форматы вывода

### Standard Output / Стандартный вывод
journalctl -o short                           # Default format / Формат по умолчанию
journalctl -o verbose                         # Verbose format / Подробный формат
journalctl -o json                            # JSON format / JSON формат
journalctl -o json-pretty                     # Pretty JSON / Красивый JSON
journalctl -o cat                             # Only message text / Только текст сообщения

### Special Formats / Специальные форматы
journalctl -xjournalctl -xe                                  # With explanations / С объяснениями
journalctl -l                                 # Full output (no ellipsis) / Полный вывод
journalctl --no-pager                         # Don't use pager / Не использовать pager

---

# 💾 Disk Management / Управление диском

### Disk Usage / Использование диска
journalctl --disk-usage                       # Show disk usage / Показать использование диска
journalctl --verify                           # Verify journal files / Проверить файлы журнала

### Vacuum / Очистка
sudo journalctl --vacuum-time=2weeks          # Keep last 2 weeks / Оставить последние 2 недели
sudo journalctl --vacuum-size=500M            # Keep max 500MB / Оставить макс 500МБ
sudo journalctl --vacuum-files=10             # Keep max 10 files / Оставить макс 10 файлов

### Rotation / Ротация
sudo systemctl kill --kill-who=main --signal=SIGUSR2 systemd-journald.service  # Force rotation / Принудительная ротация

---

# 🌟 Real-World Examples / Примеры из практики

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

### Export Logs / Экспорт логов
```bash
# Export to file / Экспортировать в файл
journalctl -u nginx --since today > nginx-logs.txt

# Export as JSON / Экспортировать как JSON
journalctl -u nginx --since today -o json > nginx.json

# Export range / Экспортировать диапазон
journalctl --since "2025-08-01" --until "2025-08-27" > logs-august.txt
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

### Cleanup Old Logs / Очистка старых логов
```bash
# Keep only 1 week / Оставить только 1 неделю
sudo journalctl --vacuum-time=1week

# Keep only 100MB / Оставить только 100МБ
sudo journalctl --vacuum-size=100M

# Persistent config / Постоянная конфигурация
# Edit /etc/systemd/journald.conf:
# SystemMaxUse=500M
# SystemKeepFree=1G
sudo systemctl restart systemd-journald
```

### Correlation with Other Logs / Корреляция с другими логами
```bash
# Combine journalctl with syslog / Комбинировать journalctl с syslog
journalctl --since "10 minutes ago" -o short-precise | grep -i error

# Time-based correlation / Корреляция по времени
date=$(date -d "10 minutes ago" "+%Y-%m-%d %H:%M:%S")
journalctl --since "$date" -u nginx
tail -f /var/log/nginx/error.log
```

# 💡 Best Practices / Лучшие практики
# Use --since and --until to limit output / Используйте --since и --until для ограничения вывода
# Use -p to filter by priority / Используйте -p для фильтрации по приоритету
# Vacuum logs regularly / Регулярно очищайте логи
# Use persistent logging / Используйте постоянное логирование
# Monitor disk usage / Мониторьте использование диска
# Use -xe for detailed error info / Используйте -xe для подробной информации об ошибках

# 🔧 Configuration Files / Файлы конфигурации
# /etc/systemd/journald.conf — Main config / Основная конфигурация
# /var/log/journal/ — Journal storage / Хранилище журнала
# /run/log/journal/ — Volatile storage / Временное хранилище

# 📋 Useful Options / Полезные опции
# -f: Follow / Следовать
# -b: Boot / Загрузка
# -u: Unit / Юнит
# -k: Kernel / Ядро
# -p: Priority / Приоритет
# -n: Lines / Строки
# -r: Reverse / Обратный порядок
# -xe: Extended + errors / Расширенный + ошибки
# -o: Output format / Формат вывода

# ⚠️ Important Notes / Важные примечания
# Journald is part of systemd / Journald часть systemd
# Logs may be volatile or persistent / Логи могут быть временными или постоянными
# Use sudo for some filters / Используйте sudo для некоторых фильтров
# Timestamps are in local time / Временные метки в местном времени
