Title: 🐳 Docker — Commands
Group: Kubernetes & Containers
Icon: 🐳
Order: 6

## Table of Contents
- [Installation & Configuration](#-installation--configuration)
- [Core Management](#-core-management)
    - [Lifecycle](#-lifecycle)
    - [Containers](#-containers)
    - [Images](#-images)
    - [Networks](#-networks)
    - [Volumes](#-volumes)
    - [Cleanup](#-cleanup)
- [Sysadmin Operations](#-sysadmin-operations)
    - [Service Control](#-service-control)
    - [Resource Tuning](#-resource-tuning)
    - [Logging & Rotation](#-logging--rotation)
- [Security](#-security)
- [Backup & Restore](#-backup--restore)
- [Troubleshooting & Tools](#-troubleshooting--tools)
- [Docker Compose](#-docker-compose)
- [Dockerfile Templates](#-dockerfile-templates)

---

## 🛠 Installation & Configuration

### Package Management

```bash
# Install Docker (Debian/Ubuntu)
apt-get update && apt-get install docker-ce docker-ce-cli containerd.io

# Install Docker (RHEL/CentOS)
yum install docker-ce docker-ce-cli containerd.io
```

### Configuration Files
`/etc/docker/daemon.json`

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```
*Tip: Always validate JSON syntax before restarting the service.*

`/etc/default/docker`
*Environment variables for the Docker daemon (Startup options).*

`~/.docker/config.json`
*Client-side configuration (Auth tokens, aliases).*

### Contexts
Manage multiple Docker environments.

```bash
docker context ls                                  # List contexts / Список контекстов
docker context create my-context --docker "host=ssh://<USER>@<HOST>" # Create context via SSH / Создать контекст через SSH
docker context use my-context                      # Switch context / Переключить контекст
```

---

## 🔹 Core Management

### Lifecycle

```bash
docker run -d --name <CONTAINER_NAME> <IMAGE>      # Run container detached / Запуск контейнера в фоне
docker start <CONTAINER_ID>                        # Start stopped container / Запустить остановленный контейнер
docker stop <CONTAINER_ID>                         # Stop running container / Остановить запущенный контейнер
docker restart <CONTAINER_ID>                      # Restart container / Перезапустить контейнер
docker pause <CONTAINER_ID>                        # Pause processes / Приостановить процессы
docker unpause <CONTAINER_ID>                      # Unpause processes / Возобновить процессы
docker wait <CONTAINER_ID>                         # Block until container stops / Ждать остановки контейнера
docker kill <CONTAINER_ID>                         # Kill container / Принудительно завершить контейнер
```

### Containers

```bash
docker ps                                          # List running containers / Список запущенных контейнеров
docker ps -a                                       # List all containers / Список всех контейнеров
docker logs <CONTAINER_ID>                         # View logs / Просмотр логов
docker logs -f <CONTAINER_ID>                      # Follow logs / Следить за логами
docker inspect <CONTAINER_ID>                      # Inspect container / Информация о контейнере
docker stats                                       # Resource usage stats / Статистика использования ресурсов
docker top <CONTAINER_ID>                          # Display running processes / Показать запущенные процессы
```

**Interactive Execution**
```bash
docker exec -it <CONTAINER_ID> /bin/bash           # Open bash shell / Открыть оболочку bash
docker exec -it <CONTAINER_ID> sh                  # Open sh shell / Открыть оболочку sh
```

### Images

```bash
docker images                                      # List images / Список образов
docker pull <IMAGE>:<TAG>                          # Pull image / Скачать образ
docker push <REGISTRY>/<IMAGE>:<TAG>               # Push image / Отправить образ
docker rmi <IMAGE_ID>                              # Remove image / Удалить образ
docker tag <SOURCE_IMAGE> <TARGET_IMAGE>           # Tag image / Назначить тег
docker history <IMAGE_ID>                          # View image layers / Просмотр слоёв образа
docker build -t <IMAGE>:<TAG> .                    # Build from Dockerfile / Сборка из Dockerfile
docker buildx build --platform linux/amd64,linux/arm64 -t <IMAGE>:<TAG> . # Multi-arch build / Мульти-арх сборка
```

### Networks

| Driver | Description (EN / RU) | Use Case / Best for... |
| :--- | :--- | :--- |
| **bridge** | Default network driver / Драйвер по умолчанию | Standalone containers communicating on the same host. |
| **host** | Remove network isolation / Нет сетевой изоляции | Performance optimization, removing NAT overhead. |
| **overlay** | Multi-host network / Сеть между хостами | Swarm services, communicating across multiple daemons. |
| **macvlan** | Assign MAC address / Назначение MAC-адреса | Legacy apps needing direct physical network connection. |
| **none** | Disable networking / Отключить сеть | Complete isolation, offline batch jobs. |

```bash
docker network ls                                  # List networks / Список сетей
docker network create --driver bridge <NET_NAME>   # Create bridge network / Создать bridge сеть
docker network inspect <NET_NAME>                  # Inspect network / Информация о сети
docker network connect <NET_NAME> <CONTAINER_ID>   # Connect container / Подключить контейнер
docker network disconnect <NET_NAME> <CONTAINER_ID> # Disconnect container / Отключить контейнер
docker network rm <NET_NAME>                       # Remove network / Удалить сеть
```

### Volumes

| Type | Description (EN / RU) | Use Case / Best for... |
| :--- | :--- | :--- |
| **volume** | Managed by Docker / Управляется Docker | Persisting data generated by and used by Docker containers. |
| **bind mount** | Host file system path / Путь ФС хоста | Sharing config files or source code between host and container. |
| **tmpfs** | In-memory storage / Хранение в памяти | Storing sensitive info or performance-critical non-persistent data. |

```bash
docker volume ls                                   # List volumes / Список томов
docker volume create <VOL_NAME>                    # Create volume / Создать том
docker volume inspect <VOL_NAME>                   # Inspect volume / Информация о томе
docker volume rm <VOL_NAME>                        # Remove volume / Удалить том
docker volume prune                                # Remove unused volumes / Удалить неиспользуемые тома
```

### Cleanup

> [!WARNING]
> Use prune commands with caution in production. They permanently delete data.
> Используйте команды очистки с осторожностью в продакшене. Данные удаляются безвозвратно.

```bash
docker system df                                   # Show disk usage / Показать использование диска
docker system prune                                # Remove unused data / Удалить неиспользуемые данные
docker system prune -a --volumes                   # Deep clean (incl. volumes) / Глубокая очистка (вкл. тома)
docker container prune                             # Remove stopped containers / Удалить остановленные контейнеры
docker image prune -a                              # Remove unused images / Удалить неиспользуемые образы
```

---

## 🔧 Sysadmin Operations

### Service Control

```bash
systemctl start docker                             # Start Docker / Запустить Docker
systemctl stop docker                              # Stop Docker / Остановить Docker
systemctl restart docker                           # Restart Docker / Перезапустить Docker
systemctl enable docker                            # Enable on boot / Включить автозапуск
systemctl status docker                            # Check status / Проверить статус
```

### Resource Tuning
Limit container resources via `docker run`.

```bash
--memory="1g"                                      # Hard memory limit / Жесткий лимит памяти
--memory-reservation="512m"                        # Soft memory limit / Мягкий лимит памяти
--cpus="1.5"                                       # CPU quota (1.5 cores) / Квота CPU (1.5 ядра)
--pids-limit=100                                   # Limit PIDs / Лимит количества процессов
```


### Default Ports

*   **2375**: Docker daemon HTTP (insecure) / Демон Docker HTTP (небезопасно)
*   **2376**: Docker daemon HTTPS (TLS) / Демон Docker HTTPS (TLS)
*   **5000**: Docker Registry / Реестр Docker

### Logging & Rotation

**Default Log Paths**
`/var/lib/docker/containers/<CONTAINER_ID>/<CONTAINER_ID>-json.log`

> [!NOTE]
> It is best practice to configure log rotation in `daemon.json` to prevent disk exhaustion.
> Рекомендуется настроить ротацию логов в `daemon.json` для предотвращения переполнения диска.

`/etc/logrotate.d/docker`
*For Docker daemon logs.*

```conf
/var/log/docker.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## 🔒 Security

### User Wrapper
Manage strict permissions via user groups instead of `sudo`.
```bash
usermod -aG docker <USER>                          # Add user to docker group / Добавить пользователя в группу docker
newgrp docker                                      # Activate group changes / Применить изменения группы
```

### Registry Authentication

```bash
docker login <REGISTRY_URL>                        # Login / Вход
docker logout <REGISTRY_URL>                       # Logout / Выход
```

*Using a Service Account or Token:*
```bash
cat ~/my-password.txt | docker login --username <USER> --password-stdin <REGISTRY_URL>
```

### Content Trust
Enable enforcement of signed images.
```bash
export DOCKER_CONTENT_TRUST=1                      # Enable trust / Включить проверку подписей
```

---

## 💾 Backup & Restore

### Image Backup
Transfer images between air-gapped systems.

```bash
docker save -o <IMAGE_NAME>.tar <IMAGE_NAME>       # Save image to tar / Сохранить образ в tar
docker load -i <IMAGE_NAME>.tar                    # Load image from tar / Загрузить образ из tar
```

### Container Backup
Export filesystem (without metadata/history).

```bash
docker export <CONTAINER_ID> > <CONTAINER_NAME>.tar # Export container / Экспорт контейнера
docker import <CONTAINER_NAME>.tar                 # Import as image / Импорт как образ
```

### Volume Backup
Backup data from a volume using a helper container.

```bash
docker run --rm -v <VOL_NAME>:/volume -v $(pwd):/backup alpine tar cvf /backup/backup.tar /volume
```

---

## 🔍 Troubleshooting & Tools

### Common Issues
*   **Permission Denied:** Check if user is in `docker` group or socket permissions (`/var/run/docker.sock`).
*   **Network Conflicts:** Check subnet overlap in `docker network inspect`.
*   **OOMKilled:** Check `docker inspect <CONTAINER_ID>` -> State -> OOMKilled.

### Debug Tools

```bash
docker events                                      # Stream server events / Поток событий сервера
docker diff <CONTAINER_ID>                         # Show FS changes / Показать изменения ФС
ctop                                               # Top-like interface for containers / Top-подобный интерфейс
dive <IMAGE>                                       # Inspect image layers / Инспекция слоёв образа
```

### Debug Container
Run a container with a custom entrypoint to debug startup issues.
```bash
docker run -it --entrypoint /bin/sh <IMAGE>        # Override entrypoint / Переопределить точку входа
```

---

## 🔹 Docker Compose

`docker-compose.yml`
```yaml
version: "3.8"
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - app-net
  db:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: <PASSWORD>
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-net

volumes:
  db-data:

networks:
  app-net:
```

### Compose CLI Basics / Базовые команды Compose

```bash
docker compose up -d                               # Start detached / Запуск в фоне
docker compose down                                # Stop & remove resources / Остановить и удалить
docker compose logs -f                             # Follow logs / Следить за логами
docker compose config                              # Validate config / Проверить конфиг
```

### Environment Files / Файлы окружения
`.env`

```dotenv
# Example / Пример
POSTGRES_PASSWORD=<PASSWORD>
APP_ENV=prod
```

> [!NOTE]
> `docker compose` automatically loads variables from `.env` in the project directory.
> `docker compose` автоматически подхватывает переменные из `.env` в каталоге проекта.

### Production-ish App + DB (Healthchecks + Safe Defaults) / Прод-подобный пример (Healthchecks + безопасные настройки)
`docker-compose.yml`

```yaml
version: "3.8"

services:
  app:
    image: <REGISTRY>/<IMAGE>:<TAG>               # App image / Образ приложения
    environment:
      APP_ENV: "prod"                             # Environment / Окружение
      DATABASE_URL: "postgresql://<USER>:<PASSWORD>@db:5432/<DB>" # DSN / Строка подключения
    depends_on:
      db:
        condition: service_healthy                 # Wait for DB health / Ждать готовности БД
    ports:
      - "8080:8080"                               # Publish port / Проброс порта
    read_only: true                                # Reduce write surface / Минимизировать запись
    tmpfs:
      - /tmp                                       # Ephemeral temp / Временные данные
    security_opt:
      - no-new-privileges:true                     # Prevent privilege escalation / Запрет повышения привилегий
    cap_drop:
      - ALL                                        # Drop Linux caps / Сбросить capabilities
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"] # Health endpoint / Эндпоинт здоровья
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - app-net

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: <USER>
      POSTGRES_PASSWORD: <PASSWORD>
      POSTGRES_DB: <DB>
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U <USER> -d <DB>"]          # DB readiness / Готовность БД
      interval: 10s
      timeout: 5s
      retries: 10
    networks:
      - app-net

volumes:
  db-data:

networks:
  app-net:
```

> [!CAUTION]
> `depends_on.condition: service_healthy` is supported by the Docker Compose implementation, but some orchestrators ignore it.
> `depends_on.condition: service_healthy` поддерживается Docker Compose, но некоторые оркестраторы это игнорируют.

### Dev/Prod Overrides / Разделение dev/prod через override
`docker-compose.yml`

```yaml
version: "3.8"
services:
  app:
    image: <IMAGE>:<TAG>                           # Base config / Базовая конфигурация
    environment:
      APP_ENV: "prod"
```

`docker-compose.override.yml`

```yaml
version: "3.8"
services:
  app:
    environment:
      APP_ENV: "dev"                              # Dev mode / Режим разработки
    volumes:
      - ./:/app                                    # Bind mount source / Монтировать исходники
    command: ["sh", "-lc", "./run-dev.sh"]     # Dev command / Команда для dev
```

```bash
docker compose up -d                               # Uses override automatically / Автоматически использует override
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d  # Explicit / Явно
```

### Secrets (File-based) / Секреты (через файлы)
`docker-compose.yml`

```yaml
version: "3.8"
services:
  app:
    image: <REGISTRY>/<IMAGE>:<TAG>
    secrets:
      - app_secret_key
    environment:
      SECRET_KEY_FILE: "/run/secrets/app_secret_key" # Read from file / Читать из файла

secrets:
  app_secret_key:
    file: ./secrets/app_secret_key.txt             # Store outside VCS / Не хранить в VCS
```

> [!WARNING]
> Treat `./secrets/*` as sensitive. Do not commit it to Git.
> `./secrets/*` — чувствительные данные. Не коммитьте в Git.

### Profiles (Optional Services) / Профили (опциональные сервисы)
`docker-compose.yml`

```yaml
version: "3.8"
services:
  app:
    image: <IMAGE>:<TAG>

  debug:
    image: alpine:3.20
    command: ["sh", "-lc", "sleep infinity"]     # Debug toolbox / Отладочный контейнер
    profiles: ["debug"]
```

```bash
docker compose up -d                               # Start normal services / Запуск обычных сервисов
docker compose --profile debug up -d               # Include debug service / Запуск с debug-сервисом
```

### Production Runbook (Deploy/Rollback) / Прод-ранбук (Deploy/Rollback)

1. Deploy / Деплой
   1. `docker compose pull`  # Pull new images / Скачать новые образы
   2. `docker compose up -d` # Apply changes / Применить изменения
   3. `docker compose ps`    # Verify / Проверить
   4. `docker compose logs -f --tail=200 app` # Watch / Наблюдать
2. Rollback / Откат
   1. Pin previous tag in `docker-compose.yml` (e.g. `<TAG_OLD>`) / Зафиксировать предыдущий тег
   2. `docker compose pull && docker compose up -d` # Redeploy / Повторный деплой
   3. Validate health endpoint / Проверить health

---

## 📦 Dockerfile Templates

`./Dockerfile`

### Alpine Base
```dockerfile
FROM alpine:3.14
RUN apk add --no-cache curl
CMD ["sh"]
```

### Node.js
```dockerfile
FROM node:14-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
USER node
CMD ["npm", "start"]
```

### Java
```dockerfile
FROM openjdk:11-jre-slim
COPY app.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

### Node.js Multi-stage (Smaller Runtime) / Multi-stage Node.js (меньше образ)
```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
USER node
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=5 CMD wget -qO- http://127.0.0.1:8080/health || exit 1
CMD ["node", "dist/server.js"]
```

### Python (Non-root + No cache) / Python (не root + без кэша)
```dockerfile
FROM python:3.12-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN useradd -r -u 10001 -g nogroup appuser

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
USER 10001
EXPOSE 8000
CMD ["python", "-m", "app"]
```

### Go Multi-stage (Static Binary) / Go Multi-stage (статический бинарник)
```dockerfile
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/app ./cmd/app

FROM alpine:3.20
RUN adduser -D -u 10001 appuser
COPY --from=build /out/app /usr/local/bin/app
USER 10001
EXPOSE 8080
CMD ["/usr/local/bin/app"]
```

### Distroless (Minimal Attack Surface) / Distroless (минимальная поверхность атаки)
```dockerfile
FROM golang:1.22 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12
USER 65532:65532
COPY --from=build /out/app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
```

> [!NOTE]
> Distroless images often have no shell/tools. Prefer external debugging containers (e.g. `alpine`) and good logging.
> В distroless обычно нет shell/утилит. Для отладки используйте внешние debug-контейнеры и хорошие логи.

### Build Args + Labels / Аргументы сборки + метки
```dockerfile
FROM alpine:3.20

ARG VCS_REF="<GIT_SHA>"
ARG BUILD_DATE="<YYYY-MM-DD>"

LABEL org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.source="<REPO_URL>"

CMD ["sh", "-lc", "echo revision=$VCS_REF created=$BUILD_DATE"]
```

> [!CAUTION]
> Avoid baking secrets into images via `ARG` or `ENV`. Use runtime secrets instead (Compose secrets/K8s secrets).
> Не вшивайте секреты в образ через `ARG` или `ENV`. Используйте секреты на этапе запуска.
