resource "nomad_namespace" "system" {
  name        = "nomad-system"
  description = "System jobs"
}

resource "nomad_job" "traefik" {
  jobspec = file("${local.jobs}/system/traefik.nomad.hcl")

  hcl2 {
    vars = {
      version           = "v3.0.4"
      domain            = var.service_base_domain
      letsencrypt_email = var.letsencrypt_email
    }
  }
}

resource "nomad_job" "cloudflared" {
  jobspec = file("${local.jobs}/system/cloudflared.nomad.hcl")

  hcl2 {
    vars = {
      version = "2024.6.1"
      token   = var.cloudflare_tunnel_token
    }
  }
}
