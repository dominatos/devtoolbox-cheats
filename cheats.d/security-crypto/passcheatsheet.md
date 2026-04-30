Title: 🔐 pass — Password Store
Group: Security & Crypto
Icon: 🔐
Order: 5

# pass (Password Store) Sysadmin Cheatsheet

> **Context:** `pass` is the standard Unix password manager. It stores passwords as GPG-encrypted files in a simple directory tree (`~/.password-store/`). Each password lives in a `.gpg` file whose filename is the entry name. It natively integrates with Git for version control and sync. Extensions add OTP, import, and browser integration. It is lightweight, scriptable, and follows the Unix philosophy. / `pass` — стандартный Unix менеджер паролей. Хранит пароли как GPG-зашифрованные файлы в дереве каталогов. Нативно интегрируется с Git для синхронизации. Лёгкий, скриптуемый, следует философии Unix.
> **Role:** Sysadmin / Developer
> **See also:** [GPG/age Encryption](gpgagecheatsheet.md)

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Organization & Search](#3-organization--search)
4. [Git Integration](#4-git-integration)
5. [Extensions](#5-extensions)
6. [Real-World Examples](#6-real-world-examples)
7. [Best Practices](#7-best-practices)
8. [Documentation Links](#8-documentation-links)

---

## 1. Installation & Configuration

### Install pass / Установка pass

```bash
sudo apt install pass                         # Debian/Ubuntu
sudo dnf install pass                         # RHEL/Fedora
sudo pacman -S pass                           # Arch Linux
brew install pass                             # macOS
```

> [!IMPORTANT]
> `pass` requires a GPG key. Generate one first with `gpg --gen-key` if you don't have one.
> `pass` требует GPG ключ. Сначала создайте его с помощью `gpg --gen-key`.

### Initialize Store / Инициализировать хранилище

```bash
pass init <GPG_KEY_ID>                        # Initialize with GPG key / Инициализировать с GPG ключом
pass init <EMAIL>                             # Initialize with email / Инициализировать с email
```

### Multiple Users / Несколько пользователей

```bash
pass init <KEY1> <KEY2> <KEY3>                # Multi-user store / Хранилище для нескольких пользователей
pass init -p team/ <TEAM_KEY_ID>              # Initialize subdirectory / Инициализировать поддиректорию
```

### Directory Structure / Структура директорий

| Path | Description (EN / RU) |
|------|----------------------|
| `~/.password-store/` | Password store / Хранилище паролей |
| `~/.password-store/.gpg-id` | GPG key ID / ID GPG ключа |
| `~/.password-store/.git/` | Git repository / Git репозиторий |

---

## 2. Core Management

### Insert Passwords / Вставить пароли

```bash
pass insert site.com/user                     # Add entry (prompt) / Добавить запись (запрос пароля)
pass insert -m site.com/user                  # Multiline entry / Многострочная запись
pass insert -e site.com/user                  # Insert from editor / Вставить из редактора
echo "<PASSWORD>" | pass insert -e site.com/user  # Insert from stdin / Вставить из stdin
```

### Generate Passwords / Сгенерировать пароли

```bash
pass generate site.com/user 20                # Generate 20-char password / Пароль 20 символов
pass generate site.com/user                   # Generate default length / Длина по умолчанию
pass generate -n site.com/user 16             # No symbols / Без символов
pass generate -c site.com/user 32             # Copy to clipboard / Скопировать в буфер
```

### Show Passwords / Показать пароли

```bash
pass site.com/user                            # Show password / Показать пароль
pass show site.com/user                       # Same as above / То же что выше
pass -c site.com/user                         # Copy to clipboard / Скопировать в буфер
pass -c2 site.com/user                        # Copy 2nd line (OTP) / Скопировать 2-ю строку (OTP)
```

### Edit & Remove / Редактировать и удалить

```bash
pass edit site.com/user                       # Edit entry / Редактировать запись
pass rm site.com/user                         # Remove entry / Удалить запись
pass rm -r site.com                           # Remove directory / Удалить директорию
```

---

## 3. Organization & Search

### List Entries / Список записей

```bash
pass                                          # List all entries / Список всех записей
pass ls                                       # Same as above / То же что выше
pass ls site.com                              # List subdirectory / Список поддиректории
```

### Search / Поиск

```bash
pass find github                              # Find entries / Найти записи
pass grep username                            # Search in passwords / Искать в паролях
```

### Move & Copy / Переместить и скопировать

```bash
pass mv old-site.com new-site.com             # Move entry / Переместить запись
pass cp site.com/user site.com/backup         # Copy entry / Скопировать запись
```

---

## 4. Git Integration

### Initialize Git / Инициализировать Git

```bash
pass git init                                 # Initialize git repo / Инициализировать git
pass git remote add origin <REPO_URL>         # Add remote / Добавить удалённый репозиторий
```

### Git Operations / Git операции

```bash
pass git push                                 # Push changes / Отправить изменения
pass git pull                                 # Pull changes / Получить изменения
pass git log                                  # Show commit history / История коммитов
pass git status                               # Check status / Проверить статус
```

> [!TIP]
> `pass` automatically creates git commits on every change. You only need to push/pull manually.
> `pass` автоматически коммитит при каждом изменении. Нужно только push/pull вручную.

---

## 5. Extensions

### OTP (One-Time Password) / OTP (одноразовый пароль)

```bash
pass otp insert site.com/user                 # Add OTP secret / Добавить OTP секрет
pass otp site.com/user                        # Generate OTP code / Сгенерировать OTP код
pass otp -c site.com/user                     # Copy OTP to clipboard / Скопировать OTP в буфер
```

### Import / Импорт

```bash
pass import keepass database.kdbx             # Import from KeePass / Импортировать из KeePass
pass import lastpass export.csv               # Import from LastPass / Импортировать из LastPass
pass import 1password export.1pif             # Import from 1Password / Импортировать из 1Password
```

### Common Extensions / Распространённые расширения

| Extension | Description (EN / RU) |
|-----------|----------------------|
| `pass-otp` | One-time passwords / Одноразовые пароли |
| `pass-update` | Update passwords / Обновление паролей |
| `pass-import` | Import from other tools / Импорт из других инструментов |
| `pass-tomb` | Encrypted filesystem / Зашифрованная файловая система |

---

## 6. Real-World Examples

### Team Setup / Настройка для команды

```bash
pass init <TEAM_GPG_KEY>
pass git init
pass git remote add origin git@git.company.com:passwords.git
pass git push -u origin main

# Team workflow / Командный рабочий процесс
pass insert servers/production-db
pass git push

# Other team members / Другие члены команды
pass git pull
pass servers/production-db
```

### Backup & Sync / Резервная копия и синхронизация

```bash
pass git init
pass git remote add origin git@github.com:<USER>/passwords.git
pass git push

# Sync on new machine / Синхронизация на новой машине
git clone git@github.com:<USER>/passwords.git ~/.password-store
pass
```

### Script Integration / Интеграция со скриптами

```bash
#!/bin/bash
# Get password in script / Получить пароль в скрипте
DB_PASS=$(pass database/production)
mysql -u admin -p"$DB_PASS" production
```

### Dmenu/Rofi Integration / Интеграция с Dmenu/Rofi

```bash
#!/bin/bash
pass -c $(pass ls | tail -n +2 | dmenu -p "Password:")
```

### Browser Integration / Интеграция с браузером

```bash
# Install passff (Firefox) or browserpass (Chrome)
# Store with URL / Сохранить с URL
pass insert -m github.com/username
# password
# url: https://github.com
# username: myuser
```

---

### Basic Workflow / Базовый рабочий процесс

```bash
# Initialize / Инициализировать
pass init <EMAIL>

# Add passwords / Добавить пароли
pass insert email/gmail
pass insert social/github
pass generate web/aws 32

# Use passwords / Использовать пароли
pass -c email/gmail              # Copy to clipboard / Скопировать в буфер
pass social/github               # Show password / Показать пароль
```

### Multiline Entries / Многострочные записи

```bash
# Add entry with metadata / Добавить запись с метаданными
pass insert -m aws/production

# Format:
# password123
# username: admin
# url: https://console.aws.amazon.com
# region: us-east-1

# Access / Доступ
pass aws/production              # Show all / Показать всё
pass -c aws/production           # Copy password / Скопировать пароль
pass -c2 aws/production          # Copy username / Скопировать имя пользователя
```

### OTP Integration / Интеграция OTP

```bash
# Add OTP secret / Добавить OTP секрет
pass otp insert github/user
# Enter otpauth://totp/...

# Generate codes / Генерировать коды
pass otp github/user             # Show OTP code / Показать OTP код
pass otp -c github/user          # Copy OTP code / Скопировать OTP код
```

## 7. Best Practices

- Use meaningful directory structure / Используйте осмысленную структуру директорий
- Store metadata with passwords / Храните метаданные с паролями
- Use git for backup and sync / Используйте git для резервного копирования
- Generate strong passwords (32+ chars) / Генерируйте сильные пароли (32+ символов)
- Backup GPG keys securely / Резервно копируйте GPG ключи безопасно
- Use OTP extension for 2FA / Используйте OTP расширение для 2FA

---

## 8. Documentation Links

- [pass Official Website](https://www.passwordstore.org/)
- [pass Man Page](https://git.zx2c4.com/password-store/about/)
- [pass-otp Extension](https://github.com/tadfisher/pass-otp)
- [pass-import Extension](https://github.com/roddhjav/pass-import)
- [passff (Firefox Extension)](https://github.com/passff/passff)
- [browserpass (Chrome Extension)](https://github.com/browserpass/browserpass-extension)
- [gopass (Enhanced pass)](https://github.com/gopasspw/gopass)
- [QtPass (GUI)](https://qtpass.org/)

---
