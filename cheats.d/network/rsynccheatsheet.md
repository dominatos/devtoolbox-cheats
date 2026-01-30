Title: 🚚 RSYNC — Commands
Group: Network
Icon: 🚚
Order: 8

rsync -avh --progress src/ dest/                # Sync dir / Синхронизация каталогов
rsync -avz --progress -e "ssh -p 2222 -i ~/.ssh/id_ed25519" src/ user@host:/path/  # Over SSH / Через SSH
rsync -avz --progress user@host:/path/ ./dest/  # Pull from remote / Загрузка с удалённого
rsync -avhn --delete src/ dest/                 # Dry-run with deletion preview / Прогон с показом удаления
rsync -avh --delete --exclude ".git/" --exclude "*.tmp" src/ dest/  # Exclude patterns / Исключить паттерны
rsync -avh --partial --append-verify src/ dest/ # Resume large file transfers / Досыл больших файлов
rsync -avh --bwlimit=2m --info=stats2 src/ dest/# Limit bandwidth + stats / Ограничить полосу + статистика

rsync -av --delete /src/ user@host:/backup/projects/ #Mirror source to remote and delete extras / Зеркалирует источник на сервере, удаляя лишнее у приёмника (опасно при ошибочных путях)
rsync -avn --delete /src/ user@host:/backup/projects/ #Dry run of mirror with deletions / Пробный запуск зеркалирования с удалениями; показывает, что будет удалено и скопировано
rsync -av --progress --partial-dir=.partial-dir user@host:/big/file.iso ./ #Resume large file via partial-dir / Докачка большого файла в безопасную временную папку, затем перенос по завершении
rsync -av --bwlimit=625 user@host:/data/ /backup/ #Throttle to ~5 Mbps / Ограничивает скорость передачи до ~5 Мбит/с, снижая нагрузку на сеть
rsync -av --bwlimit=1024 user@host:/data/ /backup/ #Throttle to 1 MiB/s / Ограничивает скорость до 1 МБ/с для более предсказуемой загрузки канала
rsync -avz -e 'ssh -p 2222' /data/ user@host:/backups/ #SSH on custom port with compression / Подключение по SSH на нестандартном порту с сжатием данных
rsync -avz -e 'ssh -p 2222' user@host:/var/log/app/ ./logs/ #Pull logs over custom SSH port / Забирает логи с сервера по нестандартному порту SSH
rsync -avz -e 'ssh -p 2222 -i ~/.ssh/id_ed25519' /data/ user@host:/backups/ #SSH custom port and key / Использует указанный ключ и порт SSH для безопасной передачи
rsync -av /data/ backup:/backups/ #Use SSH config host alias / Использует псевдоним из ~/.ssh/config для короткой и читаемой команды
rsync -av ./dist/ prod-web:/var/www/ #Deploy build to web root / Копирует сборку в корень сайта на сервере из алиаса SSH-конфига
rsync -av logfile.txt private-server:/logs/ #Send single file via SSH alias / Передаёт одиночный файл на хост, доступный через ProxyJump из SSH-конфига
rsync -avz --delete user@host:/var/www/ /local/mirror/ #Make exact local mirror of site / Создаёт локальное зеркало сайта с удалением лишних файлов для актуальности
rsync -av --delete ~/projects/ /mnt/data/projects_backup/ #Local mirror with deletions / Локальное зеркалирование каталога с удалением отсутствующих в источнике файлов
rsync -avz --delete ./build/ user@host:/var/www/mysite/ #Deploy build as exact mirror / Деплой сборки как точное зеркало веб-каталога с удалением лишнего
rsync -avz user@host:/var/log/myapp/ ./server_logs/ #Pull app logs with compression / Забирает логи приложения с сервера с сжатием по сети
rsync -av *.csv /backup/ #Copy only CSVs using shell glob / Копирует только CSV-файлы, используя шаблон оболочки
rsync -av --exclude='b*' /src/ /dst/ #Exclude by simple pattern / Исключает файлы и папки, начинающиеся на «b», из синхронизации
rsync -av --exclude='data?.csv' /src/ /dst/ #Exclude with single-character wildcard / Исключает файлы с ровно одним символом вместо «?»
rsync -av --exclude-from='backup-exclude.txt' ~/important_data/ user@host:/backups/ #Exclude rules from file / Читает шаблоны исключений из файла для единых правил
rsync -av --include='src/' --include='src/**/*.py' --exclude='*' /source/project/ /backup/project/ #Include-only subtree and pattern / Включает только каталог src и Python-файлы внутри, остальное исключает
rsync -av --include='*/' --include='*.jpg' --include='*.png' --include='*.gif' --exclude='tmp/**' --exclude='*' /photos/ /backup/photos/ #Include images, skip tmp/ and others / Включает изображения, разрешает обход каталогов, исключает tmp и всё прочее
rsync -aH --link-dest=/prev/backup/ /src/ /new/backup/ #Snapshot using hardlinks / Создаёт снимок с жёсткими ссылками на неизменившиеся файлы для экономии места
rsync -a ~/work/ /backups/work.2025-09-17/ #Initial full backup copy / Первая полная копия каталога для цепочки снимков
rsync -aH --link-dest=/backups/work.2025-09-17/ ~/work/ /backups/work.2025-09-18/ #Next snapshot with link-dest / Инкрементальный снимок с дедупликацией через жёсткие ссылки
sudo rsync -a server:/var/www/html/ ./backup/ #Preserve owners as root / Сохраняет владельцев и группы при копировании; требует root на приёмнике
sudo rsync -a /source/ user@host:/dest/ #Push as root to set ownership / Отправляет данные с сохранением владельцев/групп; выполняется от root
rsync -a --usermap=www-data:webadmin --groupmap=www-data:webadmin server:/var/www/ ./backup/ #Remap owner/group during copy / Переназначает владельца и группу на лету по заданным правилам
rsync -a --usermap='*:backupuser' --groupmap='*:backupuser' /src/ /dst/ #Map all users and groups / Меняет владельцев и группы всех файлов на указанные учётные записи
rsync -a --numeric-ids server:/var/www/ ./backup/ #Preserve numeric UIDs and GIDs / Сохраняет числовые UID/GID без разрешения имён пользователей и групп
rsync -avh --dry-run /src/ /dst/ #Preview archive copy with human sizes / Предпросмотр архивной копии с человекочитаемыми размерами без фактической записи
rsync -avh --dry-run --itemize-changes /src/ /dst/ #Show detailed change list / Показывает детальный список изменений в сухом запуске для проверки
rsync -avh --dry-run --delete /src/ /dst/ #Danger: preview deletions / Внимание: показывает, какие файлы будут удалены при зеркалировании с --delete
rsync -avh --dry-run --exclude-from=/path/exclude.txt /src/ /dst/ #Preview with exclude file / Пробный прогон с правилами исключений из файла
rsync -avh --dry-run --link-dest=/snapshots/prev/ /src/ /snapshots/new/ #Preview snapshot hardlinks / Предпросмотр снимка с жёсткими ссылками без изменений на диске
rsync -a --info=progress2 /src/ /dst/ #Global progress for large trees / Глобальный прогресс копирования деревьев, удобен для больших наборов
rsync -aP /src/ /dst/ #Archive with progress and partial / Архивный режим с прогрессом и докачкой прерванных файлов
rsync -a --partial --partial-dir=.rsync-partials /src/ /dst/ #Keep partials in side dir / Хранит недокачанные куски в отдельной папке для безопасного возобновления
rsync -a --checksum /src/ /dst/ #Force checksum comparison / Сравнивает по контрольным суммам вместо времени/размера (медленнее, надёжнее)
rsync -a --size-only /src/ /dst/ #Compare by size only / Сравнивает только по размеру, игнорируя временные метки (осторожно)
rsync -a -e ssh /src/ user@host:/dst/ #Explicit SSH remote shell / Явно задаёт SSH как транспорт удалённого копирования
rsync -a -e 'ssh -p 2222 -o ControlMaster=auto -o ControlPersist=2m' /src/ user@host:/dst/ #ControlPersist speeds repeated runs / Ускоряет повторные подключения по SSH с удержанием мастер-сессии
rsync -a -e 'ssh -J bastion@bastion.host' /src/ user@host:/dst/ #ProxyJump via bastion / Использует прыжковый хост для доступа к приватному серверу
rsync -a --compress --compress-level=6 /src/ user@host:/dst/ #Enable compression with level / Включает сжатие и задаёт уровень для экономии трафика
rsync -a --bwlimit=50m /src/ /dst/ #Limit bandwidth to 50 MiB/s / Ограничивает пропускную способность до указанного значения
rsync -a --whole-file /src/ /dst/ #Skip delta algorithm (fast LAN) / Передаёт файлы целиком, полезно на быстрых локальных сетях
rsync -a --inplace /src/ /dst/ #Update files in place / Обновляет файлы на месте без временных копий; осторожно при сбоях
rsync -a --append-verify /src/ /dst/ #Append and verify resumed files / Докачка в конец с проверкой контрольной суммы, надёжно при обрывах
rsync -4 -a /src/ user@host:/dst/ #Force IPv4 / Принудительно использует IPv4 для соединения
rsync -6 -a /src/ user@host:/dst/ #Force IPv6 / Принудительно использует IPv6 для соединения
rsync -aHAX --numeric-ids /src/ /dst/ #Preserve hardlinks, ACLs, xattrs / Сохраняет жёсткие ссылки, ACL и расширенные атрибуты; часто требует root
rsync -aAX --devices --specials /src/ /dst/ #Preserve devices and specials / Копирует файлы устройств и спецфайлы; обычно нужен root-доступ
rsync -a --chown=www-data:www-data --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r /src/ /dst/ #Set owner and permissions / Устанавливает владельца и права для каталогов и файлов при копировании
rsync -a --include='*/' --include='*.conf' --exclude='*' /etc/ /backup/etc-min/ #Copy only .conf files / Копирует только конфигурационные файлы, сохраняя структуру каталогов
rsync -a --exclude='.git/' --exclude='node_modules/' --exclude-from=/path/ignore.rsync /src/ /dst/ #Combine multiple excludes / Сочетает явные исключения и список из файла
rsync -a --filter='dir-merge /.rsync-filter' /project/ /mirror/ #Use per-directory filter files / Учитывает правила фильтра из .rsync-filter в подкаталогах
rsync -a --delete /src/ /dst/ #Danger: exact mirror deletes extras / Опасно: делает приёмник точным зеркалом, удаляя лишние файлы
rsync -a --delete-after /src/ /dst/ #Danger: delete after transfer / Опасно: удаляет лишнее после передачи, снижая окна недоступности
rsync -a --delete-excluded --exclude-from=/path/exclude.txt /src/ /dst/ #Danger: delete excluded at dest / Опасно: удаляет на приёмнике даже исключённые по шаблонам файлы
rsync -a --max-delete=100 /src/ /dst/ #Limit deletions per run / Ограничивает число удалений за запуск для снижения риска
rsync -a --backup --backup-dir=/backup/.trash-$(date +%F) /src/ /dst/ #Keep deleted/changed copies / Сохраняет изменённые/удалённые файлы в отдельном каталоге версии
rsync -aH --link-dest=/snap/last/ /live/ /snap/new/ #Snapshot with hardlinks baseline / Создаёт новый снимок, ссылаясь на предыдущий как базовый
rsync -aH --link-dest=/snap/2025-09-28/ /live/ /snap/2025-09-29/ #Daily snapshot roll / Ежедневный снимок с дедупликацией неизменившихся файлов
rsync -a --compare-dest=/ref/ /src/ /dst/ #Skip files present in reference / Не копирует файлы, уже присутствующие в каталоге сравнения
rsync -a --copy-dest=/ref/ /src/ /dst/ #Copy and hardlink unchanged to ref / Копирует новые, а неизменённые ссылает на файлы из справочного каталога
rsync -aH --link-dest=/snap/prev/ --delete /src/ /snap/new/ #Danger: snapshot mirror with deletes / Опасно: снимок-зеркало с удалением того, чего нет в источнике
rsync -a --sparse /vm-images/ /backup/vm-images/ #Efficient sparse file handling / Эффективно копирует разрежённые файлы, экономя место на приёмнике
rsync -aL /src/ /dst/ #Copy symlink targets (follow links) / Копирует содержимое по ссылкам вместо самих символических ссылок
rsync -a --safe-links /src/ /dst/ #Ignore unsafe absolute symlinks / Игнорирует небезопасные абсолютные ссылки вне дерева назначения
rsync -a --copy-dirlinks /src/ /dst/ #Treat directory symlinks as dirs / Считает симлинки на каталоги реальными каталогами при копировании
rsync -a --times --atimes /src/ /dst/ #Preserve mtime and atime where supported / Сохраняет время изменения и доступа, если поддерживается ФС
rsync -a --out-format='%t %i %n%L' --log-file=/var/log/rsync.log /src/ /dst/ #Structured log for CI/CD / Структурированный лог с отметкой времени, изменениями и путями
rsync -a --itemize-changes --log-file=/var/log/rsync-%Y%m%d.log /src/ /dst/ #Itemized logging to file / Подробный отчёт об изменениях в файл журнала
rsync -a --rsync-path='sudo rsync' /src/ user@host:/etc/ #Run remote side via sudo / Запускает rsync на удалённой стороне с sudo для записи в системные пути
rsync -a --rsync-path=/opt/homebrew/bin/rsync /src/ user@mac-host:/dst/ #Use Homebrew rsync remotely / Использует альтернативный путь rsync на удалённом macOS (Homebrew)
RSYNC_RSH='ssh -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts' rsync -a /src/ user@host:/dst/ #Enforce host key checks / Жёстко проверяет ключи хоста, записывая известные хосты в указанный файл
rsync -a -e 'ssh -o IdentitiesOnly=yes -i ~/.ssh/backup_key' /src/ backup@host:/dst/ #Use specific SSH key only / Принудительно использует конкретный ключ SSH, исключая агент/прочие ключи
rsync -a --numeric-ids --chown=0:0 /src/ /mnt/restore/ #Restore with root ownership / Восстанавливает данные с установкой владельцев по числовым UID/GID на root
rsync -aAXH --info=stats2 /src/ /dst/ #Preserve ACL/xattrs/hardlinks with stats / Сохраняет ACL, xattrs и жёсткие ссылки; выводит расширенную статистику
/opt/homebrew/bin/rsync -a --protect-decmpfs --xattrs /src/ /dst/ #macOS: preserve xattrs/resource forks / macOS: сохраняет расширенные атрибуты и ресурсные вилки (rsync 3.x из Homebrew)
/usr/bin/rsync -a --extended-attributes --crtimes /src/ /dst/ #macOS BSD rsync attributes / macOS: сохраняет xattrs и время создания, если поддерживается
rsync -a --prune-empty-dirs --include='*/' --include='*.log' --exclude='*' /var/log/ /backup/logs/ #Prune empty dirs while selecting logs / Удаляет пустые каталоги, копируя только журналы
rsync -a --min-size=10K --max-size=2G /src/ /dst/ #Only copy files within size range / Копирует файлы только в указанном диапазоне размеров
rsync -a --ignore-existing /src/ /dst/ #Do not overwrite existing files / Не перезаписывает уже существующие файлы на приёмнике
rsync -a --update /src/ /dst/ #Skip newer files on receiver / Пропускает файлы, которые новее на стороне приёмника
rsync -a --fuzzy /src/ /dst/ #Fuzzy basis for changed files / Ищет похожие файлы как основу для дельта-копирования
rsync -a --timeout=60 /src/ user@host:/dst/ #Network I/O timeout / Прерывает операцию при простое сети дольше указанного времени
rsync -a --human-readable --stats /src/ /dst/ #Readable sizes and summary stats / Выводит понятные размеры и сводку по объёму, скорости, числу файлов
rsync -a --exclude='*.tmp' --exclude='*/cache/**' --exclude-from=/etc/rsync/excludes /src/ /dst/ #Layered exclude strategy / Слоистая стратегия исключений: шаблоны и файл со списком
rsync -a --progress --mkpath /src/sub/dir/ user@host:/dst/sub/dir/ #Create missing destination path / Создаёт отсутствующие каталоги на приёмнике перед копированием
rsync -a --files-from=/path/include-list.txt / /backup/ #Copy only listed files / Копирует только перечисленные пути из файла списков
rsync -a --acls --xattrs /src/ /dst/ #Explicitly preserve ACLs and xattrs / Явно сохраняет списки контроля доступа и расширенные атрибуты (часто нужен root)
rsync -a --ipv4 --bwlimit=10m --info=progress2 /src/ user@host:/dst/ #Stable IPv4 with progress and limit / Стабильная передача по IPv4 c ограничением и общим прогрессом
rsync -a --remove-source-files /src/ /dst/ #Move files while preserving metadata / Перемещает файлы, удаляя исходники после успешной передачи
rsync -a --checksum-choice=xxh128 --compress-choice=zstd /src/ /dst/ #Modern hash and compression (3.2+) / Современный хеш и сжатие; требуется rsync ≥3.2 на обеих сторонах
rsync -a --hard-links /src/ /dst/ #Preserve hardlinks only / Сохраняет жёсткие ссылки без включения ACL/xattrs
rsync -a --inplace --no-whole-file /src/ /dst/ #In-place delta on slow links / Обновляет дельтой в месте, избегая полного перезаписи на медленных каналах
rsync -a --copy-unsafe-links /src/ /dst/ #Copy targets of unsafe links / Копирует содержимое по небезопасным ссылкам вместо создания ссылок
rsync -a --delete --exclude='.snapshot/**' /src/ /dst/ #Danger: mirror but skip snapshots / Опасно: зеркалирует с удалением, но исключает каталоги снимков
rsync -a --partial-dir=/var/tmp/rsync-partials --contimeout=10 /src/ user@host:/dst/ #Robust resume and connect timeout / Надёжное возобновление с таймаутом установки соединения
rsync -a --rsync-path='/usr/bin/env RSYNC_PROXY=http://203.0.113.10:3128 rsync' /src/ user@host:/dst/ #Proxy for rsync-over-SSH / Использует прокси для исходящих соединений на удалённой стороне
rsync -a --out-format='%i|%f|%l|%b' /src/ /dst/ #Machine-parsable output / Машиночитаемый формат для разборки скриптами
rsync -a --chmod=F644,D755 /src/ /dst/ #Normalize permissions on copy / Нормализует права файлов и каталогов при переносе
rsync -a --owner --group --super /src/ /dst/ #Set owner/group as super-user / Устанавливает владельцев/группы; требует суперпользователя
rsync -a --iconv=UTF-8,UTF-8-MAC /src/ /dst/ #macOS normalize filenames / Нормализует составные имена файлов при копировании Linux↔macOS
rsync -a --sockopts=TCP_NODELAY /src/ user@host:/dst/ #Tweak TCP small-packet latency / Уменьшает задержки при передаче мелких файлов
rsync -a --ignore-missing-args @/list-of-paths.txt / /dst/ #Skip missing listed paths / Игнорирует отсутствующие пути из списка аргументов
rsync -a --retries=3 --timeout=120 /src/ user@host:/dst/ #Retry and network timeout / Повторяет попытки при сетевых сбоях с таймаутом
rsync -a --fsync /src/ /dst/ #Fsync after each file / Принудительно синхронизирует данные на диск после записи каждого файла
rsync -a --preallocate /src/ /dst/ #Preallocate space on receiver / Предварительно выделяет место под файл на стороне приёмника
rsync -a --stats --human-readable --delete-delay /src/ /dst/ #Danger: delayed deletes with stats / Опасно: задерживает удаление до конца, выводит сводку
rsync -a --daemon --config=/etc/rsyncd.conf #Start rsync daemon / Запускает демон rsync с указанным конфигом rsyncd.conf
rsync -a rsync://user@host:/module/path/ /dst/ #Pull from rsync daemon module / Забирает данные из модуля демона rsync
rsync -a /src/ rsync://user@host:/module/path/ #Push into rsync daemon module / Отправляет данные в модуль демона rsync
rsync -a --password-file=/etc/rsyncd.secrets rsync://user@host:/module/ /dst/ #Daemon auth via secrets file / Аутентификация к демону rsync через файл с паролем
rsync -a --address=0.0.0.0 /src/ /dst/ #Bind to specific local IP / Привязывает исходящее соединение к указанному локальному адресу
rsync -a --exclude-from=/etc/rsync/backup.exclude --include-from=/etc/rsync/backup.include /src/ /dst/ #Combine include and exclude files / Использует отдельные файлы правил включения и исключения
rsync -a --from0 --files-from=list0.txt / /dst/ #NUL-delimited file list / Читает список путей, разделённых NUL, для надёжной обработки пробелов
rsync -a --mkpath --chown=backup:backup /src/sub/ /backup/sub/ #Ensure path and set owner / Создаёт путь на приёмнике и задаёт владельца каталога
rsync -a --delete --dry-run /src/ /dst/ #Danger: preview destructive mirror / Опасно: предварительный просмотр разрушительного зеркалирования перед реальным запуском
rsync mega-cheatsheet — commands in "<команда> #desc in English / описание на русском" format  
rsync -av --delete /src/ user@host:/backup/projects/ #Mirror source to remote and delete extras / Зеркалирует источник на сервере, удаляя лишнее у приёмника (опасно при ошибочных путях)  
rsync -avn --delete /src/ user@host:/backup/projects/ #Dry run of mirror with deletions / Пробный запуск зеркалирования с удалениями; показывает, что будет удалено и скопировано  
rsync -av --progress --partial-dir=.partial-dir user@host:/big/file.iso ./ #Resume large file via partial-dir / Докачка большого файла в безопасную временную папку, затем перенос по завершении  
rsync -av --bwlimit=625 user@host:/data/ /backup/ #Throttle to ~5 Mbps / Ограничивает скорость передачи до ~5 Мбит/с, снижая нагрузку на сеть  
rsync -av --bwlimit=1024 user@host:/data/ /backup/ #Throttle to 1 MiB/s / Ограничивает скорость до 1 МБ/с для более предсказуемой загрузки канала  
rsync -avz -e 'ssh -p 2222' /data/ user@host:/backups/ #SSH on custom port with compression / Подключение по SSH на нестандартном порту с сжатием данных  
rsync -avz -e 'ssh -p 2222' user@host:/var/log/app/ ./logs/ #Pull logs over custom SSH port / Забирает логи с сервера по нестандартному порту SSH  
rsync -avz -e 'ssh -p 2222 -i ~/.ssh/id_ed25519' /data/ user@host:/backups/ #SSH custom port and key / Использует указанный ключ и порт SSH для безопасной передачи  
rsync -av /data/ backup:/backups/ #Use SSH config host alias / Использует псевдоним из ~/.ssh/config для короткой и читаемой команды  
rsync -av ./dist/ prod-web:/var/www/ #Deploy build to web root / Копирует сборку в корень сайта на сервере из алиаса SSH-конфига  
rsync -av logfile.txt private-server:/logs/ #Send single file via SSH alias / Передаёт одиночный файл на хост, доступный через ProxyJump из SSH-конфига  
rsync -avz --delete user@host:/var/www/ /local/mirror/ #Make exact local mirror of site / Создаёт локальное зеркало сайта с удалением лишних файлов для актуальности  
rsync -av --delete ~/projects/ /mnt/data/projects_backup/ #Local mirror with deletions / Локальное зеркалирование каталога с удалением отсутствующих в источнике файлов  
rsync -avz --delete ./build/ user@host:/var/www/mysite/ #Deploy build as exact mirror / Деплой сборки как точное зеркало веб-каталога с удалением лишнего  
rsync -avz user@host:/var/log/myapp/ ./server_logs/ #Pull app logs with compression / Забирает логи приложения с сервера с сжатием по сети  
rsync -av *.csv /backup/ #Copy only CSVs using shell glob / Копирует только CSV-файлы, используя шаблон оболочки  
rsync -av --exclude='b*' /src/ /dst/ #Exclude by simple pattern / Исключает файлы и папки, начинающиеся на «b», из синхронизации  
rsync -av --exclude='data?.csv' /src/ /dst/ #Exclude with single-character wildcard / Исключает файлы с ровно одним символом вместо «?»  
rsync -av --exclude-from='backup-exclude.txt' ~/important_data/ user@host:/backups/ #Exclude rules from file / Читает шаблоны исключений из файла для единых правил  
rsync -av --include='src/' --include='src/**/*.py' --exclude='*' /source/project/ /backup/project/ #Include-only subtree and pattern / Включает только каталог src и Python-файлы внутри, остальное исключает  
rsync -av --include='*/' --include='*.jpg' --include='*.png' --include='*.gif' --exclude='tmp/**' --exclude='*' /photos/ /backup/photos/ #Include images, skip tmp/ and others / Включает изображения, разрешает обход каталогов, исключает tmp и всё прочее  
rsync -aH --link-dest=/prev/backup/ /src/ /new/backup/ #Snapshot using hardlinks / Создаёт снимок с жёсткими ссылками на неизменившиеся файлы для экономии места  
rsync -a ~/work/ /backups/work.2025-09-17/ #Initial full backup copy / Первая полная копия каталога для цепочки снимков  
rsync -aH --link-dest=/backups/work.2025-09-17/ ~/work/ /backups/work.2025-09-18/ #Next snapshot with link-dest / Инкрементальный снимок с дедупликацией через жёсткие ссылки  
sudo rsync -a server:/var/www/html/ ./backup/ #Preserve owners as root / Сохраняет владельцев и группы при копировании; требует root на приёмнике  
sudo rsync -a /source/ user@host:/dest/ #Push as root to set ownership / Отправляет данные с сохранением владельцев/групп; выполняется от root  
rsync -a --usermap=www-data:webadmin --groupmap=www-data:webadmin server:/var/www/ ./backup/ #Remap owner/group during copy / Переназначает владельца и группу на лету по заданным правилам  
rsync -a --usermap='*:backupuser' --groupmap='*:backupuser' /src/ /dst/ #Map all users and groups / Меняет владельцев и группы всех файлов на указанные учётные записи  
rsync -a --numeric-ids server:/var/www/ ./backup/ #Preserve numeric UIDs and GIDs / Сохраняет числовые UID/GID без разрешения имён пользователей и групп  

rsync -avh --dry-run /src/ /dst/ #Preview archive copy with human sizes / Предпросмотр архивной копии с человекочитаемыми размерами без фактической записи  
rsync -avh --dry-run --itemize-changes /src/ /dst/ #Show detailed change list / Показывает детальный список изменений в сухом запуске для проверки  
rsync -avh --dry-run --delete /src/ /dst/ #Danger: preview deletions / Внимание: показывает, какие файлы будут удалены при зеркалировании с --delete  
rsync -avh --dry-run --exclude-from=/path/exclude.txt /src/ /dst/ #Preview with exclude file / Пробный прогон с правилами исключений из файла  
rsync -avh --dry-run --link-dest=/snapshots/prev/ /src/ /snapshots/new/ #Preview snapshot hardlinks / Предпросмотр снимка с жёсткими ссылками без изменений на диске  
rsync -a --info=progress2 /src/ /dst/ #Global progress for large trees / Глобальный прогресс копирования деревьев, удобен для больших наборов  
rsync -aP /src/ /dst/ #Archive with progress and partial / Архивный режим с прогрессом и докачкой прерванных файлов  
rsync -a --partial --partial-dir=.rsync-partials /src/ /dst/ #Keep partials in side dir / Хранит недокачанные куски в отдельной папке для безопасного возобновления  
rsync -a --checksum /src/ /dst/ #Force checksum comparison / Сравнивает по контрольным суммам вместо времени/размера (медленнее, надёжнее)  
rsync -a --size-only /src/ /dst/ #Compare by size only / Сравнивает только по размеру, игнорируя временные метки (осторожно)  
rsync -a -e ssh /src/ user@host:/dst/ #Explicit SSH remote shell / Явно задаёт SSH как транспорт удалённого копирования  
rsync -a -e 'ssh -p 2222 -o ControlMaster=auto -o ControlPersist=2m' /src/ user@host:/dst/ #ControlPersist speeds repeated runs / Ускоряет повторные подключения по SSH с удержанием мастер-сессии  
rsync -a -e 'ssh -J bastion@bastion.host' /src/ user@host:/dst/ #ProxyJump via bastion / Использует прыжковый хост для доступа к приватному серверу  
rsync -a --compress --compress-level=6 /src/ user@host:/dst/ #Enable compression with level / Включает сжатие и задаёт уровень для экономии трафика  
rsync -a --bwlimit=50m /src/ /dst/ #Limit bandwidth to 50 MiB/s / Ограничивает пропускную способность до указанного значения  
rsync -a --whole-file /src/ /dst/ #Skip delta algorithm (fast LAN) / Передаёт файлы целиком, полезно на быстрых локальных сетях  
rsync -a --inplace /src/ /dst/ #Update files in place / Обновляет файлы на месте без временных копий; осторожно при сбоях  
rsync -a --append-verify /src/ /dst/ #Append and verify resumed files / Докачка в конец с проверкой контрольной суммы, надёжно при обрывах  
rsync -4 -a /src/ user@host:/dst/ #Force IPv4 / Принудительно использует IPv4 для соединения  
rsync -6 -a /src/ user@host:/dst/ #Force IPv6 / Принудительно использует IPv6 для соединения  
rsync -aHAX --numeric-ids /src/ /dst/ #Preserve hardlinks, ACLs, xattrs / Сохраняет жёсткие ссылки, ACL и расширенные атрибуты; часто требует root  
rsync -aAX --devices --specials /src/ /dst/ #Preserve devices and specials / Копирует файлы устройств и спецфайлы; обычно нужен root-доступ  
rsync -a --chown=www-data:www-data --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r /src/ /dst/ #Set owner and permissions / Устанавливает владельца и права для каталогов и файлов при копировании  
rsync -a --include='*/' --include='*.conf' --exclude='*' /etc/ /backup/etc-min/ #Copy only .conf files / Копирует только конфигурационные файлы, сохраняя структуру каталогов  
rsync -a --exclude='.git/' --exclude='node_modules/' --exclude-from=/path/ignore.rsync /src/ /dst/ #Combine multiple excludes / Сочетает явные исключения и список из файла  
rsync -a --filter='dir-merge /.rsync-filter' /project/ /mirror/ #Use per-directory filter files / Учитывает правила фильтра из .rsync-filter в подкаталогах  
rsync -a --delete /src/ /dst/ #Danger: exact mirror deletes extras / Опасно: делает приёмник точным зеркалом, удаляя лишние файлы  
rsync -a --delete-after /src/ /dst/ #Danger: delete after transfer / Опасно: удаляет лишнее после передачи, снижая окна недоступности  
rsync -a --delete-excluded --exclude-from=/path/exclude.txt /src/ /dst/ #Danger: delete excluded at dest / Опасно: удаляет на приёмнике даже исключённые по шаблонам файлы  
rsync -a --max-delete=100 /src/ /dst/ #Limit deletions per run / Ограничивает число удалений за запуск для снижения риска  
rsync -a --backup --backup-dir=/backup/.trash-$(date +%F) /src/ /dst/ #Keep deleted/changed copies / Сохраняет изменённые/удалённые файлы в отдельном каталоге версии  
rsync -aH --link-dest=/snap/last/ /live/ /snap/new/ #Snapshot with hardlinks baseline / Создаёт новый снимок, ссылаясь на предыдущий как базовый  
rsync -aH --link-dest=/snap/2025-09-28/ /live/ /snap/2025-09-29/ #Daily snapshot roll / Ежедневный снимок с дедупликацией неизменившихся файлов  
rsync -a --compare-dest=/ref/ /src/ /dst/ #Skip files present in reference / Не копирует файлы, уже присутствующие в каталоге сравнения  
rsync -a --copy-dest=/ref/ /src/ /dst/ #Copy and hardlink unchanged to ref / Копирует новые, а неизменённые ссылает на файлы из справочного каталога  
rsync -aH --link-dest=/snap/prev/ --delete /src/ /snap/new/ #Danger: snapshot mirror with deletes / Опасно: снимок-зеркало с удалением того, чего нет в источнике  
rsync -a --sparse /vm-images/ /backup/vm-images/ #Efficient sparse file handling / Эффективно копирует разрежённые файлы, экономя место на приёмнике  
rsync -aL /src/ /dst/ #Copy symlink targets (follow links) / Копирует содержимое по ссылкам вместо самих символических ссылок  
rsync -a --safe-links /src/ /dst/ #Ignore unsafe absolute symlinks / Игнорирует небезопасные абсолютные ссылки вне дерева назначения  
rsync -a --copy-dirlinks /src/ /dst/ #Treat directory symlinks as dirs / Считает симлинки на каталоги реальными каталогами при копировании  
rsync -a --times --atimes /src/ /dst/ #Preserve mtime and atime where supported / Сохраняет время изменения и доступа, если поддерживается ФС  
rsync -a --out-format='%t %i %n%L' --log-file=/var/log/rsync.log /src/ /dst/ #Structured log for CI/CD / Структурированный лог с отметкой времени, изменениями и путями  
rsync -a --itemize-changes --log-file=/var/log/rsync-%Y%m%d.log /src/ /dst/ #Itemized logging to file / Подробный отчёт об изменениях в файл журнала  
rsync -a --rsync-path='sudo rsync' /src/ user@host:/etc/ #Run remote side via sudo / Запускает rsync на удалённой стороне с sudo для записи в системные пути  
rsync -a --rsync-path=/opt/homebrew/bin/rsync /src/ user@mac-host:/dst/ #Use Homebrew rsync remotely / Использует альтернативный путь rsync на удалённом macOS (Homebrew)  
RSYNC_RSH='ssh -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts' rsync -a /src/ user@host:/dst/ #Enforce host key checks / Жёстко проверяет ключи хоста, записывая известные хосты в указанный файл  
rsync -a -e 'ssh -o IdentitiesOnly=yes -i ~/.ssh/backup_key' /src/ backup@host:/dst/ #Use specific SSH key only / Принудительно использует конкретный ключ SSH, исключая агент/прочие ключи  
rsync -a --numeric-ids --chown=0:0 /src/ /mnt/restore/ #Restore with root ownership / Восстанавливает данные с установкой владельцев по числовым UID/GID на root  
rsync -aAXH --info=stats2 /src/ /dst/ #Preserve ACL/xattrs/hardlinks with stats / Сохраняет ACL, xattrs и жёсткие ссылки; выводит расширенную статистику  
/opt/homebrew/bin/rsync -a --protect-decmpfs --xattrs /src/ /dst/ #macOS: preserve xattrs/resource forks / macOS: сохраняет расширенные атрибуты и ресурсные вилки (rsync 3.x из Homebrew)  
/usr/bin/rsync -a --extended-attributes --crtimes /src/ /dst/ #macOS BSD rsync attributes / macOS: сохраняет xattrs и время создания, если поддерживается  
rsync -a --prune-empty-dirs --include='*/' --include='*.log' --exclude='*' /var/log/ /backup/logs/ #Prune empty dirs while selecting logs / Удаляет пустые каталоги, копируя только журналы  
rsync -a --min-size=10K --max-size=2G /src/ /dst/ #Only copy files within size range / Копирует файлы только в указанном диапазоне размеров  
rsync -a --ignore-existing /src/ /dst/ #Do not overwrite existing files / Не перезаписывает уже существующие файлы на приёмнике  
rsync -a --update /src/ /dst/ #Skip newer files on receiver / Пропускает файлы, которые новее на стороне приёмника  
rsync -a --fuzzy /src/ /dst/ #Fuzzy basis for changed files / Ищет похожие файлы как основу для дельта-копирования  
rsync -a --timeout=60 /src/ user@host:/dst/ #Network I/O timeout / Прерывает операцию при простое сети дольше указанного времени  
rsync -a --human-readable --stats /src/ /dst/ #Readable sizes and summary stats / Выводит понятные размеры и сводку по объёму, скорости, числу файлов  
rsync -a --exclude='*.tmp' --exclude='*/cache/**' --exclude-from=/etc/rsync/excludes /src/ /dst/ #Layered exclude strategy / Слоистая стратегия исключений: шаблоны и файл со списком  
rsync -a --progress --mkpath /src/sub/dir/ user@host:/dst/sub/dir/ #Create missing destination path / Создаёт отсутствующие

