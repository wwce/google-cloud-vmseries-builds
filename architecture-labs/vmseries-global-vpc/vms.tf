# --------------------------------------------------------------------------------------------------------------------------
# Creates 2 Ubuntu GCE instances.  These instances are used for testing purposes.

variable vm_image {
  default = "ubuntu-os-cloud/ubuntu-1604-lts"
}

variable vm_type {
  default = "f1-micro"
}

variable vm_user {}

variable vm_scopes {
  type = list(string)

  default = [
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}


resource "google_compute_instance" "region0" {
  name                      = "${local.prefix_region0}-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region0.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_trust.subnet_self_link["trust-${var.regions[0]}"]
    network_ip = cidrhost(var.cidrs_trust[0], 10)
  }

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  service_account {
    scopes = var.vm_scopes
  }

  tags = ["${var.regions[0]}-fw"]
}


resource "google_compute_instance" "region1" {
  name                      = "${local.prefix_region1}-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region1.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_trust.subnet_self_link["trust-${var.regions[1]}"]
    network_ip = cidrhost(var.cidrs_trust[1], 10)
  }

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  service_account {
    scopes = var.vm_scopes
  }

  tags = ["${var.regions[1]}-fw"]
}