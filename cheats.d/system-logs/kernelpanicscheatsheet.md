Title: 📜 Kernel-panic RHEL
Group: System & Logs
Icon: 📜
Order: 99

# Kernel Panic After Kernel Update (EL9: Alma/Rocky/RHEL)

**Kernel panic** is a fatal error in the Linux kernel from which it cannot safely recover, resulting in a system halt. This cheatsheet focuses on a common scenario: **kernel panic after a kernel update** on Enterprise Linux 9 (RHEL, AlmaLinux, Rocky Linux).

**Root cause (most common) / Основная причина (чаще всего):**
After a kernel update, `dracut` rebuilds the initramfs with `hostonly="yes"` (default), which includes only modules needed by the current hardware. If the hardware detection fails or the module dependency graph changes, critical drivers (NVMe, dm_mod, XFS/EXT4) may be missing from the new initramfs, causing a `VFS: Unable to mount root fs` panic.

**Symptoms / Симптомы:**
- `VFS: Unable to mount root fs on unknown-block(0,0)`
- `dracut: FATAL: can't find UUID=...`
- System hangs at boot with new kernel, but old kernel works fine

> **Scenario / Сценарий:** After kernel update the node won't boot, but the old kernel works. / После апдейта ядра нода не грузится, а старое ядро — ок.
> **Goal / Цель:** Quickly restore boot, find root cause, apply a permanent fix. / Быстро вернуть загрузку, понять причину, сделать фикс «на будущее».
> **Default stack / Стек:** NVMe + LVM + XFS (adapt to your setup / адаптируй под себя).

📚 **Official Docs / Официальная документация:**
[dracut(8)](https://man7.org/linux/man-pages/man8/dracut.8.html) · [grubby(8)](https://man7.org/linux/man-pages/man8/grubby.8.html) · [lsinitrd(1)](https://man7.org/linux/man-pages/man1/lsinitrd.1.html)

## Table of Contents
- [Quick Checklist](#quick-checklist)
- [Quick Temporary Fix via cmdline](#quick-temporary-fix-via-cmdline)
- [Permanent Fix via dracut](#permanent-fix-via-dracut)
- [Safety Kernel Parameters](#safety-kernel-parameters)
- [Early Boot Diagnostics](#early-boot-diagnostics)
- [Common Causes → Solutions](#common-causes--solutions)
- [grubby / GRUB Tips](#grubby--grub-tips)
- [Fat initramfs for All Kernels](#fat-initramfs-for-all-kernels)
- [Rescue Mode / chroot](#rescue-mode--chroot)
- [Freeze Kernel Temporarily](#freeze-kernel-temporarily)
- [Mini FAQ](#mini-faq)

---

## Quick Checklist

```bash
# 1) Boot into working kernel (from GRUB) / Загрузись в рабочее ядро (из GRUB)
uname -r
rpm -qa kernel\* | sort
grubby --info=ALL
cat /proc/cmdline
lsblk -f; blkid
df -h /boot /boot/efi

# 2) Check if the new kernel initramfs has required drivers / Проверить драйверы в initramfs
KVER="<KERNEL_VERSION>"
lsinitrd -m /boot/initramfs-${KVER}.img | egrep 'nvme|dm_|lvm|xfs|ext4|md_|raid|virtio' || echo "EMPTY?"
```

* **If `nvme`, `dm_mod`, `xfs/ext4` are missing → almost certainly the cause of panic.**
* **Если нет `nvme`, `dm_mod`, `xfs/ext4` → почти точно причина паники.**

---

## Quick Temporary Fix via cmdline

```bash
# Force-load modules early + give time + remove noisy flags
# Принудительно загрузить модули на ранней стадии
KVER="<KERNEL_VERSION>"
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --remove-args="quiet rhgb nvme_core.multipath=Y" \
  --args="rd.driver.pre=nvme rd.driver.pre=dm_mod rd.driver.pre=xfs rootdelay=5 panic=120"
# NOTE: if root is EXT4, replace rd.driver.pre=xfs → rd.driver.pre=ext4
# ПРИМЕЧАНИЕ: если root на EXT4, замени rd.driver.pre=xfs → rd.driver.pre=ext4
```

> [!NOTE]
> The idea: the kernel loads critical modules before initramfs, and root becomes visible. / Идея: ядро подгрузит критичные модули перед initramfs, и root станет виден.

---

## Permanent Fix via dracut

```bash
# Permanently add drivers to initramfs / Жёстко добавляем драйверы в initramfs
cat >/etc/dracut.conf.d/99-nvme.conf <<'EOF'
hostonly="no"
add_drivers+=" nvme nvme_core dm_mod xfs "
EOF

KVER="<KERNEL_VERSION>"
dracut -f -v "/boot/initramfs-${KVER}.img" "${KVER}"

# Verify / Проверка
lsinitrd -m "/boot/initramfs-${KVER}.img" | egrep 'nvme|dm_mod|lvm|xfs|ext4'
```

> [!TIP]
> For EXT4: `add_drivers+=" ... ext4 "`;
> For mdraid/LUKS add `md_mod raid1 raid10 raid0 dm_crypt`.
> Для EXT4: `add_drivers+=" ... ext4 "`;
> При mdraid/LUKS добавь `md_mod raid1 raid10 raid0 dm_crypt`.

---

## Safety Kernel Parameters

```bash
# More logs and panic timeout (time to see the screen) / Больше логов и таймаут на панику
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="systemd.log_level=debug loglevel=7 log_buf_len=1M panic=120"

# For hardware glitches (sometimes helps) / При железных глюках (иногда спасает)
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="nokaslr iommu=soft"
# (or amd_iommu=off / intel_iommu=off depending on hardware)
# (или amd_iommu=off / intel_iommu=off в зависимости от платформы)
```

---

## Early Boot Diagnostics

### Option A: initramfs shell (dracut) / Шелл в initramfs

```bash
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="rd.break rd.shell rd.debug systemd.log_level=debug log_buf_len=1M panic=0"
```

In the shell / В шелле:

```bash
lsblk -f; blkid
lvm pvscan; lvm vgscan; lvm vgchange -ay
ls -l /dev/almalinux/root
mount -o ro /dev/almalinux/root /sysroot && echo OK_ROOT || echo FAIL
dmesg | tail -n 200
```

### Option B: kdump (kernel crash dump) / kdump (дамп ядра)

```bash
dnf -y install kexec-tools crash
systemctl enable --now kdump
kdumpctl status
# After panic and reboot / После паники и перезагрузки:
ls -lh /var/crash/*/
vmcore-dmesg /var/crash/*/vmcore | less
```

### Option C: pstore/ramoops

```bash
modprobe efi_pstore || true
ls -lah /sys/fs/pstore/
```

---

## Common Causes → Solutions

### ❌ Missing disk/FS/LVM drivers in initramfs / Нет драйверов диска/ФС/LVM в initramfs

Symptom / Симптом: `VFS: Unable to mount root fs`, `dracut: FATAL: can't find UUID`.

**Solution:** See sections **Permanent Fix via dracut** and **Quick Temporary Fix**. / Решение: см. разделы выше.

---

### ❌ Wrong `root=`/`rd.lvm.lv=` in cmdline / Неверный `root=`/`rd.lvm.lv=` в cmdline

```bash
WK="$(uname -r)"
ARGS="$(grubby --info /boot/vmlinuz-${WK} | sed -n 's/.*args=\"\(.*\)\".*/\1/p')"
grubby --update-kernel="/boot/vmlinuz-${KVER}" --args="$ARGS"
# Remove junk like nvme_core.multipath=Y if needed / Убери мусор при необходимости
```

Verify UUID/volume correspondence / Проверь соответствие UUID/томов:

```bash
lsblk -f; blkid
```

---

### ❌ NVMe multipath enabled but not configured / NVMe multipath включён, но не настроен

```bash
# Temporarily disable / Временно отключить:
grubby --update-kernel="/boot/vmlinuz-${KVER}" --remove-args="nvme_core.multipath=Y"
```

Or **properly configure** multipath (udev/LVM/rules) and **include configs in initramfs**. / Либо **донастроить** multipath и **втащить конфиги в initramfs**.

---

### ❌ IOMMU/KASLR/microcode issues / Глюки IOMMU/KASLR/микрокода

See safety flags in the **Safety Kernel Parameters** section. / См. страхующие флаги в разделе выше.

---

### ❌ Secure Boot + external DKMS modules (ZFS/NVIDIA/HBA)

New kernel modules won't load without signature. / Под новым ядром модули не загрузятся без подписи.
Options / Варианты: sign via MOK / temporarily disable Secure Boot. / Подписать через MOK / временно отключить Secure Boot.

---

## grubby / GRUB Tips

```bash
# List all entries and default / Все записи и дефолт
grubby --info=ALL
grubby --default-kernel

# Copy working kernel cmdline to new / Скопировать cmdline рабочего ядра на новое
WK="$(uname -r)"; NEW="${KVER}"
ARGS="$(grubby --info /boot/vmlinuz-${WK} | sed -n 's/.*args=\"\(.*\)\".*/\1/p')"
grubby --update-kernel="/boot/vmlinuz-${NEW}" --args="$ARGS"

# Add test entry (don't touch default) / Добавить тестовую запись (не трогая дефолт)
grubby --copy-default --add-kernel="/boot/vmlinuz-${NEW}" \
  --initrd="/boot/initramfs-${NEW}.img" --title "Test ${NEW}" \
  --args="${ARGS} rd.driver.pre=nvme"

# Regenerate GRUB configs (BIOS/UEFI) / Перегенерация конфигов
grub2-mkconfig -o /boot/grub2/grub.cfg
[ -d /boot/efi/EFI ] && grub2-mkconfig -o /boot/efi/EFI/$(ls /boot/efi/EFI | head -n1)/grub.cfg
```

---

## Fat initramfs for All Kernels

```bash
cat >/etc/dracut.conf.d/99-fat.conf <<'EOF'
hostonly="no"
add_drivers+=" nvme nvme_core dm_mod xfs ext4 md_mod raid1 raid10 raid0 dm_crypt virtio_pci virtio_blk virtio_scsi sd_mod "
EOF

for k in /lib/modules/*; do
  v="$(basename "$k")"
  [ -f "/boot/vmlinuz-${v}" ] && dracut -f -v "/boot/initramfs-${v}.img" "${v}"
done

KVER="$(ls -1 /lib/modules | sort | tail -n1)"
lsinitrd -m "/boot/initramfs-${KVER}.img" | egrep 'nvme|dm_|lvm|xfs|ext4|md_|raid'
```

> [!TIP]
> If local root disk and network drivers interfere — exclude them:
> Если локальный root-диск, а сетевые драйверы мешают — исключи:
>
> `/etc/dracut.conf.d/40-no-net.conf`
>
> ```ini
> omit_dracutmodules+=" qemu qemu-net network-manager network ifcfg "
> ```
>
> Then rebuild with `dracut`. / И пересобери `dracut`.

---

## Rescue Mode / chroot

> [!CAUTION]
> Use rescue mode when the system is completely unbootable. Boot from installation ISO → Troubleshooting → Rescue.
> Используйте режим восстановления, когда система полностью не загружается.

```bash
# From ISO → Troubleshooting → Rescue → chroot
mount /dev/mapper/almalinux-root /mnt/sysroot
mount -t proc /proc /mnt/sysroot/proc
mount --rbind /sys /mnt/sysroot/sys
mount --rbind /dev /mnt/sysroot/dev
chroot /mnt/sysroot

# Reinstall kernel / rebuild initramfs / GRUB / Переустановить ядро/пересобрать initramfs/GRUB
dnf reinstall -y "kernel-core-<KERNEL_VERSION>"
dracut -f -v "/boot/initramfs-<KERNEL_VERSION>.img" "<KERNEL_VERSION>"
grub2-mkconfig -o /boot/grub2/grub.cfg
```

---

## Freeze Kernel Temporarily

```bash
dnf install -y 'dnf-command:versionlock'
dnf versionlock add kernel kernel-core kernel-modules kernel-modules-extra
grubby --set-default /boot/vmlinuz-<KERNEL_VERSION>
```

> [!WARNING]
> Kernel freezing is a temporary measure. Unfrozen kernels should be updated regularly for security patches.
> Заморозка ядра — временная мера. Размороженные ядра необходимо обновлять для безопасности.

```bash
# Unfreeze later / Разморозить позже
dnf versionlock delete kernel kernel-core kernel-modules kernel-modules-extra
```

---

## Mini FAQ

* **Why do new kernels "suddenly" need explicit modules? / Почему новые ядра «вдруг» требуют явных модулей?**
  Dracut/udev/LVM initialization order changed. Hostonly modules weren't auto-detected. / Поменялась логика dracut/udev/LVM/порядок инициализации. Hostonly модули не подтянулись.

* **hostonly yes/no?**
  `hostonly="yes"` — smaller image, faster boot, but fragile on updates. / Меньше образ, быстрее загрузка, но хрупче.
  `hostonly="no"` — larger image, but stable across updates. / Толще, зато стабильнее.

* **How to determine the filesystem on /? / Как точно узнать ФС на /?**
  `findmnt / -o FSTYPE -n` or `lsblk -f | grep ' /$'`.

---

## Documentation Links

- **dracut(8):** https://man7.org/linux/man-pages/man8/dracut.8.html
- **grubby(8):** https://man7.org/linux/man-pages/man8/grubby.8.html
- **lsinitrd(1):** https://man7.org/linux/man-pages/man1/lsinitrd.1.html
- **kdump documentation:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel
- **Red Hat — Kernel Troubleshooting:** https://access.redhat.com/solutions/1275
- **ArchWiki — dracut:** https://wiki.archlinux.org/title/Dracut
