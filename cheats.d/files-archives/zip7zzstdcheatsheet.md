Title: 📦 ZIP / 7z / ZSTD — Archive Tools
Group: Files & Archives
Icon: 📦
Order: 3

## Description

**ZIP**, **7-Zip (7z)**, and **Zstandard (zstd)** are three widely-used compression tools, each with distinct strengths:

- **ZIP** — The universal archive format, natively supported on Windows, macOS, and Linux. Best for cross-platform sharing.
- **7-Zip (7z)** — Open-source archiver offering the highest compression ratios using LZMA/LZMA2 algorithms. Supports many formats including ZIP, RAR, TAR, and its own 7z format.
- **ZSTD (Zstandard)** — Modern, high-speed compression by Facebook (Meta). Offers gzip-like ratios at 3-5x the speed, with multi-threading support.

**Что это:** **ZIP**, **7-Zip (7z)** и **Zstandard (zstd)** — три широко используемых инструмента сжатия. ZIP — универсальный формат, 7z — максимальное сжатие, zstd — современная высокоскоростная альтернатива.

**Common use cases / Типичные случаи использования:**
- Cross-platform file sharing (ZIP) / Кроссплатформенный обмен файлами
- Maximum compression for archival (7z) / Максимальное сжатие для архивирования
- High-speed backup and log compression (zstd) / Высокоскоростное резервное копирование и сжатие логов
- Encrypted archives for sensitive data (7z, ZIP) / Шифрованные архивы для конфиденциальных данных

**Status / Статус:**
- **ZIP:** ✅ Universal standard. Natively supported everywhere. Encryption is weak (ZipCrypto) — use 7z for secure encryption.
- **7-Zip:** ✅ Actively maintained. Best compression ratios. The go-to tool for maximum compression and Windows compatibility.
- **ZSTD:** ✅ Rapidly growing adoption. Becoming the modern replacement for gzip in Linux. Used by Fedora, Arch, kernel, and many databases.

**See also:** [TAR cheatsheet](tarcheatsheet.md), [TAR+ZSTD cheatsheet](tarzstdcheatsheet.md)

---

## Table of Contents
- [ZIP — Classic Archives](#zip--classic-archives)
- [UNZIP — Extract ZIP](#unzip--extract-zip)
- [7-Zip — High Compression](#7-zip--high-compression)
- [ZSTD — Modern Compression](#zstd--modern-compression)
- [Comparison & Benchmarks](#comparison--benchmarks)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)
- [Documentation Links](#documentation-links)

---

## ZIP — Classic Archives

### Installation / Установка
```bash
sudo apt install zip unzip                    # Debian/Ubuntu
sudo dnf install zip unzip                    # RHEL/Fedora
sudo pacman -S zip unzip                      # Arch Linux
```

### Create Archives / Создание архивов
```bash
zip archive.zip file.txt                     # Zip single file / Архивировать один файл
zip -r archive.zip dir/                       # Zip recursively / Архивировать рекурсивно
zip -r archive.zip file1 file2 dir/           # Multiple files/dirs / Несколько файлов/каталогов
zip -r -9 archive.zip dir/                    # Maximum compression / Максимальное сжатие
zip -r -0 archive.zip dir/                    # Store only (no compression) / Только хранение
```

### Update & Add / Обновление и добавление
```bash
zip -u archive.zip newfile.txt                # Update archive / Обновить архив
zip -d archive.zip file.txt                   # Delete from archive / Удалить из архива
zip -r archive.zip . -x "*.log"               # Exclude pattern / Исключить шаблон
zip -r archive.zip dir/ -x "*/.git/*"         # Exclude .git / Исключить .git
```

### Password Protection / Защита паролем
```bash
zip -r -e archive.zip dir/                    # Encrypt with password / Зашифровать паролем
zip -r -P <PASSWORD> archive.zip dir/         # Password in command / Пароль в команде
```

> [!CAUTION]
> Using `-P <PASSWORD>` exposes the password in shell history and process list. Prefer `-e` for interactive password entry.
> Использование `-P <PASSWORD>` оставляет пароль в истории команд. Используйте `-e` для интерактивного ввода.

> [!WARNING]
> ZIP's default encryption (ZipCrypto) is considered weak. For sensitive data, use 7z with AES-256 encryption (`-mhe=on`).
> Шифрование ZIP по умолчанию (ZipCrypto) считается слабым. Для конфиденциальных данных используйте 7z с AES-256.

### List & Test / Просмотр и тестирование
```bash
unzip -l archive.zip                          # List contents / Список содержимого
unzip -t archive.zip                          # Test integrity / Проверить целостность
unzip -v archive.zip                          # Verbose list / Подробный список
```

---

## UNZIP — Extract ZIP

### Basic Extraction / Базовая распаковка
```bash
unzip archive.zip                             # Extract to current dir / Распаковать в текущую директорию
unzip archive.zip -d out/                     # Extract to out/ / Распаковать в out/
unzip -q archive.zip                          # Quiet mode / Тихий режим
unzip -o archive.zip                          # Overwrite without prompt / Перезаписать без подтверждения
unzip -n archive.zip                          # Never overwrite / Никогда не перезаписывать
```

### Selective Extraction / Выборочная распаковка
```bash
unzip archive.zip file.txt                    # Extract single file / Распаковать один файл
unzip archive.zip "*.txt"                     # Extract by pattern / Распаковать по шаблону
unzip archive.zip -x "*.log"                  # Exclude pattern / Исключить шаблон
unzip archive.zip dir/                        # Extract directory / Распаковать каталог
```

### Password-Protected / Защищённые паролем
```bash
unzip -P <PASSWORD> archive.zip               # Extract with password / Распаковать с паролем
```

---

## 7-Zip — High Compression

### Installation / Установка
```bash
sudo apt install p7zip-full p7zip-rar         # Debian/Ubuntu
sudo dnf install p7zip p7zip-plugins          # RHEL/Fedora
sudo pacman -S p7zip                          # Arch Linux
```

### Create Archives / Создание архивов
```bash
7z a archive.7z file.txt                      # Create 7z archive / Создать 7z архив
7z a archive.7z file1 dir/                    # Add files/dirs / Добавить файлы/каталоги
7z a -t7z -mx=9 archive.7z dir/               # Maximum compression / Максимальное сжатие
7z a -t7z -mx=1 archive.7z dir/               # Fastest compression / Быстрое сжатие
7z a -tzip archive.zip dir/                   # Create ZIP format / Создать формат ZIP
7z a -ttar archive.tar dir/                   # Create TAR format / Создать формат TAR
```

### Extract Archives / Распаковка архивов
```bash
7z x archive.7z                               # Extract with paths / Распаковать с путями
7z e archive.7z                               # Extract to current dir / Распаковать в текущую директорию
7z x archive.7z -o/path/to/out/               # Extract to path / Распаковать в путь
7z x archive.zip                              # Extract ZIP / Распаковать ZIP
7z x archive.rar                              # Extract RAR / Распаковать RAR
```

> [!NOTE]
> `7z x` preserves directory structure, while `7z e` extracts all files flat into a single directory.
> `7z x` сохраняет структуру каталогов, а `7z e` извлекает все файлы в одну директорию.

### List & Test / Просмотр и тестирование
```bash
7z l archive.7z                               # List contents / Список содержимого
7z t archive.7z                               # Test integrity / Проверить целостность
7z l -slt archive.7z                          # Detailed list / Подробный список
```

### Update & Delete / Обновление и удаление
```bash
7z u archive.7z newfile.txt                   # Update archive / Обновить архив
7z d archive.7z file.txt                      # Delete from archive / Удалить из архива
```

### Password & Encryption / Пароль и шифрование
```bash
7z a -p<PASSWORD> archive.7z dir/             # Password protection / Защита паролем
7z a -p<PASSWORD> -mhe=on archive.7z dir/     # Encrypt headers / Зашифровать заголовки
7z x -p<PASSWORD> archive.7z                  # Extract with password / Распаковать с паролем
```

> [!TIP]
> Use `-mhe=on` to encrypt file names in the archive header. Without it, file names are visible even without the password.
> Используйте `-mhe=on` для шифрования имён файлов. Без этого имена файлов видны даже без пароля.

### Compression Levels / Уровни сжатия
```bash
7z a -mx=0 archive.7z dir/                    # Copy (no compression) / Копирование (без сжатия)
7z a -mx=1 archive.7z dir/                    # Fastest / Быстрое
7z a -mx=5 archive.7z dir/                    # Normal (default) / Нормальное (по умолчанию)
7z a -mx=9 archive.7z dir/                    # Ultra / Ультра
```

---

## ZSTD — Modern Compression

### Installation / Установка
```bash
sudo apt install zstd                         # Debian/Ubuntu
sudo dnf install zstd                         # RHEL/Fedora
sudo pacman -S zstd                           # Arch Linux
```

### Compress Files / Сжатие файлов
```bash
zstd file.txt                                 # Compress file / Сжать файл
zstd -19 file.txt                             # Max compression (level 19) / Максимальное сжатие
zstd -1 file.txt                              # Fast compression / Быстрое сжатие
zstd -T0 file.txt                             # Use all CPU cores / Использовать все ядра CPU
zstd -o output.zst file.txt                   # Specify output / Указать выход
zstd -v file.txt                              # Verbose / Подробный вывод
```

### Decompress Files / Распаковка файлов
```bash
zstd -d file.zst                              # Decompress / Распаковать
unzstd file.zst                               # Alternative / Альтернатива
zstd -d -c file.zst > output.txt              # Decompress to stdout / Распаковать в stdout
```

### Multiple Files / Несколько файлов
```bash
zstd *.txt                                    # Compress all txt / Сжать все txt
zstd -d *.zst                                 # Decompress all zst / Распаковать все zst
zstd -rm *.txt                                # Compress and remove / Сжать и удалить
```

> [!WARNING]
> `zstd -rm` removes original files after compression. Use with caution in production.
> `zstd -rm` удаляет оригинальные файлы после сжатия. Используйте с осторожностью.

### Tar Integration / Интеграция с tar
```bash
tar --zstd -cvf archive.tar.zst dir/          # Create tar.zst / Создать tar.zst
tar --zstd -xvf archive.tar.zst               # Extract tar.zst / Распаковать tar.zst
tar --use-compress-program=zstd -cvf archive.tar.zst dir/  # Alternative / Альтернатива
tar -I zstd -xvf archive.tar.zst              # Alternative extraction / Альтернативная распаковка
```

### Benchmarking / Бенчмарки
```bash
zstd -b file.txt                              # Benchmark compression / Бенчмарк сжатия
zstd -b1:19 file.txt                          # Test levels 1-19 / Тест уровней 1-19
```

---

## Comparison & Benchmarks

### Compression Ratio Comparison / Сравнение степени сжатия

| Tool | Ratio | Compress Speed | Decompress Speed | Description (EN / RU) |
|------|-------|---------------|-----------------|----------------------|
| **gzip** | ~2.5x | ~100 MB/s | ~300 MB/s | Universal, moderate / Универсальный, средний |
| **bzip2** | ~3x | ~10 MB/s | ~40 MB/s | Good ratio, slow / Хорошее сжатие, медленный |
| **xz** | ~4x | ~5 MB/s | ~100 MB/s | Best ratio, very slow / Лучшее сжатие, очень медленный |
| **7z** | ~4.5x | ~5 MB/s | ~100 MB/s | Best ratio, Windows friendly / Лучшее, совместим с Windows |
| **zstd** | ~3x | ~400 MB/s | ~1000 MB/s | Very fast, good ratio / Очень быстрый, хорошее сжатие |

### Use Cases / Случаи использования

| Tool | Best For (EN / RU) |
|------|---------------------|
| **gzip** | Universal, default for archives / Универсальное, по умолчанию для архивов |
| **bzip2** | Better compression, legacy systems / Лучшее сжатие, устаревшие системы |
| **xz** | Maximum compression, slow / Максимальное сжатие, медленное |
| **7z** | Maximum compression, Windows compatible / Максимальное сжатие, совместимость с Windows |
| **zstd** | Modern, fast, best balance / Современное, быстрое, лучший баланс |
| **zip** | Universal, Windows compatible / Универсальное, совместимость с Windows |

### Encryption Comparison / Сравнение шифрования

| Tool | Algorithm | Header Encryption | Security Level (EN / RU) |
|------|-----------|-------------------|--------------------------|
| ZIP (ZipCrypto) | PKZIP stream cipher | ❌ No | Weak — easily cracked / Слабое |
| ZIP (AES) | AES-256 | ❌ No | Strong / Сильное |
| 7z | AES-256-CBC | ✅ Yes (`-mhe=on`) | Very strong / Очень сильное |
| gpg + tar | Various | N/A | Very strong / Очень сильное |

---

## Real-World Examples

### Backup with ZSTD / Резервная копия с ZSTD
```bash
# Fast backup / Быстрая резервная копия
tar --zstd -cvf backup-$(date +%F).tar.zst /home/<USER>

# Maximum compression backup / Максимальное сжатие
tar -I "zstd -19 -T0" -cvf backup-$(date +%F).tar.zst /data

# Extract / Распаковать
tar --zstd -xvf backup-$(date +%F).tar.zst
```

### Split Large Archives / Разделение больших архивов
```bash
# Create split zip (100MB parts) / Разделённый zip (100MB)
zip -r -s 100m archive.zip /large/dir

# 7z split (1GB parts) / 7z разделение (1GB)
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
unzip -t archive.zip                          # Verify zip / Проверить zip
7z t archive.7z                               # Verify 7z / Проверить 7z
tar --zstd -tvf archive.tar.zst               # Verify tar.zst / Проверить tar.zst
```

---

## Best Practices

### General Recommendations / Общие рекомендации

- Use zstd for modern Linux systems / Используйте zstd для современных Linux систем
- Use zip for Windows compatibility / Используйте zip для совместимости с Windows
- Use 7z for maximum compression / Используйте 7z для максимального сжатия
- Always test archives after creation / Всегда тестируйте архивы после создания
- Use `-T0` with zstd for parallel compression / Используйте `-T0` с zstd для параллельного сжатия
- Encrypt sensitive archives / Шифруйте чувствительные архивы
- Use 7z with `-mhe=on` instead of ZIP for security / Используйте 7z с `-mhe=on` вместо ZIP для безопасности

### Compression Levels / Уровни сжатия

| Tool | Levels | Default |
|------|--------|---------|
| zstd | 1–19 | 3 |
| 7z | 0–9 | 5 |
| zip | 0–9 | 6 |
| gzip | 1–9 | 6 |

### Default Extensions / Расширения по умолчанию

| Extension | Description (EN / RU) |
|-----------|----------------------|
| `.zip` | ZIP archives / ZIP архивы |
| `.7z` | 7-Zip archives / 7-Zip архивы |
| `.zst` | ZSTD compressed / Сжатые ZSTD |
| `.tar.zst` | TAR with ZSTD / TAR с ZSTD |
| `.tar.gz` | TAR with gzip / TAR с gzip |
| `.tar.xz` | TAR with xz / TAR с xz |

---

## Documentation Links

- **ZIP:**
  - Info-ZIP official: http://infozip.sourceforge.net/
  - zip man page: `man zip` or https://linux.die.net/man/1/zip
  - unzip man page: `man unzip` or https://linux.die.net/man/1/unzip

- **7-Zip:**
  - 7-Zip Official Site: https://www.7-zip.org/
  - p7zip (Linux port): https://github.com/p7zip-project/p7zip
  - 7z man page: `man 7z`
  - 7-Zip documentation: https://documentation.help/7-Zip/

- **Zstandard:**
  - Zstandard Official Site: https://facebook.github.io/zstd/
  - Zstandard GitHub: https://github.com/facebook/zstd
  - Zstandard RFC (RFC 8478): https://tools.ietf.org/html/rfc8478
  - zstd man page: `man zstd` or https://man7.org/linux/man-pages/man1/zstd.1.html

- **See also:** [TAR cheatsheet](tarcheatsheet.md), [TAR+ZSTD cheatsheet](tarzstdcheatsheet.md)
