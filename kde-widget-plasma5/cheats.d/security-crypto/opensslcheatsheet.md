Title: 🔐 OpenSSL — Commands
Group: Security & Crypto
Icon: 🔐
Order: 2

## Table of Contents
- [Random &Hash Generation](#-random--hash-generation--генерация-случайных-данных-и-хешей)
- [Certificate Operations](#-certificate-operations--операции-с-сертификатами)
- [Key Generation](#-key-generation--генерация-ключей)
- [Certificate Signing Requests](#-certificate-signing-requests-csr--запросы-на-подпись-сертификата)
- [SSL/TLS Testing](#-ssltls-testing--тестирование-ssltls)
- [Encryption & Decryption](#-encryption--decryption--шифрование-и-расшифровка)
- [File Operations](#-file-operations--операции-с-файлами)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🎲 Random & Hash Generation / Генерация случайных данных и хешей
openssl rand -hex 16                           # Random hex string (32 chars) / Случайная hex-строка
openssl rand -base64 32                        # Random base64 (44 chars) / Случайная base64-строка
openssl rand -out random.bin 256               # Binary random file / Бинарный файл случайных данных
openssl dgst -sha256 file                      # SHA-256 hash / Хеш SHA-256
openssl dgst -sha512 file                      # SHA-512 hash / Хеш SHA-512
openssl dgst -md5 file                         # MD5 hash / Хеш MD5
echo -n "password" | openssl dgst -sha256      # Hash string / Хешировать строку

# 📜 Certificate Operations / Операции с сертификатами
openssl x509 -in cert.pem -text -noout         # View certificate / Просмотр сертификата
openssl x509 -in cert.pem -noout -dates        # Show validity dates / Показать даты действия
openssl x509 -in cert.pem -noout -subject      # Show subject / Показать субъект
openssl x509 -in cert.pem -noout -issuer       # Show issuer / Показать издателя
openssl x509 -in cert.pem -noout -fingerprint  # Certificate fingerprint / Отпечаток сертификата
openssl x509 -in cert.der -inform DER -out cert.pem -outform PEM  # Convert DER to PEM / Конвертировать DER в PEM
openssl x509 -in cert.pem -outform DER -out cert.der  # Convert PEM to DER / Конвертировать PEM в DER
openssl verify -CAfile ca.pem cert.pem         # Verify certificate / Проверить сертификат

# 🔑 Key Generation / Генерация ключей
openssl genrsa -out private.key 2048           # Generate RSA key 2048-bit / Генерация RSA ключа 2048 бит
openssl genrsa -out private.key 4096           # Generate RSA key 4096-bit / Генерация RSA ключа 4096 бит
openssl rsa -in private.key -pubout -out public.key  # Extract public key / Извлечь публичный ключ
openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048  # Modern RSA key / Современная генерация RSA
openssl ecparam -genkey -name secp384r1 -out ec.key  # Generate EC key / Генерация EC ключа
openssl rsa -in private.key -text -noout       # View RSA key / Просмотр RSA ключа
openssl rsa -in encrypted.key -out decrypted.key  # Remove passphrase / Удалить парольную фразу
openssl rsa -aes256 -in unencrypted.key -out encrypted.key  # Add passphrase / Добавить парольную фразу

# 📝 Certificate Signing Requests (CSR) / Запросы на подпись сертификата
openssl req -new -key private.key -out request.csr  # Generate CSR / Создать CSR
openssl req -new -newkey rsa:2048 -nodes -keyout private.key -out request.csr  # Generate CSR + key / Создать CSR и ключ
openssl req -in request.csr -text -noout       # View CSR / Просмотр CSR
openssl req -in request.csr -noout -subject    # Show CSR subject / Показать субъект CSR
openssl req -x509 -new -nodes -key private.key -sha256 -days 365 -out cert.pem  # Self-signed cert / Самоподписанный сертификат
openssl req -new -key private.key -out request.csr -subj "/C=US/ST=State/L=City/O=Org/CN=<HOST>"  # CSR non-interactive / CSR без интерактива

# 🔍 SSL/TLS Testing / Тестирование SSL/TLS
openssl s_client -connect <HOST>:443           # Test SSL connection / Тестировать SSL подключение
openssl s_client -connect <HOST>:443 -servername <HOST>  # With SNI / С SNI
openssl s_client -connect <HOST>:443 </dev/null 2>/dev/null | openssl x509 -noout -dates  # Check cert validity / Проверить срок действия
openssl s_client -connect <HOST>:443 -showcerts  # Show full cert chain / Показать полную цепочку сертификатов
openssl s_client -connect <HOST>:443 -tls1_2   # Force TLS 1.2 / Принудительно TLS 1.2
openssl s_client -connect <HOST>:443 -tls1_3   # Force TLS 1.3 / Принудительно TLS 1.3
echo | openssl s_client -connect <HOST>:443 2>/dev/null | openssl x509 -noout -issuer -subject  # Quick cert check / Быстрая проверка сертификата

# 🔒 Encryption & Decryption / Шифрование и расшифровка
openssl enc -aes-256-cbc -in file.txt -out file.enc  # Encrypt file / Зашифровать файл
openssl enc -aes-256-cbc -d -in file.enc -out file.txt  # Decrypt file / Расшифровать файл
openssl enc -aes-256-cbc -salt -in file.txt -out file.enc -pass pass:<PASSWORD>  # Encrypt with password / Зашифровать с паролем
openssl enc -aes-256-cbc -d -in file.enc -out file.txt -pass file:password.txt  # Decrypt with password file / Расшифровать с файлом пароля
echo "secret" | openssl enc -aes-256-cbc -a -salt -pass pass:<PASSWORD>  # Encrypt string / Зашифровать строку
openssl rsautl -encrypt -inkey public.key -pubin -in file.txt -out file.enc  # RSA encrypt / RSA шифрование
openssl rsautl -decrypt -inkey private.key -in file.enc -out file.txt  # RSA decrypt / RSA расшифровка

# 📁 File Operations / Операции с файлами
openssl pkcs12 -export -out cert.p12 -inkey private.key -in cert.pem  # Create PKCS12 / Создать PKCS12
openssl pkcs12 -in cert.p12 -out cert.pem -nodes  # Extract from PKCS12 / Извлечь из PKCS12
openssl pkcs12 -in cert.p12 -nokeys -out cert.pem  # Extract cert only / Только сертификат
openssl pkcs12 -in cert.p12 -nocerts -nodes -out private.key  # Extract key only / Только ключ
cat cert.pem intermediate.pem root.pem > fullchain.pem  # Create cert chain / Создать цепочку сертификатов
openssl crl -in crl.pem -text -noout           # View CRL / Просмотр CRL

# 🌟 Real-World Examples / Примеры из практики
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=<HOST>"  # Quick self-signed cert / Быстрый самоподписанный сертификат
openssl s_client -connect <HOST>:443 -servername <HOST> </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject  # Inspect remote cert / Проверить удалённый сертификат
openssl x509 -in /etc/ssl/certs/cert.pem -noout -enddate  # Check expiration / Проверить срок действия
openssl s_client -connect smtp.<HOST>:587 -starttls smtp  # Test SMTP TLS / Тестировать SMTP TLS
openssl s_client -connect imap.<HOST>:993      # Test IMAPS / Тестировать IMAPS
openssl dhparam -out dhparam.pem 2048          # Generate DH params / Генерация DH параметров
openssl speed rsa2048                          # Benchmark RSA / Бенчмарк RSA
for cert in /etc/ssl/certs/*.pem; do openssl x509 -in "$cert" -noout -enddate -subject 2>/dev/null; done  # Check all system certs / Проверить все системные сертификаты
openssl passwd -6 <PASSWORD>                   # Generate SHA-512 password hash / Генерация SHA-512 хеша пароля
openssl rand -hex 32 > /etc/security/secret.key  # Generate secret key file / Генерация файла секретного ключа

# 💡 Troubleshooting / Устранение неполадок
openssl version -a                             # OpenSSL version info / Информация о версии
openssl ciphers -v 'HIGH'                      # List ciphers / Список шифров
openssl errstr 02001002                        # Error code lookup / Расшифровка кода ошибки
openssl s_client -connect <HOST>:443 -debug    # Debug SSL connection / Отладка SSL подключения
