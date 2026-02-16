Title: ⏰ cron / at — Commands
Group: System & Logs
Icon: ⏰
Order: 8

crontab -e                                      # Edit user crontab / Редактировать crontab пользователя
# ┌min┬hour┬dom┬mon┬dow┐
#  0   3    *   *   *   /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1  # Nightly backup / Ночной бэкап
crontab -l                                      # List cron entries / Показать задания cron
echo "echo hi >> /tmp/hi" | at now + 5 minutes  # One-shot job in 5 minutes / Одноразовая задача через 5 минут
atq && atrm <jobid>                             # List and remove at-jobs / Показ и удаление at-заданий

cron mega-cheatsheet — commands and cron line templates in "<команда/шаблон> #desc in English / описание на русском" format
crontab -e                                                   #Edit current user's crontab / Редактировать crontab текущего пользователя
crontab -l                                                   #List current user's crontab / Показать crontab текущего пользователя
crontab -r                                                   #Danger: remove current user's crontab / Опасно: удалить crontab пользователя (все задания исчезнут)
crontab -u user-name -e                                      #Edit another user's crontab (root) / Редактировать crontab другого пользователя (нужны права root)
crontab -u user-name -l                                      #List another user's crontab / Показать crontab другого пользователя
/etc/crontab 0 2 * * * root /opt/job.sh                      #System crontab with user field / Системный crontab: есть поле пользователя перед командой
/etc/cron.d/myjobs 15 3 * * * user-name /opt/job.sh          #Cron.d entry with explicit user / Запись в /etc/cron.d с указанием пользователя
@reboot /opt/job.sh                                          #Run once at boot / Запуск единожды при старте системы
@yearly /opt/job.sh                                          #Run yearly (0 0 1 1 *) / Годовой запуск (эквивалент 0 0 1 1 *)
@annually /opt/job.sh                                        #Alias of @yearly / Синоним @yearly
@monthly /opt/job.sh                                         #Run monthly (0 0 1 * *) / Запуск раз в месяц (0 0 1 * *)
@weekly /opt/job.sh                                          #Run weekly (0 0 * * 0) / Запуск раз в неделю (0 0 * * 0)
@daily /opt/job.sh                                           #Run daily (0 0 * * *) / Ежедневный запуск (0 0 * * *)
@midnight /opt/job.sh                                        #Alias of @daily / Синоним @daily (полночь)
@hourly /opt/job.sh                                          #Run hourly (0 * * * *) / Почасовой запуск (0 * * * *)
0 * * * * /opt/job.sh                                        #Top of every hour / В начале каждого часа
0 0 * * * /opt/job.sh                                        #Daily at midnight / Ежедневно в полночь
0 0 * * 0 /opt/job.sh                                        #Sundays at midnight / По воскресеньям в полночь
*/15 * * * * /opt/job.sh                                     #Every 15 minutes / Каждые 15 минут
0 4 1 * * /opt/job.sh                                        #Monthly at 04:00 on day 1 / Ежемесячно в 04:00 первого числа
0 9-18 * * * /opt/job.sh                                     #Hourly 09–18 / Каждый час с 09 до 18
0 0 1-7 * * /opt/job.sh                                      #First seven days monthly / Первые семь дней месяца в полночь
0 0 1,15 * * /opt/job.sh                                     #On the 1st and 15th / В полночь 1-го и 15-го числа
0 0 * * 1,3,5 /opt/job.sh                                    #Mon, Wed, Fri at midnight / По пн, ср, пт в полночь
0 */3 * * * /opt/job.sh                                      #Every 3 hours / Каждые три часа
0 8-18/2 * * 1-5 /opt/job.sh                                 #Every 2 hours on workdays / Каждые 2 часа с 8 до 18 по будням
0 0,12 1-10,15 * * /opt/job.sh                                #00:00 and 12:00 on dates / В 00:00 и 12:00 в указанные дни

* * * * * timeout 300 /opt/job.sh                            #Timeout after 5 minutes / Принудительно завершить через 5 минут
* * * * * /usr/bin/flock -n /tmp/job.lock /opt/job.sh        #No-overlap via flock / Исключить наложения запусков через flock
          0 2 * * * /opt/first.sh && touch /tmp/ok.flag                #Create success flag / Создать флаг успешного выполнения
          15 2 * * * [ -f /tmp/ok.flag ] && /opt/second.sh && rm /tmp/ok.flag  #Conditional follow-up / Запускать вторую задачу при наличии флага
          0 22 * * * [ $(awk '{print 100-$NF}' /proc/loadavg | cut -d. -f1) -lt 30 ] && /opt/backup.sh  #Run on low CPU load / Запускать бэкап при низкой загрузке CPU
          */5 * * * * [ $(pgrep -c -f "script.sh") -eq 0 ] && /opt/script.sh    #Skip if process exists / Пропускать, если процесс уже запущен
          0 3 1 * * find /var/log/app -name "*.log" -mtime +30 -exec gzip {} ;  #Compress old logs / Сжимать логи старше 30 дней
          0 * * * * timeout 600 /opt/long.sh                           #Limit to 10 minutes / Ограничить выполнение десятью минутами
          SHELL=/bin/sh                                                #Set cron shell to /bin/sh / Указать оболочку cron как /bin/sh
          PATH=/usr/bin:/bin                                           #Minimal PATH example / Пример минимального PATH
          HOME=/home/user-name                                         #Define HOME for jobs / Задать HOME для задач
          MAILTO=syslog                                                #Mail output to syslog target / Направить почтовый вывод в syslog
          0 0 * * * /opt/job.sh >> "/var/log/script_$(date +%Y%m%d).log" 2>&1  #Rotate by date in name / Лог с датой (экранировать % в cron)

---

crontab -l > /var/backups/crontab.$(date +%F)                #Backup user crontab / Сохранить crontab пользователя в файл-резервную копию
crontab /var/backups/crontab.2025-10-02                      #Restore crontab from file / Восстановить crontab пользователя из файла
crontab -u user-name -l | sed 's/^/# /'                      #Export as commented preview / Вывести crontab, закомментировав строки для обзора
crontab -u user-name -r                                      #Danger: remove other user's crontab / Опасно: удалить crontab другого пользователя (данные потеряются)
SHELL=/bin/bash                                              #Use bash for advanced features / Использовать bash для расширенных возможностей
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin  #Set robust PATH / Установить полноценный PATH для задач
HOME=/var/lib/myapp                                          #Set HOME to app directory / Назначить HOME на каталог приложения
USER=user-name                                               #Expose USER for scripts / Задать USER для использования в скриптах
LOGNAME=user-name                                            #Expose LOGNAME for mail/logs / Указать LOGNAME для почты и логов
MAILTO=                                                      #Disable email for all jobs / Отключить почтовые уведомления для всех задач
0 0 * * * MAILTO=[admin@example.com](mailto:admin@example.com) /opt/backup.sh            #Per-job email recipient / Указать получателя почты для одной задачи
CRON_TZ=UTC 0 0 * * * /opt/utc_daily.sh                      #Run at UTC midnight / Запускать ровно в полночь по UTC (обход DST)
TZ=Europe/Rome 30 7 * * * /opt/local_job.sh                  #Run at 07:30 Europe/Rome / Запуск в 07:30 по Europe/Rome (DST учитывается)
LC_ALL=C 0 * * * * /opt/locale_neutral.sh                    #Run with C locale / Запускать с нейтральной локалью C
LANG=en_US.UTF-8 5 0 * * * /opt/unicode_job.sh               #Ensure UTF-8 environment / Гарантировать окружение UTF-8
umask 027; 0 1 * * * /opt/secure_task.sh                     #Tight default permissions / Жёсткие права по умолчанию для создаваемых файлов
nice -n 10 ionice -c2 -n7 /opt/job.sh                        #Lower CPU and IO priority / Уменьшить приоритеты CPU и IO для задачи

* * * * * /usr/bin/logger --tag cron-heartbeat "tick"        #Syslog heartbeat each minute / Минутный сигнал в syslog (проверка cron)
          0 2 * * * /opt/task.sh >> /var/log/task.log 2>&1             #Append stdout+stderr to file / Добавлять stdout и stderr в файл лога
          0 2 * * * /opt/task.sh > /var/log/out.log 2> /var/log/err.log  #Split stdout/stderr logs / Разнести stdout и stderr по файлам
          0 3 * * * /opt/task.sh | /usr/bin/logger --tag task          #Pipe to syslog with tag / Перенаправить вывод задачи в syslog с тегом
          0 4 * * * /opt/task.sh >/dev/null 2>&1                       #Silence all output / Полностью подавить вывод (почта не отправится)
          0 5 * * * /opt/task.sh 2>&1 | /usr/bin/logger --priority local0.err --tag cron-task  #Send errors to syslog / Отправить ошибки в syslog с приоритетом
          */7 * * * * /usr/bin/flock -n /run/locks/job.lock /opt/job.sh #Non-overlapping every 7 minutes / Исключить параллелизм при запуске каждые 7 минут
          */5 * * * * /usr/bin/flock -w 20 /run/locks/job.lock /opt/job.sh      #Wait up to 20s for lock / Ждать блокировку до 20 секунд
          0 * * * * /usr/bin/flock -n /run/locks/once.lock bash -lc '/opt/rotate.sh >>/var/log/rot.log 2>&1'  #Lock and shell-wrapped / Блокировка и запуск через bash с логом
* * * * * /usr/bin/timeout 180 /usr/bin/flock -n /run/locks/guard.lock /opt/guarded.sh  #Timeout plus lock / Таймаут и блокировка одновременно
          */10 * * * * [ -e /run/maintenance.lock ] || /opt/healthcheck.sh     #Skip during maintenance / Пропускать запуски при наличии флага обслуживания
          */5 9-17 * * 1-5 /opt/check.sh                               #Every 5 minutes business hours / Каждые 5 минут в рабочие часы по будням
          0 */3 * * 1-5 /opt/report.sh                                 #Every 3 hours on weekdays / Каждые три часа по будням
          0 10,14,18 * * 1-5 /opt/notify.sh                            #Multiple times per workday / Несколько запусков в будни (10,14,18)
          30 23 * * * sleep $((RANDOM%900)); /opt/spread.sh            #Spread starts within 15m / Равномерный сдвиг старта до 15 минут
          RANDOM_DELAY=45 @daily /opt/heavy.sh                         #Cronie: randomize start up to 45s / Cronie: случайная задержка до 45 сек
          0 23 28-31 * * [ "$(date -d tomorrow +%m)" != "$(date +%m)" ] && /opt/month_end.sh  #Last day of month / Запуск в последний день месяца
          0 0 29 2 * /opt/leapday.sh                                   #Run on Feb 29 / Запуск только 29 февраля (високосный)
          0 6 1-7 * MON /opt/first_monday.sh                           #First Monday each month / Первый понедельник каждого месяца
          0 0 * * SAT,SUN /opt/weekend_task.sh                         #Weekends at midnight / По выходным в полночь
          0 8 * * MON-FRI /opt/workday_0800.sh                         #Workdays at 08:00 / По будням в 08:00
          0 9-17/2 * * 1-5 /opt/every2h_daytime.sh                     #Every 2h 9–17 weekdays / Каждые 2 часа с 9 до 17 по будням
          */20 * * * * test $(date +%u) -lt 6 && /opt/weekday_only.sh #Weekdays via date %u / Будни через проверку дня недели
          0 3 * * * /usr/bin/run-parts /etc/cron.daily                 #Run scripts in cron.daily / Запуск всех скриптов каталога cron.daily
          @hourly /usr/bin/run-parts /etc/cron.hourly                  #Hourly run-parts / Почасовой запуск каталога cron.hourly
          @weekly /usr/bin/run-parts /etc/cron.weekly                  #Weekly run-parts / Еженедельный запуск каталога cron.weekly
          @monthly /usr/bin/run-parts /etc/cron.monthly                #Monthly run-parts / Ежемесячный запуск каталога cron.monthly
          run-parts --test /etc/cron.daily                             #List scripts without running / Показать, что будет запущено, не исполняя
          /etc/cron.d/app 0 2 * * * appuser /usr/local/bin/task        #Cron.d file for appuser / Файл в cron.d: запуск от имени appuser
          /etc/crontab 5 0 * * * root /usr/sbin/logrotate /etc/logrotate.conf  #System logrotate nightly / Ночной запуск logrotate в системном crontab
          /etc/cron.hourly/app-prune                                   #Drop executable script here / Разместить исполняемый скрипт для почасового запуска
          /etc/cron.daily/app-backup                                   #Daily backup script location / Ежедневный бэкап через скрипт в каталоге
          /etc/anacrontab                                              #Edit anacron schedule file / Править расписание anacron в /etc/anacrontab
          1	cron.daily	5	/usr/bin/run-parts /etc/cron.daily         #Anacron: period,id,delay,cmd / Anacron: период, имя, задержка, команда
          7	cron.weekly	10	/usr/bin/run-parts /etc/cron.weekly        #Anacron: weekly tasks / Anacron: запуск еженедельных задач
          @monthly	cron.monthly	15	/usr/bin/run-parts /etc/cron.monthly  #Anacron with @monthly / Anacron: использование @monthly
          RANDOM_DELAY=30                                              #Anacron: randomize delays / Anacron: случайная задержка старта всех задач
          START_HOURS_RANGE=6-22                                       #Anacron: run only 06–22 / Anacron: запускать задачи лишь в интервале 06–22
          anacron -fn                                                  #Force run now, no timestamps / Принудительный запуск без отметок времени
          MAILTO=[admin@example.com](mailto:admin@example.com) anacron -s                          #Mail results when serialized / Отправлять почту при последовательном запуске
          0 2 * * * /usr/bin/flock -n /run/locks/backup.lock /opt/backup.sh >>/var/log/backup.log 2>&1  #Daily backup with lock / Ежедневный бэкап с блокировкой и логом
          0 */4 * * * /usr/bin/rsync -a /data/ user@host:/backup/ >>/var/log/rsync.log 2>&1            #Rsync every 4 hours / Синхронизация каждые 4 часа
          */15 * * * * /usr/bin/curl -fsS [https://example.com/health](https://example.com/health) || /usr/bin/logger --tag health "FAIL"  #HTTP healthcheck and alert / HTTP-проверка и сигнал при сбое
          0 1 * * * /usr/bin/pg_dumpall > /var/backups/pg/all.sql 2>>/var/log/pg_dump.err               #Postgres dump nightly / Ночной дамп Postgres с логом ошибок
          30 2 * * * /usr/bin/mysqldump --all-databases | gzip > /var/backups/mysql/all.sql.gz          #MySQL dump nightly / Ночной дамп MySQL c сжатием
          0 0 * * 0 /usr/bin/certbot renew --quiet && /usr/sbin/nginx -s reload                          #Renew TLS then reload / Обновить сертификаты и перезапустить nginx
          0 3 * * 1 /usr/sbin/fstrim -av >>/var/log/fstrim.log 2>&1                                      #Weekly TRIM for SSD / Еженедельный TRIM для SSD
          0 0 * * * /usr/bin/find /tmp -type f -mtime +3 -delete                                          #Purge old temp files / Удалять временные файлы старше трёх дней
          0 4 * * * /usr/bin/journalctl --vacuum-time=14d                                                 #Vacuum journals older than 14d / Удалять журналы systemd старше 14 дней
          */30 * * * * /usr/bin/df -h | /usr/bin/logger --tag disk-usage                                  #Log disk usage periodically / Периодически логировать использование дисков
          0 2 * * * /usr/bin/timeout 3600 /opt/heavy_job.sh >>/var/log/heavy.log 2>&1                     #Cap runtime to 1h / Ограничить время выполнения одной часов
          0 6 * * * /usr/bin/flock -n /run/locks/migrate.lock /opt/migrate.sh                             #Serialize migrations / Сериализовать миграции блокировкой
* * * * * /usr/bin/test -f /run/skip.cron || /opt/minutely.sh                                    #Skip when skip-file exists / Пропускать при наличии файла-признака
          0 1 * * * /usr/bin/test -x /usr/local/bin/do && /usr/local/bin/do                                #Run only if executable exists / Запускать лишь при наличии исполняемого файла
          0 0 * * * /usr/bin/env -i PATH=/usr/bin:/bin /opt/clean_env.sh                                   #Run with clean environment / Выполнять в «чистом» окружении
          0 0 * * * /usr/bin/systemd-run --user --scope -p After=network-online.target /opt/net_job.sh     #Use systemd-run for deps / Запуск через systemd-run при зависимости от сети
          0 0 * * * /usr/bin/flock -n /run/locks/pid.lock sh -c '[ -e /run/my.pid ] || /opt/start.sh'      #PID-guarded start / Защита от дублей через PID-файл
          0 12 * * * /usr/bin/chronyc tracking | /usr/bin/logger --tag time-sync                           #Log NTP status at noon / Логировать состояние синхронизации времени
          0 0 * * * (/bin/date; echo ran) >>/var/log/cron_$(date +%F).log 2>&1                            #Daily dated logfile / Ежедневный лог с датой в имени (экранировать %)
          0 8 * * * /usr/bin/apt-get update -qq && /usr/bin/apt-get -y dist-upgrade >>/var/log/apt.cron 2>&1  #Debian unattended upgrade / Обновление Debian без лишнего вывода
          0 3 * * * /usr/bin/dnf -y upgrade >>/var/log/dnf.cron 2>&1                                       #RHEL/Fedora nightly upgrades / Ночные обновления RHEL/Fedora
          0 5 * * 1 /usr/sbin/useradd -m -c "temp user" tempuser                                           #Automate maintenance users / Автоматизировать создание временных пользователей
          0 6 * * 1 /usr/sbin/userdel -r tempuser                                                          #Remove maintenance user / Удалять временного пользователя вместе с HOME
          0 0 * * * /usr/bin/logrotate -f /etc/logrotate.d/myapp                                           #Force rotate custom logs / Принудительная ротация логов приложения
          0 0 * * * echo "test" | /usr/bin/mail -s "Cron test" [admin@example.com](mailto:admin@example.com)                           #Send test email / Отправить тестовую почту из cron
          /etc/cron.allow                                             #Whitelist users allowed to use cron / Белый список пользователей, кому разрешён cron
          /etc/cron.deny                                              #Blacklist users denied cron / Чёрный список пользователей, кому запрещён cron
          echo user-name > /etc/cron.allow                            #Allow only specific user / Разрешить доступ к cron для конкретного пользователя
          echo baduser >> /etc/cron.deny                              #Deny a specific user / Запретить конкретного пользователя к cron
          grep CRON /var/log/syslog | tail -n 100                     #Inspect cron messages (Debian) / Просмотреть сообщения cron (Debian/Ubuntu)
          journalctl -u cron                                          #Review cron unit logs / Просмотреть логи юнита cron (systemd)
          journalctl -u crond                                         #Review crond logs (RHEL) / Просмотреть логи демона crond (RHEL/CentOS)
* * * * * date +%F\ %T >> /tmp/cron.tick                    #Dry-run tick marker / Маркер-тикер для проверки запуска по минутам
* * * * * env | sort > /tmp/cron.env                         #Capture cron environment / Сохранить окружение cron для диагностики
* * * * * /usr/bin/env -i /bin/bash -lc '/opt/job --dry-run' >>/var/log/dry.log 2>&1  #Dry-run under clean env / Пробный запуск в чистом окружении
          0 0 * * * /usr/bin/test "$(stat -c%s /var/log/app.log)" -gt 104857600 && /opt/rotate_large.sh    #Rotate if >100MB / Ротировать лог при превышении 100 МБ
          0 */6 * * * /usr/bin/certbot renew --post-hook "/usr/bin/systemctl reload nginx"                 #Renew with post-hook / Обновить сертификаты с пост-хук перезагрузкой
          0 */12 * * * /usr/bin/find /var/backups -type f -mtime +90 -delete                               #Prune backups older than 90d / Удалять бэкапы старше 90 дней
          15 1 * * * /usr/bin/rsnapshot daily                          #Trigger rsnapshot daily / Запуск дневного rsnapshot
          */10 * * * * /usr/bin/opcache-gc >>/var/log/php-opcache.log 2>&1                                 #PHP opcache GC / Очистка opcache PHP каждые 10 минут
          0 1 * * * /usr/bin/docker system prune -af >>/var/log/docker_prune.log 2>&1                      #Docker prune nightly / Ночная очистка Docker
          */5 * * * * /usr/bin/kubectl get nodes | /usr/bin/logger --tag k8s                                #Kubernetes nodes snapshot / Снимок списка нод Kubernetes
          0 2 * * * /usr/bin/find /var/www -type f -name '*.tmp' -delete                                   #Clean web temp files / Очистка временных файлов веб-сайта
          CRON_TZ=UTC 55 23 * * * /usr/bin/rsync -a /data/ backup@host:/data_utc                           #Run in UTC before day end / В UTC за 5 минут до полуночи (устойчиво к DST)
          TZ=UTC 0 9 * * MON /usr/bin/bash -lc '/opt/report_utc.sh'                                        #Weekly report in UTC / Еженедельный отчёт в 09:00 по UTC
          0 0 * * * test -x /usr/local/bin/run-one && run-one /opt/solo.sh                                 #Ubuntu run-one if present / Ubuntu: предотвращение дублей через run-one
          0 0 * * * /usr/bin/flock -n /run/locks/rotate.lock /usr/sbin/logrotate -s /var/lib/logrotate/status /etc/logrotate.conf  #Rotate with state file / Ротация с явным файлом состояния
          0 6 * * * /usr/bin/bash -lc 'printf "%s\n" "backup start $(date -Is)"' >>/var/log/backup_timestamps.log  #Timestamped marker / Маркер с временной меткой ISO
          0 0 * * * /usr/bin/bash -lc 'trap "echo FAIL" ERR; /opt/critical.sh' >>/var/log/critical.log 2>&1       #Trap errors in shell / Ловить ошибки в bash и логировать
          0 2 * * * /usr/bin/find /var/lib/myapp/sessions -type f -mtime +14 -delete                        #Purge old sessions / Удалять файлы сессий старше 14 дней
          */30 6-22 * * * /usr/bin/ntpq -p | /usr/bin/logger --tag ntp                                     #Monitor NTP peers / Мониторить пиров NTP дневными часами
          0 3 * * SUN /usr/bin/expire-caches >>/var/log/expire.log 2>&1                                    #Weekly cache expiration / Еженедельная просрочка кэшей в воскресенье
          0 1 * * * /usr/bin/rsync -a --delete /data/ /mnt/backup/ >>/var/log/rsync_local.log 2>&1         #Mirror to local backup / Зеркалирование в локальный бэкап
          0 0 * * * /usr/bin/find /home -name core -type f -delete                                         #Remove core dumps daily / Удалять core-дампы ежедневно
          */5 * * * * /usr/bin/curl -fsS [https://status.example.com](https://status.example.com) | grep -q "OK" || /opt/notify.sh       #Check status endpoint / Проверять статус-эндпоинт и уведомлять при сбое
          0 0 * * * /usr/bin/logger --priority local7.info "Cron is alive"                                  #Heartbeat log / Лог-индикатор работы cron
