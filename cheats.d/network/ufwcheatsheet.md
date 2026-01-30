Title: 🧱 UFW — Commands
Group: Network
Icon: 🧱
Order: 16

sudo ufw status verbose                         # Show status and rules / Показ статуса и правил
sudo ufw default deny incoming                  # Default deny inbound / Запрет входящих по умолчанию
sudo ufw default allow outgoing                 # Default allow outbound / Разрешить исходящие по умолчанию
sudo ufw allow 22/tcp                           # Allow SSH / Разрешить SSH
sudo ufw allow 80,443/tcp                       # Allow HTTP/HTTPS / Разрешить HTTP/HTTPS
sudo ufw delete allow 22/tcp                    # Remove rule / Удалить правило
sudo ufw enable                                 # Enable firewall / Включить фаервол

