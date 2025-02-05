variable "postgres_host" { type = string }
variable "postgres_port" { type = number }
variable "postgres_username" { type = string }
variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "managed_roles" {
  description = "List of role description objects"
  type = list(object({
    name  = string
    roles = optional(list(string))
    privileges = optional(object({
      superuser       = optional(bool)
      create_database = optional(bool)
      create_role     = optional(bool)
      inherit         = optional(bool)
      login           = optional(bool)
      replication     = optional(bool)
    }))
    databases = list(object({
      name              = string
      encoding          = optional(string)
      connection_limit  = optional(number)
      allow_connections = optional(bool)
    }))
    grants = optional(list(object({
      role     = string
      database = string
      # `schema` is required except if `object_type` is database
      schema = optional(string)
      # `object_type` is one of { database, schema, table, sequence, function, procedure, routine, foreign_data_wrapper, foreign_server, column }
      object_type = string
      # `privileges` is a list of one of { SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, CREATE CONNECT, TEMPORARY, EXECUTE, USAGE }
      # an empty list will revoke all privileges for this role
      privileges = list(string)
      # `objects` is the list of database objects upon which to grant the privileges.
      # An empty list means to grant permissions on ALL OBJECT OF THE SPECIFIED TYPE
      # You can not specify this option if `object_type` is `database` or `schema`.
      # When `object_type` is `column`, only one value is allowed.
      objects = list(string)
      # `columns` is the list of columns upon which to grant privileges.
      # Required when `object_type` is `column`. Otherwise, MUST be empty.
      columns = optional(list(string), null)
      # `with_grant_option` defines whether the recipient of these privileges can grant the same privileges to others.
      with_grant_option = optional(bool, false)
    })), [])
  }))
}
