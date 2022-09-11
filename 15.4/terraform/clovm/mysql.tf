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
