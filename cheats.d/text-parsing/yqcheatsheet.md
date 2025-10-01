Title: 🧪 yq — YAML processor
Group: Text & Parsing
Icon: 🧪
Order: 8

yq '.spec.replicas' deploy.yaml                 # Read field / Прочитать поле
yq '.items[].metadata.name' list.yaml           # List names / Список имён
yq '(.spec.template.spec.containers[].image) = "repo/app:v1.2.3"' -i deploy.yaml  # In-place edit / Правка на месте
yq 'del(.metadata.annotations)' -i obj.yaml     # Delete field / Удалить поле
yq 'with(.spec.containers[]; .resources.limits.memory="256Mi")' -i deploy.yaml   # Modify blocks / Модифицировать блоки
yq -o=json '.items[] | {name:.metadata.name,ns:.metadata.namespace}' k8s.yaml    # Output JSON / Вывод как JSON
yq '.spec.replicas' deploy.yaml                                       # Read field / Прочитать поле
yq '.items[].metadata.name' list.yaml                                 # List item names / Список имён элементов
yq '(.spec.template.spec.containers[].image) = "repo/app:v1.2.3"' -i deploy.yaml  # In-place set image / Поменять image на месте
yq 'del(.metadata.annotations)' -i obj.yaml                           # Delete field / Удалить поле
yq 'with(.spec.containers[]; .resources.limits.memory="256Mi")' -i deploy.yaml    # Modify blocks / Модифицировать блоки
yq -o=json '.items[] | {name:.metadata.name,ns:.metadata.namespace}' k8s.yaml     # Output as JSON / Вывод в JSON
yq ea '. as $item ireduce ({}; . *+ $item )' a.yaml b.yaml > merged.yaml          # Merge YAML files / Слить YAML-файлы

