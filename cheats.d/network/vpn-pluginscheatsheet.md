Title: 🔐 VPN Plugins — Installation & Configuration
Group: Network
Icon: 🔐
Order: 24

# VPN Plugins — NetworkManager & Standalone Tools

Comprehensive guide to installing and configuring VPN plugins for NetworkManager and standalone VPN clients for various VPN protocols (OpenVPN, OpenConnect, Fortinet/FortiGate, L2TP/IPSec, PPTP).

## Table of Contents
- [OpenVPN](#openvpn)
- [OpenConnect (Cisco AnyConnect)](#openconnect-cisco-anyconnect)
- [Fortinet VPN](#fortinet-vpn)
- [L2TP/IPSec](#l2tpipsec)
- [PPTP](#pptp)
- [WireGuard](#wireguard)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)

---

## OpenVPN

### Install OpenVPN Plugin / Установка плагина OpenVPN

#### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
# Install OpenVPN + NetworkManager plugin / Установить OpenVPN + плагин NM
```

#### RHEL / Fedora
```bash
sudo dnf install -y openvpn NetworkManager-openvpn NetworkManager-openvpn-gnome
# Install OpenVPN + NetworkManager plugin / Установить OpenVPN + плагин NM
```

### Import OpenVPN Configuration / Импорт конфигурации OpenVPN
```bash
nmcli connection import type openvpn file <CONFIG>.ovpn  # Import .ovpn file / Импортировать .ovpn
```

### Connect via CLI / Подключиться через CLI
```bash
nmcli connection up <VPN_NAME>    # Connect to VPN / Подключиться к VPN
nmcli connection down <VPN_NAME>  # Disconnect from VPN / Отключиться от VPN
```

### Connect via GUI / Подключиться через GUI
1. Open **NetworkManager applet** (system tray)
2. Select **VPN Connections → <VPN_NAME>**
3. Enter credentials if prompted

### Standalone OpenVPN (without NetworkManager) / Автономный OpenVPN
```bash
sudo openvpn --config <CONFIG>.ovpn  # Connect via OpenVPN CLI / Подключиться через OpenVPN CLI
```

---

## OpenConnect (Cisco AnyConnect)

### Install OpenConnect Plugin / Установка плагина OpenConnect

#### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y openconnect network-manager-openconnect network-manager-openconnect-gnome
# Install OpenConnect + NetworkManager plugin / Установить OpenConnect + плагин NM
```

#### RHEL / Fedora
```bash
sudo dnf install -y openconnect NetworkManager-openconnect NetworkManager-openconnect-gnome
# Install OpenConnect + NetworkManager plugin / Установить OpenConnect + плагин NM
```

### Create OpenConnect VPN (GUI) / Создать OpenConnect VPN (GUI)
1. Open **nm-connection-editor**
2. Click **Add** → Select **Cisco AnyConnect Compatible VPN (openconnect)**
3. Enter:
   - **Gateway:** VPN server URL or IP
   - **Authentication:** Username/password or certificate
4. Click **Save**

### Connect via CLI / Подключиться через CLI
```bash
nmcli connection up <VPN_NAME>  # Connect to VPN / Подключиться к VPN
```

### Standalone OpenConnect / Автономный OpenConnect
```bash
sudo openconnect <VPN_SERVER>  # Connect via OpenConnect CLI / Подключиться через OpenConnect CLI
sudo openconnect --user=<USER> <VPN_SERVER>  # Connect with username / Подключиться с именем пользователя
```

---

## Fortinet VPN

Fortinet VPN offers multiple client options: **FortiClient** (official GUI), **openfortivpn** (CLI), and **openfortigui** (GUI wrapper for openfortivpn).

### FortiClient (Official) / FortiClient (официальный)

#### Install FortiClient / Установка FortiClient

**Ubuntu/Debian:**
```bash
wget -O forticlient.deb https://links.fortinet.com/forticlient/deb/vpnagent  # Download FortiClient / Скачать FortiClient
sudo apt install -y ./forticlient.deb  # Install FortiClient / Установить FortiClient
```

> [!NOTE]
> FortiClient is proprietary software. Download URLs may change. Check Fortinet's official website for the latest version.

**RHEL/Fedora:**
```bash
wget -O forticlient.rpm https://links.fortinet.com/forticlient/rpm/vpnagent  # Download FortiClient / Скачать FortiClient
sudo dnf install -y ./forticlient.rpm  # Install FortiClient / Установить FortiClient
```

#### Launch FortiClient / Запустить FortiClient
```bash
forticlient  # Launch FortiClient GUI / Запустить FortiClient GUI
```

### openfortivpn (CLI) / openfortivpn (командная строка)

#### Install openfortivpn / Установка openfortivpn

**Debian / Ubuntu:**
```bash
sudo apt update && sudo apt install -y openfortivpn  # Install openfortivpn / Установить openfortivpn
```

**RHEL / Fedora:**
```bash
sudo dnf install -y openfortivpn  # Install openfortivpn / Установить openfortivpn
```

#### Create Configuration File / Создать файл конфигурации
`/etc/openfortivpn/config`

```ini
host = <VPN_SERVER>
port = 443
username = <USER>
password = <PASSWORD>
trusted-cert = <CERT_FINGERPRINT>  # Optional: pin certificate / Опционально: привязать сертификат
```

```bash
sudo chmod 600 /etc/openfortivpn/config  # Secure permissions / Безопасные права
```

#### Connect via openfortivpn / Подключиться через openfortivpn
```bash
sudo openfortivpn  # Connect using /etc/openfortivpn/config / Подключиться используя /etc/openfortivpn/config
sudo openfortivpn <VPN_SERVER>:<PORT> -u <USER>  # Connect with inline args / Подключиться с аргументами
```

> [!TIP]
> Use `--trusted-cert` to pin SSL certificate fingerprint for enhanced security.

### openfortigui (GUI for openfortivpn) / openfortigui (GUI для openfortivpn)

#### Install openfortigui / Установка openfortigui

**Debian / Ubuntu:**
```bash
sudo apt update && sudo apt install -y openfortigui  # Install openfortigui / Установить openfortigui
```

**RHEL / Fedora:**
```bash
sudo dnf install -y openfortigui  # Install openfortigui / Установить openfortigui
```

**Alternative: Install from source / Альтернатива: Установка из исходников**
```bash
sudo apt install -y git cmake qt5-default libqt5webkit5-dev  # Install dependencies / Установить зависимости
git clone https://github.com/theinvisible/openfortigui.git  # Clone repository / Клонировать репозиторий
cd openfortigui
cmake .
make
sudo make install
```

#### Launch openfortigui / Запустить openfortigui
```bash
openfortigui  # Launch GUI / Запустить GUI
```

**Configuration Steps:**
1. Click **Add VPN**
2. Enter:
   - **VPN Name:** Descriptive name
   - **Gateway:** VPN server address
   - **Port:** 443 (or custom)
   - **Username/Password:** Your credentials
3. Click **Save**
4. Click **Connect**

### NetworkManager Fortinet Plugin / Плагин Fortinet для NetworkManager

#### Install NetworkManager Fortinet Plugin / Установка плагина
```bash
sudo apt install -y network-manager-fortisslvpn network-manager-fortisslvpn-gnome  # Debian/Ubuntu
sudo dnf install -y NetworkManager-fortisslvpn NetworkManager-fortisslvpn-gnome  # RHEL/Fedora
```

#### Create Fortinet VPN (GUI) / Создать Fortinet VPN (GUI)
1. Open **nm-connection-editor**
2. Click **Add** → Select **Fortinet SSLVPN**
3. Enter:
   - **Gateway:** VPN server
   - **Username/Password:** Credentials
   - **Certificate:** Path to certificate (if required)
4. Click **Save**

---

## L2TP/IPSec

### Install L2TP/IPSec Plugin / Установка плагина L2TP/IPSec

#### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y network-manager-l2tp network-manager-l2tp-gnome strongswan-nm
# Install L2TP plugin + strongSwan / Установить плагин L2TP + strongSwan
```

#### RHEL / Fedora
```bash
sudo dnf install -y NetworkManager-l2tp NetworkManager-l2tp-gnome strongswan
# Install L2TP plugin + strongSwan / Установить плагин L2TP + strongSwan
```

### Create L2TP VPN (GUI) / Создать L2TP VPN (GUI)
1. Open **nm-connection-editor**
2. Click **Add** → Select **Layer 2 Tunneling Protocol (L2TP)**
3. Enter:
   - **Gateway:** VPN server
   - **Username/Password:** Credentials
   - **IPSec Settings:**
     - **Pre-shared key:** Enter PSK
     - Or select **Certificate** authentication
4. Click **Save**

---

## PPTP

> [!WARNING]
> PPTP is insecure and deprecated. Use OpenVPN, WireGuard, or L2TP/IPSec instead.

### Install PPTP Plugin / Установка плагина PPTP

#### Debian / Ubuntu
```bash
sudo apt update && sudo apt install -y network-manager-pptp network-manager-pptp-gnome
# Install PPTP plugin / Установить плагин PPTP
```

#### RHEL / Fedora
```bash
sudo dnf install -y NetworkManager-pptp NetworkManager-pptp-gnome
# Install PPTP plugin / Установить плагин PPTP
```

---

## WireGuard

### Install WireGuard / Установка WireGuard
```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y wireguard  # Install WireGuard / Установить WireGuard

# RHEL / Fedora
sudo dnf install -y wireguard-tools  # Install WireGuard / Установить WireGuard
```

### Import WireGuard Configuration / Импорт конфигурации WireGuard
```bash
nmcli connection import type wireguard file /path/to/<CONFIG>.conf  # Import config / Импортировать конфигурацию
nmcli connection up <WG_NAME>  # Connect / Подключиться
```

> [!NOTE]
> For detailed WireGuard configuration, see the dedicated [WireGuard cheatsheet](wireguardcheatsheet.md).

---

## Troubleshooting / Устранение неполадок

### Common VPN Issues / Типичные проблемы VPN
```bash
# VPN connection fails / VPN соединение не устанавливается
journalctl -u NetworkManager -f  # Watch NetworkManager logs / Смотреть логи NetworkManager
nmcli connection show <VPN_NAME>  # View connection details / Просмотреть детали соединения

# DNS not working over VPN / DNS не работает через VPN
nmcli connection modify <VPN_NAME> ipv4.dns-priority -50  # Prioritize VPN DNS / Приоритет VPN DNS
nmcli connection modify <VPN_NAME> ipv4.ignore-auto-dns no  # Use VPN DNS / Использовать VPN DNS
nmcli connection up <VPN_NAME>  # Reconnect / Переподключиться

# Certificate errors (OpenConnect, Fortinet) / Ошибки сертификата
nmcli connection modify <VPN_NAME> vpn.data "cert-pass-flags=0"  # Disable cert validation / Отключить валидацию
```

### Enable VPN Debug Logging / Включить отладочное логирование VPN
```bash
sudo nmcli general logging level DEBUG domains VPN  # Enable VPN debug / Включить отладку VPN
journalctl -u NetworkManager -f  # Watch logs / Смотреть логи
sudo nmcli general logging level INFO domains VPN  # Restore normal logging / Восстановить обычное логирование
```

### Test VPN Connection / Проверить VPN соединение
```bash
curl ifconfig.me  # Check public IP before VPN / Проверить IP до VPN
nmcli connection up <VPN_NAME>  # Connect to VPN / Подключиться к VPN
curl ifconfig.me  # Check public IP after VPN / Проверить IP после VPN (должен измениться)
```

---

## Comparison Tables / Таблицы сравнения

### VPN Protocols Comparison / Сравнение VPN протоколов

| Protocol | Security | Speed | Use Case | NAT Traversal |
| :--- | :--- | :--- | :--- | :--- |
| **OpenVPN** | High / Высокая | Medium / Средняя | General purpose / Общего назначения | Good / Хорошее |
| **WireGuard** | High / Высокая | Very High / Очень высокая | Modern VPN / Современный VPN | Excellent / Отличное |
| **L2TP/IPSec** | Medium / Средняя | Medium / Средняя | Legacy compatibility / Совместимость | Poor / Плохое |
| **OpenConnect** | High / Высокая | High / Высокая | Cisco AnyConnect / Cisco AnyConnect | Good / Хорошее |
| **Fortinet SSLVPN** | High / Высокая | High / Высокая | FortiGate appliances / Устройства FortiGate | Good / Хорошее |
| **PPTP** | **Insecure** / **Небезопасно** | High / Высокая | **Deprecated** / **Устарело** | Excellent / Отличное |

### Fortinet VPN Tools Comparison / Сравнение инструментов Fortinet VPN

| Tool | Interface | Installation | NetworkManager Integration | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **FortiClient** | GUI (Qt) | Official .deb/.rpm / Официальный | No / Нет | Official support, GUI users / Официальная поддержка, GUI пользователи |
| **openfortivpn** | CLI | Standard repos / Стандартные репозитории | Via plugin / Через плагин | Servers, scripts / Серверы, скрипты |
| **openfortigui** | GUI (Qt) | Standard repos / Стандартные репозитории | No / Нет | Desktop, open-source preference / Десктоп, open-source |
| **NM Fortinet Plugin** | NM integration | Standard repos / Стандартные репозитории | Yes / Да | Seamless NM integration / Плавная интеграция с NM |

### Installation Comparison / Сравнение установки

| VPN Type | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
| :--- | :--- | :--- |
| **OpenVPN** | `network-manager-openvpn-gnome` | `NetworkManager-openvpn-gnome` |
| **OpenConnect** | `network-manager-openconnect-gnome` | `NetworkManager-openconnect-gnome` |
| **Fortinet (official)** | `forticlient.deb` (manual) | `forticlient.rpm` (manual) |
| **Fortinet (OSS)** | `openfortigui` | `openfortigui` |
| **L2TP/IPSec** | `network-manager-l2tp-gnome` | `NetworkManager-l2tp-gnome` |
| **WireGuard** | `wireguard` | `wireguard-tools` |
