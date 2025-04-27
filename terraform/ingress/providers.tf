terraform {
  backend "pg" {}

  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
