Title: 🛠 systemctl — Commands
Group: System & Logs
Icon: 🛠
Order: 1

# systemctl — systemd Service Manager

**systemctl** is the primary tool for controlling the **systemd** init system and service manager. It is used to start, stop, reload, enable, and inspect the state of services (units) and the system itself. systemd replaced SysVinit (`/etc/init.d/`) as the default init system for most major Linux distributions starting around 2015.

**systemd** is more than just an init system — it manages services, timers (cron replacement), sockets, device units, mount points, and more. It provides:
- **Parallel startup** — services start concurrently for faster boot
- **On-demand activation** — via sockets, D-Bus, device, path, or timer triggers
- **Dependency management** — declarative `After=`, `Requires=`, `Wants=` directives
- **cgroups integration** — automatic resource tracking per service
- **Unified logging** — all output goes to the systemd journal (`journalctl`)

📚 **Official Docs / Официальная документация:**
[systemctl(1)](https://man7.org/linux/man-pages/man1/systemctl.1.html) · [systemd(1)](https://man7.org/linux/man-pages/man1/systemd.1.html) · [systemd.service(5)](https://man7.org/linux/man-pages/man5/systemd.service.5.html) · [systemd.unit(5)](https://man7.org/linux/man-pages/man5/systemd.unit.5.html)

## Table of Contents
- [Core Management](#core-management)
- [Unit File Operations](#unit-file-operations)
- [Journal & Logs](#journal--logs)
- [Advanced Operations](#advanced-operations)
- [Sandboxing & Security](#sandboxing--security)
- [Analysis & Troubleshooting](#analysis--troubleshooting)
- [Unit Type Comparison](#unit-type-comparison)

---

## Core Management

### Service Control / Управление сервисами

```bash
systemctl status <SERVICE>            # Show status / Показать статус
sudo systemctl start <SERVICE>        # Start immediately / Запустить немедленно
sudo systemctl stop <SERVICE>         # Stop immediately / Остановить немедленно
sudo systemctl restart <SERVICE>      # Full restart / Полный перезапуск
sudo systemctl reload <SERVICE>       # Reload config without restart / Перезагрузить конфиг
sudo systemctl enable --now <SERVICE> # Enable on boot and start / Включить и запустить
sudo systemctl try-restart <SERVICE>  # Restart only if running / Перезапустить только если запущен
```

### Enable/Disable Autostart / Управление автозагрузкой

```bash
sudo systemctl enable <SERVICE>       # Enable at boot / Включить автозапуск
sudo systemctl disable <SERVICE>      # Disable at boot / Отключить автозапуск
systemctl is-enabled <SERVICE>        # Check if enabled / Проверить автозапуск
systemctl is-active <SERVICE>         # Check if running / Проверить запущен ли
```

> [!WARNING]
> Masking a service prevents it from being started manually or by other services. Use with caution — it can break dependencies.
> Маскирование сервиса предотвращает его запуск вручную или другими сервисами.
> ```bash
> sudo systemctl mask <SERVICE>         # Block all startup / Заблокировать запуск
> sudo systemctl unmask <SERVICE>       # Allow startup / Разрешить запуск
> ```

---

## Unit File Operations

### Inspecting Units / Инспекция юнитов

```bash
systemctl list-units --type=service --state=running # List running units / Список запущенных
systemctl list-unit-files --type=service          # List all available / Список всех доступных
systemctl cat <SERVICE>                             # Show unit file content / Показать файл юнита
systemctl show <SERVICE>                            # Show all properties / Показать все свойства
systemctl show <SERVICE> -p MainPID,ActiveState     # Show specific props / Показать конкретные свойства
```

### Editing Units / Редактирование юнитов

Typical path: `/etc/systemd/system/<SERVICE>.service.d/override.conf`

```bash
sudo systemctl edit <SERVICE>         # Create/Edit drop-in / Редактировать переопределение
sudo systemctl edit --full <SERVICE>  # Edit full unit file / Редактировать файл полностью
sudo systemctl daemon-reload          # Reload manager config / Перезагрузить конфиг менеджера
```

> [!IMPORTANT]
> Always run `systemctl daemon-reload` after modifying unit files. Without this, systemd uses the old cached version.
> Всегда выполняйте `systemctl daemon-reload` после изменения юнит-файлов.

### Dependency Analysis / Анализ зависимостей

```bash
systemctl list-dependencies <SERVICE>         # Show dependencies / Показать зависимости
systemctl list-dependencies --reverse <SERVICE> # Show dependents / Показать что зависит от юнита
```

---

## Journal & Logs

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

## Advanced Operations

### Timers, Sockets, Paths / Таймеры, Сокеты, Пути

```bash
systemctl list-timers                         # List active timers / Список активных таймеров
systemctl list-sockets                        # List active sockets / Список активных сокетов
systemctl list-paths                          # List active path units / Список активных путей
```

### User Services / Пользовательские службы

Commands for services running in the user session context.
Команды для служб, работающих в контексте пользовательской сессии.

```bash
systemctl --user status <SERVICE>     # User service status / Статус в сессии юзера
systemctl --user daemon-reload        # Reload user units / Перезагрузить конфиги юзера
systemctl --user list-units           # List user units / Список юнитов пользователя
loginctl enable-linger <USER>         # Run user services without login / Запуск без входа юзера
```

### System State / Состояние системы

```bash
systemctl default                             # Return to default target / Вернуться к цели по умолчанию
systemctl get-default                         # Show default target / Показать цель по умолчанию
sudo systemctl set-default multi-user.target  # Set default boot target / Установить цель загрузки
```

---

## Sandboxing & Security

### Security Configuration Snippets / Примеры конфигурации безопасности

`/etc/systemd/system/<SERVICE>.service`

```ini
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

### Security Audit / Аудит безопасности

```bash
systemd-analyze security <SERVICE>            # Security score / Оценка безопасности
systemd-analyze security                      # All services / Все сервисы
```

> [!TIP]
> `systemd-analyze security` rates each service from 0.0 (most secure) to 10.0 (least secure). Aim for scores below 5.0 for production services.
> `systemd-analyze security` оценивает каждый сервис от 0.0 (безопасный) до 10.0 (небезопасный).

---

## Analysis & Troubleshooting

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
systemctl reset-failed <SERVICE>              # Clear specific unit / Сбросить конкретный юнит
```

> [!CAUTION]
> Isolation commands can lock you out of the system if used incorrectly. `rescue.target` drops to single-user mode.
> Команды изоляции могут заблокировать вас, если используются неправильно.
> ```bash
> sudo systemctl isolate rescue.target       # Enter rescue mode / Перейти в режим восстановления
> sudo systemctl reboot                      # Reboot system / Перезагрузка системы
> sudo systemctl poweroff                    # Power off system / Выключение системы
> ```

---

## Unit Type Comparison

| Unit Type | Description (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| **.service** | System service / Системная служба | Daemons, apps, tasks |
| **.timer** | Time-based trigger / Таймер (аналог cron) | Scheduled backups, maintenance |
| **.socket** | Network/IPC trigger / Активация по сокету | On-demand service startup (SSH, HTTP) |
| **.path** | Filesystem trigger / Триггер по ФС | Monitoring config changes |
| **.mount** | Filesystem mount / Монтирование ФС | Static mounts (alternative to fstab) |
| **.target** | Grouping unit / Группирующий юнит | Boot targets, dependency grouping |
| **.device** | Device node / Узел устройства | Hardware detection triggers |
| **.slice** | cgroup slice / Срез cgroup | Resource management grouping |

---

## Default Paths / Пути по умолчанию

| Path | Purpose (EN) | Назначение (RU) |
| :--- | :--- | :--- |
| `/etc/systemd/system/` | Admin unit files (highest priority) | Юнит-файлы админа (приоритет) |
| `/lib/systemd/system/` | Package-provided unit files | Юнит-файлы пакетов |
| `/run/systemd/system/` | Runtime unit files | Runtime юнит-файлы |
| `/etc/systemd/system/<SERVICE>.service.d/` | Drop-in overrides | Переопределения |
| `/etc/systemd/journald.conf` | Journald configuration | Конфигурация journald |

---

## Documentation Links

- **systemctl(1):** https://man7.org/linux/man-pages/man1/systemctl.1.html
- **systemd(1):** https://man7.org/linux/man-pages/man1/systemd.1.html
- **systemd.service(5):** https://man7.org/linux/man-pages/man5/systemd.service.5.html
- **systemd.unit(5):** https://man7.org/linux/man-pages/man5/systemd.unit.5.html
- **ArchWiki — systemd:** https://wiki.archlinux.org/title/Systemd
- **Red Hat — systemd Guide:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/managing-system-services-with-systemctl_configuring-basic-system-settings
- **Freedesktop — systemd:** https://www.freedesktop.org/wiki/Software/systemd/
