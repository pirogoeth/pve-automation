locals {
  privileges_default = {
    superuser       = false
    create_database = false
    create_role     = false
    inherit         = true
    login           = true
    replication     = false
  }
  database_default = {
    encoding          = "UTF8"
    connection_limit  = -1
    allow_connections = true
  }
  role_privs = { for mr in var.managed_roles : mr.name => merge(local.privileges_default, coalesce(mr.privileges, {})) }
  database_settings = merge(flatten([
    for mr in var.managed_roles : {
      for db in mr.databases : "${mr.name}-${db.name}" => {
        role     = mr
        database = merge(local.database_default, db)
      }
    }
  ])...)
  managed_grants = flatten([
    for role in var.managed_roles : [
      for idx in range(length(role.grants)) : {
        id    = "${role.name}-${idx}"
        role  = role,
        grant = role.grants[idx],
      }
    ]
  ])
}

resource "random_password" "role_password" {
  for_each = toset([for mr in var.managed_roles : mr.name])

  length  = 18
  special = false
}

resource "postgresql_role" "managed_role" {
  for_each = { for mr in var.managed_roles : mr.name => mr }

  name               = each.key
  password           = random_password.role_password[each.key].result
  encrypted_password = true
  roles              = each.value.roles

  // Privileges
  superuser       = local.role_privs[each.key].superuser
  create_database = local.role_privs[each.key].create_database
  create_role     = local.role_privs[each.key].create_role
  inherit         = local.role_privs[each.key].inherit
  login           = local.role_privs[each.key].login
  replication     = local.role_privs[each.key].replication
}

resource "postgresql_grant" "managed_grant" {
  for_each = { for mg in local.managed_grants : mg.id => mg }

  role              = each.value.role.name
  database          = each.value.grant.database
  schema            = each.value.grant.schema
  object_type       = each.value.grant.object_type
  privileges        = each.value.grant.privileges
  objects           = each.value.grant.objects
  with_grant_option = each.value.grant.with_grant_option

  depends_on = [postgresql_role.managed_role]
}

resource "postgresql_database" "managed_db" {
  for_each = local.database_settings

  name              = each.value.database.name
  owner             = each.value.role.name
  encoding          = each.value.database.encoding
  connection_limit  = each.value.database.connection_limit
  allow_connections = each.value.database.allow_connections
}
