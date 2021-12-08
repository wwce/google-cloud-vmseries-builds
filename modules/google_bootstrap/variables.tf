variable "bucket_name" {
}

variable "file_location" {
}

variable "config" {
  type    = list(string)
  default = []
}

variable "content" {
  type    = list(string)
  default = []
}

variable "software" {
  default = []
}

variable "plugins" {
  default = []
}

variable authcodes {
  default = null
}

variable location {
  default = "US"
}