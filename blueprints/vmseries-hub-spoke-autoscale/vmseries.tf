# -----------------------------------------------------------------------------------------------
# Create cloud NAT in mgmt VPC to provide internet connectivity to Panorama/PANW content servers. 

module "cloud_nat_mgmt" {
  source = "terraform-google-modules/cloud-nat/google"
  #ersion = "=1.2"
  name          = "${local.prefix}-mgmt"
  router        = "${local.prefix}-mgmt"
  project_id    = var.project_id
  region        = var.region
  create_router = true
  network       = module.vpc_mgmt.vpc_self_link
}

// Create cloud NAT in untrust VPC to provide outbound connectivity for backend VPC networks
module "cloud_nat_untrust" {
  source = "terraform-google-modules/cloud-nat/google"
  #ersion = "=1.2"
  name          = "${local.prefix}-untrust"
  router        = "${local.prefix}-untrust"
  project_id    = var.project_id
  region        = var.region
  create_router = true
  network       = module.vpc_untrust.vpc_self_link
}

# -----------------------------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------------------------
# Create IAM service account for the VM-Series to publish metrics to stack driver

resource "google_service_account" "vmseries" {
  project      = data.google_client_config.main.project
  account_id   = "${local.prefix}-panw-service-account"
  display_name = "Palo Alto Networks VM-Series Service Account"
}

resource "google_project_iam_member" "vmseries" {
  for_each = var.service_account_roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.vmseries.email}"
}

# -----------------------------------------------------------------------------------------------
# Create a managed instance group with the VM-Series (autoscaling)

module "autoscale" {
  source = "../../modules/vmseries_managed_ig/"

  prefix                = "${local.prefix}-vmseries"
  project_id            = data.google_client_config.main.project
  deployment_name       = local.deployment_name
  machine_type          = var.fw_machine_type
  ssh_key               = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  image                 = var.fw_image_uri
  nic0_public_ip        = false
  nic1_public_ip        = false
  nic2_public_ip        = false
  pool                  = module.extlb.target_pool
 # scopes                = ["https://www.googleapis.com/auth/cloud-platform"]
  service_account       = google_service_account.vmseries.email
  min_replicas_per_zone = 1
  max_replicas_per_zone = 2
  autoscaler_metrics    = var.autoscaler_metrics

  zones = {
    zone1 = data.google_compute_zones.main.names[0]
    zone2 = data.google_compute_zones.main.names[1]
  }

  subnetworks = [
    module.vpc_untrust.subnet_self_link["untrust-${var.region}"],
    module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"],
    module.vpc_trust.subnet_self_link["trust-${var.region}"]
  ]

  named_ports = [
    {
      name = "http"
      port = "80"
    }
  ]

  labels = {
    vm-series-fw-template-version = "1-0-0"
  }

  tags = [
    "vm-series-fw"
  ]

  metadata = {
    type                        = "dhcp-client"
    op-command-modes            = "mgmt-interface-swap"
    vm-auth-key                 = var.panorama_vm_auth_key
    panorama-server             = var.panorama_address
    dgname                      = var.panorama_device_group
    tplname                     = var.panorama_template_stack
    dhcp-send-hostname          = "yes"
    dhcp-send-client-id         = "yes"
    dhcp-accept-server-hostname = "yes"
    dhcp-accept-server-domain   = "yes"
    /*
    # Example of bootstrap via Google storage bucket.
      mgmt-interface-swap                  = "enable"
      vmseries-bootstrap-gce-storagebucket = "my-google-bootstrap-bucket"
      serial-port-enable                   = true
      ssh-keys                             = "~/.ssh/vmseries-ssh-key.pub"
    */
  }

}

# -----------------------------------------------------------------------------------------------
# Create internal TCP network load balancer (all ports)

module "intlb" {
  source = "../../modules/google_lb_internal/"

  name       = "${local.prefix}-intlb-vmseries"
  network    = module.vpc_trust.vpc_self_link
  subnetwork = module.vpc_trust.subnet_self_link["trust-${var.region}"]
  all_ports  = true
  backends   = module.autoscale.backends

  allow_global_access = true
}

# -----------------------------------------------------------------------------------------------
# Create external TCP network load balancer

module "extlb" {
  source = "../../modules/google_lb_external_tcp/"

  name                           = "${local.prefix}-extlb-vmseries"
  health_check_http_port         = 80
  health_check_http_request_path = "/"
  create_health_check            = false

  rules = {
    ("spoke1-web-80") = {
      port_range = 80
    },
    ("spoke2-jump-22") = {
      port_range = 22
    }
  }
}

# -----------------------------------------------------------------------------------------------
# Create default route in the trust VPC to use VM-Series internal LB as next hop

resource "google_compute_route" "internal_lb" {
  name         = "${local.prefix}-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_trust.vpc_id
  next_hop_ilb = module.intlb.forwarding_rule
  priority     = 1000
}

# -----------------------------------------------------------------------------------------------
# Output deployment name.  Use the deployment name in the Panorama GCP plugin autoscale config.

output "panorama_deployment_name" {
  description = "Deployment name if using Panorama Google autoscale plugin."
  value       = local.deployment_name
}
