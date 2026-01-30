Title: 🕸 nftables — Commands
Group: Network
Icon: 🕸
Order: 14

sudo nft list tables                            # List tables / Список таблиц
sudo nft list ruleset                           # Dump full ruleset / Полный дамп правил
sudo nft add table inet filter                  # Create 'filter' table / Создать таблицу filter
sudo nft 'add chain inet filter input { type filter hook input priority 0; }'  # Input chain / Цепочка input
sudo nft add rule inet filter input ct state established,related accept         # Allow established / Разрешить established
sudo nft add rule inet filter input tcp dport 22 accept                         # Allow SSH / Разрешить SSH
sudo nft add rule inet filter input drop                                         # Drop everything else / Остальное drop
sudo sh -c 'nft list ruleset > /etc/nftables.conf'                              # Persist rules / Сохранить правила

