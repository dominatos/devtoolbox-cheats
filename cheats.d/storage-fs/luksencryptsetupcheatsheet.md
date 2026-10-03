---
Title: 🔒 LUKS — Full-Disk Encryption
Group: "Storage & FS"
Icon: 🔒
Order: 20
tags:
  - storage
  - luks
  - encryption
  - security
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

# 🔒 LUKS / cryptsetup Cheatsheet

## Description

**LUKS** (Linux Unified Key Setup) is the standard full-disk/partition encryption layer on Linux. **cryptsetup** manages LUKS containers: open/close, key slots, backup of LUKS headers, and reencryption. / **LUKS** — стандарт шифрования дисков/разделов в Linux. **cryptsetup** управляет контейнерами: open/close, слоты ключей, бэкап заголовков.

**Common use cases / Типовые сценарии:**
- Laptop/desktop FDE / Полное шифрование диска (FDE)
- Encrypt data volumes for DBs / Шифрование томов для БД
- USB/portable encrypted media / Переносные зашифрованные носители
- Compliance (PCI, GDPR) data-at-rest / Комплаенс: шифрование данных в покое

**Status:** LUKS2 is the current standard (LUKS1 legacy). Alternatives: **fscrypt** (filesystem-level, e.g. ext4/f2fs), **eCryptfs** (legacy), **ZFS encryption** (dataset-level), **BitLocker** (Windows). / **Статус:** LUKS2 — текущий стандарт.

**Paths:** partition `/dev/<DEVICE>`; header backup `luks-header-backup.img`; mapping `/dev/mapper/<NAME>`.

Cross-reference: [mdadm RAID](mdadmcheatsheet.md), [LVM](lvmcheatsheet.md), [disk](diskcheatsheet.md), [mount](mountcheatsheet.md).

---

## Installation

### Install cryptsetup / Установка cryptsetup

```bash
# Debian/Ubuntu
apt install cryptsetup cryptsetup-bin

# RHEL/Rocky/Alma/Fedora
dnf install cryptsetup-luks2

# SUSE
zypper install cryptsetup
```

```bash
cryptsetup --version
cryptsetup --help | head
```

---

## Configuration

### LUKS2 format / Форматирование LUKS2

```bash
# Encrypt partition (destroys data — verify device!)
cryptsetup luksFormat /dev/<DEVICE>

# Non-interactive with key file (CI/lab)
cryptsetup luksFormat --type luks2 \
  --cipher aes-xts-plain64 --key-size 512 \
  --pbkdf argon2i --pbkdf-memory 524288 \
  --key-file /root/luks.key \
  /dev/<DEVICE>
```

> [!CAUTION]
> `luksFormat` **erases** the LUKS header and makes existing data unrecoverable without backup. Double-check `/dev/<DEVICE>`. / **`luksFormat` уничтожает заголовок** — данные станут недоступны без бэкапа. Проверьте устройство дважды.

### Open and map / Открытие и маппинг

```bash
cryptsetup open /dev/<DEVICE> <NAME>
# or
cryptsetup open /dev/<DEVICE> crypt_root

ls -la /dev/mapper/
```

### Key slots / Слоты ключей

```bash
cryptsetup luksDump /dev/<DEVICE>
cryptsetup luksAddKey /dev/<DEVICE>          # add passphrase
cryptsetup luksAddKey /dev/<DEVICE> /root/luks.key
cryptsetup luksKillSlot /dev/<DEVICE> 1      # remove slot 1
cryptsetup luksChangeKey /dev/<DEVICE>       # rotate passphrase
```

### Header backup / Бэкап заголовка

```bash
# LUKS2 header contains key material metadata — BACK THIS UP
cryptsetup luksHeaderBackup /dev/<DEVICE> --header-backup-file /var/backups/luks-<DEVICE>.header
cryptsetup luksHeaderRestore --header-backup-file /var/backups/luks-<DEVICE>.header /dev/<DEVICE>
```

> [!WARNING]
> Without a header backup, a corrupted header means **permanent loss** of encrypted data (all slots). Store headers offline and separately from the disk. / Без бэкапа заголовка повреждение = **потеря всех данных** навсегда.

### LUKS on LVM / LUKS поверх LVM

```bash
# PV on encrypted partition
cryptsetup open /dev/<DEVICE> crypt_pv
pvcreate /dev/mapper/crypt_pv
vgcreate vg_enc /dev/mapper/crypt_pv
lvcreate -L 100G -n data vg_enc
mkfs.ext4 /dev/mapper/vg_enc-data
mount /dev/mapper/vg_enc-data /mnt/data
```

### fstab and systemd / fstab и systemd

`/etc/fstab`

```bash
# Using UUID of the LUKS mapping is fragile — prefer systemd units
# /dev/mapper/data  /mnt/data  ext4  defaults  0  2
```

`/etc/systemd/system/mnt-data.mount`

```ini
[Unit]
Description=Encrypted data volume
After=cryptsetup.target

[Mount]
What=/dev/mapper/data
Where=/mnt/data
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
```

---

## Core Management

### Open / close lifecycle / Жизненный цикл open/close

```bash
cryptsetup open /dev/<DEVICE> <NAME>
mount /dev/mapper/<NAME> /mnt/<POINT>
umount /mnt/<POINT>
cryptsetup close <NAME>
```

### Status / Статус

```bash
cryptsetup status <NAME>
cryptsetup luksDump /dev/<DEVICE>
lsblk -f
```

Sample `cryptsetup status`:

```text
/dev/mapper/crypt_data is active and is in use.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 bits
  key location: keyring
  device:  /dev/sdb1
```

### Reencryption / Перешифрование

```bash
# Offline reencryption (legacy approach — needs spare space on some paths)
cryptsetup reencrypt /dev/<DEVICE>

# LUKS2 reencryption in background (careful with I/O)
cryptsetup reencrypt --reduce-device-size 16M /dev/<DEVICE>
```

> [!NOTE]
> Prefer online reencryption only when required (e.g., cipher/keysize upgrade). Schedule for maintenance windows. / Перешифрование — только в maintenance window.

### Keyfile management / Управление keyfile

```bash
# Generate strong keyfile
dd if=/dev/urandom of=/root/luks.key bs=4096 count=1
chmod 0400 /root/luks.key
cryptsetup luksAddKey /dev/<DEVICE> /root/luks.key
# Store keyfile off-host (e.g., password manager, HSM, config vault)
```

---

## Sysadmin Operations

### Filesystem on mapped device / ФС на маппинге

```bash
mkfs.ext4 /dev/mapper/<NAME>
mkfs.xfs /dev/mapper/<NAME>
mkfs.btrfs /dev/mapper/<NAME>
```

### Mount with options / Монтирование с опциями

```bash
mount -o noatime,nodiratime /dev/mapper/<NAME> /mnt/<POINT>
```

### Logrotate / Ротация логов

LUKS itself does not produce application logs; rely on journal for cryptsetup events.

```bash
journalctl -u systemd-cryptsetup@<NAME> --no-pager -n 50
```

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Use LUKS2 + argon2i PBKDF + AES-XTS-512 / Используйте LUKS2, argon2i, aes-xts-plain64 512
2. Separate passphrase vs keyfile threat model / Разделите модели угроз passphrase и keyfile
3. Backup LUKS headers offline / Бэкапируйте заголовки офлайн
4. Test unlock before relying on automation / Проверьте unlock до автоматизации
5. Prefer TPM-bound keys for laptops where threat model allows / TPM для ноутбуков, если допустимо
6. Limit key slots; kill unused slots / Ограничьте слоты ключей
7. Never store keyfile on the encrypted volume itself / Не храните keyfile на шифрованном томе

```bash
# Inspect key material usage
cryptsetup luksDump /dev/<DEVICE> | grep -A2 "Key Slot"
```

### Header size / Размер заголовка

```bash
# LUKS2 header is typically ~16MB — keep free space before partition
# cryptsetup reencrypt --reduce-device-size 16M ...
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
# 1) LUKS header (CRITICAL)
cryptsetup luksHeaderBackup /dev/<DEVICE> --header-backup-file /var/backups/luks-<DEVICE>.header

# 2) Filesystem-level backup of mounted data
tar czf /var/backups/data-$(date +%F).tar.gz -C /mnt/data .

# 3) Document key slots and unlock procedure
```

### Restore / Восстановление

```bash
# On new/replaced disk
cryptsetup luksHeaderRestore --header-backup-file /var/backups/luks-<DEVICE>.header /dev/<NEW_DEVICE>
cryptsetup open /dev/<NEW_DEVICE> <NAME>
fsck -N /dev/mapper/<NAME>   # dry-run check
mount /dev/mapper/<NAME> /mnt/<POINT>
```

> [!CAUTION]
> Header restore **overwrites** the current header on the target device. Verify the target device first. / **Restore заголовка перезаписывает** заголовок на целевом устройстве — проверьте устройство.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Device <dev> is not a valid LUKS device` | Wrong device / bad header | Try header backup restore |
| `No key available with this passphrase` | Wrong passphrase / damaged slot | Try other slots; check header backup |
| Open succeeds but mount fails | Filesystem not created / dirty | `fsck -N /dev/mapper/<NAME>` |
| systemd-cryptsetup fails at boot | Missing key file / wrong path | Check initramfs key path; dropbear/TPM unlock |
| Reencryption interrupted | Power loss / crash | Do not interrupt; use journal to check state; re-run carefully |

```bash
cryptsetup status <NAME>
cryptsetup luksDump /dev/<DEVICE>
journalctl -u systemd-cryptsetup@<NAME> -b
blkid /dev/mapper/<NAME>
```

---

## Comparison Tables

### Encryption layers / Слои шифрования

| Layer | Scope | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **LUKS** | Block device | Full-disk, OS-independent | Needs unlock at boot |
| **fscrypt** | File/dir (ext4/f2fs) | Per-directory, no unlock ceremony | FS-dependent |
| **eCryptfs** | Per-file | Legacy | Deprecated-ish, complexity |
| **ZFS encryption** | Dataset | Native, snapshot-friendly | ZFS dependency |
| **dm-crypt plain** | Block device | No header | No key slots, weaker |

---

## Production Runbooks

### Runbook: Encrypt new data volume / Шифрование нового тома

1. Verify device with `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT` / Проверить устройство
2. `cryptsetup luksFormat /dev/<DEVICE>` (accept LUKS2 defaults) / Форматировать
3. `cryptsetup open /dev/<DEVICE> data`
4. `mkfs.ext4 /dev/mapper/data`
5. `mkdir -p /mnt/data && mount /dev/mapper/data /mnt/data`
6. Backup header + persist via fstab/systemd unit / Бэкап заголовка и автозапуск
7. Test reboot unlock procedure / Проверить unlock после reboot

### Runbook: Rotate LUKS passphrase / Ротация пароля LUKS

1. Ensure at least one working unlock method / Убедиться, что есть рабочий метод
2. `cryptsetup luksChangeKey /dev/<DEVICE>` / Сменить ключ
3. Verify new passphrase opens the volume / Проверить открытие
4. Kill old slot if replaced: `luksKillSlot` / Удалить старый слот
5. Update keyfile in vault if used / Обновить keyfile в хранилище
6. Re-test boot unlock on next reboot / Проверить boot unlock

---

## Documentation Links

- cryptsetup — https://gitlab.com/cryptsetup/cryptsetup
- LUKS2 — https://wiki.archlinux.org/title/Dm-crypt/Device_encryption
- systemd-cryptsetup — https://www.freedesktop.org/software/systemd/man/systemd-cryptsetup-generator.html
- Debian dm-crypt — https://wiki.debian.org/LVM/dm-crypt
- Red Hat disk encryption — https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/encrypting_and_decrypting_data_on_disks
