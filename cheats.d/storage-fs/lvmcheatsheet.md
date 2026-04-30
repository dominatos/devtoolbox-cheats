Title: 💿 LVM — Basics
Group: Storage & FS
Icon: 💿
Order: 1

# LVM — Logical Volume Manager

**LVM (Logical Volume Manager)** is a device mapper framework that provides logical volume management for the Linux kernel. It adds an abstraction layer between physical storage devices and filesystems, enabling flexible disk management without downtime.

LVM introduces three abstraction layers:
- **PV (Physical Volume)** — a physical disk or partition initialized for LVM
- **VG (Volume Group)** — a pool of storage composed of one or more PVs
- **LV (Logical Volume)** — a virtual partition carved from a VG, on which you create a filesystem

**Why LVM matters / Зачем нужен LVM:**
- **Online resizing** — grow or shrink logical volumes without unmounting
- **Disk aggregation** — combine multiple physical disks into one logical pool
- **Snapshots** — create point-in-time copies for backups or testing  
- **Thin provisioning** — allocate storage on demand
- **Migration** — move data between physical disks transparently (`pvmove`)

LVM is the default storage layout for RHEL/CentOS/Fedora and Ubuntu Server installations. It is part of the `lvm2` package and uses the device-mapper kernel module.

📚 **Official Docs / Официальная документация:**
[lvm(8)](https://man7.org/linux/man-pages/man8/lvm.8.html) · [pvcreate(8)](https://man7.org/linux/man-pages/man8/pvcreate.8.html) · [vgcreate(8)](https://man7.org/linux/man-pages/man8/vgcreate.8.html) · [lvcreate(8)](https://man7.org/linux/man-pages/man8/lvcreate.8.html) · [lvextend(8)](https://man7.org/linux/man-pages/man8/lvextend.8.html)

## Table of Contents
- [Quick Start](#quick-start)
- [Status & Diagnostics](#status--diagnostics)
- [Adding a New Disk](#adding-a-new-disk)
- [Adding Disk to LVM](#adding-disk-to-lvm)
- [Extending LV & Filesystem](#extending-lv--filesystem)
- [Formatting & Mounting](#formatting--mounting)
- [LVM Snapshots](#lvm-snapshots)
- [Thin Provisioning](#thin-provisioning)
- [Removing Disk from LVM](#removing-disk-from-lvm)
- [Creating New LVM from Scratch](#creating-new-lvm-from-scratch)
- [Filesystem Check & Repair](#filesystem-check--repair)
- [Useful Utilities](#useful-utilities)
- [Automation Script](#automation-script)
- [Error Recovery](#error-recovery)
- [Common Commands Reference](#common-commands-reference)
- [LVM Architecture Comparison](#lvm-architecture-comparison)

---

## Quick Start

```bash
sudo pvcreate /dev/sdb                          # Initialize physical volume / Инициализировать PV
sudo vgcreate vg0 /dev/sdb                      # Create volume group / Создать VG
sudo lvcreate -n data -L 20G vg0                # Create logical volume / Создать LV
sudo mkfs.ext4 /dev/vg0/data                    # Make EXT4 filesystem / Создать ФС EXT4
sudo mkdir -p /data && sudo mount /dev/vg0/data /data  # Mount volume / Смонтировать том
sudo lvextend -r -L +10G /dev/vg0/data          # Extend LV and FS / Увеличить LV и ФС
```

---

## Status & Diagnostics / Проверка состояния дисков и LVM

```bash
lsblk -f                  # Show block device tree with FS / Показать дерево устройств с ФС
blkid                     # Show filesystem UUIDs and types / Вывести UUID и тип ФС
df -h                     # Human-readable disk usage / Использование дисков в читаемом виде
du -sh <MOUNT_POINT>/*    # Size of each subdirectory / Размер каждой папки
pvs                       # List physical volumes / Список физических томов
vgs                       # List volume groups / Список групп томов
lvs                       # List logical volumes / Список логических томов
lvdisplay                 # Detailed logical volume info / Подробности LV
vgdisplay                 # Detailed volume group info / Подробности VG
pvdisplay                 # Detailed physical volume info / Подробности PV
```

**Sample `pvs` output / Пример вывода `pvs`:**
```
  PV         VG   Fmt  Attr PSize   PFree
  /dev/sda2  vg0  lvm2 a--  <50.00g    0
  /dev/sdb1  vg0  lvm2 a--  100.00g 30.00g
```

---

## Adding a New Disk / Добавление нового диска

```bash
lsblk                                   # List all block devices / Проверить наличие нового диска
sudo parted /dev/sdd -- mklabel gpt     # Create GPT partition table / Создать таблицу GPT
sudo parted /dev/sdd -- mkpart primary 0% 100%  # Create full-size partition / Создать раздел на весь диск
lsblk /dev/sdd                          # Verify partition exists / Убедиться, что появился /dev/sdd1
```

> [!TIP]
> You can also use the whole disk as a PV without partitioning (`pvcreate /dev/sdd`), but partitioning is recommended as it makes it clearer that the disk is in use by LVM.
> Можно использовать весь диск как PV без разметки (`pvcreate /dev/sdd`), но разметка рекомендуется — она делает очевидным, что диск используется LVM.

---

## Adding Disk to LVM / Добавление диска в LVM

```bash
sudo pvcreate /dev/sdd1         # Create physical volume / Создать физический том
sudo vgextend <VG_NAME> /dev/sdd1  # Add PV to existing VG / Добавить PV в группу
sudo vgs                        # Verify VG extended / Проверить, что добавилось
```

---

## Extending LV & Filesystem / Расширение логического тома и файловой системы

```bash
sudo lvextend -l +100%FREE /dev/<VG_NAME>/<LV_NAME>   # Extend LV to all free space / Увеличить LV на всё свободное место
sudo xfs_growfs <MOUNT_POINT>                          # Grow XFS filesystem online / Расширить XFS онлайн
sudo resize2fs /dev/<VG_NAME>/<LV_NAME>                # Resize EXT4 filesystem / Расширить EXT4
df -h <MOUNT_POINT>                                    # Verify final size / Проверить итоговый размер
```

> [!TIP]
> Use `lvextend -r` to automatically resize the filesystem along with the LV in a single command.
> Используйте `lvextend -r` для автоматического изменения размера ФС вместе с LV одной командой.

---

## Formatting & Mounting / Форматирование и монтирование

```bash
sudo mkfs.xfs /dev/<VG_NAME>/<LV_NAME>          # Make XFS filesystem / Создать XFS файловую систему
sudo mount /dev/<VG_NAME>/<LV_NAME> /mnt/test    # Mount manually / Смонтировать вручную
sudo nano /etc/fstab                              # Edit fstab for auto-mount / Добавить строку для автомонтирования
sudo mount -a                                     # Test all mounts / Проверить корректность fstab
```

### fstab Entry Example / Пример записи в fstab
`/etc/fstab`

```bash
/dev/<VG_NAME>/<LV_NAME>  <MOUNT_POINT>  xfs  defaults  0  0
```

> [!TIP]
> For LVM volumes, you can use either the device path (`/dev/vg0/data`) or the device mapper path (`/dev/mapper/vg0-data`). Both point to the same device.
> Для томов LVM можно использовать как путь устройства (`/dev/vg0/data`), так и путь device mapper (`/dev/mapper/vg0-data`). Оба указывают на одно устройство.

---

## LVM Snapshots / Снапшоты LVM

LVM snapshots create a point-in-time copy of a logical volume using Copy-on-Write (CoW).
Снапшоты LVM создают копию логического тома на определённый момент времени с помощью Copy-on-Write (CoW).

```bash
# Create a snapshot / Создать снапшот
sudo lvcreate -L 5G -s -n data_snap /dev/vg0/data

# List snapshots / Список снапшотов
sudo lvs -o +snap_percent

# Mount snapshot for backup / Смонтировать снапшот для бэкапа
sudo mount -o ro /dev/vg0/data_snap /mnt/snap

# Remove snapshot / Удалить снапшот
sudo lvremove /dev/vg0/data_snap
```

> [!WARNING]
> If a snapshot fills up (100% used), it becomes **invalid** and the data is lost. Always allocate enough space and monitor with `lvs -o +snap_percent`.
> Если снапшот заполнится (100%), он становится **недействительным** и данные теряются. Выделяйте достаточно места и мониторьте с помощью `lvs -o +snap_percent`.

> [!CAUTION]
> Snapshots **degrade write performance** on the original volume because every changed block must be copied before modification. Remove snapshots after use.
> Снапшоты **ухудшают производительность записи** на исходном томе, т.к. каждый изменённый блок копируется перед модификацией. Удаляйте снапшоты после использования.

---

## Thin Provisioning / Тонкое выделение

Thin provisioning allows you to allocate more storage than physically available, with space allocated on demand.
Тонкое выделение позволяет выделить больше хранилища, чем физически доступно, с распределением по мере необходимости.

```bash
# Create thin pool / Создать тонкий пул
sudo lvcreate -L 50G -T vg0/thinpool

# Create thin volume (can exceed pool size) / Создать тонкий том
sudo lvcreate -V 100G -T vg0/thinpool -n thinvol

# Check thin pool usage / Проверить использование пула
sudo lvs -o +data_percent,metadata_percent
```

> [!WARNING]
> If a thin pool fills up completely, all thin volumes become read-only. Monitor thin pool usage closely and extend the pool before it reaches 80%.
> Если тонкий пул заполнится полностью, все тонкие тома переходят в режим только для чтения. Мониторьте использование пула и расширяйте до достижения 80%.

---

## Removing Disk from LVM / Удаление диска из LVM

> [!CAUTION]
> `pvmove` migrates data off a PV — this can take a long time on large volumes. `vgreduce` permanently removes a PV from a VG. Ensure data is migrated before removing.
> `pvmove` переносит данные с PV — это может занять длительное время. `vgreduce` безвозвратно удаляет PV из VG. Убедитесь, что данные перенесены.

```bash
sudo lvs -a -o +devices             # Show which PVs LV uses / Показать, на каких дисках LV
sudo pvmove /dev/sdd1               # Move data off PV / Перенести данные с PV
sudo vgreduce <VG_NAME> /dev/sdd1   # Remove PV from VG / Удалить PV из VG
sudo pvremove /dev/sdd1             # Wipe LVM metadata / Удалить LVM метки
```

---

## Creating New LVM from Scratch / Создание нового LVM с нуля

```bash
sudo pvcreate /dev/sdd1                              # Create PV / Создать PV
sudo vgcreate backup-vg /dev/sdd1                    # Create VG / Создать VG
sudo lvcreate -L 500G -n backup backup-vg            # Create 500G LV / Создать LV 500ГБ
sudo mkfs.xfs /dev/backup-vg/backup                  # Make XFS filesystem / Создать ФС XFS
sudo mkdir /mnt/backup                               # Create mount point / Создать точку монтирования
sudo mount /dev/backup-vg/backup /mnt/backup         # Mount filesystem / Смонтировать
```

---

## Filesystem Check & Repair / Проверка и ремонт файловой системы

> [!WARNING]
> Filesystem must be unmounted before running `e2fsck` or `xfs_repair`. Running on a mounted FS can cause data corruption.
> Файловая система должна быть размонтирована перед `e2fsck` или `xfs_repair`. Работа на смонтированной ФС может повредить данные.

```bash
sudo e2fsck -f /dev/<VG_NAME>/<LV_NAME>    # Check and fix EXT4 / Проверка EXT4
sudo xfs_repair /dev/<VG_NAME>/<LV_NAME>   # Repair XFS (requires unmount) / Ремонт XFS (требует размонтирования)
```

---

## Useful Utilities / Полезные утилиты

```bash
lsblk -e7 -o NAME,SIZE,FSTYPE,MOUNTPOINT   # Clean block device list / Чистый вывод устройств
udevadm info --query=all --name=/dev/sdd    # Detailed device info / Инфо о диске
smartctl -a /dev/sdd                        # SMART disk health check / SMART-диагностика
lvmconf --list                              # List LVM configurations / Показать конфиги LVM
lvscan                                      # Scan for logical volumes / Найти все LV
vgscan                                      # Scan for volume groups / Найти все VG
pvscan                                      # Scan for physical volumes / Найти все PV
dmsetup ls                                  # List device-mapper devices / Список устройств device-mapper
```

---

## Automation Script / Автоматизация — expand_data_storage.sh

```bash
#!/bin/bash
# Auto-extend LVM storage / Авто-добавление нового диска в VG и расширение ФС

NEW_DISK=$(lsblk -ndo NAME,TYPE | awk '$2=="disk" && $1!="sda" && $1!="sdb" && $1!="sdc"{print "/dev/"$1; exit}')
if [ -z "$NEW_DISK" ]; then
  echo "No new disk detected!"  # No new disk found / Если нет новых дисков
  exit 1
fi

echo "Using $NEW_DISK ..."                                   # Show found disk / Вывести имя найденного диска
parted $NEW_DISK -- mklabel gpt mkpart primary 0% 100%      # Create GPT and partition / Создать GPT и раздел
pvcreate ${NEW_DISK}1                                        # Create PV / Создать PV
vgextend <VG_NAME> ${NEW_DISK}1                              # Extend VG / Добавить в группу
lvextend -l +100%FREE /dev/<VG_NAME>/<LV_NAME>               # Extend LV / Расширить LV
xfs_growfs <MOUNT_POINT>                                     # Grow filesystem / Расширить ФС
df -h <MOUNT_POINT>                                          # Check result / Проверить результат
```

> [!CAUTION]
> This script auto-detects disks — always verify `$NEW_DISK` before running in production. Consider adding a confirmation prompt.
> Этот скрипт автоматически определяет диски — всегда проверяйте `$NEW_DISK` перед запуском в продакшене. Рассмотрите добавление запроса подтверждения.

---

## Error Recovery / Восстановление при ошибках

```bash
sudo vgcfgbackup                          # Backup LVM metadata / Создать резервную копию метаданных
sudo vgcfgrestore <VG_NAME>               # Restore VG metadata / Восстановить метаданные
sudo vgreduce --removemissing <VG_NAME>   # Remove missing PVs from VG / Удалить отсутствующие диски
sudo partprobe                            # Refresh partition table / Обновить таблицу разделов
sudo rescan-scsi-bus.sh                   # Rescan SCSI bus / Пересканировать устройства
sudo vgchange -ay                         # Activate all VGs / Активировать все группы томов
```

> [!NOTE]
> LVM automatically backs up metadata to `/etc/lvm/backup/` and archives to `/etc/lvm/archive/`. These backups are your lifeline for recovery.
> LVM автоматически создаёт резервные копии метаданных в `/etc/lvm/backup/` и архивы в `/etc/lvm/archive/`. Эти копии — ваш спасательный круг.

### Default LVM Paths / Пути по умолчанию LVM

| Path | Purpose (EN) | Назначение (RU) |
| :--- | :--- | :--- |
| `/etc/lvm/lvm.conf` | Main LVM configuration | Основная конфигурация LVM |
| `/etc/lvm/backup/` | VG metadata backups | Резервные копии метаданных VG |
| `/etc/lvm/archive/` | VG metadata archive | Архив метаданных VG |
| `/dev/mapper/` | Device-mapper device nodes | Узлы устройств device-mapper |
| `/dev/<VG_NAME>/` | LV device symlinks | Символические ссылки на LV |

---

## Common Commands Reference / Часто используемые команды

```bash
lvs                                        # List logical volumes / Показать логические тома
vgs                                        # List volume groups / Показать группы томов
pvs                                        # List physical volumes / Показать физические тома
pvcreate /dev/sdX                          # Create PV / Создать физический том
vgextend <VG_NAME> /dev/sdX               # Extend VG with new PV / Добавить PV в VG
lvextend -l +100%FREE /dev/<VG_NAME>/<LV_NAME>  # Extend LV / Увеличить LV
xfs_growfs <MOUNT_POINT>                   # Grow XFS filesystem / Расширить XFS
df -h                                      # Check filesystem usage / Проверить использование
xfs_info <MOUNT_POINT>                     # Show XFS info / Инфо о XFS
pvmove /dev/sdX                            # Move data off PV / Перенести данные с PV
vgreduce <VG_NAME> /dev/sdX               # Remove PV from VG / Удалить диск из VG
vgcreate <VG_NAME> /dev/sdX               # Create new VG / Создать новую VG
lvcreate -L 500G -n <LV_NAME> <VG_NAME>   # Create LV / Создать LV
smartctl -a /dev/sdX                       # Check disk SMART health / Проверить SMART
```

---

## LVM Architecture Comparison / Сравнение архитектур хранения

| Feature | Traditional Partitions | LVM | ZFS |
| :--- | :--- | :--- | :--- |
| **Online resize** | ❌ No | ✅ Yes | ✅ Yes |
| **Snapshots** | ❌ No | ✅ Yes (CoW) | ✅ Yes (native) |
| **Disk aggregation** | ❌ No | ✅ Yes (VG) | ✅ Yes (zpool) |
| **Thin provisioning** | ❌ No | ✅ Yes | ✅ Yes |
| **RAID support** | ❌ Needs mdadm | ⚠️ Limited (lvmraid) | ✅ Native (RAID-Z) |
| **Checksumming** | ❌ No | ❌ No | ✅ Yes |
| **Complexity** | Low | Medium | High |
| **Default in** | Desktop installs | Server installs | FreeBSD, Oracle |

---

## Documentation Links

- **LVM Administrator Guide (Red Hat):** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/index
- **lvm(8):** https://man7.org/linux/man-pages/man8/lvm.8.html
- **pvcreate(8):** https://man7.org/linux/man-pages/man8/pvcreate.8.html
- **vgcreate(8):** https://man7.org/linux/man-pages/man8/vgcreate.8.html
- **lvcreate(8):** https://man7.org/linux/man-pages/man8/lvcreate.8.html
- **lvextend(8):** https://man7.org/linux/man-pages/man8/lvextend.8.html
- **ArchWiki — LVM:** https://wiki.archlinux.org/title/LVM
- **Ubuntu — LVM Guide:** https://ubuntu.com/server/docs/about-logical-volume-management-lvm
