---
Title: ⚡ Modern CLI — ripgrep/fd/bat/eza
Group: "Text & Parsing"
Icon: ⚡
Order: 10
tags:
  - text-parsing
  - linux
  - sysadmin
---

> **Modern CLI replacements** for classic Unix tools — all written in Rust for speed and safety. **ripgrep** (`rg`) replaces `grep`, **fd** replaces `find`, **bat** replaces `cat`, and **eza** (community fork of the unmaintained `exa`) replaces `ls`. These tools provide better defaults, colorized output, `.gitignore` awareness, and significantly faster performance. They are drop-in enhancements for daily sysadmin and developer workflows.

> [!IMPORTANT]
> **exa is unmaintained** since 2023. The actively maintained community fork is [**eza**](https://github.com/eza-community/eza). All examples below use `eza`.

## Table of Contents
- [ripgrep — Fast Search](#ripgrep%20—%20Fast%20Search)
- [fd — Fast Find](#fd%20—%20Fast%20Find)
- [bat — Better Cat](#bat%20—%20Better%20Cat)
- [eza — Better ls](#eza%20—%20Better%20ls)
- [Real-World Examples](#Real-World%20Examples)
- [Best Practices](#Best%20Practices)
- [Aliases](#Use%20eza%20aliases%20for%20enhanced%20ls)
- [Tool Comparison](#Tool%20Comparison)
- [Installation](#️%20Installation)

---

## 🔍 ripgrep — Fast Search

### Basic Search

```bash
rg 'pattern'                                  # Search in current dir / Поиск в текущей директории
rg 'pattern' path/                            # Search in path / Поиск в пути
rg -i 'pattern'                               # Case-insensitive / Без учёта регистра
rg -w 'word'                                  # Match whole words / Совпадение целых слов
rg -v 'pattern'                               # Invert match / Обратное совпадение
```

### Advanced Search

```bash
rg 'pattern' -n                               # Show line numbers / Показать номера строк
rg 'pattern' --hidden                         # Include hidden files / Включить скрытые файлы
rg 'pattern' -g '*.py'                        # Glob pattern / Glob паттерн
rg 'pattern' -g '!node_modules'               # Exclude pattern / Исключить паттерн
rg 'pattern' -t py                            # File type (Python) / Тип файла (Python)
```

### Output Control

```bash
rg 'pattern' -l                               # Files with matches / Файлы с совпадениями
rg 'pattern' -c                               # Count matches per file / Подсчитать совпадения по файлам
rg 'pattern' --no-heading                     # No file headers / Без заголовков файлов
rg 'pattern' -A 3                             # Show 3 lines after / Показать 3 строки после
rg 'pattern' -B 3                             # Show 3 lines before / Показать 3 строки до
rg 'pattern' -C 3                             # Show 3 lines context / Показать 3 строки контекста
```

### Multiple Patterns

```bash
rg 'pattern1|pattern2'                        # OR search / ИЛИ поиск
rg -e 'pattern1' -e 'pattern2'                # Multiple patterns / Несколько паттернов
rg 'pattern' --and 'other'                    # AND search / И поиск
```

### Replacement

```bash
rg 'pattern' -r 'replacement' --passthru      # Replace (dry-run) / Замена (тестовый прогон)
rg 'pattern' -r 'replacement' --passthru | sponge file.txt  # Replace in file / Замена в файле
```

---

## 📂 fd — Fast Find

### Basic Find

```bash
fd pattern                                    # Find pattern / Найти паттерн
fd -t f pattern                               # Files only / Только файлы
fd -t d pattern                               # Directories only / Только директории
fd -t l pattern                               # Symlinks only / Только символические ссылки
```

### Extensions

```bash
fd -e log                                     # Find .log files / Найти .log файлы
fd -e py -e js                                # Multiple extensions / Несколько расширений
fd . /path                                    # Find in path / Найти в пути
```

### Advanced Options

```bash
fd -H pattern                                 # Include hidden files / Включить скрытые файлы
fd -I pattern                                 # Don't respect .gitignore / Не учитывать .gitignore
fd -g '*.log' -g '!old*'                      # Glob patterns / Glob паттерны
fd -d 3 pattern                               # Max depth 3 / Макс глубина 3
```

### Execute Commands

```bash
fd -t f -x cat {}                             # Execute on each / Выполнить на каждом
fd -t f -X vim                                # Execute once with all / Выполнить один раз со всеми
fd -e py -x python {}                         # Run Python files / Запустить Python файлы
```

---

## 🎨 bat — Better Cat

### Basic Usage

```bash
bat file.txt                                  # Show file / Показать файл
bat -p file.txt                               # Plain output (no line numbers) / Простой вывод
bat --style=plain file.txt                    # Same as above / То же что выше
bat -n file.txt                               # Show line numbers only / Показать только номера строк
```

### Language / Syntax

```bash
bat -l python file.txt                        # Force Python syntax / Принудительно Python синтаксис
bat --list-languages                          # List supported languages / Список поддерживаемых языков
```

### Themes

```bash
bat --theme=TwoDark file.txt                  # Use theme / Использовать тему
bat --list-themes                             # List available themes / Список доступных тем
```

### Paging

```bash
bat --paging=never file.txt                   # No pager / Без pager
bat --paging=always file.txt                  # Force pager / Принудительно pager
```

### Integration

```bash
export BAT_THEME="Monokai Extended"           # Set default theme / Установить тему по умолчанию
alias cat='bat -p'                            # Replace cat / Заменить cat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"  # Use as man pager / Использовать как man pager
```

---

## 📊 eza — Better ls

### Basic Listing

```bash
eza                                           # List files / Список файлов
eza -l                                        # Long format / Длинный формат
eza -la                                       # Long + all files / Длинный + все файлы
eza -lh                                       # Long + human-readable / Длинный + удобочитаемый
```

### Tree View

```bash
eza --tree                                    # Tree view / Вид дерева
eza --tree -L 2                               # Tree depth 2 / Глубина дерева 2
eza --tree -I 'node_modules|.git'             # Tree with ignore / Дерево с игнорированием
```

### Git Integration

```bash
eza -l --git                                  # Show git status / Показать git статус
eza -l --git-ignore                           # Respect .gitignore / Учитывать .gitignore
```

### Sorting

```bash
eza -l --sort=modified                        # Sort by modification time / Сортировать по времени модификации
eza -l --sort=size                            # Sort by size / Сортировать по размеру
eza -l --sort=extension                       # Sort by extension / Сортировать по расширению
```

### Colors & Icons

```bash
eza -l --color=always                         # Force colors / Принудительно цвета
eza -l --icons                                # Show icons / Показать иконки
eza -l --color-scale                          # Color by size / Цвет по размеру
```

---

## 🌟 Real-World Examples

### Code Search

```bash
# Find TODOs
rg 'TODO|FIXME|XXX' -n

# Find function definition
rg 'def myfunction' -t py

# Search excluding tests
rg 'pattern' -g '!*test*'

# Case-insensitive search in JS
rg -i 'console.log' -t js
```

### File Operations

```bash
# Find and delete old logs
fd -e log -X rm

# Find large files
fd -t f -x du -h {} | sort -hr | head -20

# Find recent files
fd -t f --changed-within 1d

# Batch rename
fd -e txt -x mv {} {.}.bak
```

### Development Workflow

```bash
# Find all Python files
fd -e py -X bat

# Search and replace
rg 'old_function' -l | xargs sed -i 's/old_function/new_function/g'

# Count lines of code
fd -e py -X wc -l | awk '{sum+=$1} END {print sum}'
```

### Log Analysis

```bash
# Search errors in logs
rg 'ERROR|FATAL' -t log

# Find errors with context
rg 'ERROR' -C 5 /var/log/app.log

# Count error types
rg 'ERROR' /var/log/app.log | cut -d':' -f3 | sort | uniq -c
```

### Git Workflows / Git

```bash
# Search in git-tracked files only
rg 'pattern' --type-add 'tracked:include:$(git ls-files)'

# Show modified files
eza -l --git --git-ignore

# Tree view of project
eza --tree -L 3 -I 'node_modules|.git|dist'
```

### System Administration

```bash
# Find config files
fd -H -e conf -e config

# Search in system logs
rg 'error' /var/log/ -g '*.log'

# Find SUID binaries
fd -t x -x test -u {} \; -print
```

### Combining Tools

```bash
# Search and open in editor
rg -l 'pattern' | fzf | xargs vim

# Find and preview files
fd -e md | fzf --preview 'bat --color=always {}'

# Interactive file search
fd -t f | fzf --preview 'bat --color=always --line-range :50 {}'
```

---

## 💡 Best Practices

```bash
# Use ripgrep instead of grep for speed
# Use fd instead of find for simplicity
# Set bat as default pager
# Use eza aliases for enhanced ls
# Combine tools with fzf for interactivity
# Use --hidden and -I carefully
```

---

## 🔧 Aliases

```bash
alias cat='bat -p'
alias catn='bat'
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias grep='rg'
alias find='fd'
```

---

## 📋 Tool Comparison

| Classic Tool | Modern Tool | Advantage / Преимущество |
|-------------|-------------|--------------------------|
| `grep` | `ripgrep` (`rg`) | 10-100x faster / 10-100x быстрее |
| `find` | `fd` | Simpler syntax, faster / Проще синтаксис, быстрее |
| `cat` | `bat` | Syntax highlighting / Подсветка синтаксиса |
| `ls` | `eza` (was `exa`) | Colors, git integration / Цвета, интеграция с git |

---

## ⚠️ Installation

```bash
# Ubuntu/Debian
sudo apt install ripgrep fd-find bat
sudo apt install -t unstable eza         # or install from GitHub releases

# Fedora
sudo dnf install ripgrep fd-find bat eza

# Arch
sudo pacman -S ripgrep fd bat eza

# macOS
brew install ripgrep fd bat eza
```

> [!NOTE]
> On Debian/Ubuntu `fd` may be installed as `fdfind`. Create a symlink: `ln -s $(which fdfind) ~/.local/bin/fd`
> На Debian/Ubuntu `fd` может быть установлен как `fdfind`. Создайте симлинк: `ln -s $(which fdfind) ~/.local/bin/fd`

> [!NOTE]
> `exa` is **unmaintained** since 2023. Use [`eza`](https://github.com/eza-community/eza) — the actively maintained community fork with the same CLI interface.
> `exa` **не поддерживается** с 2023. Используйте [`eza`](https://github.com/eza-community/eza) — активно поддерживаемый форк с тем же CLI-интерфейсом.

---

## 📚 Documentation

- [ripgrep — GitHub](https://github.com/BurntSushi/ripgrep)
- [fd — GitHub](https://github.com/sharkdp/fd)
- [bat — GitHub](https://github.com/sharkdp/bat)
- [eza — GitHub (maintained fork of exa)](https://github.com/eza-community/eza)
- [exa — GitHub (unmaintained)](https://github.com/ogham/exa)
