---
Title: 🔐 SCP — Secure Copy
Group: Network
Icon: 🔐
Order: 7
tags:
  - network
  - sysadmin
  - linux
---

# SCP — Secure Copy Protocol

`scp` (Secure Copy) uses SSH to securely transfer files between hosts. While being deprecated in favor of SFTP, it remains widely used for quick file transfers due to its simple syntax. For incremental or large-scale transfers, consider `rsync` instead.

📚 **Official Docs / Официальная документация:** [scp(1)](https://man.openbsd.org/scp)

## Table of Contents

- [Basic Transfer](#Basic%20Transfer)
- [Advanced Options](#Advanced%20Options)
- [Performance & Compression](#Performance%20&%20Compression)
- [Troubleshooting](#Troubleshooting)
- [Real-World Examples](#Real-World%20Examples)
- [Reference Tables](#Reference%20Tables)
- [📚 Documentation Links](#📚%20Documentation%20Links)

---

## Basic Transfer

### Upload to Remote
```bash
scp file.txt <USER>@<HOST>:/path/             # Copy file to remote / Скопировать файл на удалённый хост
scp file.txt <USER>@<HOST>:                   # Copy to home directory / Скопировать в домашнюю директорию
scp file1.txt file2.txt <USER>@<HOST>:/path/  # Copy multiple files / Скопировать несколько файлов
scp -r dir/ <USER>@<HOST>:/path/              # Copy directory recursively / Скопировать директорию рекурсивно
scp -r dir1/ dir2/ <USER>@<HOST>:/path/       # Copy multiple directories / Скопировать несколько директорий
```

### Download from Remote
```bash
scp <USER>@<HOST>:/path/file.txt ./           # Copy from remote / Скопировать с удалённого хоста
scp <USER>@<HOST>:/path/file.txt ./local/     # Copy to local directory / Скопировать в локальную директорию
scp -r <USER>@<HOST>:/path/dir/ ./            # Copy directory from remote / Скопировать директорию с удалённого
scp <USER>@<HOST>:/path/\*.txt ./             # Copy with wildcard / Скопировать по маске
```

### Copy Between Remotes
```bash
scp -3 <USER1>@<HOST1>:/p/file <USER2>@<HOST2>:/p/  # Copy between remotes via local / Между удалёнными через локальный
scp <USER1>@<HOST1>:/p/file <USER2>@<HOST2>:/p/     # Direct copy (no -3) / Прямое копирование
```

---

## Advanced Options

### Custom Port & Key
```bash
scp -P 2222 file.txt <USER>@<HOST>:/path/     # Custom SSH port / Пользовательский SSH порт
scp -i ~/.ssh/id_ed25519 file <USER>@<HOST>:/path/  # Specific SSH key / Конкретный SSH ключ
scp -P 2222 -i ~/.ssh/key file <USER>@<HOST>:/path/  # Port + key / Порт + ключ
```

### Preserve Attributes
```bash
scp -p file.txt <USER>@<HOST>:/path/          # Preserve modification times / Сохранить время модификации
scp -rp dir/ <USER>@<HOST>:/path/             # Recursive with attributes / Рекурсивно с атрибутами
```

### Limit Bandwidth
```bash
scp -l 1000 file.txt <USER>@<HOST>:/path/     # Limit to 1000 Kbit/s / Ограничить до 1000 Кбит/с
scp -l 8000 large.iso <USER>@<HOST>:/path/    # Limit to 8000 Kbit/s (1MB/s) / Ограничить до 8000 Кбит/с (1МБ/с)
```

### Quiet & Verbose
```bash
scp -q file.txt <USER>@<HOST>:/path/          # Quiet mode / Тихий режим
scp -v file.txt <USER>@<HOST>:/path/          # Verbose mode / Подробный режим
scp -vvv file.txt <USER>@<HOST>:/path/        # Extra verbose / Очень подробный
```

---

## Performance & Compression

### Compression
```bash
scp -C file.txt <USER>@<HOST>:/path/          # Enable compression / Включить сжатие
scp -C big.iso <USER>@<HOST>:/path/           # Compress large file / Сжать большой файл
scp -C -r /large/dir <USER>@<HOST>:/path/     # Compress directory / Сжать директорию
```

### Cipher Selection
```bash
scp -c aes128-ctr file <USER>@<HOST>:/path/   # Fast cipher / Быстрый шифр
scp -c aes256-ctr file <USER>@<HOST>:/path/   # Secure cipher / Безопасный шифр
scp -c chacha20-poly1305@openssh.com file <USER>@<HOST>:/path/  # Modern cipher / Современный шифр
```

> [!NOTE]
> SCP does not support parallel transfers. Use `rsync` or `pscp` for parallel file transfer. / SCP не поддерживает параллельную передачу. Используйте `rsync` или `pscp`.

---

## Troubleshooting

### Debug Connection
```bash
scp -v file.txt <USER>@<HOST>:/path/          # Verbose output / Подробный вывод
scp -vvv file.txt <USER>@<HOST>:/path/        # Debug output / Отладочный вывод
```

### Permission Issues
```bash
chmod 600 ~/.ssh/id_rsa                       # Fix key permissions / Исправить права ключа
ssh-add ~/.ssh/id_rsa                         # Add key to agent / Добавить ключ в агента
```

### Test Connection
```bash
ssh <USER>@<HOST> "echo test"                 # Test SSH first / Сначала проверить SSH
ssh -p 2222 <USER>@<HOST>                     # Test custom port / Проверить пользовательский порт
```

---

## Real-World Examples

### Backup to Remote Server
```bash
# Backup directory
tar -czf - /data | ssh <USER>@<HOST> "cat > backup-$(date +%F).tar.gz"

# Or with scp
tar -czf backup.tar.gz /data
scp backup.tar.gz <USER>@<HOST>:/backups/backup-$(date +%F).tar.gz
```

### Deploy Application
```bash
# Upload to multiple servers
for server in server1 server2 server3; do
  scp -r app/ <USER>@$server:/opt/app/
done

# Upload with compression
scp -C -r dist/ <USER>@<HOST>:/var/www/html/
```

### Download Logs
```bash
# Download logs from remote
scp <USER>@<HOST>:/var/log/app/*.log ./logs/

# Download with date filter
ssh <USER>@<HOST> "find /var/log -name '*.log' -mtime -7 -print0" | xargs -0 -I {} scp <USER>@<HOST>:{} ./logs/
```

### Sync Configuration Files
```bash
# Sync to multiple servers
for server in web1 web2 web3; do
  scp nginx.conf <USER>@$server:/etc/nginx/
  ssh <USER>@$server "sudo systemctl reload nginx"
done
```

### Large File Transfer
```bash
# Transfer with compression and limit
scp -C -l 10000 large-db-dump.sql <USER>@<HOST>:/backups/

# Monitor progress with pv
pv large-file.iso | ssh <USER>@<HOST> "cat > /path/large-file.iso"
```

### Database Backup & Transfer
```bash
# MySQL backup and transfer
mysqldump -u root -p<PASSWORD> database | ssh <USER>@<HOST> "cat > database-$(date +%F).sql"

# PostgreSQL backup and transfer
pg_dump database | ssh <USER>@<HOST> "cat > database-$(date +%F).sql"
```

### Container Image Transfer
```bash
# Save and transfer Docker image
docker save myimage:latest | ssh <USER>@<HOST> "docker load"

# Transfer with compression
docker save myimage:latest | gzip | ssh <USER>@<HOST> "gunzip | docker load"
```

### Copy Between Cloud Instances
```bash
# AWS to GCP / AWS
scp -i aws-key.pem -3 ec2-user@<AWS_IP>:/data/file.tar.gz user@<GCP_IP>:/data/

# With jump host
scp -o ProxyJump=<JUMP_HOST> file.txt <USER>@<TARGET_HOST>:/path/
```

---

## Reference Tables

### Common Options

| Option | Description (EN / RU) |
| :--- | :--- |
| `-r` | Recursive / Рекурсивно |
| `-P` | Port / Порт |
| `-i` | Identity file / Файл идентификации |
| `-C` | Compression / Сжатие |
| `-p` | Preserve attributes / Сохранить атрибуты |
| `-q` | Quiet / Тихий |
| `-v` | Verbose / Подробный |
| `-l` | Limit bandwidth / Ограничить пропускную способность |
| `-3` | Copy between remotes via local / Копировать между удалёнными через локальный |

### Alternative Tools

| Tool | Best For (EN / RU) |
| :--- | :--- |
| **rsync** | Incremental transfers / Инкрементальные передачи |
| **sftp** | Interactive file transfer / Интерактивная передача файлов |
| **pscp** | PuTTY SCP (Windows) / PuTTY SCP (Windows) |
| **FileZilla** | GUI SFTP client / GUI SFTP клиент |

> [!IMPORTANT]
> SCP is being deprecated in favor of SFTP in future OpenSSH versions. Consider using `rsync` or `sftp` for new workflows. / SCP устаревает в пользу SFTP в будущих версиях OpenSSH. Используйте `rsync` или `sftp` для новых задач.

## 📚 Documentation Links

- [scp Man Page](https://man7.org/linux/man-pages/man1/scp.1.html)
