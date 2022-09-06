# Домашнее задание к занятию "15.1. Организация сети"

Домашнее задание будет состоять из обязательной части, которую необходимо выполнить на провайдере Яндекс.Облако и дополнительной части в AWS по желанию. Все домашние задания в 15 блоке связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
Все задания требуется выполнить с помощью Terraform, результатом выполненного домашнего задания будет код в репозитории. 

Перед началом работ следует настроить доступ до облачных ресурсов из Terraform используя материалы прошлых лекций и [ДЗ](https://github.com/netology-code/virt-homeworks/tree/master/07-terraform-02-syntax ). А также заранее выбрать регион (в случае AWS) и зону.

---
## Задание 1. Яндекс.Облако (обязательное к выполнению)

1. Создать VPC.
- Создать пустую VPC. Выбрать зону.
2. Публичная подсеть.
- Создать в vpc subnet с названием public, сетью 192.168.10.0/24.
- Создать в этой подсети NAT-инстанс, присвоив ему адрес 192.168.10.254. В качестве image_id использовать fd80mrhj8fl2oe87o4e1
- Создать в этой публичной подсети виртуалку с публичным IP и подключиться к ней, убедиться что есть доступ к интернету.
3. Приватная подсеть.
- Создать в vpc subnet с названием private, сетью 192.168.20.0/24.
- Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс
- Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее и убедиться что есть доступ к интернету

[Terraform манифесты](./terraform)

Перед применением указываем параметры облака в файле vars.tf [Yandex cloud](./terraform/clovm/vars.tf)

Заполним параметры пользователя с которомы будем подключаться к машинам:
[user metadata](./terraform/users/metadata.txt)
Применяем:

```
> terraform init
Initializing modules...
- nat-instance in ../modules/instance
- private_vm in ../modules/instance
- public_vm in ../modules/instance

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.78.0"...
- Installing yandex-cloud/yandex v0.78.0...
- Installed yandex-cloud/yandex v0.78.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
devuser@devuser-virtual-machine:~/clokub-homeworks/15.1/terraform/clovm$
> terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_vpc_network.clotst-net will be created
  + resource "yandex_vpc_network" "clotst-net" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "clotest-network"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_route_table.nat-instance-route will be created
  + resource "yandex_vpc_route_table" "nat-instance-route" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + labels     = (known after apply)
      + name       = "route-table"
      + network_id = (known after apply)

      + static_route {
          + destination_prefix = "0.0.0.0/0"
          + next_hop_address   = "192.168.10.254"
        }
    }

  # yandex_vpc_subnet.private will be created
  + resource "yandex_vpc_subnet" "private" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "private"
      + network_id     = (known after apply)
      + route_table_id = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.20.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.public will be created
  + resource "yandex_vpc_subnet" "public" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # module.nat-instance.yandex_compute_instance.instance will be created
  + resource "yandex_compute_instance" "instance" {
      + created_at                = (known after apply)
      + description               = "NAT"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "nat-vm"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: devuser
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKqGCwNxELZCf/CzwF4Nw+LxAfJy/VfXEYj5r1NvdOsWAcs30IKyihPOXMsYXZ9FQnwf5O3TqqqbTkWtLTzKS71TUnN2KPbAzJVrM8Ih
            EOT
        }
      + name                      = "nat-vm"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd80mrhj8fl2oe87o4e1"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = "192.168.10.254"
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # module.private_vm.yandex_compute_instance.instance will be created
  + resource "yandex_compute_instance" "instance" {
      + created_at                = (known after apply)
      + description               = "ubuntu2"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "ubuntu2"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: devuser
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKqGCwNxELZCf/CzwF4Nw+LxAfJy/VfXEYj5r1NvdOsWAcs30IKyihPOXMsYXZ9FQnwf5O3TqqqbTkWtLTzKS71TUnN2KPbAzJVrM8Ih4tJC0rlFTitdHaHpqaVlJ1qKCKRCF6sXs9BXdzbODKDaMjXcwLneEnbnzru/
            EOT
        }
      + name                      = "ubuntu2"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd87k1od4v1bth3m59ha"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # module.public_vm.yandex_compute_instance.instance will be created
  + resource "yandex_compute_instance" "instance" {
      + created_at                = (known after apply)
      + description               = "ubuntu1"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "ubuntu1"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: devuser
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKqGCwNxELZCf/CzwF4Nw+LxAfJy/VfXEYj5r1NvdOsWAcs30IKyihPOXMsYXZ9FQnwf5O3TqqqbTkWtLTzKS71TUnN2KPbAzJVrM8Ih4tJC0rlFTitdHaHpqaVlJ1qKCKRCF6sXs9BXdzbODKDaMjXcwLneEnbnzru/
            EOT
        }
      + name                      = "ubuntu1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd87k1od4v1bth3m59ha"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.clotst-net: Creating...
yandex_vpc_network.clotst-net: Still creating... [10s elapsed]
yandex_vpc_network.clotst-net: Creation complete after 12s [id=enpf3djgv8o05sgl1b6r]
yandex_vpc_route_table.nat-instance-route: Creating...
yandex_vpc_subnet.public: Creating...
yandex_vpc_subnet.public: Creation complete after 3s [id=e9bqt5nf676sj9eqgq2t]
module.public_vm.yandex_compute_instance.instance: Creating...
module.nat-instance.yandex_compute_instance.instance: Creating...
yandex_vpc_route_table.nat-instance-route: Creation complete after 3s [id=enplfl4p441ac8aedmus]
yandex_vpc_subnet.private: Creating...
yandex_vpc_subnet.private: Creation complete after 3s [id=e9bfncttvseppshdivoi]
module.private_vm.yandex_compute_instance.instance: Creating...
module.public_vm.yandex_compute_instance.instance: Still creating... [10s elapsed]
module.nat-instance.yandex_compute_instance.instance: Still creating... [10s elapsed]
module.private_vm.yandex_compute_instance.instance: Still creating... [10s elapsed]
module.public_vm.yandex_compute_instance.instance: Still creating... [20s elapsed]
module.nat-instance.yandex_compute_instance.instance: Still creating... [20s elapsed]
module.private_vm.yandex_compute_instance.instance: Still creating... [20s elapsed]
module.public_vm.yandex_compute_instance.instance: Still creating... [30s elapsed]
module.nat-instance.yandex_compute_instance.instance: Still creating... [30s elapsed]
module.private_vm.yandex_compute_instance.instance: Creation complete after 30s [id=fhmosge0gd5tb2gers9j]
module.public_vm.yandex_compute_instance.instance: Creation complete after 35s [id=fhm5he8bi18dqj83rl0l]
module.nat-instance.yandex_compute_instance.instance: Still creating... [40s elapsed]
module.nat-instance.yandex_compute_instance.instance: Still creating... [50s elapsed]
module.nat-instance.yandex_compute_instance.instance: Creation complete after 53s [id=fhml86cv9busr20ceugr]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
devuser@devuser-virtual-machine:~/clokub-homeworks/15.1/terraform/clovm$
> yc compute instance list
+----------------------+---------+---------------+---------+----------------+----------------+
|          ID          |  NAME   |    ZONE ID    | STATUS  |  EXTERNAL IP   |  INTERNAL IP   |
+----------------------+---------+---------------+---------+----------------+----------------+
| fhm5he8bi18dqj83rl0l | ubuntu1 | ru-central1-a | RUNNING | 130.193.50.235 | 192.168.10.4   |
| fhml86cv9busr20ceugr | nat-vm  | ru-central1-a | RUNNING | 130.193.48.61  | 192.168.10.254 |
| fhmosge0gd5tb2gers9j | ubuntu2 | ru-central1-a | RUNNING |                | 192.168.20.34  |
+----------------------+---------+---------------+---------+----------------+----------------+

> yc vpc network list-subnets --name=clotest-network
+----------------------+---------+----------------------+----------------------+----------------------+---------------+-------------------+
|          ID          |  NAME   |      FOLDER ID       |      NETWORK ID      |    ROUTE TABLE ID    |     ZONE      |       RANGE       |
+----------------------+---------+----------------------+----------------------+----------------------+---------------+-------------------+
| e9bfncttvseppshdivoi | private | b1grv3uvss39umedtrcu | enpf3djgv8o05sgl1b6r | enplfl4p441ac8aedmus | ru-central1-a | [192.168.20.0/24] |
| e9bqt5nf676sj9eqgq2t | public  | b1grv3uvss39umedtrcu | enpf3djgv8o05sgl1b6r |                      | ru-central1-a | [192.168.10.0/24] |
+----------------------+---------+----------------------+----------------------+----------------------+---------------+-------------------+

```
Проверяем доступ в интренет из виртуальных машин

```
> ssh devuser@130.193.50.235
The authenticity of host '130.193.50.235 (130.193.50.235)' can't be established.
ECDSA key fingerprint is SHA256:qJP0X6loUHEVUCzOSgyp6C6T/DTv3QcbLvrcjGSE/4c.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '130.193.50.235' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

devuser@ubuntu1:~$ ping ya.ru
PING ya.ru (87.250.250.242) 56(84) bytes of data.
64 bytes from ya.ru (87.250.250.242): icmp_seq=1 ttl=58 time=0.762 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=2 ttl=58 time=0.303 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=3 ttl=58 time=0.297 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.297/0.454/0.762/0.217 ms
```
В первой машише (в публичной public сети) доступ есть

Для подключения ко второй машине в приватной(private) сети через первую нужно добавить публичный ключ:

```
devuser@ubuntu1:~$ vi  ~/.ssh/id_rsa
devuser@ubuntu1:~$ chmod 0600  ~/.ssh/id_rsa
```

Подключаемся на втроую машину по втруненнему ip и проверям доступ в интернет

```
devuser@ubuntu1:~$ ssh devuser@192.168.20.34 
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

devuser@ubuntu2:~$ ping ya.ru
PING ya.ru (87.250.250.242) 56(84) bytes of data.
64 bytes from ya.ru (87.250.250.242): icmp_seq=1 ttl=56 time=1.33 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=2 ttl=56 time=0.725 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=3 ttl=56 time=0.631 ms
^C
--- ya.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
```

Resource terraform для ЯО
- [VPC subnet](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet)
- [Route table](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table)
- [Compute Instance](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance)
---
## Задание 2*. AWS (необязательное к выполнению)

1. Создать VPC.
- Cоздать пустую VPC с подсетью 10.10.0.0/16.
2. Публичная подсеть.
- Создать в vpc subnet с названием public, сетью 10.10.1.0/24
- Разрешить в данной subnet присвоение public IP по-умолчанию. 
- Создать Internet gateway 
- Добавить в таблицу маршрутизации маршрут, направляющий весь исходящий трафик в Internet gateway.
- Создать security group с разрешающими правилами на SSH и ICMP. Привязать данную security-group на все создаваемые в данном ДЗ виртуалки
- Создать в этой подсети виртуалку и убедиться, что инстанс имеет публичный IP. Подключиться к ней, убедиться что есть доступ к интернету.
- Добавить NAT gateway в public subnet.
3. Приватная подсеть.
- Создать в vpc subnet с названием private, сетью 10.10.2.0/24
- Создать отдельную таблицу маршрутизации и привязать ее к private-подсети
- Добавить Route, направляющий весь исходящий трафик private сети в NAT.
- Создать виртуалку в приватной сети.
- Подключиться к ней по SSH по приватному IP через виртуалку, созданную ранее в публичной подсети и убедиться, что с виртуалки есть выход в интернет.

Resource terraform
- [VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [Subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
- [Internet Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)