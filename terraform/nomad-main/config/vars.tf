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