locals {
  idp_cfg = var.idp_configuration.backend_config
}

resource "cloudflare_zero_trust_access_identity_provider" "authentik" {
  account_id = var.cloudflare_account_id
  name       = var.idp_configuration.name
  type       = var.idp_configuration.type

  config {
    client_id        = local.idp_cfg.client_id
    client_secret    = local.idp_cfg.client_secret
    auth_url         = local.idp_cfg.auth_url
    certs_url        = local.idp_cfg.certificate_url
    token_url        = local.idp_cfg.token_url
    pkce_enabled     = local.idp_cfg.proof_key_for_code_exchange
    email_claim_name = local.idp_cfg.email_claim
    claims           = local.idp_cfg.oidc_claims
    scopes           = local.idp_cfg.oidc_scopes
  }

  lifecycle {
    ignore_changes = [
      config[0].client_secret
    ]
  }
}

# resource "cloudflare_zero_trust_access_application" "" {
# 
# }
