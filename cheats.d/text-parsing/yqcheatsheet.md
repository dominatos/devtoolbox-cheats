Title: 🧪 yq — YAML processor
Group: Text & Parsing
Icon: 🧪
Order: 8

> **yq** — a portable, lightweight YAML/JSON/XML/CSV/TSV processor written in Go by Mike Farah. It uses jq-like syntax for querying, modifying, and converting structured data. Heavily used in Kubernetes/Helm workflows, CI/CD pipelines, and infrastructure-as-code. Actively maintained with frequent releases. Note: there are two tools named `yq` — this cheatsheet covers the Go version ([mikefarah/yq](https://github.com/mikefarah/yq)), not the Python wrapper ([kislyuk/yq](https://github.com/kislyuk/yq)).

## Table of Contents
- [Basics](#Basics%20/%20Основы)
- [Reading & Querying](#Reading%20&%20Querying%20/%20Чтение%20и%20запросы)
- [Modifying YAML](#️%20Modifying%20YAML%20/%20Изменение%20YAML)
- [Arrays & Objects](#Arrays%20&%20Objects%20/%20Массивы%20и%20объекты)
- [Output Formats](#Output%20Formats%20/%20Форматы%20вывода)
- [Merging & Combining](#Merging%20&%20Combining%20/%20Слияние%20и%20комбинирование)
- [Kubernetes Examples](#️%20Kubernetes%20Examples%20/%20Примеры%20Kubernetes)
- [Real-World Examples](#Real-World%20Examples%20/%20Примеры%20из%20практики)
- [Data Transformation](#Data%20Transformation%20/%20Преобразование%20данных)
- [Advanced Techniques](#Advanced%20Techniques%20/%20Продвинутые%20техники)
- [Tips & Tricks](#Tips%20&%20Tricks%20/%20Советы%20и%20хитрости)
- [Validation & Debugging](#Validation%20&%20Debugging%20/%20Проверка%20и%20отладка)
- [Installation](#️%20Installation%20/%20Установка)

---

## 📖 Basics / Основы

```bash
yq '.' file.yaml                               # Pretty-print YAML / Красивый вывод YAML
yq eval '.' file.yaml                          # Explicit eval / Явный eval
yq '.key' file.yaml                            # Read single key / Прочитать один ключ
yq '.parent.child' file.yaml                   # Nested key / Вложенный ключ
yq '.items[0]' file.yaml                       # First array element / Первый элемент массива
yq '.items[-1]' file.yaml                      # Last array element / Последний элемент
yq -e '.key' file.yaml                         # Exit non-zero if not found / Код выхода если не найдено
```

---

## 🔍 Reading & Querying / Чтение и запросы

```bash
yq '.spec.replicas' deploy.yaml                # Read field / Прочитать поле
yq '.metadata.name' pod.yaml                   # Get resource name / Получить имя ресурса
yq '.items[].metadata.name' list.yaml          # List all names / Список всех имён
yq '.spec.containers[].image' deploy.yaml      # All container images / Все образы контейнеров
yq 'select(.kind == "Deployment")' file.yaml   # Filter by condition / Фильтр по условию
yq '.items[] | select(.metadata.name == "nginx")' list.yaml  # Find by name / Найти по имени
yq '.spec.containers[] | select(.name == "app")' deploy.yaml  # Filter containers / Фильтр контейнеров
yq 'length' file.yaml                          # Count items / Подсчитать элементы
yq '.items | length' list.yaml                 # Array length / Длина массива
yq 'keys' file.yaml                            # All keys / Все ключи
```

---

## ✏️ Modifying YAML / Изменение YAML

> [!WARNING]
> The `-i` flag modifies files in-place. Always keep backups or use version control before bulk modifications.
> Флаг `-i` модифицирует файлы на месте. Всегда делайте бэкапы или используйте контроль версий перед массовыми изменениями.

```bash
yq '.spec.replicas = 3' -i deploy.yaml         # In-place edit / Правка на месте
yq '(.spec.replicas) = 3' -i deploy.yaml       # Parentheses syntax / Синтаксис со скобками
yq '.metadata.labels.env = "prod"' -i file.yaml  # Set label / Установить метку
yq '(.spec.containers[].image) = "app:v2"' -i deploy.yaml  # Update all images / Обновить все образы
yq 'del(.metadata.annotations)' -i file.yaml   # Delete field / Удалить поле
yq 'del(.spec.containers[0])' -i file.yaml     # Delete array element / Удалить элемент массива
yq '.metadata.annotations."example.com/key" = "value"' -i file.yaml  # Key with dots / Ключ с точками
```

---

## 📊 Arrays & Objects / Массивы и объекты

```bash
yq '.items[]' list.yaml                        # Iterate array / Перебрать массив
yq '.items[0:2]' list.yaml                     # Array slice / Срез массива
yq '.items += {"name": "new"}' -i file.yaml    # Append to array / Добавить в массив
yq '.items = .items + [{"name": "new"}]' -i file.yaml  # Alternative append / Альтернативное добавление
yq 'sort_by(.metadata.name)' list.yaml         # Sort by field / Сортировать по полю
yq 'unique_by(.kind)' file.yaml                # Unique by field / Уникальные по полю
yq 'group_by(.kind)' file.yaml                 # Group by field / Группировать по полю
yq 'with(.spec.containers[]; .resources.limits.memory = "256Mi")' -i deploy.yaml  # Modify blocks / Модифицировать блоки
yq '.spec.template.spec.containers[].env += [{"name": "DEBUG", "value": "true"}]' -i deploy.yaml  # Add env var / Добавить переменную окружения
```

---

## 📤 Output Formats / Форматы вывода

```bash
yq -o=json '.' file.yaml                       # Convert to JSON / Конвертировать в JSON
yq -o=json '.items[] | {name: .metadata.name, ns: .metadata.namespace}' list.yaml  # JSON objects / JSON объекты
yq -o=props '.' file.yaml                      # Convert to properties / Конвертировать в properties
yq -o=csv '.' file.yaml                        # Convert to CSV / Конвертировать в CSV
yq -o=tsv '.' file.yaml                        # Convert to TSV / Конвертировать в TSV
yq -o=xml '.' file.yaml                        # Convert to XML / Конвертировать в XML
yq -P '.' file.json                            # JSON to YAML / JSON в YAML
yq -p=xml '.' file.xml                         # XML to YAML / XML в YAML
```

---

## 🔗 Merging & Combining / Слияние и комбинирование

```bash
yq ea '. as $item ireduce ({}; . *+ $item)' a.yaml b.yaml > merged.yaml  # Merge YAML files / Слить YAML-файлы
yq eval-all '. as $item ireduce ({}; . * $item)' file1.yaml file2.yaml  # Deep merge / Глубокое слияние
yq ea 'select(fi == 0)' file1.yaml file2.yaml  # Get first file / Получить первый файл
yq ea 'select(fi == 1)' file1.yaml file2.yaml  # Get second file / Получить второй файл
yq ea '[.]' file1.yaml file2.yaml              # Combine into array / Объединить в массив
yq ea '. as $item ireduce ([]; . + $item)' *.yaml  # Merge multiple files / Слить несколько файлов
```

---

## ☸️ Kubernetes Examples / Примеры Kubernetes

```bash
yq '.spec.replicas' deployment.yaml            # Get replica count / Получить количество реплик
yq '.spec.template.spec.containers[].image' deployment.yaml  # All images / Все образы
yq '.metadata.labels' pod.yaml                 # Get labels / Получить метки
yq '.metadata.annotations["deployment.kubernetes.io/revision"]' deployment.yaml  # Get annotation / Получить аннотацию
yq '(.spec.template.spec.containers[] | select(.name == "app")).image = "app:v2"' -i deployment.yaml  # Update specific container / Обновить конкретный контейнер
yq '.spec.template.spec.containers[].resources.limits.memory = "512Mi"' -i deployment.yaml  # Set memory limit / Установить лимит памяти
yq 'del(.spec.template.spec.containers[].resources.requests)' -i deployment.yaml  # Remove requests / Удалить requests
kubectl get pods -o yaml | yq '.items[] | select(.status.phase != "Running") | .metadata.name'  # Non-running pods / Неработающие поды
```

---

## 🌟 Real-World Examples / Примеры из практики

```bash
yq '.spec.replicas = 5' -i */deployment.yaml   # Update all deployments / Обновить все развёртывания
yq '(.spec.template.spec.containers[].image) |= sub("v1", "v2")' -i deployment.yaml  # Replace in image tag / Заменить в теге образа
yq '.metadata.labels.environment = "production"' -i *.yaml  # Add label to all / Добавить метку ко всем
yq -o=json '.items[] | {name: .metadata.name, image: .spec.containers[0].image}' pods.yaml  # Extract pod info / Извлечь информацию о подах
yq '.spec.template.spec.nodeSelector."kubernetes.io/hostname" = "<NODE>"' -i deployment.yaml  # Set node selector / Установить селектор узла
yq 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .status)' -i resource.yaml  # Clean metadata / Очистить метаданные
find . -name "*.yaml" -exec yq '.spec.replicas = 3' -i {} \;  # Batch update / Пакетное обновление
yq ea 'select(.kind == "Service")' *.yaml      # Filter all services / Отфильтровать все сервисы
```

---

## 🔄 Data Transformation / Преобразование данных

```bash
yq '.items[] | {"name": .metadata.name, "ns": .metadata.namespace}' list.yaml  # Reshape objects / Изменить форму объектов
yq '[.items[] | select(.kind == "Deployment") | .metadata.name]' file.yaml  # Extract to array / Извлечь в массив
yq '.items | map(select(.status.phase == "Running"))' pods.yaml  # Filter and map / Фильтр и преобразование
yq 'to_entries | map(select(.value > 100))' file.yaml  # Convert to entries / Конвертировать в entries
yq 'with_entries(select(.value != null))' file.yaml  # Remove null values / Удалить null значения
```

---

## 💡 Advanced Techniques / Продвинутые техники

```bash
yq -n '.name = "example" | .version = "1.0"'   # Create YAML from scratch / Создать YAML с нуля
yq --from-file script.yq file.yaml             # Execute yq script / Выполнить yq скрипт
yq 'explode(.)' file.yaml                      # Expand anchors / Развернуть якоря
yq '... comments=""' file.yaml                 # Remove all comments / Удалить все комментарии
yq '. as $root | .items[] | select(.metadata.name == $root.config.name)' file.yaml  # Use variables / Использовать переменные
yq '(.. | select(tag == "!!str")) |= sub("<IP>", "<NEW_IP>")' -i file.yaml  # Replace all strings / Заменить все строки
yq 'walk(if type == "string" then gsub("old"; "new") else . end)' file.yaml  # Walk and replace / Обход и замена
```

---

## 🔧 Tips & Tricks / Советы и хитрости

```bash
yq --version                                   # Check version / Проверить версию
yq -C '.' file.yaml                            # Colorized output / Цветной вывод
yq --unwrapScalar '.' file.yaml                # Output scalar without quotes / Вывод скаляра без кавычек
yq -r '.items[].name' file.yaml                # Raw string output / Сырой строковый вывод
yq --indent 4 '.' file.yaml                    # Custom indentation / Произвольный отступ
yq -I=4 '.' file.yaml                          # Short indent flag / Короткий флаг отступа
yq -M '.' file.yaml                            # No colors / Без цветов
yq --exit-status '.key' file.yaml || echo "Key not found"  # Check existence / Проверить существование
```

---

## 🔍 Validation & Debugging / Проверка и отладка

```bash
yq eval '.' file.yaml > /dev/null              # Validate YAML syntax / Проверить синтаксис YAML
yq 'explode(.) | keys' file.yaml               # Show all keys / Показать все ключи
yq '.. | select(type == "!!null")' file.yaml   # Find null values / Найти null значения
yq 'path(..)' file.yaml                        # Show all paths / Показать все пути
```

---

## ⚙️ Installation / Установка

```bash
# Ubuntu/Debian (snap)
sudo snap install yq

# Fedora
sudo dnf install yq

# Arch (AUR)
yay -S yq-bin

# macOS
brew install yq

# Binary (latest, any Linux)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Check version / Проверить версию
yq --version
```

> [!NOTE]
> Make sure you have the Go version (`mikefarah/yq`) and not the Python wrapper (`kislyuk/yq`). Check with `yq --version` — the Go version outputs `yq (https://github.com/mikefarah/yq/) version v4.x.x`.

---

## 📚 Documentation / Документация

- [yq — GitHub repository](https://github.com/mikefarah/yq)
- [yq Operators Reference](https://mikefarah.gitbook.io/yq/operators)
- [yq Usage Guide](https://mikefarah.gitbook.io/yq/)
- `yq --help`

#text-parsing #linux #sysadmin
