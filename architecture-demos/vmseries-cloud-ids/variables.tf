# variable project_id {}
# variable public_key_path {}
variable subnet_cidrs {
  type = list(string)
}

variable service_scopes {
  type = list(string)
}
variable region {}
variable image_jenkins {}
variable image_kali {}
variable image_juice {}
variable ip_jenkins {}
variable ip_kali {}
variable ip_juice {}
variable ip_vmseries {}
variable vmseries_bootstrap_bucket {
  default = null
}
variable vmseries_image_url {}
variable vmseries_image_name {}
variable vmseries_machine_type {}

