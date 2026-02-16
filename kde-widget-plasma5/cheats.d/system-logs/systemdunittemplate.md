Title: 🧩 systemd unit — template
Group: System & Logs
Icon: 🧩
Order: 5

# systemd Unit File Cheatsheet

> **Context:** systemd unit file templates and management. / Шаблоны и управление юнит-файлами systemd.
> **Role:** Sysadmin / DevOps
> **Location:** /etc/systemd/system/ (user) or /lib/systemd/system/ (packages)

---

## 📚 Table of Contents / Содержание

1. [Service Unit Template](#service-unit-template--шаблон-сервиса)
2. [Timer Unit Template](#timer-unit-template--шаблон-таймера)
3. [Socket Unit Template](#socket-unit-template--шаблон-сокета)
4. [Common Directives](#common-directives--частые-директивы)
5. [Unit Management](#unit-management--управление-юнитами)
6. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Service Unit Template / Шаблон сервиса

### Basic Service / Базовый сервис
```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application                # Human description / Описание
After=network-online.target               # Start after network / После сети
Wants=network-online.target               # Ensure dependency starts / Зависимость

[Service]
Type=simple                               # Service type / Тип сервиса
User=<USER>                               # Run as user / Пользователь
Group=<GROUP>                             # Run as group / Группа
WorkingDirectory=/opt/myapp               # Working directory / Рабочая директория
ExecStart=/opt/myapp/bin/myapp --config /etc/myapp/config.yml
ExecReload=/bin/kill -HUP $MAINPID        # Reload command / Команда перезагрузки
Restart=on-failure                        # Restart policy / Политика рестарта
RestartSec=5s                             # Delay before restart / Задержка рестарта

[Install]
WantedBy=multi-user.target                # Enable target / Цель включения
```

### Service with Environment / Сервис с переменными окружения
```ini
[Service]
Environment=NODE_ENV=production           # Single variable / Одна переменная
Environment="DB_HOST=<HOST>" "DB_PORT=5432"  # Multiple / Несколько
EnvironmentFile=/etc/myapp/env            # From file / Из файла
```

### Service Types / Типы сервисов
```text
Type=simple     — Default, main process (ExecStart) / По умолчанию
Type=forking    — Forks, parent exits / Форкается, родитель завершается
Type=oneshot    — One-time task, then exits / Однократное выполнение
Type=notify     — Sends notification when ready / Отправляет уведомление
Type=dbus       — Acquires D-Bus name / Получает имя D-Bus
Type=idle       — Delayed until other jobs finish / Отложенный запуск
```

---

## 2. Timer Unit Template / Шаблон таймера

### Basic Timer / Базовый таймер
```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily Backup Timer            # Timer description / Описание таймера

[Timer]
OnCalendar=*-*-* 02:00:00                 # Every day at 2 AM / Каждый день в 2:00
Persistent=true                           # Run if missed / Выполнить если пропущено
Unit=backup.service                       # Service to trigger / Сервис для запуска

[Install]
WantedBy=timers.target
```

### OnCalendar Examples / Примеры расписаний
```text
*-*-* 00:00:00                — Daily at midnight / Ежедневно в полночь
Mon *-*-* 08:00:00            — Every Monday 8 AM / Каждый понедельник 8:00
*-*-01 00:00:00               — Monthly on 1st / Ежемесячно 1-го числа
*-*-* *:00:00                 — Every hour / Каждый час
*-*-* *:*:00                  — Every minute / Каждую минуту
weekly                        — Weekly / Еженедельно
hourly                        — Hourly / Ежечасно
```

### Interval Timer / Таймер по интервалу
```ini
[Timer]
OnBootSec=5min                            # After boot / После загрузки
OnUnitActiveSec=1h                        # Every hour after last run / Каждый час после запуска
OnStartupSec=10min                        # After systemd starts / После старта systemd
```

---

## 3. Socket Unit Template / Шаблон сокета

### TCP Socket / TCP сокет
```ini
# /etc/systemd/system/myapp.socket
[Unit]
Description=MyApp Socket                  # Socket description / Описание сокета

[Socket]
ListenStream=8080                         # TCP port / TCP порт
Accept=no                                 # Single process / Один процесс

[Install]
WantedBy=sockets.target
```

### Unix Socket / Unix сокет
```ini
[Socket]
ListenStream=/run/myapp/myapp.sock        # Unix socket path / Путь к сокету
SocketUser=<USER>                         # Socket owner / Владелец сокета
SocketGroup=<GROUP>                       # Socket group / Группа сокета
SocketMode=0660                           # Socket permissions / Права сокета
```

---

## 4. Common Directives / Частые директивы

### [Unit] Section / Секция [Unit]
```ini
Description=                              # Human-readable name / Читаемое имя
Documentation=https://example.com/docs    # Documentation link / Ссылка на документацию
After=                                    # Start after / Запустить после
Before=                                   # Start before / Запустить до
Requires=                                 # Hard dependency / Жёсткая зависимость
Wants=                                    # Soft dependency / Мягкая зависимость
Conflicts=                                # Cannot run with / Конфликтует с
```

### [Service] Section / Секция [Service]
```ini
ExecStartPre=                             # Before ExecStart / Перед ExecStart
ExecStartPost=                            # After ExecStart / После ExecStart
ExecStop=                                 # Stop command / Команда остановки
TimeoutStartSec=90                        # Start timeout / Таймаут запуска
TimeoutStopSec=30                         # Stop timeout / Таймаут остановки
StandardOutput=journal                    # Output to journal / Вывод в журнал
StandardError=journal                     # Errors to journal / Ошибки в журнал
SyslogIdentifier=myapp                    # Journal identifier / Идентификатор в журнале
```

### Restart Policies / Политики рестарта
```text
Restart=no            — Never restart / Никогда не рестартовать
Restart=on-success    — Only on clean exit / Только при успешном завершении
Restart=on-failure    — On non-zero exit / При ненулевом коде выхода
Restart=on-abnormal   — On signal/timeout / При сигнале/таймауте
Restart=always        — Always restart / Всегда рестартовать
```

### Security Hardening / Усиление безопасности
```ini
NoNewPrivileges=true                      # Block privilege escalation / Блок повышения привилегий
ProtectSystem=strict                      # Read-only / and /usr / Только чтение / и /usr
ProtectHome=true                          # No access to /home / Без доступа к /home
PrivateTmp=true                           # Private /tmp / Приватный /tmp
ReadOnlyPaths=/etc                        # Read-only paths / Пути только для чтения
```

---

## 5. Unit Management / Управление юнитами

### Reload and Enable / Перезагрузка и включение
```bash
sudo systemctl daemon-reload              # Reload unit files / Перезагрузить юниты
sudo systemctl enable myapp               # Enable at boot / Включить при загрузке
sudo systemctl enable --now myapp         # Enable and start / Включить и запустить
sudo systemctl disable myapp              # Disable at boot / Отключить при загрузке
```

### Control Service / Управление сервисом
```bash
sudo systemctl start myapp                # Start service / Запустить сервис
sudo systemctl stop myapp                 # Stop service / Остановить сервис
sudo systemctl restart myapp              # Restart service / Перезапустить сервис
sudo systemctl reload myapp               # Reload config / Перезагрузить конфиг
sudo systemctl status myapp               # Check status / Проверить статус
```

### Timer Management / Управление таймерами
```bash
sudo systemctl enable backup.timer        # Enable timer / Включить таймер
sudo systemctl start backup.timer         # Start timer / Запустить таймер
systemctl list-timers                     # List active timers / Список таймеров
systemctl list-timers --all               # All timers / Все таймеры
```

---

## 6. Troubleshooting / Устранение неполадок

### Check Logs / Проверка логов
```bash
journalctl -u myapp.service               # Service logs / Логи сервиса
journalctl -u myapp.service -f            # Follow logs / Следить за логами
journalctl -u myapp.service --since today # Today's logs / Логи за сегодня
systemctl status myapp                    # Quick status / Быстрый статус
```

### Validate Unit / Валидация юнита
```bash
systemd-analyze verify /etc/systemd/system/myapp.service  # Check syntax / Проверить синтаксис
systemctl cat myapp                       # Show unit content / Показать содержимое
systemctl show myapp                      # Show all properties / Показать свойства
```

### Debug / Отладка
```bash
systemctl list-dependencies myapp         # Show dependencies / Показать зависимости
systemctl list-units --failed             # Failed units / Проваленные юниты
systemctl reset-failed                    # Reset failed state / Сбросить состояние
```

---

# 💡 Best Practices / Лучшие практики
# Always use daemon-reload after changes / Всегда daemon-reload после изменений
# Use Type=notify for apps that support it / Используйте Type=notify для поддерживающих его
# Set RestartSec to avoid restart loops / Установите RestartSec для избежания циклов
# Use EnvironmentFile for secrets / Используйте EnvironmentFile для секретов

# 📋 Unit File Paths / Пути к юнит-файлам
# /etc/systemd/system/           — Admin units (override) / Админские юниты (приоритет)
# /lib/systemd/system/           — Package units / Юниты пакетов
# /run/systemd/system/           — Runtime units / Runtime юниты
