Title: 🔑 SSH — Commands & Config
Group: Network
Icon: 🔑
Order: 6

ssh -p 2222 -i ~/.ssh/id_ed25519 user@host      # Connect with custom port/key / Подключение с портом/ключом
ssh -J jump user@target                         # ProxyJump via bastion / Прокси-прыжок через бастион
ssh -L 8080:127.0.0.1:80 user@host              # Local port-forward / Локальный форвард порта
ssh -R 2222:127.0.0.1:22 user@host              # Remote port-forward / Обратный форвард
ssh-copy-id user@host                           # Install public key on server / Установить публичный ключ

ssh -J bastion user@target                                           # ProxyJump via bastion / Подключение через бастион (ProxyJump)
ssh -L 8080:127.0.0.1:80 user@host                                   # Local port-forward / Локальный проброс порта
ssh -R 2222:127.0.0.1:22 user@host                                   # Remote port-forward / Обратный проброс порта
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 user@host     # Keepalives / Пакеты поддержания соединения
ssh-copy-id user@host                                                # Install public key / Установить публичный ключ
scp -P 2222 -i ~/.ssh/id_ed25519 file user@host:/path/               # SCP with key & port / SCP с ключом и портом
scp -3 user1@host1:/p/file user2@host2:/p/                           # Copy between remotes via local / Копировать между серверами через локальную машину
rsync -avhn --delete src/ dest/                                      # Dry-run with deletion preview / Прогон без изменений с удалениями
rsync -avz -e "ssh -p 2222 -i ~/.ssh/id_ed25519" src/ user@host:/path/  # RSYNC over SSH (key+port) / RSYNC по SSH (ключ+порт)

# ~/.ssh/config                                  # Per-host config / Конфиг по хостам
Host my
  HostName host.example.com
  User user
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ProxyJump jump-host

