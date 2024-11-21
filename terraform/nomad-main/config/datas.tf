data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${abspath(path.root)}/../infra/terraform.tfstate"
  }
}