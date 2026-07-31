---
Title: 🗄️ Veeam Agent — Linux Backup
Group: "Backups & S3"
Icon: 🗄️
Order: 7
tags:
  - backups
  - s3
  - sysadmin
  - linux
---

> **Veeam Agent for Linux** is a free/commercial backup agent that provides image-level (bare metal), volume-level, and file-level backups for physical and cloud Linux machines. It supports local, network (SMB/NFS), and Veeam Backup & Replication repository targets. Veeam is actively developed and widely used in enterprise environments alongside VMware/Hyper-V virtual infrastructure backup.
> / **Veeam Agent for Linux** — бесплатный/коммерческий агент резервного копирования для физических и облачных Linux-машин. Поддерживает полные образы, тома и файловые бэкапы. Широко используется в корпоративных средах.

## Table of Contents

- [Installation](#Installation)
- [Job Configuration](#Job%20Configuration)
- [Backup Operations](#Backup%20Operations)
- [Recovery Operations](#Recovery%20Operations)
- [Repository Management](#Repository%20Management)
- [CLI Commands](#CLI%20Commands)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Troubleshooting](#Troubleshooting)
- [Documentation](#Documentation)

---

## Installation

### Download & Install

> [!TIP]
> For production use, register at [veeam.com](https://www.veeam.com) to get the official download link for the latest version.

```bash
# Debian/Ubuntu / Debian/Ubuntu
wget https://download2.veeam.com/VeeamAgentLinux_6.0.0.287_amd64.deb
dpkg -i VeeamAgentLinux_6.0.0.287_amd64.deb    # Install .deb / Установить .deb
apt-get install -f                              # Fix dependencies / Исправить зависимости

# RHEL/AlmaLinux/Rocky / RHEL/AlmaLinux/Rocky
wget https://download2.veeam.com/VeeamAgentLinux-6.0.0.287-1.x86_64.rpm
rpm -ivh VeeamAgentLinux-6.0.0.287-1.x86_64.rpm
```

### License

```bash
veeam                                           # Start configurator / Запустить конфигуратор
# Select "Free" edition for workstation
```

---

## Job Configuration

### Create Backup Job

```bash
veeamconfig job create                          # Interactive wizard / Интерактивный мастер
```

#### Job Types

```bash
# Entire machine backup
veeamconfig job create \
  --name FullBackup \
  --type EntireMachine \
  --repoName LocalRepo

# Volume-level backup
veeamconfig job create \
  --name VolumeBackup \
  --type Volume \
  --objects /dev/sda1 \
  --repoName LocalRepo

# File-level backup
veeamconfig job create \
  --name FileBackup \
  --type FileLevel \
  --objects /var/www \
  --repoName LocalRepo
```

### List & Manage Jobs

```bash
veeamconfig job list                            # List all jobs / Список задач
veeamconfig job info --name FullBackup          # Job details / Детали задачи
veeamconfig job edit --name FullBackup          # Edit job / Редактировать задачу
veeamconfig job delete --name FullBackup        # Delete job / Удалить задачу
```

---

## Backup Operations

### Run Backup

```bash
veeamconfig job start --name FullBackup         # Start job / Запустить задачу
veeamconfig job start --all                     # Start all jobs / Все задачи
veeamconfig job start --name FullBackup --full  # Force full backup / Принудительно полный бэкап
```

### Backup Modes

| Mode | Description / Описание | Flag |
|------|------------------------|------|
| Full | Complete backup of all data / Полный бэкап | `--full` |
| Incremental | Changed blocks since last backup / Только изменения | *(default)* |

### Monitor Progress

```bash
veeamconfig job status                          # Current job status / Статус задачи
veeamconfig session list                        # List all sessions / Список сессий
```

---

## Recovery Operations

### Bare Metal Recovery

> [!IMPORTANT]
> Boot from **Veeam Recovery Media** for bare metal restore. Create it before disaster: `veeam` → "Recovery Media".

```bash
# Steps
# 1. Boot from Veeam Recovery Media
# 2. Select "Bare metal recovery"
# 3. Choose restore point
# 4. Select target disks
```

### File-Level Recovery

```bash
veeamconfig recovery mount --session <SESSION_ID>  # Mount backup / Смонтировать бэкап
# Files are mounted to /mnt/backup/
cp /mnt/backup/var/www/* /var/www/              # Copy files / Копировать файлы
veeamconfig recovery unmount                    # Unmount / Размонтировать
```

### Volume-Level Recovery

```bash
veeamconfig recovery start \
  --session <SESSION_ID> \
  --disk /dev/sda1                              # Restore volume / Восстановить том
```

---

## Repository Management

### Create Repository

```bash
# Local directory
veeamconfig repository create \
  --name LocalRepo \
  --location /backup

# Network share (SMB)
veeamconfig repository create \
  --name NetworkRepo \
  --location smb://<HOST>/backup \
  --login <USER> \
  --password <PASSWORD>

# Veeam Backup & Replication server
veeamconfig repository create \
  --name VBRRepo \
  --location vbr://<HOST> \
  --login <USER> \
  --password <PASSWORD>
```

### Manage Repositories

```bash
veeamconfig repository list                     # List repos / Список репозиториев
veeamconfig repository info --name LocalRepo    # Repo details / Детали репозитория
veeamconfig repository delete --name LocalRepo  # Delete repo / Удалить репозиторий
```

---

## CLI Commands

### Tools Reference

| Command | Purpose / Назначение |
|---------|----------------------|
| `veeam` | Interactive TUI configurator / Интерактивный конфигуратор |
| `veeamconfig` | CLI for jobs, repos, sessions / CLI для задач и репозиториев |
| `veeamsnap` | Snapshot management / Управление снапшотами |

```bash
veeamconfig --help                              # General help / Общая помощь
veeamconfig job --help                          # Job help / Помощь по задачам
veeamconfig recovery --help                     # Recovery help / Помощь по восстановлению

veeamsnap --show                                # Show snapshots / Показать снапшоты
veeamsnap --delete                              # Delete all snapshots / Удалить снапшоты
```

---

## Sysadmin Operations

### Service Management

```bash
systemctl status veeamservice                   # Check service / Проверить сервис
systemctl start veeamservice                    # Start service / Запустить
systemctl stop veeamservice                     # Stop service / Остановить
systemctl enable veeamservice                   # Enable at boot / Включить при загрузке
```

### Schedule Backups

```bash
veeamconfig job edit \
  --name FullBackup \
  --schedule daily \
  --at 02:00                                    # Daily at 2 AM / Ежедневно в 2:00

veeamconfig job edit \
  --name FullBackup \
  --schedule weekly \
  --at 03:00 \
  --days sunday                                 # Weekly on Sunday / Еженедельно в воскресенье
```

### Logs & Configuration

```bash
tail -f /var/log/veeam/veeam.log               # Main Veeam log / Основной лог Veeam
journalctl -u veeamservice                      # Service journal / Журнал сервиса
```

### Configuration Paths

```bash
/etc/veeam/          # Configuration directory / Директория конфигурации
/var/lib/veeam/      # Data directory / Директория данных
/var/log/veeam/      # Log directory / Директория логов
```

### Logrotate / Logrotate

`/etc/logrotate.d/veeam`

```
/var/log/veeam/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

---

## Troubleshooting

### Common Issues

```bash
# "Snapshot creation failed" / "Не
veeamsnap --show                                # Check snapshots / Проверить снапшоты
veeamsnap --delete                              # Delete stale snapshots / Удалить устаревшие

# "Cannot connect to repository" / "Нет
veeamconfig repository list                     # Check repo config / Конфигурация репозитория
mount | grep /backup                            # Check mount / Проверить монтирование

# "Backup job failed" / "Задача
veeamconfig session list                        # Check sessions / Список сессий
tail -f /var/log/veeam/veeam.log               # Check logs / Логи

# Kernel module missing (dkms)
dkms status                                     # Check DKMS / Статус DKMS
apt install linux-headers-$(uname -r)           # Install headers / Установить заголовки ядра
```

### Debug

```bash
veeamconfig --trace job start --name FullBackup  # Run with trace / Трассировка
```

### Uninstall

```bash
apt remove veeam                                # Debian/Ubuntu
rpm -e veeam                                    # RHEL/AlmaLinux/Rocky
```

## Documentation

- **Veeam Documentation:** https://helpcenter.veeam.com/
