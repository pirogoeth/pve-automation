resource "nomad_namespace" "monitoring" {
  name        = "monitoring"
  description = "Application monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${local.jobs}/monitoring/prometheus.nomad.hcl")

  hcl2 {
    vars = {
      version = "2.53.1"
      domain  = var.service_base_domain
    }
  }
}

resource "nomad_job" "grafana" {
  jobspec = file("${local.jobs}/monitoring/grafana.nomad.hcl")

  hcl2 {
    vars = {
      version = "11.2.1"
      domain  = var.service_base_domain
    }
  }
}

resource "minio_iam_user" "loki" {
  name = "loki"
}

resource "minio_iam_user_policy_attachment" "loki_rw" {
  user_name   = minio_iam_user.loki.name
  policy_name = minio_iam_policy.loki_policy.name
}

resource "minio_iam_service_account" "loki_sa" {
  target_user = minio_iam_user.loki.name

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "minio_s3_bucket" "loki" {
  bucket = "loki"
  acl    = "private"
}

resource "minio_iam_policy" "loki_policy" {
  name = "loki-user-rw"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            minio_iam_user.loki.id
          ]
        },
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "arn:aws:s3:::${minio_s3_bucket.loki.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.loki.bucket}/*",
        ],
      },
    ],
  })

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "nomad_job" "loki" {
  jobspec = file("${local.jobs}/monitoring/loki.nomad.hcl")

  hcl2 {
    vars = {
      version              = "3.1.0"
      s3_endpoint_url      = var.minio_server
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.loki.bucket
      s3_access_key_id     = minio_iam_service_account.loki_sa.access_key
      s3_secret_access_key = minio_iam_service_account.loki_sa.secret_key
      s3_insecure          = true
      domain               = var.service_base_domain
      config               = file("${local.jobs}/monitoring/loki/config.yml")
    }
  }

  depends_on = [
    minio_s3_bucket.loki,
    minio_iam_service_account.loki_sa,
  ]
}

resource "nomad_job" "vector" {
  jobspec = file("${local.jobs}/monitoring/vector.nomad.hcl")

  hcl2 {
    vars = {
      version       = "0.34.2-debian"
      domain        = var.service_base_domain
      vector_config = file("${local.jobs}/monitoring/vector/config.toml")
    }
  }
}

resource "nomad_job" "nvidia_exporter" {
  jobspec = file("${local.jobs}/monitoring/nvidia-exporter.nomad.hcl")

  hcl2 {
    vars = {
      version = "1.2.0"
    }
  }
}

resource "nomad_job" "qbittorrent_exporter" {
  jobspec = file("${local.jobs}/monitoring/qbittorrent-exporter.nomad.hcl")

  hcl2 {
    vars = {
      version = "v1.5.1"
    }
  }
}


resource "minio_iam_user" "tempo" {
  name = "tempo"
}

resource "minio_iam_user_policy_attachment" "tempo_rw" {
  user_name   = minio_iam_user.tempo.name
  policy_name = minio_iam_policy.tempo_policy.name
}

resource "minio_iam_service_account" "tempo_sa" {
  target_user = minio_iam_user.tempo.name

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "minio_s3_bucket" "tempo" {
  bucket = "tempo"
  acl    = "private"
}

resource "minio_iam_policy" "tempo_policy" {
  name = "tempo-user-rw"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            minio_iam_user.tempo.id
          ]
        },
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "arn:aws:s3:::${minio_s3_bucket.tempo.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.tempo.bucket}/*",
        ],
      },
    ],
  })

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "nomad_job" "tempo" {
  jobspec = file("${local.jobs}/monitoring/tempo.nomad.hcl")

  hcl2 {
    vars = {
      version              = "2.5.0"
      s3_endpoint_url      = var.minio_server
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.tempo.bucket
      s3_access_key_id     = minio_iam_service_account.tempo_sa.access_key
      s3_secret_access_key = minio_iam_service_account.tempo_sa.secret_key
      s3_insecure          = false
      domain               = var.service_base_domain
      config               = file("${local.jobs}/monitoring/tempo/config.yml")
    }
  }

  depends_on = [
    minio_s3_bucket.tempo,
    minio_iam_service_account.tempo_sa,
  ]
}
