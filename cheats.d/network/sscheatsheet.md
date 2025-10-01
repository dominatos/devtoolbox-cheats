Title: 📡 SS — Socket Stats
Group: Network
Icon: 📡
Order: 2

ss -s                                          # Socket summary statistics / Сводка сокетов
ss -tulpn                                      # Listening TCP/UDP + PIDs (sudo for -p) / Слушающие TCP/UDP + PID
ss -ltn                                        # TCP listening sockets (numeric) / TCP слушающие (цифры)
ss -lun                                        # UDP listening sockets (numeric) / UDP слушающие (цифры)
ss -ant state established                      # Active established TCP connections / Установленные TCP-соединения
ss -plnt | grep ':80'                          # Process listening on TCP 80 / Процесс на 80 порту

