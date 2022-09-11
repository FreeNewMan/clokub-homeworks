output "picture_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.test.bucket}/${yandex_storage_object.cat-picture.key}"
  depends_on = [yandex_storage_object.cat-picture]
}