Title: 📦 ZIP / 7z / ZSTD — Archive Tools
Group: Files & Archives
Icon: 📦
Order: 3

## Table of Contents
- [ZIP — Classic Archives](#-zip--classic-archives)
- [UNZIP — Extract ZIP](#-unzip--extract-zip)
- [7-Zip — High Compression](#-7-zip--high-compression)
- [ZSTD — Modern Compression](#-zstd--modern-compression)
- [Comparison & Benchmarks](#-comparison--benchmarks--сравнение-и-бенчмарки)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📁 ZIP — Classic Archives

### Create Archives / Создание архивов
zip archive.zip file.txt                     # Zip single file / Архивировать один файл
zip -r archive.zip dir/                       # Zip recursively / Архивировать рекурсивно
zip -r archive.zip file1 file2 dir/           # Multiple files/dirs / Несколько файлов/каталогов
zip -r -9 archive.zip dir/                    # Maximum compression / Максимальное сжатие
zip -r -0 archive.zip dir/                    # Store only (no compression) / Только хранение

### Update & Add / Обновление и добавление
zip -u archive.zip newfile.txt                # Update archive / Обновить архив
zip -d archive.zip file.txt                   # Delete from archive / Удалить из архива
zip -r archive.zip . -x "*.log"               # Exclude pattern / Исключить шаблон
zip -r archive.zip dir/ -x "*/.git/*"         # Exclude .git / Исключить .git

### Password Protection / Защита паролем
zip -r -e archive.zip dir/                    # Encrypt with password / Зашифровать паролем
zip -r -P <PASSWORD> archive.zip dir/         # Password in command / Пароль в команде

### List & Test / Просмотр и тестирование
unzip -l archive.zip                          # List contents / Список содержимого
unzip -t archive.zip                          # Test integrity / Проверить целостность
unzip -v archive.zip                          # Verbose list / Подробный список

---

# 📂 UNZIP — Extract ZIP

### Basic Extraction / Базовая распаковка
unzip archive.zip                             # Extract to current dir / Распаковать в текущую директорию
unzip archive.zip -d out/                     # Extract to out/ / Распаковать в out/
unzip -q archive.zip                          # Quiet mode / Тихий режим
unzip -o archive.zip                          # Overwrite without prompt / Перезаписать без подтверждения
unzip -n archive.zip                          # Never overwrite / Никогда не перезаписывать

### Selective Extraction / Выборочная распаковка
unzip archive.zip file.txt                    # Extract single file / Распаковать один файл
unzip archive.zip "*.txt"                     # Extract by pattern / Распаковать по шаблону
unzip archive.zip -x "*.log"                  # Exclude pattern / Исключить шаблон
unzip archive.zip dir/                        # Extract directory / Распаковать каталог

### Password-Protected / Защищённые паролем
unzip -P <PASSWORD> archive.zip               # Extract with password / Распаковать с паролем

---

# 🗜️ 7-Zip — High Compression

### Installation / Установка
sudo apt install p7zip-full p7zip-rar         # Debian/Ubuntu
sudo dnf install p7zip p7zip-plugins          # RHEL/Fedora

### Create Archives / Создание архивов
7z a archive.7z file.txt                      # Create 7z archive / Создать 7z архив
7z a archive.7z file1 dir/                    # Add files/dirs / Добавить файлы/каталоги
7z a -t7z -mx=9 archive.7z dir/               # Maximum compression / Максимальное сжатие
7z a -t7z -mx=1 archive.7z dir/               # Fastest compression / Быстрое сжатие
7z a -tzip archive.zip dir/                   # Create ZIP format / Создать формат ZIP
7z a -ttar archive.tar dir/                   # Create TAR format / Создать формат TAR

### Extract Archives / Распаковка архивов
7z x archive.7z                               # Extract with paths / Распаковать с путями
7z e archive.7z                               # Extract to current dir / Распаковать в текущую директорию
7z x archive.7z -o/path/to/out/               # Extract to path / Распаковать в путь
7z x archive.zip                              # Extract ZIP / Распаковать ZIP
7z x archive.rar                              # Extract RAR / Распаковать RAR

### List & Test / Просмотр и тестирование
7z l archive.7z                               # List contents / Список содержимого
7z t archive.7z                               # Test integrity / Проверить целостность
7z l -slt archive.7z                          # Detailed list / Подробный список

### Update & Delete / Обновление и удаление
7z u archive.7z newfile.txt                   # Update archive / Обновить архив
7z d archive.7z file.txt                      # Delete from archive / Удалить из архива

### Password & Encryption / Пароль и шифрование
7z a -p<PASSWORD> archive.7z dir/             # Password protection / Защита паролем
7z a -p<PASSWORD> -mhe=on archive.7z dir/     # Encrypt headers / Зашифровать заголовки
7z x -p<PASSWORD> archive.7z                  # Extract with password / Распаковать с паролем

### Compression Levels / Уровни сжатия
7z a -mx=0 archive.7z dir/                    # Copy (no compression) / Копирование (без сжатия)
7z a -mx=1 archive.7z dir/                    # Fastest / Быстрое
7z a -mx=5 archive.7z dir/                    # Normal (default) / Нормальное (по умолчанию)
7z a -mx=9 archive.7z dir/                    # Ultra / Ультра

---

# ⚡ ZSTD — Modern Compression

### Installation / Установка
sudo apt install zstd                         # Debian/Ubuntu
sudo dnf install zstd                         # RHEL/Fedora

### Compress Files / Сжатие файлов
zstd file.txt                                 # Compress file / Сжать файл
zstd -19 file.txt                             # Max compression (level 19) / Максимальное сжатие
zstd -1 file.txt                              # Fast compression / Быстрое сжатие
zstd -T0 file.txt                             # Use all CPU cores / Использовать все ядра CPU
zstd -o output.zst file.txt                   # Specify output / Указать выход
zstd -v file.txt                              # Verbose / Подробный вывод

### Decompress Files / Распаковка файлов
zstd -d file.zst                              # Decompress / Распаковать
unzstd file.zst                               # Alternative / Альтернатива
zstd -d -c file.zst > output.txt              # Decompress to stdout / Распаковать в stdout

### Multiple Files / Несколько файлов
zstd *.txt                                    # Compress all txt / Сжать все txt
zstd -d *.zst                                 # Decompress all zst / Распаковать все zst
zstd -rm *.txt                                # Compress and remove / Сжать и удалить

### Tar Integration / Интеграция с tar
tar --zstd -cvf archive.tar.zst dir/          # Create tar.zst / Создать tar.zst
tar --zstd -xvf archive.tar.zst               # Extract tar.zst / Распаковать tar.zst
tar --use-compress-program=zstd -cvf archive.tar.zst dir/  # Alternative / Альтернатива
tar -I zstd -xvf archive.tar.zst              # Alternative extraction / Альтернативная распаковка

### Benchmarking / Бенчмарки
zstd -b file.txt                              # Benchmark compression / Бенчмарк сжатия
zstd -b1:19 file.txt                          # Test levels 1-19 / Тест уровней 1-19

---

# 📊 Comparison & Benchmarks / Сравнение и бенчмарки

### Compression Ratio / Степень сжатия
```bash
# Typical ratios (higher = better) / Типичные соотношения
gzip:  ~2.5x   (fast, universal)
bzip2: ~3x     (slow, better ratio)
xz:    ~4x     (very slow, best ratio)
7z:    ~4.5x   (very slow, best ratio)
zstd:  ~3x     (very fast, good ratio)
```

### Speed Comparison / Сравнение скорости
```bash
# Compression speed (MB/s typical) / Скорость сжатия
gzip:  ~100 MB/s   (moderate)
bzip2: ~10 MB/s    (slow)
xz:    ~5 MB/s     (very slow)
7z:    ~5 MB/s     (very slow)
zstd:  ~400 MB/s   (very fast)
```

### Use Cases / Случаи использования
- **gzip**: Universal, default for archives / Универсальное, по умолчанию для архивов
- **bzip2**: Better compression, legacy / Лучшее сжатие, устаревшее
- **xz**: Maximum compression, slow / Максимальное сжатие, медленное
- **7z**: Maximum compression, Windows compatible / Максимальное сжатие, совместимость с Windows
- **zstd**: Modern, fast, best balance / Современное, быстрое, лучший баланс
- **zip**: Universal, Windows compatible / Универсальное, совместимость с Windows

---

# 🌟 Real-World Examples / Примеры из практики

### Backup with ZSTD / Резервная копия с ZSTD
```bash
# Fast backup / Быстрая резервная копия
tar --zstd -cvf backup-$(date +%F).tar.zst /home/user

# Maximum compression backup / Максимальное сжатие резервной копии
tar -I "zstd -19 -T0" -cvf backup-$(date +%F).tar.zst /data

# Extract / Распаковать
tar --zstd -xvf backup-2025-02-04.tar.zst
```

### Split Large Archives / Разделение больших архивов
```bash
# Create split zip (100MB parts) / Создать разделённый zip (части по 100MB)
zip -r -s 100m archive.zip /large/dir

# 7z split (1GB parts) / 7z разделение (части по 1GB)
7z a -v1g archive.7z /large/dir

# Rejoin split zip / Объединить разделённый zip
zip -F archive.zip --out complete.zip
```

### Password-Protected Backups / Защищённые резервные копии
```bash
# 7z encrypted backup / 7z зашифрованная резервная копия
7z a -p<PASSWORD> -mhe=on backup.7z /sensitive/data

# Zip encrypted / Zip зашифрованный
zip -r -e backup.zip /sensitive/data
```

### Cross-Platform Archives / Кроссплатформенные архивы
```bash
# For Windows compatibility / Для совместимости с Windows
zip -r archive.zip dir/

# Best compression for Windows / Лучшее сжатие для Windows
7z a -t7z -mx=9 archive.7z dir/

# Universal with good compression / Универсальное с хорошим сжатием
tar -czf archive.tar.gz dir/
```

### Log Compression / Сжатие логов
```bash
# Compress old logs / Сжать старые логи
find /var/log -name "*.log" -mtime +7 -exec zstd -19 {} \;

# Compress and remove originals / Сжать и удалить оригиналы
find /var/log -name "*.log" -mtime +7 -exec zstd --rm {} \;

# Batch compress / Пакетное сжатие
zstd -19 /var/log/*.log
```

### Docker Image Archives / Архивы образов Docker
```bash
# Save and compress / Сохранить и сжать
docker save myimage:latest | zstd -19 > myimage.tar.zst

# Load / Загрузить
zstd -d -c myimage.tar.zst | docker load
```

### Automated Rotation / Автоматическая ротация
```bash
# Compress and keep 7 days / Сжать и хранить 7 дней
tar --zstd -cvf backup-$(date +%F).tar.zst /data
find . -name "backup-*.tar.zst" -mtime +7 -delete
```

### Verify Archive Integrity / Проверка целостности архива
```bash
# Verify zip / Проверить zip
unzip -t archive.zip

# Verify 7z / Проверить 7z
7z t archive.7z

# Verify tar.zst / Проверить tar.zst
tar --zstd -tvf archive.tar.zst
```

# 💡 Best Practices / Лучшие практики
# Use zstd for modern Linux systems / Используйте zstd для современных Linux систем
# Use zip for Windows compatibility / Используйте zip для совместимости с Windows
# Use 7z for maximum compression / Используйте 7z для максимального сжатия
# Always test archives after creation / Всегда тестируйте архивы после создания
# Use -T0 with zstd for parallel compression / Используйте -T0 с zstd для параллельного сжатия
# Encrypt sensitive archives / Шифруйте чувствительные архивы

# 🔧 Compression Levels / Уровни сжатия
# zstd: 1-19 (default 3) / zstd: 1-19 (по умолчанию 3)
# 7z: 0-9 (default 5) / 7z: 0-9 (по умолчанию 5)
# zip: 0-9 (default 6) / zip: 0-9 (по умолчанию 6)
# gzip: 1-9 (default 6) / gzip: 1-9 (по умолчанию 6)

# 📋 Default Extensions / Расширения по умолчанию
# .zip — ZIP archives / ZIP архивы
# .7z — 7-Zip archives / 7-Zip архивы
# .zst — ZSTD compressed / Сжатые ZSTD
# .tar.zst — TAR with ZSTD / TAR с ZSTD
# .tar.gz — TAR with gzip / TAR с gzip
# .tar.xz — TAR with xz / TAR с xz
