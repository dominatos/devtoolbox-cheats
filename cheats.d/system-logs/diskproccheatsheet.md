Title: 💽 du/df/lsof/ps — Commands
Group: System & Logs
Icon: 💽
Order: 10

du -sh * | sort -h                              # Disk usage per item (sorted) / Размеры по элементам (сортировка)
df -hT                                          # Filesystem usage + type / Использование ФС + тип
lsof -i :5432                                   # Processes using port 5432 / Процессы на порту 5432
lsof +L1                                        # Open deleted files / Открытые удалённые файлы
ps aux --sort=-%mem | head                      # Top memory consumers / Топ по памяти
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head # Top CPU consumers / Топ по CPU

