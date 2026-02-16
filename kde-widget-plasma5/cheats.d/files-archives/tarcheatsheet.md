Title: 📦 TAR — Commands
Group: Files & Archives
Icon: 📦
Order: 2

## Table of Contents
- [Basic Operations](#-basic-operations--базовые-операции)
- [Compression Formats](#-compression-formats--formats-сжатия)
- [Advanced Options](#-advanced-options--продвинутые-опции)
- [Extraction & Listing](#-extraction--listing--распаковка-и-просмотр)
- [Backup & Restore](#-backup--restore--резервное-копирование-и-восстановление)
- [Network Transfer](#-network-transfer--передача-по-сети)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)

---

# 📦 Basic Operations / Базовые операции

### Create Archives / Создание архивов
tar -cvf archive.tar folder/                   # Create tar archive / Создать tar архив
tar -cvf archive.tar file1 file2 dir/          # Multiple files/dirs / Несколько файлов/каталогов
tar -cvf backup.tar --exclude='*.log' folder/  # Exclude pattern / Исключить шаблон
tar -cvf backup.tar --exclude-from=excludes.txt folder/  # Exclude from file / Исключить из файла
tar -cvf archive.tar -C /path folder/          # Change directory first / Сменить каталог перед архивацией

### Extract Archives / Распаковка архивов
tar -xvf archive.tar                           # Extract archive / Распаковать архив
tar -xvf archive.tar -C /dest                  # Extract to directory / Распаковать в каталог
tar -xvf archive.tar file.txt                  # Extract specific file / Извлечь конкретный файл
tar -xvf archive.tar --wildcards '*.conf'      # Extract by pattern / Извлечь по шаблону
tar -xvf archive.tar --strip-components= 1      # Remove top-level dir / Убрать верхний уровень

### List Contents / Просмотр содержимого
tar -tvf archive.tar                           # List all files / Список всех файлов
tar -tvf archive.tar | grep ".conf"            # Filter listing / Фильтрованный список
tar -tvf archive.tar --verbose                 # Detailed listing / Подробный список

---

# 🗜️ Compression Formats / Форматы сжатия

### TAR.GZ (Gzip)
tar -czvf archive.tar.gz folder/               # Create .tar.gz / Создать .tar.gz
tar -xzvf archive.tar.gz                       # Extract .tar.gz / Распаковать .tar.gz
tar -tzvf archive.tar.gz                       # List .tar.gz / Просмотр .tar.gz
tar -czvf backup-$(date +%Y%m%d).tar.gz /data  # Timestamped backup / Бэкап с датой

### TAR.BZ2 (Bzip2 - Better Compression)
tar -cjvf archive.tar.bz2 folder/              # Create .tar.bz2 / Создать .tar.bz2
tar -xjvf archive.tar.bz2                      # Extract .tar.bz2 / Распаковать .tar.bz2
tar -tjvf archive.tar.bz2                      # List .tar.bz2 / Просмотр .tar.bz2

### TAR.XZ (XZ - Best Compression)
tar -cJvf archive.tar.xz folder/               # Create .tar.xz / Создать .tar.xz
tar -xJvf archive.tar.xz                       # Extract .tar.xz / Распаковать .tar.xz
tar -tJvf archive.tar.xz                       # List .tar.xz / Просмотр .tar.xz

### TAR.ZST (Zstandard - Fast & Modern)
tar -c --zstd -vf archive.tar.zst folder/      # Create .tar.zst / Создать .tar.zst
tar -x --zstd -vf archive.tar.zst              # Extract .tar.zst / Распаковать .tar.zst
tar -t --zstd -vf archive.tar.zst              # List .tar.zst / Просмотр .tar.zst

### Auto-Detect Compression / Автоопределение сжатия
tar -xavf archive.tar.gz                       # Auto-detect format / Автоопределение формата
tar -cavf archive.tar.gz folder/               # Auto-detect by extension / По расширению

---

# ⚙️ Advanced Options / Продвинутые опции

### Preserve Permissions / Сохранение прав
tar -cpvf archive.tar folder/                  # Preserve permissions / Сохранить права
tar -cpzvf backup.tar.gz --numeric-owner /     # Preserve numeric UID/GID / Сохранить числовые UID/GID
tar -pxvf archive.tar                          # Extract with permissions / Распаковать с правами

### Exclude Patterns / Исключение шаблонов
tar -czvf backup.tar.gz --exclude='*.log' --exclude='*.tmp' folder/  # Multiple excludes / Несколько исключений
tar -czvf backup.tar.gz --exclude-from=excludes.txt folder/  # Exclude list from file / Список исключений из файла
tar -czvf backup.tar.gz --exclude-vcs folder/  # Exclude VCS (.git, .svn) / Исключить .git, .svn

### Split Archives / Разделение архивов
tar -czvf - bigfolder/ | split -b 100M - archive.tar.gz.  # Split into 100MB parts / Разделить на части по 100MB
cat archive.tar.gz.* | tar -xzvf -             # Extract split archive / Распаковать разделённый архив

### Incremental Backups / Инкрементальные бэкапы
tar -czg snapshot.snar -vf full-backup.tar.gz /data  # Full backup with snapshot / Полный бэкап со снимком
tar -czg snapshot.snar -vf incr-backup.tar.gz /data  # Incremental backup / Инкрементальный бэкап

### Sparse Files / Разреженные файлы
tar -cSzvf archive.tar.gz folder/              # Sparse file support / Поддержка разреженных файлов

---

# 📂 Extraction & Listing / Распаковка и просмотр

### Smart Extraction / Умная распаковка
tar -xvf archive.tar --keep-old-files          # Don't overwrite existing / Не перезаписывать существующие
tar -xvf archive.tar --keep-newer-files        # Keep newer files / Сохранить новые файлы
tar -xvf archive.tar --overwrite               # Force overwrite / Принудительная перезапись
tar -xvf archive.tar --no-same-owner           # Don't restore ownership / Не восстанавливать владельца

### Selective Extraction / Выборочная распаковка
tar -xvf archive.tar "*/config.yml"            # Extract by pattern / Извлечь по шаблону
tar -xvf archive.tar --wildcards '*.conf'      # Wildcard extraction / Извлечение по маске
tar -xvf backup.tar.gz etc/nginx/              # Extract specific directory / Извлечь конкретный каталог

### Validation / Проверка
tar -tvf archive.tar | wc -l                   # Count files / Подсчитать файлы
tar -tzf archive.tar.gz | head -20             # First 20 files / Первые 20 файлов
tar -tzf archive.tar.gz | grep "nginx"         # Search in archive / Поиск в архиве

---

# 💾 Backup & Restore / Резервное копирование и восстановление

### System Backup / Бэкап системы
tar -czpvf backup-$(date +%Y%m%d).tar.gz \
  --exclude=/dev \
  --exclude=/proc \
  --exclude=/sys \
  --exclude=/tmp \
  --exclude=/run \
  --exclude=/mnt \
  --exclude=/media \
  --exclude=/lost+found \
  --one-file-system /                          # Full system backup / Полный бэкап системы

### Application Backup / Бэкап приложения
tar -czf app-$(date +%Y%m%d-%H%M).tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='*.log' \
  /var/www/app                                 # Application directory / Каталог приложения

### Database-Friendly Backup / Бэкап с БД
mysqldump <DB_NAME> | gzip > db.sql.gz
tar -czf backup.tar.gz /var/www/app db.sql.gz  # Combine app + DB / Приложение + БД

---

# 🌐 Network Transfer / Передача по сети

### Direct Transfer via SSH / Прямая передача через SSH
tar -czf - folder/ | ssh <USER>@<HOST> "tar -xzf - -C /dest"  # Pipe to remote / С конвейером на удалённый сервер
ssh <USER>@<HOST> "tar -czf - /remote/folder" | tar -xzf -  # Pull from remote / Забрать с удалённого сервера

### With Progress / С прогрессом
tar -czf - folder/ | pv | ssh <USER>@<HOST> "cat > backup.tar.gz"  # Show progress / Показать прогресс

### Rsync Alternative / Альтернатива rsync
tar -czf - --exclude='.git' folder/ | ssh <USER>@<HOST> "tar -xzf - -C /dest"  # Fast directory sync / Быстрая синхронизация

---

# 🔍 Troubleshooting / Устранение неполадок

### Verify Archive Integrity / Проверка целостности
gzip -t archive.tar.gz                         # Test gzip integrity / Проверить целостность gzip
tar -tzf archive.tar.gz > /dev/null            # Test tar integrity / Проверить целостность tar
tar -xzf archive.tar.gz --to-stdout > /dev/null  # Full extraction test / Полная проверка распаковки

### Handle Errors / Обработка ошибок
tar -xvf archive.tar --ignore-failed-read      # Continue on read errors / Продолжить при ошибках чтения
tar -cvf archive.tar --warning=no-file-changed folder/  # Ignore file changes during archive / Игнорировать изменения файлов

### Verbose & Debug / Подробный вывод и отладка
tar -cvvf archive.tar folder/                  # Extra verbose / Дополнительная детализация
tar -xvf archive.tar --checkpoint=100          # Show progress every 100 records / Прогресс каждые 100 записей
tar -czf archive.tar.gz --totals folder/       # Show statistics / Показать статистику

# 🌟 Real-World Examples / Примеры из практики
tar -czf /backup/web-$(date +%Y%m%d).tar.gz --exclude='*.log' /var/www  # Daily web backup / Ежедневный бэкап веб-сервера
tar -czf - /etc | ssh <USER>@<BACKUP_HOST> "cat > /backups/etc-$(date +%Y%m%d).tar.gz"  # Remote etc backup / Удалённый бэкап /etc
find /var/log -name "*.log" -mtime +30 -print0 | tar -czf old-logs.tar.gz --null -T -  # Archive old logs / Архивировать старые логи
tar -czpf home-backup.tar.gz --exclude-caches-all ~/<USER>  # Home directory backup / Бэкап домашнего каталога
tar -czf - bigfolder/ | gpg -c > encrypted-backup.tar.gz.gpg  # Encrypted backup / Шифрованный бэкап
tar -czf code-$(date +%Y%m%d).tar.gz --exclude-vcs --exclude='node_modules' ~/projects  # Code backup / Бэкап кода

# 💡 Performance Tips / Советы по производительности
tar -czf - folder/ | pigz > archive.tar.gz     # Use pigz for parallel compression / pigz для параллельного сжатия
tar -I zstd -cf archive.tar.zst folder/        # Zstandard for fast compression / Zstandard для быстрого сжатия
tar -czf archive.tar.gz --use-compress-program=pigz folder/  # Specify compressor / Указать компрессор
