locals {
  bucket_name = join("", [var.bucket_name, random_string.randomstring.result])
}
resource "random_string" "randomstring" {
  length      = 25
  min_lower   = 15
  min_numeric = 10
  special     = false
}

resource "google_storage_bucket" "bootstrap" {
  name          = local.bucket_name
  location      = var.location
  force_destroy = true
}

resource "google_storage_bucket_object" "config_full" {
  count  = length(var.config) > 0 ? length(var.config) : "0"
  name   = "config/${element(var.config, count.index)}"
  source = "${var.file_location}${element(var.config, count.index)}"
  bucket = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "content_full" {
  count  = length(var.content) > 0 ? length(var.content) : "0"
  name   = "content/${element(var.content, count.index)}"
  source = "${var.file_location}${element(var.content, count.index)}"
  bucket = google_storage_bucket.bootstrap.name
}

resource "local_file" "authcodes" {
  count  = var.authcodes != null ? 1 : "0"
    content     = var.authcodes
    filename = "${var.file_location}/authcodes"
}

resource "google_storage_bucket_object" "license_full" {
  count  = var.authcodes != null ? 1 : "0"
  name   = "license/authcodes"
  source = "${var.file_location}/authcodes"
  bucket = google_storage_bucket.bootstrap.name
  depends_on = [
    local_file.authcodes
  ]
}

resource "google_storage_bucket_object" "software_full" {
  count  = length(var.software) > 0 ? length(var.software) : "0"
  name   = "software/${element(var.software, count.index)}"
  source = "${var.file_location}${element(var.software, count.index)}"
  bucket = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "plugins_full" {
  count  = length(var.plugins) > 0 ? length(var.plugins) : "0"
  name   = "plugins/${element(var.plugins, count.index)}"
  source = "${var.file_location}${element(var.plugins, count.index)}"
  bucket = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "config_empty" {
  count   = length(var.config) == 0 ? 1 : 0
  name    = "config/"
  content = "config/"
  bucket  = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "content_empty" {
  count   = length(var.content) == 0 ? 1 : 0
  name    = "content/"
  content = "content/"
  bucket  = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "license_empty" {
  count   = var.authcodes == null ? 1 : 0
  name    = "license/"
  content = "license/"
  bucket  = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "software_empty" {
  count   = length(var.software) == 0 ? 1 : 0
  name    = "software/"
  content = "software/"
  bucket  = google_storage_bucket.bootstrap.name
}

resource "google_storage_bucket_object" "plugins_empty" {
  count   = length(var.plugins) == 0 ? 1 : 0
  name    = "plugins/"
  content = "plugins/"
  bucket  = google_storage_bucket.bootstrap.name
}