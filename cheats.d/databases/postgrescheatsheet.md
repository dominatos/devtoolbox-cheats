Title: 🗃️ PostgreSQL — psql/pg_dump
Group: Databases
Icon: 🗃️
Order: 1

psql -h host -U user -d db -c '\dt'             # List tables in DB / Список таблиц в базе
pg_dump -h host -U user -d db | gzip > dump.sql.gz  # Dump DB to gzip / Дамп базы в gzip
psql -h host -U user -d db < dump.sql           # Restore dump / Восстановить дамп

