Title: 🔑 SSH Tunneling & Port Forwarding
Group: Network
Icon: 🔑
Order: 7

## Table of Contents
- [SSH Tunnel Basics](#-ssh-tunnel-basics--основы-ssh-туннелей)
- [Local Port Forwarding](#-local-port-forwarding--локальный-проброс-портов)
- [Remote Port Forwarding](#-remote-port-forwarding--обратный-проброс-портов)
- [Dynamic Port Forwarding (SOCKS)](#-dynamic-port-forwarding-socks--динамический-проброс-socks)
- [SSH Control Sockets](#-ssh-control-sockets--управляющие-сокеты-ssh)
- [Bastion/Jump Host Configuration](#-bastionjump-host-configuration--настройка-бастион-хоста)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примерыиз-практики)

---

# 📘 SSH Tunnel Basics / Основы SSH-туннелей

### Common SSH Tunnel Flags / Распространённые флаги SSH-туннелей
```
-L [local_port]:[remote_host]:[remote_port]  # Local port forwarding / Локальный порт форвардится на удалённый
-R [remote_port]:[local_host]:[local_port]   # Remote port forwarding / Обратный порт
-D [local_port]                              # Dynamic SOCKS proxy / Динамический SOCKS прокси
-N                                            # No shell, tunnel only / Не открывать shell, только туннель
-f                                            # Background mode / Отправить SSH в фон
-v                                            # Verbose (debug mode) / Подробный вывод (отладка)
-M                                            # Master mode / Мастер-режим
-S <socket>                                   # Control socket / Управляющий сокет
```

---

# 🔀 Local Port Forwarding / Локальный проброс портов

### Basic Syntax / Базовый синтаксис
ssh -L [LOCAL_IP:]<LOCAL_PORT>:<REMOTE_HOST>:<REMOTE_PORT> <user>@<SSH_SERVER>

### Examples / Примеры
ssh -L 2222:192.168.164.51:22 <user>@<BASTION>  # Forward local 2222 to remote SSH / Проброс локального 2222 на удалённый SSH
ssh -L 9080:<INTERNAL_HOST>:9080 <user>@<BASTION>  # Forward web service / Проброс веб-сервиса
ssh -L 3306:<DB_SERVER>:3306 <user>@<BASTION>  # Forward MySQL / Проброс MySQL
ssh -L 5432:<DB_SERVER>:5432 <user>@<BASTION>  # Forward PostgreSQL / Проброс PostgreSQL
ssh -L 6379:<REDIS_SERVER>:6379 <user>@<BASTION>  # Forward Redis / Проброс Redis

### Background Tunnel / Туннель в фоне
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <user>@<BASTION>  # Background tunnel / Туннель в фоне

### Bind to Specific Interface / Привязка к конкретному интерфейсу
ssh -L 127.0.0.1:9080:<HOST>:9080 <user>@<BASTION>  # Localhost only / Только localhost
ssh -L 0.0.0.0:9080:<HOST>:9080 <user>@<BASTION>  # All interfaces / Все интерфейсы

---

# 🔁 Remote Port Forwarding / Обратный проброс портов

### Basic Syntax / Базовый синтаксис
ssh -R [REMOTE_IP:]<REMOTE_PORT>:<LOCAL_HOST>:<LOCAL_PORT> <user>@<SSH_SERVER>

### Examples / Примеры
ssh -R 8080:localhost:80 <user>@<BASTION>  # Expose local web server / Открыть локальный веб-сервер
ssh -R 3000:localhost:3000 <user>@<BASTION>  # Expose dev server / Открыть dev-сервер
ssh -R 5432:localhost:5432 <user>@<BASTION>  # Expose local database / Открыть локальную БД

### Background Remote Tunnel / Обратный туннель в фоне
ssh -f -N -R 8080:localhost:80 <user>@<BASTION>  # Background remote tunnel / Обратный туннель в фоне

---

# 🌐 Dynamic Port Forwarding (SOCKS) / Динамический проброс (SOCKS)

### SOCKS Proxy / SOCKS прокси
ssh -D <LOCAL_PORT> <user>@<SSH_SERVER>  # Create SOCKS proxy / Создать SOCKS прокси
ssh -D 1080 <user>@<BASTION>  # Standard SOCKS on port 1080 / Стандартный SOCKS на порту 1080
ssh -f -N -D 1080 <user>@<BASTION>  # Background SOCKS proxy / SOCKS прокси в фоне

### Use with Applications / Использование с приложениями
# Configure browser / Настроить браузер
# SOCKS Host: localhost
# Port: 1080

# curl with SOCKS / curl с SOCKS
curl --socks5 localhost:1080 http://example.com

---

# 🎛️ SSH Control Sockets / Управляющие сокеты SSH

### Create Master Session / Создать мастер-сессию
ssh -fNM -S /tmp/ssh.sock -L 2222:<INTERNAL_HOST>:22 <user>@<BASTION>  # Create master with socket / Создать мастер с сокетом

### Reuse Session / Переиспользовать сессию
ssh -S /tmp/ssh.sock <user>@localhost -p 2222  # Use existing tunnel / Использовать существующий туннель

### Control Master Session / Управлять мастер-сессией
ssh -S /tmp/ssh.sock -O check <user>@<BASTION>  # Check status / Проверить статус
ssh -S /tmp/ssh.sock -O exit <user>@<BASTION>  # Close master / Закрыть мастер
ssh -S /tmp/ssh.sock -O stop <user>@<BASTION>  # Stop accepting connections / Остановить приём соединений

### SSH Config with ControlMaster / SSH конфиг с ControlMaster
```
Host bastion
    HostName <BASTION_IP>
    User <USER>
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

---

# 🛡️ Bastion/Jump Host Configuration / Настройка бастион-хоста

### SSHD Configuration for Tunnel-Only User / Конфигурация SSHD для пользователя только с туннелями
```bash
# Edit /etc/ssh/sshd_config / Редактировать /etc/ssh/sshd_config
sudo vim /etc/ssh/sshd_config

# Add match block / Добавить блок Match
Match User <TUNNEL_USER>
    PasswordAuthentication yes    # Allow password if needed / Разрешить пароль при необходимости
    AllowTcpForwarding yes        # Allow port forwarding / Разрешить проброс портов
    PermitTTY no                  # No shell access / Запретить shell
    ForceCommand /bin/false       # Block direct login / Заблокировать прямой логин
    X11Forwarding no              # Disable X11 / Отключить X11
    AllowAgentForwarding no       # Disable agent forwarding / Отключить проброс агента

# Restart SSHD / Перезапустить SSHD
sudo systemctl restart sshd
```

### Create Tunnel-Only User / Создать пользователя только для туннелей
sudo useradd -m -s /bin/false <TUNNEL_USER>  # Create user with no shell / Создать пользователя без shell
sudo passwd <TUNNEL_USER>                    # Set password / Установить пароль

### ProxyJump Configuration / Конфигурация ProxyJump
```
# SSH config with ProxyJump / SSH конфиг с ProxyJump
Host internal-server
    HostName <INTERNAL_HOST>
    User <USER>
    ProxyJump <user>@<BASTION>
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Check Local Ports / Проверка локальных портов
ss -tnlp | grep <PORT>                       # Check listening ports / Проверить слушающие порты
netstat -tnlp | grep <PORT>                  # Alternative check / Альтернативная проверка
lsof -i :<PORT>                              # Show process using port / Показать процесс на порту

### Test Tunnel / Тестировать туннель
curl http://localhost:<LOCAL_PORT>           # Test HTTP service / Тестировать HTTP сервис
nc -zv localhost <LOCAL_PORT>                # Test port connectivity / Тестировать доступность порта
telnet localhost <LOCAL_PORT>                # Interactive test / Интерактивный тест

### Check Remote Service / Проверка удалённого сервиса
# From bastion / С бастион-хоста
nc -zv <INTERNAL_HOST> <PORT>                # Test connectivity to internal host / Тестировать доступность внутреннего хоста
ss -tnlp | grep :<PORT>                      # Check if service is listening / Проверить слушает ли сервис

### Debug SSH Tunnel / Отладка SSH туннеля
ssh -v -L <LOCAL_PORT>:<HOST>:<PORT> <user>@<BASTION>  # Verbose output / Подробный вывод
ssh -vv -L <LOCAL_PORT>:<HOST>:<PORT> <user>@<BASTION>  # More verbose / Ещё более подробно
ssh -vvv -L <LOCAL_PORT>:<HOST>:<PORT> <user>@<BASTION>  # Maximum verbosity / Максимальная подробность

### Kill Stuck Tunnels / Убить зависшие туннели
ps aux | grep 'ssh.*-L'                      # Find tunnel processes / Найти процессы туннелей
pkill -f 'ssh.*-L.*<PORT>'                   # Kill specific tunnel / Убить конкретный туннель
killall ssh                                  # Kill all SSH (dangerous) / Убить все SSH (опасно)

---

# 🌟 Real-World Examples / Примеры из практики

### Access Internal Web Application / Доступ к внутреннему веб-приложению
```bash
# Forward internal web app to localhost:9080 / Проброс внутреннего веб-приложения на localhost:9080
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <user>@<BASTION>

# Access in browser / Доступ в браузере
# http://localhost:9080
```

### Database Access Through Bastion / Доступ к БД через бастион
```bash
# MySQL tunnel / Туннель MySQL
ssh -f -N -L 3306:<DB_SERVER>:3306 <user>@<BASTION>
mysql -h 127.0.0.1 -P 3306 -u <DB_USER> -p

# PostgreSQL tunnel / Туннель PostgreSQL
ssh -f -N -L 5432:<DB_SERVER>:5432 <user>@<BASTION>
psql -h localhost -p 5432 -U <DB_USER> -d <DATABASE>
```

### Multi-Hop SSH Tunnel / Многоступенчатый SSH туннель
```bash
# Tunnel through multiple hops / Туннель через несколько прыжков
ssh -f -N -L 2222:<BASTION2>:22 <user>@<BASTION1>
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <user>@localhost -p 2222

# Or use ProxyJump / Или использовать ProxyJump
ssh -J <user>@<BASTION1> -L 9080:<INTERNAL_HOST>:9080 <user>@<BASTION2>
```

### Share Tunnel with Team / Поделиться туннелем с командой
```bash
# Create shared tunnel using tmux / Создать общий туннель через tmux
# On bastion / На бастион-хосте
tmux new -s shared_tunnel
ssh -L 0.0.0.0:9080:<INTERNAL_HOST>:9080 <user>@<JUMP_HOST>

# Colleagues attach / Коллеги подключаются
tmux attach -t shared_tunnel
# Access: http://localhost:9080
```

### Persistent Tunnel with AutoSSH / Постоянный туннель с AutoSSH
```bash
# Install autossh / Установить autossh
sudo apt install autossh

# Create persistent tunnel / Создать постоянный туннель
autossh -M 0 -f -N -L 9080:<HOST>:9080 <user>@<BASTION>

# With monitoring / С мониторингом
autossh -M 20000 -f -N -L 9080:<HOST>:9080 <user>@<BASTION>
```

### Expose Local Dev Server / Открыть локальный dev-сервер
```bash
# Make local service accessible from remote / Сделать локальный сервис доступным с удалённого
ssh -R 8080:localhost:3000 <user>@<PUBLIC_SERVER>

# Now accessible at / Теперь доступен на
# http://<PUBLIC_SERVER>:8080
```

---

# 💡 Best Practices / Лучшие практики
# Use ControlMaster for connection reuse / Используйте ControlMaster для переиспользования соединений
# Always use -f -N for background tunnels / Всегда используйте -f -N для фоновых туннелей
# Restrict tunnel users with ForceCommand / Ограничивайте пользователей туннелей через ForceCommand
# Monitor tunnel health with autossh / Мониторьте здоровье туннелей с autossh
# Use ProxyJump instead of nested tunnels / Используйте ProxyJump вместо вложенных туннелей
# Bind to localhost only unless sharing / Привязывайте к localhost если не делитесь
# Document tunnel mappings for team / Документируйте проброс портов для команды

# 🔧 Configuration Files / Файлы конфигурации
# ~/.ssh/config                             — Client SSH configuration / Клиентская конфигурация SSH
# /etc/ssh/sshd_config                      — Server SSH configuration / Серверная конфигурация SSH
# ~/.ssh/sockets/                           — ControlMaster socket directory / Каталог сокетов ControlMaster

# 📋 Common Port Mappings / Распространённые проброс портов
# SSH: 22, HTTP: 80, HTTPS: 443
# MySQL: 3306, PostgreSQL: 5432
# Redis: 6379, MongoDB: 27017
# RDP: 3389, VNC: 5900
