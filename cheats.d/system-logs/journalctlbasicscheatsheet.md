Title: 📜 journalctl — Basics
Group: System & Logs
Icon: 📜
Order: 3

# journalctl Sysadmin Cheatsheet

> **Context:** systemd journal log viewer and manager. / Просмотрщик и менеджер журналов systemd.
> **Role:** Sysadmin / DevOps
> **Tool:** journalctl

---

## 📚 Table of Contents / Содержание

1. [Basic Viewing](#basic-viewing--базовый-просмотр)
2. [Time Filters](#time-filters--фильтры-времени)
3. [Unit Filters](#unit-filters--фильтры-юнитов)
4. [Priority & Field Filters](#priority--field-filters--фильтры-приоритета-и-полей)
5. [Output Formats](#output-formats--форматы-вывода)
6. [Maintenance](#maintenance--обслуживание)
7. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Basic Viewing / Базовый просмотр

### Quick Access / Быстрый доступ
```bash
journalctl                                # All logs / Все логи
journalctl -xe                            # Recent errors (extended) / Недавние ошибки (расширенно)
journalctl -f                             # Follow (tail -f) / Следить в реальном времени
journalctl -n 100                         # Last 100 lines / Последние 100 строк
```

### Reverse Order / Обратный порядок
```bash
journalctl -r                             # Newest first / Новые сначала
journalctl -r -n 50                       # Last 50, newest first / Последние 50, новые сначала
```

### Boot Logs / Логи загрузки
```bash
journalctl -b                             # Current boot / Текущая загрузка
journalctl -b -1                          # Previous boot / Предыдущая загрузка
journalctl -b -2                          # Boot before last / Позапрошлая загрузка
journalctl --list-boots                   # List all boots / Список всех загрузок
```

---

## 2. Time Filters / Фильтры времени

### Since / Until / С / До
```bash
journalctl --since "1 hour ago"           # Last hour / Последний час
journalctl --since "2 hours ago" --until "1 hour ago"  # Range / Диапазон
journalctl --since today                  # Since midnight / С полуночи
journalctl --since yesterday              # Since yesterday / С вчера
```

### Specific Date/Time / Конкретная дата/время
```bash
journalctl --since "2025-02-01"           # Since date / С даты
journalctl --since "2025-02-01 09:00:00"  # With time / С временем
journalctl --since "2025-02-01" --until "2025-02-05"  # Date range / Диапазон дат
```

### Relative Time / Относительное время
```bash
journalctl --since "30 min ago"           # Last 30 minutes / Последние 30 минут
journalctl --since "1 week ago"           # Last week / Последняя неделя
journalctl --since "-1 day"               # Alternative syntax / Альтернативный синтаксис
```

---

## 3. Unit Filters / Фильтры юнитов

### By Service / По сервису
```bash
journalctl -u nginx                       # Nginx logs / Логи nginx
journalctl -u nginx.service               # Same, explicit / То же, явно
journalctl -u nginx -u php-fpm            # Multiple units / Несколько юнитов
journalctl -u nginx -f                    # Follow nginx logs / Следить за nginx
```

### By Unit Pattern / По шаблону юнита
```bash
journalctl -u 'docker*'                   # All docker units / Все docker юниты
journalctl -u 'mysql*'                    # All mysql units / Все mysql юниты
```

### Combine with Time / Комбинировать со временем
```bash
journalctl -u nginx --since "1 hour ago"  # Nginx last hour / Nginx за последний час
journalctl -u nginx -f --since "1 hour ago"  # Follow from 1 hour / Следить с часа назад
```

---

## 4. Priority & Field Filters / Фильтры приоритета и полей

### By Priority / По приоритету
```bash
journalctl -p err                         # Errors and above / Ошибки и выше
journalctl -p warning                     # Warnings and above / Предупреждения и выше
journalctl -p warning..emerg              # Range warning to emergency / От warning до emergency
journalctl -p 0..3                        # By number (0=emerg, 7=debug) / По номеру
```

### Priority Levels / Уровни приоритета
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

### By Field / По полю
```bash
journalctl _PID=<PID>                     # By PID / По PID
journalctl _UID=1000                      # By UID / По UID
journalctl _SYSTEMD_UNIT=sshd.service     # By unit field / По полю юнита
journalctl _HOSTNAME=<HOST>               # By hostname / По имени хоста
journalctl _COMM=nginx                    # By command name / По имени команды
```

### Combine Filters / Комбинирование фильтров
```bash
journalctl -u nginx -p err --since today  # Nginx errors today / Ошибки nginx за сегодня
journalctl _UID=1000 -p warning           # User warnings / Предупреждения пользователя
```

---

## 5. Output Formats / Форматы вывода

### Standard Formats / Стандартные форматы
```bash
journalctl -o short                       # Default format / Формат по умолчанию
journalctl -o short-precise               # With microseconds / С микросекундами
journalctl -o verbose                     # All fields / Все поля
journalctl -o json                        # JSON format / Формат JSON
journalctl -o json-pretty                 # Pretty JSON / Читаемый JSON
journalctl -o cat                         # Message only / Только сообщение
```

### Export / Экспорт
```bash
journalctl -u nginx > nginx.log           # Save to file / Сохранить в файл
journalctl -u nginx -o json > nginx.json  # JSON export / JSON экспорт
journalctl --no-pager -u nginx            # No pager (for piping) / Без пейджера
```

### Search in Logs / Поиск в логах
```bash
journalctl -u nginx | grep "error"        # Grep for pattern / Grep по шаблону
journalctl -u nginx -g "error|failed"     # Builtin grep (regex) / Встроенный grep
```

---

## 6. Maintenance / Обслуживание

### Disk Usage / Использование диска
```bash
journalctl --disk-usage                   # Show journal size / Показать размер журнала
```

### Cleanup / Очистка
```bash
sudo journalctl --vacuum-size=500M        # Keep only 500MB / Оставить только 500MB
sudo journalctl --vacuum-time=7d          # Keep only 7 days / Оставить только 7 дней
sudo journalctl --vacuum-files=5          # Keep only 5 files / Оставить только 5 файлов
```

### Persistent Storage / Постоянное хранение
```bash
# Enable persistent journal / Включить постоянный журнал
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald

# Configuration file / Файл конфигурации
# /etc/systemd/journald.conf
```

### Configuration / Конфигурация
```ini
# /etc/systemd/journald.conf
[Journal]
Storage=persistent                        # Auto/persistent/volatile/none
SystemMaxUse=500M                         # Max disk usage / Макс. использование диска
SystemMaxFileSize=50M                     # Max file size / Макс. размер файла
MaxRetentionSec=1week                     # Max retention / Макс. хранение
```

---

## 7. Troubleshooting / Устранение неполадок

### Debug Service Failures / Отладка сбоёв сервисов
```bash
# Check failed units / Проверить проваленные юниты
systemctl list-units --failed

# Get logs for failed service / Получить логи проваленного сервиса
journalctl -u failed-service.service -xe

# Get logs around failure time / Логи около времени сбоя
journalctl -u myapp --since "10 min ago" -n 100
```

### Kernel Messages / Сообщения ядра
```bash
journalctl -k                             # Kernel messages / Сообщения ядра
journalctl -k -b                          # Kernel since boot / Ядро с загрузки
journalctl -k -p err                      # Kernel errors / Ошибки ядра
```

### Find Specific Events / Поиск конкретных событий
```bash
# SSH login attempts / Попытки входа по SSH
journalctl -u sshd --since today | grep "Accepted"

# Failed logins / Неудачные входы
journalctl -u sshd --since today | grep "Failed"

# Out of memory / Нехватка памяти
journalctl -k | grep -i "oom\|out of memory"
```

---

# 💡 Best Practices / Лучшие практики
# Use -u for service logs, not grep in /var/log / Используйте -u для логов сервисов
# Enable persistent journal for post-reboot debugging / Включите постоянный журнал для отладки после перезагрузки
# Set up log rotation via journald.conf / Настройте ротацию через journald.conf
# Use --since and --until to narrow down issues / Используйте --since и --until для сужения поиска

# 📋 Quick Reference / Быстрый справочник
# journalctl -u nginx -f        — Follow nginx / Следить за nginx
# journalctl -p err --since today — Today's errors / Ошибки за сегодня
# journalctl -b -1              — Previous boot / Предыдущая загрузка
# journalctl --vacuum-size=500M — Cleanup / Очистка
