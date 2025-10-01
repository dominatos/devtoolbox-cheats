Title: 📗 Linux Basics 2 — Next Steps
Group: Basics
Icon: 📗
Order: 2

# 🔐 Perms & owners / Права и владельцы
ls -l                                          # Long list / Длинный список
chmod +x script.sh                             # Make executable / Сделать исполняемым
chmod 644 file                                 # rw-r--r-- / Права rw-r--r--
chmod 755 dir                                  # rwxr-xr-x / Папка исполнимая
chmod u+r,g-w,o-x file                         # Symbolic perms / Символьные права
chmod -R 755 /path/dir                         # Recursive perms / Рекурсивно применить
sudo chown user file                           # Change owner / Сменить владельца
sudo chown -R user:group dir                   # Chown + group (rec) / Владельца+группу рекурсивно
chgrp developers file                          # Change group / Сменить группу

# 👥 Users & groups / Пользователи и группы
whoami                                         # Current user / Текущий пользователь
id                                             # UID/GID / UID/GID
groups                                         # User groups / Группы пользователя
sudo usermod -aG docker $USER                  # Add to group / Добавить в группу
newgrp docker                                  # Apply new group / Применить группу без релогина

# 🧠 Processes / Процессы
ps aux | grep nginx                            # Search process / Найти процесс
pgrep -a ssh                                   # PIDs by name / PIDы по имени
top                                            # Live monitor / Мониторинг (q выход)
htop                                           # Fancy top / Улучшенный top
kill -TERM 1234                                # Graceful kill / Корректно завершить
kill -9 1234                                   # ⚠️ Force kill / ⚠️ Жёстко убить
killall nginx                                  # Kill by name / Завершить по имени
nice -n 10 long_task &                         # Lower priority / Пониженный приоритет
sudo renice -n 10 -p 1234                      # Change priority / Изменить приоритет

# 🌐 Network basic / Сеть (база)
ip a                                           # IP addresses / IP-адреса
ip r                                           # Routes / Маршруты
ping -c 4 8.8.8.8                              # Ping 4 packets / 4 пакета
curl -I https://example.com                    # HTTP HEAD / Заголовки HTTP(S)
ss -tulpn | grep ':22'                         # Who listens 22 / Кто слушает порт 22

# 📦 Archives / Архивы
tar -xzvf file.tar.gz                          # Extract tar.gz / Распаковать .tar.gz
tar -czvf archive.tar.gz dir/                  # Create tar.gz / Упаковать каталог
zip -r archive.zip dir/                        # Zip recursively / Создать zip
unzip archive.zip -d out/                      # Unzip to out/ / Распаковать в out/
gzip -k file && gunzip file.gz                 # Gzip/ungzip / Сжать/распаковать

# 💽 Disk & memory / Диск и память
df -h                                          # Filesystems usage / Использование ФС
du -sh * | sort -h                             # Sizes sorted / Размеры объектов
free -h                                        # RAM & swap / Память и swap

