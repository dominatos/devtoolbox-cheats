Title: ☸️ KUBECTL — JSONPath
Group: Kubernetes & Containers
Icon: ☸️
Order: 2

kubectl get pods -o jsonpath='{.items[*].status.podIP}'   # All pod IPs / IP-адреса pod-ов
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'  # Names per line / Имена построчно
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'  # Node + version / Узел + версия
kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.template.spec.containers[*].image}{"\n"}{end}'  # Deploy→images / Образы контейнеров
kubectl get secret my -o jsonpath='{.data.password}' | base64 -d  # Decode field / Декодировать поле
kubectl get pods -o jsonpath='{.items[*].status.podIP}'                            # All pod IPs / Все IP подов
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'        # Names one per line / Имена по одному в строке
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'  # Node + kubelet version / Узел + версия kubelet
kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.template.spec.containers[*].image}{"\n"}{end}'  # Deploy → images / Деплой → образы
kubectl get secret my -o jsonpath='{.data.password}' | base64 -d                   # Decode secret field / Декодировать поле секрета

