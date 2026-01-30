Title: 🛠 systemctl — Commands
Group: System & Logs
Icon: 🛠
Order: 1

systemctl status nginx                          # Service status / Статус сервиса
sudo systemctl start|stop|restart nginx         # Control service / Управление сервисом
sudo systemctl enable --now nginx               # Enable + start / Включить и запустить
systemctl list-units --type=service --state=failed  # Failed services / Упалшие сервисы
journalctl -u nginx --since "1 hour ago"        # Logs from last hour / Логи за последний час


systemctl start myapp.service                     #Start a service immediately / Запустить службу немедленно
systemctl stop myapp.service                      #Stop a service immediately / Остановить службу немедленно
systemctl restart myapp.service                   #Restart a service / Перезапустить службу
systemctl reload myapp.service                    #Reload service configuration without full restart / Перезагрузить конфигурацию службы
systemctl status myapp.service                    #Show unit status with logs tail / Показать состояние юнита и хвост логов
systemctl is-active myapp.service                 #Check if service is active / Проверить, активна ли служба
systemctl is-failed myapp.service                 #Check if service is in failed state / Проверить, в состоянии failed служба
systemctl enable myapp.service                    #Enable service on boot / Включить автозапуск службы
systemctl disable myapp.service                   #Disable service autostart / Отключить автозапуск службы
systemctl is-enabled myapp.service                #Check if a service is enabled / Проверить, включена ли служба
systemctl mask myapp.service                      #Danger: mask service (block any startup) / Опасно: замаскировать службу (заблокировать запуск)
systemctl unmask myapp.service                    #Unmask service (allow startup) / Размаскировать службу (разрешить запуск)
systemctl list-units --type=service --state=running #List running service units / Список запущенных сервисов
systemctl list-unit-files --type=service          #List all service unit files / Список файлов юнитов служб
systemctl list-dependencies myapp.service         #Show unit dependencies / Показать зависимости юнита
systemctl list-dependencies --reverse myapp.service #Show dependents of given unit / Показать, какие юниты зависят
systemctl --failed                                #List all failed units / Показать все юниты в состоянии failed
journalctl -u myapp.service                       #Show full journal for service / Показать весь журнал службы
journalctl -u myapp.service --since today         #Show service logs since today / Логи службы с начала дня
journalctl -u myapp.service -f                    #Follow service logs in real time / Смотреть логи службы в реальном времени
journalctl -p err..alert                          #Show logs at error level or above / Показать логи с уровнем ошибок и выше
journalctl -b                                     #Show logs of current boot / Показать логи текущей загрузки
journalctl -b -1                                  #Show logs of previous boot / Показать логи предыдущей загрузки
systemd-analyze                                   #Show overall boot time / Показать общее время загрузки
systemd-analyze blame                             #List services by startup time descending / Сервисы по времени загрузки
systemd-analyze critical-chain myapp.service      #Show critical chain for a service / Показать цепочку зависимостей
[Unit]\nDescription=My App\nAfter=network.target  #Unit snippet: basic unit header / Фрагмент юнита: базовый заголовок
[Service]\nType=simple\nExecStart=/opt/myapp/run.sh #Unit snippet: simple service / Фрагмент юнита: простой сервис
[Service]\nType=forking\nExecStart=/usr/bin/mydaemon --daemon\nPIDFile=/run/mydaemon.pid #Unit snippet: forking service / Фрагмент юнита: демон с форком
[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/opt/myapp/init.sh #Unit snippet: one-shot service / Фрагмент юнита: однократное задание
[Service]\nRestart=on-failure\nRestartSec=5       #Unit snippet: restart policy / Фрагмент юнита: политика перезапуска
[Service]\nUser=myappuser\nGroup=myappgroup       #Unit snippet: user/group context / Фрагмент юнита: запуск от пользователя
[Service]\nNoNewPrivileges=yes\nProtectSystem=strict\nProtectHome=read-only\nPrivateTmp=yes #Unit snippet: sandboxing defaults / Фрагмент юнита: базовая изоляция
[Service]\nMemoryMax=50M\nCPUQuota=50%            #Unit snippet: resource limits / Фрагмент юнита: лимиты ресурсов
[Install]\nWantedBy=multi-user.target             #Unit snippet: install target binding / Фрагмент юнита: привязка к цели
[Timer]\nOnBootSec=1min\nOnUnitActiveSec=10min\nPersistent=yes #Unit snippet: timer schedule / Фрагмент таймера: планирование
[Socket]\nListenStream=8080\nAccept=no            #Unit snippet: basic socket activation / Фрагмент сокета: активация TCP
[Path]\nPathChanged=/opt/myapp/config.yml\nUnit=myapp.service #Unit snippet: path watch trigger / Фрагмент пути: триггер по изменению
----
systemctl daemon-reload                           #Reload systemd manager configuration / Перезагрузить конфигурацию systemd
systemctl reset-failed                            #Reset failed state of all units / Сбросить состояние failed всех юнитов
systemctl preset-all                              #Apply vendor presets to all units / Применить предустановки вендора ко всем юнитам
systemctl preset myapp.service                    #Apply vendor preset to unit / Применить предустановку к юниту
systemctl revert myapp.service                    #Revert overrides/drop-ins to unit / Вернуть юнит к версии без изменений
systemctl cat myapp.service                       #Show full unit file plus drop-ins / Показать файл юнита и переопределения
systemctl edit myapp.service                      #Edit drop-in override for unit / Редактировать переопределения юнита
systemctl edit --full myapp.service               #Edit full unit file interactively / Редактировать весь файл юнита
systemctl show myapp.service                      #Show all properties of unit / Показать все свойства юнита
systemctl show --property=MainPID myapp.service   #Show specific unit property / Показать конкретное свойство юнита
systemctl get-default                             #Show default target / Показать текущую цель по умолчанию
systemctl set-default graphical.target            #Set default boot target / Установить цель загрузки по умолчанию
systemctl isolate rescue.target                   #Danger: switch to rescue mode / Опасно: перейти в rescue режим
systemctl isolate emergency.target                #Danger: switch to emergency mode / Опасно: перейти в emergency режим
systemctl list-timers                             #List active timers / Показать активные таймеры
systemctl list-sockets                            #List active sockets / Показать активные сокеты
systemctl list-paths                              #List active path units / Показать активные path-юниты
systemctl list-unit-files --state=enabled         #List enabled units / Показать включённые юниты
systemctl list-unit-files --state=disabled        #List disabled units / Показать отключённые юниты
loginctl enable-linger user@host                  #Enable user lingering for user services / Включить linger для пользовательских юнитов
systemctl --user start myapp.service              #Start a user service in user mode / Запустить пользовательскую службу
systemctl --user enable myapp.service             #Enable user service autostart / Включить автозапуск пользовательской службы
systemctl --user status myapp.service             #Check status of user-level service / Проверить статус в user режиме
systemctl --user daemon-reload                    #Reload user mode units configurations / Перезагрузить конфигурации в user режиме
[Service]\nDelegate=yes                           #Unit snippet: allow cgroup delegation (containers) / Фрагмент юнита: разрешить делегирование cgroup
systemd-nspawn -bD /var/lib/machines/mycontainer  #Boot container for testing / Запустить container для тестирования
machinectl list                                   #List managed machines / Показать список машин machinectl
machinectl shell mycontainer /bin/bash            #Open shell in container / Открыть оболочку в контейнере
[Service]\nCPUWeight=1000\nIOWeight=1000          #Unit snippet: proportional resource weights / Фрагмент юнита: веса ресурсов
[Service]\nMemoryHigh=40M                         #Unit snippet: soft memory limit threshold / Фрагмент юнита: мягкий лимит памяти
[Service]\nTasksMax=500                           #Unit snippet: limit number of tasks (newer systemd) / Фрагмент юнита: лимит задач (новые версии)
[Service]\nIOReadBandwidthMax=/dev/sda 10M        #Unit snippet: I/O read cap / Фрагмент юнита: ограничение чтения
[Service]\nIOWriteBandwidthMax=/dev/sda 5M        #Unit snippet: I/O write cap / Фрагмент юнита: ограничение записи
[Service]\nCPUQuota=20%                           #Unit snippet: limit CPU share / Фрагмент юнита: ограничение CPU
[Service]\nProtectHome=yes                        #Unit snippet: protect home directories / Фрагмент юнита: защита /home
[Service]\nProtectSystem=full                     #Unit snippet: readonly root and /usr / Фрагмент юнита: режим полного каталога
[Service]\nProtectKernelTunables=yes\nProtectControlGroups=yes #Unit snippet: protect kernel/settings / Фрагмент юнита: защита ядра/контроля
[Service]\nPrivateDevices=yes                     #Unit snippet: isolate device nodes / Фрагмент юнита: приватные устройства
[Service]\nNoNewPrivileges=yes                    #Unit snippet: disable privilege escalation / Фрагмент юнита: запрет повышения привилегий
[Service]\nAmbientCapabilities=CAP_NET_BIND_SERVICE #Unit snippet: allow ambient cap / Фрагмент юнита: ambient capability
[Service]\nCapabilityBoundingSet=CAP_SYS_RESOURCE #Unit snippet: bounding set of capabilities / Фрагмент юнита: bounding capabilities
[Service]\nRestrictAddressFamilies=AF_INET AF_INET6 #Unit snippet: restrict address families / Фрагмент юнита: ограничение протоколов
[Service]\nSystemCallFilter=~@clock @cpu-emulation #Unit snippet: syscall filtering / Фрагмент юнита: фильтрация системных вызовов
[Service]\nMemoryDenyWriteExecute=yes             #Unit snippet: disallow RWX memory mappings / Фрагмент юнита: запрет RWX
[Service]\nLockPersonality=yes                    #Unit snippet: lock personality (exec domain) / Фрагмент юнита: фиксировать личность процесса
[Service]\nRestrictSUIDSGID=yes                   #Unit snippet: disable suid/sgid / Фрагмент юнита: запрет suid/sgid
[Service]\nReadOnlyPaths=/etc /usr/lib            #Unit snippet: readonly path restrictions / Фрагмент юнита: только для чтения пути
[Service]\nReadWritePaths=/var/log/myapp          #Unit snippet: writable specific paths / Фрагмент юнита: разрешённая запись
[Service]\nTemporaryFileSystem=/tmp:ro            #Unit snippet: tmp as temporary FS readonly / Фрагмент юнита: временная FS
[Service]\nProtectKernelModules=yes               #Unit snippet: protect kernel modules / Фрагмент юнита: защита модулей ядра
[Service]\nProtectControlGroups=yes               #Unit snippet: protect cgroup settings from modification / Фрагмент юнита: защита cgroup
[Service]\nPrivateTmp=yes                         #Unit snippet: private /tmp per service / Фрагмент юнита: приватный /tmp
[Service]\nKillMode=control-group                 #Unit snippet: kill full cgroup on stop / Фрагмент юнита: kill всей cgroup
[Service]\nTimeoutStartSec=30                     #Unit snippet: startup timeout / Фрагмент юнита: таймаут запуска
[Service]\nTimeoutStopSec=20                      #Unit snippet: shutdown timeout / Фрагмент юнита: таймаут остановки
[Service]\nExecReload=/bin/kill -HUP $MAINPID     #Unit snippet: reload command / Фрагмент юнита: команда перезагрузки
[Service]\nExecStop=/usr/bin/stop-script.sh       #Unit snippet: stop command / Фрагмент юнита: команда остановки
[Unit]\nRequires=network.target                   #Unit snippet: hard dependency / Фрагмент юнита: жёсткая зависимость
[Unit]\nWants=redis.service                       #Unit snippet: soft dependency / Фрагмент юнита: мягкая зависимость
[Unit]\nAfter=network-online.target               #Unit snippet: ordering after online network / Фрагмент юнита: запуск после сети
[Unit]\nBefore=shutdown.target                    #Unit snippet: ordering before shutdown / Фрагмент юнита: запуск до остановки системы
[Unit]\nPartOf=other.service                      #Unit snippet: part-of grouping / Фрагмент юнита: включение в группу
[Unit]\nBindsTo=other.service                     #Unit snippet: bind dependency / Фрагмент юнита: привязка зависимости
[Unit]\nConflicts=foo.service                     #Unit snippet: conflict dependency / Фрагмент юнита: конфликт юнита
[Unit]\nConditionPathExists=/etc/myapp/config.yml #Unit snippet: conditional start / Фрагмент юнита: условие наличия пути
[Unit]\nAssertPathExists=/etc/myapp/secure.key    #Unit snippet: assert file existence / Фрагмент юнита: проверка файла
[Unit]\nStartLimitIntervalSec=60\nStartLimitBurst=5 #Unit snippet: rate limiting of restarts / Фрагмент юнита: ограничение рестартов
[Timer]\nOnCalendar=*-*-* 02:00:00                #Unit snippet: daily timer at 2 AM / Фрагмент таймера: ежедневно в 2:00
[Timer]\nOnUnitActiveSec=1h                       #Unit snippet: run service 1h after last activation / Фрагмент таймера: каждый час
[Timer]\nOnUnitInactiveSec=30min                  #Unit snippet: run service 30 min after stop / Фрагмент таймера: через 30 мин после остановки
[Timer]\nAccuracySec=1s                           #Unit snippet: fine-grained timer accuracy / Фрагмент таймера: точность с 1 с
[Timer]\nRandomizedDelaySec=5min                  #Unit snippet: add random delay / Фрагмент таймера: случайная задержка
[Timer]\nPersistent=yes                           #Unit snippet: catch-up missed runs on boot / Фрагмент таймера: догонять пропущенные задания
[Socket]\nAccept=yes                              #Unit snippet: per-connection socket template / Фрагмент сокета: шаблон per-connection
[Socket]\nListenDatagram=9000                     #Unit snippet: datagram socket / Фрагмент сокета: UDP сокет
[Socket]\nListenStream=0.0.0.0:22                 #Unit snippet: listen on all interfaces / Фрагмент сокета: слушать на всех интерфейсах
[Path]\nPathExists=/opt/myapp/trigger.flag        #Unit snippet: path exists trigger / Фрагмент пути: триггер по существованию
[Mount]\nWhat=/dev/sdb1\nWhere=/mnt/data\nType=ext4\nOptions=defaults #Unit snippet: mount unit / Фрагмент монтирования
[Automount]\nWhere=/mnt/data                      #Unit snippet: automount unit / Фрагмент автозамонтирования
[Device]\n#Device units are auto-generated by udev #Unit snippet: auto-generated device unit / Фрагмент (устройство) генерируется udev
[Service]\nSyslogIdentifier=myapp                 #Unit snippet: set syslog tag / Фрагмент юнита: идентификатор лога
[Service]\nStandardOutput=journal\nStandardError=inherit #Unit snippet: stdout/stderr routing / Фрагмент юнита: вывод в журнал
[Service]\nEnvironment=ENV_VAR=value              #Unit snippet: set environment variable / Фрагмент юнита: переменная окружения
[Service]\nEnvironmentFile=/etc/myapp/env.conf    #Unit snippet: load env file / Фрагмент юнита: считывать файл окружения
[Service]\nWorkingDirectory=/opt/myapp            #Unit snippet: set working directory / Фрагмент юнита: рабочий каталог
systemd-analyze plot > boot.svg                   #Export boot sequence to SVG / Выгрузить граф загрузки в SVG
systemctl cat multi-user.target                   #Show installed target unit file / Показать файл цели multi-user.target
systemctl edit getty@tty1.service                 #Override getty on tty1 / Переопределить getty на tty1
systemctl isolate graphical.target                #Switch to graphical target / Переключиться на графический режим
systemctl reboot                                  #Reboot system / Перезагрузить систему
systemctl poweroff                                #Power off system / Выключить систему

