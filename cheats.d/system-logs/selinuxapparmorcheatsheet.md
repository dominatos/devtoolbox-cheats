---
Title: "🛡️ SELinux & AppArmor — Security Modules"
Group: "System & Logs"
Icon: 🛡️
Order: 7
tags:
  - system
  - logs
  - sysadmin
  - linux
---

# SELinux & AppArmor — Mandatory Access Control

**SELinux** (Security-Enhanced Linux) and **AppArmor** (Application Armor) are Linux Security Modules (LSM) that implement **Mandatory Access Control (MAC)**. Unlike traditional Unix permissions (DAC — Discretionary Access Control), MAC policies are enforced by the kernel regardless of file ownership.

**SELinux** uses label-based security — every file, process, and port has a security context (label). Access is allowed/denied based on policy rules matching these labels. Default on RHEL/CentOS/Fedora/AlmaLinux.

**AppArmor** uses path-based profiles — each application has a profile defining which files/capabilities it can access. Simpler to configure than SELinux. Default on Ubuntu/Debian/SUSE.

**Why MAC matters / Зачем нужен MAC:**
- Limits blast radius of compromised services (e.g., a hacked nginx can't read `/etc/shadow`)
- Prevents privilege escalation even if an attacker gets shell access
- Required for security compliance (PCI-DSS, HIPAA, SOC2)

| Feature | SELinux | AppArmor |
| :--- | :--- | :--- |
| **Approach** | Label-based | Path-based |
| **Default on** | RHEL, CentOS, Fedora | Ubuntu, Debian, SUSE |
| **Complexity** | Higher | Lower |
| **Granularity** | Very fine-grained | Good for most cases |
| **Toolchain** | `semanage`, `restorecon`, `audit2allow` | `aa-genprof`, `aa-logprof`, `aa-status` |

---

## 📚 Table of Contents

- [SELinux](#SELinux)
- [AppArmor](#AppArmor)
- [Troubleshooting](#Troubleshooting)
- [Real-World Examples](#Real-World%20Examples)
- [💡 Best Practices](#💡%20Best%20Practices)
- [Configuration Files](#Configuration%20Files)
- [Documentation Links](#Documentation%20Links)

---

## SELinux

### Check Status

```bash
getenforce                                    # Current mode / Текущий режим
sestatus                                      # Detailed status / Подробный статус
sestatus -v                                   # Verbose status / Подробный статус
```

### Change Mode

```bash
sudo setenforce 0                             # Permissive (temporary) / Разрешительный (временно)
sudo setenforce 1                             # Enforcing (temporary) / Принудительный (временно)
```

### SELinux Modes

| Mode | Description (EN / RU) | Use Case / Когда использовать |
| :--- | :--- | :--- |
| **Enforcing** | Enforces policy, blocks violations / Применяет политику, блокирует нарушения | Production systems |
| **Permissive** | Logs violations without blocking / Логирует нарушения без блокировки | Debugging, policy development |
| **Disabled** | SELinux is completely off / Полностью выключен | Not recommended |

> [!CAUTION]
> Never disable SELinux in production. Use **Permissive** mode for debugging instead. Switching from Disabled to Enforcing requires a full filesystem relabel and reboot. / Никогда не отключайте SELinux в продакшене.

### Permanent Mode Change

`/etc/selinux/config`

```bash
# Edit /etc/selinux/config
sudo vi /etc/selinux/config
# SELINUX=enforcing|permissive|disabled
sudo reboot
```

### Check Contexts

```bash
ls -Z /path/to/file                           # File context / Контекст файла
ps -eZ                                        # Process contexts / Контексты процессов
id -Z                                         # User context / Контекст пользователя
ss -Z                                         # Socket contexts / Контексты сокетов
```

### Change Contexts

```bash
sudo chcon -t httpd_sys_content_t /var/www/html/file  # Change file type / Изменить тип файла
sudo chcon -R -t httpd_sys_content_t /var/www/html    # Recursive / Рекурсивно
sudo restorecon -v /var/www/html/file         # Restore default context / Восстановить контекст по умолчанию
sudo restorecon -R -v /var/www/html           # Recursive restore / Рекурсивное восстановление
```

### Booleans

```bash
getsebool -a                                  # List all booleans / Список всех булевых
getsebool httpd_can_network_connect           # Check specific boolean / Проверить конкретное булево
sudo setsebool httpd_can_network_connect on   # Enable (temporary) / Включить (временно)
sudo setsebool -P httpd_can_network_connect on  # Enable (permanent) / Включить (постоянно)
```

### Common SELinux Booleans

| Boolean | Description (EN / RU) |
| :--- | :--- |
| `httpd_can_network_connect` | Allow HTTP network connections / Разрешить HTTP сетевые соединения |
| `httpd_can_sendmail` | Allow HTTP send mail / Разрешить HTTP отправку почты |
| `httpd_execmem` | Allow HTTP execute memory / Разрешить HTTP выполнение памяти |
| `mysql_connect_any` | Allow MySQL connect anywhere / Разрешить MySQL подключаться куда угодно |
| `selinuxuser_execmod` | Allow user exec modification / Разрешить пользователю модификацию exec |

### Audit Logs

```bash
sudo ausearch -m avc -ts recent               # Recent AVC denials / Недавние AVC отказы
sudo ausearch -m avc -ts today                # Today's denials / Сегодняшние отказы
sudo sealert -a /var/log/audit/audit.log      # Analyze audit log / Анализ лога аудита
sudo grep 'avc: denied' /var/log/audit/audit.log  # Find denials / Найти отказы
```

### Policy Management

```bash
sudo semodule -l                              # List modules / Список модулей
sudo semodule -i my-policy.pp                 # Install module / Установить модуль
sudo semodule -r my-policy                    # Remove module / Удалить модуль
```

---

## AppArmor

### Check Status

```bash
sudo aa-status                                # AppArmor status / Статус AppArmor
sudo apparmor_status                          # Alternative / Альтернатива
```

### Profile Modes

```bash
sudo aa-enforce /usr/sbin/nginx               # Enforce mode / Режим enforce
sudo aa-complain /usr/sbin/nginx              # Complain mode / Режим complain
sudo aa-disable /usr/sbin/nginx               # Disable profile / Отключить профиль
```

### Manage Profiles

```bash
sudo aa-unconfined                            # List unconfined processes / Список процессов без профиля
ls /etc/apparmor.d/                           # List profiles / Список профилей
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx  # Reload profile / Перезагрузить профиль
```

### Log Analysis

```bash
sudo aa-logprof                               # Interactive log analysis / Интерактивный анализ логов
sudo aa-genprof /usr/bin/myapp                # Generate profile / Генерировать профиль
sudo grep 'apparmor="DENIED"' /var/log/syslog  # Find denials / Найти отказы
```

### Create Profile

```bash
# Generate profile
sudo aa-genprof /usr/bin/myapp

# 1. Put in complain mode / 1.
# 2. Run the application / 2.
# 3. Scan logs with aa-logprof / 3.
# 4. Allow/deny accesses / 4.
# 5. Save profile / 5.
```

---

## Troubleshooting

### SELinux Denials / SELinux

```bash
# Check denials
sudo ausearch -m avc -ts recent

# Generate policy
sudo audit2allow -a                           # Show rules / Показать правила
sudo audit2allow -a -M my-policy              # Create module / Создать модуль
sudo semodule -i my-policy.pp                 # Install module / Установить модуль
```

> [!WARNING]
> Use `audit2allow` carefully — it can create overly permissive policies. Always review generated rules before installing. / Используйте `audit2allow` осторожно — может создать слишком разрешительные политики.

### Common SELinux Fixes

```bash
# Web server can't access files
sudo restorecon -R -v /var/www/html

# Web server can't connect to network
sudo setsebool -P httpd_can_network_connect on

# Web server can't send mail
sudo setsebool -P httpd_can_sendmail on
```

### AppArmor Denials / AppArmor

```bash
# Check denials
sudo grep 'apparmor="DENIED"' /var/log/syslog | tail

# Switch to complain mode
sudo aa-complain /usr/sbin/nginx

# Test
# ... run application ...

# Update profile
sudo aa-logprof
```

---

## Real-World Examples

### Enable SELinux for Nginx

```bash
# Check status
getenforce

# Allow network connections
sudo setsebool -P httpd_can_network_connect on

# Allow proxy connections
sudo setsebool -P httpd_can_network_relay on

# Fix file contexts
sudo restorecon -R -v /var/www/html
sudo restorecon -R -v /etc/nginx
```

### AppArmor for Custom Application / AppArmor

```bash
# Generate profile
sudo aa-genprof /usr/local/bin/myapp

# Run application
/usr/local/bin/myapp

# Scan logs
sudo aa-logprof

# Enforce profile
sudo aa-enforce /usr/local/bin/myapp
```

### Debug SELinux Issues

```bash
# Set to permissive
sudo setenforce 0

# Test application
# ... application works now ...

# Check audit log
sudo sealert -a /var/log/audit/audit.log

# Fix issues
sudo restorecon -R -v /path/to/files
sudo setsebool -P some_boolean on

# Re-enable enforcing
sudo setenforce 1
```

### Container SELinux / SELinux

```bash
# Docker container contexts
ls -Z /var/lib/docker/

# Allow Docker container access
sudo setsebool -P container_manage_cgroup on

# Fix container volume contexts
sudo chcon -Rt svirt_sandbox_file_t /path/to/volume
```

---

## 💡 Best Practices

- **Never** disable SELinux/AppArmor in production. / Никогда не отключайте в продакшене.
- Use **permissive/complain** mode for debugging. / Используйте permissive/complain для отладки.
- Always `restorecon` after file operations. / Всегда восстанавливайте контексты после операций с файлами.
- Use `-P` flag for permanent boolean changes. / Используйте `-P` для постоянных изменений булевых.
- Monitor audit logs regularly. / Регулярно мониторьте логи аудита.
- Create custom modules instead of disabling SELinux. / Создавайте модули вместо отключения.
- Test policies before enforcing. / Тестируйте политики перед применением.

> [!IMPORTANT]
> Rebooting is required after changing SELinux between `disabled` and `enforcing`/`permissive`. / Перезагрузка требуется при переключении SELinux между `disabled` и `enforcing`/`permissive`.

---

## Configuration Files

| Path | Purpose (EN) | Назначение (RU) |
| :--- | :--- | :--- |
| `/etc/selinux/config` | SELinux main config | Основная конфигурация SELinux |
| `/var/log/audit/audit.log` | SELinux audit log | Лог аудита SELinux |
| `/etc/selinux/targeted/` | SELinux policy files | Файлы политик SELinux |
| `/etc/apparmor.d/` | AppArmor profiles | Профили AppArmor |
| `/var/log/syslog` | AppArmor log (Debian) | Лог AppArmor (Debian) |
| `/sys/kernel/security/apparmor/` | AppArmor runtime | Runtime AppArmor |

---

## Documentation Links

- **SELinux Project:** https://selinuxproject.org/
- **Red Hat — SELinux Guide:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_selinux/index
- **AppArmor Wiki:** https://gitlab.com/apparmor/apparmor/-/wikis/home
- **Ubuntu — AppArmor:** https://ubuntu.com/server/docs/apparmor
- **ArchWiki — SELinux:** https://wiki.archlinux.org/title/SELinux
- **ArchWiki — AppArmor:** https://wiki.archlinux.org/title/AppArmor
- **semanage(8):** https://man7.org/linux/man-pages/man8/semanage.8.html
- **restorecon(8):** https://man7.org/linux/man-pages/man8/restorecon.8.html
