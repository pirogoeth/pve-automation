resource "minio_iam_user" "n8n-voice-transcriptions" {
  name = "n8n-voice-transcriptions"
}

resource "minio_iam_user_policy_attachment" "n8n-voice-transcriptions_rw" {
  user_name   = minio_iam_user.n8n-voice-transcriptions.name
  policy_name = minio_iam_policy.n8n-voice-transcriptions_policy.name
}

resource "minio_iam_service_account" "n8n-voice-transcriptions_sa" {
  target_user = minio_iam_user.n8n-voice-transcriptions.name

  lifecycle {
    ignore_changes = [policy]
  }
}

resource "minio_s3_bucket" "n8n-voice-transcriptions" {
  bucket = "n8n-voice-transcriptions"
  acl    = "private"
}

resource "minio_iam_policy" "n8n-voice-transcriptions_policy" {
  name = "n8n-voice-transcriptions-user-rw"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            minio_iam_user.n8n-voice-transcriptions.id
          ]
        },
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "arn:aws:s3:::${minio_s3_bucket.n8n-voice-transcriptions.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.n8n-voice-transcriptions.bucket}/*",
        ],
      },
    ],
  })

  lifecycle {
    ignore_changes = [policy]
  }
}
