Title: 🗄️ Veeam Agent — Linux Backup
Group: Backups & S3
Icon: 🗄️
Order: 7

## 📚 Table of Contents / Содержание
- [Installation / Установка](#installation)
- [Job Configuration / Настройка задач](#job-configuration)
- [Backup Operations / Операции бэкапа](#backup-operations)
- [Recovery Operations / Операции восстановления](#recovery-operations)
- [Repository Management / Управление репозиториями](#repository-management)
- [CLI Commands / CLI Команды](#cli-commands)
- [Sysadmin Operations / Операции сисадмина](#sysadmin-operations)
- [Troubleshooting / Устранение проблем](#troubleshooting)

---

## Installation

### Download

# Free edition / Бесплатная версия
wget https://download2.veeam.com/VeeamAgentLinux_6.0.0.287_amd64.deb
dpkg -i VeeamAgentLinux_6.0.0.287_amd64.deb       # Debian/Ubuntu

# RHEL/AlmaLinux/Rocky
wget https://download2.veeam.com/VeeamAgentLinux-6.0.0.287-1.x86_64.rpm
rpm -ivh VeeamAgentLinux-6.0.0.287-1.x86_64.rpm

### License

veeam                                          # Start configurator / Запустить конфигуратор
# Select "Free" edition for workstation backup / Выбрать "Free" для бэкапа рабочей станции

---

## Job Configuration

### Create Backup Job

veeamconfig job create                         # Create job (interactive) / Создать задачу (интерактивно)

### Job Types

# Entire machine / Вся машина
veeamconfig job create --name FullBackup --type EntireMachine --repoName LocalRepo

# Volume level / На уровне томов
veeamconfig job create --name VolumeBackup --type Volume --objects /dev/sda1 --repoName LocalRepo

# File level / На уровне файлов  
veeamconfig job create --name FileBackup --type FileLevel --objects /var/www --repoName LocalRepo

### List Jobs

veeamconfig job list                           # List jobs / Список задач
veeamconfig job info --name FullBackup         # Job details / Детали задачи

### Edit Job

veeamconfig job edit --name FullBackup         # Edit job / Редактировать задачу
veeamconfig job delete --name FullBackup       # Delete job / Удалить задачу

---

## Backup Operations

### Run Backup

veeamconfig job start --name FullBackup        # Start backup / Запустить бэкап
veeamconfig job start --all                    # Start all jobs / Запустить все задачи

### Backup Modes

# Full backup / Полный бэкап
veeamconfig job start --name FullBackup --full

# Incremental backup / Инкрементальный бэкап
veeamconfig job start --name FullBackup

### Show Backup Progress

veeamconfig job status                         # Job status / Статус задачи
veeamconfig session list                       # List sessions / Список сессий

---

## Recovery Operations

### Bare Metal Recovery

# Boot from Veeam Recovery Media / Загрузка с Veeam Recovery Media
# Select "Bare metal recovery" / Выбрать "Bare metal recovery"
# Choose restore point / Выбрать точку восстановления
# Select target disks / Выбрать целевые диски

### File-Level Recovery

veeamconfig recovery mount --session <SESSION_ID> # Mount backup / Монтиров ать бэкап
# Files mounted to /mnt/backup/ / Файлы смонтированы в /mnt/backup/
cp /mnt/backup/var/www/* /var/www/             # Copy files / Копировать файлы
veeamconfig recovery unmount                   # Unmount / Размонтировать

### Volume-Level Recovery

veeamconfig recovery start --session <SESSION_ID> --disk /dev/sda1 # Restore volume / Восстановить том

---

## Repository Management

### Create Repository

# Local repository / Локальный репозиторий
veeamconfig repository create --name LocalRepo --location /backup

# Network share / Сетевая папка
veeamconfig repository create --name NetworkRepo --location smb://<HOST>/backup --login <USER> --password <PASSWORD>

# Veeam Backup & Replication server / Сервер Veeam Backup & Replication
veeamconfig repository create --name VBRRepo --location vbr://<HOST> --login <USER> --password <PASSWORD>

### List Repositories

veeamconfig repository list                    # List repos / Список репозиториев
veeamconfig repository info --name LocalRepo   # Repo details / Детали репозитория

### Delete Repository

veeamconfig repository delete --name LocalRepo # Delete repo / Удалить репозиторий

---

## CLI Commands

### veeam (Interactive UI / Интерактивный UI)

veeam                                          # Start interactive configurator / Запустить интерактивный конфигуратор

### veeamconfig (CLI Configuration / CLI конфигурация)

veeamconfig --help                             # Show help / Показать помощь
veeamconfig job --help                         # Job help / Помощь по задачам
veeamconfig recovery --help                    # Recovery help / Помощь по восстановлению

### veeamsnap (Snapshot Management / Управление снапшотами)

veeamsnap --show                               # Show snapshots / Показать снапшоты
veeamsnap --delete                             # Delete snapshots / Удалить снапшоты

---

## Sysadmin Operations

### Service Management

systemctl status veeamservice                  # Check service / Проверить сервис
systemctl start veeamservice                   # Start service / Запустить сервис
systemctl enable veeamservice                  # Enable service / Включить сервис

### Scheduled Backups

veeamconfig job edit --name FullBackup --schedule daily --at 02:00 # Daily at 2AM / Ежедневно в 2:00

### Logs

tail -f /var/log/veeam/veeam.log               # Veeam log / Лог Veeam
journalctl -u veeamservice                     # Service log / Лог сервиса

### Configuration Files

/etc/veeam/                                    # Config directory / Директория конфигурации
/var/lib/veeam/                                # Data directory / Директория данных

---

## Troubleshooting

### Common Issues

# "Snapshot creation failed" / "Не удалось создать снапшот"
veeamsnap --show                               # Check existing snapshots / Проверить существующие снапшоты
veeamsnap --delete                             # Delete stale snapshots / Удалить устаревшие снапшоты

# "Cannot connect to repository" / "Не может подключиться к репозиторию"
veeamconfig repository list                    # Check repo config / Проверить конфигурацию репозитория
mount | grep /backup                           # Check mount / Проверить монтирование

# "Backup job failed" / "Задача бэкапа провалилась"
veeamconfig session list                       # List sessions / Список сессий
tail -f /var/log/veeam/veeam.log               # Check logs / Проверить логи

### Debug Mode

veeamconfig --trace job start --name FullBackup # Run with trace / Запустить с трассировкой

### Uninstall

dpkg -r veeam                                  # Debian/Ubuntu
rpm -e veeam                                   # RHEL/AlmaLinux/Rocky
