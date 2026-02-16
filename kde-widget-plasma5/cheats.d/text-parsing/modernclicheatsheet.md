Title: ⚡ Modern CLI — ripgrep/fd/bat/exa
Group: Text & Parsing
Icon: ⚡
Order: 10

## Table of Contents
- [ripgrep — Fast Search](#-ripgrep--fast-search)
- [fd — Fast Find](#-fd--fast-find)
- [bat — Better Cat](#-bat--better-cat)
- [exa — Better ls](#-exa--better-ls)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔍 ripgrep — Fast Search

### Basic Search / Базовый поиск
rg 'pattern'                                  # Search in current dir / Поиск в текущей директории
rg 'pattern' path/                            # Search in path / Поиск в пути
rg -i 'pattern'                               # Case-insensitive / Без учёта регистра
rg -w 'word'                                  # Match whole words / Совпадение целых слов
rg -v 'pattern'                               # Invert match / Обратное совпадение

### Advanced Search / Продвинутый поиск
rg 'pattern' -n                               # Show line numbers / Показать номера строк
rg 'pattern' --hidden                         # Include hidden files / Включить скрытые файлы
rg 'pattern' -g '*.py'                        # Glob pattern / Glob паттерн
rg 'pattern' -g '!node_modules'               # Exclude pattern / Исключить паттерн
rg 'pattern' -t py                            # File type (Python) / Тип файла (Python)

### Output Control / Управление выводом
rg 'pattern' -l                               # Files with matches / Файлы с совпадениями
rg 'pattern' -c                               # Count matches per file / Подсчитать совпадения по файлам
rg 'pattern' --no-heading                     # No file headers / Без заголовков файлов
rg 'pattern' -A 3                             # Show 3 lines after / Показать 3 строки после
rg 'pattern' -B 3                             # Show 3 lines before / Показать 3 строки до
rg 'pattern' -C 3                             # Show 3 lines context / Показать 3 строки контекста

### Multiple Patterns / Несколько паттернов
rg 'pattern1|pattern2'                        # OR search / ИЛИ поиск
rg -e 'pattern1' -e 'pattern2'                # Multiple patterns / Несколько паттернов
rg 'pattern' --and 'other'                    # AND search / И поиск

### Replacement / Замена
rg 'pattern' -r 'replacement' --passthru      # Replace (dry-run) / Замена (тестовый прогон)
rg 'pattern' -r 'replacement' --passthru | sponge file.txt  # Replace in file / Замена в файле

---

# 📂 fd — Fast Find

### Basic Find / Базовый поиск
fd pattern                                    # Find pattern / Найти паттерн
fd -t f pattern                               # Files only / Только файлы
fd -t d pattern                               # Directories only / Только директории
fd -t l pattern                               # Symlinks only / Только символические ссылки

### Extensions / Расширения
fd -e log                                     # Find .log files / Найти .log файлы
fd -e py -e js                                # Multiple extensions / Несколько расширений
fd . /path                                    # Find in path / Найти в пути

### Advanced Options / Продвинутые опции
fd -H pattern                                 # Include hidden files / Включить скрытые файлы
fd -I pattern                                 # Don't respect .gitignore / Не учитывать .gitignore
fd -g '*.log' -g '!old*'                      # Glob patterns / Glob паттерны
fd -d 3 pattern                               # Max depth 3 / Макс глубина 3

### Execute Commands / Выполнить команды
fd -t f -x cat {}                             # Execute on each / Выполнить на каждом
fd -t f -X vim                                # Execute once with all / Выполнить один раз со всеми
fd -e py -x python {}                         # Run Python files / Запустить Python файлы

---

# 🎨 bat — Better Cat

### Basic Usage / Базовое использование
bat file.txt                                  # Show file / Показать файл
bat -p file.txt                               # Plain output (no line numbers) / Простой вывод
bat --style=plain file.txt                    # Same as above / То же что выше
bat -n file.txt                               # Show line numbers only / Показать только номера строк

### Language /Syntax / Язык/Синтаксис
bat -l python file.txt                        # Force Python syntax / Принудительно Python синтаксис
bat --list-languages                          # List supported languages / Список поддерживаемых языков

### Themes / Темы
bat --theme=TwoDark file.txt                  # Use theme / Использовать тему
bat --list-themes                             # List available themes / Список доступных тем

### Paging / Пагинация
bat --paging=never file.txt                   # No pager / Без pager
bat --paging=always file.txt                  # Force pager / Принудительно pager

### Integration / Интеграция
export BAT_THEME="Monokai Extended"           # Set default theme / Установить тему по умолчанию
alias cat='bat -p'                            # Replace cat / Заменить cat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"  # Use as man pager / Использовать как man pager

---

# 📊 exa — Better ls

### Basic Listing / Базовый список
exa                                           # List files / Список файлов
exa -l                                        # Long format / Длинный формат
exa -la                                       # Long + all files / Длинный + все файлы
exa -lh                                       # Long + human-readable / Длинный + удобочитаемый

### Tree View / Вид дерева
exa --tree                                    # Tree view / Вид дерева
exa --tree -L 2                               # Tree depth 2 / Глубина дерева 2
exa --tree -I 'node_modules|.git'             # Tree with ignore / Дерево с игнорированием

### Git Integration / Интеграция с Git
exa -l --git                                  # Show git status / Показать git статус
exa -l --git-ignore                           # Respect .gitignore / Учитывать .gitignore

### Sorting / Сортировка
exa -l --sort=modified                        # Sort by modification time / Сортировать по времени модификации
exa -l --sort=size                            # Sort by size / Сортировать по размеру
exa -l --sort=extension                       # Sort by extension / Сортировать по расширению

### Colors & Icons / Цвета и иконки
exa -l --color=always                         # Force colors / Принудительно цвета
exa -l --icons                                # Show icons / Показать иконки
exa -l --color-scale                          # Color by size / Цвет по размеру

---

# 🌟 Real-World Examples / Примеры из практики

### Code Search / Поиск кода
```bash
# Find TODOs / Найти TODO
rg 'TODO|FIXME|XXX' -n

# Find function definition / Найти определение функции
rg 'def myfunction' -t py

# Search excluding tests / Поиск исключая тесты
rg 'pattern' -g '!*test*'

# Case-insensitive search in JS / Поиск без учёта регистра в JS
rg -i 'console.log' -t js
```

### File Operations / Операции с файлами
```bash
# Find and delete old logs / Найти и удалить старые логи
fd -e log -X rm

# Find large files / Найти большие файлы
fd -t f -x du -h {} | sort -hr | head -20

# Find recent files / Найти недавние файлы
fd -t f --changed-within 1d

# Batch rename / Пакетное переименование
fd -e txt -x mv {} {.}.bak
```

### Development Workflow / Рабочий процесс разработки
```bash
# Find all Python files / Найти все Python файлы
fd -e py -X bat

# Search and replace / Поиск и замена
rg 'old_function' -l | xargs sed -i 's/old_function/new_function/g'

# Count lines of code / Подсчитать строки кода
fd -e py -X wc -l | awk '{sum+=$1} END {print sum}'
```

### Log Analysis / Анализ логов
```bash
# Search errors in logs / Поиск ошибок в логах
rg 'ERROR|FATAL' -t log

# Find errors with context / Найти ошибки с контекстом
rg 'ERROR' -C 5 /var/log/app.log

# Count error types / Подсчитать типы ошибок
rg 'ERROR' /var/log/app.log | cut -d':' -f3 | sort | uniq -c
```

### Git Workflows / Git рабочие процессы
```bash
# Search in git-tracked files only / Поиск только в отслеживаемых файлах
rg 'pattern' --type-add 'tracked:include:$(git ls-files)'

# Show modified files / Показать измененные файлы
exa -l --git --git-ignore

# Tree view of project / Вид дерева проекта
exa --tree -L 3 -I 'node_modules|.git|dist'
```

### System Administration / Системное администрирование
```bash
# Find config files / Найти конфигурационные файлы
fd -H -e conf -e config

# Search in system logs / Поиск в системных логах
rg 'error' /var/log/ -g '*.log'

# Find SUID binaries / Найти SUID бинарники
fd -t x -x test -u {} \; -print
```

### Combining Tools / Комбинирование инструментов
```bash
# Search and open in editor / Поиск и открытие в редакторе
rg -l 'pattern' | fzf | xargs vim

# Find and preview files / Найти и предпросмотр файлов
fd -e md | fzf --preview 'bat --color=always {}'

# Interactive file search / Интерактивный поиск файлов
fd -t f | fzf --preview 'bat --color=always --line-range :50 {}'
```

# 💡 Best Practices / Лучшие практики
# Use ripgrep instead of grep for speed / Используйте ripgrep вместо grep для скорости
# Use fd instead of find for simplicity / Используйте fd вместо find для простоты
# Set bat as default pager / Установите bat как pager по умолчанию
# Use exa aliases for enhanced ls / Используйте алиасы exa для улучшенного ls
# Combine tools with fzf for interactivity / Комбинируйте инструменты с fzf для интерактивности
# Use --hidden and -I carefully / Используйте --hidden и -I осторожно

# 🔧 Aliases / Алиасы
alias cat='bat -p'
alias catn='bat'
alias ls='exa'
alias ll='exa -l'
alias la='exa -la'
alias lt='exa --tree'
alias grep='rg'
alias find='fd'

# 📋 Tool Comparison / Сравнение инструментов
# ripgrep vs grep: 10-100x faster / 10-100x быстрее
# fd vs find: Simpler syntax, faster / Проще синтаксис, быстрее
# bat vs cat: Syntax highlighting / Подсветка синтаксиса
# exa vs ls: Colors, git integration / Цвета, интеграция с git

# ⚠️ Installation / Установка
# Ubuntu/Debian: apt install ripgrep fd-find bat exa
# Fedora: dnf install ripgrep fd-find bat exa
# macOS: brew install ripgrep fd bat exa
# Note: fd may be 'fdfind' on Debian / Примечание: fd может быть 'fdfind' на Debian
