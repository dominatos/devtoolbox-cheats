Title: 🗄️ restic — Backups
Group: Backups & S3
Icon: 🗄️
Order: 1

restic -r /backup init                          # Initialize repo / Инициализировать репозиторий
restic -r /backup backup /var/www               # Backup directory / Бэкап каталога
restic -r /backup snapshots                     # List snapshots / Список снапшотов
restic -r /backup restore latest -t /restore    # Restore latest / Восстановить последний снапшот

