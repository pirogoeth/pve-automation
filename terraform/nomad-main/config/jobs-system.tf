resource "nomad_namespace" "system" {
  name        = "nomad-system"
  description = "System jobs"
}

resource "nomad_job" "traefik" {
  jobspec = file("${local.jobs}/system/traefik.nomad.hcl")

  hcl2 {
    vars = {
      version           = "v2.10.7"
      domain            = var.service_base_domain
      letsencrypt_email = var.letsencrypt_email
    }
  }
}

resource "nomad_job" "cloudflared" {
  jobspec = file("${local.jobs}/system/cloudflared.nomad.hcl")

  hcl2 {
    vars = {
      version = "2024.1.4"
      token   = var.cloudflare_tunnel_token
    }
  }
}
