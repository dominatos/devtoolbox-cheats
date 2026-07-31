Title: 🖧 NetworkManager — GUI/TUI Network Management
Group: Network
Icon: 🖧
Order: 23

# NetworkManager — GUI & TUI Network Management

NetworkManager provides graphical and text-based user interfaces for network configuration. It's the default on most desktop Linux distributions and offers excellent WiFi, VPN, and mobile broadband support.

## Table of Contents
- [Installation & Configuration](#installation-configuration)
- [GUI Tools](#gui-tools-gui-инструменты)
- [Text UI (nmtui)](#text-ui-nmtui-текстовый-интерфейс)
- [Dispatcher Scripts](#dispatcher-scripts-скрипты-диспетчера)
- [Connection Management](#connection-management-управление-соединениями)
- [Troubleshooting & Tools](#troubleshooting-tools-устранение-неполадок)

---

## Installation & Configuration

### Install NetworkManager GUI Tools / Установка GUI инструментов
```bash
# Debian / Ubuntu
sudo apt install -y network-manager network-manager-gnome  # Install NM + applet / Установить NM + апплет
sudo apt install -y network-manager-openvpn-gnome  # OpenVPN plugin / Плагин OpenVPN

# RHEL / Fedora
sudo dnf install -y NetworkManager NetworkManager-wifi NetworkManager-tui  # Install NM / Установить NM
sudo dnf install -y network-manager-applet  # GNOME applet / GNOME апплет
```

### Enable NetworkManager / Включение NetworkManager
```bash
sudo systemctl enable --now NetworkManager  # Enable and start / Включить и запустить
sudo systemctl status NetworkManager          # Check status / Проверить статус
```

### Configuration Paths / Пути конфигурации
- **Main config:** `/etc/NetworkManager/NetworkManager.conf`
- **Connection files:** `/etc/NetworkManager/system-connections/`
- **Dispatcher scripts:** `/etc/NetworkManager/dispatcher.d/`

---

## GUI Tools / GUI инструменты

### nm-connection-editor / Редактор соединений
```bash
nm-connection-editor  # Launch connection editor / Запустить редактор соединений
```

**Use Cases:**
- Create/edit/delete connections
- Configure advanced settings (IPv6, MTU, DNS)
- Set up WiFi, VPN, mobile broadband
- Configure firewall zones

### GNOME Network Settings / Настройки сети GNOME
```bash
gnome-control-center network  # Launch GNOME network settings / Запустить настройки сети
```

### Network Manager Applet / Апплет NetworkManager
```bash
nm-applet  # Start system tray applet / Запустить апплет в трее
```

**Features:**
- Click icon in system tray to connect/disconnect
- View available WiFi networks
- Connect to VPN
- View connection info

---

## Text UI (nmtui) / Текстовый интерфейс

### Launch nmtui / Запустить nmtui
```bash
nmtui  # Launch text UI / Запустить текстовый интерфейс
```

**Menu Options:**
1. **Edit a connection** — Create/modify connections
2. **Activate a connection** — Connect/disconnect
3. **Set system hostname** — Change hostname

### Common Workflows / Типичные сценарии

#### Create Ethernet Connection (nmtui)
1. Select **"Edit a connection"**
2. Choose **"Add"**
3. Select **"Ethernet"**
4. Configure IP (DHCP or Manual)
5. Select **"OK"** then **"Back"**
6. Select **"Activate a connection"** to connect

#### Create WiFi Connection (nmtui)
1. Select **"Edit a connection"**
2. Choose **"Add"**
3. Select **"Wi-Fi"**
4. Enter SSID and password
5. Select **"OK"** then **"Back"**
6. Select **"Activate a connection"** to connect

---

## Dispatcher Scripts / Скрипты диспетчера

### Create Dispatcher Script / Создать скрипт диспетчера
`/etc/NetworkManager/dispatcher.d/99-custom-script`

```bash
#!/bin/bash
# Dispatcher script example / Пример скрипта диспетчера

INTERFACE=$1  # Interface name / Имя интерфейса
ACTION=$2     # Action (up, down, vpn-up, vpn-down) / Действие

case "$ACTION" in
  up)
    echo "Interface $INTERFACE is up" >> /var/log/nm-dispatcher.log
    # Run commands when interface comes up / Команды при поднятии интерфейса
    ;;
  down)
    echo "Interface $INTERFACE is down" >> /var/log/nm-dispatcher.log
    # Run commands when interface goes down / Команды при опускании интерфейса
    ;;
  vpn-up)
    echo "VPN connection established" >> /var/log/nm-dispatcher.log
    # Run commands when VPN connects / Команды при подключении VPN
    ;;
esac
```

```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-custom-script  # Make executable / Сделать исполняемым
```

> [!NOTE]
> Dispatcher scripts run as root and receive the interface name and action as arguments.

### Common Dispatcher Use Cases / Типичные случаи использования
- Update DNS settings when VPN connects
- Mount network shares when connected to specific network
- Adjust firewall rules based on network location
- Sync time servers

---

## Connection Management / Управление соединениями

### NetworkManager Configuration File / Файл конфигурации
`/etc/NetworkManager/NetworkManager.conf`

```ini
[main]
plugins=keyfile  # Connection storage format / Формат хранения соединений
dns=systemd-resolved  # DNS backend / Бэкенд DNS

[logging]
level=INFO  # Log level / Уровень логирования

[connection]
wifi.powersave=2  # WiFi powersave (2=enabled) / Энергосбережение WiFi
```

```bash
sudo systemctl restart NetworkManager  # Apply config / Применить конфигурацию
```

### Connection File Example / Пример файла соединения
`/etc/NetworkManager/system-connections/office-wifi.nmconnection`

```ini
[connection]
id=office-wifi
uuid=<UUID>
type=wifi
autoconnect=true

[wifi]
ssid=Office_Network
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=<PASSWORD>

[ipv4]
method=auto

[ipv6]
method=auto
```

> [!CAUTION]
> Connection files contain passwords in plain text. Ensure permissions are `600` (read/write for root only).

```bash
sudo chmod 600 /etc/NetworkManager/system-connections/*  # Secure permissions / Безопасные права
```

---

## Troubleshooting & Tools / Устранение неполадок

### Common Issues / Типичные проблемы
```bash
# WiFi not working / WiFi не работает
sudo systemctl restart NetworkManager  # Restart NetworkManager / Перезапустить NM
sudo rfkill unblock wifi                # Unblock WiFi / Разблокировать WiFi

# Connection managed by other service / Соединение управляется другим сервисом
sudo nmcli device set <DEVICE> managed yes  # Force NM management / Принудительное управление

# No network icon in tray / Нет иконки сети в трее
nm-applet &  # Start applet / Запустить апплет
```

### Debug Logging / Отладочное логирование
```bash
sudo nmcli general logging level DEBUG  # Enable debug logging / Включить отладку
journalctl -u NetworkManager -f          # Follow logs / Смотреть логи
sudo nmcli general logging level INFO    # Restore normal logging / Восстановить обычное логирование
```

### View Connection Secrets / Просмотреть секреты соединений
```bash
nmcli -s connection show <CONN>  # Show with secrets / Показать с секретами (требует sudo)
```

---

## Comparison Tables / Таблицы сравнения

### NetworkManager Tools Comparison / Сравнение инструментов

| Tool | Interface | Best For | WiFi Support |
| :--- | :--- | :--- | :--- |
| **nmcli** | CLI | Scripts, automation / Скрипты, автоматизация | Full / Полная |
| **nmtui** | Text UI | SSH sessions, minimal env / SSH сессии, минимальная среда | Full / Полная |
| **nm-connection-editor** | GUI | Desktop configuration / Настройка десктопа | Full / Полная |
| **nm-applet** | System tray | Quick connect/disconnect / Быстрое подключение | Full / Полная |

## 📚 Documentation Links

- [NetworkManager API Docs](https://networkmanager.dev/docs/api/latest/)
- [NetworkManager Wiki](https://wiki.gnome.org/Projects/NetworkManager)

#network #sysadmin #linux
