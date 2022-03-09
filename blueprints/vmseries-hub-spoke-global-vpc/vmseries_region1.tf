# --------------------------------------------------------------------------------------------------------------------------
# Create bootstrap bucket for VM-Series, internal load balancer, and route to load balancer forwarding rule.

module "bootstrap_region1" {
  source        = "../../modules/google_bootstrap/"
  bucket_name   = "${local.prefix_region1}-bootstrap"
  file_location = var.fw_region1_bootstrap_path
  config        = ["init-cfg.txt", "bootstrap.xml"]
  authcodes     = var.authcodes
}

module "vmseries_region1" {
  source                = "../../modules/vmseries_unmanaged_ig/"
  image_name            = var.fw_image_name
  machine_type          = var.fw_machine_type
  create_instance_group = true
  project_id            = data.google_client_config.main.project

  metadata = {
    mgmt-interface-swap                  = "enable"
    vmseries-bootstrap-gce-storagebucket = module.bootstrap_region1.bucket_name
    serial-port-enable                   = true
    ssh-keys                             = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  }

  instances = {

    vmseries01 = {
      name             = "${local.prefix_region1}-vmseries01"
      zone             = data.google_compute_zones.region1.names[0]
      bootstrap_bucket = module.bootstrap_region1.bucket_name
      network_interfaces = [
        {
          subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.regions[1]}"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.regions[1]}"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_trust.subnet_self_link["trust-${var.regions[1]}"]
          public_nat = false
        }
      ]
    }
  }
}

resource "google_compute_region_backend_service" "region1" {
  name          = "${local.prefix_region1}-backend"
  region        = var.regions[1]
  health_checks = [google_compute_health_check.main.id]
  network       = module.vpc_trust.vpc_id

  backend {
    group = module.vmseries_region1.instance_groups["vmseries01"]
  }
}

resource "google_compute_forwarding_rule" "region1" {
  name   = "${local.prefix_region1}-forwarding-rule"
  region = var.regions[1]

  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.region1.id
  all_ports             = true
  network               = module.vpc_trust.vpc_id
  ip_address            = cidrhost(var.cidrs_trust[1], 10)
  subnetwork            = module.vpc_trust.subnet_self_link["trust-${var.regions[1]}"]
  allow_global_access   = true
}
