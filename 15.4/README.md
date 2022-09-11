# Домашнее задание к занятию 15.4 "Кластеры. Ресурсы под управлением облачных провайдеров"

Организация кластера Kubernetes и кластера баз данных MySQL в отказоустойчивой архитектуре.
Размещение в private подсетях кластера БД, а в public - кластера Kubernetes.

---
## Задание 1. Яндекс.Облако (обязательное к выполнению)

1. Настроить с помощью Terraform кластер баз данных MySQL:
- Используя настройки VPC с предыдущих ДЗ, добавить дополнительно подсеть private в разных зонах, чтобы обеспечить отказоустойчивость 
- Разместить ноды кластера MySQL в разных подсетях
- Необходимо предусмотреть репликацию с произвольным временем технического обслуживания
- Использовать окружение PRESTABLE, платформу Intel Broadwell с производительностью 50% CPU и размером диска 20 Гб
- Задать время начала резервного копирования - 23:59
- Включить защиту кластера от непреднамеренного удаления
- Создать БД с именем `netology_db` c логином и паролем

```
#mysql.tf
# Сети для нод кластера СУБД
resource "yandex_vpc_subnet" "private-mysql1" {
  v4_cidr_blocks = ["192.168.50.0/24"]
  name = "private-mysql-1"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}

resource "yandex_vpc_subnet" "private-mysql2" {
  v4_cidr_blocks = ["192.168.60.0/24"]
  name = "private-mysql-2"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}

resource "yandex_vpc_subnet" "private-mysql3" {
  v4_cidr_blocks = ["192.168.70.0/24"]
  name = "private-mysql-3"
  zone           = "ru-central1-c"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}

# создание кластера
resource "yandex_mdb_mysql_cluster" "db_mysql_cluster" {
  name        = "db_mysql_cluster"
  environment = "PRESTABLE"
  network_id  = "${yandex_vpc_network.clotst-net.id}"
  version     = "8.0"
  deletion_protection = true


  resources {
    resource_preset_id = "b1.medium" #	Intel Broadwell	50% CPU
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  backup_window_start {
    hours = 23
    minutes = 59
  }

  host {
    zone      = "ru-central1-a"
    name      = "na-1"
    subnet_id = yandex_vpc_subnet.private-mysql1.id
  }


    host {
    zone      = "ru-central1-b"
    name      = "na-2"
    replication_source_name = "na-1"
    subnet_id = yandex_vpc_subnet.private-mysql2.id
  }

  host {
    zone      = "ru-central1-c"
    name      = "na-3"
    replication_source_name = "na-1"
    subnet_id = yandex_vpc_subnet.private-mysql3.id
  }

}

#Создание базы

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.db_mysql_cluster.id
  name       = "netology_db"
}

# Пользователь в базе

resource "yandex_mdb_mysql_user" "user1" {
    depends_on = [yandex_mdb_mysql_database.netology_db]

    cluster_id = yandex_mdb_mysql_cluster.db_mysql_cluster.id
    name       = "user1"
    password   = "pass1234"

    permission {
      database_name = yandex_mdb_mysql_database.netology_db.name
      roles         = ["ALL"]
    }
    connection_limits {
      max_questions_per_hour   = 10
      max_updates_per_hour     = 20
      max_connections_per_hour = 30
      max_user_connections     = 40
    }

    global_permissions = ["PROCESS"]

    authentication_plugin = "SHA256_PASSWORD"
}

```



2. Настроить с помощью Terraform кластер Kubernetes
- Используя настройки VPC с предыдущих ДЗ, добавить дополнительно 2 подсети public в разных зонах, чтобы обеспечить отказоустойчивость
- Создать отдельный сервис-аккаунт с необходимыми правами 
- Создать региональный мастер kubernetes с размещением нод в разных 3 подсетях
- Добавить возможность шифрования ключом из KMS, созданного в предыдущем ДЗ
- Создать группу узлов состояющую из 3 машин с автомасштабированием до 6
- Подключиться к кластеру с помощью `kubectl`
- *Запустить микросервис phpmyadmin и подключиться к БД, созданной ранее
- *Создать сервис типы Load Balancer и подключиться к phpmyadmin. Предоставить скриншот с публичным адресом и подключением к БД


```
#kuber.tf
resource "yandex_vpc_subnet" "public1" {
  v4_cidr_blocks = ["192.168.100.0/24"]
  name = "public1"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}

resource "yandex_vpc_subnet" "public2" {
  v4_cidr_blocks = ["192.168.90.0/24"]
  name = "public2"
  zone           = "ru-central1-c"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}


// Create SA
resource "yandex_iam_service_account" "sakub" {
  folder_id = var.yc_folder_id
  name      = "sakub"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sakub-editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sakub.id}"
}


resource "yandex_kubernetes_cluster" "regional-cluster-my-kub" {
  name        = "regional-cluster-my-kub"
  description = "description"

  network_id = "${yandex_vpc_network.clotst-net.id}"

   master {
    regional {
      region = "ru-central1"

      location {
        zone      = "${yandex_vpc_subnet.public.zone}"
        subnet_id = "${yandex_vpc_subnet.public.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.public1.zone}"
        subnet_id = "${yandex_vpc_subnet.public1.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.public2.zone}"
        subnet_id = "${yandex_vpc_subnet.public2.id}"
      }
    }

    version   = "1.21"
    public_ip = true
  }
   
    service_account_id      = "${yandex_iam_service_account.sakub.id}"

    node_service_account_id = "${yandex_iam_service_account.sakub.id}"

  
    kms_provider {

        key_id = yandex_kms_symmetric_key.key-a.id
    }
}


resource "yandex_kubernetes_node_group" "my-kub-node-group" {
  cluster_id  = "${yandex_kubernetes_cluster.regional-cluster-my-kub.id}"
  name        = "my-kub-node-group"
  description = "description"
  version     = "1.21"

instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.public.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }


}

  scale_policy {
  
  auto_scale {
    initial = 3
    min = 3
    max = 6
  } 
  }


  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

}
```


'Настройка подключения через kubectl'

```
 yc managed-kubernetes cluster   get-credentials regional-cluster-my-kub  --external
```

```
> yc managed-kubernetes cluster   get-credentials regional-cluster-my-kub  --external

Context 'yc-regional-cluster-my-kub' was added as default to kubeconfig '/home/devuser/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/devuser/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
There is a new yc version '0.95.0' available. Current version: '0.83.0'.
See release notes at https://cloud.yandex.ru/docs/cli/release-notes
You can install it by running the following command in your shell:
        $ yc components update

devuser@devuser-virtual-machine:~/clokub-homeworks/15.4/terraform/clovm$
> kubectl cluster-info --kubeconfig /home/devuser/.kube/config
Kubernetes control plane is running at https://51.250.93.252
CoreDNS is running at https://51.250.93.252/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://51.250.93.252/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
devuser@devuser-virtual-machine:~/clokub-homeworks/15.4/terraform/clovm$
> kubectl get pods
No resources found in default namespace.
devuser@devuser-virtual-machine:~/clokub-homeworks/15.4/terraform/clovm$
> kubectl get pods -A
NAMESPACE     NAME                                     READY   STATUS    RESTARTS   AGE
kube-system   coredns-5f8dbbff8f-p6srq                 1/1     Running   0          27m
kube-system   coredns-5f8dbbff8f-s4qtk                 1/1     Running   0          9m56s
kube-system   ip-masq-agent-8vljc                      1/1     Running   0          9m33s
kube-system   ip-masq-agent-chcsb                      1/1     Running   0          10m
kube-system   ip-masq-agent-xtkvw                      1/1     Running   0          10m
kube-system   kube-dns-autoscaler-598db8ff9c-g9x6k     1/1     Running   0          27m
kube-system   kube-proxy-25mr2                         1/1     Running   0          9m33s
kube-system   kube-proxy-fltvb                         1/1     Running   0          10m
kube-system   kube-proxy-fmhx6                         1/1     Running   0          10m
kube-system   metrics-server-v0.3.1-6b998b66d6-58p9m   2/2     Running   0          9m50s
kube-system   npd-v0.8.0-pdr7d                         1/1     Running   0          9m33s
kube-system   npd-v0.8.0-phww5                         1/1     Running   0          10m
kube-system   npd-v0.8.0-vlngm                         1/1     Running   0          10m
kube-system   yc-disk-csi-node-v2-76zgt                6/6     Running   0          9m33s
kube-system   yc-disk-csi-node-v2-qgr88                6/6     Running   0          10m
kube-system   yc-disk-csi-node-v2-tzxhk                6/6     Running   0          10m
```

Документация
- [MySQL cluster](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_cluster)
- [Создание кластера kubernetes](https://cloud.yandex.ru/docs/managed-kubernetes/operations/kubernetes-cluster/kubernetes-cluster-create)
- [K8S Cluster](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster)
- [K8S node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
--- 
## Задание 2. Вариант с AWS (необязательное к выполнению)

1. Настроить с помощью terraform кластер EKS в 3 AZ региона, а также RDS на базе MySQL с поддержкой MultiAZ для репликации и создать 2 readreplica для работы:
- Создать кластер RDS на базе MySQL
- Разместить в Private subnet и обеспечить доступ из public-сети c помощью security-group
- Настроить backup в 7 дней и MultiAZ для обеспечения отказоустойчивости
- Настроить Read prelica в кол-ве 2 шт на 2 AZ.

2. Создать кластер EKS на базе EC2:
- С помощью terraform установить кластер EKS на 3 EC2-инстансах в VPC в public-сети
- Обеспечить доступ до БД RDS в private-сети
- С помощью kubectl установить и запустить контейнер с phpmyadmin (образ взять из docker hub) и проверить подключение к БД RDS
- Подключить ELB (на выбор) к приложению, предоставить скрин

Документация
- [Модуль EKS](https://learn.hashicorp.com/tutorials/terraform/eks)