terraform {
  required_version = ">= 1.8"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.46"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
