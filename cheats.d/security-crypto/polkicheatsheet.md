---
Title: "🛡️ Polkit (PolicyKit) — Privilege Management"
Group: "Security & Crypto"
Icon: 🛡️
Order: 3
tags:
  - security
  - sysadmin
  - linux
  - privilege-escalation
  - polkit
  - pkexec
---

# 🛡️ Polkit (PolicyKit) — Privilege Management

**Polkit** (formerly PolicyKit) is a system-level toolkit for defining and handling privileges. It provides an organized way for unprivileged processes to communicate with privileged ones for system-wide actions. Polkit is used by systemd, D-Bus services, and desktop environments to control privilege escalation.

**Common use cases:**
- Running single commands as root via `pkexec` (alternative to `sudo`)
- Controlling access to system services (e.g., NetworkManager, systemd units)
- Managing desktop actions (mounting drives, printing, changing network settings)
- Restricting which users can perform administrative tasks without full sudo access

**Status / Статус:** Actively maintained and widely used on all modern Linux distributions. Essential component of systemd-based systems. Not legacy — there is no direct modern replacement.

| Feature | Polkit | sudo |
| :--- | :--- | :--- |
| **Approach** | Fine-grained per-action policies | User/group-based commands |
| **Configuration** | Declarative rules + XML actions | `/etc/sudoers` file |
| **Authentication** | Per-action, with timeout caching | Per-session or per-command |
| **Best for** | D-Bus services, systemd, desktop apps | Shell access, scripts |
| **Complexity** | Higher (rules engine) | Lower (single file) |

---

## 📚 Table of Contents

- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Concepts](#Core%20Concepts)
- [pkexec — Execute as Root](#pkexec%20—%20Execute%20as%20Root)
- [pkaction — List & Describe Actions](#pkaction%20—%20List%20&%20Describe%20Actions)
- [pkcheck — Check Authorization](#pkcheck%20—%20Check%20Authorization)
- [pkcontrol — Control polkitd](#pkcontrol%20—%20Control%20polkitd)
- [Polkit Rules](#Polkit%20Rules)
- [Polkit Actions (XML)](#Polkit%20Actions%20(XML))
- [Integration](#Integration)
- [Logging & Troubleshooting](#Logging%20&%20Troubleshooting)
- [Security Best Practices](#Security%20Best%20Practices)
- [Real-World Examples](#Real-World%20Examples)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

### Package Installation

```bash
# Debian/Ubuntu — usually pre-installed
sudo apt install policykit-1                              # Install polkit / Установить polkit

# RHEL/CentOS/Fedora
sudo dnf install polkit                                   # Install polkit / Установить polkit

# Arch Linux
sudo pacman -S polkit                                     # Install polkit / Установить polkit

# openSUSE
sudo zypper install polkit                                # Install polkit / Установить polkit
```

### Verify Installation

```bash
pkaction --version                                        # Check polkit version / Проверить версию polkit
which polkitd                                             # Find polkitd binary / Найти бинарник polkitd
systemctl status polkit                                   # Check service status / Проверить статус сервиса
```

### Key File Paths

| Path | Description (EN / RU) |
| :--- | :--- |
| `/usr/bin/pkexec` | Execute programs as root / Запуск программ от root |
| `/usr/lib/polkit-1/polkitd` | Polkit daemon (older distros) / Демон polkit |
| `/usr/libexec/polkitd` | Polkit daemon (newer distros) / Демон polkit |
| `/etc/polkit-1/` | System-wide configuration / Системная конфигурация |
| `/etc/polkit-1/rules.d/` | Custom rules directory / Директория пользовательских правил |
| `/etc/polkit-1/localauthority/` | Local authority rules (legacy) / Локальные правила |
| `/usr/share/polkit-1/actions/` | Action definition files (XML) / Файлы определений действий |
| `/usr/share/polkit-1/rules.d/` | Distribution default rules / Правила дистрибутива |
| `/var/lib/polkit-1/` | Runtime data / Данные выполнения |

> [!NOTE]
> The daemon path varies by distribution. Newer systems use `/usr/libexec/polkitd`, older ones `/usr/lib/polkit-1/polkitd`. Check with `which polkitd` or `systemctl cat polkit`.

---

## Core Concepts

### How Polkit Works

Polkit operates on a **subjects → actions → authorization** model:

1. **Subject** — A process requesting privileged action (e.g., a user running `pkexec`)
2. **Action** — A named system operation defined in XML (e.g., `org.freedesktop.packagekit.system-update`)
3. **Authorization** — Polkit daemon evaluates rules to allow/deny/require-auth

### Authorization Results

| Result | Description (EN / RU) |
| :--- | :--- |
| `yes` | Authorized without authentication / Разрешено без аутентификации |
| `no` | Denied / Отказано |
| `auth_self` | Requires user password / Требуется пароль пользователя |
| `auth_admin` | Requires admin (root) password / Требуется пароль администратора |
| `auth_self_keep` | Password cached for session / Пароль кэшируется на сессию |
| `auth_admin_keep` | Admin password cached / Пароль администратора кэшируется |

### Polkit Agent

The polkit agent is a helper that prompts users for passwords during privilege escalation. It runs in the user session and communicates with polkitd via D-Bus.

```bash
# Common polkit agents / Типичные агенты polkit
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1   # GNOME
/usr/libexec/kf5/polkit-kde-authentication-agent-1               # KDE
lxpolkit                                                             # LXDE
mate-polkit                                                          # MATE
xfce-polkit                                                          # XFCE
```

> [!WARNING]
> A polkit agent must be running in your session for interactive authentication prompts to work. Headless servers typically use `auth_admin_keep` or pre-configured rules to avoid interactive prompts.

---

## pkexec — Execute as Root

`pkexec` runs a program with elevated privileges, similar to `sudo` but using polkit authorization.

### Basic Usage

```bash
pkexec <COMMAND>                                        # Run command as root / Запуск от root
pkexec --user <USER> <COMMAND>                          # Run as specific user / Запуск от конкретного пользователя
```

### Common Examples

```bash
pkexec systemctl restart nginx                          # Restart nginx as root / Перезапустить nginx от root
pkexec apt update                                       # Update packages / Обновить пакеты
pkexec useradd -m <USER>                                # Add user / Добавить пользователя
pkexec visudo                                           # Edit sudoers / Редактировать sudoers
pkexec cp /etc/config /etc/config.bak                   # Copy with root privileges / Копировать с привилегиями root
```

### Environment Variables

```bash
# pkexec strips most environment variables by default for security
# To preserve specific variables, use --keep-env
pkexec --keep-env <VARIABLE>=<VALUE> <COMMAND>          # Preserve env var / Сохранить переменную окружения

# List variables polkit allows / Список разрешённых переменных
pkexec env                                              # Show effective env / Показать окружение
```

> [!CAUTION]
> `pkexec` does NOT preserve shell aliases, functions, or most environment variables. For complex commands, wrap them in a script: `pkexec /usr/local/bin/myscript.sh`

### Polkit Agent for pkexec

```bash
# pkexec can invoke a custom authentication agent
pkexec --agent /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 <COMMAND>

# On headless servers, set DISPLAY for graphical agent (if available)
DISPLAY=:0 pkexec <COMMAND>
```

---

## pkaction — List & Describe Actions

`pkaction` queries available polkit actions and their properties.

### List All Actions

```bash
pkaction                                                # List all actions / Список всех действий
pkaction --verbose                                      # List with details / Список с подробностями
pkaction --verbose --action-id <ACTION_ID>              # Show specific action / Показать конкретное действие
```

### Query Action Properties

```bash
pkaction --action-id <ACTION_ID> --verbose              # Full details / Подробности
pkaction --action-id <ACTION_ID> --enable / --disable   # Check if enabled / Проверить включено ли
```

### Common Action IDs

| Action ID | Description (EN / RU) |
| :--- | :--- |
| `org.freedesktop.policykit.exec` | Execute as root via pkexec / Запуск от root через pkexec |
| `org.freedesktop.packagekit.system-update` | System update / Обновление системы |
| `org.freedesktop.systemd1.manage-units` | Manage systemd units / Управление юнитами systemd |
| `org.freedesktop.NetworkManager.settings.modify.system` | Modify system network settings / Изменение системных сетевых настроек |
| `org.freedesktop.accounts.change-own-user-data` | Change own user data / Изменение собственных данных |
| `org.freedesktop.login1.reboot` | Reboot system / Перезагрузка системы |
| `org.freedesktop.login1.power-off` | Power off system / Выключение системы |
| `org.freedesktop.udisks2.filesystem-mount` | Mount filesystems / Монтирование файловых систем |
| `org.freedesktop.firewall-config` | Configure firewall / Настройка файрвола |

### Create Custom Action

```bash
# Check if custom action exists
pkaction --action-id com.example.myaction --verbose 2>/dev/null || echo "Action not found"
```

---

## pkcheck — Check Authorization

`pkcheck` tests whether a subject is authorized for an action. Used in scripts and daemons.

### Basic Usage

```bash
pkcheck --action-id <ACTION_ID> --process <PID>         # Check process authorization / Проверить авторизацию процесса
pkcheck --action-id <ACTION_ID> --process $$            # Check current shell / Проверить текущий shell
pkcheck --action-id <ACTION_ID> --enable-internal-agent  # Allow user authentication / Разрешить аутентификацию
```

### Check Authorization with Details

```bash
# Check if PID is authorized for action
pkcheck --action-id <ACTION_ID> --process <PID> --user <USER>

# Check with specific details
pkcheck --action-id <ACTION_ID> --process <PID> \
  --detail device /dev/sda1 \
  --detail origin /media/<USER>/usb

# Allow authentication if needed (shows dialog)
pkcheck --action-id <ACTION_ID> --process <PID> --enable-internal-agent
```

### Exit Codes

| Code | Description (EN / RU) |
| :--- | :--- |
| `0` | Authorized / Разрешено |
| `1` | Not authorized / Не авторизовано |
| `2` | Error / Ошибка |
| `3` | User interaction required / Требуется взаимодействие с пользователем |

---

## pkcontrol — Control polkitd

`pkcontrol` controls the polkit daemon directly.

### Daemon Operations

```bash
pkcontrol --version                                      # Show version / Показать версию
pkcontrol --help                                         # Show help / Показать справку
```

### Manage polkitd

```bash
systemctl start polkit                                   # Start daemon / Запустить демон
systemctl stop polkit                                    # Stop daemon / Остановить демон
systemctl restart polkit                                 # Restart daemon / Перезапустить демон
systemctl reload polkit                                  # Reload rules / Перезагрузить правила
systemctl status polkit                                  # Check status / Проверить статус

# On older systems (sysvinit)
service polkit restart                                   # Restart via service / Перезапустить через service
```

> [!WARNING]
> Stopping polkitd will break privilege escalation for all polkit-dependent services (systemd, NetworkManager, etc.). Never stop polkitd on production systems.

---

## Polkit Rules

Polkit rules are JavaScript files that define authorization decisions. They are evaluated in lexical order (by filename).

### Rules Directory Structure

```bash
# Distribution rules (read-only)
/usr/share/polkit-1/rules.d/

# System administrator rules (highest priority)
/etc/polkit-1/rules.d/

# Local authority rules (legacy, deprecated)
/etc/polkit-1/localauthority/
```

### Rule File Naming

```bash
# Files are evaluated in lexicographic order
# Use numeric prefix for ordering
/etc/polkit-1/rules.d/00-defaults.rules    # First
/etc/polkit-1/rules.d/10-admin.rules       # Second
/etc/polkit-1/rules.d/90-custom.rules      # Last
```

### Rule File Syntax

`/etc/polkit-1/rules.d/<FILENAME>.rules`

```javascript
// Allow all users to run updates without authentication
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.packagekit.system-update") {
        return polkit.Result.YES;
    }
});
```

### Rule Templates

#### Allow Specific User for All Actions

`/etc/polkit-1/rules.d/10-allow-user.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (subject.user == "<USER>") {
        return polkit.Result.YES;
    }
});
```

#### Allow Group for Specific Action

`/etc/polkit-1/rules.d/20-group-network.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.isInGroup("netadmin")) {
        return polkit.Result.YES;
    }
});
```

#### Require Authentication for Dangerous Actions

`/etc/polkit-1/rules.d/30-restrict-dangerous.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.power-off" ||
        action.id == "org.freedesktop.login1.halt") {
        return polkit.Result.AUTH_ADMIN;
    }
});
```

#### Deny Action for Everyone

`/etc/polkit-1/rules.d/40-deny-reboot.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.reboot") {
        return polkit.Result.NO;
    }
});
```

#### Allow USB Mounting for Local Users

`/etc/polkit-1/rules.d/50-usb-mount.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
        subject.local == true) {
        return polkit.Result.YES;
    }
});
```

#### Allow Specific Command via pkexec

`/etc/polkit-1/rules.d/60-myapp.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("path") == "/usr/local/bin/myapp") {
        return polkit.Result.YES;
    }
});
```

#### Conditional Rules with Details

`/etc/polkit-1/rules.d/70-conditional.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" &&
        action.lookup("device").startsWith("/dev/sdb")) {
        return polkit.Result.AUTH_SELF;
    }
});
```

### Rule Priority & Ordering

| Priority | File Location | Evaluation Order |
| :--- | :--- | :--- |
| Highest | `/etc/polkit-1/rules.d/` | Evaluated last (overrides) |
| Medium | `/usr/share/polkit-1/rules.d/` | Evaluated first (defaults) |
| Lowest | Legacy `localauthority/` | Deprecated, lowest priority |

> [!TIP]
> Rules are evaluated in order. The **first** rule that returns a result wins. Place restrictive rules after permissive ones, or use `return` to stop evaluation early.

### Reload Rules

```bash
sudo systemctl reload polkit                              # Reload rules / Перезагрузить правила
# Rules take effect immediately for new requests
```

---

## Polkit Actions (XML)

Actions are defined in XML files. Each file declares one or more actions with their descriptions, defaults, and vendor information.

### Action File Structure

`/usr/share/polkit-1/actions/com.example.myaction.policy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>

  <vendor>My Company</vendor>
  <vendor_url>https://example.com</vendor_url>

  <action id="com.example.myaction">
    <description>My Custom Action</description>
    <message>Authentication is required to run my action</message>

    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_self</allow_active>
    </defaults>

    <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/myapp</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">false</annotate>
  </action>

</policyconfig>
```

### Default Authorization Levels

| Element | Description (EN / RU) |
| :--- | :--- |
| `<allow_any>` | Unspecified session type / Неуказанный тип сессии |
| `<allow_inactive>` | Local inactive session (e.g., logged in but not focused) / Локальная неактивная сессия |
| `<allow_active>` | Local active session (focused session) / Локальная активная сессия |

### Policy Values

| Value | Description (EN / RU) |
| :--- | :--- |
| `yes` | Always allowed / Всегда разрешено |
| `no` | Always denied / Всегда запрещено |
| `auth_self` | Require user password / Требуется пароль пользователя |
| `auth_admin` | Require root/admin password / Требуется пароль администратора |
| `auth_self_keep` | Cache user password / Кэшировать пароль пользователя |
| `auth_admin_keep` | Cache admin password / Кэшировать пароль администратора |

### Install Custom Action

```bash
# Copy action file
sudo cp com.example.myaction.policy /usr/share/polkit-1/actions/

# Verify
pkaction --action-id com.example.myaction --verbose
```

### Reload Actions

```bash
sudo systemctl restart polkit                            # Restart to reload actions / Перезапустить для перезагрузки
```

---

## Integration

### Integration with systemd

Polkit controls access to many systemd operations.

```bash
# Check which systemd actions require polkit
systemctl list-units --type=service                       # List services / Список сервисов

# Common polkit-gated systemd operations
systemctl stop <SERVICE>                                  # May require polkit / Может потребовать polkit
systemctl start <SERVICE>                                 # May require polkit / Может потребовать polkit
systemctl enable <SERVICE>                                # May require polkit / Может потребовать polkit
systemctl mask <SERVICE>                                  # May require polkit / Может потребовать polkit
systemctl daemon-reload                                   # May require polkit / Может потребовать polkit

# Polkit rules for systemd
# /etc/polkit-1/rules.d/80-systemd.rules
```

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
```

### Integration with D-Bus

Most polkit-protected services communicate via D-Bus. Polkitd listens on the system bus.

```bash
# Check polkitd D-Bus interface
busctl introspect org.freedesktop.PolicyKit1 /org/freedesktop/PolicyKit1/Authority

# Monitor polkit authorization requests
sudo dbus-monitor --system "interface='org.freedesktop.PolicyKit1.Authority'"
```

### Integration with NetworkManager

```bash
# polkit rules for NetworkManager
# Allow users in "netadmin" group to modify system network settings
```

`/etc/polkit-1/rules.d/90-networkmanager.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") === 0 &&
        subject.isInGroup("netadmin")) {
        return polkit.Result.YES;
    }
});
```

### Integration with udisks2 (Storage)

```bash
# Allow local users to mount removable media
# /etc/polkit-1/rules.d/50-udisks2.rules
```

`/etc/polkit-1/rules.d/50-udisks2.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
        subject.local == true) {
        return polkit.Result.YES;
    }
});
```

### Integration with PackageKit

```bash
# Allow users in "wheel" group to install packages
# /etc/polkit-1/rules.d/70-packagekit.rules
```

`/etc/polkit-1/rules.d/70-packagekit.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.packagekit.") === 0 &&
        subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_SELF_KEEP;
    }
});
```

---

## Logging & Troubleshooting

### Enable Debug Logging

```bash
# Run polkitd with debug output
sudo /usr/lib/polkit-1/polkitd --no-debug                # Normal mode / Обычный режим
sudo /usr/lib/polkit-1/polkitd --replace                 # Replace running instance / Заменить текущий экземпляр

# For verbose logging, edit polkitd startup or use journalctl
sudo journalctl -u polkit -f                             # Follow polkit logs / Следить за логами polkit
sudo journalctl -u polkit --since "10 min ago"           # Recent logs / Недавние логи
```

### View polkit Logs

```bash
# systemd-based systems
sudo journalctl -u polkit                                # All polkit logs / Все логи polkit
sudo journalctl -u polkit --priority=debug               # Debug level / Уровень отладки
sudo journalctl -u polkit --since "2026-01-01"           # Since date / С даты

# Older systems
sudo cat /var/log/auth.log | grep polkit                 # Check auth log / Проверить лог аутентификации
sudo grep polkit /var/log/secure                         # RHEL/CentOS / RHEL/CentOS
```

### Common Issues

#### pkexec Not Working

```bash
# Check if polkitd is running
systemctl status polkit

# Check polkit version
pkaction --version

# Verify pkexec has correct permissions
ls -la /usr/bin/pkexec
# Should be: -rwsr-xr-x 1 root root

# Fix permissions if needed
sudo chmod 4755 /usr/bin/pkexec                          # Set SUID bit / Установить SUID бит
sudo chown root:root /usr/bin/pkexec                     # Set ownership / Установить владельца
```

#### Rules Not Taking Effect

```bash
# Check rule file syntax (no errors in output)
sudo python3 -c "
import os
rules_dir = '/etc/polkit-1/rules.d/'
for f in sorted(os.listdir(rules_dir)):
    if f.endswith('.rules'):
        print(f'Checking {f}...')
        with open(os.path.join(rules_dir, f)) as fh:
            content = fh.read()
            if 'polkit.addRule' in content:
                print(f'  OK: Contains addRule')
            else:
                print(f'  WARNING: Missing addRule')
"

# Reload polkitd after rule changes
sudo systemctl reload polkit

# Check for JavaScript errors in rules
# polkitd logs rule errors to journal
sudo journalctl -u polkit | grep -i "error\|syntax\|rule"
```

#### Authentication Dialog Not Appearing

```bash
# Ensure polkit agent is running
ps aux | grep polkit-agent

# Start GNOME agent manually
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &

# Start KDE agent manually
/usr/libexec/kf5/polkit-kde-authentication-agent-1 &

# Check D-Bus session
echo $DBUS_SESSION_BUS_ADDRESS
```

#### polkitd Fails to Start

```bash
# Check for port conflicts
sudo ss -tlnp | grep polkitd

# Check JavaScript engine (polkitd requires mozjs or duktape)
sudo journalctl -u polkit -n 50                         # Check for JS errors / Проверить ошибки JS

# Verify polkitd binary
file /usr/lib/polkit-1/polkitd                           # Check binary type / Проверить тип бинарника
ldd /usr/lib/polkit-1/polkitd                            # Check dependencies / Проверить зависимости
```

### Debug polkit Authorization

```bash
# Test specific authorization
pkcheck --action-id org.freedesktop.policykit.exec \
  --process $$ --enable-internal-agent                    # Test with auth / Тест с аутентификацией

# Monitor real-time authorization requests
sudo dbus-monitor --system \
  "interface='org.freedesktop.PolicyKit1.Authority'" \
  "member='CheckAuthorization'"                          # Monitor auth checks / Мониторинг проверок
```

---

## Security Best Practices

### General Principles

- **Principle of least privilege:** Only grant the minimum permissions needed / Принцип наименьших привилегий
- **Use specific action IDs:** Never grant `org.freedesktop.policykit.exec` without restricting `path` / Используйте конкретные ID действий
- **Prefer `auth_self` over `auth_admin`:** Let users authenticate themselves when appropriate / Предпочитайте `auth_self`
- **Never set `<allow_any>yes</allow_any>`:** This bypasses authentication on any session / Никогда не устанавливайте `yes` для `allow_any`
- **Use group-based rules:** Easier to manage than user-specific rules / Используйте правила на основе групп
- **Audit rules regularly:** Review `/etc/polkit-1/rules.d/` periodically / Регулярно проверяйте правила

### Dangerous Patterns to Avoid

```javascript
// BAD: Grants root to everyone
polkit.addRule(function(action, subject) {
    return polkit.Result.YES;
});

// BAD: No restriction on which path can be executed
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec") {
        return polkit.Result.YES;
    }
});

// BAD: Allows all NetworkManager actions without auth
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") === 0) {
        return polkit.Result.YES;
    }
});
```

### Secure Rule Template

`/etc/polkit-1/rules.d/90-secure-defaults.rules`

```javascript
// Secure defaults: require auth for everything sensitive
polkit.addRule(function(action, subject) {
    // Never allow unauthenticated power operations
    if (action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.power-off" ||
        action.id == "org.freedesktop.login1.halt") {
        return polkit.Result.AUTH_ADMIN;
    }
});

// Allow admins to manage services
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
    }
});
```

---

## Real-World Examples

### Allow User to Restart Specific Services

`/etc/polkit-1/rules.d/50-webadmin.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.user == "<USER>" &&
        (action.lookup("unit") == "nginx.service" ||
         action.lookup("unit") == "php-fpm.service" ||
         action.lookup("unit") == "mysql.service")) {
        return polkit.Result.YES;
    }
});
```

### Allow Group to Use NetworkManager

`/etc/polkit-1/rules.d/60-network.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.isInGroup("netadmin")) {
        return polkit.Result.AUTH_SELF;
    }
});
```

### Create Custom pkexec Action

1. Create action XML:

`/usr/share/polkit-1/actions/com.example.restart-app.policy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <vendor>My Company</vendor>
  <vendor_url>https://example.com</vendor_url>

  <action id="com.example.restart-app">
    <description>Restart My Application</description>
    <message>Authentication is required to restart the application</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/restart-app.sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">false</annotate>
  </action>
</policyconfig>
```

2. Create the script:

`/usr/local/bin/restart-app.sh`

```bash
#!/bin/bash
systemctl restart myapp
```

3. Set permissions and use:

```bash
sudo chmod 755 /usr/local/bin/restart-app.sh             # Set script permissions / Установить права
pkexec com.example.restart-app                           # Run via polkit / Запуск через polkit
```

### Migrate from sudo to polkit

```bash
# Instead of adding to sudoers:
# <USER> ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx

# Create polkit rule:
```

`/etc/polkit-1/rules.d/40-nginx-restart.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "nginx.service" &&
        subject.user == "<USER>") {
        return polkit.Result.YES;
    }
});
```

### Restrict USB Storage Mounting

`/etc/polkit-1/rules.d/55-usb-restrict.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
        if (subject.isInGroup("usbusers")) {
            return polkit.Result.AUTH_SELF;
        }
        return polkit.Result.NO;
    }
});
```

### Allow Printer Administration for Group

`/etc/polkit-1/rules.d/65-printer.rules`

```javascript
polkit.addRule(function(action, action_id, subject) {
    if (action.id.indexOf("org.opensuse.cups-pk-helper.") === 0 &&
        subject.isInGroup("printadmin")) {
        return polkit.Result.YES;
    }
});
```

### Emergency: Disable All polkit Authentication

`/etc/polkit-1/rules.d/99-emergency.rules`

```javascript
// EMERGENCY ONLY: Allow everything without auth
// REMOVE THIS FILE IMMEDIATELY AFTER USE
polkit.addRule(function(action, subject) {
    return polkit.Result.YES;
});
```

```bash
# Apply
sudo systemctl reload polkit

# REMEMBER TO REMOVE:
sudo rm /etc/polkit-1/rules.d/99-emergency.rules
sudo systemctl reload polkit
```

> [!CAUTION]
> Only use emergency rules for short-term troubleshooting. Leaving `return polkit.Result.YES` as a catch-all defeats all security policies and exposes the system to privilege escalation attacks.

---

## Documentation Links

- [Polkit Official Documentation](https://www.freedesktop.org/software/polkit/docs/latest/)
- [Polkit Manual Pages](https://www.freedesktop.org/software/polkit/docs/latest/polkit.8.html)
- [pkexec(8) Manual](https://www.freedesktop.org/software/polkit/docs/latest/pkexec.1.html)
- [pkaction(1) Manual](https://www.freedesktop.org/software/polkit/docs/latest/pkaction.1.html)
- [pkcheck(1) Manual](https://www.freedesktop.org/software/polkit/docs/latest/pkcheck.1.html)
- [Polkit Rules Introduction](https://www.freedesktop.org/software/polkit/docs/latest/rules-format.html)
- [Polkit Actions Format](https://www.freedesktop.org/software/polkit/docs/latest/actions-format.html)
- [ArchWiki — Polkit](https://wiki.archlinux.org/title/Polkit)
- [Debian Wiki — PolicyKit](https://wiki.debian.org/PolicyKit)
- [Red Hat — Understanding Polkit](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/securing_using_and_customizing_rhel_9_security/securing-privilege-access-with-polkit_securing-privilege-access)

---
