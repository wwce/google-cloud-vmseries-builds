# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

# mgmt ethernet on VM-Series
module "vpc_mgmt" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-mgmt"
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

# ethernet1/1 on VM-Series
module "vpc_untrust" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${random_string.main.result}-untrust"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "untrust-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_untrust
    }
  }
}

# ethernet1/2 on VM-Series
module "vpc_spoke1" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${local.prefix}-spoke1-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke1-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_spoke1
    }
  }
}

# ethernet1/3 on VM-Series
module "vpc_spoke2" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${local.prefix}-spoke2-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke2-${var.region}" = {
      region = var.region,
      cidr   = var.cidr_spoke2
    }
  }
}
