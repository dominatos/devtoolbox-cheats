Title: ☁️ OpenStack
Group: Cloud
Icon: ☁️
Order: 1

# OpenStack Sysadmin Cheatsheet

> **Context:** OpenStack is a cloud operating system that controls large pools of compute, storage, and networking resources. / OpenStack - это облачная ОС для управления пулами вычислений, хранилищ и сетей.
> **Role:** Cloud Admin / User
> **CLI:** `openstack` (Unified Client)

---

## 📚 Table of Contents / Содержание

1. [Authentication](#authentication--аутентификация)
2. [Compute (Nova)](#compute-nova--вычисления)
3. [Image (Glance)](#image-glance--образы)
4. [Networking (Neutron)](#networking-neutron--сети)
5. [Storage (Cinder)](#storage-cinder--хранилище)
6. [System Status](#system-status--статус-системы-admin)

---

## 1. Authentication / Аутентификация

### Source RC File / Загрузка RC файла
You must source the `openrc` file to set environment variables. / Нужно загрузить `openrc` файл для установки переменных окружения.

```bash
source admin-openrc.sh
# Enter password if asked / Введите пароль, если спросят
```

---

## 2. Compute (Nova) / Вычисления

### Server Management / Управление серверами

```bash
# List instances / Список инстансов
openstack server list

# Create Instance / Создать инстанс
openstack server create --flavor <FLAVOR> --image <IMAGE> --network <NET> --key-name <KEY> <VM_NAME>

# Reboot Instance / Перезагрузка
openstack server reboot <VM_NAME>

# Console URL (VNC) / Ссылка на консоль (VNC)
openstack console url show <VM_NAME>
```

### Flavors / Флейворы (Конфигурации)

```bash
# List Flavors / Список флейворов
openstack flavor list
```

---

## 3. Image (Glance) / Образы

```bash
# List Images / Список образов
openstack image list

# Create Image / Загрузить образ
openstack image create "CentOS-9" --file CentOS-Stream-9.qcow2 \
  --disk-format qcow2 --container-format bare --public
```

---

## 4. Networking (Neutron) / Сети

```bash
# List Networks / Список сетей
openstack network list

# List Subnets / Список подсетей
openstack subnet list

# Create Network / Создать сеть
openstack network create <NET_NAME>
```

---

## 5. Storage (Cinder) / Хранилище

```bash
# List Volumes / Список томов
openstack volume list

# Create Volume / Создать том
openstack volume create --size 10 <VOL_NAME>

# Attach Volume / Подключить том
openstack server add volume <VM_NAME> <VOL_NAME>
```

---

## 6. System Status / Статус системы (Admin)

```bash
# Service Status / Статус сервисов
openstack compute service list
openstack network agent list
openstack volume service list
```

### Logs / Логи
Typically in `/var/log/<SERVICE>/`.

*   `/var/log/nova/`
*   `/var/log/neutron/`
*   `/var/log/keystone/`
