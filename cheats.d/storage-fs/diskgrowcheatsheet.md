---
Title: 💿 Disk Growth — Cloud/VM Expansion
Group: "Storage & FS"
Icon: 💿
Order: 3
tags:
  - storage
  - filesystem
  - sysadmin
  - linux
---

# Disk Growth — Cloud/VM Expansion

**Disk growth (online disk expansion)** is the process of increasing disk, partition, and filesystem sizes on running systems — typically in cloud VMs, hypervisors, or bare-metal servers. This is one of the most common sysadmin operations in cloud environments where storage needs grow dynamically.

The workflow follows a strict layer-by-layer approach: **disk → partition → (LVM) → filesystem**. Each layer must be expanded in order. Skipping a layer (e.g., trying to resize a filesystem without growing the partition first) will fail.

**Key tools / Основные инструменты:**
- `growpart` — automatically grows a partition to fill available space
- `resize2fs` — resizes ext2/ext3/ext4 filesystems
- `xfs_growfs` — grows XFS filesystems (grow only, no shrink)
- `pvresize` / `lvextend` — LVM physical and logical volume management
- `parted` — manual partition management

📚 **Official Docs / Официальная документация:**
[growpart(1)](https://manpages.debian.org/testing/cloud-guest-utils/growpart.1.en.html) · [resize2fs(8)](https://man7.org/linux/man-pages/man8/resize2fs.8.html) · [xfs_growfs(8)](https://man7.org/linux/man-pages/man8/xfs_growfs.8.html) · [parted(8)](https://man7.org/linux/man-pages/man8/parted.8.html)

## Table of Contents

- [Partition Growth](#Partition%20Growth)
- [Filesystem Expansion](#Filesystem%20Expansion)
- [LVM Growth](#LVM%20Growth)
- [Cloud Providers](#Cloud%20Providers)
- [Troubleshooting](#Troubleshooting)
- [Real-World Examples](#Real-World%20Examples)
- [Best Practices](#Best%20Practices)
- [Filesystem Resize Comparison](#Filesystem%20Resize%20Comparison)
- [Typical Growth Workflow](#Typical%20Growth%20Workflow)
- [Documentation Links](#Documentation%20Links)

---

## Partition Growth

### Automatic Partition Resize

```bash
sudo growpart /dev/sda 1                      # Grow partition №1 / Расширить раздел №1
sudo growpart /dev/vda 1                      # Grow partition (KVM/QEMU) / Расширить раздел (KVM/QEMU)
sudo growpart /dev/nvme0n1 1                  # Grow NVMe partition / Расширить раздел NVMe
```

### Check Before Growth

```bash
lsblk                                         # List block devices / Список блочных устройств
df -h                                         # Check filesystem usage / Проверить использование ФС
sudo fdisk -l /dev/sda                        # Check partition table / Проверить таблицу разделов
sudo parted /dev/sda print                    # Alternative check / Альтернативная проверка
```

### Manual Partition Resize (parted)

```bash
sudo parted /dev/sda                          # Enter parted / Войти в parted
# (parted) print                              # Show partitions
# (parted) resizepart 1 100%                  # Resize to 100%
# (parted) quit                               # Exit
```

### Install growpart

```bash
sudo apt install cloud-guest-utils            # Debian/Ubuntu
sudo dnf install cloud-utils-growpart         # RHEL/Fedora/CentOS
sudo pacman -S cloud-guest-utils              # Arch Linux
```

---

## Filesystem Expansion

> [!CAUTION]
> Always create a backup or snapshot before resizing a filesystem. Data loss is possible if the operation is interrupted.
> Всегда создавайте резервную копию или снимок перед изменением размера ФС. Потеря данных возможна при прерывании операции.

### EXT2/EXT3/EXT4

```bash
sudo resize2fs /dev/sda1                      # Grow EXT4 / Увеличить EXT4
sudo resize2fs /dev/vda1                      # Grow EXT4 (KVM) / Увеличить EXT4 (KVM)
sudo e2fsck -f /dev/sda1                      # Check before resize / Проверить перед изменением
sudo resize2fs /dev/sda1 50G                  # Resize to specific size / Изменить до конкретного размера
```

### XFS

```bash
sudo xfs_growfs /mountpoint                   # Grow XFS / Увеличить XFS
sudo xfs_growfs /                             # Grow root XFS / Увеличить корневой XFS
sudo xfs_growfs -d /mnt/data                  # Grow data filesystem / Увеличить ФС данных
```

> [!WARNING]
> XFS can only be grown (not shrunk) and **must be mounted** during resize. EXT4 can be shrunk, but only when unmounted.
> XFS можно только увеличить (не уменьшить) и ФС **должна быть смонтирована** при изменении. EXT4 можно уменьшить, но только когда размонтирована.

### Btrfs

```bash
sudo btrfs filesystem resize max /mountpoint  # Grow Btrfs to max / Увеличить Btrfs до максимума
sudo btrfs filesystem resize +10G /mnt        # Grow by 10GB / Увеличить на 10GB
sudo btrfs filesystem resize 1:max /mnt       # Grow device 1 to max / Увеличить устройство 1 до максимума
```

### Check Filesystem Type

```bash
df -T                                         # Show filesystem types / Показать типы ФС
lsblk -f                                      # Show filesystems / Показать файловые системы
sudo blkid /dev/sda1                          # Show filesystem UUID and type / Показать UUID и тип ФС
```

---

## LVM Growth

### Extend Physical Volume

```bash
sudo pvresize /dev/sda2                       # Resize PV to use full disk / Изменить PV на весь диск
sudo pvs                                      # List PVs / Список PV
sudo pvdisplay /dev/sda2                      # Show PV details / Показать детали PV
```

### Extend Logical Volume

```bash
sudo lvextend -l +100%FREE /dev/vg0/lv_root   # Extend to use all free space / Расширить на всё свободное место
sudo lvextend -L +10G /dev/vg0/lv_data        # Extend by 10GB / Расширить на 10GB
sudo lvextend -L 50G /dev/vg0/lv_data         # Extend to 50GB total / Расширить до 50GB всего
sudo lvs                                      # List LVs / Список LV
```

### Resize Filesystem After LVM

```bash
sudo lvextend -r -l +100%FREE /dev/vg0/lv_root  # Extend and resize FS / Расширить и изменить ФС
sudo lvextend -L +10G /dev/vg0/lv_root && sudo resize2fs /dev/vg0/lv_root  # EXT4 manual / EXT4 вручную
sudo lvextend -L +10G /dev/vg0/lv_root && sudo xfs_growfs /mount  # XFS manual / XFS вручную
```

> [!TIP]
> Use `lvextend -r` to automatically resize the filesystem along with the LV — this is the safest and most convenient method.
> Используйте `lvextend -r` для автоматического изменения ФС вместе с LV — это самый безопасный и удобный метод.

### Complete LVM Workflow

```bash
# 1. Check current state
lsblk
df -h
sudo pvs
sudo vgs
sudo lvs

# 2. Grow partition
sudo growpart /dev/sda 2

# 3. Resize PV
sudo pvresize /dev/sda2

# 4. Extend LV and resize FS
sudo lvextend -r -l +100%FREE /dev/vg0/lv_root

# 5. Verify
df -h
```

---

## Cloud Providers

### AWS EC2

```bash
# After resizing EBS volume in AWS Console
lsblk
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1                     # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

> [!NOTE]
> AWS EBS volume modification can take several minutes. Monitor progress in EC2 console under "Volumes" → "State" column. The volume must be in `optimizing` or `completed` state before resizing on the OS level.
> Модификация тома EBS может занять несколько минут. Следите за прогрессом в консоли EC2.

### Google Cloud Platform (GCP)

```bash
# After resizing disk in GCP Console
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

### Azure

```bash
# After resizing disk in Azure Portal
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

> [!NOTE]
> Azure may require stopping and deallocating the VM before resizing the OS disk. Data disks can be resized while the VM is running.
> Azure может потребовать остановки и деаллокации ВМ перед изменением размера диска ОС.

### DigitalOcean

```bash
# After resizing droplet
lsblk
sudo growpart /dev/vda 1
sudo resize2fs /dev/vda1                      # For EXT4 / Для EXT4
```

### VMware / Proxmox

```bash
# After increasing disk size in hypervisor
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

---

## Troubleshooting

### Common Issues

```bash
# Check if partition table is GPT or MBR
sudo parted /dev/sda print

# Kernel not recognizing new size
sudo partprobe /dev/sda                       # Reread partition table / Перечитать таблицу разделов
sudo partx -u /dev/sda                        # Update kernel partition table / Обновить таблицу разделов ядра

# LVM not showing full size / LVM
sudo pvscan                                   # Scan for PVs / Сканировать PV
sudo vgscan                                   # Scan for VGs / Сканировать VG
sudo lvscan                                   # Scan for LVs / Сканировать LV
```

### "NOCHANGE" from growpart / growpart

```bash
# This means the partition already uses all available space
#
lsblk                                         # Verify disk size vs partition size / Проверить размер диска vs раздела

# If disk was resized but kernel doesn't see it:
#
echo 1 > /sys/class/block/sda/device/rescan   # Rescan SCSI device / Пересканировать SCSI устройство
```

### Verify Growth

```bash
# Before
lsblk
df -h

# After partition growth
lsblk

# After filesystem resize
df -h
```

### Filesystem Check

```bash
# EXT4 check
sudo e2fsck -f /dev/sda1

# XFS check
sudo xfs_repair /dev/sda1

# Btrfs check
sudo btrfs check /dev/sda1
```

---

## Real-World Examples

### Standard Cloud Growth (EXT4)

```bash
# 1. Resize disk in cloud console
# 2. SSH to server / SSH

# 3. Check current state
df -h
lsblk

# 4. Grow partition
sudo growpart /dev/sda 1

# 5. Resize filesystem
sudo resize2fs /dev/sda1

# 6. Verify
df -h
```

### LVM in Production / LVM

```bash
# Scenario: Root LV on LVM

# 1. Check state
sudo vgs
sudo lvs
df -h

# 2. Grow partition (if needed)
sudo growpart /dev/sda 2

# 3. Resize PV
sudo pvresize /dev/sda2

# 4. Extend LV with filesystem
sudo lvextend -r -l +100%FREE /dev/mapper/vg0-root

# 5. Verify
df -h
sudo lvs
```

### Add New Disk to LVM

```bash
# 1. Identify new disk
lsblk

# 2. Create PV
sudo pvcreate /dev/sdb

# 3. Extend VG
sudo vgextend vg0 /dev/sdb

# 4. Extend LV
sudo lvextend -l +100%FREE /dev/vg0/lv_data

# 5. Resize filesystem
sudo resize2fs /dev/vg0/lv_data              # EXT4
sudo xfs_growfs /mount                        # XFS
```

### Emergency Filesystem Recovery

```bash
# Boot into rescue mode

# Unmount filesystem
sudo umount /dev/sda1

# Check and repair
sudo e2fsck -f /dev/sda1                      # EXT4
sudo xfs_repair /dev/sda1                     # XFS

# Resize
sudo resize2fs /dev/sda1                      # EXT4
sudo mount /dev/sda1 /mnt && sudo xfs_growfs /mnt  # XFS

# Remount
sudo mount /dev/sda1 /
```

---

## Best Practices

> [!IMPORTANT]
> - Always **backup before resizing** — snapshots in cloud, LVM snapshots, or full backups.
> - Check filesystem integrity **before** resize with `e2fsck -f` or `xfs_repair`.
> - Use **LVM** for flexibility — it allows online resizing without rebooting.
> - Take **snapshots** in cloud before resize — they are your safety net.
> - **Document** growth operations — track disk changes for audit trails.
> - **Monitor** disk usage after resize with `df -h`.

> [!WARNING]
> - Never shrink XFS — it does not support shrinking at all.
> - Never run `e2fsck` on a mounted filesystem — it will corrupt data.
> - `growpart` requires free space **after** the target partition — if another partition follows, you must move or delete it first.

---

## Filesystem Resize Comparison

| Feature | EXT4 | XFS | Btrfs |
| :--- | :--- | :--- | :--- |
| **Grow online** | ✅ Yes / Да | ✅ Yes / Да | ✅ Yes / Да |
| **Shrink** | ✅ Offline only / Только offline | ❌ No / Нет | ✅ Online / Онлайн |
| **Must be mounted** | No for grow, unmount for shrink | **Yes** — must be mounted | No |
| **Resize command** | `resize2fs` | `xfs_growfs` | `btrfs filesystem resize` |
| **Check command** | `e2fsck -f` | `xfs_repair` | `btrfs check` |
| **Best for** | General purpose / Общее назначение | Large files, high-performance / Большие файлы | Snapshots, CoW / Снапшоты |

---

## Typical Growth Workflow

1. **Increase disk size** in hypervisor/cloud console / Увеличить размер диска в гипервизоре/облаке
2. **Rescan** (if needed): `echo 1 > /sys/class/block/sda/device/rescan`
3. **`growpart`** to expand partition / расширение раздела
4. **`pvresize`** (if LVM) / если LVM
5. **`lvextend`** (if LVM) / если LVM
6. **`resize2fs` / `xfs_growfs`** to expand filesystem / расширение ФС
7. **`df -h`** to verify / проверка

> [!NOTE]
> Some cloud providers (e.g., GCP) auto-resize the filesystem on reboot. Always verify with `df -h`.
> Некоторые облачные провайдеры (например, GCP) автоматически расширяют ФС при перезагрузке. Всегда проверяйте с `df -h`.

---

## Documentation Links

- **growpart:** https://manpages.debian.org/testing/cloud-guest-utils/growpart.1.en.html
- **resize2fs(8):** https://man7.org/linux/man-pages/man8/resize2fs.8.html
- **xfs_growfs(8):** https://man7.org/linux/man-pages/man8/xfs_growfs.8.html
- **parted(8):** https://man7.org/linux/man-pages/man8/parted.8.html
- **lvextend(8):** https://man7.org/linux/man-pages/man8/lvextend.8.html
- **pvresize(8):** https://man7.org/linux/man-pages/man8/pvresize.8.html
- **AWS — Extend EBS Volume:** https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html
- **GCP — Resize Disk:** https://cloud.google.com/compute/docs/disks/resize-persistent-disk
- **Azure — Expand OS Disk:** https://learn.microsoft.com/en-us/azure/virtual-machines/linux/expand-disks
