# Import state from the config module
data "terraform_remote_state" "infra" {
  backend   = "pg"
  workspace = "nomad-main-infra"
}

data "terraform_remote_state" "config" {
  backend   = "pg"
  workspace = "nomad-main-config"
}
