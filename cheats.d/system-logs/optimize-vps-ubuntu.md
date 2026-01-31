Title: Ubuntu VPS optimization
Group: System & Logs
Icon:
Order: 7



# Cheat Sheet: Ubuntu 22.04 VPS Optimization

**Date: January 2026** | **Goal:** Free disk space, RAM/CPU; improve security on a headless server (web/DB/Docker).[^1][^2][^3]

## 1. Remove unnecessary packages

```
sudo apt update
sudo apt autoremove --purge
sudo apt autoclean && sudo apt clean
```

- **Orphaned packages (deborphan):** `sudo apt install deborphan && sudo apt purge $(deborphan)`
- **Graphics stack (headless servers):** `sudo apt purge '*nvidia*' libgl1-mesa-dri libglu1-mesa xserver-xorg*`
- **Other:** `sudo apt purge snapd` (~300 MB), `language-pack-*` (keep `en`).[^4][^5][^6]

**Freed space:** 500+ MB.

## 2. Disable services (systemd)

```
sudo systemctl disable --now servicename.service
sudo systemctl daemon-reload
```

### Recommended to disable:

- `gpu-manager switcheroo-control thermald power-profiles-daemon speech-dispatcherd`
- `open-vm-tools lxd-agent pollinate ubuntu-advantage`
- Mail/DNS/FTP (if unused): `dovecot postfix named proftpd`

**Do NOT disable:** ssh/apache2/nginx/mysql/php-fpm/docker/cron/rsyslog/fail2ban/crowdsec.[^2][^7]

**Check running services:** `systemctl list-units --type=service --state=running | wc -l`

## 3. Monitoring and final checks

```
df -h  # disk usage
htop  # RAM/CPU
deborphan  # leftovers
systemd-analyze blame  # boot time
```

**Reboot:** `sudo reboot`

## Result

- **Disk space:** +1 GB+
- **RAM:** −100–300 MB
- **CPU:** −5–15%
- **Security:** Fewer open ports and attack surface

**Download this .md** and apply step by step. Ideal for stacks like Tomcat/Nginx/MySQL/Docker.[^8][^9]

***

*Compiled from practice: packages → services → graphics.*

<div align="center">⁂</div>

[^1]: https://www.tecmint.com/clean-up-ubuntu-terminal-commands/
[^2]: https://www.tecmint.com/remove-unwanted-services-from-linux/
[^3]: https://series.vpsfuel.com
[^4]: https://linuxopsys.com/ubuntu-remove-unused-packages
[^5]: https://techpiezo.com/linux/remove-unused-packages-in-ubuntu-using-deborphan/
[^6]: https://linuxconfig.org/how-to-uninstall-the-nvidia-drivers-on-ubuntu-22-04-jammy-jellyfish-linux
[^7]: https://docs.anyone.io/security/vps-hardening-and-best-practices
[^8]: https://www.accuwebhosting.com/blog/optimize-ubuntu-vps-performance/
[^9]: https://serverspace.io/support/help/initial-setup-of-ubuntu-server-22-04/


<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Шпаргалка: Оптимизация VPS Ubuntu 22.04

**Дата: Январь 2026** | **Цель:** Освободить место, RAM/CPU; повысить безопасность на headless сервере (web/DB/Docker).[^1][^2][^3]

## 1. Удаление лишних пакетов

```
sudo apt update
sudo apt autoremove --purge
sudo apt autoclean && sudo apt clean
```

- **Orphaned (deborphan):** `sudo apt install deborphan && sudo apt purge $(deborphan)`
- **Графика (headless):** `sudo apt purge '*nvidia*' libgl1-mesa-dri libglu1-mesa xserver-xorg*`
- **Другое:** `sudo apt purge snapd` (300 МБ), `language-pack-*` (кроме en).[^4][^5][^6]

**Освобождение:** 500+ МБ.

## 2. Отключение сервисов (systemd)

```
sudo systemctl disable --now servicename.service
sudo systemctl daemon-reload
```

### Критично отключить:

- `gpu-manager switcheroo-control thermald power-profiles-daemon speech-dispatcherd`
- `open-vm-tools lxd-agent pollinate ubuntu-advantage`
- Mail/DNS/FTP (если не нужно): `dovecot postfix named proftpd`

**НЕ трогать:** ssh/apache2/nginx/mysql/php-fpm/docker/cron/rsyslog/fail2ban/crowdsec.[^2][^7]

**Проверить:** `systemctl list-units --type=service --state=running | wc -l`

## 3. Мониторинг и финал

```
df -h  # диск
htop  # RAM/CPU
deborphan  # остатки
systemd-analyze blame  # boot-время
```

**Reboot:** `sudo reboot`

## Результат

- **Место:** +1 ГБ+
- **RAM:** -100–300 МБ
- **CPU:** -5–15%
- **Безопасность:** Меньше портов/уязвимостей.

**Скачайте этот .md** и применяйте поэтапно. Для вашего стека (Tomcat/Nginx/MySQL/Docker) идеально.[^8][^9]

***

*Собрано по чату: пакеты → сервисы → графика.*

<div align="center">⁂</div>

---

