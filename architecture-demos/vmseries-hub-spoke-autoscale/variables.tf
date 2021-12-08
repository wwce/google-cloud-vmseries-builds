variable project_id {
  description = "GCP project ID"
}

variable auth_file {
  description = "GCP Project auth file"
  default     = null
}

variable region {
  description = "Google Cloud region to host the deployment"
}
variable public_key_path {
  description = "Local path to public SSH key. To generate the key pair use `ssh-keygen -t rsa -C admin -N '' -f id_rsa`  If you do not have a public key, run `ssh-keygen -f ~/.ssh/demo-key -t rsa -C admin`"
  default     = "id_rsa.pub"
}

variable fw_image_uri {
  description = "Link to VM-Series PAN-OS image. Can be either a full self_link, or one of the shortened forms per the [provider doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#image)."
  default     = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-byol-912"
  type        = string
}

variable fw_machine_type {
  default = "n1-standard-4"
}

variable extlb_healthcheck_port {
  type    = number
  default = 80
}

variable autoscaler_metrics {
  description = <<-EOF
  The map with the keys being metrics identifiers (e.g. custom.googleapis.com/VMSeries/panSessionUtilization).
  Each of the contained objects has attribute `target` which is a numerical threshold for a scale-out or a scale-in.
  Each zonal group grows until it satisfies all the targets.

  Additional optional attribute `type` defines the metric as either `GAUGE` (the default), `DELTA_PER_SECOND`, or `DELTA_PER_MINUTE`.
  For full specification, see the `metric` inside the [provider doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler).
  EOF
  default = {
    "custom.googleapis.com/VMSeries/panSessionActive" = {
      target = 100
    }
  }
}

variable fw_service_account_name {
  description = "IAM Service Account for running firewall instances (just the identifier, without `@domain` part)"
  type        = string
}


variable mgmt_sources {
  description = "Source IPs to access the VM-Series management interfaces."
  type = list(string)
}

variable cidrs_mgmt {
  description = "Management VPC subnet CIDR ranges.  Enter multiple CIDRs in string notation."
}
variable cidrs_untrust {
  description = "Untrust VPC subnet CIDR ranges.  Enter multiple CIDRs in string notation."
}
variable cidrs_trust {
  description = "Trust VPC subnet CIDR ranges.  Enter multiple CIDRS in string notation."
}


variable cidr_spoke1 {
    description = "Spoke1 VPC subnet CIDR ranges.  Enter multiple CIDRS in string notation."
}
variable cidr_spoke2 {
    description = "Spoke2 VPC subnet CIDR ranges.  Enter multiple CIDRS in string notation."
}
variable spoke_vm_type {
    description = "The GCE instance type."
}


variable spoke_vm_image {
  description = "The VM image for the spoke GCE instances."
}
variable spoke_vm_user {}

variable spoke_vm_scopes {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}


variable roles {
  description = "List of IAM role names, such as [\"roles/compute.viewer\"] or [\"project/A/roles/B\"]. The default list is suitable for Palo Alto Networks Firewall to run and publish custom metrics to GCP Stackdriver."
  default = [
    "roles/compute.networkViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/viewer", # to reach a bootstrap bucket (project's storage.buckets.list with bucket's roles/storage.objectViewer insufficient)
    # per https://docs.paloaltonetworks.com/vm-series/9-1/vm-series-deployment/set-up-the-vm-series-firewall-on-google-cloud-platform/deploy-vm-series-on-gcp/enable-google-stackdriver-monitoring-on-the-vm-series-firewall.html
    "roles/stackdriver.accounts.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ]
  type = set(string)
}


variable panorama_vm_auth_key {
  description = "Panorama VM authorization key.  To generate, follow this guide https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/bootstrap-the-vm-series-firewall/generate-the-vm-auth-key-on-panorama.html"
}

variable panorama_address {
  description = <<-EOF
  The Panorama IP/Domain address.  The Panorama address must be reachable from the management VPC.  
  This build assumes Panorama is reachable via the internet. The management VPC network uses a 
  NAT gateway to communicate to Panorama's external IP addresses.
  EOF
}

variable panorama_device_group {
  description = "The name of the Panorama device group that will bootstrap the VM-Series firewalls."
}

variable panorama_template_stack {
  description = "The name of the Panorama template stack that will bootstrap the VM-Series firewalls."
}