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