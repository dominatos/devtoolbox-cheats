Title: 💿 SMART & mdadm RAID
Group: Storage & FS
Icon: 💿
Order: 4

# SMART & mdadm RAID

Comprehensive guide to SMART disk health diagnostics and software RAID management with mdadm.

## Table of Contents
- [SMART Diagnostics](#smart-diagnostics)
- [mdadm RAID Management](#mdadm-raid-management)
- [RAID Levels Comparison](#raid-levels-comparison)
- [Critical SMART Attributes](#critical-smart-attributes)
- [Monitoring & Alerts](#monitoring--alerts)
- [Real-World Examples](#real-world-examples)
- [Best Practices](#best-practices)

---

## SMART Diagnostics / Диагностика SMART

### Basic SMART Info / Базовая SMART информация

```bash
sudo smartctl -a /dev/sda                     # Full SMART info / Полная SMART информация
sudo smartctl -i /dev/sda                     # Device info / Информация об устройстве
sudo smartctl -H /dev/sda                     # Health status / Статус здоровья
sudo smartctl -A /dev/sda                     # Attributes / Атрибуты
```

### Run Tests / Запустить тесты

```bash
sudo smartctl -t short /dev/sda               # Short test (~2 min) / Короткий тест (~2 мин)
sudo smartctl -t long /dev/sda                # Long test (~hours) / Длинный тест (~часы)
sudo smartctl -t conveyance /dev/sda          # Conveyance test / Тест транспортировки
sudo smartctl -X                              # Abort test / Прервать тест
```

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
```

---

## mdadm RAID Management / Управление RAID

### Check Status / Проверить статус

```bash
cat /proc/mdstat                              # RAID arrays status / Статус RAID массивов
sudo mdadm --detail /dev/md0                  # Detailed info / Подробная информация
sudo mdadm --detail --scan                    # Scan all arrays / Сканировать все массивы
```

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

---

## RAID Levels Comparison / Сравнение уровней RAID

| RAID Level | Min Disks | Redundancy (EN) | Избыточность (RU) | Usable Capacity | Best For |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RAID 0** | 2 | None — data loss if any disk fails | Нет — потеря данных при отказе любого диска | 100% | Performance, scratch data |
| **RAID 1** | 2 | Mirror — survives 1 disk failure | Зеркало — выдерживает отказ 1 диска | 50% | OS, critical data |
| **RAID 5** | 3 | Parity — survives 1 disk failure | Четность — выдерживает отказ 1 диска | (N-1)/N | General storage |
| **RAID 6** | 4 | Double parity — survives 2 disk failures | Двойная четность — выдерживает отказ 2 дисков | (N-2)/N | Large arrays, archival |
| **RAID 10** | 4 | Mirror + Stripe — survives 1 disk per mirror | Зеркало + Чередование | 50% | Databases, high I/O |

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

### mdadm Monitoring / Мониторинг mdadm

```bash
sudo mdadm --monitor --scan --daemonize       # Start monitor daemon / Запустить демон мониторинга
sudo mdadm --detail --test /dev/md0           # Test for degradation / Тест на деградацию
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

4. Add new disk to array / Добавить новый диск в массив:

```bash
sudo mdadm --add /dev/md0 /dev/sdb1
```

5. Monitor rebuild progress / Следить за ходом восстановления:

```bash
watch cat /proc/mdstat
```

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

---

## Best Practices / Лучшие практики

> [!IMPORTANT]
> - Run **SMART tests regularly** (at least weekly) / Регулярно запускайте SMART тесты
> - Monitor **critical attributes** (`Reallocated_Sector_Ct`, `Current_Pending_Sector`) / Мониторьте критические атрибуты
> - Keep **spare disks** for RAID arrays / Держите запасные диски для RAID массивов
> - **Save `mdadm.conf`** after every change / Сохраняйте `mdadm.conf` после изменений
> - Configure **email alerts** for failures / Настройте email оповещения для сбоев
> - Check `/proc/mdstat` **daily** / Проверяйте `/proc/mdstat` ежедневно

> [!WARNING]
> - SMART tests **don't guarantee** a disk won't fail — they only detect degradation trends.
> - **RAID is NOT a backup** — it protects against hardware failure, not data corruption or accidental deletion.
> - Replace disks with **increasing error counts** — don't wait for total failure.
> - Keep `mdadm.conf` in sync with actual array state.

---

*End of SMART & RAID Cheat Sheet*
