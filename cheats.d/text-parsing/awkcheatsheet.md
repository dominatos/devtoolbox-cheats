Title: 🦾 AWK — Commands
Group: Text & Parsing
Icon: 🦾
Order: 4

> **AWK** — pattern-scanning and text-processing language, part of POSIX and available on virtually every Unix/Linux system. GNU AWK (`gawk`) is the most common implementation. AWK excels at columnar data extraction, report generation, and one-liner transformations in shell pipelines. It remains a core sysadmin tool with no signs of deprecation; for heavier data work, consider `python` or `miller`.

## Table of Contents
- [Basics](#-basics--основы)
- [Field Separators](#-field-separators--разделители-полей)
- [Patterns & Filters](#-patterns--filters--шаблоны-и-фильтры)
- [Built-in Variables](#-built-in-variables--встроенные-переменные)
- [Arithmetic & Aggregation](#-arithmetic--aggregation--арифметика-и-агрегация)
- [String Functions](#-string-functions--строковые-функции)
- [Arrays & Loops](#-arrays--loops--массивы-и-циклы)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Advanced Patterns](#-advanced-patterns--продвинутые-шаблоны)

---

## 📖 Basics / Основы

```bash
awk '{print}' file                             # Print all lines / Вывести все строки
awk '{print $1}' file                          # Print first column / Вывести первый столбец
awk '{print $1,$3}' file                       # Print columns 1,3 / Вывести столбцы 1 и 3
awk '{print $NF}' file                         # Print last column / Вывести последний столбец
awk '{print $(NF-1)}' file                     # Second-to-last column / Предпоследний столбец
awk '{print $0}' file                          # Print whole line / Вывести всю строку
```

---

## 🔤 Field Separators / Разделители полей

```bash
awk -F',' '{print $1,$3}' data.csv             # Comma separator / Разделитель — запятая
awk -F':' '{print $1}' /etc/passwd             # Colon separator / Разделитель — двоеточие
awk -F'\t' '{print $2}' file.tsv               # Tab separator / Разделитель — табуляция
awk 'BEGIN{FS=":"; OFS=","} {print $1,$3}' file  # Input/Output FS / Входной и выходной разделитель
awk -F'[,:]' '{print $1}' file                 # Multiple separators / Несколько разделителей
```

---

## 🎯 Patterns & Filters / Шаблоны и фильтры

```bash
awk '/ERROR/' file                             # Lines matching regex / Строки с совпадением
awk '!/^#/' file                               # Exclude comments / Исключить комментарии
awk '$3 > 100' file                            # Column 3 > 100 / Столбец 3 больше 100
awk '$2 == "active"' file                      # Exact match / Точное совпадение
awk '/ERROR/ && $2 == "db"' app.log            # Combined conditions / Комбинированные условия
awk 'NR >= 10 && NR <= 20' file                # Lines 10-20 / Строки 10-20
awk 'length($0) > 80' file                     # Lines longer than 80 / Строки длиннее 80 символов
awk '$1 ~ /^[0-9]+$/' file                     # First column is numeric / Первый столбец — число
```

---

## 🔢 Built-in Variables / Встроенные переменные

```bash
awk '{print NR, $0}' file                      # NR = line number / NR = номер строки
awk '{print NF, $0}' file                      # NF = field count / NF = количество полей
awk 'NR == 5' file                             # Print line 5 / Вывести строку 5
awk 'NR > 5' file                              # Skip first 5 lines / Пропустить первые 5 строк
awk 'END {print NR}' file                      # Total line count / Общее количество строк
awk '{print FILENAME, $0}' file                # FILENAME = current file / FILENAME = текущий файл
```

---

## 🧮 Arithmetic & Aggregation / Арифметика и агрегация

```bash
awk '{sum += $2} END {print sum}' file         # Sum column 2 / Сумма столбца 2
awk '{sum += $2; count++} END {print sum/count}' file  # Average / Среднее значение
awk '{if ($2 > max) max = $2} END {print max}' file  # Maximum value / Максимальное значение
awk '{min = (NR == 1 || $2 < min) ? $2 : min} END {print min}' file  # Minimum / Минимум
awk '{total += $3} END {print "Total:", total}' file  # Running total / Итоговая сумма
awk '{print $1, $2 * 1.5}' file                # Multiply column / Умножить столбец
```

---

## 🔡 String Functions / Строковые функции

```bash
awk '{print toupper($1)}' file                 # Convert to uppercase / В верхний регистр
awk '{print tolower($1)}' file                 # Convert to lowercase / В нижний регистр
awk '{print length($0)}' file                  # Line length / Длина строки
awk '{print substr($1, 1, 5)}' file            # Substring (pos 1, len 5) / Подстрока
awk '{gsub(/foo/, "bar"); print}' file         # Global replace / Глобальная замена
awk '{sub(/^[ \t]+/, ""); print}' file         # Remove leading spaces / Удалить пробелы в начале
awk 'index($0, "error")' file                  # Lines containing "error" / Строки с "error"
awk '{split($0, a, ":"); print a[1]}' file     # Split into array / Разбить в массив
```

---

## 📊 Arrays & Loops / Массивы и циклы

```bash
awk '{count[$1]++} END {for (k in count) print k, count[k]}' file  # Frequency count / Подсчёт частот
awk '{sum[$1] += $2} END {for (k in sum) print k, sum[k]}' file  # Sum by key / Сумма по ключу
awk '{a[$1] = $2} END {for (k in a) print k, a[k]}' file  # Key-value map / Карта ключ-значение
awk 'NR == FNR {map[$1] = $2; next} {print $0, map[$1]}' A B  # Join two files / Соединить два файла
```

---

## 🌟 Real-World Examples / Примеры из практики

```bash
awk -F',' '{sum[$1] += $3} END {for (k in sum) print k, sum[k]}' sales.csv  # Sales by category / Продажи по категориям
ps aux | awk '$3 > 50 {print $2, $11}'         # High CPU processes / Процессы с высоким CPU
awk '/ERROR/ {errors++} /WARN/ {warnings++} END {print "Errors:", errors, "Warnings:", warnings}' app.log  # Log analysis / Анализ логов
df -h | awk '$5+0 > 80 {print $0}'             # Disk usage > 80% / Использование диска > 80%
netstat -an | awk '/ESTABLISHED/ {count++} END {print count}'  # Count connections / Подсчёт соединений
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10  # Top 10 IPs / Топ 10 IP-адресов
awk 'BEGIN {for(i=1; i<=10; i++) print "Line", i}'  # Generate lines / Генерация строк
awk -F: '$3 >= 1000 {print $1}' /etc/passwd     # Users with UID >= 1000 / Пользователи с UID >= 1000
```

---

## 💡 Advanced Patterns / Продвинутые шаблоны

```bash
awk 'BEGIN {print "Start"} {print $0} END {print "End"}' file  # BEGIN/END blocks / Блоки BEGIN/END
awk '/start/,/end/' file                       # Range pattern / Шаблон диапазона
awk '!seen[$0]++' file                         # Remove duplicate lines / Удалить дубликаты
awk '{$2 = $2 * 1.1; print}' file              # Modify and print / Изменить и вывести
awk 'NR % 2 == 0' file                         # Even-numbered lines / Чётные строки
awk 'NR % 2 == 1' file                         # Odd-numbered lines / Нечётные строки
```

---

## 📚 Documentation / Документация

- [GNU AWK User's Guide (gawk)](https://www.gnu.org/software/gawk/manual/gawk.html)
- [POSIX awk specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html)
- [AWK — Wikipedia](https://en.wikipedia.org/wiki/AWK)
- `man awk` / `man gawk`
