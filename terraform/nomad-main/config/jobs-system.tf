resource "nomad_namespace" "system" {
  name        = "nomad-system"
  description = "System jobs"
}

resource "nomad_job" "traefik" {
  jobspec = file("${local.jobs}/system/traefik.nomad.hcl")

  hcl2 {
    vars = {
      version           = local.traefik_version
      domain            = var.service_base_domain
      letsencrypt_email = var.letsencrypt_email
    }
  }
}

resource "nomad_job" "cloudflared" {
  jobspec = file("${local.jobs}/system/cloudflared.nomad.hcl")

  hcl2 {
    vars = {
      version = local.cloudflared_version
      token   = var.cloudflare_tunnel_token
    }
  }
}
