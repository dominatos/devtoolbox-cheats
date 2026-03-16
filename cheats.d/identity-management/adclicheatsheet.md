---
Title: adcli (Active Directory CLI)
Group: Identity Management
Icon: 🪪
Order: 10
---

# adcli — Active Directory Client Tools

`adcli` is a tool for joining an Active Directory domain using standard interoperable security technologies like LDAP, Kerberos, and Samba.

## 1. Domain Discovery & Joining

### Discover Active Directory Domain / Обнаружение домена AD
```bash
adcli info <DOMAIN>  # E.g., adcli info AD.ARUBA.IT
```

### Join a Domain / Присоединение к домену
```bash
adcli join <DOMAIN> -U <USER>  # Join with specific AD admin user
adcli join <DOMAIN> -C <COMPUTER_NAME>  # Join with a specific computer name
adcli join <DOMAIN> --show-details  # Show details during join
```

### Update Machine Account / Обновление учетной записи компьютера
```bash
adcli update --domain=<DOMAIN> --verbose  # Update the machine account password and details in AD / Обновить пароль и данные учетки машины в AD
```

## 2. Machine Account Management

### Reset Machine Account Password / Сброс пароля учетной записи
```bash
adcli preset-computer --domain=<DOMAIN> <COMPUTER_NAME>  # Pre-create computer account
adcli reset-computer --domain=<DOMAIN> <COMPUTER_NAME>  # Reset password for existing computer account
```

### Delete Machine Account / Удаление учетной записи
> [!WARNING]
> This command will remove the computer from Active Directory. The machine will no longer be able to authenticate users against AD until re-joined.

```bash
adcli delete-computer --domain=<DOMAIN> <COMPUTER_NAME>
```

## 3. Active Directory Authentication (Kerberos)

### Initialize Kerberos Ticket for Machine / Инициализация Kerberos билета для машины
```bash
kinit -k -t /etc/krb5.keytab <COMPUTER_NAME>$@<REALM_UPPERCASE>
```

### Check Available Kerberos Tickets / Проверка доступных билетов Kerberos
```bash
klist -k /etc/krb5.keytab  # View keys in the keytab / Просмотр ключей в keytab
```

## 4. Key Configuration Files / Основные конфигурационные файлы

### SSSD Configuration / Конфигурация SSSD
`/etc/sssd/sssd.conf`

```ini
[sssd]
domains = <DOMAIN>
config_file_version = 2
services = nss, pam

[domain/<DOMAIN>]
ad_domain = <DOMAIN>
krb5_realm = <REALM_UPPERCASE>
realmd_tags = manages-system joined-with-adcli 
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
access_provider = ad
```

### Kerberos Configuration / Конфигурация Kerberos
`/etc/krb5.conf`

```ini
[libdefaults]
    dns_lookup_realm = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    rdns = false
    pkinit_anchors = /etc/pki/tls/certs/ca-bundle.crt
    spnego_resolv_groups = false
    default_realm = <REALM_UPPERCASE>
    default_ccache_name = KEYRING:persistent:%{uid}

[realms]
<REALM_UPPERCASE> = {
    kdc = <DC_SERVER_IP>
    admin_server = <DC_SERVER_IP>
}

[domain_realm]
.<DOMAIN> = <REALM_UPPERCASE>
<DOMAIN> = <REALM_UPPERCASE>
```

## 5. Troubleshooting & Tools

### Important Log Files / Важные лог-файлы
```bash
tail -f /var/log/sssd/sssd_<DOMAIN>.log  # SSSD domain logs / Логи домена SSSD
tail -f /var/log/secure  # Auth logs (CentOS/RHEL) / Логи аутентификации (CentOS/RHEL)
tail -f /var/log/auth.log  # Auth logs (Debian/Ubuntu) / Логи аутентификации (Debian/Ubuntu)
```

### Common Service Restarts / Перезапуск основных сервисов
```bash
systemctl restart sssd  # Restart SSSD service / Перезапуск сервиса SSSD
systemctl clear-cache sssd  # Clear SSSD cache (sss_cache -E) / Очистка кэша SSSD
```

> [!TIP]
> Use `adcli update --domain=<DOMAIN> --verbose` periodically as part of your system's maintenance runbooks if the automated machine password renewal fails. SSSD usually handles this automatically, but doing it manually can fix "trust broken" errors.

## 6. Concepts Comparison

| Concept / Концепция | Description (EN / RU) | Use Case / Best for... |
| :--- | :--- | :--- |
| **Kerberos** | Network authentication protocol / Сетевой протокол аутентификации | Secure identity verification using tickets without sending passwords over the network. |
| **LDAP** | Lightweight Directory Access Protocol / Облегченный протокол доступа к каталогам | Querying AD for users, groups, and attributes. |
| **SSSD** | System Security Services Daemon / Демон системных служб безопасности | Local caching and integration of AD authentication on Linux. Allows offline login. |
| **adcli** | AD Command Line Tool / Утилита командной строки AD | Specifically designed for joining and managing machine accounts in AD easily. |
| **realmd** | DBus service for managing network auth / Сервис DBus для управления сетевой аутентификацией | Higher-level tool that often uses `adcli` underneath to configure SSSD and Kerberos automatically. |

