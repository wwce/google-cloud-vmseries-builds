variable "vpc" {
}

variable "subnet_names" {
  type    = list(string)
  default = null
}

variable "allowed_sources" {
  type    = list(string)
  default = []
}

variable "allowed_protocol" {
  default = "all"
}

variable "allowed_ports" {
  type    = list(string)
  default = []
}

variable "delete_default_route" {
  default = "false"
}


variable "subnets" {
  type        = map(map(any))
  default     = {}
}