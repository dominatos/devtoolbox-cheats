Title: 🗄️ Bareos/Bacula — Enterprise Backup
Group: Backups & S3
Icon: 🗄️
Order: 6

##  Table of Contents
- [Architecture Overview](#architecture-overview)
- [Installation](#installation)
- [bconsole Basics](#bconsole-basics)
- [Job Management](#job-management)
- [Volume & Pool Management](#volume--pool-management)
- [Restore Operations](#restore-operations)
- [Catalog Queries](#catalog-queries)
- [Client Operations](#client-operations)
- [Configuration Essentials](#configuration-essentials)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Components

**Director** — Central management daemon / Центральный управляющий демон
**Storage Daemon** — Manages storage volumes / Управляет томами хранилища
**File Daemon (Client)** — Runs on backup clients / Работает на клиентах бэкапа
**Catalog** — Database (PostgreSQL/MySQL) / База данных

**Default Ports:**
- Director: 9101
- Storage Daemon: 9103
- File Daemon: 9102

---

## Installation

### Bareos (Modern Fork / Современный форк)

# Debian/Ubuntu
wget -q https://download.bareos.org/current/Debian_12/Release.key -O- | apt-key add -
echo "deb https://download.bareos.org/current/Debian_12/ /" > /etc/apt/sources.list.d/bareos.list
apt update && apt install bareos bareos-database-postgresql # Install Bareos / Установить Bareos

# RHEL/AlmaLinux/Rocky
dnf install bareos bareos-database-postgresql  # Install Bareos / Установить Bareos

### Bacula (Original)

# Debian/Ubuntu
apt install bacula bacula-director-mysql bacula-sd bacula-fd # Install Bacula / Установить Bacula

### Initialize Catalog

/usr/lib/bareos/scripts/create_bareos_database # Create DB / Создать БД
/usr/lib/bareos/scripts/make_bareos_tables     # Create tables / Создать таблицы
/usr/lib/bareos/scripts/grant_bareos_privileges # Grant privileges / Выдать права

---

## bconsole Basics

bconsole                                       # Start console / Запустить консоль

### Common Commands

status dir                                     # Director status / Статус директора
status client                                  # Client status / Статус клиента
status storage                                 # Storage status / Статус хранилища
messages                                       # Show messages / Показать сообщения
quit                                           # Exit console / Выйти из консоли

---

## Job Management

### Run Jobs

run                                            # Run job (interactive) / Запустить задачу (интерактивно)
run job=BackupClient1 yes                      # Run specific job / Запустить конкретную задачу
run job=BackupClient1 level=Full yes           # Full backup / Полный бэкап
run job=BackupClient1 level=Incremental yes    # Incremental / Инкрементальный
run job=BackupClient1 level=Differential yes   # Differential / Дифференциальный

### List Jobs

list jobs                                      # List all jobs / Список всех задач
list jobs jobname=BackupClient1                # Jobs for specific client / Задачи для конкретного клиента
list jobs days=7                               # Jobs from last 7 days / Задачи за последние 7 дней

### Job Status

status client=client1-fd                       # Client status / Статус клиента
status dir running                             # Running jobs / Запущенные задачи
list joblog jobid=123                          # Job log / Лог задачи

### Cancel/Delete Jobs

cancel jobid=123                               # Cancel running job / Отменить запущенную задачу
delete job jobid=123                           # Delete job / Удалить задачу

---

## Volume & Pool Management

### List Volumes

list volumes                                   # List all volumes / Список всех томов
list volumes pool=Full                         # Volumes in pool / Тома в пуле
list media                                     # List media / Список носителей

### Volume Operations

label                                          # Label new volume / Пометить новый том
update volume=Vol-0001                         # Update volume / Обновить том
prune volume=Vol-0001                          # Prune expired jobs / Удалить устаревшие задачи
purge volume=Vol-0001                          # Purge all jobs (careful!) / Очистить все задачи (осторожно!)

### Pool Management

list pools                                     # List pools / Список пулов
update pool=Full                               # Update pool / Обновить пул

---

## Restore Operations

### Interactive Restore

restore                                        # Start restore wizard / Запустить мастер восстановления
restore all                                    # Restore all files / Восстановить все файлы
restore select                                 # Select files / Выбрать файлы

### Restore by Job ID

restore jobid=123                              # Restore from job / Восстановить из задачи
restore jobid=123 where=/tmp/restore           # Restore to alternate location / Восстановить в другое место

### Restore Latest

restore client=client1-fd select all done yes  # Restore latest / Восстановить последний

---

## Catalog Queries

### File Queries

list files jobid=123                           # List files in job / Список файлов в задаче
query                                          # Custom SQL query / Кастомный SQL запрос
list backups                                   # List all backups / Список всех бэкапов

### Client Queries

list clients                                   # List clients / Список клиентов
list jobs client=client1-fd                    # Jobs for client / Задачи для клиента

---

## Client Operations

### File Daemon Commands

systemctl status bareos-fd                     # Check FD status / Проверить статус FD
systemctl start bareos-fd                      # Start FD / Запустить FD
systemctl enable bareos-fd                     # Enable FD / Включить FD

### Estimate Backup Size

estimate job=BackupClient1                     # Estimate size / Оценить размер
estimate job=BackupClient1 level=Full          # Full backup estimate / Оценка полного бэкапа

---

## Configuration Essentials

### Director Config

/etc/bareos/bareos-dir.d/                      # Director config dir / Директория конфигурации директора

#### Sample Job

Job {
  Name = "BackupClient1"
  Type = Backup
  Level = Incremental
  Client = client1-fd
  FileSet = "Full Set"
  Schedule = "WeeklyCycle"
  Storage = File
  Messages = Standard
  Pool = Default
  Priority = 10
  Write Bootstrap = "/var/lib/bareos/%c.bsr"
}

### Storage Config

/etc/bareos/bareos-sd.d/                       # Storage config dir / Директория конфигурации хранилища

### Client Config

/etc/bareos/bareos-fd.d/                       # File Daemon config / Конфигурация File Daemon

#### Sample Client

Client {
  Name = client1-fd
  Address = <CLIENT_IP>
  FDPort = 9102
  Catalog = MyCatalog
  Password = "<PASSWORD>"
  File Retention = 60 days
  Job Retention = 6 months
  AutoPrune = yes
}

### FileSet Example

FileSet {
  Name = "Full Set"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
    File = /var/www
    File = /etc
  }
  Exclude {
    File = /tmp
    File = /var/tmp
    File = *.tmp
  }
}

---

## Troubleshooting

### Common Issues

# "No Jobs running" / "Нет запущенных задач"
status dir                                     # Check director / Проверить директор

# "Could not connect to client" / "Не удалось подключиться к клиенту"
systemctl status bareos-fd                     # Check FD service / Проверить сервис FD
telnet <CLIENT_IP> 9102                        # Test connectivity / Тестировать подключение

# "Volume errors" / "Ошибки тома"
list volumes                                   # Check volumes / Проверить тома
update volume                                  # Update volume status / Обновить статус тома

### Logs

journalctl -u bareos-dir                       # Director logs / Логи директора
journalctl -u bareos-sd                        # Storage logs / Логи хранилища
journalctl -u bareos-fd                        # FD logs / Логи FD

tail -f /var/log/bareos/bareos.log             # Bareos log / Лог Bareos

### Catalog Maintenance

bareos-dbcheck                                 # Check catalog / Проверить каталог
prune files                                    # Prune old files / Удалить старые файлы
prune jobs                                     # Prune old jobs / Удалить старые задачи
prune volumes                                  # Prune old volumes / Удалить старые тома

### Debug Mode

bareos-dir -d 100 -f                           # Debug director / Отладка директора
bareos-sd -d 100 -f                            # Debug storage / Отладка хранилища
bareos-fd -d 100 -f                            # Debug FD / Отладка FD
