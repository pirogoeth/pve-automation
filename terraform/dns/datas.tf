data "terraform_remote_state" "infra" {
  backend   = "pg"
  workspace = "nomad-main-infra"
}


