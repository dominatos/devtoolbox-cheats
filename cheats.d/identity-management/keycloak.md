---
Title: Keycloak
Group: Identity Management
Icon: 🪪
Order: 50
tags:
  - identity-management
  - sysadmin
  - security
---

# Keycloak — Identity and Access Management

**Description / Описание:**
Keycloak is an open-source Identity and Access Management (IAM) solution providing Single Sign-On (SSO), identity brokering, social login, user federation (LDAP/AD), and fine-grained authorization. Originally built on WildFly (JBoss), modern Keycloak (17+) is based on **Quarkus** for significantly improved startup time and resource efficiency. This cheatsheet focuses on the **Quarkus-based distribution**.

> [!NOTE]
> **Legacy vs Modern:** Keycloak versions prior to 17.0 used WildFly/JBoss as the application server (with `standalone.xml` configuration). Since version 17.0, Keycloak migrated to Quarkus. If you are running a WildFly-based version, consider upgrading. WildFly-based Keycloak reached end-of-life. / **Устаревший vs Современный:** Версии Keycloak до 17.0 использовали WildFly. С версии 17.0 Keycloak мигрировал на Quarkus.

## Table of Contents

- [Dev vs Prod Comparison](#Dev%20vs%20Prod%20Comparison)
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management](#Core%20Management)
- [Production Runbook: Realm Configuration (UI)](#Production%20Runbook:%20Realm%20Configuration%20(UI))
- [Tomcat Integration](#Tomcat%20Integration)
- [Sysadmin Operations](#Sysadmin%20Operations)
- [Security](#Security)
- [Backup & Restore](#Backup%20&%20Restore)
- [Optimization](#Optimization)
- [Troubleshooting](#Troubleshooting)
- [Logrotate Configuration](#Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## Dev vs Prod Comparison

| Feature / Характеристика | Dev Mode / Режим разработки | Prod Mode / Режим продакшена | Best for / Лучше для... |
| :--- | :--- | :--- | :--- |
| **Command / Команда** | `start-dev` | `start --optimized` | Launch method / Метод запуска |
| **HTTPS** | Optional / Необязательно | Mandatory / Обязательно | Security policy / Политика безопасности |
| **Database / База данных** | H2 (Embedded) | External (PostgreSQL/MySQL/etc) | Persistence / Хранение данных |
| **Hostname** | Any / Любой | Strictly defined / Строго определён | Networking / Сетевое взаимодействие |
| **Performance / Скорость** | Hot reload / Горячая перезагрузка | Build-time optimized / Оптимизирован при сборке | Throughput / Пропускная способность |
| **Caching** | Disabled / Отключено | Infinispan (local/distributed) | Session persistence / Сохранение сессий |
| **Admin Console** | Enabled / Включена | Should be restricted / Следует ограничить | Security / Безопасность |

> [!IMPORTANT]
> **Why use Optimized build?** Keycloak Quarkus performs heavy lifting during the `build` phase (resolving providers, configuring persistence, generating optimized code) to reduce startup time and memory footprint. Always run `kc.sh build` before deploying to production. / **Зачем нужна оптимизированная сборка?** Keycloak Quarkus выполняет тяжёлые операции на этапе `build`, чтобы сократить время запуска и потребление памяти.

---

## Installation & Configuration

### Production Runbook: Installation

#### 1. Prerequisites

```bash
# Install Java 17 (Required for modern Keycloak)
sudo apt update && sudo apt install openjdk-17-jdk -y  # Debian/Ubuntu
sudo dnf install java-17-openjdk-devel -y             # RHEL/Fedora

# Verify Java version
java -version  # Should output: openjdk version "17.x.x" / Должен вывести: openjdk version "17.x.x"
```

#### 2. Database Setup

> [!IMPORTANT]
> Use a production-grade database like PostgreSQL. The embedded H2 database is **only for development**. / Используйте производственную БД, такую как PostgreSQL. Встроенная H2 **только для разработки**.

```bash
# PostgreSQL Setup
sudo -u postgres psql <<EOF
CREATE DATABASE keycloak;
CREATE USER <USER> WITH ENCRYPTED PASSWORD '<PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO <USER>;
EOF
```

#### 3. Download & Install

```bash
# Create dedicated system user
sudo useradd -m -d /opt/keycloak -s /sbin/nologin keycloak

# Download and extract
curl -L https://github.com/keycloak/keycloak/releases/download/<VERSION>/keycloak-<VERSION>.tar.gz -o keycloak.tar.gz
sudo tar -xvzf keycloak.tar.gz -C /opt/keycloak --strip-components=1
sudo chown -R keycloak: /opt/keycloak
```

#### 4. Configuration
`/opt/keycloak/conf/keycloak.conf`

```properties
# Database
db=postgres
db-url=jdbc:postgresql://<HOST>:5432/keycloak
db-username=<USER>
db-password=<PASSWORD>

# Hostname
hostname=<HOST>

# HTTPS
http-enabled=false
https-certificate-file=/etc/letsencrypt/live/<HOST>/fullchain.pem
https-certificate-key-file=/etc/letsencrypt/live/<HOST>/privkey.pem

# Proxy (if behind reverse proxy)
# proxy-headers=xforwarded
# http-enabled=true
```

#### 5. Build and Admin Setup

```bash
# Build optimized image
sudo -u keycloak /opt/keycloak/bin/kc.sh build

# Create initial admin user (Env variables)
export KC_BOOTSTRAP_ADMIN_USERNAME=<USER>
export KC_BOOTSTRAP_ADMIN_PASSWORD=<PASSWORD>
sudo -u keycloak /opt/keycloak/bin/kc.sh start --optimized
```

> [!TIP]
> After the first admin is created, remove the environment variables from your shell history for security. / После создания первого админа удалите переменные окружения из истории shell.

#### 6. Systemd Integration
`/etc/systemd/system/keycloak.service`

```ini
[Unit]
Description=Keycloak Identity Management
After=network.target postgresql.service

[Service]
Type=simple
User=keycloak
Group=keycloak
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start --optimized
Restart=on-failure
RestartSec=10
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/keycloak

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload  # Reload systemd / Перезагрузить systemd
sudo systemctl enable --now keycloak  # Enable and start / Включить и запустить
```

### Running the Server

```bash
bin/kc.sh start-dev  # Run in dev mode (H2, HTTP allowed) / Запуск в режиме разработки
bin/kc.sh start --optimized  # Start optimized for production / Запуск в продакшен-режиме
bin/kc.sh build  # Pre-configure for faster startup / Предварительная сборка
bin/kc.sh show-config  # Show current configuration / Показать текущую конфигурацию
```

---

## Core Management

### CLI Login

```bash
# Login to master realm
bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user <USER> \
  --password <PASSWORD>
```

### Realm Management

```bash
bin/kcadm.sh create realms -s realm=<REALM_NAME> -s enabled=true  # Create new realm / Создать новый реалм
bin/kcadm.sh get realms/<REALM_NAME>  # Get realm info / Получить информацию о реалме
bin/kcadm.sh get realms  # List all realms / Список всех реалмов
bin/kcadm.sh update realms/<REALM_NAME> -s enabled=false  # Disable realm / Отключить реалм
bin/kcadm.sh delete realms/<REALM_NAME>  # Delete realm / Удалить реалм
```

> [!WARNING]
> Deleting a realm removes all users, clients, roles, and sessions within it. This action is **irreversible**. / Удаление реалма удалит всех пользователей, клиентов, роли и сессии. Это действие **необратимо**.

### User Management

```bash
# Create user
bin/kcadm.sh create users -r <REALM_NAME> -s username=<USER> -s enabled=true

# Set password
bin/kcadm.sh set-password -r <REALM_NAME> --username <USER> --new-password <PASSWORD>

# Set password as temporary (user must change on first login)
bin/kcadm.sh set-password -r <REALM_NAME> --username <USER> --new-password <PASSWORD> --temporary

# List users
bin/kcadm.sh get users -r <REALM_NAME> --limit 100

# Search users
bin/kcadm.sh get users -r <REALM_NAME> -q username=<USER>

# Delete user
bin/kcadm.sh delete users/<USER_ID> -r <REALM_NAME>
```

### Client Management

```bash
# Create client
bin/kcadm.sh create clients -r <REALM_NAME> \
  -s clientId=<CLIENT_ID> \
  -s enabled=true \
  -s protocol=openid-connect \
  -s publicClient=false \
  -s 'redirectUris=["http://<HOST>:8080/*"]'

# List clients
bin/kcadm.sh get clients -r <REALM_NAME> --fields id,clientId

# Get client secret
bin/kcadm.sh get clients/<CLIENT_UUID>/client-secret -r <REALM_NAME>
```

### Role Management

```bash
# Create realm role
bin/kcadm.sh create roles -r <REALM_NAME> -s name=<ROLE_NAME>

# Assign role to user
bin/kcadm.sh add-roles -r <REALM_NAME> --uusername <USER> --rolename <ROLE_NAME>

# List realm roles
bin/kcadm.sh get roles -r <REALM_NAME>
```

---

## Production Runbook: Realm Configuration (UI)

### 1. Create a Realm

1. Login to Admin Console at `https://<HOST>:8443/admin/`.
2. Click the **Master** dropdown (top-left) → **Create Realm**.
3. Name: `my-realm` → **Create**.

### 2. Create a Client (e.g. Tomcat)

1. Navigate to **Clients** → **Create client**.
2. **Client ID:** `tomcat-app`.
3. **Client Protocol:** `openid-connect`.
4. **Access Type:** `confidential` (requires secret) / `public`.
5. **Valid Redirect URIs:** `http://<APP_HOST>:8080/*`.
6. **Web Origins:** `*` (or your domain).
7. Save and go to **Credentials** tab to get the **Client Secret**.

### 3. Create a User

1. Navigate to **Users** → **Add user**.
2. Username: `<USER>` → **Create**.
3. **Credentials** tab → **Set password** → Disable **Temporary**.

### 4. Configure Identity Providers (Optional)

1. Navigate to **Identity Providers** → Choose provider (Google, GitHub, SAML, etc.).
2. Configure **Client ID** and **Secret** from the external provider.
3. Set **Redirect URI** back to Keycloak.

---

## Tomcat Integration

### Configuration Details

To integrate Tomcat with Keycloak, use the `keycloak.json` file or configure the `KeycloakAuthenticatorValve` in `context.xml`.

> [!NOTE]
> The Keycloak Tomcat adapter is **deprecated** since Keycloak 19+. For new projects, consider using standards-based OpenID Connect libraries (e.g., `spring-security-oauth2` or `mod_auth_openidc` for Apache). / Адаптер Keycloak для Tomcat **устарел** с версии 19+. Для новых проектов используйте стандартные OIDC-библиотеки.

`/var/lib/tomcat/webapps/<APP>/WEB-INF/keycloak.json`

```json
{
  "realm": "my-realm",
  "auth-server-url": "https://<KEYCLOAK_HOST>:8443/",
  "ssl-required": "external",
  "resource": "tomcat-app",
  "credentials": {
    "secret": "<SECRET_KEY>"
  },
  "confidential-port": 8443
}
```

### Installation Steps

```bash
# 1. Download Keycloak Tomcat Adapter
curl -L https://github.com/keycloak/keycloak/releases/download/<VERSION>/keycloak-oidc-tomcat-adapter-<VERSION>.tar.gz -o adapter.tar.gz

# 2. Extract into $TOMCAT_HOME/lib
tar xzf adapter.tar.gz -C /opt/tomcat/lib/

# 3. Restart Tomcat
systemctl restart tomcat
```

### Add Keycloak Valve to context.xml
`/var/lib/tomcat/webapps/<APP>/META-INF/context.xml`

```xml
<Valve className="org.keycloak.adapters.tomcat.KeycloakAuthenticatorValve"/>
```

---

## Sysadmin Operations

### Service Controls

```bash
systemctl daemon-reload  # Reload systemd / Перезагрузить systemd
systemctl enable --now keycloak  # Enable and start / Включить и запустить
systemctl status keycloak  # Check status / Проверить статус
systemctl restart keycloak  # Restart service / Перезапустить сервис
systemctl stop keycloak  # Stop service / Остановить сервис
journalctl -u keycloak -f  # Follow logs / Следовать за логами
journalctl -u keycloak --since "1 hour ago"  # Logs from last hour / Логи за последний час
```

### Default Network Ports

| Port / Порт | Protocol / Протокол | Service / Сервис |
| :--- | :--- | :--- |
| **8080** | HTTP | External Load Balancer / Внешний балансировщик |
| **8443** | HTTPS | Direct Access / Прямой доступ |
| **9000** | HTTP | Management Interface (health, metrics) / Интерфейс управления |

### Firewall Configuration

```bash
# UFW (Debian/Ubuntu)
sudo ufw allow 8443/tcp  # HTTPS access / Доступ по HTTPS
sudo ufw allow 9000/tcp  # Management (restrict to internal network!) / Управление (ограничьте внутренней сетью!)

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=8443/tcp  # HTTPS
sudo firewall-cmd --permanent --add-port=9000/tcp  # Management
sudo firewall-cmd --reload  # Apply changes / Применить изменения
```

### Key File Locations

| Path / Путь | Description / Описание |
| :--- | :--- |
| `/opt/keycloak/conf/keycloak.conf` | Main configuration / Основная конфигурация |
| `/opt/keycloak/conf/cache-ispn.xml` | Infinispan cache config / Конфигурация кэша Infinispan |
| `/opt/keycloak/data/` | Runtime data (H2, logs, tmp) / Данные времени выполнения |
| `/opt/keycloak/data/log/` | Log files / Файлы логов |
| `/opt/keycloak/providers/` | Custom SPI providers / Пользовательские SPI-провайдеры |
| `/opt/keycloak/themes/` | Custom themes / Пользовательские темы |

---

## Security

### Brute Force Protection

> [!NOTE]
> Configure via **Realm Settings** → **Security Defenses** → **Brute Force Detection** in the Admin Console. / Настройте через **Настройки реалма** → **Защита** → **Обнаружение брутфорса** в консоли администратора.

```bash
# Get brute force config for realm
bin/kcadm.sh get realms/<REALM_NAME> --fields bruteForceProtected,maxFailureWaitSeconds,failureFactor
```

### Password Policies

```bash
# Set password policy for realm
bin/kcadm.sh update realms/<REALM_NAME> \
  -s 'passwordPolicy="length(8) and digits(1) and upperCase(1) and specialChars(1)"'
```

### Truststores & Keystores

```bash
# Import certificate into Java keystore
keytool -import -alias <HOST> -file <CERT_FILE> -keystore <KEYSTORE_FILE> -storepass <PASSWORD>

# List certificates in keystore
keytool -list -keystore <KEYSTORE_FILE> -storepass <PASSWORD>
```

### Restricting Admin Console Access

```bash
# In keycloak.conf — restrict admin console to specific IPs
# Use reverse proxy rules (nginx/Apache) to restrict /admin/ path
# Or use Keycloak's built-in hostname settings:
hostname-admin=<ADMIN_HOST>
```

---

## Backup & Restore

### Export Realm

```bash
bin/kc.sh export --dir <EXPORT_PATH> --realm <REALM_NAME>  # Export specific realm to directory / Экспорт конкретного реалма в каталог
bin/kc.sh export --file <FILE_PATH>  # Export all realms to single file / Экспорт всех реалмов в один файл
bin/kc.sh export --dir <EXPORT_PATH> --users realm_file  # Export with users / Экспорт с пользователями
```

### Import Realm

```bash
bin/kc.sh import --file <FILE_PATH>  # Import from file / Импорт из файла
bin/kc.sh import --dir <IMPORT_PATH>  # Import from directory / Импорт из каталога
```

> [!CAUTION]
> **Data Loss Risk:** Importing realms may overwrite existing configurations including users, clients, and roles. Always take a database snapshot before major imports. / **Риск потери данных:** Импорт реалмов может перезаписать существующие конфигурации. Всегда делайте снапшот базы данных перед крупным импортом.

### Database Backup

```bash
# PostgreSQL backup
pg_dump -U <USER> -h <HOST> keycloak > keycloak_backup_$(date +%Y%m%d).sql

# PostgreSQL restore
psql -U <USER> -h <HOST> keycloak < keycloak_backup_<DATE>.sql
```

### Production Runbook: Full Backup

1. **Stop Keycloak** (if consistency is critical):
   ```bash
   systemctl stop keycloak
   ```
2. **Backup database:**
   ```bash
   pg_dump -U <USER> -h <HOST> -Fc keycloak > keycloak_$(date +%Y%m%d).dump
   ```
3. **Backup configuration:**
   ```bash
   tar czf keycloak_conf_$(date +%Y%m%d).tar.gz /opt/keycloak/conf/ /opt/keycloak/providers/ /opt/keycloak/themes/
   ```
4. **Export realms** (optional, for portability):
   ```bash
   bin/kc.sh export --dir /tmp/kc-export --users realm_file
   ```
5. **Start Keycloak:**
   ```bash
   systemctl start keycloak
   ```

---

## Optimization

### JVM Tuning
`/opt/keycloak/conf/keycloak.conf`

```bash
# Add to JAVA_OPTS in bin/kc.sh or use environment variables
export KC_DB_POOL_MAX_SIZE=20  # Max DB connection pool size / Макс. размер пула соединений с БД
export KC_DB_POOL_INITIAL_SIZE=5  # Initial connection pool / Начальный пул соединений
export JAVA_OPTS="-Xms1024m -Xmx2048m"  # RAM allocation / Выделение оперативной памяти
```

### Performance Flags

| Optimization / Оптимизация | Env Variable / Переменная | Description / Описание |
| :--- | :--- | :--- |
| **Max Threads** | `QUARKUS_THREAD_POOL_MAX_THREADS` | Max worker threads / Макс. рабочих потоков |
| **Build Optimization** | `--optimized` flag | Skip runtime checks / Пропуск проверок во время выполнения |
| **DB Pool Max** | `KC_DB_POOL_MAX_SIZE` | Max DB connections / Макс. соединений с БД |
| **DB Pool Initial** | `KC_DB_POOL_INITIAL_SIZE` | Initial connection pool / Начальный пул соединений |
| **HTTP Max Connections** | `QUARKUS_HTTP_MAX_CONNECTIONS` | Max concurrent HTTP connections / Макс. одновременных HTTP-соединений |
| **Cache Owners** | `KC_CACHE_ISPN_DEFAULT_OWNERS` | Number of cache owners in cluster / Число владельцев кэша в кластере |

### Health & Metrics Endpoints

```bash
# Enable health and metrics (add to keycloak.conf)
# health-enabled=true
# metrics-enabled=true

# Check health
curl -s http://localhost:9000/health | jq .

# Check readiness
curl -s http://localhost:9000/health/ready | jq .

# Prometheus metrics
curl -s http://localhost:9000/metrics
```

---

## Troubleshooting

### Check Active Sessions

```bash
bin/kcadm.sh get realms/<REALM_NAME>/users/<USER_ID>/sessions  # List sessions for user / Список сессий пользователя
```

### Logout All Sessions

> [!WARNING]
> This will force all users in the realm to re-authenticate. / Это заставит всех пользователей реалма пройти повторную аутентификацию.

```bash
# Logout all sessions in realm
bin/kcadm.sh create realms/<REALM_NAME>/logout-all
```

### Common Issues & Fixes

| Issue / Проблема | Fix / Решение |
| :--- | :--- |
| **Invalid redirect URI** | Check "Valid Redirect URIs" in Client settings / Проверьте настройки клиента |
| **HTTPS Required but not configured** | Set `http-enabled=true` for dev OR configure SSL certificates / Включите http для разработки или настройте SSL |
| **Database connection refused** | Verify DB host, port, credentials in `keycloak.conf` / Проверьте хост, порт, учётные данные в конфиге |
| **Admin console blank page** | Clear browser cache and verify `hostname` setting / Очистите кэш браузера и проверьте настройку `hostname` |
| **Out of Memory** | Increase `-Xmx` in `JAVA_OPTS` / Увеличьте `-Xmx` |
| **Slow startup** | Run `kc.sh build` first, then `start --optimized` / Сначала `kc.sh build`, потом `start --optimized` |
| **Token expired errors** | Increase token lifespan in Realm Settings → Tokens / Увеличьте время жизни токена |

### Debug Logging

```bash
# Enable debug logging for specific categories
bin/kc.sh start --log-level=org.keycloak:debug  # Debug Keycloak internals / Отладка внутренних компонентов
bin/kc.sh start --log-level=org.keycloak.services:debug  # Debug services / Отладка сервисов
```

### Test OIDC Token

```bash
# Get access token via Resource Owner Password Grant
curl -X POST "https://<HOST>:8443/realms/<REALM_NAME>/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=<CLIENT_ID>" \
  -d "client_secret=<SECRET_KEY>" \
  -d "username=<USER>" \
  -d "password=<PASSWORD>"

# Introspect token
curl -X POST "https://<HOST>:8443/realms/<REALM_NAME>/protocol/openid-connect/token/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=<ACCESS_TOKEN>" \
  -d "client_id=<CLIENT_ID>" \
  -d "client_secret=<SECRET_KEY>"
```

---

## Logrotate Configuration

### Keycloak Logs
`/etc/logrotate.d/keycloak`

```bash
/opt/keycloak/data/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 keycloak keycloak
}
```

---

## Documentation Links

- **Keycloak Official Documentation:** [https://www.keycloak.org/documentation](https://www.keycloak.org/documentation)
- **Keycloak Server Administration Guide:** [https://www.keycloak.org/docs/latest/server_admin/](https://www.keycloak.org/docs/latest/server_admin/)
- **Keycloak Configuration Guide (Quarkus):** [https://www.keycloak.org/server/configuration](https://www.keycloak.org/server/configuration)
- **Keycloak REST API Reference:** [https://www.keycloak.org/docs-api/latest/rest-api/](https://www.keycloak.org/docs-api/latest/rest-api/)
- **Keycloak GitHub Repository:** [https://github.com/keycloak/keycloak](https://github.com/keycloak/keycloak)
- **Keycloak Migration Guide (WildFly → Quarkus):** [https://www.keycloak.org/migration/migrating-to-quarkus](https://www.keycloak.org/migration/migrating-to-quarkus)
