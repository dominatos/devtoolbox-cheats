Title: 🫙 Podman / nerdctl — Commands
Group: Kubernetes & Containers
Icon: 🫙
Order: 7

podman ps -a                                   # List (Podman) / Список (Podman)
podman run -d --name app -p 8080:80 image:tag  # Run (Podman) / Запуск (Podman)
podman logs -f app                             # Logs (Podman) / Логи (Podman)
nerdctl ps -a                                  # List (nerdctl) / Список (nerdctl)
nerdctl run -d --name app -p 8080:80 image:tag # Run (nerdctl) / Запуск (nerdctl)
nerdctl logs -f app                            # Logs (nerdctl) / Логи (nerdctl)

