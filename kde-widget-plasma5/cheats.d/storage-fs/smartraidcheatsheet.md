Title: 💿 SMART & mdadm RAID
Group: Storage & FS
Icon: 💿
Order: 4

## Table of Contents
- [SMART Diagnostics](#-smart-diagnostics--диагностика-smart)
- [mdadm RAID Management](#-mdadm-raid-management--управление-raid)
- [Monitoring & Alerts](#-monitoring--alerts--мониторинг-и-оповещения)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔍 SMART Diagnostics / Диагностика SMART

### Basic SMART Info / Базовая SMART информация
sudo smartctl -a /dev/sda                     # Full SMART info / Полная SMART информация
sudo smartctl -i /dev/sda                     # Device info / Информация об устройстве
sudo smartctl -H /dev/sda                     # Health status / Статус здоровья
sudo smartctl -A /dev/sda                     # Attributes / Атрибуты

### Run Tests / Запустить тесты
sudo smartctl -t short /dev/sda               # Short test (~2 min) / Короткий тест (~2 мин)
sudo smartctl -t long /dev/sda                # Long test (~hours) / Длинный тест (~часы)
sudo smartctl -t conveyance /dev/sda          # Conveyance test / Тест транспортировки
sudo smartctl -X                              # Abort test / Прервать тест

### View Test Results / Просмотр результатов тестов
sudo smartctl -l selftest /dev/sda            # Self-test log / Лог само-тестов
sudo smartctl -l error /dev/sda               # Error log / Лог ошибок
sudo smartctl -l selective /dev/sda           # Selective test log / Лог выборочных тестов

### For NVMe Drives / Для NVMe дисков
sudo smartctl -a /dev/nvme0                   # NVMe SMART info / NVMe SMART информация
sudo smartctl -H /dev/nvme0n1                 # NVMe health / NVMe здоровье

---

# 🛡️ mdadm RAID Management / Управление RAID

### Check Status / Проверить статус
cat /proc/mdstat                              # RAID arrays status / Статус RAID массивов
sudo mdadm --detail /dev/md0                  # Detailed info / Подробная информация
sudo mdadm --detail --scan                    # Scan all arrays / Сканировать все массивы

### Create RAID / Создать RAID
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1  # RAID 1 / RAID 1
sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1  # RAID 5 / RAID 5
sudo mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sd[abcd]1  # RAID 10 / RAID 10

### Add/Remove Devices / Добавить/Удалить устройства
sudo mdadm --add /dev/md0 /dev/sdc1           # Add spare / Добавить запасной
sudo mdadm --fail /dev/md0 /dev/sdb1          # Mark as failed / Отметить как неисправный
sudo mdadm --remove /dev/md0 /dev/sdb1        # Remove device / Удалить устройство

### Manage Array / Управление массивом
sudo mdadm --stop /dev/md0                    # Stop array / Остановить массив
sudo mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1  # Assemble array / Собрать массив
sudo mdadm --assemble --scan                  # Auto-assemble all / Автособрать все

### Configuration / Конфигурация
sudo mdadm --detail --scan >> /etc/mdadm/mdadm.conf  # Save config / Сохранить конфиг
sudo update-initramfs -u                      # Update initramfs / Обновить initramfs

---

# 📊 Monitoring & Alerts / Мониторинг и оповещения

### Enable SMART Monitoring / Включить SMART мониторинг
sudo systemctl enable smartd                  # Enable smartd / Включить smartd
sudo systemctl start smartd                   # Start smartd / Запустить smartd
sudo systemctl status smartd                  # Check status / Проверить статус

### smartd Configuration / Конфигурация smartd
```bash
# /etc/smartd.conf
/dev/sda -a -o on -S on -s (S/../.././02|L/../../6/03) -m <EMAIL>
# -a: Monitor all attributes / Мониторить все атрибуты
# -o on: Enable automatic offline tests / Включить автоматические offline тесты
# -S on: Enable attribute autosave / Включить автосохранение атрибутов
# -s: Schedule tests / Запланировать тесты
# -m: Email alerts / Email оповещения
```

### mdadm Monitoring / Мониторинг mdadm
sudo mdadm --monitor --scan --daemonize       # Start monitor daemon / Запустить демон мониторинга
sudo mdadm --detail --test /dev/md0           # Test for degradation / Тест на деградацию

---

# 🌟 Real-World Examples / Примеры из практики

### Daily SMART Check / Ежедневная проверка SMART
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

### Replace Failed Disk / Заменить неисправный диск
```bash
# Check status / Проверить статус
cat /proc/mdstat

# Mark as failed / Отметить как неисправный
sudo mdadm --fail /dev/md0 /dev/sdb1

# Remove failed disk / Удалить неисправный диск
sudo mdadm --remove /dev/md0 /dev/sdb1

# Physically replace disk / Физически заменить диск

# Add new disk / Добавить новый диск
sudo mdadm --add /dev/md0 /dev/sdb1

# Watch rebuild / Следить за восстановлением
watch cat /proc/mdstat
```

### RAID Performance Test / Тест производительности RAID
```bash
# Write test / Тест записи
sudo dd if=/dev/zero of=/dev/md0 bs=1M count=1000 oflag=direct

# Read test / Тест чтения
sudo dd if=/dev/md0 of=/dev/null bs=1M count=1000 iflag=direct

# Random I/O test / Тест случайного I/O
sudo fio --name=randwrite --ioengine=libaio --iodepth=16 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=/dev/md0
```

### Monitor Disk Health / Мониторить здоровье дисков
```bash
# Check all disks / Проверить все диски
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

# 💡 Best Practices / Лучшие практики
# Run SMART tests regularly / Регулярно запускайте SMART тесты
# Monitor critical attributes (Reallocated_Sector_Ct) / Мониторьте критические атрибуты
# Keep spare disks for RAID arrays / Держите запасные диски для RAID массивов
# Save mdadm.conf after changes / Сохраняйте mdadm.conf после изменений
# Use email alerts for failures / Используйте email оповещения для сбоев
# Check /proc/mdstat daily / Проверяйте /proc/mdstat ежедневно

# 🔧 RAID Levels / Уровни RAID
# RAID 0: Striping (no redundancy) / Чередование (без избыточности)
# RAID 1: Mirroring (2+ disks) / Зеркалирование (2+ дисков)
# RAID 5: Parity (3+ disks) / Четность (3+ дисков)
# RAID 6: Double parity (4+ disks) / Двойная четность (4+ дисков)
# RAID 10: Mirror + Stripe (4+ disks) / Зеркало + Чередование (4+ дисков)

# 📋 Critical SMART Attributes / Критические SMART атрибуты
# 5: Reallocated_Sector_Ct — Bad sectors / Плохие секторы
# 187: Reported_Uncorrect — Uncorrectable errors / Неисправимые ошибки
# 188: Command_Timeout — Command timeouts / Таймауты команд
# 197: Current_Pending_Sector — Pending sectors / Ожидающие секторы
# 198: Offline_Uncorrectable — Offline errors / Offline ошибки
# 194: Temperature_Celsius — Temperature / Температура

# ⚠️ Important Notes / Важные примечания
# SMART tests don't guarantee disk won't fail / SMART тесты не гарантируют что диск не выйдет из строя
# Check SMART weekly / Проверяйте SMART еженедельно
# Replace disks with increasing errors / Заменяйте диски с растущими ошибками
# RAID is not a backup / RAID это не резервная копия
# Keep mdadm.conf in sync / Держите mdadm.conf синхронизированным
