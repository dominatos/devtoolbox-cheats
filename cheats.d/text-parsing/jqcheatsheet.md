Title: 🧩 JQ — Commands
Group: Text & Parsing
Icon: 🧩
Order: 9

jq '.' file.json                                # Pretty-print entire JSON / Красивый вывод всего JSON
jq -r '.items[].name' file.json                 # Extract field as raw lines / Имена как «сырые» строки
jq '.items | map(select(.active))'              # Filter active items / Фильтр по .active
jq '[.[]|.price] | add'                         # Sum of .price fields / Сумма полей .price
jq 'group_by(.status) | map({status:.[0].status,count:length})'  # Group & count / Группировка и подсчёт
jq '(.users[]|select(.id==42)).name="Alice"'    # Update field conditionally / Условное обновление поля
curl -s https://api.example.com/users | jq '.[] | {id,email}'  # Curl + jq pipeline / Связка curl + jq

