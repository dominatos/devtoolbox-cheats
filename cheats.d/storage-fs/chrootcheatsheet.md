Title: 🐧 Chroot Cheatsheet
Group: Storage & FS
Icon: 🐧
Order: 4

# Chroot / Смена корневого каталога

Chroot (change root) is an operation that changes the apparent root directory for the current running process and its children. This is typically used for system recovery, bootloader repair, or software testing in an isolated environment.

## Table of Contents
- [Core Management](#core-management)
- [Sysadmin Operations](#sysadmin-operations)
- [Comparison: BIOS vs UEFI](#comparison-bios-vs-uefi)
- [Troubleshooting & Tips](#troubleshooting--tips)

---

## Core Management / Основное управление

### 1. Identify Partitions / Определение разделов
Identify the root, boot, and EFI partitions before mounting.

```bash
lsblk -f       # List disks and partitions with filesystems / Список дисков и разделов
blkid          # Show UUIDs of partitions / Показать UUID разделов
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

### 4. Enter Chroot Environment / Вход в окружение Chroot
Switch to the mounted system environment.

```bash
chroot /mnt/sysroot /bin/bash    # Enter using Bash / Войти через Bash
# OR / ИЛИ
chroot /mnt/sysroot /bin/sh      # Fallback to SH / Войти через SH
```

### 5. Exit and Cleanup / Выход и очистка
Always unmount recursively to ensure all bind mounts are released.

```bash
exit                             # Exit chroot / Выйти из chroot
umount -R /mnt/sysroot           # Recursive unmount / Рекурсивное размонтирование
```

> [!CAUTION]
> Failure to unmount correctly before rebooting can occasionally lead to filesystem synchronization issues.

---

## Sysadmin Operations / Операции системного администратора

### Kernel & Initramfs Management / Управление ядром и Initramfs
Rebuilding the initial ramdisk after kernel updates.

```bash
ls /boot                                  # List kernels / Список ядер
dpkg -l | grep linux-image                # Check installed kernels / Проверить установленные ядра
update-initramfs -u -k <kernel-version>   # Update specific kernel / Обновить конкретное ядро
update-initramfs -u -k all                # Update all kernels / Обновить все ядра
```

### Bootloader Repair (GRUB) / Восстановление загрузчика (GRUB)
Installing and updating the GRUB configuration.

```bash
# BIOS Version:
update-grub                               # Update config / Обновить конфигурацию

# UEFI Version:
grub-install /dev/sdX                     # Install bootloader to disk / Установить загрузчик на диск
update-grub                               # Update config / Обновить конфигурацию
```

---

## Comparison: BIOS vs UEFI / Сравнение: BIOS и UEFI

| Feature | BIOS (Legacy) | UEFI |
| :--- | :--- | :--- |
| **Boot Partition** | Often optional or integrated. | **MANDATORY** FAT32 EFI System Partition (ESP). |
| **Mounting** | `mount /dev/sdXY /mnt/sysroot/boot` | `mount /dev/sdXZ /mnt/sysroot/boot/efi` |
| **Firmware Bits** | N/A | `mount --bind /sys/firmware/efi/efivars ...` |
| **Why?** | Simple MBR-based boot. | Modern, supports Secure Boot and GPT > 2TB. |

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

- `/var/log/syslog` — General system logs / Общие системные логи
- `/var/log/apt/history.log` — Package history / История установки пакетов
- `/var/log/boot.log` — Boot process logs / Логи процесса загрузки