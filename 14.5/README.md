# Домашнее задание к занятию "14.5 SecurityContext, NetworkPolicies"

## Задача 1: Рассмотрите пример 14.5/example-security-context.yml

Создайте модуль

```
kubectl apply -f 14.5/example-security-context.yml
```

Проверьте установленные настройки внутри контейнера

```
kubectl logs security-context-demo
uid=1000 gid=3000 groups=3000
```


```
opsuser@opsserver:~/home_works/clokub-homeworks/14.5/files$ 
> kubectl apply -f example-security-context.yml 
pod/security-context-demo created
opsuser@opsserver:~/home_works/clokub-homeworks/14.5/files$ 
> kubectl logs security-context-demo
uid=1000 gid=3000 groups=3000

```
## Задача 2 (*): Рассмотрите пример 14.5/example-network-policy.yml

Создайте два модуля. Для первого модуля разрешите доступ к внешнему миру
и ко второму контейнеру. Для второго модуля разрешите связь только с
первым контейнером. Проверьте корректность настроек.


Создадим namespace


```
> kubectl create ns netology
namespace/netology created
opsuser@opsserver:~/home_works/clokub-homeworks/14.5/files$ 
> kubens netology 
Context "kubernetes-admin@cluster.local" modified.
Active namespace is "netology".

```


Создадим два манифеста для двух подов 

```
#10-frontend.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: frontend
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - image: praqma/network-multitool:alpine-extra
          imagePullPolicy: IfNotPresent
          name: network-multitool
      terminationGracePeriodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  ports:
    - name: web
      port: 80
  selector:
    app: frontend
```
```
#20-backend.yml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: backend
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - image: praqma/network-multitool:alpine-extra
          imagePullPolicy: IfNotPresent
          name: network-multitool
      terminationGracePeriodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  ports:
    - name: web
      port: 80
  selector:
    app: backend

```
Применяем и проверям что он создались

```
> kubectl apply -f pods/
deployment.apps/frontend created
service/frontend created
deployment.apps/backend created
service/backend created
```

```
Every 2,0s: kubectl get po,svc,networkpolicies                             devuser-virtual-machine: Tue Sep  6 19:32:28 2022

NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-869fd89bdc-7v5sd   1/1     Running   0          39s
pod/frontend-c74c5646c-cvfl2   1/1     Running   0          39s

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/backend    ClusterIP   10.233.1.91     <none>        80/TCP    39s
service/frontend   ClusterIP   10.233.34.234   <none>        80/TCP    39s

```

Создадим манифесты политик:

```
# 00-default.yml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
    - Ingress #Запрещаем всем подам входящий трафик
```

```
#10-front-policy.yml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-policy  
spec:
  podSelector: 
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress #Разрешаем входящий трафик в frontend из backend
  ingress: 
  - from:
    - podSelector:
        matchLabels:
          app: backend
         
```

```
#20-back-policy.yml

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: back-policy
spec:
  podSelector: 
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress     
  ingress: #Разрешаем входящий трафик в backend из frontend
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress: #Разершаем только исходящий трафик в frontend из backend  
  - to:
    - podSelector:
        matchLabels:
          app: frontend
  - to:
    ports:
    - protocol: UDP #доступ к kube-dns 
      port: 53
    - protocol: TCP
      port: 53
    - protocol: TCP
      port: 80

```

Проверяем
```
Every 2,0s: kubectl get po,svc,networkpolicies                             devuser-virtual-machine: Tue Sep  6 19:41:08 2022

NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-869fd89bdc-7v5sd   1/1     Running   0          9m19s
pod/frontend-c74c5646c-cvfl2   1/1     Running   0          9m19s

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/backend    ClusterIP   10.233.1.91     <none>        80/TCP    9m19s
service/frontend   ClusterIP   10.233.34.234   <none>        80/TCP    9m19s

NAME                                                   POD-SELECTOR   AGE
networkpolicy.networking.k8s.io/back-policy            app=backend    10s
networkpolicy.networking.k8s.io/default-deny-ingress   <none>         10s
networkpolicy.networking.k8s.io/front-policy           app=frontend   10s
```


Фронденд может ходить в бекенд и во внешний мир:

```
> kubectl exec -it frontend-c74c5646c-cvfl2  -- sh
/ # ping ya.ru
PING ya.ru (87.250.250.242) 56(84) bytes of data.
64 bytes from ya.ru (87.250.250.242): icmp_seq=1 ttl=127 time=611 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=2 ttl=127 time=611 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 2 received, 33.3333% packet loss, time 3151ms
rtt min/avg/max/mdev = 611.006/611.109/611.212/0.103 ms
/ # curl backend
Praqma Network MultiTool (with NGINX) - backend-869fd89bdc-7v5sd - 10.233.90.194
```

Бэкенд может ходить только во frontend. Во внешний мир и еще куда-то мир доступ запрещен. 


```
> kubectl exec -it backend-869fd89bdc-7v5sd  -- sh
/ # ping ya.ru
PING ya.ru (87.250.250.242) 56(84) bytes of data.
^C
--- ya.ru ping statistics ---
13 packets transmitted, 0 received, 100% packet loss, time 12270ms

/ # curl frontend
Praqma Network MultiTool (with NGINX) - frontend-c74c5646c-cvfl2 - 10.233.90.193
```
---

