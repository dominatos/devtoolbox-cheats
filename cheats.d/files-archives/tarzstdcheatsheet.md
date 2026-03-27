Title: 📦 TAR + Zstandard (zstd) — Compression
Group: Files & Archives
Icon: 📦
Order: 1

## Description

**Zstandard (zstd)** is a modern, high-performance compression algorithm developed by Facebook (Meta). When combined with **tar**, it provides an excellent balance of compression speed and ratio, significantly outperforming traditional tools like gzip and bzip2. Zstd supports adjustable compression levels (1–19), multi-threaded compression, and streaming operations.

**Что это:** **Zstandard (zstd)** — современный высокопроизводительный алгоритм сжатия, разработанный Facebook (Meta). В сочетании с **tar** обеспечивает отличный баланс скорости и степени сжатия, значительно превосходя традиционные инструменты вроде gzip и bzip2. Поддерживает настраиваемые уровни сжатия (1–19), многопоточность и потоковые операции.

**Common use cases / Типичные случаи использования:**
- High-speed backups of large datasets / Высокоскоростное резервное копирование больших данных
- Container and VM image compression / Сжатие образов контейнеров и ВМ
- Log archival with minimal CPU overhead / Архивирование логов с минимальной нагрузкой на CPU
- CI/CD artifact compression / Сжатие артефактов CI/CD
- Real-time streaming compression / Потоковое сжатие в реальном времени

**Status / Статус:** ✅ Actively maintained, rapidly gaining adoption. Becoming the **de facto modern replacement** for gzip in many Linux distributions (e.g., Fedora uses zstd for RPM packages, Arch Linux uses it for package compression). Supported in GNU tar 1.31+ (2019), Linux kernel (since 4.14), and most modern tools.

**See also:** [TAR cheatsheet](tarcheatsheet.md) for general tar usage, [ZIP/7z/ZSTD cheatsheet](zip7zzstdcheatsheet.md) for standalone zstd usage.

---

## Table of Contents
- [Installation](#installation)
- [Basic Commands](#basic-commands)
- [Compression Levels](#compression-levels)
- [Advanced Usage](#advanced-usage)
- [Backup Operations](#backup-operations)
- [Best Practices](#best-practices)
- [Documentation Links](#documentation-links)

---

## Installation

### Install zstd / Установка zstd
```bash
# Debian/Ubuntu
sudo apt install zstd                          # Install zstd / Установить zstd

# RHEL/Fedora
sudo dnf install zstd                          # Install zstd / Установить zstd

# Arch Linux
sudo pacman -S zstd                            # Install zstd / Установить zstd

# Verify installation / Проверить установку
zstd --version                                 # Show zstd version / Версия zstd
tar --version                                  # Ensure GNU tar 1.31+ / Убедиться в GNU tar 1.31+
```

> [!NOTE]
> The `--zstd` flag requires GNU tar 1.31+ (2019). For older versions, use `-I zstd` instead.
> Флаг `--zstd` требует GNU tar 1.31+ (2019). Для старых версий используйте `-I zstd`.

---

## Basic Commands

### Method 1: Explicit Compressor / Явный компрессор
```bash
tar -I zstd -cvf <ARCHIVE>.tar.zst <DIR>/     # Pack dir → .tar.zst / Упаковать dir → .tar.zst
tar -I unzstd -xvf <ARCHIVE>.tar.zst          # Extract .tar.zst / Распаковать .tar.zst
```

### Method 2: GNU tar Flags / Флаги GNU tar
```bash
tar --zstd -cvf <ARCHIVE>.tar.zst <DIR>/      # Pack with --zstd / Упаковать с --zstd
tar --zstd -xvf <ARCHIVE>.tar.zst             # Extract / Распаковать
```

### Method Comparison / Сравнение методов

| Method | Compatibility (EN / RU) | Advantage / Преимущество |
|--------|------------------------|--------------------------|
| `-I zstd` | All GNU tar versions / Все версии GNU tar | Works on older systems / Работает на старых системах |
| `--zstd` | GNU tar 1.31+ | Cleaner syntax / Более чистый синтаксис |
| `tar -a` | GNU tar 1.31+ | Auto-detect by extension / Автоопределение по расширению |

### List Contents / Просмотр содержимого
```bash
tar -I zstd -tvf <ARCHIVE>.tar.zst | less    # List contents / Показать содержимое
tar --zstd -tvf <ARCHIVE>.tar.zst            # Alternative / Альтернатива
```

---

## Compression Levels

### Available Levels / Доступные уровни
```bash
# Zstandard levels: 1-19 (default: 3) / Уровни Zstandard: 1-19 (по умолчанию: 3)
# Higher = better compression, slower / Выше = лучшее сжатие, медленнее
# Lower = faster, larger files / Ниже = быстрее, больше файлы
```

### Fast Compression / Быстрое сжатие
```bash
tar -I 'zstd -1' -cvf <ARCHIVE>.tar.zst <DIR>/  # Fast compression / Быстрое сжатие
tar -I 'zstd -3' -cvf <ARCHIVE>.tar.zst <DIR>/  # Balanced (default) / Сбалансированное (по умолчанию)
```

### Maximum Compression / Максимальное сжатие
```bash
tar -I 'zstd -19' -cvf <ARCHIVE>.tar.zst <DIR>/  # Max compression / Максимальное сжатие
```

### Default Level / Уровень по умолчанию
```bash
tar -I zstd -cvf <ARCHIVE>.tar.zst <DIR>/     # Default (level 3) / По умолчанию (уровень 3)
```

### Compression Level Comparison / Сравнение уровней сжатия

The key insight is that zstd at level 1 is already comparable to gzip in ratio but **3-5x faster**. Level 3 (default) matches bzip2 ratio at much higher speed. Only use level 19 for archival storage where speed doesn't matter.

Ключевой момент: zstd на уровне 1 уже сопоставим с gzip по степени сжатия, но **в 3-5 раз быстрее**. Уровень 3 (по умолчанию) соответствует степени сжатия bzip2 при намного большей скорости. Уровень 19 для архивного хранения, где скорость не важна.

| Level | Speed | Ratio | Use Case (EN / RU) |
|-------|-------|-------|---------------------|
| 1 | Fastest / Быстрейший | Low / Низкое | Real-time / streaming / Потоковая передача |
| 3 | Fast / Быстрый | Good / Хорошее | Default, daily backups / По умолчанию, ежедневные бэкапы |
| 9 | Moderate / Средний | Better / Лучшее | Balanced storage / Сбалансированное хранение |
| 19 | Slow / Медленный | Best / Лучшее | Archival storage / Архивное хранение |

---

## Advanced Usage

### Multi-threaded Compression / Многопоточное сжатие
```bash
tar -cv <DIR>/ | zstd -T0 -19 -o <ARCHIVE>.tar.zst  # Use all cores / Использовать все ядра
tar -cv <DIR>/ | zstd -T4 -o <ARCHIVE>.tar.zst      # Use 4 threads / Использовать 4 потока
```

> [!TIP]
> `-T0` automatically uses all available CPU cores, dramatically speeding up compression of large datasets. This is one of zstd's biggest advantages over gzip.
> `-T0` автоматически использует все доступные ядра CPU, значительно ускоряя сжатие больших данных. Это одно из главных преимуществ zstd над gzip.

### Streaming Operations / Поточные операции
```bash
# Create archive from stream / Создать архив из потока
tar -cv <DIR>/ | zstd -T0 -19 -o <ARCHIVE>.tar.zst

# Extract from stream / Распаковать из потока
zstdcat <ARCHIVE>.tar.zst | tar -xv
zstd -dc <ARCHIVE>.tar.zst | tar -xv  # Alternative / Альтернатива
```

### Pipe to Remote Server / Передать на удалённый сервер
```bash
tar -cv <DIR>/ | zstd | ssh <USER>@<HOST> 'cat > archive.tar.zst'  # Send to remote / Отправить на удалённый
ssh <USER>@<HOST> 'zstdcat archive.tar.zst' | tar -xv  # Extract from remote / Распаковать с удалённого
```

### Exclude Patterns / Исключить паттерны
```bash
tar -cv --exclude='*.log' --exclude='node_modules' <DIR>/ | zstd -o <ARCHIVE>.tar.zst  # Exclude patterns / Исключить паттерны
```

### Compression with Progress / Сжатие с прогрессом
```bash
tar -cv <DIR>/ | pv | zstd -T0 -o <ARCHIVE>.tar.zst  # Show progress (requires pv) / Показать прогресс (требуется pv)
```

### Dictionary-Based Compression / Сжатие на основе словаря
```bash
# Train a dictionary on sample files / Обучить словарь на образцах файлов
zstd --train samples/* -o dict.zstd

# Compress with dictionary / Сжать со словарём
tar -cv <DIR>/ | zstd -D dict.zstd -o <ARCHIVE>.tar.zst

# Decompress with dictionary / Распаковать со словарём
zstd -D dict.zstd -dc <ARCHIVE>.tar.zst | tar -xv
```

> [!TIP]
> Dictionary compression is highly effective for many small similar files (logs, JSON records). It can improve ratio by 2-5x for small files.
> Сжатие со словарём высокоэффективно для множества маленьких похожих файлов (логи, JSON-записи). Может улучшить степень сжатия в 2-5 раз.

---

## Backup Operations

### Daily Backup with Rotation / Ежедневный бэкап с ротацией
```bash
# Fast backup / Быстрая резервная копия
tar --zstd -cvf backup-$(date +%F).tar.zst /home/<USER>

# Maximum compression backup / Максимальное сжатие резервной копии
tar -I "zstd -19 -T0" -cvf backup-$(date +%F).tar.zst /data

# Extract / Распаковать
tar --zstd -xvf backup-$(date +%F).tar.zst

# Rotate old backups / Ротация старых бэкапов
find /backup/ -name "backup-*.tar.zst" -mtime +7 -delete
```

> [!CAUTION]
> The `find -delete` command permanently removes old backups. Always verify your retention policy before enabling rotation.
> Команда `find -delete` безвозвратно удаляет старые бэкапы. Всегда проверяйте политику хранения перед включением ротации.

### Verify Archive Integrity / Проверка целостности архива
```bash
tar --zstd -tvf <ARCHIVE>.tar.zst > /dev/null  # Test integrity / Проверить целостность
zstd -t <ARCHIVE>.tar.zst                      # Test zstd layer / Проверить слой zstd
```

---

## Best Practices

### General Recommendations / Общие рекомендации

- Use `--zstd` for GNU tar 1.31+ / Используйте `--zstd` для GNU tar 1.31+
- Use `-T0` for multi-core compression / Используйте `-T0` для многоядерного сжатия
- Level 3 is a good balance for daily use / Уровень 3 — хороший баланс для повседневного использования
- Level 19 for long-term archival storage / Уровень 19 для долгосрочного архивного хранения
- Zstd is faster than gzip/bzip2 at comparable ratios / Zstd быстрее чем gzip/bzip2 при сопоставимых коэффициентах
- Always verify archives after creation / Всегда проверяйте архивы после создания

### Quick Comparison / Быстрое сравнение

| Format | Speed | Ratio | Description (EN / RU) |
|--------|-------|-------|----------------------|
| `.tar.gz` | Moderate / Средняя | ~2.5x | gzip (slower, widely compatible) / gzip (медленнее, широко совместим) |
| `.tar.bz2` | Slow / Медленная | ~3x | bzip2 (slow, good compression) / bzip2 (медленный, хорошее сжатие) |
| `.tar.xz` | Very slow / Очень медленная | ~4x | xz (very slow, best compression) / xz (очень медленный, лучшее сжатие) |
| `.tar.zst` | **Very fast** / **Очень быстрая** | ~3x | zstd (FAST, great compression) / zstd (БЫСТРЫЙ, отличное сжатие) |

---

## Documentation Links

- **Zstandard Official Site:** https://facebook.github.io/zstd/
- **Zstandard GitHub:** https://github.com/facebook/zstd
- **Zstandard RFC (RFC 8478):** https://tools.ietf.org/html/rfc8478
- **zstd man page:** `man zstd` or https://man7.org/linux/man-pages/man1/zstd.1.html
- **GNU tar Manual (zstd support):** https://www.gnu.org/software/tar/manual/
- **Zstandard Benchmarks:** https://facebook.github.io/zstd/#benchmarks
- **See also:** [TAR cheatsheet](tarcheatsheet.md), [ZIP/7z/ZSTD cheatsheet](zip7zzstdcheatsheet.md)
