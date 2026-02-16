Title: ✂️ SED — Commands
Group: Text & Parsing
Icon: ✂️
Order: 5

## Table of Contents
- [Basic Substitution](#-basic-substitution--базовая-замена)
- [Line Selection & Deletion](#-line-selection--deletion--выбор-и-удаление-строк)
- [In-Place Editing](#-in-place-editing--правка-на-месте)
- [Multiple Commands](#-multiple-commands--несколько-команд)
- [Advanced Patterns](#-advanced-patterns--продвинутые-шаблоны)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔀 Basic Substitution / Базовая замена
sed 's/foo/bar/' file                          # Replace first 'foo' per line / Заменить первое 'foo' в строке
sed 's/foo/bar/g' file                         # Replace all 'foo' per line / Заменить все 'foo' в строке
sed 's/foo/bar/2' file                         # Replace 2nd occurrence / Заменить второе вхождение
sed 's/foo/bar/gi' file                        # Case-insensitive global / Без учёта регистра (глобально)
sed 's/^/prefix: /' file                       # Add prefix to lines / Добавить префикс к строкам
sed 's/$/ suffix/' file                        # Add suffix to lines / Добавить суффикс к строкам
sed 's/  */ /g' file                           # Collapse multiple spaces / Схлопнуть множественные пробелы
sed 's/\t/ /g' file                            # Replace tabs with spaces / Заменить табы на пробелы

# 📑 Line Selection & Deletion / Выбор и удаление строк
sed -n '10,20p' file                           # Print only lines 10-20 / Печать только строк 10-20
sed -n '10p' file                              # Print line 10 / Печать строки 10
sed -n '1~2p' file                             # Print odd lines / Печать нечётных строк
sed -n '$p' file                               # Print last line / Печать последней строки
sed '5d' file                                  # Delete line 5 / Удалить строку 5
sed '10,20d' file                              # Delete lines 10-20 / Удалить строки 10-20
sed '/^#/d' file                               # Delete comment lines / Удалить строки с комментариями
sed '/^$/d' file                               # Delete empty lines / Удалить пустые строки
sed '/pattern/d' file                          # Delete lines matching pattern / Удалить совпадающие строки

# 💾 In-Place Editing / Правка на месте
sed -i 's/DEBUG=false/DEBUG=true/' .env        # In-place edit / Правка на месте
sed -i.bak 's/foo/bar/g' file                  # In-place with backup / С резервной копией
sed -i '' 's/old/new/g' file                   # macOS in-place / macOS правка на месте
sed -i '/^#/d' config.txt                      # Delete comments in-place / Удалить комментарии на месте

# 🔧 Multiple Commands / Несколько команд
sed -e 's/foo/bar/' -e 's/baz/qux/' file       # Multiple substitutions / Несколько замен
sed 's/foo/bar/; s/baz/qux/' file              # Semicolon-separated / Разделённые точкой с запятой
sed -n '10p; 20p; 30p' file                    # Print multiple lines / Вывести несколько строк
sed '1d; $d' file                              # Delete first and last / Удалить первую и последнюю

# 🎯 Advanced Patterns / Продвинутые шаблоны
sed -n 's/^ID=//p' /etc/os-release             # Extract value after ID= / Извлечь значение после ID=
sed -n '/^SERVER/s/.*=//p' config              # Extract server value / Извлечь значение сервера
sed '/start/,/end/d' file                      # Delete range / Удалить диапазон
sed '/pattern/!d' file                         # Keep only matching lines / Оставить только совпадения
sed 's/\(.*\):\(.*\)/\2:\1/' file              # Swap fields / Поменять поля местами
sed 's/^\s*//; s/\s*$//' file                  # Trim whitespace / Обрезать пробелы
sed -n '/ERROR/,+5p' file                      # Pattern + 5 lines / Шаблон + 5 строк
sed '0,/pattern/s//replacement/' file          # Replace first occurrence / Заменить первое вхождение

# 🌟 Real-World Examples / Примеры из практики
sed 's/192\.168\.1\./10.0.0./' hosts           # Change IP range / Сменить диапазон IP
sed -i 's/password=.*/password=<PASSWORD>/' config  # Sanitize config / Санитизировать конфиг
sed -n '/ERROR/p' app.log | wc -l              # Count errors / Подсчитать ошибки
sed '/^$/N; /^\n$/d' file                      # Remove consecutive blank lines / Удалить последовательные пустые строки
sed = file | sed 'N; s/\n/\t/'                 # Add line numbers / Добавить номера строк
sed 's/#.*$//' script.sh                       # Remove comments / Удалить комментарии
sed -n '/^FROM/p' Dockerfile                   # Extract FROM lines / Извлечь строки FROM
cat file | sed 's/^/    /'                     # Indent all lines / Сделать отступ для всех строк
sed 's/\b<IP>\b/<NEW_IP>/g' nginx.conf         # Replace placeholder / Заменить placeholder
sed -i 's/\r$//' file.txt                      # Remove Windows line endings / Удалить Windows окончания строк

# 📋 Extraction & Transformation / Извлечение и преобразование
sed -n 's/.*href="\([^"]*\)".*/\1/p' page.html  # Extract URLs / Извлечь URL
sed 's/\([0-9]\{3\}\)-\([0-9]\{4\}\)/(\1) \2/' file  # Format phone numbers / Форматировать телефоны
sed 's/./&\n/g' file                           # Add newline after each char / Добавить перевод строки после каждого символа
sed ':a;N;$!ba;s/\n/ /g' file                  # Join all lines / Соединить все строки
sed 's/\([^,]*\),\([^,]*\)/\2,\1/' file        # Swap CSV columns / Поменять столбцы CSV местами

# 🔬 Advanced Use Cases / Продвинутые случаи
sed -n '/BEGIN/,/END/p' file                   # Extract block / Извлечь блок
sed '/pattern/a\new line' file                 # Append after match / Добавить после совпадения
sed '/pattern/i\new line' file                 # Insert before match / Вставить перед совпадением
sed '/pattern/c\replacement line' file         # Change entire line / Заменить всю строку
sed 'y/abc/ABC/' file                          # Translate characters / Транслитерировать символы
sed -n 'n; p' file                             # Print even lines / Печать чётных строк
sed -n 'p; n' file                             # Print odd lines / Печать нечётных строк
sed '5q' file                                  # Quit after line 5 / Выход после строки 5
