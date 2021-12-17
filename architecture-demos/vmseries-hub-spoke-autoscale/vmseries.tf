# -----------------------------------------------------------------------------------------------
# Create IAM service account for the VM-Series to publish metrics to stack driver
module "iam_service_account" {
  source = "../../modules/panw_iam_service_account/"

  project_id         = data.google_client_config.main.project
  service_account_id = "${local.prefix}-panw-service-account"
}

#-----------------------------------------------------------------------------------------------
# Create a managed instance group with the VM-Series (autoscaling)

module "autoscale" {
  source = "../../modules/vmseries_managed_ig/"

  project_id = data.google_client_config.main.project

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
  nic0_public_ip        = false
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

#-----------------------------------------------------------------------------------------------
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

resource "google_compute_route" "internal_lb" {
  name         = "${local.prefix}-route"
  dest_range   = "0.0.0.0/0"
  network      = module.vpc_trust.vpc_id
  next_hop_ilb = module.intlb.forwarding_rule
  priority     = 1000
}
