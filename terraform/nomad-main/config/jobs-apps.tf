resource "nomad_namespace" "apps" {
  name        = "apps"
  description = "Apps"
}

resource "random_string" "miniflux_admin_password" {
  length  = 12
  special = true
}

resource "nomad_job" "miniflux" {
  jobspec = file("${local.jobs}/apps/miniflux.nomad.hcl")

  hcl2 {
    vars = {
      admin_username = "sean"
      admin_password = random_string.miniflux_admin_password.result
      domain         = var.service_base_domain
      version        = "2.0.51"
    }
  }
}

resource "nomad_job" "n8n" {
  jobspec = file("${local.jobs}/apps/n8n.nomad.hcl")

  hcl2 {
    vars = {
      domain  = var.service_base_domain
      version = "1.48.0"
    }
  }
}

resource "nomad_job" "coder" {
  jobspec = file("${local.jobs}/apps/coder.nomad.hcl")

  hcl2 {
    vars = {
      version = "2.7.0"
      domain  = var.service_base_domain
    }
  }
}

# resource "nomad_job" "whishper" {
#   jobspec = file("${local.jobs}/apps/whishper.nomad.hcl")
# 
#   hcl2 {
#     vars = {
#       version             = "latest-gpu"
#       domain              = var.service_base_domain
#       mongodb_version     = "6"
#       volume_name_data    = module.whishper_data.volume_name
#       volume_name_db_data = module.whishper_db_data.volume_name
#     }
#   }
# }

resource "nomad_job" "windmill" {
  jobspec = file("${local.jobs}/apps/windmill.nomad.hcl")

  hcl2 {
    vars = {
      version          = ""
      domain           = var.service_base_domain
      postgres_version = "16"
    }
  }
}

resource "nomad_job" "localai" {
  jobspec = file("${local.jobs}/apps/localai.nomad.hcl")

  hcl2 {
    vars = {
      version = "latest"
      domain  = var.service_base_domain
    }
  }
}

# resource "nomad_job" "clusterplex" {
#   jobspec = file("${local.jobs}/apps/clusterplex.nomad.hcl")

#   hcl2 {
#     vars = {
#       version               = "latest"
#       domain                = var.service_base_domain
#       volume_name_downloads = module.nas_downloads_share.volume_id
#       volume_name_plex_data = module.nas_plex_data_share.volume_id
#     }
#   }

#   depends_on = [
#     module.nas_downloads_share,
#     module.nas_plex_data_share,
#   ]
# }

resource "nomad_job" "plex" {
  jobspec = file("${local.jobs}/apps/plex.nomad.hcl")

  hcl2 {
    vars = {
      version               = "latest"
      domain                = var.service_base_domain
      volume_name_downloads = module.nas_downloads_share.volume_id
      volume_name_plex_data = module.nas_plex_data_share.volume_id
    }
  }

  depends_on = [
    module.nas_downloads_share,
    module.nas_plex_data_share,
  ]
}
