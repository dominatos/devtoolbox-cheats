Title: 📜 Kernel-panic RHEL
Group: System & Logs
Icon: 📜
Order: 99

# 🧰 Kernel panic после обновления ядра (EL9: Alma/Rocky/RHEL) — мега-шпаргалка1

> **Сценарий:** после апдейта ядра нода не грузится, а старое ядро — ок.
> **Цель:** быстро вернуть загрузку, понять причину, сделать фикс «на будущее».
> **Стек по умолчанию:** NVMe + LVM + XFS (адаптируй под себя).

---

## 🔎 0) Быстрый чек-лист (EN/RU)

```bash
# 1) Загрузись в рабочее ядро (из GRUB)
uname -r
rpm -qa kernel\* | sort
grubby --info=ALL
cat /proc/cmdline
lsblk -f; blkid
df -h /boot /boot/efi

# 2) Проверить, есть ли нужные драйверы в initramfs нового ядра
KVER="5.14.0-570.49.1.el9_6.x86_64"
lsinitrd -m /boot/initramfs-${KVER}.img | egrep 'nvme|dm_|lvm|xfs|ext4|md_|raid|virtio' || echo "EMPTY?"
```

* **Если нет `nvme`, `dm_mod`, `xfs/ext4` → почти точно причина паники.**

---

## 🚑 1) Быстрый «временный» фикс через cmdline (EN/RU)

```bash
# Force-load modules early + give time + remove noisy flags
KVER="5.14.0-570.49.1.el9_6.x86_64"
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --remove-args="quiet rhgb nvme_core.multipath=Y" \
  --args="rd.driver.pre=nvme rd.driver.pre=dm_mod rd.driver.pre=xfs rootdelay=5 panic=120"
# NOTE: если root на EXT4, замени rd.driver.pre=xfs → rd.driver.pre=ext4
```

> Идея: **ядро подгрузит критичные модули перед initramfs**, и root станет виден.

---

## 🧱 2) Постоянный фикс через dracut (EN/RU)

```bash
# Жёстко добавляем драйверы в initramfs «на будущее»
cat >/etc/dracut.conf.d/99-nvme.conf <<'EOF'
hostonly="no"
add_drivers+=" nvme nvme_core dm_mod xfs "
EOF

KVER="5.14.0-570.49.1.el9_6.x86_64"
dracut -f -v "/boot/initramfs-${KVER}.img" "${KVER}"

# Проверка
lsinitrd -m "/boot/initramfs-${KVER}.img" | egrep 'nvme|dm_mod|lvm|xfs|ext4'
```

> Для EXT4: `add_drivers+=" ... ext4 "`;
> при mdraid/LUKS добавь `md_mod raid1 raid10 raid0 dm_crypt`.

---

## 🧰 3) Полезные «страховочные» параметры ядра (EN/RU)

```bash
# Больше логов и таймаут на панику (успеть сфоткать экран)
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="systemd.log_level=debug loglevel=7 log_buf_len=1M panic=120"

# При железных глюках (иногда спасает)
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="nokaslr iommu=soft"
# (или amd_iommu=off / intel_iommu=off по ситуации)
```

---

## 🐣 4) Диагностика ранней стадии boot (EN/RU)

### Вариант A: шелл в initramfs (dracut)

```bash
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --args="rd.break rd.shell rd.debug systemd.log_level=debug log_buf_len=1M panic=0"
```

В шелле:

```bash
lsblk -f; blkid
lvm pvscan; lvm vgscan; lvm vgchange -ay
ls -l /dev/almalinux/root
mount -o ro /dev/almalinux/root /sysroot && echo OK_ROOT || echo FAIL
dmesg | tail -n 200
```

### Вариант B: kdump (дамп ядра, стек)

```bash
dnf -y install kexec-tools crash
systemctl enable --now kdump
kdumpctl status
# после паники и ребута:
ls -lh /var/crash/*/
vmcore-dmesg /var/crash/*/vmcore | less
```

### Вариант C: pstore/ramoops

```bash
modprobe efi_pstore || true
ls -lah /sys/fs/pstore/
```

---

## 🧩 5) Типовые причины → решения (EN/RU)

### ❌ В initramfs нет драйверов диска/ФС/LVM

Симптом: `VFS: Unable to mount root fs`, `dracut: FATAL: can't find UUID`.

**Решение:** см. разделы **2** и **1** (dracut + rd.driver.pre).

---

### ❌ Неверный `root=`/`rd.lvm.lv=` в cmdline

```bash
WK="$(uname -r)"
ARGS="$(grubby --info /boot/vmlinuz-${WK} | sed -n 's/.*args=\"\(.*\)\".*/\1/p')"
grubby --update-kernel="/boot/vmlinuz-${KVER}" --args="$ARGS"
# (убери мусор типа nvme_core.multipath=Y при необходимости)
```

Проверь соответствие UUID/томов:

```bash
lsblk -f; blkid
```

---

### ❌ Включён NVMe multipath, но не настроен

* Временно отключить:

  ```bash
  grubby --update-kernel="/boot/vmlinuz-${KVER}" --remove-args="nvme_core.multipath=Y"
  ```
* Либо **донастроить** multipath (udev/LVM/правила) и **втащить конфиги в initramfs**.

---

### ❌ Глюки IOMMU/KASLR/микрокода

См. страхующие флаги в разделе **3**.

---

### ❌ Secure Boot + внешние DKMS-модули (ZFS/NVIDIA/HBA)

Под новым ядром модули не загрузятся без подписи.
Варианты: подписать через MOK / временно отключить Secure Boot.

---

## 🧪 6) Полезные приёмы с `grubby`/GRUB (EN/RU)

```bash
# Все записи и дефолт
grubby --info=ALL
grubby --default-kernel

# Скопировать cmdline рабочего ядра на новое
WK="$(uname -r)"; NEW="${KVER}"
ARGS="$(grubby --info /boot/vmlinuz-${WK} | sed -n 's/.*args=\"\(.*\)\".*/\1/p')"
grubby --update-kernel="/boot/vmlinuz-${NEW}" --args="$ARGS"

# Добавить тестовую запись (не трогая дефолт)
grubby --copy-default --add-kernel="/boot/vmlinuz-${NEW}" \
  --initrd="/boot/initramfs-${NEW}.img" --title "Test ${NEW}" \
  --args="${ARGS} rd.driver.pre=nvme"

# Перегенерация конфигов (BIOS/UEFI)
grub2-mkconfig -o /boot/grub2/grub.cfg
[ -d /boot/efi/EFI ] && grub2-mkconfig -o /boot/efi/EFI/$(ls /boot/efi/EFI | head -n1)/grub.cfg
```

---

## 🧱 7) «Толстый» initramfs для всех ядер (EN/RU)

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

> Если локальный root-диск, а сетевые драйверы мешают — исключи их:
>
> ```ini
> # /etc/dracut.conf.d/40-no-net.conf
> omit_dracutmodules+=" qemu qemu-net network-manager network ifcfg "
> ```
>
> И пересобери `dracut`.

---

## 🛟 8) Rescue-mode / chroot, если совсем «кирпич» (EN/RU)

```bash
# С ISO → Troubleshooting → Rescue → chroot
mount /dev/mapper/almalinux-root /mnt/sysroot
mount -t proc /proc /mnt/sysroot/proc
mount --rbind /sys /mnt/sysroot/sys
mount --rbind /dev /mnt/sysroot/dev
chroot /mnt/sysroot

# Переустановить ядро/пересобрать initramfs/GRUB
dnf reinstall -y "kernel-core-<версия>"
dracut -f -v "/boot/initramfs-<версия>.img" "<версия>"
grub2-mkconfig -o /boot/grub2/grub.cfg
```

---

## 🧊 9) Заморозить ядро временно (EN/RU)

```bash
dnf install -y 'dnf-command:versionlock'
dnf versionlock add kernel kernel-core kernel-modules kernel-modules-extra
grubby --set-default /boot/vmlinuz-5.14.0-503.11.1.el9_5.x86_64
```

---

## ❓ 10) Мини-FAQ (EN/RU)

* **Почему новые ядра «вдруг» требуют явных модулей?**
  Поменялась логика dracut/udev/LVM/порядок инициализации. Hostonly/модули не подтянулись автоматически.
* **Hostonly yes/no?**
  `hostonly="yes"` — меньше образ, быстрее загрузка, но «хрупче» к изменениям.
  `hostonly="no"` — «толще», зато стабильнее после апдейтов.
* **Как точно узнать ФС на /?**
  `findmnt / -o FSTYPE -n` или `lsblk -f | grep ' /$'`.

---

### 📌 Готовые сниппеты

**A) Быстрый фикс (cmdline):**

```bash
KVER="5.14.0-570.49.1.el9_6.x86_64"
grubby --update-kernel="/boot/vmlinuz-${KVER}" \
  --remove-args="quiet rhgb nvme_core.multipath=Y" \
  --args="rd.driver.pre=nvme rd.driver.pre=dm_mod rd.driver.pre=xfs rootdelay=5 panic=120"
```

**B) Постоянный фикс (dracut):**

```bash
cat >/etc/dracut.conf.d/99-nvme.conf <<'EOF'
hostonly="no"
add_drivers+=" nvme nvme_core dm_mod xfs "
EOF

dracut -f -v "/boot/initramfs-${KVER}.img" "${KVER}"
lsinitrd -m "/boot/initramfs-${KVER}.img" | egrep 'nvme|dm_mod|lvm|xfs'
```

**C) Проверка содержимого initramfs:**

```bash
lsinitrd -m /boot/initramfs-${KVER}.img | egrep 'nvme|dm_|lvm|xfs|ext4|md_|raid' || echo "нет критичных драйверов"
```
