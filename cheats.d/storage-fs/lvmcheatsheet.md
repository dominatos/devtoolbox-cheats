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

