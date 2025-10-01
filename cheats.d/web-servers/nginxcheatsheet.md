Title: 🌐 Nginx — Cheatsheet
Group: Web Servers
Icon: 🌐
Order: 1

# Manage / Управление
sudo nginx -t                                                         # Test config / Проверить конфиг
sudo systemctl reload nginx                                           # Reload no downtime / Перечитать без простоя
sudo systemctl status nginx                                           # Service status / Статус сервиса
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log       # Tail logs / Хвост логов

# vhost reverse proxy / вирт. хост обратный прокси
server {
  listen 80;                                                          # Listen 80 / Слушать :80
  server_name example.com;                                            # Server name / Имя хоста
  location / {
    proxy_pass http://127.0.0.1:3000;                                 # Upstream / Проксировать на backend
    proxy_set_header Host $host;                                      # Forward headers / Проброс заголовков
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
  access_log /var/log/nginx/app_access.log;                           # Access log / Логи доступа
  error_log  /var/log/nginx/app_error.log;                            # Error log / Логи ошибок
}
# Enable site / Активировать сайт:
# sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx

