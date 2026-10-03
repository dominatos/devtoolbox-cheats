---
Title: 🌐 OpenVPN — VPN Tunnel
Group: Network
Icon: 🌐
Order: 12
tags:
  - network
  - vpn
  - openvpn
  - tunnel
  - security
  - sysadmin
  - linux
---

## Table of Contents

- [Description](#description)
- [Installation](#installation)
- [Configuration](#configuration)
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Security](#security)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Comparison Tables](#comparison-tables)
- [Production Runbooks](#production-runbooks)
- [Documentation Links](#documentation-links)

---

# 🌐 OpenVPN Cheatsheet

## Description

**OpenVPN** is an open-source **VPN solution** using SSL/TLS for key exchange and OpenSSL for encryption. Supports remote access and site-to-site tunnels over UDP/TCP. / **OpenVPN** — решение VPN на SSL/TLS для обмена ключами и OpenSSL для шифрования. Поддерживает remote access и site-to-site туннели поверх UDP/TCP.

**Common use cases / Типовые сценарии:**
- Remote access VPN for admins / Удалённый доступ для администраторов
- Site-to-site connectivity / Соединение площадок
- Secure access to internal services / Безопасный доступ к внутренним сервисам
- Bypass network restrictions / Обход сетевых ограничений

**Status:** Actively maintained (OpenVPN Inc / community). Alternatives: **WireGuard**, **IPsec (strongSwan)**, **tailscale**. / **Статус:** активно развивается; альтернативы — WireGuard, IPsec, Tailscale.

**Default ports:** `1194/udp` (default), configurable TCP.  
**Paths:** server `/etc/openvpn/server/`, client `/etc/openvpn/client/`.

Cross-reference: [WireGuard](wireguard.md), [iptables](iptablescheatsheet.md), [nftables](nftables.md), [Firewalld](firewalld.md).

---

## Installation

### Install OpenVPN / Установка OpenVPN

```bash
# Debian/Ubuntu
apt install openvpn easy-rsa

# RHEL/Rocky/Alma/Fedora
dnf install openvpn easy-rsa
```

```bash
openvpn --version
```

---

## Configuration

### Easy-RSA PKI / Easy-RSA PKI

```bash
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
./easyrsa build-client-full client1 nopass
./easyrsa gen-dh
openvpn --genkey secret ta.key
```

### Server config / Серверная конфигурация

`/etc/openvpn/server/server.conf`

```bash
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS <DNS_IP>"
keepalive 10 120
cipher AES-256-GCM
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
```

### Client config / Клиентская конфигурация

`/etc/openvpn/client/client.ovpn`

```bash
client
dev tun
proto udp
remote <SERVER_IP> 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
<ca>
...ca.crt...
</ca>
<cert>
...client1.crt...
</cert>
<key>
...client1.key...
</key>
<tls-auth>
...ta.key...
</tls-auth>
key-direction 1
```

```bash
systemctl enable --now openvpn-server@server
```

---

## Core Management

### Service control / Управление сервисом

```bash
systemctl status openvpn-server@server
systemctl restart openvpn-server@server
journalctl -u openvpn-server@server --no-pager -n 50
```

### Status / Статус

```bash
cat /etc/openvpn/server/openvpn-status.log
ip addr show tun0
```

---

## Sysadmin Operations

### Logs / Логи

```bash
journalctl -u openvpn-server@server --no-pager
tail -f /var/log/openvpn/*.log
```

### Logrotate / Ротация логов

`/etc/logrotate.d/openvpn`

```bash
/var/log/openvpn/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload openvpn-server@server >/dev/null 2>&1 || true
    endscript
}
```

### Firewall / Firewall

```bash
# firewalld
firewall-cmd --permanent --add-port=1194/udp
firewall-cmd --reload

# iptables
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
```

---

## Security

### Hardening / Ужесточение

1. Use AES-256-GCM and SHA256 / Используйте AES-256-GCM и SHA256
2. Protect private keys with 0600 / Защитите ключи (0600)
3. Use tls-auth or tls-crypt / Используйте tls-auth/tls-crypt
4. Push internal-only DNS / Пробрасывайте только internal DNS
5. Disable client-to-client unless needed / Отключайте client-to-client
6. Keep OpenVPN patched / Обновляйте OpenVPN
7. Use cert-based auth / Используйте аутентификацию по сертификатам

```bash
chmod 0600 server.key client1.key ta.key
```

---

## Backup and Restore

### Backup / Резервное копирование

```bash
tar czf /var/backups/openvpn-$(date +%F).tar.gz \
  /etc/openvpn ~/openvpn-ca/pki
```

### Restore / Восстановление

```bash
systemctl stop openvpn-server@server
tar xzf /var/backups/openvpn-<DATE>.tar.gz -C /
systemctl start openvpn-server@server
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Cannot connect | Port blocked / wrong proto | Check firewall, proto |
| Handshake fails | Cert/key mismatch | Verify CA chain |
| No internet after connect | Missing redirect-gateway | Add push redirect |
| DNS not working | No DNS push | Add dhcp-option DNS |
| Tunnel drops | NAT/MTU issues | Adjust MTU; keepalive |

```bash
openvpn --config /etc/openvpn/server/server.conf --verb 4
ip route show
cat /etc/openvpn/server/openvpn-status.log
```

---

## Comparison Tables

### VPN solutions / VPN-решения

| System | Protocol | Best for |
| :--- | :--- | :--- |
| **OpenVPN** | OpenSSL/TLS | Flexible, mature |
| **WireGuard** | WG protocol | Performance, simplicity |
| **IPsec** | IKEv2 | Site-to-site standard |
| **Tailscale** | WireGuard mesh | Zero-config mesh |

---

## Production Runbooks

### Runbook: Deploy remote-access VPN / Развёртывание VPN

1. Install OpenVPN and easy-rsa / Установить пакеты
2. Build CA, server, and client certs / Создать сертификаты
3. Write server.conf; enable IP forwarding / Настроить сервер
4. Open firewall port 1194/udp / Открыть порт
5. Start openvpn-server@server / Запустить сервис
6. Distribute client.ovpn to users / Раздать клиентские конфиги
7. Test from remote client / Проверить подключение
8. Document key rotation policy / Задокументировать ротацию ключей

### Runbook: Revoke compromised client / Отзыв клиента

1. Revoke cert: `./easyrsa revoke client1` / Отозвать сертификат
2. Regenerate CRL: `./easyrsa gen-crl` / Сгенерировать CRL
3. Copy CRL to server; reference in server.conf / Скопировать CRL
4. Restart OpenVPN server / Перезапустить сервер
5. Verify client cannot connect / Проверить отказ
6. Issue new client cert if needed / Выпустить новый сертификат

---

## Documentation Links

- OpenVPN docs — https://openvpn.net/community-resources/
- OpenVPN howto — https://openvpn.net/community-resources/howto/
- Easy-RSA — https://github.com/OpenVPN/easy-rsa
