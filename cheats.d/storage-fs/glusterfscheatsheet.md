---
Title: 📦 GlusterFS — Scale-out FS
Group: "Storage & FS"
Icon: 📦
Order: 24
tags:
  - storage
  - glusterfs
  - filesystem
  - distributed
  - nas
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
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 📦 GlusterFS Cheatsheet

## Description

**GlusterFS** is a **scale-out distributed filesystem** that aggregates storage from multiple servers into a single global namespace. Supports NFS/SMB export and Kubernetes via CSI. / **GlusterFS** — масштабируемая распределённая файловая система, объединяющая хранилища нескольких серверов в одно глобальное пространство. Поддерживает NFS/SMB и Kubernetes через CSI.

**Common use cases / Типовые сценарии:**
- Shared POSIX storage across nodes / Общее POSIX-хранилище
- NFS/SMB for VM images / NFS/SMB для образов VM
- Container persistent volumes / Persistent volumes для контейнеров
- Media / archive distribution / Распределение медиа/архивов

**Status:** Maintained (Red Hat / gluster community). Alternatives: **Ceph**, **ZFS + NFS**, **MinIO**, **Longhorn**. / **Статус:** поддерживается (Red Hat / community); альтернативы — Ceph, ZFS+NFS, MinIO.

**Default ports:** `24007/tcp` (brick), `49152+` (NFS).  
**Paths:** `/var/lib/glusterd/`, bricks at `/bricks/<VOLNAME>/brick1`.

Cross-reference: [Ceph](cephcheatsheet.md), [ZFS](zfscheatsheet.md), [Samba](sambacheatsheet.md), [NFS](nfscheatsheet.md).

---

## Installation

### Install GlusterFS / Установка GlusterFS

```bash
# Debian/Ubuntu
apt install glusterfs-server glusterfs-client

# RHEL/Rocky/Alma
dnf install glusterfs-server glusterfs-fuse
```

```bash
systemctl enable --now glusterd
gluster --version
```

---

## Configuration

### Hosts and firewall / Хосты и firewall

```bash
# /etc/hosts on all nodes
<IP1> gluster1
<IP2> gluster2
<IP3> gluster3
```

```bash
firewall-cmd --permanent --add-service=glusterfs
firewall-cmd --reload
```

### Create volume / Создание тома

```bash
gluster peer probe <REMOTE_HOST>
gluster peer status

# Distributed-replicated volume (3 nodes, replica 3)
gluster volume create <VOLNAME> \
  replica 3 \
  transport tcp \
  gluster1:/bricks/<VOLNAME>/brick1 \
  gluster2:/bricks/<VOLNAME>/brick1 \
  gluster3:/bricks/<VOLNAME>/brick1

gluster volume start <VOLNAME>
```

---

## Core Management

### Volume status / Статус тома

```bash
gluster volume list
gluster volume info <VOLNAME>
gluster volume status <VOLNAME>
gluster volume status <VOLNAME> clients
gluster volume status <VOLNAME> detail
gluster volume stats <VOLNAME>
```

### Volume operations / Операции с томом

```bash
gluster volume set <VOLNAME> nfs.disable off
gluster volume set <VOLNAME> performance.cache-size 512MB
gluster volume set <VOLNAME> nfs.export-volumes on
gluster volume add-brick <VOLNAME> replica 3 \
  gluster4:/bricks/<VOLNAME>/brick1
gluster volume remove-brick <VOLNAME> \
  gluster1:/bricks/<VOLNAME>/brick1 force
gluster volume rebalance <VOLNAME> start
gluster volume rebalance <VOLNAME> status
```

---

## Sysadmin Operations

### Mount / Монтирование

```bash
mkdir -p /mnt/gluster
mount -t glusterfs gluster1:/<VOLNAME> /mnt/gluster
# Or via FUSE on any node
gluster mount gluster1:/<VOLNAME> /mnt/gluster
```

### NFS/SMB export / Экспорт NFS/SMB

```bash
gluster volume set <VOLNAME> nfs.disable off
# Export via standard NFS/exports or Samba share
```

### Logs / Логи

```bash
journalctl -u glusterd --no-pager -n 50
ls /var/log/glusterfs/
tail -f /var/log/glusterfs/<VOLNAME>.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/glusterfs`

```bash
/var/log/glusterfs/*.log {
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

1. Use replica 3+ for production / Используйте replica 3+ в production
2. Restrict management network to trusted hosts / Ограничьте management-сеть
3. Use TLS for transport if possible / Используйте TLS при возможности
4. Monitor brick health / Мониторьте здоровье brick-ов
5. Keep GlusterFS patched / Обновляйте GlusterFS
6. Separate cluster and client traffic / Разделяйте cluster и client traffic

```bash
gluster volume set <VOLNAME> transport.ssl on   # if supported
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Peer probe fails | DNS / firewall | Check hosts, ports |
| Volume won't start | Brick down | Check brick process |
| Split-brain | Network partition | `gluster volume heal <VOL> info` |
| Slow reads | Replication lag / cache | Rebalance; tune performance |
| Mount hangs | Brick unreachable | Check node/brick health |

```bash
gluster volume status <VOLNAME>
gluster peer status
gluster volume heal <VOLNAME> info
```

---

## Comparison Tables

### Scale-out filesystems / Масштабируемые ФС

| System | Protocol | Replication |
| :--- | :--- | :--- |
| **GlusterFS** | NFS, SMB, FUSE | Replicate/EC |
| **Ceph** | RBD, S3, CephFS | CRUSH replica |
| **ZFS** | ZFS send, NFS | Mirror/raidz |
| **Longhorn** | PVC | Replica volumes |

---

## Production Runbooks

### Runbook: Create HA volume / Создание HA-тома

1. Install glusterfs on all nodes; enable glusterd / Установить glusterd
2. Configure /etc/hosts; open firewall / Настроить hosts и firewall
3. `gluster peer probe` between nodes / Подключить узлы
4. Create brick directories on each node / Создать brick-каталоги
5. `gluster volume create ... replica 3` / Создать том
6. `gluster volume start` / Запустить том
7. Mount test from client / Проверить mount
8. Document volume and brick layout / Задокументировать раскладку

### Runbook: Heal split-brain / Лечение split-brain

1. Identify heal status: `gluster volume heal <VOL> info` / Проверить heal
2. Ensure network connectivity between nodes / Восстановить сеть
3. Run heal: `gluster volume heal <VOL> start` / Запустить heal
4. `gluster volume heal <VOL> info --heal-failed` / Проверить heal-failed
5. For stubborn files, inspect brick paths / Проверить brick-файлы
6. Document root cause / Задокументировать причину

---

## Documentation Links

- GlusterFS docs — https://docs.gluster.org/
- GlusterFS GitHub — https://github.com/gluster/glusterfs
- GlusterFS wiki — https://wiki.gluster.org/
