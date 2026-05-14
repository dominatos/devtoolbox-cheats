Title: 🔑 SSH Tunneling & Port Forwarding
Group: Network
Icon: 🔑
Order: 7

# SSH Tunneling & Port Forwarding

SSH tunneling (port forwarding) allows you to securely route network traffic through an encrypted SSH connection. This cheatsheet covers local, remote, and dynamic port forwarding, control sockets, bastion/jump host configuration, and real-world production scenarios.

📚 **Official Docs / Официальная документация:** [ssh(1)](https://man.openbsd.org/ssh)

## Table of Contents
- [SSH Tunnel Basics](#ssh-tunnel-basics)
- [Local Port Forwarding](#local-port-forwarding)
- [Remote Port Forwarding](#remote-port-forwarding)
- [Dynamic Port Forwarding (SOCKS)](#dynamic-port-forwarding-socks)
- [SSH Control Sockets](#ssh-control-sockets)
- [Bastion/Jump Host Configuration](#bastionjump-host-configuration)
- [Troubleshooting](#troubleshooting)
- [Real-World Examples](#real-world-examples)
- [Reference Tables](#reference-tables)

---

## SSH Tunnel Basics

### Common SSH Tunnel Flags / Распространённые флаги SSH-туннелей
```bash
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

## Local Port Forwarding

### Basic Syntax / Базовый синтаксис
```bash
ssh -L [LOCAL_IP:]<LOCAL_PORT>:<REMOTE_HOST>:<REMOTE_PORT> <USER>@<SSH_SERVER>
```

### Examples / Примеры
```bash
ssh -L 2222:192.168.164.51:22 <USER>@<BASTION>  # Forward local 2222 to remote SSH / Проброс локального 2222 на удалённый SSH
ssh -L 9080:<INTERNAL_HOST>:9080 <USER>@<BASTION>  # Forward web service / Проброс веб-сервиса
ssh -L 3306:<DB_SERVER>:3306 <USER>@<BASTION>  # Forward MySQL / Проброс MySQL
ssh -L 5432:<DB_SERVER>:5432 <USER>@<BASTION>  # Forward PostgreSQL / Проброс PostgreSQL
ssh -L 6379:<REDIS_SERVER>:6379 <USER>@<BASTION>  # Forward Redis / Проброс Redis
```

### Background Tunnel / Туннель в фоне
```bash
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <USER>@<BASTION>  # Background tunnel / Туннель в фоне
```

### Bind to Specific Interface / Привязка к конкретному интерфейсу
```bash
ssh -L 127.0.0.1:9080:<HOST>:9080 <USER>@<BASTION>  # Localhost only / Только localhost
ssh -L 0.0.0.0:9080:<HOST>:9080 <USER>@<BASTION>  # All interfaces / Все интерфейсы
```

---

## Remote Port Forwarding

### Basic Syntax / Базовый синтаксис
```bash
ssh -R [REMOTE_IP:]<REMOTE_PORT>:<LOCAL_HOST>:<LOCAL_PORT> <USER>@<SSH_SERVER>
```

### Examples / Примеры
```bash
ssh -R 8080:localhost:80 <USER>@<BASTION>  # Expose local web server / Открыть локальный веб-сервер
ssh -R 3000:localhost:3000 <USER>@<BASTION>  # Expose dev server / Открыть dev-сервер
ssh -R 5432:localhost:5432 <USER>@<BASTION>  # Expose local database / Открыть локальную БД
```

### Background Remote Tunnel / Обратный туннель в фоне
```bash
ssh -f -N -R 8080:localhost:80 <USER>@<BASTION>  # Background remote tunnel / Обратный туннель в фоне
```

---

## Dynamic Port Forwarding (SOCKS)

### SOCKS Proxy / SOCKS прокси
```bash
ssh -D <LOCAL_PORT> <USER>@<SSH_SERVER>  # Create SOCKS proxy / Создать SOCKS прокси
ssh -D 1080 <USER>@<BASTION>  # Standard SOCKS on port 1080 / Стандартный SOCKS на порту 1080
ssh -f -N -D 1080 <USER>@<BASTION>  # Background SOCKS proxy / SOCKS прокси в фоне
```

### Use with Applications / Использование с приложениями
```bash
# Configure browser / Настроить браузер
# SOCKS Host: localhost
# Port: 1080

# curl with SOCKS / curl с SOCKS
curl --socks5 localhost:1080 http://example.com
```

---

## SSH Control Sockets

### Create Master Session / Создать мастер-сессию
```bash
ssh -fNM -S /tmp/ssh.sock -L 2222:<INTERNAL_HOST>:22 <USER>@<BASTION>  # Create master with socket / Создать мастер с сокетом
```

### Reuse Session / Переиспользовать сессию
```bash
ssh -S /tmp/ssh.sock <USER>@localhost -p 2222  # Use existing tunnel / Использовать существующий туннель
```

### Control Master Session / Управлять мастер-сессией
```bash
ssh -S /tmp/ssh.sock -O check <USER>@<BASTION>  # Check status / Проверить статус
ssh -S /tmp/ssh.sock -O exit <USER>@<BASTION>  # Close master / Закрыть мастер
ssh -S /tmp/ssh.sock -O stop <USER>@<BASTION>  # Stop accepting connections / Остановить приём соединений
```

### SSH Config with ControlMaster / SSH конфиг с ControlMaster
`~/.ssh/config`

```bash
Host bastion
    HostName <BASTION_IP>
    User <USER>
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

---

## Bastion/Jump Host Configuration

### SSHD Configuration for Tunnel-Only User / Конфигурация SSHD для пользователя только с туннелями
`/etc/ssh/sshd_config`

```bash
Match User <TUNNEL_USER>
    PasswordAuthentication yes    # Allow password if needed / Разрешить пароль при необходимости
    AllowTcpForwarding yes        # Allow port forwarding / Разрешить проброс портов
    PermitTTY no                  # No shell access / Запретить shell
    ForceCommand /bin/false       # Block direct login / Заблокировать прямой логин
    X11Forwarding no              # Disable X11 / Отключить X11
    AllowAgentForwarding no       # Disable agent forwarding / Отключить проброс агента
```

```bash
sudo systemctl restart sshd  # Restart SSHD / Перезапустить SSHD
```

### Create Tunnel-Only User / Создать пользователя только для туннелей
```bash
sudo useradd -m -s /bin/false <TUNNEL_USER>  # Create user with no shell / Создать пользователя без shell
sudo passwd <TUNNEL_USER>                    # Set password / Установить пароль
```

### ProxyJump Configuration / Конфигурация ProxyJump
`~/.ssh/config`

```bash
Host internal-server
    HostName <INTERNAL_HOST>
    User <USER>
    ProxyJump <USER>@<BASTION>
```

---

## Troubleshooting

### Check Local Ports / Проверка локальных портов
```bash
ss -tnlp | grep <PORT>                       # Check listening ports / Проверить слушающие порты
netstat -tnlp | grep <PORT>                  # Alternative check / Альтернативная проверка
lsof -i :<PORT>                              # Show process using port / Показать процесс на порту
```

### Test Tunnel / Тестировать туннель
```bash
curl http://localhost:<LOCAL_PORT>           # Test HTTP service / Тестировать HTTP сервис
nc -zv localhost <LOCAL_PORT>                # Test port connectivity / Тестировать доступность порта
telnet localhost <LOCAL_PORT>                # Interactive test / Интерактивный тест
```

### Check Remote Service / Проверка удалённого сервиса
```bash
# From bastion / С бастион-хоста
nc -zv <INTERNAL_HOST> <PORT>                # Test connectivity to internal host / Тестировать доступность внутреннего хоста
ss -tnlp | grep :<PORT>                      # Check if service is listening / Проверить слушает ли сервис
```

### Debug SSH Tunnel / Отладка SSH туннеля
```bash
ssh -v -L <LOCAL_PORT>:<HOST>:<PORT> <USER>@<BASTION>  # Verbose output / Подробный вывод
ssh -vv -L <LOCAL_PORT>:<HOST>:<PORT> <USER>@<BASTION>  # More verbose / Ещё более подробно
ssh -vvv -L <LOCAL_PORT>:<HOST>:<PORT> <USER>@<BASTION>  # Maximum verbosity / Максимальная подробность
```

### Kill Stuck Tunnels / Убить зависшие туннели
```bash
ps aux | grep 'ssh.*-L'                      # Find tunnel processes / Найти процессы туннелей
pkill -f 'ssh.*-L.*<PORT>'                   # Kill specific tunnel / Убить конкретный туннель
```

> [!WARNING]
> `killall ssh` will terminate ALL SSH sessions, not just tunnels. Use `pkill -f` with a specific pattern instead. / `killall ssh` завершит ВСЕ SSH сессии. Используйте `pkill -f` с конкретным паттерном.

---

## Real-World Examples

### Access Internal Web Application / Доступ к внутреннему веб-приложению
```bash
# Forward internal web app to localhost:9080 / Проброс внутреннего веб-приложения на localhost:9080
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <USER>@<BASTION>

# Access in browser / Доступ в браузере
# http://localhost:9080
```

### Database Access Through Bastion / Доступ к БД через бастион
```bash
# MySQL tunnel / Туннель MySQL
ssh -f -N -L 3306:<DB_SERVER>:3306 <USER>@<BASTION>
mysql -h 127.0.0.1 -P 3306 -u <DB_USER> -p

# PostgreSQL tunnel / Туннель PostgreSQL
ssh -f -N -L 5432:<DB_SERVER>:5432 <USER>@<BASTION>
psql -h localhost -p 5432 -U <DB_USER> -d <DATABASE>
```

### Multi-Hop SSH Tunnel / Многоступенчатый SSH туннель
```bash
# Tunnel through multiple hops / Туннель через несколько прыжков
ssh -f -N -L 2222:<BASTION2>:22 <USER>@<BASTION1>
ssh -f -N -L 9080:<INTERNAL_HOST>:9080 <USER>@localhost -p 2222

# Or use ProxyJump / Или использовать ProxyJump
ssh -J <USER>@<BASTION1> -L 9080:<INTERNAL_HOST>:9080 <USER>@<BASTION2>
```

### Persistent Tunnel with AutoSSH / Постоянный туннель с AutoSSH
```bash
# Install autossh / Установить autossh
sudo apt install autossh

# Create persistent tunnel / Создать постоянный туннель
autossh -M 0 -f -N -L 9080:<HOST>:9080 <USER>@<BASTION>

# With monitoring / С мониторингом
autossh -M 20000 -f -N -L 9080:<HOST>:9080 <USER>@<BASTION>
```

### Expose Local Dev Server / Открыть локальный dev-сервер
```bash
# Make local service accessible from remote / Сделать локальный сервис доступным с удалённого
ssh -R 8080:localhost:3000 <USER>@<PUBLIC_SERVER>

# Now accessible at / Теперь доступен на
# http://<PUBLIC_SERVER>:8080
```

---

## Reference Tables

### Common Port Mappings / Распространённые проброс портов

| Service | Port | Typical Tunnel Command |
| :--- | :--- | :--- |
| SSH | 22 | `ssh -L 2222:host:22` |
| HTTP | 80 | `ssh -L 8080:host:80` |
| HTTPS | 443 | `ssh -L 8443:host:443` |
| MySQL | 3306 | `ssh -L 3306:host:3306` |
| PostgreSQL | 5432 | `ssh -L 5432:host:5432` |
| Redis | 6379 | `ssh -L 6379:host:6379` |
| MongoDB | 27017 | `ssh -L 27017:host:27017` |
| RDP | 3389 | `ssh -L 3389:host:3389` |
| VNC | 5900 | `ssh -L 5900:host:5900` |

### Configuration Files / Файлы конфигурации

| File | Description (EN / RU) |
| :--- | :--- |
| `~/.ssh/config` | Client SSH configuration / Клиентская конфигурация SSH |
| `/etc/ssh/sshd_config` | Server SSH configuration / Серверная конфигурация SSH |
| `~/.ssh/sockets/` | ControlMaster socket directory / Каталог сокетов ControlMaster |

> [!TIP]
> Use ControlMaster for connection reuse. Always use `-f -N` for background tunnels. Use ProxyJump instead of nested tunnels. Bind to localhost only unless sharing. / Используйте ControlMaster для переиспользования соединений. Используйте ProxyJump вместо вложенных туннелей.
