Title: 🔌 nc / nmap — Commands
Group: Network
Icon: 🔌
Order: 4

nc -zv host 80                                  # Probe TCP port 80 (no data) / Проверка TCP 80 (без данных)
echo -e "GET / HTTP/1.0\r\n\r\n" | nc host 80   # Grab HTTP banner / Снять HTTP баннер
nmap -sS -p 1-1024 host                          # SYN scan common ports / SYN-скан общих портов
nmap -sV -p 443 host                             # Detect service version on 443 / Версия сервиса на 443
nmap -Pn -A host                                 # Aggressive scan (no ping) / Агрессивное сканирование (без ping)

