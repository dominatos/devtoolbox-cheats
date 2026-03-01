Title: 🗄️ Veritas InfoScale — Storage Foundation
Group: Backups & S3
Icon: 🗄️
Order: 8

> **Context:** Veritas InfoScale (formerly Storage Foundation) provides enterprise-grade HA storage management, clustering, and disaster recovery for Linux and Unix systems.
> - **VxVM (Veritas Volume Manager):** Manages physical disks, disk groups, volumes, mirrors.
> - **VxFS (Veritas File System):** Online-resizable filesystem with integrated snapshot support.
> - **Role:** Storage Admin / Sysadmin

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [VxVM — Volume Manager](#vxvm--volume-manager)
- [VxFS — Filesystem](#vxfs--filesystem)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Component Summary / Компоненты

| Component | Full Name | Function |
|-----------|-----------|----------|
| **VxVM** | Veritas Volume Manager | Disk, DG, volume management |
| **VxFS** | Veritas File System | Online-resizable FS with snapshots |
| **VCS** | Veritas Cluster Server | HA clustering (part of InfoScale HA/Enterprise) |
| **DMP** | Dynamic Multi-Pathing | Multipath I/O failover |

---

## VxVM — Volume Manager

### Disk Management (vxdisk) / Управление дисками

```bash
vxdisk list                                     # List all disks / Список дисков
vxdisk -o alldgs list                           # Disks mapped to DGs / Диски в DG
vxdisksetup -i <DEVICE>                         # Initialize disk for VxVM / Инициализировать диск
```

### Disk Groups (vxdg) / Дисковые группы

```bash
# Create Disk Group / Создать Disk Group
vxdg init <DG_NAME> <DISK_NAME>=<DEVICE>

# Add disk to existing DG / Добавить диск в существующий DG
vxdg -g <DG_NAME> adddisk <DISK_NAME>=<DEVICE>

# Import / Deport DG / Импортировать / Деимпортировать DG
vxdg import <DG_NAME>                           # Import (bring online) / Импортировать
vxdg deport <DG_NAME>                           # Deport (take offline) / Деимпортировать

# List all DGs / Список всех DG
vxdg list
```

> [!WARNING]
> Deporting a DG takes all volumes in that group offline. Ensure no applications are using them before deporting.

### Volumes (vxassist) / Тома

```bash
# Create volume / Создать том
vxassist -g <DG_NAME> make <VOL_NAME> 10g

# Create mirrored volume / Создать зеркальный том
vxassist -g <DG_NAME> make <VOL_NAME> 10g layout=mirror

# Grow volume online / Увеличить том онлайн
vxassist -g <DG_NAME> growto <VOL_NAME> 20g

# Shrink volume (filesystem must be shrunk first) / Уменьшить том
vxassist -g <DG_NAME> shrinkto <VOL_NAME> 8g

# Add mirror to existing volume / Добавить зеркало
vxassist -g <DG_NAME> mirror <VOL_NAME>

# Remove mirror / Удалить зеркало
vxassist -g <DG_NAME> remove mirror <VOL_NAME>
```

### Volume States / Состояния томов

```bash
vxprint -ht                                     # Hierarchy view (all objects) / Иерархия всех объектов
vxprint -g <DG_NAME> -v                         # Volumes in DG / Тома в DG
```

| State | Meaning |
|-------|---------|
| `ENABLED` | Online and healthy / Онлайн и исправен |
| `DISABLED` | Offline / Офлайн |
| `DEGRADED` | Mirror member missing / Зеркало неполное |
| `FAILED` | I/O error / Ошибка ввода-вывода |

### Device Paths / Пути устройств

```bash
/dev/vx/dsk/<DG>/<VOL>    # Block device / Блочное устройство
/dev/vx/rdsk/<DG>/<VOL>   # Raw device (for mkfs) / Сырое устройство (для mkfs)
```

---

## VxFS — Filesystem

### Create & Mount / Создать и смонтировать

```bash
# Create VxFS filesystem / Создать файловую систему VxFS
mkfs -t vxfs /dev/vx/rdsk/<DG>/<VOL>

# Mount / Смонтировать
mount -t vxfs /dev/vx/dsk/<DG>/<VOL> /mnt/point

# Add to /etc/fstab / Добавить в /etc/fstab
echo "/dev/vx/dsk/<DG>/<VOL>  /mnt/point  vxfs  defaults  0 0" >> /etc/fstab
```

### Online Resize / Изменить размер онлайн

> [!TIP]
> VxFS supports online resize (grow/shrink) without unmounting — a major advantage in production environments.

```bash
# Grow volume + filesystem together / Увеличить том и ФС одновременно
vxassist -g <DG_NAME> growto <VOL_NAME> 20g
fsadm -F vxfs -b 20g /mnt/point                # Grow FS to 20 GB / Увеличить ФС до 20 ГБ

# Shrink — must shrink FS FIRST, then volume / Сначала ФС, потом том
fsadm -F vxfs -b 8g /mnt/point                 # Shrink FS / Уменьшить ФС
vxassist -g <DG_NAME> shrinkto <VOL_NAME> 8g   # Then shrink volume / Потом том
```

### Snapshot (VxFS-level) / Снапшот на уровне VxFS

```bash
# Create snapshot volume (same DG) / Создать снапшот-том
vxassist -g <DG_NAME> make <SNAP_VOL> 2g layout=mirror

# Mount snapshot / Смонтировать снапшот
mount -t vxfs -o snapof=/mnt/point \
  /dev/vx/dsk/<DG>/<SNAP_VOL> /mnt/snap

# List snapshots / Список снапшотов
fsadm -S info /mnt/point

# Remove snapshot / Удалить снапшот
umount /mnt/snap
vxedit -g <DG_NAME> rm <SNAP_VOL>
```

### Filesystem Info / Информация о ФС

```bash
df -h /mnt/point                                # Size and usage / Размер и использование
fsadm -F vxfs -i /mnt/point                    # VxFS info / Информация VxFS
fsck -t vxfs /dev/vx/rdsk/<DG>/<VOL>           # Filesystem check (unmounted) / Проверить ФС
```

---

## Sysadmin Operations

### Service Management / Управление сервисами

```bash
systemctl status vxvm-boot                      # VxVM boot service / VxVM загрузка
systemctl status vxfs                           # VxFS mount service / VxFS монтирование
/etc/init.d/vxvm-boot start                     # Start VxVM boot services / Запустить
```

### VxVM Daemon / Демон VxVM

```bash
vxconfigd start                                 # Start VxVM config daemon / Запустить демон
vxconfigd stop                                  # Stop / Остановить
vxconfigd -m enable                             # Start enabled / Запустить включенным
```

### Log Locations / Пути логов

```bash
/var/adm/messages          # System messages (Solaris legacy) / Системные сообщения
/var/log/messages          # System messages (Linux) / Системные сообщения
/var/vx/vxdmp.log          # DMP multipath log / Лог многопутевания DMP
/var/adm/vx/                # VxVM messages / Сообщения VxVM
```

---

## Troubleshooting

### Status Commands / Команды статуса

```bash
vxprint -ht                                     # Full object hierarchy / Полная иерархия
vxdisk -o alldgs list                           # All disk → DG mapping / Карта дисков к DG
vxprint -g <DG_NAME> -ht                        # Hierarchy for specific DG / Иерархия DG
vxprint -g <DG_NAME> -v                         # Volume details / Детали томов
```

### Disk & Volume Errors / Ошибки дисков и томов

```bash
# Check for failed disks / Проверить неисправные диски
vxdisk list | grep -i fail

# Recover a failed subdisk / Восстановить неисправный subdisk
vxrecover -g <DG_NAME>

# Rescan disks (after adding hardware) / Пересканировать диски
vxdctl enable
```

### DMP (Multipathing) / Многопутевание DMP

```bash
vxdmpadm listctlr all                           # List HBA controllers / Список HBA
vxdmpadm getsubpaths dmpnodename=<DEVICE>       # List paths for device / Пути устройства
vxdmpadm enable controller=<CTL>               # Enable path / Включить путь
vxdmpadm disable controller=<CTL>              # Disable path / Отключить путь
```

### Common Fixes / Типичные решения

```bash
# DG not importing (disk DAEMONIZED state) / DG не импортируется
vxdg import -f <DG_NAME>                        # Force import / Принудительный импорт

# Volume in DISABLED state / Том в состоянии DISABLED
vxvol -g <DG_NAME> start <VOL_NAME>             # Start volume / Запустить том

# Stale NFS mounts preventing deport / Устаревшие NFS монтирования
umount -f -l /mnt/point                         # Force unmount / Принудительное размонтирование
```
