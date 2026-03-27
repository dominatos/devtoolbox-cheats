---
Title: adcli (Active Directory CLI)
Group: Identity Management
Icon: 🪪
Order: 10
---

# adcli — Active Directory Client Tools

**Description / Описание:**
`adcli` is a lightweight command-line tool for joining Linux machines to Microsoft Active Directory domains using standard interoperable protocols (LDAP, Kerberos, SASL). It is commonly used alongside SSSD and realmd for AD integration on Linux servers and workstations. `adcli` is the **recommended modern approach** for AD-joining on RHEL/CentOS/Fedora and Debian/Ubuntu systems.

> [!NOTE]
> `adcli` is actively maintained and is the primary tool used by `realmd` under the hood. For higher-level automation, consider using `realm join` which wraps `adcli` with automatic SSSD/Kerberos configuration.

## Table of Contents / Оглавление

- [Installation & Configuration](#installation--configuration)
- [Domain Discovery & Joining](#domain-discovery--joining)
- [Machine Account Management](#machine-account-management)
- [Active Directory Authentication (Kerberos)](#active-directory-authentication-kerberos)
- [Key Configuration Files](#key-configuration-files)
- [Sysadmin Operations](#sysadmin-operations)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Concepts Comparison](#concepts-comparison)
- [Documentation Links](#documentation-links)

---

## Installation & Configuration

### Install adcli / Установка adcli

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install adcli sssd sssd-ad realmd krb5-user -y

# RHEL/CentOS/Fedora
sudo dnf install adcli sssd realmd krb5-workstation oddjob oddjob-mkhomedir -y
```

### Required Packages Overview / Обзор необходимых пакетов

| Package / Пакет | Purpose / Назначение |
| :--- | :--- |
| `adcli` | AD join/management tool / Утилита присоединения к AD |
| `sssd` | System Security Services Daemon / Демон безопасности (кэширование, аутентификация) |
| `realmd` | High-level AD integration / Высокоуровневая интеграция с AD |
| `krb5-user` / `krb5-workstation` | Kerberos client utilities / Клиентские утилиты Kerberos |
| `oddjob-mkhomedir` | Auto-create home dirs on login (RHEL) / Автосоздание домашних каталогов (RHEL) |

### Enable Auto Home Directory Creation / Автоматическое создание домашних каталогов

```bash
# RHEL/CentOS/Fedora
sudo authselect select sssd with-mkhomedir --force  # Enable mkhomedir via authselect / Включить mkhomedir через authselect

# Debian/Ubuntu
sudo pam-auth-update --enable mkhomedir  # Enable mkhomedir PAM module / Включить PAM-модуль mkhomedir
```

---

## Domain Discovery & Joining

### Discover Active Directory Domain / Обнаружение домена AD

```bash
adcli info <DOMAIN>  # Discover domain info (DCs, site, forest) / Обнаружить информацию о домене (DC, сайт, лес)
```

**Sample Output / Пример вывода:**
```
[domain]
domain-name = <DOMAIN>
domain-short = <SHORT_DOMAIN>
domain-forest = <FOREST>
domain-controller = <DC_HOSTNAME>
domain-controller-site = Default-First-Site-Name
```

### Production Runbook: Domain Join / Пошаговое присоединение к домену

> [!IMPORTANT]
> Before joining, ensure DNS is correctly configured to resolve the AD domain. The Linux server **must** be able to resolve `_ldap._tcp.<DOMAIN>` SRV records.

1. **Verify DNS resolution / Проверьте DNS:**
   ```bash
   nslookup <DOMAIN>  # Should resolve to DC IPs / Должен разрешиться в IP контроллеров домена
   host -t SRV _ldap._tcp.<DOMAIN>  # Check SRV records / Проверить SRV-записи
   ```

2. **Discover the domain / Обнаружьте домен:**
   ```bash
   adcli info <DOMAIN>  # Verify connectivity / Проверить подключение
   ```

3. **Join the domain / Присоединитесь к домену:**
   ```bash
   adcli join <DOMAIN> -U <USER>  # Join with specific AD admin user / Присоединиться с указанным администратором AD
   adcli join <DOMAIN> -C <COMPUTER_NAME>  # Join with a specific computer name / Присоединиться с указанным именем компьютера
   adcli join <DOMAIN> --show-details  # Show details during join / Показать детали при присоединении
   ```

4. **Verify the join / Проверьте присоединение:**
   ```bash
   adcli testjoin --domain=<DOMAIN> --verbose  # Test domain membership / Проверить членство в домене
   klist -k /etc/krb5.keytab  # Verify keytab was created / Проверить, что keytab создан
   ```

5. **Restart SSSD / Перезапустите SSSD:**
   ```bash
   systemctl restart sssd  # Restart SSSD / Перезапустить SSSD
   id <USER>@<DOMAIN>  # Verify AD user lookup / Проверить поиск пользователя AD
   ```

### Join via realmd (Higher-Level) / Присоединение через realmd

```bash
realm discover <DOMAIN>  # Discover domain and required packages / Обнаружить домен и зависимости
realm join <DOMAIN> -U <USER>  # Join automatically (configures SSSD + Kerberos) / Присоединиться автоматически
realm list  # Show joined domains / Показать присоединённые домены
```

### Update Machine Account / Обновление учетной записи компьютера

```bash
adcli update --domain=<DOMAIN> --verbose  # Update the machine account password and details in AD / Обновить пароль и данные учётной записи машины в AD
```

> [!TIP]
> Use `adcli update --domain=<DOMAIN> --verbose` periodically as part of your system's maintenance runbooks if the automated machine password renewal fails. SSSD usually handles this automatically, but doing it manually can fix "trust broken" errors.

---

## Machine Account Management

### Pre-Create Computer Account / Предварительное создание учётной записи

```bash
adcli preset-computer --domain=<DOMAIN> <COMPUTER_NAME>  # Pre-create computer account in AD / Предварительно создать учётную запись компьютера в AD
```

### Reset Machine Account Password / Сброс пароля учётной записи

```bash
adcli reset-computer --domain=<DOMAIN> <COMPUTER_NAME>  # Reset password for existing computer account / Сбросить пароль существующей учётной записи компьютера
```

### Delete Machine Account / Удаление учётной записи

> [!WARNING]
> This command will remove the computer from Active Directory. The machine will no longer be able to authenticate users against AD until re-joined. / Эта команда удалит компьютер из Active Directory. Машина не сможет аутентифицировать пользователей в AD до повторного присоединения.

```bash
adcli delete-computer --domain=<DOMAIN> <COMPUTER_NAME>  # Remove computer from AD / Удалить компьютер из AD
```

---

## Active Directory Authentication (Kerberos)

### Initialize Kerberos Ticket for Machine / Инициализация Kerberos-билета для машины

```bash
kinit -k -t /etc/krb5.keytab <COMPUTER_NAME>$@<REALM_UPPERCASE>  # Authenticate using machine keytab / Аутентификация с помощью keytab машины
```

### Initialize Kerberos Ticket for User / Инициализация Kerberos-билета для пользователя

```bash
kinit <USER>@<REALM_UPPERCASE>  # Obtain TGT for user / Получить TGT для пользователя
```

### Check Available Kerberos Tickets / Проверка доступных билетов Kerberos

```bash
klist  # Show current tickets / Показать текущие билеты
klist -k /etc/krb5.keytab  # View keys in the keytab / Просмотр ключей в keytab
```

### Destroy Kerberos Tickets / Уничтожение Kerberos-билетов

```bash
kdestroy  # Destroy all tickets in default cache / Уничтожить все билеты в кэше по умолчанию
```

---

## Key Configuration Files

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

> [!IMPORTANT]
> File permissions must be `0600` and owned by root: `chmod 0600 /etc/sssd/sssd.conf`. SSSD will refuse to start otherwise. / Права на файл должны быть `0600`, владелец root. Иначе SSSD не запустится.

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

### NSSwitch Configuration / Конфигурация NSSwitch
`/etc/nsswitch.conf`

```bash
# Ensure sss is listed for passwd, group, shadow / Убедитесь, что sss указан для passwd, group, shadow
passwd:     files sss
group:      files sss
shadow:     files sss
```

---

## Sysadmin Operations

### Service Management / Управление сервисами

```bash
systemctl enable --now sssd  # Enable and start SSSD / Включить и запустить SSSD
systemctl restart sssd  # Restart SSSD service / Перезапустить службу SSSD
systemctl status sssd  # Check SSSD status / Проверить статус SSSD
```

### Important Log Files / Важные лог-файлы

| Log File / Файл лога | Purpose / Назначение |
| :--- | :--- |
| `/var/log/sssd/sssd_<DOMAIN>.log` | SSSD domain-specific logs / Логи домена SSSD |
| `/var/log/sssd/sssd_pam.log` | PAM authentication logs / Логи аутентификации PAM |
| `/var/log/sssd/sssd_nss.log` | NSS (name resolution) logs / Логи разрешения имён |
| `/var/log/secure` | Auth logs (CentOS/RHEL) / Логи аутентификации |
| `/var/log/auth.log` | Auth logs (Debian/Ubuntu) / Логи аутентификации |

```bash
tail -f /var/log/sssd/sssd_<DOMAIN>.log  # Follow SSSD domain logs / Следить за логами домена SSSD
journalctl -u sssd -f  # Follow SSSD journal logs / Следить за журналом SSSD
tail -f /var/log/secure  # Auth logs (CentOS/RHEL) / Логи аутентификации (CentOS/RHEL)
tail -f /var/log/auth.log  # Auth logs (Debian/Ubuntu) / Логи аутентификации (Debian/Ubuntu)
```

### SSSD Debug Level / Уровень отладки SSSD

```bash
# Temporarily increase debug level / Временно увеличить уровень отладки
sss_debuglevel 6  # Set debug level (1-9, 6 is detailed) / Установить уровень отладки

# Or add to /etc/sssd/sssd.conf under [domain/<DOMAIN>]:
# debug_level = 6
```

### Logrotate Configuration / Настройка ротации логов
`/etc/logrotate.d/sssd`

```bash
/var/log/sssd/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## Troubleshooting & Tools

### Verify Domain Membership / Проверка членства в домене

```bash
adcli testjoin --domain=<DOMAIN> --verbose  # Test domain join status / Проверить статус присоединения к домену
realm list  # Show joined domains / Показать присоединённые домены
```

### Clear SSSD Cache / Очистка кэша SSSD

> [!CAUTION]
> Clearing the SSSD cache will force re-lookup of all users/groups from AD. During this time, AD authentication may be temporarily unavailable. / Очистка кэша SSSD приведёт к повторному запросу всех пользователей/групп из AD. На это время аутентификация может быть временно недоступна.

```bash
sss_cache -E  # Expire all cached entries / Инвалидировать все кэшированные записи
systemctl restart sssd  # Restart SSSD after cache clear / Перезапустить SSSD после очистки кэша
```

### Test User Lookup / Проверка поиска пользователя

```bash
id <USER>@<DOMAIN>  # Lookup AD user / Найти пользователя AD
getent passwd <USER>  # Get passwd entry for AD user / Получить запись passwd для пользователя AD
getent group "<GROUP_NAME>"  # Get group entry / Получить запись группы
```

### Common Issues & Fixes / Частые проблемы и решения

| Issue / Проблема | Fix / Решение |
| :--- | :--- |
| `adcli: couldn't connect to domain` | Check DNS resolution and firewall (ports 53, 88, 389, 636) / Проверьте DNS и файрвол |
| `kinit: Cannot resolve KDC` | Verify `/etc/krb5.conf` realm config and DNS / Проверьте конфиг реалма и DNS |
| SSSD won't start | Check permissions on `/etc/sssd/sssd.conf` (must be `0600`) / Проверьте права на файл |
| Users not found after join | Clear the SSSD cache: `sss_cache -E && systemctl restart sssd` / Очистите кэш SSSD |
| Machine password expired (trust broken) | Run `adcli update --domain=<DOMAIN> --verbose` / Обновите пароль машины |

### Required Firewall Ports / Необходимые порты файрвола

| Port / Порт | Protocol / Протокол | Service / Сервис |
| :--- | :--- | :--- |
| 53 | TCP/UDP | DNS |
| 88 | TCP/UDP | Kerberos |
| 389 | TCP/UDP | LDAP |
| 636 | TCP | LDAPS |
| 445 | TCP | SMB/CIFS |
| 3268 | TCP | Global Catalog |
| 3269 | TCP | Global Catalog (SSL) |

```bash
# UFW (Debian/Ubuntu)
sudo ufw allow out 88/tcp  # Kerberos
sudo ufw allow out 389/tcp  # LDAP
sudo ufw allow out 636/tcp  # LDAPS

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=kerberos  # Kerberos
sudo firewall-cmd --permanent --add-service=ldap  # LDAP
sudo firewall-cmd --permanent --add-service=ldaps  # LDAPS
sudo firewall-cmd --reload  # Apply changes / Применить изменения
```

---

## Concepts Comparison

| Concept / Концепция | Description (EN / RU) | Use Case / Best for... |
| :--- | :--- | :--- |
| **Kerberos** | Network authentication protocol / Сетевой протокол аутентификации | Secure identity verification using tickets without sending passwords over the network. |
| **LDAP** | Lightweight Directory Access Protocol / Облегчённый протокол доступа к каталогам | Querying AD for users, groups, and attributes. |
| **SSSD** | System Security Services Daemon / Демон системных служб безопасности | Local caching and integration of AD authentication on Linux. Allows offline login. |
| **adcli** | AD Command Line Tool / Утилита командной строки AD | Specifically designed for joining and managing machine accounts in AD easily. |
| **realmd** | DBus service for managing network auth / Сервис DBus для управления сетевой аутентификацией | Higher-level tool that often uses `adcli` underneath to configure SSSD and Kerberos automatically. |
| **Winbind** | Samba component for AD integration / Компонент Samba для интеграции с AD | Alternative to SSSD, commonly used with Samba file shares. |

---

## Documentation Links

- **adcli Official Documentation:** [https://www.freedesktop.org/software/realmd/adcli/](https://www.freedesktop.org/software/realmd/adcli/)
- **SSSD Documentation:** [https://sssd.io/docs/introduction.html](https://sssd.io/docs/introduction.html)
- **realmd Documentation:** [https://www.freedesktop.org/software/realmd/docs/](https://www.freedesktop.org/software/realmd/docs/)
- **Red Hat — Joining AD:** [https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/integrating_rhel_systems_directly_with_windows_active_directory/](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/integrating_rhel_systems_directly_with_windows_active_directory/)
- **MIT Kerberos Documentation:** [https://web.mit.edu/kerberos/krb5-latest/doc/](https://web.mit.edu/kerberos/krb5-latest/doc/)
