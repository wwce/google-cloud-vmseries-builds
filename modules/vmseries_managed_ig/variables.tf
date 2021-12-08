variable prefix {
  description = "Prefix to various GCP resource names"
  type        = string
}

variable project_id {
  default = null
}
variable subnetworks {
  type = list(string)
}

variable machine_type {
  type = string
}

variable region {
  description = "GCP region to deploy to, if not set the default provider region is used."
  default     = null
  type        = string
}

variable zones {
  description = "Map of zone names for the zonal IGMs"
  default     = {}
  type        = map(string)
}

variable deployment_name {
  description = "Deployment Name that matches what is specified in Panorama GCP Plugin"
  type        = string
}

variable min_cpu_platform {
  type    = string
  default = "Intel Broadwell"
}

variable disk_type {
  type    = string
  default = "pd-ssd"
}


variable ssh_key {
  type    = string
  default = ""
}

variable scopes {
  type = list(string)

  default = [
    "https://www.googleapis.com/auth/compute.readonly",
    "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}

variable image {
  description = "Link to VM-Series PAN-OS image. Can be either a full self_link, or one of the shortened forms per the [provider doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#image)."
  default     = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-byol-912"
  type        = string
}

variable tags {
  type    = list(string)
  default = []
}
variable nic0_ip {
  type    = list(string)
  default = [""]
}

variable nic1_ip {
  type    = list(string)
  default = [""]
}

variable nic2_ip {
  type    = list(string)
  default = [""]
}

variable nic0_public_ip {
  type    = bool
  default = false
}

variable nic1_public_ip {
  type    = bool
  default = false
}

variable nic2_public_ip {
  type    = bool
  default = false
}

variable pool {
  description = "The self_link of google_compute_target_pool where the auto-created instances will be placed for healtchecking of External Load Balancer"
  default     = null
  type        = string
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
    "custom.googleapis.com/VMSeries/panSessionUtilization" = {
      target = 70
    }
    "custom.googleapis.com/VMSeries/panSessionThroughputKbps" = {
      target = 700000
    }
  }
}

variable max_replicas_per_zone {
  description = "Maximum number of VM-series instances per *each* of the zones"
  default     = 1
  type        = number
}

variable min_replicas_per_zone {
  description = "Minimum number of VM-series instances per *each* of the zones"
  default     = 1
  type        = number
}

variable cooldown_period {
  description = "How much tame does it take for a spawned PA-VM to become functional on the initialization boot"
  default     = 720
  type        = number
}

variable scale_in_control_time_window_sec {
  description = <<-EOF
  How many seconds autoscaling should look into the past when scaling in (down).
  Default 30 minutes corresponds to the default custom metrics period of 5 minutes
  and also to the considerable init time of a fresh instance.
  EOF
  default     = 1800
  type        = number
}

variable scale_in_control_replicas_fixed {
  description = <<-EOF
  Fixed number of VM instances that can be killed in each zone within the scale-in time window.
  See `scale_in_control` in the [provider doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler).
  EOF
  default     = 1
  type        = number
}

variable update_policy_min_ready_sec {
  description = <<-EOF
  After underlying template changes (e.g. PAN-OS upgrade) and the new instance is being spawned,
  how long to wait after it becomes online.
  See `update_policy` in the [provider doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager)."
  EOF
  default     = 720
  type        = number
}

variable update_policy_type {
  description = <<-EOF
  What to do when the underlying template changes (e.g. PAN-OS upgrade).
  OPPORTUNISTIC is the only recommended value. Also PROACTIVE is allowed: it immediately
  starts to re-create/delete instances and since this is not coordinated with
  the instance group manager in other zone, it can easily lead to total outage.
  It is thus feasible only in dev environments. Real environments should
  perform a "Rolling Update" in GCP web interface.
  EOF
  default     = "OPPORTUNISTIC"
  type        = string
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
  EOF
  default     = []
}

variable service_account {
  description = "IAM Service Account for running firewall instance (just the email)"
  default     = null
  type        = string
}

variable metadata {
  description = "Metadata for VM-Series firewall.  Commented examples below show two examples: 1. partial bootstrap to Panorama 2. Full configuration bootstrap from Google storage bucket."
  default     = {}
  type        = map(string)

  /* 

  # Partial Bootstrap to Panorama (no dynamic content installed on bootup)

  default = {
    type                                 = "dhcp-client"
    op-command-modes                     = "mgmt-interface-swap"
    vm-auth-key                          = "289932414614775"
    panorama-server                      = "74.97.22.10"
    dgname                               = "gcp-autoscale"
    tplname                              = "gcp-autoscale_stack"
    dhcp-send-hostname                   = "yes"
    dhcp-send-client-id                  = "yes"
    dhcp-accept-server-hostname          = "yes"
    dhcp-accept-server-domain            = "yes"
  }

  # Full bootstrap to using Google storage bucket example

  default = {
    mgmt-interface-swap                  = "enable"
    vmseries-bootstrap-gce-storagebucket = "my-google-bootstrap-bucket"
    serial-port-enable                   = true
    ssh-keys                             = "~/.ssh/vmseries-ssh-key.pub"
  }

  */
}
