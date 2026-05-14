Title: 🔐 htpasswd — Basic Auth
Group: Security & Crypto
Icon: 🔐
Order: 10

# htpasswd Sysadmin Cheatsheet

> **Context:** `htpasswd` is a utility for creating and managing password files used for HTTP Basic Authentication. Part of Apache HTTP Server utilities (`apache2-utils`/`httpd-tools`) but commonly used with Nginx, HAProxy, Traefik, and Kubernetes Ingress. Passwords are hashed using Bcrypt (recommended), MD5, or SHA. / `htpasswd` — утилита для создания файлов паролей для HTTP Basic Auth. Часть утилит Apache, но используется с Nginx, HAProxy, Traefik и Kubernetes Ingress.
> **Role:** Sysadmin / DevOps Engineer

---

## 📚 Table of Contents / Содержание

1. [Installation & Configuration](#1-installation--configuration)
2. [Core Management](#2-core-management)
3. [Sysadmin Operations](#3-sysadmin-operations)
4. [Security](#4-security)
5. [Real-World Examples](#5-real-world-examples)
6. [Documentation Links](#6-documentation-links)

---

## 1. Installation & Configuration

### Install Utilities / Установка утилит

```bash
sudo apt install apache2-utils   # Debian/Ubuntu
sudo dnf install httpd-tools     # RHEL/CentOS/Fedora
apk add apache2-utils            # Alpine Linux
```

### Algorithm Comparison / Сравнение алгоритмов

| Algorithm | Flag | Security | Recommendation / Рекомендация |
|-----------|------|----------|-------------------------------|
| **Bcrypt** | `-B` | ✅ Excellent | ✅ Recommended / Рекомендуется |
| **SHA-512** | `-s` | ✅ Good | Good alternative / Хорошая альтернатива |
| **MD5 (APR1)** | `-m` | ⚠️ Legacy | Legacy only / Только legacy |
| **Crypt** | `-d` | ❌ Weak | ❌ Avoid / Не использовать |

---

## 2. Core Management

### Create New File / Создать новый файл

> [!WARNING]
> The `-c` flag creates a new file. If the file exists, it is **overwritten**!
> Флаг `-c` создает новый файл. Если файл существует, он будет **перезаписан**!

```bash
htpasswd -c .htpasswd <USER>          # Create new file + add user / Создать файл и добавить пользователя
```

### Add/Update User / Добавить/Обновить пользователя

```bash
htpasswd .htpasswd <USER>             # Add or update user / Добавить или обновить пользователя
```

### Verify & Delete / Проверка и удаление

```bash
htpasswd -v .htpasswd <USER>          # Verify password / Проверить пароль
htpasswd -D .htpasswd <USER>          # Delete user / Удалить пользователя
```

### Batch Mode / Пакетный режим

> [!CAUTION]
> The password will be visible in bash history!
> Пароль будет виден в истории bash!

```bash
htpasswd -b .htpasswd <USER> <PASSWORD>       # Add user (batch) / Добавить (пакетно)
htpasswd -B -C 10 .htpasswd <USER>            # Bcrypt cost 10 / Сложность Bcrypt 10
```

---

## 3. Sysadmin Operations

### Force Specific Algorithm / Принудительный алгоритм

```bash
htpasswd -B .htpasswd <USER>          # Bcrypt (Recommended) / Bcrypt (Рекомендуется)
htpasswd -m .htpasswd <USER>          # MD5 (Legacy) / MD5 (Устарело)
htpasswd -s .htpasswd <USER>          # SHA-512 / SHA-512
```

### Output to Console / Вывод в консоль

```bash
htpasswd -bn <USER> <PASSWORD>        # Generate to stdout / Сгенерировать в stdout
htpasswd -bnB <USER> <PASSWORD>       # Bcrypt to stdout / Bcrypt в stdout
```

### Scripted User Creation / Создание пользователей скриптом

```bash
for user in alice bob charlie; do
  htpasswd -b .htpasswd "$user" "PassFor$user"
done
```

```bash
for u in user1:pass1 user2:pass2 user3:pass3; do
    IFS=":" read -r name pw <<< "$u"
    if [ ! -f .htpasswd ]; then
        htpasswd -bc .htpasswd "$name" "$pw"
    else
        htpasswd -b .htpasswd "$name" "$pw"
    fi
done
```

---

## 4. Security

### File Permissions / Права доступа

```bash
chmod 640 .htpasswd                   # Read for owner+group / Чтение для владельца+группа
chown root:www-data .htpasswd         # Owner root, group web server / Владелец root, группа веб
```

> [!IMPORTANT]
> Place `.htpasswd` **outside** the document root or protect it in web server config.
> Размещайте `.htpasswd` **вне** корневого каталога или защищайте конфигурацией сервера.

---

## 5. Real-World Examples

### Nginx Basic Auth

```bash
htpasswd -c /etc/nginx/.htpasswd <USER>
```

```nginx
# /etc/nginx/conf.d/protected.conf
location /admin {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### Apache HTTPD Basic Auth

```apache
# .htaccess or httpd.conf
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /etc/apache2/.htpasswd
Require valid-user
```

### HAProxy Basic Auth

```bash
htpasswd -bn <USER> <PASSWORD>
```

```haproxy
# /etc/haproxy/haproxy.cfg
userlist my_users
    user <USER> password <PASSWORD_HASH>

backend my_backend
    acl auth_ok http_auth(my_users)
    http-request auth realm "Restricted" unless auth_ok
```

### Traefik Basic Auth

```bash
htpasswd -nb user password | sed -e s/\\$/\\$\\$/g
```

```yaml
# Traefik Dynamic Config
http:
  middlewares:
    my-auth:
      basicAuth:
        users:
          - "user:$apr1$..."
```

### Kubernetes/OpenShift Secret

```bash
htpasswd -c -B auth <USER>
kubectl create secret generic my-basic-auth --from-file=auth
```

```yaml
# Ingress annotations
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: my-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

---

## 6. Documentation Links

- [Apache htpasswd Documentation](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)
- [Nginx HTTP Auth Basic Module](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html)
- [Apache HTTP Authentication](https://httpd.apache.org/docs/2.4/howto/auth.html)
- [Kubernetes Ingress Basic Auth](https://kubernetes.github.io/ingress-nginx/examples/auth/basic/)
- [Traefik BasicAuth Middleware](https://doc.traefik.io/traefik/middlewares/http/basicauth/)

---
