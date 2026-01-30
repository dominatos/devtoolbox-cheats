Title: 🖧 resolvectl
Group: Network
Icon: 🖧
Order: 999

resolvectl status #Show global and per-link DNS status / Показать общий статус DNS и по интерфейсам
resolvectl statistics #Show resolver statistics / Показать статистику резолвера
resolvectl flush-caches #Clear DNS cache / Очистить DNS-кэш
resolvectl reset-statistics #Reset statistics counters / Сбросить счётчики статистики
resolvectl reset-server-features #Forget probed DNS server features / Забыть обнаруженные возможности DNS-серверов

resolvectl query example.com #Resolve A/AAAA records / Разрешить A/AAAA для домена
resolvectl query -t MX example.com #Query specific RR type / Запросить конкретный тип записи
resolvectl query @1.1.1.1 example.com #Query via specific DNS server / Резолвить через указанный DNS-сервер
resolvectl query --class=CH -t TXT whoami.cloudflare #Custom class/type query / Кастомный класс/тип запроса
resolvectl service _https._tcp.example.com #Resolve DNS-SD (SRV+TXT) / Разрешить сервис DNS-SD
resolvectl tlsa _443._tcp.example.com #Query TLSA (DANE) records / Запросить записи TLSA
resolvectl openpgp example.com #Query OPENPGPKEY record / Запросить OPENPGPKEY

resolvectl domain #List per-link search domains / Показать поисковые домены по интерфейсам
resolvectl domain eth0 example.com ~intra.example.com #Set search & routing-only domains / Задать поисковые и маршрутизируемые домены
resolvectl default-route eth0 yes #Mark link as default DNS route / Пометить интерфейс как дефолтный DNS-маршрут
resolvectl dns eth0 9.9.9.9 149.112.112.112 #Set DNS servers for link / Установить DNS-серверы для интерфейса
resolvectl dns #List DNS servers per link / Список DNS-серверов по интерфейсам

resolvectl llmnr eth0 yes #Enable LLMNR on link / Включить LLMNR на интерфейсе
resolvectl llmnr eth0 no #Disable LLMNR on link / Выключить LLMNR на интерфейсе
resolvectl mdns eth0 yes #Enable Multicast DNS on link / Включить mDNS на интерфейсе
resolvectl mdns eth0 no #Disable Multicast DNS on link / Выключить mDNS на интерфейсе
resolvectl nss #Show NSS module info for resolved / Показать информацию NSS-модуля resolved

resolvectl dnssec eth0 yes #Enable DNSSEC validation on link / Включить DNSSEC-валидацию для интерфейса
resolvectl dnssec eth0 allow-downgrade #Opportunistic DNSSEC / Оппортунистический режим DNSSEC
resolvectl dnssec eth0 no #Disable DNSSEC on link / Отключить DNSSEC для интерфейса
resolvectl dnsovertls eth0 opportunistic #Enable DoT opportunistic / Включить DNS-over-TLS оппортунистически
resolvectl dnsovertls eth0 yes #Force DNS-over-TLS / Принудительно использовать DoT
resolvectl dnsovertls eth0 no #Disable DNS-over-TLS / Отключить DoT

resolvectl nta list #List Negative Trust Anchors / Показать список NTA
resolvectl nta add example.local #Add NTA (skip DNSSEC) / Добавить NTA (пропуск DNSSEC для зоны)
resolvectl nta remove example.local #Remove NTA / Удалить NTA

resolvectl revert #Drop all runtime link settings / Сбросить все временные настройки интерфейсов
resolvectl revert eth0 #Revert single link / Сбросить настройки для одного интерфейса
resolvectl reload #Reload resolved configuration / Перечитать конфигурацию resolved
resolvectl hosts #Show static hosts in memory / Показать загруженные статические записи hosts

resolvectl compat #Show nss-compat state / Показать состояние совместимости nss
resolvectl -n query example.com #No-pager output / Вывод без пейджера
resolvectl -4 query example.com #IPv4-only resolution / Разрешать только по IPv4
resolvectl -6 query example.com #IPv6-only resolution / Разрешать только по IPv6
resolvectl --legend=no status #Terse output / Короткий вывод без легенды

systemctl status systemd-resolved #Check resolver service state / Проверить состояние службы резолвера
sudo systemctl restart systemd-resolved #Restart resolver service / Перезапустить службу резолвера
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf #Use resolved-managed resolv.conf / Подключить управляемый resolved resolv.conf
sudoedit /etc/systemd/resolved.conf #Edit persistent settings / Редактировать постоянные настройки resolved
resolvectl status | grep -A4 'Link' #Quick per-link summary / Быстрый срез по интерфейсам

resolvectl query myhost.local #Test mDNS/LLMNR host / Проверить резолвинг локального имени через mDNS/LLMNR
resolvectl query _workstation._tcp.local #Discover LAN services / Обнаружить сервисы в локальной сети
resolvectl query --search printer #Use search domains / Использовать поисковые домены для короткого имени
