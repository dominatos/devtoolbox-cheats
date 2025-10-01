Title: 🔤 tr/head/tail/watch — Commands
Group: Text & Parsing
Icon: 🔤
Order: 7

tr '[:lower:]' '[:upper:]' < file               # To uppercase / В верхний регистр
head -n 20 file && tail -n 50 file              # First 20 then last 50 lines / Первые 20 и последние 50
tail -f /var/log/syslog                         # Follow new log lines / Следить за новыми строками
watch -n2 'ss -s'                               # Refresh command every 2s / Выполнять команду каждые 2с

