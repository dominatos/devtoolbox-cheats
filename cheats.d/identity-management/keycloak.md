Title: Keycloak
Group: Identity Management
Icon: 🪪
Order: 50

# Keycloak Cheatsheet / Шпаргалка по Keycloak

Keycloak is an open-source Identity and Access Management (IAM) solution based on WildFly (legacy) or Quarkus (modern). This cheatsheet focuses on the **Quarkus-based distribution**.

## Table of Contents / Оглавление
- [Dev vs Prod Comparison / Сравнение Dev и Prod](#dev-vs-prod-comparison--сравнение-dev-и-prod)
- [Production Runbook: Installation / Руководство по установке](#production-runbook-installation--руководство-по-установке)
- [Production Runbook: Realm Configuration (UI) / Настройка реалма (в браузере)](#production-runbook-realm-configuration-ui--настройка-реалма-в-браузере)
- [Tomcat Integration / Интеграция с Tomcat](#tomcat-integration--интеграция-с-tomcat)
- [Installation & Configuration / Установка и конфигурация](#installation--configuration--установка-и-конфигурация)
- [Core Management / Основное управление](#core-management--основное-управление)
- [Sysadmin Operations / Системное администрирование](#sysadmin-operations--системное-администрирование)
- [Security / Безопасность](#security--безопасность)
- [Backup & Restore / Резервное копирование и восстановление](#backup--restore--резервное-копирование-и-восстановление)
- [Optimization / Оптимизация](#optimization--оптимизация)
- [Troubleshooting / Исправление неполадок](#troubleshooting--исправление-неполадок)

---

## Production Runbook: Installation / Руководство по установке

### 1. Prerequisites / Предварительные требования
```bash
# Install Java 17 (Required for modern Keycloak) / Установите Java 17
sudo apt update && sudo apt install openjdk-17-jdk -y  # Debian/Ubuntu
sudo dnf install java-17-openjdk-devel -y             # RHEL/Fedora
```

### 2. Database Backup/Setup / Настройка базы данных
> [!IMPORTANT]
> Use a production-grade database like PostgreSQL.

```bash
# PostgreSQL Setup / Настройка PostgreSQL
sudo -u postgres psql <<EOF
CREATE DATABASE keycloak;
CREATE USER <USER> WITH ENCRYPTED PASSWORD '<PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO <USER>;
EOF
```

### 3. Basic Installation / Базовая установка
```bash
# Create user and download / Создайте пользователя и скачайте
sudo useradd -m -d /opt/keycloak -s /sbin/nologin keycloak
curl -L https://github.com/keycloak/keycloak/releases/download/<VERSION>/keycloak-<VERSION>.tar.gz -o keycloak.tar.gz
sudo tar -xvzf keycloak.tar.gz -C /opt/keycloak --strip-components=1
sudo chown -R keycloak: /opt/keycloak
```

### 4. Initial Configuration / Первоначальная конфигурация
`/opt/keycloak/conf/keycloak.conf`

```properties
db=postgres
db-url=jdbc:postgresql://<HOST>:5432/keycloak
db-username=<USER>
db-password=<PASSWORD>
hostname=<HOST>
http-enabled=false
https-certificate-file=/etc/letsencrypt/live/<HOST>/fullchain.pem
https-certificate-key-file=/etc/letsencrypt/live/<HOST>/privkey.pem
```

### 5. Build and Admin Setup / Сборка и создание админа
```bash
# Build optimized image / Сборка оптимизированного образа
sudo -u keycloak /opt/keycloak/bin/kc.sh build

# Create initial admin user (Env variables) / Создание первого админа
export KC_BOOTSTRAP_ADMIN_USERNAME=<USER>
export KC_BOOTSTRAP_ADMIN_PASSWORD=<PASSWORD>
sudo -u keycloak /opt/keycloak/bin/kc.sh start --optimized
```

### 6. Systemd Integration / Интеграция с Systemd
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
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

[Install]
WantedBy=multi-user.target
```

---

## Dev vs Prod Comparison / Сравнение Dev и Prod

| Feature / Характеристика | Dev Mode / Режим разработки | Prod Mode / Режим продакшена | Best for / Лучше для... |
| :--- | :--- | :--- | :--- |
| **Command / Команда** | `start-dev` | `start --optimized` | Launch method / Метод запуска |
| **HTTPS** | Optional / Необязательно | Mandatory / Обязательно | Security policy / Политика безопасности |
| **Database / База данных** | Dev / H2 (Embedded) | External (PostgreSQL/MySQL/etc) | Persistence / Хранение данных |
| **Hostname** | Any / Любой | Strictly defined / Строго определен | Networking / Сетевое взаимодействие |
| **Performance / Скорость** | Hot reload / Горячая перезагрузка | Built-time optimized / Оптимизирован при сборке | Throughput / Пропускная способность |

> [!IMPORTANT]
> **Why use Optimized build?** Keycloak Quarkus performs heavy lifting during the `build` phase to reduce startup time and memory footprint. Always run `kc.sh build` before deploying to production.

---

## Production Runbook: Realm Configuration (UI) / Настройка реалма (в браузере)

### 1. Create a Realm / Создание реалма
1. Login to Admin Console at `https://<HOST>:8443/admin/`.
2. Click the **Master** dropdown (top-left) -> **Create Realm**.
3. Name: `my-realm` -> **Create**.

### 2. Create a Client (Tomcat) / Создание клиента
1. Navigate to **Clients** -> **Create client**.
2. **Client ID:** `tomcat-app`.
3. **Client Protocol:** `openid-connect`.
4. **Access Type:** `confidential` (requires secret) / `public`.
5. **Valid Redirect URIs:** `http://<TOMCAT_HOST>:8080/*`.
6. **Web Origins:** `*` (or your domain).
7. Save and go to **Credentials** tab to get the **Client Secret**.

### 3. Create a User / Создание пользователя
1. Navigate to **Users** -> **Add user**.
2. Username: `john_doe` -> **Create**.
3. **Credentials** tab -> **Set password** -> Disable **Temporary**.

---

## Tomcat Integration / Интеграция с Tomcat

### Configuration Details / Детали конфигурации
To integrate Tomcat with Keycloak, use the `keycloak.json` file or configure the `KeycloakAuthenticatorValve` in `context.xml`.

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

### Installation Steps / Шаги установки
```bash
# 1. Download Keycloak Tomcat Adapter / Скачайте адаптер
# 2. Extract into $TOMCAT_HOME/lib / Распакуйте в lib
# 3. Add Keycloak Valve to META-INF/context.xml / Добавьте клапан в context.xml
```

```xml
<Valve className="org.keycloak.adapters.tomcat.KeycloakAuthenticatorValve"/>
```

---

## Installation & Configuration / Установка и конфигурация

### Initial Build / Первоначальная сборка
`/opt/keycloak/conf/keycloak.conf`

```bash
bin/kc.sh build  # Pre-configure for faster startup / Предварительная настройка для быстрого запуска
```

### Basic Config / Базовая конфигурация
`/opt/keycloak/conf/keycloak.conf`

```properties
db=postgres
db-url=jdbc:postgresql://<HOST>:5432/keycloak
db-username=<USER>
db-password=<PASSWORD>
hostname=<HOST>
http-enabled=false
https-certificate-file=/etc/letsencrypt/live/<HOST>/fullchain.pem
https-certificate-key-file=/etc/letsencrypt/live/<HOST>/privkey.pem
```

### Running the Server / Запуск сервера
```bash
bin/kc.sh start-dev  # Run in dev mode (H2, HTTP) / Запуск в режиме разработки (H2, HTTP)
bin/kc.sh start --optimized  # Start optimized for production / Запуск, оптимизированный для продакшена
```

---

## Core Management / Основное управление

### CLI Login / Вход через CLI
```bash
bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user <USER> --password <PASSWORD>  # Login to master realm / Вход в мастер-реалм
```

### Realm Management / Управление реалмами
```bash
bin/kcadm.sh create realms -s realm=<REALM_NAME> -s enabled=true  # Create new realm / Создать новый реалм
bin/kcadm.sh get realms/<REALM_NAME>  # Get realm info / Получить информацию о реалме
```

### User Management / Управление пользователями
```bash
bin/kcadm.sh create users -r <REALM_NAME> -s username=<USER> -s enabled=true  # Create user / Создать пользователя
bin/kcadm.sh set-password -r <REALM_NAME> --username <USER> --new-password <PASSWORD>  # Set password / Установить пароль
```

---

## Sysadmin Operations / Системное администрирование

### Systemd Service / Служба Systemd
`/etc/systemd/system/keycloak.service`

```ini
[Unit]
Description=Keycloak Identity Management
After=network.target postgresql.service

[Service]
Type=simple
User=keycloak
Group=keycloak
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start --optimized
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Service Controls / Управление службой
```bash
systemctl daemon-reload  # Reload systemd / Перезагрузить systemd
systemctl enable --now keycloak  # Enable and start / Включить и запустить
systemctl status keycloak  # Check status / Проверить статус
journalctl -u keycloak -f  # Follow logs / Следовать за логами
```

### Default Network Ports / Сетевые порты по умолчанию
- **8080**: HTTP (External Load Balancer) / Внешний балансировщик
- **8443**: HTTPS (Direct Access) / Прямой доступ
- **9000**: Management Interface (Optional) / Интерфейс управления

---

## Security / Безопасность

### Brute Force Protection / Защита от брутфорса
> [!NOTE]
> Configure via Realm Settings -> Security Defenses -> Brute Force Detection.

```bash
# Get brute force config for realm / Получить конфиг защиты от брутфорса
bin/kcadm.sh get realms/<REALM_NAME>/brute-force-detection
```

### Truststores & Keystores / Хранилища ключей
```bash
keytool -import -alias <HOST> -file <CERT_FILE> -keystore <KEYSTORE_FILE>  # Import certificate / Импорт сертификата
```

---

## Backup & Restore / Резервное копирование и восстановление

### Export Realm / Экспорт реалма
```bash
bin/kc.sh export --dir <EXPORT_PATH> --realm <REALM_NAME>  # Export specific realm / Экспорт конкретного реалма
bin/kc.sh export --file <FILE_PATH>  # Export all to single file / Экспорт всего в один файл
```

### Import Realm / Импорт реалма
```bash
bin/kc.sh import --file <FILE_PATH>  # Import from file / Импорт из файла
```

> [!CAUTION]
> **Data Loss Risk:** Importing realms may overwrite existing configurations. Always take a database snapshot before major imports. / **Риск потери данных:** Импорт реалмов может перезаписать существующие конфигурации. Всегда делайте снапшот базы данных перед крупным импортом.

---

## Optimization / Оптимизация

### JVM Tuning / Настройка JVM
`/opt/keycloak/conf/keycloak.conf`

```bash
# Add to JAVA_OPTS in bin/kc.sh or use environment variables / Добавьте в JAVA_OPTS или используйте переменные окружения
export KC_DB_POOL_MAX_SIZE=20  # Optimization for DB connections / Оптимизация соединений с БД
export JAVA_OPTS="-Xms1024m -Xmx2048m"  # RAM allocation / Выделение оперативной памяти
```

### Performance Flags / Флаги производительности
| Optimization / Оптимизация | Env Variable / Переменная | Description / Описание |
| :--- | :--- | :--- |
| **Max Threads** | `QUARKUS_THREAD_POOL_MAX_THREADS` | Max worker threads / Макс. рабочих потоков |
| **Build Optimization** | `--optimized` | Skip runtime checks / Пропуск проверок во время выполнения |
| **DB Caching** | `KC_DB_POOL_INITIAL_SIZE` | Initial connection pool / Начальный пул соединений |

---

## Troubleshooting / Исправление неполадок

### Check Active Sessions / Просмотр активных сессий
```bash
bin/kcadm.sh get realms/<REALM_NAME>/users/<USER_ID>/sessions  # List sessions for user / Список сессий пользователя
```

### Common Fixes / Частые решения

- **Issue:** Invalid redirect URI / Неверный redirect URI.  
  **Fix:** Check "Valid Redirect URIs" in Client settings / Проверьте настройки клиента.
- **Issue:** HTTPS Required but not configured / Требуется HTTPS, но он не настроен.  
  **Fix:** Set `http-enabled=true` for internal dev OR configure SSL certificates / Включите http для разработки или настройте SSL.

---

## Logrotate Configuration / Настройка ротации логов
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
