Title: 📜 journalctl — Commands
Group: System & Logs
Icon: 📜
Order: 2

journalctl -xe                                  # Last errors with details / Последние ошибки подробно
journalctl -u ssh --since "2025-08-01" --until "2025-08-27"  # Unit logs range / Диапазон логов юнита
journalctl -k                                   # Kernel messages / Сообщения ядра
journalctl -f                                   # Follow (tail) the journal / «Хвост» журнала
journalctl --disk-usage                         # Journal disk usage summary / Использование места журналом

