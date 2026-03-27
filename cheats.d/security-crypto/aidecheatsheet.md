Title: 🛡️ AIDE (Integrity Checker)
Group: Security & Crypto
Icon: 🛡️
Order: 9

# AIDE (Advanced Intrusion Detection Environment) Sysadmin Cheatsheet

> **Context:** AIDE (Advanced Intrusion Detection Environment, [eyd]) is a file and directory integrity checker. It creates a database of filesystem state and compares against it to detect unauthorized modifications. / AIDE — средство проверки целостности файлов и каталогов. Создаёт базу данных состояния файловой системы и сравнивает с ней для обнаружения несанкционированных изменений.
> **Role:** Security Engineer / Sysadmin
> **Version:** AIDE 0.16+ / 0.17+

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Troubleshooting & Tools](#5-troubleshooting--tools)
6. [Logrotate Configuration](#6-logrotate-configuration)
7. [Documentation Links](#7-documentation-links)

---

## 1. Installation & Configuration

### Install AIDE / Установка AIDE

```bash
# RHEL/CentOS/AlmaLinux
dnf install aide

# Debian/Ubuntu
apt install aide aide-common

# openSUSE
zypper install aide
```

### Main Configuration File / Основной конфигурационный файл

`/etc/aide.conf` (RHEL) or `/etc/aide/aide.conf` (Debian)

```ini
# Database locations / Расположение баз данных
database_in=file:/var/lib/aide/aide.db.gz
database_out=file:/var/lib/aide/aide.db.new.gz
database_new=file:/var/lib/aide/aide.db.new.gz

# Gzip compression level / Уровень сжатия gzip
gzip_dbout=yes

# Report settings / Настройки отчётов
report_url=file:/var/log/aide/aide.log
report_url=stdout

# Log verbosity (default: 5) / Уровень детализации логов
verbose=5
```

### AIDE Check Attributes / Атрибуты проверки AIDE

| Attribute | Description / Описание |
|-----------|------------------------|
| `p` | Permissions / Права доступа |
| `i` | Inode number / Номер inode |
| `n` | Number of hard links / Количество жёстких ссылок |
| `u` | User ownership / Владелец |
| `g` | Group ownership / Группа |
| `s` | File size / Размер файла |
| `b` | Block count / Количество блоков |
| `m` | Modification time / Время модификации |
| `a` | Access time / Время доступа |
| `c` | Change time (inode) / Время изменения (inode) |
| `S` | Check for growing size / Проверка роста размера |
| `md5` | MD5 hash / Хэш MD5 |
| `sha256` | SHA-256 hash / Хэш SHA-256 |
| `sha512` | SHA-512 hash / Хэш SHA-512 |
| `acl` | POSIX ACL / POSIX ACL |
| `selinux` | SELinux context / Контекст SELinux |
| `xattrs` | Extended attributes / Расширенные атрибуты |

### Predefined Groups / Предопределённые группы

```ini
# Common predefined attribute groups / Часто используемые группы атрибутов
# NORMAL: check everything except access time / NORMAL: проверять всё кроме времени доступа
NORMAL = p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# For log files (only check growing) / Для лог-файлов (только проверка роста)
LOG = p+u+g+i+n+S

# For data files (full check) / Для файлов данных (полная проверка)
DATAONLY = p+n+u+g+s+acl+selinux+xattrs+sha256

# Permissions only / Только права доступа
PERMS = p+u+g+acl+selinux+xattrs
```

### Rule Examples / Примеры правил

`/etc/aide.conf`

```ini
# Monitor critical system directories / Мониторинг критических системных каталогов
/etc    NORMAL
/boot   NORMAL
/usr/bin NORMAL
/usr/sbin NORMAL
/usr/lib NORMAL

# Monitor config files strictly / Строгий мониторинг конфигов
/etc/passwd NORMAL
/etc/shadow NORMAL
/etc/group  NORMAL
/etc/sudoers NORMAL
/etc/ssh/sshd_config NORMAL

# Log files (only track growth) / Лог-файлы (только отслеживать рост)
/var/log LOG

# Exclude directories / Исключить каталоги
!/var/log/journal
!/var/cache
!/tmp
!/run
!/proc
!/sys
!/dev
!/var/lib/aide
```

---

## 2. Core Management

### Initialize Database / Инициализация базы данных

> [!IMPORTANT]
> Initialize AIDE on a known-clean system. The initial database becomes your trusted baseline. / Инициализируйте AIDE на заведомо чистой системе. Начальная БД станет вашим доверенным эталоном.

```bash
# Initialize AIDE database / Инициализировать базу данных AIDE
aide --init

# On Debian/Ubuntu (aideinit wrapper) / На Debian/Ubuntu (обёртка aideinit)
aideinit                  # Interactive init / Интерактивная инициализация
aideinit -y -f            # Force reinit, auto yes / Принудительная переинициализация, без вопросов

# Move new database to active position / Переместить новую БД в активную позицию
cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

### Run Integrity Check / Запуск проверки целостности

```bash
# Run check / Запустить проверку
aide --check

# Check with explicit config (Debian path) / Проверка с явным конфигом (Debian)
aide -C -c /etc/aide/aide.conf

# Check with detailed output / Проверка с подробным выводом
aide --check --verbose=20

# Check specific config (RHEL path) / Проверка с конкретным конфигом (RHEL)
aide --check --config=/etc/aide.conf
```

Sample output:
```
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	56890
  Added entries:		3
  Removed entries:		0
  Changed entries:		5
```

### Update Database / Обновление базы данных

> [!WARNING]
> Only update the database after verifying that all detected changes are legitimate. / Обновляйте базу данных только после проверки легитимности всех обнаруженных изменений.

```bash
# Update database (creates new DB with current state) / Обновить БД
aide --update

# Replace old database with updated one / Заменить старую БД обновлённой
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

### Compare Two Databases / Сравнение двух баз данных

```bash
# Compare old and new databases / Сравнить старую и новую БД
aide --compare
```

---

## 3. Sysadmin Operations

### Automated Daily Check (Cron) / Автоматическая ежедневная проверка (Cron)

`/etc/cron.daily/aide-check` (make executable)

```bash
#!/bin/bash
# Daily AIDE integrity check / Ежедневная проверка целостности AIDE
LOGFILE="/var/log/aide/aide-check-$(date +%F).log"
MAILTO="root"

aide --check > "$LOGFILE" 2>&1
RETVAL=$?

if [ $RETVAL -ne 0 ]; then
    mail -s "AIDE Alert: Changes detected on $(hostname)" "$MAILTO" < "$LOGFILE"
fi
```

```bash
chmod +x /etc/cron.daily/aide-check
```

### Systemd Timer Alternative / Альтернатива через systemd timer

`/etc/systemd/system/aide-check.service`

```ini
[Unit]
Description=AIDE Integrity Check
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/aide --check
StandardOutput=append:/var/log/aide/aide-check.log
StandardError=append:/var/log/aide/aide-check.log
```

`/etc/systemd/system/aide-check.timer`

```ini
[Unit]
Description=Run AIDE integrity check daily

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl enable --now aide-check.timer  # Enable timer / Включить таймер
systemctl list-timers aide-check*        # Verify timer / Проверить таймер
```

### Important Paths / Важные пути

| Path | Description |
|------|-------------|
| `/etc/aide.conf` | Main config (RHEL) / Основной конфиг |
| `/etc/aide/aide.conf` | Main config (Debian) / Основной конфиг |
| `/etc/aide.conf.d/` | Additional rule files (RHEL 9+) / Дополнительные правила |
| `/var/lib/aide/aide.db.gz` | Active database / Активная БД |
| `/var/lib/aide/aide.db.new.gz` | Newly generated database / Новая БД |
| `/var/log/aide/` | AIDE reports / Отчёты AIDE |

---

## 4. Security

### Best Practices / Лучшие практики

> [!CAUTION]
> Store the AIDE database on read-only media or a remote secure location. If an attacker can modify the AIDE database, the integrity check becomes useless. / Храните БД AIDE на носителе только для чтения или в удалённом безопасном месте.

```bash
# Store database on read-only USB or remote / Хранить БД на USB или удалённо
scp /var/lib/aide/aide.db.gz <USER>@<SECURE_HOST>:/backup/aide/

# Check with remote database / Проверка с удалённой БД
scp <USER>@<SECURE_HOST>:/backup/aide/aide.db.gz /tmp/aide.db.gz
aide --check --config=/etc/aide.conf --before="database_in=file:/tmp/aide.db.gz"
```

### Exclude Patterns for Noisy Directories / Исключения для шумных каталогов

```ini
# /etc/aide.conf - Exclude dynamic content / Исключения для динамического контента
!/var/log/journal
!/var/cache
!/var/tmp
!/tmp
!/run
!/proc
!/sys
!/dev/shm
!/var/lib/docker
!/var/lib/containerd
!/home/.*/.cache
```

---

## 5. Troubleshooting & Tools

### Common Issues / Частые проблемы

#### 1. Too Many False Positives / Слишком много ложных срабатываний

```bash
# Review what's changing / Проверить что меняется
aide --check 2>&1 | grep -E "^(changed|added|removed):"

# Adjust rules to exclude noisy paths / Настроить правила для исключения шумных путей
# Add exclusions to /etc/aide.conf / Добавить исключения в aide.conf
```

#### 2. Database Initialization Takes Too Long / Инициализация БД занимает слишком долго

```bash
# Check what directories are being scanned / Проверить какие каталоги сканируются
aide --init --verbose=20 2>&1 | tail -f

# Reduce scope by excluding large dirs / Уменьшить область, исключив большие каталоги
```

#### 3. AIDE Returns Exit Codes / Коды возврата AIDE

| Exit Code | Description / Описание |
|-----------|------------------------|
| `0` | No changes detected / Изменений не обнаружено |
| `1` | New files added / Добавлены новые файлы |
| `2` | Files removed / Файлы удалены |
| `4` | Files changed / Файлы изменены |
| `7` | All types of changes (1+2+4) / Все типы изменений |
| `14` | Error writing DB / Ошибка записи БД |
| `15` | Invalid argument / Неверный аргумент |
| `16` | Unimplemented function / Не реализованная функция |
| `17` | Configuration error / Ошибка конфигурации |
| `18` | IO error / Ошибка ввода-вывода |

> [!TIP]
> Exit codes are bitmask-additive. Code `5` means files were both added (`1`) and changed (`4`). / Коды возврата суммируются побитово. Код `5` означает, что файлы были добавлены (`1`) и изменены (`4`).

---

## 6. Logrotate Configuration

`/etc/logrotate.d/aide`

```conf
/var/log/aide/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```


---

## 7. Documentation Links

- [AIDE Official Website](https://aide.github.io/)
- [AIDE GitHub Repository](https://github.com/aide/aide)
- [AIDE Manual](https://aide.github.io/doc/)
- [AIDE Configuration Reference](https://aide.github.io/doc/configuration.html)
- [RHEL AIDE Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/checking-integrity-with-aide_security-hardening)

---
