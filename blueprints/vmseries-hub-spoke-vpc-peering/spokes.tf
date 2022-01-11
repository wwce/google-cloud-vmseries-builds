# --------------------------------------------------------------------------------------------------------------------------
# Create spoke VPC networks

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


# --------------------------------------------------------------------------------------------------------------------------
# Create VPC peering connections between spoke networks and the trust network

resource "google_compute_network_peering" "spoke1_to_trust" {
  name                 = "${local.prefix}-spoke1-to-trust"
  network              = module.vpc_spoke1.vpc_id
  peer_network         = module.vpc_trust.vpc_id
  import_custom_routes = true
  export_custom_routes = false
}

resource "google_compute_network_peering" "trust_to_spoke1" {
  name                 = "${local.prefix}-trust-to-spoke1"
  network              = module.vpc_trust.vpc_id
  peer_network         = module.vpc_spoke1.vpc_id
  import_custom_routes = false
  export_custom_routes = true
}


resource "google_compute_network_peering" "spoke2_to_trust" {
  name                 = "${local.prefix}-spoke2-to-trust"
  network              = module.vpc_spoke2.vpc_id
  peer_network         = module.vpc_trust.vpc_id
  import_custom_routes = true
  export_custom_routes = false
}

resource "google_compute_network_peering" "trust_to_spoke2" {
  name                 = "${local.prefix}-trust-to-spoke2"
  network              = module.vpc_trust.vpc_id
  peer_network         = module.vpc_spoke2.vpc_id
  import_custom_routes = false
  export_custom_routes = true
}


# --------------------------------------------------------------------------------------------------------------------------
# Create spoke1 compute instances with internal load balancer

resource "google_compute_instance" "spoke1_vm1" {
  name                      = "${local.prefix}-spoke1-vm1"
  machine_type              = var.spoke_vm_type
  zone                      = data.google_compute_zones.main.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.spoke_vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
  }

  boot_disk {
    initialize_params {
      image = var.spoke_vm_image
    }
  }

  service_account {
    scopes = var.spoke_vm_scopes
  }
}

resource "google_compute_instance" "spoke1_vm2" {
  name                      = "${local.prefix}-spoke1-vm2"
  machine_type              = var.spoke_vm_type
  zone                      = data.google_compute_zones.main.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.spoke_vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
  }

  boot_disk {
    initialize_params {
      image = var.spoke_vm_image
    }
  }

  service_account {
    scopes = var.spoke_vm_scopes
  }
}


resource "google_compute_instance_group" "spoke1_lb" {
  name = "${local.prefix}-ig-spoke1"
  zone = data.google_compute_zones.main.names[0]

  instances = [
    google_compute_instance.spoke1_vm1.id,
    google_compute_instance.spoke1_vm2.id
  ]
}

resource "google_compute_health_check" "spoke1_lb" {
  name = "${local.prefix}-hc-tcp80-spoke1"

  tcp_health_check {
    port = 80
  }
}

resource "google_compute_region_backend_service" "spoke1_lb" {
  name          = "${local.prefix}-backend-spoke1"
  region        = var.region
  health_checks = [google_compute_health_check.spoke1_lb.id]
  network       = module.vpc_spoke1.vpc_id

  backend {
    group = google_compute_instance_group.spoke1_lb.id
  }
}

resource "google_compute_forwarding_rule" "spoke1_lb" {
  name                  = "${local.prefix}-internal-lb-spoke1"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.spoke1_lb.id
  ip_address            = cidrhost(var.cidr_spoke1, 10)
  ip_protocol           = "TCP"
  ports                 = ["80"]
  network               = module.vpc_spoke1.vpc_id
  subnetwork            = module.vpc_spoke1.subnet_self_link["spoke1-${var.region}"]
  allow_global_access   = true
}


# --------------------------------------------------------------------------------------------------------------------------
# Create spoke2 compute instances. 

resource "google_compute_instance" "spoke2_vm2" {
  name                      = "${local.prefix}-spoke2-vm1"
  machine_type              = var.spoke_vm_type
  zone                      = data.google_compute_zones.main.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.spoke_vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke2.subnet_self_link["spoke2-${var.region}"]
    network_ip = cidrhost(var.cidr_spoke2, 10)
  }

  boot_disk {
    initialize_params {
      image = var.spoke_vm_image
    }
  }

  service_account {
    scopes = var.spoke_vm_scopes
  }
}
