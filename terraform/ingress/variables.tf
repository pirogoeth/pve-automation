variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_token" {
  type = string
}

variable "cloudflare_tunnel_name" {
  type = string
}

variable "cloudflare_zt_team_name" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "idp_configuration" {
  type = object({
    name = string
    type = string
    backend_config = object({
      client_id                   = string
      client_secret               = string
      auth_url                    = string
      token_url                   = string
      certificate_url             = string
      proof_key_for_code_exchange = bool
      email_claim                 = optional(string)
      oidc_claims                 = optional(set(string))
      oidc_scopes                 = optional(set(string))
    })
  })
}

variable "tunnel_forwards" {
  type = list(object({
    subdomain = string
    domain    = optional(string)
    target    = string
    path      = optional(string)
    origin_settings = optional(object({
      no_happy_eyeballs = optional(bool, true)
    }), {})
    access = optional(object({
      required      = optional(bool, false)
      audience_tags = optional(list(string), [])
    }))
  }))
}
