Title: ☸️ KUBECTL — Commands
Group: Kubernetes & Containers
Icon: ☸️
Order: 1

kubectl config get-contexts && kubectl get ns   # Contexts & namespaces / Контексты и неймспейсы
kubectl get pods -A                             # All pods / Все pod-ы
kubectl get deploy,svc,ing -n demo              # Deploy/Svc/Ing in ns / Обзор в namespace
kubectl describe pod POD -n demo                # Describe pod / Детали pod-а
kubectl logs -f POD -n demo --tail=200          # Follow logs / Логи (последние 200)
kubectl exec -it POD -n demo -- /bin/sh         # Shell in container / Оболочка в контейнере
kubectl cp demo/POD:/path/in/pod ./local/       # Copy from pod / Копировать из pod-а
kubectl apply -f manifest.yaml                  # Apply manifests / Применить манифест
kubectl rollout restart deploy/myapp -n demo    # Restart deployment / Перезапуск деплоймента
kubectl scale deploy/myapp -n demo --replicas=3 # Scale to 3 / Масштаб до 3
kubectl port-forward deploy/myapp 8080:80 -n demo # Local 8080→svc 80 / Проброс портов
kubectl top pods -n demo                        # Pods CPU/mem / Ресурсы pod-ов

