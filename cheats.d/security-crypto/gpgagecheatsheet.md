Title: 🔐 gpg / age
Group: Security & Crypto
Icon: 🔐
Order: 4

gpg --symmetric --cipher-algo AES256 file       # Encrypt with password (GPG) / Шифровать паролем (GPG)
gpg -d file.gpg > file                          # Decrypt / Расшифровать
age -p -o file.age file                         # Encrypt with pass (age) / Шифровать паролем (age)
age -d -o file file.age                         # Decrypt (age) / Расшифровать (age)

