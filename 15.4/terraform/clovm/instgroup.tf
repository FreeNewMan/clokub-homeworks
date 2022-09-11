resource "yandex_vpc_subnet" "private-group-vm" {
  v4_cidr_blocks = ["192.168.30.0/24"]
  name = "private-group-vm"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}


resource "yandex_compute_instance_group" "group1" {
  
  depends_on = [yandex_iam_service_account.sa,
                yandex_vpc_network.clotst-net,
                yandex_vpc_subnet.private-group-vm,
                yandex_resourcemanager_folder_iam_member.sa-editor
                ]

  name                = "test-ig"
  folder_id           = "${var.yc_folder_id}"
  service_account_id  = "${yandex_iam_service_account.sa.id}"
  deletion_protection = false
  instance_template {
     name = "my-instance-{instance.index}" 
     platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 4
      }
    }
    network_interface {
      network_id = "${ yandex_vpc_network.clotst-net.id}"
      subnet_ids = ["${yandex_vpc_subnet.private-group-vm.id}"]
    }

    metadata = {
      ssh-keys = "devuser:${file("~/.ssh/id_rsa.pub")}"
      user-data = "${file("../assets/sitedata.yaml")}"
   }

    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["${var.yc_region}"]
  }

  deploy_policy {
    max_unavailable = 3
    max_creating    = 3
    max_expansion   = 3
    max_deleting    = 3
  }

 health_check {
   interval = 5
   timeout = 4
   healthy_threshold = 2
   unhealthy_threshold = 2
   http_options {
    path = "/"
    port = 80
   }


}

  load_balancer {
    target_group_name = "sitevm-target-group"
  }

}



resource "yandex_lb_network_load_balancer" "sitevm-balancer" {
  name = "sitevm-balancer"

  listener {
    name = "sitevm-listener"
    port = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.group1.load_balancer.0.target_group_id

    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 80
      }
    }
  }
}