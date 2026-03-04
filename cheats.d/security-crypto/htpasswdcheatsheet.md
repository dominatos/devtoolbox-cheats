Title: 🔐 htpasswd — Basic Auth
Group: Security & Crypto
Icon: 🔐
Order: 10

## Table of Contents
- [Installation](#-installation--установка)
- [Basic Usage](#-basic-usage--основное-использование)
- [Batch Mode](#-batch-mode--пакетный-режим)
- [Verification & Deletion](#-verification--deletion--проверка-и-удаление)
- [Security Best Practices](#-security-best-practices--лучшие-практики-безопасности)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔧 Installation / Установка

### Install Utilities / Установка утилит
If `htpasswd` is missing: / Если `htpasswd` отсутствует:

```bash
# Debian / Ubuntu
sudo apt install apache2-utils

# CentOS / RHEL / Fedora
sudo yum install httpd-tools

# Alpine Linux
apk add apache2-utils
```

---

# 🚀 Basic Usage / Основное использование

### Create New File / Создать новый файл
> [!WARNING]
> The `-c` flag creates a new file. If the file exists, it is **overwritten**!
>
> Флаг `-c` создает новый файл. Если файл существует, он будет **перезаписан**!

```bash
# Create new file and add user / Создать новый файл и добавить пользователя
htpasswd -c .htpasswd <USER>
# You will be prompted for a password. / Вас попросят ввести пароль.
```

### Add/Update User / Добавить/Обновить пользователя
To add a user to an existing file or update their password:
Для добавления пользователя в существующий файл или обновления пароля:

```bash
# Add or update user / Добавить или обновить пользователя
htpasswd .htpasswd <USER>
```

---

# 📦 Batch Mode / Пакетный режим

### Non-Interactive Password / Неинтерактивный ввод пароля
Use `-b` to pass the password from the command line (useful for scripts).
Используйте `-b` для передачи пароля в командной строке (полезно для скриптов).

> [!CAUTION]
> The password will be visible in bash history!
>
> Пароль будет виден в истории bash!

```bash
# Add user with password (batch) / Добавить пользователя с паролем (пакетно)
htpasswd -b .htpasswd <USER> <PASSWORD>
```

### Cost Factor (Bcrypt) / Настройка сложности (Bcrypt)
Use `-B` (default in modern versions) and `-C` to set cost.
Используйте `-B` (по умолчанию в новых версиях) и `-C` для настройки сложности.

```bash
# Set Bcrypt cost to 10 (higher = slower) / Установить сложность Bcrypt на 10 (выше = медленнее)
htpasswd -B -C 10 .htpasswd <USER>
```

---

# 🔍 Verification & Deletion / Проверка и удаление

### Verify Password / Проверить пароль
Check if the stored password matches the provided one.
Проверить, совпадает ли сохраненный пароль с введенным.

```bash
# Verify password / Проверить пароль
htpasswd -v .htpasswd <USER>
```

### Delete User / Удалить пользователя
Remove a user from the file.
Удалить пользователя из файла.

```bash
# Delete user / Удалить пользователя
htpasswd -D .htpasswd <USER>
```

---

# 🔒 Security Best Practices / Лучшие практики безопасности

### Hashing Algorithms / Алгоритмы хеширования
Always specify a strong algorithm if defaults are old.
Всегда указывайте сильный алгоритм, если настройки по умолчанию устарели.

```bash
# Force Bcrypt (Recommended) / Принудительно использовать Bcrypt (Рекомендуется)
htpasswd -B .htpasswd <USER>

# Force MD5 (Legacy, avoid) / Принудительно MD5 (Устарело, избегайте)
htpasswd -m .htpasswd <USER>

# Force SHA-512 (Secure) / Принудительно SHA-512 (Безопасно)
htpasswd -s .htpasswd <USER>
```

---

# 🌟 Real-World Examples / Примеры из практики

### Nginx Basic Auth / Nginx Basic Auth
Create a file for Nginx protection.
Создать файл для защиты Nginx.

```bash
# 1. Create file / Создать файл
htpasswd -c /etc/nginx/.htpasswd <USER>

# 2. Nginx Config / Конфиг Nginx
# location /admin {
#     auth_basic "Admin Area";
#     auth_basic_user_file /etc/nginx/.htpasswd;
# }
```

### Apache HTTPD Basic Auth / Apache HTTPD Basic Auth
Standard configuration for Apache.
Стандартная конфигурация для Apache.

```apache
# .htaccess or httpd.conf
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /etc/apache2/.htpasswd
Require valid-user
```

### HAProxy Basic Auth / HAProxy Basic Auth
Using a userlist with hashed passwords.
Использование списка пользователей с хешированными паролями.

```bash
# 1. Generate password (output to console) / Сгенерировать пароль (вывод в консоль)
htpasswd -bn <USER> <PASSWORD>
# Output: user:password_hash

# 2. HAProxy Config / Конфиг HAProxy
# userlist my_users
#     user <USER> password <PASSWORD_HASH>
#
# backend my_backend
#     acl auth_ok http_auth(my_users)
#     http-request auth realm "Restricted" unless auth_ok
```

### Traefik Basic Auth / Traefik Basic Auth
Middleware configuration.
Конфигурация Middleware.

```yaml
# 1. Generate password string / Сгенерировать строку пароля
# htpasswd -nb user password | sed -e s/\\$/\\$\\$/g

# 2. Traefik Dynamic Config (YAML)
http:
  middlewares:
    my-auth:
      basicAuth:
        users:
          - "user:$apr1$..."
```

### Kubernetes/OpenShift Secret / Секрет Kubernetes/OpenShift
Create a secret from an htpasswd file.
Создать секрет из файла htpasswd.

```bash
# 1. Create local file / Создать локальный файл
htpasswd -c -B auth <USER>

# 2. Create Secret / Создать секрет
kubectl create secret generic my-basic-auth --from-file=auth

# 3. Use in Ingress (Nginx) / Использовать в Ingress (Nginx)
# metadata:
#   annotations:
#     nginx.ingress.kubernetes.io/auth-type: basic
#     nginx.ingress.kubernetes.io/auth-secret: my-basic-auth
#     nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

### Scripted User Creation / Создание пользователей скриптом
Add multiple users from a list.
Добавить несколько пользователей из списка.

```bash
# Loop through users / Цикл по пользователям
for user in alice bob charlie; do
  htpasswd -b .htpasswd "$user" "PassFor$user"
done


```

```bash
# Loop through users com password/ Цикл по пользователям с паролями
for u in user1:pass1 user2:pass2 user3:pass3; do
    IFS=":" read -r name pw <<< "$u"
    if [ ! -f .htpasswd ]; then
        htpasswd -bc .htpasswd "$name" "$pw"
    else
        htpasswd -b .htpasswd "$name" "$pw"
    fi
done
```

