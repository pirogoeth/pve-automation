terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 2.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "nomad" {
  address     = var.nomad_url
  ca_file     = var.ca_cert
  cert_file   = var.cli_cert
  key_file    = var.cli_key
  skip_verify = var.tls_skip_verify
  secret_id   = var.secret_id
}

provider "minio" {
  minio_server   = "s3.2811rrt.net"
  minio_user     = nomad_job.minio.hcl2[0].vars.root_username
  minio_password = nomad_job.minio.hcl2[0].vars.root_password
  minio_ssl      = true
}
