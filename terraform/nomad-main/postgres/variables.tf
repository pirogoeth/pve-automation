variable "postgres_host" { type = string }
variable "postgres_port" { type = number }
variable "postgres_username" { type = string }
variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "managed_roles" {
  description = "List of role description objects"
  type = list(object({
    name  = string
    roles = optional(list(string))
    privileges = optional(object({
      superuser       = optional(bool)
      create_database = optional(bool)
      create_role     = optional(bool)
      inherit         = optional(bool)
      login           = optional(bool)
      replication     = optional(bool)
    }))
    databases = list(object({
      name              = string
      encoding          = optional(string)
      connection_limit  = optional(number)
      allow_connections = optional(bool)
    }))
  }))
}
