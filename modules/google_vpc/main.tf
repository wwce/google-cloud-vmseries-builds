resource "google_compute_network" "main" {
  name                            = var.vpc
  delete_default_routes_on_create = var.delete_default_route
  auto_create_subnetworks         = false
}


resource "google_compute_firewall" "main" {
  count         = length(var.allowed_sources) != 0 ? 1 : 0
  name          = "${google_compute_network.main.name}-ingress"
  network       = google_compute_network.main.self_link
  direction     = "INGRESS"
  source_ranges = var.allowed_sources

  allow {
    protocol = var.allowed_protocol
    ports    = var.allowed_ports
  }
}


resource "google_compute_subnetwork" "main" {
  for_each = var.subnets

  name = format("%s", "${each.key}")
  network       = google_compute_network.main.self_link
  region        = each.value["region"]
  ip_cidr_range = each.value["cidr"]

}


