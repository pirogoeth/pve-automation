resource "nomad_namespace" "monitoring" {
  name        = "monitoring"
  description = "Application monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${local.jobs}/monitoring/prometheus.nomad.hcl")

  hcl2 {
    vars = {
      version     = "2.48.1"
      volume_name = module.prometheus_data.volume_name
      domain      = var.service_base_domain
    }
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("${local.jobs}/monitoring/grafana.nomad.hcl")

  hcl2 {
    vars = {
      version     = "10.0.10"
      volume_name = module.grafana_data.volume_name
      domain      = var.service_base_domain
    }
  }
}
