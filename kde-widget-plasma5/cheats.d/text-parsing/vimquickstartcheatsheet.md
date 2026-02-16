Title: ✍️ vim
Group: Text & Parsing
Icon: ✍️
Order: 1

# Open / Save / Quit — Открытие / Сохранение / Выход
vim file.txt                                     # Open file / Открыть файл
:e {file}                                        # Edit (open) file / Открыть файл
:ene                                             # New empty buffer / Новый пустой буфер
:w                                               # Save / Сохранить
:w {filename}                                    # Save as / Сохранить как
:x | :wq                                         # Save & quit / Сохранить и выйти
:q | :q!                                         # Quit / force quit / Выйти / выйти без сохранения
:qa | :qa!                                       # Quit all (force) / Выйти из всех (силой)
:w !sudo tee %                                   # Save with sudo / Сохранить с sudo

# Modes — Режимы
i / a / o / O                                    # Insert before/after/new line / Вставка до/после/новая строка
ESC                                              # Back to Normal / Возврат в normal
R                                                # Replace mode / Режим замены
v / V / Ctrl+v                                   # Visual char/line/block / Визуальный симв./строчный/блочный

# Navigation & Movement — Навигация и перемещения
h j k l                                          # Left/down/up/right / Влево/вниз/вверх/вправо
w / b / e                                        # Word fwd/back/end / По словам вперёд/назад/конец
0 / ^ / $                                        # Line start/first non-space/end / Начало/первый не-пробел/конец
gg / G                                           # File start/end / Начало/конец файла
{ / }                                            # Prev/next paragraph / Абзац назад/вперёд
f{char} / t{char}                                # Find/till char on line / Найти/до символа в строке
; / ,                                            # Repeat last f/t (fwd/back) / Повтор f/t (вперёд/назад)
%                                                # Jump between pairs ()[]{} / Переход по парным скобкам
H / M / L                                        # Top/Middle/Bottom of screen / Верх/середина/низ экрана
Ctrl+u / Ctrl+d                                  # Half-page up/down / Полстраницы вверх/вниз
Ctrl+b / Ctrl+f                                  # Page up/down / Страница вверх/вниз
:{number}                                        # Go to line / Перейти на строку

# Marks & Jumps — Метки и прыжки
m{a-z}                                           # Set mark / Поставить метку
'{a-z} / `{a-z}                                  # Jump to mark (line/column) / Прыжок к метке (строка/точно)
'' / ``                                          # Jump back (line/pos) / Назад (строка/точно)
gi                                               # Last insert position / К последней точке вставки
gd / gD                                          # Go to local/global definition (ctags) / К определению
:ju / :changes                                   # Jump/change list / Списки прыжков/изменений
Ctrl+o / Ctrl+i                                  # Older/newer jump / Назад/вперёд по прыжкам

# Search — Поиск
/pattern                                         # Search forward / Поиск вперёд
n / N                                            # Next/prev match / След./пред. совпадение
* / #                                            # Search word under cursor fwd/back / По слову под курсором
:noh                                             # Clear highlight / Снять подсветку
:set incsearch hlsearch                          # Live search + highlight / Живой поиск + подсветка
:set nowrapscan ignorecase smartcase             # Search behavior / Поведение поиска

# Replace — Замены
:%s/foo/bar/g                                    # Replace all / Замена во всём файле
:%s/foo/bar/gc                                   # Replace with confirm / Замена с подтв.
:%s/\v(foo|baz)/bar/g                            # “Very magic” regex / Упрощённые регэкспы
:'<,'>s/\s\+/, /g                                # Replace in visual selection / Замена в выделении
:%s/\n/\r/g                                      # Use \r as newline in replace / Перенос строки — \r

# Editing — Редактирование
x                                                # Delete char / Удалить символ
d{motion} / c{motion} / y{motion}                # Delete/change/yank by motion / По движению
dw / d$ / dd                                     # Del word / to EOL / line / Удалить слово/до конца/строку
ciw / diw / daw                                  # Change/delete (inner/a word) / Изменить/удалить слово
C / D / S                                        # Change to EOL / Delete to EOL / Substitute line
s / r{char}                                      # Substitute char / Replace with char / Замены символов
J                                                # Join lines / Склеить строки
.                                                # Repeat last change / Повторить действие
~ / gu{motion} / gU{motion}                      # Toggle/lower/upper case / Регистр
>> / << / =                                      # Indent right/left/autoformat / Отступы/выравнивание
gq{motion} / gqq / gqap                          # Format text / Форматирование текста
yy / p / P                                       # Yank line / paste after/before / Копир. строку / вставка
u / Ctrl+r                                       # Undo / redo / Отмена / повтор
xp                                               # Swap two chars / Поменять символы местами

# Visual & Block Ops — Операции в визуальном/блочном режимах
I / A  (in Ctrl+v)                               # Insert/append on block / Вставка/добавление в столбец
:normal {cmd}                                    # Apply Normal cmd to selection / Команда к выделению

# Registers & Clipboard — Регистры и буфер обмена
:reg                                             # Show registers / Показать регистры
"{reg}y / "{reg}p                                # Yank/Paste with register / Копир./вставка в регистр
"+y / "+p                                        # System clipboard / Системный буфер обмена
"_d                                              # Black hole delete / «Чёрная дыра» (без буфера)

# Windows (splits) — Окна (сплиты)
:split / :vsplit                                 # Split horizontally/vertically / Гор./верт. сплит
Ctrl+w s / Ctrl+w v                              # Split via mapping / Сплит с клавиатуры
Ctrl+w w / h j k l                               # Switch window / Переключение окна
Ctrl+w q / c / o                                 # Close / close-pane / only / Закрыть / оставить одно
Ctrl+w = / :res +/-N / :vert res N               # Equalize / resize / Выравнять / размер

# Tabs — Вкладки
:tabnew / :tabclose / :tabonly                   # New / close / only / Новая / закрыть / только эта
:tabnext / :tabprev / :tabmove N                 # Next / prev / reorder / Вперёд / назад / переместить

# Buffers — Буферы
:ls                                              # List buffers / Список буферов
:b{N} / :bn / :bp / :b#                          # By number / next / prev / alternate / Переход по буферам
:bd                                              # Delete buffer / Закрыть буфер

# Folding — Сворачивание
za / zc / zo                                     # Toggle / close / open fold / Перекл./закр./откр. свёртку
:set foldmethod=indent | marker                  # By indent / markers / По отступам / по маркерам

# Quickfix & Grep — Окно результатов и поиск по файлам
:vimgrep /pat/ **/*.py                           # Grep into quickfix / Поиск в файлах (quickfix)
:make  |  :grep {pat} **/*                       # Fill quickfix via make/grep / Заполнить quickfix
:copen / :cnext / :cprev                         # Open / next / prev entry / Открыть / далее / назад

# Diff — Сравнение
:diffsplit {file}                                # Open diff split / Открыть сравнение
]c / [c                                          # Next/prev change / След./пред. изменение
do / dp                                          # Obtain/put change / Принять/внести изменение

# Netrw (file browser) — Файловый браузер
:Ex / :Sex / :Vex                                # Explore / split / vsplit / Проводник
:Lex                                             # Local explore / Локальный проводник

# External & Filters — Внешние команды и фильтры
:!{cmd}                                          # Run shell cmd / Команда оболочки
:r !{cmd} / :r {file}                            # Read cmd output / file / Вставить вывод / файл
:%!jq .                                          # Filter buffer through cmd / Прогнать буфер через команду

# Sessions & Workdirs — Сессии и каталоги
:mksession! sess.vim                             # Save session / Сохранить сессию
:source sess.vim                                 # Restore session / Загрузить сессию
:cd {path} / :lcd {path}                         # Change (local) dir / Сменить (локальный) каталог

# Indent & Whitespace — Отступы и пробелы
:set et sw=2 ts=2 sts=2                          # Spaces & widths / Пробелы и ширины табов
:retab                                           # Retab file / Пересчитать табы
:set list listchars=tab:▸\ ,trail:·              # Show invisibles / Показать невидимые символы

# Spell — Орфография
:setlocal spell spelllang=en,ru,it               # Enable spell / Включить проверку
]s / [s                                          # Next/prev misspell / След./пред. ошибка
z= / zg / zw                                     # Suggestions / add / mark wrong / Подсказки / добавить / ошибка

# QoL Options — Полезные опции
:set nu rnu                                      # Abs + relative numbers / Абс. + относ. номера
:set wrap linebreak                              # Soft wrap nicely / Мягкие переносы
:set cursorline cursorcolumn                     # Highlight line/column / Подсветка строки/колонки
:help {topic}                                    # Help / Справка



