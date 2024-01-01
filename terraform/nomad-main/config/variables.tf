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
