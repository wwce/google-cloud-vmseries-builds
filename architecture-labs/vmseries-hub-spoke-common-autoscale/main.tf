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
  length      = 5
  min_lower   = 5
  special     = false
}

locals {
  prefix = "mrm01" #random_string.main.result
}



hub-spoke-vmseries-common
hub-spoke-vmseries-common-autoscale
hub-spoke-vmseries-distributed
hub-spoke-vmseries-distributed-autoscale



network-connectivity-center
hub-spoke-common-vmseries