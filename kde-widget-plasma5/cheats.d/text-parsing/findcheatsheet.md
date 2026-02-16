Title: 🗃 FIND — Commands
Group: Text & Parsing
Icon: 🗃
Order: 3

## Table of Contents
- [Basic Search](#-basic-search--базовый-поиск)
- [By Type & Name](#-by-type--name--по-типу-и-имени)
- [By Time](#-by-time--по-времени)
- [By Size & Permissions](#-by-size--permissions--по-размеру-и-правам)
- [Excluding Paths](#-excluding-paths--исключение-путей)
- [Actions: Delete, Exec](#-actions-delete-exec--действия-удаление-выполнение)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔍 Basic Search / Базовый поиск
find . -name "file.txt"                        # Find by exact name / Поиск по точному имени
find . -iname "file.txt"                       # Case-insensitive name / Без учёта регистра
find /var -name "*.log"                        # Wildcard search / Поиск с подстановкой
find . -type f                                 # All files / Все файлы
find . -type d                                 # All directories / Все каталоги
find . -type l                                 # All symlinks / Все символические ссылки
find /home -user <USER>                        # Files owned by user / Файлы пользователя
find . -group <GROUP>                          # Files owned by group / Файлы группы

# 📁 By Type & Name / По типу и имени
find . -name "*.log" -type f                   # Log files / Файлы логов
find /var -type d -name "nginx*"               # Dirs starting with nginx / Каталоги с nginx
find . -name "*.tmp" -o -name "*.bak"          # Multiple patterns (OR) / Несколько шаблонов (ИЛИ)
find . -name "*.sh" -not -name "test*"         # Exclude pattern / Исключить шаблон
find . -regex '.*\.\(jpg\|png\|gif\)$'         # Regex match / Регулярное выражение
find . -path "*/conf/*" -name "*.xml"          # Path + name pattern / Шаблон пути + имени

# ⏰ By Time / По времени
find . -mtime -1                               # Modified last 24h / Изменено за сутки
find . -mtime +7                               # Modified >7 days ago / Изменено >7 дней назад
find . -mtime 0                                # Modified today / Изменено сегодня
find . -atime -7                               # Accessed last 7 days / Доступ за 7 дней
find . -ctime +30                              # Status changed >30 days / Статус изменён >30 дней
find . -mmin -60                               # Modified last hour / Изменено за час
find . -newer reference.txt                    # Newer than file / Новее чем файл
find . -newermt "2024-01-01"                   # Newer than date / Новее даты

# 📏 By Size & Permissions / По размеру и правам
find . -size +100M                             # Larger than 100MB / Больше 100МБ
find . -size -1k                               # Smaller than 1KB / Меньше 1КБ
find . -size 50M                               # Exactly 50MB / Ровно 50МБ
find . -empty                                  # Empty files/dirs / Пустые файлы/каталоги
find . -perm -u+x                              # Executable by user / Исполняемые пользователем
find . -perm 644                               # Exact permissions / Точные права
find . -perm /u+w,g+w                          # Writable by user OR group / Доступ на запись

# 🚫 Excluding Paths / Исключение путей
find . -not -path "*/.git/*"                   # Exclude .git / Исключить .git
find . -not -path "*/node_modules/*" -not -name "*.min.js"  # Multiple excludes / Несколько исключений
find . -path "*/build/*" -prune -o -type f -print  # Prune build dir / Обрезать каталог build
find . -name ".DS_Store" -prune -o -name "*.log" -print  # Skip .DS_Store / Пропустить .DS_Store

# ⚡ Actions: Delete, Exec / Действия: удаление, выполнение
find . -name "*.tmp" -delete                   # Delete tmp files / Удалить .tmp файлы
find . -name "*.log" -exec gzip {} \;          # Gzip each log / Сжать каждый лог
find . -name "*.log" -exec gzip {} +           # Gzip batch (faster) / Сжать пакетом (быстрее)
find . -type f -exec chmod 644 {} \;           # Set file permissions / Установить права файлам
find . -type d -exec chmod 755 {} \;           # Set dir permissions / Установить права каталогам
find . -name "*.sh" -ok rm {} \;               # Interactive confirm / С подтверждением
find . -type f -print0 | xargs -0 sha256sum    # Hash all files / Хеш всех файлов
find . -name "core" -delete                    # Delete core dumps / Удалить core-дампы

# 🌟 Real-World Examples / Примеры из практики
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

# 🔬 Advanced Use Cases / Продвинутые случаи
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
