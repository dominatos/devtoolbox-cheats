Title: 📦 TAR with Zstandard Compression
Group: Files & Archives
Icon: 📦
Order: 1

## Table of Contents
- [Basic Commands](#-basic-commands--базовые-команды)
- [Compression Levels](#-compression-levels--уровни-сжатия)
- [Advanced Usage](#-advanced-usage--расширенное-использование)

---

# 📘 Basic Commands / Базовые команды

### Method 1: Explicit Compressor / Явный компрессор
tar -I zstd -cvf <ARCHIVE>.tar.zst <DIR>/     # Pack dir → .tar.zst / Упаковать dir → .tar.zst
tar -I unzstd -xvf <ARCHIVE>.tar.zst          # Extract .tar.zst / Распаковать .tar.zst

### Method 2: GNU tar Flags / Флаги GNU tar
tar --zstd -cvf <ARCHIVE>.tar.zst <DIR>/      # Pack with --zstd / Упаковать с --zstd
tar --zstd -xvf <ARCHIVE>.tar.zst             # Extract / Распаковать

### List Contents / Просмотр содержимого
tar -I zstd -tvf <ARCHIVE>.tar.zst | less    # List contents / Показать содержимое
tar --zstd -tvf <ARCHIVE>.tar.zst            # Alternative / Альтернатива

---

# 🔢 Compression Levels / Уровни сжатия

### Available Levels / Доступные уровни
# Zstandard levels: 0-19 / Уровни Zstandard: 0-19
# Higher = better compression, slower / Выше = лучшее сжатие, медленнее
# Lower = faster, larger files / Ниже = быстрее, больше файлы

### Fast Compression / Быстрое сжатие
tar -I 'zstd -1' -cvf <ARCHIVE>.tar.zst <DIR>/  # Fast compression / Быстрое сжатие
tar -I 'zstd -3' -cvf <ARCHIVE>.tar.zst <DIR>/  # Balanced / Сбалансированное

### Maximum Compression / Максимальное сжатие
tar -I 'zstd -19' -cvf <ARCHIVE>.tar.zst <DIR>/  # Max compression / Максимальное сжатие

### Default Level / Уровень по умолчанию
tar -I zstd -cvf <ARCHIVE>.tar.zst <DIR>/     # Default (level 3) / По умолчанию (уровень 3)

---

# 🚀 Advanced Usage / Расширенное использование

### Multi-threaded Compression / Многопоточное сжатие
tar -cv <DIR>/ | zstd -T0 -19 -o <ARCHIVE>.tar.zst  # Use all cores / Использовать все ядра
tar -cv <DIR>/ | zstd -T4 -o <ARCHIVE>.tar.zst      # Use 4 threads / Использовать 4 потока

### Streaming Operations / Поточные операции
# Create archive from stream / Создать архив из потока
tar -cv <DIR>/ | zstd -T0 -19 -o <ARCHIVE>.tar.zst

# Extract from stream / Распаковать из потока
zstdcat <ARCHIVE>.tar.zst | tar -xv
zstd -dc <ARCHIVE>.tar.zst | tar -xv  # Alternative / Альтернатива

### Pipe to Remote Server / Передать на удалённый сервер
tar -cv <DIR>/ | zstd | ssh <user>@<HOST> 'cat > archive.tar.zst'  # Send to remote / Отправить на удалённый
ssh <user>@<HOST> 'zstdcat archive.tar.zst' | tar -xv  # Extract from remote / Распаковать с удалённого

### Exclude Patterns / Исключить паттерны
tar -cv --exclude='*.log' --exclude='node_modules' <DIR>/ | zstd -o <ARCHIVE>.tar.zst  # Exclude patterns / Исключить паттерны

### Compression with Progress / Сжатие с прогрессом
tar -cv <DIR>/ | pv | zstd -T0 -o <ARCHIVE>.tar.zst  # Show progress (requires pv) / Показать прогресс (требуется pv)

---

# 💡 Best Practices / Лучшие практики
# Use --zstd for GNU tar 1.31+ / Используйте --zstd для GNU tar 1.31+
# Use -T0 for multi-core compression / Используйте -T0 для многоядерного сжатия
# Level 3 is good balance / Уровень 3 - хороший баланс
# Level 19 for archival / Уровень 19 для архивирования
# Zstd is faster than gzip/bzip2 / Zstd быстрее чем gzip/bzip2

# 📋 Quick Comparison / Быстрое сравнение
# .tar.gz   — gzip (slower, widely compatible) / gzip (медленнее, широко совместим)
# .tar.bz2  — bzip2 (slow, good compression) / bzip2 (медленный, хорошее сжатие)
# .tar.xz   — xz (very slow, best compression) / xz (очень медленный, лучшее сжатие)
# .tar.zst  — zstd (FAST, great compression) / zstd (БЫСТРЫЙ, отличное сжатие)
