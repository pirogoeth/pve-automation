locals {
  bucket_configs = [
    {
      user = "tempo"
      buckets = [{
        name = "tempo"
        acl  = "private"
      }]
    },
    {
      user = "n8n-voice-transcriptions"
      buckets = [{
        name = "n8n-voice-transcriptions"
        acl  = "private"
      }]
    },
    {
      user = "loki"
      buckets = [{
        name = "loki"
        acl  = "private"
      }]
    },
    {
      user = "pg-archive"
      buckets = [{
        name = "pg-archive"
        acl  = "private"
      }]
    }
  ]

  default_acl     = "private"
  _bucket_mapping = merge([for cfg in local.bucket_configs : { for bucket in cfg.buckets : bucket.name => bucket }]...)
  _user_mapping   = { for cfg in local.bucket_configs : cfg.user => cfg }
}

resource "minio_iam_user" "user" {
  for_each = toset(keys(local._user_mapping))

  name = each.key
}

resource "minio_iam_service_account" "user_sa" {
  for_each = minio_iam_user.user

  target_user = each.value.name

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "minio_iam_user_policy_attachment" "user_policy" {
  for_each = minio_iam_user.user

  user_name   = each.value.name
  policy_name = minio_iam_policy.policy[each.key].name
}

resource "minio_s3_bucket" "bucket" {
  for_each = toset(keys(local._bucket_mapping))

  bucket = each.key
  acl    = lookup(local._bucket_mapping[each.value], "acl", local.default_acl)
}

resource "minio_iam_policy" "policy" {
  for_each = minio_iam_user.user

  name = "${each.key}-user-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            minio_iam_user.user[each.key].id
          ]
        },
        "Action" : [
          "s3:*",
        ],
        "Resource" : flatten([
          for bucket in local._user_mapping[each.key].buckets : [
            "arn:aws:s3:::${minio_s3_bucket.bucket[bucket.name].bucket}",
            "arn:aws:s3:::${minio_s3_bucket.bucket[bucket.name].bucket}/*",
          ]
        ]),
      },
    ],
  })

  lifecycle {
    ignore_changes = [policy]
  }
}

output "buckets" {
  value = keys(local._bucket_mapping)
}

output "credentials" {
  sensitive = true
  value = { for user in keys(local._user_mapping) :
    user => {
      access_key_id     = minio_iam_service_account.user_sa[user].access_key
      secret_access_key = minio_iam_service_account.user_sa[user].secret_key
    }
  }
}
