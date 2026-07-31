---
Title: ACL Cheat Sheet for Linux
Group: "Storage & FS"
Icon: 💿
Order: 5
tags:
  - storage
  - filesystem
  - sysadmin
  - linux
---

# ACL — Access Control Lists

**ACL (Access Control Lists)** extends standard Unix permissions (`chmod`) by allowing fine-grained control over file and directory access for specific users and groups. Unlike traditional Unix permissions (owner/group/other), ACLs let you grant or deny access to any number of individual users or groups on a single file or directory.

ACLs are implemented via POSIX.1e (withdrawn draft) and are supported on all major Linux filesystems (ext4, XFS, Btrfs). They require the `acl` mount option (enabled by default on most modern distributions). The primary tools are `getfacl` (read ACLs) and `setfacl` (set/modify ACLs), both part of the `acl` package.

**Common use cases / Типичные сценарии:**
- Granting a specific developer write access to a shared project without adding them to the group
- Allowing a monitoring agent read-only access to application logs
- Setting default permissions so new files inherit specific access rules

📚 **Official Docs / Официальная документация:**
[acl(5)](https://man7.org/linux/man-pages/man5/acl.5.html) · [getfacl(1)](https://man7.org/linux/man-pages/man1/getfacl.1.html) · [setfacl(1)](https://man7.org/linux/man-pages/man1/setfacl.1.html)

## Table of Contents
- [Installation & Configuration](#Installation%20&%20Configuration)
- [Basic Commands](#Basic%20Commands)
- [ACL Symbols and Values](#ACL%20Symbols%20and%20Values)
- [Usage Examples](#Usage%20Examples)
- [Default ACLs (Inheritance)](#Default%20ACLs%20(Inheritance)%20/%20ACL%20по%20умолчанию%20(Наследование))
- [ACL Mask](#ACL%20Mask)
- [Utilities and Useful Flags](#Utilities%20and%20Useful%20Flags)
- [Combining with chmod](#Combining%20with%20chmod)
- [Backup & Restore ACLs](#Backup%20&%20Restore%20ACLs)
- [Troubleshooting](#Troubleshooting)

---

## Installation & Configuration

### Install ACL Package

```bash
sudo apt install acl                              # Debian/Ubuntu
sudo dnf install acl                              # RHEL/Fedora/CentOS
sudo pacman -S acl                                # Arch Linux
```

### Verify ACL Support

```bash
mount | grep acl                                  # Check if acl option is enabled / Проверить опцию acl
tune2fs -l /dev/sda1 | grep "Default mount"       # Check default ext4 mount options / Проверить опции монтирования ext4
```

> [!NOTE]
> Modern Linux distributions enable ACL by default on ext4, XFS, and Btrfs. If ACLs are not working, remount with `mount -o remount,acl /mountpoint`.
> Современные дистрибутивы Linux включают ACL по умолчанию на ext4, XFS и Btrfs. Если ACL не работают, перемонтируйте с `mount -o remount,acl /mountpoint`.

---

## Basic Commands

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

## ACL Symbols and Values

| Symbol | Permission (EN) | Описание (RU) |
| :--- | :--- | :--- |
| `r` | Read permission | Право на чтение |
| `w` | Write permission | Право на запись |
| `x` | Execute permission | Право на выполнение (для файлов и директорий) |
| `X` | Execute only if directory or already executable | Выполнять только если каталог или файл уже исполняемый |
| `-` | No permission / Deny | Нет разрешения / Запрет |

---

## Usage Examples

```bash
# Give user read/write to logs directory recursively
#
setfacl -R -m u:<USER>:rwX /opt/<APP>/logs

# Set default ACL for directory (all new files inherit rw)
#
setfacl -R -d -m u:<USER>:rwX /opt/<APP>/logs

# Remove ACL entry for user
#
setfacl -x u:<USER> /opt/<APP>/logs

# Give group read-only access recursively
#
setfacl -R -m g:<GROUP>:r /project

# Give multiple users different access
#
setfacl -m u:<USER1>:rwx,u:<USER2>:r /shared/data

# View ACL including default entries recursively
#
getfacl -R /opt/<APP>/logs
```

---

## Default ACLs (Inheritance) / ACL

Default ACLs are set on directories and determine the ACLs that new files and subdirectories inherit.
ACL по умолчанию устанавливаются на каталоги и определяют ACL, которые наследуют новые файлы и подкаталоги.

```bash
# Set default ACL on directory
setfacl -d -m u:<USER>:rwX /shared/project

# Set default ACL for group
setfacl -d -m g:<GROUP>:rx /shared/project

# Verify default ACLs
getfacl /shared/project
# Output includes lines prefixed with "default:"
```

> [!TIP]
> Default ACLs only affect **newly created** files and directories. Existing files are not modified. Use `-R` (recursive) with `-m` to apply to existing files simultaneously.
> ACL по умолчанию влияют только на **вновь создаваемые** файлы и каталоги. Существующие файлы не изменяются. Используйте `-R` с `-m` для одновременного применения к существующим файлам.

---

## ACL Mask

The mask defines the **maximum effective permissions** for named users, named groups, and the owning group. It acts as a filter.
Маска определяет **максимальные эффективные разрешения** для именованных пользователей, групп и группы владельца. Она действует как фильтр.

```bash
# Set mask to read-only
setfacl -m m::r <FILE>

# Set mask to read-write
setfacl -m m::rw <FILE>

# View effective permissions (getfacl shows #effective: comments)
#
getfacl <FILE>
```

> [!WARNING]
> Running `chmod` on a file with ACLs will **change the mask**, not the owning group permission. This can inadvertently reduce effective permissions for all ACL entries.
> Выполнение `chmod` на файле с ACL **изменит маску**, а не разрешения группы владельца. Это может непреднамеренно уменьшить эффективные разрешения для всех ACL-записей.

---

## Utilities and Useful Flags

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

getfacl -t <FILE_OR_DIR>        # Tabular format / Табличный формат
```

---

## Combining with chmod

```bash
chmod 750 <FILE>                  # Standard Unix permissions
                                  # Стандартные права Unix

setfacl -m u:<USER>:rw <FILE>    # Add extra ACL for user on top of chmod
                                  # Добавить ACL для пользователя поверх chmod
```

> [!NOTE]
> ACL **does not replace chmod** — it adds extra permissions for specific users or groups on top of standard Unix permissions. The `+` sign in `ls -l` output (e.g., `rwxr-x---+`) indicates that a file has ACL entries.
> ACL **не заменяет chmod** — он добавляет дополнительные права для конкретных пользователей или групп поверх стандартных прав Unix. Знак `+` в выводе `ls -l` (например, `rwxr-x---+`) указывает на наличие ACL-записей.

---

## Backup & Restore ACLs

```bash
# Backup ACLs for a directory tree
getfacl -R /path/to/dir > acl_backup.txt

# Restore ACLs from backup
setfacl --restore=acl_backup.txt
```

> [!TIP]
> Include ACL backup in your regular backup procedures. Tools like `rsync` require `-A` flag (`rsync -aA`) to preserve ACLs, and `tar` requires `--acls` flag.
> Включите резервное копирование ACL в регулярные процедуры бэкапа. `rsync` требует флаг `-A` (`rsync -aA`) для сохранения ACL, а `tar` — флаг `--acls`.

---

## Troubleshooting

### ACL Not Working / ACL

```bash
# Check if filesystem supports ACL
mount | grep <MOUNT_POINT>

# Remount with ACL support
sudo mount -o remount,acl <MOUNT_POINT>

# Check if acl package is installed
which getfacl setfacl
```

### Verify ACL in Action

```bash
# Check file for ACL presence
ls -la <FILE>                     # Look for '+' at end of permissions / Ищите '+' в конце прав

# Detailed ACL view
getfacl <FILE>
```

---

## Documentation Links

- **acl(5) — POSIX ACLs:** https://man7.org/linux/man-pages/man5/acl.5.html
- **getfacl(1):** https://man7.org/linux/man-pages/man1/getfacl.1.html
- **setfacl(1):** https://man7.org/linux/man-pages/man1/setfacl.1.html
- **ArchWiki — Access Control Lists:** https://wiki.archlinux.org/title/Access_control_lists
- **Red Hat — ACL Guide:** https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_file_systems/assembly_setting-access-acls_managing-file-systems
