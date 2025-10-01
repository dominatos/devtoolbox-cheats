Title: 🌐 CURL — Commands
Group: Network
Icon: 🌐
Order: 1

curl -L https://example.com                     # GET URL and follow redirects / GET с переходами по редиректам
curl -I https://example.com                     # Request headers only (HEAD) / Только заголовки (HEAD)
curl -sS -o out.html https://site               # Save body silently (show errors) / Сохранить тихо (ошибки показывать)
curl -O https://host/file.zip                   # Download using remote filename / Сохранить с именем сервера
curl -C - -O https://host/big.iso               # Resume an interrupted download / Возобновить прерванную загрузку
curl -H 'Content-Type: application/json' --data '{"a":1}' https://api/app  # POST JSON / POST JSON
curl -H 'Authorization: Bearer TOKEN' https://api/secure  # Bearer token auth / Авторизация токеном
curl -c cookies.txt https://site && curl -b cookies.txt https://site  # Save+send cookies / Сохранить и отправить куки
curl -w '%{http_code}\n' -o /dev/null -s https://api/health  # Print only HTTP status / Вывести только HTTP статус
curl --cacert ca.crt https://secure             # Use custom CA bundle (verify) / Свой CA для проверки
curl --insecure https://self-signed.local       # Skip TLS verify (testing only) / Пропустить проверку TLS (только тесты)

# ====================== BASICS ======================
curl https://example.com                        # Simple GET, print body / Простой GET, печать тела
curl -I https://example.com                     # HEAD request (headers only) / HEAD-запрос (только заголовки)
curl -L https://example.com                     # Follow redirects / Следовать редиректам
curl -s https://example.com                     # Silent (no progress) / Тихо (без прогресса)
curl -S https://example.com                     # Show errors (with -s) / Показ ошибок (с -s)
curl -sS https://example.com                    # Silent but show errors / Тихо, но с ошибками
curl -v https://example.com                     # Verbose I/O / Подробный ввод-вывод
curl -k https://example.com                     # Do not verify TLS cert / Не проверять TLS-сертификат
curl --fail https://example.com                 # Non-2xx/3xx as error / 4xx/5xx как ошибка
curl --fail-with-body https://example.com       # Fail but print body / Ошибка, но печатать тело
curl --http1.1 https://example.com              # Force HTTP/1.1 / Принудительно HTTP/1.1
curl --http2 https://example.com                # Force HTTP/2 / Принудительно HTTP/2
curl --http3 https://example.com                # Force HTTP/3 / Принудительно HTTP/3
curl --ipv4 https://example.com                 # Use IPv4 / Использовать IPv4
curl --ipv6 https://example.com                 # Use IPv6 / Использовать IPv6
curl --no-progress-meter https://example.com    # Hide progress meter / Скрыть индикатор прогресса

# ====================== OUTPUT / FILES ======================
curl -o file.html https://example.com           # Save to custom name / Сохранить в указанный файл
curl -O https://host/path/file.zip              # Save using remote name / Сохранить с удалённым именем
curl -OJ https://host/path/file                 # Use Content-Disposition name / Имя из заголовка Content-Disposition
curl --create-dirs -o out/dir/file https://example.com  # Create missing dirs / Создать недостающие каталоги
curl -C - -O https://host/file.iso              # Resume download / Возобновить загрузку
curl -r 0-999 -o part.bin https://host/file     # Download byte range / Скачать диапазон байт
curl --remote-name-all https://h/a.bin https://h/b.bin  # -O for all URLs / -O для всех URL
curl -D headers.txt -o body.bin https://example.com     # Save headers & body separately / Сохранить заголовки и тело раздельно
curl --output-dir downloads -O https://host/file.tar.gz # Output directory / Задать директорию для сохранения

# ====================== HEADERS ======================
curl -H 'Accept: application/json' https://example.com          # Add request header / Добавить заголовок
curl -H 'User-Agent: MyAgent/1.0' https://example.com           # Custom User-Agent / Пользовательский User-Agent
curl -H 'Authorization: Bearer TOKEN' https://api.example.com   # Bearer auth / Авторизация Bearer
curl -I -H 'If-None-Match: "etag123"' https://example.com       # Conditional by ETag / Условный запрос по ETag
curl -H 'Expect:' -T big.bin https://host/upload                 # Disable 100-continue / Отключить 100-continue
curl --compressed https://example.com                            # Ask compressed response / Запросить сжатый ответ

# ====================== HTTP METHODS ======================
curl -X GET https://api.example.com/items           # Explicit GET / Явный GET
curl -X POST https://api.example.com/items          # POST empty body / POST с пустым телом
curl -X PUT https://api.example.com/items/1         # PUT empty body / PUT с пустым телом
curl -X PATCH https://api.example.com/items/1       # PATCH empty body / PATCH с пустым телом
curl -X DELETE https://api.example.com/items/1      # DELETE / Удаление

# ====================== SENDING DATA ======================
curl -d 'a=1&b=2' https://api.example.com           # POST form urlencoded / POST форма application/x-www-form-urlencoded
curl --data-urlencode 'q=тестовая строка' https://example.com/search  # URL-encode field / URL-кодирование поля
curl -d @data.txt https://api.example.com           # Body from file / Тело из файла
curl --data-binary @payload.bin https://api.example.com  # Binary as-is / Бинарные данные как есть
curl -H 'Content-Type: application/json' -d '{"a":1}' https://api.example.com  # POST JSON / POST JSON
curl --json '{"a":1}' https://api.example.com        # Shortcut for JSON POST / Шорткат JSON POST
curl --json @payload.json https://api.example.com/v1/items  # JSON from file / JSON из файла
curl -X PUT -T file.bin https://host/put             # Upload file as body (PUT) / Загрузка файла как тело (PUT)
curl -F 'field=value' -F 'file=@image.png' https://host/upload  # Multipart upload / Мультичаст загрузка
curl --form-string 'note=plain text' https://host/upload        # Force string field / Строковое поле без файла
curl -G -d 'q=term' -d 'limit=10' https://api.example.com/search # GET with query params / GET с параметрами
echo 'streamed-data' | curl -T - https://host/put               # Upload from stdin / Загрузка из stdin

# ====================== COOKIES ======================
curl -b 'sid=123; theme=dark' https://example.com   # Send cookies inline / Отправить куки строкой
curl -c cookies.txt https://example.com             # Save cookies to file / Сохранить куки в файл
curl -b cookies.txt https://example.com             # Send cookies from file / Отправить куки из файла
curl -c cookies.txt -b cookies.txt https://example.com  # Persist + reuse / Сохранять и переиспользовать
curl --cookie-jar jar.txt https://example.com       # Alias for -c / Синоним -c (сохранить куки)

# ====================== AUTHENTICATION ======================
curl -u user:pass https://example.com               # HTTP Basic auth / Базовая авторизация
curl -u user https://example.com                    # Prompt for password / Запрос пароля
curl --anyauth -u user:pass https://example.com     # Auto-pick auth scheme / Автовыбор схемы
curl --digest -u user:pass https://example.com      # HTTP Digest auth / Digest-авторизация
curl --negotiate -u : https://example.com           # Kerberos/Negotiate / Kerberos/Negotiate
curl --ntlm -u user:pass https://example.com        # NTLM auth / NTLM авторизация
curl --oauth2-bearer TOKEN https://api.example.com  # OAuth2 Bearer / OAuth2 токен

# ====================== PROXY ======================
curl -x http://proxy:3128 https://example.com             # HTTP proxy / HTTP-прокси
curl -x socks5h://user:pass@proxy:1080 https://example.com # SOCKS5 with DNS via proxy / SOCKS5 с DNS через прокси
curl --proxy-insecure -x https://proxy:443 https://example.com  # Skip TLS to proxy / Не проверять TLS у прокси
curl --noproxy example.com https://example.com             # Bypass proxy for domain / Обойти прокси для домена
curl --proxy-header 'Header: value' -x http://p:3128 https://example.com  # Header to proxy / Заголовок для прокси

# ====================== REDIRECTS ======================
curl -L https://t.co/xxx                          # Follow 3xx redirects / Следовать 3xx-редиректам
curl -L -X POST -d 'a=1' https://example.com      # Follow redirects keep POST (may change) / Следовать редиректам, POST может смениться
curl -L --post301 --post302 -d 'a=1' https://example.com  # Keep POST on 301/302 / Сохранять POST на 301/302
curl --max-redirs 5 -L https://example.com        # Limit redirects / Ограничить число редиректов

# ====================== COMPRESSION / CONTENT ======================
curl --compressed https://example.com             # Request compressed / Запросить сжатый ответ
curl --decompressed -o out.txt https://example.com.gz  # Force decompression on save / Принудительно распаковать при сохранении
curl --raw https://example.com                    # Do not decode transfer-encoding / Не декодировать transfer-encoding
curl --no-buffer https://example.com/stream       # Disable output buffering / Отключить буферизацию вывода

# ====================== TIMEOUTS / RETRIES / RATES ======================
curl --connect-timeout 5 https://example.com      # Conn timeout (s) / Таймаут соединения (с)
curl --max-time 15 https://example.com            # Total timeout (s) / Общий таймаут (с)
curl --retry 5 --retry-delay 2 https://example.com  # Retries with delay / Повторы с задержкой
curl --retry-all-errors https://example.com       # Retry on any error / Повтор при любой ошибке
curl --retry-connrefused https://example.com      # Retry on connection refused / Повтор при отказе соединения
curl --retry-max-time 60 https://example.com      # Cap total retry time / Ограничить суммарное время повторов
curl --limit-rate 500k -O https://host/file       # Limit download speed / Ограничить скорость загрузки
curl --rate 10/s https://api.example.com          # Throttle request rate / Ограничить частоту запросов
curl --speed-time 30 --speed-limit 1024 https://host/file  # Abort if <1KB/s 30s / Прервать если <1КБ/с за 30с

# ====================== DEBUG / METRICS ======================
curl -v https://example.com                       # Verbose / Подробный вывод
curl --trace trace.bin https://example.com        # Binary trace / Бинарный трейс
curl --trace-ascii trace.txt https://example.com  # ASCII trace / ASCII трейс
curl --trace-time -v https://example.com          # Timestamps in trace / Метки времени в трейсе
curl -w '%{http_code}\n' -o /dev/null -s https://example.com  # Print only status / Печатать только статус
curl -s -o /dev/null -w 'dns:%{time_namelookup} connect:%{time_connect} ttfb:%{time_starttransfer} total:%{time_total}\n' https://example.com  # Key timings / Ключевые тайминги
curl -s -o /dev/null -w 'down:%{size_download} speed:%{speed_download}\n' https://example.com  # Sizes/speeds / Размеры/скорости
curl -s -o /dev/null -w '{"code":%{http_code},"total":%{time_total}}\n' https://example.com  # JSON-like metrics / Метрики в JSON-подобном виде

# ====================== DNS / NETWORK TRICKS ======================
curl --resolve example.com:443:1.2.3.4 https://example.com   # Override DNS for host:port / Переопределить DNS для host:port
curl --connect-to example.com:443:127.0.0.1:8443 https://example.com  # Reroute to other host:port / Переадресовать на другой host:port
curl --interface eth0 https://example.com                    # Bind to interface / Привязка к интерфейсу
curl --local-port 5000-5100 https://example.com              # Use local port range / Диапазон локальных портов
curl --path-as-is 'https://example.com/a/../b'               # Do not normalize path / Не нормализовать путь
curl --globoff 'https://example.com/file[1-3].txt'           # Disable URL globbing / Отключить шаблоны в URL

# ====================== TLS / SECURITY ======================
curl --cacert ca.pem https://example.com         # Trust custom CA / Доверять заданному CA
curl --capath /etc/ssl/certs https://example.com # CA directory / Директория CA
curl --cert client.pem --key client.key https://mtls.example.com  # mTLS PEM / mTLS с PEM-файлами
curl --cert-type P12 --cert client.p12:PASS https://mtls.example.com  # mTLS PKCS#12 / mTLS с PKCS#12
curl --tlsv1.2 https://example.com               # Force TLS 1.2 / Принудительно TLS 1.2
curl --pinnedpubkey 'sha256//BASE64==' https://example.com  # Public key pinning / Пиннинг публичного ключа
curl --ciphers 'TLS_AES_128_GCM_SHA256' https://example.com  # Restrict cipher suites / Ограничить шифры

# ====================== PARALLEL REQUESTS ======================
curl --parallel --parallel-max 5 -K urls.txt     # Parallel from config / Параллельно из файла конфигов
curl --parallel -O https://h/a.bin -O https://h/b.bin -O https://h/c.bin  # Parallel downloads / Параллельные загрузки

# ====================== CONFIG / NETRC ======================
curl --config ~/.curlrc https://example.com      # Load options from config / Загрузить опции из конфигурации
curl --netrc https://example.com                 # Use ~/.netrc for creds / Использовать ~/.netrc для учётных данных
curl --netrc-file .netrc https://example.com     # Custom netrc path / Заданный путь к netrc

# ====================== API / JSON EXAMPLES ======================
curl --json @payload.json https://api.example.com/v1/items  # POST JSON from file / POST JSON из файла
curl -H 'Content-Type: application/json' -d @payload.json https://api.example.com  # Same without --json / То же без --json
curl -H 'Authorization: Bearer TOKEN' https://api.example.com/me  # Call with bearer token / Вызов с токеном
curl -H 'Content-Type: application/json' -d '{"query":"{ me { id name } }"}' https://api.example.com/graphql  # GraphQL POST / POST GraphQL
curl 'https://api.example.com/search?q=term&limit=10'        # GET with inline query / GET с параметрами в URL
curl -s https://ifconfig.co/json                             # Quick IP info in JSON / Быстрая информация об IP в JSON

# ====================== UPLOADS ======================
curl -T ./file.bin https://upload.example.com/put           # Upload via PUT / Загрузка через PUT
curl -F 'file=@report.pdf;type=application/pdf' https://upload.example.com  # Multipart with MIME / Мультичаст с MIME-типом
curl -F 'meta={"a":1};type=application/json' -F 'file=@img.png' https://upload.example.com  # Mixed multipart / Смешанный multipart
tar czf - folder | curl --data-binary @- https://host/upload  # Stream tar.gz to server / Потоковая отправка tar.gz

# ====================== FTP / SFTP / SMTP ======================
curl -u user:pass ftp://ftp.example.com/        # List FTP directory / Список каталога FTP
curl -u user:pass -O ftp://ftp.example.com/file.zip  # Download via FTP / Скачать по FTP
curl -u user:pass -T backup.tar.gz sftp://sftp.example.com/in/  # Upload via SFTP / Загрузка по SFTP
curl --ssl-reqd -u user:pass ftp://ftp.example.com/  # Require TLS on FTP (FTPS) / Требовать TLS для FTP (FTPS)
curl --mail-from from@ex.com --mail-rcpt to@ex.com --upload-file msg.txt smtp://smtp.ex.com  # Send email via SMTP / Отправка письма по SMTP

# ====================== USEFUL COMBOS ======================
curl -sSL https://get.example.sh | bash         # Download & execute (be careful) / Скачивание и запуск (осторожно)
curl -fsSLo tool https://host/tool && chmod +x tool  # Quiet, fail on errors, save file / Тихо, падать при ошибках, сохранить
curl -s -o /dev/null -w '%{http_code}\n' https://example.com  # Status-only healthcheck / Проверка статуса
curl -s -D - -o /dev/null https://example.com   # Print response headers only / Печатать только заголовки ответа
curl -s https://ipinfo.io/ip                    # Print public IP / Показать внешний IP
curl -s https://icanhazip.com                   # Alternative public IP service / Альтернативный сервис внешнего IP

