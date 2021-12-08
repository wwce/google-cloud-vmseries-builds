# -----------------------------------------------------------------------------------
# Networking
module "vpc_mgmt" {
  source               = "./modules/vpc/"
  name                 = "${local.prefix}-mgmt-vpc"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "${var.region}-mgmt-subnet" = {
      region                = var.region,
      cidr                  = var.subnet_cidrs[0]
      private_google_access = false
    }
  }
}

module "vpc_untrust" {
  source               = "./modules/vpc/"
  name                 = "${local.prefix}-untrust-vpc"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "${var.region}-untrust-subnet" = {
      region                = var.region,
      cidr                  = var.subnet_cidrs[1]
      private_google_access = false
    }
  }
}

module "vpc_trust" {
  source               = "./modules/vpc/"
  name                 = "${local.prefix}-trust-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "${var.region}-trust-subnet" = {
      region                = var.region,
      cidr                  = var.subnet_cidrs[2]
      private_google_access = false
    }
  }
  depends_on = [
    google_project_service.service_networking,
    google_project_service.ids
  ]
}

resource "google_compute_global_address" "trust" {
  name          = "${module.vpc_trust.vpc_name}-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc_trust.vpc_self_link
}

resource "google_service_networking_connection" "trust" {
  network                 = module.vpc_trust.vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.trust.name]
}

# -----------------------------------------------------------------------------------
# Set default route to VM-Series within the trust VPC network
resource "google_compute_route" "trust_route0" {
  name              = "${local.prefix}-route"
  dest_range        = "0.0.0.0/0"
  network           = module.vpc_trust.vpc_id
  next_hop_instance = module.vmseries.self_links["vmseries01"]
  priority          = 100
}
