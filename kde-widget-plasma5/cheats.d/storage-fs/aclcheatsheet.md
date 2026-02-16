Title: ACL Cheat Sheet for Linux
Group: Storage & FS
Icon: 💿
Order: 5
```markdown
# ACL Cheat Sheet for Linux

Comprehensive guide to `getfacl` and `setfacl` commands with English and Russian comments.

---

## 1. Basic Commands

```bash
getfacl file_or_dir          # Show ACLs of file or directory
                              # Показать ACL файла или каталога

setfacl -m u:user:rw file     # Modify ACL: give user read/write
                              # Изменить ACL: дать пользователю чтение/запись

setfacl -m g:group:r file     # Modify ACL: give group read
                              # Изменить ACL: дать группе чтение

setfacl -x u:user file        # Remove ACL entry for user
                              # Удалить ACL-запись для пользователя

setfacl -R -m u:user:rw dir   # Recursive: apply ACL to all files in directory
                              # Рекурсивно: применить ACL ко всем файлам в каталоге

setfacl -d -m u:user:rw dir   # Default ACL: new files inherit permissions
                              # ACL по умолчанию: новые файлы наследуют права
```

---

## 2. ACL Symbols and Values

```text
r   # read permission            # право на чтение
w   # write permission           # право на запись
x   # execute permission         # право на выполнение (для файлов и директорий)
X   # execute only if directory or already executable
    # выполнять только если каталог или файл уже исполняемый
```

---

## 3. Usage Examples

```bash
# Give user 'usb' read/write to logs directory recursively
setfacl -R -m u:usb:rwX /opt/tomcat/logs
# Дать пользователю 'usb' чтение/запись в каталог logs рекурсивно

# Set default ACL for directory (all new files inherit rw for usb)
setfacl -R -d -m u:usb:rwX /opt/tomcat/logs
# Установить ACL по умолчанию (новые файлы наследуют rw для usb)

# Remove ACL entry for user 'usb'
setfacl -x u:usb /opt/tomcat/logs
# Удалить ACL-запись для пользователя 'usb'

# Give group 'devs' read-only access recursively
setfacl -R -m g:devs:r /project
# Дать группе 'devs' только чтение рекурсивно

# View ACL including default entries
getfacl -R /opt/tomcat/logs
# Посмотреть ACL рекурсивно, включая записи по умолчанию
```

---

## 4. Utilities and Useful Flags

```bash
setfacl -b file_or_dir        # Remove all extended ACLs (reset)
                              # Удалить все расширенные ACL

setfacl -k file_or_dir        # Remove default ACLs
                              # Удалить ACL по умолчанию

getfacl -c file_or_dir        # Compact format, no comments
                              # Компактный формат, без комментариев

getfacl -R file_or_dir        # Recursive, show ACLs of all files/directories
                              # Рекурсивно, показать ACL всех файлов/каталогов
```

---

## 5. Combining with chmod

```bash
chmod 750 file                 # Standard Unix permissions
                               # Стандартные права Unix

setfacl -m u:alice:rw file     # Add extra ACL for alice
                               # Добавить ACL для alice поверх chmod
```

> ACL **does not replace chmod**, it adds extra permissions for specific users or groups.

---

*End of ACL Cheat Sheet*

