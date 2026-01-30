Title: 🍃 MongoDB — Cheatsheet
Group: Databases
Icon: 🍃
Order: 5

# Connect / Подключение
mongosh "mongodb://user:pass@localhost:27017/admin"                                # Open mongosh / Войти в mongosh

# Basics in mongosh / База в mongosh
show dbs                                                                            # List DBs / Список баз
use mydb                                                                            # Switch DB / Перейти на базу
show collections                                                                    # List collections / Список коллекций
db.items.insertOne({name:"item1", qty:10})                                          # Insert one / Вставить документ
db.items.findOne({name:"item1"})                                                    # Find one / Найти один
db.items.find({qty:{$gt:5}}).limit(5)                                               # Filter+limit / Фильтр + лимит
db.items.updateOne({name:"item1"}, {$set:{qty:15}})                                 # Update fields / Обновить поля
db.items.createIndex({name:1}, {unique:true})                                       # Create index / Индекс по полю
db.stats()                                                                          # DB stats / Статистика базы
db.items.stats()                                                                     # Coll stats / Статистика коллекции

# Export/Import / Экспорт/импорт
mongoexport --uri="mongodb://user:pass@localhost/mydb" \
  --collection=items --out=items.json                                               # Export JSON / Экспорт в JSON
mongoimport --uri="mongodb://user:pass@localhost/mydb" \
  --collection=items --file=items.json --jsonArray                                  # Import JSON array / Импорт массива

# Dump/restore / Дамп/восстановление
mongodump   --uri="mongodb://user:pass@localhost/" -o dump/                         # Dump all DBs / Дамп всех баз
mongorestore --uri="mongodb://user:pass@localhost/" dump/                           # Restore from dump / Восстановление

# Service admin / Администрирование сервиса
sudo systemctl status mongod                                                        # Service status / Статус сервиса
sudo journalctl -u mongod -f                                                        # Follow logs / Логи (follow)

# Security tips / Подсказки по безопасности
# 1) use admin; db.createUser({user:"u",pwd:"p",roles:[{role:"root",db:"admin"}]})  # Create user / Создать пользователя
# 2) enable authorization in mongod.conf; restart                                    # Включить authorization; перезапустить

#test user
use admin
db.getUser("admin")        
db.updateUser("admin", { pwd: "3dinformatica" })


