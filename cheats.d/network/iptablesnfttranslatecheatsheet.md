Title: 🔁 iptables → nftables — Mapping
Group: Network
Icon: 🔁
Order: 15

# iptables: allow SSH on 22 / Разрешить SSH на 22
#   iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# nftables:
nft add rule inet filter input tcp dport 22 accept

# iptables: allow established/related / Разрешить established/related
#   iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# nftables:
nft add rule inet filter input ct state established,related accept

# iptables: default DROP policy / Политика DROP по умолчанию
#   iptables -P INPUT DROP
# nftables:
nft 'add chain inet filter input { type filter hook input priority 0; policy drop; }'

