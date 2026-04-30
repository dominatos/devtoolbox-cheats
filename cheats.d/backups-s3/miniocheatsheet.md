Title: 🗄️ MinIO & mc — S3-Compatible Object Storage
Group: Backups & S3
Icon: 🗄️
Order: 14

> **MinIO** is a high-performance, distributed object storage system fully compatible with the Amazon S3 API. It is used for storing large volumes of unstructured data such as photos, videos, backups, and application data. The `mc` (MinIO Client) provides a modern alternative to AWS CLI for managing MinIO and S3 storage. MinIO is actively developed and widely used as a self-hosted S3 replacement in private clouds, CI/CD pipelines, and Kubernetes environments.
> / **MinIO** — высокопроизводительная распределённая система хранения объектов, полностью совместимая с API Amazon S3. Используется для хранения больших объёмов неструктурированных данных. `mc` (MinIO Client) — современная альтернатива AWS CLI для управления MinIO и S3 хранилищем.

## Table of Contents
- [Installation & Configuration](#installation--configuration)
- [Core Management with mc](#core-management-with-mc)
- [Bucket Operations](#bucket-operations)
- [Object Operations](#object-operations)
- [Advanced Features](#advanced-features )
- [Administration](#administration)
- [AWS S3 Interoperability](#aws-s3-interoperability)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Comparison Tables](#comparison-tables)

---

## Installation & Configuration

### Install MinIO Server / Установка сервера MinIO

#### Standalone Mode / Автономный режим
```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio  # Download MinIO binary / Скачать MinIO
chmod +x minio  # Make executable / Сделать исполняемым
sudo mv minio /usr/local/bin/  # Move to PATH / Переместить в PATH
```

#### Start MinIO Server / Запуск сервера MinIO
```bash
export MINIO_ROOT_USER=<USER>        # Set admin username / Установить имя администратора
export MINIO_ROOT_PASSWORD=<PASSWORD>  # Set admin password / Установить пароль администратора
minio server /mnt/data  # Start server with data directory / Запустить сервер с директорией данных
```

**Default Ports / Порты по умолчанию:**
- **Web Console:** `http://127.0.0.1:9000`
- **API:** `http://127.0.0.1:9000`

#### Distributed Mode (Cluster) / Распределённый режим (кластер)
```bash
minio server http://<NODE1>/export http://<NODE2>/export http://<NODE3>/export http://<NODE4>/export
# Start distributed cluster / Запустить распределённый кластер
```

> [!NOTE]
> MinIO requires at least 4 nodes for erasure coding. Use `{1...4}` notation for sequential nodes: `http://node{1...4}/export`

### Install MinIO Client (mc) / Установка клиента MinIO
```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc  # Download mc binary / Скачать mc
chmod +x mc  # Make executable / Сделать исполняемым
sudo mv mc /usr/local/bin/  # Move to PATH / Переместить в PATH
mc --version  # Verify installation / Проверить установку
```

### Configuration Paths / Пути конфигурации
- **mc config:** `~/.mc/config.json`
- **MinIO server config:** `~/.minio/` or `/etc/minio/`

---

## Core Management with mc / Основное управление с mc

### Add MinIO Server Alias / Добавить алиас сервера MinIO
```bash
mc alias set <ALIAS> <URL> <ACCESS_KEY> <SECRET_KEY>  # Configure server alias / Настроить алиас сервера
mc alias list  # List all configured aliases / Список всех настроенных алиасов
mc alias remove <ALIAS>  # Remove alias / Удалить алиас
```

**Example:**
```bash
mc alias set myminio http://127.0.0.1:9000 <USER> <PASSWORD>  # Add local MinIO / Добавить локальный MinIO
mc ls myminio  # List buckets / Список бакетов
```

> [!TIP]
> Always verify your alias with `mc alias list` before performing destructive operations.

---

## Bucket Operations / Операции с бакетами

### Create Bucket / Создать бакет
```bash
mc mb <ALIAS>/<BUCKET>  # Make bucket / Создать бакет
mc mb myminio/photos  # Create "photos" bucket / Создать бакет "photos"
```

### List Buckets / Список бакетов
```bash
mc ls <ALIAS>  # List all buckets / Список всех бакетов
mc ls myminio  # List buckets on myminio / Список бакетов на myminio
```

### Delete Bucket / Удалить бакет
```bash
mc rb <ALIAS>/<BUCKET>  # Remove empty bucket / Удалить пустой бакет
mc rb <ALIAS>/<BUCKET> --force  # Force delete non-empty bucket / Принудительно удалить непустой бакет
```

> [!CAUTION]
> `mc rb --force` permanently deletes the bucket and all its contents. This operation is **irreversible**.

---

## Object Operations / Операции с объектами

### Upload Files / Загрузить файлы
```bash
mc cp <LOCAL_FILE> <ALIAS>/<BUCKET>/  # Copy file to bucket / Скопировать файл в бакет
mc cp /local/file.txt myminio/mybucket/  # Upload single file / Загрузить один файл
mc cp /local/dir/* myminio/mybucket/ --recursive  # Upload directory recursively / Загрузить директорию рекурсивно
```

### Download Files / Скачать файлы
```bash
mc cp <ALIAS>/<BUCKET>/<OBJECT> <LOCAL_PATH>  # Download object / Скачать объект
mc cp myminio/mybucket/file.txt /local/path/  # Download to local / Скачать локально
```

### Move Objects / Переместить объекты
```bash
mc mv <ALIAS>/<BUCKET>/<SRC> <ALIAS>/<BUCKET>/<DEST>  # Move object / Переместить объект
```

### Delete Objects / Удалить объекты
```bash
mc rm <ALIAS>/<BUCKET>/<OBJECT>  # Remove object / Удалить объект
mc rm <ALIAS>/<BUCKET>/<PREFIX> --recursive --force  # Delete all objects with prefix / Удалить все объекты с префиксом
```

### View Object Content / Просмотреть содержимое объекта
```bash
mc cat <ALIAS>/<BUCKET>/<OBJECT>  # Display object content / Показать содержимое объекта
mc head <ALIAS>/<BUCKET>/<OBJECT>  # Show first 10KB / Показать первые 10KB
mc tail <ALIAS>/<BUCKET>/<OBJECT>  # Show last 10KB / Показать последние 10KB
```

---

## Advanced Features / Продвинутые возможности

### Mirror/Sync Operations / Зеркалирование/Синхронизация
```bash
mc mirror <SRC> <DEST>  # Sync source to destination / Синхронизировать источник с назначением
mc mirror /local/dir/ myminio/mybucket/  # Local → MinIO sync / Синхронизация локально → MinIO
mc mirror myminio/mybucket/ /local/dir/  # MinIO → Local sync / Синхронизация MinIO → локально
mc mirror myminio/source/ myminio/backup/ --overwrite  # Overwrite existing / Перезаписать существующие
mc mirror myminio/source/ myminio/backup/ --remove  # Remove extra files / Удалить лишние файлы
```

> [!TIP]
> Use `mc mirror` with `--watch` flag for continuous synchronization: `mc mirror --watch /local/dir/ myminio/mybucket/`

### Versioning / Версионирование
```bash
mc version enable <ALIAS>/<BUCKET>  # Enable versioning / Включить версионирование
mc version info <ALIAS>/<BUCKET>  # Show versioning status / Показать статус версионирования
mc version list <ALIAS>/<BUCKET>  # List all versions / Список всех версий
```

### Access Policies / Политики доступа
```bash
mc policy set <POLICY> <ALIAS>/<BUCKET>  # Set bucket policy / Установить политику бакета
mc policy list <ALIAS>/<BUCKET>  # List current policy / Показать текущую политику
mc policy get <ALIAS>/<BUCKET>  # Get detailed policy / Получить детальную политику
```

**Available Policies:**
- `private` — Access restricted to owner only / Доступ только владельцу
- `public` — Anonymous read access / Анонимный доступ на чтение
- `download` — Anonymous download access / Анонимный доступ на скачивание
- `upload` — Anonymous upload access / Анонимный доступ на загрузку

**Example:**
```bash
mc policy set public myminio/mybucket  # Make bucket public / Сделать бакет публичным
```

> [!WARNING]
> Setting `public` policy allows **unauthenticated access** to all objects in the bucket. Use with caution in production.

---

## Administration / Администрирование

### Server Information / Информация о сервере
```bash
mc admin info <ALIAS>  # Show server info / Показать информацию о сервере
mc admin top <ALIAS>  # Show real-time stats / Показать статистику в реальном времени
mc admin trace <ALIAS>  # Trace API calls / Трассировать API вызовы
```

### User Management / Управление пользователями
```bash
mc admin user add <ALIAS> <USER> <PASSWORD>  # Add user / Добавить пользователя
mc admin user list <ALIAS>  # List users / Список пользователей
mc admin user remove <ALIAS> <USER>  # Remove user / Удалить пользователя
mc admin user disable <ALIAS> <USER>  # Disable user / Отключить пользователя
mc admin user enable <ALIAS> <USER>  # Enable user / Включить пользователя
```

### Group Management / Управление группами
```bash
mc admin group add <ALIAS> <GROUP> <USER1> <USER2>  # Create group / Создать группу
mc admin group remove <ALIAS> <GROUP>  # Remove group / Удалить группу
mc admin group info <ALIAS> <GROUP>  # Show group members / Показать членов группы
```

### Policy Management / Управление политиками
```bash
mc admin policy set <ALIAS> <POLICY> user=<USER>  # Assign policy to user / Назначить политику пользователю
mc admin policy set <ALIAS> <POLICY> group=<GROUP>  # Assign policy to group / Назначить политику группе
mc admin policy list <ALIAS>  # List all policies / Список всех политик
```

**Built-in Policies:**
- `readwrite` — Full read/write access / Полный доступ на чтение/запись
- `readonly` — Read-only access / Доступ только на чтение
- `writeonly` — Write-only access / Доступ только на запись
- `diagnostics` — Server diagnostics access / Доступ к диагностике сервера

---

## AWS S3 Interoperability / Совместимость с AWS S3

### Configure AWS S3 Alias / Настроить алиас AWS S3
```bash
mc alias set aws s3.amazonaws.com <AWS_ACCESS_KEY> <AWS_SECRET_KEY>  # Add AWS S3 / Добавить AWS S3
mc ls aws  # List S3 buckets / Список S3 бакетов
```

### Copy Between MinIO and S3 / Копирование между MinIO и S3
```bash
mc cp /local/file.txt aws/mybucket/  # Upload to S3 / Загрузить в S3
mc cp aws/mybucket/file.txt myminio/backup/  # Copy from S3 to MinIO / Копировать из S3 в MinIO
mc mirror aws/mybucket/ myminio/backup/  # Mirror S3 bucket to MinIO / Зеркалировать S3 бакет в MinIO
```

> [!NOTE]
> MinIO is fully compatible with S3 API, making it excellent for local testing before deploying to AWS S3.

---

## Troubleshooting & Tools / Устранение неполадок

### Common Issues / Типичные проблемы
```bash
# Connection refused / Отказ в подключении
mc alias list  # Verify alias configuration / Проверить конфигурацию алиаса
curl http://127.0.0.1:9000/minio/health/live  # Check server health / Проверить здоровье сервера

# Permission denied / Отказано в доступе
mc admin user info myminio <USER>  # Check user permissions / Проверить права пользователя
mc admin policy list myminio  # List available policies / Список доступных политик

# Slow uploads/downloads / Медленная загрузка/скачивание
mc cp --limit-upload 100M /local/file.txt myminio/mybucket/  # Limit upload speed / Ограничить скорость загрузки
```

### Debug Mode / Режим отладки
```bash
mc --debug cp /local/file.txt myminio/mybucket/  # Run with debug output / Запустить с отладочным выводом
mc admin trace myminio  # Trace all API calls / Трассировать все API вызовы
```

### Performance Tuning / Настройка производительности
```bash
mc cp /local/bigfile.bin myminio/mybucket/ --attr "Cache-Control=max-age=90000"  # Set cache headers / Установить заголовки кэша
```

---

## Comparison Tables / Таблицы сравнения

### MinIO Deployment Modes / Режимы развёртывания MinIO

| Mode | Nodes Required | Redundancy | Use Case |
| :--- | :--- | :--- | :--- |
| **Standalone** | 1 | None / Нет | Development, testing / Разработка, тестирование |
| **Distributed (Erasure Coded)** | 4+ | High / Высокая | Production, high availability / Продакшн, высокая доступность |

### mc vs AWS CLI / mc против AWS CLI

| Feature | mc | AWS CLI |
| :--- | :--- | :--- |
| **S3 Compatibility** | Full / Полная | Full / Полная |
| **MinIO Support** | Native / Нативная | Limited / Ограниченная |
| **Syntax** | Simple / Простой | Complex / Сложный |
| **Mirror Command** | Built-in / Встроенная | Requires sync / Требует sync |
| **Speed** | Fast / Быстрый | Moderate / Умеренный |

### Bucket Policies Comparison / Сравнение политик бакетов

| Policy | Read Access | Write Access | Use Case |
| :--- | :--- | :--- | :--- |
| **private** | Owner only / Только владелец | Owner only / Только владелец | Sensitive data / Конфиденциальные данные |
| **public** | Anonymous / Анонимный | Owner only / Только владелец | Static website hosting / Хостинг статических сайтов |
| **download** | Anonymous / Анонимный | Owner only / Только владелец | Public downloads / Публичные загрузки |
| **upload** | Owner only / Только владелец | Anonymous / Анонимный | Public file uploads / Публичная загрузка файлов |

---

## Best Practices / Лучшие практики

1. **Always verify aliases** before destructive operations: `mc alias list`
2. **Use `--watch` with mirror** for continuous sync: `mc mirror --watch /local/ myminio/backup/`
3. **Enable versioning** for critical buckets to protect against accidental deletion
4. **Use erasure coding** in distributed mode for data redundancy
5. **Set appropriate bucket policies** to control access
6. **Regular backups** to another MinIO instance: `mc mirror myminio/data/ backup-minio/data/`
7. **Monitor server health**: `mc admin info myminio` and `mc admin top myminio`
8. **Use TLS** in production: configure MinIO with SSL certificates

---

## Additional Resources / Дополнительные ресурсы

- [MinIO Documentation](https://docs.min.io)
- [mc Client Complete Guide](https://docs.min.io/docs/minio-client-complete-guide.html)
- [MinIO Admin Guide](https://docs.min.io/docs/minio-admin-complete-guide.html)
