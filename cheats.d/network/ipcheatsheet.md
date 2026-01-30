Title: 🌐 ip — Commands
Group: Network
Icon: 🌐
Order: 3

ip addr && ip -brief addr                       # Show addresses (detailed/brief) / Адреса (подробно/кратко)
ip route && ip -s link && ip neigh              # Routing, link stats, ARP/NDP / Маршруты, стат. ссылок, ARP/NDP
ip addr add 10.0.0.10/24 dev eth0               # Add IP to interface / Добавить IP на интерфейс
ip link set eth0 up                             # Bring interface up / Поднять интерфейс

