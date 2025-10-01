Title: ⛏ Helm — template/lint
Group: Kubernetes & Containers
Icon: ⛏
Order: 5

helm template my-app ./chart -f values.yaml | kubectl apply -f -   # Render+apply / Рендер и применить
helm lint ./chart                                                  # Lint chart / Проверка чарта
helm template my-app ./chart -f values.yaml -f values-prod.yaml    # Merge values / Объединить values

