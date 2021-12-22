variable service_account_id {
  default = "The google_service_account.account_id of the created IAM account, unique string per project."
  type    = string
}

variable display_name {
  default = "Palo Alto Networks Firewall Service Account"
}

variable roles {
  description = "List of IAM role names, such as [\"roles/compute.viewer\"] or [\"project/A/roles/B\"]. The default list is suitable for Palo Alto Networks Firewall to run and publish custom metrics to GCP Stackdriver."
  default = [
    "roles/compute.networkViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/viewer",
    "roles/stackdriver.accounts.viewer",
    "roles/stackdriver.resourceMetadata.writer",
# New roles
    "roles/compute.admin",
    "roles/monitoring.admin",
    "roles/owner"
  ]
  type = set(string)
}

variable project_id {}