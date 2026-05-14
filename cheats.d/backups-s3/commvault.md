Title: 🗄️ Commvault v11 — Enterprise Backup
Group: Backups & S3
Icon: 🗄️
Order: 1

> **Commvault v11 (Simpana)** is a unified data management and protection platform for enterprise environments. It provides backup, recovery, archiving, and replication across physical, virtual, and cloud workloads. Commvault is widely used in large organizations for centralized backup management with a single CommServe console managing thousands of clients.
> / **Commvault v11 (Simpana)** — унифицированная платформа управления и защиты данных для корпоративных сред. Обеспечивает резервное копирование, восстановление, архивирование и репликацию для физической, виртуальной и облачной инфраструктуры.

> [!NOTE]
> Commvault v11 (Simpana) is a legacy product. Current versions are branded **Commvault Complete™ Backup & Recovery** (v2024+). The CLI and architecture remain similar but the web UI has been significantly modernized.

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security & Auth](#security--auth)
- [Performance Tuning](#performance-tuning)
- [Database Protection](#database-protection)
- [Backup & Restore](#backup--restore)
- [Troubleshooting](#troubleshooting)
- [Additional Notes](#additional-notes)

---

## Installation & Configuration

### Default Ports / Порты по умолчанию

| Port / Порт | Service / Сервис | Description (EN / RU) |
| :--- | :--- | :--- |
| `8400` | Commv_CVD | Data transmission and control / Передача данных и контроль |
| `8403` | Commv_EvMgrC | Event Manager / Менеджер событий |
| `81` | Web Console | Optional HTTP / Опционально HTTP |
| `443` | Command Center | HTTPS Web UI / Веб-интерфейс HTTPS |

### Core Registry Paths / Основные пути в реестре (Linux)
`/etc/CommVaultRegistry`

```bash
cat /etc/CommVaultRegistry/Galaxy/Instance001/.properties  # View instance properties / Просмотреть свойства инстанса
```

### System Tuning / Настройка системы
`/etc/sysctl.conf`

```bash
# Recommended for MediaAgent / Рекомендуется для MediaAgent
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 655360
```

---

## Core Management

### CLI Login / Вход через CLI
`/opt/commvault/Base`

```bash
./qlogin -cs <HOST> -u <USER>  # Basic login / Базовый вход
# Password will be prompted / Пароль будет запрошен
```

### Resource Listing / Просмотр ресурсов

```bash
./qlist client  # List all clients / Список всех клиентов
./qlist mediaagent  # List all MediaAgents / Список всех MediaAgent
./qlist job -c <HOST>  # List active jobs for client / Список активных заданий клиента
```

### Job Control / Управление заданиями

```bash
./qoperation job_control -j <JOB_ID> -o suspend  # Suspend job / Приостановить задание
./qoperation job_control -j <JOB_ID> -o resume   # Resume job / Возобновить задание
./qoperation job_control -j <JOB_ID> -o kill     # Kill job / Убить задание
```

> [!CAUTION]
> Killing a backup job may leave partial data or snapshots. Use only if job is hung.
> / Принудительное завершение задания может оставить частичные данные или снапшоты. Используйте только если задание зависло.

---

## Sysadmin Operations

### Service Control / Управление сервисами

```bash
commvault status   # Check overall status / Проверить общий статус
commvault stop     # Stop all services / Остановить все сервисы
commvault start    # Start all services / Запустить все сервисы
commvault restart  # Restart services / Перезапустить сервисы
```

### Log Locations / Расположение логов
`/var/log/commvault/Log_Files` (Simpana 11)

```bash
tail -f CVD.log        # Core service logs / Логи основного сервиса
tail -f EvMgrC.log     # Event manager logs / Логи менеджера событий
tail -f install.log    # Installation diagnostics / Диагностика установки
```

### Infrastructure Components / Компоненты инфраструктуры

| Component / Компонент | Description (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| **CommServe** | Central Management / Центр управления | Mandatory (1 per CommCell) / Обязательно |
| **MediaAgent** | Data Mover / Передатчик данных | Scalability / Для масштабирования |
| **iDataAgent** | Agent on Client / Агент на клиенте | Specific OS/DB protection / Защита конкретных ОС/БД |

---

## Security & Auth

### Certificate Management / Управление сертификатами

```bash
./qoperation qreinit_cert -c <HOST>  # Reinitialize certificate / Переинициализировать сертификат
```

### User Permissions / Права пользователей

```bash
./qlist usergroup  # View user groups / Просмотреть группы пользователей
```

---

## Performance Tuning

### Data Streams Configuration / Настройка потоков данных (Multi-streaming)

To increase backup speed, you can configure the number of parallel connections (streams).
/ Для увеличения скорости бэкапа можно настроить количество параллельных соединений (потоков).

**Via Command Center (Web UI):**
1.  Navigate to **Manage > Servers > [Server Name]**.
2.  Click on the **Subclient** (e.g., default).
3.  Under **Settings**, find **Number of Data Streams**.
4.  Increase the value (Default is 1, recommended 4-8 for high-speed disks).

**Via CommCell Console (Java GUI):**
1.  Client Computers > `[Client Name]` > `[Agent Name]` > `[Backup Set]`.
2.  Right-click **Subclient** > **Properties**.
3.  **Storage Device** tab > **Data Transfer Option** sub-tab.
4.  Set **Max Number of Data Pipes** / **Number of Data Readers**.

### Registry Tuning (Linux/Windows) / Настройка через реестр
`/etc/CommVaultRegistry/Galaxy/Instance001/.properties`

```bash
# Increase parallel transfer limit on Agent / Увеличить лимит параллельной передачи на агенте
nMaxParallelTransfers 8  # Set to desired number / Установите желаемое число
```

> [!TIP]
> **Number of Data Readers** should not exceed the number of CPU cores or available network bandwidth.
> / **Количество читателей данных** не должно превышать количество ядер CPU или доступную пропускную способность сети.

### Low Impact Backups / Бэкап с низким влиянием на систему

To minimize impact on production workloads during business hours.
/ Для минимизации влияния на рабочие нагрузки в рабочее время.

**Network Throttling / Ограничение сетевого трафика:**
1.  **Command Center:** Manage > Servers > [Server] > Configuration > **Network Throttling**.
2.  Enable throttling and set the limit (e.g., 500 Mbps) and schedule.
    / Включите ограничение и установите лимит (например, 500 Мбит/с) и расписание.

**CPU Priority / Приоритет CPU:**
1.  **Console:** Right-click Client > **Properties** > **Advanced**.
2.  **Job Configuration** tab > **CPU Priority**.
3.  Set to **Below Normal** or **Low**.
    / Установите значение **Below Normal** или **Low**.

**Operation Windows / Окна выполнения операций:**
1.  Right-click CommServe/Client > **All Tasks** > **Operation Window**.
2.  Click **Add** to define a "Blackout Window" (e.g., Mon-Fri 09:00-18:00).
    / Нажмите **Add**, чтобы определить окно запрета операций (например, Пн-Пт 09:00-18:00).
3.  Select operations to ignore (e.g., Full Backups).
    / Выберите операции, которые следует игнорировать (например, Full Backups).

---

## Database Protection

### MongoDB Protection / Защита MongoDB

Commvault supports both traditional and IntelliSnap (hardware-based) backups for MongoDB.
/ Commvault поддерживает как традиционное, так и аппаратное (IntelliSnap) резервное копирование для MongoDB.

**Agent Configuration / Конфигурация агента:**
1.  **Linux Client:** Requires `mongosh` or `mongo` shell in PATH.
    / **Клиент Linux:** Требует `mongosh` или `mongo` shell в PATH.
2.  **Permissions:** Create a backup user in MongoDB `admin` database.
    ```javascript
    db.createUser({ user: "<USER>", pwd: "<PASSWORD>", roles: ["backup", "clusterMonitor"] })
    ```

**Physical vs Logical Backup / Физический и логический бэкап:**

| Backup Method / Метод | Logic (EN / RU) | Best for... / Когда использовать |
| :--- | :--- | :--- |
| **IntelliSnap** | Volume snapshots + oplog / Снапшоты томов + oplog | Large clusters (>1TB) / Большие кластеры |
| **Logical** | `mongodump` via pipes / `mongodump` через пайпы | Small databases / Небольшие базы |

**Manual Backup Trigger / Ручной запуск бэкапа:**
`/opt/commvault/Base`

```bash
./qoperation backup -c <HOST> -a "BigData Apps" -i "MongoDB" -t FULL  # Trigger Full / Запустить полный бэкап
```

### MySQL & PostgreSQL / Защита MySQL и PostgreSQL

1.  **Binaries:** Specify paths to `mysqldump` or `pg_dump` in subclient properties.
    / **Бинарные файлы:** Укажите пути к `mysqldump` или `pg_dump` в свойствах subclient.
2.  **Staging:** Commvault creates a temporary dump in the configured staging directory.
    / **Стейджинг:** Commvault создает временный дамп в настроенном каталоге стейджинга.

**Service Accounts / Сервисные учетные записи:**

```bash
# Verify mysql access / Проверить доступ к mysql
mysql -u <USER> -p<PASSWORD> -e "SHOW DATABASES;"
```

> [!IMPORTANT]
> **PostgreSQL:** Ensure the `postgres` user group has read access to the data directory for physical backups.
> / **PostgreSQL:** Убедитесь, что группа пользователей `postgres` имеет доступ на чтение к каталогу данных для физических бэкапов.

---

## Backup & Restore

### Backup Types Comparison / Сравнение типов бэкапа

| Type / Тип | Description (EN / RU) | Best for... / Лучше всего для... |
| :--- | :--- | :--- |
| **Full** | Complete data copy / Полная копия данных | Baseline / Базовая точка |
| **Incremental** | Only changed data / Только измененные данные | Daily window / Ежедневное окно |
| **Synthetic Full** | Combines Incr+Full on MA / Собирает Incr+Full на MediaAgent | Reducing client load / Снижение нагрузки на клиент |

### Production Runbook: Agent Deployment / Инструкция: Развертывание агента

1.  **Preparation:** Verify ports `8400` and `8403` are open in firewall.
    / **Подготовка:** Проверьте доступность портов `8400` и `8403`.
2.  **Binary Transfer:** Copy CVPkgSmg to `<HOST>`.
    / **Перенос:** Скопируйте CVPkgSmg на `<HOST>`.
3.  **Silent Install:**
    ```bash
    ./cvpkgadd -isC1 -instance Instance001 -client <HOST> -cs <COMM_SERVE_IP>
    ```
4.  **Verification:** Check status.
    ```bash
    commvault status
    ```

---

## Troubleshooting

### Diagnostic Tools / Инструменты диагностики

```bash
/opt/commvault/Base/cvcheck -all  # Comprehensive health check / Комплексная проверка здоровья
```

### Network Connectivity / Сетевая связность

```bash
./CvPing <CS_HOST> -p 8400  # Internal ping tool / Внутренняя утилита пинга
```

> [!WARNING]
> High CPU/Memory usage by MediaAgent is normal during deduplication.
> / Высокое потребление CPU/RAM на MediaAgent — это нормально во время дедупликации.

---

## Additional Notes

### Log Rotation / Ротация логов

Commvault manages its own log rotation inside `/var/log/commvault/Log_Files`.
If you need to use system logrotate:

`/etc/logrotate.d/commvault`

```
/var/log/commvault/Log_Files/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```
