Title: 🔐 GPG / age — Encryption
Group: Security & Crypto
Icon: 🔐
Order: 4

## Table of Contents
- [GPG — Key Management](#-gpg--key-management--управление-ключами)
- [GPG — Encryption/Decryption](#-gpg--encryptiondecryption--шифрованиерасшифровка)
- [GPG — Signing & Verification](#-gpg--signing--verification--подпись-и-проверка)
- [age — Modern Encryption](#-age--modern-encryption--современное-шифрование)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔑 GPG — Key Management / Управление ключами

### Generate Keys / Генерация ключей
gpg --gen-key                                 # Generate key (interactive) / Генерировать ключ (интерактивно)
gpg --full-generate-key                       # Full key generation / Полная генерация ключа
gpg --quick-generate-key "<USER> <<EMAIL>>"   # Quick key generation / Быстрая генерация ключа
gpg --quick-generate-key "<USER> <<EMAIL>>" rsa4096  # RSA 4096-bit key / Ключ RSA 4096 бит

### List Keys / Список ключей
gpg --list-keys                               # List public keys / Список публичных ключей
gpg --list-secret-keys                        # List private keys / Список приватных ключей
gpg --list-sigs                               # List signatures / Список подписей
gpg -K                                        # Short for list-secret-keys / Короткая форма

### Export Keys / Экспорт ключей
gpg --export <KEY_ID> > public.gpg            # Export public key / Экспортировать публичный ключ
gpg --export --armor <KEY_ID> > public.asc    # Export ASCII armored / Экспортировать в ASCII
gpg --export-secret-keys --armor <KEY_ID> > private.asc  # Export private key / Экспортировать приватный ключ
gpg --export-secret-subkeys <KEY_ID> > subkeys.gpg  # Export subkeys / Экспортировать подключи

### Import Keys / Импорт ключей
gpg --import public.asc                       # Import public key / Импортировать публичный ключ
gpg --import private.asc                      # Import private key / Импортировать приватный ключ

### Delete Keys / Удаление ключей
gpg --delete-keys <KEY_ID>                    # Delete public key / Удалить публичный ключ
gpg --delete-secret-keys <KEY_ID>             # Delete private key / Удалить приватный ключ
gpg --delete-secret-and-public-keys <KEY_ID>  # Delete both / Удалить оба

### Edit Keys / Редактирование ключей
gpg --edit-key <KEY_ID>                       # Edit key (interactive) / Редактировать ключ (интерактивно)
# > adduid                                    # Add UID / Добавить UID
# > expire                                    # Change expiration / Изменить срок действия
# > trust                                     # Set trust level / Установить уровень доверия
# > save                                      # Save and exit / Сохранить и выйти

### Keyserver Operations / Операции с серверами ключей
gpg --send-keys <KEY_ID>                      # Send to keyserver / Отправить на сервер ключей
gpg --recv-keys <KEY_ID>                      # Receive from keyserver / Получить с сервера ключей
gpg --search-keys <EMAIL>                     # Search keyserver / Поиск на сервере ключей
gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>  # Specific server / Конкретный сервер

---

# 🔒 GPG — Encryption/Decryption / Шифрование/Расшифровка

### Symmetric Encryption / Симметричное шифрование
gpg --symmetric file                          # Encrypt with password / Зашифровать паролем
gpg --symmetric --cipher-algo AES256 file     # AES256 encryption / Шифрование AES256
gpg -c file                                   # Short form / Короткая форма

### Asymmetric Encryption / Асимметричное шифрование
gpg --encrypt --recipient <EMAIL> file        # Encrypt for recipient / Зашифровать для получателя
gpg -e -r <EMAIL> file                        # Short form / Короткая форма
gpg --encrypt --armor -r <EMAIL> file         # ASCII armored / В формате ASCII
gpg --encrypt --recipient <EMAIL1> --recipient <EMAIL2> file  # Multiple recipients / Несколько получателей

### Decryption / Расшифровка
gpg --decrypt file.gpg                        # Decrypt file / Расшифровать файл
gpg -d file.gpg                               # Short form / Короткая форма
gpg -d file.gpg > decrypted.txt               # Decrypt to file / Расшифровать в файл
gpg --decrypt --output decrypted.txt file.gpg # Decrypt with output / Расшифровать с выводом

### Encrypt and Sign / Зашифровать и подписать
gpg --encrypt --sign --recipient <EMAIL> file # Encrypt and sign / Зашифровать и подписать
gpg -es -r <EMAIL> file                       # Short form / Короткая форма

---

# ✍️ GPG — Signing & Verification / Подпись и проверка

### Sign Files / Подписание файлов
gpg --sign file                               # Sign file / Подписать файл
gpg -s file                                   # Short form / Короткая форма
gpg --clearsign file                          # Clear text signature / Подпись открытым текстом
gpg --detach-sign file                        # Detached signature / Отдельная подпись
gpg --armor --detach-sign file                # ASCII detached signature / ASCII отдельная подпись

### Verify Signatures / Проверка подписей
gpg --verify file.sig file                    # Verify detached signature / Проверить отдельную подпись
gpg --verify file.sig                         # Verify signature / Проверить подпись
gpg --verify file.asc                         # Verify clear-signed / Проверить подпись открытым текстом

### Sign and Encrypt / Подписать и зашифровать
gpg --sign --encrypt --recipient <EMAIL> file # Sign then encrypt / Подписать затем зашифровать
gpg -se -r <EMAIL> file                       # Short form / Короткая форма

---

# 🆕 age — Modern Encryption / Современное шифрование

### Install / Установка
sudo apt install age                          # Debian/Ubuntu
brew install age                              # macOS
go install filippo.io/age/cmd/...@latest      # From source / Из исходников

### Generate Keys / Генерация ключей
age-keygen > key.txt                          # Generate key / Генерировать ключ
age-keygen -o key.txt                         # Save to file / Сохранить в файл

### Encryption / Шифрование
age -p -o file.age file                       # Encrypt with password / Зашифровать паролем
age -p < file > file.age                      # Pipe encryption / Шифрование через pipe
age -r age1qqw... -o file.age file            # Encrypt with public key / Зашифровать публичным ключом
age -R recipients.txt -o file.age file        # Multiple recipients / Несколько получателей

### Decryption / Расшифровка
age -d -o file file.age                       # Decrypt with password / Расшифровать паролем
age -d < file.age > file                      # Pipe decryption / Расшифровка через pipe
age -d -i key.txt -o file file.age            # Decrypt with key / Расшифровать ключом
age -d -i key.txt < file.age > file           # Pipe with key / Pipe с ключом

### SSH Keys / SSH ключи
ssh-keygen -t ed25519 -C "age key"            # Generate SSH key / Генерировать SSH ключ
age -R ~/.ssh/id_ed25519.pub file > file.age  # Encrypt with SSH key / Зашифровать SSH ключом
age -d -i ~/.ssh/id_ed25519 file.age > file   # Decrypt with SSH key / Расшифровать SSH ключом

### Multiple Recipients / Несколько получателей
age -r age1qqw... -r age1xyz... -o file.age file  # Encrypt for multiple / Зашифровать для нескольких
cat recipients.txt                            # List recipients / Список получателей
# age1qqw...
# age1xyz...
age -R recipients.txt -o file.age file        # Encrypt from file / Зашифровать из файла

---

# 🐛 Troubleshooting / Устранение неполадок

### GPG Agent Issues / Проблемы агента GPG
gpg-agent --daemon                            # Start agent / Запустить агента
gpgconf --kill gpg-agent                      # Restart agent / Перезапустить агента
gpg-agent --daemon --pinentry-program /usr/bin/pinentry-curses  # Specify pinentry / Указать pinentry

### Trust Issues / Проблемы доверия
gpg --edit-key <KEY_ID>                       # Edit key / Редактировать ключ
# > trust                                     # Set trust / Установить доверие
# > 5                                         # Ultimate trust / Полное доверие
# > save                                      # Save / Сохранить

### Expired Keys / Истёкший срок действия
gpg --edit-key <KEY_ID>                       # Edit key / Редактировать ключ
# > expire                                    # Change expiration / Изменить срок
# > key 1                                     # Select subkey / Выбрать подключ
# > expire                                    # Change subkey expiration / Изменить срок подключа
# > save                                      # Save / Сохранить

### List Recipients / Список получателей
gpg --list-packets file.gpg                   # Show encryption info / Показать информацию о шифровании
gpg --batch --list-packets file.gpg | grep keyid  # Extract key IDs / Извлечь ID ключей

---

# 🌟 Real-World Examples / Примеры из практики

### Encrypt Directory / Зашифровать директорию
```bash
# GPG tar archive / GPG архив tar
tar -czf - directory/ | gpg -c -o directory.tar.gz.gpg

# age tar archive / age архив tar
tar -czf - directory/ | age -p > directory.tar.gz.age

# Decrypt and extract / Расшифровать и распаковать
gpg -d directory.tar.gz.gpg | tar -xzf -
age -d directory.tar.gz.age | tar -xzf -
```

### Backup Encryption / Шифрование резервной копии
```bash
# GPG backup / GPG резервная копия
tar -czf - /home/user | gpg -c -o backup-$(date +%F).tar.gz.gpg

# age backup / age резервная копия
tar -czf - /home/user | age -p > backup-$(date +%F).tar.gz.age

# Automated backup with age / Автоматизированная резервная копия с age
age-keygen > ~/.backup-key.txt
tar -czf - /home/user | age -r $(grep public ~/.backup-key.txt | cut -d: -f2) > backup.tar.gz.age
```

### Password Manager / Менеджер паролей
```bash
# pass uses GPG / pass использует GPG
pass init <GPG_KEY_ID>                        # Initialize password store / Инициализировать хранилище паролей
pass insert email/gmail                       # Add password / Добавить пароль
pass show email/gmail                         # Show password / Показать пароль
pass generate email/yahoo 32                  # Generate password / Генерировать пароль
```

### Git Commit Signing / Подписание коммитов Git
```bash
git config --global user.signingkey <KEY_ID>  # Set signing key / Установить ключ для подписи
git config --global commit.gpgsign true       # Auto-sign commits / Автоподпись коммитов
git commit -S -m "message"                    # Sign commit / Подписать коммит
git verify-commit HEAD                        # Verify commit / Проверить коммит
```

### Encrypted Secrets / Зашифрованные секреты
```bash
# Store API keys / Хранить API ключи
echo "API_KEY=secret123" | age -p > api.age
# Decrypt / Расшифровать
age -d api.age | source /dev/stdin

# Ansible vault alternative / Альтернатива Ansible vault
age -p < secrets.yml > secrets.yml.age
age -d secrets.yml.age > secrets.yml
```

### SSH Over GPG / SSH через GPG
```bash
# Enable GPG SSH support / Включить поддержку SSH GPG
echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# List SSH keys / Список SSH ключей
ssh-add -L
```

### Encrypted Email / Зашифрованная почта
```bash
# Encrypt email body / Зашифровать тело письма
echo "Secret message" | gpg --encrypt --armor -r <EMAIL> | mail -s "Encrypted" <EMAIL>

# Decrypt received email / Расшифровать полученное письмо
gpg --decrypt encrypted.asc
```

### File Shredding / Безопасное удаление
```bash
# Encrypt then shred / Зашифровать затем уничтожить
gpg -c sensitive.txt
shred -vfz -n 10 sensitive.txt                # Securely delete / Безопасно удалить
```

### Multi-Device Sync / Синхронизация между устройствами
```bash
# Export keys for sync / Экспортировать ключи для синхронизации
gpg --export-secret-keys --armor <KEY_ID> > secret.asc
gpg --export-ownertrust > trust.txt

# Import on new device / Импортировать на новом устройстве
gpg --import secret.asc
gpg --import-ownertrust trust.txt
```

### Container Secrets / Секреты контейнеров
```bash
# Encrypt secrets for Docker / Зашифровать секреты для Docker
echo "DB_PASSWORD=secret" | age -p > secrets.age
# In Dockerfile / В Dockerfile
# COPY secrets.age /app/
# Decrypt at runtime / Расшифровать во время выполнения
age -d /app/secrets.age | source /dev/stdin
```

# 💡 Best Practices / Лучшие практики
# Use age for new projects (simpler) / Используйте age для новых проектов (проще)
# Use GPG for compatibility / Используйте GPG для совместимости
# Always backup private keys / Всегда делайте резервные копии приватных ключей
# Set key expiration dates / Устанавливайте сроки действия ключей
# Use strong passphrases / Используйте сильные парольные фразы
# Store keys securely (encrypted USB, hardware token) / Храните ключи безопасно (зашифрованный USB, аппаратный токен)

# 🔧 Configuration Files / Файлы конфигурации
# ~/.gnupg/                 — GPG directory / Директория GPG
# ~/.gnupg/gpg.conf         — GPG config / Конфигурация GPG
# ~/.gnupg/gpg-agent.conf   — Agent config / Конфигурация агента
# ~/.age/                   — age directory / Директория age

# 📋 Key Management Tools / Инструменты управления ключами
# pass — Password manager (GPG) / Менеджер паролей (GPG)
# gopass — Enhanced pass / Улучшенный pass
# rage — Rust implementation of age / Rust реализация age
