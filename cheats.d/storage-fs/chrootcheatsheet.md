Title: 🐧 Chroot Cheatsheet
Group: Storage & FS
Icon: 🐧
Order: 4

# Chroot — Change Root Environment

**Chroot (change root)** is an operation that changes the apparent root directory (`/`) for the current running process and its children. It creates an isolated filesystem environment by making a directory appear as the root of the filesystem hierarchy.

Chroot is a fundamental Unix concept (since V7 Unix, 1979) and is built into the Linux kernel. It is **not** a full security sandbox — processes inside chroot can escape if they have root privileges (see `pivot_root` for stronger isolation). For full containerization, use namespaces (Docker, LXC) or VMs.

**Common use cases / Типичные сценарии:**
- **System recovery:** Fixing a non-booting system from a live USB/CD
- **Bootloader repair:** Reinstalling or updating GRUB from a rescue environment
- **Package management:** Installing/removing packages on an unmounted root filesystem
- **Build environments:** Creating isolated build environments (e.g., `debootstrap`)
- **Testing:** Testing software in a minimal filesystem environment

**Modern alternatives / Современные альтернативы:**
- `systemd-nspawn` — lightweight container-like chroot with better isolation
- `unshare` + `chroot` — add namespace isolation to chroot
- `bubblewrap` — unprivileged sandboxing
- Docker/Podman — full containerization

📚 **Official Docs / Официальная документация:**
[chroot(1)](https://man7.org/linux/man-pages/man1/chroot.1.html) · [chroot(2)](https://man7.org/linux/man-pages/man2/chroot.2.html) · [mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html) · [arch-chroot](https://man.archlinux.org/man/arch-chroot.8)

## Table of Contents
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Comparison: BIOS vs UEFI](#comparison-bios-vs-uefi)
- [Comparison: Chroot vs Alternatives](#comparison-chroot-vs-alternatives)
- [Troubleshooting & Tips](#troubleshooting--tips)
- [Production Runbook: System Recovery via Chroot](#production-runbook-system-recovery-via-chroot)

---

## Core Management / Основное управление

### 1. Identify Partitions / Определение разделов
Identify the root, boot, and EFI partitions before mounting.

```bash
lsblk -f       # List disks and partitions with filesystems / Список дисков и разделов
blkid          # Show UUIDs of partitions / Показать UUID разделов
fdisk -l       # List partition tables / Показать таблицы разделов
```

### 2. Mount Root Filesystem / Монтирование корневой системы
Mount the main partition where the OS is installed.

```bash
mkdir -p /mnt/sysroot             # Create mount point / Создать точку монтирования
mount /dev/sdXN /mnt/sysroot      # Mount root partition / Смонтировать корневой раздел
```

### 3. Mount System Directories / Монтирование системных директорий
Bind essential system virtual filesystems to the new root.

```bash
mount --bind /dev  /mnt/sysroot/dev     # Bind devices / Пробросить устройства
mount --bind /proc /mnt/sysroot/proc    # Bind processes / Пробросить процессы
mount --bind /sys  /mnt/sysroot/sys     # Bind system info / Пробросить системную информацию
mount --bind /run  /mnt/sysroot/run     # Bind runtime data / Пробросить данные выполнения
```

> [!TIP]
> On UEFI systems, also mount the EFI partition and efivars:
> На UEFI системах также смонтируйте EFI раздел и efivars:
> ```bash
> mount /dev/sdXZ /mnt/sysroot/boot/efi
> mount --bind /sys/firmware/efi/efivars /mnt/sysroot/sys/firmware/efi/efivars
> ```

### 4. Enter Chroot Environment / Вход в окружение Chroot
Switch to the mounted system environment.

```bash
chroot /mnt/sysroot /bin/bash    # Enter using Bash / Войти через Bash
# OR / ИЛИ
chroot /mnt/sysroot /bin/sh      # Fallback to SH / Войти через SH
```

> [!TIP]
> On Arch-based systems, use `arch-chroot /mnt/sysroot` — it auto-mounts `/proc`, `/sys`, `/dev`, and `/run` for you.
> На системах Arch используйте `arch-chroot /mnt/sysroot` — он автоматически монтирует `/proc`, `/sys`, `/dev` и `/run`.

### 5. Exit and Cleanup / Выход и очистка
Always unmount recursively to ensure all bind mounts are released.

```bash
exit                             # Exit chroot / Выйти из chroot
umount -R /mnt/sysroot           # Recursive unmount / Рекурсивное размонтирование
```

> [!CAUTION]
> Failure to unmount correctly before rebooting can occasionally lead to filesystem synchronization issues. Always use `umount -R` or unmount in reverse order.
> Несвоевременное размонтирование перед перезагрузкой может привести к проблемам синхронизации файловой системы. Всегда используйте `umount -R` или размонтируйте в обратном порядке.

---

## Sysadmin Operations / Операции системного администратора

### Kernel & Initramfs Management / Управление ядром и Initramfs
Rebuilding the initial ramdisk after kernel updates.

```bash
ls /boot                                  # List kernels / Список ядер
dpkg -l | grep linux-image                # Check installed kernels (Debian/Ubuntu) / Проверить установленные ядра
rpm -qa | grep kernel                     # Check installed kernels (RHEL/CentOS) / Проверить установленные ядра
update-initramfs -u -k <kernel-version>   # Update specific kernel / Обновить конкретное ядро
update-initramfs -u -k all                # Update all kernels / Обновить все ядра
dracut --force                            # Regenerate initramfs (RHEL/Fedora) / Пересоздать initramfs
```

### Bootloader Repair (GRUB) / Восстановление загрузчика (GRUB)
Installing and updating the GRUB configuration.

```bash
# BIOS Version:
update-grub                               # Update config / Обновить конфигурацию

# UEFI Version:
grub-install /dev/sdX                     # Install bootloader to disk / Установить загрузчик на диск
update-grub                               # Update config / Обновить конфигурацию

# RHEL/Fedora equivalent:
grub2-mkconfig -o /boot/grub2/grub.cfg    # Regenerate GRUB config / Пересоздать конфиг GRUB
```

### DNS Resolution Inside Chroot / DNS разрешение внутри Chroot

```bash
# Copy DNS config into chroot / Скопировать DNS конфиг в chroot
cp /etc/resolv.conf /mnt/sysroot/etc/resolv.conf

# This is required for network-dependent operations like apt/dnf
# Это необходимо для сетевых операций, таких как apt/dnf
```

---

## Comparison: BIOS vs UEFI / Сравнение: BIOS и UEFI

| Feature | BIOS (Legacy) | UEFI |
| :--- | :--- | :--- |
| **Boot Partition** | Often optional or integrated. | **MANDATORY** FAT32 EFI System Partition (ESP). |
| **Mounting** | `mount /dev/sdXY /mnt/sysroot/boot` | `mount /dev/sdXZ /mnt/sysroot/boot/efi` |
| **Firmware Bits** | N/A | `mount --bind /sys/firmware/efi/efivars ...` |
| **Partition Table** | MBR (max 2TB, 4 primary partitions) | GPT (no practical size limit, 128 partitions) |
| **Secure Boot** | Not supported | Supported |
| **Why?** | Simple MBR-based boot. | Modern, supports Secure Boot and GPT > 2TB. |

---

## Comparison: Chroot vs Alternatives / Сравнение: Chroot и альтернативы

| Feature | `chroot` | `systemd-nspawn` | Docker/Podman |
| :--- | :--- | :--- | :--- |
| **Isolation level** | Filesystem only | Filesystem + PID + Network | Full (cgroups + namespaces) |
| **Requires root** | Yes | Yes | No (rootless mode) |
| **Network isolation** | No | Optional | Yes |
| **Setup complexity** | Minimal | Low | Medium |
| **Best for** | System recovery | Build/test environments | Application deployment |
| **Escape risk** | High (root can escape) | Medium | Low |

---

## Troubleshooting & Tips / Устранение неполадок и советы

### Common Fixes / Типичные исправления
If the system fails to boot after an update, reinstalling the kernel often helps.

```bash
apt update                                # Update package lists / Обновить списки пакетов
apt install --reinstall linux-image-generic # Reinstall kernel / Переустановить ядро
update-initramfs -u -k all                # Rebuild images / Пересобрать образы
update-grub                               # Refresh GRUB / Обновить GRUB
```

> [!TIP]
> Use `ls -lh /boot` to verify that both `vmlinuz-*` (kernel) and `initrd.img-*` (initramfs) pairs exist for your version.

### Log Locations / Расположение логов
Checking logs inside chroot after a failed boot attempt.

| Log Path | Description (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `/var/log/syslog` | General system logs (Debian/Ubuntu) | Общие системные логи |
| `/var/log/messages` | General system logs (RHEL/CentOS) | Общие системные логи |
| `/var/log/apt/history.log` | Package history | История установки пакетов |
| `/var/log/boot.log` | Boot process logs | Логи процесса загрузки |
| `/var/log/kern.log` | Kernel messages | Сообщения ядра |

### Common Chroot Problems / Типичные проблемы Chroot

```bash
# "bash: command not found" inside chroot
# Verify /bin and /usr/bin exist in chroot / Проверить наличие /bin и /usr/bin
ls /mnt/sysroot/bin /mnt/sysroot/usr/bin

# "Could not resolve host" inside chroot
# Copy resolv.conf / Скопировать resolv.conf
cp /etc/resolv.conf /mnt/sysroot/etc/resolv.conf

# "Permission denied" on commands inside chroot
# Ensure /dev is properly bind-mounted / Убедитесь, что /dev правильно примонтирован
mount --bind /dev /mnt/sysroot/dev

# Cannot run systemd commands inside chroot
# systemd requires PID 1 — use systemd-nspawn instead
# systemd требует PID 1 — используйте systemd-nspawn
```

---

## Production Runbook: System Recovery via Chroot

### Scenario: System won't boot after kernel update / Система не загружается после обновления ядра

1. **Boot from Live USB/CD** / Загрузиться с Live USB/CD

2. **Identify partitions** / Определить разделы:
```bash
lsblk -f
```

3. **Mount root filesystem** / Смонтировать корневую систему:
```bash
mount /dev/sdXN /mnt/sysroot
```

4. **Mount virtual filesystems** / Примонтировать виртуальные ФС:
```bash
mount --bind /dev  /mnt/sysroot/dev
mount --bind /proc /mnt/sysroot/proc
mount --bind /sys  /mnt/sysroot/sys
mount --bind /run  /mnt/sysroot/run
```

5. **Mount EFI** (UEFI systems only) / Примонтировать EFI (только UEFI):
```bash
mount /dev/sdXZ /mnt/sysroot/boot/efi
```

6. **Enter chroot** / Войти в chroot:
```bash
chroot /mnt/sysroot /bin/bash
```

7. **Fix the system** / Исправить систему:
```bash
apt update
apt install --reinstall linux-image-generic
update-initramfs -u -k all
update-grub
```

8. **Exit and cleanup** / Выйти и очистить:
```bash
exit
umount -R /mnt/sysroot
reboot
```

---

## Documentation Links

- **chroot(1):** https://man7.org/linux/man-pages/man1/chroot.1.html
- **chroot(2) — System call:** https://man7.org/linux/man-pages/man2/chroot.2.html
- **arch-chroot (Arch Linux):** https://man.archlinux.org/man/arch-chroot.8
- **systemd-nspawn (alternative):** https://man7.org/linux/man-pages/man1/systemd-nspawn.1.html
- **ArchWiki — Chroot:** https://wiki.archlinux.org/title/Chroot
- **Debian Wiki — Chroot:** https://wiki.debian.org/Chroot