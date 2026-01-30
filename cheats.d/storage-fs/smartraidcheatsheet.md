Title: 💿 SMART & mdadm RAID
Group: Storage & FS
Icon: 💿
Order: 4

sudo smartctl -a /dev/sda                       # Disk SMART / Диагностика SMART диска
cat /proc/mdstat                                # mdadm arrays status / Состояние массивов mdadm
sudo mdadm --detail /dev/md0                    # RAID details / Детали RAID-массива

