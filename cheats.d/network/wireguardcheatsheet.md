Title: 🔐 WireGuard — VPN Setup
Group: Network
Icon: 🔐
Order: 9

## Table of Contents
- [Installation](#-installation--установка)
- [Key Generation](#-key-generation--генерация-ключей)
- [Configuration](#-configuration--конфигурация)
- [Interface Management](#-interface-management--управление-интерфейсами)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Server Setup](#-server-setup--настройка-сервера)
- [Client Setup](#-client-setup--настройка-клиента)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📥 Installation / Установка

### Ubuntu/Debian
```bash
sudo apt update && sudo apt install wireguard  # Install WireGuard / Установить WireGuard
sudo apt install wireguard-tools              # Install tools only / Только инструменты
```

### RHEL/AlmaLinux/Rocky
```bash
sudo dnf install epel-release                 # Enable EPEL / Включить EPEL
sudo dnf install wireguard-tools              # Install tools / Установить инструменты
sudo dnf install kmod-wireguard               # Install kernel module / Установить модуль ядра
```

### Verify Installation / Проверка установки
```bash
wg --version                                  # Check version / Проверить версию
sudo modprobe wireguard                       # Load module / Загрузить модуль
lsmod | grep wireguard                        # Verify module loaded / Проверить загрузку модуля
```

---

# 🔑 Key Generation / Генерация ключей

### Generate Keys / Генерация ключей
```bash
wg genkey | tee server.key | wg pubkey > server.pub  # Server keys / Ключи сервера
wg genkey | tee client.key | wg pubkey > client.pub  # Client keys / Ключи клиента
```

### Generate Preshared Key / Генерация предварительно разделённого ключа
```bash
wg genpsk > preshared.key                     # Preshared key (optional) / Предварительно разделённый ключ (опционально)
```

### Secure Key Files / Защита файлов ключей
```bash
chmod 600 server.key client.key preshared.key # Secure keys / Защитить ключи
sudo mkdir -p /etc/wireguard                  # Create config dir / Создать директорию конфигов
sudo mv *.key /etc/wireguard/                 # Move keys / Переместить ключи
sudo chmod 600 /etc/wireguard/*.key# Secure moved keys / Защитить перемещённые ключи
```

---

# ⚙️ Configuration / Конфигурация

### Server Config: /etc/wireguard/wg0.conf
```ini
[Interface]
Address = 10.0.0.1/24                         # VPN subnet / Подсеть VPN
ListenPort = 51820                            # UDP port / UDP порт
PrivateKey = <SERVER_PRIVATE_KEY>             # Server private key / Приватный ключ сервера

# NAT and IP forwarding / NAT и пересылка IP
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1 / Клиент 1
[Peer]
PublicKey = <CLIENT1_PUBLIC_KEY>              # Client public key / Публичный ключ клиента
AllowedIPs = 10.0.0.2/32                      # Client VPN IP / VPN IP клиента

# Client 2 / Клиент 2
[Peer]
PublicKey = <CLIENT2_PUBLIC_KEY>              # Client public key / Публичный ключ клиента
AllowedIPs = 10.0.0.3/32                      # Client VPN IP / VPN IP клиента
```

### Client Config: /etc/wireguard/wg0.conf
```ini
[Interface]
Address = 10.0.0.2/24                         # Client VPN IP / VPN IP клиента
PrivateKey = <CLIENT_PRIVATE_KEY>             # Client private key / Приватный ключ клиента
DNS = 1.1.1.1, 8.8.8.8                        # DNS servers / DNS серверы

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>               # Server public key / Публичный ключ сервера
Endpoint = <SERVER_IP>:51820                  # Server IP and port / IP и порт сервера
AllowedIPs = 0.0.0.0/0, ::/0                  # Route all traffic / Маршрутизировать весь трафик
PersistentKeepalive = 25                      # Keep connection alive / Поддерживать соединение
```

### Split-Tunnel Config (Client)
```ini
# Route only specific networks / Маршрутизировать только определённые сети
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24      # VPN subnets only / Только подсети VPN
```

---

# 🔧 Interface Management / Управление интерфейсами

### Start/Stop Interface / Запуск/остановка интерфейса
```bash
sudo wg-quick up wg0                          # Bring up wg0 / Поднять wg0
sudo wg-quick down wg0                        # Bring down wg0 / Опустить wg0
sudo wg-quick up /path/to/custom.conf         # Custom config / Пользовательская конфигурация
```

### Status and Information / Статус и информация
```bash
sudo wg show                                  # Show all interfaces / Показать все интерфейсы
sudo wg show wg0                              # Show specific interface / Показать конкретный интерфейс
sudo wg show wg0 dump                         # Dump full config / Выгрузить полную конфигурацию
sudo wg show wg0 peers                        # Show peers / Показать пиры
sudo wg show wg0 latest-handshakes            # Latest handshakes / Последние handshakes
sudo wg show wg0 transfer                     # Transfer stats / Статистика передачи
sudo wg show wg0 endpoints                    # Peer endpoints / Конечные точки пиров
```

### Enable on Boot / Включить при загрузке
```bash
sudo systemctl enable wg-quick@wg0            # Enable wg0 / Включить wg0
sudo systemctl start wg-quick@wg0             # Start wg0 / Запустить wg0
sudo systemctl status wg-quick@wg0            # Check status / Проверить статус
sudo systemctl restart wg-quick@wg0           # Restart wg0 / Перезапустить wg0
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Check Interface Status / Проверка статуса интерфейса
```bash
ip addr show wg0                              # Show wg0 IP / Показать IP wg0
ip route show                                 # Show routing table / Показать таблицу маршрутизации
sudo wg show wg0                              # WireGuard status / Статус WireGuard
```

### Test Connectivity / Тестирование подключения
```bash
ping 10.0.0.1                                 # Ping server VPN IP / Пинг VPN IP сервера
ping 10.0.0.2                                 # Ping client VPN IP / Пинг VPN IP клиента
traceroute 10.0.0.1                           # Trace route / Трассировка маршрута
```

### Check Firewall / Проверка файрвола
```bash
sudo iptables -L -n -v | grep wg0             # Check iptables rules / Проверить правила iptables
sudo ufw status                               # UFW status / Статус UFW
sudo ufw allow 51820/udp                      # Allow WireGuard port / Разрешить порт WireGuard
sudo firewall-cmd --add-port=51820/udp --permanent  # FirewallD (RHEL) / FirewallD (RHEL)
sudo firewall-cmd --reload                    # Reload firewall / Перезагрузить файрвол
```

### Check IP Forwarding / Проверка пересылки IP
```bash
sysctl net.ipv4.ip_forward                    # Check forwarding status / Проверить статус пересылки
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf  # Enable permanently / Включить постоянно
sudo sysctl -p                                # Apply sysctl changes / Применить изменения sysctl
```

### View Logs / Просмотр логов
```bash
sudo journalctl -u wg-quick@wg0 -f            # Follow logs / Следить за логами
sudo journalctl -u wg-quick@wg0 --since "10 minutes ago"  # Recent logs / Последние логи
dmesg | grep wireguard                        # Check kernel messages / Проверить сообщения ядра
```

### Dynamic Peer Management / Динамическое управление пирами
```bash
sudo wg set wg0 peer <PEER_PUBLIC_KEY> allowed-ips 10.0.0.4/32  # Add peer / Добавить пир
sudo wg set wg0 peer <PEER_PUBLIC_KEY> remove  # Remove peer / Удалить пир
sudo wg syncconf wg0 <(wg-quick strip wg0)    # Reload without restart / Перезагрузить без перезапуска
```

---

# 🖥️ Server Setup / Настройка сервера

### Complete Server Setup / Полная настройка сервера
```bash
# Generate server keys / Генерация ключей сервера
wg genkey | sudo tee /etc/wireguard/server.key | wg pubkey | sudo tee /etc/wireguard/server.pub
sudo chmod 600 /etc/wireguard/server.key

# Create server config / Создание конфигурации сервера
sudo tee /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(sudo cat /etc/wireguard/server.key)
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Enable IP forwarding / Включение пересылки IP
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Enable and start / Включить и запустить
sudo systemctl enable --now wg-quick@wg0
```

### Add Client to Server / Добавление клиента на сервер
```bash
# Add peer section to /etc/wireguard/wg0.conf
[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32

# Reload config / Перезагрузить конфигурацию
sudo wg syncconf wg0 <(wg-quick strip wg0)
```

---

# 💻 Client Setup / Настройка клиента

### Complete Client Setup / Полная настройка клиента
```bash
# Generate client keys / Генерация ключей клиента
wg genkey | tee client.key | wg pubkey > client.pub
chmod 600 client.key

# Create client config / Создание конфигурации клиента
cat > wg0.conf <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $(cat client.key)
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Install and start / Установить и запустить
sudo cp wg0.conf /etc/wireguard/
sudo wg-quick up wg0
```

---

# 🌟 Real-World Examples / Примеры из практики

### Site-to-Site VPN / VPN между сайтами
```ini
# Site A (10.1.0.0/24)
[Interface]
Address = 10.0.0.1/24
PrivateKey = <SITE_A_PRIVATE_KEY>
ListenPort = 51820

[Peer]
PublicKey = <SITE_B_PUBLIC_KEY>
Endpoint = <SITE_B_IP>:51820
AllowedIPs = 10.2.0.0/24                      # Site B subnet / Подсеть сайта B
PersistentKeepalive = 25
```

### Road Warrior Setup / Настройка для мобильных работников
```bash
# Server allows multiple clients / Сервер разрешает несколько клиентов
# Each client has unique IP in AllowedIPs
[Peer]
PublicKey = <CLIENT1_PUBLIC_KEY>
AllowedIPs = 10.0.0.10/32

[Peer]
PublicKey = <CLIENT2_PUBLIC_KEY>
AllowedIPs = 10.0.0.11/32

[Peer]
PublicKey = <CLIENT3_PUBLIC_KEY>
AllowedIPs = 10.0.0.12/32
```

### Multi-Hop VPN / Многоуровневый VPN
```bash
# Client → Server1 → Server2
# Client routes through Server1 to reach Server2
# Server1 acts as relay with proper routing and IP forwarding
```

### Docker Integration / Интеграция с Docker
```bash
# Access Docker containers via VPN / Доступ к Docker контейнерам через VPN
[Interface]
Address = 10.0.0.1/24
PostUp = iptables -A FORWARD -i wg0 -o docker0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o docker0 -j ACCEPT

[Peer]
AllowedIPs = 172.17.0.0/16, 10.0.0.2/32      # Docker подсеть + клиент
```

### QR Code for Mobile / QR-код для мобильных
```bash
# Install qrencode / Установить qrencode
sudo apt install qrencode

# Generate QR code / Генерация QR-кода
qrencode -t ansiutf8 < /etc/wireguard/client-mobile.conf
qrencode -o mobile.png < /etc/wireguard/client-mobile.conf  # Save as image / Сохранить как изображение
```

# 💡 Best Practices / Лучшие практики
# Use strong keys (default Ed25519) / Используйте сильные ключи (по умолчанию Ed25519)
# Enable PersistentKeepalive for NAT traversal / Включайте PersistentKeepalive для прохождения NAT
# Use split-tunnel when possible / Используйте split-tunnel когда возможно
# Regularly rotate keys / Регулярно меняйте ключи
# Monitor peer handshakes / Мониторьте handshakes пиров
# Use firewall rules to restrict access / Используйте правила файрвола для ограничения доступа

# 🔧 Configuration Paths / Пути конфигурации
# /etc/wireguard/          — Config directory / Директория конфигураций
# /etc/wireguard/wg0.conf  — Main config / Основная конфигурация
# /etc/wireguard/*.key     — Private keys / Приватные ключи
# /etc/wireguard/*.pub     — Public keys / Публичные ключи
