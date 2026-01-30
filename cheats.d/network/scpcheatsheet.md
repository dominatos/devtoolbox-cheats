Title: 🔐 SCP — Commands
Group: Network
Icon: 🔐
Order: 7

scp file.txt user@host:/path/                   # Copy to remote / На удалённый хост
scp -r dir/ user@host:/path/                    # Copy directory recursively / Папку рекурсивно
scp user@host:/path/file.txt ./local/           # Copy from remote / С удалённого
scp -P 2222 -i ~/.ssh/id_ed25519 file user@host:/path/  # Custom port + key / Порт + ключ
scp -C big.iso user@host:/path/                 # Enable compression (-C) / Включить сжатие (-C)
scp -3 user1@host1:/p/file user2@host2:/p/      # Copy between remotes via local / Между удалёнными через локальный

