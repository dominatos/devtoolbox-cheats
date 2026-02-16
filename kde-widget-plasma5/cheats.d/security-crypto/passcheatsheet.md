Title: 🔐 pass — Password Store
Group: Security & Crypto
Icon: 🔐
Order: 5

## Table of Contents
- [Setup](#-setup--настройка)
- [Basic Operations](#-basic-operations--базовые-операции)
- [Organization](#-organization--организация)
- [Git Integration](#-git-integration--интеграция-с-git)
- [Extensions](#-extensions--расширения)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Setup / Настройка

### Initialize Store / Инициализировать хранилище
pass init <GPG_KEY_ID>                        # Initialize with GPG key / Инициализировать с GPG ключом
pass init user@example.com                    # Initialize with email / Инициализировать с email

### Multiple Users / Несколько пользователей
pass init <KEY1> <KEY2> <KEY3>                # Multi-user store / Хранилище для нескольких пользователей
pass init -p team/ <TEAM_KEY_ID>              # Initialize subdirectory / Инициализировать поддиректорию

---

# 📝 Basic Operations / Базовые операции

### Insert Passwords / Вставить пароли
pass insert site.com/user                     # Add entry (prompt for password) / Добавить запись (запрос пароля)
pass insert -m site.com/user                  # Multiline entry / Многострочная запись
pass insert -e site.com/user                  # Insert from editor / Вставить из редактора
echo "<PASSWORD>" | pass insert -e site.com/user  # Insert from stdin / Вставить из stdin

### Generate Passwords / Сгенерировать пароли
pass generate site.com/user 20                # Generate 20-char password / Сгенерировать пароль 20 символов
pass generate site.com/user                   # Generate default length / Сгенерировать длину по умолчанию
pass generate -n site.com/user 16             # No symbols / Без символов
pass generate -c site.com/user 32             # Copy to clipboard / Скопировать в буфер

### Show Passwords / Показать пароли
pass site.com/user                            # Show password / Показать пароль
pass show site.com/user                       # Same as above / То же что выше
pass -c site.com/user                         # Copy to clipboard / Скопировать в буфер
pass -c2 site.com/user                        # Copy 2nd line (OTP) / Скопировать 2-ю строку (OTP)

### Edit & Remove / Редактировать и удалить
pass edit site.com/user                       # Edit entry / Редактировать запись
pass rm site.com/user                         # Remove entry / Удалить запись
pass rm -r site.com                           # Remove directory / Удалить директорию

---

# 📁 Organization / Организация

### List Entries / Список записей
pass                                          # List all entries / Список всех записей
pass ls                                       # Same as above / То же что выше
pass ls site.com                              # List subdirectory / Список поддиректории

### Search / Поиск
pass find github                              # Find entries / Найти записи
pass grep username                            # Search in passwords / Искать в паролях

### Move & Copy / Переместить и скопировать
pass mv old-site.com new-site.com             # Move entry / Переместить запись
pass cp site.com/user site.com/backup         # Copy entry / Скопировать запись

---

# 🔄 Git Integration / Интеграция с Git

### Initialize Git / Инициализировать Git
pass git init                                 # Initialize git repo / Инициализировать git репозиторий
pass git remote add origin <REPO_URL>         # Add remote / Добавить удалённый репозиторий

### Git Operations / Git операции
pass git push                                 # Push changes / Отправить изменения
pass git pull                                 # Pull changes / Получить изменения
pass git log                                  # Show commit history / Показать историю коммитов
pass git status                               # Check status / Проверить статус

### Automatic Git / Автоматический Git
# pass automatically commits on changes / pass автоматически коммитит изменения
pass insert site.com/user                     # Auto-commits / Автоматический коммит
pass git push origin main                     # Sync to remote / Синхронизировать на удалённый

---

# 🔌 Extensions / Расширения

### OTP (One-Time Password) / OTP (одноразовый пароль)
pass otp insert site.com/user                 # Add OTP secret / Добавить OTP секрет
pass otp site.com/user                        # Generate OTP code / Сгенерировать OTP код
pass otp -c site.com/user                     # Copy OTP to clipboard / Скопировать OTP в буфер

### Import / Импорт
pass import keepass database.kdbx             # Import from KeePass / Импортировать из KeePass
pass import lastpass export.csv               # Import from LastPass / Импортировать из LastPass

---

# 🌟 Real-World Examples / Примеры из практики

### Basic Workflow / Базовый рабочий процесс
```bash
# Initialize / Инициализировать
pass init user@example.com

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

### Team Setup / Настройка для команды
```bash
# Initialize for team / Инициализировать для команды
pass init <TEAM_GPG_KEY>

# Setup git sync / Настроить git синхронизацию
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

### OTP Integration / Интеграция OTP
```bash
# Add OTP secret / Добавить OTP секрет
pass otp insert github/user
# Enter otpauth://totp/...

# Generate codes / Генерировать коды
pass otp github/user             # Show OTP code / Показать OTP код
pass otp -c github/user          # Copy OTP code / Скопировать OTP код
```

### Backup & Sync / Резервная копия и синхронизация
```bash
# Backup to remote / Резервная копия на удалённый
pass git init
pass git remote add origin git@github.com:user/passwords.git
pass git push

# Sync on new machine / Синхронизация на новой машине
git clone git@github.com:user/passwords.git ~/.password-store
pass
```

### Import from Other Tools / Импорт из других инструментов
```bash
# Import from LastPass / Импорт из LastPass
pass import lastpass export.csv

# Import from KeePass / Импорт из KeePass
pass import keepass database.kdbx

# Import from 1Password / Импорт из 1Password
pass import 1password export.1pif
```

### Browser Integration / Интеграция с браузером
```bash
# Install passff (Firefox) or browserpass (Chrome) / Установить passff (Firefox) или browserpass (Chrome)
# Configure native messaging / Настроить нативный обмен сообщениями

# Store with URL / Сохранитьс URL
pass insert -m github.com/username
# password
# url: https://github.com
# username: myuser
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
# passmenu script / passmenu скрипт
#!/bin/bash
pass -c $(pass ls | tail -n +2 | dmenu -p "Password:")
```

# 💡 Best Practices / Лучшие практики
# Use meaningful directory structure / Используйте осмысленную структуру директорий
# Store metadata with passwords / Храните метаданные с паролями
# Use git for backup and sync / Используйте git для резервного копирования и синхронизации
# Generate strong passwords (32+ chars) / Генерируйте сильные пароли (32+ символов)
# Backup GPG keys securely / Резервно копируйте GPG ключи безопасно
# Use OTP extension for 2FA / Используйте OTP расширение для 2FA

# 🔧 Directory Structure / Структура директорий
# ~/.password-store/ — Password store / Хранилище паролей
# ~/.password-store/.gpg-id — GPG key ID / ID GPG ключа
# ~/.password-store/.git/ — Git repository / Git репозиторий

# 📋 Common Extensions / Распространённые расширения
# pass-otp — One-time passwords / Одноразовые пароли
# pass-update — Update passwords / Обновление паролей
# pass-import — Import from other tools / Импорт из других инструментов
# pass-tomb — Encrypted filesystem / Зашифрованная файловая система

# ⚠️ Important Notes / Важные примечания
# Requires GPG key / Требует GPG ключ
# Passwords encrypted with GPG / Пароли зашифрованы с GPG
# Directory structure = entry names / Структура директорий = имена записей
# Auto-commits with git / Автоматические коммиты с git
# Cross-platform (Linux/macOS/Android) / Мультиплатформенный
