Title: ⛏ Helm — Commands
Group: Kubernetes & Containers
Icon: ⛏
Order: 4

helm repo add bitnami https://charts.bitnami.com/bitnami   # Add repo / Добавить репозиторий
helm repo update && helm search repo nginx                  # Update & search / Обновить и искать
helm install my-nginx oci://registry-1.docker.io/bitnamicharts/nginx  # Install OCI / Установка OCI
helm upgrade --install my-app ./chart -n demo -f values.yaml # Upsert release / Установка/обновление
helm get values my-app -n demo                               # Effective values / Итоговые значения
helm uninstall my-app -n demo                                # Remove release / Удалить релиз

