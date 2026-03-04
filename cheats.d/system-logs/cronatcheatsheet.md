Title: ⏰ cron / at — Commands
Group: System & Logs
Icon: ⏰
Order: 8

# ⏰ cron / at — Scheduled Tasks Cheatsheet

> **Context:** cron and at are Linux schedulers for recurring and one-shot tasks. / cron и at — планировщики задач Linux для повторяющихся и одноразовых заданий.
> **Role:** Sysadmin / DevOps
> **Tools:** crontab, cron, at, atq, atrm, anacron, flock, timeout

---

## 📚 Table of Contents / Содержание

1. [Crontab Management](#crontab-management)
2. [Schedule Syntax](#schedule-syntax)
3. [Shortcut Macros](#shortcut-macros)
4. [Common Schedule Patterns](#common-schedule-patterns)
5. [Environment Variables](#environment-variables)
6. [Locking & Overlap Prevention](#locking--overlap-prevention)
7. [Logging & Output](#logging--output)
8. [at — One-Shot Jobs](#at--one-shot-jobs)
9. [Anacron](#anacron)
10. [System Cron Directories](#system-cron-directories)
11. [Access Control](#access-control)
12. [Backup & Restore](#backup--restore)
13. [Real-World Examples](#real-world-examples)
14. [Troubleshooting & Debugging](#troubleshooting--debugging)
15. [Logrotate for Cron](#logrotate-for-cron)

---

## Crontab Management

### Crontab Commands / Команды crontab

```bash
crontab -e                                      # Edit current user's crontab / Редактировать crontab текущего пользователя
crontab -l                                      # List current user's crontab / Показать crontab текущего пользователя
crontab -u <USER> -e                            # Edit another user's crontab (root) / Редактировать crontab другого пользователя (root)
crontab -u <USER> -l                            # List another user's crontab / Показать crontab другого пользователя
```

> [!WARNING]
> `crontab -r` removes **all** cron entries for the user without confirmation. Use `crontab -l > backup` first.
> ```bash
> crontab -r                                    # DANGER: remove all cron entries / ОПАСНО: удалить все задания cron
> crontab -u <USER> -r                          # DANGER: remove another user's crontab / ОПАСНО: удалить crontab другого пользователя
> ```

---

## Schedule Syntax

### Cron Field Reference / Поля расписания cron

```text
┌──────── minute (0–59)
│ ┌────── hour (0–23)
│ │ ┌──── day of month (1–31)
│ │ │ ┌── month (1–12 or jan–dec)
│ │ │ │ ┌ day of week (0–7, 0 and 7 = Sunday, or mon–sun)
│ │ │ │ │
* * * * * <command>
```

### Field Operators / Операторы полей

| Operator | Description (EN / RU) | Example |
| :--- | :--- | :--- |
| `*` | Any value / Любое значение | `* * * * *` — every minute |
| `,` | List / Список | `1,15 * * * *` — at minute 1 and 15 |
| `-` | Range / Диапазон | `9-17 * * * *` — hours 9 through 17 |
| `/` | Step / Шаг | `*/15 * * * *` — every 15 minutes |

---

## Shortcut Macros

### Predefined Schedules / Предустановленные расписания

```bash
@reboot /opt/job.sh                             # Run once at boot / Запуск единожды при старте системы
@yearly /opt/job.sh                             # Run yearly (0 0 1 1 *) / Годовой запуск
@annually /opt/job.sh                           # Alias of @yearly / Синоним @yearly
@monthly /opt/job.sh                            # Run monthly (0 0 1 * *) / Запуск раз в месяц
@weekly /opt/job.sh                             # Run weekly (0 0 * * 0) / Запуск раз в неделю
@daily /opt/job.sh                              # Run daily (0 0 * * *) / Ежедневный запуск
@midnight /opt/job.sh                           # Alias of @daily / Синоним @daily (полночь)
@hourly /opt/job.sh                             # Run hourly (0 * * * *) / Почасовой запуск
```

---

## Common Schedule Patterns

### Basic Patterns / Базовые шаблоны

```bash
0 * * * * /opt/job.sh                           # Top of every hour / В начале каждого часа
0 0 * * * /opt/job.sh                           # Daily at midnight / Ежедневно в полночь
0 0 * * 0 /opt/job.sh                           # Sundays at midnight / По воскресеньям в полночь
*/15 * * * * /opt/job.sh                        # Every 15 minutes / Каждые 15 минут
0 4 1 * * /opt/job.sh                           # Monthly at 04:00 on day 1 / Ежемесячно в 04:00 первого числа
```

### Business Hours / Рабочие часы

```bash
0 9-18 * * * /opt/job.sh                        # Hourly 09–18 / Каждый час с 09 до 18
0 8-18/2 * * 1-5 /opt/job.sh                    # Every 2 hours on workdays / Каждые 2 часа с 8 до 18 по будням
*/5 9-17 * * 1-5 /opt/check.sh                  # Every 5 min business hours / Каждые 5 минут в рабочие часы по будням
0 */3 * * 1-5 /opt/report.sh                    # Every 3 hours on weekdays / Каждые три часа по будням
0 10,14,18 * * 1-5 /opt/notify.sh               # Multiple times per workday / Несколько запусков в будни
0 9-17/2 * * 1-5 /opt/every2h_daytime.sh        # Every 2h 9–17 weekdays / Каждые 2 часа с 9 до 17 по будням
0 8 * * MON-FRI /opt/workday_0800.sh            # Workdays at 08:00 / По будням в 08:00
```

### Multi-Day / Комбинации дней

```bash
0 0 1-7 * * /opt/job.sh                         # First seven days monthly / Первые семь дней месяца в полночь
0 0 1,15 * * /opt/job.sh                        # On the 1st and 15th / В полночь 1-го и 15-го числа
0 0 * * 1,3,5 /opt/job.sh                       # Mon, Wed, Fri at midnight / По пн, ср, пт в полночь
0 0 * * SAT,SUN /opt/weekend_task.sh            # Weekends at midnight / По выходным в полночь
0 0,12 1-10,15 * * /opt/job.sh                  # 00:00 and 12:00 on dates / В 00:00 и 12:00 в указанные дни
```

### Advanced Patterns / Продвинутые шаблоны

```bash
0 0 29 2 * /opt/leapday.sh                      # Run on Feb 29 / Запуск только 29 февраля (високосный)
0 6 1-7 * MON /opt/first_monday.sh              # First Monday each month / Первый понедельник каждого месяца
0 23 28-31 * * [ "$(date -d tomorrow +%m)" != "$(date +%m)" ] && /opt/month_end.sh  # Last day of month / Запуск в последний день месяца
*/20 * * * * test $(date +%u) -lt 6 && /opt/weekday_only.sh  # Weekdays via date %u / Будни через проверку дня недели
```

### Staggering / Распределение нагрузки

```bash
30 23 * * * sleep $((RANDOM%900)); /opt/spread.sh  # Spread starts within 15m / Равномерный сдвиг старта до 15 минут
RANDOM_DELAY=45 @daily /opt/heavy.sh            # Cronie: randomize start up to 45s / Cronie: случайная задержка до 45 сек
```

---

## Environment Variables

### Crontab Environment / Переменные окружения crontab

```bash
SHELL=/bin/bash                                 # Use bash for advanced features / Использовать bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin  # Set robust PATH / Установить полноценный PATH
HOME=/var/lib/myapp                             # Set HOME to app directory / Назначить HOME на каталог приложения
USER=<USER>                                     # Expose USER for scripts / Задать USER для использования в скриптах
LOGNAME=<USER>                                  # Expose LOGNAME for mail/logs / Указать LOGNAME для почты и логов
MAILTO=                                         # Disable email for all jobs / Отключить почтовые уведомления
MAILTO=admin@example.com                        # Per-job email recipient / Указать получателя почты для задач
```

### Timezone Overrides / Переопределение часового пояса

```bash
CRON_TZ=UTC 0 0 * * * /opt/utc_daily.sh        # Run at UTC midnight / Запускать в полночь по UTC (обход DST)
TZ=Europe/Rome 30 7 * * * /opt/local_job.sh     # Run at 07:30 Europe/Rome / Запуск в 07:30 по Europe/Rome
```

### Locale & Permissions / Локаль и права

```bash
LC_ALL=C 0 * * * * /opt/locale_neutral.sh       # Run with C locale / Запускать с нейтральной локалью C
LANG=en_US.UTF-8 5 0 * * * /opt/unicode_job.sh  # Ensure UTF-8 environment / Гарантировать окружение UTF-8
umask 027; 0 1 * * * /opt/secure_task.sh        # Tight default permissions / Жёсткие права для создаваемых файлов
```

### Priority / Приоритет

```bash
nice -n 10 ionice -c2 -n7 /opt/job.sh           # Lower CPU and IO priority / Уменьшить приоритеты CPU и IO
```

---

## Locking & Overlap Prevention

### flock — Prevent Overlapping Runs / Предотвращение наложения

```bash
* * * * * /usr/bin/flock -n /tmp/job.lock /opt/job.sh              # No-overlap via flock / Исключить наложения через flock
*/7 * * * * /usr/bin/flock -n /run/locks/job.lock /opt/job.sh      # Non-overlapping every 7 min / Каждые 7 минут без параллелизма
*/5 * * * * /usr/bin/flock -w 20 /run/locks/job.lock /opt/job.sh   # Wait up to 20s for lock / Ждать блокировку до 20 секунд
0 * * * * /usr/bin/flock -n /run/locks/once.lock bash -lc '/opt/rotate.sh >>/var/log/rot.log 2>&1'  # Lock and shell-wrapped / Блокировка и запуск через bash с логом
```

### timeout + flock / Таймаут с блокировкой

```bash
* * * * * /usr/bin/timeout 180 /usr/bin/flock -n /run/locks/guard.lock /opt/guarded.sh  # Timeout plus lock / Таймаут и блокировка одновременно
* * * * * timeout 300 /opt/job.sh               # Timeout after 5 minutes / Принудительно завершить через 5 минут
0 * * * * timeout 600 /opt/long.sh              # Limit to 10 minutes / Ограничить выполнение десятью минутами
0 2 * * * /usr/bin/timeout 3600 /opt/heavy_job.sh >>/var/log/heavy.log 2>&1  # Cap runtime to 1h / Ограничить время выполнения одним часом
```

### Skip Conditions / Условия пропуска

```bash
*/5 * * * * [ $(pgrep -c -f "script.sh") -eq 0 ] && /opt/script.sh    # Skip if process exists / Пропускать, если процесс запущен
*/10 * * * * [ -e /run/maintenance.lock ] || /opt/healthcheck.sh       # Skip during maintenance / Пропускать при обслуживании
* * * * * /usr/bin/test -f /run/skip.cron || /opt/minutely.sh          # Skip when skip-file exists / Пропускать при наличии файла-признака
0 1 * * * /usr/bin/test -x /usr/local/bin/do && /usr/local/bin/do     # Run only if executable exists / Запускать лишь при наличии файла
0 0 * * * test -x /usr/local/bin/run-one && run-one /opt/solo.sh      # Ubuntu run-one / Ubuntu: предотвращение дублей
```

### Chained Jobs / Цепочки заданий

```bash
0 2 * * * /opt/first.sh && touch /tmp/ok.flag                        # Create success flag / Создать флаг успешного выполнения
15 2 * * * [ -f /tmp/ok.flag ] && /opt/second.sh && rm /tmp/ok.flag  # Conditional follow-up / Запустить вторую задачу при наличии флага
```

### Load-Aware Execution / Запуск с учётом нагрузки

```bash
0 22 * * * [ $(awk '{print 100-$NF}' /proc/loadavg | cut -d. -f1) -lt 30 ] && /opt/backup.sh  # Run on low CPU load / Бэкап при низкой загрузке CPU
```

---

## Logging & Output

### Redirections / Перенаправления

```bash
0 2 * * * /opt/task.sh >> /var/log/task.log 2>&1           # Append stdout+stderr to file / Добавлять stdout и stderr в файл лога
0 2 * * * /opt/task.sh > /var/log/out.log 2> /var/log/err.log  # Split stdout/stderr logs / Разнести stdout и stderr по файлам
0 4 * * * /opt/task.sh >/dev/null 2>&1                     # Silence all output / Полностью подавить вывод
0 0 * * * /opt/job.sh >> "/var/log/script_$(date +\%Y\%m\%d).log" 2>&1  # Rotate by date in name / Лог с датой (экранировать %)
```

> [!IMPORTANT]
> In crontab, the `%` character is treated as a newline — always escape it with `\%`.

### Syslog Integration / Интеграция с syslog

```bash
* * * * * /usr/bin/logger --tag cron-heartbeat "tick"       # Syslog heartbeat each minute / Минутный сигнал в syslog
0 3 * * * /opt/task.sh | /usr/bin/logger --tag task         # Pipe to syslog with tag / Перенаправить вывод в syslog с тегом
0 5 * * * /opt/task.sh 2>&1 | /usr/bin/logger --priority local0.err --tag cron-task  # Send errors to syslog / Ошибки в syslog с приоритетом
0 0 * * * /usr/bin/logger --priority local7.info "Cron is alive"  # Heartbeat log / Лог-индикатор работы cron
```

### Timestamped Logs / Логи с метками времени

```bash
0 0 * * * (/bin/date; echo ran) >>/var/log/cron_$(date +\%F).log 2>&1  # Daily dated logfile / Ежедневный лог с датой
0 6 * * * /usr/bin/bash -lc 'printf "%s\n" "backup start $(date -Is)"' >>/var/log/backup_timestamps.log  # Timestamped marker / Маркер с временной меткой ISO
```

### Error Trapping / Перехват ошибок

```bash
0 0 * * * /usr/bin/bash -lc 'trap "echo FAIL" ERR; /opt/critical.sh' >>/var/log/critical.log 2>&1  # Trap errors in shell / Ловить ошибки в bash
```

---

## at — One-Shot Jobs

### Basic at Usage / Базовое использование at

```bash
echo "echo hi >> /tmp/hi" | at now + 5 minutes  # One-shot job in 5 minutes / Одноразовая задача через 5 минут
atq                                              # List at-jobs / Показать at-задания
atrm <JOBID>                                    # Remove at-job / Удалить at-задание
atq && atrm <JOBID>                             # List and remove / Показ и удаление at-заданий
```

---

## Anacron

### Anacron Configuration / Конфигурация anacron

`/etc/anacrontab`

```bash
# Format: period_in_days  delay_in_minutes  job_id  command
1	5	cron.daily	/usr/bin/run-parts /etc/cron.daily       # Anacron: daily tasks / Ежедневные задачи
7	10	cron.weekly	/usr/bin/run-parts /etc/cron.weekly      # Anacron: weekly tasks / Еженедельные задачи
@monthly	15	cron.monthly	/usr/bin/run-parts /etc/cron.monthly  # Anacron with @monthly / Ежемесячные задачи
RANDOM_DELAY=30                                  # Anacron: randomize delays / Случайная задержка старта
START_HOURS_RANGE=6-22                           # Anacron: run only 06–22 / Запускать задачи в интервале 06–22
```

### Anacron Commands / Команды anacron

```bash
anacron -fn                                      # Force run now, no timestamps / Принудительный запуск без отметок времени
MAILTO=admin@example.com anacron -s              # Mail results when serialized / Отправлять почту при последовательном запуске
```

> **Note:** Anacron is designed for systems that are not running 24/7 (laptops, desktops). It ensures missed jobs run after system resumes. / Anacron предназначен для систем, которые не работают 24/7. Он гарантирует запуск пропущенных заданий после включения.

---

## System Cron Directories

### Cron Directory Structure / Структура директорий cron

```bash
/etc/crontab                                    # System crontab with user field / Системный crontab с полем пользователя
/etc/cron.d/myjobs                              # Cron.d entry with explicit user / Запись в /etc/cron.d с указанием пользователя
/etc/cron.hourly/app-prune                      # Drop executable script here / Разместить исполняемый скрипт для почасового запуска
/etc/cron.daily/app-backup                      # Daily backup script / Ежедневный бэкап через скрипт
```

### System Crontab Examples / Примеры системного crontab

```bash
# /etc/crontab — includes user field / включает поле пользователя
0 2 * * * root /opt/job.sh                      # System crontab with user field / Системный crontab
5 0 * * * root /usr/sbin/logrotate /etc/logrotate.conf  # System logrotate nightly / Ночной logrotate

# /etc/cron.d/app
0 2 * * * appuser /usr/local/bin/task            # Cron.d file for appuser / Файл в cron.d для appuser
```

### run-parts — Batch Execution / Пакетный запуск

```bash
0 3 * * * /usr/bin/run-parts /etc/cron.daily    # Run scripts in cron.daily / Запуск скриптов каталога cron.daily
@hourly /usr/bin/run-parts /etc/cron.hourly     # Hourly run-parts / Почасовой запуск каталога cron.hourly
@weekly /usr/bin/run-parts /etc/cron.weekly      # Weekly run-parts / Еженедельный запуск
@monthly /usr/bin/run-parts /etc/cron.monthly    # Monthly run-parts / Ежемесячный запуск
run-parts --test /etc/cron.daily                # List scripts without running / Показать, что будет запущено, не исполняя
```

---

## Access Control

### User Access / Доступ пользователей

```bash
/etc/cron.allow                                 # Whitelist: users allowed cron / Белый список пользователей
/etc/cron.deny                                  # Blacklist: users denied cron / Чёрный список пользователей
echo <USER> > /etc/cron.allow                   # Allow only specific user / Разрешить cron для конкретного пользователя
echo baduser >> /etc/cron.deny                  # Deny a specific user / Запретить конкретного пользователя
```

> **Note:** If `cron.allow` exists, only listed users can use cron. If neither file exists, all users have access (some distros allow root only). / Если `cron.allow` существует, только перечисленные пользователи могут использовать cron.

---

## Backup & Restore

### Crontab Backup / Резервное копирование crontab

```bash
crontab -l > /var/backups/crontab.$(date +%F)   # Backup user crontab / Сохранить crontab в файл
crontab /var/backups/crontab.2025-10-02         # Restore crontab from file / Восстановить crontab из файла
crontab -u <USER> -l | sed 's/^/# /'           # Export as commented preview / Вывести crontab, закомментировав строки
```

---

## Real-World Examples

### Infrastructure Maintenance / Обслуживание инфраструктуры

```bash
0 2 * * * /usr/bin/flock -n /run/locks/backup.lock /opt/backup.sh >>/var/log/backup.log 2>&1  # Daily backup with lock / Ежедневный бэкап с блокировкой
0 */4 * * * /usr/bin/rsync -a /data/ <USER>@<HOST>:/backup/ >>/var/log/rsync.log 2>&1  # Rsync every 4 hours / Синхронизация каждые 4 часа
0 1 * * * /usr/bin/rsync -a --delete /data/ /mnt/backup/ >>/var/log/rsync_local.log 2>&1  # Mirror to local backup / Зеркалирование в локальный бэкап
```

### Database Backups / Бэкапы баз данных

```bash
0 1 * * * /usr/bin/pg_dumpall > /var/backups/pg/all.sql 2>>/var/log/pg_dump.err  # Postgres dump nightly / Ночной дамп Postgres
30 2 * * * /usr/bin/mysqldump --all-databases | gzip > /var/backups/mysql/all.sql.gz  # MySQL dump nightly / Ночной дамп MySQL
```

### Certificate & TLS / Сертификаты

```bash
0 0 * * 0 /usr/bin/certbot renew --quiet && /usr/sbin/nginx -s reload  # Renew TLS then reload / Обновить сертификаты и перезапустить nginx
0 */6 * * * /usr/bin/certbot renew --post-hook "/usr/bin/systemctl reload nginx"  # Renew with post-hook / Обновить с пост-хук
```

### Disk & Log Cleanup / Очистка дисков и логов

```bash
0 3 1 * * find /var/log/app -name "*.log" -mtime +30 -exec gzip {} \;  # Compress old logs / Сжимать логи старше 30 дней
0 0 * * * /usr/bin/find /tmp -type f -mtime +3 -delete                  # Purge old temp files / Удалять временные файлы старше 3 дней
0 4 * * * /usr/bin/journalctl --vacuum-time=14d                         # Vacuum journals older than 14d / Удалять журналы systemd старше 14 дней
0 2 * * * /usr/bin/find /var/lib/myapp/sessions -type f -mtime +14 -delete  # Purge old sessions / Удалять файлы сессий старше 14 дней
0 */12 * * * /usr/bin/find /var/backups -type f -mtime +90 -delete      # Prune backups older than 90d / Удалять бэкапы старше 90 дней
0 0 * * * /usr/bin/find /home -name core -type f -delete                # Remove core dumps daily / Удалять core-дампы ежедневно
0 2 * * * /usr/bin/find /var/www -type f -name '*.tmp' -delete          # Clean web temp files / Очистка временных файлов
```

### System Maintenance / Системное обслуживание

```bash
0 3 * * 1 /usr/sbin/fstrim -av >>/var/log/fstrim.log 2>&1             # Weekly TRIM for SSD / Еженедельный TRIM для SSD
0 8 * * * /usr/bin/apt-get update -qq && /usr/bin/apt-get -y dist-upgrade >>/var/log/apt.cron 2>&1  # Debian unattended upgrade / Обновление Debian
0 3 * * * /usr/bin/dnf -y upgrade >>/var/log/dnf.cron 2>&1             # RHEL/Fedora nightly upgrades / Ночные обновления RHEL/Fedora
0 1 * * * /usr/bin/docker system prune -af >>/var/log/docker_prune.log 2>&1  # Docker prune nightly / Ночная очистка Docker
```

### Monitoring & Health Checks / Мониторинг

```bash
*/15 * * * * /usr/bin/curl -fsS https://<HOST>/health || /usr/bin/logger --tag health "FAIL"  # HTTP healthcheck / HTTP-проверка
*/5 * * * * /usr/bin/curl -fsS https://status.example.com | grep -q "OK" || /opt/notify.sh  # Status endpoint check / Проверять статус-эндпоинт
*/30 * * * * /usr/bin/df -h | /usr/bin/logger --tag disk-usage          # Log disk usage / Логировать использование дисков
*/5 * * * * /usr/bin/kubectl get nodes | /usr/bin/logger --tag k8s      # Kubernetes nodes snapshot / Снимок списка нод K8s
0 12 * * * /usr/bin/chronyc tracking | /usr/bin/logger --tag time-sync  # Log NTP status / Логировать синхронизацию времени
*/30 6-22 * * * /usr/bin/ntpq -p | /usr/bin/logger --tag ntp           # Monitor NTP peers / Мониторить пиров NTP
```

### Logrotate & Cache / Ротация и кэш

```bash
0 0 * * * /usr/bin/logrotate -f /etc/logrotate.d/myapp               # Force rotate custom logs / Принудительная ротация
0 0 * * * /usr/bin/flock -n /run/locks/rotate.lock /usr/sbin/logrotate -s /var/lib/logrotate/status /etc/logrotate.conf  # Rotate with state / Ротация с явным файлом состояния
0 3 * * SUN /usr/bin/expire-caches >>/var/log/expire.log 2>&1        # Weekly cache expiration / Еженедельная просрочка кэшей
*/10 * * * * /usr/bin/opcache-gc >>/var/log/php-opcache.log 2>&1     # PHP opcache GC / Очистка opcache PHP
15 1 * * * /usr/bin/rsnapshot daily                                   # Trigger rsnapshot daily / Запуск дневного rsnapshot
```

### Size-Based Rotation / Ротация по размеру

```bash
0 0 * * * /usr/bin/test "$(stat -c%s /var/log/app.log)" -gt 104857600 && /opt/rotate_large.sh  # Rotate if >100MB / Ротировать лог при превышении 100 МБ
```

### Clean Environment / Чистое окружение

```bash
0 0 * * * /usr/bin/env -i PATH=/usr/bin:/bin /opt/clean_env.sh       # Run with clean environment / Выполнять в «чистом» окружении
0 0 * * * /usr/bin/systemd-run --user --scope -p After=network-online.target /opt/net_job.sh  # Use systemd-run for deps / Запуск с зависимостью от сети
0 0 * * * /usr/bin/flock -n /run/locks/pid.lock sh -c '[ -e /run/my.pid ] || /opt/start.sh'  # PID-guarded start / Защита от дублей через PID
```

### Timezone-Aware / Учёт часового пояса

```bash
CRON_TZ=UTC 55 23 * * * /usr/bin/rsync -a /data/ backup@<HOST>:/data_utc  # Run in UTC before day end / В UTC за 5 мин до полуночи
TZ=UTC 0 9 * * MON /usr/bin/bash -lc '/opt/report_utc.sh'            # Weekly report in UTC / Еженедельный отчёт в 09:00 UTC
```

### Email Notifications / Уведомления по почте

```bash
0 0 * * * echo "test" | /usr/bin/mail -s "Cron test" admin@example.com  # Send test email / Отправить тестовую почту
```

---

## Troubleshooting & Debugging

### Check Cron Logs / Проверка логов cron

```bash
grep CRON /var/log/syslog | tail -n 100         # Inspect cron messages (Debian) / Просмотреть сообщения cron (Debian/Ubuntu)
journalctl -u cron                              # Review cron unit logs / Логи юнита cron (systemd)
journalctl -u crond                             # Review crond logs (RHEL) / Логи демона crond (RHEL/CentOS)
```

### Debug Markers / Маркеры отладки

```bash
* * * * * date +%F\ %T >> /tmp/cron.tick        # Dry-run tick marker / Маркер-тикер для проверки запуска по минутам
* * * * * env | sort > /tmp/cron.env            # Capture cron environment / Сохранить окружение cron для диагностики
* * * * * /usr/bin/env -i /bin/bash -lc '/opt/job --dry-run' >>/var/log/dry.log 2>&1  # Dry-run under clean env / Пробный запуск в чистом окружении
```

---

## Logrotate for Cron

### Cron Log Rotation Config / Конфигурация ротации логов cron

`/etc/logrotate.d/cron`

```bash
/var/log/cron.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate 2>/dev/null || true
    endscript
}
```

---

## 💡 Best Practices / Лучшие практики

- Always use **full paths** to commands in crontab (`/usr/bin/rsync`, not `rsync`). / Всегда используйте полные пути к командам.
- Set a proper `PATH` at the top of your crontab. / Установите правильный `PATH` в начале crontab.
- Use `flock` to prevent overlapping runs. / Используйте `flock` для предотвращения наложений.
- Redirect output or set `MAILTO=` to avoid silent failures. / Перенаправляйте вывод или используйте `MAILTO=`.
- Use `timeout` to cap long-running jobs. / Используйте `timeout` для ограничения времени выполнения.
- **Back up your crontab** before making changes (`crontab -l > backup`). / Делайте резервную копию crontab.
- Escape `%` as `\%` in crontab entries. / Экранируйте `%` как `\%` в crontab.
- Test with `crontab -l` after editing. / Проверяйте через `crontab -l` после редактирования.

---

## 📋 Quick Reference / Быстрый справочник

```text
crontab -e          — Edit crontab / Редактировать crontab
crontab -l          — List entries / Показать задания
crontab -r          — Remove all (DANGER!) / Удалить все (ОПАСНО!)
at now + 5 min      — One-shot job / Одноразовая задача
flock -n LOCK CMD   — No-overlap run / Запуск без наложений
timeout 300 CMD     — Kill after 5 min / Убить через 5 минут
```
