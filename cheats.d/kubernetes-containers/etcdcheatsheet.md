---
Title: 📦 etcd — Distributed KV Store
Group: "Kubernetes & Containers"
Icon: 📦
Order: 24
tags:
  - etcd
  - kubernetes
  - kv-store
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

# 📦 etcd Cheatsheet

## Description

**etcd** is a distributed, consistent key-value store used as the **control-plane database of Kubernetes** (and by other systems). It provides Raft consensus, watches, and strong consistency. / **etcd** — распределённое согласованное KV-хранилище, используемое как **БД control plane Kubernetes** (и другими системами). Raft-consensus, watches, сильная консистентность.

**Common use cases / Типовые сценарии:**
- Kubernetes API object storage / Хранилище объектов Kubernetes API
- Service discovery / Service discovery
- Distributed locks / Распределённые блокировки
- Configuration store / Хранилище конфигурации

**Status:** Actively maintained (CNCF etcd). Alternatives: **ZooKeeper** (legacy), **Consul KV**, **Valkey/Redis** (no K8s control-plane role). / **Статус:** активно развивается; альтернативы — ZooKeeper, Consul KV.

**Default ports:** `2379/tcp` (client), `2380/tcp` (peer).  
**Paths:** data `/var/lib/etcd/`; client cert dir `/etc/kubernetes/pki/etcd/`; kube-apiserver endpoint `https://<ETCD_HOST>:2379`.

Cross-reference: [Kubernetes](kubectlcheatsheet.md), [OpenSSL](../security-crypto/opensslcheatsheet.md), [systemctl](../system-logs/systemctlcheatsheet.md).

---

## Installation

### Install etcd / Установка etcd

```bash
# RHEL/Rocky/Alma/Fedora
dnf install etcd

# Debian/Ubuntu
apt install etcd-server etcd-client

# Manual
ETCD_VER=3.5.16
wget https://github.com/etcd-io/etcd/releases/download/v${ETCD_VER}/etcd-v${ETCD_VER}-linux-amd64.tar.gz
tar xzf etcd-v${ETCD_VER}-linux-amd64.tar.gz
install -m755 etcd-v${ETCD_VER}-linux-amd64/{etcd,etcdctl,etcdutl} /usr/local/bin/
```

```bash
etcd --version
etcdctl version
```

---

## Configuration

### Main files / Основные файлы

`/etc/etcd/etcd.conf` (RHEL)

`/etc/default/etcd` (Debian)

`/etc/kubernetes/manifests/etcd.yaml` (kubeadm static pod)

`/etc/kubernetes/pki/etcd/`

### kubeadm-style config / Конфигурация в стиле kubeadm

`/etc/kubernetes/manifests/etcd.yaml`

```bash
spec:
  containers:
    - name: etcd
      image: registry.k8s.io/etcd:3.5.16-0
      command:
        - etcd
        - --listen-client-urls=https://127.0.0.1:2379
        - --advertise-client-urls=https://<ETCD_IP>:2379
        - --listen-peer-urls=https://<ETCD_IP>:2380
        - --initial-advertise-peer-urls=https://<ETCD_IP>:2380
        - --initial-cluster=default=https://<ETCD_IP>:2380
        - --cert-file=/etc/kubernetes/pki/etcd/server.crt
        - --key-file=/etc/kubernetes/pki/etcd/server.key
        - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
        - --client-cert-auth=true
        - --data-dir=/var/lib/etcd
```

> [!NOTE]
> On kubeadm clusters etcd runs as a static pod managed by kubelet — restart via `crictl` or kubelet, not always via systemd. / На кластерах kubeadm etcd — static pod; перезапуск через crictl/kubelet.

---

## Core Management

### etcdctl basics / Основы etcdctl

```bash
export ETCDCTL_API=3
export ENDPOINTS=https://127.0.0.1:2379
export CA=/etc/kubernetes/pki/etcd/ca.crt
export CERT=/etc/kubernetes/pki/etcd/server.crt
export KEY=/etc/kubernetes/pki/etcd/server.key

etcdctl --endpoints=$ENDPOINTS \
  --cacert=$CA --cert=$CERT --key=$KEY \
  endpoint health

etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  put /message/hello "world"
etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  get /message/hello
etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  del /message/hello
etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  ls --prefix /registry/services
```

### Member management / Управление участниками

```bash
etcdctl member list
etcdctl endpoint status --cluster
etcdctl endpoint hashkv --cluster
```

Sample `endpoint status`:

```text
127.0.0.1:2379, a1b2c3d4e5f6, 3.5.16, 25154968, 2, 10, 2, 10, false
```

---

## Sysadmin Operations

### Service / Сервис

```bash
# systemd (if not static pod)
systemctl status etcd
systemctl restart etcd

# kubeadm static pod
crictl ps | grep etcd
kubectl get pods -n kube-system -l component=etcd
```

### Metrics / Метрики

```bash
curl -s http://127.0.0.1:2379/metrics | grep -E '^etcd_(server|disk|wal)_'
```

### Logrotate / Ротация логов

`/etc/logrotate.d/etcd`

```bash
/var/log/etcd/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

> Note: many deployments log to journald rather than files. / Часто etcd логирует в journald, а не в файлы.

---

## Security

### Hardening checklist / Чек-лист ужесточения

1. Always enable client-cert-auth / Включайте client-cert-auth
2. Bind client API to localhost or private NIC / Привязывайте API к localhost/VPC
3. Restrict firewall: 2379/2380 only from control plane / Ограничьте firewall
4. Use dedicated disk or volume for data dir / Выделенный диск для data dir
5. Monitor disk fsync latency / Мониторьте latency диска
6. Snapshot regularly / Делайте регулярные снапшоты
7. Keep etcd version aligned with Kubernetes / Согласуйте версию с Kubernetes
8. Never expose etcd without TLS to untrusted networks / Не выставляйте etcd без TLS

```bash
etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  member list -w table
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
etcdctl --endpoints=$ENDPOINTS --cacert=$CA --cert=$CERT --key=$KEY \
  snapshot save /var/backups/etcd-$(date +%F).db
etcdctl snapshot status /var/backups/etcd-$(date +%F).db -w table
```

### Restore / Восстановление

```bash
# Offline restore into new data dir
etcdctl snapshot restore /var/backups/etcd-<DATE>.db \
  --data-dir=/var/lib/etcd-restored \
  --name=<NODE_NAME>
# Then point etcd to new data dir (maintenance window)
```

> [!CAUTION]
> Restore replaces cluster state from the snapshot point. Only use on a maintenance window and verify snapshot health first. / **Restore перезаписывает состояние кластера** — только в maintenance window.

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `member count is 1` / no quorum | Peer down | Restore peer or rejoin member |
| `etcdserver: request took too long` | Slow disk / fsync | Check `etcd_disk_wal_fsync_duration_seconds` |
| API server down | etcd health | `etcdctl endpoint health` |
| TLS errors | Cert expiry / wrong CA | Check cert dates, `--cacert` path |
| Data dir full | No GC / disk | Snapshot + compact; expand disk |

```bash
etcdctl endpoint health --cluster
journalctl -u etcd --no-pager -n 50
df -h /var/lib/etcd
```

---

## Comparison Tables

### Distributed KV stores / Распределённые KV-хранилища

| Store | Consistency | Typical use |
| :--- | :--- | :--- |
| **etcd** | Linearizable (Raft) | Kubernetes control plane |
| **ZooKeeper** | Linearizable (ZAB) | Legacy distributed systems |
| **Consul KV** | Strong (Raft) | Service mesh/config |
| **Redis** | Eventual (single-master) | Cache, sessions |

---

## Production Runbooks

### Runbook: etcd snapshot + compact / Снапшот и компакция etcd

1. Verify cluster health / Проверить health
2. Compact: `etcdctl compact <REV>` / Выполнить compact
3. Snapshot to backup dir / Снять snapshot
4. Store snapshot off-box / Сохранить snapshot вне хоста
5. Monitor disk reclaim after compact / Проверить освобождение диска

### Runbook: Restore etcd on new node / Восстановление etcd на новой ноде

1. Install matching etcd version / Установить совместимую версию
2. Stop API server traffic to this node / Остановить трафик к API
3. Snapshot restore to data dir / Выполнить snapshot restore
4. Start etcd with restored dir / Запустить etcd с восстановленным data dir
5. Validate API server connectivity / Проверить connectivity API server
6. Rejoin if needed via member add / При необходимости rejoin

---

## Documentation Links

- etcd docs — https://etcd.io/docs/
- etcd GitHub — https://github.com/etcd-io/etcd
- etcdctl — https://etcd.io/docs/v3.5/tutorials/how-to-use-etcdctl/
- Kubernetes etcd — https://kubernetes.io/docs/tasks/administer-cluster/setup-ha-etcd-without-kubeadm/
