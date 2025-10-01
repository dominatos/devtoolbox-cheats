Title: 🧭 DNS — dig/nslookup
Group: Network
Icon: 🧭
Order: 5

dig A example.com +short                        # IPv4 addresses / IPv4-адреса
dig MX example.com +short                       # Mail exchangers / Почтовые MX
dig @1.1.1.1 TXT example.com                    # TXT via specific resolver / TXT через указанный резолвер
dig +trace example.com                          # Full delegation trace / Полная трассировка делегации
nslookup -type=SRV _xmpp-server._tcp.example.com# SRV record lookup / Поиск SRV записи

