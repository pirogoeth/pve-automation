resource "random_password" "k3s-server-token" {
  length           = 32
  special          = false
  override_special = "_%@"
}

resource "random_password" "pgadmin-user-password" {
  length  = 16
  special = true
}

resource "random_password" "support-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "random_password" "k3s-leader-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}
