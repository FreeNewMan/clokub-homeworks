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


Создадим два манифеста для двух подов с nginx

```
#00-pod1.yml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-1
  labels:
    app: nginx-1  
spec:
  containers:
  - name: nginx-1
    image: nginx:latest
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-1
spec:
  ports:
    - name: web
      port: 80
    - name: webs
      port: 443     
  selector:
    app: nginx-1
```
```
#01-pod2.yml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-2
  labels:
    app: nginx-2    
spec:
  containers:
  - name: nginx-2
    image: nginx:latest

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-2
spec:
  ports:
    - name: web
      port: 80
    - name: webs
      port: 443          
  selector:
    app: nginx-2

```
Применяем и проверям что он создались

```
> kubectl apply -f pods
pod/nginx-1 created
service/nginx-1 created
pod/nginx-2 created
service/nginx-2 created
```

```
Every 2.0s: kubectl get po,svc,networkpolicies                                              opsserver: Mon Aug 22 20:24:34 2022

NAME          READY   STATUS    RESTARTS   AGE
pod/nginx-1   1/1     Running   0          26m
pod/nginx-2   1/1     Running   0          26m

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/nginx-1   ClusterIP   10.233.40.220   <none>        80/TCP,443/TCP   5m17s
service/nginx-2   ClusterIP   10.233.60.141   <none>        80/TCP,443/TCP   5m17s

```

---

