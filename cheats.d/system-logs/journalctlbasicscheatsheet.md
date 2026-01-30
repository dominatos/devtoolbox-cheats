Title: 📜 journalctl — Basics
Group: System & Logs
Icon: 📜
Order: 3

# Viewing / Просмотр
journalctl -xe                                   # Recent errors / Последние ошибки (расширенно)
journalctl -f                                    # Follow / «Хвост» в реальном времени
journalctl -u nginx                              # Unit logs / Логи юнита nginx
journalctl -u nginx -f --since "1 hour ago"      # Last hour follow / Последний час (follow)

# Time ranges / Диапазоны времени
journalctl --since "2025-08-01" --until "2025-08-27"  # Range / Диапазон
journalctl -b                                    # Since current boot / С текущей загрузки
journalctl -b -1                                 # Previous boot / С предыдущей загрузки

# Filters / Фильтры
journalctl -p warning..emerg                     # Levels ≥ warning / Уровни ≥ warning
journalctl _PID=1234                             # By PID / По PID
journalctl _SYSTEMD_UNIT=ssh.service             # By unit field / По полю unit

# Output / Вывод
journalctl -u app.service -n 200                 # Last 200 lines / Последние 200 строк
journalctl -u app.service -o json-pretty         # JSON output / JSON вывод
journalctl -u app.service > app.log              # Save to file / Сохранить в файл

# Persistent storage / Персистентность
# sudo mkdir -p /var/log/journal && sudo systemd-tmpfiles --create --prefix /var/log/journal  # Enable persistent / Включить персистентность

