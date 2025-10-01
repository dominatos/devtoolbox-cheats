Title: 🕰️ systemd timers — Basics
Group: System & Logs
Icon: 🕰️
Order: 4

# my.timer (example) / пример
# [Unit] Description=Nightly job
# [Timer] OnCalendar=*-*-* 03:00:00 Persistent=true
# [Install] WantedBy=timers.target
sudo systemctl enable --now my.timer            # Enable & start / Включить и запустить
systemctl list-timers                           # List timers / Список таймеров
journalctl -u my.service -b                     # Logs of related service / Логи связанного сервиса

