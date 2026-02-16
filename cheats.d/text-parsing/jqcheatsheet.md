Title: 🧩 JQ — Commands
Group: Text & Parsing
Icon: 🧩
Order: 9

## Table of Contents
- [Basics](#-basics--основы)
- [Selecting & Filtering](#-selecting--filtering--выбор-и-фильтрация)
- [Transforming Data](#-transforming-data--преобразование-данных)
- [Arrays & Objects](#-arrays--objects--массивы-и-объекты)
- [Aggregation & Math](#-aggregation--math--агрегация-и-математика)
- [Advanced Queries](#-advanced-queries--продвинутые-запросы)
- [Output Formatting](#-output-formatting--форматирование-вывода)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📖 Basics / Основы
jq '.' file.json                               # Pretty-print JSON / Красивый вывод JSON
jq '.' < file.json                             # Read from stdin / Читать из stdin
echo '{"key":"value"}' | jq '.'                # Pipe JSON / JSON через pipe
jq '.key' file.json                            # Extract single key / Извлечь один ключ
jq '.user.name' file.json                      # Nested key / Вложенный ключ
jq '.items[0]' file.json                       # First array element / Первый элемент массива
jq '.items[-1]' file.json                      # Last array element / Последний элемент
jq '.items[2:5]' file.json                     # Array slice / Срез массива

# 🔍 Selecting & Filtering / Выбор и фильтрация
jq '.items[]' file.json                        # Iterate array elements / Перебрать элементы
jq '.items[] | .name' file.json                # Extract field from each / Извлечь поле из каждого
jq -r '.items[].name' file.json                # Raw output (no quotes) / Сырой вывод (без кавычек)
jq '.items[] | select(.active)' file.json      # Filter by boolean / Фильтр по булеву значению
jq '.items[] | select(.price > 100)' file.json # Filter by value / Фильтр по значению
jq '.items[] | select(.name == "Alice")' file.json  # Exact match / Точное совпадение
jq '.items[] | select(.name | contains("test"))' file.json  # Contains filter / Фильтр по вхождению
jq '.items[] | select(.tags | contains(["prod"]))' file.json  # Array contains / Массив содержит
jq '.items[] | select(.status != "deleted")' file.json  # Not equal / Не равно

# 🔄 Transforming Data / Преобразование данных
jq '.items[] | {id, email}' file.json          # Pick specific fields / Выбрать конкретные поля
jq '.items[] | {name: .user, value: .price}' file.json  # Rename fields / Переименовать поля
jq '.items | map(.name)' file.json             # Map array / Преобразовать массив
jq '.items | map({name, price})' file.json     # Map to objects / Преобразовать в объекты
jq '.user | {name, age: (.age | tostring)}' file.json  # Type conversion / Преобразование типов
jq '(.items[] | select(.id == 42)).name = "Alice"' file.json  # Update field / Обновить поле
jq '.items[] | .price *= 1.1' file.json        # Modify values / Изменить значения
jq 'del(.password)' file.json                  # Delete field / Удалить поле
jq '.items[] | if .active then .status = "live" else .status = "paused" end' file.json  # Conditional / Условие

# 📊 Arrays & Objects / Массивы и объекты
jq '.items | length' file.json                 # Array length / Длина массива
jq '.items | add' file.json                    # Sum array elements / Сумма элементов
jq '.items | unique' file.json                 # Remove duplicates / Удалить дубликаты
jq '.items | sort_by(.price)' file.json        # Sort by field / Сортировать по полю
jq '.items | reverse' file.json                # Reverse array / Обратный порядок
jq '.items | group_by(.category)' file.json    # Group by field / Группировать по полю
jq '.items | flatten' file.json                # Flatten nested arrays / Развернуть вложенные массивы
jq '.items | first' file.json                  # First element / Первый элемент
jq '.items | last' file.json                   # Last element / Последний элемент
jq '{name, age} + {email}' file.json           # Merge objects / Объединить объекты
jq '.items | keys' file.json                   # Object keys / Ключи объекта
jq '.items | values' file.json                 # Object values / Значения объекта

# 🧮 Aggregation & Math / Агрегация и математика
jq '[.items[].price] | add' file.json          # Sum prices / Сумма цен
jq '[.items[].price] | add / length' file.json # Average / Среднее значение
jq '[.items[].price] | max' file.json          # Maximum value / Максимальное значение
jq '[.items[].price] | min' file.json          # Minimum value / Минимальное значение
jq '.items | map(.price) | add' file.json      # Map and sum / Преобразовать и сложить
jq 'group_by(.status) | map({status: .[0].status, count: length})' file.json  # Group & count / Группировка и подсчёт
jq '.items | map(select(.active)) | length' file.json  # Count filtered / Подсчитать отфильтрованные
jq '.items[] | .total = (.price * .quantity)' file.json  # Calculate field / Вычислить поле

# 🔬 Advanced Queries / Продвинутые запросы
jq '.items[] | select(.tags[] | contains("prod"))' file.json  # Filter nested arrays / Фильтр вложенных массивов
jq '.items | map(select(.price > 100)) | sort_by(.price) | .[0:5]' file.json  # Complex pipeline / Сложный конвейер
jq '.items | unique_by(.category)' file.json   # Unique by field / Уникальные по полю
jq '.items[] | select(.created | fromdateiso8601 > now - 86400)' file.json  # Date filter / Фильтр по дате
jq '.items | INDEX(.id)' file.json             # Convert to object by ID / Конвертировать в объект по ID
jq '.items[] | .tags | @csv' file.json         # Convert to CSV / Конвертировать в CSV
jq 'reduce .items[] as $item (0; . + $item.price)' file.json  # Reduce operation / Операция reduce
jq '.items[] | select(.tags | any(. == "prod"))' file.json  # Any match / Любое совпадение
jq '.items[] | select(.tags | all(. != "test"))' file.json  # All match / Все совпадают
jq 'paths(type == "number")' file.json         # Find all number paths / Найти все пути к числам

# 📤 Output Formatting / Форматирование вывода
jq -r '.items[] | "\(.name): \(.price)"' file.json  # Custom string format / Произвольный формат строки
jq -r '.items[] | @csv' file.json              # CSV output / Вывод CSV
jq -r '.items[] | @tsv' file.json              # TSV output / Вывод TSV
jq -r '.items[] | @json' file.json             # JSON output / Вывод JSON
jq -r '.items[] | @base64' file.json           # Base64 encoding / Кодирование Base64
jq -r '.items[] | @uri' file.json              # URL encoding / URL кодирование
jq -c '.items[]' file.json                     # Compact output (no newlines) / Компактный вывод
jq -S '.' file.json                            # Sort keys / Сортировать ключи
jq --tab '.' file.json                         # Tab indentation / Отступы табуляцией
jq -r '.items[] | [.id, .name, .price] | @tsv' file.json  # Array to TSV / Массив в TSV

# 🌟 Real-World Examples / Примеры из практики
curl -s https://api.example.com/users | jq '.[] | {id, email}'  # API response filter / Фильтр API ответа
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'  # Kubernetes pods / Kubernetes поды
jq -r '.users[] | select(.active) | "\(.id),\(.email)"' users.json > active.csv  # Export to CSV / Экспорт в CSV
docker inspect <CONTAINER> | jq '.[0].NetworkSettings.IPAddress'  # Docker IP / IP контейнера Docker
curl -s https://api.github.com/repos/<USER>/<REPO>/releases/latest | jq -r '.tag_name'  # GitHub latest release / Последний релиз GitHub
jq -s '.[0] * .[1]' file1.json file2.json      # Merge two JSON files / Объединить два JSON файла
jq -r '.items[] | select(.price > 100) | @csv' products.json  # Filter and export / Фильтр и экспорт
cat access.log | jq -s 'group_by(.status) | map({status: .[0].status, count: length})'  # Log analysis / Анализ логов
jq '.services[] | select(.health == "unhealthy") | .name' status.json  # Find unhealthy services / Найти нездоровые сервисы
echo '{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}' | jq '.users | sort_by(.age) | .[0].name'  # Youngest user / Самый молодой пользователь

# 💡 Advanced Techniques / Продвинутые техники
jq -n --arg name "Alice" --arg email "alice@example.com" '{name: $name, email: $email}'  # Build JSON from args / Создать JSON из аргументов
jq -n --argjson data '{"key":"value"}' '$data'  # Pass JSON as argument / Передать JSON как аргумент
jq --slurpfile data other.json '{main: ., imported: $data}' file.json  # Import external JSON / Импортировать внешний JSON
jq -r 'to_entries | .[] | "\(.key)=\(.value)"' config.json  # Convert to key=value / Конвертировать в key=value
jq 'walk(if type == "string" then gsub("<IP>"; "<NEW_IP>") else . end)' file.json  # Replace all strings / Заменить все строки
jq 'limit(5; .items[])' file.json              # Limit output / Ограничить вывод
jq -e '.status == "success"' file.json         # Exit code based on condition / Код выхода по условию
jq '.. | numbers'                              # All numbers in JSON / Все числа в JSON
jq '.. | strings | select(startswith("http"))' file.json  # Find all URLs / Найти все URL
jq -c '.[]' file.json | parallel -j 4 'process {}'  # Parallel processing / Параллельная обработка

# 🔧 Troubleshooting / Устранение неполадок
jq --version                                   # Check version / Проверить версию
jq -e '.' file.json; echo $?                   # Validate JSON syntax / Проверить синтаксис JSON
jq 'type' file.json                            # Check data type / Проверить тип данных
jq 'keys' file.json                            # List all keys / Список всех ключей
jq 'paths' file.json                           # Show all paths / Показать все пути
