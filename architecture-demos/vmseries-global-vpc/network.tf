# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

module "vpc_mgmt" {
  source               = "../modules/google_vpc/"
  vpc                  = "${local.prefix}-mgmt-vpc"
  delete_default_route = false
  allowed_sources      = var.mgmt_sources
  allowed_protocol     = "TCP"
  allowed_ports        = ["443", "22"]

  subnets = {
    "mgmt-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_mgmt[0]
    },
    "mgmt-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_mgmt[1]
    }
  }
}

module "vpc_untrust" {
  source               = "../modules/google_vpc/"
  vpc                  = "${local.prefix}-untrust-vpc"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "untrust-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_untrust[0]
    },
    "untrust-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_untrust[1]
    }
  }
}

module "vpc_trust" {
  source               = "../modules/google_vpc/"
  vpc                  = "${local.prefix}-trust-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "trust-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_trust[0]
    },
    "trust-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_trust[1]
    }
  }
}