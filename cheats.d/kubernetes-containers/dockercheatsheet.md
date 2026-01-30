Title: 🐳 Docker — Commands
Group: Kubernetes & Containers
Icon: 🐳
Order: 6

## 🔹 Basics

docker version                                 # Show Docker version / Показать версию Docker
docker info                                    # Docker system info / Информация о системе Docker
docker help                                    # Docker help / Справка Docker

---

## 🔹 Containers

docker ps                                      # Running containers / Запущенные контейнеры
docker ps -a                                   # All containers / Все контейнеры
docker ps -q                                   # Container IDs only / Только ID контейнеров

docker start CONTAINER                         # Start container / Запустить контейнер
docker stop CONTAINER                          # Stop container / Остановить контейнер
docker restart CONTAINER                       # Restart container / Перезапустить контейнер
docker rm CONTAINER                            # Remove container / Удалить контейнер
docker rm -f CONTAINER                         # Force remove / Принудительное удаление

docker logs CONTAINER                          # Container logs / Логи контейнера
docker logs -f CONTAINER                       # Follow logs / Логи (follow)
docker logs --tail=100 CONTAINER               # Last lines / Последние строки

docker inspect CONTAINER                       # Inspect container / Информация о контейнере
docker stats                                   # Resource usage / Использование ресурсов

docker exec -it CONTAINER sh                   # Shell inside / Оболочка внутри
docker exec -it CONTAINER bash                 # Bash inside / Bash внутри

---

## 🔹 Images

docker images                                  # List images / Список образов
docker pull nginx                              # Pull image / Скачать образ
docker push myimg:tag                          # Push image / Отправить образ
docker rmi IMAGE                               # Remove image / Удалить образ
docker tag img:latest img:v1                   # Tag image / Назначить тег
docker history IMAGE                           # Image layers / Слои образа

---

## 🔹 Build

docker build .                                 # Build image / Сборка образа
docker build -t myimg:tag .                    # Build with tag / Сборка с тегом
docker build --no-cache -t myimg:tag .         # Build no cache / Без кэша

---

## 🔹 Run

docker run myimg                               # Run container / Запуск контейнера
docker run -it myimg sh                        # Interactive / Интерактивный режим
docker run -d myimg                            # Detached / Фоновый режим

docker run --name app myimg                    # Named container / С именем
docker run -p 8080:80 myimg                    # Port mapping / Проброс портов
docker run -e ENV=prod myimg                   # Env var / Переменная окружения
docker run -v /host:/ctr myimg                 # Volume mount / Монтирование
docker run --restart=always myimg              # Auto restart / Автоперезапуск

---

## 🔹 Volumes

docker volume ls                               # List volumes / Список volumes
docker volume create VOL                       # Create volume / Создать volume
docker volume inspect VOL                     # Inspect volume / Инфо volume
docker volume rm VOL                           # Remove volume / Удалить volume

---

## 🔹 Networks

docker network ls                              # List networks / Список сетей
docker network create NET                      # Create network / Создать сеть
docker network inspect NET                     # Inspect network / Информация
docker network rm NET                          # Remove network / Удалить сеть

---

## 🔹 Docker Compose

docker compose up                              # Start services / Запуск сервисов
docker compose up -d                           # Detached / Фоновый режим
docker compose down                            # Stop & remove / Остановить и удалить
docker compose restart                         # Restart / Перезапуск

docker compose ps                              # List services / Список сервисов
docker compose logs                            # Logs / Логи
docker compose logs -f                         # Follow logs / Логи (follow)
docker compose exec app sh                     # Exec service / Войти в сервис

---

## 🔹 Cleanup

docker system df                               # Disk usage / Использование диска
docker system prune                            # Cleanup unused / Очистка
docker system prune -af                        # Aggressive cleanup / Глубокая очистка
docker image prune -a                          # Remove images / Удалить образы
docker volume prune                            # Remove volumes / Удалить volumes

---

## 📦 Dockerfile templates

### Alpine

FROM alpine:3.19
RUN apk add --no-cache curl
CMD ["sh"]

### Node.js

FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm","start"]

### Java JAR

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]

---

## 📦 docker-compose.yml example

version: "3.9"

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - db

  db:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: appdb
    volumes:
      - dbdata:/var/lib/mysql

volumes:
  dbdata:


