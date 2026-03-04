Title: 🔪 cut/sort/uniq — Commands
Group: Text & Parsing
Icon: 🔪
Order: 6

## Table of Contents
- [CUT — Field Extraction](#-cut--field-extraction--cut--извлечение-полей)
- [SORT — Sorting Lines](#-sort--sorting-lines--sort--сортировка-строк)
- [UNIQ — Deduplication](#-uniq--deduplication--uniq--удаление-дубликатов)
- [Combined Pipelines](#-combined-pipelines--комбинированные-конвейеры)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Performance Tips](#-performance-tips--советы-по-производительности)

---

## ✂️ CUT — Field Extraction / CUT — Извлечение полей

### By Delimiter / По разделителю

```bash
cut -d',' -f1 data.csv                         # First column (CSV) / Первый столбец (CSV)
cut -d',' -f1,3 data.csv                       # Columns 1 and 3 / Столбцы 1 и 3
cut -d',' -f1-3 data.csv                       # Columns 1 to 3 / Столбцы от 1 до 3
cut -d',' -f2- data.csv                        # From column 2 onward / Со столбца 2 до конца
cut -d':' -f1 /etc/passwd                      # Extract usernames / Извлечь имена пользователей
cut -d':' -f1,3 /etc/passwd                    # Username and UID / Имя и UID
cut -d' ' -f1 access.log                       # First field (space-delimited) / Первое поле (пробел)
cut -d$'\t' -f2 file.tsv                       # Tab-delimited / Разделитель табуляция
```

### By Character Position / По позиции символов

```bash
cut -c1-10 file                                # Characters 1-10 / Символы 1-10
cut -c5 file                                   # 5th character only / Только 5-й символ
cut -c1,5,10 file                              # Specific characters / Конкретные символы
cut -c5- file                                  # From position 5 onward / С позиции 5 до конца
cut -c-10 file                                 # First 10 characters / Первые 10 символов
```

### By Byte / По байтам

```bash
cut -b1-10 file                                # First 10 bytes / Первые 10 байтов
cut -b5- file                                  # From byte 5 onward / С байта 5 до конца
```

### Options / Опции

```bash
cut -d',' -f1 --complement data.csv            # All except field 1 / Все кроме поля 1
cut -d',' -f1-3 --output-delimiter=' ' file    # Custom output delimiter / Свой разделитель вывода
cut -s -d':' -f1 /etc/passwd                   # Suppress lines without delimiter / Пропустить строки без разделителя
```

---

## 📊 SORT — Sorting Lines / SORT — Сортировка строк

### Basic Sorting / Базовая сортировка

```bash
sort file                                      # Alphabetical sort / Алфавитная сортировка
sort -r file                                   # Reverse sort / Обратная сортировка
sort -u file                                   # Unique lines / Уникальные строки
sort -n numbers.txt                            # Numeric sort / Числовая сортировка
sort -nr numbers.txt                           # Numeric reverse / Обратная числовая
sort -h sizes.txt                              # Human-readable sizes (1K, 2M) / Человекочитаемые размеры
sort -M months.txt                             # Month sort / Сортировка по месяцам
sort -V versions.txt                           # Version sort / Сортировка версий
```

### By Field / По полю

```bash
sort -t',' -k2 data.csv                        # Sort by 2nd field (CSV) / Сортировать по 2-му полю
sort -t',' -k2,2 data.csv                      # Sort only by field 2 / Только по полю 2
sort -t':' -k3 -n /etc/passwd                  # Numeric sort by 3rd field / Числовая по 3-му полю
sort -k2n -k1 file                             # Sort by 2nd (numeric), then 1st / По 2-му (числовая), затем по 1-му
sort -t',' -k3nr data.csv                      # 3rd field numeric reverse / 3-е поле обратная числовая
```

### Advanced Options / Продвинутые опции

```bash
sort -o output.txt input.txt                   # Sort to file / Сортировать в файл
sort --parallel=4 largefile.txt                # Use 4 cores / Использовать 4 ядра
sort -S 2G largefile.txt                       # Use 2GB buffer / Использовать 2GB буфер
sort -m file1.txt file2.txt                    # Merge sorted files / Объединить отсортированные
sort -c file.txt                               # Check if sorted / Проверить сортировку
sort -d file.txt                               # Dictionary order / Словарный порядок
sort -f file.txt                               # Case-insensitive / Без учёта регистра
sort -b file.txt                               # Ignore leading blanks / Игнорировать пробелы вначале
sort -s file.txt                               # Stable sort / Стабильная сортировка
```

---

## 🔀 UNIQ — Deduplication / UNIQ — Удаление дубликатов

### Basic Usage / Базовое использование

```bash
sort file | uniq                               # Remove adjacent duplicates / Удалить смежные дубликаты
sort file | uniq -c                            # Count occurrences / Подсчитать вхождения
sort file | uniq -d                            # Show only duplicates / Только дубликаты
sort file | uniq -u                            # Show only unique / Только уникальные
sort file | uniq -i                            # Case-insensitive / Без учёта регистра
```

### With Count / С подсчётом

```bash
sort file | uniq -c                            # Count lines / Подсчитать строки
sort file | uniq -c | sort -nr                 # Sort by frequency / Сортировать по частоте
sort file | uniq -c | sort -n                  # Sort by frequency (ascending) / По частоте (возрастание)
sort file | uniq -c | sort -rn | head -10      # Top 10 most frequent / Топ 10 самых частых
```

### By Field / По полю

```bash
sort -k2 file | uniq -f 1                      # Skip first field / Пропустить первое поле
sort file | uniq -s 5                          # Skip first 5 chars / Пропустить первые 5 символов
sort file | uniq -w 10                         # Compare only first 10 chars / Сравнивать только первые 10 символов
```

---

## 🔗 Combined Pipelines / Комбинированные конвейеры

### CUT + SORT + UNIQ

```bash
cut -d',' -f2 data.csv | sort | uniq           # Unique values in column 2 / Уникальные значения столбца 2
cut -d',' -f2 data.csv | sort | uniq -c        # Count unique in column 2 / Подсчитать уникальные столбца 2
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10  # Top 10 IPs / Топ 10 IP-адресов
```

### Complex Pipelines / Сложные конвейеры

```bash
cat /var/log/nginx/access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -20  # Top 20 IPs / Топ 20 IP
ps aux | tr -s ' ' | cut -d' ' -f1 | sort | uniq -c  # Processes per user / Процессы по пользователю
netstat -an | grep ESTABLISHED | cut -d':' -f2 | cut -d' ' -f1 | sort | uniq -c  # Connections per port / Соединения по порту
```

---

## 🌟 Real-World Examples / Примеры из практики

### Log Analysis / Анализ логов

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head  # Top IPs / Топ IP-адресов
cut -d' ' -f7 access.log | sort | uniq -c | sort -rn | head  # Most requested URLs / Самые запрашиваемые URL
cut -d' ' -f9 access.log | sort | uniq -c                   # HTTP status distribution / Распределение HTTP статусов
cat access.log | cut -d'[' -f2 | cut -d']' -f1 | cut -d':' -f2 | sort | uniq -c  # Requests by hour / Запросы по часам
```

### User & System Analysis / Анализ пользователей и системы

```bash
cut -d':' -f1 /etc/passwd | sort                # All usernames / Все имена пользователей
cut -d':' -f3 /etc/passwd | sort -n             # All UIDs / Все UID
cut -d':' -f7 /etc/passwd | sort | uniq -c      # Shell distribution / Распределение shell
ps aux | tr -s ' ' | cut -d' ' -f1 | sort | uniq -c | sort -rn  # Processes per user / Процессы на пользователя
```

### Data Processing / Обработка данных

```bash
cut -d',' -f2,4 sales.csv | sort -t',' -k2 -nr  # Sort sales by price / Сортировать продажи по цене
cut -d',' -f3 data.csv | sort -n | uniq          # Unique numeric values / Уникальные числовые значения
cat *.log | cut -d' ' -f5 | sort | uniq -c       # Aggregate from multiple files / Агрегация из нескольких файлов
```

### CSV Manipulation / Работа с CSV

```bash
cut -d',' -f1,3,5 data.csv > filtered.csv       # Extract columns / Извлечь столбцы
cut -d',' -f2 data.csv | sort | uniq | wc -l    # Count unique values / Подсчитать уникальные значения
cut -d',' -f3 data.csv | sort -n > sorted.txt   # Sort numeric column / Сортировать числовой столбец
```

### Network Analysis / Анализ сети

```bash
netstat -an | grep ESTABLISHED | cut -d':' -f2 | cut -d' ' -f1 | sort | uniq -c  # Active connections / Активные соединения
ss -tn | tail -n +2 | tr -s ' ' | cut -d' ' -f5 | cut -d':' -f1 | sort | uniq -c | sort -rn  # Connections by IP / Соединения по IP
cat /var/log/auth.log | grep "Failed password" | cut -d' ' -f11 | sort | uniq -c | sort -rn  # Failed SSH attempts / Неудачные попытки SSH
```

### File System / Файловая система

```bash
find . -type f -name "*.log" | cut -d'/' -f2 | sort | uniq  # Unique subdirs with logs / Уникальные подкаталоги с логами
df -h | tail -n +2 | tr -s ' ' | cut -d' ' -f5 | sort -h    # Disk usage sorted / Использование диска (сортировка)
du -sh * | sort -h                              # Directory sizes sorted / Размеры каталогов (сортировка)
```

### Complex Text Processing / Сложная обработка текста

```bash
grep "ERROR" app.log | cut -d' ' -f5 | cut -d':' -f1 | sort | uniq -c | sort -rn  # Error frequency by hour / Частота ошибок по часам
ps aux | tail -n +2 | tr -s ' ' | cut -d' ' -f3 | sort -n | tail -1  # Highest CPU process / Процесс с максимальным CPU
cat /proc/cpuinfo | grep "model name" | cut -d':' -f2 | uniq  # CPU model / Модель CPU
```

---

## 💡 Performance Tips / Советы по производительности

```bash
# Use 'sort -u' instead of 'sort | uniq' for better performance
# Используйте 'sort -u' вместо 'sort | uniq'
sort -u file                                    # Faster than sort | uniq / Быстрее чем sort | uniq

# For very large files, use LC_ALL=C for faster sorting
# Для очень больших файлов используйте LC_ALL=C
LC_ALL=C sort largefile.txt                     # Faster byte-order sort / Быстрая побайтовая сортировка

# Parallelize sorting for multi-core systems
# Распараллеливание для многоядерных систем
sort --parallel=8 -S 4G largefile.txt           # 8 cores, 4GB buffer / 8 ядер, 4GB буфер
```
