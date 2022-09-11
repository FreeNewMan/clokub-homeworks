#variable image { default =  "centos-8" }
variable image_id { default =  "" }
variable name { default = ""}
variable description { default =  "instance from terraform" }
variable instance_role { default =  "all" }
variable users { default = "devuser"}
variable cores { default = ""}
variable platform_id { default = "standard-v1"}
variable memory { default = ""}
variable core_fraction { default = "20"}
variable subnet_id { default = ""}
variable nat { default = "false"}
variable count_offset { default = 0 } #start numbering from X+1 (e.g. name-1 if '0', name-3 if '2', etc.)
variable count_format { default = "%01d" } #server number format (-1, -2, etc.)
variable boot_disk { default =  "network-hdd" }
variable disk_size { default =  "20" }
variable ip_addr {default = "" }

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.78.0"
    }
  }
}

#data "yandex_compute_image" "image" {
#  family = "${var.image}"
#}

resource "yandex_compute_instance" "instance" {
  name = "${var.name}" #-${format(var.count_format, var.count_offset+count.index+1)}"
  platform_id = "${var.platform_id}"
  hostname = "${var.name}"
  description = "${var.description}"


  resources {
    cores  = "${var.cores}"
    memory = "${var.memory}"
    core_fraction = "${var.core_fraction}"
  }
  boot_disk {
    initialize_params {
      image_id = "${var.image_id}"
      type = "${var.boot_disk}"
      size = "${var.disk_size}"
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat        = var.nat
    ip_address  = var.ip_addr
  }

  metadata = {
    #ssh-keys = "${var.users}:${file("~/.ssh/id_rsa.pub")}"
    user-data = "${file("../users/metadata.txt")}"
  }
}

