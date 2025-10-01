Title: 📚 Linux Basics — Cheatsheet
Group: Basics
Icon: 📚
Order: 1

# 🔎 Navigation / Навигация
pwd                                           # Show current directory / Показать текущую директорию
ls -la                                        # List detailed incl. hidden / Подробный список (включая скрытые)
cd /path/to/dir                               # Change directory / Перейти в папку
cd ..                                         # Up one level / Вверх на уровень
cd -                                          # Previous directory / В предыдущую папку
cd ~                                          # Home directory / Домашняя директория
cd /                                          # Filesystem root / Корень ФС

# 📁 Files & dirs / Файлы и папки
mkdir newdir                                  # Create directory / Создать папку
mkdir -p a/b/c                                # Create nested dirs / Вложенные папки
touch file.txt                                # New empty/update mtime / Пустой файл/обновить время
cp file.txt backup.txt                        # Copy file / Копировать файл
cp -r dir/ dir_copy/                          # Recursive copy dir / Рекурсивно копировать каталог
cp -i file.txt backup.txt                     # Copy with prompt / Копировать с подтверждением
mv old.txt new.txt                            # Rename/move / Переименовать/переместить
mv file.txt /some/path/                       # Move to dir / Переместить в папку
mv -i file.txt /some/path/                    # Move with prompt / Перемещать с подтверждением
rm file.txt                                   # Delete file / Удалить файл
rm -i file.txt                                # Delete with prompt / Удалить с подтверждением
rm -r dir/                                    # Remove dir recursively / Рекурсивно удалить каталог
rm -rf dir/                                   # ⚠️ Force remove / ⚠️ Силовое удаление
rmdir emptydir                                # Remove empty dir / Удалить пустую папку

# 📖 View/edit / Просмотр/редактирование
cat file.txt                                  # Print file / Вывести файл
less file.txt                                 # Pager (q exit, / search) / Просмотрщик (q выход, / поиск)
head -n 20 file.txt                           # First 20 lines / Первые 20 строк
tail -n 50 file.txt                           # Last 50 lines / Последние 50 строк
tail -f /var/log/syslog                       # Follow log / «Хвост» лога

# ✏️ nano editor / Редактор nano
nano file.txt                                 # Open in nano / Открыть в nano
# Ctrl+O save | Ctrl+X exit | Ctrl+W search | Ctrl+K cut | Ctrl+U paste | Ctrl+\ replace
# Сохранить Ctrl+O | Выход Ctrl+X | Поиск Ctrl+W | Вырезать Ctrl+K | Вставить Ctrl+U | Замена Ctrl+\

# 🔐 Privileges / Права и привилегии
whoami                                        # Current user / Текущий пользователь
sudo command                                  # Run as root / Выполнить от root
sudo -i                                       # Root shell (root env) / Оболочка root (окружение root)
sudo -s                                       # Root shell (user env) / Оболочка root (ваше окружение)
su -                                          # Switch to root / Переключиться на root

# 📦 APT (Debian/Ubuntu)
sudo apt update                               # Update package lists / Обновить списки пакетов
sudo apt upgrade                              # Upgrade packages / Установить обновления
sudo apt install htop                         # Install package / Установить пакет
sudo apt remove htop                          # Remove keep conf / Удалить (с конфигами)
sudo apt purge htop                           # Remove + purge conf / Удалить + конфиги
sudo apt autoremove                           # Remove unused deps / Удалить неисп. зависимости
apt search nginx                              # Search package / Поиск пакета
apt show nginx                                # Package info / Информация о пакете

# 💡 Good to know / Полезно
man ls                                        # Manual (q exit) / Руководство (q — выход)
ls --help                                     # Help options / Короткая справка
history                                       # Shell history / История команд
sudo !!                                       # Repeat prev with sudo / Повторить прошлую с sudo
# TAB completion helps with paths and names / TAB дополняет пути и имена

