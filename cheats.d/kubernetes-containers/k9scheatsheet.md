Title: 🎛 k9s — Hotkeys
Group: Kubernetes & Containers
Icon: 🎛
Order: 8

## Table of Contents
- [Basic Navigation](#basic-navigation)
- [Resource Views](#resource-views)
- [Common Operations](#common-operations)
- [Filtering & Search](#filtering--search)
- [Context & Namespace](#context--namespace)
- [Sorting & Display](#sorting--display)
- [Advanced Features](#advanced-features)
- [Configuration](#configuration)

---

## Basic Navigation

```text
?                                              # Show help / Показать помощь
:q / Ctrl+c                                    # Quit k9s / Выйти из k9s
Esc                                            # Back to previous view / Назад к предыдущему виду
:alias                                         # Show command aliases / Показать алиасы команд
```

---

## Resource Views

```text
:pods / :po                                    # View pods / Просмотр pod-ов
:deployments / :deploy / :dp                   # View deployments / Просмотр deployment-ов
:services / :svc                               # View services / Просмотр сервисов
:ingresses / :ing                              # View ingresses / Просмотр ingress-ов
:nodes / :no                                   # View nodes / Просмотр узлов
:namespaces / :ns                              # View namespaces / Просмотр namespace-ов
:configmaps / :cm                              # View ConfigMaps / Просмотр ConfigMap-ов
:secrets / :sec                                # View secrets / Просмотр секретов
:persistentvolumes / :pv                       # View PV / Просмотр PersistentVolume
:persistentvolumeclaims / :pvc                 # View PVC / Просмотр PersistentVolumeClaim
:statefulsets / :sts                           # View StatefulSets / Просмотр StatefulSet-ов
:daemonsets / :ds                              # View DaemonSets / Просмотр DaemonSet-ов
:jobs                                          # View jobs / Просмотр задач
:cronjobs / :cj                                # View CronJobs / Просмотр CronJob-ов
:events / :ev                                  # View events / Просмотр событий
```

---

## Common Operations

```text
Enter                                          # View details / Просмотр деталей
d                                              # Describe resource / Описать ресурс
e                                              # Edit resource / Редактировать ресурс
v                                              # View YAML / Просмотр YAML
y                                              # View YAML (full) / Просмотр YAML (полный)

l                                              # View logs / Просмотр логов
L                                              # View logs (follow) / Просмотр логов (follow)
p                                              # Previous logs / Предыдущие логи

s                                              # Shell into container / Оболочка в контейнере
a                                              # Show all containers / Показать все контейнеры

x / Ctrl+k                                     # Delete resource (confirm) / Удалить ресурс (подтверждение)

r                                              # Refresh view / Обновить вид
Ctrl+r                                         # Refresh all views / Обновить все виды
```

---

## Filtering & Search

/                                              # Filter view / Фильтровать вид
/!                                             # Inverse filter / Обратный фильтр
/-                                             # Clear filter / Очистить фильтр

# Example filters / Примеры фильтров:
# /Running     → Show only Running pods / Показать только запущенные pod-ы
# /!Completed  → Exclude Completed pods / Исключить завершённые pod-ы
# /app=nginx   → Filter by label / Фильтр по label

Ctrl+s                                         # Save filter / Сохранить фильтр

---

## Context & Namespace

```text
:ctx                                           # Switch context / Сменить контекст
:ns                                            # Switch namespace / Сменить namespace

0                                              # Show all namespaces / Показать все namespace-ы
Ctrl+a                                         # Show all resources / Показать все ресурсы
```

---

## Sorting & Display

f                                              # Port forward / Проброс портов
n                                              # Cycle through namespaces / Переключение namespace-ов
u                                              # Show used resources / Показать используемые ресурсы

Shift+c                                        # Sort by CPU / Сортировка по CPU
Shift+m                                        # Sort by memory / Сортировка по памяти
Shift+n                                        # Sort by name / Сортировка по имени
Shift+t                                        # Sort by age / Сортировка по возрасту

w                                              # Toggle wide columns / Переключить широкие колонки
z                                              # Toggle error state / Переключить состояние ошибки

---

## Advanced Features

### Logs

l                                              # View logs / Просмотр логов
L                                              # Follow logs / Следить за логами
p                                              # Previous container logs / Логи предыдущего контейнера
c                                              # Copy logs / Копировать логи
s                                              # Toggle timestamps / Переключить временные метки
w                                              # Toggle wrap / Переключить перенос строк

### Port Forward

f                                              # Start port forward / Запустить проброс портов
# Format: local_port:remote_port / Формат: локальный_порт:удалённый_порт

### Resource Monitoring

t                                              # View resource tree / Просмотр дерева ресурсов
h                                              # Toggle header / Переключить заголовок
Ctrl+z                                         # Toggle errors only / Переключить только ошибки

### Labels & Annotations

Shift+l                                        # Show labels / Показать labels
Shift+f                                        # Toggle full screen / Переключить полноэкранный режим

---

## Configuration

### Config Location

```bash
~/.config/k9s/config.yml                       # Main config file / Основной файл конфигурации
~/.config/k9s/plugin.yml                       # Plugins config / Конфигурация плагинов
~/.config/k9s/hotkey.yml                       # Hotkeys config / Конфигурация горячих клавиш
~/.config/k9s/alias.yml                        # Aliases config / Конфигурация алиасов
```

### Sample ~/.config/k9s/config.yml

```yaml
k9s:
  refreshRate: 2
  maxConnRetry: 5
  enableMouse: false
  headless: false
  logoless: false
  crumbsless: false
  readOnly: false
  noIcons: false
  logger:
    tail: 200
    buffer: 500
    sinceSeconds: 300
    fullScreen: false
    textWrap: false
    showTime: false
```

### Useful Tips

```bash
# Read-only mode / Режим только для чтения
k9s --readonly

# Start with specific namespace / Запуск с конкретным namespace
k9s -n kube-system

# Start with specific context / Запуск с конкретным контекстом
k9s --context <CONTEXT_NAME>
```

### Command Mode Shortcuts

```text
:xray deploy                                   # Show deployment dependencies / Показать зависимости deployment
:popeye                                        # Run cluster sanitizer / Запустить очистку кластера
:pulse                                         # Show cluster metrics / Показать метрики кластера
```
