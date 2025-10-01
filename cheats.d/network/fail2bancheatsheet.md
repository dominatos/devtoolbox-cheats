Title: 🚓 Fail2Ban — Commands
Group: Network
Icon: 🚓
Order: 17

sudo fail2ban-client status                     # List jails / Список jail-ов
sudo fail2ban-client status sshd                # Status of sshd jail / Статус jail sshd
sudo fail2ban-client set sshd banip 1.2.3.4     # Manually ban IP / Забанить IP вручную
sudo fail2ban-client set sshd unbanip 1.2.3.4   # Unban IP / Разбанить IP
# Config: /etc/fail2ban/jail.local              # Local jail overrides / Локальные настройки jail
sudo tail -f /var/log/fail2ban.log              # Live log / Лог в реальном времени

