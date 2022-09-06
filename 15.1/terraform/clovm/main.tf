terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.78.0"
    }
  }
}

# Provider
provider "yandex" {
  token     = "${var.yc_token}"
  cloud_id  = "${var.yc_cloud_id}"
  folder_id = "${var.yc_folder_id}"
  zone      = "${var.yc_region}"
}

resource "yandex_vpc_network" "clotst-net" {
  name = "clotest-network"
}

resource "yandex_vpc_subnet" "public" {
  v4_cidr_blocks = ["192.168.10.0/24"]
  name = "public"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
}

resource "yandex_vpc_subnet" "private" {
  v4_cidr_blocks = ["192.168.20.0/24"]
  name = "private"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.clotst-net.id}"
  route_table_id  = "${yandex_vpc_route_table.nat-instance-route.id}"
}


resource "yandex_vpc_route_table" "nat-instance-route" {
  network_id     = "${yandex_vpc_network.clotst-net.id}"
  name = "route-table"
  
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}


module "nat-instance" {
  source = "../modules/instance"

  subnet_id     = "${yandex_vpc_subnet.public.id}"
  image_id      = "fd80mrhj8fl2oe87o4e1"  # nat-instance-ubuntu-1559218207 yc compute image list --folder-id standard-images | grep  fd80mrhj8fl2oe87o4e1
  platform_id   = "standard-v2"
  name          = "nat-vm"
  description   = "NAT"
  instance_role = "nat"
  ip_addr       = "192.168.10.254"
  users         = "devuser"
  cores         = "2"
  boot_disk     = "network-ssd"
  disk_size     = "20"
  nat           = "true"
  memory        = "2"
  core_fraction = "100"
}

module "public_vm" {
  source = "../modules/instance"

  subnet_id     = "${yandex_vpc_subnet.public.id}"
  image_id      = "fd87k1od4v1bth3m59ha"  # ubuntu 16
  platform_id   = "standard-v2"
  name          = "ubuntu1"
  description   = "ubuntu1"
  users         = "devuser"
  cores         = "2"
  boot_disk     = "network-ssd"
  disk_size     = "20"
  nat           = "true"
  memory        = "2"
  core_fraction = "100"
}

module "private_vm" {
  source = "../modules/instance"

  subnet_id     = "${yandex_vpc_subnet.private.id}"
  image_id      = "fd87k1od4v1bth3m59ha"  # ubuntu 16
  platform_id   = "standard-v2"
  name          = "ubuntu2"
  description   = "ubuntu2"
  users         = "devuser"
  cores         = "2"
  boot_disk     = "network-ssd"
  disk_size     = "20"
  nat           = "false"
  memory        = "2"
  core_fraction = "100"
}





