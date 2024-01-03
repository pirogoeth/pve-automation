resource "nomad_namespace" "apps" {
  name        = "apps"
  description = "Apps"
}

resource "random_string" "miniflux_admin_password" {
  length  = 12
  special = true
}

resource "nomad_job" "miniflux" {
  depends_on = [module.miniflux_data]
  jobspec    = file("${local.jobs}/apps/miniflux.nomad.hcl")

  hcl2 {
    vars = {
      admin_username = "sean"
      admin_password = random_string.miniflux_admin_password.result
      domain         = var.service_base_domain
      version        = "2.0.51"
      volume_name    = module.miniflux_data.volume_name
    }
  }
}

resource "nomad_job" "n8n" {
  depends_on = [
    module.n8n_data,
    module.n8n_local_files,
  ]
  jobspec = file("${local.jobs}/apps/n8n.nomad.hcl")

  hcl2 {
    vars = {
      domain                  = var.service_base_domain
      version                 = "1.22.3"
      volume_name_data        = module.n8n_data.volume_name
      volume_name_local_files = module.n8n_local_files.volume_name
      webhook_url             = var.n8n_webhook_url
    }
  }
}
