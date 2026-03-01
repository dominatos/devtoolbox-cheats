Title: 🗄️ Veeam Agent — Linux Backup
Group: Backups & S3
Icon: 🗄️
Order: 7

## Table of Contents
- [Installation](#installation)
- [Job Configuration](#job-configuration)
- [Backup Operations](#backup-operations)
- [Recovery Operations](#recovery-operations)
- [Repository Management](#repository-management)
- [CLI Commands](#cli-commands)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Download & Install / Скачать и установить

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

### License / Лицензия

```bash
veeam                                           # Start configurator / Запустить конфигуратор
# Select "Free" edition for workstation / Выбрать "Free" для рабочей станции
```

---

## Job Configuration

### Create Backup Job / Создать задачу бэкапа

```bash
veeamconfig job create                          # Interactive wizard / Интерактивный мастер
```

#### Job Types / Типы задач

```bash
# Entire machine backup / Бэкап всей машины
veeamconfig job create \
  --name FullBackup \
  --type EntireMachine \
  --repoName LocalRepo

# Volume-level backup / Бэкап на уровне томов
veeamconfig job create \
  --name VolumeBackup \
  --type Volume \
  --objects /dev/sda1 \
  --repoName LocalRepo

# File-level backup / Бэкап на уровне файлов
veeamconfig job create \
  --name FileBackup \
  --type FileLevel \
  --objects /var/www \
  --repoName LocalRepo
```

### List & Manage Jobs / Список и управление задачами

```bash
veeamconfig job list                            # List all jobs / Список задач
veeamconfig job info --name FullBackup          # Job details / Детали задачи
veeamconfig job edit --name FullBackup          # Edit job / Редактировать задачу
veeamconfig job delete --name FullBackup        # Delete job / Удалить задачу
```

---

## Backup Operations

### Run Backup / Запустить бэкап

```bash
veeamconfig job start --name FullBackup         # Start job / Запустить задачу
veeamconfig job start --all                     # Start all jobs / Все задачи
veeamconfig job start --name FullBackup --full  # Force full backup / Принудительно полный бэкап
```

### Backup Modes / Режимы бэкапа

| Mode | Description / Описание | Flag |
|------|------------------------|------|
| Full | Complete backup of all data / Полный бэкап | `--full` |
| Incremental | Changed blocks since last backup / Только изменения | *(default)* |

### Monitor Progress / Мониторинг прогресса

```bash
veeamconfig job status                          # Current job status / Статус задачи
veeamconfig session list                        # List all sessions / Список сессий
```

---

## Recovery Operations

### Bare Metal Recovery / Восстановление Bare Metal

> [!IMPORTANT]
> Boot from **Veeam Recovery Media** for bare metal restore. Create it before disaster: `veeam` → "Recovery Media".

```bash
# Steps / Шаги:
# 1. Boot from Veeam Recovery Media / Загрузить с Veeam Recovery Media
# 2. Select "Bare metal recovery" / Выбрать "Bare metal recovery"
# 3. Choose restore point / Выбрать точку восстановления
# 4. Select target disks / Выбрать целевые диски
```

### File-Level Recovery / Файловое восстановление

```bash
veeamconfig recovery mount --session <SESSION_ID>  # Mount backup / Смонтировать бэкап
# Files are mounted to /mnt/backup/ / Файлы смонтированы в /mnt/backup/
cp /mnt/backup/var/www/* /var/www/              # Copy files / Копировать файлы
veeamconfig recovery unmount                    # Unmount / Размонтировать
```

### Volume-Level Recovery / Восстановление тома

```bash
veeamconfig recovery start \
  --session <SESSION_ID> \
  --disk /dev/sda1                              # Restore volume / Восстановить том
```

---

## Repository Management

### Create Repository / Создать репозиторий

```bash
# Local directory / Локальный каталог
veeamconfig repository create \
  --name LocalRepo \
  --location /backup

# Network share (SMB) / Сетевой ресурс (SMB)
veeamconfig repository create \
  --name NetworkRepo \
  --location smb://<HOST>/backup \
  --login <USER> \
  --password <PASSWORD>

# Veeam Backup & Replication server / Сервер VBR
veeamconfig repository create \
  --name VBRRepo \
  --location vbr://<HOST> \
  --login <USER> \
  --password <PASSWORD>
```

### Manage Repositories / Управление репозиториями

```bash
veeamconfig repository list                     # List repos / Список репозиториев
veeamconfig repository info --name LocalRepo    # Repo details / Детали репозитория
veeamconfig repository delete --name LocalRepo  # Delete repo / Удалить репозиторий
```

---

## CLI Commands

### Tools Reference / Справка по инструментам

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

### Service Management / Управление сервисами

```bash
systemctl status veeamservice                   # Check service / Проверить сервис
systemctl start veeamservice                    # Start service / Запустить
systemctl stop veeamservice                     # Stop service / Остановить
systemctl enable veeamservice                   # Enable at boot / Включить при загрузке
```

### Schedule Backups / Планирование бэкапов

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

### Logs & Configuration / Логи и конфигурация

```bash
tail -f /var/log/veeam/veeam.log               # Main Veeam log / Основной лог Veeam
journalctl -u veeamservice                      # Service journal / Журнал сервиса
```

### Configuration Paths / Пути конфигурации

```bash
/etc/veeam/          # Configuration directory / Директория конфигурации
/var/lib/veeam/      # Data directory / Директория данных
/var/log/veeam/      # Log directory / Директория логов
```

---

## Troubleshooting

### Common Issues / Распространённые проблемы

```bash
# "Snapshot creation failed" / "Не удалось создать снапшот"
veeamsnap --show                                # Check snapshots / Проверить снапшоты
veeamsnap --delete                              # Delete stale snapshots / Удалить устаревшие

# "Cannot connect to repository" / "Нет подключения к репозиторию"
veeamconfig repository list                     # Check repo config / Конфигурация репозитория
mount | grep /backup                            # Check mount / Проверить монтирование

# "Backup job failed" / "Задача бэкапа провалилась"
veeamconfig session list                        # Check sessions / Список сессий
tail -f /var/log/veeam/veeam.log               # Check logs / Логи

# Kernel module missing (dkms) / Модуль ядра не установлен
dkms status                                     # Check DKMS / Статус DKMS
apt install linux-headers-$(uname -r)           # Install headers / Установить заголовки ядра
```

### Debug / Отладка

```bash
veeamconfig --trace job start --name FullBackup  # Run with trace / Трассировка
```

### Uninstall / Удалить

```bash
apt remove veeam                                # Debian/Ubuntu
rpm -e veeam                                    # RHEL/AlmaLinux/Rocky
```
