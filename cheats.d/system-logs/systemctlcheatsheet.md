Title: 🛠 systemctl — Commands
Group: System & Logs
Icon: 🛠
Order: 1

systemctl status nginx                          # Service status / Статус сервиса
sudo systemctl start|stop|restart nginx         # Control service / Управление сервисом
sudo systemctl enable --now nginx               # Enable + start / Включить и запустить
systemctl list-units --type=service --state=failed  # Failed services / Упалшие сервисы
journalctl -u nginx --since "1 hour ago"        # Logs from last hour / Логи за последний час

