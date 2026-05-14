Title: 💻 KVM / Libvirt — Virtualization
Group: Virtualization
Icon: 💻
Order: 1

# 💻 KVM / Libvirt — Virtualization Cheatsheet

## Description

**KVM** (Kernel-based Virtual Machine) is a Linux kernel module that turns Linux into a **Type-1 (bare-metal) hypervisor**. Combined with **QEMU** for hardware emulation and **Libvirt** as the management API layer (`virsh`, `virt-manager`, `virt-install`), it forms the standard open-source virtualization stack for Linux servers.

**Common use cases / Типичные сценарии:**
- Production server virtualization / Виртуализация серверов в продакшене
- Virtual machine templates and rapid provisioning / Шаблоны ВМ и быстрое развёртывание
- Development and testing environments / Среды разработки и тестирования
- Cloud infrastructure (OpenStack, oVirt) / Облачная инфраструктура
- Network Function Virtualization (NFV) / Виртуализация сетевых функций
- Live migration between hosts / Живая миграция между хостами

> [!NOTE]
> KVM is the most widely used Linux hypervisor and is the foundation of major cloud platforms (AWS, GCP, OpenStack, Proxmox). For desktop virtualization, **VirtualBox** and **VMware Workstation** offer simpler GUIs. For container-based workloads, **Docker/Podman** and **Kubernetes** are preferred. **Proxmox VE** provides a web-based management interface on top of KVM/QEMU. **oVirt** is the enterprise management platform (upstream of Red Hat Virtualization).
> KVM — самый популярный гипервизор Linux, основа облачных платформ (AWS, GCP, OpenStack, Proxmox). Для десктопной виртуализации — **VirtualBox**, **VMware Workstation**. Для контейнеров — **Docker/Podman**, **Kubernetes**. **Proxmox VE** — веб-интерфейс для управления KVM.

---

## Table of Contents

- [Description](#description)
- [Installation & Configuration](#installation--configuration)
- [Core Management](#core-management)
- [Storage Management](#storage-management)
- [Networking](#networking)
- [Template Creation](#template-creation)
- [Snapshots & Backup](#snapshots--backup)
- [Performance Tuning](#performance-tuning)
- [Security](#security)
- [Troubleshooting & Tools](#troubleshooting--tools)
- [Comparison Tables](#comparison-tables)
- [Documentation Links](#documentation-links)

---

## Installation & Configuration

### Install KVM Stack / Установка стека KVM

#### Debian / Ubuntu
```bash
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils virt-manager  # Install full stack / Установить полный стек
sudo apt install -y libguestfs-tools  # For virt-sysprep, virt-customize / Для работы с образами
```

#### RHEL / CentOS / AlmaLinux
```bash
sudo dnf install -y @virtualization  # Install virtualization group / Установить группу виртуализации
sudo dnf install -y libguestfs-tools virt-install  # Image tools / Инструменты для образов
```

### Enable Libvirt Service / Включение сервиса Libvirt
```bash
sudo systemctl enable --now libvirtd  # Enable and start / Включить и запустить
sudo systemctl status libvirtd        # Check status / Проверить статус
```

### Verify KVM Support / Проверка поддержки KVM
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo   # Must return > 0 / Должно вернуть > 0
lsmod | grep kvm                       # Check loaded modules / Проверить загруженные модули
sudo virt-host-validate                # Full validation / Полная валидация
```

**Sample Output:**
```
QEMU: Checking for hardware virtualization     : PASS
QEMU: Checking if device /dev/kvm exists       : PASS
QEMU: Checking if device /dev/kvm is accessible: PASS
```

### Add User to libvirt Group / Добавить пользователя в группу
```bash
sudo usermod -aG libvirt <USER>       # Add user to group / Добавить в группу
sudo usermod -aG kvm <USER>           # Add to kvm group / Добавить в группу kvm
newgrp libvirt                         # Apply without logout / Применить без перелогина
```

### Configuration Paths / Пути конфигурации
- **Libvirt config:** `/etc/libvirt/libvirtd.conf`
- **QEMU config:** `/etc/libvirt/qemu.conf`
- **VM definitions:** `/etc/libvirt/qemu/<VM_NAME>.xml`
- **Default storage pool:** `/var/lib/libvirt/images/`
- **Default network:** `/etc/libvirt/qemu/networks/default.xml`

### Default Ports / Порты по умолчанию
| Port | Protocol | Description (EN / RU) |
| :--- | :--- | :--- |
| 16509 | TCP | Libvirt remote (unencrypted) / Удалённое подключение |
| 16514 | TLS | Libvirt remote (encrypted) / Удалённое подключение (TLS) |
| 5900+ | TCP | VNC console / VNC консоль |
| 5800+ | TCP | SPICE console / SPICE консоль |

### Log Locations / Расположение логов
- **Libvirt daemon:** `/var/log/libvirt/libvirtd.log`
- **Per-VM QEMU logs:** `/var/log/libvirt/qemu/<VM_NAME>.log`
- **Journal:** `journalctl -u libvirtd`

### Logrotate Configuration / Конфигурация Logrotate
`/etc/logrotate.d/libvirtd`

```bash
/var/log/libvirt/libvirtd.log
/var/log/libvirt/qemu/*.log {
    weekly
    missingok
    rotate 12
    compress
    delaycompress
    notifempty
    postrotate
        systemctl reload libvirtd > /dev/null 2>&1 || true
    endscript
}
```

---

## Core Management

### Create VM with virt-install / Создать ВМ с virt-install
```bash
# Create VM from ISO / Создать ВМ из ISO
sudo virt-install \
  --name <VM_NAME> \
  --ram 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/<VM_NAME>.qcow2,size=20,format=qcow2 \
  --os-variant ubuntu22.04 \
  --network bridge=br0 \
  --graphics vnc,listen=0.0.0.0 \
  --cdrom /var/lib/libvirt/images/<ISO_FILE> \
  --boot hd,cdrom

# Create VM from existing disk image / Создать ВМ из готового образа
sudo virt-install \
  --name <VM_NAME> \
  --ram 4096 \
  --vcpus 4 \
  --disk path=/var/lib/libvirt/images/<VM_NAME>.qcow2 \
  --os-variant centos-stream9 \
  --import \
  --network bridge=br0 \
  --graphics vnc
```

> [!TIP]
> Use `virt-install --os-variant list` (or `osinfo-query os`) to list all supported OS variants. Choosing the correct variant optimizes virtio drivers and clock settings.

### VM Lifecycle (virsh) / Жизненный цикл ВМ
```bash
virsh list --all                       # List all VMs / Список всех ВМ
virsh start <VM_NAME>                  # Start VM / Запустить ВМ
virsh shutdown <VM_NAME>               # Graceful shutdown / Мягкое выключение
virsh reboot <VM_NAME>                 # Reboot VM / Перезагрузить ВМ
virsh suspend <VM_NAME>                # Pause VM / Приостановить ВМ
virsh resume <VM_NAME>                 # Resume VM / Возобновить ВМ
virsh autostart <VM_NAME>              # Enable autostart / Включить автозапуск
virsh autostart --disable <VM_NAME>    # Disable autostart / Отключить автозапуск
```

> [!CAUTION]
> `virsh destroy` forcefully kills the VM process (equivalent to pulling the power cord). Use only when `virsh shutdown` fails.
> ```bash
> virsh destroy <VM_NAME>               # Force stop (DANGER) / Принудительное выключение
> ```

### VM Information / Информация о ВМ
```bash
virsh dominfo <VM_NAME>                # Show VM details / Показать детали ВМ
virsh domblklist <VM_NAME>             # List block devices / Список дисков
virsh domiflist <VM_NAME>              # List network interfaces / Список сетевых интерфейсов
virsh vcpuinfo <VM_NAME>               # vCPU mapping / Маппинг vCPU
virsh dumpxml <VM_NAME>                # Full XML dump / Полный XML дамп
```

### Delete VM / Удалить ВМ
```bash
virsh destroy <VM_NAME>                # Force stop first / Сначала выключить
virsh undefine <VM_NAME> --remove-all-storage  # Delete VM + disks / Удалить ВМ и диски
virsh undefine <VM_NAME> --nvram       # For UEFI VMs / Для UEFI ВМ
```

> [!WARNING]
> `--remove-all-storage` permanently deletes all attached disk images. This is **irreversible**.

### Console Access / Доступ к консоли
```bash
virsh console <VM_NAME>                # Serial console / Серийная консоль (Ctrl+] to exit)
virt-viewer <VM_NAME>                  # GUI console / Графическая консоль
```

### Modify VM Resources / Изменить ресурсы ВМ
```bash
virsh setvcpus <VM_NAME> 4 --config    # Set vCPUs (next boot) / Установить vCPU
virsh setmaxmem <VM_NAME> 8G --config  # Set max RAM (next boot) / Установить макс. RAM
virsh setmem <VM_NAME> 4G --live       # Hot-change RAM / Изменить RAM на лету
virsh edit <VM_NAME>                   # Edit XML directly / Редактировать XML напрямую
```

---

## Storage Management

### Storage Pools / Пулы хранилища
```bash
virsh pool-list --all                  # List all pools / Список всех пулов
virsh pool-define-as <POOL> dir --target /var/lib/libvirt/images/  # Define pool / Определить пул
virsh pool-build <POOL>                # Build pool / Создать пул
virsh pool-start <POOL>                # Start pool / Запустить пул
virsh pool-autostart <POOL>            # Enable autostart / Автозапуск пула
```

### Disk Image Operations / Операции с образами дисков
```bash
qemu-img create -f qcow2 <DISK>.qcow2 20G   # Create 20G disk / Создать диск 20G
qemu-img info <DISK>.qcow2                    # Show image info / Информация об образе
qemu-img resize <DISK>.qcow2 +10G             # Grow disk / Увеличить диск на 10G
qemu-img convert -f raw -O qcow2 <SRC>.raw <DST>.qcow2  # Convert format / Конвертировать формат
```

> [!WARNING]
> Shrinking a qcow2 image is dangerous and can corrupt data. Always grow, never shrink without a full backup.

### Attach/Detach Disks / Подключить/Отключить диски
```bash
virsh attach-disk <VM_NAME> /path/to/<DISK>.qcow2 vdb --subdriver qcow2 --persistent  # Attach disk / Подключить диск
virsh detach-disk <VM_NAME> vdb --persistent  # Detach disk / Отключить диск
```

---

## Networking

### Virtual Networks / Виртуальные сети
```bash
virsh net-list --all                   # List networks / Список сетей
virsh net-info default                 # Network details / Детали сети
virsh net-dhcp-leases default          # Active DHCP leases / Активные DHCP аренды
virsh net-start default                # Start network / Запустить сеть
virsh net-autostart default            # Enable autostart / Включить автозапуск
```

### Bridge Networking / Мост (бриджевая сеть)
`/etc/netplan/01-netcfg.yaml` (Ubuntu/Netplan)

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
  bridges:
    br0:
      interfaces: [enp0s3]
      dhcp4: true
```

```bash
sudo netplan apply  # Apply bridge config / Применить конфигурацию моста
```

> [!TIP]
> Bridge networking gives VMs direct access to the physical LAN, making them appear as separate hosts. NAT (default) is simpler but isolates VMs behind the host.

---

## Template Creation

Creating VM templates allows rapid provisioning of identical, clean machines. The workflow involves preparing a base VM, cleaning it with `virt-sysprep`, and cloning it.

### Production Runbook: Create a VM Template / Создание шаблона ВМ

1. **Install base VM / Установить базовую ВМ**
   ```bash
   sudo virt-install \
     --name template-ubuntu2204 \
     --ram 2048 --vcpus 2 \
     --disk path=/var/lib/libvirt/images/template-ubuntu2204.qcow2,size=20,format=qcow2 \
     --os-variant ubuntu22.04 \
     --cdrom /var/lib/libvirt/images/ubuntu-22.04-server.iso \
     --network bridge=br0 \
     --graphics vnc
   ```

2. **Prepare the base VM (inside the guest) / Подготовить базовую ВМ (внутри гостя)**
   ```bash
   sudo apt update && sudo apt upgrade -y     # Update packages / Обновить пакеты
   sudo apt install -y qemu-guest-agent cloud-init  # Install guest agent / Установить агент
   sudo apt clean                              # Clean APT cache / Очистить кэш
   sudo truncate -s 0 /etc/machine-id          # Reset machine ID / Сбросить machine-id
   sudo rm -f /etc/ssh/ssh_host_*              # Remove SSH host keys / Удалить ключи SSH
   sudo rm -rf /tmp/* /var/tmp/*               # Clean temp / Очистить временные файлы
   cat /dev/null > ~/.bash_history && history -c  # Clear history / Очистить историю
   sudo shutdown -h now                        # Shutdown / Выключить
   ```

3. **Clean image with virt-sysprep / Очистить образ с virt-sysprep**
   ```bash
   sudo virt-sysprep -d template-ubuntu2204 \
     --operations defaults,-lvm-uuids \
     --enable customize \
     --hostname template \
     --run-command 'dpkg-reconfigure -f noninteractive openssh-server'
   ```

> [!IMPORTANT]
> `virt-sysprep` removes SSH keys, machine IDs, persistent network rules, and user data from the disk image, making it generic and ready for cloning.

4. **Undefine VM but keep the disk / Убрать определение ВМ, сохранив диск**
   ```bash
   virsh undefine template-ubuntu2204  # Undefine template VM / Удалить определение шаблона
   ```

5. **Mark the template as read-only / Защитить шаблон от записи**
   ```bash
   sudo chmod 444 /var/lib/libvirt/images/template-ubuntu2204.qcow2  # Read-only / Только чтение
   ```

### Clone from Template / Клонирование из шаблона

#### Method 1: virt-clone (Full Copy / Полная копия)
```bash
sudo virt-clone \
  --original template-ubuntu2204 \
  --name <NEW_VM_NAME> \
  --file /var/lib/libvirt/images/<NEW_VM_NAME>.qcow2  # Full clone / Полная копия
```

#### Method 2: Linked Clone with Backing File (Fast / Быстрое связанное клонирование)
```bash
# Create linked clone (thin provisioning) / Создать связанный клон
sudo qemu-img create -f qcow2 \
  -b /var/lib/libvirt/images/template-ubuntu2204.qcow2 \
  -F qcow2 \
  /var/lib/libvirt/images/<NEW_VM_NAME>.qcow2

# Import the linked clone as a new VM / Импортировать связанный клон как новую ВМ
sudo virt-install \
  --name <NEW_VM_NAME> \
  --ram 2048 --vcpus 2 \
  --disk path=/var/lib/libvirt/images/<NEW_VM_NAME>.qcow2 \
  --os-variant ubuntu22.04 \
  --import \
  --network bridge=br0 \
  --graphics vnc
```

> [!TIP]
> **Linked clones** use the template as a read-only backing file and only store the delta (differences). They are much faster to create and save disk space, but depend on the template image remaining intact.

### Customize Clone with virt-customize / Кастомизация клона
```bash
sudo virt-customize -a /var/lib/libvirt/images/<NEW_VM_NAME>.qcow2 \
  --hostname <NEW_HOSTNAME> \
  --run-command 'dpkg-reconfigure -f noninteractive openssh-server' \
  --root-password password:<PASSWORD> \
  --timezone Europe/Berlin \
  --install nginx,htop
```

### Clone Method Comparison / Сравнение методов клонирования

| Method | Speed (EN / RU) | Disk Usage | Independence | Best Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **virt-clone** | Slow (full copy) / Медленно | Full size / Полный размер | Fully independent / Полностью независим | Production VMs, long-lived instances |
| **Linked clone** | Instant / Мгновенно | Delta only / Только изменения | Depends on template / Зависит от шаблона | Dev/test, ephemeral environments |

---

## Snapshots & Backup

### Snapshot Management / Управление снимками
```bash
virsh snapshot-create-as <VM_NAME> --name "<SNAP_NAME>" --description "Before upgrade"  # Create / Создать
virsh snapshot-list <VM_NAME>                     # List snapshots / Список снимков
virsh snapshot-revert <VM_NAME> --snapshotname "<SNAP_NAME>"  # Revert / Откатиться
virsh snapshot-delete <VM_NAME> --snapshotname "<SNAP_NAME>"  # Delete / Удалить
```

> [!CAUTION]
> Reverting a snapshot discards all changes made after the snapshot was taken. This is irreversible.

### Backup VM Disk / Бэкап диска ВМ
```bash
virsh shutdown <VM_NAME>               # Shutdown first / Сначала выключить
sudo cp /var/lib/libvirt/images/<VM_NAME>.qcow2 /backup/<VM_NAME>_$(date +%F).qcow2  # Copy disk / Скопировать диск
virsh dumpxml <VM_NAME> > /backup/<VM_NAME>.xml  # Backup XML config / Бэкап конфигурации
```

### Restore VM from Backup / Восстановление ВМ из бэкапа
```bash
sudo cp /backup/<VM_NAME>.qcow2 /var/lib/libvirt/images/  # Restore disk / Восстановить диск
virsh define /backup/<VM_NAME>.xml     # Restore config / Восстановить конфигурацию
virsh start <VM_NAME>                  # Start VM / Запустить ВМ
```

---

## Performance Tuning

### CPU Pinning / Привязка CPU
`/etc/libvirt/qemu/<VM_NAME>.xml`

```xml
<vcpu placement='static'>4</vcpu>
<cputune>
  <vcpupin vcpu='0' cpuset='2'/>
  <vcpupin vcpu='1' cpuset='3'/>
  <vcpupin vcpu='2' cpuset='4'/>
  <vcpupin vcpu='3' cpuset='5'/>
</cputune>
```

### Hugepages / Огромные страницы памяти
```bash
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages  # Allocate 2MB hugepages / Выделить hugepages
grep HugePages /proc/meminfo                      # Verify / Проверить
```

`/etc/libvirt/qemu/<VM_NAME>.xml`

```xml
<memoryBacking>
  <hugepages/>
</memoryBacking>
```

### VirtIO Drivers / Драйверы VirtIO

> [!TIP]
> Always use **virtio** for disk and network devices. VirtIO is paravirtualized and significantly faster than emulated IDE/e1000 devices.

```bash
# Check current disk bus type / Проверить тип шины диска
virsh dumpxml <VM_NAME> | grep "target dev" | grep "bus"
```

---

## Security

### TLS for Remote Libvirt / TLS для удалённого доступа
`/etc/libvirt/libvirtd.conf`

```bash
listen_tls = 1
listen_tcp = 0
key_file = "/etc/pki/libvirt/private/serverkey.pem"
cert_file = "/etc/pki/libvirt/servercert.pem"
ca_file = "/etc/pki/CA/cacert.pem"
```

### SELinux / sVirt Labels / Метки безопасности
```bash
sudo getenforce                        # Check SELinux status / Проверить статус SELinux
ls -lZ /var/lib/libvirt/images/        # Check sVirt labels / Проверить метки sVirt
sudo restorecon -Rv /var/lib/libvirt/images/  # Restore contexts / Восстановить контексты
```

---

## Troubleshooting & Tools

### Common Issues / Типичные проблемы
```bash
# VM won't start: permission denied on disk / ВМ не стартует: нет прав на диск
sudo chown qemu:qemu /var/lib/libvirt/images/<VM_NAME>.qcow2
sudo chmod 660 /var/lib/libvirt/images/<VM_NAME>.qcow2

# Check QEMU log for errors / Проверить лог QEMU
sudo cat /var/log/libvirt/qemu/<VM_NAME>.log | tail -50

# Network issues: restart libvirt network / Проблемы с сетью: перезапуск сети
virsh net-destroy default && virsh net-start default
```

### Useful Diagnostic Commands / Полезные диагностические команды
```bash
virsh nodeinfo                         # Host hardware info / Информация о хосте
virsh capabilities                     # Hypervisor capabilities / Возможности гипервизора
virsh domstats <VM_NAME>               # VM resource stats / Статистика ресурсов ВМ
virt-top                               # Real-time VM monitor / Мониторинг ВМ в реальном времени
```

---

## Comparison Tables

### Virtualization Approach Comparison / Сравнение подходов виртуализации

| Feature | KVM (Type-1) | VirtualBox (Type-2) | Docker (Containers) |
| :--- | :--- | :--- | :--- |
| **Isolation** | Full hardware / Полная аппаратная | Full hardware / Полная аппаратная | Kernel-shared / Общее ядро |
| **Performance** | Near-native / Близко к нативной | Moderate / Умеренная | Native / Нативная |
| **Use Case** | Production servers / Продакшн серверы | Desktop testing / Тестирование на десктопе | Microservices / Микросервисы |
| **Overhead** | Low / Низкие | Medium / Средние | Minimal / Минимальные |

### Network Mode Comparison / Сравнение сетевых режимов

| Mode | Description (EN / RU) | Best Use Case |
| :--- | :--- | :--- |
| **NAT** | VMs share host IP / ВМ за NAT хоста | Development, default setup |
| **Bridge** | VMs on physical LAN / ВМ в физической сети | Production, server hosting |
| **Isolated** | VMs talk only to each other / ВМ только между собой | Security testing, labs |
| **macvtap** | Direct passthrough / Прямое подключение | High-performance networking |

---

## Documentation Links

- [KVM Official Site](https://www.linux-kvm.org/)
- [Libvirt Documentation](https://libvirt.org/docs.html)
- [Libvirt — virsh Command Reference](https://libvirt.org/manpages/virsh.html)
- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [virt-install Manual](https://man.archlinux.org/man/virt-install.1)
- [virt-sysprep Manual](https://libguestfs.org/virt-sysprep.1.html)
- [Red Hat — KVM/Libvirt Guide](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_virtualization/)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [oVirt Documentation](https://www.ovirt.org/documentation/)

---
