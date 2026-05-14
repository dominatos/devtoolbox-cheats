Title: 🧷 tmux — Terminal Multiplexer
Group: Dev & Tools
Icon: 🧷
Order: 6

# tmux Cheatsheet — Terminal Multiplexer

> **Description:** tmux (Terminal Multiplexer) is a command-line tool that allows you to create, manage, and navigate between multiple terminal sessions from a single window. Sessions persist after disconnection, making it essential for remote server management — SSH sessions survive connection drops.
> tmux (Terminal Multiplexer) — это инструмент командной строки для создания и управления несколькими терминальными сессиями из одного окна. Сессии сохраняются после отключения, что делает его незаменимым для удалённого управления серверами.

> **Status:** Actively maintained. Alternatives: **GNU Screen** (older, simpler), **Zellij** (modern Rust-based terminal workspace with built-in layouts), **byobu** (tmux/screen wrapper with enhanced UI).
> **Role:** Developer / Sysadmin / DevOps

---

## Table of Contents
- [Basics & Installation](#-basics--installation--основы-и-установка)
- [Session Management](#-session-management--управление-сессиями)
- [Window Management](#-window-management--управление-окнами)
- [Pane Management](#-pane-management--управление-панелями)
- [Copy Mode & Buffers](#-copy-mode--buffers--режим-копирования-и-буферы)
- [Configuration](#-configuration--настройки)
- [Key Bindings Quick Reference](#key-bindings-quick-reference)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Useful Tips](#-useful-tips--полезные-советы)

---

# 📘 Basics & Installation / Основы и установка

### What is tmux? / Что такое tmux?
**tmux** = Terminal Multiplexer — allows you to work with multiple sessions, windows, and panes in one terminal.  
**tmux** = Терминальный мультиплексор — позволяет работать с несколькими сессиями, окнами и панелями в одном терминале.

**Main prefix key** / Главная клавиша префикса: `Ctrl+b`  
All commands are executed after pressing prefix / Все команды вводятся после префикса.

### tmux Components / Компоненты tmux

| Component | Description (EN / RU) |
|-----------|----------------------|
| **Server** | Background process managing all sessions / Фоновый процесс управляющий всеми сессиями |
| **Session** | A collection of windows / Набор окон |
| **Window** | A full-screen tab within a session / Полноэкранная вкладка внутри сессии |
| **Pane** | A split within a window / Разделение внутри окна |

### Installation / Установка
```bash
sudo apt install tmux              # Debian/Ubuntu
sudo dnf install tmux              # RHEL/Fedora
sudo pacman -S tmux                # Arch
brew install tmux                  # macOS
```

---

# 🔧 Session Management / Управление сессиями

### Basic Session Commands / Основные команды сессий
```bash
tmux                                      # Start new session / Запустить новую сессию
tmux new -s <NAME>                        # Create named session / Создать именованную сессию
tmux attach                               # Attach to last session / Подключиться к последней сессии
tmux attach -t <NAME>                     # Attach by name / Подключиться к сессии по имени
tmux ls                                   # List all sessions / Показать список сессий
tmux kill-session -t <NAME>               # Kill specific session / Удалить конкретную сессию
tmux kill-server                          # Kill all sessions / Завершить все сессии
tmux detach                               # Detach from current session / Отсоединиться от текущей сессии
tmux new-session -d -s <NAME>             # Create detached session / Создать фоновую сессию
```

### Session Switching / Переключение сессий
```bash
tmux switch -t <NAME>                     # Switch to session / Переключить сессию
tmux rename-session -t <OLD> <NEW>        # Rename session / Переименовать сессию
```

### Key Bindings / Сочетания клавиш
```
Ctrl+b d                                  # Detach from session / Отсоединиться от сессии
Ctrl+b D                                  # Choose session to detach / Выбор сессии для отсоединения
Ctrl+b s                                  # List sessions / Список сессий
Ctrl+b $                                  # Rename current session / Переименовать текущую сессию
```

---

# 🪟 Window Management / Управление окнами

### Window Commands / Команды окон
```
Ctrl+b c                                  # Create new window / Создать новое окно
Ctrl+b w                                  # List all windows / Список окон
Ctrl+b n                                  # Next window / Следующее окно
Ctrl+b p                                  # Previous window / Предыдущее окно
Ctrl+b l                                  # Last active window / Последнее активное окно
Ctrl+b &                                  # Close current window / Закрыть текущее окно
Ctrl+b ,                                  # Rename window / Переименовать окно
Ctrl+b f                                  # Find window / Найти окно
Ctrl+b 0-9                                # Switch to window N / Переключиться на окно N
```

### Rename Window / Переименование окна
```bash
tmux rename-window <NAME>                 # Rename current window / Переименовать текущее окно
```

---

# 🔲 Pane Management / Управление панелями

### Split Panes / Разделение панелей
```
Ctrl+b %                                  # Split vertically / Вертикальный сплит
Ctrl+b "                                  # Split horizontally / Горизонтальный сплит
```

### Navigate Panes / Навигация между панелями
```
Ctrl+b ↑↓←→                               # Move between panes / Перемещение между панелями
Ctrl+b o                                  # Next pane / Следующая панель
Ctrl+b ;                                  # Last active pane / Предыдущая панель
Ctrl+b q                                  # Show pane numbers / Показать номера панелей
```

### Manage Panes / Управление панелями
```
Ctrl+b x                                  # Kill current pane / Удалить панель
Ctrl+b z                                  # Toggle zoom pane / Развернуть/свернуть панель
Ctrl+b !                                  # Break pane to new window / Вынести панель в новое окно
Ctrl+b {                                  # Move pane left / Переместить панель влево
Ctrl+b }                                  # Move pane right / Переместить панель вправо
```

### Resize Panes / Изменение размера панелей
```
Ctrl+b Alt+↑↓←→                           # Resize pane / Изменить размер панели
Ctrl+b Space                              # Change layout / Сменить раскладку
Ctrl+b M-1                                # Even horizontal layout / Горизонтальная раскладка
Ctrl+b M-2                                # Even vertical layout / Вертикальная раскладка
Ctrl+b M-3                                # Main horizontal layout / Основная горизонтальная
Ctrl+b M-4                                # Main vertical layout / Основная вертикальная
Ctrl+b M-5                                # Tiled layout / Мозаичная раскладка
```

---

# 📋 Copy Mode & Buffers / Режим копирования и буферы

### Copy Mode / Режим копирования
```
Ctrl+b [                                  # Enter copy mode / Войти в режим копирования
↑ ↓ PgUp PgDn                             # Scroll / Пролистывать экран
Space                                     # Start selection / Начать выделение
Enter                                     # Copy selected text / Копировать выделенный текст
Ctrl+b ]                                  # Paste buffer / Вставить буфер
```

### Buffer Management / Управление буферами
```bash
tmux show-buffer                          # Show buffer content / Показать содержимое буфера
tmux save-buffer <FILE>                   # Save buffer to file / Сохранить буфер в файл
tmux load-buffer <FILE>                   # Load buffer from file / Загрузить буфер из файла
tmux paste-buffer                         # Paste buffer / Вставить буфер
```

---

# ⚙️ Configuration / Настройки

### Configuration File / Файл конфигурации
`~/.tmux.conf`

```bash
# Performance / Производительность
set -sg escape-time 0                     # Remove prefix delay / Убрать задержку префикса
set -g history-limit 10000                # History limit / Лимит истории

# Mouse Support / Поддержка мыши
set -g mouse on                           # Enable mouse / Включить мышь

# Indexing / Нумерация
set -g base-index 1                       # Window start from 1 / Нумерация окон с 1
setw -g pane-base-index 1                 # Pane start from 1 / Нумерация панелей с 1

# Prefix Key / Клавиша префикса
unbind C-b                                # Unbind default prefix / Отвязать стандартный префикс
set -g prefix C-a                         # Set new prefix to Ctrl+a / Установить новый префикс Ctrl+a
bind C-a send-prefix                      # Forward prefix / Передать префикс

# Status Bar / Строка состояния
set -g status-bg black                    # Status bar background / Фон строки состояния
set -g status-fg white                    # Status bar foreground / Цвет текста
set -g status-left "#S"                   # Show session name left / Показать имя сессии слева
set -g status-right "%Y-%m-%d %H:%M"      # Show time right / Показать время справа
```

### Reload Configuration / Перезагрузка конфигурации
```bash
tmux source-file ~/.tmux.conf             # Reload config / Перезагрузить конфигурацию
```

Inside tmux command prompt (`Ctrl+b :`):
```
:source-file ~/.tmux.conf                 # Reload from prompt / Перезагрузить из командной строки
```

---

## Key Bindings Quick Reference

### General / Общие
```
Ctrl+b ?                                  # Show all key bindings / Показать все сочетания клавиш
Ctrl+b t                                  # Show clock / Показать часы
Ctrl+b :                                  # Command prompt / Командная строка
```

### Custom Commands / Дополнительные команды
```bash
tmux list-keys                            # List all key bindings / Список всех сочетаний клавиш
tmux info                                 # Show session info / Показать информацию о сессии
```

### Default Shortcuts Summary / Краткая справка по сочетаниям

| Shortcut | Action (EN / RU) |
|----------|-----------------|
| `Ctrl+b c` | New window / Новое окно |
| `Ctrl+b %` | Vertical split / Вертикальный сплит |
| `Ctrl+b "` | Horizontal split / Горизонтальный сплит |
| `Ctrl+b d` | Detach / Отсоединиться |
| `Ctrl+b [` | Copy mode / Режим копирования |
| `Ctrl+b z` | Zoom pane / Развернуть панель |
| `Ctrl+b ?` | Help / Справка |
| `Ctrl+b x` | Kill pane / Удалить панель |
| `Ctrl+b n/p` | Next/Previous window / Следующее/Предыдущее окно |

---

# 🌟 Real-World Examples / Примеры из практики

### Quick Start Workflow / Быстрый старт
```bash
# Create development session / Создать сессию для разработки
tmux new -s dev

# Create windows / Создать окна
Ctrl+b c                                  # New window for editor / Новое окно для редактора
Ctrl+b c                                  # New window for terminal / Новое окно для терминала

# Split panes / Разделить панели
Ctrl+b %                                  # Vertical split / Вертикальный сплит

# Detach and reattach / Отсоединиться и подключиться обратно
Ctrl+b d                                  # Detach / Отсоединиться
tmux attach -t dev                        # Reattach / Подключиться обратно
```

### Development Environment / Среда разработки
```bash
# Create project session with 3 windows / Создать проектную сессию с 3 окнами
tmux new -s project
tmux rename-window editor
tmux new-window -n servers
tmux new-window -n logs

# Split panes for monitoring / Разделить панели для мониторинга
Ctrl+b %                                  # Split for logs / Разделить для логов
```

### Remote Server Management / Управление удалённым сервером
```bash
# SSH to server and create session / SSH на сервер и создать сессию
ssh user@<SERVER>
tmux new -s maintenance

# Work safely - connection drops won't kill session
# Работать безопасно - разрыв соединения не убьёт сессию

# Reconnect later / Переподключиться позже
ssh user@<SERVER>
tmux attach -t maintenance
```

### Pair Programming / Парное программирование
```bash
# User 1: Create shared session / Пользователь 1: Создать общую сессию
tmux new -s shared

# User 2: Attach to same session / Пользователь 2: Подключиться к той же сессии
ssh <USER>@<HOST>
tmux attach -t shared
```

### Kill Detached Sessions / Удалить отсоединённые сессии
```bash
# Remove all detached sessions / Удалить все отсоединённые сессии
tmux ls | grep -v attached | cut -d: -f1 | xargs -n1 tmux kill-session -t
```

### Scripted Session Setup / Скриптовая настройка сессии
```bash
#!/bin/bash
# Create a full development environment / Создать полное окружение разработки
tmux new-session -d -s dev -n editor
tmux send-keys -t dev:editor 'vim .' C-m
tmux new-window -t dev -n server
tmux send-keys -t dev:server 'npm run dev' C-m
tmux new-window -t dev -n logs
tmux send-keys -t dev:logs 'tail -f /var/log/app.log' C-m
tmux select-window -t dev:editor
tmux attach -t dev
```

---

# 💡 Useful Tips / Полезные советы

### Aliases / Алиасы

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias ta='tmux attach -t'                # Quick attach / Быстрое подключение
alias tn='tmux new -s'                   # Quick new session / Быстрое создание сессии
alias tls='tmux ls'                      # Quick list / Быстрый список
alias tkill='tmux kill-session -t'       # Quick kill / Быстрое удаление
```

### Terminal Multiplexer Comparison / Сравнение мультиплексоров

| Tool | Description (EN / RU) | Best For |
|------|----------------------|----------|
| **tmux** | Feature-rich multiplexer / Функциональный мультиплексор | Power users, scripting |
| **GNU Screen** | Classic multiplexer / Классический мультиплексор | Legacy systems, simplicity |
| **Zellij** | Modern Rust-based workspace / Современный workspace на Rust | New users, built-in layouts |
| **byobu** | tmux/screen wrapper / Обёртка для tmux/screen | Enhanced UI out of the box |

### Best Practices / Лучшие практики

- Always name your sessions / Всегда именуйте сессии
- Use mouse mode for easier navigation / Используйте режим мыши для лёгкой навигации
- Keep `.tmux.conf` in version control / Храните `.tmux.conf` под контролем версий
- Use tmux on remote servers / Используйте tmux на удалённых серверах
- Detach instead of closing / Отсоединяйтесь вместо закрытия

### Common Issues / Распространённые проблемы

| Issue | Solution (EN / RU) |
|-------|-------------------|
| Nested tmux | Press prefix twice (`Ctrl+b Ctrl+b`) / Нажмите префикс дважды |
| Wrong colors | `set -g default-terminal "screen-256color"` in `.tmux.conf` / Установить 256-цветный терминал |
| Clipboard not working | Install `xclip` (Linux) or use `pbcopy` (macOS) / Установить `xclip` или использовать `pbcopy` |

### Configuration Files / Файлы конфигурации

| File | Description (EN / RU) |
|------|----------------------|
| `~/.tmux.conf` | User configuration / Пользовательская конфигурация |
| `/etc/tmux.conf` | System-wide configuration / Системная конфигурация |

---

## Official Documentation / Официальная документация

- **tmux:** https://github.com/tmux/tmux/wiki
- **tmux Man Page:** `man tmux`
- **Zellij (alternative):** https://zellij.dev/documentation/
- **GNU Screen:** https://www.gnu.org/software/screen/manual/