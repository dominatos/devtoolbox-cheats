---
Title: 🗄️ Veritas InfoScale — Storage Foundation
Group: "Backups & S3"
Icon: 🗄️
Order: 8
tags:
  - backups
  - s3
  - sysadmin
  - linux
---

> **Veritas InfoScale** (formerly Storage Foundation) provides enterprise-grade HA storage management, clustering, and disaster recovery for Linux and Unix systems. Key components include **VxVM** (Volume Manager) for disk, volume, and mirror management, and **VxFS** (File System) for online-resizable filesystems with integrated snapshot support. InfoScale is a legacy enterprise product; modern alternatives include **LVM + ext4/XFS** (built into Linux), **ZFS**, and **Btrfs** for volume/filesystem management.
> / **Veritas InfoScale** (ранее Storage Foundation) — корпоративная платформа управления хранилищем, кластеризации и аварийного восстановления. Включает **VxVM** (Volume Manager) и **VxFS** (File System). Современные альтернативы: **LVM + ext4/XFS**, **ZFS**, **Btrfs**.

## Table of Contents

- [Architecture Overview](#Architecture%20Overview)
- [VxVM — Volume Manager](#VxVM%20—%20Volume%20Manager)
- [VxFS — Filesystem](#VxFS%20—%20Filesystem)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Troubleshooting](#Troubleshooting)
- [Documentation](#Documentation)

---

## Architecture Overview

### Component Summary

| Component | Full Name | Function |
|-----------|-----------|----------|
| **VxVM** | Veritas Volume Manager | Disk, DG, volume management |
| **VxFS** | Veritas File System | Online-resizable FS with snapshots |
| **VCS** | Veritas Cluster Server | HA clustering (part of InfoScale HA/Enterprise) |
| **DMP** | Dynamic Multi-Pathing | Multipath I/O failover |

---

## VxVM — Volume Manager

### Disk Management (vxdisk)

```bash
vxdisk list                                     # List all disks / Список дисков
vxdisk -o alldgs list                           # Disks mapped to DGs / Диски в DG
vxdisksetup -i <DEVICE>                         # Initialize disk for VxVM / Инициализировать диск
```

### Disk Groups (vxdg)

```bash
# Create Disk Group
vxdg init <DG_NAME> <DISK_NAME>=<DEVICE>

# Add disk to existing DG
vxdg -g <DG_NAME> adddisk <DISK_NAME>=<DEVICE>

# Import / Deport DG
vxdg import <DG_NAME>                           # Import (bring online) / Импортировать
vxdg deport <DG_NAME>                           # Deport (take offline) / Деимпортировать

# List all DGs
vxdg list
```

> [!WARNING]
> Deporting a DG takes all volumes in that group offline. Ensure no applications are using them before deporting.

### Volumes (vxassist)

```bash
# Create volume
vxassist -g <DG_NAME> make <VOL_NAME> 10g

# Create mirrored volume
vxassist -g <DG_NAME> make <VOL_NAME> 10g layout=mirror

# Grow volume online
vxassist -g <DG_NAME> growto <VOL_NAME> 20g

# Shrink volume (filesystem must be shrunk first)
vxassist -g <DG_NAME> shrinkto <VOL_NAME> 8g

# Add mirror to existing volume
vxassist -g <DG_NAME> mirror <VOL_NAME>

# Remove mirror
vxassist -g <DG_NAME> remove mirror <VOL_NAME>
```

### Volume States

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

### Device Paths

```bash
/dev/vx/dsk/<DG>/<VOL>    # Block device / Блочное устройство
/dev/vx/rdsk/<DG>/<VOL>   # Raw device (for mkfs) / Сырое устройство (для mkfs)
```

---

## VxFS — Filesystem

### Create & Mount

```bash
# Create VxFS filesystem
mkfs -t vxfs /dev/vx/rdsk/<DG>/<VOL>

# Mount
mount -t vxfs /dev/vx/dsk/<DG>/<VOL> /mnt/point

# Add to /etc/fstab
echo "/dev/vx/dsk/<DG>/<VOL>  /mnt/point  vxfs  defaults  0 0" >> /etc/fstab
```

### Online Resize

> [!TIP]
> VxFS supports online resize (grow/shrink) without unmounting — a major advantage in production environments.

```bash
# Grow volume + filesystem together
vxassist -g <DG_NAME> growto <VOL_NAME> 20g
fsadm -F vxfs -b 20g /mnt/point                # Grow FS to 20 GB / Увеличить ФС до 20 ГБ

# Shrink — must shrink FS FIRST, then volume
fsadm -F vxfs -b 8g /mnt/point                 # Shrink FS / Уменьшить ФС
vxassist -g <DG_NAME> shrinkto <VOL_NAME> 8g   # Then shrink volume / Потом том
```

### Snapshot (VxFS-level)

```bash
# Create snapshot volume (same DG)
vxassist -g <DG_NAME> make <SNAP_VOL> 2g layout=mirror

# Mount snapshot
mount -t vxfs -o snapof=/mnt/point \
  /dev/vx/dsk/<DG>/<SNAP_VOL> /mnt/snap

# List snapshots
fsadm -S info /mnt/point

# Remove snapshot
umount /mnt/snap
vxedit -g <DG_NAME> rm <SNAP_VOL>
```

### Filesystem Info

```bash
df -h /mnt/point                                # Size and usage / Размер и использование
fsadm -F vxfs -i /mnt/point                    # VxFS info / Информация VxFS
fsck -t vxfs /dev/vx/rdsk/<DG>/<VOL>           # Filesystem check (unmounted) / Проверить ФС
```

---

## Sysadmin Operations

### Service Management

```bash
systemctl status vxvm-boot                      # VxVM boot service / VxVM загрузка
systemctl status vxfs                           # VxFS mount service / VxFS монтирование
/etc/init.d/vxvm-boot start                     # Start VxVM boot services / Запустить
```

### VxVM Daemon

```bash
vxconfigd start                                 # Start VxVM config daemon / Запустить демон
vxconfigd stop                                  # Stop / Остановить
vxconfigd -m enable                             # Start enabled / Запустить включенным
```

### Log Locations

```bash
/var/adm/messages          # System messages (Solaris legacy) / Системные сообщения
/var/log/messages          # System messages (Linux) / Системные сообщения
/var/vx/vxdmp.log          # DMP multipath log / Лог многопутевания DMP
/var/adm/vx/                # VxVM messages / Сообщения VxVM
```

### Logrotate / Logrotate

`/etc/logrotate.d/veritas`

```
/var/vx/*.log
/var/adm/vx/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Troubleshooting

### Status Commands

```bash
vxprint -ht                                     # Full object hierarchy / Полная иерархия
vxdisk -o alldgs list                           # All disk → DG mapping / Карта дисков к DG
vxprint -g <DG_NAME> -ht                        # Hierarchy for specific DG / Иерархия DG
vxprint -g <DG_NAME> -v                         # Volume details / Детали томов
```

### Disk & Volume Errors

```bash
# Check for failed disks
vxdisk list | grep -i fail

# Recover a failed subdisk
vxrecover -g <DG_NAME>

# Rescan disks (after adding hardware)
vxdctl enable
```

### DMP (Multipathing)

```bash
vxdmpadm listctlr all                           # List HBA controllers / Список HBA
vxdmpadm getsubpaths dmpnodename=<DEVICE>       # List paths for device / Пути устройства
vxdmpadm enable controller=<CTL>               # Enable path / Включить путь
vxdmpadm disable controller=<CTL>              # Disable path / Отключить путь
```

### Common Fixes

```bash
# DG not importing (disk DAEMONIZED state) / DG
vxdg import -f <DG_NAME>                        # Force import / Принудительный импорт

# Volume in DISABLED state
vxvol -g <DG_NAME> start <VOL_NAME>             # Start volume / Запустить том

# Stale NFS mounts preventing deport
umount -f -l /mnt/point                         # Force unmount / Принудительное размонтирование
```

## Documentation

- **Veritas NetBackup Documentation:** https://www.veritas.com/support/en_US.html
