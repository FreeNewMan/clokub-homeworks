resource "yandex_kms_symmetric_key" "key-a" { 
  folder_id = var.yc_folder_id
  name              = "my-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}