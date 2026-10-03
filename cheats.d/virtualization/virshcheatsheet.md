---
Title: "🖥️ virsh — Libvirt Shell"
Group: Virtualization
Icon: "🖥️"
Order: 2
tags:
  - virtualization
  - sysadmin
  - linux
---

# 🖥️ virsh — Libvirt Shell Cheatsheet

## Description

**virsh** is the command-line management tool for **libvirt**, the standard virtualization API for Linux. It provides a consistent interface to manage KVM/QEMU, Xen, LXC, and other hypervisors. With virsh you can create, configure, monitor, and control virtual machines, storage pools, virtual networks, snapshots, and more — all from the terminal.

**Alternatives / Альтернативы:**
- **virt-manager** — GUI frontend for libvirt / Графический интерфейс для libvirt
- **Cockpit** — Web-based server management with VM plugin / Веб-интерфейс управления серверами
- **Proxmox VE** — Full-featured web UI on KVM/QEMU + libvirt / Полнофункциональный веб-интерфейс
- **oVirt** — Enterprise virtualization management / Корпоративное управление виртуализацией

**Common use cases / Типичные сценарии:**
- Automated VM provisioning and lifecycle management / Автоматизация развёртывания и управления ВМ
- Remote hypervisor administration over SSH / Удалённое управление гипервизором через SSH
- Snapshot-based rollback and backup / Откат и бэкап на основе снимков
- Live and offline migration between hosts / Живая и оффлайн-миграция между хостами
- Storage pool and volume management / Управление пулами хранилищ и томами
- Virtual network and bridge configuration / Настройка виртуальных сетей и мостов

> [!NOTE]
> virsh is actively maintained as part of the libvirt project. It is the recommended CLI for scripted and manual VM management on KVM/QEMU hosts. For GUI-based alternatives, see virt-manager (local), Cockpit (web), Proxmox VE, or oVirt.
> virsh активно поддерживается как часть проекта libvirt. Рекомендуется для CLI-управления ВМ на KVM/QEMU хостах. Для GUI-альтернатив см. virt-manager (локально), Cockpit (веб), Proxmox VE, oVirt.

---

## Table of Contents

- [Description](#Description)
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Core Management (VM Lifecycle)](#Core%20Management%20(VM%20Lifecycle))
- [VM Information & Inspection](#VM%20Information%20&%20Inspection)
- [Console Access & Interaction](#Console%20Access%20&%20Interaction)
- [Resource Management](#Resource%20Management)
- [Storage Management](#Storage%20Management)
- [Networking](#Networking)
- [Snapshots & Checkpoints](#Snapshots%20&%20Checkpoints)
- [Migration](#Migration)
- [Templates & Cloning](#Templates%20&%20Cloning)
- [XML Editing & Device Management](#XML%20Editing%20&%20Device%20Management)
- [Security & Access Control](#Security%20&%20Access%20Control)
- [Host & Hypervisor Info](#Host%20&%20Hypervisor%20Info)
- [Advanced Operations](#Advanced%20Operations)
- [Troubleshooting](#Troubleshooting)
- [Comparison Tables](#Comparison%20Tables)
- [Quick Reference Cards](#Quick%20Reference%20Cards)
- [Logrotate Configuration](#Logrotate%20Configuration)
- [Documentation Links](#Documentation%20Links)

---

## Installation & Configuration

### Install virsh / Установка virsh

#### Debian / Ubuntu
```bash
sudo apt install -y libvirt-clients  # Install virsh client / Установить клиент virsh
sudo apt install -y libvirt-daemon-system  # Install libvirt daemon / Установить демон libvirt
sudo apt install -y qemu-kvm bridge-utils virtinst  # Full stack / Полный стек
```

#### RHEL / CentOS / AlmaLinux
```bash
sudo dnf install -y libvirt  # Install libvirt package / Установить пакет libvirt
sudo dnf install -y qemu-kvm  # Install QEMU/KVM / Установить QEMU/KVM
```

### Enable Libvirt Daemon
```bash
sudo systemctl enable --now libvirtd   # Enable and start / Включить и запустить
sudo systemctl status libvirtd         # Check status / Проверить статус
```

### Verify Installation
```bash
virsh version                          # Show virsh and libvirt version / Версия virsh и libvirt
virsh capabilities                     # Hypervisor capabilities / Возможности гипервизора
sudo virt-host-validate                # Validate host configuration / Валидация конфигурации хоста
```

**Sample Output:**
```
virsh version
Compiled against library: libvirt 9.0.0
Using library: libvirt 9.0.0
Using API: QEMU 9.0.0
Running hypervisor: QEMU 8.2.0
```

### Add User to libvirt Group
```bash
sudo usermod -aG libvirt <USER>        # Add user to libvirt group / Добавить в группу libvirt
sudo usermod -aG kvm <USER>            # Add to kvm group / Добавить в группу kvm
newgrp libvirt                          # Apply without logout / Применить без перелогина
```

### Configuration Paths
- **Libvirt daemon:** `/etc/libvirt/libvirtd.conf`
- **QEMU config:** `/etc/libvirt/qemu.conf`
- **VM definitions:** `/etc/libvirt/qemu/<VM_NAME>.xml`
- **Default storage pool:** `/var/lib/libvirt/images/`
- **Default network:** `/etc/libvirt/qemu/networks/default.xml`

### Remote Connection Modes / Режимы удалённого подключения

#### Unix Socket (Local / Локально)
```bash
virsh connect qemu:///system            # Local system connection / Локальное подключение к системе
```

#### SSH (Recommended / Рекомендуемый)
```bash
virsh connect qemu+ssh://root@<HOST>/system  # SSH connection / Подключение через SSH
```

> [!TIP]
> SSH is the most secure remote connection method. It uses existing SSH key authentication and encrypts all traffic. No additional ports need to be opened.
> SSH — самый безопасный метод удалённого подключения. Использует аутентификацию по SSH-ключам и шифрует весь трафик. Дополнительные порты открывать не нужно.

#### TLS (Encrypted / Шифрование)
```bash
virsh connect qemu+tls://<HOST>/system  # TLS connection / Подключение через TLS
```

> [!WARNING]
> TLS requires proper PKI certificates on both client and server. Incorrect certificate setup can lead to connection failures or security vulnerabilities.
> TLS требует корректных PKI-сертификатов на клиенте и сервере. Неправильная настройка сертификатов может привести к сбоям подключения или уязвимостям.

#### TCP (Unencrypted / Без шифрования)
```bash
virsh connect qemu+tcp://<HOST>/system  # TCP connection / Подключение через TCP
```

> [!CAUTION]
> TCP connections are **unencrypted**. Never use TCP over untrusted networks. It requires explicit enabling in `/etc/libvirt/libvirtd.conf` (`listen_tcp = 1`) and is **disabled by default** for security.
> TCP-подключения **не шифруются**. Никогда не используйте TCP в ненадёжных сетях. Требует явного включения в `/etc/libvirt/libvirtd.conf` (`listen_tcp = 1`) и **отключён по умолчанию** в целях безопасности.

### Default Ports
| Port | Protocol | Description (EN / RU) |
| :--- | :--- | :--- |
| 16509 | TCP | Libvirt remote (unencrypted) / Удалённое подключение libvirt (без шифрования) |
| 16514 | TLS | Libvirt remote (encrypted) / Удалённое подключение libvirt (TLS) |
| 5900+ | TCP | VNC console / VNC консоль |
| 5800+ | TCP | SPICE console / SPICE консоль |
| 22 | TCP | SSH (for qemu+ssh) / SSH (для qemu+ssh) |

### Log Locations
- **Libvirt daemon:** `/var/log/libvirt/libvirtd.log`
- **Per-VM QEMU logs:** `/var/log/libvirt/qemu/<VM_NAME>.log`
- **Journal:** `journalctl -u libvirtd`

---

## Core Management (VM Lifecycle)

### List VMs / Список ВМ
```bash
virsh list                             # List running VMs / Список запущенных ВМ
virsh list --all                       # List all VMs / Список всех ВМ
virsh list --inactive                  # List stopped VMs / Список остановленных ВМ
virsh list --autostart                 # List autostart VMs / Список ВМ с автозапуском
virsh list --state-running             # Filter by running state / Фильтр по состоянию running
virsh list --state-shutoff             # Filter by stopped state / Фильтр по состоянию shutoff
```

**Sample Output:**
```
 Id   Name            State
--------------------------------
 1    ubuntu2204      running
 2    centos9         running
 3    win11           shutoff
```

### Start VM / Запуск ВМ
```bash
virsh start <VM_NAME>                  # Start VM / Запустить ВМ
virsh start <VM_NAME> --paused         # Start in paused state / Запустить в приостановленном состоянии
virsh start <VM_NAME> --autoboot       # Start if set autostart / Запустить если включён автозапуск
```

### Shutdown VM / Выключение ВМ
```bash
virsh shutdown <VM_NAME>               # Graceful ACPI shutdown / Мягкое выключение через ACPI
virsh shutdown <VM_NAME> --mode acpi   # ACPI shutdown (default) / Выключение через ACPI (по умолчанию)
virsh shutdown <VM_NAME> --mode agent  # Guest agent shutdown / Выключение через гостевой агент
```

> [!TIP]
> `virsh shutdown` sends an ACPI signal or uses the guest agent. The VM may take time to shut down. If it doesn't shut down within a timeout, use `virsh destroy` as a last resort.
> `virsh shutdown` отправляет ACPI-сигнал или использует гостевой агент. ВМ может занять время на выключение. Если не выключается — используйте `virsh destroy` как крайнюю меру.

### Reboot VM / Перезагрузка ВМ
```bash
virsh reboot <VM_NAME>                 # Graceful reboot / Мягкая перезагрузка
```

### Pause / Resume / Приостановка / Возобновление
```bash
virsh suspend <VM_NAME>                # Pause VM (freeze processes) / Приостановить ВМ (заморозить процессы)
virsh resume <VM_NAME>                 # Resume paused VM / Возобновить приостановленную ВМ
```

### Force Stop / Принудительное выключение
```bash
virsh destroy <VM_NAME>                # Force kill VM (DANGER) / Принудительное завершение ВМ (ОПАСНО)
```

> [!CAUTION]
> `virsh destroy` is equivalent to pulling the power cord on a physical machine. It does **not** shut down the guest OS cleanly. Use only when `virsh shutdown` fails. Data loss is possible.
> `virsh destroy` эквивалентен выдергиванию кабеля питания из физической машины. **Не** выполняет корректное завершение работы гостевой ОС. Используйте только когда `virsh shutdown` не работает. Возможна потеря данных.

### Delete VM / Удаление ВМ
```bash
virsh destroy <VM_NAME>                # Force stop first / Сначала принудительно остановить
virsh undefine <VM_NAME>               # Remove VM definition / Удалить определение ВМ
virsh undefine <VM_NAME> --remove-all-storage  # Delete VM + all disks / Удалить ВМ и все диски
virsh undefine <VM_NAME> --nvram       # For UEFI VMs / Для UEFI ВМ (удалить NVRAM)
virsh undefine <VM_NAME> --storage vda  # Delete specific disk / Удалить конкретный диск
```

> [!WARNING]
> `--remove-all-storage` permanently deletes all attached disk images. This is **irreversible**. Always verify your VM name and backup important data before running this command.
> `--remove-all-storage` безвозвратно удаляет все подключённые образы дисков. Это **необратимо**. Всегда проверяйте имя ВМ и делайте бэкап важных данных перед выполнением.

### Autostart / Автозапуск
```bash
virsh autostart <VM_NAME>              # Enable autostart / Включить автозапуск
virsh autostart --disable <VM_NAME>    # Disable autostart / Отключить автозапуск
```

### Define / Redefine / Определение / Переопределение
```bash
virsh define <VM_NAME>.xml             # Define VM from XML / Определить ВМ из XML
virsh define /dev/stdin < <MODIFIED_XML>  # Define from stdin / Определить из stdin
```

---

## VM Information & Inspection

### VM Details / Детали ВМ
```bash
virsh dominfo <VM_NAME>                # VM information / Информация о ВМ
virsh domid <VM_NAME>                  # Get VM numeric ID / Получить числовой ID ВМ
virsh domname <ID>                     # Get VM name from ID / Получить имя ВМ по ID
virsh domstate <VM_NAME>               # VM power state / Состояние питания ВМ
virsh domuuid <VM_NAME>                # Get VM UUID / Получить UUID ВМ
```

**Sample Output of `virsh dominfo`:**
```
Id:             1
Name:           ubuntu2204
UUID:           a1b2c3d4-e5f6-7890-abcd-ef1234567890
OS Type:        hvm
State:          running
CPU(s):         4
CPU time:       123.45s
Max memory:     8388608 KiB
Used memory:    4194304 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: selinux
Security DOI:   0
```

### Block Devices / Блочные устройства
```bash
virsh domblklist <VM_NAME>             # List block devices / Список блочных устройств
virsh domblkinfo <VM_NAME> <DISK>      # Disk details / Детали диска
virsh domblkstat <VM_NAME> <DISK>      # Disk I/O stats / Статистика ввода-вывода диска
```

**Sample Output of `virsh domblklist`:**
```
 Target   Source
------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu2204.qcow2
 hdc      -
```

### Network Interfaces / Сетевые интерфейсы
```bash
virsh domiflist <VM_NAME>              # List network interfaces / Список сетевых интерфейсов
virsh domifstat <VM_NAME> <INTERFACE>  # Interface stats / Статистика интерфейса
virsh domifaddr <VM_NAME>              # Guest IP addresses (requires agent) / IP-адреса гостя (нужен агент)
```

**Sample Output of `virsh domiflist`:**
```
 Interface   Type     Source       Model       MAC
-------------------------------------------------------
 vnet0       bridge   br0          virtio      52:54:00:ab:cd:ef
```

### CPU & Memory / Процессор и память
```bash
virsh vcpuinfo <VM_NAME>               # vCPU mapping to physical CPUs / Маппинг vCPU на физические CPU
virsh vcpucount <VM_NAME>              # vCPU counts / Количество vCPU
virsh dommemstat <VM_NAME>             # Memory statistics / Статистика памяти
```

### Full XML Dump / Полный XML дамп
```bash
virsh dumpxml <VM_NAME>                # Full XML definition / Полное XML-определение
virsh dumpxml <VM_NAME> > <VM_NAME>.xml  # Save to file / Сохранить в файл
virsh dumpxml <VM_NAME> --inactive     # Inactive config (persistent) / Неактивная конфигурация
virsh dumpxml <VM_NAME> --update-cap   # Update to current capabilities / Обновить до текущих возможностей
```

---

## Console Access & Interaction

### Serial Console / Серийная консоль
```bash
virsh console <VM_NAME>                # Connect to serial console / Подключиться к серийной консоли
```

> [!TIP]
> To exit the serial console, press `Ctrl+ ]`. The guest must have a serial console configured (e.g., `console=ttyS0` in kernel boot parameters).
> Для выхода из серийной консоли нажмите `Ctrl+ ]`. В госте должна быть настроена серийная консоль (например, `console=ttyS0` в параметрах загрузки ядра).

### Graphical Console / Графическая консоль
```bash
virt-viewer <VM_NAME>                  # GUI console viewer / Графический просмотр консоли
virt-viewer <VM_NAME> --connect qemu+ssh://root@<HOST>/system  # Remote console / Удалённая консоль
```

### SPICE Console / SPICE консоль
```bash
remote-viewer spice://<HOST>:5900      # Connect via SPICE / Подключиться через SPICE
```

### VNC Console / VNC консоль
```bash
remote-viewer vnc://<HOST>:5900        # Connect via VNC / Подключиться через VNC
```

### Send Keys / Отправка клавиш
```bash
virsh send-key <VM_NAME> KEY_ENTER     # Send Enter key / Отправить клавишу Enter
virsh send-key <VM_NAME> KEY_LEFTCTRL KEY_LEFTALT KEY_DELETE  # Ctrl+Alt+Del / Отправить Ctrl+Alt+Del
```

### Guest Agent Commands / Команды гостевого агента
```bash
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-info"}'          # Get guest info / Информация о госте
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-sync","arguments":{"id":12345}}'  # Sync / Синхронизация
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-shutdown","arguments":{"mode":"powerdown"}}'  # Shutdown / Выключение
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-exec","arguments":{"path":"/bin/true"}}'  # Run command / Запустить команду
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-ping"}'          # Ping agent / Пинг агента
virsh qemu-agent-command <VM_NAME> '{"execute":"guest-info"}' | python3 -m json.tool  # Pretty print / Красивый вывод
```

> [!NOTE]
> Guest agent commands require `qemu-guest-agent` installed and running inside the VM. These commands execute within the guest OS.
> Команды гостевого агента требуют установленного и запущенного `qemu-guest-agent` внутри ВМ. Эти команды выполняются внутри гостевой ОС.

### QEMU Monitor (HMP/QMP) / Монитор QEMU
```bash
virsh qemu-monitor-command <VM_NAME> --hmp "info status"       # HMP status / Статус через HMP
virsh qemu-monitor-command <VM_NAME> --hmp "info block"        # Block devices / Блочные устройства
virsh qemu-monitor-command <VM_NAME> --hmp "info cpus"         # CPU info / Информация о CPU
virsh qemu-monitor-command <VM_NAME> --hmp "info registers"    # CPU registers / Регистры CPU
virsh qemu-monitor-command <VM_NAME> --hmp "screendump <FILE>.ppm"  # Screenshot / Снимок экрана
virsh qemu-monitor-command <VM_NAME> --hmp "migrate <URI>"     # Migrate via HMP / Миграция через HMP
virsh qemu-monitor-command <VM_NAME> --qmp '{"execute":"query-status"}'  # QMP query / Запрос через QMP
virsh qemu-monitor-command <VM_NAME> --qmp '{"execute":"query-blockstats"}'  # Block stats / Статистика блоков
virsh qemu-monitor-command <VM_NAME> --qmp '{"execute":"human-monitor-command","arguments":{"command-line":"info status"}}'  # QMP→HMP bridge / Мост QMP→HMP
```

> [!WARNING]
> `qemu-monitor-command` bypasses libvirt's abstraction layer. Use it only when virsh commands cannot accomplish the task. Improper use can corrupt VM state.
> `qemu-monitor-command` обходит слой абстракции libvirt. Используйте только когда команды virsh не помогают. Неправильное использование может повредить состояние ВМ.

---

## Resource Management

### CPU / Процессор
```bash
virsh setvcpus <VM_NAME> 4 --config    # Set vCPUs (next boot) / Установить vCPU (при следующей загрузке)
virsh setvcpus <VM_NAME> 4 --live      # Hot-add/remove vCPU / Добавить/удалить vCPU на лету
virsh setvcpus <VM_NAME> 2 --maximum --config  # Set max vCPUs / Установить макс. vCPU
```

### Memory / Память
```bash
virsh setmaxmem <VM_NAME> 8G --config  # Set max RAM (next boot) / Установить макс. RAM (при следующей загрузке)
virsh setmem <VM_NAME> 4G --live       # Hot-change RAM / Изменить RAM на лету
virsh setmem <VM_NAME> 4G --config     # Set RAM (next boot) / Установить RAM (при следующей загрузке)
virsh dommemstat <VM_NAME>             # Show memory statistics / Показать статистику памяти
```

> [!CAUTION]
> You cannot set memory larger than max memory. Always call `setmaxmem` before `setmem` if you need to increase beyond the current maximum.
> Нельзя установить память больше максимальной. Всегда вызывайте `setmaxmem` перед `setmem`, если нужно увеличить сверх текущего максимума.

### Device Hotplug / Подключение устройств на лету
```bash
virsh attach-device <VM_NAME> <DEVICE>.xml --live  # Attach device (live) / Подключить устройство (на лету)
virsh detach-device <VM_NAME> <DEVICE>.xml --live  # Detach device (live) / Отключить устройство (на лету)
virsh attach-disk <VM_NAME> /path/to/disk.qcow2 vdb --subdriver qcow2 --live  # Attach disk / Подключить диск
virsh detach-disk <VM_NAME> vdb --live              # Detach disk / Отключить диск
virsh attach-interface <VM_NAME> bridge br1 --model virtio --live  # Attach NIC / Подключить сетевую карту
virsh detach-interface <VM_NAME> bridge --live      # Detach NIC / Отключить сетевую карту
```

### CPU Pinning & NUMA / Привязка CPU и NUMA
```bash
virsh vcpupin <VM_NAME> 0 0 --live      # Pin vCPU 0 to pCPU 0 / Привязать vCPU 0 к pCPU 0
virsh vcpupin <VM_NAME> --current       # Show current pinning / Показать текущую привязку
virsh vcpupin <VM_NAME> 0-3 0-3 --live  # Pin vCPU range / Привязать диапазон vCPU
virsh numatune <VM_NAME> --memnodes 0-1 --memorymode preferred --live  # NUMA memory policy / NUMA-политика памяти
virsh numatune <VM_NAME> --memorymode strict --memorynode 0 --live     # Strict NUMA / Строгий NUMA
virsh dominfo <VM_NAME> | grep numa     # Show NUMA topology / Показать топологию NUMA
```

> [!TIP]
> CPU pinning improves latency consistency for latency-sensitive workloads (databases, trading). Pair with NUMA-aware memory policy to avoid cross-node access penalties.
> Привязка CPU улучшает согласованность задержек для нагрузок, чувствительных к latency (базы данных, трейдинг). Сочетайте с NUMA-политикой памяти для избежания штрафов кросс-узлового доступа.

### I/O Threads / Потоки ввода-вывода
```bash
virsh qemu-monitor-command <VM_NAME> --hmp "info block" 2>/dev/null | grep iothread  # Check iothreads / Проверить iothreads
```

**I/O Thread XML configuration (via `virsh edit <VM_NAME>`):**
```xml
<!-- Add iothreadids / Добавить iothreadids -->
<iothreadids>
  <iothread id='1'/>
  <iothread id='2'/>
</iothreadids>

<!-- Assign iothread to disk / Назначить iothread диску -->
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' iothread='1'/>
  <source file='/var/lib/libvirt/images/<VM_NAME>.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>
```

> [!NOTE]
> I/O threads are configured via XML (not a direct virsh command). Use `virsh edit <VM_NAME>` to add `iothreadids` and assign `iothread` attributes to disk controllers or individual disks.
> I/O threads настраиваются через XML (не прямой командой virsh). Используйте `virsh edit <VM_NAME>` для добавления `iothreadids` и назначения атрибутов `iothread` дискам или контроллерам.

---

## Storage Management

### Storage Pools / Пулы хранилищ
```bash
virsh pool-list --all                  # List all storage pools / Список всех пулов хранилищ
virsh pool-list --all --details        # Detailed pool list / Детальный список пулов
virsh pool-info <POOL>                 # Pool information / Информация о пуле
virsh pool-define-as <POOL> dir --target /data/images/  # Define directory pool / Определить пул каталога
virsh pool-build <POOL>                # Build pool structure / Создать структуру пула
virsh pool-start <POOL>                # Start pool / Запустить пул
virsh pool-destroy <POOL>              # Stop and delete pool / Остановить и удалить пул
virsh pool-undefine <POOL>             # Remove pool definition / Удалить определение пула
virsh pool-autostart <POOL>            # Enable autostart / Включить автозапуск
virsh pool-autostart --disable <POOL>  # Disable autostart / Отключить автозапуск
```

### Create NFS Pool / Создание NFS пула
```bash
virsh pool-define-as nfs-pool netfs --source-host <NFS_SERVER> --source-path /export/images --target /var/lib/libvirt/images/  # Define NFS pool / Определить NFS пул
virsh pool-build nfs-pool              # Build pool / Создать пул
virsh pool-start nfs-pool              # Start pool / Запустить пул
virsh pool-autostart nfs-pool          # Autostart / Автозапуск
```

### Volumes / Тома
```bash
virsh vol-list <POOL>                  # List volumes in pool / Список томов в пуле
virsh vol-info <VOL> --pool <POOL>     # Volume details / Детали тома
virsh vol-create-as <POOL> <VOL> 20G  # Create 20G volume / Создать том 20G
virsh vol-create-as <POOL> <VOL> 20G --format qcow2  # Create qcow2 volume / Создать qcow2 том
virsh vol-delete <VOL> --pool <POOL>  # Delete volume / Удалить том
virsh vol-resize <VOL> 30G --pool <POOL>  # Resize volume / Изменить размер тома
```

### Disk Image Operations / Операции с образами дисков
```bash
qemu-img create -f qcow2 <DISK>.qcow2 20G   # Create 20G disk / Создать диск 20G
qemu-img info <DISK>.qcow2                   # Show image info / Информация об образе
qemu-img resize <DISK>.qcow2 +10G            # Grow disk / Увеличить диск на 10G
qemu-img convert -f raw -O qcow2 <SRC>.raw <DST>.qcow2  # Convert format / Конвертировать формат
qemu-img snapshot -l <DISK>.qcow2            # List internal snapshots / Список внутренних снимков
qemu-img snapshot -c <SNAP_NAME> <DISK>.qcow2  # Create internal snapshot / Создать внутренний снимок
```

> [!WARNING]
> Shrinking a qcow2 image is dangerous and can corrupt data. Always grow, never shrink without a full backup.
> Уменьшение образа qcow2 опасно и может повредить данные. Всегда увеличивайте, никогда не уменьшайте без полного бэкапа.

### Block Device Operations / Операции с блочными устройствами
```bash
virsh domblkinfo <VM_NAME> <DISK>       # Block device info / Информация о блочном устройстве
virsh domblkstat <VM_NAME> <DISK>       # Block I/O statistics / Статистика ввода-вывода
virsh domblklist <VM_NAME> --details    # List all disks with details / Список всех дисков с деталями

# Block commit — merge overlay into backing file / Блочное слияние — слить overlay в backing-файл
virsh blockcommit <VM_NAME> <DISK> --base <BASE>.qcow2 --top <TOP>.qcow2 --active --wait
virsh blockcommit <VM_NAME> <DISK> --base <BASE>.qcow2 --top <TOP>.qcow2 --wait  # Commit & pivot / Слить и переключить

# Block copy — copy disk to new file (live) / Блочное копирование — скопировать диск в новый файл (на лету)
virsh blockcopy <VM_NAME> <DISK> <NEW_PATH>.qcow2 --wait --pivot  # Copy & pivot / Копировать и переключить
virsh blockcopy <VM_NAME> <DISK> <NEW_PATH>.qcow2 --wait          # Copy without pivot / Копировать без переключения

# Block resize — grow disk online / Изменение размера блока — увеличить диск онлайн
virsh blockresize <VM_NAME> <DISK> 30G --live
```

**Sample `virsh domblkinfo` output:**
```
Capacity:       21474836480
Physical:       21474836480
Allocation:     1073741824
Virtual size:   21474836480
```

> [!TIP]
> `blockcommit --active` keeps the VM running during the merge (dirty block tracking). Use `--pivot` to switch to the new top image after copy completes. Always snapshot before block operations.
> `blockcommit --active` поддерживает работу ВМ во время слияния (отслеживание изменённых блоков). Используйте `--pivot` для переключения на новый верхний образ после завершения копирования. Всегда создавайте снимок перед блочными операциями.

---

## Networking

### Virtual Networks / Виртуальные сети
```bash
virsh net-list --all                   # List all networks / Список всех сетей
virsh net-list --all --details         # Detailed network list / Детальный список сетей
virsh net-info <NETWORK>               # Network details / Детали сети
virsh net-dumpxml <NETWORK>            # Network XML / XML сети
virsh net-start <NETWORK>              # Start network / Запустить сеть
virsh net-destroy <NETWORK>            # Stop network / Остановить сеть
virsh net-autostart <NETWORK>          # Enable autostart / Включить автозапуск
virsh net-autostart --disable <NETWORK>  # Disable autostart / Отключить автозапуск
virsh net-dhcp-leases <NETWORK>        # Active DHCP leases / Активные DHCP аренды
```

### Create Virtual Network / Создание виртуальной сети
```bash
virsh net-define-as isolated-net isolated --bridge virbr1  # Define isolated network / Определить изолированную сеть
virsh net-start isolated-net           # Start network / Запустить сеть
virsh net-autostart isolated-net       # Autostart / Автозапуск
```

### Attach/Detach NIC / Подключение/отключение сетевой карты
```bash
virsh attach-interface <VM_NAME> network default --model virtio --live  # Attach NIC to network / Подключить НИС к сети
virsh detach-interface <VM_NAME> network --live  # Detach NIC / Отключить НИС
```

### Bridge Networking / Сетевой мост
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
> Сетевой мост даёт ВМ прямой доступ к физической LAN, делая их видимыми как отдельные хосты. NAT (по умолчанию) проще, но изолирует ВМ за хостом.

---

## Snapshots & Checkpoints

### Snapshot Operations / Операции со снимками
```bash
virsh snapshot-list <VM_NAME>          # List all snapshots / Список всех снимков
virsh snapshot-list <VM_NAME> --tree   # Tree view of snapshots / Древовидный вид снимков
virsh snapshot-info <VM_NAME> <SNAP>   # Snapshot details / Детали снимка
virsh snapshot-create <VM_NAME> <SNAP>.xml  # Create from XML / Создать из XML
virsh snapshot-create-as <VM_NAME> <SNAP_NAME> "Description"  # Create named snapshot / Создать именованный снимок
virsh snapshot-revert <VM_NAME> <SNAP> # Revert to snapshot / Откат к снимку
virsh snapshot-delete <VM_NAME> <SNAP> # Delete snapshot / Удалить снимку
virsh snapshot-current <VM_NAME>       # Show current snapshot / Показать текущий снимок
virsh snapshot-num <VM_NAME>           # Count snapshots / Подсчёт снимков
```

**Sample Output of `virsh snapshot-list`:**
```
 Name              Creation Time             State
--------------------------------------------------------------
 pre-update        2024-01-15 10:30:00 +0000 running
 post-update       2024-02-20 14:15:00 +0000 shutoff
```

### Snapshot XML Example / Пример XML снимка
```xml
<domainsnapshot>
  <name>pre-update</name>
  <description>Snapshot before system update</description>
  <memory snapshot="internal"/>  <!-- Include RAM / Включить RAM -->
  <disks>
    <disk name='vda' snapshot='internal'/>
  </disks>
</domainsnapshot>
```

### Checkpoint Operations / Операции с контрольными точками
```bash
virsh checkpoint-list <VM_NAME>         # List all checkpoints / Список всех контрольных точек
virsh checkpoint-list <VM_NAME> --tree  # Tree view / Древовидный вид
virsh checkpoint-info <VM_NAME> <CKPT>  # Checkpoint details / Детали контрольной точки
virsh checkpoint-create-as <VM_NAME> <CKPT_NAME> "Description"  # Create named checkpoint / Создать именованную точку
virsh checkpoint-create-as <VM_NAME> <CKPT_NAME> "Desc" --reuse / --no-shutdown  # Advanced options / Расширенные опции
virsh checkpoint-revert <VM_NAME> <CKPT> # Revert to checkpoint / Откат к контрольной точке
virsh checkpoint-delete <VM_NAME> <CKPT> # Delete checkpoint / Удалить контрольную точку
virsh checkpoint-current <VM_NAME>      # Show current checkpoint / Показать текущую точку
virsh checkpoint-dumpxml <VM_NAME> <CKPT>  # Checkpoint XML / XML контрольной точки
virsh domcheckpoint-set <VM_NAME> <CKPT_NAME>  # Set checkpoint name / Установить имя контрольной точки
virsh domcheckpoint-get <VM_NAME>       # Get checkpoint metadata / Получить метаданные контрольной точки
```

**Sample `virsh checkpoint-list` output:**
```
 Name             Creation Time             State
------------------------------------------------------------------
 pre-update       2024-01-15 10:30:00 +0000 running
 post-update      2024-02-20 14:15:00 +0000 shutoff
```

> [!NOTE]
> Checkpoints are similar to snapshots but also capture guest memory state. They require the QEMU guest agent for full memory capture. Use `--no-shutdown` for faster (but less consistent) checkpoints.
> Контрольные точки похожи на снимки, но также сохраняют состояние памяти гостя. Требуют QEMU guest agent для полного захвата памяти. Используйте `--no-shutdown` для более быстрых (но менее согласованных) контрольных точек.

---

## Migration

### Live Migration (Running VM) / Живая миграция (запущенная ВМ)
```bash
virsh migrate <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Live migrate / Живая миграция
virsh migrate --live <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Explicit live / Явно live
virsh migrate --persistent <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Make persistent on dest / Сделать постоянной на цели
virsh migrate --suspend <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Suspend after migration / Приостановить после миграции
virsh migrate --abort-on-error <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Abort on error / Прервать при ошибке
virsh migrate --unsafe <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Allow unsafe options / Разрешить небезопасные опции
```

> [!TIP]
> Live migration moves a running VM to another host with minimal downtime. The VM continues to run during migration. Requires shared or identical storage, and compatible CPU features on both hosts.
> Живая миграция переносит запущенную ВМ на другой хост с минимальным простоем. ВМ продолжает работать во время миграции. Требует общего или идентичного хранилища и совместимых возможностей CPU на обоих хостах.

### Offline Migration (Stopped VM) / Оффлайн миграция (остановленная ВМ)
```bash
virsh migrate <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Offline migrate (VM must be off) / Оффлайн миграция (ВМ должна быть выключена)
virsh migrate --offline <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Explicit offline / Явно offline
virsh migrate --offline --persistent <VM_NAME> qemu+ssh://<DEST_HOST>/system  # Persistent on dest / Постоянная на цели
```

> [!NOTE]
> Offline migration moves the VM definition and disk images. No downtime is needed since the VM is already off. Ensure sufficient disk space on the destination.
> Оффлайн миграция переносит определение ВМ и образы дисков. Простой не требуется, так как ВМ уже выключена. Убедитесь в достаточном месте на диске на целевом хосте.

### Migration Options / Опции миграции
| Option | Description (EN / RU) |
| :--- | :--- |
| `--live` | Live migration (running VM) / Живая миграция (запущенная ВМ) |
| `--offline` | Offline migration (stopped VM) / Оффлайн миграция (остановленная ВМ) |
| `--persistent` | Make VM persistent on destination / Сделать ВМ постоянной на цели |
| `--suspend` | Suspend VM after migration / Приостановить ВМ после миграции |
| `--abort-on-error` | Abort if migration error occurs / Прервать при ошибке миграции |
| `--unsafe` | Allow unsafe migration options / Разрешить небезопасные опции миграции |
| `--destxml` | Override destination XML / Переопределить XML назначения |
| `--copy-storage-all` | Copy all storage / Копировать все хранилище |
| `--copy-storage-inc` | Copy only new/changed storage / Копировать только новое/изменённое хранилище |

### Check Migration Progress / Проверка прогресса миграции
```bash
virsh domjobinfo <VM_NAME>             # Migration job info / Информация о задаче миграции
virsh domjobabort <VM_NAME>            # Abort migration / Прервать миграцию
```

---

## Templates & Cloning

### Create VM Template from Running VM / Создание шаблона ВМ из запущенной ВМ
```bash
virsh shutdown <VM_NAME>               # Graceful shutdown / Мягкое выключение
virsh dumpxml <VM_NAME> > template.xml # Export XML definition / Экспорт XML-определения
# Edit template.xml: remove UUID, MAC, name / Редактировать template.xml: удалить UUID, MAC, имя
virsh define template.xml              # Define template VM / Определить шаблонную ВМ
virsh autostart --disable template     # Disable autostart for template / Отключить автозапуск шаблона
```

> [!TIP]
> Set `autostart=disable` on template VMs to prevent them from booting accidentally. Templates should be kept in a clean, unconfigured state.
> Отключите автозапуск на шаблонных ВМ, чтобы предотвратить случайную загрузку. Шаблоны должны поддерживаться в чистом, не настроенном состоянии.

### Clone VM from Template / Клонирование ВМ из шаблона
```bash
virt-clone --original <TEMPLATE> --name <NEW_VM> --auto-clone  # Clone with auto-generated disk / Клонировать с автогенерацией диска
virt-clone --original <TEMPLATE> --name <NEW_VM> --file /var/lib/libvirt/images/<NEW_VM>.qcow2  # Clone to specific path / Клонировать в указанный путь
virt-clone --original <TEMPLATE> --name <NEW_VM> --file /var/lib/libvirt/images/<NEW_VM>.qcow2 --preserve  # Preserve original / Сохранить оригинал
```

> [!CAUTION]
> `virt-clone` requires the source VM to be shut off. Cloning a running VM will fail. Always shut down the template before cloning.
> `virt-clone` требует, чтобы исходная ВМ была выключена. Клонирование запущенной ВМ завершится ошибкой. Всегда выключайте шаблон перед клонированием.

### Customize Cloned VM / Настройка клонированной ВМ
```bash
virt-customize -a /var/lib/libvirt/images/<NEW_VM>.qcow2 --hostname <NEW_HOSTNAME>  # Set hostname / Установить имя хоста
virt-customize -a /var/lib/libvirt/images/<NEW_VM>.qcow2 --ssh-inject root:file:/root/.ssh/id_rsa.pub  # Inject SSH key / Внедрить SSH-ключ
virt-customize -a /var/lib/libvirt/images/<NEW_VM>.qcow2 --selinux-relabel  # Relabel SELinux / Переметить SELinux
```

---

## XML Editing & Device Management

### Edit VM XML / Редактирование XML ВМ
```bash
virsh edit <VM_NAME>                   # Edit VM XML in default editor / Редактировать XML ВМ в редакторе по умолчанию
virsh edit <VM_NAME> --skip-validation  # Skip XML validation / Пропустить валидацию XML
```

> [!TIP]
> `virsh edit` opens the XML in your default editor (usually `vi`). Always make a backup before editing. Use `--skip-validation` only when you need to fix invalid XML.
> `virsh edit` открывает XML в редакторе по умолчанию (обычно `vi`). Всегда делайте бэкап перед редактированием. Используйте `--skip-validation` только когда нужно исправить невалидный XML.

### Example: Add a New Disk / Пример: добавление нового диска
```bash
virsh dumpxml <VM_NAME> > vm.xml       # Backup XML / Бэкап XML
# Edit vm.xml, add within <devices>:
#   <disk type='file' device='disk'>
#     <driver name='qemu' type='qcow2'/>
#     <source file='/var/lib/libvirt/images/data.qcow2'/>
#     <target dev='vdb' bus='virtio'/>
#   </disk>
virsh define vm.xml                    # Apply changes / Применить изменения
```

### Example: Change CPU Count / Пример: изменение количества CPU
```bash
virsh setvcpus <VM_NAME> 8 --config    # Set to 8 vCPUs (next boot) / Установить 8 vCPU (при следующей загрузке)
virsh setvcpus <VM_NAME> 8 --live      # Hot-change (if supported) / Изменить на лету (если поддерживается)
```

### Example: Set Memory Limit / Пример: установка лимита памяти
```bash
virsh setmaxmem <VM_NAME> 16G --config # Set max memory / Установить макс. память
virsh setmem <VM_NAME> 8G --config     # Set current memory / Установить текущую память
```

### Update Devices / Обновление устройств
```bash
virsh update-device <VM_NAME> <DEVICE>.xml --live  # Update device on the fly / Обновить устройство на лету
```

---

## Security & Access Control

### SELinux / SELinux
```bash
chcon -t svirt_image_t /path/to/disk.qcow2           # Set correct SELinux label / Установить правильную метку SELinux
restorecon -Rv /var/lib/libvirt/images/               # Restore SELinux context / Восстановить контекст SELinux
getenforce                                         # Check SELinux mode / Проверить режим SELinux
sudo setenforce 0                                  # Set permissive (temporary) / Установить разрешающий (временно)
sudo setenforce 1                                  # Set enforcing (permanent) / Установить принудительный (постоянно)
```

### sVirt (Mandatory Access Control) / sVirt (управление обязательного доступа)
```bash
virsh dominfo <VM_NAME> | grep -i security           # Show VM security model / Показать модель безопасности ВМ
```

> [!NOTE]
> sVirt uses SELinux (or DAC) to confine each VM process, preventing VMs from accessing host files or other VMs' resources. This is critical for multi-tenant environments.
> sVirt использует SELinux (или DAC) для изоляции каждого процесса ВМ, предотвращая доступ ВМ к файлам хоста или ресурсам других ВМ. Это критически важно для мультитенантных сред.

### User Access Control / Управление доступом пользователей
`/etc/libvirt/libvirtd.conf`

```conf
unix_sock_group = "libvirt"           # Grant access to libvirt group / Предоступить доступ группе libvirt
unix_sock_ro_perms = "0777"           # Read-only socket permissions / Права только для чтения
unix_sock_rw_perms = "0770"           # Read-write socket permissions / Права чтения-записи
auth_unix_ro = "none"                 # No auth for read-only / Без аутентификации для чтения
auth_unix_rw = "polkit"              # Polkit for read-write / Polkit для чтения-записи
```

> [!CAUTION]
> Using `auth_unix_ro = "none"` and `auth_unix_rw = "none"` disables authentication. Only use in isolated environments. For production, use `polkit`.
> Использование `auth_unix_ro = "none"` и `auth_unix_rw = "none"` отключает аутентификацию. Используйте только в изолированных средах. В продакшене используйте `polkit`.

---

## Host & Hypervisor Info

### System Information / Информация о системе
```bash
virsh nodeinfo                        # Host system info (CPU, memory, NUMA) / Информация о хосте (CPU, память, NUMA)
virsh capabilities                    # Hypervisor capabilities / Возможности гипервизора
virsh sysinfo                         # SMBIOS/DMI system info / Информация SMBIOS/DMI системы
```

**Sample Output of `virsh nodeinfo`:**
```
CPU model:           x86_64
CPU(s):              16
CPU frequency:       3600 MHz
CPU socket(s):       1
Core(s) per socket:  8
Thread(s) per core:  2
NUMA cell(s):        1
Memory size:         32768 MiB
```

### Hypervisor Capabilities / Возможности гипервизора
```bash
virsh capabilities | grep -i kvm      # Check KVM support / Проверить поддержку KVM
```

---

## Advanced Operations

### Managed Save / Управляемое сохранение
```bash
virsh managedsave <VM_NAME>            # Save VM state to disk / Сохранить состояние ВМ на диск
virsh managedsave-remove <VM_NAME>     # Remove saved state / Удалить сохранённое состояние
virsh managedsave-dumpxml <VM_NAME>    # Dump saved state XML / Выгрузить XML сохранённого состояния
virsh start <VM_NAME> --from-saved    # Start from saved state / Запустить из сохранённого состояния
```

### Statistics & Monitoring / Статистика и мониторинг
```bash
virsh domstats <VM_NAME>               # Domain statistics / Статистика домена
virsh domstats <VM_NAME> --vcpu        # vCPU stats only / Статистика vCPU
virsh domstats <VM_NAME> --disk        # Disk stats only / Статистика дисков
virsh domstats <VM_NAME> --interface   # Network stats only / Статистика сети
virsh domstats <VM_NAME> --memory      # Memory stats only / Статистика памяти
virsh domstats <VM_NAME> --state       # State only / Только состояние
virsh domstats <VM_NAME> --list-active # All active domains / Все активные домены
virsh domstats <VM_NAME> --list-all     # All domains / Все домены

# Host-level statistics / Статистика уровня хоста
virsh nodecpustats                     # Host CPU statistics / Статистика CPU хоста
virsh nodecpustats --cpu 0             # CPU 0 stats / Статистика CPU 0
virsh nodecpuinfo                      # Host CPU info / Информация о CPU хоста
virsh nodecpumap                       # Host CPU map / Карта CPU хоста
virsh nodeinfo                         # Host node info / Информация об узле
virsh node-memory-stats                # Host memory statistics / Статистика памяти хоста

# Memory & device stats / Статистика памяти и устройств
virsh dommemstat <VM_NAME>             # Memory statistics / Статистика памяти
virsh domblkstat <VM_NAME> <DISK>      # Disk I/O statistics / Статистика ввода-вывода диска
virsh domifstat <VM_NAME> <IFACE>      # Network interface stats / Статистика сетевого интерфейса
virsh domjobinfo <VM_NAME>             # Current job info (migration etc.) / Инфо о текущей задаче (миграция и т.д.)
virsh domjobabort <VM_NAME>            # Abort current job / Прервать текущую задачу
```

**Sample `virsh domstats <VM_NAME>` output:**
```
Domain: '<VM_NAME>'
  state:running
  cpu.time:123456789
  balloon.current:4194304
  balloon.actual:4194304
  disk.path:/var/lib/libvirt/images/<VM_NAME>.qcow2
  disk.read.bytes:1048576
  disk.read.reqs:10
  disk.write.bytes:2097152
  disk.write.reqs:20
```

### CPU Feature Control / Управление функциями CPU
```bash
virsh cpu-baseline <CPU_MODEL>.xml --connect qemu:///system  # Baseline CPU features / Базовые функции CPU
virsh cpu-features <VM_NAME> --pretty    # VM CPU features / Функции CPU ВМ
virsh cpu-models                       # List CPU models / Список моделей CPU
virsh domcapabilities                  # Host hypervisor capabilities / Возможности гипервизора хоста
virsh domcapabilities --arch <ARCH>    # Capabilities for specific arch / Возможности для конкретной архитектуры
virsh domcapabilities --machine <MACHINE>  # Capabilities for machine type / Возможности для типа машины
```

**Sample `virsh domcapabilities` output:**
```
<domCapabilities>
  <guest supported='yes'>
    <os_type>hvm</os_type>
    <arch name='x86_64'>
      <machine canonical='pc-q35-8.2'>pc-q35-8.2</machine>
      ...
    </arch>
  </guest>
</domCapabilities>
```

### Guest Administration / Администрирование гостя
```bash
# Set guest user password (requires qemu-guest-agent) / Установить пароль пользователя гостя (требует qemu-guest-agent)
virsh set-user-password <VM_NAME> <USERNAME> --password
virsh set-user-password <VM_NAME> <USERNAME> --password <SECRET_PASSWORD>
virsh set-user-password <VM_NAME> <USERNAME> --crypted <HASH>  # Crypted password / Шифрованный пароль

# Guest info via agent / Информация о госте через агент
virsh guestinfo <VM_NAME>              # All guest info / Вся информация о госте
virsh guestinfo <VM_NAME> --user       # User info only / Только информация о пользователе
virsh guestinfo <VM_NAME> --os         # OS info only / Только информация об ОС
virsh guestinfo <VM_NAME> --disk       # Disk info only / Только информация о дисках
virsh guestinfo <VM_NAME> --iface      # Interface info only / Только информация об интерфейсах
virsh guestinfo <VM_NAME> --hostname   # Hostname only / Только имя хоста

# TRIM/Discard (fstrim) / TRIM/Discard (fstrim)
virsh domfstrim <VM_NAME>              # Issue TRIM to guest / Отправить TRIM гостю
virsh domfstrim <VM_NAME> --min 1      # Min free space for TRIM / Мин. свободное место для TRIM
```

> [!CAUTION]
> `set-user-password` and `guestinfo` require `qemu-guest-agent` installed and running inside the VM. If the agent is not available, these commands will fail.
> `set-user-password` и `guestinfo` требуют установленного и запущенного `qemu-guest-agent` внутри ВМ. Если агент недоступен, эти команды завершатся ошибкой.

### VM Lifecycle Summary / Сводка жизненного цикла ВМ

| State | Description (EN / RU) |
| :--- | :--- |
| **running** | VM is active and running / ВМ активна и работает |
| **paused** | VM is suspended (frozen) / ВМ приостановлена (заморожена) |
| **shutoff** | VM is turned off / ВМ выключена |
| **saved** | VM state saved to disk / Состояние ВМ сохранено на диск |
| **pmsuspended** | VM suspended by power management / ВМ приостановлена управлением питанием |

### Trigger Crash Dump / Запуск аварийного дампа
```bash
virsh crashdump <VM_NAME> --trigger  # Trigger crash dump (if configured) / Запустить аварийный дамп (если настроено)
```

### Freeze/Thaw Filesystem / Заморозка/разморозка ФС
```bash
virsh domfsfreeze <VM_NAME>           # Freeze guest filesystem (for consistent snapshots) / Заморозить ФС гостя
virsh domfsthaw <VM_NAME>             # Thaw guest filesystem / Разморозить ФС гостя
```

> [!TIP]
> Use `virsh domfsfreeze` before creating a snapshot to ensure filesystem consistency. Always call `virsh domfsthaw` afterwards, even if snapshot creation fails.
> Используйте `virsh domfsfreeze` перед созданием снимка для обеспечения согласованности файловой системы. Всегда вызывайте `virsh domfsthaw` после, даже если создание снимка завершилось неудачно.

### Domstate Codes / Коды состояний
```bash
virsh domstate <VM_NAME>               # Raw state / Необработанное состояние
virsh domstate <VM_NAME> --reason      # State with reason / Состояние с причиной
```

**State Codes / Коды состояний:**
| Code | Description (EN / RU) |
| :--- | :--- |
| `running` | VM is running / ВМ работает |
| `idle` | VM is idle (waiting for I/O) / ВМ в ожидании (ввода-вывода) |
| `paused` | VM is paused / ВМ приостановлена |
| `shutdown` | VM is shutting down / ВМ выключается |
| `shut off` | VM is off / ВМ выключена |
| `crashed` | VM has crashed / ВМ аварийно завершилась |
| `suspended` | VM is suspended (e.g., by PM) / ВМ приостановлена (напр., управлением питанием) |

### State Reason Codes / Коды причин состояний
| Code | Description (EN / RU) |
| :--- | :--- |
| `booted` | Started after boot / Запущена после загрузки |
| `migrated` | Migrated to/from / Мигрирована на/с |
| `saved` | Restored from saved state / Восстановлена из сохранённого состояния |
| `failed` | Failed to start / Ошибка при запуске |
| `crashed` | VM crashed / ВМ аварийно завершилась |
| `paused` | Paused by user / Приостановлена пользователем |
| `shutdown` | Shutting down / Выключается |
| `destroyed` | Force destroyed / Принудительно завершена |
| `daunted` | Domain became dormant / Домен перешл в спящий режим |
| `unknown` | Unknown reason / Неизвестная причина |

---

## Troubleshooting

### Common Issues / Типичные проблемы

#### "error: failed to get connection driver" / Ошибка: не удалось получить драйвер подключения
```bash
virsh -c qemu:///system list           # Test connection / Проверить подключение
sudo systemctl status libvirtd        # Check daemon status / Проверить статус демона
sudo systemctl restart libvirtd       # Restart daemon / Перезапустить демон
```

#### "error: Cannot check QEMU binary /libvirt/qemu/bin/qemu-system-x86_64" / Ошибка: не удалось проверить бинарник QEMU
```bash
which qemu-system-x86_64              # Check if QEMU is installed / Проверить установку QEMU
sudo apt install qemu-kvm             # Install QEMU (Debian/Ubuntu) / Установить QEMU (Debian/Ubuntu)
sudo dnf install qemu-kvm             # Install QEMU (RHEL/CentOS) / Установить QEMU (RHEL/CentOS)
```

#### "error: Unable to open /dev/kvm" / Ошибка: Unable to open /dev/kvm
```bash
ls -la /dev/kvm                       # Check KVM device / Проверить устройство KVM
sudo modprobe kvm_intel               # Load Intel KVM module / Загрузить модуль KVM Intel
sudo modprobe kvm_amd                 # Load AMD KVM module / Загрузить модуль KVM AMD
sudo usermod -aG kvm <USER>           # Add user to kvm group / Добавить пользователя в группу kvm
```

#### "error: internal error: Failed to initialize a valid firewall backend" / Ошибка: Failed to initialize firewall backend
```bash
sudo apt install ebtables bridge-utils  # Install required packages (Debian/Ubuntu) / Установить пакеты (Debian/Ubuntu)
sudo dnf install ebtables bridge-utils  # Install required packages (RHEL/CentOS) / Установить пакеты (RHEL/CentOS)
sudo systemctl restart libvirtd         # Restart after install / Перезапустить после установки
```

#### "error: cannot create/read/write pid file /var/run/libvirt/libvirtd.pid" / Ошибка: Cannot create/read/write pid file
```bash
sudo mkdir -p /var/run/libvirt         # Create directory / Создать каталог
sudo chown root:root /var/run/libvirt  # Set ownership / Установить владельца
```

#### VM Won't Start / ВМ не запускается
```bash
virsh domstate <VM_NAME>               # Check state / Проверить состояние
virsh dumpxml <VM_NAME>                # Inspect XML config / Проверить XML-конфигурацию
journalctl -u libvirtd -n 50           # Check daemon logs / Проверить логи демона
cat /var/log/libvirt/qemu/<VM_NAME>.log  # Check QEMU logs / Проверить логи QEMU
```

#### Networking Issues / Проблемы с сетью
```bash
virsh net-list --all --state-running   # Check active networks / Проверить активные сети
virsh net-info default                 # Check default network / Проверить сеть по умолчанию
ip addr show virbr0                    # Check bridge interface / Проверить интерфейс моста
sudo iptables -L -n                    # Check firewall rules / Проверить правила файрвола
```

#### Storage Issues / Проблемы с хранилищем
```bash
virsh pool-list --all --state-running  # Check active pools / Проверить активные пулы
virsh pool-info <POOL>                 # Pool details / Детали пула
df -h                                  # Check disk space / Проверить место на диске
ls -la /var/lib/libvirt/images/        # Check images directory / Проверить каталог образов
```

---

## Comparison Tables

### Internal vs External Snapshots / Внутренние vs внешние снимки

| Feature | Internal Snapshots | External Snapshots |
| :--- | :--- | :--- |
| **Storage** | Stored within the qcow2 file / Хранятся в файле qcow2 | Stored as separate files / Хранятся как отдельные файлы |
| **Performance** | Slower (requires qcow2 metadata reads) / Медленнее (требует чтения метаданных qcow2) | Faster (direct I/O to base) / Быстрее (прямой I/O к базе) |
| **Chain** | Creates internal chain / Создаёт внутреннюю цепочку | Creates external chain / Создаёт внешнюю цепочку |
| **Rollback** | Simple revert / Простой откат | Requires metadata management / Требует управления метаданными |
| **Disk Space** | Grows with snapshots / Увеличивается с снимками | Pre-allocated / Предварительно выделяется |
| **Best For** | Simple setups / Простые конфигурации | Production, large VMs / Продакшен, крупные ВМ |

### Live vs Offline Migration / Живая vs оффлайн миграция

| Feature | Live Migration | Offline Migration |
| :--- | :--- | :--- |
| **VM State** | Running / Запущена | Stopped / Остановлена |
| **Downtime** | Minimal (ms to sec) / Минимальный (мсек — сек) | Full stop / Полная остановка |
| **Data Transfer** | Memory pages + disk sync / Страницы памяти + синхронизация дисков | Disk images only / Только образы дисков |
| **Duration** | Depends on RAM usage / Зависит от использования RAM | Depends on disk size / Зависит от размера дисков |
| **Network** | Requires fast, stable network / Требует быстрой стабильной сети | Can use any method / Может использовать любой метод |
| **Best For** | Zero-downtime migration / Миграция без простоя | Scheduled maintenance / Плановое обслуживание |

---

## Quick Reference Cards

### VM Lifecycle Commands / Команды жизненного цикла ВМ
```
virsh list --all                    # List all VMs / Список всех ВМ
virsh start <VM>                    # Start / Запустить
virsh shutdown <VM>                 # Graceful shutdown / Мягкое выключение
virsh destroy <VM>                  # Force stop / Принудительная остановка
virsh reboot <VM>                   # Reboot / Перезагрузка
virsh suspend <VM>                  # Pause / Приостановка
virsh resume <VM>                   # Resume / Возобновление
virsh undefine <VM>                 # Remove definition / Удалить определение
virsh autostart <VM>                # Enable autostart / Включить автозапуск
virsh autostart --disable <VM>      # Disable autostart / Отключить автозапуск
virsh dumpxml <VM>                  # Export XML / Экспорт XML
virsh edit <VM>                     # Edit XML / Редактирование XML
virsh console <VM>                  # Serial console / Серийная консоль
virsh dominfo <VM>                  # VM info / Информация о ВМ
```

### Storage Commands / Команды хранилища
```
virsh pool-list --all               # List pools / Список пулов
virsh pool-info <POOL>              # Pool info / Информация о пуле
virsh pool-start <POOL>             # Start pool / Запустить пул
virsh pool-destroy <POOL>           # Destroy pool / Уничтожить пул
virsh vol-list <POOL>               # List volumes / Список томов
virsh vol-create-as <POOL> <VOL> 20G  # Create volume / Создать том
```

### Network Commands / Команды сети
```
virsh net-list --all                # List networks / Список сетей
virsh net-info <NET>                # Network info / Информация о сети
virsh net-start <NET>               # Start network / Запустить сеть
virsh net-destroy <NET>             # Stop network / Остановить сеть
virsh net-dhcp-leases <NET>         # DHCP leases / DHCP аренды
```

### Snapshot & Checkpoint Commands / Команды снимков и контрольных точек
```
virsh snapshot-list <VM>            # List snapshots / Список снимков
virsh snapshot-create-as <VM> <NAME> "desc"  # Create snapshot / Создать снимок
virsh snapshot-revert <VM> <NAME>   # Revert / Откатить
virsh snapshot-delete <VM> <NAME>   # Delete / Удалить
virsh snapshot-current <VM>         # Current snapshot / Текущий снимок

virsh checkpoint-list <VM>          # List checkpoints / Список контрольных точек
virsh checkpoint-create-as <VM> <NAME> "desc"  # Create checkpoint / Создать контрольную точку
virsh checkpoint-revert <VM> <NAME> # Revert checkpoint / Откат к контрольной точке
virsh checkpoint-delete <VM> <NAME> # Delete checkpoint / Удалить контрольную точку
virsh checkpoint-current <VM>       # Current checkpoint / Текущая контрольная точка
```

### CPU & NUMA Commands / Команды CPU и NUMA
```
virsh vcpupin <VM> <VCPU> <PCPU> --live  # Pin vCPU to pCPU / Привязать vCPU к pCPU
virsh vcpupin <VM> --current             # Show pinning / Показать привязку
virsh numatune <VM> --memnodes 0-1 --memorymode preferred --live  # NUMA memory policy / NUMA-политика
virsh setvcpus <VM> <N> --live           # Hot-change vCPU / Изменить vCPU на летu
virsh dominfo <VM> | grep numa           # NUMA topology / Топология NUMA
```

### Statistics & Monitoring Commands / Команды статистики и мониторинга
```
virsh domstats <VM>                 # Domain statistics / Статистика домена
virsh domstats <VM> --list-active   # All active domains / Все активные домены
virsh nodecpustats                  # Host CPU stats / Статистика CPU хоста
virsh nodeinfo                      # Host node info / Информация об узле
virsh dommemstat <VM>               # Memory stats / Статистика памяти
virsh domblkstat <VM> <DISK>        # Disk I/O stats / Статистика диска
virsh domjobinfo <VM>               # Current job info / Инфо о текущей задаче
```

### Block Operations / Блочные операции
```
virsh domblkinfo <VM> <DISK>        # Block device info / Инфо о блочном устройстве
virsh domblklist <VM> --details     # List all disks / Список всех дисков
virsh blockcommit <VM> <DISK> --base <BASE> --top <TOP> --active --wait  # Commit / Слить
virsh blockcopy <VM> <DISK> <PATH> --wait --pivot  # Copy & pivot / Копировать и переключить
virsh blockresize <VM> <DISK> <SIZE> --live        # Resize disk / Изменить размер диска
```

### Guest Administration Commands / Команды администрирования гостя
```
virsh set-user-password <VM> <USER> --password  # Set password / Установить пароль
virsh guestinfo <VM>                 # All guest info / Вся информация о госте
virsh guestinfo <VM> --os            # OS info only / Только информация об ОС
virsh guestinfo <VM> --hostname      # Hostname only / Только имя хоста
virsh domfstrim <VM>                 # TRIM/TRIM discard / TRIM/Discard
virsh qemu-monitor-command <VM> --hmp "info status"  # HMP status / Статус через HMP
virsh qemu-agent-command <VM> '{"execute":"guest-info"}'  # Agent info / Инфо агента
```

### Migration Commands / Команды миграции
```
virsh migrate <VM> qemu+ssh://<HOST>/system  # Migrate / Мигрировать
virsh migrate --live <VM> qemu+ssh://<HOST>/system  # Live migrate / Живая миграция
virsh domjobinfo <VM>               # Migration progress / Прогресс миграции
virsh domjobabort <VM>              # Abort migration / Прервать миграцию
```

### One-Line Patterns / Однострочные шаблоны
```bash
# List all running VMs / Список всех запущенных ВМ
virsh list --state-running --name

# Start all stopped VMs / Запустить все остановленные ВМ
virsh list --inactive --name | xargs -I{} virsh start {}

# Show all VM IPs (requires guest agent) / Показать все IP ВМ (нужен гостевой агент)
for vm in $(virsh list --name); do echo "$vm: $(virsh domifaddr $vm 2>/dev/null | awk 'NR>2{print $4}')"; done

# Bulk snapshot creation / Массовое создание снимков
for vm in $(virsh list --name); do virsh snapshot-create-as $vm "backup-$(date +%Y%m%d)" "Daily backup"; done

# Show VM disk usage / Показать использование дисков ВМ
for vm in $(virsh list --name); do echo "$vm:"; virsh domblkinfo $vm vda 2>/dev/null | grep -E "Capacity|Allocation"; done
```

---

## Logrotate Configuration

### Libvirt Logrotate / Настройка logrotate для libvirt
`/etc/logrotate.d/libvirt-qemu`

```
/var/log/libvirt/qemu/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 libvirt-qemu kvm
    sharedscripts
    postrotate
        /usr/lib/libvirt/libvirt_lxc 2>/dev/null || true
    endscript
}
```

```bash
sudo logrotate -d /etc/logrotate.d/libvirt-qemu  # Test logrotate config / Тестировать конфигурацию logrotate
sudo logrotate -f /etc/logrotate.d/libvirt-qemu  # Force rotation / Принудительная ротация
```

### Per-VM Log Configuration / Конфигурация логов для каждой ВМ
```bash
# Enable per-VM logging in libvirtd.conf / Включить логирование для каждой ВМ в libvirtd.conf
# Set in /etc/libvirt/qemu.conf:
# log_timestamp = 1
# user = "root"
# group = "kvm"
```

---

## Documentation Links

### Official Documentation / Официальная документация
- [virsh man page](https://man7.org/linux/man-pages/man1/virsh.1.html) — virsh command reference / Справочник команд virsh
- [libvirt documentation](https://libvirt.org/docs.html) — Official libvirt docs / Официальная документация libvirt
- [libvirt.org](https://libvirt.org) — Project homepage / Домашняя страница проекта

### Tutorials & Guides / Учебники и руководства
- [KVM Virtualization](https://wiki.archlinux.org/title/KVM) — Arch Wiki KVM guide / Руководство KVM из Arch Wiki
- [Ubuntu KVM Guide](https://ubuntu.com/tutorials/kvm-install-vm) — Ubuntu KVM tutorial / Учебник KVM от Ubuntu
- [Red Hat Virtualization](https://access.redhat.com/documentation/en-us/red_hat_virtualization/) — RHEL docs / Документация RHEL

### Related Tools / Связанные инструменты
- [virt-manager](https://virt-manager.org/) — GUI management tool / GUI инструмент управления
- [Cockpit](https://cockpit-project.org/) — Web management interface / Веб-интерфейс управления
- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview) — Enterprise virtualization platform / Корпоративная платформа виртуализации
- [oVirt](https://www.ovirt.org/) — Open-source virtualization / Open-source виртуализация
