---
Title: 📁 NFS — Network File System
Group: "Storage & FS"
Icon: 📁
Order: 7
tags:
  - storage
  - filesystem
  - nfs
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#Description)
- [⚙️ Configuration](#⚙️%20Configuration)
- [🛠 Server Setup](#🛠%20Server%20Setup)
- [🖥 Client Setup](#🖥%20Client%20Setup)
- [🔧 Sysadmin Operations](#🔧%20Sysadmin%20Operations)
- [📈 Performance Monitoring](#📈%20Performance%20Monitoring)
- [📊 Mount Options Comparison](#📊%20Mount%20Options%20Comparison)
- [🚨 Troubleshooting](#🚨%20Troubleshooting)
- [🔒 Security](#🔒%20Security)
- [🔐 TLS Encryption](#🔐%20TLS%20Encryption)
- [⚙️ Advanced Configuration](#⚙️%20Advanced%20Configuration)
- [📖 Production Runbook: NFS for OpenSearch Snapshots](#📖%20Production%20Runbook:%20NFS%20for%20OpenSearch%20Snapshots)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

# 📁 NFS Cheatsheet (Network File System)

## Description

**NFS (Network File System)** is a distributed file system protocol that allows a client computer to access files over a network as if they were local. Originally developed by Sun Microsystems (1984), it remains the standard for Unix/Linux shared storage in data centers, clusters, and backup environments. NFSv4.2 is the current recommended version, offering better security (Kerberos), performance (delegations, pNFS), and features (copy offload, space reservation). / **NFS (Network File System)** — распределённая файловая система, позволяющая клиентам обращаться к файлам по сети как к локальным. Рекомендуемая текущая версия — NFSv4.2 с улучшенной безопасностью (Kerberos) и производительностью.

**Status:** Actively maintained and widely used in enterprise Linux environments. NFSv3 remains common for legacy compatibility; NFSv4.x is preferred for new deployments. Alternatives: SMB/CIFS (Windows interoperability), GlusterFS/Ceph (scale-out), object storage (S3-compatible). / **Статус:** Активно используется в корпоративных Linux-средах. NFSv3 — для совместимости со старыми системами; NFSv4.x — предпочтителен для новых развёртываний.

**Default Ports:**
| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| **2049** | TCP/UDP | NFS (main file access) |
| 111 | TCP/UDP | rpcbind (port mapper) |
| 20048 | TCP/UDP | mountd (NFSv3 mount protocol) |
| 20047 | TCP/UDP | nfsd (NFSv4 callback) |
| 662 | TCP/UDP | lockd (file locking, NFSv3) |

**Package Format:** N/A (network filesystem protocol)

---

## ⚙️ Configuration

### Main Configuration Files
`/etc/exports`
`/etc/exports.d/*.exports`
`/etc/fstab` (client mounts)
`/etc/nfs.conf` (NFSv4 server config)

### NFSv4 Server Config
`/etc/nfs.conf`

```ini
[nfsd]
vers4 = y
vers3 = y          # Keep v3 for compatibility / Оставить v3 для совместимости
threads = 8        # NFS worker threads / Рабочие потоки NFS
port = 2049
```

---

## 🛠 Server Setup

### Install Packages

```bash
# RHEL/AlmaLinux/Rocky
sudo dnf install -y nfs-utils                              # Install NFS server / Установить NFS-сервер

# Ubuntu/Debian
sudo apt update && sudo apt install -y nfs-kernel-server   # Install NFS server / Установить NFS-сервер
```

### Prepare Export Directory

```bash
sudo mkdir -p <EXPORT_PATH>                                # Create export dir / Создать каталог экспорта
sudo chown <SERVICE_USER>:<SERVICE_GROUP> <EXPORT_PATH>    # Set ownership (e.g. opensearch:opensearch) / Владелец
sudo chmod 750 <EXPORT_PATH>                               # Restrict permissions / Ограничить права
```

### Configure Exports
`/etc/exports`

```bash
# Export whole subnet (recommended for clusters)
<EXPORT_PATH> <SUBNET_IP>/24(rw,sync,no_subtree_check)

# Or list specific IPs
<EXPORT_PATH> <CLIENT_IP_1>(rw,sync,no_subtree_check) <CLIENT_IP_2>(rw,sync,no_subtree_check)
```

| Option | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `rw` | Read-write access | Доступ на чтение-запись |
| `ro` | Read-only access | Только чтение |
| `sync` | Sync writes (safe, slower) | Синхронная запись (безопасно, медленнее) |
| `async` | Async writes (faster, risk) | Асинхронная запись (быстрее, риск) |
| `no_subtree_check` | Skip subtree checks (faster) | Пропустить проверки поддерева |
| `root_squash` | Map root → nobody (default) | root → nobody (по умолчанию) |
| `no_root_squash` | Allow remote root | Разрешить удалённый root |
| `insecure` | Allow non-reserved ports | Разрешить незарезервированные порты |

> [!WARNING]
> `no_root_squash` gives remote root full access to the export. Use only when absolutely required (e.g., some virtualization clusters). / `no_root_squash` даёт удалённому root полный доступ. Используйте только при крайней необходимости.
> `no_root_squash` даёт удалённому root полный доступ к экспорту. Используйте только при необходимости.

### Apply Exports & Start Service

```bash
sudo exportfs -ra                                        # Re-read exports / Перечитать экспорт
sudo systemctl enable --now nfs-server                   # Enable & start / Включить и запустить
```

### Firewall (RHEL/Alma/Rocky)

```bash
sudo firewall-cmd --add-service=nfs --permanent          # NFS port / Порт NFS
sudo firewall-cmd --add-service=mountd --permanent       # Mount daemon / Демон монтирования
sudo firewall-cmd --add-service=rpc-bind --permanent     # RPC bind / RPC bind
sudo firewall-cmd --reload                               # Reload firewall / Перезагрузить firewall
```

### SELinux (RHEL/Alma/Rocky)

```bash
sudo setsebool -P nfs_export_all_rw 1                    # Allow NFS export RW / Разрешить экспорт NFS RW
sudo semanage fcontext -a -t public_content_rw_t "<EXPORT_PATH>(/.*)?"  # Set context / Установить контекст
sudo restorecon -Rv <EXPORT_PATH>                        # Apply context / Применить контекст
```

> **Note:** If `semanage` is not installed: `sudo dnf install -y policycoreutils-python-utils`. / Если `semanage` не установлен: `sudo dnf install -y policycoreutils-python-utils`.

### Server Self-Check

```bash
sudo exportfs -v                                         # List active exports / Список активных экспортов
ss -tulpn | grep 2049                                    # Check NFS port / Проверить порт NFS
rpcinfo -t <NFS_HOST> nfs                                # Check NFS version / Проверить версию NFS
```

**Sample output / Пример вывода:**
```
program vers proto   port  service
  100003    3    tcp   2049  nfs
  100003    4    tcp   2049  nfs
  100227    3    tcp   2049  nfs_acl
```

---

## 🖥 Client Setup

### Install Packages

```bash
# RHEL/AlmaLinux/Rocky
sudo dnf install -y nfs-utils                            # Install NFS client / Установить NFS-клиент

# Ubuntu/Debian
sudo apt update && sudo apt install -y nfs-common        # Install NFS client / Установить NFS-клиент
```

### Create Mount Point

```bash
sudo mkdir -p <MOUNT_POINT>                              # Create mountpoint / Создать точку монтирования
```

### Test Manual Mount

```bash
# Try NFSv4.2 first (recommended)
sudo mount -t nfs -o nfsvers=4.2 <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>

# Fallback: NFSv4.1
sudo mount -t nfs -o nfsvers=4.1 <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>

# Fallback: NFSv3 (legacy)
sudo mount -t nfs -o nfsvers=3 <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>
```

**Verify mount:**
```bash
mount | grep <MOUNT_POINT>                               # Check mount / Проверить монтирование
ls -ld <MOUNT_POINT>                                     # Check directory / Проверить каталог
touch <MOUNT_POINT>/client_check.txt                     # Write test file / Тестовый файл
ls -l <MOUNT_POINT>                                      # List contents / Список содержимого
```

### Permanent Mount (fstab)
`/etc/fstab`

```bash
# Standard NFS mount (boots with system)
<NFS_HOST>:<EXPORT_PATH>  <MOUNT_POINT>  nfs  rw,noatime,hard,intr,_netdev,nfsvers=4.2  0  0

# With systemd automount (mounts on access, unmounts after idle)
<NFS_HOST>:<EXPORT_PATH>  <MOUNT_POINT>  nfs  rw,noatime,nodiratime,vers=4,nofail,_netdev  0  0

# Simple NFSv4 with nofail (boot continues even if NFS unavailable)
<NFS_HOST>:<EXPORT_PATH>  <MOUNT_POINT>  nfs  tcp,vers=4,noatime,nodiratime,nofail,_netdev  0  0

# Production example: NFSv3 with tuned timeout
<NFS_HOST>:<EXPORT_PATH>  <MOUNT_POINT>  nfs  rw,noatime,nodiratime,vers=3,rsize=131072,wsize=524288,hard,tcp,timeo=600,retrans=5,sec=sys,noauto,x-systemd.automount,x-systemd.idle-timeout=1min  0  0
```

**Apply:**
```bash
sudo mount -a                                           # Mount all from fstab / Смонтировать всё из fstab
sudo mount -fav                                         # Test (fake) mount / Тестовое монтирование
```

> [!TIP]
> - Use `_netdev` if network comes up after filesystems at boot.
> - Use `x-systemd.automount` instead of `_netdev` for more reliable auto-mount on modern systemd systems.
> - For latency-sensitive apps: `hard,intr` and/or `timeo=600,retrans=2`.
> - **Test fstab changes before rebooting** — a bad entry can prevent boot.
> - Используйте `_netdev`, если сеть поднимается позже ФС. Для надёжного автомонта — `x-systemd.automount`. Для чувствительных к таймаутам приложений — `hard,intr` и/или `timeo=600,retrans=2`.

---

## 🔧 Sysadmin Operations

### List NFS Exports

```bash
showmount -e <NFS_HOST>                                 # List exports on server / Список экспортов на сервере
showmount -e <NFS_HOST> -a                               # All clients per export / Все клиенты по экспорту
```

**Sample output / Пример вывода:**
```
Export list for <NFS_HOST>:
/ifs/shared/nfs_shares/accreditamentostrutture_test *
/mnt/backups                      <SUBNET_IP>/24
```

### Check Automount Units

```bash
systemctl list-units --type=automount                   # List automount units / Список automount-юнитов
systemctl status <MOUNT_POINT>                          # Check automount status / Статус automount
```

### Check NFS Version (Client)

```bash
rpcinfo -t <NFS_HOST> nfs                               # TCP check / Проверка по TCP
rpcinfo -u <NFS_HOST> nfs                               # UDP check / Проверка по UDP
nfsstat -c                                               # Client NFS stats / Статистика NFS-клиента
nfsstat -s                                               # Server NFS stats / Статистика NFS-сервера
```

### Unmount

```bash
sudo umount <MOUNT_POINT>                               # Unmount / Размонтировать
sudo umount -l <MOUNT_POINT>                            # Lazy unmount / Отложенное размонтирование
```

> [!NOTE]
> Lazy unmount (`-l`) detaches immediately but cleans up when no longer in use. Useful if processes still hold files open. / Отложенное размонтирование (`-l`) сразу отключает, но очищает при завершении использования.
> Отложенное размонтирование (`-l`) сразу отключает, но очищает при завершении использования.

### Logs
- **NFS server logs:** `journalctl -u nfs-server`
- **Mount logs:** `journalctl -u <MOUNT_POINT>`
- **RSync logs (if used for sync jobs):** `<RSYNC_LOG_PATH>`

```bash
tail -f /var/log/rsync-<JOB_NAME>.log                  # Monitor rsync job / Мониторинг задачи rsync
awk 'NR==1 || $7 != 0' <RSYNC_LOG_PATH> | less         # Show errors only (skip exit=0) / Только ошибки (без exit=0)
```

---

## 📈 Performance Monitoring

### nfsstat — NFS Statistics

```bash
nfsstat                                                  # All NFS stats / Все статистики NFS
nfsstat -c                                               # Client-only stats / Статистика клиента
nfsstat -s                                               # Server-only stats / Статистика сервера
nfsstat -m                                               # Per-mount info / Информация по монтированиям
nfsstat -o all                                           # All facilities (nfs,rpc,net,fh,rc) / Все разделы
nfsstat -2 -3 -4                                        # Specific NFS versions / Конкретные версии NFS
nfsstat -Z 5                                             # Real-time (5s interval) / Реальное время (интервал 5с)
```

**Key metrics / Ключевые метрики:**
| Metric | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `calls` | Total NFS calls | Всего NFS-вызовов |
| `badcalls` | Failed RPC calls | Неудачные RPC-вызовы |
| `retrans` | Retransmissions | Повторные передачи |
| `authreferrals` | Auth retries | Повторы аутентификации |

### nfsiostat — Per-Mount I/O Stats

```bash
nfsiostat                                                # All NFS mounts / Все NFS-монтирования
nfsiostat <MOUNT_POINT>                                  # Specific mount / Конкретное монтирование
nfsiostat 5 10                                           # 10 reports, 5s interval / 10 отчётов, интервал 5с
nfsiostat -m                                             # Show in MB/s / Показать в MB/s
nfsiostat -s                                             # Sort by ops/sec / Сортировать по операциям/с
nfsiostat -a                                             # Attribute cache stats / Статистика кэша атрибутов
nfsiostat -d                                             # Directory ops stats / Статистика каталогов
```

**Key columns / Ключевые столбцы:**
| Column | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `op/s` | Operations per second | Операций в секунду |
| `kB/s` | Throughput (read/write) | Пропускная способность (чтение/запись) |
| `retrans` | Retransmission count | Количество повторных передач |
| `avg RTT (ms)` | Average round-trip time | Среднее время отклика |
| `avg exe (ms)` | Average execution time | Среднее время выполнения |
| `errors` | Operations with errors | Операции с ошибками |

### mountstats — Detailed Mount Info

```bash
mountstats <MOUNT_POINT>                                 # Detailed stats for mount / Детальная статистика
mountstats -n nfs <MOUNT_POINT>                         # NFS-specific stats / NFS-специфичная статистика
```

### Raw Proc Stats

```bash
cat /proc/net/rpc/nfsd                                  # Server stats (raw) / Статистика сервера (raw)
cat /proc/net/rpc/nfs                                   # Client stats (raw) / Статистика клиента (raw)
cat /proc/self/mountstats                               # Mount statistics / Статистика монтирований
```

> [!TIP]
> Monitor `retrans` and `avg RTT` — high values indicate network congestion or server load. Use `nfsiostat` to identify slow mount points. / Следите за `retrans` и `avg RTT` — высокие значения указывают на сетевую перегрузку или нагрузку на сервер.

---

## 📊 Mount Options Comparison

| Option | Description (EN) | Описание (RU) | Best For / Лучше для |
| :--- | :--- | :--- | :--- |
| `hard` | App blocks until server responds | Приложение ждёт ответ сервера | Critical data, OpenSearch, DBs |
| `soft` | App gets I/O error after timeout | Ошибка I/O после таймаута | Non-critical, read-only data |
| `intr` | Allow interrupting hard mount | Прерывание hard-монтирования | Recovery when server is down |
| `noatime` | Don't update access time | Не обновлять время доступа | Performance, busy filesystems |
| `nodiratime` | Don't update dir access time | Не обновлять время доступа к каталогам | Performance |
| `vers=3` | NFSv3 protocol | Протокол NFSv3 | Legacy compatibility |
| `vers=4` / `nfsvers=4.2` | NFSv4.2 (recommended) | NFSv4.2 (рекомендуется) | New deployments, Kerberos |
| `tcp` | Use TCP transport (reliable) | TCP-транспорт (надёжный) | Production (default for v4) |
| `udp` | Use UDP transport (fast, unreliable) | UDP (быстро, ненадёжно) | LAN, low-latency only |
| `rsize=131072` | Read chunk size (128 KiB) | Размер чанка чтения | Tuned performance |
| `wsize=524288` | Write chunk size (512 KiB) | Размер чанка записи | Tuned performance |
| `timeo=600` | Timeout in deciseconds (60s) | Таймаут (60 сек) | High-latency links |
| `retrans=5` | Retransmissions before error | Повторные передачи до ошибки | Reliability |
| `sec=sys` | AUTH_SYS (no encryption) | AUTH_SYS (без шифрования) | Trusted networks |
| `sec=krb5` | Kerberos authentication | Аутентификация Kerberos | Secure environments |
| `sec=krb5p` | Kerberos + encryption | Kerberos + шифрование | Highest security |
| `xprtsec=tls` | TLS encryption (Linux 6.5+) | TLS-шифрование (Linux 6.5+) | Encrypted transport |
| `nocto` | No close-to-open consistency | Без close-to-open согласованности | Read-only, rarely-changing data |
| `nconnect=16` | Multiple TCP connections | Несколько TCP-соединений | High-throughput, many clients |
| `softreval` | Use soft timeout for revalidation | Мягкий таймаут для ревалидации | Availability over consistency |
| `noauto` | Don't mount at boot (manual) | Не монтировать при загрузке | systemd automount setup |
| `x-systemd.automount` | Mount on first access | Монтировать при первом обращении | Reliable auto-mount |
| `x-systemd.idle-timeout=1min` | Unmount after idle | Размонтировать после простоя | Save resources |
| `x-systemd.mount-timeout=10` | Mount timeout (10s) | Таймаут монтирования (10 сек) | Faster failure detection |
| `_netdev` | Wait for network at boot | Ждать сеть при загрузке | Boot with network deps |
| `nofail` | Don't fail boot if mount fails | Не прерывать загрузку при ошибке | Non-critical mounts |

---

## 🚨 Troubleshooting

### Mount Fails / Permission Denied

```bash
dmesg | tail -30                                        # Kernel messages / Сообщения ядра
journalctl -xeu <MOUNT_POINT>                           # Mount unit logs / Логи mount-юнита
rpcinfo -t <NFS_HOST> nfs                               # Check NFS version / Проверить версию
rpcinfo -p <NFS_HOST>                                   # List all RPC services / Все RPC-сервисы
showmount -e <NFS_HOST>                                 # Verify export exists / Проверить экспорт
```

### NFS Server Not Reachable

```bash
ping <NFS_HOST>                                         # Network reachability / Доступность по сети
ss -tulpn | grep 2049                                   # Port listening on server / Порт слушается на сервере
sudo firewall-cmd --list-services                       # Check firewall rules / Проверить правила firewall
timeout 2 bash -c "cat < /dev/tcp/<NFS_HOST>/2049"     # TCP probe (more reliable than ping) / TCP-проверка
```

### Stale File Handle / Server Restart

```bash
sudo umount -l <MOUNT_POINT>                            # Lazy unmount / Отложенное размонтирование
sudo mount -a                                           # Remount from fstab / Смонтировать заново из fstab
```

> [!WARNING]
> After NFS server restart, clients may see "Stale file handle" errors. Lazy unmount + remount is the standard fix. / После перезапуска NFS-сервера клиенты могут видеть "Stale file handle". Lazy unmount + remount — стандартное исправление.
> После перезезапуска NFS-сервера клиенты могут видеть ошибку "Stale file handle". Lazy unmount + remount — стандартное исправление.

### Clock Skew Issues

NFS requires synchronized clocks. Large time differences cause permission errors. / NFS требует синхронизированных часов. Большая разница во времени вызывает ошибки доступа.

```bash
timedatectl                                             # Check time sync / Проверить синхронизацию времени
chronyc tracking                                         # Chrony status / Статус chrony
sudo chronyc makestep                                    # Force time sync (if needed) / Принудительная синхронизация
```

### NFS Hangs / Timeout

```bash
# Check if hard mount is causing hangs
mount | grep <MOUNT_POINT>                              # Check mount options / Проверить опции монтирования

# Try lazy unmount if process is stuck
sudo umount -l -f <MOUNT_POINT>                         # Force lazy unmount / Принудительное отложенное размонтирование

# Check NFS client stats for errors
nfsstat -c                                               # Client stats / Статистика клиента
```

> [!CAUTION]
> If using `hard` mount option, applications will block indefinitely when NFS server is unreachable. Consider `soft` for non-critical data, or use `hard,intr` to allow interrupts. / При опции `hard` приложения будут блокироваться бесконечно. Рассмотрите `soft` для некритичных данных или `hard,intr`.

### RSync Job Failures

```bash
# Check rsync log for non-zero exit codes
awk 'NR==1 || $7 != 0' <RSYNC_LOG_PATH> | less

# Common rsync parallel job checks
ps aux | grep rsync | grep -v grep                      # Running rsync processes / Активные процессы rsync
lsof +D <MOUNT_POINT>                                   # What's using the mount / Что использует точку монтирования
```

---

## 🔒 Security

### Network Restriction

```bash
# In /etc/exports — restrict to specific subnet
<EXPORT_PATH> <SUBNET_IP>/24(rw,sync,no_subtree_check,root_squash)

# Restrict to specific IPs only
<EXPORT_PATH> <CLIENT_IP_1>(rw,sync,no_subtree_check) <CLIENT_IP_2>(rw,sync,no_subtree_check)
```

### Firewall Ports

| Port | Service | Purpose |
| :--- | :--- | :--- |
| 2049/tcp | nfs | NFS file access |
| 111/tcp,111/udp | rpcbind | Port mapper |
| 20048/tcp | mountd | NFSv3 mount |
| 662/tcp,662/udp | lockd | File locking (NFSv3) |

```bash
# RHEL/Alma/Rocky
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --add-service=mountd --permanent
sudo firewall-cmd --add-service=rpc-bind --permanent
sudo firewall-cmd --reload
```

### Kerberos Authentication (NFSv4)

For stronger security than `sec=sys` (AUTH_SYS), use Kerberos. / Для большей безопасности, чем `sec=sys` (AUTH_SYS), используйте Kerberos.

```bash
# Mount with Kerberos (requires KDC setup)
sudo mount -t nfs -o sec=krb5 <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>

# Mount with Kerberos + encryption (krb5p)
sudo mount -t nfs -o sec=krb5p <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>
```

| Sec | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `sec=sys` | AUTH_SYS (no auth, IP-based) | AUTH_SYS (без аутентификации, по IP) |
| `sec=krb5` | Kerberos authentication | Аутентификация Kerberos |
| `sec=krb5i` | Kerberos + integrity | Kerberos + целостность |
| `sec=krb5p` | Kerberos + privacy (encryption) | Kerberos + конфиденциальность (шифрование) |

> [!NOTE]
> NFS does not support POSIX ACLs over the network. The server enforces ACLs, but clients cannot see or modify them. / NFS не поддерживает POSIX ACL по сети. Сервер применяет ACL, но клиенты не могут их видеть или изменять.

---

## 🔐 TLS Encryption

NFS traffic can be encrypted using TLS as of Linux 6.5+ with `xprtsec=tls`. / Трафик NFS можно шифровать с помощью TLS (начиная с Linux 6.5+) через `xprtsec=tls`.

### Server Setup

`/etc/tlshd.conf`

```ini
[authenticate.server]
x509.certificate = /etc/nfsd-certificate.pem
x509.private_key = /etc/nfsd-private-key.pem
```

```bash
sudo apt install -y ktls-utils                          # Install ktls-utils / Установить ktls-utils
sudo systemctl enable --now tlshd                       # Start TLS daemon / Запустить TLS-демон
```

### Client Setup

```bash
sudo apt install -y ktls-utils                          # Install ktls-utils / Установить ktls-utils
# Add server cert to trust store (or use x509.truststore)
sudo cp <SERVER_CERT> /usr/local/share/ca-certificates/
sudo update-ca-certificates
sudo systemctl enable --now tlshd                       # Start TLS daemon / Запустить TLS-демон
```

### Mount with TLS

```bash
sudo mount -t nfs -o xprtsec=tls <NFS_HOST>:<EXPORT_PATH> <MOUNT_POINT>
```

```bash
journalctl -b -u tlshd.service                          # Verify TLS handshake / Проверить TLS-хендшейк
```

> [!WARNING]
> Encrypted private keys are not currently supported by ktls-utils and will cause mount failure. / Зашифрованные приватные ключи сейчас не поддерживаются ktls-utils и вызовут ошибку монтирования.
> Зашифрованные приватные ключи сейчас не поддерживаются ktls-utils и вызовут ошибку монтирования.

---

## ⚙️ Advanced Configuration

### Server Tuning
`/etc/nfs.conf`

```ini
[nfsd]
threads = 16        # NFS worker threads (default: 8) / Рабочие потоки (по умолчанию: 8)
vers4 = y           # Enable NFSv4 / Включить NFSv4
vers3 = y           # Enable NFSv3 (compatibility) / Включить NFSv3 (совместимость)
port = 2049         # NFS port / Порт NFS
host = <SERVER_IP>  # Bind to specific interface (optional) / Привязать к интерфейсу (опционально)

[mountd]
port = 20048        # Static mountd port (for firewalls) / Статический порт mountd (для firewall)
```

### NFSv4 Export Root (fsid=0)

NFSv4 supports a single export root. Shares below it are mounted without the root prefix. / NFSv4 поддерживает один корень экспорта. Пути ниже него монтируются без префикса корня.

```bash
# Create NFS root directory
sudo mkdir -p /srv/nfs/music /srv/nfs/home
sudo mount --bind /mnt/music /srv/nfs/music              # Bind mount to actual path / Bind-mount к реальному пути
```

`/etc/exports`

```bash
# Designate export root with fsid=0
/srv/nfs         <SUBNET_IP>/24(rw,fsid=0,no_subtree_check)
/srv/nfs/music   <SUBNET_IP>/24(rw,sync,no_subtree_check)
/srv/nfs/home    <SUBNET_IP>/24(rw,sync,no_subtree_check)
```

```bash
# Client mounts root, then subdirs are visible
sudo mount -t nfs -o vers=4 <NFS_HOST>:/ /mnt/nfs-root
ls /mnt/nfs-root/                                        # Shows music, home / Показывает music, home
```

### Crossmnt / Nohide (NFSv3)

```bash
# crossmnt: auto-mount child filesystems (NFSv3)
/srv/nfs  <SUBNET_IP>/24(rw,crossmnt,fsid=0)

# nohide: child exports auto-mount when parent is mounted (respects IP ranges)
/srv/nfs/music  <SUBNET_IP>/24(rw,sync,nohide)
```

### ID/GID Mapping

NFS identifies users by UID/GID numeric IDs, not usernames. If client and server have different user databases, files appear owned by wrong users or "nobody". / NFS идентифицирует пользователей по числовым UID/GID, а не по именам. Если клиент и сервер имеют разные базы пользователей, файлы будут отображаться с неверными владельцами или "nobody".

**The problem / Проблема:**
| Scenario | Server UID | Client UID | Result |
| :--- | :--- | :--- | :--- |
| Same mapping | 1000 (`alice`) | 1000 (`alice`) | ✅ Correct / Корректно |
| Different mapping | 1000 (`alice`) | 1001 (`bob`) | ❌ Wrong owner / Неверный владелец |
| Unknown user | 1000 (`alice`) | — (no 1000) | ❌ Shows as nobody / Отображается как nobody |

#### NFSv3 Approach: Squash Options

For NFSv3, control ownership via export options. / Для NFSv3 управляйте владельцем через опции экспорта.

`/etc/exports`

```bash
# Default: remote root becomes nobody
/EXPORT_PATH <SUBNET_IP>/24(rw,sync,root_squash)

# Map ALL users to nobody (public shares)
/EXPORT_PATH <SUBNET_IP>/24(ro,all_squash,anonuid=65534,anongid=65534)

# Map all users to specific UID/GID (e.g., service account)
/EXPORT_PATH <SUBNET_IP>/24(rw,all_squash,anonuid=1000,anongid=1000)

# Allow remote root (dangerous — use only if required)
/EXPORT_PATH <SUBNET_IP>/24(rw,no_root_squash)
```

| Option | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `root_squash` | Map remote root → nobody (default) | Удалённый root → nobody (по умолчанию) |
| `no_root_squash` | Allow remote root full access | Разрешить удалённому root полный доступ |
| `all_squash` | Map ALL users → anonuid/anongid | Все пользователи → anonuid/anongid |
| `anonuid=<UID>` | UID for squashed users | UID для сжатых пользователей |
| `anongid=<GID>` | GID for squashed users | GID для сжатых пользователей |

> [!WARNING]
> `no_root_squash` gives remote root full access to the export. Never use on untrusted networks. / `no_root_squash` даёт удалённому root полный доступ. Никогда не используйте в ненадёжных сетях.

#### NFSv4 ID Mapping (idmapd)

NFSv4 translates UIDs/GIDs to strings like `user@domain` on the wire, enabling cross-domain mapping. / NFSv4 преобразует UID/GID в строки вида `user@domain` при передаче по сети, обеспечивая маппинг между доменами.

**How it works / Как это работает:**
```
Client (UID 1000) → nfsidmap → "alice@example.com" → NFSv4 wire → Server → nfsidmap → Server UID 2000
```

##### Step 1: Configure Domain (Both Client & Server)

`/etc/idmapd.conf`

```ini
[General]
# MUST match on both client and server
Domain = example.com

# Optional: set verbosity (1=normal, 2=debug)
Verbosity = 1
```

```bash
nfsidmap -d                                              # Show current domain / Показать текущий домен
# Output: example.com
```

> [!IMPORTANT]
> The `Domain` must be **identical** on client and server. If they differ, all files will show as `nobody`. Use a stable domain (not dependent on DHCP/DNS changes). / `Domain` должен быть **идентичным** на клиенте и сервере. При различии все файлы будут отображаться как `nobody`.

##### Step 2: Choose Translation Method

`/etc/idmapd.conf`

```ini
[Translation]
# Method order (comma-separated):
#   nsswitch  — use NSS (LDAP, files, etc.) — DEFAULT
#   static    — use [Static] section mappings
#   umich     — use umich.edu schema (legacy)
method = nsswitch

# For mixed environments, combine methods:
# method = static,nsswitch
```

##### Step 3: Static Mapping (Optional)

Map specific remote users to local users. / Сопоставьте конкретных удалённых пользователей с локальными.

`/etc/idmapd.conf`

```ini
[Static]
# remote_user@domain = local_user
bob@company.com = local_bob
alice@company.com = local_alice
service@company.com = svc_account
```

##### Step 4: Fallback Mapping (Nobody-User)

Map unmapped users to a default account. / Сопоставьте несопоставленных пользователей с аккаунтом по умолчанию.

`/etc/idmapd.conf`

```ini
[Mapping]
Nobody-User = nobody
Nobody-Group = nobody

# Or map to a specific service account:
# Nobody-User = nfs-anon
# Nobody-Group = nfs-anon
```

##### Step 5: Start idmapd Service

```bash
# Server: enable and start idmapd
sudo systemctl enable --now nfs-idmapd

# Client: idmapd runs in-kernel on modern systems (no service needed)
# Verify kernel idmapper is active:
dmesg | grep id_resolver
# Output: NFS: Registering the id_resolver key type
```

> [!NOTE]
> On modern kernels (3.x+), the client uses an in-kernel idmapper (`id_resolver`). The `nfs-idmapd.service` is only needed on the **server**. / На современных ядрах (3.x+) клиент использует встроенный маппер (`id_resolver`). Сервис `nfs-idmapd` нужен только на **сервере**.

##### Tools & Verification

```bash
nfsidmap -d                                              # Show domain / Показать домен
nfsidmap -l                                              # List cached mappings / Кэшированные сопоставления
nfsidmap -c                                              # Clear idmap cache / Очистить кэш idmap
nfsidmap -r <USER>@<DOMAIN>                             # Remove specific mapping / Удалить сопоставление
```

**Sample output / Пример вывода:**
```
$ nfsidmap -l
7 .id_resolver keys found:
uid:nobody
uid:alice@example.com
uid:bob@example.com
gid:alice@example.com
gid:bob@example.com
```

##### Troubleshooting ID Mapping

```bash
# Check if files show wrong ownership
ls -ln <MOUNT_POINT>                                     # Show numeric UIDs / Показать числовые UID

# Verify idmapd is running (server)
systemctl status nfs-idmapd

# Check idmapd logs
journalctl -u nfs-idmapd -n 50

# Clear cache and remount
sudo nfsidmap -c
sudo umount <MOUNT_POINT> && sudo mount -a
```

**Common issues / Частые проблемы:**
| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Files show `nobody` | Domain mismatch | Set same `Domain` in idmapd.conf |
| Files show wrong user | No mapping exists | Add static mapping or fix NSS |
| idmapd not working | Service not running | `systemctl enable --now nfs-idmapd` |
| Stale mappings | Cache outdated | `nfsidmap -c` then remount |

#### Alternative: Consistent UIDs Across Fleet

The simplest approach — keep UIDs/GIDs synchronized across all nodes. / Простейший подход — синхронизируйте UID/GID на всех узлах.

```bash
# Check local user UIDs
id <USER>                                                # Show UID/GID / Показать UID/GID
getent passwd <USER>                                     # Lookup in NSS / Поиск в NSS

# For LDAP/NIS environments, ensure consistent identity source
# Ensure same UID ranges for service accounts across cluster
```

> [!TIP]
> For clusters (OpenSearch, Kubernetes nodes), create service accounts with **fixed UIDs** (e.g., `opensearch:x:1001:1001`) on all nodes, or use centralized identity (LDAP/FreeIPA). / Для кластеров создавайте сервисные аккаунты с **фиксированными UID** (например, `opensearch:x:1001:1001`) на всех узлах или используйте централизованную идентификацию (LDAP/FreeIPA).

### systemd Mount Units (Alternative to fstab)

Instead of `/etc/fstab`, you can use dedicated systemd units. / Вместо `/etc/fstab` можно использовать отдельные systemd-юниты.

`/etc/systemd/system/mnt-backups.mount`

```ini
[Unit]
Description=Mount NFS backups
After=network-online.target
Wants=network-online.target

[Mount]
What=<NFS_HOST>:/mnt/backups
Where=/mnt/backups
Type=nfs
Options=vers=4.2,noatime,hard,_netdev
TimeoutSec=30

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/mnt-backups.automount`

```ini
[Unit]
Description=Automount NFS backups

[Automount]
Where=/mnt/backups
TimeoutIdleSec=60

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload                            # Reload units / Перезагрузить юниты
sudo systemctl enable --now mnt-backups.automount       # Enable automount / Включить automount
sudo systemctl status mnt-backups.automount             # Check status / Проверить статус
```

> [!TIP]
> Use `automount` units for NFS shares that should mount on first access and unmount after idle. Use `mount` units for always-mounted shares. / Используйте `automount`-юниты для монтирования по обращению. Используйте `mount`-юниты для постоянно смонтированных шар.

### Time Synchronization

NFS requires accurate clocks on all nodes. Use chrony or ntpd. / NFS требует точных часов на всех узлах. Используйте chrony или ntpd.

```bash
sudo timedatectl set-ntp true                          # Enable NTP / Включить NTP
chronyc tracking                                         # Check chrony status / Проверить статус chrony
```

---

## 📖 Production Runbook: NFS for OpenSearch Snapshots

**Goal/Цель:** One shared path `/mnt/backups` visible identically on all cluster nodes. / Один общий путь `/mnt/backups` доступен одинаково на всех нодах кластера.

### Prerequisites / Предпосылки

- NFS server: `<NFS_SERVER>` (e.g., `<SERVER_IP>`)
- Clients: remaining cluster nodes (e.g., `<CLIENT_IP_1>`, `<CLIENT_IP_2>`)
- Shared path: `/mnt/backups`
- On all OpenSearch nodes in `opensearch.yml`: `path.repo: ["/mnt/backups"]`

### Step 1: Server Setup / Настройка сервера

```bash
# 1.1 Install packages
sudo dnf install -y nfs-utils

# 1.2 Prepare export directory
sudo mkdir -p /mnt/backups
sudo chown opensearch:opensearch /mnt/backups
sudo chmod 750 /mnt/backups

# 1.3 Configure export (add to /etc/exports)
# /mnt/backups <SUBNET_IP>/24(rw,sync,no_subtree_check)

# 1.4 Apply & start
sudo exportfs -ra
sudo systemctl enable --now nfs-server

# 1.5 Firewall
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --add-service=mountd --permanent
sudo firewall-cmd --add-service=rpc-bind --permanent
sudo firewall-cmd --reload

# 1.6 Self-check
sudo exportfs -v
ss -tulpn | grep 2049
rpcinfo -t <NFS_SERVER> nfs
```

### Step 2: Client Setup / Настройка клиентов

```bash
# 2.1 Install packages
# RHEL/AlmaLinux/Rocky
sudo dnf install -y nfs-utils

# Ubuntu/Debian
sudo apt update && sudo apt install -y nfs-common

# 2.2 Create mount point
sudo mkdir -p /mnt/backups

# 2.3 Test manual mount
sudo mount -t nfs -o nfsvers=4.2 <NFS_SERVER>:/mnt/backups /mnt/backups

# 2.4 Verify (test file visible from all nodes)
touch /mnt/backups/client_check.txt
ls -l /mnt/backups
```

### Step 3: Permanent Mount (fstab) / Постоянное монтирование

`/etc/fstab`

```bash
<NFS_SERVER>:/mnt/backups  /mnt/backups  nfs  rw,noatime,hard,intr,_netdev,nfsvers=4.2  0  0
```

```bash
sudo mount -a
```

### Step 4: Validation / Валидация

```bash
# On each node
mount | grep /mnt/backups
ls -ld /mnt/backups
df -h /mnt/backups
```

### Step 5: OpenSearch Configuration / Конфигурация OpenSearch

`/etc/opensearch/opensearch.yml`

```yaml
path.repo:
  - "/mnt/backups"
```

> [!CAUTION]
> After changing `opensearch.yml`, you must restart OpenSearch on **all** nodes. Ensure NFS is mounted on every node **before** starting OpenSearch. / После изменения `opensearch.yml` перезапустите OpenSearch на **всех** нодах. Убедитесь, что NFS смонтирован на каждой ноде **до** запуска OpenSearch.
> После изменения `opensearch.yml` перезапустите OpenSearch на **всех** нодах. Убедитесь, что NFS смонтирован на каждой ноде **до** запуска OpenSearch.

---

## 📚 Documentation Links

- **nfs(5) Man Page:** https://man7.org/linux/man-pages/man5/nfs.5.html
- **exports(5) Man Page:** https://man7.org/linux/man-pages/man5/exports.5.html
- **nfsstat(8) Man Page:** https://man7.org/linux/man-pages/man8/nfsstat.8.html
- **nfsiostat(8) Man Page:** https://man7.org/linux/man-pages/man8/nfsiostat.8.html
- **mountstats(8) Man Page:** https://man7.org/linux/man-pages/man8/mountstats.8.html
- **NFS man pages (Debian):** https://manpages.debian.org/testing/nfs-common/showmount.1.en.html
- **Red Hat — NFS Overview:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_file_systems/mounting-nfs-shares-on-rhel-8
- **Ubuntu — NFS Server:** https://ubuntu.com/server/docs/service-nfs
- **ArchWiki — NFS:** https://wiki.archlinux.org/title/NFS
- **ArchWiki — NFS Troubleshooting:** https://wiki.archlinux.org/title/NFS/Troubleshooting
- **ArchWiki — NFS Kerberos:** https://wiki.archlinux.org/title/NFS/Kerberos
- **Debian Wiki — NFS:** https://wiki.debian.org/NFS
- **OpenSearch — Snapshot Repositories:** https://opensearch.org/docs/latest/api-reference/snapshot-apis/
- **systemd.mount(5):** https://man7.org/linux/man-pages/man5/systemd.mount.5.html
- **systemd.automount(5):** https://man7.org/linux/man-pages/man5/systemd.automount.5.html
