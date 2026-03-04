Title: 🔤 tr/head/tail/watch — Commands
Group: Text & Parsing
Icon: 🔤
Order: 7

## Table of Contents
- [TR — Translate Characters](#-tr--translate-characters--tr--преобразование-символов)
- [HEAD — First Lines](#-head--first-lines--head--первые-строки)
- [TAIL — Last Lines](#-tail--last-lines--tail--последние-строки)
- [WATCH — Monitor Commands](#-watch--monitor-commands--watch--мониторинг-команд)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

## 🔄 TR — Translate Characters / TR — Преобразование символов

### Case Conversion / Конвертация регистра

```bash
tr '[:lower:]' '[:upper:]' < file               # To uppercase / В верхний регистр
tr 'a-z' 'A-Z' < file                           # Alternative uppercase / Альтернативный метод
tr '[:upper:]' '[:lower:]' < file               # To lowercase / В нижний регистр
echo "Hello World" | tr 'A-Z' 'a-z'             # Pipe to lowercase / Через pipe в нижний регистр
```

### Delete Characters / Удаление символов

```bash
tr -d '0-9' < file                              # Delete all digits / Удалить все цифры
tr -d '\n' < file                               # Remove newlines / Удалить переносы строк
tr -d ' ' < file                                # Remove spaces / Удалить пробелы
tr -d '[:punct:]' < file                        # Remove punctuation / Удалить пунктуацию
tr -d -c '[:alnum:]\n' < file                   # Keep only alphanumeric / Оставить только буквы и цифры
```

### Squeeze Repeats / Сжатие повторов

```bash
tr -s ' ' < file                                # Squeeze spaces / Сжать пробелы
tr -s '\n' < file                               # Squeeze blank lines / Сжать пустые строки
tr -s '[:space:]' ' ' < file                    # All whitespace to single space / Все пробелы в один
echo "hello    world" | tr -s ' '               # Remove extra spaces / Удалить лишние пробелы
```

### Replace Characters / Замена символов

```bash
tr ' ' '_' < file                               # Spaces to underscores / Пробелы в подчёркивания
tr ':' ',' < /etc/passwd                        # Colon to comma / Двоеточия в запятые
tr -c '[:alnum:]' '_' < file                    # Non-alphanumeric to underscores / Не буквы/цифры в подчёркивания
echo "192.168.1.1" | tr '.' '-'                 # Dots to dashes / Точки в дефисы
```

### Complement Sets / Дополнение множеств

```bash
tr -cd '[:digit:]' < file                       # Keep only digits / Оставить только цифры
tr -cd '[:alpha:]\n' < file                     # Keep only letters / Оставить только буквы
```

---

## ⬆️ HEAD — First Lines / HEAD — Первые строки

### Basic Usage / Базовое использование

```bash
head file                                       # First 10 lines / Первые 10 строк
head -n 20 file                                 # First 20 lines / Первые 20 строк
head -20 file                                   # Short form / Короткая форма
head -n -10 file                                # All except last 10 lines / Все кроме последних 10
head -c 100 file                                # First 100 bytes / Первые 100 байт
```

### Multiple Files / Несколько файлов

```bash
head -n 5 file1 file2                           # First 5 lines of each / Первые 5 строк каждого
head -q -n 10 file1 file2                       # Quiet (no headers) / Без заголовков
head -v file1 file2                             # Verbose (always headers) / С заголовками
```

### With Pipes / С конвейерами

```bash
ps aux | head -n 20                             # First 20 processes / Первые 20 процессов
ls -lt | head -n 10                             # 10 newest files / 10 новейших файлов
history | head -n 50                            # First 50 history entries / Первые 50 команд истории
```

---

## ⬇️ TAIL — Last Lines / TAIL — Последние строки

### Basic Usage / Базовое использование

```bash
tail file                                       # Last 10 lines / Последние 10 строк
tail -n 20 file                                 # Last 20 lines / Последние 20 строк
tail -20 file                                   # Short form / Короткая форма
tail -n +10 file                                # From line 10 to end / С 10-й строки до конца
tail -c 100 file                                # Last 100 bytes / Последние 100 байт
```

### Follow Mode / Режим слежения

```bash
tail -f /var/log/syslog                         # Follow new lines / Следить за новыми строками
tail -f /var/log/nginx/access.log               # Follow web server log / Следить за логом веб-сервера
tail -F file                                    # Follow by name (retry) / Следить по имени (с повтором)
tail -f file1 file2                             # Follow multiple files / Следить за несколькими файлами
tail -f --retry file                            # Retry if file doesn't exist / Повторять если файл не существует
```

### Follow with PID / Слежение с PID

```bash
tail --pid=1234 -f file                         # Stop when PID dies / Остановить когда процесс завершится
tail -f --pid=$$ file                           # Follow until current shell exits / До выхода из текущей оболочки
```

### Advanced Tail / Продвинутый tail

```bash
tail -n 100 -f /var/log/app.log | grep ERROR   # Follow and filter / Следить и фильтровать
tail -f file | awk '{print $1, $5}'             # Follow and extract fields / Следить и извлекать поля
tail -q -n 50 *.log                             # Quiet mode / Тихий режим
tail -s 5 -f file                               # Poll every 5s / Опрос каждые 5 секунд
```

---

## 🔁 WATCH — Monitor Commands / WATCH — Мониторинг команд

### Basic Monitoring / Базовый мониторинг

```bash
watch 'ss -s'                                   # Monitor socket stats / Мониторинг статистики сокетов
watch -n 2 'ss -s'                              # Refresh every 2s / Обновлять каждые 2 секунды
watch -n 5 'df -h'                              # Monitor disk space / Мониторинг дискового пространства
watch 'free -h'                                 # Monitor memory / Мониторинг памяти
watch 'uptime'                                  # Monitor load average / Мониторинг нагрузки
```

### Highlight Differences / Подсвечивание изменений

```bash
watch -d 'netstat -an | wc -l'                  # Highlight differences / Подсветить различия
watch -d=cumulative 'ps aux | wc -l'            # Cumulative differences / Накопительные различия
watch -n 1 -d 'cat /proc/loadavg'               # Monitor load with highlighting / Мониторинг нагрузки с подсветкой
```

### Precise Timing / Точное время

```bash
watch -p 'date'                                 # Precise timing / Точное время
watch -t 'ps aux | grep nginx'                  # No title / Без заголовка
watch -n 0.1 'cat sensor.dat'                   # 100ms interval / Интервал 100мс
```

### Exit on Change / Выход при изменении

```bash
watch -g 'ls -l file'                           # Exit when output changes / Выход при изменении вывода
watch -g -n 1 'pgrep myapp'                     # Exit when process appears / Выход при появлении процесса
```

### Complex Commands / Сложные команды

```bash
watch 'docker ps --format "table {{.Names}}\t{{.Status}}"'  # Monitor containers / Мониторинг контейнеров
watch 'kubectl get pods -o wide'                # Monitor Kubernetes pods / Мониторинг подов Kubernetes
watch -n 5 'tail -n 20 /var/log/app.log'        # Watch latest log entries / Смотреть последние записи лога
watch 'systemctl list-units --state=failed'     # Monitor failed services / Мониторинг упавших сервисов
```

---

## 🌟 Real-World Examples / Примеры из практики

### Log Processing / Обработка логов

```bash
tail -f /var/log/nginx/access.log | grep "POST"  # Monitor POST requests / Мониторинг POST запросов
tail -f /var/log/app.log | grep -i error | head -n 50  # First 50 errors / Первые 50 ошибок
tail -n 1000 /var/log/syslog | grep failure     # Last 1000 lines with failures / Последние 1000 строк с ошибками
tail -f /var/log/auth.log | grep "Failed password"  # Monitor SSH failures / Мониторинг неудач SSH
```

### System Monitoring / Мониторинг системы

```bash
watch -n 1 'ps aux --sort=-%mem | head -n 10'   # Top memory consumers / Топ по памяти
watch -n 2 'docker stats --no-stream'           # Monitor Docker resources / Мониторинг ресурсов Docker
watch -d 'free -h'                              # Memory usage with changes / Использование памяти с изменениями
watch -n 5 'systemctl status nginx'             # Monitor service status / Мониторинг статуса сервиса
```

### File Conversion / Конвертация файлов

```bash
cat file.txt | tr -d '\r' > unix.txt            # Remove Windows line endings / Удалить Windows переносы
cat file.csv | tr ',' '\t' > file.tsv           # CSV to TSV / CSV в TSV
cat data.txt | tr '[:upper:]' '[:lower:]' | tr -s ' ' '\n' | sort | uniq -c  # Word frequency / Частота слов
cat access.log | tr ' ' '\n' | grep -E '^[0-9]{1,3}\.' | sort | uniq -c  # Count IPs / Подсчёт IP
```

### Deployment Monitoring / Мониторинг развёртывания

```bash
watch -n 1 'kubectl get pods | grep myapp'      # Watch pod deployment / Смотреть развёртывание пода
tail -f deploy.log & watch -n 2 'curl -s http://localhost:8080/health'  # Monitor deployment + health / Мониторинг развёртывания + здоровье
watch -g 'curl -sf http://localhost:8080 >/dev/null' && echo "Service up!"  # Wait for service / Ждать сервис
```

### Data Extraction / Извлечение данных

```bash
head -n 1 data.csv && tail -n +2 data.csv | sort  # Header + sorted data / Заголовок + отсортированные данные
tail -n +2 data.csv | head -n 100               # Skip header, first 100 rows / Пропустить заголовок, первые 100 строк
cat /var/log/app.log | tail -n 10000 | grep ERROR | head -n 50  # Last 10k lines, first 50 errors / Последние 10k строк, первые 50 ошибок
```

### Network Monitoring / Мониторинг сети

```bash
watch -n 1 'netstat -an | grep ESTABLISHED | wc -l'  # Active connections count / Подсчёт активных соединений
watch -d 'ss -tn | tail -n +2 | wc -l'          # TCP connection count / Подсчёт TCP соединений
watch 'iptables -nvL | head -n 20'              # Monitor firewall / Мониторинг файрвола
```

### Process Management / Управление процессами

```bash
watch -n 1 'ps aux | grep -v grep | grep myapp'  # Monitor specific process / Мониторинг конкретного процесса
tail -f --pid=$(pgrep nginx | head -1) /var/log/nginx/error.log  # Follow until process dies / Следить до завершения процесса
watch -g 'pgrep -x myservice' || echo "Service stopped!"  # Alert on service stop / Оповещение при остановке сервиса
```

### Cleanup / Очистка

```bash
cat file.txt | tr -cd '[:print:]\n'             # Remove non-printable chars / Удалить непечатаемые символы
cat file.txt | tr -s '\n' | tail -n +2          # Remove leading blank lines / Удалить пустые строки в начале
echo "Hello   World" | tr -s ' ' | tr ' ' '-'   # Normalize and replace spaces / Нормализовать и заменить пробелы
```

---

## 💡 Performance Tips / Советы по производительности

> [!TIP]
> Use `tail -f` instead of `watch` for log files — it's more efficient and real-time.
> Используйте `tail -f` вместо `watch` для логов — это эффективнее и работает в реальном времени.

```bash
# watch -p for better timing accuracy / watch -p для лучшей точности времени
# tr -cd is faster than grep for character filtering / tr -cd быстрее grep для фильтрации символов
```
