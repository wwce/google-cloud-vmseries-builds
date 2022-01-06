# --------------------------------------------------------------------------------------------------------------------------
# Setup Terraform providers, pull the regions availability zones, and create naming prefix as local variable

terraform {}

provider "google" {
  #credentials = var.auth_file
  project     = var.project_id
  region      = var.region
}

data "google_client_config" "main" {
}

data "google_compute_zones" "main" {
  project = data.google_client_config.main.project
  region  = var.region
}

resource "random_string" "main" {
  length      = 4
  min_lower   = 4
  special     = false
}

locals {
  prefix = random_string.main.result
}