Title: 🛡️ SELinux / AppArmor — Basic diag
Group: System & Logs
Icon: 🛡️
Order: 7

getenforce                                      # Current SELinux mode / Текущий режим SELinux
setenforce 0                                    # Permissive (temporary) / Разрешительный (временно)
sudo sealert -a /var/log/audit/audit.log        # Analyze SELinux report / Анализ отчёта SELinux
aa-status                                       # AppArmor profiles status / Статус профилей AppArmor
sudo aa-complain /usr/sbin/nginx                # Switch to complain / Режим complain

