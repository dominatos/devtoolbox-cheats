---
Title: Podman / nerdctl — Commands
Group: Kubernetes & Containers
Icon: 🫙
Order: 7
---

# 🫙 Podman / nerdctl / crictl — Container Runtimes & Tools

**Description / Описание:**
This cheatsheet covers three container management tools: **Podman** — a daemonless, rootless container engine (drop-in Docker replacement); **nerdctl** — a Docker-compatible CLI for containerd; and **crictl** — a debugging tool for CRI-compatible container runtimes. Together, they represent the modern container runtime ecosystem beyond Docker.

**Podman** is developed by Red Hat and runs containers without a central daemon, supports rootless mode natively, integrates with systemd, and can manage pods (similar to Kubernetes). **nerdctl** provides Docker CLI compatibility on top of containerd (the runtime used by Kubernetes). **crictl** is used for low-level debugging of CRI runtimes on Kubernetes nodes.

> [!NOTE]
> **Current Status:** All three tools are actively maintained. **Podman** is the default container runtime on RHEL/Fedora and a primary Docker alternative. **nerdctl** is a CNCF project gaining adoption in containerd-based environments. **crictl** is part of the `cri-tools` project for Kubernetes node debugging. Docker remains dominant for development, but Podman and nerdctl are preferred in many production and security-conscious environments. / **Текущий статус:** Все три инструмента активно поддерживаются. **Podman** — замена Docker по умолчанию в RHEL/Fedora. **nerdctl** — CLI для containerd. **crictl** — для отладки CRI на нодах Kubernetes.

---

## Table of Contents

- [Podman Basics](#podman-basics)
- [Podman Rootless Mode](#podman-rootless-mode)
- [Podman Pods](#podman-pods)
- [Podman Systemd Integration](#podman-systemd-integration)
- [nerdctl Basics](#nerdctl-basics)
- [crictl (CRI Debugging)](#crictl-cri-debugging)
- [Sysadmin Essentials](#sysadmin-essentials)
- [Logrotate Configuration](#logrotate-configuration)
- [Documentation Links](#documentation-links)

---

## Podman Basics

### Container Management / Управление контейнерами

```bash
podman ps -a                                   # List containers / Список контейнеров
podman run -d --name app -p 8080:80 nginx      # Run container / Запуск контейнера
podman start app                               # Start container / Запустить контейнер
podman stop app                                # Stop container / Остановить контейнер
podman restart app                             # Restart container / Перезапустить контейнер
podman rm app                                  # Remove container / Удалить контейнер
```

### Logs & Inspection / Логи и инспекция

```bash
podman logs -f app                             # Follow logs / Следить за логами
podman logs --tail=100 app                     # Last 100 lines / Последние 100 строк
podman inspect app                             # Inspect container / Информация о контейнере
podman stats                                   # Resource usage / Использование ресурсов
podman top app                                 # Container processes / Процессы контейнера
```

### Execute & Attach / Выполнение и подключение

```bash
podman exec -it app /bin/sh                    # Shell in container / Оболочка в контейнере
podman attach app                              # Attach to container / Подключиться к контейнеру
```

### Image Management / Управление образами

```bash
podman images                                  # List images / Список образов
podman pull nginx                              # Pull image / Скачать образ
podman push myimg:tag                          # Push image / Отправить образ
podman rmi nginx                               # Remove image / Удалить образ
podman build -t myimg:tag .                    # Build image / Собрать образ
```

---

## Podman Rootless Mode

### User Setup / Настройка пользователя

```bash
podman system migrate                          # Migrate to rootless / Миграция в rootless
loginctl enable-linger <USER>                  # Enable user lingering / Включить user lingering
```

> [!NOTE]
> `loginctl enable-linger` allows user systemd services to run even when the user is not logged in. This is required for rootless container auto-start. / `loginctl enable-linger` позволяет пользовательским сервисам systemd работать без активной сессии.

### Rootless Commands / Команды Rootless

```bash
podman run --rm -it alpine                     # Run as user / Запуск от пользователя
podman system reset                            # Reset rootless storage / Сбросить rootless storage
podman info | grep -i root                     # Check root/rootless / Проверить root/rootless
```

### Port Mapping (Rootless) / Маппинг портов (Rootless)

```bash
podman run -d -p 8080:80 nginx                 # Port ≥ 1024 / Порт ≥ 1024
sudo sysctl net.ipv4.ip_unprivileged_port_start=80  # Allow ports < 1024 / Разрешить порты < 1024
```

> [!TIP]
> Rootless containers can only bind to ports ≥ 1024 by default. Use `sysctl` to lower the threshold or use port forwarding. / Rootless-контейнеры по умолчанию могут использовать порты ≥ 1024.

---

## Podman Pods

### Pod Management / Управление pod-ами

```bash
podman pod create --name mypod -p 8080:80      # Create pod / Создать pod
podman pod list                                # List pods / Список pod-ов
podman pod ps                                  # Running pods / Запущенные pod-ы
podman pod start mypod                         # Start pod / Запустить pod
podman pod stop mypod                          # Stop pod / Остановить pod
podman pod rm mypod                            # Remove pod / Удалить pod
```

### Add Containers to Pod / Добавить контейнеры в pod

```bash
podman run -d --pod mypod nginx                # Add nginx to pod / Добавить nginx в pod
podman run -d --pod mypod redis                # Add redis to pod / Добавить redis в pod
```

### Generate Kubernetes YAML / Сгенерировать Kubernetes YAML

```bash
podman generate kube mypod > mypod.yaml        # Generate K8s YAML / Сгенерировать K8s YAML
podman play kube mypod.yaml                    # Deploy from YAML / Развернуть из YAML
```

> [!TIP]
> `podman generate kube` + `podman play kube` enables local development with Podman pods, then deploying the same YAML to Kubernetes. / `podman generate kube` + `podman play kube` позволяют разрабатывать локально и деплоить тот же YAML в Kubernetes.

---

## Podman Systemd Integration

### Generate Systemd Unit (User Service) / Генерация Systemd юнита (пользовательский)

```bash
podman generate systemd --new --name app > ~/.config/systemd/user/app.service  # User service / Пользовательский сервис
systemctl --user daemon-reload                 # Reload systemd / Перезагрузить systemd
systemctl --user enable app                    # Enable on boot / Включить автозапуск
systemctl --user start app                     # Start service / Запустить сервис
systemctl --user status app                    # Check status / Проверить статус
```

### System-wide Service (Root) / Системный сервис (Root)

```bash
podman generate systemd --new --name app > /etc/systemd/system/app.service  # System service / Системный сервис
systemctl daemon-reload                        # Reload systemd / Перезагрузить systemd
systemctl enable app                           # Enable on boot / Включить автозапуск
systemctl start app                            # Start service / Запустить сервис
```

> [!IMPORTANT]
> `podman generate systemd` is being replaced by **Quadlet** in Podman 4.4+. Quadlet uses `.container`, `.volume`, and `.network` unit files natively understood by systemd. / `podman generate systemd` заменяется **Quadlet** в Podman 4.4+. Quadlet использует `.container`-файлы, нативно поддерживаемые systemd.

---

## nerdctl Basics

### Container Management / Управление контейнерами

```bash
nerdctl ps -a                                  # List containers / Список контейнеров
nerdctl run -d --name app -p 8080:80 nginx     # Run container / Запуск контейнера
nerdctl start app                              # Start container / Запустить контейнер
nerdctl stop app                               # Stop container / Остановить контейнер
nerdctl rm app                                 # Remove container / Удалить контейнер
```

### Logs & Execution / Логи и выполнение

```bash
nerdctl logs -f app                            # Follow logs / Следить за логами
nerdctl exec -it app /bin/sh                   # Shell in container / Оболочка в контейнере
```

### Namespace Management / Управление namespace-ами

```bash
nerdctl namespace ls                           # List namespaces / Список namespace-ов
nerdctl -n k8s.io ps                           # Containers in k8s.io ns / Контейнеры в k8s.io ns
nerdctl -n default ps                          # Default namespace / Namespace по умолчанию
```

> [!NOTE]
> nerdctl namespaces are **containerd namespaces**, not Kubernetes namespaces. The `k8s.io` namespace contains containers managed by Kubernetes. / Namespace-ы nerdctl — это namespace-ы **containerd**, а не Kubernetes.

### BuildKit & Compose / BuildKit и Compose

```bash
nerdctl build -t myimg:tag .                   # Build with BuildKit / Сборка с BuildKit
nerdctl compose up -d                          # Docker Compose support / Поддержка Docker Compose
nerdctl compose down                           # Stop and remove / Остановить и удалить
```

---

## crictl (CRI Debugging)

> [!IMPORTANT]
> `crictl` is designed for **debugging CRI-compatible runtimes** on Kubernetes nodes. It is NOT a replacement for Docker/Podman for running containers. / `crictl` предназначен для **отладки CRI-совместимых рантаймов** на нодах Kubernetes. Это НЕ замена Docker/Podman.

### Pod & Container Inspection / Инспекция pod-ов и контейнеров

```bash
crictl pods                                    # List pods / Список pod-ов
crictl ps                                      # List containers / Список контейнеров
crictl ps -a                                   # All containers / Все контейнеры
crictl inspect <CONTAINER_ID>                  # Inspect container / Информация о контейнере
crictl inspectp <POD_ID>                       # Inspect pod / Информация о pod-е
```

### Logs & Execution / Логи и выполнение

```bash
crictl logs <CONTAINER_ID>                     # Container logs / Логи контейнера
crictl logs -f <CONTAINER_ID>                  # Follow logs / Следить за логами
crictl exec -it <CONTAINER_ID> /bin/sh         # Shell in container / Оболочка в контейнере
```

### Images / Образы

```bash
crictl images                                  # List images / Список образов
crictl pull nginx                              # Pull image / Скачать образ
crictl rmi <IMAGE_ID>                          # Remove image / Удалить образ
```

### Pod Lifecycle / Жизненный цикл pod-ов

```bash
crictl stopp <POD_ID>                          # Stop pod / Остановить pod
crictl rmp <POD_ID>                            # Remove pod / Удалить pod
```

> [!CAUTION]
> Manually stopping/removing pods via `crictl` bypasses Kubernetes. The kubelet will likely recreate them. Use `kubectl` for pod management. / Ручная остановка pod-ов через `crictl` обходит Kubernetes. Kubelet их пересоздаст.

---

## Sysadmin Essentials

### Podman Configuration / Конфигурация Podman

| Path / Путь | Description / Описание |
| :--- | :--- |
| `/etc/containers/registries.conf` | Registry config / Конфигурация реестров |
| `/etc/containers/storage.conf` | Storage config / Конфигурация хранилища |
| `~/.config/containers/` | User config dir / Директория конфигурации пользователя |
| `/run/user/<UID>/podman/podman.sock` | Rootless socket / Rootless сокет |
| `/run/podman/podman.sock` | Root socket / Root сокет |

### nerdctl Configuration / Конфигурация nerdctl

| Path / Путь | Description / Описание |
| :--- | :--- |
| `/etc/containerd/config.toml` | containerd config / Конфигурация containerd |
| `/run/containerd/containerd.sock` | containerd socket / containerd сокет |

### crictl Configuration / Конфигурация crictl

`/etc/crictl.yaml`

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

### Network Management / Управление сетью

#### Podman Networks / Сети Podman

```bash
podman network ls                              # List networks / Список сетей
podman network create mynet                    # Create network / Создать сеть
podman network inspect mynet                   # Inspect network / Информация о сети
podman network rm mynet                        # Remove network / Удалить сеть
```

#### nerdctl Networks / Сети nerdctl

```bash
nerdctl network ls                             # List networks / Список сетей
nerdctl network create mynet                   # Create network / Создать сеть
nerdctl network inspect mynet                  # Inspect network / Информация о сети
```

### Volume Management / Управление томами

#### Podman Volumes / Тома Podman

```bash
podman volume ls                               # List volumes / Список volumes
podman volume create myvol                     # Create volume / Создать volume
podman volume inspect myvol                    # Inspect volume / Информация о volume
podman volume rm myvol                         # Remove volume / Удалить volume
```

#### nerdctl Volumes / Тома nerdctl

```bash
nerdctl volume ls                              # List volumes / Список volumes
nerdctl volume create myvol                    # Create volume / Создать volume
nerdctl volume inspect myvol                   # Inspect volume / Информация о volume
```

### Troubleshooting / Устранение неполадок

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

### Performance & Differences vs Docker / Производительность и отличия от Docker

#### Podman advantages / Преимущества Podman

| Feature | Description (EN / RU) |
| :--- | :--- |
| Rootless by default | No daemon, runs as regular user / Без демона, работает от обычного пользователя |
| Daemonless architecture | No single point of failure / Нет единой точки отказа |
| Native systemd integration | Generate `.service` units directly / Генерация юнитов `.service` напрямую |
| Pod support | Pod concept similar to K8s / Концепция pod как в K8s |
| Fork/exec model | Each container is a child process / Каждый контейнер — дочерний процесс |

#### nerdctl advantages / Преимущества nerdctl

| Feature | Description (EN / RU) |
| :--- | :--- |
| Docker-compatible CLI | Drop-in replacement / Совместимый CLI |
| Native BuildKit support | Fast, efficient builds / Быстрые сборки |
| K8s namespace awareness | Access `k8s.io` namespace containers / Доступ к контейнерам namespace `k8s.io` |
| Lazy image pulling | Faster container starts / Быстрый запуск контейнеров |
| containerd-native | Same runtime as Kubernetes / Тот же рантайм, что и Kubernetes |

---

## Logrotate Configuration

> [!NOTE]
> Podman is daemonless; logs are managed per-container or via journald.
> Podman без демона; логи управляются по контейнерам или через journald.

For containerd logs: / Для логов containerd:

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

## Documentation Links

- **Podman Official Documentation:** [https://docs.podman.io/](https://docs.podman.io/)
- **Podman GitHub Repository:** [https://github.com/containers/podman](https://github.com/containers/podman)
- **Podman Desktop (GUI):** [https://podman-desktop.io/](https://podman-desktop.io/)
- **nerdctl GitHub Repository:** [https://github.com/containerd/nerdctl](https://github.com/containerd/nerdctl)
- **containerd Official Documentation:** [https://containerd.io/docs/](https://containerd.io/docs/)
- **crictl (cri-tools) GitHub:** [https://github.com/kubernetes-sigs/cri-tools](https://github.com/kubernetes-sigs/cri-tools)
- **Quadlet (Podman systemd):** [https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- **Buildah (OCI image builder):** [https://buildah.io/](https://buildah.io/)
