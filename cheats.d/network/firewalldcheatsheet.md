Title: 🔥 firewalld — Firewall Management
Group: Network
Icon: 🔥
Order: 12

## Table of Contents
- [Installation & Configuration](#-installation--configuration--установка-и-настройка)
- [Basic Commands](#-basic-commands--базовые-команды)
- [Zone Management](#-zone-management--управление-зонами)
- [Service Management](#-service-management--управление-сервисами)
- [Port Management](#-port-management--управление-портами)
- [Rich Rules](#-rich-rules--сложные-правила)
- [Direct Rules](#-direct-rules--прямые-правила)
- [Masquerading & Port Forwarding](#-masquerading--port-forwarding--маскарадинг-и-проброс-портов)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 📦 Installation & Configuration / Установка и настройка

### Installation / Установка
```bash
sudo dnf install firewalld              # RHEL/Fedora
sudo apt install firewalld              # Debian/Ubuntu
```

### Service Management / Управление сервисом
```bash
sudo systemctl start firewalld          # Start service / Запустить сервис
sudo systemctl stop firewalld           # Stop service / Остановить сервис
sudo systemctl enable firewalld         # Enable on boot / Включить при загрузке
sudo systemctl disable firewalld        # Disable on boot / Отключить при загрузке
sudo systemctl status firewalld         # Check status / Проверить статус
sudo firewall-cmd --state               # Check daemon state / Проверить состояние демона
```

---

# 🔧 Basic Commands / Базовые команды

### General Information / Общая информация
```bash
sudo firewall-cmd --state               # Daemon state / Состояние демона
sudo firewall-cmd --get-default-zone    # Get default zone / Получить зону по умолчанию
sudo firewall-cmd --set-default-zone=<ZONE>  # Set default zone / Установить зону по умолчанию
sudo firewall-cmd --get-active-zones    # Active zones / Активные зоны
sudo firewall-cmd --get-zones           # List all zones / Список всех зон
sudo firewall-cmd --get-services        # Predefined services / Предустановленные сервисы
sudo firewall-cmd --reload              # Reload firewall / Перезагрузить файрвол
sudo firewall-cmd --complete-reload     # Full reload (drops connections) / Полная перезагрузка
sudo firewall-cmd --runtime-to-permanent  # Save runtime rules / Сохранить runtime правила
```

---

# 🛡️ Zone Management / Управление зонами

### Zone Information / Информация о зонах
```bash
sudo firewall-cmd --get-zones           # List all zones / Список всех зон
sudo firewall-cmd --list-all            # List default zone rules / Список правил зоны по умолчанию
sudo firewall-cmd --zone=<ZONE> --list-all  # List specific zone rules / Список правил конкретной зоны
sudo firewall-cmd --get-active-zones    # Show active zones / Показать активные зоны
```

### Default Zones / Зоны по умолчанию
```bash
# drop      — Drop all incoming, allow outgoing / Отбросить входящий, разрешить исходящий
# block     — Reject with ICMP error / Отклонить с ICMP ошибкой
# public    — Default, selective incoming / По умолчанию, выборочный входящий
# external  — For external use (masquerading) / Для внешнего использования (маскарадинг)
# dmz       — DMZ zone, limited incoming / DMZ зона, ограниченный входящий
# work      — Work environments / Рабочие окружения
# home      — Home networks / Домашние сети
# internal  — Internal networks / Внутренние сети
# trusted   — Accept all / Доверенная (принять всё)
```

### Zone Operations / Операции с зонами
```bash
sudo firewall-cmd --new-zone=<ZONE> --permanent  # Create new zone / Создать новую зону
sudo firewall-cmd --delete-zone=<ZONE> --permanent  # Delete zone / Удалить зону
sudo firewall-cmd --zone=<ZONE> --change-interface=<INTERFACE>  # Assign interface to zone / Назначить интерфейс зоне
sudo firewall-cmd --zone=<ZONE> --add-source=<IP>/24  # Add source to zone / Добавить источник в зону
sudo firewall-cmd --zone=<ZONE> --remove-source=<IP>/24  # Remove source / Удалить источник
```

---

# 🌐 Service Management / Управление сервисами

### Add/Remove Services / Добавить/Удалить сервисы
```bash
sudo firewall-cmd --zone=<ZONE> --add-service=<SERVICE>  # Add service (runtime) / Добавить сервис (runtime)
sudo firewall-cmd --zone=<ZONE> --add-service=<SERVICE> --permanent  # Add service (permanent) / Добавить сервис (постоянно)
sudo firewall-cmd --zone=<ZONE> --remove-service=<SERVICE>  # Remove service / Удалить сервис
sudo firewall-cmd --zone=<ZONE> --remove-service=<SERVICE> --permanent  # Remove permanent / Удалить постоянно
```

### Common Services / Распространённые сервисы
```bash
sudo firewall-cmd --zone=public --add-service=ssh --permanent  # Allow SSH / Разрешить SSH
sudo firewall-cmd --zone=public --add-service=http --permanent  # Allow HTTP / Разрешить HTTP
sudo firewall-cmd --zone=public --add-service=https --permanent  # Allow HTTPS / Разрешить HTTPS
sudo firewall-cmd --zone=public --add-service=mysql --permanent  # Allow MySQL / Разрешить MySQL
sudo firewall-cmd --zone=public --add-service=postgresql --permanent  # Allow PostgreSQL / Разрешить PostgreSQL
sudo firewall-cmd --zone=public --add-service=dns --permanent  # Allow DNS / Разрешить DNS
```

### List Services / Список сервисов
```bash
sudo firewall-cmd --get-services        # List all available services / Список всех доступных сервисов
sudo firewall-cmd --zone=<ZONE> --list-services  # List enabled services in zone / Список включённых сервисов в зоне
```

---

# 🔌 Port Management / Управление портами

### Add/Remove Ports / Добавить/Удалить порты
```bash
sudo firewall-cmd --zone=<ZONE> --add-port=<PORT>/<PROTOCOL>  # Add port (runtime) / Добавить порт (runtime)
sudo firewall-cmd --zone=<ZONE> --add-port=<PORT>/<PROTOCOL> --permanent  # Add port (permanent) / Добавить порт (постоянно)
sudo firewall-cmd --zone=<ZONE> --remove-port=<PORT>/<PROTOCOL>  # Remove port / Удалить порт
sudo firewall-cmd --zone=<ZONE> --remove-port=<PORT>/<PROTOCOL> --permanent  # Remove permanent / Удалить постоянно
```

### Port Range / Диапазон портов
```bash
sudo firewall-cmd --zone=<ZONE> --add-port=8000-9000/tcp --permanent  # Add port range / Добавить диапазон портов
```

### Common Ports Examples / Примеры распространённых портов
```bash
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent  # SSH port / Порт SSH
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent  # HTTP port / Порт HTTP
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent  # HTTPS port / Порт HTTPS
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent  # MySQL port / Порт MySQL
sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent  # PostgreSQL port / Порт PostgreSQL
sudo firewall-cmd --zone=public --add-port=6379/tcp --permanent  # Redis port / Порт Redis
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent  # Custom HTTP / Пользовательский HTTP
```

### List Ports / Список портов
```bash
sudo firewall-cmd --zone=<ZONE> --list-ports  # List open ports / Список открытых портов
```

---

# 🎯 Rich Rules / Сложные правила

### Rich Rule Syntax / Синтаксис сложных правил
```bash
sudo firewall-cmd --zone=<ZONE> --add-rich-rule='<RULE>' --permanent  # Add rich rule / Добавить сложное правило
```

### Rich Rule Examples / Примеры сложных правил
```bash
# Allow SSH from specific IP / Разрешить SSH с конкретного IP
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" service name="ssh" accept' --permanent

# Block specific IP / Заблокировать конкретный IP
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" reject' --permanent

# Allow port from subnet / Разрешить порт с подсети
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>/24" port port="8080" protocol="tcp" accept' --permanent

# Rate limit SSH / Ограничить частоту SSH
sudo firewall-cmd --zone=public --add-rich-rule='rule service name="ssh" limit value="10/m" accept' --permanent

# Log dropped packets / Логировать отброшенные пакеты
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<IP>" log prefix="DROPPED: " level="info" drop' --permanent
```

### List Rich Rules / Список сложных правил
```bash
sudo firewall-cmd --zone=<ZONE> --list-rich-rules  # List all rich rules / Список всех сложных правил
```

---

# ⚡ Direct Rules / Прямые правила

### Direct Rule Management / Управление прямыми правилами
```bash
sudo firewall-cmd --direct --add-rule ipv4 filter INPUT 0 -p tcp --dport 9000 -j ACCEPT  # Add direct rule / Добавить прямое правило
sudo firewall-cmd --direct --get-all-rules  # List all direct rules / Список всех прямых правил
sudo firewall-cmd --direct --remove-rule ipv4 filter INPUT 0 -p tcp --dport 9000 -j ACCEPT  # Remove direct rule / Удалить прямое правило
```

---

# 🔀 Masquerading & Port Forwarding / Маскарадинг и проброс портов

### Masquerading / Маскарадинг
```bash
sudo firewall-cmd --zone=<ZONE> --add-masquerade  # Enable masquerading (runtime) / Включить маскарадинг (runtime)
sudo firewall-cmd --zone=<ZONE> --add-masquerade --permanent  # Enable permanent / Включить постоянно
sudo firewall-cmd --zone=<ZONE> --remove-masquerade  # Disable masquerading / Отключить маскарадинг
sudo firewall-cmd --zone=<ZONE> --query-masquerade  # Check if enabled / Проверить включён ли
```

### Port Forwarding / Проброс портов
```bash
sudo firewall-cmd --zone=<ZONE> --add-forward-port=port=<PORT>:proto=<PROTOCOL>:toport=<TARGET_PORT>  # Forward to local port / Перенаправить на локальный порт
sudo firewall-cmd --zone=<ZONE> --add-forward-port=port=<PORT>:proto=<PROTOCOL>:toaddr=<IP>:toport=<TARGET_PORT>  # Forward to remote / Перенаправить на удалённый
```

### Examples / Примеры
```bash
# Forward port 80 to 8080 / Перенаправить порт 80 на 8080
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent

# Forward port 443 to internal server / Перенаправить порт 443 на внутренний сервер
sudo firewall-cmd --zone=external --add-forward-port=port=443:proto=tcp:toaddr=<INTERNAL_IP>:toport=443 --permanent
```

---

# 🐛 Troubleshooting / Устранение неполадок

### Check Configuration / Проверка конфигурации
```bash
sudo firewall-cmd --check-config        # Validate configuration / Проверить конфигурацию
sudo firewall-cmd --list-all-zones      # List all zone configurations / Список всех конфигураций зон
sudo firewall-cmd --get-log-denied      # Check log denied setting / Проверить настройку логирования отклонённых
sudo firewall-cmd --set-log-denied=all  # Enable logging denied / Включить логирование отклонённых
```

### View Logs / Просмотр логов
```bash
sudo journalctl -u firewalld            # View firewalld logs / Просмотр логов firewalld
sudo journalctl -u firewalld -f         # Follow firewalld logs / Следовать за логами firewalld
sudo journalctl -k | grep -i firewall   # Kernel firewall messages / Сообщения файрвола ядра
```

### Debug Mode / Режим отладки
```bash
sudo firewall-cmd --set-log-denied=all  # Log all denied packets / Логировать все отброшенные пакеты
sudo firewall-cmd --get-log-denied      # Check current log setting / Проверить текущую настройку логов
```

---

# 🌟 Real-World Examples / Примеры из практики

### Web Server Setup / Настройка веб-сервера
```bash
# Allow HTTP and HTTPS / Разрешить HTTP и HTTPS
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
```

### Database Server Setup / Настройка сервера БД
```bash
# Allow MySQL only from app server / Разрешить MySQL только с сервера приложений
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<APP_SERVER_IP>" service name="mysql" accept' --permanent
sudo firewall-cmd --reload
```

### NAT Gateway Setup / Настройка NAT шлюза
```bash
# Enable masquerading for external zone / Включить маскарадинг для внешней зоны
sudo firewall-cmd --zone=external --add-masquerade --permanent
sudo firewall-cmd --zone=internal --set-target=ACCEPT --permanent
sudo firewall-cmd --reload
```

### SSH Lockdown / Ограничение SSH
```bash
# Allow SSH only from management subnet / Разрешить SSH только с управленческой подсети
sudo firewall-cmd --zone=public --remove-service=ssh --permanent
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<MGMT_SUBNET>/24" service name="ssh" accept' --permanent
sudo firewall-cmd --reload
```

### Development Environment / Среда разработки
```bash
# Open common development ports / Открыть распространённые порты разработки
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent  # Node.js
sudo firewall-cmd --zone=public --add-port=8000/tcp --permanent  # Django
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent  # Tomcat
sudo firewall-cmd --zone=public --add-port=9000/tcp --permanent  # PHP-FPM
sudo firewall-cmd --reload
```

# 💡 Best Practices / Лучшие практики
# Always use --permanent for production / Всегда используйте --permanent для продакшена
# Reload after making changes / Перезагружайте после внесения изменений
# Use zones to organize rules / Используйте зоны для организации правил
# Test rules before making permanent / Тестируйте правила перед постоянным применением
# Use rich rules for complex scenarios / Используйте сложные правила для сложных сценариев
# Log denied packets for troubleshooting / Логируйте отклонённые пакеты для отладки
# Keep default zone restrictive / Держите зону по умолчанию строгой

# 🔧 Configuration Files / Файлы конфигурации
```bash
# /etc/firewalld/firewalld.conf                    — Main configuration / Основная конфигурация
# /etc/firewalld/zones/                             — Zone definitions / Определения зон
# /etc/firewalld/services/                          — Service definitions / Определения сервисов
```

# 📋 Common Ports / Распространённые порты
```bash
# SSH: 22/tcp, HTTP: 80/tcp, HTTPS: 443/tcp
# MySQL: 3306/tcp, PostgreSQL: 5432/tcp
# Redis: 6379/tcp, MongoDB: 27017/tcp
# DNS: 53/udp, NTP: 123/udp
```
