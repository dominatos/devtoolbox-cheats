Title: 💿 LVM — Basics
Group: Storage & FS
Icon: 💿
Order: 1

# LVM — Logical Volume Manager

Comprehensive guide to LVM management: physical volumes, volume groups, logical volumes, and filesystem operations.

## Table of Contents
- [Quick Start](#quick-start)
- [Status & Diagnostics](#status--diagnostics)
- [Adding a New Disk](#adding-a-new-disk)
- [Adding Disk to LVM](#adding-disk-to-lvm)
- [Extending LV & Filesystem](#extending-lv--filesystem)
- [Formatting & Mounting](#formatting--mounting)
- [Removing Disk from LVM](#removing-disk-from-lvm)
- [Creating New LVM from Scratch](#creating-new-lvm-from-scratch)
- [Filesystem Check & Repair](#filesystem-check--repair)
- [Useful Utilities](#useful-utilities)
- [Automation Script](#automation-script)
- [Error Recovery](#error-recovery)
- [Common Commands Reference](#common-commands-reference)

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

---

## Adding a New Disk / Добавление нового диска

```bash
lsblk                                   # List all block devices / Проверить наличие нового диска
sudo parted /dev/sdd -- mklabel gpt     # Create GPT partition table / Создать таблицу GPT
sudo parted /dev/sdd -- mkpart primary 0% 100%  # Create full-size partition / Создать раздел на весь диск
lsblk /dev/sdd                          # Verify partition exists / Убедиться, что появился /dev/sdd1
```

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
> This script auto-detects disks — always verify `$NEW_DISK` before running in production.
> Этот скрипт автоматически определяет диски — всегда проверяйте `$NEW_DISK` перед запуском в продакшене.

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

*End of LVM Cheat Sheet*
