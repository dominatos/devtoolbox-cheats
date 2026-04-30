Title: 🔁 diff / patch — File Comparison
Group: Files & Archives
Icon: 🔁
Order: 4

## Description

**diff** and **patch** are fundamental UNIX utilities for comparing files and applying changes. `diff` computes the differences between two files or directories and outputs them in various formats. `patch` reads a diff output (a "patch file") and applies those changes to the original file.

**Что это:** `diff` и `patch` — базовые UNIX-утилиты для сравнения файлов и применения изменений. `diff` вычисляет различия между двумя файлами или каталогами. `patch` читает вывод diff ("файл патча") и применяет эти изменения к оригиналу.

**Common use cases / Типичные случаи использования:**
- Code review and collaborative development / Ревью кода и совместная разработка
- Configuration management across servers / Управление конфигурацией между серверами
- Security auditing (detecting unauthorized changes) / Аудит безопасности (обнаружение несанкционированных изменений)
- Software distribution via patches / Распространение ПО через патчи
- Backup verification / Проверка резервных копий

**Status / Статус:** ✅ Actively maintained, universally available on all UNIX/Linux systems. Part of POSIX standard. No modern replacement needed — `diff` and `patch` remain the foundation for version control and change management.

---

## Table of Contents
- [Installation](#installation)
- [diff — Compare Files](#diff--compare-files)
- [patch — Apply Changes](#patch--apply-changes)
- [Directory Comparison](#directory-comparison)
- [Git-Style Diffs](#git-style-diffs)
- [Advanced Usage](#advanced-usage)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)
- [Documentation Links](#documentation-links)

---

## Installation

### Install diff & patch / Установка diff и patch

> [!NOTE]
> `diff` and `patch` are part of GNU diffutils and are pre-installed on virtually all Linux distributions.
> `diff` и `patch` входят в состав GNU diffutils и предустановлены практически во всех дистрибутивах Linux.

```bash
# Verify installation / Проверить установку
diff --version                                 # Show diff version / Версия diff
patch --version                                # Show patch version / Версия patch

# Install if missing / Установить если отсутствует
sudo apt install diffutils patch               # Debian/Ubuntu
sudo dnf install diffutils patch               # RHEL/Fedora
sudo pacman -S diffutils patch                 # Arch Linux
```

### Install Enhanced Tools / Установка улучшенных инструментов
```bash
sudo apt install colordiff diffstat            # Colored diff + statistics / Цветной diff + статистика
sudo apt install meld                          # GUI diff/merge tool / GUI инструмент diff/merge
sudo apt install wdiff                         # Word-level diff / Diff на уровне слов
```

---

## diff — Compare Files

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

The unified format (`-u`) is the most widely used and recommended for patches and code review. Context format (`-c`) provides more surrounding context. Side-by-side (`-y`) is best for visual comparison in a terminal.

Унифицированный формат (`-u`) — самый распространённый и рекомендуемый для патчей и ревью кода. Контекстный формат (`-c`) предоставляет больше окружающего контекста. Бок о бок (`-y`) лучше всего подходит для визуального сравнения в терминале.

```bash
diff -u file1.txt file2.txt                   # Unified format (recommended) / Унифицированный формат (рекомендуется)
diff -c file1.txt file2.txt                   # Context format / Контекстный формат
diff -y file1.txt file2.txt                   # Side-by-side / Бок о бок
diff -y -W 200 file1.txt file2.txt            # Side-by-side wide / Бок о бок широко
diff --normal file1.txt file2.txt             # Normal format / Нормальный формат
```

### Output Format Comparison / Сравнение форматов вывода

| Format | Flag | Description (EN / RU) | Best For / Лучше для |
|--------|------|-----------------------|----------------------|
| Unified | `-u` | Shows `+`/`-` with context lines / Показывает `+`/`-` с контекстом | Patches, code review / Патчи, ревью кода |
| Context | `-c` | Extended context with `!` markers / Расширенный контекст с маркерами `!` | Detailed review / Детальный обзор |
| Side-by-side | `-y` | Two columns / Два столбца | Visual comparison / Визуальное сравнение |
| Normal | (default) | Line ranges with `<`/`>` / Диапазоны строк с `<`/`>` | Scripts, legacy tools / Скрипты, устаревшие инструменты |
| Brief | `-q` | Only reports if files differ / Только сообщает о различиях | Quick checks / Быстрая проверка |

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
colordiff file1.txt file2.txt                 # Using colordiff (requires package) / С помощью colordiff
```

---

## patch — Apply Changes

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

> [!WARNING]
> Applying patches without backup (`-b`) in production can make rollback difficult if the patch fails partially.
> Применение патчей без резервной копии (`-b`) в продакшене может затруднить откат при частичном сбое.

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

### Patch Strip Level Explanation / Объяснение уровней strip патча

The `-pN` flag strips `N` leading path components from file paths in the patch. This is critical when the patch was generated in a different directory context.

Флаг `-pN` убирает `N` начальных компонентов пути из путей файлов в патче. Это критически важно когда патч был сгенерирован в другом контексте каталогов.

| Level | Description (EN / RU) | Example / Пример |
|-------|----------------------|-------------------|
| `-p0` | Apply at current directory / Применить в текущей директории | `a/src/file.c` → `a/src/file.c` |
| `-p1` | Strip top-level directory (most common) / Убрать верхний каталог | `a/src/file.c` → `src/file.c` |
| `-p2` | Strip two levels / Убрать два уровня | `a/src/file.c` → `file.c` |

---

## Directory Comparison

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

## Git-Style Diffs

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

## Advanced Usage

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
xxd file1.bin > /tmp/hex1.txt && xxd file2.bin > /tmp/hex2.txt && diff /tmp/hex1.txt /tmp/hex2.txt  # Hex diff / Hex сравнение
```

### Diff Statistics / Статистика diff
```bash
diff -u file1.txt file2.txt | diffstat        # Show statistics / Показать статистику
diff -u file1.txt file2.txt | wc -l           # Count diff lines / Подсчитать строки diff
```

---

## Real-World Examples

### Compare Configuration Files / Сравнение файлов конфигурации
```bash
# Compare configs and create patch / Сравнить конфигурации и создать патч
diff -u /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf > nginx.patch

# Apply to another server / Применить на другом сервере
scp nginx.patch <USER>@<HOST>:/tmp/
ssh <USER>@<HOST> "cd /etc/nginx && sudo patch -p0 < /tmp/nginx.patch"
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

> [!CAUTION]
> Always test patches on staging before applying to production web directories. A broken patch can cause website downtime.
> Всегда тестируйте патчи на staging перед применением к продакшен веб-каталогам. Сломанный патч может вызвать простой сайта.

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
for server in <HOST1> <HOST2> <HOST3>; do
  ssh <USER>@$server "cat /etc/app/config.yml" > config.$server
done
diff -u config.<HOST1> config.<HOST2>
diff -u config.<HOST1> config.<HOST3>
```

---

## Best Practices

### General Recommendations / Общие рекомендации

- Always use `-u` for unified format — it's the standard for patches / Всегда используйте `-u` для унифицированного формата
- Test patches with `--dry-run` before applying / Тестируйте патчи с `--dry-run` перед применением
- Backup files before patching (`patch -b`) / Делайте резервные копии перед применением патчей
- Use `-p1` for most patch applications / Используйте `-p1` для большинства применений патчей
- Exclude version control dirs (`.git`, `.svn`) / Исключайте каталоги контроля версий
- Document patches with descriptive names / Документируйте патчи описательными именами

### Useful diff Options / Полезные опции diff

| Option | Description (EN / RU) |
|--------|----------------------|
| `-u` | Unified format (most readable) / Унифицированный формат |
| `-r` | Recursive / Рекурсивно |
| `-N` | Treat absent files as empty / Рассматривать отсутствующие как пустые |
| `-a` | Treat all files as text / Рассматривать все как текст |
| `-q` | Brief output / Краткий вывод |
| `-i` | Ignore case / Игнорировать регистр |
| `-w` | Ignore whitespace / Игнорировать пробелы |

### Alternative Tools / Альтернативные инструменты

| Tool | Description (EN / RU) | Use Case / Применение |
|------|----------------------|----------------------|
| `vimdiff` | Visual diff editor / Визуальный diff редактор | Terminal-based merge / Слияние в терминале |
| `meld` | GUI diff tool / GUI инструмент diff | Visual file/dir comparison / Визуальное сравнение файлов |
| `kompare` | KDE diff tool / KDE инструмент diff | KDE desktop integration / Интеграция с KDE |
| `colordiff` | Colored diff / Цветной diff | Better terminal readability / Читаемость в терминале |
| `delta` | Modern diff viewer / Современный просмотрщик diff | Git pager, syntax highlighting / Git pager, подсветка синтаксиса |
| `difftastic` | Structural diff / Структурный diff | Language-aware comparison / Сравнение с учётом языка |
| `wdiff` | Word-level diff / Diff по словам | Document comparison / Сравнение документов |

---

## Documentation Links

- **GNU Diffutils Manual:** https://www.gnu.org/software/diffutils/manual/
- **diff man page:** `man diff` or https://man7.org/linux/man-pages/man1/diff.1.html
- **patch man page:** `man patch` or https://man7.org/linux/man-pages/man1/patch.1.html
- **cmp man page:** `man cmp` or https://man7.org/linux/man-pages/man1/cmp.1.html
- **GNU Diffutils source:** https://savannah.gnu.org/projects/diffutils
- **Git diff documentation:** https://git-scm.com/docs/git-diff
- **Git apply documentation:** https://git-scm.com/docs/git-apply
