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
  prefix = random_string.main.result
}


# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

module "vpc_mgmt" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-mgmt-vpc"
  delete_default_route = false
  allowed_sources      = var.mgmt_sources
  allowed_protocol     = "TCP"
  allowed_ports        = ["443", "22"]

  subnets = {
    "mgmt-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_mgmt
    }
  }
}

module "vpc_untrust" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-untrust-vpc"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "untrust-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_untrust
    }
  }
}

module "vpc_trust" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-trust-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "trust-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_trust
    }
  }
}


# --------------------------------------------------------------------------------------------------------------------------
# Create VM-Series firewalls

module "vmseries" {
  source = "../../modules/vmseries_unmanaged_ig/" 
  image_name            = var.fw_image_name
  machine_type          = var.fw_machine_type
  create_instance_group = true
  project_id            = data.google_client_config.main.project
  ssh_key               = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  
  instances = { 
    vmseries01 = {
      name               = "${random_string.main.result}-vmseries01"
      zone               = data.google_compute_zones.main.names[0]
      bootstrap_bucket   = module.bootstrap.bucket_name #var.fw_bootstrap_bucket
      network_interfaces = [
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"]
          public_nat = true
          lb = false
        },
        {
          subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.region}"]
          public_nat = true
          lb = false
        },
        {
          subnetwork = module.vpc_trust.subnet_self_link["trust-${var.region}"]
          public_nat = false
          lb = true
        }
      ]
    }
  }
}



# --------------------------------------------------------------------------------------------------------------------------
# Outputs to terminal

output VMSERIES_WEB_ACCESS {
  value = "https://${module.vmseries.nic0_ips["vmseries01"]}"
}
output VMSERIES_SSH_ACCESS {
  value = "ssh admin@${module.vmseries.nic0_ips["vmseries01"]} -i ${replace(var.public_key_path, ".pub", "")}"
}