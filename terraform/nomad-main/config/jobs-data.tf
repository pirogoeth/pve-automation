resource "nomad_namespace" "data" {
  name        = "data"
  description = "Data collection/processing workloads"
}

resource "nomad_job" "changedetection" {
  jobspec = file("${local.jobs}/data/changedetection.nomad.hcl")

  hcl2 {
    vars = {
      namespace = nomad_namespace.data.name
      version   = local.changedetectionio_version
      domain    = var.service_base_domain
    }
  }
}
