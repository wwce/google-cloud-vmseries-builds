# --------------------------------------------------------------------------------------------------------------------------
# Creates Ubuntu GCE instances.  These instances are used for testing purposes.

resource "google_compute_instance" "region0_spoke1" {
  name                      = "${local.prefix_region0}-spoke1-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region0.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.regions[0]}"]
    network_ip = cidrhost(var.cidrs_spoke1[0], 10)
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


resource "google_compute_instance" "region1_spoke1" {
  name                      = "${local.prefix_region1}-spoke1-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region1.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke1.subnet_self_link["spoke1-${var.regions[1]}"]
    network_ip = cidrhost(var.cidrs_spoke1[1], 10)
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


resource "google_compute_instance" "region0_spoke2" {
  name                      = "${local.prefix_region0}-spoke2-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region0.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke2.subnet_self_link["spoke2-${var.regions[0]}"]
    network_ip = cidrhost(var.cidrs_spoke2[0], 10)
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


resource "google_compute_instance" "region1_spoke2" {
  name                      = "${local.prefix_region1}-spoke2-vm"
  machine_type              = var.vm_type
  zone                      = data.google_compute_zones.region1.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "${var.vm_user}:${file(var.public_key_path)}" : ""
  }

  network_interface {
    subnetwork = module.vpc_spoke2.subnet_self_link["spoke2-${var.regions[1]}"]
    network_ip = cidrhost(var.cidrs_spoke2[1], 10)
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
