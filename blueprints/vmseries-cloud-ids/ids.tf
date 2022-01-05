resource "null_resource" "ids" {
  triggers = {
    network = module.vpc_trust.vpc_id
    zone    = data.google_compute_zones.main.names[0]
    name    = "${local.prefix}-ids-endpoint"
  }

  provisioner "local-exec" {
       # "./myscript add '${self.triggers.thing}'"
    command     = "gcloud alpha ids endpoints create ${self.triggers.name} --network ${self.triggers.network} --zone ${self.triggers.zone} --severity INFORMATIONAL --enable-traffic-logs"
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "gcloud alpha ids endpoints delete ${self.triggers.name} --zone ${self.triggers.zone}"
    working_dir = path.module
  }

  depends_on = [
    google_project_service.service_networking,
    google_project_service.ids,
    google_service_networking_connection.trust
  ]
}