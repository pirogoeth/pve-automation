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

variable "capacity" {
  type = object({
    min = string
    max = optional(string)
  })
}

variable "access_mode" {
  type    = string
  default = "single-node-writer"
}
