
# --------------------------------------------------------------------------------------------------------------------------
# Create a cloud NAT for the management VPC network.  This provides external connectivity
# to Panorama and PANW licensing & content servers. 

module "mgmt_cloud_nat" {
  source = "terraform-google-modules/cloud-nat/google"
  # version = "=1.2"

  name                               = "${local.prefix}-mgmt"
  router                             = "${local.prefix}-mgmt"
  project_id                         = var.project_id
  region                             = var.region
  create_router                      = true
  network                            = module.vpc_mgmt.vpc_self_link
}

# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets
module "vpc_mgmt" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-mgmt-vpc"
  delete_default_route = false
  allowed_sources      = var.mgmt_sources
  allowed_protocol     = "TCP"
  allowed_ports        = ["443", "22", "3978"]

  subnets = {
    "mgmt-${var.region}" = {
      region = var.region,
      cidr   = var.cidrs_mgmt
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
      cidr   = var.cidrs_untrust
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
      cidr   = var.cidrs_trust
    }
  }
}
