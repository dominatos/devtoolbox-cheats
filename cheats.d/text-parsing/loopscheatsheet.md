Title: 🌀 Bash — Loops
Group: Text & Parsing
Icon: 🌀
Order: 12

# FOR over files / Перебор файлов
for f in *.log; do : > "$f"; done        # Truncate all .log files / Очистить все .log файлы
for f in *.{yml,yaml}; do echo "$f"; done # Multiple globs / Несколько расширений

# FOR over numbers / Перебор чисел
for i in {1..5}; do echo $i; done        # 1..5 (brace expansion) / Диапазон в фигурных скобках
for ((i=1;i<=5;i++)); do echo $i; done   # C-style loop / Цикл в стиле C

# WHILE / Пока условие выполняется
i=1; while [ $i -le 5 ]; do echo $i; ((i++)); done  # Counter loop / Счётчик до 5
while read -r line; do echo "$line"; done < file    # Read file lines / Чтение файла построчно

# UNTIL / Пока условие НЕ выполняется
i=1; until [ $i -gt 5 ]; do echo $i; ((i++)); done  # Run until condition true / Выполнять пока условие ЛОЖНО

# Infinite with sleep / Бесконечный цикл с паузой
while :; do date; sleep 5; done          # Tick every 5s / Печать даты каждые 5 секунд

# Safe pipeline read (no subshell var loss) / Без потери переменных в пайплайне
while IFS= read -r f; do echo "$f"; done < <(ls -1) # Process substitution / Подстановка через < <(...)

