output "connection_settings" {
  value = {
    host = var.postgres_host
    port = var.postgres_port
  }
}

output "connection_uri" {
  value = "postgresql://${var.postgres_host}:${var.postgres_port}"
}

locals {
  credentials = { for mr in var.managed_roles : mr.name => random_password.role_password[mr.name].result }
}

output "credentials" {
  value     = local.credentials
  sensitive = true
}

output "application_connection_uri" {
  value = {
    for mr in var.managed_roles :
    mr.name => "postgresql://${mr.name}:${local.credentials[mr.name]}@${var.postgres_host}:${var.postgres_port}"
  }
  sensitive = true
}
