Title: 🍯 SSH Honeypot + CrowdSec
Group: Security & Crypto
Icon: 🍯
Order: 99

# SSH Honeypot + CrowdSec Sysadmin Cheatsheet

> **Context:** This guide covers deploying a Cowrie SSH honeypot on port 22 while moving the real SSH service to a non-standard port. Cowrie emulates a vulnerable SSH server, logging attacker commands and credentials. Combined with CrowdSec, attacking IPs are automatically banned via firewall rules and optionally shared with the community blocklist. / Руководство по развёртыванию SSH-ловушки Cowrie на порту 22 с переносом реального SSH на нестандартный порт. Cowrie эмулирует уязвимый SSH-сервер, логируя команды и пароли атакующих. В связке с CrowdSec атакующие IP автоматически банятся.
> **Role:** Security Engineer / Sysadmin
> **See also:** [CrowdSec](crowdseccheatsheet.md), [SSH Keys](ssh_keys_cheatsheet.md)

---

## 📚 Table of Contents / Содержание

1. [Overview](#1-overview)
2. [Install Docker](#2-install-docker)
3. [Move Real SSH to Port 2222](#3-move-real-ssh-to-port-2222)
4. [Install Cowrie Honeypot](#4-install-cowrie-honeypot)
5. [Save Honeypot Logs](#5-save-honeypot-logs)
6. [Install CrowdSec](#6-install-crowdsec)
7. [Install Cowrie Parser](#7-install-cowrie-parser)
8. [Community Integration](#8-community-integration)
9. [Web Dashboard](#9-web-dashboard)
10. [Verify Detection & Firewall](#10-verify-detection--firewall)
11. [Cowrie Log Analysis Script](#11-cowrie-log-analysis-script)
12. [Documentation Links](#12-documentation-links)

---

## 1. Overview

> **Goal / Цель:**
> - Real SSH runs on port **2222** / Реальный SSH работает на порту **2222**
> - Port **22** becomes a **Cowrie honeypot** / Порт **22** становится **ловушкой Cowrie**
> - **CrowdSec** automatically bans attacking IPs / **CrowdSec** автоматически банит атакующие IP
> - Logs saved and optionally sent to CrowdSec community blocklist / Логи сохраняются и отправляются в CrowdSec
> - Optional web dashboard and GeoIP visualization / Опциональная веб-панель и визуализация GeoIP

### Architecture / Архитектура

```text
Internet
   |
   v
Port 22  ---> Cowrie Honeypot ---> Logs & GeoIP Dashboard
   |
   v
CrowdSec detection
   |
   v
Firewall ban & optional Community feed

Real admin access:
Port 2222 ---> OpenSSH
```

---

## 2. Install Docker

```bash
sudo apt update                                           # Update packages / Обновить пакеты
sudo apt install -y docker.io                             # Install Docker / Установить Docker
sudo systemctl enable --now docker                        # Enable & start / Включить и запустить
docker --version                                          # Verify install / Проверить установку
```

---

## 3. Move Real SSH to Port 2222

> [!CAUTION]
> Open firewall for the new SSH port **before** disconnecting from the current session!
> Откройте порт в файрволе **до** отключения от текущей сессии!

### Edit SSH Config / Редактирование конфига SSH

`/etc/ssh/sshd_config`

```bash
Port 2222
```

### Apply Changes / Применить изменения

```bash
sudo ufw allow 2222/tcp                                   # Open firewall / Открыть файрвол
sudo systemctl restart ssh                                # Restart SSH / Перезапустить SSH
ssh <USER>@<HOST> -p 2222                                 # Test login / Тестовый вход
```

---

## 4. Install Cowrie Honeypot

```bash
docker pull cowrie/cowrie                                  # Pull image / Скачать образ
docker run -d --name cowrie \
  -p 22:2222 \
  --restart unless-stopped \
  cowrie/cowrie                                            # Run on port 22 / Запустить на порту 22
docker ps                                                 # Check container / Проверить контейнер
```

---

## 5. Save Honeypot Logs

```bash
# Run with persistent logs / Запуск с постоянными логами
docker run -d --name cowrie \
  -p 22:2222 \
  -v /opt/cowrie/log:/cowrie/var/log/cowrie \
  --restart unless-stopped \
  cowrie/cowrie

ls /opt/cowrie/log                                        # Access logs / Доступ к логам
```

---

## 6. Install CrowdSec

```bash
curl -s https://install.crowdsec.net | sudo sh            # Add repo / Добавить репозиторий
sudo apt install -y crowdsec                              # Install CrowdSec / Установить CrowdSec
sudo apt install -y crowdsec-firewall-bouncer-iptables    # Install bouncer / Установить bouncer
sudo systemctl status crowdsec                            # Check status / Проверить статус
```

---

## 7. Install Cowrie Parser

```bash
sudo cscli collections install crowdsecurity/cowrie       # Install collection / Установить коллекцию
sudo systemctl restart crowdsec                           # Restart CrowdSec / Перезапустить CrowdSec
```

---

## 8. Community Integration

```bash
sudo cscli hub update                                     # Update hub / Обновить хаб
sudo cscli hub install crowdsecurity/lapi                  # Install LAPI / Установить LAPI
```

---

## 9. Web Dashboard

```bash
docker run -d -p 8080:8080 \
  --name cowrie-web \
  --link cowrie:db \
  cowrie/cowrie-web                                        # Start dashboard / Запустить панель
```

Access / Доступ: `http://<HOST>:8080`

> [!TIP]
> Use Python script or Kibana to parse `/opt/cowrie/log/cowrie.json` and plot IPs on a GeoIP map.
> Используйте Python-скрипт или Kibana для парсинга логов и отображения IP на карте.

---

## 10. Verify Detection & Firewall

```bash
sudo cscli decisions list                                  # Active bans / Активные баны
sudo cscli alerts list                                     # Alert history / История алертов
sudo cscli metrics                                         # CrowdSec metrics / Метрики CrowdSec
sudo iptables -L -n                                        # Firewall rules / Правила файрвола
sudo cscli bouncers list                                   # Registered bouncers / Зарегистрированные bouncer'ы
```

### Useful Commands / Полезные команды

```bash
sudo cscli alerts list -o human                            # Top attackers / Топ атакующих
sudo cscli decisions delete --ip <IP>                      # Unban IP / Разбанить IP
sudo cscli scenarios list                                  # List scenarios / Список сценариев
```

---

## 11. Cowrie Log Analysis Script

### watch_cowrie_commands.py

```python
#!/usr/bin/env python3
"""Watch Cowrie Honeypot Commands.

Reads Cowrie logs and prints top commands entered by attacking IPs.
Скрипт читает логи Cowrie и выводит топ команд атакующих IP.
"""

import json
from pathlib import Path
from collections import Counter

log_dir = Path("/opt/cowrie/log")              # Path to Cowrie logs / Путь к логам
commands = Counter()

for log_file in log_dir.glob("cowrie.json*"):
    with log_file.open() as f:
        for line in f:
            try:
                evt = json.loads(line)
                if evt.get("eventid") == "cowrie.command.input":
                    ip = evt.get("src_ip", "")
                    cmd = evt.get("input", "").strip()
                    commands[(ip, cmd)] += 1
            except json.JSONDecodeError:
                continue

print("\nTop 10 commands by attacking IPs:\n")
for (ip, cmd), count in commands.most_common(10):
    print(f"{ip}: {cmd} ({count} times)")
```

---

## 12. Documentation Links

- [Cowrie SSH Honeypot GitHub](https://github.com/cowrie/cowrie)
- [Cowrie Documentation](https://cowrie.readthedocs.io/)
- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [CrowdSec Cowrie Collection](https://hub.crowdsec.net/author/crowdsecurity/collections/cowrie)
- [Docker Documentation](https://docs.docker.com/)

---