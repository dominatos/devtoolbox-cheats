---
Title: 🐙 Ceph — Distributed Storage
Group: "Storage & FS"
Icon: 🐙
Order: 23
tags:
  - storage
  - ceph
  - distributed
  - rados
  - cephfs
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

# 🐙 Ceph Cheatsheet

## Description

**Ceph** is a unified, distributed storage platform providing **block (RBD)**, **object (RGW/S3)**, and **filesystem (CephFS)** on commodity hardware. Scales horizontally with CRUSH replication. / **Ceph** — единое распределённое хранилище: block (RBD), object (RGW/S3), filesystem (CephFS) на commodity hardware. Горизонтальное масштабирование через CRUSH.

**Common use cases / Типовые сценарии:**
- Cloud VM disk images (OpenStack/KVM) / Диски облачных VM
- S3-compatible object storage / S3-совместимое объектное хранилище
- Shared POSIX filesystem / Общая POSIX-файловая система
- VMware/KVM backup target / Целевой хост для бэкапов

**Status:** Actively maintained (Ceph / Red Hat). Alternatives: **MinIO**, **GlusterFS**, **Longhorn**, **ZFS + NFS**. / **Статус:** активно развивается; альтернативы — MinIO, GlusterFS, Longhorn.

**Default ports:** `6789/tcp` (monitor), `6800-7300/tcp` (OSD/MDS/MGR).  
**Paths:** `/etc/ceph/ceph.conf`, `/etc/ceph/ceph.client.admin.keyring`.

Cross-reference: [GlusterFS](glusterfscheatsheet.md), [ZFS](zfscheatsheet.md), [KVM](../../virtualization/virshcheatsheet.md), [Kubernetes](../kubernetes-containers/k8scheatsheet.md).

---

## Installation

### Install Ceph packages / Установка пакетов Ceph

```bash
# RHEL/Rocky/Alma
dnf install ceph ceph-common ceph-volume

# Debian/Ubuntu
apt install ceph ceph-common
```

### Quick mon/OSD via cephadm / Cephadm (quickstart)

```bash
cephadm bootstrap --mon-ip <MON_IP>
ceph orch apply mon --placement="3"
ceph orch apply osd --all-available-devices
```

```bash
ceph --version
ceph status
```

---

## Configuration

### Main files / Основные файлы

`/etc/ceph/ceph.conf`

`/etc/ceph/ceph.client.admin.keyring`

### ceph.conf / ceph.conf

`/etc/ceph/ceph.conf`

```bash
[global]
fsid = <FSID>
mon_initial_members = <MON1>,<MON2>,<MON3>
mon_host = <MON1_IP>,<MON2_IP>,<MON3_IP>
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 32
public_network = <PUBLIC_CIDR>
cluster_network = <CLUSTER_CIDR>
```

```bash
chmod 0600 /etc/ceph/ceph.client.admin.keyring
```

---

## Core Management

### Cluster status / Статус кластера

```bash
ceph status
ceph -s
ceph health
ceph osd status
ceph pg stat
ceph df
ceph osd df
```

### Pool management / Управление пулами

```bash
ceph osd pool ls detail
ceph osd pool create <POOL_NAME> <PG_NUM>
ceph osd pool set <POOL_NAME> size 3
ceph osd pool set <POOL_NAME> min_size 2
ceph osd pool application enable <POOL_NAME> rbd
ceph osd pool application enable <POOL_NAME> rgw
ceph osd pool application enable <POOL_NAME> cephfs
```

---

## Sysadmin Operations

### RBD (block) / RBD (блок)

```bash
rbd create <POOL>/<IMAGE> --size 10G
rbd ls <POOL>
rbd info <POOL>/<IMAGE>
rbd resize <POOL>/<IMAGE> --size 20G
rbd snap create <POOL>/<IMAGE>@<SNAP>
rbd snap ls <POOL>/<IMAGE>
rbd rm <POOL>/<IMAGE>
```

### CephFS / CephFS

```bash
ceph fs ls
ceph fs status <FS_NAME>
ceph mds stat
# Mount:
mount -t ceph <MON_IP>:6789:/ <MOUNTPOINT> -o name=admin,secretfile=/etc/ceph/ceph.client.admin.keyring
```

### RGW (object) / RGW (объект)

```bash
ceph rgw admin user create <USER> --access-key <AK> --secret <SK>
s3cmd --access_key=<AK> --secret_key=<SK> --host=<RGW_HOST> ls s3://<BUCKET>
```

### Logs / Логи

```bash
journalctl -u ceph-mon@<MON> --no-pager -n 50
journalctl -u ceph-osd@<OSD_ID> --no-pager -n 50
ceph -w
```

### Logrotate / Ротация логов

`/etc/logrotate.d/ceph`

```bash
/var/log/ceph/*.log {
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

1. Use cephx authentication / Используйте cephx
2. Protect admin keyring (0600) / Защитите admin keyring
3. Separate public/cluster networks / Разделите public/cluster сети
4. Monitor HEALTH_OK / Мониторьте HEALTH_OK
5. Regular scrub and deep-scrub / Регулярные scrub/deep-scrub
6. Keep Ceph updated / Обновляйте Ceph

```bash
ceph auth ls
ceph auth get-or-create client.<USER> mon 'profile rbd' osd 'profile rbd pool=<POOL>'
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `HEALTH_WARN` | Degraded PGs / OSD down | Check OSDs; recover |
| `HEALTH_ERR` | Critical failure | Check mon quorum |
| Mount timeout | MDS down | Check `ceph mds stat` |
| Slow ops | Network / disk | `ceph osd perf`; scrub |
| Keyring errors | Wrong permissions | Fix keyring path/perm |

```bash
ceph health detail
ceph osd tree
ceph pg dump_stuck
ceph -w
```

---

## Comparison Tables

### Distributed storage / Распределённые хранилища

| System | Protocols | Best for |
| :--- | :--- | :--- |
| **Ceph** | RBD, S3, CephFS | Unified scale-out |
| **GlusterFS** | NFS, SMB | Simple shared FS |
| **MinIO** | S3 only | Object-only |
| **Longhorn** | PVC (K8s) | K8s block |

---

## Production Runbooks

### Runbook: Bootstrap cluster / Инициализация кластера

1. Prepare nodes; sync time / Подготовить узлы; синхронизировать время
2. Install cephadm; bootstrap mon / Установить cephadm; bootstrap mon
3. Add mons (3+) / Добавить мониторы (3+)
4. Add OSDs on available devices / Добавить OSD-ы
5. Verify HEALTH_OK / Проверить HEALTH_OK
6. Create pools; enable apps / Создать пулы; включить приложения
7. Configure clients (keyring) / Настроить клиенты

### Runbook: OSD disk replacement / Замена диска OSD

1. `ceph osd out <OSD_ID>` / Вывести OSD
2. Remove from tree; replace disk / Удалить; заменить диск
3. `ceph-volume lvm zap <DEVICE>` / Очистить устройство
4. Add new OSD via cephadm/orch / Добавить новый OSD
5. Wait for rebalance / Дождаться rebalance
6. Verify HEALTH_OK / Проверить HEALTH_OK

---

## Documentation Links

- Ceph docs — https://docs.ceph.com/en/latest/
- Cephadm — https://docs.ceph.com/en/latest/cephadm/
- RBD — https://docs.ceph.com/en/latest/rbd/
- CephFS — https://docs.ceph.com/en/latest/cephfs/
