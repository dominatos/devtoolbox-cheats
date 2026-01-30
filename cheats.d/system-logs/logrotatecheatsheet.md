Title: 🌀 logrotate — Basics
Group: System & Logs
Icon: 🌀
Order: 6

sudo logrotate -d /etc/logrotate.conf           # Dry-run (show actions) / Пробный прогон
sudo logrotate -f /etc/logrotate.conf           # Force rotation / Форсировать ротацию
cat /etc/logrotate.d/nginx                      # Show nginx rule / Показать правило nginx

