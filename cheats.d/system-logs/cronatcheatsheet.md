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

