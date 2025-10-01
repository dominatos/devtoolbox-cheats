Title: 🗃 FIND — Commands
Group: Text & Parsing
Icon: 🗃
Order: 3

find . -name "*.log" -type f                    # Logs under cwd / Логи в текущем каталоге
find /var -type d -name "nginx*"                # Dirs named nginx* / Папки nginx*
find . -mtime -1 -type f                        # Modified <24h / Изменены за сутки
find . -size +100M -type f                      # Bigger than 100MB / Размер >100МБ
find . -type f -perm -u+x                       # Executable by user / Исполняемые файлы
find . -not -path "*/.git/*" -not -name "*.min.js"  # Exclude paths/names / Исключить пути/имена
find . -name "*.tmp" -type f -delete            # Delete tmp files / Удалить .tmp
find . -name "*.log" -type f -exec gzip -9 {} \;  # Gzip each log / Сжать каждый лог
find . -type f -print0 | xargs -0 sha256sum     # Hash all files / Хеш всех файлов
find /root -maxdepth 1 -mindepth 1 -type f -name '.*.bak.*' -mtime +7 -print -delete  # Удалит только файлы .*.bak.* старше 7 дней в /root -mtime +7 — старше 7*24 часов -type f — только файлы -print — покажет, что удаляет (можно убрать)


