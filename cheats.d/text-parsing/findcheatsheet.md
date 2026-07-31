---
Title: 🗃 FIND — Commands
Group: "Text & Parsing"
Icon: 🗃
Order: 3
tags:
  - text-parsing
  - linux
  - sysadmin
---

> **find** — POSIX-standard utility for recursively searching the file system by name, type, size, time, permissions, and more. Part of GNU Findutils, pre-installed on all Linux distributions. `find` is the most powerful and flexible file-locating tool available in the shell. For simpler syntax and faster performance, consider the modern alternative [`fd`](https://github.com/sharkdp/fd) — but `find` remains the universal, scriptable standard.

## Table of Contents
- [Basic Search](#Basic%20Search)
- [By Type & Name](#By%20Type%20&%20Name)
- [By Time](#⏰%20By%20Time)
- [By Size & Permissions](#By%20Size%20&%20Permissions)
- [Excluding Paths](#Excluding%20Paths)
- [Actions: Delete, Exec](#Actions:%20Delete,%20Exec)
- [Real-World Examples](#Real-World%20Examples)
- [Advanced Use Cases](#Advanced%20Use%20Cases)

---

## 🔍 Basic Search

```bash
find . -name "file.txt"                        # Find by exact name / Поиск по точному имени
find . -iname "file.txt"                       # Case-insensitive name / Без учёта регистра
find /var -name "*.log"                        # Wildcard search / Поиск с подстановкой
find . -type f                                 # All files / Все файлы
find . -type d                                 # All directories / Все каталоги
find . -type l                                 # All symlinks / Все символические ссылки
find /home -user <USER>                        # Files owned by user / Файлы пользователя
find . -group <GROUP>                          # Files owned by group / Файлы группы
```

---

## 📁 By Type & Name

```bash
find . -name "*.log" -type f                   # Log files / Файлы логов
find /var -type d -name "nginx*"               # Dirs starting with nginx / Каталоги с nginx
find . -name "*.tmp" -o -name "*.bak"          # Multiple patterns (OR) / Несколько шаблонов (ИЛИ)
find . -name "*.sh" -not -name "test*"         # Exclude pattern / Исключить шаблон
find . -regex '.*\.\(jpg\|png\|gif\)$'         # Regex match / Регулярное выражение
find . -path "*/conf/*" -name "*.xml"          # Path + name pattern / Шаблон пути + имени
```

---

## ⏰ By Time

```bash
find . -mtime -1                               # Modified last 24h / Изменено за сутки
find . -mtime +7                               # Modified >7 days ago / Изменено >7 дней назад
find . -mtime 0                                # Modified today / Изменено сегодня
find . -atime -7                               # Accessed last 7 days / Доступ за 7 дней
find . -ctime +30                              # Status changed >30 days / Статус изменён >30 дней
find . -mmin -60                               # Modified last hour / Изменено за час
find . -newer reference.txt                    # Newer than file / Новее чем файл
find . -newermt "2024-01-01"                   # Newer than date / Новее даты
```

---

## 📏 By Size & Permissions

```bash
find . -size +100M                             # Larger than 100MB / Больше 100МБ
find . -size -1k                               # Smaller than 1KB / Меньше 1КБ
find . -size 50M                               # Exactly 50MB / Ровно 50МБ
find . -empty                                  # Empty files/dirs / Пустые файлы/каталоги
find . -perm -u+x                              # Executable by user / Исполняемые пользователем
find . -perm 644                               # Exact permissions / Точные права
find . -perm /u+w,g+w                          # Writable by user OR group / Доступ на запись
```

---

## 🚫 Excluding Paths

```bash
find . -not -path "*/.git/*"                   # Exclude .git / Исключить .git
find . -not -path "*/node_modules/*" -not -name "*.min.js"  # Multiple excludes / Несколько исключений
find . -path "*/build/*" -prune -o -type f -print  # Prune build dir / Обрезать каталог build
find . -name ".DS_Store" -prune -o -name "*.log" -print  # Skip .DS_Store / Пропустить .DS_Store
```

---

## ⚡ Actions: Delete, Exec

> [!CAUTION]
> Commands with `-delete` and `-exec rm` permanently remove files. Always test with `-print` first.
> Команды с `-delete` и `-exec rm` безвозвратно удаляют файлы. Всегда сначала тестируйте с `-print`.

```bash
find . -name "*.tmp" -delete                   # Delete tmp files / Удалить .tmp файлы
find . -name "*.log" -exec gzip {} \;          # Gzip each log / Сжать каждый лог
find . -name "*.log" -exec gzip {} +           # Gzip batch (faster) / Сжать пакетом (быстрее)
find . -type f -exec chmod 644 {} \;           # Set file permissions / Установить права файлам
find . -type d -exec chmod 755 {} \;           # Set dir permissions / Установить права каталогам
find . -name "*.sh" -ok rm {} \;               # Interactive confirm / С подтверждением
find . -type f -print0 | xargs -0 sha256sum    # Hash all files / Хеш всех файлов
find . -name "core" -delete                    # Delete core dumps / Удалить core-дампы
```

---

## 🌟 Real-World Examples

```bash
find /var/log -name "*.log" -mtime +30 -delete  # Delete old logs / Удалить старые логи
find ~ -name "*.bak" -mtime +7 -print -delete   # Delete old backups / Удалить старые бэкапы
find /root -maxdepth 1 -name ".*.bak.*" -mtime +7 -delete  # Delete old dotfile backups / Удалить старые .bak* файлы
find . -name "*.jpg" -exec convert {} {}.png \;  # Convert images / Конвертировать изображения
find /etc -name "*.conf" -exec grep -l "server_name" {} \;  # Find configs with server_name / Найти конфиги с server_name
find . -type f -size +100M -exec ls -lh {} \;   # List large files / Список больших файлов
find /tmp -type f -atime +3 -delete             # Cleanup /tmp / Очистка /tmp
find . -name "Dockerfile" -exec dirname {} \;   # Get parent dirs / Получить родительские каталоги
du -sh $(find . -maxdepth 1 -type d)            # Size of each subdir / Размер каждого подкаталога
find . -type f -name "*.py" | wc -l             # Count Python files / Подсчитать Python файлы
find /var/www -type f -exec sed -i 's/<IP>/<NEW_IP>/g' {} \;  # Replace IP in all files / Заменить IP во всех файлах
find . -name ".git" -type d -prune -o -name "*.js" -print  # JS files excluding .git / JS файлы без .git
```

---

## 🔬 Advanced Use Cases

```bash
find . -maxdepth 2 -name "*.md"                # Limit depth to 2 / Глубина до 2
find . -mindepth 2 -name "*.txt"               # Minimum depth 2 / Минимальная глубина 2
find . -samefile file.txt                      # Find hard links / Найти жёсткие ссылки
find . -inum 12345                             # Find by inode number / Найти по номеру inode
find . -links +1                               # Files with >1 hard link / Файлы с >1 жёсткой ссылкой
find . -type f -printf "%s %p\n" | sort -n     # Sort files by size / Сортировать файлы по размеру
find . -type f -printf "%T@ %p\n" | sort -n    # Sort by modification time / По времени изменения
find . -type f -newer file1 ! -newer file2     # Between two files / Между двумя файлами
find . -xtype l                                # Broken symlinks / Сломанные символические ссылки
find . -perm /4000                             # Find SUID files / Найти SUID файлы
```

---

## 📚 Documentation

- [GNU Findutils Manual](https://www.gnu.org/software/findutils/manual/html_node/find_html/index.html)
- [POSIX find specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html)
- [fd — modern alternative (GitHub)](https://github.com/sharkdp/fd)
- `man find`
