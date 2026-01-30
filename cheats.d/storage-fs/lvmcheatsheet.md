Title: 💿 LVM — Basics
Group: Storage & FS
Icon: 💿
Order: 1

sudo pvcreate /dev/sdb                          # Initialize physical volume / Инициализировать PV
sudo vgcreate vg0 /dev/sdb                      # Create volume group / Создать VG
sudo lvcreate -n data -L 20G vg0                # Create logical volume / Создать LV
sudo mkfs.ext4 /dev/vg0/data                    # Make EXT4 filesystem / Создать ФС EXT4
sudo mkdir -p /data && sudo mount /dev/vg0/data /data  # Mount volume / Смонтировать том
sudo lvextend -r -L +10G /dev/vg0/data          # Extend LV and FS / Увеличить LV и ФС


## 📦 1. Проверка состояния дисков и LVM


lsblk -f                  # показать дерево устройств с ФС / show block devices with filesystems
blkid                     # вывести UUID и тип ФС / show filesystem UUIDs and types
df -h                     # использование дисков в читаемом виде / human-readable disk usage
du -sh /opt/3di.it/media-storage/*   # размер каждой папки / size of each subdirectory
pvs                       # список физических томов / list physical volumes
vgs                       # список групп томов / list volume groups
lvs                       # список логических томов / list logical volumes
lvdisplay                 # подробности LV / detailed logical volume info
vgdisplay                 # подробности VG / detailed volume group info
pvdisplay                 # подробности PV / detailed physical volume info


---

## 💾 2. Добавление нового диска


lsblk                     # проверить наличие нового диска / list all block devices
parted /dev/sdd -- mklabel gpt      # создать таблицу GPT / create GPT partition table
parted /dev/sdd -- mkpart primary 0% 100%   # создать раздел на весь диск / create full-size partition
lsblk /dev/sdd             # убедиться, что появился /dev/sdd1 / verify partition exists


---

## 🧩 3. Добавление диска в LVM


pvcreate /dev/sdd1         # создать физический том / create physical volume
vgextend data-vg /dev/sdd1 # добавить PV в группу / add PV to existing VG
vgs                        # проверить, что добавилось / verify VG extended


---

## 🚀 4. Расширение логического тома и файловой системы


lvextend -l +100%FREE /dev/data-vg/datalv   # увеличить LV на всё свободное место / extend LV to all free space
xfs_growfs /opt/3di.it/media-storage        # расширить XFS онлайн / grow XFS filesystem online
resize2fs /dev/data-vg/datalv              # расширить EXT4 / resize EXT4 filesystem
df -h /opt/3di.it/media-storage             # проверить итоговый размер / verify final size


---

## 🔧 5. Форматирование и монтирование


mkfs.xfs /dev/data-vg/datalv               # создать XFS файловую систему / make XFS filesystem
mount /dev/data-vg/datalv /mnt/test        # смонтировать вручную / mount manually
nano /etc/fstab                            # добавить строку для автомонтирования / edit fstab for auto-mount
mount -a                                   # проверить корректность fstab / test all mounts


---

## 🧹 6. Удаление диска из LVM


lvs -a -o +devices          # показать, на каких дисках LV / show which PVs LV uses
pvmove /dev/sdd1            # перенести данные с PV / move data off PV
vgreduce data-vg /dev/sdd1  # удалить PV из VG / remove PV from VG
pvremove /dev/sdd1          # удалить LVM метки / wipe LVM metadata


---

## 🧱 7. Создание нового LVM с нуля


pvcreate /dev/sdd1                # создать PV / create physical volume
vgcreate backup-vg /dev/sdd1      # создать VG / create volume group
lvcreate -L 500G -n backup backup-vg   # создать LV 500ГБ / create 500G LV
mkfs.xfs /dev/backup-vg/backup    # создать ФС XFS / make XFS filesystem
mkdir /mnt/backup                 # создать точку монтирования / create mount point
mount /dev/backup-vg/backup /mnt/backup  # смонтировать / mount filesystem


---

## 🧾 8. Проверка и ремонт файловой системы


e2fsck -f /dev/data-vg/datalv     # проверка EXT4 / check and fix EXT4
xfs_repair /dev/data-vg/datalv    # ремонт XFS (требует размонтирования) / repair XFS (unmounted)


---

## ⚙️ 9. Полезные утилиты


lsblk -e7 -o NAME,SIZE,FSTYPE,MOUNTPOINT   # чистый вывод устройств / clean block list
udevadm info --query=all --name=/dev/sdd   # инфо о диске / get detailed device info
smartctl -a /dev/sdd                       # SMART-диагностика / disk health check
lvmconf --list                             # показать конфиги LVM / list LVM conf
lvscan                                     # найти все LV / scan for logical volumes
vgscan                                     # найти все VG / scan for volume groups
pvscan                                     # найти все PV / scan for physical volumes


---

## 🤖 10. Автоматизация — expand_data_storage.sh


#!/bin/bash
# Авто-добавление нового диска в data-vg и расширение ФС / Auto-extend LVM storage

NEW_DISK=$(lsblk -ndo NAME,TYPE | awk '$2=="disk" && $1!="sda" && $1!="sdb" && $1!="sdc"{print "/dev/"$1; exit}')
if [ -z "$NEW_DISK" ]; then
  echo "No new disk detected!"  # если нет новых дисков / if no new disk found
  exit 1
fi

echo "Using $NEW_DISK ..."       # вывести имя найденного диска / show found disk
parted $NEW_DISK -- mklabel gpt mkpart primary 0% 100%  # создать GPT и раздел / create partition
pvcreate ${NEW_DISK}1            # создать PV / create PV
vgextend data-vg ${NEW_DISK}1    # добавить в группу / extend VG
lvextend -l +100%FREE /dev/data-vg/datalv  # расширить LV / extend LV
xfs_growfs /opt/3di.it/media-storage       # расширить ФС / grow filesystem
df -h /opt/3di.it/media-storage            # проверить результат / check result


---

## 🧰 11. Восстановление при ошибках


vgcfgbackup                     # создать резервную копию метаданных / backup LVM metadata
vgcfgrestore data-vg             # восстановить метаданные / restore VG metadata
vgreduce --removemissing data-vg # удалить отсутствующие диски / remove missing PVs from VG
partprobe                        # обновить таблицу разделов / refresh partition table
rescan-scsi-bus.sh               # пересканировать устройства / rescan SCSI bus
vgchange -ay                     # активировать все группы томов / activate all VGs


---

## 🧠 12. Часто используемые команды


lvs                             # показать логические тома / list logical volumes
vgs                             # показать группы томов / list volume groups
pvs                             # показать физические тома / list physical volumes
pvcreate /dev/sdX               # создать физический том / create PV
vgextend data-vg /dev/sdX       # добавить PV в VG / extend VG with new PV
lvextend -l +100%FREE /dev/data-vg/datalv  # увеличить LV / extend LV
xfs_growfs /mount/point         # расширить XFS / grow XFS filesystem
df -h                           # проверить использование / check filesystem usage
xfs_info /mount/point           # инфо о XFS / show XFS info
pvmove /dev/sdX                 # перенести данные с PV / move data off PV
vgreduce data-vg /dev/sdX       # удалить диск из VG / remove PV from VG
vgcreate new-vg /dev/sdX        # создать новую VG / create new volume group
lvcreate -L 500G -n name vg     # создать LV / create logical volume
smartctl -a /dev/sdX            # проверить SMART / check disk health



