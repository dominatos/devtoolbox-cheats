Title: 🖥️ Ubuntu VPS Optimization
Group: System & Logs
Icon: 🖥️
Order: 7

# Ubuntu VPS Optimization

Quick guide to free disk space, reduce RAM/CPU usage, and improve security on a headless Ubuntu 22.04+ VPS running web/DB/Docker stacks. These optimizations are particularly effective for small VPS instances (1–4 GB RAM) where every megabyte counts.

**What this covers / Что охватывает:**
- Removing unused packages (GPU drivers, snapd, language packs)
- Disabling unnecessary services (GPU manager, VM tools, power management)
- Verifying improvements with monitoring tools

**When to apply / Когда применять:**
- After provisioning a new VPS
- When migrating from a desktop-oriented image to a server role
- When disk space or RAM is critically low

> [!IMPORTANT]
> These optimizations target **headless servers only**. Do not apply GPU removal or service disabling on desktop systems or VMs that need graphical output.
> Эти оптимизации только для **headless серверов**. Не применяйте на десктопах.

---

## 📚 Table of Contents / Содержание

1. [Remove Unnecessary Packages](#remove-unnecessary-packages)
2. [Disable Unneeded Services](#disable-unneeded-services)
3. [Monitoring & Verification](#monitoring--verification)
4. [Expected Results](#expected-results)

---

## Remove Unnecessary Packages

### Basic Cleanup / Базовая очистка

```bash
sudo apt update                               # Update package list / Обновить список пакетов
sudo apt autoremove --purge                   # Remove orphaned + configs / Удалить сироты + конфиги
sudo apt autoclean && sudo apt clean          # Clear APT cache / Очистить кэш APT
```

### Orphaned Packages / Пакеты-сироты

```bash
sudo apt install deborphan                    # Install deborphan / Установить deborphan
sudo apt purge $(deborphan)                   # Remove orphaned packages / Удалить пакеты-сироты
```

### Graphics Stack (headless servers) / Графика (headless серверы)

```bash
sudo apt purge '*nvidia*' libgl1-mesa-dri libglu1-mesa xserver-xorg*  # Remove GPU stack / Удалить GPU стек
```

> [!TIP]
> On headless VPS this frees ~300–500 MB. Ensure no GUI apps depend on these packages before removing. / На headless VPS это освобождает ~300–500 МБ.

### Other Removable Packages / Другие удаляемые пакеты

```bash
sudo apt purge snapd                          # Remove snapd (~300 MB) / Удалить snapd
sudo apt purge language-pack-*                # Remove language packs (keep en) / Удалить языковые пакеты
sudo apt install language-pack-en             # Reinstall English pack / Переустановить английский пакет
```

---

## Disable Unneeded Services

### Disable Service / Отключить сервис

```bash
sudo systemctl disable --now <SERVICE>.service  # Disable and stop / Отключить и остановить
sudo systemctl daemon-reload                    # Reload systemd / Перезагрузить systemd
```

### Recommended to Disable / Рекомендуется отключить

```bash
# GPU / VM / Power management — not needed on headless VPS
# GPU / ВМ / Управление питанием — не нужны на headless VPS
sudo systemctl disable --now gpu-manager switcheroo-control thermald power-profiles-daemon speech-dispatcherd

# VM tools / Ubuntu extras — disable if not needed
# Утилиты ВМ / Ubuntu экстра — отключить если не нужны
sudo systemctl disable --now open-vm-tools lxd-agent pollinate ubuntu-advantage
```

### Conditionally Disable / Условно отключить

```bash
# Mail/DNS/FTP — if unused / Если не используются
sudo systemctl disable --now dovecot postfix named proftpd
```

> [!CAUTION]
> **Do NOT disable** these critical services: `sshd`, `apache2`, `nginx`, `mysql`, `php-fpm`, `docker`, `cron`, `rsyslog`, `fail2ban`, `crowdsec`. / **Не отключайте** критичные сервисы.

### Check Running Services / Проверить запущенные сервисы

```bash
systemctl list-units --type=service --state=running        # List running / Список запущенных
systemctl list-units --type=service --state=running | wc -l  # Count running / Количество запущенных
```

---

## Monitoring & Verification

### Final Checks / Финальная проверка

```bash
df -h                                         # Disk usage / Использование диска
htop                                          # RAM/CPU monitoring / Мониторинг RAM/CPU
deborphan                                     # Check for leftovers / Проверить остатки
systemd-analyze blame                         # Boot time per service / Время загрузки по сервисам
```

### Reboot / Перезагрузка

```bash
sudo reboot                                   # Reboot to apply changes / Перезагрузить для применения изменений
```

---

## Expected Results

| Metric | Improvement (EN / RU) |
| :--- | :--- |
| **Disk space** | +1 GB+ freed / +1 ГБ+ освобождено |
| **RAM** | −100–300 MB / −100–300 МБ |
| **CPU** | −5–15% idle load / −5–15% нагрузки |
| **Security** | Fewer open ports and attack surface / Меньше портов и поверхность атаки |

> **Ideal for stacks:** Tomcat / Nginx / MySQL / Docker / PHP-FPM. / Идеально для стеков: Tomcat / Nginx / MySQL / Docker / PHP-FPM.

---

## 💡 Best Practices / Лучшие практики

- Apply changes **step by step**, verifying after each. / Применяйте изменения поэтапно.
- Always **check what you're removing** before `apt purge`. / Всегда проверяйте, что удаляете.
- Keep `sshd` running — losing SSH access locks you out. / Не отключайте `sshd`.
- Run `systemd-analyze blame` to find slow boot services. / Найдите медленные сервисы через `systemd-analyze blame`.
- Document disabled services for future reference. / Документируйте отключённые сервисы.

---

## Documentation Links

- **Ubuntu Server Guide:** https://ubuntu.com/server/docs
- **systemd-analyze(1):** https://man7.org/linux/man-pages/man1/systemd-analyze.1.html
- **deborphan:** https://packages.debian.org/deborphan
- **ArchWiki — Improving Performance:** https://wiki.archlinux.org/title/Improving_performance
