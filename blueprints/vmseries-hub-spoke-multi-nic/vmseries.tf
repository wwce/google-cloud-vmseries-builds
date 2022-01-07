# --------------------------------------------------------------------------------------------------------------------------
# Create bootstrap bucket for VM-Series firewalls

module "bootstrap" {
  source        = "../../modules/google_bootstrap/"
  bucket_name   = "vmseries-demo-bootstrap"
  file_location = "bootstrap_files/"
  config        = ["init-cfg.txt", "bootstrap.xml"]
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
          subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.region}"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
          public_nat = false
        },
        {
          subnetwork = module.vpc_spoke2.subnet_self_link["spoke2-${var.region}"]
          public_nat = false
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
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
          public_nat = false
        },
        {
          subnetwork = module.vpc_spoke2.subnet_self_link["spoke2-${var.region}"]
          public_nat = false
        }
      ]
    }
  }

  depends_on = [
    module.bootstrap
  ]
}

# --------------------------------------------------------------------------------------------------------------------------
# Create an internal TCP network load balancer in each spoke network.  Each ILB will use the VM-Series NICs as its backend.

module "intlb_spoke1" {
  source = "../../modules/google_lb_internal/"

  name                = "${local.prefix}-intlb01-spoke1"
  network             = module.vpc_spoke1.vpc_self_link
  subnetwork          = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
  all_ports           = true
  allow_global_access = true
  backends            = module.vmseries.instance_group_self_links
}


module "intlb_spoke2" {
  source = "../../modules/google_lb_internal/"

  name                = "${local.prefix}-intlb02-spoke2"
  network             = module.vpc_spoke2.vpc_self_link
  subnetwork          = module.vpc_spoke2.subnet_self_link["spoke2-${var.region}"]
  all_ports           = true
  allow_global_access = true
  backends            = module.vmseries.instance_group_self_links
}

// Create default route in each spoke network to their internal LB forwarding rule
resource "google_compute_route" "spoke1_internal_lb" {
  name         = "${local.prefix}-default-spoke1"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_spoke1.vpc_id
  next_hop_ilb = module.intlb_spoke1.forwarding_rule
  priority     = 1000
}

resource "google_compute_route" "spoke2_internal_lb" {
  name         = "${local.prefix}-default-spoke2"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_spoke2.vpc_id
  next_hop_ilb = module.intlb_spoke2.forwarding_rule
  priority     = 1000
}

# --------------------------------------------------------------------------------------------------------------------------
# Create external TCP network load balancer with two frontend IP addresses on TCP/80 & TCP/22.

module "extlb" {
  source = "../../modules/google_lb_external_tcp/"

  name                           = "${local.prefix}-extlb-vmseries"
  health_check_http_port         = 80
  health_check_http_request_path = "/"
  create_health_check            = false
  instances                      = module.vmseries.instances
  
  rules = {
    ("spoke1-web-80") = {
      port_range = 80
    },
    ("spoke2-jump-22") = {
      port_range = 22
    }
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
  value = "https://${module.extlb.ip_addresses["spoke1-web-80"]}"
}

output SSH_TO_SPOKE2 {
  value = "ssh ${var.spoke_vm_user}@${module.extlb.ip_addresses["spoke2-jump-22"]}"
}