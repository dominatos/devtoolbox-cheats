Title: 💿 Partition & Mount
Group: Storage & FS
Icon: 💿
Order: 2

lsblk -f                                        # Block devices + FS tree / Дерево блочных устройств и ФС
blkid                                           # UUID/types of FS / UUID и типы ФС
sudo parted /dev/sdb -- mklabel gpt mkpart primary ext4 1MiB 100%  # GPT + partition / GPT + раздел
sudo mkfs.xfs /dev/sdb1                         # Format as XFS / Форматировать в XFS
sudo mkdir -p /mnt/disk && sudo mount /dev/sdb1 /mnt/disk  # Mount / Смонтировать
echo '/dev/sdb1 /mnt/disk xfs defaults 0 0' | sudo tee -a /etc/fstab  # Add to fstab / Добавить в fstab

