---
Title: ⚙️ sysctl — Kernel Parameters
Group: "System & Logs"
Icon: ⚙️
Order: 12
tags:
  - system
  - logs
  - sysadmin
  - linux
---

# sysctl — Linux Kernel Parameter Management

**sysctl** is the primary tool for reading and modifying kernel parameters at runtime and persistently. It provides a clean interface to the `/proc/sys/` virtual filesystem, allowing administrators to tune networking, memory, filesystem, and security behavior without rebooting or recompiling the kernel.

**Common use cases / Типичные сценарии:**
- Tune TCP/IP stack for high-concurrency web servers and databases
- Harden kernel security (ASLR, ptrace restrictions, network filtering)
- Adjust memory management for VMs, containers, and swap-heavy hosts
- Increase file descriptor and inotify limits for large deployments
- Apply one-time or persistent performance profiles per workload

**Current status / Актуальность:**
- **sysctl** is available on virtually all Linux distributions by default
- Persistent configuration lives in `/etc/sysctl.conf` and `/etc/sysctl.d/*.conf`
- systemd manages early boot sysctl via `systemd-sysctl.service`
- The legacy `/etc/sysctl.conf` format is still supported; drop-in files under `/etc/sysctl.d/` are preferred for modularity

📚 **Official Docs / Официальная документация:**
[sysctl(8)](https://man7.org/linux/man-pages/man8/sysctl.8.html) · [sysctl.conf(5)](https://man7.org/linux/man-pages/man5/sysctl.conf.5.html) · [proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) · [Kernel sysctl docs](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/)

## Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Networking Parameters](#Networking%20Parameters)
- [Memory & VM Parameters](#Memory%20&%20VM%20Parameters)
- [Filesystem Parameters](#Filesystem%20Parameters)
- [Kernel & Security Parameters](#Kernel%20&%20Security%20Parameters)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Performance Tuning Profiles](#Performance%20Tuning%20Profiles)
- [Security Hardening](#Security%20Hardening)
- [Backup & Restore](#Backup%20&%20Restore)
- [Troubleshooting & Tools](#Troubleshooting%20&%20Tools)
- [Production Runbooks](#Production%20Runbooks)
- [Parameter Reference Tables](#Parameter%20Reference%20Tables)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

### Verify Availability

```bash
which sysctl                               # Confirm sysctl is installed / Убедиться что sysctl установлен
sysctl -V                                  # Show sysctl version / Показать версию sysctl
ls /proc/sys/                              # Verify /proc/sys exists and is populated / Проверить наличие /proc/sys
```

> [!NOTE]
> sysctl is part of the `procps-ng` package on most distributions. It is almost always present on systemd-based systems.

### Config File Locations

| Path | Purpose (EN) | Назначение (RU) |
| :--- | :--- | :--- |
| `/etc/sysctl.conf` | Legacy main config (still read) | Основной конфиг (устаревший, но читается) |
| `/etc/sysctl.d/*.conf` | Drop-in overrides (preferred) | Переопределения (рекомендуется) |
| `/run/sysctl.d/*.conf` | Runtime drop-ins (ephemeral) | Runtime переопределения (временные) |
| `/usr/lib/sysctl.d/*.conf` | Package-provided defaults | Конфиги по умолчанию из пакетов |
| `/proc/sys/` | Live kernel parameters | Живые параметры ядра |

### How Loading Works

1. On boot, `systemd-sysctl.service` reads files from the directories above in priority order: `/usr/lib` -> `/etc` -> `/run`
2. Files in `/etc/sysctl.d/` override `/usr/lib/sysctl.d/`
3. `/etc/sysctl.conf` is read last and can override everything
4. Later-loaded values win for duplicate keys

```bash
systemctl status systemd-sysctl             # Check if sysctl service ran on boot / Проверить запуск sysctl-сервиса при загрузке
cat /proc/sys/net/ipv4/ip_forward           # Read live value directly / Прочитать текущее значение напрямую
```

### Create Custom Drop-In

`/etc/sysctl.d/99-custom.conf`

```bash
# Custom tuning / Пользовательские настройки
net.ipv4.ip_forward = 1
vm.swappiness = 10
fs.file-max = 2097152
```

```bash
sudo sysctl --system                        # Reload all drop-in files / Перечитать все drop-in файлы
sudo systemctl restart systemd-sysctl       # Or reload via systemd / Или перезагрузить через systemd
```

> [!TIP]
> Use numeric prefixes like `10-`, `50-`, `99-` to control load order within `/etc/sysctl.d/`. Lower numbers load first; higher numbers override.

---

## Core Management

### Read Parameters

```bash
sysctl net.ipv4.ip_forward                  # Read a single parameter / Прочитать один параметр
sysctl -a                                   # List all parameters / Список всех параметров
sysctl -a | grep ^net\.                     # List all networking params / Список всех сетевых параметров
cat /proc/sys/net/ipv4/ip_forward           # Read via /proc/sys directly / Прочитать напрямую через /proc/sys
```

### Write Parameters (Runtime Only)

```bash
sudo sysctl -w net.ipv4.ip_forward=1        # Enable IP forwarding temporarily / Включить IP-форвардинг временно
sudo sysctl -w vm.swappiness=10             # Set swappiness until reboot / Установить swappiness до перезагрузки
```

### Apply Config Files

```bash
sudo sysctl --system                        # Reload all config files in priority order / Перечитать все конфиги по приоритету
sudo sysctl -p                              # Reload /etc/sysctl.conf only / Перезагрузить только /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.d/99-custom.conf # Reload a specific file / Перезагрузить конкретный файл
sudo systemctl restart systemd-sysctl       # Reload via systemd unit / Перезагрузить через systemd юнит
```

### Using /proc/sys/ Directly

```bash
cat /proc/sys/net/ipv4/ip_forward           # Read value / Прочитать значение
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward  # Write value (equivalent to sysctl -w) / Записать значение
```

> [!WARNING]
> Writing directly to `/proc/sys/` is temporary and not persistent. Always create a corresponding `/etc/sysctl.d/` entry for durable changes.

### CRUD Reference

| Operation | Command / Что делать | Notes / Примечание |
| :--- | :--- | :--- |
| **C**reate/Write | `sysctl -w <key>=<value>` or `echo <val> > /proc/sys/<path>` | Runtime only |
| **R**ead | `sysctl <key>`, `sysctl -a`, `cat /proc/sys/<path>` | Multiple ways |
| **U**pdate persistent | Create/edit `/etc/sysctl.d/<file>.conf` then `sysctl --system` | Survives reboot |
| **D**elete/Reset | Remove line from conf file, apply, reboot | Requires file edit |

---

## Networking Parameters

### TCP/IP Stack Tuning

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `net.ipv4.ip_forward` | `0` | `1` (routers/containers) | Enable IP forwarding / Включить IP-форвардинг |
| `net.core.somaxconn` | `128` | `4096`-`65535` | Max socket listen backlog / Макс. очередь сокетов |
| `net.ipv4.tcp_max_syn_backlog` | `1024` | `4096`-`8192` | SYN queue size per interface / Размер SYN-очереди |
| `net.ipv4.tcp_fin_timeout` | `60` | `15`-`30` | FIN-WAIT-2 timeout (sec) / Таймаут FIN-WAIT-2 (сек) |
| `net.ipv4.tcp_tw_reuse` | `0` | `1` | Reuse TIME_WAIT sockets / Переиспользовать TIME_WAIT сокеты |
| `net.ipv4.tcp_keepalive_time` | `7200` | `300`-`600` | Keepalive idle time (sec) / Время бездействия keepalive (сек) |
| `net.ipv4.tcp_keepalive_intvl` | `75` | `15`-`30` | Keepalive probe interval (sec) / Интервал keepalive-проверки (сек) |
| `net.ipv4.tcp_keepalive_probes` | `9` | `5`-`10` | Keepalive probes before drop / Проверок keepalive до отбрасывания |
| `net.core.netdev_max_backlog` | `1000` | `5000`-`10000` | RX queue for fast interfaces / RX-очередь для быстрых интерфейсов |

### Socket Buffer Sizes / Размеры буферов сокетов

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `net.core.rmem_max` | `212992` (208 KB) | `16777216` (16 MB) | Max receive buffer per socket / Макс. буфер приёма на сокет |
| `net.core.wmem_max` | `212992` (208 KB) | `16777216` (16 MB) | Max send buffer per socket / Макс. буфер отправки на сокет |
| `net.core.rmem_default` | `212992` (208 KB) | `1048576` (1 MB) | Default receive buffer / Буфер приёма по умолчанию |
| `net.core.wmem_default` | `212992` (208 KB) | `1048576` (1 MB) | Default send buffer / Буфер отправки по умолчанию |
| `net.ipv4.tcp_rmem` | `4096 131072 6291456` | `4096 1048576 16777216` | TCP receive buffer (min default max) / Буфер TCP-приёма (мин. по умолч. макс.) |
| `net.ipv4.tcp_wmem` | `4096 16384 4194304` | `4096 1048576 16777216` | TCP send buffer (min default max) / Буфер TCP-отправки (мин. по умолч. макс.) |
| `net.ipv4.tcp_moderate_rcvbuf` | `1` | `1` | Enable auto-tuning of receive buffer / Включить автонастройку буфера приёма |
| `net.core.netdev_budget` | `300` | `600` | Packets processed per NAPI poll / Пакетов за один NAPI-опрос |

> [!TIP]
> For high-throughput workloads (databases, media streaming, proxies), increase `rmem_max`/`wmem_max` and `tcp_rmem`/`tcp_wmem` to match the application's needs. Check current values with `ss -tm` to see actual buffer usage.
> Для высоконагруженных задач (базы данных, стриминг медиа, прокси) увеличивайте `rmem_max`/`wmem_max` и `tcp_rmem`/`tcp_wmem` под потребности приложения. Проверяйте текущие значения через `ss -tm` для анализа фактического использования буферов.

### Connection Tracking

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `net.netfilter.nf_conntrack_max` | `262144` | `524288`-`2097152` | Max tracked connections / Макс. отслеживаемых соединений |
| `net.netfilter.nf_conntrack_tcp_timeout_established` | `432000` (5 days) | `86400` (1 day) | Established TCP timeout / Таймаут установленного TCP |

> [!IMPORTANT]
> After increasing `nf_conntrack_max`, also ensure `/proc/sys/net/netfilter/nf_conntrack_buckets` is sized proportionally (typically `nf_conntrack_max / 4`).

### Apply Networking Snippet

`/etc/sysctl.d/10-network.conf`

```bash
# TCP/IP stack tuning / Настройка TCP/IP стека
net.ipv4.ip_forward = 1
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.core.netdev_max_backlog = 5000
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# Socket buffer sizes / Размеры буферов сокетов
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 4096 1048576 16777216
net.ipv4.tcp_wmem = 4096 1048576 16777216
net.ipv4.tcp_moderate_rcvbuf = 1
```

```bash
sudo sysctl --system                        # Apply networking tuning / Применить сетевые настройки
```

---

## Memory & VM Parameters

### Swappiness & Cache Pressure

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `vm.swappiness` | `60` | `10` (servers), `60` (desktop) | Swap aggressiveness / Агрессивность swap |
| `vm.vfs_cache_pressure` | `100` | `50` (file servers) | Reclaim inode/dentry cache / Сбор файлового кэша |
| `vm.dirty_ratio` | `20` | `10`-`15` | % RAM for dirty pages before sync / % RAM для грязных страниц |
| `vm.dirty_background_ratio` | `10` | `3`-`5` | % RAM before background writeback / % RAM до фоновой записи |
| `vm.dirty_writeback_centisecs` | `500` | `300`-`500` | Writeback interval (ms) / Интервал обратной записи (мс) |

### Shared Memory & Overcommit

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `vm.overcommit_memory` | `0` | `0` or `2` | Overcommit mode (heuristic/always/never) / Режим перераспределения |
| `vm.overcommit_ratio` | `50` | `80`-`90` | % of RAM for overcommit when mode=2 / % RAM при режиме=2 |
| `kernel.shmmax` | `68719476736` | Match RAM size | Max shared memory segment / Макс. сегмент разделяемой памяти |
| `kernel.shmall` | `4294967296` | Match pages | Total shared memory pages / Всего страниц разделяемой памяти |

> [!TIP]
> For Redis, PostgreSQL, or any application using huge shared memory segments, ensure `kernel.shmmax` is at least as large as the application's shared memory requirement.

### Apply Memory Snippet

`/etc/sysctl.d/20-memory.conf`

```bash
# Memory & VM tuning / Настройка памяти и VM
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_writeback_centisecs = 300
vm.overcommit_memory = 0
vm.overcommit_ratio = 80
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
```

```bash
sudo sysctl --system                        # Apply memory tuning / Применить настройки памяти
```

---

## Filesystem Parameters

### File Handles & Inotify

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `fs.file-max` | `2097152` | `2097152`-`16777216` | Max system-wide file handles / Макс. файловых дескрипторов в системе |
| `fs.nr_open` | `1048576` | `2097152` | Max file descriptors per process (hard limit) / Макс. дескрипторов на процесс |
| `fs.inotify.max_user_watches` | `8192` | `524288`-`1048576` | Max inotify watches per user / Макс. inotify-наблюдений на пользователя |
| `fs.inotify.max_user_instances` | `8192` | `8192`-`65536` | Max inotify instances per user / Макс. inotify-инстансов на пользователя |

### Async I/O & IPC / Асинхронный ввод-вывод и IPC

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `fs.aio-max-nr` | `65536` | `1048576` | Max concurrent async I/O requests / Макс. одновременных async I/O запросов |
| `fs.aio-nr` | `0` | — | Current async I/O requests (read-only) / Текущие async I/O запросы (только чтение) |
| `kernel.msgmax` | `8192` | `8192` | Max bytes per message / Макс. байт на сообщение |
| `kernel.msgmnb` | `16384` | `16384` | Max bytes per message queue / Макс. байт на очередь сообщений |
| `kernel.msgmni` | `32000` | `32000` | Max message queue identifiers / Макс. идентификаторов очередей сообщений |
| `kernel.sem` | `32000 1024 512 32000` | `32000 1024 512 32000` | Semaphore limits (max, ops, etc.) / Лимиты семафоров (макс., операции и т.д.) |

> [!NOTE]
> `fs.aio-max-nr` is critical for databases (MySQL, PostgreSQL, MongoDB, ClickHouse) that use async I/O. If you see "aio queue full" errors, increase this value.
> `fs.aio-max-nr` критичен для баз данных (MySQL, PostgreSQL, MongoDB, ClickHouse), использующих асинхронный ввод-вывод. Если видите ошибки "aio queue full", увеличьте это значение.

### Apply Filesystem Snippet

`/etc/sysctl.d/30-filesystem.conf`

```bash
# Filesystem & inotify tuning / Настройка ФС и inotify
fs.file-max = 16777216
fs.nr_open = 2097152
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 65536

# Async I/O & IPC / Асинхронный ввод-вывод и IPC
fs.aio-max-nr = 1048576
```

```bash
sudo sysctl --system                        # Apply filesystem tuning / Применить настройки ФС
```

> [!NOTE]
> `fs.file-max` is a system-wide limit. For per-process limits, also check `ulimit -n` and `/etc/security/limits.conf`. See also [diskproccheatsheet.md](diskproccheatsheet.md) for `/proc` filesystem details.

---

## Kernel & Security Parameters

### Kernel Hardening

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `kernel.randomize_va_space` | `2` | `2` | ASLR full randomization / Полная случайная адресация |
| `kernel.core_uses_pid` | `0` | `1` | Append PID to core dumps / Добавить PID к core-дампам |
| `kernel.sysrq` | `16` | `0` (production) | Magic SysRq key / Магическая клавиша SysRq |
| `kernel.dmesg_restrict` | `0` | `1` | Restrict dmesg to root / Ограничить dmesg для root |
| `kernel.kptr_restrict` | `0` | `2` | Hide kernel pointers / Скрыть указатели ядра |

### Network Security

| Parameter | Default | Recommended | Description (EN / RU) |
| :--- | :--- | :--- | :--- |
| `net.ipv4.conf.all.rp_filter` | `0` | `1` | Reverse path filtering / Обратная фильтрация пути |
| `net.ipv4.icmp_echo_ignore_broadcasts` | `0` | `1` | Ignore ICMP broadcast echo / Игнорировать broadcast ICMP echo |
| `net.ipv4.conf.all.accept_redirects` | `1` | `0` | Refuse ICMP redirects / Отклонять ICMP-редиректы |
| `net.ipv4.conf.all.send_redirects` | `1` | `0` | Don't send ICMP redirects / Не отправлять ICMP-редиректы |
| `net.ipv4.conf.all.accept_source_route` | `1` | `0` | Refuse source-routed packets / Отклонять маршрутизированные пакеты |
| `net.ipv4.tcp_syncookies` | `0` | `1` | SYN flood protection / Защита от SYN-флуда |
| `kernel.yama.ptrace_scope` | `0` | `1`-`2` | Restrict ptrace to parent / Ограничить ptrace для родителя |

### Apply Security Snippet

`/etc/sysctl.d/40-security.conf`

```bash
# Kernel hardening / Усиление безопасности ядра
kernel.randomize_va_space = 2
kernel.core_uses_pid = 1
kernel.sysrq = 0
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# Network security / Сетевая безопасность
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
kernel.yama.ptrace_scope = 1
```

```bash
sudo sysctl --system                        # Apply security hardening / Применить усиление безопасности
```

---

## Sysadmin Operations

### Inspecting Values

```bash
sysctl -a | grep -E 'net\.(ipv4|core)'     # List all networking params / Список всех сетевых параметров
sysctl -a | grep ^vm\.                      # List all VM params / Список всех VM-параметров
sysctl -a | grep ^fs\.                      # List all filesystem params / Список всех ФС-параметров
sysctl -a | grep ^kernel\.                  # List all kernel params / Список всех параметров ядра
```

### Applying Changes Safely

1. **Inspect the current value** before changing anything:

```bash
sysctl net.ipv4.ip_forward                  # Show current value / Показать текущее значение
```

2. **Test the new value** at runtime:

```bash
sudo sysctl -w net.ipv4.ip_forward=1        # Set runtime value / Установить временное значение
```

3. **Verify the change** took effect:

```bash
sysctl net.ipv4.ip_forward                  # Confirm new value / Подтвердить новое значение
```

4. **Persist the change** in a drop-in file:

```bash
sudo tee /etc/sysctl.d/99-custom.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF
```

5. **Reboot or reload** to confirm persistence:

```bash
sudo sysctl --system                        # Reload without reboot / Перезагрузить без ребута
sudo reboot                                 # Or reboot to fully verify / Или перезагрузить для полной проверки
```

> [!CAUTION]
> Incorrect network parameters can lock you out of a remote host. Always test on console access or have out-of-band recovery (IPMI, cloud console) available before applying network changes on production servers.

### Check systemd-sysctl

```bash
systemctl status systemd-sysctl             # Check if service ran / Проверить запуск сервиса
journalctl -u systemd-sysctl                # View sysctl service logs / Просмотр логов sysctl-сервиса
sudo systemctl restart systemd-sysctl       # Force reapply / Принудительно повторно применить
```

---

## Performance Tuning Profiles

### Web Server

`/etc/sysctl.d/10-web-server.conf`

```bash
# High-concurrency web server tuning / Настройка для высоконагруженного веб-сервера
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
fs.file-max = 4194304
fs.inotify.max_user_watches = 524288
```

```bash
sudo sysctl --system                        # Apply web server profile / Применить профиль веб-сервера
```

### Database Server

`/etc/sysctl.d/10-database.conf`

```bash
# Database server tuning (PostgreSQL, MySQL) / Настройка БД (PostgreSQL, MySQL)
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 0
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
fs.file-max = 4194304
net.core.somaxconn = 4096
net.ipv4.tcp_keepalive_time = 600
```

```bash
sudo sysctl --system                        # Apply database profile / Применить профиль БД
```

### Container Host

`/etc/sysctl.d/10-container.conf`

```bash
# Container host tuning (Docker, Kubernetes) / Настройка хоста контейнеров (Docker, Kubernetes)
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.file-max = 16777216
vm.max_map_count = 262144
```

```bash
sudo sysctl --system                        # Apply container host profile / Применить профиль контейнерного хоста
```

> [!IMPORTANT]
> `net.bridge.bridge-nf-call-iptables` and `net.bridge.bridge-nf-call-ip6tables` require the `br_netfilter` kernel module. Load it first:

```bash
sudo modprobe br_netfilter                  # Load bridge filter module / Загрузить модуль фильтрации мостов
echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_netfilter.conf  # Persist module load / Сохранить загрузку модуля
```

### High-Concurrency VPS

`/etc/sysctl.d/10-high-concurrency.conf`

```bash
# High-concurrency VPS tuning / Настройка VPS с высокой нагрузкой
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 10000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_syncookies = 1
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 3
fs.file-max = 16777216
fs.inotify.max_user_watches = 524288
kernel.pid_max = 65536
```

```bash
sudo sysctl --system                        # Apply high-concurrency profile / Применить профиль высокой нагрузки
```

---

## Security Hardening

### Production Baseline

`/etc/sysctl.d/50-hardening.conf`

```bash
# Production security baseline / Базовая безопасность для продакшена

# Kernel hardening / Усиление ядра
kernel.randomize_va_space = 2
kernel.core_uses_pid = 1
kernel.sysrq = 0
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# Network security / Сетевая безопасность
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
```

```bash
sudo sysctl --system                        # Apply security baseline / Применить базовую безопасность
```

### Security vs Performance Tradeoffs

| Parameter | Secure Value | Performance Value | Tradeoff / Компромисс |
| :--- | :--- | :--- | :--- |
| `kernel.sysrq` | `0` | `16` | No magic keys vs. emergency recovery / Нет магических клавиш vs. аварийное восстановление |
| `kernel.dmesg_restrict` | `1` | `0` | Hide dmesg vs. open debugging / Скрыть dmesg vs. открытая отладка |
| `kernel.kptr_restrict` | `2` | `0` | Hide pointers vs. open profiling / Скрыть указатели vs. открытый профилинг |
| `net.ipv4.tcp_syncookies` | `1` | `0` | SYN protection vs. slight overhead / Защита SYN vs. небольшой overhead |
| `kernel.yama.ptrace_scope` | `1` | `0` | Restrict ptrace vs. full debugging / Ограничить ptrace vs. полная отладка |
| `net.ipv4.conf.all.accept_redirects` | `0` | `1` | No redirects vs. auto-path optimization / Нет редиректов vs. авто-оптимизация |
| `vm.swappiness` | `0`-`10` | `60` | Minimal swap vs. better cache eviction / Минимум swap vs. лучший сбор кэша |

> [!WARNING]
> Removing security hardening for performance gains is rarely justified in production. Benchmark first; do not assume a parameter hurts performance without measuring.

---

## Backup & Restore

### Backup sysctl Configuration

```bash
sudo tar czf /root/sysctl-backup-$(date +%F).tar.gz \
    /etc/sysctl.conf \
    /etc/sysctl.d/ \
    /usr/lib/sysctl.d/                      # Archive all sysctl config / Архивировать все конфиги sysctl
```

### Restore from Backup

```bash
sudo tar xzf /root/sysctl-backup-2026-01-15.tar.gz -C /  # Restore configs / Восстановить конфиги
sudo sysctl --system                        # Reapply restored settings / Повторно применить восстановленные настройки
```

> [!TIP]
> Always back up sysctl configs before major changes. A single incorrect networking parameter can disable connectivity on a remote host.

---

## Troubleshooting & Tools

### Common Issues

| Symptom | Likely Cause (EN / RU) | Fix / Что делать |
| :--- | :--- | :--- |
| `sysctl: error reading key` | Parameter does not exist / Параметр не существует | Check parameter name with `sysctl -a \| grep <partial>` |
| `sysctl: permission denied` | Not running as root / Не от root | Use `sudo` |
| Changes not persistent | Forgot to write to drop-in file / Забыли записать в drop-in | Create `/etc/sysctl.d/<file>.conf` |
| `sysctl --system` ignored value | Duplicate key in earlier file / Дублирующий ключ в раннем файле | Check load order with `systemd-analyze cat-config sysctl` |
| Container networking broken | `ip_forward=0` or bridge params missing / Не включён ip_forward или нет bridge-параметров | Set `net.ipv4.ip_forward=1` and bridge params |
| `Connection refused` after tuning | `tcp_syncookies` or backlog too small / tcp_syncookies или backlog слишком мал | Increase `somaxconn`, `tcp_max_syn_backlog`, enable `tcp_syncookies` |

### Debugging Commands

```bash
sysctl -a | grep <PARTIAL>                 # Find parameters by partial name / Найти параметры по частичному имени
systemd-analyze cat-config sysctl           # Show effective config load order / Показать порядок загрузки конфигов
sysctl -p --system 2>&1 | head -20         # Check for errors during apply / Проверить ошибки при применении
dmesg | tail -30                            # Recent kernel messages for sysctl errors / Последние сообщения ядра
journalctl -u systemd-sysctl --since "10 min ago"  # Sysctl service logs / Логи sysctl-сервиса
cat /proc/sys/net/ipv4/ip_forward           # Verify value directly in proc / Проверить значение напрямую в proc
```

### Finding Parameters

```bash
sysctl -a | grep ^net\. | sort             # All networking parameters sorted / Все сетевые параметры по алфавиту
sysctl -a | grep ^vm\.                     # All VM parameters / Все VM-параметры
sysctl -a | grep ^fs\.                     # All filesystem parameters / Все параметры ФС
sysctl -a | grep ^kernel\.security         # Kernel security parameters / Параметры безопасности ядра
```

---

## Production Runbooks

### Runbook 1: Applying Tuning to Production

1. **Audit current state** and record baseline values:

```bash
sysctl net.ipv4.ip_forward net.core.somaxconn net.ipv4.tcp_fin_timeout vm.swappiness  # Record baselines / Записать базовые значения
```

2. **Back up existing configuration**:

```bash
sudo tar czf /root/sysctl-pre-tune-$(date +%F).tar.gz /etc/sysctl.conf /etc/sysctl.d/  # Backup configs / Бэкап конфигов
```

3. **Create the tuning file** and test at runtime:

```bash
sudo sysctl -w net.core.somaxconn=65535    # Test at runtime / Тестировать во время работы
sysctl net.core.somaxconn                   # Verify value / Проверить значение
```

4. **Persist the configuration** if the runtime test is successful:

`/etc/sysctl.d/99-tuning.conf`

```bash
net.core.somaxconn = 65535
net.ipv4.tcp_fin_timeout = 15
vm.swappiness = 10
```

5. **Reload and verify persistence**:

```bash
sudo sysctl --system                        # Reload all configs / Перезагрузить все конфиги
sysctl net.core.somaxconn net.ipv4.tcp_fin_timeout vm.swappiness  # Confirm values / Подтвердить значения
```

6. **Reboot if required** and verify again:

```bash
sudo reboot                                 # Reboot to verify persistence / Перезагрузить для проверки
sysctl net.core.somaxconn net.ipv4.tcp_fin_timeout vm.swappiness  # Post-reboot check / Проверка после ребута
```

### Runbook 2: Incident -- Connection Refused

1. **Check if the service is listening** and on which port:

```bash
ss -tlnp                                   # Show listening TCP sockets / Показать слушающие TCP-сокеты
```

2. **Inspect backlog and connection limits**:

```bash
sysctl net.core.somaxconn net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_syncookies  # Check limits / Проверить лимиты
```

3. **Increase backlog and enable SYN cookies** if limits are too low:

```bash
sudo sysctl -w net.core.somaxconn=65535    # Increase listen backlog / Увеличить очередь прослушивания
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=8192  # Increase SYN queue / Увеличить SYN-очередь
sudo sysctl -w net.ipv4.tcp_syncookies=1   # Enable SYN flood protection / Включить защиту от SYN-флуда
```

4. **Verify the service accepts connections**:

```bash
curl -v http://localhost:80/               # Test local HTTP connection / Проверить локальное HTTP-соединение
ss -tlnp | grep :80                        # Confirm socket is listening / Подтвердить прослушивание сокета
```

5. **Persist the fix** in a drop-in file:

```bash
sudo tee /etc/sysctl.d/99-backlog-fix.conf <<'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
EOF
```

6. **Reload and verify**:

```bash
sudo sysctl --system                        # Apply persisted fix / Применить сохранённое исправление
sysctl net.core.somaxconn net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_syncookies  # Confirm / Подтвердить
```

### Runbook 3: Incident -- Container Networking Broken

1. **Check IP forwarding** status:

```bash
sysctl net.ipv4.ip_forward                 # Should be 1 for containers / Должно быть 1 для контейнеров
```

2. **Check bridge parameters** if using Docker or Kubernetes:

```bash
sysctl net.bridge.bridge-nf-call-iptables  # Should be 1 / Должно быть 1
sysctl net.bridge.bridge-nf-call-ip6tables # Should be 1 / Должно быть 1
```

3. **Load the bridge module** and enable forwarding:

```bash
sudo modprobe br_netfilter                 # Load bridge filter module / Загрузить модуль фильтрации мостов
sudo sysctl -w net.ipv4.ip_forward=1       # Enable IP forwarding / Включить IP-форвардинг
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1  # Enable bridge filtering / Включить фильтрацию мостов
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1 # Enable bridge filtering for IPv6 / Включить фильтрацию мостов IPv6
```

4. **Persist the configuration**:

`/etc/sysctl.d/10-container.conf`

```bash
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

5. **Persist the kernel module** and reload:

```bash
echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_netfilter.conf  # Persist module / Сохранить модуль
sudo sysctl --system                        # Apply sysctl changes / Применить изменения sysctl
```

6. **Verify container networking** works:

```bash
docker run --rm alpine ping -c 1 8.8.8.8  # Test container connectivity / Проверить связь контейнера
```

---

## Parameter Reference Tables

### Overcommit Modes

| Mode (`vm.overcommit_memory`) | Behavior (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| `0` | Heuristic overcommit (default) / Эвристическое перераспределение | General-purpose systems / Универсальные системы |
| `1` | Always overcommit (no checks) / Всегда разрешать (без проверок) | Workloads that guarantee allocation success / Работы, гарантирующие успех выделения |
| `2` | Never overcommit beyond ratio / Никогда не превышать ratio | Databases, Redis, memory-critical apps / БД, Redis, критичные к памяти приложения |

### Swappiness Comparison

| Value | Behavior (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| `0`-`10` | Minimal swap usage / Минимальное использование swap | Production servers, databases, latency-sensitive apps |
| `10`-`30` | Balanced behavior / Сбалансированное поведение | General Linux hosts and mixed workloads |
| `60` | More aggressive paging / Более агрессивный свопинг | Kernel default on many systems, desktop-friendly defaults |

### Kernel Pointer Restriction (`kernel.kptr_restrict`)

| Value | Behavior (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| `0` | No restriction (default) / Без ограничений | Debugging, profiling / Отладка, профилинг |
| `1` | Restrict to root for /proc/kallsyms / Ограничить для root в /proc/kallsyms | Semi-secure systems / Полу-защищённые системы |
| `2` | Hide all kernel pointers completely / Полностью скрыть указатели ядра | Production hardening / Усиление продакшена |

### Yama ptrace_scope (`kernel.yama.ptrace_scope`)

| Value | Behavior (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| `0` | No restrictions / Без ограничений | Development, debugging / Разработка, отладка |
| `1` | Only parent can ptrace / Только родительский процесс может ptrace | Semi-secure production / Полу-защищённый продакшен |
| `2` | Only admin can ptrace / Только администратор может ptrace | High-security environments / Высоко-защищённые среды |
| `3` | ptrace fully disabled / ptrace полностью отключён | Maximum lockdown / Максимальная изоляция |

---

## Documentation Links

- **sysctl(8):** https://man7.org/linux/man-pages/man8/sysctl.8.html
- **sysctl.conf(5):** https://man7.org/linux/man-pages/man5/sysctl.conf.5.html
- **proc(5):** https://man7.org/linux/man-pages/man5/proc.5.html
- **Kernel sysctl documentation:** https://www.kernel.org/doc/html/latest/admin-guide/sysctl/
- **ArchWiki -- sysctl:** https://wiki.archlinux.org/title/Sysctl

```bash
man sysctl                                  # Local manual for sysctl / Локальная man-страница sysctl
man sysctl.conf                             # Local manual for sysctl.conf / Локальная man-страница sysctl.conf
```
