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

resource "minio_iam_user" "loki" {
  name = "loki"
}

resource "minio_iam_user_policy_attachment" "loki_rw" {
  user_name   = minio_iam_user.loki.name
  policy_name = "readwrite"
}

resource "minio_iam_service_account" "loki_sa" {
  target_user = minio_iam_user.loki.name
}

resource "minio_s3_bucket" "loki" {
  bucket = "loki"
  acl    = "private"
}

resource "minio_s3_bucket_policy" "loki_policy" {
  bucket = minio_s3_bucket.loki.bucket
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
}

resource "nomad_job" "loki" {
  jobspec = file("${local.jobs}/monitoring/loki.nomad.hcl")

  hcl2 {
    vars = {
      version              = "2.9.3"
      s3_endpoint_url      = "s3.${var.service_base_domain}"
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.loki.bucket
      s3_access_key_id     = minio_iam_service_account.loki_sa.access_key
      s3_secret_access_key = minio_iam_service_account.loki_sa.secret_key
      domain               = var.service_base_domain
      config               = file("${local.jobs}/monitoring/loki/config.yml")
    }
  }
}

resource "nomad_job" "vector" {
  jobspec = file("${local.jobs}/monitoring/vector.nomad.hcl")

  hcl2 {
    vars = {
      version = "0.34.2-debian"
      domain = var.service_base_domain
    }
  }
}