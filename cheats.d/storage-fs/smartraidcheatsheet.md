Title: 💿 SMART & mdadm RAID
Group: Storage & FS
Icon: 💿
Order: 4

# SMART & mdadm RAID — Disk Health & Software RAID

**S.M.A.R.T. (Self-Monitoring, Analysis, and Reporting Technology)** is a monitoring system built into hard drives and SSDs that detects and reports indicators of drive reliability. It provides early warnings of disk failure, giving you time to replace drives before data loss occurs.

**mdadm (Multiple Device Administration)** is the standard Linux utility for managing software RAID arrays. Unlike hardware RAID controllers, mdadm uses the kernel's `md` (multiple device) driver to combine multiple disks into redundant arrays entirely in software.

**Why SMART matters / Зачем нужен SMART:**
- Detects degradation trends (bad sectors, temperature, wear) before total failure
- Allows proactive disk replacement instead of reactive incident response
- Runs self-tests (short, long, conveyance) to verify drive integrity

**Why mdadm / Зачем mdadm:**
- Software RAID without expensive hardware controllers
- Portable — array metadata travels with the disks, not the controller
- Supports RAID 0, 1, 4, 5, 6, 10, and linear concatenation
- Online rebuilding — arrays can rebuild while the system is running

**Modern alternatives / Современные альтернативы:**
- **ZFS** — integrated volume manager + filesystem with built-in RAID (RAID-Z), checksumming, snapshots
- **Btrfs** — Linux filesystem with built-in RAID (0, 1, 10, 5/6 experimental), snapshots, checksumming
- **Hardware RAID** — dedicated controller cards (LSI/Broadcom MegaRAID, HP SmartArray)

📚 **Official Docs / Официальная документация:**
[smartctl(8)](https://man7.org/linux/man-pages/man8/smartctl.8.html) · [smartd(8)](https://man7.org/linux/man-pages/man8/smartd.8.html) · [mdadm(8)](https://man7.org/linux/man-pages/man8/mdadm.8.html) · [md(4)](https://man7.org/linux/man-pages/man4/md.4.html)

## Table of Contents
- [Installation](#installation)
- [SMART Diagnostics](#smart-diagnostics)
- [mdadm RAID Management](#mdadm-raid-management)
- [RAID Levels Comparison](#raid-levels-comparison)
- [Critical SMART Attributes](#critical-smart-attributes)
- [Monitoring & Alerts](#monitoring--alerts)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)

---

## Installation / Установка

```bash
# Debian/Ubuntu
sudo apt install smartmontools mdadm

# RHEL/Fedora/CentOS
sudo dnf install smartmontools mdadm

# Arch Linux
sudo pacman -S smartmontools mdadm
```

### Default Ports & Services / Порты и сервисы по умолчанию

| Service | Port | Config File | Description (EN) | Описание (RU) |
| :--- | :--- | :--- | :--- | :--- |
| `smartd` | N/A | `/etc/smartd.conf` | SMART monitoring daemon | Демон мониторинга SMART |
| `mdmonitor` | N/A | `/etc/mdadm/mdadm.conf` | mdadm monitoring service | Сервис мониторинга mdadm |

---

## SMART Diagnostics / Диагностика SMART

### Basic SMART Info / Базовая SMART информация

```bash
sudo smartctl -a /dev/sda                     # Full SMART info / Полная SMART информация
sudo smartctl -i /dev/sda                     # Device info / Информация об устройстве
sudo smartctl -H /dev/sda                     # Health status / Статус здоровья
sudo smartctl -A /dev/sda                     # Attributes / Атрибуты
```

**Sample health output / Пример вывода:**
```
=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED
```

### Run Tests / Запустить тесты

```bash
sudo smartctl -t short /dev/sda               # Short test (~2 min) / Короткий тест (~2 мин)
sudo smartctl -t long /dev/sda                # Long test (~hours) / Длинный тест (~часы)
sudo smartctl -t conveyance /dev/sda          # Conveyance test / Тест транспортировки
sudo smartctl -X                              # Abort test / Прервать тест
```

> [!NOTE]
> **Short test** — quick check (~2 minutes), verifies basic functionality. **Long test** — thorough surface scan (can take hours on large drives). **Conveyance test** — designed to detect damage during shipping.
> **Короткий тест** — быстрая проверка (~2 мин). **Длинный тест** — полное сканирование поверхности (может занять часы). **Тест транспортировки** — обнаружение повреждений при перевозке.

### View Test Results / Просмотр результатов тестов

```bash
sudo smartctl -l selftest /dev/sda            # Self-test log / Лог само-тестов
sudo smartctl -l error /dev/sda               # Error log / Лог ошибок
sudo smartctl -l selective /dev/sda           # Selective test log / Лог выборочных тестов
```

### For NVMe Drives / Для NVMe дисков

```bash
sudo smartctl -a /dev/nvme0                   # NVMe SMART info / NVMe SMART информация
sudo smartctl -H /dev/nvme0n1                 # NVMe health / NVMe здоровье
sudo nvme smart-log /dev/nvme0n1              # nvme-cli alternative / Альтернатива через nvme-cli
```

> [!TIP]
> NVMe drives use a different SMART attribute set. Key metrics: **Percentage Used** (drive wear, 100% = end of rated life), **Available Spare** (replacement blocks remaining), and **Temperature**.
> NVMe используют другой набор SMART-атрибутов. Ключевые метрики: **Percentage Used** (износ), **Available Spare** (оставшиеся блоки замены), **Temperature**.

### For RAID Controllers / Для RAID контроллеров

```bash
# Behind hardware RAID (specify device type) / За аппаратным RAID
sudo smartctl -a /dev/sda -d megaraid,0       # LSI MegaRAID, disk 0
sudo smartctl -a /dev/sda -d cciss,0          # HP SmartArray, disk 0
sudo smartctl -a /dev/sda -d areca,1          # Areca, disk 1
```

---

## mdadm RAID Management / Управление RAID

### Check Status / Проверить статус

```bash
cat /proc/mdstat                              # RAID arrays status / Статус RAID массивов
sudo mdadm --detail /dev/md0                  # Detailed info / Подробная информация
sudo mdadm --detail --scan                    # Scan all arrays / Сканировать все массивы
```

**Sample `/proc/mdstat` output / Пример вывода:**
```
md0 : active raid1 sda1[0] sdb1[1]
      1048576 blocks super 1.2 [2/2] [UU]
```

> [!NOTE]
> In `/proc/mdstat`, `[UU]` means all disks are up. `[U_]` means one disk is missing/failed. `[2/2]` shows active/total disks.
> В `/proc/mdstat` `[UU]` означает все диски работают. `[U_]` — один диск отсутствует/неисправен. `[2/2]` — активных/всего.

### Create RAID / Создать RAID

```bash
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1  # RAID 1
sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1  # RAID 5
sudo mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sd[abcd]1  # RAID 10
```

### Add/Remove Devices / Добавить/Удалить устройства

> [!WARNING]
> Marking a device as failed with `--fail` and removing it with `--remove` will degrade the array. Ensure you have a replacement ready.
> Пометка устройства как неисправного и его удаление ухудшат состояние массива. Убедитесь, что замена готова.

```bash
sudo mdadm --add /dev/md0 /dev/sdc1           # Add spare / Добавить запасной
sudo mdadm --fail /dev/md0 /dev/sdb1          # Mark as failed / Отметить как неисправный
sudo mdadm --remove /dev/md0 /dev/sdb1        # Remove device / Удалить устройство
```

### Manage Array / Управление массивом

> [!CAUTION]
> `mdadm --stop` will take the array offline. All I/O to the array will stop. Ensure no filesystems are mounted from this array before stopping.
> `mdadm --stop` остановит массив. Все операции ввода-вывода будут прекращены. Убедитесь, что ни одна ФС не смонтирована с этого массива.

```bash
sudo mdadm --stop /dev/md0                    # Stop array / Остановить массив
sudo mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1  # Assemble array / Собрать массив
sudo mdadm --assemble --scan                  # Auto-assemble all / Автособрать все
```

### Configuration / Конфигурация

`/etc/mdadm/mdadm.conf`

```bash
sudo mdadm --detail --scan >> /etc/mdadm/mdadm.conf  # Save config / Сохранить конфиг
sudo update-initramfs -u                      # Update initramfs / Обновить initramfs
```

> [!IMPORTANT]
> Always update `/etc/mdadm/mdadm.conf` after creating or modifying arrays, then run `update-initramfs -u`. Without this, arrays may not auto-assemble on boot.
> Всегда обновляйте `/etc/mdadm/mdadm.conf` после создания или изменения массивов, затем выполните `update-initramfs -u`. Без этого массивы могут не собраться при загрузке.

---

## RAID Levels Comparison / Сравнение уровней RAID

| RAID Level | Min Disks | Redundancy (EN) | Избыточность (RU) | Usable Capacity | Best For |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RAID 0** | 2 | None — data loss if any disk fails | Нет — потеря данных при отказе любого диска | 100% | Performance, scratch data |
| **RAID 1** | 2 | Mirror — survives 1 disk failure | Зеркало — выдерживает отказ 1 диска | 50% | OS, critical data |
| **RAID 5** | 3 | Parity — survives 1 disk failure | Четность — выдерживает отказ 1 диска | (N-1)/N | General storage |
| **RAID 6** | 4 | Double parity — survives 2 disk failures | Двойная четность — выдерживает отказ 2 дисков | (N-2)/N | Large arrays, archival |
| **RAID 10** | 4 | Mirror + Stripe — survives 1 disk per mirror | Зеркало + Чередование | 50% | Databases, high I/O |

### RAID Performance Comparison / Сравнение производительности RAID

| RAID Level | Read Speed | Write Speed | Write Penalty | Rebuild Risk |
| :--- | :--- | :--- | :--- | :--- |
| **RAID 0** | N × single | N × single | None | N/A (no redundancy) |
| **RAID 1** | Up to 2× | 1× (writes to both) | 2× | Low |
| **RAID 5** | (N-1) × single | Reduced (parity calc) | 4× | **High** (URE risk) |
| **RAID 6** | (N-2) × single | Further reduced | 6× | Medium |
| **RAID 10** | N × single | N/2 × single | 2× | Low |

> [!WARNING]
> **RAID 5 with large disks (>2TB) is risky.** During rebuild, an Unrecoverable Read Error (URE, ~1 per 12.5TB read on consumer drives) can cause the entire array to fail. For large arrays, use RAID 6 or RAID 10.
> **RAID 5 с большими дисками (>2ТБ) рискован.** При восстановлении неисправимая ошибка чтения (URE, ~1 на 12.5ТБ) может вывести из строя весь массив. Для больших массивов используйте RAID 6 или RAID 10.

---

## Critical SMART Attributes / Критические SMART атрибуты

| ID | Attribute | Description (EN) | Описание (RU) | Action Threshold |
| :--- | :--- | :--- | :--- | :--- |
| 5 | `Reallocated_Sector_Ct` | Bad sectors remapped | Плохие секторы, перенесённые на резерв | > 0 — monitor closely |
| 187 | `Reported_Uncorrect` | Uncorrectable errors | Неисправимые ошибки | > 0 — plan replacement |
| 188 | `Command_Timeout` | Command timeouts | Таймауты команд | Increasing — check cable/controller |
| 197 | `Current_Pending_Sector` | Sectors pending reallocation | Секторы, ожидающие перераспределения | > 0 — disk degrading |
| 198 | `Offline_Uncorrectable` | Offline uncorrectable errors | Offline неисправимые ошибки | > 0 — replace soon |
| 194 | `Temperature_Celsius` | Drive temperature | Температура диска | > 50°C — improve cooling |
| 9 | `Power_On_Hours` | Total hours powered on | Общее время работы | Informational |
| 12 | `Power_Cycle_Count` | Number of power cycles | Количество циклов питания | Informational |

### SSD-Specific Attributes / Атрибуты SSD

| ID | Attribute | Description (EN) | Описание (RU) | Action Threshold |
| :--- | :--- | :--- | :--- | :--- |
| 177 | `Wear_Leveling_Count` | SSD wear level | Уровень износа SSD | < 10% — plan replacement |
| 181 | `Program_Fail_Cnt_Total` | Flash program failures | Ошибки программирования флеш | > 0 — monitor |
| 182 | `Erase_Fail_Count_Total` | Flash erase failures | Ошибки стирания флеш | > 0 — monitor |
| 233 | `Media_Wearout_Indicator` | Remaining SSD life | Оставшийся ресурс SSD | < 10 — replace soon |

---

## Monitoring & Alerts / Мониторинг и оповещения

### Enable SMART Monitoring / Включить SMART мониторинг

```bash
sudo systemctl enable smartd                  # Enable smartd / Включить smartd
sudo systemctl start smartd                   # Start smartd / Запустить smartd
sudo systemctl status smartd                  # Check status / Проверить статус
```

### smartd Configuration / Конфигурация smartd

`/etc/smartd.conf`

```bash
/dev/sda -a -o on -S on -s (S/../.././02|L/../../6/03) -m <EMAIL>
# -a: Monitor all attributes / Мониторить все атрибуты
# -o on: Enable automatic offline tests / Включить автоматические offline тесты
# -S on: Enable attribute autosave / Включить автосохранение атрибутов
# -s: Schedule tests (short daily 2AM, long Saturday 3AM) / Запланировать тесты
# -m: Email alerts / Email оповещения
```

### Monitor All Disks / Мониторить все диски

`/etc/smartd.conf`

```bash
DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -m <EMAIL>
# DEVICESCAN: Auto-detect all drives / Автоопределение всех дисков
# -n standby,q: Skip standby drives quietly / Пропускать спящие диски тихо
```

### mdadm Monitoring / Мониторинг mdadm

```bash
sudo mdadm --monitor --scan --daemonize       # Start monitor daemon / Запустить демон мониторинга
sudo mdadm --detail --test /dev/md0           # Test for degradation / Тест на деградацию
```

### Logrotate for SMART / Logrotate для SMART

`/etc/logrotate.d/smartd`

```
/var/log/smartd.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
    postrotate
        systemctl reload smartd > /dev/null 2>&1 || true
    endscript
}
```

---

## Real-World Examples / Примеры из практики

### Daily SMART Check Script / Скрипт ежедневной проверки SMART

```bash
#!/bin/bash
# Check all disks / Проверить все диски
for disk in /dev/sd?; do
  echo "=== $disk ==="
  sudo smartctl -H "$disk" || echo "WARNING: $disk has issues"
done
```

### Create RAID 1 for System / Создать RAID 1 для системы

```bash
# Create RAID 1 / Создать RAID 1
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

# Format / Форматировать
sudo mkfs.ext4 /dev/md0

# Mount / Смонтировать
sudo mount /dev/md0 /mnt/data

# Save config / Сохранить конфиг
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

### Replace Failed Disk Runbook / Замена неисправного диска

1. Check array status / Проверить статус массива:

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

2. Mark failed disk and remove / Отметить и удалить неисправный диск:

```bash
sudo mdadm --fail /dev/md0 /dev/sdb1
sudo mdadm --remove /dev/md0 /dev/sdb1
```

3. Physically replace the disk / Физически заменить диск.

4. Partition the new disk identically / Разметить новый диск идентично:

```bash
sfdisk -d /dev/sda | sfdisk /dev/sdb        # Copy partition table / Скопировать таблицу разделов
```

5. Add new disk to array / Добавить новый диск в массив:

```bash
sudo mdadm --add /dev/md0 /dev/sdb1
```

6. Monitor rebuild progress / Следить за ходом восстановления:

```bash
watch cat /proc/mdstat
```

7. Update config after rebuild / Обновить конфиг после восстановления:

```bash
sudo mdadm --detail --scan | sudo tee /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

> [!CAUTION]
> During rebuild, the array has **no redundancy** (RAID 1) or reduced redundancy (RAID 5/6). Avoid heavy I/O and do NOT reboot unless absolutely necessary.
> Во время восстановления массив не имеет **избыточности** (RAID 1) или имеет уменьшенную избыточность (RAID 5/6). Избегайте интенсивного I/O и НЕ перезагружайте без крайней необходимости.

### RAID Performance Test / Тест производительности RAID

```bash
# Write test / Тест записи
sudo dd if=/dev/zero of=/dev/md0 bs=1M count=1000 oflag=direct

# Read test / Тест чтения
sudo dd if=/dev/md0 of=/dev/null bs=1M count=1000 iflag=direct

# Random I/O test / Тест случайного I/O
sudo fio --name=randwrite --ioengine=libaio --iodepth=16 --rw=randwrite \
  --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 \
  --group_reporting --filename=/dev/md0
```

### Monitor Disk Health / Мониторить здоровье дисков

```bash
# Check critical attributes for all disks / Проверить критические атрибуты всех дисков
for disk in /dev/sd?; do
  echo "=== $disk ==="
  sudo smartctl -A "$disk" | grep -E "Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable|Temperature_Celsius"
done
```

### NVMe SMART Check / Проверка NVMe SMART

```bash
# Basic check / Базовая проверка
sudo smartctl -a /dev/nvme0n1

# Health percentage / Процент здоровья
sudo smartctl -a /dev/nvme0n1 | grep "Percentage Used"

# Temperature / Температура
sudo smartctl -a /dev/nvme0n1 | grep "Temperature"
```

### Expand RAID Array / Расширить RAID массив

```bash
# Add device / Добавить устройство
sudo mdadm --add /dev/md0 /dev/sdd1

# Grow array / Расширить массив
sudo mdadm --grow /dev/md0 --raid-devices=4

# Resize filesystem / Изменить размер файловой системы
sudo resize2fs /dev/md0
```

### Check RAID Consistency / Проверить целостность RAID

```bash
# Start consistency check / Запустить проверку целостности
echo check > /sys/block/md0/md/sync_action

# Monitor progress / Следить за прогрессом
cat /proc/mdstat

# Check mismatch count / Проверить количество несовпадений
cat /sys/block/md0/md/mismatch_cnt
```

> [!NOTE]
> A small `mismatch_cnt` on RAID 1/10 is often harmless (caused by in-flight writes during the check). On RAID 5/6, any mismatch indicates a potential parity error and should be investigated.
> Небольшое `mismatch_cnt` на RAID 1/10 часто безвредно (вызвано записями во время проверки). На RAID 5/6 любое несовпадение указывает на потенциальную ошибку четности.

---

## Best Practices / Лучшие практики

> [!IMPORTANT]
> - Run **SMART tests regularly** (at least weekly) / Регулярно запускайте SMART тесты
> - Monitor **critical attributes** (`Reallocated_Sector_Ct`, `Current_Pending_Sector`) / Мониторьте критические атрибуты
> - Keep **spare disks** for RAID arrays / Держите запасные диски для RAID массивов
> - **Save `mdadm.conf`** after every change / Сохраняйте `mdadm.conf` после изменений
> - Configure **email alerts** for failures / Настройте email оповещения для сбоев
> - Check `/proc/mdstat` **daily** / Проверяйте `/proc/mdstat` ежедневно
> - Use **matching disks** in RAID arrays (same model, size, firmware) / Используйте одинаковые диски

> [!WARNING]
> - SMART tests **don't guarantee** a disk won't fail — they only detect degradation trends.
> - **RAID is NOT a backup** — it protects against hardware failure, not data corruption or accidental deletion.
> - Replace disks with **increasing error counts** — don't wait for total failure.
> - Keep `mdadm.conf` in sync with actual array state.
> - **Never use RAID 5 with disks >2TB** — use RAID 6 or RAID 10 instead.

---

## Documentation Links

- **smartmontools:** https://www.smartmontools.org/
- **smartctl(8):** https://man7.org/linux/man-pages/man8/smartctl.8.html
- **smartd(8):** https://man7.org/linux/man-pages/man8/smartd.8.html
- **mdadm(8):** https://man7.org/linux/man-pages/man8/mdadm.8.html
- **md(4) — RAID kernel driver:** https://man7.org/linux/man-pages/man4/md.4.html
- **ArchWiki — RAID:** https://wiki.archlinux.org/title/RAID
- **ArchWiki — S.M.A.R.T.:** https://wiki.archlinux.org/title/S.M.A.R.T.
- **Red Hat — Managing RAID:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_storage_devices/managing-raid_managing-storage-devices
- **Linux RAID Wiki:** https://raid.wiki.kernel.org/
