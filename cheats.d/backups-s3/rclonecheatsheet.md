Title: 🗄️ rclone — Remotes/S3
Group: Backups & S3
Icon: 🗄️
Order: 2

rclone config                                   # Configure remote / Настройка remote
rclone ls remote:bucket/path                    # List objects / Список объектов
rclone sync /data remote:bucket/path --progress # Sync local → S3 / Синхронизация локального в S3
rclone copy remote:bucket/path /restore --progress  # Copy S3 → local / Копировать из S3 на диск

