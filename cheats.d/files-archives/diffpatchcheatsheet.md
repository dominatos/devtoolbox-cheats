Title: 🔁 diff / patch — File Comparison
Group: Files & Archives
Icon: 🔁
Order: 4

## Table of Contents
- [diff — Compare Files](#-diff--compare-files)
- [patch — Apply Changes](#-patch--apply-changes)
- [Directory Comparison](#-directory-comparison--сравнение-каталогов)
- [Git-Style Diffs](#-git-style-diffs--diff-в-стиле-git)
- [Advanced Usage](#-advanced-usage--продвинутое-использование)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔍 diff — Compare Files

### Basic Comparison / Базовое сравнение
```bash
diff file1.txt file2.txt                     # Compare two files / Сравнить два файла
diff -q file1.txt file2.txt                   # Brief (quiet) mode / Краткий режим
diff -s file1.txt file2.txt                   # Report identical files / Сообщить об идентичных файлах
diff -i file1.txt file2.txt                   # Ignore case / Игнорировать регистр
diff -w file1.txt file2.txt                   # Ignore whitespace / Игнорировать пробелы
diff -b file1.txt file2.txt                   # Ignore blank lines / Игнорировать пустые строки
```

### Output Formats / Форматы вывода
```bash
diff -u file1.txt file2.txt                   # Unified format (recommended) / Унифицированный формат (рекомендуется)
diff -c file1.txt file2.txt                   # Context format / Контекстный формат
diff -y file1.txt file2.txt                   # Side-by-side / Бок о бок
diff -y -W 200 file1.txt file2.txt            # Side-by-side wide / Бок о бок широко
diff --normal file1.txt file2.txt             # Normal format / Нормальный формат
```

### Save to Patch File / Сохранить в файл патча
```bash
diff -u old.conf new.conf > change.patch      # Create unified patch / Создать унифицированный патч
diff -Naur old/ new/ > changes.patch          # Recursive patch / Рекурсивный патч
diff -u file1.txt file2.txt | tee change.patch  # Save and display / Сохранить и показать
```

### Color Output / Цветной вывод
```bash
diff --color=always file1.txt file2.txt       # Colored diff / Цветной diff
diff --color=auto file1.txt file2.txt         # Auto color / Авто цвет
```

---

# 🔧 patch — Apply Changes

### Basic Patching / Базовое применение патчей
```bash
patch file.txt < change.patch                 # Apply patch / Применить патч
patch -p0 < change.patch                      # Apply at current level / Применить на текущем уровне
patch -p1 < change.patch                      # Strip one directory / Убрать один каталог
patch -p2 < change.patch                      # Strip two directories / Убрать два каталога
```

### Reverse & Test / Откат и тестирование
```bash
patch -R file.txt < change.patch              # Reverse patch / Откатить патч
patch --dry-run -p1 < change.patch            # Test without applying / Тест без применения
patch -b file.txt < change.patch              # Backup original / Резервная копия оригинала
patch -b -V numbered file.txt < change.patch  # Numbered backups / Нумерованные резервные копии
```

> [!TIP]
> Always use `--dry-run` before applying patches in production to verify they apply cleanly.
> Всегда используйте `--dry-run` перед применением патчей в продакшене.

### Interactive & Verbose / Интерактивный и подробный
```bash
patch -i change.patch                         # Read from file / Читать из файла
patch -v -p1 < change.patch                   # Verbose output / Подробный вывод
patch -f -p1 < change.patch                   # Force (skip prompts) / Принудительно (пропустить подтверждения)
```

### Directory Patching / Применение к каталогам
```bash
cd /path/to/project                           # Change to project / Перейти в проект
patch -p1 < /path/to/changes.patch            # Apply patch / Применить патч
```

---

# 📂 Directory Comparison / Сравнение каталогов

### Recursive Comparison / Рекурсивное сравнение
```bash
diff -r dir1/ dir2/                           # Recursive diff / Рекурсивный diff
diff -qr dir1/ dir2/                          # Brief recursive / Краткий рекурсивный
diff -ur dir1/ dir2/                          # Unified recursive / Унифицированный рекурсивный
diff -Naur dir1/ dir2/ > changes.patch        # Create patch / Создать патч
```

### Exclude Patterns / Исключить шаблоны
```bash
diff -r --exclude=".git" dir1/ dir2/          # Exclude .git / Исключить .git
diff -r --exclude="*.log" dir1/ dir2/         # Exclude log files / Исключить файлы логов
diff -r --exclude-from=exclude.txt dir1/ dir2/  # Exclude from file / Исключить из файла
```

### Only Show Differences / Только различия
```bash
diff -qrl dir1/ dir2/                         # List different files / Список различающихся файлов
diff -qr dir1/ dir2/ | grep "^Only in"        # Files only in one dir / Файлы только в одном каталоге
diff -qr dir1/ dir2/ | grep "differ$"         # Files that differ / Различающиеся файлы
```

---

# 🔀 Git-Style Diffs / Diff в стиле Git

### Git Diff Format / Формат Git diff
```bash
diff -u --label="old version" --label="new version" file1.txt file2.txt  # Custom labels / Пользовательские метки
git diff --no-index file1.txt file2.txt       # Git-style diff / Diff в стиле Git
git diff --no-index --color-words file1.txt file2.txt  # Word diff / Diff по словам
```

### Git Patch Creation / Создание патчей Git
```bash
git format-patch -1                           # Create patch from commit / Создать патч из коммита
git format-patch HEAD~3..HEAD                 # Patches from last 3 commits / Патчи из последних 3 коммитов
git diff > changes.patch                      # Working tree diff / Diff рабочего дерева
git diff --cached > staged.patch              # Staged changes / Staged изменения
```

### Apply Git Patches / Применение Git патчей
```bash
git apply changes.patch                       # Apply patch / Применить патч
git apply --check changes.patch               # Check if applicable / Проверить применимость
git apply --reject changes.patch              # Apply with reject files / Применить с reject файлами
git am < email.patch                          # Apply mail format / Применить формат почты
```

---

# 🔬 Advanced Usage / Продвинутое использование

### Ignore Specific Changes / Игнорировать конкретные изменения
```bash
diff -I "^#" file1.txt file2.txt              # Ignore lines starting with # / Игнорировать строки начинающиеся с #
diff -I ".*timestamp.*" file1.txt file2.txt   # Ignore lines with pattern / Игнорировать строки с шаблоном
diff -B file1.txt file2.txt                   # Ignore blank lines / Игнорировать пустые строки
diff -w -B file1.txt file2.txt                # Ignore whitespace and blank / Игнорировать пробелы и пустые
```

### Context Lines / Контекстные строки
```bash
diff -U 5 file1.txt file2.txt                 # 5 lines of context / 5 строк контекста
diff -U 0 file1.txt file2.txt                 # No context / Без контекста
diff -C 3 file1.txt file2.txt                 # 3 lines context format / 3 строки контекстного формата
```

### Binary Files / Бинарные файлы
```bash
diff --brief file1.bin file2.bin              # Binary comparison / Бинарное сравнение
cmp file1.bin file2.bin                       # Byte-by-byte comparison / Побайтовое сравнение
cmp -l file1.bin file2.bin                    # List all differences / Список всех различий
```

### Diff Statistics / Статистика diff
```bash
diff -u file1.txt file2.txt | diffstat        # Show statistics / Показать статистику
diff -u file1.txt file2.txt | wc -l           # Count diff lines / Подсчитать строки diff
```

---

# 🌟 Real-World Examples / Примеры из практики

### Compare Configuration Files / Сравнение файлов конфигурации
```bash
# Compare configs and create patch / Сравнить конфигурации и создать патч
diff -u /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf > nginx.patch

# Apply to another server / Применить на другом сервере
scp nginx.patch <USER>@<SERVER>:/tmp/
ssh <USER>@<SERVER> "cd /etc/nginx && sudo patch -p0 < /tmp/nginx.patch"
```

### Sync Directory Changes / Синхронизация изменений каталогов
```bash
# Create patch of all changes / Создать патч всех изменений
diff -Naur /var/www/old/ /var/www/new/ > website.patch

# Apply to production / Применить в продакшене
cd /var/www/html
patch -p1 < website.patch

# Verify / Проверить
patch --dry-run -p1 < website.patch
```

### Code Review Workflow / Процесс ревью кода
```bash
# Generate review patch / Генерировать патч для ревью
diff -Naur src.old/ src.new/ > review.patch

# Review changes / Проверить изменения
less review.patch
vim review.patch

# Apply if approved / Применить если одобрено
cd src.new/
patch -R -p1 < review.patch  # Reverse if needed / Откатить если нужно
```

### Migration Scripts / Скрипты миграции
```bash
# Compare database schemas / Сравнить схемы баз данных
diff -u schema.old.sql schema.new.sql > migration.patch

# Generate SQL migration / Генерировать SQL миграцию
diff -u schema.old.sql schema.new.sql | grep "^+" | sed 's/^+//' > migration.sql
```

### Security Audits / Аудит безопасности
```bash
# Check for unauthorized changes / Проверить несанкционированные изменения
diff -qr /etc.backup/ /etc/ | tee /var/log/config-audit.log

# Detailed diff of changed files / Подробный diff изменённых файлов
diff -ur /etc.backup/ /etc/ > /var/log/config-changes.patch
```

### Automated Testing / Автоматическое тестирование
```bash
# Compare test outputs / Сравнить выводы тестов
./test.sh > output.new
diff -u output.expected output.new
if [ $? -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi

# Regression testing / Регрессионное тестирование
diff -qr baselines/ results/ || echo "Regression detected"
```

### Documentation Updates / Обновления документации
```bash
# Track doc changes / Отслеживать изменения документации
diff -u README.md.old README.md > doc-updates.patch

# Generate changelog from diff / Генерировать changelog из diff
diff -u v1.0/ v2.0/ | grep "^+" | grep -v "^+++" > CHANGES.txt
```

### Backup Verification / Проверка резервных копий
```bash
# Verify backup integrity / Проверить целостность резервной копии
diff -qr /data/ /backup/data/ | tee backup-verification.log

# Find files missing in backup / Найти файлы отсутствующие в резервной копии
diff -qr /data/ /backup/data/ | grep "^Only in /data"
```

### Container Image Layers / Слои образов контейнеров
```bash
# Compare Dockerfiles / Сравнить Dockerfiles
diff -u Dockerfile.old Dockerfile.new > docker.patch

# Compare container filesystems / Сравнить файловые системы контейнеров
docker export container1 | tar -x -C /tmp/c1
docker export container2 | tar -x -C /tmp/c2
diff -qr /tmp/c1 /tmp/c2
```

### Multi-Server Consistency / Согласованность между серверами
```bash
# Check config consistency / Проверить согласованность конфигурации
for server in server1 server2 server3; do
  ssh $server "cat /etc/app/config.yml" > config.$server
done
diff -u config.server1 config.server2
diff -u config.server1 config.server3
```

---

# 💡 Best Practices / Лучшие практики

- Always use `-u` for unified format / Всегда используйте `-u` для унифицированного формата
- Test patches with `--dry-run` / Тестируйте патчи с `--dry-run`
- Backup files before patching / Делайте резервные копии перед применением патчей
- Use `-p1` for most patch applications / Используйте `-p1` для большинства применений патчей
- Exclude version control dirs (`.git`, `.svn`) / Исключайте каталоги контроля версий
- Document patches with descriptive names / Документируйте патчи описательными именами

## Useful diff Options / Полезные опции diff

| Option | Description (EN / RU) |
|--------|----------------------|
| `-u` | Unified format (most readable) / Унифицированный формат |
| `-r` | Recursive / Рекурсивно |
| `-N` | Treat absent files as empty / Рассматривать отсутствующие как пустые |
| `-a` | Treat all files as text / Рассматривать все как текст |
| `-q` | Brief output / Краткий вывод |
| `-i` | Ignore case / Игнорировать регистр |
| `-w` | Ignore whitespace / Игнорировать пробелы |

## Patch Levels / Уровни патчей

| Level | Description (EN / RU) |
|-------|----------------------|
| `-p0` | Apply at current directory / Применить в текущей директории |
| `-p1` | Strip top-level directory (most common) / Убрать верхний каталог |
| `-p2` | Strip two levels / Убрать два уровня |

## Alternative Tools / Альтернативные инструменты

| Tool | Description (EN / RU) |
|------|----------------------|
| `vimdiff` | Visual diff editor / Визуальный diff редактор |
| `meld` | GUI diff tool / GUI инструмент diff |
| `kompare` | KDE diff tool / KDE инструмент diff |
| `colordiff` | Colored diff / Цветной diff |
