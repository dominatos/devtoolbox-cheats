Title: 🌀 Bash — Loops
Group: Text & Parsing
Icon: 🌀
Order: 12

## Table of Contents
- [FOR Loops](#-for-loops--циклы-for)
- [WHILE Loops](#-while-loops--циклы-while)
- [UNTIL Loops](#-until-loops--циклы-until)
- [Loop Control](#-loop-control--управление-циклами)
- [Reading Files](#-reading-files--чтение-файлов)
- [Real-World Examples](#-real-world-examples--примеры-из-практики)

---

# 🔄 FOR Loops / Циклы FOR

### Over Files / Перебор файлов
for f in *.log; do echo "$f"; done             # Iterate .log files / Перебрать .log файлы
for f in *.{yml,yaml}; do echo "$f"; done      # Multiple extensions / Несколько расширений
for f in /var/log/*.log; do : > "$f"; done     # Truncate all logs / Очистить все логи
for f in $(find . -name "*.txt"); do echo "$f"; done  # With find / С find
for f in *.conf; do cp "$f" "$f.bak"; done     # Backup all configs / Бэкап всех конфигов

### Over Numbers / Перебор чисел
for i in {1..5}; do echo $i; done              # Range 1-5 / Диапазон 1-5
for i in {1..10..2}; do echo $i; done          # Step by 2 / Шаг 2
for i in {10..1}; do echo $i; done             # Reverse / Обратный порядок
for ((i=1; i<=5; i++)); do echo $i; done       # C-style loop / Цикл в стиле C
for ((i=0; i<10; i+=2)); do echo $i; done      # C-style with step / С шагом

### Over Arrays / Перебор массивов
arr=("apple" "banana" "cherry")
for item in "${arr[@]}"; do echo "$item"; done # Iterate array / Перебрать массив
for i in "${!arr[@]}"; do echo "$i: ${arr[$i]}"; done  # With indices / С индексами

### Over Command Output / По выводу команды
for user in $(cut -d: -f1 /etc/passwd); do echo "$user"; done  # All users / Все пользователи
for ip in $(cat ips.txt); do ping -c1 "$ip"; done  # Ping all IPs / Пинговать все IP
for pod in $(kubectl get pods -o name); do kubectl describe "$pod"; done  # K8s pods / Поды Kubernetes

---

# ⏳ WHILE Loops / Циклы WHILE

### Basic While / Базовый while
i=1
while [ $i -le 5 ]; do
  echo $i
  ((i++))
done                                           # Counter 1-5 / Счётчик 1-5

### Read from File / Чтение из файла
while read -r line; do
  echo "$line"
done < file.txt                                # Read file lines / Читать построчно

### Infinite Loops / Бесконечные циклы
while :; do
  date
  sleep 5
done                                           # Tick every 5s / Каждые 5 секунд

while true; do
  echo "Running..."
  sleep 10
done                                           # Alternative infinite / Альтернативный бесконечный

### Conditional While / Условный while
while pgrep -x "nginx" > /dev/null; do
  echo "Nginx running"
  sleep 5
done                                           # While process exists / Пока процесс существует

while ! ping -c1 8.8.8.8 &>/dev/null; do
  echo "Waiting for network..."
  sleep 2
done                                           # Wait for network / Ждать сети

---

# 🔁 UNTIL Loops / Циклы UNTIL

### Basic Until / Базовый until
i=1
until [ $i -gt 5 ]; do
  echo $i
  ((i++))
done                                           # Run until condition true / Пока условие ЛОЖНО

### Wait for Condition / Ожидание условия
until curl -sf http://localhost:8080/health > /dev/null; do
  echo "Waiting for service..."
  sleep 2
done                                           # Wait for service / Ждать сервис

until [ -f /tmp/ready ]; do
  echo "Waiting for file..."
  sleep 1
done                                           # Wait for file / Ждать файл

---

# 🎮 Loop Control / Управление циклами

### Break / Прерывание
for i in {1..10}; do
  if [ $i -eq 5 ]; then
    break
  fi
  echo $i
done                                           # Exit loop at 5 / Выход на 5

### Continue / Продолжение
for i in {1..10}; do
  if [ $((i % 2)) -eq 0 ]; then
    continue
  fi
  echo $i
done                                           # Skip even numbers / Пропустить чётные

### Nested Loops / Вложенные циклы
for i in {1..3}; do
  for j in {1..3}; do
    echo "$i,$j"
  done
done                                           # Nested iteration / Вложенный перебор

---

# 📖 Reading Files / Чтение файлов

### Read Lines / Чтение строк
while IFS= read -r line; do
  echo "$line"
done < file.txt                                # Preserve whitespace / Сохранить пробелы

### Read CSV / Чтение CSV
while IFS=',' read -r col1 col2 col3; do
  echo "Col1: $col1, Col2: $col2"
done < data.csv                                # Parse CSV / Парсить CSV

### Process Substitution / Подстановка процесса
while IFS= read -r f; do
  echo "$f"
done < <(ls -1)                                # No subshell variable loss / Без потери переменных

### Read with Timeout / Чтение с таймаутом
while read -t 5 -r line; do
  echo "$line"
done < <(some_command)                         # 5s timeout / Таймаут 5с

---

# 🌟 Real-World Examples / Примеры из практики

### System Administration / Системное администрирование
# Rotate logs / Ротация логов
for log in /var/log/app/*.log; do
  mv "$log" "$log.old"
  touch "$log"
done

# Monitor services / Мониторинг сервисов
while :; do
  if ! systemctl is-active --quiet nginx; then
    echo "Nginx down, restarting..."
    systemctl restart nginx
  fi
  sleep 60
done

# Cleanup old files / Очистка старых файлов
for f in $(find /tmp -name "*.tmp" -mtime +7); do
  echo "Deleting $f"
  rm "$f"
done

### Network Operations / Сетевые операции
# Ping sweep / Проверка сети
for i in {1..254}; do
  {
    ip="192.168.1.$i"
    ping -c1 -W1 "$ip" &>/dev/null && echo "$ip is up"
  } &
done
wait

# Port scan / Сканирование портов
for port in {20..30}; do
  timeout 1 bash -c "echo > /dev/tcp/<HOST>/$port" 2>/dev/null && echo "Port $port open"
done

# Check URLs / Проверка URL
while IFS= read -r url; do
  status=$(curl -o /dev/null -s -w "%{http_code}" "$url")
  echo "$url: $status"
done < urls.txt

### File Processing / Обработка файлов
# Batch rename / Пакетное переименование
for f in *.jpeg; do
  mv "$f" "${f%.jpeg}.jpg"
done

# Convert images / Конвертация изображений
for img in *.png; do
  convert "$img" "${img%.png}.webp"
done

# Extract archives / Распаковка архивов
for archive in *.tar.gz; do
  tar -xzf "$archive" -C /dest/
done

### Database Operations / Операции с БД
# Backup all databases / Бэкап всех БД
for db in $(mysql -Ne "SHOW DATABASES" | grep -v "information_schema\|performance_schema\|mysql"); do
  mysqldump "$db" | gzip > "/backup/${db}-$(date +%Y%m%d).sql.gz"
done

# Check DB connections / Проверка подключений к БД
while IFS= read -r host; do
  mysql -h "$host" -e "SELECT 1" &>/dev/null && echo "$host: OK" || echo "$host: FAIL"
done < db_hosts.txt

### Kubernetes / Docker
# Restart all pods / Перезапуск всех подов
for pod in $(kubectl get pods -o name -n <NAMESPACE>); do
  kubectl delete "$pod" -n <NAMESPACE>
done

# Cleanup old containers / Очистка старых контейнеров
for container in $(docker ps -aq); do
  docker rm -f "$container"
done

# Check pod status / Проверка статуса подов
while :; do
  kubectl get pods -o wide
  sleep 10
done

### Parallel Processing / Параллельная обработка
# Process files in parallel / Обработка файлов параллел но
for f in *.log; do
  {
    gzip "$f"
    echo "$f compressed"
  } &
done
wait                                           # Wait for all background jobs / Ждать все фоновые задачи

# Limited parallelism / Ограниченный параллелизм
max_jobs=4
for f in *.txt; do
  while [ $(jobs -r | wc -l) -ge $max_jobs ]; do
    sleep 0.1
  done
  {
    process_file "$f"
  } &
done
wait

### Monitoring & Alerting / Мониторинг и оповещения
# Watch disk space / Мониторинг дискового пространства
while :; do
  usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
  if [ "$usage" -gt 90 ]; then
    echo "Disk usage critical: ${usage}%"
  fi
  sleep 300
done

# Monitor log for errors / Мониторинг логов на ошибки
tail -f /var/log/app.log | while read -r line; do
  if echo "$line" | grep -q "ERROR"; then
    echo "Error detected: $line"
  fi
done

### Advanced Patterns / Продвинутые шаблоны
# Counter with timeout / Счётчик с таймаутом
timeout=10
counter=0
while [ $counter -lt $timeout ]; do
  if check_condition; then
    echo "Success!"
    break
  fi
  ((counter++))
  sleep 1
done

# Retry logic / Логика повтора
max_retries=3
retry=0
until some_command || [ $retry -eq $max_retries ]; do
  ((retry++))
  echo "Retry $retry/$max_retries..."
  sleep 5
done

# Interactive menu / Интерактивное меню
options=("Start" "Stop" "Restart" "Exit")
while :; do
  for i in "${!options[@]}"; do
    echo "$((i+1)). ${options[$i]}"
  done
  read -p "Select option: " choice
  case $choice in
    4) break ;;
    *) echo "Processing ${options[$((choice-1))]}" ;;
  esac
done
