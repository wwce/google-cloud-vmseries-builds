# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

module "vpc_mgmt" {
  source               = "../../modules/google_vpc/"
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
  source               = "../../modules/google_vpc/"
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
  source               = "../../modules/google_vpc/"
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

module "vpc_spoke1" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${local.prefix}-spoke1-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke1-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_spoke1[0]
    },
    "spoke1-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_spoke1[1]
    }
  }
}

module "vpc_spoke2" {
  source               = "../../modules/google_vpc/"
  vpc                  = "${local.prefix}-spoke2-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke2-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_spoke2[0]
    },
    "spoke2-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_spoke2[1]
    }
  }
}


# --------------------------------------------------------------------------------------------------------------------------
# Create VPC peering connections between spoke networks and the trust network

resource "google_compute_network_peering" "spoke1_to_trust" {
  name                 = "${local.prefix}-spoke1-to-trust"
  network              = module.vpc_spoke1.vpc_id
  peer_network         = module.vpc_trust.vpc_id
  import_custom_routes = false
  export_custom_routes = false
}

resource "null_resource" "spoke1_to_trust" {
  provisioner "local-exec" {
    command = "echo ${google_compute_network_peering.spoke1_to_trust.id}"
  }
}

resource "google_compute_network_peering" "spoke2_to_trust" {
  name                 = "${local.prefix}-spoke2-to-trust"
  network              = module.vpc_spoke2.vpc_id
  peer_network         = module.vpc_trust.vpc_id
  import_custom_routes = false
  export_custom_routes = false

  depends_on = [
    null_resource.spoke1_to_trust
  ]
}

resource "null_resource" "spoke2_to_trust" {
  provisioner "local-exec" {
    command = "echo ${google_compute_network_peering.spoke2_to_trust.id}"
  }
}

resource "google_compute_network_peering" "trust_to_spoke1" {
  name                 = "${local.prefix}-trust-to-spoke1"
  network              = module.vpc_trust.vpc_id
  peer_network         = module.vpc_spoke1.vpc_id
  import_custom_routes = false
  export_custom_routes = false

  depends_on = [
    null_resource.spoke2_to_trust
  ]
}

# Prevents API bug with too many concurrent peering connections created at the same time.
resource "null_resource" "trust_to_spoke1" {
  provisioner "local-exec" {
    command = "echo ${google_compute_network_peering.trust_to_spoke1.id}"
  }
}

resource "google_compute_network_peering" "trust_to_spoke2" {
  name                 = "${local.prefix}-trust-to-spoke2"
  network              = module.vpc_trust.vpc_id
  peer_network         = module.vpc_spoke2.vpc_id
  import_custom_routes = false
  export_custom_routes = false

  depends_on = [
    null_resource.trust_to_spoke1
  ]
}


# Spoke1 VPC route to ILB region 0
resource "google_compute_route" "spoke1_region0" {
  name         = "${local.prefix_region0}-spoke1-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_spoke1.vpc_id
  next_hop_ilb = cidrhost(var.cidrs_trust[0], 10)
  priority     = 1000
  tags         = ["${var.regions[0]}-fw"]
}

# Spoke2 VPC route to ILB region 0
resource "google_compute_route" "spoke2_region0" {
  name         = "${local.prefix_region0}-spoke2-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_spoke2.vpc_id
  next_hop_ilb = cidrhost(var.cidrs_trust[0], 10)
  priority     = 1000
  tags         = ["${var.regions[0]}-fw"]
}


# --------------------------------------------------------------------------------------------------------------------------
# Create a default route for each region in each spoke network.

# Spoke1 VPC route to ILB region 1
resource "google_compute_route" "spoke1_region1" {
  name       = "${local.prefix_region1}-spoke1-route"
  dest_range = "0.0.0.0/0"
  network    = module.vpc_spoke1.vpc_id
  next_hop_ilb = cidrhost(var.cidrs_trust[1], 10)
  priority     = 1000
  tags         = ["${var.regions[1]}-fw"]
}

# Spoke2 VPC route to ILB region 1
resource "google_compute_route" "spoke2_region1" {
  name       = "${local.prefix_region1}-spoke2-route"
  dest_range = "0.0.0.0/0"
  network    = module.vpc_spoke2.vpc_id
  next_hop_ilb = cidrhost(var.cidrs_trust[1], 10)
  priority     = 1000
  tags         = ["${var.regions[1]}-fw"]
}
