Title: 💿 Partition & Mount
Group: Storage & FS
Icon: 💿
Order: 2

# Partition & Mount Sysadmin Cheatsheet

> **Context:** Linux disk partitioning and mounting operations. / Операции с разделами и монтированием в Linux.
> **Role:** Sysadmin / DevOps
> **Tools:** lsblk, blkid, parted, fdisk, mkfs, mount

---

## 📚 Table of Contents / Содержание

1. [Disk Information](#disk-information--информация-о-дисках)
2. [Partitioning](#partitioning--разметка)
3. [Formatting](#formatting--форматирование)
4. [Mounting](#mounting--монтирование)
5. [fstab Management](#fstab-management--управление-fstab)
6. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. Disk Information / Информация о дисках

### List Block Devices / Список блочных устройств
```bash
lsblk                                     # Tree view of devices / Дерево устройств
lsblk -f                                  # With filesystems / С файловыми системами
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,UUID   # Custom columns / Выборочные столбцы
```

### Device Info / Информация об устройствах
```bash
blkid                                     # UUID and FS types / UUID и типы ФС
blkid /dev/sdb1                           # Specific device / Конкретное устройство
sudo fdisk -l                             # Partition tables / Таблицы разделов
sudo parted -l                            # All disks info / Информация о всех дисках
```

### Disk Usage / Использование дисков
```bash
df -h                                     # Mounted filesystems / Смонтированные ФС
df -hT                                    # With filesystem type / С типом ФС
lsblk -d -o NAME,SIZE,MODEL               # Physical disks / Физические диски
```

---

## 2. Partitioning / Разметка

### GPT Partitioning (parted) / GPT разметка
```bash
# Create GPT table and partition / Создать GPT таблицу и раздел
sudo parted /dev/sdb -- mklabel gpt
sudo parted /dev/sdb -- mkpart primary ext4 1MiB 100%

# Create multiple partitions / Создать несколько разделов
sudo parted /dev/sdb -- mkpart primary ext4 1MiB 50%
sudo parted /dev/sdb -- mkpart primary xfs 50% 100%
```

### MBR Partitioning (fdisk) / MBR разметка
```bash
sudo fdisk /dev/sdb                       # Interactive mode / Интерактивный режим
# Commands: n=new, d=delete, p=print, w=write, q=quit
# Команды: n=новый, d=удалить, p=показать, w=записать, q=выход
```

### Partition Info / Информация о разделах
```bash
sudo parted /dev/sdb print                # Show partitions / Показать разделы
sudo fdisk -l /dev/sdb                    # Partition table / Таблица разделов
cat /proc/partitions                      # Kernel view / Вид ядра
```

---

## 3. Formatting / Форматирование

### Create Filesystems / Создание файловых систем
```bash
sudo mkfs.ext4 /dev/sdb1                  # ext4 filesystem / ФС ext4
sudo mkfs.xfs /dev/sdb1                   # XFS filesystem / ФС XFS
sudo mkfs.btrfs /dev/sdb1                 # Btrfs filesystem / ФС Btrfs
sudo mkfs.vfat -F 32 /dev/sdb1            # FAT32 (USB/EFI) / FAT32 (USB/EFI)
```

### Filesystem Options / Опции форматирования
```bash
sudo mkfs.ext4 -L "DATA" /dev/sdb1        # With label / С меткой
sudo mkfs.xfs -L "BACKUP" /dev/sdb1       # XFS with label / XFS с меткой
sudo mkfs.ext4 -j /dev/sdb1               # With journaling / С журналированием
```

### Check/Repair Filesystems / Проверка/Восстановление ФС
```bash
sudo fsck /dev/sdb1                       # Check filesystem / Проверить ФС
sudo fsck.ext4 -f /dev/sdb1               # Force check ext4 / Принудительная проверка
sudo xfs_repair /dev/sdb1                 # Repair XFS / Восстановить XFS
```

---

## 4. Mounting / Монтирование

### Basic Mount / Базовое монтирование
```bash
sudo mkdir -p /mnt/disk                   # Create mount point / Создать точку монтирования
sudo mount /dev/sdb1 /mnt/disk            # Mount device / Смонтировать устройство
sudo mount -t xfs /dev/sdb1 /mnt/disk     # Specify FS type / Указать тип ФС
```

### Mount Options / Опции монтирования
```bash
sudo mount -o ro /dev/sdb1 /mnt/disk      # Read-only / Только чтение
sudo mount -o noexec /dev/sdb1 /mnt/disk  # No executables / Без исполняемых
sudo mount -o rw,noatime /dev/sdb1 /mnt/disk  # Read-write, no atime / RW, без atime
```

### Mount by UUID / Монтирование по UUID
```bash
# Get UUID / Получить UUID
blkid /dev/sdb1

# Mount by UUID / Монтировать по UUID
sudo mount UUID="<UUID>" /mnt/disk
```

### Unmount / Размонтирование
```bash
sudo umount /mnt/disk                     # Unmount by path / Размонтировать по пути
sudo umount /dev/sdb1                     # Unmount by device / Размонтировать по устройству
sudo umount -l /mnt/disk                  # Lazy unmount / Отложенное размонтирование
```

### Check Mounted / Проверка смонтированных
```bash
mount | grep sdb                          # Find mounted / Найти смонтированные
findmnt                                   # Tree of mounts / Дерево монтирования
findmnt /mnt/disk                         # Check specific / Проверить конкретную
```

---

## 5. fstab Management / Управление fstab

### fstab Format / Формат fstab
```bash
# Format: <device> <mount> <type> <options> <dump> <pass>
# Формат: <устройство> <точка> <тип> <опции> <dump> <pass>
```

### Add to fstab / Добавить в fstab
```bash
# By device / По устройству
echo '/dev/sdb1 /mnt/disk xfs defaults 0 0' | sudo tee -a /etc/fstab

# By UUID (recommended) / По UUID (рекомендуется)
echo 'UUID=<UUID> /mnt/disk xfs defaults 0 2' | sudo tee -a /etc/fstab

# By label / По метке
echo 'LABEL=DATA /mnt/disk ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

### Common fstab Options / Типичные опции fstab
```text
defaults    — rw,suid,dev,exec,auto,nouser,async
noatime     — Don't update access time / Не обновлять время доступа
nofail      — Don't fail boot if missing / Не прерывать загрузку если отсутствует
ro          — Read-only / Только чтение
noexec      — No executables / Без исполняемых файлов
_netdev     — Network device (wait for network) / Сетевое устройство
```

### Test fstab / Тестирование fstab
```bash
sudo mount -a                             # Mount all from fstab / Смонтировать всё из fstab
sudo mount -fav                           # Fake mount (test) / Тестовое монтирование
findmnt --verify                          # Verify fstab syntax / Проверить синтаксис fstab
```

---

## 6. Troubleshooting / Устранение неполадок

### Device Busy / Устройство занято
```bash
lsof +D /mnt/disk                         # What's using mount / Что использует точку
fuser -mv /mnt/disk                       # Processes using mount / Процессы на точке
sudo fuser -km /mnt/disk                  # Kill processes / Убить процессы
```

### Mount Errors / Ошибки монтирования
```bash
dmesg | tail -20                          # Kernel messages / Сообщения ядра
journalctl -xe                            # Systemd journal / Журнал systemd
sudo mount -v /dev/sdb1 /mnt/disk         # Verbose mount / Подробный вывод
```

### Refresh Partition Table / Обновить таблицу разделов
```bash
sudo partprobe /dev/sdb                   # Re-read partitions / Перечитать разделы
sudo blockdev --rereadpt /dev/sdb         # Alternative method / Альтернативный метод
```

---

# 💡 Best Practices / Лучшие практики
# Use UUID in fstab for stability / Используйте UUID в fstab для стабильности
# Add nofail option for non-critical mounts / Добавьте nofail для некритичных точек
# Use XFS for large files, ext4 for general use / XFS для больших файлов, ext4 для общего использования
# Always backup fstab before editing / Всегда делайте бэкап fstab перед редактированием
# Test fstab changes with mount -a before reboot / Тестируйте изменения fstab перед перезагрузкой

# 📋 Common Filesystem Types / Распространённые типы ФС
# ext4   — Linux default, journaling / Linux по умолчанию, журналирование
# xfs    — High-performance, large files / Высокопроизводительная, большие файлы
# btrfs  — Copy-on-write, snapshots / Копирование при записи, снапшоты
# vfat   — FAT32, USB compatibility / FAT32, совместимость с USB
# ntfs   — Windows NTFS (ntfs-3g) / Windows NTFS

# 🔧 Default Paths / Пути по умолчанию
# /etc/fstab                — Filesystem table / Таблица ФС
# /mnt/                     — Temporary mounts / Временные монтирования
# /media/                   — Removable media / Съёмные носители
