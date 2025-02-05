variable "nomad_url" {
  type    = string
  default = "http://localhost:4646"
}

variable "ca_cert" {
  type    = string
  default = ""
}

variable "cli_cert" {
  type    = string
  default = ""
}

variable "cli_key" {
  type    = string
  default = ""
}

variable "tls_skip_verify" {
  type    = bool
  default = false
}

variable "secret_id" {
  type    = string
  default = ""
}

variable "buildkite_agent_token" {
  type    = string
  default = ""
}

variable "service_base_domain" {
  type    = string
  default = "example.org"
}

variable "letsencrypt_email" {
  type    = string
  default = "misconfigured.admin@example.org"
}

variable "cloudflare_tunnel_token" {
  type = string
}

variable "n8n_webhook_url" {
  description = "Base URL n8n should use for webhook endpoints"
  type        = string
}

variable "minio_server" {
  type    = string
  default = "http://10.100.10.2:9000"
}

variable "minio_ssl" {
  type    = bool
  default = false
}

variable "minio_username" {
  type    = string
  default = "minio"
}

variable "minio_password" {
  type    = string
  default = "minio"
}

variable "minio_metrics_bearer_token" {
  type      = string
  sensitive = true
}

variable "langfuse_mailgun_smtp_password" {
  type      = string
  sensitive = true
}

variable "dns_server" {
  type = string
}

variable "dns_key_name" {
  type = string
}

variable "dns_key_algo" {
  type = string
}

variable "dns_key_secret" {
  type = string
  sensitive = true
}