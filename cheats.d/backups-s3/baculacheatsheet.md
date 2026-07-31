Title: 🗄️ Bareos/Bacula — Enterprise Backup
Group: Backups & S3
Icon: 🗄️
Order: 6

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Installation](#installation)
- [bconsole Basics](#bconsole-basics)
- [Job Management](#job-management)
- [Volume & Pool Management](#volume-pool-management)
- [Restore Operations](#restore-operations)
- [Catalog Queries](#catalog-queries)
- [Client Operations](#client-operations)
- [Configuration Essentials](#configuration-essentials)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Components & Default Ports / Компоненты и порты по умолчанию

| Component | Description / Описание | Default Port |
|-----------|------------------------|-------------|
| **Director** | Central scheduler & control / Центральный планировщик | 9101 |
| **Storage Daemon** | Manages volumes & media / Управляет томами | 9103 |
| **File Daemon (Client)** | Agent on backup clients / Агент на клиентах | 9102 |
| **Catalog** | PostgreSQL/MySQL metadata DB / БД метаданных | 5432 / 3306 |

> [!TIP]
> Bareos is the actively maintained fork of Bacula with additional features and more frequent releases. Use Bareos for new deployments.

---

## Installation

### Bareos (Recommended / Рекомендуется)

```bash
# Debian/Ubuntu (Debian 12 example)
wget -q https://download.bareos.org/current/Debian_12/Release.key -O- | apt-key add -
echo "deb https://download.bareos.org/current/Debian_12/ /" > /etc/apt/sources.list.d/bareos.list
apt update && apt install bareos bareos-database-postgresql  # Install / Установить

# RHEL / AlmaLinux / Rocky
dnf install bareos bareos-database-postgresql  # Install / Установить
```

### Bacula (Original)

```bash
# Debian/Ubuntu
apt install bacula bacula-director-mysql bacula-sd bacula-fd
```

### Initialize Catalog Database / Инициализация базы каталога

```bash
/usr/lib/bareos/scripts/create_bareos_database     # Create DB / Создать БД
/usr/lib/bareos/scripts/make_bareos_tables          # Create tables / Создать таблицы
/usr/lib/bareos/scripts/grant_bareos_privileges     # Grant privileges / Выдать права
```

---

## bconsole Basics

```bash
bconsole                                        # Start console / Запустить консоль
```

### Common bconsole Commands / Основные команды bconsole

```bash
status dir                                      # Director status / Статус директора
status client                                   # Client status / Статус клиента
status storage                                  # Storage status / Статус хранилища
messages                                        # Show recent messages / Последние сообщения
quit                                            # Exit console / Выйти из консоли
help                                            # Show all commands / Все команды
```

---

## Job Management

### Run Jobs / Запустить задачи

```bash
run                                             # Run job (interactive wizard) / Интерактивный запуск
run job=BackupClient1 yes                       # Run specific job / Конкретная задача
run job=BackupClient1 level=Full yes            # Full backup / Полный бэкап
run job=BackupClient1 level=Incremental yes     # Incremental / Инкрементальный
run job=BackupClient1 level=Differential yes    # Differential / Дифференциальный
```

### List & Monitor Jobs / Список и мониторинг задач

```bash
list jobs                                       # All jobs / Все задачи
list jobs jobname=BackupClient1                 # Jobs for specific client / Задачи клиента
list jobs days=7                                # Jobs from last 7 days / Задачи за 7 дней
status dir running                              # Running jobs only / Только запущенные
list joblog jobid=<JOB_ID>                      # Log for specific job / Лог задачи
```

### Cancel & Delete / Отменить и удалить

> [!WARNING]
> `delete job` removes the job record from the catalog permanently. The data on volumes is not immediately freed — run `prune` or `purge` afterward.

```bash
cancel jobid=<JOB_ID>                           # Cancel running job / Отменить запущенную
delete job jobid=<JOB_ID>                       # Delete job from catalog / Удалить из каталога
```

---

## Volume & Pool Management

### List Volumes / Список томов

```bash
list volumes                                    # All volumes / Все тома
list volumes pool=Full                          # Volumes in specific pool / Тома в пуле
list media                                      # List media / Список носителей
```

### Volume Operations / Операции с томами

```bash
label                                           # Label new volume / Пометить новый том
update volume=Vol-0001                          # Update volume properties / Обновить свойства
prune volume=Vol-0001                           # Remove expired job records / Удалить устаревшие записи

# Purge removes ALL job data from volume — use with caution!
# / Purge удаляет ВСЕ данные задач из тома — используйте осторожно!
purge volume=Vol-0001
```

> [!CAUTION]
> `purge volume` removes ALL backup records referencing that volume from the catalog, making recovery impossible. Only use when decommissioning a volume.

### Pool Management / Управление пулами

```bash
list pools                                      # List pools / Список пулов
update pool=Full                                # Update pool settings / Обновить настройки пула
```

---

## Restore Operations

### Interactive Restore / Интерактивное восстановление

```bash
restore                                         # Restore wizard / Мастер восстановления
restore all                                     # Restore all files / Восстановить все файлы
restore select                                  # Select files interactively / Выбрать файлы
```

### Restore by Job ID / Восстановление по ID задачи

```bash
restore jobid=<JOB_ID>                          # Restore from job / Восстановить из задачи
restore jobid=<JOB_ID> where=/tmp/restore       # Restore to alternate path / В другое место
```

### Restore Latest / Восстановление последней версии

```bash
restore client=client1-fd select all done yes  # Restore latest / Восстановить последний
```

---

## Catalog Queries

```bash
list files jobid=<JOB_ID>                       # Files in job / Файлы в задаче
list clients                                    # List clients / Список клиентов
list jobs client=client1-fd                     # Jobs for client / Задачи клиента
list backups                                    # All backups / Все бэкапы
query                                           # Custom SQL query / Кастомный SQL запрос
```

---

## Client Operations

### File Daemon Service / Сервис File Daemon

```bash
systemctl status bareos-fd                      # Check FD status / Проверить статус
systemctl start bareos-fd                       # Start FD / Запустить
systemctl enable bareos-fd                      # Enable at boot / Включить при загрузке
```

### Estimate Backup Size / Оценить размер бэкапа

```bash
estimate job=BackupClient1                      # Estimate all / Оценить всё
estimate job=BackupClient1 level=Full           # Estimate full backup / Оценить полный бэкап
```

---

## Configuration Essentials

### Director Configuration / Конфигурация директора

`/etc/bareos/bareos-dir.d/`

```
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
```

### Storage Daemon Configuration / Конфигурация Storage Daemon

`/etc/bareos/bareos-sd.d/`

### Client (File Daemon) Configuration / Конфигурация клиента

`/etc/bareos/bareos-fd.d/`

```
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
```

### FileSet Example / Пример FileSet

`/etc/bareos/bareos-dir.d/fileset/`

```
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
```

---

## Sysadmin Operations

### Service Management / Управление сервисами

```bash
systemctl status bareos-dir                     # Director status / Статус директора
systemctl status bareos-sd                      # Storage Daemon status / Статус хранилища
systemctl status bareos-fd                      # File Daemon status / Статус File Daemon
systemctl restart bareos-dir                    # Restart director / Перезапустить директора
```

### Logs & Monitoring / Логи и мониторинг

```bash
journalctl -u bareos-dir                        # Director logs / Логи директора
journalctl -u bareos-sd                         # Storage logs / Логи хранилища
journalctl -u bareos-fd                         # FD logs / Логи FD
tail -f /var/log/bareos/bareos.log              # Bareos combined log / Общий лог
```

### Log Paths / Пути логов

```bash
/var/log/bareos/bareos.log         # Main log / Основной лог
/var/log/bareos/bareos-audit.log   # Audit log / Аудит лог
```

### Logrotate / Logrotate

`/etc/logrotate.d/bareos`

```
/var/log/bareos/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        systemctl kill --signal=HUP bareos-dir 2>/dev/null || true
    endscript
}
```

---

## Troubleshooting

### Common Issues / Распространённые проблемы

```bash
# "No Jobs running" / "Нет запущенных задач"
status dir                                      # Check director / Проверить директора
messages                                        # Check messages / Проверить сообщения

# "Could not connect to client" / "Нет подключения к клиенту"
systemctl status bareos-fd                      # Client FD running? / FD запущен?
telnet <CLIENT_IP> 9102                         # Test TCP connectivity / Тест соединения

# "Volume errors" / "Ошибки тома"
list volumes                                    # Check volume status / Статус томов
update volume                                   # Fix volume status / Исправить статус
```

### Catalog Maintenance / Обслуживание каталога

```bash
bareos-dbcheck                                  # Check catalog integrity / Проверить каталог
prune files                                     # Remove expired file records / Удалить устаревшие
prune jobs                                      # Remove expired job records / Удалить устаревшие задачи
prune volumes                                   # Remove expired volumes / Удалить устаревшие тома
```

### Debug Mode / Режим отладки

```bash
bareos-dir -d 100 -f                            # Debug director / Отладка директора
bareos-sd -d 100 -f                             # Debug storage / Отладка хранилища
bareos-fd -d 100 -f                             # Debug FD / Отладка FD
```

## Documentation

- **Bacula Documentation:** https://www.bacula.org/
- **Bacula Man Pages:** https://www.bacula.org/manuals/

#backups #s3 #sysadmin #linux
