Title: 💾 Swap — Virtual Memory Management
Group: System & Logs
Icon: 💾
Order: 11

# Swap — Linux Virtual Memory Management

**Swap** is disk-backed virtual memory used when physical RAM is exhausted or when the kernel wants to move cold pages out of RAM. It is still relevant on modern Linux systems for burst absorption, OOM protection, crash resilience, and hibernation support.

**Common use cases / Типичные сценарии:**
- Prevent immediate `OOMKilled` or kernel out-of-memory events on small VPS instances
- Smooth short-lived memory spikes on application, CI, and container hosts
- Support hibernation on laptops and workstations
- Provide extra safety margin while investigating memory leaks

**Current status / Актуальность:**
- **Swap files** are the normal default on modern Ubuntu installs and cloud images
- **Swap partitions** are still valid, but are more common on legacy systems or dedicated hibernation setups
- **zram** and **zswap** are modern complements, not always full replacements for disk-backed swap

## Table of Contents
- [Overview](#overview)
- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Performance Tuning](#performance-tuning)
- [Security](#security)
- [Backup & Restore](#backup--restore)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Production Runbooks](#production-runbooks)
- [Additional Notes](#additional-notes)
- [Documentation](#documentation)

---

## Overview

Swap is **not RAM**. It is slower than memory because it uses disk or compressed memory layers. Short and occasional usage can be normal; sustained high activity usually means the host is under memory pressure.

> [!WARNING]
> Heavy continuous swap usage usually indicates a real memory bottleneck. Treat it as a symptom, not a fix.

### Swap Types / Типы swap

| Type | Description (EN / RU) | Best For / Когда использовать |
|------|------------------------|-------------------------------|
| Swap file | File-backed swap such as `/swapfile` or `/swap.img` / Swap в виде файла | Default Ubuntu installs, VPS hosts, easy resizing |
| Swap partition | Dedicated block device or partition / Выделенный раздел | Legacy builds, predictable hibernation layouts, bare metal |
| zram | Compressed RAM block device used as swap / Сжатый swap в RAM | Low-memory systems, laptops, lightweight VMs |
| zswap | Compressed cache before writing pages to disk swap / Сжатый кэш перед записью на диск | Systems that already have disk swap and want fewer physical writes |

### Why It Matters / Зачем это нужно

| Feature | Description (EN / RU) | Use Case / Best for |
|---------|------------------------|---------------------|
| Burst protection | Absorbs short RAM spikes / Смягчает кратковременные пики памяти | CI jobs, package builds, backup windows |
| OOM delay | Gives time before the kernel kills processes / Даёт время до OOM-убийства процессов | Incident response, temporary overload |
| Hibernation | Saves RAM image to swap / Сохраняет образ RAM в swap | Laptops and workstations |
| Cold-page eviction | Moves rarely used pages out of RAM / Выносит редко используемые страницы из RAM | Mixed workloads, shared hosts |

### Paths, Logs, and Service Notes / Пути, логи и сервисные заметки

| Item | Typical Location / Команда | Notes / Примечание |
|------|-----------------------------|--------------------|
| Active swap devices | `/proc/swaps` | Kernel view of enabled swap |
| Memory tuning | `/proc/sys/vm/*` | Runtime VM tunables |
| Persistent tuning | `/etc/sysctl.conf`, `/etc/sysctl.d/*.conf` | Survives reboot |
| Persistent activation | `/etc/fstab` | `swapon -a` reads this file |
| Kernel logs | `journalctl -k`, `dmesg` | First place to inspect OOM/swap issues |
| Syslog logs | `/var/log/syslog`, `/var/log/kern.log` | Common on Ubuntu when `rsyslog` is installed |
| Dedicated service | None | Swap is managed by the kernel and `swapon`/`swapoff` |
| Default ports | None | Swap has no network listener |

> [!NOTE]
> For kernel log workflows, see the `journalctl` cheatsheets in this category. logrotate is usually **not** applied directly to swap because swap events live in kernel/system logs rather than a dedicated swap log file.

---

## Installation & Configuration

### Inspect Current Setup / Проверить текущую конфигурацию

```bash
swapon --show --bytes                       # Show active swap devices / Показать активные swap-устройства
cat /proc/swaps                             # Read kernel swap table / Прочитать таблицу swap из ядра
free -h                                     # Show RAM and swap usage / Показать использование RAM и swap
cat /proc/sys/vm/swappiness                 # Current swappiness value / Текущее значение swappiness
```

### fstab Entry / Запись в fstab
`/etc/fstab`

```bash
/swap.img none swap sw 0 0                  # Swap file entry / Запись swap-файла
```

### Create or Resize Swap File to 6 GiB / Создать или изменить swap до 6 ГиБ

> [!CAUTION]
> `swapoff` can stall or fail on a host that has no free RAM to absorb swapped pages. Check memory pressure before disabling swap in production.

```bash
free -h                                     # Check current memory usage / Проверить текущее использование памяти
swapon --show                               # Verify active swap before changes / Проверить активный swap перед изменениями
sudo swapoff /swap.img                      # Disable swap file / Отключить swap-файл
sudo rm -f /swap.img                        # Remove old swap file / Удалить старый swap-файл
sudo fallocate -l 6G /swap.img              # Fast create 6 GiB swap file / Быстро создать swap 6 ГиБ
sudo dd if=/dev/zero of=/swap.img bs=1M count=6144 status=progress  # Fallback create method / Альтернативный способ создания
sudo chmod 600 /swap.img                    # Restrict permissions / Ограничить права доступа
sudo mkswap /swap.img                       # Write swap signature / Создать swap-сигнатуру
sudo swapon /swap.img                       # Enable new swap file / Включить новый swap-файл
swapon --show                               # Verify result / Проверить результат
```

### Persistent VM Tuning / Постоянная настройка VM
`/etc/sysctl.d/99-swap-tuning.conf`

```bash
vm.swappiness=10                            # Prefer RAM, swap later / Предпочитать RAM, позже использовать swap
vm.vfs_cache_pressure=50                    # Keep inode/dentry cache longer / Дольше хранить файловый кэш
```

Apply the settings after creating the file:

```bash
sudo sysctl --system                        # Reload all sysctl config files / Перечитать все sysctl-конфиги
sudo systemctl restart systemd-sysctl       # Reapply sysctl via systemd / Повторно применить sysctl через systemd
```

### Temporary Runtime Tuning / Временная настройка во время работы

```bash
sudo sysctl vm.swappiness=10                # Set swappiness until reboot / Изменить swappiness до перезагрузки
sudo sysctl vm.vfs_cache_pressure=50        # Tune cache pressure until reboot / Настроить cache pressure до перезагрузки
```

### Optional zram Configuration / Опциональная настройка zram
`/etc/systemd/zram-generator.conf`

```bash
[zram0]                                     # First zram device / Первое zram-устройство
zram-size = ram / 2                         # Use half of RAM for zram / Использовать половину RAM под zram
compression-algorithm = zstd                # Fast modern compression / Быстрое современное сжатие
swap-priority = 100                         # Prefer zram before disk swap / Предпочитать zram перед дисковым swap
```

```bash
sudo apt install systemd-zram-generator     # Install zram generator on Ubuntu if needed / Установить генератор zram при необходимости
sudo systemctl daemon-reload                # Reload systemd units / Перечитать юниты systemd
sudo systemctl start systemd-zram-setup@zram0.service  # Create zram device now / Создать zram-устройство сейчас
swapon --show                               # Verify active zram or disk swap / Проверить активный zram или диск swap
```

> [!TIP]
> On modern Ubuntu, `/swapfile` is more common than `/swap.img`, but cloud images and custom builds may use either. Always verify with `swapon --show`.

---

## Core Management

### Check Status / Проверить состояние

```bash
swapon --show                               # Active swap devices / Активные swap-устройства
free -h                                     # Human-readable memory usage / Использование памяти в удобном формате
cat /proc/swaps                             # Kernel swap table / Таблица swap из ядра
```

Sample output:

```bash
NAME       TYPE SIZE USED PRIO
/swap.img  file   6G   0B   -2
```

### Enable or Disable / Включить или отключить

```bash
sudo swapon /swap.img                       # Enable one swap file / Включить один swap-файл
sudo swapoff /swap.img                      # Disable one swap file / Отключить один swap-файл
sudo swapon -a                              # Enable all swap entries from fstab / Включить все записи swap из fstab
sudo swapoff -a                             # Disable all swap devices / Отключить все swap-устройства
```

### Verify File and Priority / Проверить файл и приоритет

```bash
ls -lh /swap.img                            # Check file size and ownership / Проверить размер и владельца файла
stat /swap.img                              # Show permissions and timestamps / Показать права и время изменения
swapon --show=NAME,TYPE,SIZE,USED,PRIO      # Show priority and utilization / Показать приоритет и использование
```

### Quick CRUD Mindset / Базовые операции

| Operation | Command / Что делать | Notes / Примечание |
|-----------|----------------------|--------------------|
| Create | `fallocate` or `dd` + `mkswap` | File-backed swap |
| Read status | `swapon --show`, `free -h`, `cat /proc/swaps` | Fast health check |
| Update size | `swapoff` -> recreate file -> `mkswap` -> `swapon` | Safest resize flow |
| Delete | `swapoff` -> remove file -> clean `fstab` | Confirm RAM headroom first |

---

## Sysadmin Operations

### Top Memory Consumers / Процессы с наибольшим потреблением памяти

```bash
ps aux --sort=-%mem | head                  # Top memory users / Топ процессов по памяти
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 15  # Detailed top list / Подробный список лидеров
```

### Memory Pressure and Paging / Давление на память и пейджинг

```bash
vmstat 1 5                                  # Memory and swap stats / Статистика памяти и swap
sar -W 1 5                                  # Swap in/out rates if sysstat is installed / Скорость swap in/out если установлен sysstat
```

Sample `vmstat` fields to watch:

| Field | Meaning (EN / RU) | Why it matters |
|-------|--------------------|----------------|
| `si` | Swap in / Чтение из swap | High values mean pages are being read back into RAM |
| `so` | Swap out / Запись в swap | High values mean RAM pressure is forcing pages out |
| `wa` | I/O wait / Ожидание I/O | Rising `wa` with swap often means disk contention |
| `r` | Runnable tasks / Очередь на CPU | Helps separate CPU pressure from memory pressure |

### OOM and Kernel Logs / Логи OOM и ядра

```bash
dmesg | grep -i oom                         # Search kernel ring buffer for OOM / Искать OOM в буфере ядра
journalctl -k | grep -i oom                 # Search persistent kernel journal / Искать OOM в журнале ядра
journalctl -k --since "1 hour ago" | grep -Ei 'oom|out of memory|swap'  # Recent swap/OOM events / Недавние события swap или OOM
grep -Ei 'oom|out of memory|swap' /var/log/kern.log  # Ubuntu kernel log if rsyslog is enabled / Лог ядра Ubuntu при включённом rsyslog
```

### System Actions / Сервисные действия

```bash
sudo swapon -a                              # Re-enable configured swap devices / Повторно включить настроенные swap-устройства
sudo swapoff -a                             # Disable all configured swap devices / Отключить все настроенные swap-устройства
sudo systemctl restart systemd-sysctl       # Reapply VM tunables / Повторно применить VM-настройки
systemctl status systemd-sysctl             # Check sysctl unit status / Проверить статус юнита sysctl
```

### Why zram vs Disk Swap / Почему zram и disk swap отличаются

| Option | Description (EN / RU) | Use Case / Best for |
|--------|------------------------|---------------------|
| Disk swap | Writes pages to SSD/HDD/NVMe / Пишет страницы на SSD/HDD/NVMe | Servers that need guaranteed extra backing store |
| zram | Compresses pages in RAM / Сжимает страницы в RAM | Small VPS, laptops, low-memory desktop systems |
| zswap | Compresses before disk write / Сжимает перед записью на диск | Reduce write amplification while keeping real swap |

Disk swap gives more total backing storage but is slower. zram is much faster because it stays in memory, but it still consumes RAM and cannot replace real capacity on heavily loaded hosts.

---

## Performance Tuning

### Swappiness / Параметр swappiness

```bash
cat /proc/sys/vm/swappiness                 # Read current swappiness / Прочитать текущее значение swappiness
sudo sysctl vm.swappiness=10                # Set runtime swappiness / Установить swappiness во время работы
```

### Persistent Swappiness / Постоянный swappiness
`/etc/sysctl.d/99-swappiness.conf`

```bash
vm.swappiness=10                            # Lower tendency to swap / Снизить склонность к swap
```

```bash
sudo sysctl --system                        # Reload persistent sysctl settings / Перечитать постоянные sysctl-настройки
```

### Swappiness Comparison / Сравнение значений swappiness

| Value | Behavior (EN / RU) | Use Case / Best for |
|------|---------------------|---------------------|
| `0-10` | Minimal swap usage / Минимальное использование swap | Production servers, databases, latency-sensitive apps |
| `10-30` | Balanced behavior / Сбалансированное поведение | General Linux hosts and mixed workloads |
| `60` | More aggressive paging / Более агрессивный свопинг | Kernel default on many systems, desktop-friendly defaults |

### Cache Pressure / Давление на VFS cache

```bash
cat /proc/sys/vm/vfs_cache_pressure         # Show current cache pressure / Показать текущее давление на кэш
sudo sysctl vm.vfs_cache_pressure=50        # Keep filesystem cache longer / Дольше держать файловый кэш
```

### Tuning Guidance / Практические замечания

- Lower `swappiness` when you care about latency more than cache retention.
- Keep `swappiness` moderate on general-purpose hosts where occasional background swap is acceptable.
- Tune `vfs_cache_pressure` carefully; values that are too low may keep cache too aggressively and starve applications of RAM.

> [!WARNING]
> Do not set `swappiness=0` blindly on every system. On some kernels and workloads it can delay reclaim until memory pressure becomes severe.

---

## Security

### File Permissions / Права доступа

```bash
sudo chmod 600 /swap.img                    # Restrict swap file to root only / Ограничить swap-файл только для root
stat /swap.img                              # Verify restrictive mode / Проверить ограниченный режим доступа
```

### Encrypted Swap Note / Заметка про шифрование

Sensitive data can be paged out to swap. On laptops, shared servers, or regulated environments, prefer full-disk encryption or encrypted swap.

`/etc/crypttab`

```bash
cryptswap1 /dev/disk/by-uuid/<UUID> /dev/urandom swap,cipher=aes-xts-plain64,size=256  # Example encrypted swap mapping / Пример шифрованного swap
```

> [!NOTE]
> Encrypted swap is most common with a dedicated swap partition. File-backed encrypted swap is possible but usually needs more careful boot and initramfs design.

---

## Backup & Restore

Swap contents themselves are not useful to back up. Back up the **configuration** instead: `fstab`, sysctl files, and any resume or encryption settings.

### Backup and Restore Config Files / Резервная копия и восстановление конфигов

```bash
sudo cp /etc/fstab /etc/fstab.bak                          # Back up fstab / Сделать резервную копию fstab
sudo cp /etc/sysctl.d/99-swap-tuning.conf /etc/sysctl.d/99-swap-tuning.conf.bak  # Back up swap sysctl file / Сохранить backup sysctl-файла
sudo mv /etc/fstab.bak /etc/fstab                          # Restore fstab / Восстановить fstab
sudo mv /etc/sysctl.d/99-swap-tuning.conf.bak /etc/sysctl.d/99-swap-tuning.conf  # Restore sysctl tuning / Восстановить sysctl-настройки
sudo swapon -a                                             # Re-enable configured swap / Повторно включить настроенный swap
sudo sysctl --system                                       # Reapply kernel tuning / Повторно применить настройки ядра
```

### Snapshot Considerations / Замечания по снапшотам

- VM or cloud snapshots should capture config files, not rely on live swap state.
- Exclude swap files from backup archives when possible to save space and avoid copying meaningless transient data.

---

## Troubleshooting & Tools

### Swap Not Working / Swap не работает

```bash
swapon --show                               # Check whether swap is active / Проверить, активен ли swap
sudo swapon --verbose --all                 # Try enabling all configured swap devices / Попробовать включить все настроенные swap-устройства
ls -lh /swap.img                            # Confirm file exists and size looks correct / Убедиться, что файл существует и размер корректный
file /swap.img                              # Check for swap signature or file type / Проверить сигнатуру swap или тип файла
```

### Fix Permissions / Исправить права

```bash
sudo chmod 600 /swap.img                    # Fix unsafe permissions / Исправить небезопасные права
sudo mkswap /swap.img                       # Recreate swap signature if needed / Пересоздать swap-сигнатуру при необходимости
sudo swapon /swap.img                       # Re-enable swap file / Снова включить swap-файл
```

### Detect Thrashing / Обнаружить thrashing

```bash
vmstat 1                                    # Watch swap in/out continuously / Наблюдать swap in/out в реальном времени
iostat -xz 1                                # Check disk saturation if sysstat is installed / Проверить загрузку диска если установлен sysstat
ps aux --sort=-%mem | head                  # Find biggest memory consumers / Найти главных потребителей памяти
```

> [!CAUTION]
> High `si` and `so` values together with high I/O wait usually mean the host is thrashing and performance will collapse quickly.

### Common Failure Patterns / Частые проблемы

| Symptom | Likely Cause (EN / RU) | Fix / Что делать |
|---------|-------------------------|------------------|
| `swapon: insecure permissions` | Swap file is too open / Слишком широкие права на файл | `chmod 600 /swap.img` |
| `swapon: Invalid argument` | Missing swap signature / Нет сигнатуры swap | Run `mkswap` again |
| `swapoff` hangs | System lacks free RAM / Не хватает свободной RAM | Stop memory-heavy apps first |
| High swap use with low free RAM | Real memory pressure / Реальное давление на память | Identify offenders, tune, or add RAM |

### Log Handling / Работа с логами

There is usually no dedicated `/var/log/swap.log`. Swap events appear in kernel or system logs.

```bash
journalctl -k -n 100                        # Read recent kernel messages / Прочитать последние сообщения ядра
grep -Ei 'oom|swap|out of memory' /var/log/syslog  # Search syslog on Ubuntu systems with rsyslog / Искать события в syslog на Ubuntu с rsyslog
```

> [!NOTE]
> Dedicated logrotate snippets are generally **not applicable** to swap itself. Rotate `syslog`, `kern.log`, or service logs instead; see `logrotatecheatsheet.md`.

---

## Production Runbooks

### Safe Swap Resize Procedure / Безопасное изменение размера swap

1. Check current pressure and confirm the host can survive a temporary `swapoff`.

```bash
free -h                                     # Confirm available RAM / Проверить доступную RAM
swapon --show                               # Check current swap usage / Проверить текущее использование swap
vmstat 1 5                                  # Ensure the system is not already thrashing / Убедиться, что система уже не thrashing
```

2. Disable the current swap file.

```bash
sudo swapoff /swap.img                      # Disable current swap file / Отключить текущий swap-файл
```

3. Recreate the file with the new size.

```bash
sudo rm -f /swap.img                        # Remove old file / Удалить старый файл
sudo fallocate -l 6G /swap.img              # Create new 6 GiB file / Создать новый файл 6 ГиБ
sudo chmod 600 /swap.img                    # Secure permissions / Выставить безопасные права
sudo mkswap /swap.img                       # Write new swap signature / Создать новую swap-сигнатуру
```

4. Re-enable swap and verify.

```bash
sudo swapon /swap.img                       # Enable resized swap / Включить изменённый swap
swapon --show                               # Verify active swap / Проверить активный swap
free -h                                     # Confirm memory/swap totals / Проверить объём памяти и swap
```

5. Confirm persistence in `fstab` if the path changed.

```bash
grep -n '/swap' /etc/fstab                  # Verify persistent swap entry / Проверить постоянную запись swap
```

### Incident: High Swap Usage / Инцидент: высокий swap

1. Identify which process or service is driving memory consumption.

```bash
ps aux --sort=-%mem | head -n 20            # Show top memory consumers / Показать топ потребителей памяти
systemd-cgtop                               # Check memory by cgroup/service / Проверить память по cgroup или сервису
```

2. Check whether the host is actually thrashing.

```bash
vmstat 1 10                                 # Watch swap in/out rates / Смотреть скорость swap in/out
iostat -xz 1 5                              # Check storage wait and saturation / Проверить ожидание и насыщение диска
```

3. Review logs for OOM events, allocator failures, or service crashes.

```bash
journalctl -k --since "30 minutes ago"      # Recent kernel events / Последние события ядра
journalctl -u <SERVICE> --since "30 minutes ago"  # Service logs if a single app is affected / Логи сервиса если затронуто одно приложение
dmesg | grep -i oom                         # Fast OOM grep / Быстрый поиск OOM
```

4. Apply the least risky mitigation first.

```bash
sudo systemctl restart <SERVICE>            # Restart leaking service if safe / Перезапустить проблемный сервис если это безопасно
sudo sysctl vm.swappiness=10                # Reduce pressure to swap out active pages / Снизить склонность к swap для активных страниц
sudo swapon --show                          # Recheck active swap state / Повторно проверить состояние swap
```

5. Plan the durable fix.

- Increase RAM or VM size if the workload has genuinely outgrown the host
- Tune JVM, database, container, or application memory limits
- Consider zram for burst absorption on small hosts
- Investigate leaks before increasing swap indefinitely

> [!WARNING]
> Adding more swap can buy time, but it will not fix a memory leak or a host that is fundamentally undersized.

---

## Additional Notes

### Naming Conventions / Именование

| Path | Typical Usage / Типичное использование |
|------|----------------------------------------|
| `/swapfile` | Common default on Ubuntu and Debian |
| `/swap.img` | Common on cloud images or custom builds |

### Swap Sizing Guide / Рекомендации по размеру

| RAM | Swap | Notes / Примечание |
|-----|------|--------------------|
| `<= 8 GiB` | `4-8 GiB` | Small VPS and general-purpose hosts |
| `8-16 GiB` | `2-6 GiB` | Enough for safety margin on many servers |
| `>= 16 GiB` | `2-4 GiB` | Often sufficient unless hibernation is required |

### Hibernation / Гибернация

For hibernation, swap should usually be at least as large as RAM, and resume configuration must also be correct for your distro and bootloader.

### Ubuntu and Distro Differences / Отличия Ubuntu и других дистрибутивов

- Ubuntu servers commonly use a swap file and rely on `systemd` + `procps`
- Some minimal cloud images ship without swap at all
- On systems without `rsyslog`, kernel messages may exist only in the journal, not in `/var/log/kern.log`
- zram is increasingly common on desktops and low-memory devices, but not always enabled by default on servers

### Modern Alternatives / Современные альтернативы

- **zram**: faster than disk swap, good for low-memory systems
- **zswap**: reduces disk writes when real swap already exists
- **More RAM**: still the correct long-term fix for sustained swap pressure

---

## Documentation

- [Ubuntu Swap FAQ](https://help.ubuntu.com/community/SwapFaq)
- [Linux kernel VM sysctl documentation](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html)
- [swapon(8) manual](https://man7.org/linux/man-pages/man8/swapon.8.html)
- [fstab(5) manual](https://man7.org/linux/man-pages/man5/fstab.5.html)
- [systemd-zram-generator project](https://github.com/systemd/zram-generator)

```bash
man swapon                                  # Local manual for swapon / Локальная man-страница swapon
man mkswap                                  # Local manual for mkswap / Локальная man-страница mkswap
man sysctl                                  # Local manual for sysctl / Локальная man-страница sysctl
```
