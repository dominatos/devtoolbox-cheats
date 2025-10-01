Title: 🧩 systemd unit — template
Group: System & Logs
Icon: 🧩
Order: 5

# /etc/systemd/system/myapp.service             # Unit file path / Путь к юниту
[Unit]
Description=My App                              # Human description / Описание
After=network-online.target                     # Start after network ready / После готовности сети
Wants=network-online.target                     # Ensure dependency is started / Запуск зависимости

[Service]
User=myuser                                     # Run as this user / Пользователь
ExecStart=/usr/local/bin/myapp --flag           # Start command / Команда запуска
Restart=on-failure                              # Restart on non-zero exit / Рестарт при ошибке
RestartSec=3s                                   # Wait before restart / Задержка перед рестартом
Environment=ENV=prod                            # Inject env var / Переменная окружения

[Install]
WantedBy=multi-user.target                      # Enable on multi-user boot / Запуск в multi-user

# Commands:
sudo systemctl daemon-reload                    # Reload unit files / Перезагрузить юниты
sudo systemctl enable --now myapp               # Enable and start service / Включить и запустить

