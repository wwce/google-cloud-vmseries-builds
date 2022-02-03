# --------------------------------------------------------------------------------------------------------------------------
# Setup Terraform providers, pull the regions availability zones, and create naming prefix as local variable

terraform {}

provider "google" {
  #credentials = var.auth_file
  project     = var.project_id
  region      = var.regions[0]
}

data "google_compute_zones" "region0" {
  region = var.regions[0]
}

data "google_client_config" "main" {
}

data "google_compute_zones" "region1" {
  region = var.regions[1]
}

resource "random_string" "main" {
  length      = 4
  min_lower   = 4
  special     = false
}

locals {
    prefix         = random_string.main.result
    prefix_region0 = "${local.prefix}-${var.regions[0]}"
    prefix_region1 = "${local.prefix}-${var.regions[1]}"
}