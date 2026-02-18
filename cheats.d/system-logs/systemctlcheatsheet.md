Title: 🛠 systemctl — Commands
Group: System & Logs
Icon: 🛠
Order: 1

# Systemd & systemctl / Управление системой и службами

`systemctl` is the primary tool for controlling the `systemd` init system and service manager. It is used to start, stop, reload, and inspect the state of services (units) and the system itself.

## Table of Contents
- [Core Management](#core-management)
- [Unit File Operations](#unit-file-operations)
- [Journal & Logs](#journal--logs)
- [Advanced Operations](#advanced-operations)
- [Sandboxing & Security](#sandboxing--security)
- [Analysis & Troubleshooting](#analysis--troubleshooting)

---

## Core Management / Основное управление

### Service Control / Управление сервисами
Basic operations for managing service state.

```bash
systemctl status <SERVICE>            # Show status / Показать статус
sudo systemctl start <SERVICE>        # Start immediately / Запустить немедленно
sudo systemctl stop <SERVICE>         # Stop immediately / Остановить немедленно
sudo systemctl restart <SERVICE>      # Full restart / Полный перезапуск
sudo systemctl reload <SERVICE>       # Reload config without restart / Перезагрузить конфиг
sudo systemctl enable --now <SERVICE> # Enable on boot and start / Включить и запустить
```

### Enable/Disable Autostart / Управление автозагрузкой
```bash
sudo systemctl enable <SERVICE>       # Enable at boot / Включить автозапуск
sudo systemctl disable <SERVICE>      # Disable at boot / Отключить автозапуск
systemctl is-enabled <SERVICE>        # Check if enabled / Проверить автозапуск
```

> [!WARNING]
> Masking a service prevents it from being started manually or by other services.
> ```bash
> sudo systemctl mask <SERVICE>         # Block all startup / Заблокировать запуск
> sudo systemctl unmask <SERVICE>       # Allow startup / Разрешить запуск
> ```

---

## Unit File Operations / Операции с файлами юнитов

### Inspecting Units / Инспекция юнитов
```bash
systemctl list-units --type=service --state=running # List running units / Список запущенных
systemctl list-unit-files --type=service          # List all available / Список всех доступных
systemctl cat <SERVICE>                             # Show unit file content / Показать файл юнита
systemctl show <SERVICE>                            # Show all properties / Показать все свойства
```

### Editing Units / Редактирование юнитов
Typical path: `/etc/systemd/system/<SERVICE>.service.d/override.conf`

```bash
sudo systemctl edit <SERVICE>         # Create/Edit drop-in / Редактировать переопределение
sudo systemctl edit --full <SERVICE>  # Edit full unit file / Редактировать файл полностью
sudo systemctl daemon-reload          # Reload manager config / Перезагрузить конфиг менеджера
```

### Dependency Analysis / Анализ зависимостей
```bash
systemctl list-dependencies <SERVICE>         # Show dependencies / Показать зависимости
systemctl list-dependencies --reverse <SERVICE> # Show dependents / Показать что зависит от юнита
```

---

## Journal & Logs / Журналы и логи

### Filtering logs with journalctl / Фильтрация логов
```bash
journalctl -u <SERVICE> -f                    # Follow logs / Следить за логами
journalctl -u <SERVICE> --since today         # Logs since today / Логи за сегодня
journalctl -u <SERVICE> --since "1 hour ago"  # Last hour logs / Логи за последний час
journalctl -p err..alert                      # Error level and above / Ошибки и выше
journalctl -b                                 # Current boot logs / Логи текущей загрузки
journalctl -b -1                              # Previous boot logs / Логи прошлой загрузки
```

---

## Advanced Operations / Продвинутые операции

### Timers, Sockets, Paths / Таймеры, Сокеты, Пути
```bash
systemctl list-timers                         # List active timers / Список активных таймеров
systemctl list-sockets                        # List active sockets / Список активных сокетов
systemctl list-paths                          # List active path units / Список активных путей
```

### User Services / Пользовательские службы
Commands for services running in the user session context.

```bash
systemctl --user status <SERVICE>     # User service status / Статус в сессии юзера
systemctl --user daemon-reload        # Reload user units / Перезагрузить конфиги юзера
loginctl enable-linger <USER>         # Run user services without login / Запуск без входа юзера
```

---

## Sandboxing & Security / Изоляция и безопасность

### Security Configuration Snippets / Примеры конфигурации безопасности
`/etc/systemd/system/<SERVICE>.service`

```systemd
[Service]
# Basic Sandboxing / Базовая изоляция
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=yes

# Capability Controls / Контроль привилегий
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Resource Limits / Лимиты ресурсов
MemoryMax=50M
CPUQuota=50%
TasksMax=500
```

---

## Analysis & Troubleshooting / Анализ и отладка

### Performance Analysis / Анализ производительности
```bash
systemd-analyze                               # Total boot time / Общее время загрузки
systemd-analyze blame                         # Slowest services / Самые медленные сервисы
systemd-analyze critical-chain                # Critical chain tree / Дерево цепочки запуска
systemd-analyze plot > boot.svg               # Export SVG graph / Выгрузить график в SVG
```

### Troubleshooting states / Отладка состояний
```bash
systemctl --failed                            # List failed units / Показать упавшие юниты
systemctl reset-failed                        # Clear failed status / Сбросить статус failed
```

> [!CAUTION]
> Isolation commands can lock you out of the system if used incorrectly.
> ```bash
> sudo systemctl isolate rescue.target       # Enter rescue mode / Перейти в режим восстановления
> sudo systemctl reboot                      # Reboot system / Перезагрузка системы
> ```

---

## Unit Type Comparison / Сравнение типов юнитов

| Unit Type | Description (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| **.service** | System service / Системная служба | Daemons, apps, tasks. |
| **.timer** | Time-based trigger / Таймер (аналог cron) | Scheduled backups, maintenance. |
| **.socket** | Network/IPC trigger / Активация по сокету | On-demand service startup (SSH, HTTP). |
| **.path** | Filesystem trigger / Триггер по ФС | Monitoring config changes. |
| **.mount** | Filesystem mount / Монтирование ФС | Static mounts (alternative to fstab). |
