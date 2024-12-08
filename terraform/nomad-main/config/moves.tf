moved {
  from = minio_iam_user.n8n-voice-transcriptions
  to   = minio_iam_user.user["n8n-voice-transcriptions"]
}

moved {
  from = minio_iam_user.loki
  to   = minio_iam_user.user["loki"]
}

moved {
  from = minio_iam_user.tempo
  to   = minio_iam_user.user["tempo"]
}

moved {
  from = minio_iam_service_account.loki_sa
  to   = minio_iam_service_account.user_sa["loki"]
}

moved {
  from = minio_iam_service_account.tempo_sa
  to   = minio_iam_service_account.user_sa["tempo"]
}

moved {
  from = minio_iam_service_account.n8n-voice-transcriptions_sa
  to   = minio_iam_service_account.user_sa["n8n-voice-transcriptions"]
}

moved {
  from = minio_iam_policy.tempo_policy
  to   = minio_iam_policy.policy["tempo"]
}

moved {
  from = minio_iam_policy.loki_policy
  to   = minio_iam_policy.policy["loki"]
}

moved {
  from = minio_iam_policy.n8n-voice-transcriptions_policy
  to   = minio_iam_policy.policy["n8n-voice-transcriptions"]
}

moved {
  from = minio_iam_user_policy_attachment.loki_rw
  to   = minio_iam_user_policy_attachment.user_policy["loki"]
}

moved {
  from = minio_iam_user_policy_attachment.tempo_rw
  to   = minio_iam_user_policy_attachment.user_policy["tempo"]
}

moved {
  from = minio_iam_user_policy_attachment.n8n-voice-transcriptions_rw
  to   = minio_iam_user_policy_attachment.user_policy["n8n-voice-transcriptions"]
}

moved {
  from = minio_s3_bucket.tempo
  to   = minio_s3_bucket.bucket["tempo"]
}

moved {
  from = minio_s3_bucket.loki
  to   = minio_s3_bucket.bucket["loki"]
}

moved {
  from = minio_s3_bucket.n8n-voice-transcriptions
  to   = minio_s3_bucket.bucket["n8n-voice-transcriptions"]
}
