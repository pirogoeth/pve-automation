resource "nomad_variable" "tls-ca-cert" {
  path      = "tls/ca-cert"
  namespace = nomad_namespace.system.id
  items = {
    text = file(var.ca_cert)
  }
}

resource "nomad_variable" "tls-cli-cert" {
  path      = "tls/cli-cert"
  namespace = nomad_namespace.system.id
  items = {
    text = file(var.cli_cert)
  }
}

resource "nomad_variable" "tls-cli-key" {
  path      = "tls/cli-key"
  namespace = nomad_namespace.system.id
  items = {
    text = file(var.cli_key)
  }
}

locals {
  namespaces = [
    nomad_namespace.apps,
    nomad_namespace.continuous_integration,
    # nomad_namespace.csi_drivers,
    nomad_namespace.data,
    nomad_namespace.system,
    nomad_namespace.monitoring,
  ]
}

resource "nomad_variable" "namespaces" {
  path      = "managed-namespaces"
  for_each  = toset([for namespace in local.namespaces : namespace.id])
  namespace = each.value

  items = {
    json = jsonencode([for namespace in local.namespaces : namespace.name])
  }
}

resource "nomad_variable" "prometheus_scrape_configs" {
  path      = "prometheus/scrape-configs"
  namespace = nomad_namespace.monitoring.id

  items = {
    minio-job = jsonencode({
      bearer_token   = var.minio_metrics_bearer_token
      metrics_path   = "/minio/v2/metrics/cluster"
      scheme         = "https"
      static_configs = [{ targets = ["s3.2811rrt.net:443"] }]
    })
  }
}
