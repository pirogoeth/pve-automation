variable "id" {
  type = string
}

variable "name" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "nfs_host" {
  type = string
}

variable "nfs_share" {
  type = string
}

variable "access_modes" {
  type    = list(string)
  default = ["multi-node-multi-writer"]
}
