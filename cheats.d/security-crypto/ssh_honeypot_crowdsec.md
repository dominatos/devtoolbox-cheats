Title: 🍯 SSH Honeypot + CrowdSec
Group: Security & Crypto
Icon: 🍯
Order: 99

---

## 📚 Table of Contents / Содержание

1. [Overview](#overview--обзор)
2. [Install Docker](#1-install-docker--установка-docker)
3. [Move Real SSH to Port 2222](#2-move-real-ssh-to-port-2222--перенос-ssh-на-порт-2222)
4. [Install Cowrie Honeypot](#3-install-cowrie-honeypot--установка-cowrie)
5. [Save Honeypot Logs](#4-save-honeypot-logs--сохранение-логов)
6. [Install CrowdSec](#5-install-crowdsec--установка-crowdsec)
7. [Install Cowrie Parser](#6-install-cowrie-parser--установка-парсера-cowrie)
8. [Community Integration](#7-community-integration--интеграция-с-сообществом)
9. [Web Dashboard](#8-web-dashboard--веб-панель)
10. [GeoIP Visualization](#9-geoip-visualization--визуализация-geoip)
11. [Verify Detection & Firewall](#10-verify-detection--firewall--проверка-обнаружения-и-файрвола)
12. [Architecture](#architecture--архитектура)
13. [Useful Commands](#useful-commands--полезные-команды)
14. [Cowrie Log Analysis Script](#cowrie-log-analysis-script--скрипт-анализа-логов-cowrie)

---

## Overview / Обзор

> **Goal / Цель:**
> - Real SSH runs on port **2222** / Реальный SSH работает на порту **2222**
> - Port **22** becomes a **Cowrie honeypot** / Порт **22** становится **ловушкой Cowrie**
> - **CrowdSec** automatically bans attacking IPs / **CrowdSec** автоматически банит атакующие IP
> - Logs saved and optionally sent to CrowdSec community blocklist / Логи сохраняются и опционально отправляются в CrowdSec
> - Optional web dashboard and GeoIP visualization / Опциональная веб-панель и визуализация GeoIP

---

## 1. Install Docker / Установка Docker

```bash
sudo apt update                                           # Update packages / Обновить пакеты
sudo apt install -y docker.io                             # Install Docker / Установить Docker
sudo systemctl enable --now docker                        # Enable & start / Включить и запустить
docker --version                                          # Verify install / Проверить установку
```

---

## 2. Move Real SSH to Port 2222 / Перенос SSH на порт 2222

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

## 3. Install Cowrie Honeypot / Установка Cowrie

```bash
docker pull cowrie/cowrie                                  # Pull image / Скачать образ
docker run -d --name cowrie \
  -p 22:2222 \
  --restart unless-stopped \
  cowrie/cowrie                                            # Run on port 22 / Запустить на порту 22
docker ps                                                 # Check container / Проверить контейнер
```

---

## 4. Save Honeypot Logs / Сохранение логов

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

## 5. Install CrowdSec / Установка CrowdSec

```bash
curl -s https://install.crowdsec.net | sudo sh            # Add repo / Добавить репозиторий
sudo apt install -y crowdsec                              # Install CrowdSec / Установить CrowdSec
sudo apt install -y crowdsec-firewall-bouncer-iptables    # Install firewall bouncer / Установить bouncer
sudo systemctl status crowdsec                            # Check status / Проверить статус
```

---

## 6. Install Cowrie Parser / Установка парсера Cowrie

```bash
sudo cscli collections install crowdsecurity/cowrie       # Install collection / Установить коллекцию
sudo systemctl restart crowdsec                           # Restart CrowdSec / Перезапустить CrowdSec
```

---

## 7. Community Integration / Интеграция с сообществом

Enable LAPI and push decisions to community blocklist. / Включите LAPI и отправляйте решения в общий блоклист.

```bash
sudo cscli hub update                                     # Update hub / Обновить хаб
sudo cscli hub install crowdsecurity/lapi                  # Install LAPI / Установить LAPI
```

---

## 8. Web Dashboard / Веб-панель

```bash
docker run -d -p 8080:8080 \
  --name cowrie-web \
  --link cowrie:db \
  cowrie/cowrie-web                                        # Start dashboard / Запустить панель
```

Access / Доступ: `http://<HOST>:8080`

---

## 9. GeoIP Visualization / Визуализация GeoIP

Use Python script or Kibana to parse `/opt/cowrie/log/cowrie.json` and plot IPs on map.
Используйте Python-скрипт или Kibana для парсинга `/opt/cowrie/log/cowrie.json` и отображения IP на карте.

---

## 10. Verify Detection & Firewall / Проверка обнаружения и файрвола

```bash
sudo cscli decisions list                                  # Active bans / Активные баны
sudo cscli alerts list                                     # Alert history / История алертов
sudo cscli metrics                                         # CrowdSec metrics / Метрики CrowdSec
sudo iptables -L -n                                        # Firewall rules / Правила файрвола
sudo cscli bouncers list                                   # Registered bouncers / Зарегистрированные bouncer'ы
```

---

## Architecture / Архитектура

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

## Useful Commands / Полезные команды

```bash
sudo cscli alerts list -o human                            # Top attackers / Топ атакующих
sudo cscli decisions delete --ip <IP>                      # Unban IP / Разбанить IP
sudo cscli scenarios list                                  # List scenarios / Список сценариев
```

---

## Cowrie Log Analysis Script / Скрипт анализа логов Cowrie

### watch_cowrie_commands.py

```python
#!/usr/bin/env python3
"""Watch Cowrie Honeypot Commands.

This script reads Cowrie logs and prints the top commands
entered by attacking IPs.
Скрипт читает логи Cowrie и выводит топ команд, вводимых атакующими IP.
"""

import json
from pathlib import Path
from collections import Counter

# Path to Cowrie logs / Путь к логам Cowrie
log_dir = Path("/opt/cowrie/log")

# Counter for commands / Счётчик команд
commands = Counter()

# Parse all log files / Парсинг всех лог-файлов
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

# Display top 10 commands / Показать топ-10 команд
print("\nTop 10 commands by attacking IPs:\n")
for (ip, cmd), count in commands.most_common(10):
    print(f"{ip}: {cmd} ({count} times)")
```

---