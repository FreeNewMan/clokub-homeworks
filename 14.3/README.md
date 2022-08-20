# Домашнее задание к занятию "14.3 Карты конфигураций"

## Задача 1: Работа с картами конфигураций через утилиту kubectl в установленном minikube

Выполните приведённые команды в консоли. Получите вывод команд. Сохраните
задачу 1 как справочный материал.

### Как создать карту конфигураций?

```
kubectl create configmap nginx-config --from-file=nginx.conf
kubectl create configmap domain --from-literal=name=netology.ru
```

```
> kubectl create configmap nginx-config --from-file=nginx.conf
configmap/nginx-config created
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> kubectl create configmap domain --from-literal=name=netology.ru
configmap/domain created
```

### Как просмотреть список карт конфигураций?

```
kubectl get configmaps
kubectl get configmap
```

```
> kubectl get configmaps
NAME                   DATA   AGE
domain                 1      17s
kube-root-ca.crt       1      18h
nginx-config           1      34s
vault-agent-config     2      43m
vault-agent-configs    3      68m
vault-config           1      18h
vault-nginx-template   1      68m
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> kubectl get configmap
NAME                   DATA   AGE
domain                 1      30s
kube-root-ca.crt       1      18h
nginx-config           1      47s
vault-agent-config     2      43m
vault-agent-configs    3      68m
vault-config           1      18h
vault-nginx-template   1      68m
```

### Как просмотреть карту конфигурации?

```
kubectl get configmap nginx-config
kubectl describe configmap domain
```

```
> kubectl get configmap nginx-config
NAME           DATA   AGE
nginx-config   1      100s
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> kubectl describe configmap domain
Name:         domain
Namespace:    netology-test
Labels:       <none>
Annotations:  <none>

Data
====
name:
----
netology.ru

BinaryData
====

Events:  <none>

```

### Как получить информацию в формате YAML и/или JSON?

```
kubectl get configmap nginx-config -o yaml
kubectl get configmap domain -o json
```

```
> kubectl get configmap nginx-config -o yaml
apiVersion: v1
data:
  nginx.conf: "server {\r\n    listen 80;\r\n    server_name  netology.ru www.netology.ru;\r\n
    \   access_log  /var/log/nginx/domains/netology.ru-access.log  main;\r\n    error_log
    \  /var/log/nginx/domains/netology.ru-error.log info;\r\n    location / {\r\n
    \       include proxy_params;\r\n        proxy_pass http://10.10.10.10:8080/;\r\n
    \   }\r\n}\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-20T05:48:37Z"
  name: nginx-config
  namespace: netology-test
  resourceVersion: "411352"
  uid: fa9a3432-3a09-4246-9702-501a5e5febee
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> kubectl get configmap domain -o json
{
    "apiVersion": "v1",
    "data": {
        "name": "netology.ru"
    },
    "kind": "ConfigMap",
    "metadata": {
        "creationTimestamp": "2022-08-20T05:48:54Z",
        "name": "domain",
        "namespace": "netology-test",
        "resourceVersion": "411379",
        "uid": "0b51f8a2-6175-4792-9bf3-e8a43c65b5e1"
    }
}
```

### Как выгрузить карту конфигурации и сохранить его в файл?

```
kubectl get configmaps -o json > configmaps.json
kubectl get configmap nginx-config -o yaml > nginx-config.yml
```

```
> kubectl get configmaps -o json > configmaps.json
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> kubectl get configmap nginx-config -o yaml > nginx-config.yml
opsuser@opsserver:~/home_works/clokub-homeworks/14.3/files$ 
> ls
configmaps.json  generator.py  myapp-pod.yml  nginx.conf  nginx-config.yml  templates
```
### Как удалить карту конфигурации?

```
kubectl delete configmap nginx-config
```

```
> kubectl delete configmap nginx-config
configmap "nginx-config" deleted
```


### Как загрузить карту конфигурации из файла?

```
kubectl apply -f nginx-config.yml
```

```
> kubectl apply -f nginx-config.yml
configmap/nginx-config created
```

## Задача 2 (*): Работа с картами конфигураций внутри модуля

Выбрать любимый образ контейнера, подключить карты конфигураций и проверить
их доступность как в виде переменных окружения, так и в виде примонтированного
тома


манифест:

```
#myapp-pod.yml
---
apiVersion: v1
kind: Pod
metadata:
  name: netology-14.3
spec:
  containers:
  - name: myapp
    image: fedora:latest
    command: ['sleep', '3600']
    #command: ['/bin/bash', '-c']
    #args: ["env; ls -la /etc/nginx/conf.d"]
    env:
      - name: SPECIAL_LEVEL_KEY
        valueFrom:
          configMapKeyRef:
            name: nginx-config
            key: nginx.conf
    envFrom:
      - configMapRef:
          name: nginx-config
    volumeMounts:
      - name: config
        mountPath: /etc/nginx/conf.d
        readOnly: true
  volumes:
  - name: config
    configMap:
      name: nginx-config
```

```
> kubectl apply -f myapp-pod.yml 
pod/netology-14.3 created
```

```
> kubectl get pods
NAME                                 READY   STATUS             RESTARTS        AGE
netology-14.3                        1/1     Running            0               90s
nginx-autoreload-7fc59bc88f-mj9k2    2/2     Running            0               29m
vault-0                              1/1     Running            0               95m
vault-approle-demo-fcf5cc6cc-zb7cb   1/2     CrashLoopBackOff   8 (4m17s ago)   20m
```

Проверяем переменные окружения и наличие файла из конфигмапа:


```
> kubectl exec --stdin --tty netology-14.3 -- /bin/bash
[root@netology-14 /]# env
nginx.conf=server {
    listen 80;
    server_name  netology.ru www.netology.ru;
    access_log  /var/log/nginx/domains/netology.ru-access.log  main;
    error_log   /var/log/nginx/domains/netology.ru-error.log info;
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8080/;
    }
}

KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
HOSTNAME=netology-14.3
SPECIAL_LEVEL_KEY=server {
    listen 80;
    server_name  netology.ru www.netology.ru;
    access_log  /var/log/nginx/domains/netology.ru-access.log  main;
    error_log   /var/log/nginx/domains/netology.ru-error.log info;
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8080/;
    }
}

DISTTAG=f36container
PWD=/
FBR=f36
HOME=/root
LANG=C.UTF-8
KUBERNETES_PORT_443_TCP=tcp://10.233.0.1:443
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.m4a=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.oga=01;36:*.opus=01;36:*.spx=01;36:*.xspf=01;36:
FGC=f36
TERM=xterm
SHLVL=1
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_ADDR=10.233.0.1
KUBERNETES_SERVICE_HOST=10.233.0.1
KUBERNETES_PORT=tcp://10.233.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443
PATH=/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
_=/usr/bin/env
[root@netology-14 /]# ls -la /etc/nginx/conf.d
total 12
drwxrwxrwx 3 root root 4096 Aug 20 18:58 .
drwxr-xr-x 3 root root 4096 Aug 20 18:58 ..
drwxr-xr-x 2 root root 4096 Aug 20 18:58 ..2022_08_20_18_58_51.3288931004
lrwxrwxrwx 1 root root   32 Aug 20 18:58 ..data -> ..2022_08_20_18_58_51.3288931004
lrwxrwxrwx 1 root root   17 Aug 20 18:58 nginx.conf -> ..data/nginx.conf
```

---
