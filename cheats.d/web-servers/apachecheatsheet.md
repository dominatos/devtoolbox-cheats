Title: 🪶 Apache HTTPD — Cheatsheet
Group: Web Servers
Icon: 🪶
Order: 2

# Manage & modules / Управление и модули
sudo apachectl configtest                                            # Test config / Проверка конфига
sudo systemctl reload apache2                                        # Reload service / Перечитать конфиг
sudo a2enmod rewrite proxy proxy_http ssl                            # Enable modules / Включить модули
sudo a2ensite mysite.conf && sudo systemctl reload apache2           # Enable site / Включить сайт

# vhost reverse proxy / вирт. хост обратный прокси
<VirtualHost *:80>
  ServerName example.com                                            # ServerName / Имя хоста
  ProxyPass        / http://127.0.0.1:3000/                         # Proxy / Проксировать
  ProxyPassReverse / http://127.0.0.1:3000/
  ErrorLog  ${APACHE_LOG_DIR}/mysite_error.log                      # Error log / Лог ошибок
  CustomLog ${APACHE_LOG_DIR}/mysite_access.log combined            # Access log / Лог доступа
</VirtualHost>

# Logs / Логи
sudo tail -f /var/log/apache2/access.log /var/log/apache2/error.log  # Tail logs / Хвост логов

