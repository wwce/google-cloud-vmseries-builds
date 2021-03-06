variable instances {
  description = "Definition of firewalls that will be deployed"
  type        = map(any)
  # Why `any` here: don't use object() because then every element must then have exactly the same nested structure.
  # It thus becomes unwieldy. There can be no optional attributes. Even if there is a non-optional attribute that
  # is a nested list, it needs to have same number of elements for each firewall.
}

variable machine_type {
  description = "Firewall instance machine type, which depends on the license used. See the [Terraform manual](https://www.terraform.io/docs/providers/google/r/compute_instance.html)"
  default     = "n1-standard-4"
  type        = string
}

variable min_cpu_platform {
  default = "Intel Broadwell"
  type    = string
}

variable disk_type {
  description = "Default is pd-ssd, alternative is pd-balanced."
  default     = "pd-ssd"
}

variable bootstrap_bucket {
  default = ""
  type    = string
}

variable ssh_key {
  default = ""
  type    = string
}

variable scopes {
  default = [
    "https://www.googleapis.com/auth/compute.readonly",
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
  type = list(string)
}

variable image_prefix_uri {
  description = "The image URI prefix, by default https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/ string. When prepended to `image_name` it should result in a full valid Google Cloud Engine image resource URI."
  default     = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/"
  type        = string
}

variable image_name {
  description = "The image name from which to boot an instance, including the license type and the version, e.g. vmseries-byol-814, vmseries-bundle1-814, vmseries-flex-bundle2-1001. Default is vmseries-flex-bundle1-913."
  default     = "vmseries-flex-bundle1-913"
  type        = string
}

variable labels {
  default = {}
  type    = map(any)
}

variable tags {
  default = []
  type    = list(string)
}

variable metadata {
  default = {}
  type    = map(string)
}

variable metadata_startup_script {
  description = "See the [Terraform manual](https://www.terraform.io/docs/providers/google/r/compute_instance.html)"
  default     = null
  type        = string
}

variable project {
  default = null
  type    = string
}

variable resource_policies {
  default = []
  type    = list(string)
}

variable create_instance_group {
  default = false
  type    = bool
}

variable named_ports {
  description = <<-EOF
  (Optional) The list of named ports:
  ```
  named_ports = [
    {
      name = "http"
      port = "80"
    },
    {
      name = "app42"
      port = "4242"
    },
  ]
  ```
  The name identifies the backend port to receive the traffic from the global load balancers.
  Practically, tcp port 80 named "http" works even when not defined here, but it's not a documented provider's behavior.
  EOF
  default     = []
}

variable service_account {
  description = "IAM Service Account for running firewall instance (just the email)"
  default     = null
  type        = string
}