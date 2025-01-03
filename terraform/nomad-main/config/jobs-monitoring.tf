resource "nomad_namespace" "monitoring" {
  name        = "monitoring"
  description = "Application monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${local.jobs}/monitoring/prometheus.nomad.hcl")

  hcl2 {
    vars = {
      version = local.prometheus_version
      domain  = var.service_base_domain
    }
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("${local.jobs}/monitoring/grafana.nomad.hcl")

  hcl2 {
    vars = {
      version = local.grafana_version
      domain  = var.service_base_domain
    }
  }
}

resource "nomad_job" "loki" {
  jobspec = file("${local.jobs}/monitoring/loki.nomad.hcl")

  hcl2 {
    vars = {
      version              = local.loki_version
      s3_endpoint_url      = var.minio_server
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.bucket["loki"].bucket
      s3_access_key_id     = minio_iam_service_account.user_sa["loki"].access_key
      s3_secret_access_key = minio_iam_service_account.user_sa["loki"].secret_key
      s3_insecure          = true
      domain               = var.service_base_domain
      config               = file("${local.jobs}/monitoring/loki/config.yml")
    }
  }

  depends_on = [
    minio_s3_bucket.bucket["loki"],
    minio_iam_service_account.user_sa["loki"],
  ]
}

resource "nomad_job" "vector" {
  jobspec = file("${local.jobs}/monitoring/vector.nomad.hcl")

  hcl2 {
    vars = {
      version       = local.vector_version
      domain        = var.service_base_domain
      vector_config = file("${local.jobs}/monitoring/vector/config.toml")
    }
  }
}

resource "nomad_job" "nvidia_exporter" {
  jobspec = file("${local.jobs}/monitoring/nvidia-exporter.nomad.hcl")

  hcl2 {
    vars = {
      version = local.nvidia_exporter_version
    }
  }
}

resource "nomad_job" "qbittorrent_exporter" {
  jobspec = file("${local.jobs}/monitoring/qbittorrent-exporter.nomad.hcl")

  hcl2 {
    vars = {
      version = local.qbittorrent_exporter_version
    }
  }
}

resource "nomad_job" "tempo" {
  jobspec = file("${local.jobs}/monitoring/tempo.nomad.hcl")

  hcl2 {
    vars = {
      version              = local.tempo_version
      s3_endpoint_url      = var.minio_server
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.bucket["tempo"].bucket
      s3_access_key_id     = minio_iam_service_account.user_sa["tempo"].access_key
      s3_secret_access_key = minio_iam_service_account.user_sa["tempo"].secret_key
      s3_insecure          = false
      domain               = var.service_base_domain
      config               = file("${local.jobs}/monitoring/tempo/config.yml")
    }
  }

  depends_on = [
    minio_s3_bucket.bucket["tempo"],
    minio_iam_service_account.user_sa["tempo"],
  ]
}
