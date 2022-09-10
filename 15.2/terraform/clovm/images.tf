resource "yandex_storage_object" "cat-picture" {
  bucket = "tf-test-bucket-72"
  key    = "cat.jpg"
  source = "../../images/cat.jpg"
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  acl = "public-read"
  depends_on = [yandex_storage_bucket.test]
}