Title: 📜 Ionice nice
Group: System & Logs
Icon: 📜
Order: 98


---
# 🧠 ionice — приоритет ввода-вывода (I/O priority)
# Аналог nice, но для диска (чтение/запись)

# 📦 Формат:
ionice [опции] [команда]
ionice -p <PID>                      # показать приоритет процесса
ionice -c <class> -n <level> -p <PID> # изменить приоритет процесса

# 🧱 Классы (-c)
1 = realtime   # максимум, только root, может повесить систему
2 = best-effort (default)  # обычный режим, настраивается через -n
3 = idle       # работает только когда диск свободен

# 🎚 Уровень (-n) (только для class=2)
0 = самый высокий приоритет
7 = самый низкий приоритет

# 💡 Примеры
ionice -c3 rsync -a /mnt/data /backup     # минимальная нагрузка (idle)
ionice -c2 -n7 find / -type f > list.txt  # фоновая задача
ionice -c2 -n0 dd if=/dev/zero of=/dev/sda # максимум приоритета
ionice -p 1234                             # показать приоритет PID
ionice -c3 nice -n19 tar czf /backup.tgz /data # минимально по CPU и диску

# ⚙️ Советы
- Работает только с блочными устройствами (HDD, SSD, NVMe)
- Использует I/O scheduler (cfq, bfq, mq-deadline)
- Отлично комбинируется с `nice` для фоновых копий и бэкапов
- Ideal: rsync, find, tar, dd, bzip2, gzip

# 📊 Типичные режимы
ionice -c2 -n0   # максимум приоритета
ionice -c2 -n4   # средний приоритет (default)
ionice -c3       # только когда диск свободен (idle mode)
