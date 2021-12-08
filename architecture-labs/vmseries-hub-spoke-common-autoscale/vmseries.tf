# -----------------------------------------------------------------------------------------------
module "iam_service_account" {
  source = "./modules/iam_service_account/"

  project_id         = var.project_id
  service_account_id = "${local.prefix}-panw-service-account"
}

#-----------------------------------------------------------------------------------------------
# Firewalls with auto-scaling.

module "autoscale" {
  source = "../modules/autoscale/"

  project_id = var.project_id

  zones = {
    zone1 = data.google_compute_zones.main.names[0]
    zone2 = data.google_compute_zones.main.names[1]
  }

  subnetworks = [
    module.vpc_untrust.subnet_self_link["untrust-${var.region}"],
    module.vpc_mgmt.subnet_self_link["mgmt-${var.region}"],
    module.vpc_trust.subnet_self_link["trust-${var.region}"]
  ]
  
  prefix                = "${local.prefix}-vmseries"
  deployment_name       = "${local.prefix}-vmseries-deployment"
  machine_type          = var.fw_machine_type
  ssh_key               = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  image                 = var.fw_image_uri
  nic0_public_ip        = true
  nic1_public_ip        = true
  nic2_public_ip        = false
  pool                  = module.extlb.target_pool
  scopes                = ["https://www.googleapis.com/auth/cloud-platform"]
  service_account       = module.iam_service_account.email
  min_replicas_per_zone = 1
  max_replicas_per_zone = 2
  autoscaler_metrics    = var.autoscaler_metrics
  named_ports = [
    {
      name = "http"
      port = "80"
    }
  ]

  # metadata = {
  #   type                                 = "dhcp-client"
  #   op-command-modes                     = "mgmt-interface-swap"
  #   vm-auth-key                          = "289932414614775"
  #   panorama-server                      = "74.97.22.10"
  #   dgname                               = "gcp-autoscale"
  #   tplname                              = "gcp-autoscale_stack"
  #   dhcp-send-hostname                   = "yes"
  #   dhcp-send-client-id                  = "yes"
  #   dhcp-accept-server-hostname          = "yes"
  #   dhcp-accept-server-domain            = "yes"
  # }
  
  metadata = {
    type                                 = "dhcp-client"
    op-command-modes                     = "mgmt-interface-swap"
    vm-auth-key                          = var.panorama_vm_auth_key
    panorama-server                      = var.panorama_address
    dgname                               = var.panorama_device_group
    tplname                              = var.panorama_template_stack
    dhcp-send-hostname                   = "yes"
    dhcp-send-client-id                  = "yes"
    dhcp-accept-server-hostname          = "yes"
    dhcp-accept-server-domain            = "yes"
  }

  # Example of bootstrap via Google storage bucket (full boostrap with dynamic content installed)
  # metadata = {
  #   mgmt-interface-swap                  = "enable"
  #   vmseries-bootstrap-gce-storagebucket = "my-google-bootstrap-bucket"
  #   serial-port-enable                   = true
  #   ssh-keys                             = "~/.ssh/vmseries-ssh-key.pub"
  # }
}

#-----------------------------------------------------------------------------------------------
# Regional Internal TCP Load Balancer
#
# It is not strictly required part of this example.
# It's here just to show how to integrate it with auto-scaling.

module "intlb" {
  source = "./modules/lb_tcp_internal/"

  name       = "${local.prefix}-intlb"
  network    = module.vpc_trust.vpc_self_link
  subnetwork = module.vpc_trust.subnet_self_link["trust-${var.region}"]
  all_ports  = true
  backends   = module.autoscale.backends

  allow_global_access = true
}

#-----------------------------------------------------------------------------------------------
# Regional External TCP Network Load Balancer
#
# It is not strictly required part of this example.
# It's here just to show how to integrate it with auto-scaling.

module "extlb" {
  source = "./modules/lb_tcp_external/"

  name  = "${local.prefix}-extlb"
  rules = { 
      ("rule0") = { 
          port_range = 80 
      },
      ("rule1") = { 
          port_range = 221 
      },
      ("rule2") = { 
          port_range = 222 
      }   
  }

  health_check_http_port         = 80
  health_check_http_request_path = "/"
}



resource "google_compute_route" "internal_lb" {
  name         = "${local.prefix}-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_trust.vpc_id
  next_hop_ilb = module.intlb.forwarding_rule
  priority     = 1000
}

# -----------------------------------------------------------------------------------------------
# Cloud Nat for the management interfaces.
# Needed to reach bootstrap bucket or to log to Cortex DataLake.
# module "mgmt_cloud_nat" {
#   source  = "terraform-google-modules/cloud-nat/google"
#   version = "=1.2"

#   name          = "mgmt"
#   project_id    = "gcp-gcs-pso" # FIXME vars? other module?
#   region        = "europe-west4"
#   create_router = true
#   router        = "mgmt"
#   network       = var.mgmt_network
# }
