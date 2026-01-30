Title: 🔐 WireGuard — Quickstart
Group: Network
Icon: 🔐
Order: 9

wg genkey | tee server.key | wg pubkey > server.pub  # Generate keys / Сгенерировать ключи
sudo wg-quick up wg0                             # Bring up wg0 / Поднять wg0
sudo wg show                                     # Show status / Показать состояние

