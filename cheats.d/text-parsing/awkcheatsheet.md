Title: 🦾 AWK — Commands
Group: Text & Parsing
Icon: 🦾
Order: 4

awk '{print $1,$2}' file                        # Print cols 1,2 / Вывести столбцы 1 и 2
awk -F',' '{print $1,$3}' data.csv              # Set FS comma / Разделитель запятая
awk '$3>100' file                               # Filter col3>100 / Фильтр по 3 столбцу
awk '/ERROR/ && $2=="db"' app.log               # Regex+eq col2 / Регэксп + сравнение
awk '{s+=$2} END{print s}' file                 # Sum col2 / Сумма столбца 2
awk '{c[$1]++} END{for(k in c) print k,c[k]}'   # Frequency by col1 / Частоты по 1 столбцу
awk -F, '{a[$1]+=$3} END{for(k in a) print k,a[k]}' data.csv  # Sum by key / Сумма по ключу
awk '{gsub(/foo/,"bar");print}' file            # Replace in stream / Замена в потоке
awk 'NR==FNR{m[$1]=$2;next}{print $0,m[$1]}' A B  # Join map / Джойн по карте

