Title: 🍃 MongoDB — Cheatsheet
Group: Databases
Icon: 🍃
Order: 5

# Connect / Подключение
mongosh "mongodb://<USER>:<PASSWORD>@localhost:27017/admin"                                # Connect with Auth / Подключение с авторизацией
mongosh "mongodb://<USER>:<PASSWORD>@<NODE_1>:27017,<NODE_2>:27017/<DB>?replicaSet=<RS>"  # Connect to Replica Set / Подключение к реплике

# Basics / Основы
show dbs                                                                            # List DBs / Список баз
use <DB_NAME>                                                                       # Switch DB / Перейти на базу
show collections                                                                    # List collections / Список коллекций
db.stats()                                                                          # DB stats / Статистика базы
db.<COLLECTION>.stats()                                                             # Collection stats / Статистика коллекции

# CRUD Operations / Операции CRUD
db.items.insertOne({name:"item1", qty:10})                                          # Insert document / Вставить документ
db.items.find({qty:{$gt:5}}).limit(5)                                               # Find with filter / Поиск с фильтром
db.items.updateOne({name:"item1"}, {$set:{qty:15}})                                 # Update document / Обновить документ
db.items.deleteOne({name:"item1"})                                                  # Delete document / Удалить документ
db.items.createIndex({name:1}, {unique:true})                                       # Create Index / Создать индекс

# Data Management / Управление данными
mongoexport --uri="mongodb://<USER>:<PASSWORD>@localhost/mydb" \
  --collection=items --out=items.json                                               # Export to JSON / Экспорт в JSON
mongoimport --uri="mongodb://<USER>:<PASSWORD>@localhost/mydb" \
  --collection=items --file=items.json --jsonArray                                  # Import from JSON / Импорт из JSON

mongodump --uri="mongodb://<USER>:<PASSWORD>@localhost/" -o dump/                   # Dump all databases / Дамп всех баз
mongorestore --uri="mongodb://<USER>:<PASSWORD>@localhost/" dump/                   # Restore from dump / Восстановление из дампа

# Administration / Администрирование
sudo systemctl status mongod                                                        # Service status / Статус сервиса
sudo journalctl -u mongod -f                                                        # Follow logs / Логи в реальном времени

// Create Admin User / Создать администратора
use admin;
db.createUser({
  user: "<USER>",
  pwd: "<PASSWORD>",
  roles: [{ role: "root", db: "admin" }]
});

// Change Password / Сменить пароль
db.updateUser("<USER>", { pwd: "<NEW_PASSWORD>" });

// Replica Set Initiation / Инициализация Replica Set
rs.initiate({
   _id : "rs0",
   members: [
      { _id: 0, host: "<NODE_1>:27017" },
      { _id: 1, host: "<NODE_2>:27017" },
      { _id: 2, host: "<NODE_3>:27017" }
   ]
});

// Replica Set Management / Управление Репликами
rs.status()                                                                         # Replica set status / Статус реплики
rs.conf()                                                                           # Replica set config / Конфигурация реплики
rs.isMaster()                                                                       # Check master status / Проверка мастера
rs.stepDown()                                                                       # Step down as primary / Уступить роль Primary
rs.syncFrom("<HOST>:<PORT>")                                                        # Force sync source / Принудительная синхронизация с узла
rs.add("<HOST>:<PORT>")                                                             # Add member / Добавить узел
rs.remove("<HOST>:<PORT>")                                                          # Remove member / Удалить узел

// Oplog & Replication Info / Oplog и Инфо о репликации
db.getReplicationInfo()                                                             # Oplog size & time window / Размер и время Oplog
db.printReplicationInfo()                                                           # Formatted replication info / Инфо о репликации (формат)
db.printSlaveReplicationInfo()                                                      # Replication lag info / Инфо о лаге репликации
use local; db.oplog.rs.stats();                                                     # Oplog collection stats / Статистика коллекции Oplog

# Profiling & Performance / Профилирование и Производительность
db.getProfilingStatus()                                                             # Get current status / Текущий статус
db.setProfilingLevel(1, { slowms: 100 })                                            # Profile slow ops > 100ms / Логировать медленные > 100мс
db.setProfilingLevel(2)                                                             # Profile ALL operations / Логировать ВСЕ операции
db.setProfilingLevel(0)                                                             # Disable profiling / Отключить профилирование
db.system.profile.find({ millis: { $gt: 500 } }).sort({ ts: -1 })                   # Find slow queries > 500ms / Найти запросы > 500мс
db.system.profile.find({ ns: "mydb.users" }).limit(5).sort({ ts: -1 })             # Queries for collection / Запросы к коллекции
[un manual](https://hevodata.com/learn/mongodb-profiler/)

# Audit Log Configuration (mongod.conf) / Настройка Аудита
/*
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/audit.json
  filter: '{ atype: { $in: [
      "authenticate", "createUser", "dropUser", "dropDatabase",
      "grantRolesToUser", "revokeRolesFromUser"
  ]}}'
setParameter:
  auditAuthorizationSuccess: true
*/

# Sysadmin Toolkit / Инструменты Сисадмина

// 🩺 Diagnostics & Operations / Диагностика и Операции
db.currentOp()                                                                      # List active operations / Список активных операций
db.currentOp({ "secs_running": { $gt: 5 } })                                        # Ops running > 5s / Операции длительностью > 5с
db.killOp(<opid>)                                                                   # Kill operation / Убить операцию (по opid)
db.serverStatus().connections                                                       # Connection stats / Статистика соединений
db.runCommand({ serverStatus: 1 }).asserts                                          # Assertions info / Инфо об ошибках (asserts)

// 📉 External Monitoring Tools / Внешний Мониторинг
// Run in terminal / Запускать в терминале:
// mongostat --uri="mongodb://<USER>:<PASS>@localhost" --rowcount=20 1              # Live stats (1s interval) / Живая статистика
// mongotop --uri="mongodb://<USER>:<PASS>@localhost" 1                             # Collection I/O stats / Статистика I/O коллекций

// 🧹 Maintenance / Обслуживание
db.adminCommand({ logRotate: 1 })                                                   # Rotate logs / Ротация логов
db.runCommand({ compact: "<COLLECTION>" })                                          # Compact collection / Сжатие коллекции (block!)
// db.repairDatabase()                                                              # Repair DB (Blocking!) / Восстановление БД (Блок!)


# Advanced Cheatsheet - Queries / Продвинутая шпаргалка - Запросы

// 📄 Search / Поиск
db.users.find({ age: { $gt: 25 } })                                                 # Age > 25 / Возраст > 25
db.users.find({ languages: "english" })                                             # Array contains "english" / Массив содержит "english"
db.users.find({ age: { $gte: 18, $lte: 25 } })                                      # 18 <= Age <= 25 / Возраст от 18 до 25
db.users.find({ city: "Rome" })                                                     # City is queries / Город = Rome
db.users.find({ age: 25 }).sort({ name: 1 })                                        # Sort by name ASC / Сортировка по имени (возр.)
db.users.find().sort({ created_at: -1 }).limit(3)                                   # Sort DSC + Limit / Сортировка (убыв.) + Лимит
db.users.find({ phone: { $eq: null } })                                             # Field is null / Поле null
db.users.find({ age: { $ne: 30 } })                                                 # Age != 30 / Возраст не 30
db.users.find({ $or: [{ languages: "english" }, { languages: "french" }] })         # OR condition / ИЛИ
db.users.find({ email: { $exists: true } })                                         # Field exists / Поле существует

// Array & Embedded / Массивы и Вложенность
db.users.find({ "skills.level": { $in: ["base", "advanced"] } })                    # Nested field Match / Поиск по вложенному полю
db.users.find({ tags: { $all: ["admin", "active"] } })                              # Array constraints all / Массив содержит все значения
db.users.find({ $expr: { $eq: [ { $size: "$languages" }, 2 ] } })                   # Array size = 2 / Размер массива = 2

// ➕ Insert / Вставка
db.users.insertOne({ name: "Anna", age: 22 })
db.users.insertMany([{ name: "Luca", age: 30 }, { name: "Tom", age: 25 }])

// 🔁 Update / Обновление
db.users.updateOne({ name: "Tom" }, { $set: { age: 30 } })                          # Set field / Установить поле
db.users.updateOne({ name: "Tom" }, { $inc: { age: 1 } })                           # Increment / Увеличить значение
db.users.updateOne({ name: "Tom" }, { $push: { languages: "spanish" } })            # Add to array / Добавить в массив
db.users.updateMany({ "skills.level": "advanced" }, { $inc: { salary: 100 } })      # Update multiple / Обновить множественные

// ❌ Delete / Удаление
db.users.deleteMany({ email: { $exists: false } })                                  # Delete if missing email / Удалить если нет email

# Real-world Scenarios (Sanitized) / Примеры из практики

// ElasticDump Migration / Миграция ElasticDump
// Export Data / Экспорт данных
NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump \
    --input=http://<SOURCE_IP>:9200/<INDEX> \
    --output=<INDEX>.json --type=data

// Export Settings / Экспорт настроек
NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump \
    --input=http://<SOURCE_IP>:9200/<INDEX> \
    --output=<INDEX>-settings.json --type=settings

// Import Data / Импорт данных
NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump \
    --output=http://<DEST_IP>:9200/<INDEX> \
    --input=<INDEX>.json --type=data

// Mongodump Specific / Специфичный дамп
mongodump --uri="mongodb://<ADMIN>:<PASS>@<NODE_1>:27017,<NODE_2>:27017/?replicaSet=<RS>" \
    --db=<DB_NAME> --collection=<COLL> --out=dump/

db.createView(
  "fasc_chiusi_view",     // The name of your "soft link"
  "fasc",                 // The source collection
  [ 
    { $match: { "customFields_Frontespizio_o_DataChiusura_ld": { $exists: true } } },
    { $project: { _id: 1, customFields_Frontespizio_o_DataChiusura_ld: 1 } }
  ]
)

db.createView(
  "vw_fasc_orienta",
  "fasc",
  [
    {
      $project: {
        _id: 1,
        statoFascicolo: 1,

        tipologia_cod: { $ifNull: ["$tipologia_cod", "$tipologia.cod"] },

        tipoFascicolo: {
          $ifNull: [
            "$tipologia.descrizione",
            { $ifNull: ["$tipologia_descrizione", "$tipologia.cod"] }
          ]
        },

        dataChiusura: 1,
        dataInizioAssegnazione: 1,
        numeroFascicolo: 1,


        customFields_Frontespizio_o_DataChiusuraArchiviazioneFascicolo_ld:
          "$customFields.Frontespizio_o.DataChiusura_ld",

        customFields_nomegruppo0_o_DataChiusuraArchiviazioneFascicolo_ld:
          "$customFields.nomegruppo0_o.DataChiusuraArchiviazioneFascicolo_ld",

        customFields_nomegruppo0_o_datadepositoricorso_ld:
          "$customFields.nomegruppo0_o.datadepositoricorso_ld",

        customFields_Frontespizio_o_DataDepositoRicorso_ld:
          "$customFields.Frontespizio_o.DataDepositoRicorso_ld",

        customFields_nomegruppo0_o_DataDepositoRicorso_ld_1:
          "$customFields.nomegruppo0_o.DataDepositoRicorso_ld_1",

        dataChiusura_ld: {
          $ifNull: [
            "$customFields.Frontespizio_o.DataChiusura_ld",
            "$dataChiusura"
          ]
        }
      }
    }
  ]
)




# Practice Exercises / Задания для практики

// ## 📋 FIND (Filtering) / Фильтрация

// ### Level 1: Basics / Уровень 1: Базовые
// 1. Find users from Milan / Найди всех пользователей из города Milan
// db.users.find({city: "Milan"})

// 2. Find users older than 30 / Найди всех пользователей старше 30 лет
// db.users.find({ age: { $gt: 30 } })

// 3. Find users with salary > 1400 / Найди пользователей с зарплатой больше 1400
// db.users.find({ salary: { $gte: 1400 } })

// 4. Find users with bonus < 200 / Найди пользователей с бонусом меньше 200
// db.users.find({ bonus: { $lt: 200 } })

// 5. Find users named "Marco" / Найди пользователей с именем "Marco"
// db.users.find({ name: "Marco" })

// ### Level 2: Comparison Operators / Уровень 2: Операторы сравнения
// 6. Salary 1000-1300 / Зарплата от 1000 до 1300
// db.users.find({ salary: { $gte: 1000, $lte: 1300 } })

// 7. Users younger than 25 / Пользователи моложе 25 лет
// db.users.find({ age: { $lt: 25 } })

// 8. Bonus not equal to 200 / Пользователи с бонусом НЕ равным 200
// db.users.find({ bonus: { $ne: 200 } })

// 9. Users older than 32 / Пользователи старше 32 лет
// db.users.find({ age: { $gt: 32 } })

// 10. Salary not greater than 1200 / Зарплата не больше 1200
// db.users.find({ salary: { $lte: 1200 } })

// ### Level 3: Logical Operators / Уровень 3: Логические операторы
// 11. Rome OR Naples / Из Rome ИЛИ Naples
// db.users.find({ city: { $in: ["Rome", "Naples"] } })

// 12. >30 AND salary > 1300 / Старше 30 И зарплата больше 1300
// db.users.find({ $and: [{ salary: { $gt: 1300 } }, { age: { $gt: 30 } }] })

// 13. (Milan OR Turin) AND <30 / (Milan ИЛИ Turin) И моложе 30
// db.users.find({ age: { $lt: 30 }, $or: [{ city: "Milan" }, { city: "Turin" }] })

// 14. NOT Rome AND NOT Milan / НЕ из Rome И НЕ из Milan
// db.users.find({ $and: [{ city: { $ne: "Milan" } }, { city: { $ne: "Rome" } }] })

// 15. Salary 1200-1500 AND Age 25-30 / Зарплата 1200-1500 И возраст 25-30
// db.users.find({ salary: { $gte: 1200, $lte: 1500 }, age: { $gte: 25, $lte: 30 } })

// ### Level 4: Arrays / Уровень 4: Работа с массивами
// 16. Know English / Знают английский
// db.users.find({ languages: { $in: ["english"] } })

// 17. Know English AND French / Знают English И French
// db.users.find({ languages: { $all: ["french", "english"] } })

// 18. Know exactly 2 languages / Знают ровно 2 языка
// db.users.find({ $expr: { $eq: [{ $size: "$languages" }, 2] } })

// 19. Have friend "Luca" / Имеют друга "Luca"
// db.users.find({ "friends.name": "Luca" })

// 20. More than 2 friends / Больше 2 друзей
// db.users.find({ $expr: { $gt: [{ $size: "$friends" }, 2] } })

// ### Level 5: Nested Objects / Уровень 5: Вложенные объекты
// 21. Zip code "00100" / Почтовый индекс "00100"
// db.users.find({ "address.zip": "00100" })

// 22. Skill "Zustand" / Навык "Zustand"
// db.users.find({ "skills.name": "Zustand" })

// 23. Skill level "expert" / Уровень навыка "expert"
// db.users.find({ "skills.level": "expert" })

// 24. React AND Intermediate / Навык React И уровень intermediate
// db.users.find({ "skills.name": "React", "skills.level": "intermediate" })

// 25. Any "beginner" skill / Любой навык уровня "beginner"
// db.users.find({ "skills.level": "beginner" })

// ### Level 6: Regex / Уровень 6: Регулярные выражения
// 26. Name starts with "M" / Имя начинается с "M"
// db.users.find({ name: { $regex: "^M" } })

// ## 🔄 UPDATE / Обновление

// 31. Increase Marco's salary by 200 / Увеличь зарплату Marco на 200
// db.users.updateOne({ name: "Marco" }, { $inc: { salary: 200 } })

// 32. Set Anna's city to Florence / Измени город Anna на Florence
// db.users.updateOne({ name: "Anna" }, { $set: { city: "Florence" } })

// 36. Increase salary for Rome users by 100 / Увеличь зарплату всем из Rome на 100
// db.users.updateMany({ city: "Rome" }, { $inc: { salary: 100 } })

// 37. Bonus 250 for >33 years old / Бонус 250 для всех старше 33
// db.users.updateMany({ age: { $gt: 33 } }, { $set: { bonus: 250 } })

// 38. Increase age by 1 for all / Увеличь возраст всех на 1
// db.users.updateMany({}, { $inc: { age: 1 } })

// 40. Set city "Remote" for salary > 1500 / Город "Remote" для зп > 1500
// db.users.updateMany({ salary: { $gt: 1500 } }, { $set: { city: "Remote" } })

// 41. Add "portuguese" to Marco / Добавь язык "portuguese" для Marco
// db.users.updateOne({ name: "Marco" }, { $push: { languages: "portuguese" } })

// 42. Remove "spanish" from all / Удали "spanish" у всех
// db.users.updateMany({}, { $pull: { languages: "spanish" } })

// 43. Add friend to Anna / Добавь друга для Anna
// db.users.updateOne({ name: "Anna" }, { $push: { friends: { name: "Cristian" } } })

// ## 🗑️ DELETE / Удаление

// 51. Delete Marco / Удали пользователя Marco
// db.users.deleteOne({ name: "Marco" })

// 52. Delete all from Naples / Удали всех из Naples
// db.users.deleteMany({ city: "Naples" })

// 53. Delete younger than 26 / Удали моложе 26
// db.users.deleteMany({ age: { $lt: 26 } })

// 60. Delete users with no friends / Удали пользователей без друзей
// db.users.deleteMany({ friends: { $size: 0 } })

// ## 📊 AGGREGATION / Агрегация

// 61. Average salary / Средняя зарплата
// db.users.aggregate([{ $group: { _id: null, avgSalary: { $avg: "$salary" } } }])

// 63. Count by city / Количество по городам
// db.users.aggregate([{ $group: { _id: "$city", count: { $sum: 1 } } }])

// 66. Avg salary by city / Средняя зп по городам
// db.users.aggregate([{ $group: { _id: "$city", avgSalary: { $avg: "$salary" } } }])

// 67. Top 5 cities / Топ-5 городов
// db.users.aggregate([
//   { $group: { _id: "$city", count: { $sum: 1 } } },
//   { $sort: { count: -1 } },
//   { $limit: 5 }
// ])

// Sample Data / Пример данных
// const sampleData = [
//   { name: "Anna", age: 28, city: "Rome", salary: 1200, bonus: 200, address: { zip: "00100" }, languages: ["italian", "english"], skills: { name: "Zustand", level: "advanced" } },
//   { name: "Daniela", age: 29, city: "Vibo Valentia", salary: 1200, bonus: 210, address: { zip: "89900" }, languages: ["italian", "english"], skills: { name: "Recoil", level: "intermediate" } },
//   { name: "Gianni", age: 31, city: "Catanzaro", salary: 1320, bonus: 260, address: { zip: "88100" }, languages: ["italian", "english", "spanish"], skills: { name: "Jotai", level: "beginner" } },
//   { name: "Simona", age: 26, city: "Pescara", salary: 1100, bonus: 180, address: { zip: "65100" }, languages: ["italian", "english"], skills: { name: "Valtio", level: "beginner" } },
//   { name: "Alfredo", age: 32, city: "Chieti", salary: 1380, bonus: 270, address: { zip: "66100" }, languages: ["italian", "english", "french"], skills: { name: "Apollo Client", level: "advanced" } },
//   // ... (Add more if needed / Добавьте больше при необходимости)
// ];
// db.users.insertMany(sampleData);

# Configuration Snippets / Примеры Конфигурации

// mongod.conf
/*
storage:
  dbPath: /var/lib/mongo
systemLog:
  destination: file
  path: /var/log/mongo/mongod.log
net:
  port: 27017
  bindIp: 0.0.0.0
security:
  authorization: "enabled"
  keyFile: /etc/mongod.key
replication:
  replSetName: "<REPLICA_SET_NAME>"
*/

# insertusers.js for testing:

const sampleData = [
  {
    name: "Anna",
    age: 28,
    city: "Rome",
    salary: 1200,
    bonus: 200,
    address: { zip: "00100" },
    languages: ["italian", "english"],
    friends: [ { name: "Rocco" }, { name: "Angela" }, { name: "Domenico" } ],
    skills: { name: "Zustand", level: "advanced" }
  },
  {
    name: "Daniela",
    age: 29,
    city: "Vibo Valentia",
    salary: 1200,
    bonus: 210,
    address: { zip: "89900" },
    languages: ["italian", "english"],
    friends: [ { name: "Bruno" }, { name: "Concetta" }, { name: "Fortunato" } ],
    skills: { name: "Recoil", level: "intermediate" }
  },
  {
    name: "Gianni",
    age: 31,
    city: "Catanzaro",
    salary: 1320,
    bonus: 260,
    address: { zip: "88100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Salvatore" }, { name: "Teresa" } ],
    skills: { name: "Jotai", level: "beginner" }
  },
  {
    name: "Simona",
    age: 26,
    city: "Pescara",
    salary: 1100,
    bonus: 180,
    address: { zip: "65100" },
    languages: ["italian", "english"],
    friends: [ { name: "Marco" }, { name: "Cristina" }, { name: "Fabio" } ],
    skills: { name: "Valtio", level: "beginner" }
  },
  {
    name: "Alfredo",
    age: 32,
    city: "Chieti",
    salary: 1380,
    bonus: 270,
    address: { zip: "66100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Daniele" }, { name: "Luisa" } ],
    skills: { name: "Apollo Client", level: "advanced" }
  },
  {
    name: "Luisa",
    age: 28,
    city: "Teramo",
    salary: 1150,
    bonus: 190,
    address: { zip: "64100" },
    languages: ["italian", "english"],
    friends: [ { name: "Mario" }, { name: "Beatrice" }, { name: "Pierluigi" } ],
    skills: { name: "Relay", level: "intermediate" }
  },
  {
    name: "Mario",
    age: 30,
    city: "L'Aquila",
    salary: 1250,
    bonus: 230,
    address: { zip: "67100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Massimo" }, { name: "Daniela" } ],
    skills: { name: "Urql", level: "beginner" }
  },
  {
    name: "Pierluigi",
    age: 33,
    city: "Ascoli Piceno",
    salary: 1400,
    bonus: 280,
    address: { zip: "63100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Raffaella" }, { name: "Beatrice" }, { name: "Luisa" } ],
    skills: { name: "SWR", level: "advanced" }
  },
  {
    name: "Raffaella",
    age: 27,
    city: "Macerata",
    salary: 1120,
    bonus: 180,
    address: { zip: "62100" },
    languages: ["italian", "english"],
    friends: [ { name: "Umberto" }, { name: "Lorella" } ],
    skills: { name: "React Query", level: "intermediate" }
  },
  {
    name: "Umberto",
    age: 35,
    city: "Fermo",
    salary: 1500,
    bonus: 320,
    address: { zip: "63900" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Giacomo" }, { name: "Ilaria" }, { name: "Piero" } ],
    skills: { name: "Axios", level: "expert" }
  },
  {
    name: "Lorella",
    age: 29,
    city: "Perugia",
    salary: 1280,
    bonus: 240,
    address: { zip: "06100" },
    languages: ["italian", "english"],
    friends: [ { name: "Piero" }, { name: "Raffaella" } ],
    skills: { name: "Fetch API", level: "advanced" }
  },
  {
    name: "Piero",
    age: 31,
    city: "Terni",
    salary: 1350,
    bonus: 260,
    address: { zip: "05100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Giacomo" }, { name: "Monica" }, { name: "Claudio" } ],
    skills: { name: "Superagent", level: "intermediate" }
  },
  {
    name: "Monica",
    age: 26,
    city: "Spoleto",
    salary: 1080,
    bonus: 160,
    address: { zip: "06049" },
    languages: ["italian", "english"],
    friends: [ { name: "Ilaria" }, { name: "Piero" } ],
    skills: { name: "Request", level: "beginner" }
  },
  {
    name: "Mauro",
    age: 32,
    city: "Orvieto",
    salary: 1300,
    bonus: 250,
    address: { zip: "05018" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Emanuele" }, { name: "Gabriella" }, { name: "Flavio" } ],
    skills: { name: "Got", level: "intermediate" }
  },
  {
    name: "Gabriella",
    age: 28,
    city: "Gubbio",
    salary: 1180,
    bonus: 200,
    address: { zip: "06024" },
    languages: ["italian", "english"],
    friends: [ { name: "Flavio" }, { name: "Mauro" } ],
    skills: { name: "Undici", level: "beginner" }
  },
  {
    name: "Flavio",
    age: 30,
    city: "Assisi",
    salary: 1220,
    bonus: 220,
    address: { zip: "06081" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Emanuele" }, { name: "Gabriella" }, { name: "Mauro" } ],
    skills: { name: "Isomorphic Fetch", level: "intermediate" }
  },
  {
    name: "Ciro",
    age: 27,
    city: "Cassino",
    salary: 1100,
    bonus: 170,
    address: { zip: "03043" },
    languages: ["italian", "english"],
    friends: [ { name: "Stefania" }, { name: "Alessandra" } ],
    skills: { name: "Cross Fetch", level: "beginner" }
  },
  {
    name: "Alessandra",
    age: 25,
    city: "Formia",
    salary: 1000,
    bonus: 140,
    address: { zip: "04023" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Ciro" }, { name: "Stefania" }, { name: "Enzo" } ],
    skills: { name: "Whatwg Fetch", level: "beginner" }
  },
  {
    name: "Silvio",
    age: 34,
    city: "Gaeta",
    salary: 1420,
    bonus: 290,
    address: { zip: "04024" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Alberto" }, { name: "Paola" } ],
    skills: { name: "Node Fetch", level: "advanced" }
  },
  {
    name: "Enzo",
    age: 29,
    city: "Terracina",
    salary: 1250,
    bonus: 230,
    address: { zip: "04019" },
    languages: ["italian", "english"],
    friends: [ { name: "Silvio" }, { name: "Alessandra" }, { name: "Alberto" } ],
    skills: { name: "Ky", level: "intermediate" }
  },
  {
    name: "Sandro",
    age: 31,
    city: "Civitavecchia",
    salary: 1380,
    bonus: 270,
    address: { zip: "00053" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Claudio" }, { name: "Ornella" } ],
    skills: { name: "Wretch", level: "advanced" }
  },
  {
    name: "Ornella",
    age: 28,
    city: "Tivoli",
    salary: 1200,
    bonus: 210,
    address: { zip: "00019" },
    languages: ["italian", "english"],
    friends: [ { name: "Sandro" }, { name: "Claudio" } ],
    skills: { name: "Redaxios", level: "intermediate" }
  },
  {
    name: "Gino",
    age: 33,
    city: "Venafro",
    salary: 1300,
    bonus: 250,
    address: { zip: "86079" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Carla" }, { name: "Filomena" }, { name: "Luigi" } ],
    skills: { name: "Apisauce", level: "advanced" }
  },
  {
    name: "Filomena",
    age: 26,
    city: "Termoli",
    salary: 1080,
    bonus: 160,
    address: { zip: "86039" },
    languages: ["italian", "english"],
    friends: [ { name: "Gino" }, { name: "Luigi" } ],
    skills: { name: "Frisbee", level: "beginner" }
  },
  {
    name: "Luigi",
    age: 30,
    city: "Larino",
    salary: 1220,
    bonus: 220,
    address: { zip: "86035" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Manuela" }, { name: "Gino" }, { name: "Filomena" } ],
    skills: { name: "Supertest", level: "intermediate" }
  },
  {
    name: "Gerardo",
    age: 32,
    city: "Ariano Irpino",
    salary: 1350,
    bonus: 260,
    address: { zip: "83031" },
    languages: ["italian", "english"],
    friends: [ { name: "Roberto" }, { name: "Nunzia" } ],
    skills: { name: "Nock", level: "advanced" }
  },
  {
    name: "Nunzia",
    age: 27,
    city: "Montella",
    salary: 1120,
    bonus: 180,
    address: { zip: "83048" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Raffaele" }, { name: "Gerardo" }, { name: "Roberto" } ],
    skills: { name: "MSW", level: "intermediate" }
  },
  {
    name: "Raffaele",
    age: 29,
    city: "Lioni",
    salary: 1200,
    bonus: 210,
    address: { zip: "83047" },
    languages: ["italian", "english"],
    friends: [ { name: "Nunzia" }, { name: "Gerardo" } ],
    skills: { name: "Mirage JS", level: "beginner" }
  },
  {
    name: "Rosaria",
    age: 31,
    city: "Telese Terme",
    salary: 1280,
    bonus: 240,
    address: { zip: "82037" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Massimo" }, { name: "Vincenzo" }, { name: "Anna" } ],
    skills: { name: "JSON Server", level: "intermediate" }
  },
  {
    name: "Gennaro",
    age: 28,
    city: "Maddaloni",
    salary: 1180,
    bonus: 200,
    address: { zip: "81024" },
    languages: ["italian", "english"],
    friends: [ { name: "Patrizia" }, { name: "Anna" } ],
    skills: { name: "Faker.js", level: "beginner" }
  },
  {
    name: "Alfonso",
    age: 33,
    city: "Nocera Inferiore",
    salary: 1400,
    bonus: 280,
    address: { zip: "84014" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Sergio" }, { name: "Immacolata" } ],
    skills: { name: "Casual", level: "advanced" }
  },
  {
    name: "Immacolata",
    age: 25,
    city: "Cava de' Tirreni",
    salary: 1050,
    bonus: 150,
    address: { zip: "84013" },
    languages: ["italian", "english"],
    friends: [ { name: "Alfonso" }, { name: "Sergio" } ],
    skills: { name: "Chance.js", level: "beginner" }
  },
  {
    name: "Marco",
    age: 32,
    city: "Milan",
    salary: 1500,
    bonus: 300,
    address: { zip: "20100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Andrea" }, { name: "Giuseppe" }, { name: "Francesca" } ],
    skills: { name: "React", level: "intermediate" }
  },
  {
    name: "Giulia",
    age: 26,
    city: "Naples",
    salary: 1100,
    bonus: 150,
    address: { zip: "80100" },
    languages: ["italian", "spanish"],
    friends: [ { name: "Alessandro" }, { name: "Valentina" } ],
    skills: { name: "Python", level: "advanced" }
  },
  {
    name: "Lorenzo",
    age: 35,
    city: "Florence",
    salary: 1800,
    bonus: 400,
    address: { zip: "50100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Matteo" }, { name: "Chiara" }, { name: "Davide" }, { name: "Elena" } ],
    skills: { name: "Java", level: "expert" }
  },
  {
    name: "Federica",
    age: 29,
    city: "Turin",
    salary: 1350,
    bonus: 250,
    address: { zip: "10100" },
    languages: ["italian", "english"],
    friends: [ { name: "Simone" }, { name: "Roberta" } ],
    skills: { name: "Vue.js", level: "intermediate" }
  },
  {
    name: "Alessandro",
    age: 31,
    city: "Bologna",
    salary: 1400,
    bonus: 280,
    address: { zip: "40100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Francesco" }, { name: "Martina" }, { name: "Nicola" } ],
    skills: { name: "Node.js", level: "advanced" }
  },
  {
    name: "Valentina",
    age: 24,
    city: "Genoa",
    salary: 950,
    bonus: 120,
    address: { zip: "16100" },
    languages: ["italian", "french"],
    friends: [ { name: "Giorgio" }, { name: "Silvia" } ],
    skills: { name: "HTML/CSS", level: "beginner" }
  },
  {
    name: "Matteo",
    age: 33,
    city: "Venice",
    salary: 1600,
    bonus: 350,
    address: { zip: "30100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Stefano" }, { name: "Paola" }, { name: "Riccardo" } ],
    skills: { name: "Angular", level: "expert" }
  },
  {
    name: "Chiara",
    age: 27,
    city: "Palermo",
    salary: 1050,
    bonus: 180,
    address: { zip: "90100" },
    languages: ["italian", "english"],
    friends: [ { name: "Salvatore" }, { name: "Claudia" } ],
    skills: { name: "PostgreSQL", level: "intermediate" }
  },
  {
    name: "Francesco",
    age: 30,
    city: "Bari",
    salary: 1250,
    bonus: 220,
    address: { zip: "70100" },
    languages: ["italian", "english", "arabic"],
    friends: [ { name: "Antonio" }, { name: "Lucia" }, { name: "Michele" } ],
    skills: { name: "Docker", level: "advanced" }
  },
  {
    name: "Martina",
    age: 25,
    city: "Catania",
    salary: 1000,
    bonus: 140,
    address: { zip: "95100" },
    languages: ["italian", "spanish"],
    friends: [ { name: "Filippo" }, { name: "Sara" } ],
    skills: { name: "PHP", level: "beginner" }
  },
  {
    name: "Davide",
    age: 34,
    city: "Verona",
    salary: 1550,
    bonus: 320,
    address: { zip: "37100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Enrico" }, { name: "Giuliana" }, { name: "Tommaso" } ],
    skills: { name: "Kubernetes", level: "expert" }
  },
  {
    name: "Elena",
    age: 28,
    city: "Trieste",
    salary: 1300,
    bonus: 240,
    address: { zip: "34100" },
    languages: ["italian", "english", "slovenian"],
    friends: [ { name: "Fabio" }, { name: "Cristina" } ],
    skills: { name: "GraphQL", level: "intermediate" }
  },
  {
    name: "Simone",
    age: 26,
    city: "Padua",
    salary: 1150,
    bonus: 190,
    address: { zip: "35100" },
    languages: ["italian", "english"],
    friends: [ { name: "Daniele" }, { name: "Beatrice" }, { name: "Marco" } ],
    skills: { name: "TypeScript", level: "advanced" }
  },
  {
    name: "Roberta",
    age: 29,
    city: "Brescia",
    salary: 1320,
    bonus: 260,
    address: { zip: "25100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Giacomo" }, { name: "Ilaria" } ],
    skills: { name: "AWS", level: "intermediate" }
  },
  {
    name: "Nicola",
    age: 31,
    city: "Parma",
    salary: 1400,
    bonus: 280,
    address: { zip: "43100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Luca" }, { name: "Federica" }, { name: "Emanuele" } ],
    skills: { name: "Redis", level: "advanced" }
  },
  {
    name: "Giorgio",
    age: 27,
    city: "Modena",
    salary: 1200,
    bonus: 210,
    address: { zip: "41100" },
    languages: ["italian", "english"],
    friends: [ { name: "Stefania" }, { name: "Alberto" } ],
    skills: { name: "Laravel", level: "intermediate" }
  },
  {
    name: "Silvia",
    age: 32,
    city: "Reggio Emilia",
    salary: 1450,
    bonus: 290,
    address: { zip: "42100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Claudio" }, { name: "Manuela" }, { name: "Fabio" } ],
    skills: { name: "Spring Boot", level: "expert" }
  },
  {
    name: "Stefano",
    age: 30,
    city: "Pisa",
    salary: 1380,
    bonus: 270,
    address: { zip: "56100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Carla" }, { name: "Roberto" } ],
    skills: { name: "Django", level: "advanced" }
  },
  {
    name: "Paola",
    age: 28,
    city: "Livorno",
    salary: 1100,
    bonus: 170,
    address: { zip: "57100" },
    languages: ["italian", "english"],
    friends: [ { name: "Massimo" }, { name: "Patrizia" }, { name: "Sergio" } ],
    skills: { name: "Flask", level: "beginner" }
  },
  {
    name: "Riccardo",
    age: 33,
    city: "Ancona",
    salary: 1500,
    bonus: 310,
    address: { zip: "60100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Gianluca" }, { name: "Michela" } ],
    skills: { name: "Elasticsearch", level: "expert" }
  },
  {
    name: "Salvatore",
    age: 35,
    city: "Messina",
    salary: 1250,
    bonus: 230,
    address: { zip: "98100" },
    languages: ["italian", "english"],
    friends: [ { name: "Rosario" }, { name: "Carmela" }, { name: "Antonino" } ],
    skills: { name: "RabbitMQ", level: "intermediate" }
  },
  {
    name: "Claudia",
    age: 26,
    city: "Cagliari",
    salary: 1080,
    bonus: 160,
    address: { zip: "09100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Giovanni" }, { name: "Francesca" } ],
    skills: { name: "Svelte", level: "beginner" }
  },
  {
    name: "Antonio",
    age: 29,
    city: "Foggia",
    salary: 1180,
    bonus: 200,
    address: { zip: "71100" },
    languages: ["italian", "english"],
    friends: [ { name: "Maria" }, { name: "Giuseppe" }, { name: "Pasquale" } ],
    skills: { name: "Terraform", level: "intermediate" }
  },
  {
    name: "Lucia",
    age: 31,
    city: "Lecce",
    salary: 1220,
    bonus: 220,
    address: { zip: "73100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Cosimo" }, { name: "Isabella" } ],
    skills: { name: "Ansible", level: "advanced" }
  },
  {
    name: "Michele",
    age: 28,
    city: "Taranto",
    salary: 1150,
    bonus: 190,
    address: { zip: "74100" },
    languages: ["italian", "english"],
    friends: [ { name: "Vincenzo" }, { name: "Rosanna" }, { name: "Domenico" } ],
    skills: { name: "Jenkins", level: "intermediate" }
  },
  {
    name: "Filippo",
    age: 27,
    city: "Reggio Calabria",
    salary: 1050,
    bonus: 150,
    address: { zip: "89100" },
    languages: ["italian", "english", "greek"],
    friends: [ { name: "Rocco" }, { name: "Angela" } ],
    skills: { name: "Git", level: "advanced" }
  },
  {
    name: "Sara",
    age: 24,
    city: "Cosenza",
    salary: 950,
    bonus: 130,
    address: { zip: "87100" },
    languages: ["italian", "english"],
    friends: [ { name: "Francesco" }, { name: "Giuseppina" }, { name: "Emilio" } ],
    skills: { name: "Selenium", level: "beginner" }
  },
  {
    name: "Enrico",
    age: 32,
    city: "Catanzaro",
    salary: 1280,
    bonus: 240,
    address: { zip: "88100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Salvatore" }, { name: "Teresa" } ],
    skills: { name: "Cypress", level: "intermediate" }
  },
  {
    name: "Giuliana",
    age: 30,
    city: "Potenza",
    salary: 1200,
    bonus: 210,
    address: { zip: "85100" },
    languages: ["italian", "english"],
    friends: [ { name: "Carmine" }, { name: "Giovanna" }, { name: "Rocco" } ],
    skills: { name: "Jest", level: "advanced" }
  },
  {
    name: "Tommaso",
    age: 29,
    city: "Matera",
    salary: 1100,
    bonus: 180,
    address: { zip: "75100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Nicola" }, { name: "Antonietta" } ],
    skills: { name: "Mocha", level: "intermediate" }
  },
  {
    name: "Fabio",
    age: 34,
    city: "L'Aquila",
    salary: 1400,
    bonus: 280,
    address: { zip: "67100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Massimo" }, { name: "Daniela" }, { name: "Gianni" } ],
    skills: { name: "Webpack", level: "expert" }
  },
  {
    name: "Cristina",
    age: 26,
    city: "Pescara",
    salary: 1080,
    bonus: 160,
    address: { zip: "65100" },
    languages: ["italian", "english"],
    friends: [ { name: "Marco" }, { name: "Simona" } ],
    skills: { name: "Gulp", level: "beginner" }
  },
  {
    name: "Daniele",
    age: 31,
    city: "Chieti",
    salary: 1300,
    bonus: 250,
    address: { zip: "66100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Alfredo" }, { name: "Luisa" }, { name: "Mario" } ],
    skills: { name: "Sass", level: "intermediate" }
  },
  {
    name: "Beatrice",
    age: 25,
    city: "Teramo",
    salary: 1000,
    bonus: 140,
    address: { zip: "64100" },
    languages: ["italian", "english"],
    friends: [ { name: "Pierluigi" }, { name: "Raffaella" } ],
    skills: { name: "Less", level: "beginner" }
  },
  {
    name: "Giacomo",
    age: 33,
    city: "Perugia",
    salary: 1450,
    bonus: 290,
    address: { zip: "06100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Umberto" }, { name: "Lorella" }, { name: "Piero" } ],
    skills: { name: "Tailwind CSS", level: "advanced" }
  },
  {
    name: "Ilaria",
    age: 27,
    city: "Terni",
    salary: 1120,
    bonus: 180,
    address: { zip: "05100" },
    languages: ["italian", "english"],
    friends: [ { name: "Claudio" }, { name: "Monica" } ],
    skills: { name: "Bootstrap", level: "intermediate" }
  },
  {
    name: "Emanuele",
    age: 30,
    city: "Viterbo",
    salary: 1250,
    bonus: 230,
    address: { zip: "01100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Mauro" }, { name: "Gabriella" }, { name: "Flavio" } ],
    skills: { name: "Bulma", level: "beginner" }
  },
  {
    name: "Stefania",
    age: 28,
    city: "Frosinone",
    salary: 1180,
    bonus: 200,
    address: { zip: "03100" },
    languages: ["italian", "english"],
    friends: [ { name: "Ciro" }, { name: "Alessandra" } ],
    skills: { name: "Material-UI", level: "intermediate" }
  },
  {
    name: "Alberto",
    age: 32,
    city: "Latina",
    salary: 1350,
    bonus: 260,
    address: { zip: "04100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Silvio" }, { name: "Paola" }, { name: "Enzo" } ],
    skills: { name: "Ant Design", level: "advanced" }
  },
  {
    name: "Claudio",
    age: 35,
    city: "Rieti",
    salary: 1500,
    bonus: 320,
    address: { zip: "02100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Sandro" }, { name: "Ornella" } ],
    skills: { name: "Chakra UI", level: "expert" }
  },
  {
    name: "Manuela",
    age: 29,
    city: "Campobasso",
    salary: 1200,
    bonus: 210,
    address: { zip: "86100" },
    languages: ["italian", "english"],
    friends: [ { name: "Pasquale" }, { name: "Carmela" }, { name: "Luigi" } ],
    skills: { name: "Styled Components", level: "intermediate" }
  },
  {
    name: "Carla",
    age: 26,
    city: "Isernia",
    salary: 1050,
    bonus: 150,
    address: { zip: "86170" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Gino" }, { name: "Filomena" } ],
    skills: { name: "Emotion", level: "beginner" }
  },
  {
    name: "Roberto",
    age: 31,
    city: "Avellino",
    salary: 1300,
    bonus: 250,
    address: { zip: "83100" },
    languages: ["italian", "english"],
    friends: [ { name: "Gerardo" }, { name: "Nunzia" }, { name: "Raffaele" } ],
    skills: { name: "Styled System", level: "intermediate" }
  },
  {
    name: "Massimo",
    age: 33,
    city: "Benevento",
    salary: 1400,
    bonus: 280,
    address: { zip: "82100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Vincenzo" }, { name: "Rosaria" } ],
    skills: { name: "Framer Motion", level: "advanced" }
  },
  {
    name: "Patrizia",
    age: 28,
    city: "Caserta",
    salary: 1150,
    bonus: 190,
    address: { zip: "81100" },
    languages: ["italian", "english"],
    friends: [ { name: "Gennaro" }, { name: "Anna" }, { name: "Salvatore" } ],
    skills: { name: "React Spring", level: "intermediate" }
  },
  {
    name: "Sergio",
    age: 30,
    city: "Salerno",
    salary: 1280,
    bonus: 240,
    address: { zip: "84100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Alfonso" }, { name: "Immacolata" } ],
    skills: { name: "Lottie", level: "beginner" }
  },
  {
    name: "Gianluca",
    age: 27,
    city: "Aosta",
    salary: 1200,
    bonus: 220,
    address: { zip: "11100" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Davide" }, { name: "Valentina" }, { name: "Luca" } ],
    skills: { name: "Three.js", level: "intermediate" }
  },
  {
    name: "Michela",
    age: 25,
    city: "Trento",
    salary: 1100,
    bonus: 170,
    address: { zip: "38100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Paolo" }, { name: "Chiara" } ],
    skills: { name: "D3.js", level: "beginner" }
  },
  {
    name: "Rosario",
    age: 34,
    city: "Bolzano",
    salary: 1600,
    bonus: 350,
    address: { zip: "39100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Klaus" }, { name: "Ingrid" }, { name: "Hans" } ],
    skills: { name: "Chart.js", level: "advanced" }
  },
  {
    name: "Carmela",
    age: 32,
    city: "Udine",
    salary: 1380,
    bonus: 270,
    address: { zip: "33100" },
    languages: ["italian", "english", "slovenian"],
    friends: [ { name: "Mattia" }, { name: "Elisa" } ],
    skills: { name: "Plotly", level: "expert" }
  },
  {
    name: "Antonino",
    age: 29,
    city: "Pordenone",
    salary: 1250,
    bonus: 230,
    address: { zip: "33170" },
    languages: ["italian", "english"],
    friends: [ { name: "Diego" }, { name: "Francesca" }, { name: "Matteo" } ],
    skills: { name: "Highcharts", level: "intermediate" }
  },
  {
    name: "Giovanni",
    age: 26,
    city: "Gorizia",
    salary: 1080,
    bonus: 160,
    address: { zip: "34170" },
    languages: ["italian", "english", "slovenian"],
    friends: [ { name: "Janez" }, { name: "Maja" } ],
    skills: { name: "Leaflet", level: "beginner" }
  },
  {
    name: "Francesca",
    age: 31,
    city: "Sassari",
    salary: 1150,
    bonus: 190,
    address: { zip: "07100" },
    languages: ["italian", "english", "sardinian"],
    friends: [ { name: "Gavino" }, { name: "Giuseppina" }, { name: "Piero" } ],
    skills: { name: "Mapbox", level: "intermediate" }
  },
  {
    name: "Giuseppe",
    age: 33,
    city: "Nuoro",
    salary: 1200,
    bonus: 210,
    address: { zip: "08100" },
    languages: ["italian", "english"],
    friends: [ { name: "Sebastiano" }, { name: "Maria" } ],
    skills: { name: "OpenLayers", level: "advanced" }
  },
  {
    name: "Pasquale",
    age: 28,
    city: "Oristano",
    salary: 1050,
    bonus: 150,
    address: { zip: "09170" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Efisio" }, { name: "Grazia" }, { name: "Antioco" } ],
    skills: { name: "Cesium", level: "beginner" }
  },
  {
    name: "Cosimo",
    age: 30,
    city: "Crotone",
    salary: 1100,
    bonus: 180,
    address: { zip: "88900" },
    languages: ["italian", "english"],
    friends: [ { name: "Saverio" }, { name: "Caterina" } ],
    skills: { name: "Deck.gl", level: "intermediate" }
  },
  {
    name: "Isabella",
    age: 27,
    city: "Vibo Valentia",
    salary: 1000,
    bonus: 140,
    address: { zip: "89900" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Fortunato" }, { name: "Concetta" }, { name: "Bruno" } ],
    skills: { name: "Turf.js", level: "beginner" }
  },
  {
    name: "Vincenzo",
    age: 32,
    city: "Ragusa",
    salary: 1250,
    bonus: 230,
    address: { zip: "97100" },
    languages: ["italian", "english"],
    friends: [ { name: "Corrado" }, { name: "Giusy" } ],
    skills: { name: "Moment.js", level: "intermediate" }
  },
  {
    name: "Rosanna",
    age: 25,
    city: "Siracusa",
    salary: 980,
    bonus: 130,
    address: { zip: "96100" },
    languages: ["italian", "english", "greek"],
    friends: [ { name: "Orazio" }, { name: "Concetta" }, { name: "Alfio" } ],
    skills: { name: "Day.js", level: "beginner" }
  },
  {
    name: "Domenico",
    age: 35,
    city: "Trapani",
    salary: 1400,
    bonus: 300,
    address: { zip: "91100" },
    languages: ["italian", "english", "arabic"],
    friends: [ { name: "Calogero" }, { name: "Vita" } ],
    skills: { name: "Luxon", level: "advanced" }
  },
  {
    name: "Rocco",
    age: 29,
    city: "Agrigento",
    salary: 1120,
    bonus: 180,
    address: { zip: "92100" },
    languages: ["italian", "english"],
    friends: [ { name: "Liborio" }, { name: "Calogera" }, { name: "Gerlando" } ],
    skills: { name: "Date-fns", level: "intermediate" }
  },
  {
    name: "Angela",
    age: 26,
    city: "Caltanissetta",
    salary: 1050,
    bonus: 150,
    address: { zip: "93100" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Salvatore" }, { name: "Pietra" } ],
    skills: { name: "Lodash", level: "beginner" }
  },
  {
    name: "Giuseppina",
    age: 31,
    city: "Enna",
    salary: 1180,
    bonus: 200,
    address: { zip: "94100" },
    languages: ["italian", "english"],
    friends: [ { name: "Calogero" }, { name: "Rosalia" }, { name: "Vincenzo" } ],
    skills: { name: "Ramda", level: "intermediate" }
  },
  {
    name: "Emilio",
    age: 28,
    city: "Matera",
    salary: 1100,
    bonus: 170,
    address: { zip: "75100" },
    languages: ["italian", "english", "german"],
    friends: [ { name: "Rocco" }, { name: "Angela" } ],
    skills: { name: "Underscore.js", level: "beginner" }
  },
  {
    name: "Teresa",
    age: 30,
    city: "Potenza",
    salary: 1220,
    bonus: 220,
    address: { zip: "85100" },
    languages: ["italian", "english"],
    friends: [ { name: "Carmine" }, { name: "Lucia" }, { name: "Nicola" } ],
    skills: { name: "Immutable.js", level: "intermediate" }
  },
  {
    name: "Carmine",
    age: 33,
    city: "Lamezia Terme",
    salary: 1300,
    bonus: 250,
    address: { zip: "88046" },
    languages: ["italian", "english", "spanish"],
    friends: [ { name: "Antonio" }, { name: "Francesca" } ],
    skills: { name: "RxJS", level: "advanced" }
  },
  {
    name: "Giovanna",
    age: 27,
    city: "Cosenza",
    salary: 1080,
    bonus: 160,
    address: { zip: "87100" },
    languages: ["italian", "english"],
    friends: [ { name: "Francesco" }, { name: "Maria" }, { name: "Giuseppe" } ],
    skills: { name: "Redux", level: "intermediate" }
  },
  {
    name: "Antonietta",
    age: 24,
    city: "Crotone",
    salary: 950,
    bonus: 120,
    address: { zip: "88900" },
    languages: ["italian", "english", "french"],
    friends: [ { name: "Salvatore" }, { name: "Rosa" } ],
    skills: { name: "MobX", level: "beginner" }
  }
];

printjson(db.users2.insertMany(sampleData));
print("Script ha inserito 100 users nel db users2");

