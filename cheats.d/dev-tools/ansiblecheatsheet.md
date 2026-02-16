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
```

---

## 5. Configuration / Конфигурация
File: `/etc/ansible/ansible.cfg` or `./ansible.cfg`

```ini
[defaults]
inventory = ./hosts
remote_user = <USER>
host_key_checking = False
private_key_file = ~/.ssh/id_rsa
```
