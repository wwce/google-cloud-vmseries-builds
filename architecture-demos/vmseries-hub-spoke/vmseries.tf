# --------------------------------------------------------------------------------------------------------------------------
# Create bootstrap bucket for VM-Series firewalls

module "bootstrap" {
  source        = "../modules/gcp_bootstrap/"
  bucket_name   = "vmseries-demo-bootstrap"
  file_location = "bootstrap_files/"
  config        = ["init-cfg.txt", "bootstrap.xml"]
}


# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

module "vpc_mgmt" {
  source               = "../modules/vpc/"
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
  source               = "../modules/vpc/"
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
  source               = "../modules/vpc/"
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
  source = "../modules/vmseries/"
  image_name            = var.fw_image_name
  machine_type          = var.fw_machine_type
  create_instance_group = true
  project_id               = data.google_client_config.main.project
  ssh_key               = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  
  instances = { 
    vmseries01 = {
      name               = "${random_string.main.result}-vmseries01"
      zone               = data.google_compute_zones.main.names[0]
      bootstrap_bucket   = module.bootstrap.bucket_name #var.fw_bootstrap_bucket
      network_interfaces = [
        {
          subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.region}"]
          public_nat = true
          lb = false
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"]
          public_nat = true
          lb = false
        },
        {
          subnetwork = module.vpc_trust.subnet_self_link["trust-${var.region}"]
          public_nat = false
          lb = true
        }
      ]
    },
    vmseries02 = {
      name               = "${random_string.main.result}-vmseries02"
      zone               = data.google_compute_zones.main.names[0]
      bootstrap_bucket   = module.bootstrap.bucket_name #var.fw_bootstrap_bucket
      network_interfaces = [
        {
          subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.region}"]
          public_nat = true
          lb = false
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"]
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

  depends_on = [
    module.bootstrap
  ]
}

# --------------------------------------------------------------------------------------------------------------------------
# Create VM-Series internal load balancer with default route

resource "google_compute_health_check" "internal_lb" {
  name = "${local.prefix}-hc-tcp80"

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_region_backend_service" "internal_lb" {
  name          = "${local.prefix}-backend"
  region        = var.region
  health_checks = [google_compute_health_check.internal_lb.id]
  network       = module.vpc_trust.vpc_id

  backend {
    group = module.vmseries.instance_groups["vmseries01"]
  }

  backend {
    group = module.vmseries.instance_groups["vmseries02"]
  }

}

resource "google_compute_forwarding_rule" "internal_lb" {
  name   = "${local.prefix}-internal-lb"
  region = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.internal_lb.id
  all_ports             = true
  network               = module.vpc_trust.vpc_id
  subnetwork            = module.vpc_trust.subnet_self_link["trust-${var.region}"]
  allow_global_access   = true
}

resource "google_compute_route" "internal_lb" {
  name         = "${local.prefix}-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_trust.vpc_id
  next_hop_ilb = google_compute_forwarding_rule.internal_lb.id
  priority     = 1000
}


# --------------------------------------------------------------------------------------------------------------------------
# Create VM-Series public load balancer

resource "google_compute_forwarding_rule" "public_lb" {
  name            = "${local.prefix}-public-lb"
  region          = var.region
  port_range      = "80"
  backend_service = google_compute_region_backend_service.public_lb.id
}

resource "google_compute_region_backend_service" "public_lb" {
  name                  = "${local.prefix}-public-lb-backend"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.public_lb.id]

  backend {
    group = module.vmseries.instance_groups["vmseries01"]
  }

  backend {
    group = module.vmseries.instance_groups["vmseries02"]
  }

}

resource "google_compute_region_health_check" "public_lb" {
  name   = "${local.prefix}-hc-tcp80"
  region = var.region

  tcp_health_check {
    port = "80"
  }
}


# --------------------------------------------------------------------------------------------------------------------------
# Outputs to terminal

output VMSERIES01_ACCESS {
  value = "https://${module.vmseries.nic1_ips["vmseries01"]}"
}
output VMSERIES02_ACCESS {
  value = "https://${module.vmseries.nic1_ips["vmseries02"]}"
}

output EXT_LB_URL {
  value = "http://${google_compute_forwarding_rule.public_lb.ip_address}"
}

output SSH_TO_SPOKE2 {
  value = "ssh ${var.spoke_vm_user}@${module.vmseries.nic0_ips["vmseries01"]}"
}