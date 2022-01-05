output "vpc_name" {
  value = google_compute_network.main.*.name[0]
}

output "vpc_id" {
  value = google_compute_network.main.*.id[0]
}

output "vpc_self_link" {
  value = google_compute_network.main.*.self_link[0]
}

output "subnet_self_link" {

   value = tomap({
    for k, b in google_compute_subnetwork.main : k => b.self_link
  })
}
