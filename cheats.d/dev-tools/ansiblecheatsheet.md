---
Title: 🛠️ Ansible
Group: "Dev & Tools"
Icon: 🛠️
Order: 5
tags:
  - dev-tools
  - devops
  - sysadmin
---

# Ansible Cheatsheet

> **Description:** Ansible is an open-source agentless automation tool for software provisioning, configuration management, and application deployment. It uses SSH and YAML-based playbooks — no agent installation required on target hosts. Created by Michael DeHaan (2012), now maintained by Red Hat.
> Ansible — это open-source безагентный инструмент автоматизации для провижининга ПО, управления конфигурацией и деплоя. Использует SSH и YAML-плейбуки — не требует установки агентов на целевых хостах.

> **Status:** Actively maintained by Red Hat. Alternatives: **SaltStack** (agent-based, faster at scale), **Puppet** (agent-based, declarative), **Chef** (Ruby-based). **Ansible Semaphore** provides a modern web UI.
> **Role:** DevOps / Sysadmin
> **Version:** 2.9+

---

## 📚 Table of Contents

1. [Ad-Hoc Commands](#1.%20Ad-Hoc%20Commands%20/%20Ad-Hoc%20Команды)
2. [Playbooks](#2.%20Playbooks)
3. [Ansible Galaxy](#3.%20Ansible%20Galaxy%20/%20Ansible%20Galaxy)
4. [Ansible Vault](#4.%20Ansible%20Vault%20/%20Ansible%20Vault%20(Шифрование))
5. [Configuration](#5.%20Configuration)
6. [Sysadmin Basics](#Sysadmin%20Basics)
7. [Logrotate Configuration](#Logrotate%20Configuration)

---

## 1. Ad-Hoc Commands / Ad-Hoc

### Basic Connectivity
```bash
# Ping all hosts
ansible all -m ping -i <INVENTORY_FILE>
```

### Module Execution
```bash
# Shell command
ansible all -m shell -a "uptime" -i hosts

# Copy file
ansible web -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# Install package (yum)
ansible db -m yum -a "name=nc state=present" --become
```

---

## 2. Playbooks

### Running Playbooks
```bash
# Run
ansible-playbook -i inventory site.yml

# Check mode (Dry Run)
ansible-playbook -i inventory site.yml --check

# Limit to specific hosts
ansible-playbook -i inventory site.yml --limit web01

# Debug (Verbose)
ansible-playbook site.yml -vvv
```

### Example Playbook
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
# Install Role
ansible-galaxy install geerlingguy.nginx

# Init new role structure
ansible-galaxy init <ROLE_NAME>
```

---

## 4. Ansible Vault / Ansible Vault

```bash
# Encrypt file
ansible-vault encrypt secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Decrypt file
ansible-vault decrypt secrets.yml

# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass

# Use vault password file
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

> [!WARNING]
> Never commit vault passwords to version control. Use `--vault-password-file` pointing to a file excluded in `.gitignore`.
> Никогда не коммитьте пароли vault в систему контроля версий.

---

## 5. Configuration

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

### Default Paths

| Path | Description (EN / RU) |
|------|----------------------|
| `/etc/ansible/ansible.cfg` | System-wide config / Глобальная конфигурация |
| `~/.ansible.cfg` | User config / Пользовательская конфигурация |
| `./ansible.cfg` | Project config (highest priority) / Проектная конфигурация (наивысший приоритет) |
| `/etc/ansible/hosts` | Default inventory / Инвентарь по умолчанию |
| `~/.ansible/` | Cache, plugins, roles / Кэш, плагины, роли |

### Default Ports

| Port | Protocol | Description (EN / RU) |
|------|----------|----------------------|
| 22 | SSH | Default connection method / Метод подключения по умолчанию |
| 5986 | WinRM (HTTPS) | Windows hosts / Хосты Windows |

### Useful Diagnostic Commands
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

---

## Official Documentation

- **Ansible:** https://docs.ansible.com/
- **Ansible Galaxy (Roles):** https://galaxy.ansible.com/
- **Ansible Vault:** https://docs.ansible.com/ansible/latest/vault_guide/
- **Ansible Semaphore (Web UI):** https://semaphoreui.com/
