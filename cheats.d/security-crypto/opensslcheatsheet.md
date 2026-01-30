Title: 🔐 OpenSSL — Commands
Group: Security & Crypto
Icon: 🔐
Order: 2

openssl rand -hex 16                            # Generate random hex string / Случайная hex-строка
openssl dgst -sha256 file                       # SHA-256 hash of file / Хеш SHA-256 файла
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject  # Inspect remote cert / Проверить удалённый сертификат
openssl x509 -in cert.pem -text -noout          # Pretty-print cert / Красивый вывод сертификата

