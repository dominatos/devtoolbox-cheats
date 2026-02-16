Title: 💿 Disk Growth — Cloud/VM Expansion
Group: Storage & FS
Icon: 💿
Order: 3

## Table of Contents
- [Partition Growth](#-partition-growth--расширение-раздела)
- [Filesystem Expansion](#-filesystem-expansion--расширение-файловой-системы)
- [LVM Growth](#-lvm-growth--расширение-lvm)
- [Cloud Providers](#-cloud-providers--облачные-провайдеры)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📏 Partition Growth / Расширение раздела

### Automatic Partition Resize / Автоматическое изменение размера раздела
sudo growpart /dev/sda 1                      # Grow partition №1 / Расширить раздел №1
sudo growpart /dev/vda 1                      # Grow partition (KVM/QEMU) / Расширить раздел (KVM/QEMU)
sudo growpart /dev/nvme0n1 1                  # Grow NVMe partition / Расширить раздел NVMe

### Check Before Growth / Проверка перед расширением
lsblk                                         # List block devices / Список блочных устройств
df -h                                         # Check filesystem usage / Проверить использование ФС
sudo fdisk -l /dev/sda                        # Check partition table / Проверить таблицу разделов
sudo parted /dev/sda print                    # Alternative check / Альтернативная проверка

### Manual Partition Resize (parted) / Ручное изменение (parted)
sudo parted /dev/sda                          # Enter parted / Войти в parted
# (parted) print                              # Show partitions / Показать разделы
# (parted) resizepart 1 100%                  # Resize to 100% / Изменить до 100%
# (parted) quit                               # Exit / Выйти

---

# 📂 Filesystem Expansion / Расширение файловой системы

### EXT2/EXT3/EXT4
sudo resize2fs /dev/sda1                      # Grow EXT4 / Увеличить EXT4
sudo resize2fs /dev/vda1                      # Grow EXT4 (KVM) / Увеличить EXT4 (KVM)
sudo e2fsck -f /dev/sda1                      # Check before resize / Проверить перед изменением
sudo resize2fs /dev/sda1 50G                  # Resize to specific size / Изменить до конкретного размера

### XFS
sudo xfs_growfs /mountpoint                   # Grow XFS / Увеличить XFS
sudo xfs_growfs /                             # Grow root XFS / Увеличить корневой XFS
sudo xfs_growfs -d /mnt/data                  # Grow data filesystem / Увеличить ФС данных

### Btrfs
sudo btrfs filesystem resize max /mountpoint  # Grow Btrfs to max / Увеличить Btrfs до максимума
sudo btrfs filesystem resize +10G /mnt        # Grow by 10GB / Увеличить на 10GB
sudo btrfs filesystem resize 1:max /mnt       # Grow device 1 to max / Увеличить устройство 1 до максимума

### Check Filesystem Type / Проверка типа ФС
df -T                                         # Show filesystem types / Показать типы ФС
lsblk -f                                      # Show filesystems / Показать файловые системы
sudo blkid /dev/sda1                          # Show filesystem UUID and type / Показать UUID и тип ФС

---

# 📦 LVM Growth / Расширение LVM

### Extend Physical Volume / Расширить физический том
sudo pvresize /dev/sda2                       # Resize PV to use full disk / Изменить PV на весь диск
sudo pvs                                      # List PVs / Список PV
sudo pvdisplay /dev/sda2                      # Show PV details / Показать детали PV

### Extend Logical Volume / Расширить логический том
sudo lvextend -l +100%FREE /dev/vg0/lv_root   # Extend to use all free space / Расширить на всё свободное место
sudo lvextend -L +10G /dev/vg0/lv_data        # Extend by 10GB / Расширить на 10GB
sudo lvextend -L 50G /dev/vg0/lv_data         # Extend to 50GB total / Расширить до 50GB всего
sudo lvs                                      # List LVs / Список LV

### Resize Filesystem After LVM / Изменить ФС после LVM
sudo lvextend -r -l +100%FREE /dev/vg0/lv_root  # Extend and resize FS / Расширить и изменить ФС
sudo lvextend -L +10G /dev/vg0/lv_root && sudo resize2fs /dev/vg0/lv_root  # EXT4 manual / EXT4 вручную
sudo lvextend -L +10G /dev/vg0/lv_root && sudo xfs_growfs /mount  # XFS manual / XFS вручную

### Complete LVM Workflow / Полный процесс LVM
```bash
# 1. Check current state / Проверить текущее состояние
lsblk
df -h
sudo pvs
sudo vgs
sudo lvs

# 2. Grow partition / Расширить раздел
sudo growpart /dev/sda 2

# 3. Resize PV / Изменить PV
sudo pvresize /dev/sda2

# 4. Extend LV and resize FS / Расширить LV и изменить ФС
sudo lvextend -r -l +100%FREE /dev/vg0/lv_root

# 5. Verify / Проверить
df -h
```

---

# ☁️ Cloud Providers / Облачные провайдеры

### AWS EC2
```bash
# After resizing EBS volume in AWS Console / После изменения размера тома EBS в консоли AWS
lsblk
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1                     # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

### Google Cloud Platform (GCP)
```bash
# After resizing disk in GCP Console / После изменения размера диска в консоли GCP
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

### Azure
```bash
# After resizing disk in Azure Portal / После изменения размера диска в Azure Portal
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

### DigitalOcean
```bash
# After resizing droplet / После изменения размера дроплета
lsblk
sudo growpart /dev/vda 1
sudo resize2fs /dev/vda1                      # For EXT4 / Для EXT4
```

### VMware / Proxmox
```bash
# After increasing disk size in hypervisor / После увеличения размера диска в гипервизоре
lsblk
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1                      # For EXT4 / Для EXT4
sudo xfs_growfs /                             # For XFS / Для XFS
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Common Issues / Распространённые проблемы
```bash
# Check if partition table is GPT or MBR / Проверить тип таблицы разделов
sudo parted /dev/sda print

# Kernel not recognizing new size / Ядро не распознаёт новый размер
sudo partprobe /dev/sda                       # Reread partition table / Перечитать таблицу разделов
sudo partx -u /dev/sda                        # Update kernel partition table / Обновить таблицу разделов ядра

# LVM not showing full size / LVM не показывает полный размер
sudo pvscan                                   # Scan for PVs / Сканировать PV
sudo vgscan                                   # Scan for VGs / Сканировать VG
sudo lvscan                                   # Scan for LVs / Сканировать LV
```

### Verify Growth / Проверка расширения
```bash
# Before / До
lsblk
df -h

# After partition growth / После расширения раздела
lsblk

# After filesystem resize / После изменения ФС
df -h
```

### Filesystem Check / Проверка файловой системы
```bash
# EXT4 check / Проверка EXT4
sudo e2fsck -f /dev/sda1

# XFS check / Проверка XFS
sudo xfs_repair /dev/sda1

# Btrfs check / Проверка Btrfs
sudo btrfs check /dev/sda1
```

---

# 🌟 Real-World Examples / Примеры из практики

### Standard Cloud Growth (EXT4) / Стандартное расширение в облаке (EXT4)
```bash
# 1. Resize disk in cloud console / Изменить размер диска в консоли облака
# 2. SSH to server / SSH на сервер

# 3. Check current state / Проверить текущее состояние
df -h
lsblk

# 4. Grow partition / Расширить раздел
sudo growpart /dev/sda 1

# 5. Resize filesystem / Изменить размер ФС
sudo resize2fs /dev/sda1

# 6. Verify / Проверить
df -h
```

### LVM in Production / LVM в продакшене
```bash
# Scenario: Root LV on LVM / Сценарий: Корневой LV на LVM

# 1. Check state / Проверить состояние
sudo vgs
sudo lvs
df -h

# 2. Grow partition (if needed) / Расширить раздел (если нужно)
sudo growpart /dev/sda 2

# 3. Resize PV / Изменить PV
sudo pvresize /dev/sda2

# 4. Extend LV with filesystem / Расширить LV с ФС
sudo lvextend -r -l +100%FREE /dev/mapper/vg0-root

# 5. Verify / Проверить
df -h
sudo lvs
```

### Add New Disk to LVM / Добавить новый диск к LVM
```bash
# 1. Identify new disk / Идентифицировать новый диск
lsblk

# 2. Create PV / Создать PV
sudo pvcreate /dev/sdb

# 3. Extend VG / Расширить VG
sudo vgextend vg0 /dev/sdb

# 4. Extend LV / Расширить LV
sudo lvextend -l +100%FREE /dev/vg0/lv_data

# 5. Resize filesystem / Изменить ФС
sudo resize2fs /dev/vg0/lv_data              # EXT4
sudo xfs_growfs /mount                        # XFS
```

### Emergency Filesystem Recovery / Аварийное восстановление ФС
```bash
# Boot into rescue mode / Загрузиться в режим восстановления

# Unmount filesystem / Отмонтировать ФС
sudo umount /dev/sda1

# Check and repair / Проверить и исправить
sudo e2fsck -f /dev/sda1                      # EXT4
sudo xfs_repair /dev/sda1                     # XFS

# Resize / Изменить размер
sudo resize2fs /dev/sda1                      # EXT4
sudo mount /dev/sda1 /mnt && sudo xfs_growfs /mnt  # XFS

# Remount / Перемонтировать
sudo mount /dev/sda1 /
```

# 💡 Best Practices / Лучшие практики
# Always backup before resizing / Всегда делайте резервную копию перед изменением размера
# Check filesystem before resize / Проверяйте ФС перед изменением
# Use LVM for flexibility / Используйте LVM для гибкости
# Take snapshots in cloud before resize / Делайте снимки в облаке перед изменением
# Document growth operations / Документируйте операции расширения
# Monitor disk usage after resize / Мониторьте использование диска после изменения

# 🔧 Common Commands by Filesystem / Распространённые команды по ФС
# EXT4: resize2fs
# XFS: xfs_growfs (mounted!)
# Btrfs: btrfs filesystem resize
# Note: XFS must be mounted / Примечание: XFS должна быть смонтирована

# 📋 Typical Growth Workflow / Типичный процесс расширения
# 1. Increase disk size in hypervisor/cloud / Увеличить размер диска в гипервизоре/облаке
# 2. growpart to expand partition / growpart для расширения раздела
# 3. pvresize (if LVM) / pvresize (если LVM)
# 4. lvextend (if LVM) / lvextend (если LVM)
# 5. resize2fs/xfs_growfs to expand filesystem / resize2fs/xfs_growfs для расширения ФС

# ⚠️ Important Notes / Важные примечания
# XFS cannot be shrunk, only grown / XFS нельзя уменьшить, только увеличить
# EXT4 can be shrunk offline / EXT4 можно уменьшить offline
# Always verify with df -h after resize / Всегда проверяйте с df -h после изменения
# Some cloud providers auto-resize on reboot / Некоторые провайдеры авторасширяют при перезагрузке
