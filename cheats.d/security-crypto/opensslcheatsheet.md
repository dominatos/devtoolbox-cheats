Title: 🔐 OpenSSL — Commands
Group: Security & Crypto
Icon: 🔐
Order: 2

# OpenSSL Sysadmin Cheatsheet

> **Context:** OpenSSL is the industry-standard open-source toolkit for SSL/TLS protocols and general-purpose cryptography. Used for generating keys, creating certificates, testing SSL connections, encrypting files, and hashing. It is pre-installed on virtually all Linux distributions and macOS. / OpenSSL — стандартный open-source инструмент для SSL/TLS и криптографии общего назначения. Используется для генерации ключей, создания сертификатов, тестирования SSL, шифрования файлов и хеширования. Предустановлен на всех Linux-дистрибутивах.
> **Role:** Sysadmin / Security Engineer
> **Default Ports:** `443` (HTTPS), `587` (SMTP/STARTTLS), `993` (IMAPS)

---

## 📚 Table of Contents / Содержание

1. [Random & Hash Generation](#1-random--hash-generation)
2. [Certificate Operations](#2-certificate-operations)
3. [Key Generation](#3-key-generation)
4. [Certificate Signing Requests](#4-certificate-signing-requests)
5. [SSL/TLS Testing](#5-ssltls-testing)
6. [Encryption & Decryption](#6-encryption--decryption)
7. [File Operations](#7-file-operations)
8. [Real-World Examples](#8-real-world-examples)
9. [Troubleshooting & Tools](#9-troubleshooting--tools)
10. [Documentation Links](#10-documentation-links)

---

## 1. Random & Hash Generation

```bash
openssl rand -hex 16                           # Random hex string (32 chars) / Случайная hex-строка
openssl rand -base64 32                        # Random base64 (44 chars) / Случайная base64-строка
openssl rand -out random.bin 256               # Binary random file / Бинарный файл случайных данных
openssl dgst -sha256 file                      # SHA-256 hash / Хеш SHA-256
openssl dgst -sha512 file                      # SHA-512 hash / Хеш SHA-512
openssl dgst -md5 file                         # MD5 hash / Хеш MD5
echo -n "password" | openssl dgst -sha256      # Hash string / Хешировать строку
```

---

## 2. Certificate Operations

```bash
openssl x509 -in cert.pem -text -noout         # View certificate / Просмотр сертификата
openssl x509 -in cert.pem -noout -dates        # Show validity dates / Показать даты действия
openssl x509 -in cert.pem -noout -subject      # Show subject / Показать субъект
openssl x509 -in cert.pem -noout -issuer       # Show issuer / Показать издателя
openssl x509 -in cert.pem -noout -fingerprint  # Certificate fingerprint / Отпечаток сертификата
openssl x509 -in cert.der -inform DER -out cert.pem -outform PEM  # DER→PEM / Конвертировать DER в PEM
openssl x509 -in cert.pem -outform DER -out cert.der  # PEM→DER / Конвертировать PEM в DER
openssl verify -CAfile ca.pem cert.pem         # Verify certificate / Проверить сертификат
```

---

## 3. Key Generation

```bash
openssl genrsa -out private.key 2048           # RSA key 2048-bit / RSA ключ 2048 бит
openssl genrsa -out private.key 4096           # RSA key 4096-bit / RSA ключ 4096 бит
openssl rsa -in private.key -pubout -out public.key  # Extract public key / Извлечь публичный ключ
openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048  # Modern RSA / Современная генерация RSA
openssl ecparam -genkey -name secp384r1 -out ec.key  # EC key / EC ключ
openssl rsa -in private.key -text -noout       # View RSA key / Просмотр RSA ключа
openssl rsa -in encrypted.key -out decrypted.key  # Remove passphrase / Удалить парольную фразу
openssl rsa -aes256 -in unencrypted.key -out encrypted.key  # Add passphrase / Добавить парольную фразу
```

---

## 4. Certificate Signing Requests

```bash
openssl req -new -key private.key -out request.csr  # Generate CSR / Создать CSR
openssl req -new -newkey rsa:2048 -nodes -keyout private.key -out request.csr  # CSR + key / CSR и ключ
openssl req -in request.csr -text -noout       # View CSR / Просмотр CSR
openssl req -in request.csr -noout -subject    # Show CSR subject / Субъект CSR
openssl req -x509 -new -nodes -key private.key -sha256 -days 365 -out cert.pem  # Self-signed cert / Самоподписанный
openssl req -new -key private.key -out request.csr -subj "/C=US/ST=State/L=City/O=Org/CN=<HOST>"  # Non-interactive CSR / CSR без интерактива
```

---

## 5. SSL/TLS Testing

```bash
openssl s_client -connect <HOST>:443           # Test SSL connection / Тестировать SSL
openssl s_client -connect <HOST>:443 -servername <HOST>  # With SNI / С SNI
openssl s_client -connect <HOST>:443 </dev/null 2>/dev/null | openssl x509 -noout -dates  # Check validity / Проверить срок
openssl s_client -connect <HOST>:443 -showcerts  # Show full cert chain / Показать цепочку
openssl s_client -connect <HOST>:443 -tls1_2   # Force TLS 1.2 / Принудительно TLS 1.2
openssl s_client -connect <HOST>:443 -tls1_3   # Force TLS 1.3 / Принудительно TLS 1.3
echo | openssl s_client -connect <HOST>:443 2>/dev/null | openssl x509 -noout -issuer -subject  # Quick cert check / Быстрая проверка
```

---

## 6. Encryption & Decryption

```bash
openssl enc -aes-256-cbc -in file.txt -out file.enc  # Encrypt file / Зашифровать файл
openssl enc -aes-256-cbc -d -in file.enc -out file.txt  # Decrypt file / Расшифровать файл
openssl enc -aes-256-cbc -salt -in file.txt -out file.enc -pass pass:<PASSWORD>  # Encrypt with password / С паролем
openssl enc -aes-256-cbc -d -in file.enc -out file.txt -pass file:password.txt  # Decrypt with file / С файлом пароля
echo "secret" | openssl enc -aes-256-cbc -a -salt -pass pass:<PASSWORD>  # Encrypt string / Зашифровать строку
openssl rsautl -encrypt -inkey public.key -pubin -in file.txt -out file.enc  # RSA encrypt / RSA шифрование
openssl rsautl -decrypt -inkey private.key -in file.enc -out file.txt  # RSA decrypt / RSA расшифровка
```

---

## 7. File Operations

```bash
openssl pkcs12 -export -out cert.p12 -inkey private.key -in cert.pem  # Create PKCS12 / Создать PKCS12
openssl pkcs12 -in cert.p12 -out cert.pem -nodes  # Extract from PKCS12 / Извлечь из PKCS12
openssl pkcs12 -in cert.p12 -nokeys -out cert.pem  # Extract cert only / Только сертификат
openssl pkcs12 -in cert.p12 -nocerts -nodes -out private.key  # Extract key only / Только ключ
cat cert.pem intermediate.pem root.pem > fullchain.pem  # Create cert chain / Создать цепочку
openssl crl -in crl.pem -text -noout           # View CRL / Просмотр CRL
```

---

## 8. Real-World Examples

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=<HOST>"  # Quick self-signed / Быстрый самоподписанный
openssl s_client -connect <HOST>:443 -servername <HOST> </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject  # Inspect remote cert / Проверить удалённый сертификат
openssl x509 -in /etc/ssl/certs/cert.pem -noout -enddate  # Check expiration / Проверить срок
openssl s_client -connect smtp.<HOST>:587 -starttls smtp  # Test SMTP TLS / Тестировать SMTP TLS
openssl s_client -connect imap.<HOST>:993      # Test IMAPS / Тестировать IMAPS
openssl dhparam -out dhparam.pem 2048          # Generate DH params / Генерация DH параметров
openssl speed rsa2048                          # Benchmark RSA / Бенчмарк RSA
for cert in /etc/ssl/certs/*.pem; do openssl x509 -in "$cert" -noout -enddate -subject 2>/dev/null; done  # Check all certs / Проверить все сертификаты
openssl passwd -6 <PASSWORD>                   # SHA-512 password hash / SHA-512 хеш пароля
openssl rand -hex 32 > /etc/security/secret.key  # Generate secret key / Генерация секретного ключа
```

---

## 9. Troubleshooting & Tools

```bash
openssl version -a                             # OpenSSL version info / Информация о версии
openssl ciphers -v 'HIGH'                      # List ciphers / Список шифров
openssl errstr 02001002                        # Error code lookup / Расшифровка кода ошибки
openssl s_client -connect <HOST>:443 -debug    # Debug SSL connection / Отладка SSL
```

---

## 10. Documentation Links

- [OpenSSL Official Documentation](https://www.openssl.org/docs/)
- [OpenSSL Manual Pages](https://www.openssl.org/docs/man3.0/)
- [OpenSSL Cookbook (free)](https://www.feistyduck.com/library/openssl-cookbook/)
- [OpenSSL GitHub Repository](https://github.com/openssl/openssl)
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

---
