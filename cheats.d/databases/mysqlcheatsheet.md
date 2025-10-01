Title: 🗃️ MySQL/MariaDB
Group: Databases
Icon: 🗃️
Order: 2

mysql -h host -u user -p -e 'SHOW DATABASES;'   # Show databases / Показать базы
mysqldump -h host -u user -p db | gzip > dump.sql.gz  # Dump DB to gzip / Дамп базы в gzip
mysql -h host -u user -p db < dump.sql          # Restore dump / Восстановить дамп

