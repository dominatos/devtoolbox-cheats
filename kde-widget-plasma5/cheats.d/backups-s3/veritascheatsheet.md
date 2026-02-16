Title: 🗄️ Veritas InfoScale
Group: Backups & S3
Icon: 🗄️
Order: 8

# Veritas InfoScale Cheatsheet

> **Context:** Veritas InfoScale (formerly Storage Foundation) provides high-availability storage management, clustering, and disaster recovery. / Veritas InfoScale (ранее Storage Foundation) обеспечивает HA управление хранением, кластеризацию и DR.
> **Role:** Storage Admin / Sysadmin
> **Components:** VxVM (Volume Manager), VxFS (Filesystem)

---

## 📚 Table of Contents / Содержание

1. [VxVM (Volume Manager)](#vxvm-volume-manager--управление-томами)
2. [VxFS (Filesystem)](#vxfs-filesystem--файловая-система)
3. [Troubleshooting](#troubleshooting--устранение-неполадок)

---

## 1. VxVM (Volume Manager) / Управление томами

### Disk Management (vxdisk) / Управление дисками

```bash
# List disks / Список дисков
vxdisk list

# Initialize disk / Инициализация диска
vxdisksetup -i <DEVICE_NAME>

# List disk groups / Список дисковых групп
vxdg list
```

### Disk Groups (vxdg) / Дисковые группы

```bash
# Create Disk Group / Создать Disk Group
vxdg init <DG_NAME> <DISK_NAME>=<DEVICE_NAME>

# Add disk to DG / Добавить диск в DG
vxdg -g <DG_NAME> adddisk <DISK_NAME>=<DEVICE_NAME>

# Import/Deport DG / Импорт/Депорт DG
vxdg import <DG_NAME>
vxdg deport <DG_NAME>
```

### Volumes (vxassist) / Тома

```bash
# Create Volume (10GB) / Создать том
vxassist -g <DG_NAME> make <VOL_NAME> 10g

# Grow Volume / Увеличить том
vxassist -g <DG_NAME> growto <VOL_NAME> 20g

# Mirror Volume / Зеркалирование
vxassist -g <DG_NAME> mirror <VOL_NAME>
```

---

## 2. VxFS (Filesystem) / Файловая система

### Create & Mount / Создание и Монтирование

```bash
# Create Filesystem / Создать ФС
mkfs -t vxfs /dev/vx/rdsk/<DG_NAME>/<VOL_NAME>

# Mount / Монтирование
mount -t vxfs /dev/vx/dsk/<DG_NAME>/<VOL_NAME> /mnt/point
```

### Resize Filesystem / Изменение размера ФС
Can be done online! / Можно делать на лету!

```bash
# Grow/Shrink FS to 20G / Изменить размер до 20Гб
fsadm -F vxfs -b 20g /mnt/point
```

### Snapshot / Снапшот

```bash
# Mount snapshot / Монтирование снапшота
mount -F vxfs -o snapof=/mnt/point /dev/vx/dsk/<DG_NAME>/<SNAP_VOL> /mnt/snap
```

---

## 3. Troubleshooting / Устранение неполадок

### Status Commands / Команды статуса

```bash
vxprint -ht  # Hierarchy view of objects / Иерархия объектов
vxdisk -o alldgs list # Disks map to DGs / Карта дисков к DG
```

### Log Locations / Логи
*   `/var/adm/messages` (Solaris)
*   `/var/log/messages` (Linux)
*   `/var/vx/vxdmp.log` (DMP logs)
