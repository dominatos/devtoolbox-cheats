Title: 🗄️ Snapshots — LVM/ZFS/Btrfs
Group: Backups & S3
Icon: 🗄️
Order: 8

## Table of Contents
- [LVM Snapshots](#lvm-snapshots)
- [ZFS Snapshots](#zfs-snapshots)
- [Btrfs Snapshots](#btrfs-snapshots)
- [Snapshot Strategies](#snapshot-strategies)
- [Sysadmin Patterns](#sysadmin-patterns)
- [Troubleshooting](#troubleshooting)

---

## LVM Snapshots

### Create Snapshot

lvcreate -L 10G -s -n snap1 /dev/vg0/lv_root   # Create 10GB snapshot / Создать снапшот 10ГБ
lvcreate -L 5G -s -n snap_www /dev/vg0/lv_www  # Snapshot specific LV / Снапшот конкретного LV

### List Snapshots

lvs                                            # List all LVs / Список всех LV
lvs | grep snapshot                            # Show only snapshots / Только снапшоты
lvdisplay /dev/vg0/snap1                       # Snapshot details / Детали снапшота

### Mount Snapshot

mkdir /mnt/snap1                               # Create mount point / Создать точку монтирования
mount /dev/vg0/snap1 /mnt/snap1 -o ro          # Mount read-only / Монтировать только для чтения
ls /mnt/snap1                                  # Browse files / Просмотр файлов
umount /mnt/snap1                              # Unmount / Размонтировать

### Remove Snapshot

lvremove /dev/vg0/snap1                        # Remove snapshot / Удалить снапшот
lvremove -f /dev/vg0/snap1                     # Force remove / Принудительно удалить

### Merge Snapshot

lvconvert --merge /dev/vg0/snap1               # Merge snapshot to origin / Слить снапшот с оригиналом
# Requires reboot if origin is mounted / Требует перезагрузки если оригинал смонтирован

### Extend Snapshot

lvextend -L +5G /dev/vg0/snap1                 # Extend by 5GB / Расширить на 5ГБ

---

## ZFS Snapshots

### Create Snapshot

zfs snapshot pool/dataset@snap1                # Create snapshot / Создать снапшот
zfs snapshot -r pool/dataset@snap1             # Recursive snapshot / Рекурсивный снапшот
zfs snapshot pool/dataset@$(date +%Y%m%d)     # Snapshot with date / Снапшот с датой

### List Snapshots

zfs list -t snapshot                           # List all snapshots / Список всех снапшотов
zfs list -t snapshot pool/dataset              # Dataset snapshots / Снапшоты датасета
zfs list -t snapshot -o name,used,referenced   # Custom columns / Кастомные колонки

### Rollback Snapshot

zfs rollback pool/dataset@snap1                # Rollback to snapshot / Откатить к снапшоту
zfs rollback -r pool/dataset@snap1             # Recursive rollback / Рекурсивный откат
zfs rollback -rf pool/dataset@snap1            # Force rollback / Принудительный откат

### Clone Snapshot

zfs clone pool/dataset@snap1 pool/clone1       # Clone snapshot / Клонировать снапшот
zfs promote pool/clone1                        # Promote clone / Повысить клон

### Delete Snapshot

zfs destroy pool/dataset@snap1                 # Delete snapshot / Удалить снапшот
zfs destroy -r pool/dataset@ snap1              # Recursive delete / Рекурсивное удаление

### Send/Receive (Replication)

zfs send pool/dataset@snap1 | ssh <USER>@<HOST> zfs receive backup/dataset # Send to remote / Отправить на удалённый

zfs send -i pool/dataset@snap1 pool/dataset@snap2 | ssh <USER>@<HOST> zfs receive backup/dataset # Incremental send / Инкрементальная отправка

zfs send -R pool/dataset@snap1 | zfs receive backup/dataset # Recursive send / Рекурсивная отправка

### Snapshot Holds

zfs hold keep pool/dataset@snap1               # Hold snapshot / Удержать снапшот
zfs holds pool/dataset@snap1                   # List holds / Список удержаний
zfs release keep pool/dataset@snap1            # Release hold / Освободить удержание

---

## Btrfs Snapshots

### Create Snapshot

btrfs subvolume snapshot /mnt/data /mnt/data_snap1 # Create snapshot / Создать снапшот
btrfs subvolume snapshot -r /mnt/data /mnt/data_snap1 # Read-only snapshot / Снапшот только для чтения

### List Snapshots

btrfs subvolume list /mnt                      # List subvolumes / Список подтомов
btrfs subvolume list -s /mnt                   # List snapshots / Список снапшотов
btrfs subvolume show /mnt/data_snap1           # Snapshot details / Детали снапшота

### Delete Snapshot

btrfs subvolume delete /mnt/data_snap1         # Delete snapshot / Удалить снапшот

### Restore from Snapshot

mv /mnt/data /mnt/data_old                     # Rename current / Переименовать текущий
btrfs subvolume snapshot /mnt/data_snap1 /mnt/data # Restore snapshot / Восстановить снапшот
btrfs subvolume delete /mnt/data_old           # Delete old / Удалить старый

### Send/Receive

btrfs send /mnt/data_snap1 | ssh <USER>@<HOST> btrfs receive /backup # Send snapshot / Отправить снапшот

btrfs send -p /mnt/data_snap1 /mnt/data_snap2 | ssh <USER>@<HOST> btrfs receive /backup # Incremental send / Инкрементальная отправка

---

## Snapshot Strategies

### Snapshot-Based Backups

# 1. Create snapshot / Создать снапшот
lvcreate -L 5G -s -n backup_snap /dev/vg0/lv_data

# 2. Mount and backup / Монтировать и бэкапить
mount /dev/vg0/backup_snap /mnt/snap -o ro
tar -czf /backup/data-$(date +%Y%m%d).tar.gz /mnt/snap
umount /mnt/snap

# 3. Remove snapshot / Удалить снапшот
lvremove -f /dev/vg0/backup_snap

### Retention Policies

# Keep daily snapshots for 7 days / Сохранять дневные снапшоты 7 дней
# Keep weekly snapshots for 4 weeks / Сохранять недельные снапшоты 4 недели
# Keep monthly  snapshots for 6 months / Сохранять месячные снапшоты 6 месяцев

### ZFS Auto-Snapshot

# Using zfs-auto-snapshot package / Используя пакет zfs-auto-snapshot
apt install zfs-auto-snapshot                  # Install / Установить

zfs set com.sun:auto-snapshot=true pool/dataset # Enable auto-snapshot / Включить авто-снапшот
zfs set com.sun:auto-snapshot:frequent=false pool/dataset # Disable frequent / Отключить частые
zfs set com.sun:auto-snapshot:hourly=true pool/dataset    # Enable hourly / Включить почасовые

---

## Sysadmin Patterns

### Daily LVM Snapshot Script

#!/bin/bash
# /usr/local/bin/daily-lvm-snapshot.sh

VG=vg0
LV=lv_data
SNAP_NAME="snap_$(date +%Y%m%d)"
SNAP_SIZE="10G"

# Create snapshot / Создать снапшот
lvcreate -L $SNAP_SIZE -s -n $SNAP_NAME /dev/$VG/$LV

# Keep only last 7 snapshots / Сохранить только последние 7 снапшотов
lvs --noheadings -o lv_name $VG | grep '^snap_' | sort | head -n -7 | while read snap; do
  lvremove -f /dev/$VG/$snap
done

### ZFS Snapshot + Replication

#!/bin/bash
# ZFS snapshot and remote replication / Снапшот ZFS и удалённая репликация

DATASET="pool/data"
REMOTE_HOST="<HOST>"
REMOTE_DATASET="backup/data"
SNAP_NAME="daily_$(date +%Y%m%d)"

# Create new snapshot / Создать новый снапшот
zfs snapshot ${DATASET}@${SNAP_NAME}

# Get previous snapshot / Получить предыдущий снапшот
PREV_SNAP=$(zfs list -t snapshot -o name -s creation | grep "^${DATASET}@daily" | tail -n 2 | head -n 1 | cut -d@ -f2)

if [ -n "$PREV_SNAP" ]; then
  # Incremental send / Инкрементальная отправка
  zfs send -i ${DATASET}@${PREV_SNAP} ${DATASET}@${SNAP_NAME} | ssh <USER>@${REMOTE_HOST} zfs receive ${REMOTE_DATASET}
else
  # Full send / Полная отправка
  zfs send ${DATASET}@${SNAP_NAME} | ssh <USER>@${REMOTE_HOST} zfs receive ${REMOTE_DATASET}
fi

# Remove old snapshots (keep 30) / Удалить старые снапшоты (сохранить 30)
zfs list -t snapshot -o name -s creation | grep "^${DATASET}@daily" | head -n -30 | while read snap; do
  zfs destroy $snap
done

### Btrfs Automated Snapshots

#!/bin/bash
# Btrfs daily snapshots / Ежедневные снапшоты Btrfs

SUBVOL="/mnt/data"
SNAP_DIR="/mnt/snapshots"
SNAP_NAME="data_$(date +%Y%m%d_%H%M%S)"

# Create snapshot / Создать снапшот
btrfs subvolume snapshot -r $SUBVOL $SNAP_DIR/$SNAP_NAME

# Remove snapshots older than 30 days / Удалить снапшоты старше 30 дней
find $SNAP_DIR -maxdepth 1 -type d -name "data_*" -mtime +30 | while read snap; do
  btrfs subvolume delete $snap
done

---

## Troubleshooting

### LVM Issues

# "Insufficient free space" / "Недостаточно свободного места"
vgs                                            # Check VG free space / Проверить свободное место VG
lvextend -L +5G /dev/vg0/snap1                 # Extend snapshot / Расширить снапшот

# Snapshot full / Снапшот заполнен
lvs | grep snapshot                            # Check snapshot usage / Проверить использование снапшота
lvremove -f /dev/vg0/snap1                     # Emergency remove / Экстренное удаление

### ZFS Issues

# "Cannot destroy snapshot: dataset is busy" / "Невозможно удалить снапшот: датасет занят"
zfs holds pool/dataset@snap1                   # Check holds / Проверить удержания
zfs release keep pool/dataset@snap1            # Release hold / Освободить удержание

# "Cannot receive incremental stream" / "Невозможно получить инкрементальный поток"
zfs rollback pool/dataset@snap1                # Rollback to common snapshot / Откатить к общему снапшоту

### Btrfs Issues

# "Cannot delete subvolume" / "Невозможно удалить подтом"
btrfs subvolume list /mnt                      # List subvolumes / Список подтомов
umount /mnt/data_snap1                         # Unmount if mounted / Размонтировать если смонтирован

### Space Management

# LVM
lvs -o lv_name,data_percent                    # Snapshot usage / Использование снапшота

# ZFS
zfs list -o name,used,refer -t snapshot        # Snapshot space / Место снапшотов
zfs destroy -nv pool/dataset@snap1             # Dry run destroy / Пробный запуск удаления

# Btrfs
btrfs filesystem df /mnt                       # Filesystem usage / Использование файловой системы
btrfs qgroup show /mnt                         # Quota group usage / Использование квот групп
