Title: 🛠️ Ansible
Group: Dev & Tools
Icon: 🛠️
Order: 5

# Ansible Cheatsheet

> **Context:** Ansible is an open-source software provisioning, configuration management, and application-deployment tool. / Ansible - это open-source инструмент для провижининга ПО, управления конфигурацией и деплоя.
> **Role:** DevOps / Sysadmin
> **Version:** 2.9+

---

## 📚 Table of Contents / Содержание

1. [Ad-Hoc Commands](#ad-hoc-commands--ad-hoc-команды)
2. [Playbooks](#playbooks--плейбуки)
3. [Ansible Galaxy](#ansible-galaxy--ansible-galaxy)
4. [Ansible Vault](#ansible-vault--ansible-vault-шифрование)
5. [Configuration](#configuration--конфигурация)
6. [Sysadmin Basics](#sysadmin-basics)
7. [Logrotate Configuration](#logrotate-configuration)

---

## 1. Ad-Hoc Commands / Ad-Hoc Команды

### Basic Connectivity / Пинг
```bash
# Ping all hosts / Пинг всех хостов
ansible all -m ping -i <INVENTORY_FILE>
```

### Module Execution / Заполнение модулей
```bash
# Shell command / Команда shell
ansible all -m shell -a "uptime" -i hosts

# Copy file / Копирование файла
ansible web -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# Install package (yum) / Установка пакета (yum)
ansible db -m yum -a "name=nc state=present" --become
```

---

## 2. Playbooks / Плейбуки

### Running Playbooks / Запуск плейбуков
```bash
# Run / Запуск
ansible-playbook -i inventory site.yml

# Check mode (Dry Run) / Режим проверки (Dry Run)
ansible-playbook -i inventory site.yml --check

# Limit to specific hosts / Ограничить конкретными хостами
ansible-playbook -i inventory site.yml --limit web01

# Debug (Verbose) / Отладка (Подробно)
ansible-playbook site.yml -vvv
```

### Example Playbook / Пример плейбука
```yaml
---
- name: Install Nginx
  hosts: webservers
  become: yes
  tasks:
    - name: Ensure nginx is installed
      yum:
        name: nginx
        state: present
    
    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes
```

---

## 3. Ansible Galaxy / Ansible Galaxy

```bash
# Install Role / Установить роль
ansible-galaxy install geerlingguy.nginx

# Init new role structure / Создать структуру новой роли
ansible-galaxy init <ROLE_NAME>
```

---

## 4. Ansible Vault / Ansible Vault (Шифрование)

```bash
# Encrypt file / Зашифровать файл
ansible-vault encrypt secrets.yml

# Edit encrypted file / Редактировать зашифрованный файл
ansible-vault edit secrets.yml

# Decrypt file / Расшифровать файл
ansible-vault decrypt secrets.yml

# Run playbook with vault / Запуск плейбука с vault
ansible-playbook site.yml --ask-vault-pass

# Use vault password file / Использовать файл с паролем vault
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

> [!WARNING]
> Never commit vault passwords to version control. Use `--vault-password-file` pointing to a file excluded in `.gitignore`.
> Никогда не коммитьте пароли vault в систему контроля версий.

---

## 5. Configuration / Конфигурация

`/etc/ansible/ansible.cfg` or `./ansible.cfg`

```ini
[defaults]
inventory = ./hosts
remote_user = <USER>
host_key_checking = False
private_key_file = ~/.ssh/id_rsa
```

---

## Sysadmin Basics

### Default Paths / Стандартные пути

| Path | Description (EN / RU) |
|------|----------------------|
| `/etc/ansible/ansible.cfg` | System-wide config / Глобальная конфигурация |
| `~/.ansible.cfg` | User config / Пользовательская конфигурация |
| `./ansible.cfg` | Project config (highest priority) / Проектная конфигурация (наивысший приоритет) |
| `/etc/ansible/hosts` | Default inventory / Инвентарь по умолчанию |
| `~/.ansible/` | Cache, plugins, roles / Кэш, плагины, роли |

### Default Ports / Стандартные порты

| Port | Protocol | Description (EN / RU) |
|------|----------|----------------------|
| 22 | SSH | Default connection method / Метод подключения по умолчанию |
| 5986 | WinRM (HTTPS) | Windows hosts / Хосты Windows |

### Useful Diagnostic Commands / Полезные команды диагностики
```bash
ansible --version                              # Show version / Показать версию
ansible all -m setup -i hosts                  # Gather facts / Собрать факты
ansible all -m ping -i hosts                   # Connectivity check / Проверка связи
ansible-config dump --only-changed             # Show changed config / Показать изменённую конфигурацию
```

---

## Logrotate Configuration

`/etc/logrotate.d/ansible`

```conf
/var/log/ansible/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
```

> [!NOTE]
> Ansible does not log by default. Enable logging by setting `log_path` in `ansible.cfg`:
> `log_path = /var/log/ansible/ansible.log`
> Ansible не логирует по умолчанию. Включите логирование через `log_path` в `ansible.cfg`.
