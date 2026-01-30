Title: 🔥 firewalld — Commands
Group: Network
Icon: 🔥
Order: 12

sudo firewall-cmd --state                       # Daemon state / Состояние демона
sudo firewall-cmd --get-active-zones            # Active zones / Активные зоны
sudo firewall-cmd --get-services                # Predefined services / Преднастроенные сервисы
sudo firewall-cmd --zone=public --list-all      # Rules in zone (runtime) / Правила в зоне (runtime)
sudo firewall-cmd --zone=public --add-service=ssh --permanent && sudo firewall-cmd --reload  # Allow SSH / Разрешить SSH
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent && sudo firewall-cmd --reload # Open port 8080/TCP / Открыть порт 8080/TCP
sudo firewall-cmd --zone=public --remove-port=8080/tcp --permanent && sudo firewall-cmd --reload # Close port / Закрыть порт
sudo firewall-cmd --runtime-to-permanent        # Save runtime rules / Сохранить runtime правила
sudo firewall-cmd --state                                            # Daemon state? / Состояние демона?
sudo firewall-cmd --get-active-zones                                 # Active zones / Активные зоны
sudo firewall-cmd --get-services                                     # Predefined services / Преднастроенные сервисы
sudo firewall-cmd --zone=public --list-all                           # Rules in public (runtime) / Правила в public (runtime)
sudo firewall-cmd --zone=public --add-service=ssh --permanent && sudo firewall-cmd --reload  # Allow SSH permanently / Разрешить SSH навсегда
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent && sudo firewall-cmd --reload # Open 8080/TCP permanently / Открыть 8080/TCP навсегда
sudo firewall-cmd --runtime-to-permanent                             # Save runtime → permanent / Сохранить runtime → permanent

