# --------------------------------------------------------------------------------------------------------------------------
# Create spoke1 compute instances

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
    network_ip = cidrhost(var.cidr_spoke1, 10)
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

# --------------------------------------------------------------------------------------------------------------------------
# Create spoke2 compute instances

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
