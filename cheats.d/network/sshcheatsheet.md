Title: 🔑 SSH — Commands & Config
Group: Network
Icon: 🔑
Order: 6

## Table of Contents
- [Basic Connection](#-basic-connection--базовое-подключение)
- [Key Management](#-key-management--управление-ключами)
- [Port Forwarding & Tunnels](#-port-forwarding--tunnels--проброс-портов-и-туннели)
- [ProxyJump & Bastion](#-proxyjump--bastion--прокси-прыжок-и-бастион)
- [File Transfer (SCP/SFTP)](#-file-transfer-scpsftp--передача-файлов)
- [SSH Config](#-ssh-config--конфигурация-ssh)
- [Security & Hardening](#-security--hardening--безопасность-и-усиление)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔌 Basic Connection / Базовое подключение

```bash
ssh <USER>@<HOST>                              # Connect to host / Подключиться к хосту
ssh -p 2222 <USER>@<HOST>                      # Custom port / Нестандартный порт
ssh -i ~/.ssh/id_ed25519 <USER>@<HOST>         # Specific key / Определённый ключ
ssh -p 2222 -i ~/.ssh/id_ed25519 <USER>@<HOST>  # Port + key / Порт и ключ
ssh -o StrictHostKeyChecking=no <USER>@<HOST>  # Skip host key check / Пропустить проверку ключа
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 <USER>@<HOST>  # Keepalive / Поддержание соединения
ssh -v <USER>@<HOST>                           # Verbose (debug) / Подробный вывод
ssh -vv <USER>@<HOST>                          # More verbose / Ещё более подробный
ssh -vvv <USER>@<HOST>                         # Maximum verbosity / Максимальная подробность
```

# 🔑 Key Management / Управление ключами

```bash
ssh-keygen -t ed25519 -C "<USER>@<HOST>"       # Generate ED25519 key / Генерация ED25519 ключа
ssh-keygen -t rsa -b 4096 -C "<USER>@<HOST>"   # Generate RSA 4096 key / Генерация RSA 4096 ключа
ssh-copy-id <USER>@<HOST>                      # Install public key / Установить публичный ключ
ssh-copy-id -i ~/.ssh/id_ed25519.pub <USER>@<HOST>  # Install specific key / Установить конкретный ключ
ssh-copy-id -p 2222 <USER>@<HOST>              # With custom port / С нестандартным портом
ssh-add ~/.ssh/id_ed25519                      # Add key to agent / Добавить ключ в агент
ssh-add -l                                     # List added keys / Список добавленных ключей
ssh-add -D                                     # Remove all keys / Удалить все ключи
ssh-keygen -lf ~/.ssh/id_ed25519.pub           # Show key fingerprint / Показать отпечаток ключа
ssh-keygen -p -f ~/.ssh/id_ed25519             # Change passphrase / Изменить парольную фразу
ssh-keygen -R <HOST>                           # Remove host from known_hosts / Удалить хост из known_hosts
cat ~/.ssh/id_ed25519.pub                      # View public key / Просмотр публичного ключа
```

# 🚪 Port Forwarding & Tunnels / Проброс портов и туннели

```bash
ssh -L 8080:127.0.0.1:80 <USER>@<HOST>         # Local port forward / Локальный проброс порта
ssh -L 3306:<DB_HOST>:3306 <USER>@<HOST>       # Forward to remote DB / Проброс к удалённой БД
ssh -R 2222:127.0.0.1:22 <USER>@<HOST>         # Remote port forward / Обратный проброс порта
ssh -D 1080 <USER>@<HOST>                      # SOCKS proxy / SOCKS прокси
ssh -N -L 8080:127.0.0.1:80 <USER>@<HOST>      # No command (tunnels only) / Только туннели
ssh -f -N -L 8080:127.0.0.1:80 <USER>@<HOST>   # Background tunnel / Туннель в фоне
ssh -L 8080:localhost:80 -L 8443:localhost:443 <USER>@<HOST>  # Multiple tunnels / Несколько туннелей
ssh -R 0:localhost:8080 <USER>@<HOST>          # Auto-assign remote port / Автоматический выбор порта
```

# 🏰 ProxyJump & Bastion / Прокси-прыжок и бастион

```bash
ssh -J <BASTION_USER>@<BASTION> <USER>@<TARGET>  # ProxyJump via bastion / Прыжок через бастион
ssh -J <USER>@<BASTION>:2222 <USER>@<TARGET>   # Bastion with port / Бастион с портом
ssh -J <USER1>@<BASTION1>,<USER2>@<BASTION2> <USER>@<TARGET>  # Chain jumps / Цепочка прыжков
ssh -o ProxyCommand="ssh -W %h:%p <USER>@<BASTION>" <USER>@<TARGET>  # Proxy command / Команда прокси
```

# 📁 File Transfer (SCP/SFTP) / Передача файлов

```bash
scp file.txt <USER>@<HOST>:/path/              # Copy file to remote / Копировать файл на удалённый сервер
scp <USER>@<HOST>:/remote/file.txt ./          # Copy from remote / Копировать с удалённого сервера
scp -r dir/ <USER>@<HOST>:/path/               # Copy directory / Копировать каталог
scp -P 2222 file.txt <USER>@<HOST>:/path/      # SCP with port / SCP с портом
scp -i ~/.ssh/id_ed25519 file.txt <USER>@<HOST>:/path/  # SCP with key / SCP с ключом
scp -3 <USER1>@<HOST1>:/file <USER2>@<HOST2>:/path/  # Copy between remotes / Копировать между серверами
sftp <USER>@<HOST>                             # Start SFTP session / Начать SFTP сессию
sftp -P 2222 <USER>@<HOST>                     # SFTP with port / SFTP с портом
```

# ⚙️ SSH Config / Конфигурация SSH

```bash
# ~/.ssh/config example / Пример ~/.ssh/config
Host myserver
  HostName <HOST>
  User <USER>
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 3

Host bastion
  HostName <BASTION_HOST>
  User <USER>
  IdentityFile ~/.ssh/bastion_key

Host production
  HostName <PROD_HOST>
  User <USER>
  ProxyJump bastion
  IdentityFile ~/.ssh/prod_key

Host *.internal
  ProxyJump bastion
  User <USER>

Host *
  AddKeysToAgent yes
  UseKeychain yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

# 🔒 Security & Hardening / Безопасность и усиление

```bash
ssh-keygen -t ed25519 -a 100                   # Ed25519 with KDF rounds / Ed25519 с раундами KDF
ssh -o PubkeyAuthentication=yes -o PasswordAuthentication=no <USER>@<HOST>  # Key-only auth / Только ключи
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 <USER>@<HOST>  # Use only specified key / Только указанный ключ
chmod 700 ~/.ssh                               # Secure SSH directory / Защитить каталог SSH
chmod 600 ~/.ssh/id_ed25519                    # Secure private key / Защитить приватный ключ
chmod 644 ~/.ssh/id_ed25519.pub                # Secure public key / Защитить публичный ключ
chmod 600 ~/.ssh/authorized_keys               # Secure authorized_keys / Защитить authorized_keys
chmod 600 ~/.ssh/config                        # Secure config / Защитить конфиг
```

# 🔧 Troubleshooting / Устранение неполадок

```bash
ssh -vvv <USER>@<HOST>                         # Maximum debug output / Максимальная отладка
ssh -o ConnectTimeout=10 <USER>@<HOST>         # Connection timeout / Таймаут подключения
ssh -o ConnectionAttempts=3 <USER>@<HOST>      # Retry attempts / Попытки повтора
ssh -T <USER>@<HOST>                           # No PTY allocation / Без выделения PTY
ssh -t <USER>@<HOST> "command"                 # Force PTY / Принудительно PTY
ssh -Q cipher                                  # List supported ciphers / Список поддерживаемых шифров
ssh -Q mac                                     # List supported MACs / Список поддерживаемых MAC
ssh -Q kex                                     # List supported key exchanges / Список поддерживаемых обменов ключами
cat ~/.ssh/known_hosts                         # View known hosts / Просмотр известных хостов
ssh-keyscan <HOST> >> ~/.ssh/known_hosts       # Add host key / Добавить ключ хоста
```

# 🌟 Real-World Examples / Примеры из практики

```bash
ssh -L 3306:localhost:3306 <USER>@<DB_HOST> -N -f  # MySQL tunnel background / Туннель MySQL в фоне
ssh -D 1080 -N -f <USER>@<HOST> && export http_proxy=socks5://127.0.0.1:1080  # SOCKS proxy setup / Настройка SOCKS прокси
ssh <USER>@<HOST> "docker logs -f <CONTAINER>" # Follow remote logs / Следить за удалёнными логами
ssh <USER>@<HOST> "journalctl -u nginx -f"     # Follow remote journal / Следить за удалённым журналом
rsync -avz -e "ssh -p 2222 -i ~/.ssh/id_ed25519" src/ <USER>@<HOST>:/dst/  # Rsync over SSH / Rsync через SSH
ssh <USER>@<HOST> "tar czf - /path" | tar xzf - -C ./backup  # Remote tar backup / Удалённый tar бэкап
ssh -L 5900:localhost:5900 <USER>@<HOST>       # VNC tunnel / VNC туннель
ssh -J <USER>@<BASTION> <USER>@<TARGET> "uptime"  # Command via bastion / Команда через бастион
for host in <HOST1> <HOST2> <HOST3>; do ssh <USER>@$host "uptime"; done  # Execute on multiple hosts / Выполнить на нескольких хостах
ssh <USER>@<HOST> 'bash -s' < local_script.sh  # Run local script remotely / Запустить локальный скрипт удалённо
```

# 🔄 SSH Agent Forwarding / Проброс SSH-агента

```bash
ssh -A <USER>@<HOST>                           # Enable agent forwarding / Включить проброс агента
# In ~/.ssh/config:
# ForwardAgent yes
```

# 🚀 Advanced Techniques / Продвинутые техники

```bash
ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlPersist=10m <USER>@<HOST>  # Connection multiplexing / Мультиплексирование
ssh -o 'RemoteCommand=tmux attach || tmux new' <USER>@<HOST>  # Auto tmux / Автоматический tmux
autossh -M 0 -N -L 8080:localhost:80 <USER>@<HOST>  # Auto-reconnecting tunnel / Авто-переподключаемый туннель
```
