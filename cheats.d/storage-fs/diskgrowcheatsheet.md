Title: 💿 Grow Disk (Cloud EXT4/XFS)
Group: Storage & FS
Icon: 💿
Order: 3

sudo growpart /dev/sda 1                        # Grow partition №1 / Расширить раздел №1
sudo resize2fs /dev/sda1                        # Grow EXT4 / Увеличить EXT4
sudo xfs_growfs /mountpoint                     # Grow XFS / Увеличить XFS

