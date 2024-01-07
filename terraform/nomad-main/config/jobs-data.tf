resource "nomad_namespace" "data" {
  name        = "data"
  description = "Data collection/processing workloads"
}

resource "nomad_job" "changedetection" {
  jobspec = file("${local.jobs}/data/changedetection.nomad.hcl")

  hcl2 {
    vars = {
      version     = "latest"
      volume_name = module.changedetection_data.volume_name
      domain      = var.service_base_domain
    }
  }
}

resource "random_string" "minio_root_password" {
  length  = 16
  special = true
}

resource "nomad_job" "minio" {
  jobspec = file("${local.jobs}/data/minio.nomad.hcl")

  hcl2 {
    vars = {
      root_username = "root"
      root_password = random_string.minio_root_password.result
      version       = "latest"
      volume_name   = module.minio_data.volume_name
      domain        = var.service_base_domain
    }
  }
}

resource "minio_iam_user" "distribution" {
  name = "distribution"
}

resource "minio_iam_user_policy_attachment" "distribution_rw" {
  user_name   = minio_iam_user.distribution.name
  policy_name = "readwrite"
}

resource "minio_iam_service_account" "distribution_sa" {
  target_user = minio_iam_user.distribution.name
}

resource "minio_s3_bucket" "distribution" {
  bucket = "distribution"
  acl    = "private"
}

resource "minio_s3_bucket_policy" "distribution_policy" {
  bucket = minio_s3_bucket.distribution.bucket
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            minio_iam_user.distribution.id
          ]
        },
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "arn:aws:s3:::${minio_s3_bucket.distribution.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.distribution.bucket}/*",
        ],
      },
    ],
  })
}

resource "nomad_job" "distribution" {
  jobspec = file("${local.jobs}/data/distribution.nomad.hcl")

  hcl2 {
    vars = {
      s3_endpoint_url      = "s3.${var.service_base_domain}"
      s3_region            = "global"
      s3_bucket_name       = minio_s3_bucket.distribution.bucket
      s3_access_key_id     = minio_iam_service_account.distribution_sa.access_key
      s3_secret_access_key = minio_iam_service_account.distribution_sa.secret_key
      version              = "2"
      domain               = var.service_base_domain
    }
  }
}
