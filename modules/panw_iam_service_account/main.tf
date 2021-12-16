terraform {
  required_providers {
    google = { version = "~> 3.30" }
  }
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.display_name
}

resource "google_project_iam_member" "this" {
  for_each = var.roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.this.email}"
}