Title: 📦 TAR + Zstandard (zstd) — Compression
Group: Files & Archives
Icon: 📦
Order: 1

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Compression Levels](#-compression-levels--уровни-сжатия)
- [Advanced Usage](#-advanced-usage--расширенное-использование)
- [Best Practices](#-best-practices--лучшие-практики)

---

# 📘 Basic Commands / Базовые команды

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

> [!NOTE]
> The `--zstd` flag requires GNU tar 1.31+ (2019). For older versions, use `-I zstd`.
> Флаг `--zstd` требует GNU tar 1.31+ (2019). Для старых версий используйте `-I zstd`.

### List Contents / Просмотр содержимого
```bash
tar -I zstd -tvf <ARCHIVE>.tar.zst | less    # List contents / Показать содержимое
tar --zstd -tvf <ARCHIVE>.tar.zst            # Alternative / Альтернатива
```

---

# 🔢 Compression Levels / Уровни сжатия

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

| Level | Speed | Ratio | Use Case (EN / RU) |
|-------|-------|-------|---------------------|
| 1 | Fastest / Быстрейший | Low / Низкое | Real-time / streaming / Потоковая передача |
| 3 | Fast / Быстрый | Good / Хорошее | Default, daily backups / По умолчанию, ежедневные бэкапы |
| 9 | Moderate / Средний | Better / Лучшее | Balanced storage / Сбалансированное хранение |
| 19 | Slow / Медленный | Best / Лучшее | Archival storage / Архивное хранение |

---

# 🚀 Advanced Usage / Расширенное использование

### Multi-threaded Compression / Многопоточное сжатие
```bash
tar -cv <DIR>/ | zstd -T0 -19 -o <ARCHIVE>.tar.zst  # Use all cores / Использовать все ядра
tar -cv <DIR>/ | zstd -T4 -o <ARCHIVE>.tar.zst      # Use 4 threads / Использовать 4 потока
```

> [!TIP]
> `-T0` automatically uses all available CPU cores, dramatically speeding up compression of large datasets.
> `-T0` автоматически использует все доступные ядра CPU, значительно ускоряя сжатие больших данных.

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

---

# 💡 Best Practices / Лучшие практики

- Use `--zstd` for GNU tar 1.31+ / Используйте `--zstd` для GNU tar 1.31+
- Use `-T0` for multi-core compression / Используйте `-T0` для многоядерного сжатия
- Level 3 is a good balance for daily use / Уровень 3 — хороший баланс для повседневного использования
- Level 19 for long-term archival storage / Уровень 19 для долгосрочного архивного хранения
- Zstd is faster than gzip/bzip2 at comparable ratios / Zstd быстрее чем gzip/bzip2 при сопоставимых коэффициентах сжатия

## Quick Comparison / Быстрое сравнение

| Format | Speed | Ratio | Description (EN / RU) |
|--------|-------|-------|----------------------|
| `.tar.gz` | Moderate / Средняя | ~2.5x | gzip (slower, widely compatible) / gzip (медленнее, широко совместим) |
| `.tar.bz2` | Slow / Медленная | ~3x | bzip2 (slow, good compression) / bzip2 (медленный, хорошее сжатие) |
| `.tar.xz` | Very slow / Очень медленная | ~4x | xz (very slow, best compression) / xz (очень медленный, лучшее сжатие) |
| `.tar.zst` | **Very fast** / **Очень быстрая** | ~3x | zstd (FAST, great compression) / zstd (БЫСТРЫЙ, отличное сжатие) |
