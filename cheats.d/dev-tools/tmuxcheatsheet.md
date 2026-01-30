Title: 🧷 tmux — Commands
Group: Dev & Tools
Icon: 🧷
Order: 6

tmux new -s work  # New session work / Новая сессия work
tmux attach -t work  # Attach to session / Подключиться к сессии
tmux kill-session -t work  # Kill session / Убить сессию

Keys (prefix = Ctrl+b) / Клавиши (префикс = Ctrl+b):
% split vertical / Вертикальное разделение
" split horizontal / Горизонтальное разделение
arrows move pane / Перемещение между панелями
z toggle zoom / Развернуть панель на весь экран
x kill-pane / Закрыть панель
d detach / Отсоединиться
[ copy-mode / Режим копирования
c new-window / Новое окно
, rename / Переименовать

Tmux = Terminal Multiplexer — allows you to work with multiple sessions, windows, and panes in one terminal.
Tmux = Терминальный мультиплексор — позволяет работать с несколькими сессиями, окнами и панелями в одном терминале.
Main prefix key / Главная клавиша префикса: Ctrl+b
All commands are executed after pressing prefix / Все команды вводятся после префикса.

Основные команды / Basic Commands:
tmux                     Start new session / Запустить новую сессию
tmux new -s NAME         Create named session / Создать именованную сессию
tmux attach              Attach to last session / Подключиться к последней сессии
tmux attach -t NAME      Attach by name / Подключиться к сессии по имени
tmux ls                  List all sessions / Показать список сессий
tmux kill-session -t NAME Kill specific session / Удалить конкретную сессию
tmux kill-server         Kill all sessions / Завершить все сессии
tmux detach              Detach from current session / Отсоединиться от текущей сессии

Управление окнами / Window Management:
Ctrl+b c   Create new window / Создать новое окно
Ctrl+b w   List all windows / Список окон
Ctrl+b n   Next window / Следующее окно
Ctrl+b p   Previous window / Предыдущее окно
Ctrl+b l   Last window / Последнее активное окно
Ctrl+b &   Close window / Закрыть текущее окно
Ctrl+b ,   Rename window / Переименовать окно
Ctrl+b f   Find window / Найти окно

Управление панелями / Pane Management:
Ctrl+b %   Split vertically / Вертикальный сплит
Ctrl+b "   Split horizontally / Горизонтальный сплит
Ctrl+b o   Next pane / Следующая панель
Ctrl+b q   Show pane numbers / Показать номера панелей
Ctrl+b x   Kill pane / Удалить панель
Ctrl+b z   Zoom toggle / Развернуть панель
Ctrl+b {   Move pane left / Влево
Ctrl+b }   Move pane right / Вправо
Ctrl+b ↑↓←→ Move between panes / Перемещение между панелями
Ctrl+b ;   Last active pane / Предыдущая панель
Ctrl+b !   Break pane to window / Вынести панель в новое окно

Управление сессиями / Session Management:
Ctrl+b d   Detach / Отсоединиться
tmux attach -t name  Reattach / Подключиться обратно
tmux switch -t name  Switch sessions / Переключить сессию
tmux rename-session -t old new  Rename / Переименовать
tmux new-session -d -s name  Create detached / Создать фоновую сессию

Навигация и изменение размера панелей / Resizing and Navigation:
Ctrl+b Alt+←→↑↓ Resize pane / Изменить размер панели
Ctrl+b Space       Change layout / Сменить раскладку
Ctrl+b M-1..5      Apply layout / Применить раскладку

Режим копирования / Copy Mode:
Ctrl+b [     Enter copy mode / Войти в режим копирования
↑ ↓ PgUp PgDn  Scroll / Пролистывать экран
Space         Start selection / Начать выделение
Enter         Copy selected / Копировать
Ctrl+b ]      Paste buffer / Вставить буфер

Буферы / Buffers:
tmux show-buffer        Show buffer content / Показать буфер
tmux save-buffer file   Save buffer / Сохранить буфер
tmux load-buffer file   Load buffer / Загрузить буфер
tmux paste-buffer       Paste buffer / Вставить буфер

Настройки / Configuration:
Файл: ~/.tmux.conf
set -sg escape-time 0        Remove prefix delay / Убрать задержку
set -g mouse on              Enable mouse / Включить мышь
set -g base-index 1          Window start from 1 / Нумерация окон с 1
setw -g pane-base-index 1    Pane start from 1 / Нумерация панелей с 1
set -g history-limit 10000   History limit / Лимит истории
unbind C-b                   Unbind old prefix / Удалить старый префикс
set -g prefix C-a            New prefix / Новый префикс
bind C-a send-prefix         Forward prefix / Передать префикс
set -g status-bg black       Status bg / Фон статусбара
set -g status-fg white       Status fg / Цвет текста
set -g status-left #S        Status left / Левая часть
set -g status-right %Y-%m-%d %H:%M  Status right / Правая часть

tmux source-file ~/.tmux.conf  Reload config / Перезагрузить конфиг

Полезные команды / Useful tips:
tmux list-keys  Show key bindings / Все сочетания клавиш
tmux info       Show info / Инфо о сессии
Ctrl+b t        Clock / Часы
Ctrl+b :        Command prompt / Командная строка
Ctrl+b ?        Help / Справка

Примеры / Examples:
tmux new -s dev     Create session dev / Создать dev
Ctrl+b c            New window / Новое окно
Ctrl+b %            Vertical split / Вертикальный сплит
Ctrl+b d            Detach / Отсоединиться
tmux attach -t dev  Reattach / Вернуться

Убрать висячие сессии / Kill detached:
tmux ls | grep -v attached | cut -d: -f1 | xargs -n1 tmux kill-session -t

Алиасы / Aliases:
alias ta='tmux attach -t'   Attach / Подключиться
alias tn='tmux new -s'      New / Новая
alias tls='tmux ls'         List / Список

Советы / Tips:
set -g mouse on  Mouse scroll & select / Мышь для скролла
tmux rename-window name  Rename window / Переименовать окно
Ctrl+b D  Choose detach / Выбор сессии
Sharing session via ssh same_user + tmux attach / Совместная работа через ssh