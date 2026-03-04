Title: 🫙 Podman / nerdctl — Commands
Group: Kubernetes & Containers
Icon: 🫙
Order: 7

## Table of Contents
- [Podman Basics](#podman-basics)
- [Podman Rootless Mode](#podman-rootless-mode)
- [Podman Pods](#podman-pods)
- [Podman Systemd Integration](#podman-systemd-integration)
- [nerdctl Basics](#nerdctl-basics)
- [crictl (CRI Debugging)](#crictl-cri-debugging)
- [Sysadmin Essentials](#sysadmin-essentials)
- [Logrotate Configuration](#logrotate-configuration)

---

## Podman Basics

### Container Management

```bash
podman ps -a                                   # List containers / Список контейнеров
podman run -d --name app -p 8080:80 nginx      # Run container / Запуск контейнера
podman start app                               # Start container / Запустить контейнер
podman stop app                                # Stop container / Остановить контейнер
podman restart app                             # Restart container / Перезапустить контейнер
podman rm app                                  # Remove container / Удалить контейнер
```

### Logs & Inspection

```bash
podman logs -f app                             # Follow logs / Следить за логами
podman logs --tail=100 app                     # Last 100 lines / Последние 100 строк
podman inspect app                             # Inspect container / Информация о контейнере
podman stats                                   # Resource usage / Использование ресурсов
podman top app                                 # Container processes / Процессы контейнера
```

### Execute & Attach

```bash
podman exec -it app /bin/sh                    # Shell in container / Оболочка в контейнере
podman attach app                              # Attach to container / Подключиться к контейнеру
```

### Image Management

```bash
podman images                                  # List images / Список образов
podman pull nginx                              # Pull image / Скачать образ
podman push myimg:tag                          # Push image / Отправить образ
podman rmi nginx                               # Remove image / Удалить образ
podman build -t myimg:tag .                    # Build image / Собрать образ
```

---

## Podman Rootless Mode

### User Setup

```bash
podman system migrate                          # Migrate to rootless / Миграция в rootless
loginctl enable-linger <USER>                  # Enable user lingering / Включить user lingering
```

### Rootless Commands

```bash
podman run --rm -it alpine                     # Run as user / Запуск от пользователя
podman system reset                            # Reset rootless storage / Сбросить rootless storage
podman info | grep -i root                     # Check root/rootless / Проверить root/rootless
```

### Port Mapping (Rootless)

```bash
podman run -d -p 8080:80 nginx                 # Port ≥ 1024 / Порт ≥ 1024
sudo sysctl net.ipv4.ip_unprivileged_port_start=80  # Allow ports < 1024 / Разрешить порты < 1024
```

---

## Podman Pods

### Pod Management

```bash
podman pod create --name mypod -p 8080:80      # Create pod / Создать pod
podman pod list                                # List pods / Список pod-ов
podman pod ps                                  # Running pods / Запущенные pod-ы
podman pod start mypod                         # Start pod / Запустить pod
podman pod stop mypod                          # Stop pod / Остановить pod
podman pod rm mypod                            # Remove pod / Удалить pod
```

### Add Containers to Pod

```bash
podman run -d --pod mypod nginx                # Add nginx to pod / Добавить nginx в pod
podman run -d --pod mypod redis                # Add redis to pod / Добавить redis в pod
```

### Generate Kubernetes YAML

```bash
podman generate kube mypod > mypod.yaml        # Generate K8s YAML / Сгенерировать K8s YAML
podman play kube mypod.yaml                    # Deploy from YAML / Развернуть из YAML
```

---

## Podman Systemd Integration

### Generate Systemd Unit

```bash
podman generate systemd --new --name app > ~/.config/systemd/user/app.service  # User service / Пользовательский сервис
systemctl --user daemon-reload                 # Reload systemd / Перезагрузить systemd
systemctl --user enable app                    # Enable on boot / Включить автозапуск
systemctl --user start app                     # Start service / Запустить сервис
systemctl --user status app                    # Check status / Проверить статус
```

### System-wide Service (Root)

```bash
podman generate systemd --new --name app > /etc/systemd/system/app.service  # System service / Системный сервис
systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable app                           # Enable on boot / Включить автозапуск
systemctl start app                            # Start service / Запустить сервис
```

---

## nerdctl Basics

### Container Management

nerdctl ps -a                                  # List containers / Список контейнеров
nerdctl run -d --name app -p 8080:80 nginx     # Run container / Запуск контейнера
nerdctl start app                              # Start container / Запустить контейнер
nerdctl stop app                               # Stop container / Остановить контейнер
nerdctl rm app                                 # Remove container / Удалить контейнер

### Logs & Execution

nerdctl logs -f app                            # Follow logs / Следить за логами
nerdctl exec -it app /bin/sh                   # Shell in container / Оболочка в контейнере

### Namespace Management

nerdctl namespace ls                           # List namespaces / Список namespace-ов
nerdctl -n k8s.io ps                           # Containers in k8s.io ns / Контейнеры в k8s.io ns
nerdctl -n default ps                          # Default namespace / Namespace по умолчанию

### BuildKit & Compose

nerdctl build -t myimg:tag .                   # Build with BuildKit / Сборка с BuildKit
nerdctl compose up -d                          # Docker Compose support / Поддержка Docker Compose
nerdctl compose down                           # Stop and remove / Остановить и удалить

---

## crictl (CRI Debugging)

### Pod & Container Inspection

crictl pods                                    # List pods / Список pod-ов
crictl ps                                      # List containers / Список контейнеров
crictl ps -a                                   # All containers / Все контейнеры
crictl inspect <CONTAINER_ID>                  # Inspect container / Информация о контейнере
crictl inspectp <POD_ID>                       # Inspect pod / Информация о pod-е

### Logs & Execution

crictl logs <CONTAINER_ID>                     # Container logs / Логи контейнера
crictl logs -f <CONTAINER_ID>                  # Follow logs / Следить за логами
crictl exec -it <CONTAINER_ID> /bin/sh         # Shell in container / Оболочка в контейнере

### Images

crictl images                                  # List images / Список образов
crictl pull nginx                              # Pull image / Скачать образ
crictl rmi <IMAGE_ID>                          # Remove image / Удалить образ

### Pod Lifecycle

crictl stopp <POD_ID>                          # Stop pod / Остановить pod
crictl rmp <POD_ID>                            # Remove pod / Удалить pod

---

## Sysadmin Essentials

### Podman Configuration

/etc/containers/registries.conf                # Registry config / Конфигурация реестров
/etc/containers/storage.conf                   # Storage config / Конфигурация хранилища
~/.config/containers/                          # User config dir / Директория конфигурации пользователя
/run/user/<UID>/podman/podman.sock             # Rootless socket / Rootless сокет
/run/podman/podman.sock                        # Root socket / Root сокет

### nerdctl Configuration

/etc/containerd/config.toml                    # containerd config / Конфигурация containerd
/run/containerd/containerd.sock                # containerd socket / containerd сокет

### crictl Configuration

/etc/crictl.yaml                               # crictl config / Конфигурация crictl

`/etc/crictl.yaml`

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

### Network Management

#### Podman Networks

```bash
podman network ls                              # List networks / Список сетей
podman network create mynet                    # Create network / Создать сеть
podman network inspect mynet                   # Inspect network / Информация о сети
podman network rm mynet                        # Remove network / Удалить сеть
```

#### nerdctl Networks

```bash
nerdctl network ls                             # List networks / Список сетей
nerdctl network create mynet                   # Create network / Создать сеть
nerdctl network inspect mynet                  # Inspect network / Информация о сети
```

### Volume Management

#### Podman Volumes

```bash
podman volume ls                               # List volumes / Список volumes
podman volume create myvol                     # Create volume / Создать volume
podman volume inspect myvol                    # Inspect volume / Информация о volume
podman volume rm myvol                         # Remove volume / Удалить volume
```

#### nerdctl Volumes

```bash
nerdctl volume ls                              # List volumes / Список volumes
nerdctl volume create myvol                    # Create volume / Создать volume
nerdctl volume inspect myvol                   # Inspect volume / Информация о volume
```

### Troubleshooting

```bash
# Check Podman version / Проверка версии Podman
podman --version

# Check containerd/nerdctl / Проверка containerd/nerdctl
nerdctl --version
containerd --version

# Podman system info / Информация о системе Podman
podman info

# Check CRI runtime / Проверка CRI runtime
crictl version

# Podman events / События Podman
podman events
```

> [!CAUTION]
> `podman system reset` permanently deletes ALL containers, images, and volumes. Use with extreme care.
> `podman system reset` безвозвратно удаляет ВСЕ контейнеры, образы и тома.

```bash
# Reset Podman storage / Сброс хранилища Podman
podman system reset

# Cleanup unused resources / Очистка неиспользуемых ресурсов
podman system prune -af
nerdctl system prune -af
```

### Performance & Differences vs Docker

**Podman advantages / Преимущества Podman:**
- Rootless by default / Rootless по умолчанию
- Daemonless architecture / Архитектура без демона
- Native systemd integration / Нативная интеграция с systemd
- Pod support (like K8s) / Поддержка pod-ов (как в K8s)

**nerdctl advantages / Преимущества nerdctl:**
- Docker-compatible CLI / Docker-совместимый CLI
- Native BuildKit support / Нативная поддержка BuildKit
- Kubernetes namespace awareness / Осведомлённость о namespace Kubernetes
- Lazy image pulling / Ленивая загрузка образов

---

## Logrotate Configuration

> [!NOTE]
> Podman is daemonless; logs are managed per-container or via journald.
> Podman без демона; логи управляются по контейнерам или через journald.

For containerd logs:

`/etc/logrotate.d/containerd`

```conf
/var/log/containerd/*.log {
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

