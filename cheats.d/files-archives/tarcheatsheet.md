Title: 📦 TAR — Archive Commands
Group: Files & Archives
Icon: 📦
Order: 2

## Description

**tar** (Tape ARchive) is the standard UNIX/Linux utility for creating, extracting, and managing archive files. Originally designed for tape backup, it is now the universal tool for bundling files and directories into a single archive, with optional compression via gzip, bzip2, xz, or zstd.

**Что это:** `tar` — стандартная UNIX/Linux утилита для создания, распаковки и управления архивами. Универсальный инструмент для объединения файлов и каталогов в один архив с опциональным сжатием.

**Common use cases / Типичные случаи использования:**
- System and application backups / Резервное копирование систем и приложений
- Software distribution (source tarballs) / Распространение ПО (тарболлы)
- File transfer between servers / Передача файлов между серверами
- Log rotation and archival / Ротация и архивирование логов

**Status / Статус:** ✅ Actively maintained (GNU project). The most fundamental archive tool in Linux — not replaceable. For compression, consider **zstd** (faster) instead of legacy gzip/bzip2.

---

## Table of Contents
- [Installation](#installation)
- [Basic Operations](#basic-operations)
- [Compression Formats](#compression-formats)
- [Advanced Options](#advanced-options)
- [Extraction & Listing](#extraction--listing)
- [Backup & Restore](#backup--restore)
- [Network Transfer](#network-transfer)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Documentation Links](#documentation-links)

---

## Installation

> [!NOTE]
> GNU tar is pre-installed on virtually all Linux distributions.
> GNU tar предустановлен практически во всех дистрибутивах Linux.

```bash
tar --version                                  # Show tar version / Версия tar
sudo apt install tar                           # Debian/Ubuntu
sudo dnf install tar                           # RHEL/Fedora
sudo pacman -S tar                             # Arch Linux

# Parallel compression tools / Инструменты параллельного сжатия
sudo apt install pigz pbzip2 pixz zstd pv      # Parallel compressors + progress / Параллельные компрессоры + прогресс
```

---

## Basic Operations

### Key Flags / Основные флаги

| Flag | Meaning (EN / RU) |
|------|--------------------|
| `-c` | Create archive / Создать архив |
| `-x` | Extract archive / Распаковать архив |
| `-t` | List contents / Показать содержимое |
| `-v` | Verbose output / Подробный вывод |
| `-f` | Specify filename (must be last flag) / Указать имя файла |
| `-p` | Preserve permissions / Сохранить права |
| `-z` | Use gzip / Сжатие gzip |
| `-j` | Use bzip2 / Сжатие bzip2 |
| `-J` | Use xz / Сжатие xz |
| `-a` | Auto-detect compression / Автоопределение |

### Create Archives / Создание архивов
```bash
tar -cvf archive.tar folder/                   # Create tar archive / Создать tar архив
tar -cvf archive.tar file1 file2 dir/          # Multiple files/dirs / Несколько файлов/каталогов
tar -cvf backup.tar --exclude='*.log' folder/  # Exclude pattern / Исключить шаблон
tar -cvf backup.tar --exclude-from=excludes.txt folder/  # Exclude from file / Исключить из файла
tar -cvf archive.tar -C /path folder/          # Change directory first / Сменить каталог перед архивацией
```

### Extract Archives / Распаковка архивов
```bash
tar -xvf archive.tar                           # Extract archive / Распаковать архив
tar -xvf archive.tar -C /dest                  # Extract to directory / Распаковать в каталог
tar -xvf archive.tar file.txt                  # Extract specific file / Извлечь конкретный файл
tar -xvf archive.tar --wildcards '*.conf'      # Extract by pattern / Извлечь по шаблону
tar -xvf archive.tar --strip-components=1      # Remove top-level dir / Убрать верхний уровень
```

### List Contents / Просмотр содержимого
```bash
tar -tvf archive.tar                           # List all files / Список всех файлов
tar -tvf archive.tar | grep ".conf"            # Filter listing / Фильтрованный список
tar -tvf archive.tar --verbose                 # Detailed listing / Подробный список
```

---

## Compression Formats

### TAR.GZ (Gzip)
```bash
tar -czvf archive.tar.gz folder/               # Create .tar.gz / Создать .tar.gz
tar -xzvf archive.tar.gz                       # Extract .tar.gz / Распаковать .tar.gz
tar -tzvf archive.tar.gz                       # List .tar.gz / Просмотр .tar.gz
tar -czvf backup-$(date +%Y%m%d).tar.gz /data  # Timestamped backup / Бэкап с датой
```

### TAR.BZ2 (Bzip2 — Better Compression / Лучшее сжатие)
```bash
tar -cjvf archive.tar.bz2 folder/              # Create .tar.bz2 / Создать .tar.bz2
tar -xjvf archive.tar.bz2                      # Extract .tar.bz2 / Распаковать .tar.bz2
tar -tjvf archive.tar.bz2                      # List .tar.bz2 / Просмотр .tar.bz2
```

### TAR.XZ (XZ — Best Compression / Лучшее сжатие)
```bash
tar -cJvf archive.tar.xz folder/               # Create .tar.xz / Создать .tar.xz
tar -xJvf archive.tar.xz                       # Extract .tar.xz / Распаковать .tar.xz
tar -tJvf archive.tar.xz                       # List .tar.xz / Просмотр .tar.xz
```

### TAR.ZST (Zstandard — Fast & Modern / Быстрое и современное)
```bash
tar -c --zstd -vf archive.tar.zst folder/      # Create .tar.zst / Создать .tar.zst
tar -x --zstd -vf archive.tar.zst              # Extract .tar.zst / Распаковать .tar.zst
tar -t --zstd -vf archive.tar.zst              # List .tar.zst / Просмотр .tar.zst
```

> [!NOTE]
> The `--zstd` flag requires GNU tar 1.31+ (2019). For older systems, use `tar -I zstd`.
> Флаг `--zstd` требует GNU tar 1.31+. Для старых систем используйте `tar -I zstd`.

### Auto-Detect Compression / Автоопределение сжатия
```bash
tar -xavf archive.tar.gz                       # Auto-detect format / Автоопределение формата
tar -cavf archive.tar.gz folder/               # Auto-detect by extension / По расширению
```

---

## Advanced Options

### Preserve Permissions / Сохранение прав
```bash
tar -cpvf archive.tar folder/                  # Preserve permissions / Сохранить права
tar -cpzvf backup.tar.gz --numeric-owner /     # Preserve numeric UID/GID / Сохранить числовые UID/GID
tar -pxvf archive.tar                          # Extract with permissions / Распаковать с правами
```

### Exclude Patterns / Исключение шаблонов
```bash
tar -czvf backup.tar.gz --exclude='*.log' --exclude='*.tmp' folder/  # Multiple excludes / Несколько исключений
tar -czvf backup.tar.gz --exclude-from=excludes.txt folder/  # Exclude list from file / Список исключений из файла
tar -czvf backup.tar.gz --exclude-vcs folder/  # Exclude VCS (.git, .svn) / Исключить .git, .svn
```

### Split Archives / Разделение архивов
```bash
tar -czvf - bigfolder/ | split -b 100M - archive.tar.gz.  # Split into 100MB parts / Разделить на части по 100MB
cat archive.tar.gz.* | tar -xzvf -             # Extract split archive / Распаковать разделённый архив
```

### Incremental Backups / Инкрементальные бэкапы
```bash
tar -czg snapshot.snar -vf full-backup.tar.gz /data  # Full backup with snapshot / Полный бэкап со снимком
tar -czg snapshot.snar -vf incr-backup.tar.gz /data  # Incremental backup / Инкрементальный бэкап
```

> [!IMPORTANT]
> Keep the `.snar` snapshot file safe — it's required for incremental restores.
> Сохраняйте файл снимка `.snar` — он нужен для инкрементального восстановления.

### Sparse Files / Разреженные файлы
```bash
tar -cSzvf archive.tar.gz folder/              # Sparse file support / Поддержка разреженных файлов
```

---

## Extraction & Listing

### Smart Extraction / Умная распаковка
```bash
tar -xvf archive.tar --keep-old-files          # Don't overwrite existing / Не перезаписывать существующие
tar -xvf archive.tar --keep-newer-files        # Keep newer files / Сохранить новые файлы
tar -xvf archive.tar --overwrite               # Force overwrite / Принудительная перезапись
tar -xvf archive.tar --no-same-owner           # Don't restore ownership / Не восстанавливать владельца
```

### Selective Extraction / Выборочная распаковка
```bash
tar -xvf archive.tar "*/config.yml"            # Extract by pattern / Извлечь по шаблону
tar -xvf archive.tar --wildcards '*.conf'      # Wildcard extraction / Извлечение по маске
tar -xvf backup.tar.gz etc/nginx/              # Extract specific directory / Извлечь конкретный каталог
```

### Validation / Проверка
```bash
tar -tvf archive.tar | wc -l                   # Count files / Подсчитать файлы
tar -tzf archive.tar.gz | head -20             # First 20 files / Первые 20 файлов
tar -tzf archive.tar.gz | grep "nginx"         # Search in archive / Поиск в архиве
```

---

## Backup & Restore

### System Backup / Бэкап системы
```bash
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
```

> [!WARNING]
> Full system backup can take significant time and disk space. Ensure sufficient storage at the destination.
> Полный бэкап системы может занять значительное время и место на диске.

### Application Backup / Бэкап приложения
```bash
tar -czf app-$(date +%Y%m%d-%H%M).tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='*.log' \
  /var/www/app                                 # Application directory / Каталог приложения
```

### Database-Friendly Backup / Бэкап с БД
```bash
mysqldump <DB_NAME> | gzip > db.sql.gz
tar -czf backup.tar.gz /var/www/app db.sql.gz  # Combine app + DB / Приложение + БД
```

---

## Network Transfer

### Direct Transfer via SSH / Прямая передача через SSH
```bash
tar -czf - folder/ | ssh <USER>@<HOST> "tar -xzf - -C /dest"  # Pipe to remote / На удалённый сервер
ssh <USER>@<HOST> "tar -czf - /remote/folder" | tar -xzf -  # Pull from remote / Забрать с удалённого
```

### With Progress / С прогрессом
```bash
tar -czf - folder/ | pv | ssh <USER>@<HOST> "cat > backup.tar.gz"  # Show progress / Показать прогресс
```

### Rsync Alternative / Альтернатива rsync
```bash
tar -czf - --exclude='.git' folder/ | ssh <USER>@<HOST> "tar -xzf - -C /dest"  # Fast directory sync / Быстрая синхронизация
```

> [!TIP]
> For regular file synchronization, `rsync` is more efficient as it only transfers changed bytes.
> Для регулярной синхронизации `rsync` эффективнее, так как передаёт только изменённые байты.

---

## Troubleshooting

### Verify Archive Integrity / Проверка целостности
```bash
gzip -t archive.tar.gz                         # Test gzip integrity / Проверить целостность gzip
tar -tzf archive.tar.gz > /dev/null            # Test tar integrity / Проверить целостность tar
tar -xzf archive.tar.gz --to-stdout > /dev/null  # Full extraction test / Полная проверка распаковки
```

### Handle Errors / Обработка ошибок
```bash
tar -xvf archive.tar --ignore-failed-read      # Continue on read errors / Продолжить при ошибках чтения
tar -cvf archive.tar --warning=no-file-changed folder/  # Ignore file changes during archive / Игнорировать изменения файлов
```

### Verbose & Debug / Подробный вывод и отладка
```bash
tar -cvvf archive.tar folder/                  # Extra verbose / Дополнительная детализация
tar -xvf archive.tar --checkpoint=100          # Show progress every 100 records / Прогресс каждые 100 записей
tar -czf archive.tar.gz --totals folder/       # Show statistics / Показать статистику
```

### Common Errors / Типичные ошибки

| Error | Cause (EN / RU) | Solution / Решение |
|-------|------------------|--------------------|
| `No such file or directory` | Wrong path / Неверный путь | Verify with `ls` / Проверьте через `ls` |
| `Removing leading '/'` | Absolute paths stripped / Удалены абсолютные пути | Normal behavior / Нормальное поведение |
| `Permission denied` | Insufficient permissions / Недостаточно прав | Use `sudo` / Используйте `sudo` |
| `Unexpected EOF` | Corrupted archive / Повреждённый архив | Re-create archive / Пересоздайте архив |

### Real-World Examples / Примеры из практики
```bash
tar -czf /backup/web-$(date +%Y%m%d).tar.gz --exclude='*.log' /var/www  # Daily web backup / Ежедневный бэкап
tar -czf - /etc | ssh <USER>@<HOST> "cat > /backups/etc-$(date +%Y%m%d).tar.gz"  # Remote etc backup / Удалённый бэкап /etc
find /var/log -name "*.log" -mtime +30 -print0 | tar -czf old-logs.tar.gz --null -T -  # Archive old logs / Архив старых логов
tar -czf - bigfolder/ | gpg -c > encrypted-backup.tar.gz.gpg  # Encrypted backup / Шифрованный бэкап
tar -czf code-$(date +%Y%m%d).tar.gz --exclude-vcs --exclude='node_modules' ~/projects  # Code backup / Бэкап кода
```

### Performance Tips / Советы по производительности
```bash
tar -czf - folder/ | pigz > archive.tar.gz     # Use pigz for parallel compression / pigz для параллельного сжатия
tar -I zstd -cf archive.tar.zst folder/        # Zstandard for fast compression / Zstandard для быстрого сжатия
tar -czf archive.tar.gz --use-compress-program=pigz folder/  # Specify compressor / Указать компрессор
```

---

## Best Practices

### Compression Format Comparison / Сравнение форматов сжатия

| Format | Flag | Speed | Ratio | Best For (EN / RU) |
|--------|------|-------|-------|---------------------|
| `.tar.gz` | `-z` | Moderate / Средняя | ~2.5x | Universal default / Универсальный формат |
| `.tar.bz2` | `-j` | Slow / Медленная | ~3x | Better ratio, legacy / Лучшее сжатие, устаревший |
| `.tar.xz` | `-J` | Very slow / Очень медленная | ~4x | Max compression / Максимальное сжатие |
| `.tar.zst` | `--zstd` | Very fast / Очень быстрая | ~3x | Modern, fast, great balance / Современный, быстрый |

> [!TIP]
> Use `tar -a` (auto-detect) to let tar choose the compressor based on the file extension.
> Используйте `tar -a` для автоопределения компрессора по расширению файла.

---

## Documentation Links

- **GNU tar Manual:** https://www.gnu.org/software/tar/manual/
- **tar man page:** `man tar` or https://man7.org/linux/man-pages/man1/tar.1.html
- **GNU tar source:** https://savannah.gnu.org/projects/tar
- **gzip documentation:** https://www.gnu.org/software/gzip/manual/
- **bzip2 documentation:** https://sourceware.org/bzip2/
- **xz documentation:** https://tukaani.org/xz/
- **Zstandard documentation:** https://facebook.github.io/zstd/
- **pigz (parallel gzip):** https://zlib.net/pigz/
