variable "project_id" {
  description = "GCP project ID"
  default     = null
}

variable "region" {}
variable "fw_machine_type" {}

variable "fw_image_name" {
  description = "The image name from which to boot an instance, including the license type and the version, e.g. vmseries-byol-814, vmseries-bundle1-814, vmseries-flex-bundle2-1001. Default is vmseries-flex-bundle1-913."
  default     = "vmseries-flex-bundle1-1010"
  type        = string
}

variable "mgmt_sources" {
  type = list(string)
}

variable "cidr_mgmt" {}
variable "cidr_untrust" {}
variable "cidr_trust" {}

variable "public_key_path" {
  description = "Local path to public SSH key.  If you do not have a public key, run >> ssh-keygen -f ~/.ssh/demo-key -t rsa -C admin"
}

# variable "auth_file" {
#   description = "GCP Project auth file"
#   default     = null
# }
