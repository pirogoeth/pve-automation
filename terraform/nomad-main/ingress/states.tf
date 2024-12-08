# Import state from the config module
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = abspath(join("/", [path.root, "..", "infra", "terraform.tfstate"]))
  }
}

data "terraform_remote_state" "config" {
  backend = "local"

  config = {
    path = abspath(join("/", [path.root, "..", "config", "terraform.tfstate"]))
  }
}
