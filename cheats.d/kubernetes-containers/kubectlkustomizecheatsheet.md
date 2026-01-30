Title: ☸️ Kustomize — kustomization.yaml
Group: Kubernetes & Containers
Icon: ☸️
Order: 3

# Skeleton / Шаблон
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  app: demo
patchesStrategicMerge:
  - patch-env.yaml
configMapGenerator:
  - name: demo-config
    literals: [MODE=prod, LOG_LEVEL=info]

# Run / Запуск
kubectl kustomize ./overlays/prod                                 # Render / Рендер
kubectl apply -k ./overlays/prod                                  # Apply / Применить

