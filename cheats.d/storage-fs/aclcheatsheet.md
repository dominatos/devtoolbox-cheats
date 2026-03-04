Title: ACL Cheat Sheet for Linux
Group: Storage & FS
Icon: 💿
Order: 5

# ACL — Access Control Lists

Comprehensive guide to `getfacl` and `setfacl` commands for fine-grained Linux permissions.

## Table of Contents
- [Basic Commands](#basic-commands)
- [ACL Symbols and Values](#acl-symbols-and-values)
- [Usage Examples](#usage-examples)
- [Utilities and Useful Flags](#utilities-and-useful-flags)
- [Combining with chmod](#combining-with-chmod)

---

## Basic Commands / Основные команды

```bash
getfacl <FILE_OR_DIR>            # Show ACLs of file or directory
                                 # Показать ACL файла или каталога

setfacl -m u:<USER>:rw <FILE>   # Modify ACL: give user read/write
                                 # Изменить ACL: дать пользователю чтение/запись

setfacl -m g:<GROUP>:r <FILE>   # Modify ACL: give group read
                                 # Изменить ACL: дать группе чтение

setfacl -x u:<USER> <FILE>      # Remove ACL entry for user
                                 # Удалить ACL-запись для пользователя

setfacl -R -m u:<USER>:rw <DIR> # Recursive: apply ACL to all files in directory
                                 # Рекурсивно: применить ACL ко всем файлам в каталоге

setfacl -d -m u:<USER>:rw <DIR> # Default ACL: new files inherit permissions
                                 # ACL по умолчанию: новые файлы наследуют права
```

---

## ACL Symbols and Values / Символы и значения ACL

| Symbol | Permission (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `r` | Read permission | Право на чтение |
| `w` | Write permission | Право на запись |
| `x` | Execute permission | Право на выполнение (для файлов и директорий) |
| `X` | Execute only if directory or already executable | Выполнять только если каталог или файл уже исполняемый |

---

## Usage Examples / Примеры использования

```bash
# Give user read/write to logs directory recursively
# Дать пользователю чтение/запись в каталог logs рекурсивно
setfacl -R -m u:<USER>:rwX /opt/<APP>/logs

# Set default ACL for directory (all new files inherit rw)
# Установить ACL по умолчанию (новые файлы наследуют rw)
setfacl -R -d -m u:<USER>:rwX /opt/<APP>/logs

# Remove ACL entry for user
# Удалить ACL-запись для пользователя
setfacl -x u:<USER> /opt/<APP>/logs

# Give group read-only access recursively
# Дать группе только чтение рекурсивно
setfacl -R -m g:<GROUP>:r /project

# View ACL including default entries recursively
# Посмотреть ACL рекурсивно, включая записи по умолчанию
getfacl -R /opt/<APP>/logs
```

---

## Utilities and Useful Flags / Утилиты и полезные флаги

> [!WARNING]
> `setfacl -b` removes **all** extended ACLs from a file or directory — use with caution in production.
> `setfacl -b` удаляет **все** расширенные ACL — используйте с осторожностью в продакшене.

```bash
setfacl -b <FILE_OR_DIR>        # Remove all extended ACLs (reset)
                                 # Удалить все расширенные ACL

setfacl -k <FILE_OR_DIR>        # Remove default ACLs
                                 # Удалить ACL по умолчанию

getfacl -c <FILE_OR_DIR>        # Compact format, no comments
                                 # Компактный формат, без комментариев

getfacl -R <FILE_OR_DIR>        # Recursive, show ACLs of all files/directories
                                 # Рекурсивно, показать ACL всех файлов/каталогов
```

---

## Combining with chmod / Совмещение с chmod

```bash
chmod 750 <FILE>                  # Standard Unix permissions
                                  # Стандартные права Unix

setfacl -m u:<USER>:rw <FILE>    # Add extra ACL for user on top of chmod
                                  # Добавить ACL для пользователя поверх chmod
```

> [!NOTE]
> ACL **does not replace chmod** — it adds extra permissions for specific users or groups on top of standard Unix permissions.
> ACL **не заменяет chmod** — он добавляет дополнительные права для конкретных пользователей или групп поверх стандартных прав Unix.

---

*End of ACL Cheat Sheet*
