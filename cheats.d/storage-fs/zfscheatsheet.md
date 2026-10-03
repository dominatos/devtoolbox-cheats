---
Title: 💾 ZFS — Advanced Filesystem
Group: "Storage & FS"
Icon: 💾
Order: 22
tags:
  - storage
  - zfs
  - filesystem
  - snapshots
  - raidz
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 💾 ZFS Cheatsheet

## Description

**ZFS** is a combined **filesystem and volume manager** with checksumming, copy-on-write, snapshots, cloning, and built-in RAID (mirror, raidz). Used on NAS and backup servers. / **ZFS** — combined filesystem and volume manager с checksumming, copy-on-write, snapshots, cloning и встроенным RAID (mirror, raidz). Используется на NAS и backup-серверах.

**Common use cases / Типовые сценарии:**
- NAS / NAS / БД на NAS
- Snapshot-based backups / Snapshot-бэкапы
- Proxmox / FreeBSD storage / Хранилища Proxmox / FreeBSD
- Data integrity protection / Защита целостности данных

**Status:** Actively maintained (OpenZFS). Alternatives: **Btrfs**, **LVM + ext4/XFS**, **mdadm**. / **Статус:** активно развивается (OpenZFS); альтернативы — Btrfs, LVM+ext4/XFS, mdadm.

**Paths:** pools at `/dev/disk/by-id/...`; datasets under pool root.  
**Tools:** `zpool`, `zfs`.

Cross-reference: [LUKS](luksencryptsetupcheatsheet.md), [Samba](sambacheatsheet.md), [Ceph](cephcheatsheet.md), [GlusterFS](glusterfscheatsheet.md).

---

## Installation

### Install OpenZFS / Установка OpenZFS

```bash
# Debian/Ubuntu
apt install zfsutils-linux

# RHEL/Rocky/Alma (EPEL or ZFS repo)
dnf install zfs
```

```bash
zfs --version
zpool --version
```

---

## Configuration

### Create pool / Создание пула

```bash
# Single-disk pool (testing only!)
zpool create -f tank <DISK>

# Mirror
zpool create -f tank mirror <DISK1> <DISK2>

# raidz2 (2-disk fault tolerance)
zpool create -f tank raidz2 <DISK1> <DISK2> <DISK3> <DISK4>

# raidz1
zpool create -f tank raidz1 <DISK1> <DISK2> <DISK3>
```

### Dataset layout / Раскладка dataset-ов

```bash
zfs create tank/data
zfs create tank/data/home
zfs create tank/data/postgres
zfs set mountpoint=/data tank/data
zfs set compression=lz4 tank/data
zfs set atime=off tank/data
```

---

## Core Management

### Pool status / Статус пула

```bash
zpool status -v tank
zpool list
zpool get all tank
zpool scrub tank
```

### Dataset operations / Операции с dataset

```bash
zfs list
zfs list -o name,used,avail,refer,compressratio
zfs create tank/snapshots
zfs set quota=50G tank/data/postgres
zfs set reservation=10G tank/data/postgres
zfs destroy tank/old
zfs rename tank/old tank/new
```

---

## Sysadmin Operations

### Snapshots / Снимки

```bash
zfs snapshot tank/data@$(date +%F)
zfs list -t snapshot
zfs rollback tank/data@<SNAPSHOT>
zfs clone tank/data@<SNAPSHOT> tank/data/clone
zfs destroy tank/data@<SNAPSHOT>
```

### Send/receive / Отправка и приём

```bash
# Backup snapshot to remote
zfs send tank/data@<SNAPSHOT> | ssh backup@<HOST> zfs receive backup/data

# Incremental send
zfs send -i tank/data@<SNAP1> tank/data@<SNAP2> | ssh backup@<HOST> zfs receive backup/data

# Resume token
zfs send -t <TOKEN>
```

### Scrub and trim / Scrub и TRIM

```bash
zpool scrub tank
zpool status -v tank
zpool trim tank
```

### Logrotate (scrub logs) / Ротация логов

`/etc/logrotate.d/zfs`

```bash
/var/log/zfs/* {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Security

### Hardening / Ужесточение

1. Use `ashift=12` for 4K-sector disks / Используйте ashift=12 для 4K-дисков
2. Avoid single-disk pools in production / Не используйте single-disk пулы в production
3. Set quotas to prevent fill-up / Задавайте quotas
4. Scrub regularly / Регулярно делайте scrub
5. Encrypt sensitive datasets / Шифруйте чувствительные dataset-ы
6. Test restore before trusting backups / Тестируйте восстановление

```bash
zfs create -o encryption=aes-256-gcm -o keyformat=passphrase tank/secure
```

> [!WARNING]
> Encryption keys are lost if passphrase/key is forgotten — no recovery. / **Ключи шифрования не восстановимы.**

---

## Backup and Restore

### Backup via send/recv / Бэкап через send/recv

```bash
zfs snapshot -r tank@nightly
zfs send -R tank@nightly | ssh backup@<HOST> zfs receive backup/tank
```

### Export/import / Экспорт и импорт

```bash
zpool export tank
zpool import tank
zpool import -d /dev/disk/by-id tank
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Pool DEGRADED | Failed disk | `zpool status`; replace disk |
| Checksum errors | Bad disk/memory | Scrub; replace disk |
| No space | Dataset full / quota | `zfs list`; destroy old snaps |
| Scrub fails | Device errors | Investigate SMART; replace |
| Pool unmounted after reboot | Not in /etc/zfs/zpool.cache | `zpool import` |

```bash
zpool status -v tank
zfs list -o name,used,avail
zpool scrub tank
```

---

## Comparison Tables

### Storage systems / Файловые системы

| System | Integrity | Snapshots | RAID |
| :--- | :--- | :--- | :--- |
| **ZFS** | Checksummed | Yes (Copy-on-Write) | Built-in (mirror/raidz) |
| **Btrfs** | Checksummed | Yes | RAID5/6 (experimental) |
| **XFS + LVM** | No | LVM thin snaps | External (md) |
| **ext4** | No | External | External |

---

## Production Runbooks

### Runbook: Create production pool / Создание production-пула

1. Identify disks by-id / Определить диски по by-id
2. `zpool create -f tank raidz2 <DISKS> -o ashift=12` / Создать pool
3. Create datasets; set compression=lz4, atime=off / Создать datasets
4. Set quotas on user-facing datasets / Задать quotas
5. Export/import test / Проверить export/import
6. Configure scrub cron / Настроить cron на scrub
7. Document pool layout / Задокументировать раскладку

### Runbook: Replace failed disk / Замена деградировавшего диска

1. `zpool status -v tank` — identify failed device / Определить диск
2. Online replace or offline; replace hardware / Заменить диск
3. `zpool replace tank <OLD> <NEW>` / Заменить в пуле
4. Wait for resilver / Дождаться resilver
5. `zpool status` — verify healthy / Проверить статус
6. Scrub after resilver / Сделать scrub

---

## Documentation Links

- OpenZFS docs — https://openzfs.github.io/openzfs-docs/
- ZFS wiki — https://openzfs.org/
- man zpool — https://linux.die.net/man/8/zpool
- man zfs — https://linux.die.net/man/8/zfs
