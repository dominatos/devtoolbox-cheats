Title: 🔁 autossh — Resilient tunnels
Group: Network
Icon: 🔁
Order: 10

autossh -M 0 -N -L 8080:127.0.0.1:80 user@host  # Local tunnel / Локальный туннель
autossh -M 0 -N -R 2222:127.0.0.1:22 user@host  # Reverse tunnel / Обратный туннель

