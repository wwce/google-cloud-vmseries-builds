
# -----------------------------------------------------------------------------------
# Kali Linux VM
resource "google_compute_instance" "kali" {
  name         = "${local.prefix}-kali"
  machine_type = "n1-standard-1"
  zone         = data.google_compute_zones.main.names[0]
  tags         = ["kali"]
  boot_disk {
    initialize_params {
      image = var.image_kali
    }
  }
  network_interface {
    subnetwork = module.vpc_trust.subnet_self_link["${var.region}-trust-subnet"]
    network_ip = var.ip_kali
  }
  service_account {
    scopes = var.service_scopes
  }
}


# -----------------------------------------------------------------------------------
# Jenkins VM
resource "google_compute_instance" "jenkins" {
  name         = "${local.prefix}-jenkins"
  machine_type = "n1-standard-1"
  zone         = data.google_compute_zones.main.names[0]
  tags         = ["jenkins"]
  boot_disk {
    initialize_params {
      image = var.image_jenkins
    }
  }
  network_interface {
    subnetwork = module.vpc_trust.subnet_self_link["${var.region}-trust-subnet"]
    network_ip = var.ip_jenkins
  }
  service_account {
    scopes = var.service_scopes
  }
}

# -----------------------------------------------------------------------------------
# Juice Shop VM
resource "google_compute_instance" "juice_shop" {
  name         = "${local.prefix}-juice-shop"
  machine_type = "n1-standard-1"
  zone         = data.google_compute_zones.main.names[0]
  tags         = ["juice-shop"]
  boot_disk {
    initialize_params {
      image = var.image_juice
    }
  }
  network_interface {
    subnetwork = module.vpc_trust.subnet_self_link["${var.region}-trust-subnet"]
    network_ip = var.ip_juice
  }
  service_account {
    scopes = var.service_scopes
  }
}


# -----------------------------------------------------------------------------------
# Create bootstrap bucket for VM-Series and create VM-Series firewalls. \
module "vmseries" {
  source = "./modules/vmseries/"
  image_prefix_uri      = var.vmseries_image_url
  image_name            = var.vmseries_image_name
  machine_type          = var.vmseries_machine_type
  create_instance_group = true
  #project               = var.project_id
  #ssh_key               = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  
  instances = {

    vmseries01 = {
      name             = "${local.prefix}-vmseries01"
      zone             = data.google_compute_zones.main.names[0]
      bootstrap_bucket = "" #var.vmseries_bootstrap_bucket
      network_interfaces = [
        {
          subnetwork = module.vpc_untrust.subnet_self_link["${var.region}-untrust-subnet"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_mgmt.subnet_self_link["${var.region}-mgmt-subnet"]
          public_nat = true
        },
        {
          subnetwork = module.vpc_trust.subnet_self_link["${var.region}-trust-subnet"]
          public_nat = false
          network_ip = var.ip_vmseries
        }
      ]
    }
  }

  depends_on = [
    google_compute_instance.kali,
    google_compute_instance.juice_shop,
    google_compute_instance.jenkins
  ]
}