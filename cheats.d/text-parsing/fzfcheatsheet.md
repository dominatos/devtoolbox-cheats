Title: ⚡ fzf — Fuzzy Finder
Group: Text & Parsing
Icon: ⚡
Order: 11

> **fzf** (Fuzzy Finder) — a general-purpose, interactive command-line fuzzy finder written in Go by Junegunn Choi. It reads lines from stdin and provides an interactive, filterable selection interface. Commonly used for file navigation, command history search, process management, Git workflows, and as a building block for custom shell functions. Actively maintained with frequent releases; no known alternatives match its versatility.

## Table of Contents
- [Basics](#-basics--основы)
- [File & Directory Navigation](#-file--directory-navigation--навигация-по-файлам-и-каталогам)
- [Command History](#-command-history--история-команд)
- [Git Integration](#-git-integration--интеграция-с-git)
- [Process Management](#-process-management--управление-процессами)
- [Custom Preview](#-custom-preview--настраиваемый-предпросмотр)
- [Docker & Kubernetes](#-docker--kubernetes)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Advanced Techniques](#-advanced-techniques--продвинутые-техники)
- [Keybindings & Options](#-keybindings--options--клавиатурные-сокращения-и-опции)
- [Color Schemes](#-color-schemes--цветовые-схемы)
- [Search Modes](#-search-modes--режимы-поиска)
- [Performance](#-performance--производительность)
- [Installation](#%EF%B8%8F-installation--установка)

---

## 📖 Basics / Основы

```bash
fzf                                            # Interactive fuzzy finder / Интерактивный нечёткий поиск
fzf -m                                         # Multi-select mode / Режим множественного выбора
fzf --height 40%                               # Set height / Установить высоту
fzf --reverse                                  # Reverse layout / Обратная раскладка
fzf --border                                   # Show border / Показать рамку
fzf --prompt='Select: '                        # Custom prompt / Произвольная подсказка
fzf --query='init'                             # Start with query / Начать с запроса
fzf --select-1                                 # Auto-select if only one match / Авт выбор если одно совпадение
fzf --exit-0                                   # Auto-exit if no matches / Автовыход если нет совпадений
```

---

## 📁 File & Directory Navigation / Навигация по файлам и каталогам

```bash
fd -t f | fzf                                  # Find and select file / Найти и выбрать файл
fd -t f | fzf | xargs -r $EDITOR               # Pick file to edit / Выбрать файл для редактирования
fd -t d | fzf                                  # Find and select directory / Найти и выбрать каталог
fd -t f | fzf | xargs -r cat                   # View file content / Просмотреть содержимое
find . -type f | fzf --preview 'cat {}'        # With preview / С предпросмотром
fd . | fzf --preview 'bat --color=always {}'   # Syntax highlighted preview / Предпросмотр с подсветкой
fd . | fzf --preview 'tree -C {} | head -100'  # Tree preview for dirs / Дерево для каталогов
```

---

## 📜 Command History / История команд

```bash
history | fzf                                  # Search command history / Поиск по истории команд
history | fzf +s --tac                         # Reverse history / Обратная история
history | fzf +s | sed 's/^ *[0-9]* *//' | sh  # Execute selected command / Выполнить выбранную команду
fc -l 1 | fzf | awk '{print $2}'               # Alternative history / Альтернативная история
```

---

## 🌿 Git Integration / Интеграция с Git

```bash
git branch | fzf | xargs -r git checkout       # Switch branch / Переключить ветку
git branch -a | fzf | sed 's/remotes\/origin\///' | xargs -r git checkout  # Checkout remote branch / Переключить удалённую ветку
git log --oneline | fzf | awk '{print $1}' | xargs -r git show  # View commit / Просмотреть коммит
git status -s | fzf -m | awk '{print $2}' | xargs -r git add  # Stage files / Добавить файлы
git diff --name-only | fzf | xargs -r git checkout --  # Discard changes / Отменить изменения
git branch | fzf -m | xargs -r git branch -d   # Delete branches / Удалить ветки
git log --oneline | fzf --preview 'git show --color=always {1}'  # Log with preview / Лог с предпросмотром
git reflog | fzf | awk '{print $1}' | xargs -r git checkout  # Browse reflog / Просмотр reflog
```

---

## 🔄 Process Management / Управление процессами

> [!WARNING]
> `kill -9` forcefully terminates processes without cleanup. Use with caution.
> `kill -9` принудительно завершает процессы без очистки. Используйте с осторожностью.

```bash
ps aux | fzf | awk '{print $2}' | xargs -r kill  # Kill process / Убить процесс
ps aux | fzf -m | awk '{print $2}' | xargs -r kill -9  # Force kill multiple / Принудительно убить несколько
systemctl list-units --type=service | fzf | awk '{print $1}' | xargs -r systemctl status  # Service status / Статус сервиса
systemctl list-units --type=service --state=running | fzf | awk '{print $1}' | xargs -r systemctl restart  # Restart service / Перезапустить сервис
journalctl -u $(systemctl list-units --type=service | fzf | awk '{print $1}')  # View service logs / Просмотр логов сервиса
```

---

## 🖼️ Custom Preview / Настраиваемый предпросмотр

```bash
fzf --preview 'cat {}'                         # File content preview / Предпросмотр содержимого
fzf --preview 'head -100 {}'                   # First 100 lines / Первые 100 строк
fzf --preview 'bat --style=numbers --color=always {}'  # Syntax highlight with bat / С подсветкой синтаксиса
fzf --preview 'ls -lah {}'                     # File details / Детали файла
fzf --preview-window=right:50%                 # Preview on right 50% / Предпросмотр справа 50%
fzf --preview-window=up:40%:wrap               # Preview up with wrap / Предпросмотр сверху с переносом
fzf --preview-window=hidden                    # Hidden preview (toggle with ctrl-/) / Скрытый предпросмотр
```

---

## 🐳 Docker & Kubernetes

```bash
docker ps -a --format '{{.Names}}' | fzf | xargs -r docker logs  # View container logs / Просмотр логов контейнера
docker ps -a --format '{{.Names}}' | fzf -m | xargs -r docker rm -f  # Remove containers / Удалить контейнеры
docker images --format '{{.Repository}}:{{.Tag}}' | fzf -m | xargs -r docker rmi  # Remove images / Удалить образы
docker ps --format '{{.Names}}' | fzf | xargs -r docker exec -it  # Exec into container / Войти в контейнер
kubectl get pods -o name | fzf | xargs -r kubectl logs  # View pod logs / Просмотр логов пода
kubectl get pods -o name | fzf | xargs -r kubectl describe  # Describe pod / Описание пода
kubectl get pods -o name | fzf | xargs -r kubectl delete  # Delete pod / Удалить под
```

---

## 🌟 Real-World Examples / Примеры из практики

```bash
# Select and edit config file / Выбор и редактирование конфига
fd -e conf -e yaml -e yml /etc | fzf | xargs -r $EDITOR

# Select and tail log file / Выбор и просмотр лога
find /var/log -name "*.log" | fzf | xargs -r tail -f

# Kill process by name / Убить процесс по имени
ps aux | fzf --header 'Select process to kill' | awk '{print $2}' | xargs -r kill -9

# SSH to host / SSH на хост
cat ~/.ssh/config | grep "^Host " | awk '{print $2}' | fzf | xargs -r ssh

# Change directory / Сменить каталог
cd $(fd -t d | fzf)

# Git checkout with preview / Git checkout с предпросмотром
git branch -a | sed 's/^* //' | sed 's/remotes\/origin\///' | sort -u | fzf --preview 'git log --oneline --color=always {}' | xargs -r git checkout

# Select and compress files / Выбор и сжатие файлов
fd -t f | fzf -m | xargs -r tar -czf archive.tar.gz

# Find and remove old files / Найти и удалить старые файлы
find . -name "*.tmp" -mtime +7 | fzf -m --preview 'ls -lh {}' | xargs -r rm

# Browse and edit recent files / Просмотр и редактирование недавних файлов
find . -type f -mtime -7 | fzf --preview 'bat --color=always {}' | xargs -r $EDITOR
```

---

## 🔧 Advanced Techniques / Продвинутые техники

```bash
# With ripgrep for content search / С ripgrep для поиска по содержимому
rg --files-with-matches "" | fzf --preview 'rg --pretty --context 3 {q} {}'

# Interactive file manager / Интерактивный файловый менеджер
fd . | fzf --bind 'enter:execute($EDITOR {})'

# Multi-select with custom actions / Множественный выбор с действиями
fd -t f | fzf -m --bind 'ctrl-d:execute(rm {}),ctrl-e:execute($EDITOR {})'

# Environment variable selector / Выбор переменной окружения
env | fzf | cut -d= -f1

# Select and copy to clipboard / Выбор и копирование в буфер
fd -t f | fzf | xargs -r cat | xclip -selection clipboard

# Kill process by port / Убить процесс по порту
lsof -ti:$(seq 1 65535 | fzf) | xargs -r kill -9
```

---

## 💡 Keybindings & Options / Клавиатурные сокращения и опции

### Default Keybindings / Стандартные сочетания

| Key | Action / Действие |
|-----|-------------------|
| `Ctrl-J` / `Ctrl-K` | Move down/up / Вниз/вверх |
| `Ctrl-N` / `Ctrl-P` | Move down/up / Вниз/вверх |
| `Enter` | Select / Выбрать |
| `Ctrl-C` / `Esc` | Cancel / Отменить |
| `Ctrl-Space` | Toggle selection (multi-select) / Переключить выбор |
| `Ctrl-/` | Toggle preview / Переключить предпросмотр |

### Custom Keybindings / Пользовательские сочетания

```bash
fzf --bind 'ctrl-a:select-all,ctrl-d:deselect-all'  # Select all/none / Выбрать все/ничего
fzf --bind 'ctrl-y:execute-silent(echo {} | xclip)'  # Copy to clipboard / Копировать в буфер
fzf --bind 'ctrl-e:execute($EDITOR {})'            # Edit file / Редактировать файл
fzf --bind 'ctrl-r:reload(fd -t f)'                # Reload results / Перезагрузить результаты
```

---

## 🎨 Color Schemes / Цветовые схемы

```bash
fzf --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9       # Dracula theme / Тема Dracula
fzf --color=dark                                   # Dark theme / Тёмная тема
fzf --color=light                                  # Light theme / Светлая тема
fzf --color=16                                     # 16-color scheme / 16-цветная схема
```

---

## 🔍 Search Modes / Режимы поиска

```bash
fzf --exact                                        # Exact match / Точное совпадение
fzf -e                                             # Short exact flag / Короткий флаг точного совпадения
fzf -i                                             # Case-insensitive / Без учёта регистра
fzf +i                                             # Case-sensitive / С учётом регистра
fzf --nth 2,3                                      # Search only fields 2,3 / Искать только в полях 2,3
fzf --with-nth 2..                                 # Display from field 2 / Показывать с поля 2
```

---

## 🚀 Performance / Производительность

```bash
fzf --algo=v2                                      # Use v2 algorithm / Использовать алгоритм v2
fzf --no-sort                                      # Don't sort results / Не сортировать результаты
fzf --tiebreak=index                               # Tiebreaker strategy / Стратегия равенства
```

---

## ⚙️ Installation / Установка

```bash
# Ubuntu/Debian
sudo apt install fzf

# Fedora
sudo dnf install fzf

# Arch
sudo pacman -S fzf

# macOS
brew install fzf

# From Git (latest)
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

# Check version / Проверить версию
fzf --version
```

> [!TIP]
> After installing, source the shell integration for keybindings (`Ctrl-T`, `Ctrl-R`, `Alt-C`):
> `source /usr/share/doc/fzf/examples/key-bindings.bash` (path varies by distro).

---

## 📚 Documentation / Документация

- [fzf — GitHub repository](https://github.com/junegunn/fzf)
- [fzf Wiki — Examples](https://github.com/junegunn/fzf/wiki/examples)
- [fzf Wiki — Configuring](https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings)
- `man fzf`
