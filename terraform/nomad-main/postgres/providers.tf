terraform {
  backend "pg" {}

  required_version = "~> 1.8"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}

provider "postgresql" {
  # Configuration options
  host     = var.postgres_host
  port     = var.postgres_port
  username = var.postgres_username
  password = var.postgres_password
  sslmode  = "require"
}
