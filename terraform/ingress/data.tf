data "cloudflare_zone" "main" {
  name = var.dns_zone_name
}

data "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
}
