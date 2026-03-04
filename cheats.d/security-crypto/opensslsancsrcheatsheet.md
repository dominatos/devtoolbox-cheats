Title: 🔐 OpenSSL — CSR with Subject Alternative Names (SAN)
Group: Security & Crypto
Icon: 🔐
Order: 3

## Table of Contents
- [Basics & Overview](#-basics--overview--основы-и-обзор)
- [Configuration File](#-configuration-file--файл-конфигурации)
- [Generating CSR](#-generating-csr--создание-csr)
- [Verification](#-verification--проверка)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)
- [Best Practices](#-best-practices--лучшие-практики)

---

# 📘 Basics & Overview / Основы и обзор

### What is SAN? / Что такое SAN?
**Subject Alternative Name (SAN)** allows a single certificate to secure multiple domain names.  
**Альтернативное имя субъекта (SAN)** позволяет одному сертификату защищать несколько доменных имён.

**Common Use Cases / Типичные случаи использования:**
- Multiple subdomains (`www.example.com`, `api.example.com`) / Несколько поддоменов
- Wildcard + specific domains / Wildcard + конкретные домены
- IPs + domains (less common) / IP + домены (реже)

---

# 📄 Configuration File / Файл конфигурации

### Basic SAN Configuration / Базовая конфигурация SAN
`openssl-san.cnf`

```ini
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = <COUNTRY_CODE>                  # Country / Страна
ST = <STATE>                         # State/Province / Штат/Область
L  = <CITY>                          # City / Город
O  = <ORGANIZATION>                  # Organization / Организация
CN = <COMMON_NAME>                   # Common Name / Основное имя

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = <DOMAIN>
DNS.2 = www.<DOMAIN>
DNS.3 = api.<DOMAIN>
DNS.4 = mail.<DOMAIN>
```

### Example Configuration / Пример конфигурации
`openssl-san.cnf`

```ini
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = US
ST = California
L  = San Francisco
O  = Example Inc
CN = example.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = api.example.com
DNS.4 = *.example.com              # Wildcard / Wildcard
```

### With IP Addresses / С IP-адресами
```ini
[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
IP.1  = <IP_ADDRESS>
IP.2  = <ANOTHER_IP>
```

---

# 🔑 Generating CSR / Создание CSR

### Generate New Key + CSR / Создать новый ключ + CSR
```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout <KEYFILE>.pem \
  -out <CSR_FILE>.pem \
  -config openssl-san.cnf
```

### Generate CSR from Existing Key / Создать CSR из существующего ключа
```bash
openssl req -new -key <EXISTING_KEY>.pem \
  -out <CSR_FILE>.pem \
  -config openssl-san.cnf
```

### Generate 4096-bit Key / Создать ключ 4096-бит
```bash
openssl req -new -newkey rsa:4096 -nodes \
  -keyout <KEYFILE>.pem \
  -out <CSR_FILE>.pem \
  -config openssl-san.cnf
```

### Generate ECC Key (Modern) / Создать ECC ключ (современный)
```bash
openssl req -new -newkey ec:<(openssl ecparam -name prime256v1) -nodes \
  -keyout <KEYFILE>.pem \
  -out <CSR_FILE>.pem \
  -config openssl-san.cnf
```

> [!TIP]
> ECC keys (prime256v1/secp384r1) are faster and smaller than RSA while providing equivalent security.
> ECC ключи быстрее и компактнее RSA при эквивалентном уровне безопасности.

---

# ✅ Verification / Проверка

### View CSR Details / Просмотр деталей CSR
```bash
openssl req -text -noout -in <CSR_FILE>.pem  # View CSR / Просмотр CSR
openssl req -text -noout -in <CSR_FILE>.pem | grep -A1 "Subject Alternative Name"  # View SANs only / Только SANs
```

### Verify CSR Signature / Проверить подпись CSR
```bash
openssl req -verify -in <CSR_FILE>.pem -noout  # Verify CSR / Проверить CSR
```

### Extract Public Key from CSR / Извлечь публичный ключ из CSR
```bash
openssl req -in <CSR_FILE>.pem -pubkey -noout  # Extract public key / Извлечь публичный ключ
```

### View Private Key / Просмотр приватного ключа
```bash
openssl rsa -in <KEYFILE>.pem -text -noout  # View RSA key / Просмотр RSA ключа
openssl ec -in <KEYFILE>.pem -text -noout   # View EC key / Просмотр EC ключа
```

---

# 🌟 Real-World Examples / Примеры из практики

### Web Server with Multiple Subdomains / Веб-сервер с несколькими поддоменами
```bash
# Create configuration / Создать конфигурацию
cat > openssl-san.cnf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = US
ST = California
L  = San Francisco
O  = Example Corp
CN = example.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
DNS.3 = api.example.com
DNS.4 = app.example.com
DNS.5 = admin.example.com
EOF

# Generate key and CSR / Создать ключ и CSR
openssl req -new -newkey rsa:2048 -nodes \
  -keyout example.com.key \
  -out example.com.csr \
  -config openssl-san.cnf

# Verify SANs / Проверить SANs
openssl req -text -noout -in example.com.csr | grep -A1 "Subject Alternative Name"
```

### Microservices with Internal IPs / Микросервисы с внутренними IP
```bash
# Create config with IPs / Создать конфиг с IP
cat > openssl-san-internal.cnf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = US
ST = California
L  = San Francisco
O  = Internal Services
CN = internal.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = service.internal.local
DNS.2 = api.internal.local
IP.1  = <INTERNAL_IP_1>
IP.2  = <INTERNAL_IP_2>
EOF

# Generate / Создать
openssl req -new -newkey rsa:2048 -nodes \
  -keyout internal.key \
  -out internal.csr \
  -config openssl-san-internal.cnf
```

### Self-Signed Certificate with SAN / Самоподписанный сертификат с SAN
```bash
# Generate self-signed cert with SANs / Создать самоподписанный сертификат с SANs
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout selfsigned.key \
  -out selfsigned.crt \
  -days 365 \
  -config openssl-san.cnf \
  -extensions req_ext

# Verify certificate SANs / Проверить SANs сертификата
openssl x509 -in selfsigned.crt -text -noout | grep -A1 "Subject Alternative Name"
```

### Wildcard + Specific Domains / Wildcard + конкретные домены
```bash
# Config with wildcard / Конфиг с wildcard
cat > openssl-san-wildcard.cnf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C  = US
ST = California
L  = San Francisco
O  = Example Corp
CN = *.example.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.example.com              # Wildcard for all subdomains / Wildcard для всех поддоменов
DNS.2 = example.com                # Apex domain / Основной домен
DNS.3 = *.api.example.com          # Nested wildcard / Вложенный wildcard
EOF

# Generate / Создать
openssl req -new -newkey rsa:2048 -nodes \
  -keyout wildcard.key \
  -out wildcard.csr \
  -config openssl-san-wildcard.cnf
```

---

# 💡 Best Practices / Лучшие практики

- Always include the CN in SANs / Всегда включайте CN в SANs
- Use SHA-256 or higher for hashing / Используйте SHA-256 или выше для хеширования
- Consider ECC keys for better performance / Рассмотрите ECC ключи для лучшей производительности
- Keep private keys secure (`chmod 600`) / Храните приватные ключи безопасно
- Use 2048-bit minimum for RSA / Используйте минимум 2048-бит для RSA
- Test SANs before submitting to CA / Тестируйте SANs перед отправкой в CA
- Keep backup of `.key` and `.csr` files / Храните резервные копии `.key` и `.csr` файлов

## File Types / Типы файлов

| File | Description (EN / RU) |
|------|----------------------|
| `openssl-san.cnf` | SAN configuration / Конфигурация SAN |
| `<DOMAIN>.key` | Private key / Приватный ключ |
| `<DOMAIN>.csr` | Certificate signing request / Запрос на подпись сертификата |
| `<DOMAIN>.crt` | Signed certificate / Подписанный сертификат |

## Common DN Fields / Распространённые поля DN

| Field | Description (EN / RU) |
|-------|----------------------|
| `C` | Country (2-letter code) / Страна (2-буквенный код) |
| `ST` | State or Province / Штат или область |
| `L` | Locality (city) / Город |
| `O` | Organization / Организация |
| `OU` | Organizational Unit / Подразделение |
| `CN` | Common Name (primary domain) / Основное имя (основной домен) |
