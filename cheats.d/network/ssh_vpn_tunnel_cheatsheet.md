Title: 🔑 SSH / VPN / Port Forwarding
Group: Network
Icon: 🔑
Order: 7
# SSH / VPN / Port Forwarding Шпаргалка

## 1️⃣ Основы SSH-туннелей

| Флаг | Значение | Пример |
|------|----------|--------|
| `-L [local_port]:[remote_host]:[remote_port]` | Локальный порт форвардится на удалённый | `ssh -L 2222:192.168.164.51:22 user@bastion` |
| `-R [remote_port]:[local_host]:[local_port]` | Обратный порт | `ssh -R 8080:localhost:80 user@bastion` |
| `-N` | Не открывать shell, только туннель | `ssh -N -L 9080:192.168.164.51:9080 user@bastion` |
| `-f` | Отправить SSH в фон | `ssh -f -N -L 9080:host:9080 user@bastion` |
| `-v` | Verbose (отладка) | `ssh -v -N -L ...` |

## 2️⃣ Проверка туннеля

```bash
# Проверка локальных портов
ss -tnlp | grep 9080
# или
netstat -tnlp | grep 9080

# Проверка доступности сервиса через туннель
curl http://localhost:9080
```

## 3️⃣ Настройка пользователя на bastion для безопасного туннеля

В `/etc/ssh/sshd_config`:

```ini
Match User gabriele
    PasswordAuthentication yes    # если нужен пароль
    AllowTcpForwarding yes        # разрешаем форвардинг
    PermitTTY no                  # запрет shell
    ForceCommand /bin/false       # нельзя логиниться напрямую
```

Перезапуск SSH после изменений:

```bash
sudo systemctl restart sshd
```

Установка пароля для пользователя:

```bash
sudo passwd gabriele
```

## 4️⃣ Unix-сокеты для SSH

```bash
# Создание master-сессии через сокет
ssh -fN -M -S /tmp/ssh.sock -L 2222:192.168.164.51:22 gabriele@10.18.61.28

# Повторное использование
ssh -S /tmp/ssh.sock user@localhost -p 2222
```

Позволяет коллегам подключаться через **туннель без VPN-пароля**.

## 5️⃣ Общие советы

- Если VPN требуется для доступа к серверу, порт 22 напрямую через туннель может не работать. Нужно, чтобы bastion был подключен к VPN.
- Для проверки соединения через VPN:

```bash
ssh user@192.168.164.51   # с bastion, который уже в VPN
```
- Если работает 9080, а 22 нет → значит внутренний сервер требует VPN-авторизацию.

## 6️⃣ Быстрое решение из чата

- Коллега получает доступ через tmux на bastion + 9080 порт:

```text
tmux attach -t needed_session
http://localhost:9080   # веб
```
- Быстро, без передачи VPN-пароля, и работает.

## 7️⃣ Полезные команды проверки

```bash
# Проверка, слушает ли порт на внутреннем сервере
ss -tnlp | grep :22
ss -tnlp | grep :9080

# Проверка доступа с bastion к внутреннему серверу
nc -zv 192.168.164.51 22
nc -zv 192.168.164.51 9080
```

