Title: 🗄️ Snapshots — LVM/ZFS/Btrfs
Group: Backups & S3
Icon: 🗄️
Order: 8

## Table of Contents
- [Technology Comparison](#technology-comparison)
- [LVM Snapshots](#lvm-snapshots)
- [ZFS Snapshots](#zfs-snapshots)
- [Btrfs Snapshots](#btrfs-snapshots)
- [Snapshot Strategies](#snapshot-strategies)
- [Sysadmin Patterns](#sysadmin-patterns)
- [Troubleshooting](#troubleshooting)

---

## Technology Comparison

> Choosing the right snapshot technology depends on your storage stack and OS.

| Feature | LVM | ZFS | Btrfs |
|---------|-----|-----|-------|
| **Description** | Block-level snapshots via CoW | Integrated filesystem + volume manager | Copy-on-Write Linux filesystem |
| **CoW Type** | Block-level | Block-level | Extent-level |
| **Replication** | Manual (tar + SSH) | Native `zfs send/receive` | Native `btrfs send/receive` |
| **Incremental Replication** | No (manual) | Yes (built-in) | Yes (with `-p` parent) |
| **Auto-snapshot** | Via cron/scripts | `zfs-auto-snapshot` package | Via scripts / snapper |
| **Quota / Space Control** | VG free space | Dataset quotas | qgroups |
| **Best For** | Traditional Linux servers | NAS, FreeBSD, TrueNAS, production DBs | Modern Linux desktops/servers |
| **Rollback Without Reboot** | No (root LV requires reboot) | Yes | Yes |
| **OS Support** | All Linux | Linux (OpenZFS), FreeBSD, Illumos | Linux only |

---

## LVM Snapshots

### Create Snapshot / Создать снапшот

```bash
lvcreate -L 10G -s -n snap1 /dev/vg0/lv_root     # Create 10 GB snapshot / Создать снапшот 10 ГБ
lvcreate -L 5G  -s -n snap_www /dev/vg0/lv_www   # Snapshot specific LV / Снапшот конкретного LV
```

> [!IMPORTANT]
> The snapshot size (`-L`) controls the CoW (Copy-on-Write) extent pool, not the data size. If the source LV changes more than the snapshot size, the snapshot becomes **invalid**. Size to at least 10–20% of the source LV's expected change rate.

### List Snapshots / Список снапшотов

```bash
lvs                                                # List all LVs / Список всех LV
lvs | grep snapshot                               # Show only snapshots / Только снапшоты
lvdisplay /dev/vg0/snap1                          # Snapshot details / Детали снапшота
lvs -o lv_name,data_percent                       # Show usage % / Использование снапшота
```

Sample output of `lvs | grep snapshot`:
```
  snap1   vg0 swi-ao----  10.00g                                     lv_root 45.23
  snap_www vg0 swi-ao----   5.00g                                     lv_www   12.01
```

### Mount Snapshot / Монтировать снапшот

```bash
mkdir -p /mnt/snap1                               # Create mount point / Создать точку монтирования
mount /dev/vg0/snap1 /mnt/snap1 -o ro            # Mount read-only / Монтировать только для чтения
ls /mnt/snap1                                     # Browse files / Просмотр файлов
umount /mnt/snap1                                 # Unmount / Размонтировать
```

### Remove Snapshot / Удалить снапшот

> [!WARNING]
> Removing a snapshot is permanent and immediate. Ensure no backup jobs are reading from it first.

```bash
lvremove /dev/vg0/snap1                           # Remove snapshot (interactive) / Удалить снапшот (интерактивно)
lvremove -f /dev/vg0/snap1                        # Force remove (no confirmation) / Принудительно удалить
```

### Merge Snapshot / Слить снапшот с оригиналом

```bash
lvconvert --merge /dev/vg0/snap1                  # Merge snapshot into origin / Слить снапшот с оригиналом
# If LV is active, merge completes on next activation (reboot)
# / Если LV активен — слияние завершится при следующей активации (перезагрузке)
```

> [!CAUTION]
> Merging a snapshot **replaces** the current state of the origin LV with the snapshot state. This is a destructive rollback — all changes since the snapshot was taken will be lost.

### Extend Snapshot / Расширить снапшот

```bash
lvextend -L +5G /dev/vg0/snap1                   # Extend by 5 GB / Расширить на 5 ГБ
```

> [!TIP]
> Monitor snapshot fill with `lvs -o lv_name,data_percent`. If it reaches 100%, the snapshot is invalidated automatically.

---

## ZFS Snapshots

### Create Snapshot / Создать снапшот

```bash
zfs snapshot pool/dataset@snap1                   # Create snapshot / Создать снапшот
zfs snapshot -r pool/dataset@snap1                # Recursive snapshot (all children) / Рекурсивный снапшот
zfs snapshot pool/dataset@$(date +%Y%m%d)        # Snapshot with date suffix / Снапшот с суффиксом даты
```

### List Snapshots / Список снапшотов

```bash
zfs list -t snapshot                              # List all snapshots / Список всех снапшотов
zfs list -t snapshot pool/dataset                 # Dataset-specific snapshots / Снапшоты датасета
zfs list -t snapshot -o name,used,referenced      # Custom columns / Кастомные колонки
zfs list -t snapshot -s creation                  # Sort by creation time / Сортировка по времени
```

Sample output of `zfs list -t snapshot -o name,used,referenced`:
```
NAME                      USED   REFER
pool/data@20240101       1.23G   45.6G
pool/data@20240102        234M   46.1G
```

### Rollback Snapshot / Откатить снапшот

> [!CAUTION]
> `zfs rollback` destroys all snapshots newer than the target and reverts the dataset to the snapshot state. Use `-r` to also remove child snapshots. This is irreversible.

```bash
zfs rollback pool/dataset@snap1                   # Rollback to snapshot / Откатить к снапшоту
zfs rollback -r pool/dataset@snap1                # Recursive rollback / Рекурсивный откат
zfs rollback -rf pool/dataset@snap1               # Force rollback (unmounts if needed) / Принудительный откат
```

### Clone Snapshot / Клонировать снапшот

```bash
zfs clone pool/dataset@snap1 pool/clone1          # Clone snapshot to new dataset / Клонировать снапшот
zfs promote pool/clone1                           # Promote clone (reverse dependency) / Повысить клон
# After promote: clone becomes independent, original depends on it
# / После promote: клон становится независимым, оригинал зависит от него
```

### Delete Snapshot / Удалить снапшот

```bash
zfs destroy pool/dataset@snap1                    # Delete single snapshot / Удалить снапшот
zfs destroy -r pool/dataset@snap1                 # Recursive delete / Рекурсивное удаление
zfs destroy pool/dataset@snap1%snap3              # Delete range snap1 → snap3 / Удалить диапазон
zfs destroy -nv pool/dataset@snap1                # Dry run — preview what will be freed / Пробный запуск
```

### Send/Receive — Replication / Репликация

```bash
# Full send to remote host / Полная отправка на удалённый хост
zfs send pool/dataset@snap1 | ssh <USER>@<HOST> zfs receive backup/dataset

# Incremental send (much faster after initial) / Инкрементальная отправка (намного быстрее)
zfs send -i pool/dataset@snap1 pool/dataset@snap2 | ssh <USER>@<HOST> zfs receive backup/dataset

# Recursive send (all children) / Рекурсивная отправка (все дочерние датасеты)
zfs send -R pool/dataset@snap1 | zfs receive backup/dataset
```

> [!TIP]
> Add `mbuffer` between `zfs send` and SSH to buffer network fluctuations:
> `zfs send pool/dataset@snap1 | mbuffer -s 128k -m 1G | ssh <USER>@<HOST> zfs receive backup/dataset`

### Snapshot Holds / Удержания снапшотов

```bash
zfs hold keep pool/dataset@snap1                  # Place hold (prevents destroy) / Удержание (запрет удаления)
zfs holds pool/dataset@snap1                      # List holds / Список удержаний
zfs release keep pool/dataset@snap1               # Release hold / Освободить удержание
```

### ZFS Auto-Snapshot / Автоматические снапшоты ZFS

```bash
apt install zfs-auto-snapshot                     # Install auto-snapshot / Установить авто-снапшот

zfs set com.sun:auto-snapshot=true pool/dataset              # Enable auto-snapshot / Включить
zfs set com.sun:auto-snapshot:frequent=false pool/dataset    # Disable 15-min snapshots / Отключить частые
zfs set com.sun:auto-snapshot:hourly=true pool/dataset       # Enable hourly / Включить почасовые
zfs set com.sun:auto-snapshot:daily=true pool/dataset        # Enable daily / Включить ежедневные
zfs set com.sun:auto-snapshot:weekly=true pool/dataset       # Enable weekly / Включить еженедельные
zfs set com.sun:auto-snapshot:monthly=true pool/dataset      # Enable monthly / Включить ежемесячные
```

---

## Btrfs Snapshots

### Create Snapshot / Создать снапшот

```bash
btrfs subvolume snapshot /mnt/data /mnt/data_snap1      # Read-write snapshot / Снапшот для чтения-записи
btrfs subvolume snapshot -r /mnt/data /mnt/data_snap1   # Read-only snapshot (required for send) / Только чтение (нужен для send)
```

> [!IMPORTANT]
> Read-only snapshots (`-r`) are required when using `btrfs send`. Read-write snapshots can be accidentally modified, making incremental send impossible.

### List Snapshots / Список снапшотов

```bash
btrfs subvolume list /mnt                         # List all subvolumes / Список всех подтомов
btrfs subvolume list -s /mnt                      # List only snapshots / Только снапшоты
btrfs subvolume show /mnt/data_snap1              # Snapshot details / Детали снапшота
```

### Delete Snapshot / Удалить снапшот

```bash
btrfs subvolume delete /mnt/data_snap1            # Delete snapshot / Удалить снапшот
```

### Restore from Snapshot — Production Runbook / Восстановление из снапшота

> [!CAUTION]
> This procedure replaces the live subvolume. Ensure all services writing to `/mnt/data` are stopped first.

1. Stop services that use the subvolume:
   ```bash
   systemctl stop <SERVICE>
   ```
2. Rename the current (broken) subvolume:
   ```bash
   mv /mnt/data /mnt/data_old
   ```
3. Create a new snapshot from the restore point:
   ```bash
   btrfs subvolume snapshot /mnt/data_snap1 /mnt/data
   ```
4. Restart services:
   ```bash
   systemctl start <SERVICE>
   ```
5. Verify, then remove the old subvolume:
   ```bash
   btrfs subvolume delete /mnt/data_old
   ```

### Send/Receive — Replication / Репликация

```bash
# Full send to remote / Полная отправка на удалённый хост
btrfs send /mnt/data_snap1 | ssh <USER>@<HOST> btrfs receive /backup

# Incremental send (-p specifies parent snapshot) / Инкрементальная отправка (-p задаёт родительский снапшот)
btrfs send -p /mnt/data_snap1 /mnt/data_snap2 | ssh <USER>@<HOST> btrfs receive /backup
```

### Space Usage / Использование места

```bash
btrfs filesystem df /mnt                          # Filesystem usage by type / Использование файловой системы
btrfs qgroup show /mnt                            # Quota group usage (if enabled) / Использование квот групп
```

---

## Snapshot Strategies

### Retention Policy Reference / Справка по политике хранения

| Period | Suggested Retention | Notes |
|--------|---------------------|-------|
| Daily | 7 days | Covers most accidental deletion scenarios |
| Weekly | 4 weeks | Catches weekly batch issues |
| Monthly | 6 months | Useful for compliance & long-term rollback |
| Yearly | 2–3 years | Audit & regulatory requirements |

### Snapshot-Based Backup Workflow (LVM) / Рабочий процесс бэкапа на основе LVM

```bash
# 1. Create snapshot / Создать снапшот
lvcreate -L 5G -s -n backup_snap /dev/vg0/lv_data

# 2. Mount read-only and archive / Монтировать и создать архив
mount /dev/vg0/backup_snap /mnt/snap -o ro
tar -czf /backup/data-$(date +%Y%m%d).tar.gz -C /mnt/snap .
umount /mnt/snap

# 3. Remove snapshot / Удалить снапшот
lvremove -f /dev/vg0/backup_snap
```

---

## Sysadmin Patterns

### Daily LVM Snapshot Script / Ежедневный скрипт снапшотов LVM

`/usr/local/bin/daily-lvm-snapshot.sh`

```bash
#!/bin/bash
# Daily LVM snapshot with 7-day rolling retention
# / Ежедневный LVM-снапшот с ротацией 7 дней

set -euo pipefail

VG="vg0"
LV="lv_data"
SNAP_NAME="snap_$(date +%Y%m%d)"
SNAP_SIZE="10G"
KEEP=7

# Create snapshot / Создать снапшот
lvcreate -L "$SNAP_SIZE" -s -n "$SNAP_NAME" "/dev/$VG/$LV"
echo "Created snapshot: /dev/$VG/$SNAP_NAME"

# Remove oldest snapshots beyond retention count / Удалить старые снапшоты сверх лимита
lvs --noheadings -o lv_name "$VG" | awk '{print $1}' | grep '^snap_' | sort | head -n "-$KEEP" | while read -r snap; do
  echo "Removing old snapshot: /dev/$VG/$snap"
  lvremove -f "/dev/$VG/$snap"
done
```

```bash
chmod +x /usr/local/bin/daily-lvm-snapshot.sh    # Make executable / Сделать исполняемым
```

### Cron for LVM Snapshot / Cron для LVM снапшотов

`/etc/cron.d/lvm-snapshot`

```
# Run LVM daily snapshot at 01:00 / Ежедневный снапшот LVM в 01:00
0 1 * * * root /usr/local/bin/daily-lvm-snapshot.sh >> /var/log/lvm-snapshot.log 2>&1
```

### ZFS Snapshot + Remote Replication Script / Скрипт ZFS снапшота и удалённой репликации

`/usr/local/bin/zfs-snapshot-replicate.sh`

```bash
#!/bin/bash
# ZFS snapshot with incremental remote replication
# / Снапшот ZFS с инкрементальной удалённой репликацией

set -euo pipefail

DATASET="pool/data"
REMOTE_HOST="<HOST>"
REMOTE_USER="<USER>"
REMOTE_DATASET="backup/data"
SNAP_NAME="daily_$(date +%Y%m%d)"
KEEP=30

# Create new snapshot / Создать новый снапшот
zfs snapshot "${DATASET}@${SNAP_NAME}"
echo "Created: ${DATASET}@${SNAP_NAME}"

# Get previous snapshot for incremental send / Получить предыдущий снапшот
PREV_SNAP=$(zfs list -t snapshot -o name -s creation | grep "^${DATASET}@daily" | tail -n 2 | head -n 1 | cut -d@ -f2)

if [ -n "$PREV_SNAP" ]; then
  echo "Incremental send: @${PREV_SNAP} → @${SNAP_NAME}"
  zfs send -i "${DATASET}@${PREV_SNAP}" "${DATASET}@${SNAP_NAME}" \
    | ssh "${REMOTE_USER}@${REMOTE_HOST}" zfs receive "${REMOTE_DATASET}"
else
  echo "Full send: ${DATASET}@${SNAP_NAME}"
  zfs send "${DATASET}@${SNAP_NAME}" \
    | ssh "${REMOTE_USER}@${REMOTE_HOST}" zfs receive "${REMOTE_DATASET}"
fi

# Prune old snapshots beyond retention / Удалить старые снапшоты сверх лимита
zfs list -t snapshot -o name -s creation | grep "^${DATASET}@daily" | head -n "-${KEEP}" | while read -r snap; do
  echo "Destroying old snapshot: $snap"
  zfs destroy "$snap"
done
```

```bash
chmod +x /usr/local/bin/zfs-snapshot-replicate.sh
```

### Cron for ZFS Replication / Cron для ZFS репликации

`/etc/cron.d/zfs-snapshot`

```
# ZFS daily snapshot + replication at 02:00 / Ежедневный снапшот + репликация в 02:00
0 2 * * * root /usr/local/bin/zfs-snapshot-replicate.sh >> /var/log/zfs-snapshot.log 2>&1
```

### Btrfs Automated Snapshot Script / Скрипт автоматических снапшотов Btrfs

`/usr/local/bin/btrfs-snapshot.sh`

```bash
#!/bin/bash
# Btrfs daily read-only snapshots with 30-day retention
# / Ежедневные снапшоты Btrfs только для чтения с хранением 30 дней

set -euo pipefail

SUBVOL="/mnt/data"
SNAP_DIR="/mnt/snapshots"
SNAP_NAME="data_$(date +%Y%m%d_%H%M%S)"
KEEP_DAYS=30

# Ensure snapshot directory exists / Убедиться что директория снапшотов существует
mkdir -p "$SNAP_DIR"

# Create read-only snapshot / Создать снапшот только для чтения
btrfs subvolume snapshot -r "$SUBVOL" "${SNAP_DIR}/${SNAP_NAME}"
echo "Created: ${SNAP_DIR}/${SNAP_NAME}"

# Remove snapshots older than retention period / Удалить снапшоты старше периода хранения
find "$SNAP_DIR" -maxdepth 1 -type d -name "data_*" -mtime "+${KEEP_DAYS}" | while read -r snap; do
  echo "Deleting old snapshot: $snap"
  btrfs subvolume delete "$snap"
done
```

```bash
chmod +x /usr/local/bin/btrfs-snapshot.sh
```

### Cron for Btrfs Snapshots / Cron для Btrfs снапшотов

`/etc/cron.d/btrfs-snapshot`

```
# Btrfs daily snapshot at 01:30 / Ежедневный снапшот Btrfs в 01:30
30 1 * * * root /usr/local/bin/btrfs-snapshot.sh >> /var/log/btrfs-snapshot.log 2>&1
```

### Logrotate for Snapshot Logs / Logrotate для логов снапшотов

`/etc/logrotate.d/snapshots`

```
/var/log/lvm-snapshot.log
/var/log/zfs-snapshot.log
/var/log/btrfs-snapshot.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    dateext
}
```

---

## Troubleshooting

### LVM Issues / Проблемы LVM

```bash
# Error: "Insufficient free space" / "Недостаточно свободного места"
vgs                                               # Check VG free space / Проверить свободное место VG
lvextend -L +5G /dev/vg0/snap1                   # Extend snapshot / Расширить снапшот

# Snapshot fill percentage / Заполненность снапшота
lvs -o lv_name,data_percent                       # Check all LV usage / Проверить использование LV

# Emergency: snapshot is full (100%) — snapshot is now invalid
# / Экстренный случай: снапшот заполнен (100%) — снапшот недействителен
lvremove -f /dev/vg0/snap1                        # Remove invalid snapshot / Удалить недействительный снапшот
```

> [!CAUTION]
> When an LVM snapshot fills to 100%, it becomes **automatically invalidated** — all data in it is lost. Monitor usage regularly and extend or remove promptly.

### ZFS Issues / Проблемы ZFS

```bash
# Error: "Cannot destroy snapshot: dataset is busy"
# / Ошибка: "Невозможно удалить снапшот: датасет занят"
zfs holds pool/dataset@snap1                      # Check active holds / Проверить удержания
zfs release keep pool/dataset@snap1               # Release hold / Освободить удержание

# Error: "Cannot receive incremental stream" (remote diverged)
# / Ошибка: "Невозможно получить инкрементальный поток" (расхождение)
zfs rollback pool/dataset@snap1                   # Rollback to common snapshot / Откатить к общему снапшоту
zfs destroy -nv pool/dataset@snap1                # Dry run before destroy / Пробный запуск перед удалением
```

### Btrfs Issues / Проблемы Btrfs

```bash
# Error: "Cannot delete subvolume" / "Невозможно удалить подтом"
btrfs subvolume list /mnt                         # List subvolumes to find IDs / Список подтомов
umount /mnt/data_snap1                            # Unmount if mounted / Размонтировать если смонтирован
btrfs subvolume delete /mnt/data_snap1            # Retry delete / Повторить удаление
```

### Space Management / Управление местом

```bash
# LVM — snapshot space usage / LVM — использование снапшотов
lvs -o lv_name,data_percent                       # Usage in % / Использование в %

# ZFS — per-snapshot space usage / ZFS — место каждого снапшота
zfs list -o name,used,refer -t snapshot           # Space used / Занятое место
zfs destroy -nv pool/dataset@snap1                # Preview space freed / Просмотр освобождаемого места

# Btrfs — overall + quota groups / Btrfs — общее + квота группы
btrfs filesystem df /mnt                          # Filesystem usage / Использование файловой системы
btrfs qgroup show /mnt                            # Quota group usage (if enabled) / Квота групп
```
