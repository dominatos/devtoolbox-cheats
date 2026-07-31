---
Title: 🔐 GPG / age — Encryption
Group: "Security & Crypto"
Icon: 🔐
Order: 4
tags:
  - security
  - crypto
  - sysadmin
  - linux
---

# GPG / age Sysadmin Cheatsheet

> **Context:** GPG (GNU Privacy Guard) is a complete, free implementation of the OpenPGP standard for encrypting data and creating digital signatures. `age` is a modern, simpler alternative focused solely on file encryption with a minimal design. GPG is widely used for email encryption, package signing, and credential management. `age` is ideal for simple file encryption in scripts and modern workflows. / GPG — полная реализация стандарта OpenPGP для шифрования данных и цифровых подписей. `age` — современная альтернатива, ориентированная на простое шифрование файлов. GPG широко используется для шифрования почты, подписи пакетов. `age` идеален для шифрования файлов в скриптах.
> **Role:** Security Engineer / Sysadmin
> **Version:** GPG 2.x / age 1.x

---

## 📚 Table of Contents

- [1. Installation & Configuration](#1.%20Installation%20&%20Configuration)
- [2. GPG Key Management](#2.%20GPG%20Key%20Management)
- [3. GPG Encryption & Decryption](#3.%20GPG%20Encryption%20&%20Decryption)
- [4. GPG Signing & Verification](#4.%20GPG%20Signing%20&%20Verification)
- [5. age — Modern Encryption](#5.%20age%20—%20Modern%20Encryption)
- [6. Real-World Examples](#6.%20Real-World%20Examples)
- [7. Troubleshooting & Tools](#7.%20Troubleshooting%20&%20Tools)
- [8. Best Practices](#8.%20Best%20Practices)
- [9. Documentation Links](#9.%20Documentation%20Links)

---

## 1. Installation & Configuration

### Install GPG

```bash
# GPG is usually pre-installed / GPG
gpg --version                                 # Check version / Проверить версию

# Debian/Ubuntu (if missing)
sudo apt install gnupg

# RHEL/CentOS/Fedora
sudo dnf install gnupg2

# macOS
brew install gnupg
```

### Install age

```bash
sudo apt install age                          # Debian/Ubuntu
brew install age                              # macOS
go install filippo.io/age/cmd/...@latest      # From source / Из исходников
```

### Configuration Paths

| Path | Description (EN / RU) |
|------|----------------------|
| `~/.gnupg/` | GPG directory / Директория GPG |
| `~/.gnupg/gpg.conf` | GPG config / Конфигурация GPG |
| `~/.gnupg/gpg-agent.conf` | Agent config / Конфигурация агента |
| `~/.age/` | age directory / Директория age |

### GPG vs age Comparison

| Feature | GPG | age |
|---------|-----|-----|
| Complexity / Сложность | High / Высокая | Low / Низкая |
| Key management / Управление ключами | Keyservers, WoT / Серверы ключей | Simple files / Простые файлы |
| Compatibility / Совместимость | Wide / Широкая | Growing / Растущая |
| SSH key support / Поддержка SSH | Via agent / Через агент | Native / Нативная |
| Best for / Лучше для | Email, signing, legacy / Почта, подписи | Files, scripts, modern / Файлы, скрипты |

> [!TIP]
> Use `age` for new projects (simpler, no config). Use GPG for compatibility with existing systems (email, package signing).
> Используйте `age` для новых проектов (проще). GPG — для совместимости (почта, подпись пакетов).

---

## 2. GPG Key Management

### Generate Keys

```bash
gpg --gen-key                                 # Generate key (interactive) / Генерировать ключ (интерактивно)
gpg --full-generate-key                       # Full key generation / Полная генерация ключа
gpg --quick-generate-key "<USER> <<EMAIL>>"   # Quick key generation / Быстрая генерация ключа
gpg --quick-generate-key "<USER> <<EMAIL>>" rsa4096  # RSA 4096-bit key / Ключ RSA 4096 бит
```

### List Keys

```bash
gpg --list-keys                               # List public keys / Список публичных ключей
gpg --list-secret-keys                        # List private keys / Список приватных ключей
gpg --list-sigs                               # List signatures / Список подписей
gpg -K                                        # Short for list-secret-keys / Короткая форма
```

### Export Keys

```bash
gpg --export <KEY_ID> > public.gpg            # Export public key / Экспортировать публичный ключ
gpg --export --armor <KEY_ID> > public.asc    # Export ASCII armored / Экспортировать в ASCII
gpg --export-secret-keys --armor <KEY_ID> > private.asc  # Export private key / Экспортировать приватный ключ
gpg --export-secret-subkeys <KEY_ID> > subkeys.gpg  # Export subkeys / Экспортировать подключи
```

> [!CAUTION]
> Never share your private key (`--export-secret-keys`). Store it securely on encrypted media or hardware tokens.
> Никогда не передавайте приватный ключ. Храните его на зашифрованных носителях или аппаратных токенах.

### Import Keys

```bash
gpg --import public.asc                       # Import public key / Импортировать публичный ключ
gpg --import private.asc                      # Import private key / Импортировать приватный ключ
```

### Delete Keys

```bash
gpg --delete-keys <KEY_ID>                    # Delete public key / Удалить публичный ключ
gpg --delete-secret-keys <KEY_ID>             # Delete private key / Удалить приватный ключ
gpg --delete-secret-and-public-keys <KEY_ID>  # Delete both / Удалить оба
```

### Edit Keys

```bash
gpg --edit-key <KEY_ID>                       # Edit key (interactive) / Редактировать ключ (интерактивно)
# > adduid                                    # Add UID
# > expire                                    # Change expiration
# > trust                                     # Set trust level
# > save                                      # Save and exit
```

### Keyserver Operations

```bash
gpg --send-keys <KEY_ID>                      # Send to keyserver / Отправить на сервер ключей
gpg --recv-keys <KEY_ID>                      # Receive from keyserver / Получить с сервера ключей
gpg --search-keys <EMAIL>                     # Search keyserver / Поиск на сервере ключей
gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>  # Specific server / Конкретный сервер
```

---

## 3. GPG Encryption & Decryption

### Symmetric Encryption

```bash
gpg --symmetric file                          # Encrypt with password / Зашифровать паролем
gpg --symmetric --cipher-algo AES256 file     # AES256 encryption / Шифрование AES256
gpg -c file                                   # Short form / Короткая форма
```

### Asymmetric Encryption

```bash
gpg --encrypt --recipient <EMAIL> file        # Encrypt for recipient / Зашифровать для получателя
gpg -e -r <EMAIL> file                        # Short form / Короткая форма
gpg --encrypt --armor -r <EMAIL> file         # ASCII armored / В формате ASCII
gpg --encrypt --recipient <EMAIL1> --recipient <EMAIL2> file  # Multiple recipients / Несколько получателей
```

### Decryption

```bash
gpg --decrypt file.gpg                        # Decrypt file / Расшифровать файл
gpg -d file.gpg                               # Short form / Короткая форма
gpg -d file.gpg > decrypted.txt               # Decrypt to file / Расшифровать в файл
gpg --decrypt --output decrypted.txt file.gpg # Decrypt with output / Расшифровать с выводом
```

### Encrypt and Sign

```bash
gpg --encrypt --sign --recipient <EMAIL> file # Encrypt and sign / Зашифровать и подписать
gpg -es -r <EMAIL> file                       # Short form / Короткая форма
```

---

## 4. GPG Signing & Verification

### Sign Files

```bash
gpg --sign file                               # Sign file / Подписать файл
gpg -s file                                   # Short form / Короткая форма
gpg --clearsign file                          # Clear text signature / Подпись открытым текстом
gpg --detach-sign file                        # Detached signature / Отдельная подпись
gpg --armor --detach-sign file                # ASCII detached signature / ASCII отдельная подпись
```

### Verify Signatures

```bash
gpg --verify file.sig file                    # Verify detached signature / Проверить отдельную подпись
gpg --verify file.sig                         # Verify signature / Проверить подпись
gpg --verify file.asc                         # Verify clear-signed / Проверить подпись открытым текстом
```

### Sign and Encrypt

```bash
gpg --sign --encrypt --recipient <EMAIL> file # Sign then encrypt / Подписать затем зашифровать
gpg -se -r <EMAIL> file                       # Short form / Короткая форма
```

---

## 5. age — Modern Encryption

### Generate Keys

```bash
age-keygen > key.txt                          # Generate key / Генерировать ключ
age-keygen -o key.txt                         # Save to file / Сохранить в файл
```

### Encryption

```bash
age -p -o file.age file                       # Encrypt with password / Зашифровать паролем
age -p < file > file.age                      # Pipe encryption / Шифрование через pipe
age -r age1qqw... -o file.age file            # Encrypt with public key / Зашифровать публичным ключом
age -R recipients.txt -o file.age file        # Multiple recipients / Несколько получателей
```

### Decryption

```bash
age -d -o file file.age                       # Decrypt with password / Расшифровать паролем
age -d < file.age > file                      # Pipe decryption / Расшифровка через pipe
age -d -i key.txt -o file file.age            # Decrypt with key / Расшифровать ключом
age -d -i key.txt < file.age > file           # Pipe with key / Pipe с ключом
```

### SSH Keys with age / SSH

```bash
ssh-keygen -t ed25519 -C "age key"            # Generate SSH key / Генерировать SSH ключ
age -R ~/.ssh/id_ed25519.pub file > file.age  # Encrypt with SSH key / Зашифровать SSH ключом
age -d -i ~/.ssh/id_ed25519 file.age > file   # Decrypt with SSH key / Расшифровать SSH ключом
```

### Multiple Recipients

```bash
age -r age1qqw... -r age1xyz... -o file.age file  # Encrypt for multiple / Зашифровать для нескольких
age -R recipients.txt -o file.age file        # Encrypt from file / Зашифровать из файла
```

---

## 6. Real-World Examples

### Encrypt Directory

```bash
# GPG tar archive / GPG
tar -czf - directory/ | gpg -c -o directory.tar.gz.gpg

# age tar archive / age
tar -czf - directory/ | age -p > directory.tar.gz.age

# Decrypt and extract
gpg -d directory.tar.gz.gpg | tar -xzf -
age -d directory.tar.gz.age | tar -xzf -
```

### Backup Encryption

```bash
# GPG backup / GPG
tar -czf - /home/<USER> | gpg -c -o backup-$(date +%F).tar.gz.gpg

# age backup / age
tar -czf - /home/<USER> | age -p > backup-$(date +%F).tar.gz.age

# Automated backup with age
age-keygen > ~/.backup-key.txt
tar -czf - /home/<USER> | age -r $(grep public ~/.backup-key.txt | cut -d: -f2) > backup.tar.gz.age
```

### Password Manager

```bash
# pass uses GPG / pass
pass init <GPG_KEY_ID>                        # Initialize password store / Инициализировать хранилище паролей
pass insert email/gmail                       # Add password / Добавить пароль
pass show email/gmail                         # Show password / Показать пароль
pass generate email/yahoo 32                  # Generate password / Генерировать пароль
```

### Git Commit Signing

```bash
git config --global user.signingkey <KEY_ID>  # Set signing key / Установить ключ для подписи
git config --global commit.gpgsign true       # Auto-sign commits / Автоподпись коммитов
git commit -S -m "message"                    # Sign commit / Подписать коммит
git verify-commit HEAD                        # Verify commit / Проверить коммит
```

### Encrypted Secrets

```bash
# Store API keys
echo "API_KEY=<SECRET_KEY>" | age -p > api.age
# Decrypt
age -d api.age | source /dev/stdin

# Ansible vault alternative
age -p < secrets.yml > secrets.yml.age
age -d secrets.yml.age > secrets.yml
```

### SSH Over GPG / SSH

```bash
# Enable GPG SSH support
echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# List SSH keys
ssh-add -L
```

### Encrypted Email

```bash
# Encrypt email body
echo "Secret message" | gpg --encrypt --armor -r <EMAIL> | mail -s "Encrypted" <EMAIL>

# Decrypt received email
gpg --decrypt encrypted.asc
```

### File Shredding

```bash
# Encrypt then shred
gpg -c sensitive.txt
shred -vfz -n 10 sensitive.txt                # Securely delete / Безопасно удалить
```

### Multi-Device Sync

```bash
# Export keys for sync
gpg --export-secret-keys --armor <KEY_ID> > secret.asc
gpg --export-ownertrust > trust.txt

# Import on new device
gpg --import secret.asc
gpg --import-ownertrust trust.txt
```

### Container Secrets

```bash
# Encrypt secrets for Docker
echo "DB_PASSWORD=<PASSWORD>" | age -p > secrets.age
# In Dockerfile: COPY secrets.age /app/
# Decrypt at runtime
age -d /app/secrets.age | source /dev/stdin
```

---

## 7. Troubleshooting & Tools

### GPG Agent Issues

```bash
gpg-agent --daemon                            # Start agent / Запустить агента
gpgconf --kill gpg-agent                      # Restart agent / Перезапустить агента
gpg-agent --daemon --pinentry-program /usr/bin/pinentry-curses  # Specify pinentry / Указать pinentry
```

### Trust Issues

```bash
gpg --edit-key <KEY_ID>                       # Edit key / Редактировать ключ
# > trust                                     # Set trust
# > 5                                         # Ultimate trust
# > save                                      # Save
```

### Expired Keys

```bash
gpg --edit-key <KEY_ID>                       # Edit key / Редактировать ключ
# > expire                                    # Change expiration
# > key 1                                     # Select subkey
# > expire                                    # Change subkey expiration
# > save                                      # Save
```

### List Recipients

```bash
gpg --list-packets file.gpg                   # Show encryption info / Показать информацию о шифровании
gpg --batch --list-packets file.gpg | grep keyid  # Extract key IDs / Извлечь ID ключей
```

### Key Management Tools

| Tool | Description (EN / RU) |
|------|----------------------|
| `pass` | Password manager (GPG-based) / Менеджер паролей (на GPG) |
| `gopass` | Enhanced pass / Улучшенный pass |
| `rage` | Rust implementation of age / Rust-реализация age |

---

## 8. Best Practices

- Use `age` for new projects (simpler) / Используйте `age` для новых проектов (проще)
- Use GPG for compatibility with existing systems / Используйте GPG для совместимости
- Always backup private keys / Всегда делайте резервные копии приватных ключей
- Set key expiration dates / Устанавливайте сроки действия ключей
- Use strong passphrases / Используйте сильные парольные фразы
- Store keys securely (encrypted USB, hardware token) / Храните ключи безопасно

---

## 9. Documentation Links

### GPG

- [GnuPG Official Documentation](https://gnupg.org/documentation/)
- [GnuPG Manual](https://gnupg.org/documentation/manuals/gnupg/)
- [OpenPGP Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)
- [GnuPG FAQ](https://gnupg.org/faq/gnupg-faq.html)

### age

- [age GitHub Repository](https://github.com/FiloSottile/age)
- [age Specification](https://age-encryption.org/v1)
- [rage (Rust implementation)](https://github.com/str4d/rage)

---
