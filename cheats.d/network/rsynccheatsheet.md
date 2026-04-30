Title: 🚚 rsync — File Synchronization
Group: Network
Icon: 🚚
Order: 8

# rsync — Fast Incremental File Synchronization

`rsync` is a fast, versatile file synchronization and transfer utility for Unix-like systems. It uses a delta-transfer algorithm to minimize data transfer by sending only the differences between source and destination files, making it ideal for backups, mirrors, and deployments.

📚 **Official Docs / Официальная документация:** [rsync(1)](https://download.samba.org/pub/rsync/rsync.1)

## Table of Contents
- [Basics](#basics)
- [Remote Sync via SSH](#remote-sync-via-ssh)
- [Mirror & Delete](#mirror--delete)
- [Exclude Patterns](#exclude-patterns)
- [Backups & Snapshots](#backups--snapshots)
- [Permissions & Ownership](#permissions--ownership)
- [Dry Run & Preview](#dry-run--preview)
- [Progress & Stats](#progress--stats)
- [Reference Tables](#reference-tables)

---

## Basics

### Core Sync Commands / Базовая синхронизация
```bash
rsync -avh --progress <SRC>/ <DEST>/  # Sync directory / Синхронизация каталогов
rsync -av <SRC>/ <DEST>/  # Archive mode (preserves permissions) / Архивный режим
rsync -avz <SRC>/ <DEST>/  # With compression / Со сжатием
rsync -avh <SRC>/ <DEST>/  # Human-readable sizes / Человекочитаемые размеры
rsync -aP <SRC>/ <DEST>/  # Archive with progress and partial / С прогрессом и докачкой
```

---

## Remote Sync via SSH

### Push to Remote / Отправка на удалённый
```bash
rsync -avz --progress -e "ssh -p 2222 -i ~/.ssh/id_ed25519" <SRC>/ <USER>@<HOST>:/path/  # Custom SSH port and key / Свой порт и ключ SSH
rsync -avz -e 'ssh -p 2222' /data/ <USER>@<HOST>:/backups/  # SSH on custom port with compression / SSH на нестандартном порту со сжатием
rsync -av /data/ backup:/backups/  # Use SSH config host alias / Использует псевдоним из ~/.ssh/config
```

### Pull from Remote / Загрузка с удалённого
```bash
rsync -avz --progress <USER>@<HOST>:/path/ ./<DEST>/  # Pull from remote / Загрузка с удалённого
rsync -avz -e 'ssh -p 2222' <USER>@<HOST>:/var/log/app/ ./logs/  # Pull logs over custom SSH port / Забирает логи по нестандартному порту
rsync -avz <USER>@<HOST>:/var/log/myapp/ ./server_logs/  # Pull app logs with compression / Забирает логи с сжатием
```

### Resume Large Files / Докачка больших файлов
```bash
rsync -avh --partial --append-verify <SRC>/ <DEST>/  # Resume large file transfers / Досыл больших файлов
rsync -av --progress --partial-dir=.partial-dir <USER>@<HOST>:/big/file.iso ./  # Resume via partial-dir / Докачка в безопасную временную папку
```

---

## Mirror & Delete

### Exact Mirroring / Точное зеркалирование
```bash
rsync -av --delete /<SRC>/ <USER>@<HOST>:/backup/projects/  # Mirror source to remote / Зеркалирует источник на сервере
rsync -avn --delete /<SRC>/ <USER>@<HOST>:/backup/projects/  # Dry run with deletions / Пробный запуск с удалениями
rsync -avz --delete <USER>@<HOST>:/var/www/ /local/mirror/  # Make exact local mirror / Локальное зеркало сайта
rsync -av --delete ~/projects/ /mnt/data/projects_backup/  # Local mirror with deletions / Локальное зеркалирование
rsync -avz --delete ./build/ <USER>@<HOST>:/var/www/mysite/  # Deploy build as exact mirror / Деплой сборки как зеркало
```

> [!WARNING]
> `--delete` removes files from the destination that don't exist in the source. Always test with `--dry-run` first! / `--delete` удаляет файлы из назначения, которых нет в источнике. Всегда проверяйте с `--dry-run` сначала!

---

## Exclude Patterns

### Basic Excludes / Базовые исключения
```bash
rsync -avh --delete --exclude ".git/" --exclude "*.tmp" <SRC>/ <DEST>/  # Exclude patterns / Исключить паттерны
rsync -av --exclude='b*' /<SRC>/ /<DST>/  # Exclude by simple pattern / Исключает файлы на «b»
rsync -av --exclude='data?.csv' /<SRC>/ /<DST>/  # Single-character wildcard / Один символ вместо «?»
rsync -av *.csv /backup/  # Copy only CSVs using shell glob / Только CSV-файлы
```

### Exclude from File / Исключения из файла
```bash
rsync -av --exclude-from='backup-exclude.txt' ~/important_data/ <USER>@<HOST>:/backups/  # Exclude rules from file / Правила из файла
rsync -avh --dry-run --exclude-from=/path/exclude.txt /<SRC>/ /<DST>/  # Preview with exclude file / Пробный прогон с исключениями
```

### Include/Exclude Patterns / Паттерны включения/исключения
```bash
rsync -av --include='src/' --include='src/**/*.py' --exclude='*' /source/project/ /backup/project/  # Include-only subtree / Только каталог src и Python
rsync -av --include='*/' --include='*.jpg' --include='*.png' --include='*.gif' --exclude='tmp/**' --exclude='*' /photos/ /backup/photos/  # Include images only / Только изображения
```

---

## Backups & Snapshots

### Simple Backups / Простые бэкапы
```bash
rsync -a ~/work/ /backups/work.2025-09-17/  # Initial full backup / Первая полная копия
```

### Hardlink Snapshots / Снимки с жёсткими ссылками
```bash
rsync -aH --link-dest=/prev/backup/ /<SRC>/ /new/backup/  # Snapshot using hardlinks / Снимок с хардлинками
rsync -a ~/work/ /backups/work.2025-09-17/  # Initial snapshot / Начальный снимок
rsync -aH --link-dest=/backups/work.2025-09-17/ ~/work/ /backups/work.2025-09-18/  # Incremental snapshot / Инкрементальный снимок
rsync -avh --dry-run --link-dest=/snapshots/prev/ /<SRC>/ /snapshots/new/  # Preview snapshot / Предпросмотр снимка
```

---

## Permissions & Ownership

### Preserve Ownership / Сохранение владельцев
```bash
sudo rsync -a server:/var/www/html/ ./backup/  # Preserve owners as root / Сохраняет владельцев
sudo rsync -a /<SOURCE>/ <USER>@<HOST>:/<DEST>/  # Push as root / Отправка от root
```

### Remap Ownership / Переназначение владельцев
```bash
rsync -a --usermap=www-data:webadmin --groupmap=www-data:webadmin server:/var/www/ ./backup/  # Remap owner/group / Переназначает владельца
rsync -a --usermap='*:backupuser' --groupmap='*:backupuser' /<SRC>/ /<DST>/  # Map all users / Меняет всех владельцев
rsync -a --numeric-ids server:/var/www/ ./backup/  # Preserve numeric UIDs / Сохраняет числовые UID/GID
```

---

## Dry Run & Preview

### Preview Changes / Предпросмотр изменений
```bash
rsync -avh --dry-run /<SRC>/ /<DST>/  # Preview archive copy / Предпросмотр копии
rsync -avh --dry-run --itemize-changes /<SRC>/ /<DST>/  # Show detailed changes / Детальный список изменений
rsync -avh --dry-run --delete /<SRC>/ /<DST>/  # Preview deletions / Предпросмотр удалений
rsync -avhn --delete <SRC>/ <DEST>/  # Dry-run with deletion preview / Прогон с показом удаления
```

---

## Progress & Stats

### Progress Monitoring / Мониторинг прогресса
```bash
rsync -avh --progress <SRC>/ <DEST>/  # Show progress per file / Прогресс по файлам
rsync -a --info=progress2 /<SRC>/ /<DST>/  # Global progress / Глобальный прогресс
rsync -avh --bwlimit=2m --info=stats2 <SRC>/ <DEST>/  # Bandwidth limit + stats / Ограничение + статистика
rsync -aP /<SRC>/ /<DST>/  # Archive with progress and partial / С прогрессом и докачкой
rsync -a --partial --partial-dir=.rsync-partials /<SRC>/ /<DST>/  # Keep partials in side dir / Недокачанные в отдельной папке
```

### Bandwidth Limiting / Ограничение пропускной способности
```bash
rsync -av --bwlimit=625 <USER>@<HOST>:/data/ /backup/  # Throttle to ~5 Mbps / Ограничить до ~5 Мбит/с
rsync -av --bwlimit=1024 <USER>@<HOST>:/data/ /backup/  # Throttle to 1 MiB/s / Ограничить до 1 МБ/с
rsync -avh --bwlimit=2m --info=stats2 <SRC>/ <DEST>/  # 2 MB/s limit with stats / 2 МБ/с с статистикой
```

---

## Reference Tables

### Common Flags / Распространённые флаги

| Flag | Description (EN / RU) |
| :--- | :--- |
| `-a` | Archive mode (same as -rlptgoD) / Архивный режим |
| `-v` | Verbose output / Подробный вывод |
| `-h` | Human-readable sizes / Человекочитаемые размеры |
| `-z` | Compress during transfer / Сжатие при передаче |
| `-P` | Same as --partial --progress / Прогресс + докачка |
| `-n` | Dry-run (no changes) / Пробный прогон |
| `--delete` | Delete extraneous files / Удалить лишние файлы |
| `--exclude` | Exclude pattern / Исключить паттерн |
| `--include` | Include pattern / Включить паттерн |
| `--partial` | Keep partial files / Сохранять недокачанные |
| `--bwlimit` | Limit bandwidth (KB/s) / Ограничить скорость |

### Use Cases Quick Reference / Быстрая справка сценариев

| Scenario | Command |
| :--- | :--- |
| Local backup | `rsync -avh --progress <SRC>/ /backup/` |
| Remote push | `rsync -avz <SRC>/ <USER>@<HOST>:/<DEST>/` |
| Remote pull | `rsync -avz <USER>@<HOST>:/<SRC>/ <DEST>/` |
| Mirror with delete | `rsync -av --delete <SRC>/ <DEST>/` |
| Incremental backup | `rsync -aH --link-dest=/prev/ <SRC>/ /new/` |
| Deploy website | `rsync -avz --delete ./build/ <USER>@<HOST>:/var/www/` |

> [!TIP]
> Always use trailing slashes on source dirs: `rsync <SRC>/ <DEST>/` copies **contents**, while `rsync <SRC> <DEST>/` copies the **directory itself**. Always test with `--dry-run` first. / Всегда используйте слеш в конце исходной папки. Всегда тестируйте с `--dry-run` сначала.
