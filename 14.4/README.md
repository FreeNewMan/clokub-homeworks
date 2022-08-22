# Домашнее задание к занятию "14.4 Сервис-аккаунты"

## Задача 1: Работа с сервис-аккаунтами через утилиту kubectl в установленном minikube

Выполните приведённые команды в консоли. Получите вывод команд. Сохраните
задачу 1 как справочный материал.

### Как создать сервис-аккаунт?

```
kubectl create serviceaccount netology
```

```
> kubectl create ns netology
namespace/netology created
opsuser@opsserver:~/home_works/clokub-homeworks/14.4$ 
> kubectl create serviceaccount netology
serviceaccount/netology created
```
### Как просмотреть список сервис-акаунтов?

```
kubectl get serviceaccounts
kubectl get serviceaccount
```

```
> kubectl get serviceaccounts
NAME       SECRETS   AGE
default    1         80s
netology   1         76s
opsuser@opsserver:~/home_works/clokub-homeworks/14.4$ 
> kubectl get serviceaccount
NAME       SECRETS   AGE
default    1         86s
netology   1         82s
opsuser@opsserver:~/home_works/clokub-homeworks/14.4$ 
> kubectl get serviceaccount netology 
NAME       SECRETS   AGE
netology   1         88s
```

### Как получить информацию в формате YAML и/или JSON?

```
kubectl get serviceaccount netology -o yaml
kubectl get serviceaccount default -o json
```

```
> kubectl get serviceaccount netology -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-08-21T19:28:10Z"
  name: netology
  namespace: netology
  resourceVersion: "24694"
  uid: a8c4a6ef-9782-4109-a42a-f41cbe989e20
secrets:
- name: netology-token-tlsvr

```

```
> kubectl get serviceaccount default -o json
{
    "apiVersion": "v1",
    "kind": "ServiceAccount",
    "metadata": {
        "creationTimestamp": "2022-08-21T19:28:06Z",
        "name": "default",
        "namespace": "netology",
        "resourceVersion": "24688",
        "uid": "8fce0d20-2851-4c78-a71d-f21e5033afe7"
    },
    "secrets": [
        {
            "name": "default-token-zg9w4"
        }
    ]
}

```

### Как выгрузить сервис-акаунты и сохранить его в файл?

```
kubectl get serviceaccounts -o json > serviceaccounts.json
kubectl get serviceaccount netology -o yaml > netology.yml
```
```
> kubectl get serviceaccounts -o json > serviceaccounts.json
opsuser@opsserver:~/home_works/clokub-homeworks/14.4$ 
> kubectl get serviceaccount netology -o yaml > netology.yml
```
### Как удалить сервис-акаунт?

```
kubectl delete serviceaccount netology
```
```
> kubectl delete serviceaccount netology
serviceaccount "netology" deleted
```
### Как загрузить сервис-акаунт из файла?

```
kubectl apply -f netology.yml
```
```
opsuser@opsserver:~/home_works/clokub-homeworks/14.4$ 
> kubectl apply -f netology.yml
serviceaccount/netology created

```
## Задача 2 (*): Работа с сервис-акаунтами внутри модуля

Выбрать любимый образ контейнера, подключить сервис-акаунты и проверить
доступность API Kubernetes

```
kubectl run -i --tty fedora --image=fedora --restart=Never -- sh
```

```
> kubectl run -i --tty fedora --image=fedora --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
sh-5.1# 

```

Просмотреть переменные среды

```
env | grep KUBE
```

```
sh-5.1# env | grep KUBE
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
HELLO_MINIKUBE_PORT_8080_TCP_PROTO=tcp
HELLO_MINIKUBE_SERVICE_HOST=10.101.155.60
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
HELLO_MINIKUBE_PORT_8080_TCP=tcp://10.101.155.60:8080
HELLO_MINIKUBE_PORT_8080_TCP_ADDR=10.101.155.60
HELLO_MINIKUBE_PORT_8080_TCP_PORT=8080
HELLO_MINIKUBE_SERVICE_PORT=8080
KUBERNETES_PORT_443_TCP_PROTO=tcp
HELLO_MINIKUBE_PORT=tcp://10.101.155.60:8080
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443

```

Получить значения переменных

```
K8S=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
SADIR=/var/run/secrets/kubernetes.io/serviceaccount
TOKEN=$(cat $SADIR/token)
CACERT=$SADIR/ca.crt
NAMESPACE=$(cat $SADIR/namespace)
```

```
sh-5.1# K8S=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
SADIR=/var/run/secrets/kubernetes.io/serviceaccount
TOKEN=$(cat $SADIR/token)
CACERT=$SADIR/ca.crt
NAMESPACE=$(cat $SADIR/namespace)
sh-5.1# echo $K8S
https://10.96.0.1:443
sh-5.1# echo $SADIR
/var/run/secrets/kubernetes.io/serviceaccount
sh-5.1# echo $CACERT 
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
sh-5.1# echo $NAMESPACE 
default
```

Подключаемся к API

```
curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/api/v1/
```

```
sh-5.1# curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/api/v1/
{
  "kind": "APIResourceList",
  "groupVersion": "v1",
  "resources": [
    {
      "name": "bindings",
      "singularName": "",
      "namespaced": true,
      "kind": "Binding",
      "verbs": [
        "create"
      ]
    },
    {
....
```

В случае с minikube может быть другой адрес и порт, который можно взять здесь

```
cat ~/.kube/config
```

или здесь

```
kubectl cluster-info
```

---


