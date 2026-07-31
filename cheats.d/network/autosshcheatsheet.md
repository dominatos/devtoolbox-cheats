---
Title: 🔁 autossh — Resilient SSH Tunnels
Group: Network
Icon: 🔁
Order: 10
tags:
  - network
  - sysadmin
  - linux
---

# autossh — Resilient SSH Tunnels

`autossh` is a program to start an SSH session and monitor it, automatically restarting the SSH session if it drops. It is commonly used for maintaining persistent SSH tunnels (port forwarding) across unreliable networks. It wraps the standard `ssh` command and adds automatic reconnection logic.

📚 **Official Docs / Официальная документация:** [autossh(1)](https://www.harding.motd.ca/autossh/)

## Table of Contents
- [Basic Tunneling](#Basic%20Tunneling)
- [Persistent Tunnels](#Persistent%20Tunnels)
- [Monitoring & Debugging](#Monitoring%20&%20Debugging)
- [Systemd Integration](#Systemd%20Integration)
- [Real-World Examples](#Real-World%20Examples)

---

## 🔧 Basic Tunneling

### Local Port Forwarding
```bash
autossh -M 0 -N -L 8080:127.0.0.1:80 <USER>@<HOST>  # Forward local 8080→remote 80 / Переслать локальный 8080→удалённый 80
autossh -M 0 -N -L 3306:localhost:3306 <USER>@<HOST>  # MySQL tunnel / MySQL туннель
autossh -M 0 -N -L 5432:localhost:5432 <USER>@<HOST>  # PostgreSQL tunnel / PostgreSQL туннель
autossh -M 0 -N -L 0.0.0.0:8080:localhost:80 <USER>@<HOST>  # Bind to all interfaces / Привязать ко всем интерфейсам
```

### Remote Port Forwarding
```bash
autossh -M 0 -N -R 2222:127.0.0.1:22 <USER>@<HOST>  # Forward remote 2222→local 22 / Переслать удалённый 2222→локальный 22
autossh -M 0 -N -R 8080:localhost:80 <USER>@<HOST>  # Expose local web server / Выставить локальный веб сервер
autossh -M 0 -N -R 0.0.0.0:9000:localhost:9000 <USER>@<HOST>  # Bind to all remote interfaces / Привязать ко всем удалённым интерфейсам
```

### Dynamic Port Forwarding (SOCKS)
```bash
autossh -M 0 -N -D 1080 <USER>@<HOST>          # SOCKS proxy on port 1080 / SOCKS прокси на порту 1080
autossh -M 0 -N -D 0.0.0.0:1080 <USER>@<HOST>  # SOCKS proxy on all interfaces / SOCKS прокси на всех интерфейсах
```

---

## 🔄 Persistent Tunnels

### Monitoring Options
```bash
autossh -M 0 -N -L 8080:localhost:80 <USER>@<HOST>  # Disable monitoring port (recommended) / Отключить порт мониторинга (рекомендуется)
autossh -M 20000 -N -L 8080:localhost:80 <USER>@<HOST>  # Use monitoring port 20000 / Использовать порт мониторинга 20000
```

### ServerAliveInterval
```bash
autossh -M 0 -N -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3" -L 8080:localhost:80 <USER>@<HOST>
# Check every 30s, fail after 3 attempts
```

### ExitOnForwardFailure
```bash
autossh -M 0 -N -o "ExitOnForwardFailure=yes" -L 8080:localhost:80 <USER>@<HOST>
# Exit if port forwarding fails
```

---

## 📊 Monitoring & Debugging

### Verbose Mode
```bash
autossh -M 0 -N -v -L 8080:localhost:80 <USER>@<HOST>  # Verbose / Подробный
autossh -M 0 -N -vv -L 8080:localhost:80 <USER>@<HOST>  # Very verbose / Очень подробный
```

### Environment Variables
```bash
export AUTOSSH_DEBUG=1                        # Enable debug / Включить отладку
export AUTOSSH_LOGFILE=/var/log/autossh.log   # Log to file / Логировать в файл
export AUTOSSH_POLL=60                        # Poll interval / Интервал опроса
export AUTOSSH_GATETIME=0                     # No wait before first connection / Не ждать перед первым соединением
```

### Check Connection
```bash
ps aux | grep autossh                         # Check if running / Проверить работает ли
netstat -tlnp | grep 8080                     # Check port / Проверить порт
ss -tlnp | grep 8080                          # Alternative / Альтернатива
```

---

## 🔧 Systemd Integration

### Create Systemd Service
```ini
# /etc/systemd/system/autossh-tunnel.service
[Unit]
Description=AutoSSH Tunnel
After=network.target

[Service]
Type=simple
User=<USER>
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3" -o "ExitOnForwardFailure=yes" -L 8080:localhost:80 <USER>@<HOST>
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Manage Service
```bash
sudo systemctl daemon-reload                  # Reload systemd / Перезагрузить systemd
sudo systemctl start autossh-tunnel           # Start service / Запустить сервис
sudo systemctl enable autossh-tunnel          # Enable on boot / Включить при загрузке
sudo systemctl status autossh-tunnel          # Check status / Проверить статус
sudo journalctl -u autossh-tunnel -f          # Follow logs / Следовать за логами
```

---

## 🌟 Real-World Examples

### Database Access
```bash
# MySQL tunnel / MySQL
autossh -M 0 -N -L 3306:127.0.0.1:3306 <USER>@<DB_SERVER>
# Connect: mysql -h 127.0.0.1 -P 3306

# PostgreSQL tunnel / PostgreSQL
autossh -M 0 -N -L 5432:localhost:5432 <USER>@<DB_SERVER>
# Connect: psql -h 127.0.0.1 -p 5432

# MongoDB tunnel / MongoDB
autossh -M 0 -N -L 27017:localhost:27017 <USER>@<DB_SERVER>
# Connect: mongosh --host 127.0.0.1 --port 27017
```

### Reverse Tunnel for Remote Access
```bash
# From local machine
autossh -M 0 -N -R 2222:localhost:22 <USER>@<JUMP_HOST>

# From jump host
ssh -p 2222 <LOCAL_USER>@localhost
```

### SOCKS Proxy for Browsing / SOCKS
```bash
# Start SOCKS proxy
autossh -M 0 -N -D 1080 <USER>@<PROXY_HOST>

# Configure browser
# SOCKS5: localhost:1080

# Or use with curl
curl --socks5 localhost:1080 https://api.example.com
```

### Multi-Hop Tunnel
```bash
# Via bastion host
autossh -M 0 -N -L 8080:internal-server:80 -J <USER>@<BASTION> <USER>@<INTERNAL>

# Alternative with ProxyJump
autossh -M 0 -N -o "ProxyJump=<USER>@<BASTION>" -L 8080:localhost:80 <USER>@<INTERNAL>
```

### Docker API Access
```bash
# Tunnel Docker socket
autossh -M 0 -N -L 2375:localhost:2375 <USER>@<DOCKER_HOST>

# Use Docker
export DOCKER_HOST=tcp://localhost:2375
docker ps
```

### Kubernetes API Access
```bash
# Tunnel K8s API
autossh -M 0 -N -L 6443:localhost:6443 <USER>@<K8S_MASTER>

# Use kubectl
kubectl --server=https://localhost:6443 get pods
```

### Web Development Preview
```bash
# Expose local dev server
autossh -M 0 -N -R 8080:localhost:3000 <USER>@<PUBLIC_SERVER>

# Access from: http://<PUBLIC_SERVER>:8080
```

### VNC Tunnel / VNC
```bash
# Tunnel VNC
autossh -M 0 -N -L 5900:localhost:5900 <USER>@<VNC_SERVER>

# Connect with VNC client
vncviewer localhost:5900
```

### Redis Tunnel / Redis
```bash
# Tunnel Redis
autossh -M 0 -N -L 6379:localhost:6379 <USER>@<REDIS_SERVER>

# Connect
redis-cli -h 127.0.0.1 -p 6379
```

### Multiple Tunnels in One Connection
```bash
autossh -M 0 -N \
  -L 3306:localhost:3306 \
  -L 5432:localhost:5432 \
  -L 6379:localhost:6379 \
  <USER>@<SERVER>
```

### SSH Config Integration
```bash
# ~/.ssh/config
Host tunnel
  HostName <HOST>
  User <USER>
  LocalForward 8080 localhost:80
  ServerAliveInterval 30
  ServerAliveCountMax 3
  ExitOnForwardFailure yes

# Use with autossh
autossh -M 0 -N tunnel
```

## 💡 Best Practices

- Always use `-M 0` (disable monitoring port) / Всегда используйте `-M 0` (отключить порт мониторинга)
- Set `ServerAliveInterval` for reliability / Устанавливайте `ServerAliveInterval` для надёжности
- Use systemd for persistent tunnels / Используйте systemd для постоянных туннелей
- Use SSH config for cleaner commands / Используйте SSH config для чистых команд
- Set `ExitOnForwardFailure=yes` for critical tunnels / Устанавливайте `ExitOnForwardFailure=yes` для критических туннелей

## 🔧 SSH Config Options

| Option | Description (EN / RU) |
|--------|----------------------|
| `ServerAliveInterval` | Keepalive interval / Интервал keepalive |
| `ServerAliveCountMax` | Max failed keepalives / Макс неудачных keepalive |
| `ExitOnForwardFailure` | Exit if forwarding fails / Выйти если переадресация не удалась |
| `LocalForward` | Local port forward / Локальная переадресация |
| `RemoteForward` | Remote port forward / Удалённая переадресация |
| `DynamicForward` | SOCKS proxy / SOCKS прокси |

## 📋 Common Use Cases

| Use Case | Flag |
|----------|------|
| Database access | `-L 3306:localhost:3306` |
| Web preview | `-R 8080:localhost:3000` |
| SOCKS proxy | `-D 1080` |
| Reverse shell | `-R 2222:localhost:22` |
| VNC access | `-L 5900:localhost:5900` |

## ⚠️ Security Notes

- Only bind to localhost when possible / Привязывайтесь только к localhost когда возможно
- Use SSH keys instead of passwords / Используйте SSH ключи вместо паролей
- Restrict port forwarding in `sshd_config` if needed / Ограничьте переадресацию портов в `sshd_config` если нужно
- Monitor for unauthorized tunnels / Мониторьте на несанкционированные туннели

## 📚 Documentation Links

- [autossh Man Page](https://www.harding.motd.ca/autossh/)
