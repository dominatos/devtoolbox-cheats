Title: 🛡️ SELinux & AppArmor — Security Modules
Group: System & Logs
Icon: 🛡️
Order: 7

## Table of Contents
- [SELinux](#-selinux)
- [AppArmor](#-apparmor)
- [Troubleshooting](#-troubleshooting--устранение-неполадок)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔐 SELinux

### Check Status / Проверить статус
getenforce                                    # Current mode / Текущий режим
sestatus                                      # Detailed status / Подробный статус
sestatus -v                                   # Verbose status / Подробный статус

### Change Mode / Изменить режим
sudo setenforce 0                             # Permissive (temporary) / Разрешительный (временно)
sudo setenforce 1                             # Enforcing (temporary) / Принудительный (временно)

### Modes / Режимы
# Enforcing: SELinux enforces policy / Принудительный: SELinux применяет политику
# Permissive: SELinux logs violations / Разрешительный: SELinux логирует нарушения
# Disabled: SELinux is off / Отключен: SELinux выключен

### Permanent Mode Change / Постоянное изменение режима
```bash
# Edit /etc/selinux/config / Редактировать /etc/selinux/config
sudo vi /etc/selinux/config
# SELINUX=enforcing|permissive|disabled
sudo reboot
```

### Check Contexts / Проверить контексты
ls -Z /path/to/file                           # File context / Контекст файла
ps -eZ                                        # Process contexts / Контексты процессов
id -Z                                         # User context / Контекст пользователя
netstat -Z                                    # Network contexts / Контексты сети
ss -Z                                         # Socket contexts / Контексты сокетов

### Change Contexts / Изменить контексты
sudo chcon -t httpd_sys_content_t /var/www/html/file  # Change file type / Изменить тип файла
sudo chcon -R -t httpd_sys_content_t /var/www/html    # Recursive / Рекурсивно
sudo restorecon -v /var/www/html/file         # Restore default context / Восстановить контекст по умолчанию
sudo restorecon -R -v /var/www/html           # Recursive restore / Рекурсивное восстановление

### Booleans / Булевы значения
getsebool -a                                  # List all booleans / Список всех булевых
getsebool httpd_can_network_connect           # Check specific boolean / Проверить конкретное булево
sudo setsebool httpd_can_network_connect on   # Enable (temporary) / Включить (временно)
sudo setsebool -P httpd_can_network_connect on  # Enable (permanent) / Включить (постоянно)

### Audit Logs / Логи аудита
sudo ausearch -m avc -ts recent               # Recent AVC denials / Недавние AVC отказы
sudo ausearch -m avc -ts today                # Today's denials / Сегодняшние отказы
sudo sealert -a /var/log/audit/audit.log      # Analyze audit log / Анализ лога аудита
sudo grep 'avc: denied' /var/log/audit/audit.log  # Find denials / Найти отказы

### Policy Management / Управление политикой
sudo semodule -l                              # List modules / Список модулей
sudo semodule -i my-policy.pp                 # Install module / Установить модуль
sudo semodule -r my-policy                    # Remove module / Удалить модуль

---

# 🛡️ AppArmor

### Check Status / Проверить статус
sudo aa-status                                # AppArmor status / Статус AppArmor
sudo apparmor_status                          # Alternative / Альтернатива

### Profile Modes / Режимы профилей
sudo aa-enforce /usr/sbin/nginx               # Enforce mode / Режим enforce
sudo aa-complain /usr/sbin/nginx              # Complain mode / Режим complain
sudo aa-disable /usr/sbin/nginx               # Disable profile / Отключить профиль

### Manage Profiles / Управление профилями
sudo aa-unconfined                            # List unconfined processes / Список процессов без профиля
ls /etc/apparmor.d/                           # List profiles / Список профилей
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx  # Reload profile / Перезагрузить профиль

### Log Analysis / Анализ логов
sudo aa-logprof                               # Interactive log analysis / Интерактивный анализ логов
sudo aa-genprof /usr/bin/myapp                # Generate profile / Генерировать профиль
sudo grep 'apparmor="DENIED"' /var/log/syslog  # Find denials / Найти отказы

### Create Profile / Создать профиль
```bash
# Generate profile / Генерировать профиль
sudo aa-genprof /usr/bin/myapp

# 1. Put in complain mode / 1. Переключить в режим complain
# 2. Run the application / 2. Запустить приложение
# 3. Scan logs with aa-logprof / 3. Сканировать логи с aa-logprof
# 4. Allow/deny accesses / 4. Разрешить/запретить доступы
# 5. Save profile / 5. Сохранить профиль
```

---

# 🔧 Troubleshooting / Устранение неполадок

### SELinux Denials / SELinux отказы
```bash
# Check denials / Проверить отказы
sudo ausearch -m avc -ts recent

# Generate policy / Генерировать политику
sudo audit2allow -a                           # Show rules / Показать правила
sudo audit2allow -a -M my-policy              # Create module / Создать модуль
sudo semodule -i my-policy.pp                 # Install module / Установить модуль
```

### Common SELinux Fixes / Распространённые исправления SELinux
```bash
# Web server can't access files / Веб сервер не может получить доступ к файлам
sudo restorecon -R -v /var/www/html

# Web server can't connect to network / Веб сервер не может подключиться к сети
sudo setsebool -P httpd_can_network_connect on

# Web server can't send mail / Веб сервер не может отправлять почту
sudo setsebool -P httpd_can_sendmail on
```

### AppArmor Denials / AppArmor отказы
```bash
# Check denials / Проверить отказы
sudo grep 'apparmor="DENIED"' /var/log/syslog | tail

# Switch to complain mode / Переключить в режим complain
sudo aa-complain /usr/sbin/nginx

# Test / Тест
# ... run application ...

# Update profile / Обновить профиль
sudo aa-logprof
```

---

# 🌟 Real-World Examples / Примеры из практики

### Enable SELinux for Nginx / Включить SELinux для Nginx
```bash
# Check status / Проверить статус
getenforce

# Allow network connections / Разрешить сетевые соединения
sudo setsebool -P httpd_can_network_connect on

# Allow proxy connections / Разрешить прокси соединения
sudo setsebool -P httpd_can_network_relay on

# Fix file contexts / Исправить контексты файлов
sudo restorecon -R -v /var/www/html
sudo restorecon -R -v /etc/nginx
```

### AppArmor for Custom Application / AppArmor для пользовательского приложения
```bash
# Generate profile / Генерировать профиль
sudo aa-genprof /usr/local/bin/myapp

# Run application / Запустить приложение
/usr/local/bin/myapp

# Scan logs / Сканировать логи
sudo aa-logprof

# Enforce profile / Применить профиль
sudo aa-enforce /usr/local/bin/myapp
```

### Debug SELinux Issues / Отладка проблем SELinux
```bash
# Set to permissive / Установить в permissive
sudo setenforce 0

# Test application / Тестировать приложение
# ... application works now ...

# Check audit log / Проверить лог аудита
sudo sealert -a /var/log/audit/audit.log

# Fix issues / Исправить проблемы
sudo restorecon -R -v /path/to/files
sudo setsebool -P some_boolean on

# Re-enable enforcing / Включить enforcing снова
sudo setenforce 1
```

### Container SELinux / SELinux для контейнеров
```bash
# Docker container contexts / Контексты Docker контейнеров
ls -Z /var/lib/docker/

# Allow Docker container access / Разрешить доступ Docker контейнеров
sudo setsebool -P container_manage_cgroup on

# Fix container volume contexts / Исправить контексты volume контейнеров
sudo chcon -Rt svirt_sandbox_file_t /path/to/volume
```

# 💡 Best Practices / Лучшие практики
# Never disable SELinux/AppArmor in production / Никогда не отключайте SELinux/AppArmor в продакшене
# Use permissive/complain mode for debugging / Используйте permissive/complain для отладки
# Always restore contexts after file operations / Всегда восстанавливайте контексты после операций с файлами
# Use -P flag for permanent boolean changes / Используйте флаг -P для постоянных изменений булевых
# Monitor audit logs regularly / Регулярно мониторьте логи аудита
# Create custom modules instead of disabling / Создавайте пользовательские модули вместо отключения

# 🔧 Configuration Files / Файлы конфигурации
# SELinux:
# /etc/selinux/config — Main config / Основная конфигурация
# /var/log/audit/audit.log — Audit log / Лог аудита
# /etc/selinux/targeted/ — Policy files / Файлы политик

# AppArmor:
# /etc/apparmor.d/ — Profiles / Профили
# /var/log/syslog — AppArmor log / Лог AppArmor
# /sys/kernel/security/apparmor/ — Runtime / Время выполнения

# 📋 Common SELinux Booleans / Распространённые SELinux булевы
# httpd_can_network_connect — Allow HTTP network connections / Разрешить HTTP сетевые соединения
# httpd_can_sendmail — Allow HTTP send mail / Разрешить HTTP отправку почты
# httpd_execmem — Allow HTTP execute memory / Разрешить HTTP выполнение памяти
# mysql_connect_any — Allow MySQL connect anywhere / Разрешить MySQL подключаться куда угодно
# selinuxuser_execmod — Allow user exec modification / Разрешить пользователю модификацию exec

# ⚠️ Important Notes / Важные примечания
# Disabling SELinux/AppArmor reduces security / Отключение SELinux/AppArmor снижает безопасность
# Use audit2allow carefully / Используйте audit2allow осторожно
# Test policies before enforcing / Тестируйте политики перед применением
# Reboot required after disabling/enabling SELinux / Требуется перезагрузка после отключения/включения SELinux
