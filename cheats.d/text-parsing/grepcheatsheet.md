Title: 🔎 GREP — Commands
Group: Text & Parsing
Icon: 🔎
Order: 2

## Table of Contents
- [Quick Reference](#-quick-reference--краткая-справка)
- [Basics](#-basics--основы)
- [Regex Dialects](#-regex-dialects--диалекты-регулярных-выражений)
- [Files & Recursion](#-files--recursion--файлы-и-рекурсия)
- [Output & Context](#-output--context--вывод-и-контекст)
- [Counts & File Lists](#-counts--file-lists--подсчёт-и-списки-файлов)
- [Words, Lines & Anchors](#-words-lines--anchors--слова-строки-и-якоря)
- [Case & Locale](#-case--locale--регистр-и-локаль)
- [Multiline & NULL-Separated](#-multiline--null-separated--многострочные-и-null-разделители)
- [Performance & Behavior](#-performance--behavior--производительность-и-поведение)
- [Log & Streaming Examples](#-log--streaming-examples--логи-и-потоковая-обработка)
- [Common One-Liners](#-common-one-liners--частые-однострочники)

---

## 🚀 Quick Reference / Краткая справка

```bash
grep -Ev '^(#|$)' /etc/pdns/pdns.conf           # Show only active lines and hide commented / Показывает только активные строки, а закомментированные прячет
grep -nH 'pattern' file*                        # Show line numbers + filenames / Номера строк и имена файлов
grep -ri --include='*.log' 'error' .            # Recursive in *.log (ci) / Рекурсивно по *.log (без регистра)
grep -E 'foo|bar' file                          # Extended regex alternation / Расширенные регэкспы (альтернация)
grep -P '(?<=user=)\w+' file                    # PCRE lookbehind / PCRE просмотр назад
grep -C3 'panic' app.log                        # 3 lines of context / 3 строки контекста
grep -v '^#' config                             # Exclude commented lines / Исключить комментарии
grep -o 'id=[0-9]+' file                        # Print only matching part / Печатать только совпадение
grep -l 'pattern' -r .                          # Files that contain the pattern / Файлы с совпадением
grep -L 'pattern' -r .                          # Files that do NOT contain the pattern / Файлы без совпадения
grep --color=auto -n '\berror\b' app.log        # Highlight whole-word 'error' / Подсветка слова 'error'
```

---

## 📖 Basics / Основы

```bash
grep 'pattern' file.txt                         # Match lines (basic regex) / Совпадения (базовые регэкспы)
grep -n 'pattern' file.txt                      # Show line numbers / Показ номеров строк
grep -H 'pattern' file.txt                      # Always show filename / Всегда показывать имя файла
grep -h 'pattern' file.txt                      # Hide filename / Скрыть имя файла
grep -i 'pattern' file.txt                      # Case-insensitive / Без учета регистра
grep -v 'pattern' file.txt                      # Invert match / Инвертировать совпадения
grep -e 'pat1' -e 'pat2' file.txt               # Multiple patterns / Несколько паттернов
grep -f patterns.txt file.txt                   # Patterns from file / Паттерны из файла
grep -s 'pattern' file.txt                      # Suppress errors / Подавить сообщения об ошибках
grep -q 'pattern' file.txt                      # Quiet; exit status only / Тихий режим; только код выхода
```

---

## 🧬 Regex Dialects / Диалекты регулярных выражений

```bash
grep -E 'a|b|c+' file.txt                       # Extended regex (egrep) / Расширенный синтаксис (egrep)
grep -F 'literal?chars*' file.txt               # Fixed strings (fgrep) / Поиск по строкам без регэкспов (fgrep)
grep -P '(?<=user=)\w+' file.txt                # PCRE lookarounds / PCRE с lookaround
```

---

## 📂 Files & Recursion / Файлы и рекурсия

```bash
grep -r 'pattern' ./dir                         # Recursive (no symlinks) / Рекурсивно (без симлинков)
grep -R 'pattern' ./dir                         # Recursive with symlinks / Рекурсивно + симлинки
grep -I -r 'pattern' ./dir                      # Skip binary files / Пропустить бинарные файлы
grep --include='*.{c,h}' -r 'main' ./src        # Include globs / Только заданные маски
grep --exclude='*.min.js' -r 'pattern' .        # Exclude by glob / Исключить по маске
grep --exclude-dir=.git --exclude-dir=node_modules -r 'pattern' .  # Exclude dirs / Исключить каталоги
grep --binary-files=without-match -r 'pattern' . # Treat binary as no-match / Бинарные как не-совпадение
grep -a 'pattern' binfile                       # Force text for binary / Считать бинарный как текст
```

---

## 📋 Output & Context / Вывод и контекст

```bash
grep -A2 'error' app.log                        # 2 lines After match / 2 строки после
grep -B2 'error' app.log                        # 2 lines Before match / 2 строки до
grep -C3 'error' app.log                        # 3 lines of Context / 3 строки контекста
grep -o 'ERROR:[^ ]\+' app.log                  # Only matched part / Только совпавшая часть
grep -oP '(?<=id=)\d+' app.log                  # Only capture with PCRE / Только группа с PCRE
grep --color=always 'pattern' file.txt          # Always colorize / Всегда подсвечивать
grep --color=auto 'pattern' file.txt            # Colorize when TTY / Подсветка если TTY
grep --line-buffered -r 'pattern' /var/log      # Flush each line (pipes) / Построчная буферизация
grep --label='stdin' 'pattern' -                # Label for stdin / Метка для stdin
```

---

## 🔢 Counts & File Lists / Подсчёт и списки файлов

```bash
grep -c 'pattern' file.txt                      # Count per file / Количество совпадений в файле
grep -r -c 'pattern' ./dir                      # Counts recursively / Подсчёт рекурсивно
grep -m 1 'pattern' big.log                     # Stop after N matches / Остановиться после 1-го совпадения
grep -l 'pattern' *.txt                         # List files with matches / Файлы с совпадениями
grep -L 'pattern' *.txt                         # List files without matches / Файлы без совпадений
grep -Z -l 'pattern' . | xargs -0 ls -l         # NUL-delimited names / Имена, разделённые NUL
```

---

## 🔤 Words, Lines & Anchors / Слова, строки и якоря

```bash
grep -w 'cat' file.txt                          # Whole word / Целое слово
grep -x 'exact line' file.txt                   # Exact line / Точное совпадение строки
grep -E '^(GET|POST) ' access.log               # Anchor at start / Якорь в начале
grep -E 'error$' app.log                        # Anchor at end / Якорь в конце
```

---

## 🌐 Case & Locale / Регистр и локаль

```bash
LC_ALL=C grep -i 'straße' file.txt              # ASCII case-folding / ASCII-фолдинг регистра
grep -i 'pattern' file.txt                      # Locale-aware case-insensitive / Без регистра с учётом локали
```

---

## 📄 Multiline & NULL-Separated / Многострочные и NULL-разделители

```bash
grep -z 'foo.*bar' file0                        # Read NUL-separated "lines" / NUL-разделители как строки
grep -zPo 'foo(?s).*?bar' file0                 # PCRE with dotall via -z / PCRE с dotall через -z
grep -Z 'pattern' files*                        # Print NUL after filename / NUL после имени файла
```

---

## ⚡ Performance & Behavior / Производительность и поведение

```bash
grep --mmap 'pattern' bigfile                   # Allow mmap I/O / Разрешить mmap I/O
grep --no-messages 'pattern' missing*           # Suppress "No such file" / Подавить «Нет файла»
grep --directories=read 'pattern' dir           # Read dirs as files / Читать каталоги как файлы
grep --exclude-from=globs.txt -r 'p' .          # Exclude globs from file / Исключения из файла
grep --text 'pattern' file.bin                  # Same as -a (treat as text) / То же что -a
```

---

## 📊 Log & Streaming Examples / Логи и потоковая обработка

```bash
tail -f app.log | grep --line-buffered -E 'ERROR|WARN'  # Live filter logs / Живой фильтр логов
journalctl -u nginx -n 500 | grep -n 'timeout'          # Search last 500 lines / Поиск в последних 500 строках
grep -r --include='*.log' -nE 'HTTP/[23]\.[01] 5..' /var/log  # Find 5xx responses / Найти ответы 5xx
```

---

## 💡 Common One-Liners / Частые однострочники

```bash
grep -R --include='*.{py,sh}' -n 'TODO' .       # List TODOs in code / TODO в коде
grep -R -n --exclude-dir=.git --exclude-dir=node_modules 'pattern' .  # Skip heavy dirs / Пропустить тяжёлые каталоги
grep -ri --include='*.log' 'error' .             # Recursive only in *.log / Рекурсивно только в *.log
grep -r -c 'pattern' .                           # Count matches per file / Подсчёт совпадений на файл
```
