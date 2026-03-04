Title: 🌲 Tree — Cheatsheet
Group: Text & Parsing
Icon: 🌲
Order: 13

## Table of Contents
- [Basic Usage](#-basic-usage--базовое-использование)
- [Filters (Include/Exclude)](#-filters-includeexclude--фильтры-включениеисключение)
- [Sorting & Order](#-sorting--order--сортировка-и-порядок)
- [Metadata Columns](#-metadata-columns--столбцы-метаданных)
- [Symlinks](#-symlinks--символические-ссылки)
- [Color & Charsets](#-color--charsets--цвет-и-кодировки)
- [Report & Output](#-report--output--отчёт-и-вывод)
- [HTML Output](#-html-output--html-вывод)
- [Performance Tips](#-performance-tips--советы-по-производительности)
- [Practical Recipes](#-practical-recipes--практические-рецепты)

---

## 📂 Basic Usage / Базовое использование

```bash
tree                          # Default recursive listing / Рекурсивный вывод по умолчанию
tree -L 2                     # Limit depth to 2 levels / Ограничить глубину до 2 уровней
tree -d                       # Directories only / Показывать только каталоги
tree -a                       # Include hidden files / Включать скрытые файлы (начинаются с .)
tree -f                       # Show full path prefixes / Печатать полный путь к каждому элементу
tree -i                       # No indentation lines / Без рисования "веток" (ровный список)
tree -x                       # Stay on current filesystem / Не выходить за пределы текущей ФС
```

---

## 🔍 Filters (Include/Exclude) / Фильтры (включение/исключение)

```bash
tree -I 'node_modules|.git'   # Ignore by pattern(s) / Исключить по шаблону(ам)
tree -P '*.py|*.sh'           # Include only matching files / Включить только файлы по шаблону
tree --matchdirs -P 'src*'    # Apply pattern to dirs too / Применить шаблон и к каталогам
tree --prune                  # Prune empty dirs (useful with -I/-P) / Подрезать пустые каталоги
tree --filelimit 200          # Skip dirs with > N entries / Пропускать каталоги с > N элементов
```

---

## 📊 Sorting & Order / Сортировка и порядок

```bash
tree -U                       # Do not sort (faster) / Не сортировать (быстрее)
tree -r                       # Reverse sort order / Обратная сортировка
tree -t                       # Sort by mtime / Сортировка по времени изменения
tree -S                       # Sort by size / Сортировка по размеру
tree -v                       # Version sort (1,2,10) / "Человеческая" сортировка версий
tree --dirsfirst              # Dirs before files / Каталоги раньше файлов
```

---

## 📋 Metadata Columns / Столбцы метаданных

```bash
tree -s                       # Show size (bytes) / Показать размер в байтах
tree -h                       # Human-readable sizes / Удобные размеры (K, M, G)
tree --du                     # Dir sizes = sum of contents / Размер каталога как сумма содержимого
tree --si                     # SI units (1000-based) / Размеры в тыс. мерах (10^3)
tree -p                       # Show permissions / Права доступа (как ls -l)
tree -u                       # Show owner / Показывать владельца
tree -g                       # Show group / Показывать группу
tree -D                       # Show last mod time / Показать время изменения
tree --timefmt '%F %T'        # Custom time format for -D / Свой формат времени для -D
tree -F                       # Type indicators (/ * @ = |) / Индикаторы типа в конце имён
tree -Q                       # Quote names / Брать имена в кавычки
tree --inodes                 # Show inode numbers / Показать номера инодов
tree --device                 # Show device IDs / Показать ID устройства
```

---

## 🔗 Symlinks / Символические ссылки

```bash
tree -l                       # Follow symlinks / Ходить по симлинкам как по каталогам
tree -L 1 -l                  # Follow links but limit depth / По симлинкам, но ограничить глубину
```

---

## 🎨 Color & Charsets / Цвет и кодировки

```bash
tree -C                       # Force color / Насильно включить цвет
tree -n                       # No color / Отключить цвет
tree --charset=UTF-8          # Set output charset / Указать кодировку вывода
tree -q                       # Nonprintables as '?' / Непечатаемые символы как '?'
tree -N                       # Print raw characters / Печатать символы как есть
```

---

## 📄 Report & Output / Отчёт и вывод

```bash
tree --noreport               # No "X directories, Y files" / Без итоговой строки-отчёта
tree -L 3 | less -R           # Page through long output / Пролистывать длинный вывод
tree -L 2 > tree.txt          # Save to text file / Сохранить в текстовый файл
tree -o out.txt               # Write to file (text) / Писать вывод сразу в файл (текст)
```

---

## 🌐 HTML Output / HTML вывод

```bash
tree -H . -o index.html       # Generate clickable HTML / Сгенерировать HTML с кликабельными ссылками
tree -H /base -o tree.html    # HTML with base HREF / HTML с базовым HREF
tree -h --du -H . -o sizes.html  # HTML + human dir sizes / HTML со сводными размерами каталогов
```

---

## ⚡ Performance Tips / Советы по производительности

```bash
tree -L 2 -I '.git|node_modules|venv'   # Limit & ignore heavy dirs / Ограничить глубину и исключить тяжёлые каталоги
tree -U -L 2                             # Unsorted = faster / Без сортировки быстрее на больших деревьях
tree --prune -I '*.tmp|*.log'            # Prune + ignore junk / Убрать пустые и мусорные каталоги
tree -L 1 -d                             # Quick top-level map / Быстрый обзор верхнего уровня
```

---

## 🧰 Practical Recipes / Практические рецепты

```bash
tree -L 2 -a --du -h                     # Depth 2 + hidden + human dir sizes / Глубина 2 + скрытые + удобные размеры
tree -d -L 3 --noreport                  # Only dirs, depth 3, no footer / Только каталоги, глубина 3, без отчёта
tree -P '*.md|*.txt' -L 3                # Only docs up to depth 3 / Только .md/.txt до глубины 3
tree -I '.git|dist|build|node_modules'   # Ignore common build dirs / Игнор типовых билд-каталогов
tree -f -Q -L 2                          # Full paths, quoted / Полные пути в кавычках
tree -t -r -L 2                          # Newest first within depth / Новые сверху при глубине 2
tree -S -r -L 1                          # Largest first at top level / Самые большие сверху на верхнем уровне
tree --fromfile list.txt                 # Read paths from file / Список путей из файла (по строкам)
```
