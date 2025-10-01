Title: 🐳 Docker — Commands
Group: Kubernetes & Containers
Icon: 🐳
Order: 6

docker ps -a                                   # List containers / Список контейнеров
docker logs -f CONTAINER                       # Follow logs / Логи (follow)
docker exec -it CONTAINER sh                   # Shell inside / Оболочка внутри
docker build -t myimg:tag .                    # Build image / Сборка образа
docker run -d --name app -p 8080:80 myimg:tag  # Run mapped / Запуск с маппингом портов
docker compose up -d                           # Compose up / Запуск compose
docker system prune -af                        # Aggressive cleanup / Глубокая очистка

