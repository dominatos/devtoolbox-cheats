Title: 📅 date / TZ — Commands
Group: System & Logs
Icon: 📅
Order: 9

date '+%Y-%m-%d %H:%M:%S'                       # Local time formatted / Локальное время в формате
date -u '+%Y-%m-%dT%H:%M:%SZ'                   # UTC in ISO-8601 / UTC в ISO-8601
date -d '@1693152000' '+%F %T'                  # Convert Unix timestamp / Конвертация Unix-штампа
TZ=Europe/Rome date                             # Show time in specific TZ / Время в заданном поясе
timedatectl status                              # System clock/TZ status / Статус системного времени/пояса

