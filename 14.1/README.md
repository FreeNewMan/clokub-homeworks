# Домашнее задание к занятию "14.1 Создание и использование секретов"

## Задача 1: Работа с секретами через утилиту kubectl в установленном minikube

Выполните приведённые ниже команды в консоли, получите вывод команд. Сохраните
задачу 1 как справочный материал.

### Как создать секрет?

```
openssl genrsa -out cert.key 4096
openssl req -x509 -new -key cert.key -days 3650 -out cert.crt \
-subj '/C=RU/ST=Moscow/L=Moscow/CN=server.local'
kubectl create secret tls domain-cert --cert=certs/cert.crt --key=certs/cert.key
```

#### Ответ

Создадим папку certs
```
devuser@devuser-virtual-machine:~$
> mkdir certs
devuser@devuser-virtual-machine:~$
> cd certs/

```
Генерим секреты

```
devuser@devuser-virtual-machine:~/certs$
> openssl genrsa -out cert.key 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
.............................................................................................................................................................................++++
....................................................................................................................................................................................++++
e is 65537 (0x010001)
devuser@devuser-virtual-machine:~/certs$
> openssl req -x509 -new -key cert.key -days 3650 -out cert.crt \
> -subj '/C=RU/ST=Moscow/L=Moscow/CN=server.local'
devuser@devuser-virtual-machine:~/certs$
> ls
cert.crt  cert.key

```
Грузим в Kubernates

```
> cd ..
devuser@devuser-virtual-machine:~$
> kubectl create secret tls domain-cert --cert=certs/cert.crt --key=certs/cert.key
secret/domain-cert created

```


### Как просмотреть список секретов?

```
kubectl get secrets
kubectl get secret
```
Смотрим

```
> kubectl get secrets
NAME                               TYPE                 DATA   AGE
domain-cert                        kubernetes.io/tls    2      2m22s
sh.helm.release.v1.nfs-server.v1   helm.sh/release.v1   1      22d
devuser@devuser-virtual-machine:~$
> kubectl get secret
NAME                               TYPE                 DATA   AGE
domain-cert                        kubernetes.io/tls    2      2m52s
sh.helm.release.v1.nfs-server.v1   helm.sh/release.v1   1      22d

```

### Как просмотреть секрет?

```
kubectl get secret domain-cert
kubectl describe secret domain-cert
```

```
> kubectl get secret domain-cert
NAME          TYPE                DATA   AGE
domain-cert   kubernetes.io/tls   2      5m3s
devuser@devuser-virtual-machine:~$
> kubectl describe secret domain-cert
Name:         domain-cert
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1944 bytes
tls.key:  3243 bytes
devu
```



### Как получить информацию в формате YAML и/или JSON?

```
kubectl get secret domain-cert -o yaml
kubectl get secret domain-cert -o json
```

```
devuser@devuser-virtual-machine:~$
> kubectl get secret domain-cert -o yaml
apiVersion: v1
data:
  tls.crt: 
  tls.key: 
kind: Secret
metadata:
  creationTimestamp: "2022-07-30T13:15:46Z"
  name: domain-cert
  namespace: default
  resourceVersion: "368359"
  uid: 3a2e4547-31ba-41d0-a7b2-feae512f5143
type: kubernetes.io/tls
devuser@devuser-virtual-machine:~$
> kubectl get secret domain-cert -o json
{
    "apiVersion": "v1",
    "data": {
        "tls.crt": "",
        "tls.key": ""
    },
    "kind": "Secret",
    "metadata": {
        "creationTimestamp": "2022-07-30T13:15:46Z",
        "name": "domain-cert",
        "namespace": "default",
        "resourceVersion": "368359",
        "uid": "3a2e4547-31ba-41d0-a7b2-feae512f5143"
    },
    "type": "kubernetes.io/tls"
}
```

### Как выгрузить секрет и сохранить его в файл?

```
kubectl get secrets -o json > secrets.json
kubectl get secret domain-cert -o yaml > domain-cert.yml
```

```
devuser@devuser-virtual-machine:~/certs$
> kubectl get secrets -o json > secrets.json
devuser@devuser-virtual-machine:~/certs$
> kubectl get secret domain-cert -o yaml > domain-cert.yml
devuser@devuser-virtual-machine:~/certs$
> ls
cert.crt  cert.key  domain-cert.yml  secrets.json

```
### Как удалить секрет?

```
kubectl delete secret domain-cert
```
```
devuser@devuser-virtual-machine:~/certs$
> kubectl delete secret domain-cert
secret "domain-cert" deleted
devuser@devuser-virtual-machine:~/certs$
> kubectl get secrets
NAME                               TYPE                 DATA   AGE
sh.helm.release.v1.nfs-server.v1   helm.sh/release.v1   1      22d
```
### Как загрузить секрет из файла?

```
kubectl apply -f domain-cert.yml
```
```
> kubectl apply -f domain-cert.yml
secret/domain-cert created
devuser@devuser-virtual-machine:~/certs$
> kubectl get secrets
NAME                               TYPE                 DATA   AGE
domain-cert                        kubernetes.io/tls    2      4s
sh.helm.release.v1.nfs-server.v1   helm.sh/release.v1   1      22d
```

## Задача 2 (*): Работа с секретами внутри модуля

Выберите любимый образ контейнера, подключите секреты и проверьте их доступность
как в виде переменных окружения, так и в виде примонтированного тома.

### Ответ
Создадим Deployment

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: multitool
  name: multitool
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multitool
  template:
    metadata:
      labels:
        app: multitool
    spec:
      containers:
      - name: network-multitool
        image: praqma/network-multitool:alpine-extra
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: crts-tst    
          mountPath: "/crts"
          readOnly: true
        env:
          - name: SECRET_CRT
            valueFrom:
              secretKeyRef:
                name: domain-cert
                key: tls.crt          
          - name: SECRET_KEY
            valueFrom:
              secretKeyRef:
                name: domain-cert
                key: tls.key          
      volumes:
      - name: crts-tst
        secret:     
          secretName: domain-cert

```
Сохраним в файл и загрузим в Kubernetes

```
devuser@devuser-virtual-machine:~/clokub-homeworks/14.1/manifests$
> kubectl apply -f multitoolscr.yml 
deployment.apps/multitool created

```
Смотрим, создался ли под:
```
> kubectl get pods
NAME                                  READY   STATUS    RESTARTS        AGE
multitool-dc4bdf946-qk7qt             1/1     Running   0               52s
nfs-server-nfs-server-provisioner-0   1/1     Running   11 (4h2m ago)   22d

```


Логинимся в под и смотрим наличие файлов сертификатов

```
devuser@devuser-virtual-machine:~/clokub-homeworks/14.1/manifests$
> kubectl exec --stdin --tty multitool-dc4bdf946-qk7qt -- /bin/bash
bash-5.1# ls
bin                   docker-entrypoint.sh  media                 root                  sys
certs                 etc                   mnt                   run                   tmp
crts                  home                  opt                   sbin                  usr
dev                   lib                   proc                  srv                   var
bash-5.1# ls /crts
tls.crt  tls.key
bash-5.1# 
```


Смотрим переменные окружения:

```
bash-5.1# echo $SECRET_CRT
-----BEGIN CERTIFICATE----- MIIFbTCCA1WgAwIBAgIUeHuM40+yqhjF35VP/UiWra1wWDgwDQYJKoZIhvcNAQEL BQAwRjELMAkGA1UEBhMCUlUxDzANBgNVBAgMBk1vc2NvdzEPMA0GA1U.....
```

```
bash-5.1# echo $SECRET_KEY
-----BEGIN RSA PRIVATE KEY----- MIIJKQIBAAKCAgEA4TYgbsE9/mtcX4QOuikN0RMQEF+nwhF6OvgufeD1aopGepul SjEnTtd3XAYeg1qCdRKVq5+ctLnpglz5xkp83sDxUEnkC96ypE4ZCDG0E1Xqy9zB RQEo6QtY1....
```
---
