terraform {
  required_providers {
    null   = { version = "~> 2.1" }
    google = { version = "~> 3.30" }
  }
}

resource "google_compute_instance" "main" {
  for_each = var.instances

  name                      = each.value.name
  zone                      = each.value.zone
  machine_type              = var.machine_type
  min_cpu_platform          = var.min_cpu_platform
  labels                    = var.labels
  tags                      = var.tags
  metadata_startup_script   = var.metadata_startup_script
  project                   = var.project_id
  resource_policies         = var.resource_policies
  can_ip_forward            = true
  allow_stopping_for_update = true

  metadata = var.metadata

  service_account {
    email  = var.service_account
    scopes = var.scopes
  }

  dynamic "network_interface" {
    for_each = each.value.network_interfaces

    content {
      network_ip = local.dyn_interfaces[each.key][network_interface.key].network_ip
      subnetwork = network_interface.value.subnetwork

      dynamic "access_config" {
        # The "access_config", if present, creates a public IP address. Currently GCE only supports one, hence "one".
        for_each = try(network_interface.value.public_nat, false) ? ["one"] : []
        content {
          nat_ip                 = local.dyn_interfaces[each.key][network_interface.key].nat_ip
          public_ptr_domain_name = local.dyn_interfaces[each.key][network_interface.key].public_ptr_domain_name
        }
      }

      dynamic "alias_ip_range" {
        for_each = try(network_interface.value.alias_ip_range, [])
        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = try(alias_ip_range.value.subnetwork_range_name, null)
        }
      }
    }
  }

  boot_disk {
    initialize_params {
      image = "${var.image_prefix_uri}${var.image_name}"
      type  = var.disk_type
    }
  }

  depends_on = []
}

// The Deployment Guide Jan 2020 recommends per-zone instance groups (instead of regional IGMs).
resource "google_compute_instance_group" "main" {
  for_each = var.create_instance_group ? var.instances : {}

  name      = "${each.value.name}-${each.value.zone}-ig"
  zone      = each.value.zone
  project   = var.project_id
  instances = [google_compute_instance.main[each.key].self_link]

  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
}