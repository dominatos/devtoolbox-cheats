Title: 🚚 RSYNC — File Synchronization
Group: Network
Icon: 🚚
Order: 8

## Table of Contents
- [Basics](#-basics--основы)
- [Remote Sync via SSH](#-remote-sync-via-ssh--синхронизация-через-ssh)
- [Mirror & Delete](#-mirror--delete--зеркалирование-и-удаление)
- [Exclude Patterns](#-exclude-patterns--исключение-паттернов)
- [Backups & Snapshots](#-backups--snapshots--бэкапы-и-снимки)
- [Permissions & Ownership](#-permissions--ownership--права-и-владельцы)
- [Dry Run & Preview](#-dry-run--preview--пробный-прогон-и-предпросмотр)
- [Progress & Stats](#-progress--stats--прогресс-и-статистика)
- [Best Practices](#-best-practices--лучшие-практики)

---

# 📘 Basics / Основы

rsync -avh --progress <SRC>/ <DEST>/  # Sync directory / Синхронизация каталогов
rsync -av <SRC>/ <DEST>/  # Archive mode (preserves permissions) / Архивный режим
rsync -avz <SRC>/ <DEST>/  # With compression / Со сжатием
rsync -avh <SRC>/ <DEST>/  # Human-readable sizes / Человекочитаемые размеры
rsync -aP <SRC>/ <DEST>/  # Archive with progress and partial / С прогрессом и докачкой

---

# 🌐 Remote Sync via SSH / Синхронизация через SSH

### Push to Remote / Отправка на удалённый
rsync -avz --progress -e "ssh -p 2222 -i ~/.ssh/id_ed25519" <SRC>/ <user>@<host>:/path/  # Custom SSH port and key / Свой порт и ключ SSH
rsync -avz -e 'ssh -p 2222' /data/ <user>@<host>:/backups/  # SSH on custom port with compression / SSH на нестандартном порту со сжатием
rsync -av /data/ backup:/backups/  # Use SSH config host alias / Использует псевдоним из ~/.ssh/config

### Pull from Remote / Загрузка с удалённого
rsync -avz --progress <user>@<host>:/path/ ./<DEST>/  # Pull from remote / Загрузка с удалённого
rsync -avz -e 'ssh -p 2222' <user>@<host>:/var/log/app/ ./logs/  # Pull logs over custom SSH port / Забирает логи по нестандартному порту
rsync -avz <user>@<host>:/var/log/myapp/ ./server_logs/  # Pull app logs with compression / Забирает логи с сжатием

### Resume Large Files / Докачка больших файлов
rsync -avh --partial --append-verify <SRC>/ <DEST>/  # Resume large file transfers / Досыл больших файлов
rsync -av --progress --partial-dir=.partial-dir <user>@<host>:/big/file.iso ./  # Resume via partial-dir / Докачка в безопасную временную папку

---

# 🔄 Mirror & Delete / Зеркалирование и удаление

rsync -av --delete /<SRC>/ <user>@<host>:/backup/projects/  # Mirror source to remote / Зеркалирует источник на сервере
rsync -avn --delete /<SRC>/ <user>@<host>:/backup/projects/  # Dry run with deletions / Пробный запуск с удалениями
rsync -avz --delete <user>@<host>:/var/www/ /local/mirror/  # Make exact local mirror / Локальное зеркало сайта
rsync -av --delete ~/projects/ /mnt/data/projects_backup/  # Local mirror with deletions / Локальное зеркалирование
rsync -avz --delete ./build/ <user>@<host>:/var/www/mysite/  # Deploy build as exact mirror / Деплой сборки как зеркало

---

# 🚫 Exclude Patterns / Исключение паттернов

### Basic Excludes / Базовые исключения
rsync -avh --delete --exclude ".git/" --exclude "*.tmp" <SRC>/ <DEST>/  # Exclude patterns / Исключить паттерны
rsync -av --exclude='b*' /<SRC>/ /<DST>/  # Exclude by simple pattern / Исключает файлы на «b»
rsync -av --exclude='data?.csv' /<SRC>/ /<DST>/  # Single-character wildcard / Один символ вместо «?»
rsync -av *.csv /backup/  # Copy only CSVs using shell glob / Только CSV-файлы

### Exclude from File / Исключения из файла
rsync -av --exclude-from='backup-exclude.txt' ~/important_data/ <user>@<host>:/backups/  # Exclude rules from file / Правила из файла
rsync -avh --dry-run --exclude-from=/path/exclude.txt /<SRC>/ /<DST>/  # Preview with exclude file / Пробный прогон с исключениями

### Include/Exclude Patterns / Паттерны включения/исключения
rsync -av --include='src/' --include='src/**/*.py' --exclude='*' /source/project/ /backup/project/  # Include-only subtree / Только каталог src и Python
rsync -av --include='*/' --include='*.jpg' --include='*.png' --include='*.gif' --exclude='tmp/**' --exclude='*' /photos/ /backup/photos/  # Include images only / Только изображения

---

# 💾 Backups & Snapshots / Бэкапы и снимки

### Simple Backups / Простые бэкапы
rsync -a ~/work/ /backups/work.2025-09-17/  # Initial full backup / Первая полная копия

### Hardlink Snapshots / Снимки с жёсткими ссылками
rsync -aH --link-dest=/prev/backup/ /<SRC>/ /new/backup/  # Snapshot using hardlinks / Снимок с хардлинками
rsync -a ~/work/ /backups/work.2025-09-17/  # Initial snapshot / Начальный снимок  
rsync -aH --link-dest=/backups/work.2025-09-17/ ~/work/ /backups/work.2025-09-18/  # Incremental snapshot / Инкрементальный снимок
rsync -avh --dry-run --link-dest=/snapshots/prev/ /<SRC>/ /snapshots/new/  # Preview snapshot / Предпросмотр снимка

---

# 👤 Permissions & Ownership / Права и владельцы

### Preserve Ownership / Сохранение владельцев
sudo rsync -a server:/var/www/html/ ./backup/  # Preserve owners as root / Сохраняет владельцев
sudo rsync -a /<SOURCE>/ <user>@<host>:/<DEST>/  # Push as root / Отправка от root

### Remap Ownership / Переназначение владельцев
rsync -a --usermap=www-data:webadmin --groupmap=www-data:webadmin server:/var/www/ ./backup/  # Remap owner/group / Переназначает владельца
rsync -a --usermap='*:backupuser' --groupmap='*:backupuser' /<SRC>/ /<DST>/  # Map all users / Меняет всех владельцев
rsync -a --numeric-ids server:/var/www/ ./backup/  # Preserve numeric UIDs / Сохраняет числовые UID/GID

---

# 🔍 Dry Run & Preview / Пробный прогон и предпросмотр

rsync -avh --dry-run /<SRC>/ /<DST>/  # Preview archive copy / Предпросмотр копии
rsync -avh --dry-run --itemize-changes /<SRC>/ /<DST>/  # Show detailed changes / Детальный список изменений
rsync -avh --dry-run --delete /<SRC>/ /<DST>/  # Preview deletions / Предпросмотр удалений
rsync -avhn --delete <SRC>/ <DEST>/  # Dry-run with deletion preview / Прогон с показом удаления

---

# 📊 Progress & Stats / Прогресс и статистика

rsync -avh --progress <SRC>/ <DEST>/  # Show progress per file / Прогресс по файлам
rsync -a --info=progress2 /<SRC>/ /<DST>/  # Global progress / Глобальный прогресс
rsync -avh --bwlimit=2m --info=stats2 <SRC>/ <DEST>/  # Bandwidth limit + stats / Ограничение + статистика
rsync -aP /<SRC>/ /<DST>/  # Archive with progress and partial / С прогрессом и докачкой
rsync -a --partial --partial-dir=.rsync-partials /<SRC>/ /<DST>/  # Keep partials in side dir / Недокачанные в отдельной папке

### Bandwidth Limiting / Ограничение пропускной способности
rsync -av --bwlimit=625 <user>@<host>:/data/ /backup/  # Throttle to ~5 Mbps / Ограничить до ~5 Мбит/с
rsync -av --bwlimit=1024 <user>@<host>:/data/ /backup/  # Throttle to 1 MiB/s / Ограничить до 1 МБ/с
rsync -avh --bwlimit=2m --info=stats2 <SRC>/ <DEST>/  # 2 MB/s limit with stats / 2 МБ/с с статистикой

---

# 💡 Best Practices / Лучшие практики

# Always use trailing slashes on source dirs / Всегда используйте слеш в конце исходной папки
# rsync <SRC>/ <DEST>/  - copies contents / копирует содержимое
# rsync <SRC> <DEST>/   - copies directory itself / копирует саму папку

# Always test with --dry-run first / Всегда тестируйте с --dry-run сначала
# Use --delete carefully - can wipe data / --delete опасен - может удалить данные
# Use -e "ssh -p <PORT>" for non-standard SSH / Используйте -e для нестандартных портов SSH
# Use --partial for resuming interrupted transfers / --partial для возобновления передач
# Use --link-dest for space-efficient snapshots / --link-dest для экономии места
# Combine -a with -z for remote syncs / Комбинируйте -a с -z для удалённых синхронизаций

# 🔧 Common Flags / Распространённые флаги
# -a  — Archive mode (same as -rlptgoD) / Архивный режим
# -v  — Verbose output / Подробный вывод
# -h  — Human-readable sizes / Человекочитаемые размеры
# -z  — Compress during transfer / Сжатие при передаче
# -P  — Same as --partial --progress / Прогресс + докачка
# -n  — Dry-run (no changes) / Пробный прогон
# --delete  — Delete extraneous files / Удалить лишние файлы
# --exclude  — Exclude pattern / Исключить паттерн
# --include  — Include pattern / Включить паттерн
# --partial  — Keep partial files / Сохранять недокачанные
# --bwlimit  — Limit bandwidth (KB/s) / Ограничить скорость

# 📋 Use Cases / Сценарии использования
# Local backup:        rsync -avh --progress <SRC>/ /backup/
# Remote push:         rsync -avz <SRC>/ <user>@<host>:/<DEST>/
# Remote pull:         rsync -avz <user>@<host>:/<SRC>/ <DEST>/
# Mirror with delete:  rsync -av --delete <SRC>/ <DEST>/
# Incremental backup:  rsync -aH --link-dest=/prev/ <SRC>/ /new/
# Deploy website:      rsync -avz --delete ./build/ <user>@<host>:/var/www/
