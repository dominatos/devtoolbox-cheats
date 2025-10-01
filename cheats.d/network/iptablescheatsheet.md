Title: 🔥 iptables — Commands
Group: Network
Icon: 🔥
Order: 13

sudo iptables -L -n -v                          # List rules with counters / Правила со счётчиками
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Allow SSH / Разрешить SSH
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  # Allow established / Разрешить established
sudo iptables -A INPUT -j DROP                  # Default drop (if policy not set) / Правило DROP по умолчанию
sudo iptables-save > rules.v4                   # Save rules to file / Сохранить правила в файл
sudo iptables-restore < rules.v4                # Restore rules from file / Восстановить правила из файла

